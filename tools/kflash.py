#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import (division, print_function)

import sys
import time
import zlib
import copy
import struct
import binascii
import hashlib
import argparse
import math
import zipfile, tempfile
import json
import re
import os


class KFlash:
    print_callback = None

    def __init__(self, print_callback = None):
        self.killProcess = False
        self.loader = None
        self.print_callback = print_callback

    @staticmethod
    def log(*args, **kwargs):
        if KFlash.print_callback:
            KFlash.print_callback(*args, **kwargs)
        else:
            print(*args, **kwargs)

    def process(self, terminal=True, dev="", baudrate=1500000, board=None, sram = False, file="", callback=None, noansi=False, terminal_auto_size=False, terminal_size=(50, 1), slow_mode = False):
        self.killProcess = False
        BASH_TIPS = dict(NORMAL='\033[0m',BOLD='\033[1m',DIM='\033[2m',UNDERLINE='\033[4m',
                            DEFAULT='\033[0m', RED='\033[31m', YELLOW='\033[33m', GREEN='\033[32m',
                            BG_DEFAULT='\033[49m', BG_WHITE='\033[107m')

        ERROR_MSG   = BASH_TIPS['RED']+BASH_TIPS['BOLD']+'[ERROR]'+BASH_TIPS['NORMAL']
        WARN_MSG    = BASH_TIPS['YELLOW']+BASH_TIPS['BOLD']+'[WARN]'+BASH_TIPS['NORMAL']
        INFO_MSG    = BASH_TIPS['GREEN']+BASH_TIPS['BOLD']+'[INFO]'+BASH_TIPS['NORMAL']

        VID_LIST_FOR_AUTO_LOOKUP = "(1A86)|(0403)|(067B)|(10C4)|(C251)|(0403)"
        #                            WCH    FTDI    PL     CL    DAP   OPENEC
        ISP_RECEIVE_TIMEOUT = 0.5

        MAX_RETRY_TIMES = 10

        ISP_FLASH_SECTOR_SIZE = 4096
        ISP_FLASH_DATA_FRAME_SIZE = ISP_FLASH_SECTOR_SIZE * 16

        def tuple2str(t):
            ret = ""
            for i in t:
                ret += i+" "
            return ret

        def raise_exception(exception):
            if self.loader:
                try:
                    self.loader._port.close()
                except Exception:
                    pass
            raise exception

        try:
            from enum import Enum
        except ImportError:
            err = (ERROR_MSG,'enum34 must be installed, run '+BASH_TIPS['GREEN']+'`' + ('pip', 'pip3')[sys.version_info > (3, 0)] + ' install enum34`',BASH_TIPS['DEFAULT'])
            err = tuple2str(err)
            raise Exception(err)
        try:
            import serial
            import serial.tools.list_ports
        except ImportError:
            err = (ERROR_MSG,'PySerial must be installed, run '+BASH_TIPS['GREEN']+'`' + ('pip', 'pip3')[sys.version_info > (3, 0)] + ' install pyserial`',BASH_TIPS['DEFAULT'])
            err = tuple2str(err)
            raise Exception(err)

        class TimeoutError(Exception): pass

        class ProgramFileFormat(Enum):
            FMT_BINARY = 0
            FMT_ELF = 1
            FMT_KFPKG = 2

        # AES is from: https://github.com/ricmoo/pyaes, Copyright by Richard Moore
        class AES:
            '''Encapsulates the AES block cipher.
            You generally should not need this. Use the AESModeOfOperation classes
            below instead.'''
            @staticmethod
            def _compact_word(word):
                return (word[0] << 24) | (word[1] << 16) | (word[2] << 8) | word[3]

            # Number of rounds by keysize
            number_of_rounds = {16: 10, 24: 12, 32: 14}

            # Round constant words
            rcon = [ 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91 ]

            # S-box and Inverse S-box (S is for Substitution)
            S = [ 0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15, 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf, 0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73, 0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08, 0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a, 0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf, 0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16 ]
            Si =[ 0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb, 0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb, 0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e, 0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25, 0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92, 0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84, 0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06, 0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b, 0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73, 0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e, 0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b, 0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4, 0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f, 0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef, 0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61, 0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d ]

            # Transformations for encryption
            T1 = [ 0xc66363a5, 0xf87c7c84, 0xee777799, 0xf67b7b8d, 0xfff2f20d, 0xd66b6bbd, 0xde6f6fb1, 0x91c5c554, 0x60303050, 0x02010103, 0xce6767a9, 0x562b2b7d, 0xe7fefe19, 0xb5d7d762, 0x4dababe6, 0xec76769a, 0x8fcaca45, 0x1f82829d, 0x89c9c940, 0xfa7d7d87, 0xeffafa15, 0xb25959eb, 0x8e4747c9, 0xfbf0f00b, 0x41adadec, 0xb3d4d467, 0x5fa2a2fd, 0x45afafea, 0x239c9cbf, 0x53a4a4f7, 0xe4727296, 0x9bc0c05b, 0x75b7b7c2, 0xe1fdfd1c, 0x3d9393ae, 0x4c26266a, 0x6c36365a, 0x7e3f3f41, 0xf5f7f702, 0x83cccc4f, 0x6834345c, 0x51a5a5f4, 0xd1e5e534, 0xf9f1f108, 0xe2717193, 0xabd8d873, 0x62313153, 0x2a15153f, 0x0804040c, 0x95c7c752, 0x46232365, 0x9dc3c35e, 0x30181828, 0x379696a1, 0x0a05050f, 0x2f9a9ab5, 0x0e070709, 0x24121236, 0x1b80809b, 0xdfe2e23d, 0xcdebeb26, 0x4e272769, 0x7fb2b2cd, 0xea75759f, 0x1209091b, 0x1d83839e, 0x582c2c74, 0x341a1a2e, 0x361b1b2d, 0xdc6e6eb2, 0xb45a5aee, 0x5ba0a0fb, 0xa45252f6, 0x763b3b4d, 0xb7d6d661, 0x7db3b3ce, 0x5229297b, 0xdde3e33e, 0x5e2f2f71, 0x13848497, 0xa65353f5, 0xb9d1d168, 0x00000000, 0xc1eded2c, 0x40202060, 0xe3fcfc1f, 0x79b1b1c8, 0xb65b5bed, 0xd46a6abe, 0x8dcbcb46, 0x67bebed9, 0x7239394b, 0x944a4ade, 0x984c4cd4, 0xb05858e8, 0x85cfcf4a, 0xbbd0d06b, 0xc5efef2a, 0x4faaaae5, 0xedfbfb16, 0x864343c5, 0x9a4d4dd7, 0x66333355, 0x11858594, 0x8a4545cf, 0xe9f9f910, 0x04020206, 0xfe7f7f81, 0xa05050f0, 0x783c3c44, 0x259f9fba, 0x4ba8a8e3, 0xa25151f3, 0x5da3a3fe, 0x804040c0, 0x058f8f8a, 0x3f9292ad, 0x219d9dbc, 0x70383848, 0xf1f5f504, 0x63bcbcdf, 0x77b6b6c1, 0xafdada75, 0x42212163, 0x20101030, 0xe5ffff1a, 0xfdf3f30e, 0xbfd2d26d, 0x81cdcd4c, 0x180c0c14, 0x26131335, 0xc3ecec2f, 0xbe5f5fe1, 0x359797a2, 0x884444cc, 0x2e171739, 0x93c4c457, 0x55a7a7f2, 0xfc7e7e82, 0x7a3d3d47, 0xc86464ac, 0xba5d5de7, 0x3219192b, 0xe6737395, 0xc06060a0, 0x19818198, 0x9e4f4fd1, 0xa3dcdc7f, 0x44222266, 0x542a2a7e, 0x3b9090ab, 0x0b888883, 0x8c4646ca, 0xc7eeee29, 0x6bb8b8d3, 0x2814143c, 0xa7dede79, 0xbc5e5ee2, 0x160b0b1d, 0xaddbdb76, 0xdbe0e03b, 0x64323256, 0x743a3a4e, 0x140a0a1e, 0x924949db, 0x0c06060a, 0x4824246c, 0xb85c5ce4, 0x9fc2c25d, 0xbdd3d36e, 0x43acacef, 0xc46262a6, 0x399191a8, 0x319595a4, 0xd3e4e437, 0xf279798b, 0xd5e7e732, 0x8bc8c843, 0x6e373759, 0xda6d6db7, 0x018d8d8c, 0xb1d5d564, 0x9c4e4ed2, 0x49a9a9e0, 0xd86c6cb4, 0xac5656fa, 0xf3f4f407, 0xcfeaea25, 0xca6565af, 0xf47a7a8e, 0x47aeaee9, 0x10080818, 0x6fbabad5, 0xf0787888, 0x4a25256f, 0x5c2e2e72, 0x381c1c24, 0x57a6a6f1, 0x73b4b4c7, 0x97c6c651, 0xcbe8e823, 0xa1dddd7c, 0xe874749c, 0x3e1f1f21, 0x964b4bdd, 0x61bdbddc, 0x0d8b8b86, 0x0f8a8a85, 0xe0707090, 0x7c3e3e42, 0x71b5b5c4, 0xcc6666aa, 0x904848d8, 0x06030305, 0xf7f6f601, 0x1c0e0e12, 0xc26161a3, 0x6a35355f, 0xae5757f9, 0x69b9b9d0, 0x17868691, 0x99c1c158, 0x3a1d1d27, 0x279e9eb9, 0xd9e1e138, 0xebf8f813, 0x2b9898b3, 0x22111133, 0xd26969bb, 0xa9d9d970, 0x078e8e89, 0x339494a7, 0x2d9b9bb6, 0x3c1e1e22, 0x15878792, 0xc9e9e920, 0x87cece49, 0xaa5555ff, 0x50282878, 0xa5dfdf7a, 0x038c8c8f, 0x59a1a1f8, 0x09898980, 0x1a0d0d17, 0x65bfbfda, 0xd7e6e631, 0x844242c6, 0xd06868b8, 0x824141c3, 0x299999b0, 0x5a2d2d77, 0x1e0f0f11, 0x7bb0b0cb, 0xa85454fc, 0x6dbbbbd6, 0x2c16163a ]
            T2 = [ 0xa5c66363, 0x84f87c7c, 0x99ee7777, 0x8df67b7b, 0x0dfff2f2, 0xbdd66b6b, 0xb1de6f6f, 0x5491c5c5, 0x50603030, 0x03020101, 0xa9ce6767, 0x7d562b2b, 0x19e7fefe, 0x62b5d7d7, 0xe64dabab, 0x9aec7676, 0x458fcaca, 0x9d1f8282, 0x4089c9c9, 0x87fa7d7d, 0x15effafa, 0xebb25959, 0xc98e4747, 0x0bfbf0f0, 0xec41adad, 0x67b3d4d4, 0xfd5fa2a2, 0xea45afaf, 0xbf239c9c, 0xf753a4a4, 0x96e47272, 0x5b9bc0c0, 0xc275b7b7, 0x1ce1fdfd, 0xae3d9393, 0x6a4c2626, 0x5a6c3636, 0x417e3f3f, 0x02f5f7f7, 0x4f83cccc, 0x5c683434, 0xf451a5a5, 0x34d1e5e5, 0x08f9f1f1, 0x93e27171, 0x73abd8d8, 0x53623131, 0x3f2a1515, 0x0c080404, 0x5295c7c7, 0x65462323, 0x5e9dc3c3, 0x28301818, 0xa1379696, 0x0f0a0505, 0xb52f9a9a, 0x090e0707, 0x36241212, 0x9b1b8080, 0x3ddfe2e2, 0x26cdebeb, 0x694e2727, 0xcd7fb2b2, 0x9fea7575, 0x1b120909, 0x9e1d8383, 0x74582c2c, 0x2e341a1a, 0x2d361b1b, 0xb2dc6e6e, 0xeeb45a5a, 0xfb5ba0a0, 0xf6a45252, 0x4d763b3b, 0x61b7d6d6, 0xce7db3b3, 0x7b522929, 0x3edde3e3, 0x715e2f2f, 0x97138484, 0xf5a65353, 0x68b9d1d1, 0x00000000, 0x2cc1eded, 0x60402020, 0x1fe3fcfc, 0xc879b1b1, 0xedb65b5b, 0xbed46a6a, 0x468dcbcb, 0xd967bebe, 0x4b723939, 0xde944a4a, 0xd4984c4c, 0xe8b05858, 0x4a85cfcf, 0x6bbbd0d0, 0x2ac5efef, 0xe54faaaa, 0x16edfbfb, 0xc5864343, 0xd79a4d4d, 0x55663333, 0x94118585, 0xcf8a4545, 0x10e9f9f9, 0x06040202, 0x81fe7f7f, 0xf0a05050, 0x44783c3c, 0xba259f9f, 0xe34ba8a8, 0xf3a25151, 0xfe5da3a3, 0xc0804040, 0x8a058f8f, 0xad3f9292, 0xbc219d9d, 0x48703838, 0x04f1f5f5, 0xdf63bcbc, 0xc177b6b6, 0x75afdada, 0x63422121, 0x30201010, 0x1ae5ffff, 0x0efdf3f3, 0x6dbfd2d2, 0x4c81cdcd, 0x14180c0c, 0x35261313, 0x2fc3ecec, 0xe1be5f5f, 0xa2359797, 0xcc884444, 0x392e1717, 0x5793c4c4, 0xf255a7a7, 0x82fc7e7e, 0x477a3d3d, 0xacc86464, 0xe7ba5d5d, 0x2b321919, 0x95e67373, 0xa0c06060, 0x98198181, 0xd19e4f4f, 0x7fa3dcdc, 0x66442222, 0x7e542a2a, 0xab3b9090, 0x830b8888, 0xca8c4646, 0x29c7eeee, 0xd36bb8b8, 0x3c281414, 0x79a7dede, 0xe2bc5e5e, 0x1d160b0b, 0x76addbdb, 0x3bdbe0e0, 0x56643232, 0x4e743a3a, 0x1e140a0a, 0xdb924949, 0x0a0c0606, 0x6c482424, 0xe4b85c5c, 0x5d9fc2c2, 0x6ebdd3d3, 0xef43acac, 0xa6c46262, 0xa8399191, 0xa4319595, 0x37d3e4e4, 0x8bf27979, 0x32d5e7e7, 0x438bc8c8, 0x596e3737, 0xb7da6d6d, 0x8c018d8d, 0x64b1d5d5, 0xd29c4e4e, 0xe049a9a9, 0xb4d86c6c, 0xfaac5656, 0x07f3f4f4, 0x25cfeaea, 0xafca6565, 0x8ef47a7a, 0xe947aeae, 0x18100808, 0xd56fbaba, 0x88f07878, 0x6f4a2525, 0x725c2e2e, 0x24381c1c, 0xf157a6a6, 0xc773b4b4, 0x5197c6c6, 0x23cbe8e8, 0x7ca1dddd, 0x9ce87474, 0x213e1f1f, 0xdd964b4b, 0xdc61bdbd, 0x860d8b8b, 0x850f8a8a, 0x90e07070, 0x427c3e3e, 0xc471b5b5, 0xaacc6666, 0xd8904848, 0x05060303, 0x01f7f6f6, 0x121c0e0e, 0xa3c26161, 0x5f6a3535, 0xf9ae5757, 0xd069b9b9, 0x91178686, 0x5899c1c1, 0x273a1d1d, 0xb9279e9e, 0x38d9e1e1, 0x13ebf8f8, 0xb32b9898, 0x33221111, 0xbbd26969, 0x70a9d9d9, 0x89078e8e, 0xa7339494, 0xb62d9b9b, 0x223c1e1e, 0x92158787, 0x20c9e9e9, 0x4987cece, 0xffaa5555, 0x78502828, 0x7aa5dfdf, 0x8f038c8c, 0xf859a1a1, 0x80098989, 0x171a0d0d, 0xda65bfbf, 0x31d7e6e6, 0xc6844242, 0xb8d06868, 0xc3824141, 0xb0299999, 0x775a2d2d, 0x111e0f0f, 0xcb7bb0b0, 0xfca85454, 0xd66dbbbb, 0x3a2c1616 ]
            T3 = [ 0x63a5c663, 0x7c84f87c, 0x7799ee77, 0x7b8df67b, 0xf20dfff2, 0x6bbdd66b, 0x6fb1de6f, 0xc55491c5, 0x30506030, 0x01030201, 0x67a9ce67, 0x2b7d562b, 0xfe19e7fe, 0xd762b5d7, 0xabe64dab, 0x769aec76, 0xca458fca, 0x829d1f82, 0xc94089c9, 0x7d87fa7d, 0xfa15effa, 0x59ebb259, 0x47c98e47, 0xf00bfbf0, 0xadec41ad, 0xd467b3d4, 0xa2fd5fa2, 0xafea45af, 0x9cbf239c, 0xa4f753a4, 0x7296e472, 0xc05b9bc0, 0xb7c275b7, 0xfd1ce1fd, 0x93ae3d93, 0x266a4c26, 0x365a6c36, 0x3f417e3f, 0xf702f5f7, 0xcc4f83cc, 0x345c6834, 0xa5f451a5, 0xe534d1e5, 0xf108f9f1, 0x7193e271, 0xd873abd8, 0x31536231, 0x153f2a15, 0x040c0804, 0xc75295c7, 0x23654623, 0xc35e9dc3, 0x18283018, 0x96a13796, 0x050f0a05, 0x9ab52f9a, 0x07090e07, 0x12362412, 0x809b1b80, 0xe23ddfe2, 0xeb26cdeb, 0x27694e27, 0xb2cd7fb2, 0x759fea75, 0x091b1209, 0x839e1d83, 0x2c74582c, 0x1a2e341a, 0x1b2d361b, 0x6eb2dc6e, 0x5aeeb45a, 0xa0fb5ba0, 0x52f6a452, 0x3b4d763b, 0xd661b7d6, 0xb3ce7db3, 0x297b5229, 0xe33edde3, 0x2f715e2f, 0x84971384, 0x53f5a653, 0xd168b9d1, 0x00000000, 0xed2cc1ed, 0x20604020, 0xfc1fe3fc, 0xb1c879b1, 0x5bedb65b, 0x6abed46a, 0xcb468dcb, 0xbed967be, 0x394b7239, 0x4ade944a, 0x4cd4984c, 0x58e8b058, 0xcf4a85cf, 0xd06bbbd0, 0xef2ac5ef, 0xaae54faa, 0xfb16edfb, 0x43c58643, 0x4dd79a4d, 0x33556633, 0x85941185, 0x45cf8a45, 0xf910e9f9, 0x02060402, 0x7f81fe7f, 0x50f0a050, 0x3c44783c, 0x9fba259f, 0xa8e34ba8, 0x51f3a251, 0xa3fe5da3, 0x40c08040, 0x8f8a058f, 0x92ad3f92, 0x9dbc219d, 0x38487038, 0xf504f1f5, 0xbcdf63bc, 0xb6c177b6, 0xda75afda, 0x21634221, 0x10302010, 0xff1ae5ff, 0xf30efdf3, 0xd26dbfd2, 0xcd4c81cd, 0x0c14180c, 0x13352613, 0xec2fc3ec, 0x5fe1be5f, 0x97a23597, 0x44cc8844, 0x17392e17, 0xc45793c4, 0xa7f255a7, 0x7e82fc7e, 0x3d477a3d, 0x64acc864, 0x5de7ba5d, 0x192b3219, 0x7395e673, 0x60a0c060, 0x81981981, 0x4fd19e4f, 0xdc7fa3dc, 0x22664422, 0x2a7e542a, 0x90ab3b90, 0x88830b88, 0x46ca8c46, 0xee29c7ee, 0xb8d36bb8, 0x143c2814, 0xde79a7de, 0x5ee2bc5e, 0x0b1d160b, 0xdb76addb, 0xe03bdbe0, 0x32566432, 0x3a4e743a, 0x0a1e140a, 0x49db9249, 0x060a0c06, 0x246c4824, 0x5ce4b85c, 0xc25d9fc2, 0xd36ebdd3, 0xacef43ac, 0x62a6c462, 0x91a83991, 0x95a43195, 0xe437d3e4, 0x798bf279, 0xe732d5e7, 0xc8438bc8, 0x37596e37, 0x6db7da6d, 0x8d8c018d, 0xd564b1d5, 0x4ed29c4e, 0xa9e049a9, 0x6cb4d86c, 0x56faac56, 0xf407f3f4, 0xea25cfea, 0x65afca65, 0x7a8ef47a, 0xaee947ae, 0x08181008, 0xbad56fba, 0x7888f078, 0x256f4a25, 0x2e725c2e, 0x1c24381c, 0xa6f157a6, 0xb4c773b4, 0xc65197c6, 0xe823cbe8, 0xdd7ca1dd, 0x749ce874, 0x1f213e1f, 0x4bdd964b, 0xbddc61bd, 0x8b860d8b, 0x8a850f8a, 0x7090e070, 0x3e427c3e, 0xb5c471b5, 0x66aacc66, 0x48d89048, 0x03050603, 0xf601f7f6, 0x0e121c0e, 0x61a3c261, 0x355f6a35, 0x57f9ae57, 0xb9d069b9, 0x86911786, 0xc15899c1, 0x1d273a1d, 0x9eb9279e, 0xe138d9e1, 0xf813ebf8, 0x98b32b98, 0x11332211, 0x69bbd269, 0xd970a9d9, 0x8e89078e, 0x94a73394, 0x9bb62d9b, 0x1e223c1e, 0x87921587, 0xe920c9e9, 0xce4987ce, 0x55ffaa55, 0x28785028, 0xdf7aa5df, 0x8c8f038c, 0xa1f859a1, 0x89800989, 0x0d171a0d, 0xbfda65bf, 0xe631d7e6, 0x42c68442, 0x68b8d068, 0x41c38241, 0x99b02999, 0x2d775a2d, 0x0f111e0f, 0xb0cb7bb0, 0x54fca854, 0xbbd66dbb, 0x163a2c16 ]
            T4 = [ 0x6363a5c6, 0x7c7c84f8, 0x777799ee, 0x7b7b8df6, 0xf2f20dff, 0x6b6bbdd6, 0x6f6fb1de, 0xc5c55491, 0x30305060, 0x01010302, 0x6767a9ce, 0x2b2b7d56, 0xfefe19e7, 0xd7d762b5, 0xababe64d, 0x76769aec, 0xcaca458f, 0x82829d1f, 0xc9c94089, 0x7d7d87fa, 0xfafa15ef, 0x5959ebb2, 0x4747c98e, 0xf0f00bfb, 0xadadec41, 0xd4d467b3, 0xa2a2fd5f, 0xafafea45, 0x9c9cbf23, 0xa4a4f753, 0x727296e4, 0xc0c05b9b, 0xb7b7c275, 0xfdfd1ce1, 0x9393ae3d, 0x26266a4c, 0x36365a6c, 0x3f3f417e, 0xf7f702f5, 0xcccc4f83, 0x34345c68, 0xa5a5f451, 0xe5e534d1, 0xf1f108f9, 0x717193e2, 0xd8d873ab, 0x31315362, 0x15153f2a, 0x04040c08, 0xc7c75295, 0x23236546, 0xc3c35e9d, 0x18182830, 0x9696a137, 0x05050f0a, 0x9a9ab52f, 0x0707090e, 0x12123624, 0x80809b1b, 0xe2e23ddf, 0xebeb26cd, 0x2727694e, 0xb2b2cd7f, 0x75759fea, 0x09091b12, 0x83839e1d, 0x2c2c7458, 0x1a1a2e34, 0x1b1b2d36, 0x6e6eb2dc, 0x5a5aeeb4, 0xa0a0fb5b, 0x5252f6a4, 0x3b3b4d76, 0xd6d661b7, 0xb3b3ce7d, 0x29297b52, 0xe3e33edd, 0x2f2f715e, 0x84849713, 0x5353f5a6, 0xd1d168b9, 0x00000000, 0xeded2cc1, 0x20206040, 0xfcfc1fe3, 0xb1b1c879, 0x5b5bedb6, 0x6a6abed4, 0xcbcb468d, 0xbebed967, 0x39394b72, 0x4a4ade94, 0x4c4cd498, 0x5858e8b0, 0xcfcf4a85, 0xd0d06bbb, 0xefef2ac5, 0xaaaae54f, 0xfbfb16ed, 0x4343c586, 0x4d4dd79a, 0x33335566, 0x85859411, 0x4545cf8a, 0xf9f910e9, 0x02020604, 0x7f7f81fe, 0x5050f0a0, 0x3c3c4478, 0x9f9fba25, 0xa8a8e34b, 0x5151f3a2, 0xa3a3fe5d, 0x4040c080, 0x8f8f8a05, 0x9292ad3f, 0x9d9dbc21, 0x38384870, 0xf5f504f1, 0xbcbcdf63, 0xb6b6c177, 0xdada75af, 0x21216342, 0x10103020, 0xffff1ae5, 0xf3f30efd, 0xd2d26dbf, 0xcdcd4c81, 0x0c0c1418, 0x13133526, 0xecec2fc3, 0x5f5fe1be, 0x9797a235, 0x4444cc88, 0x1717392e, 0xc4c45793, 0xa7a7f255, 0x7e7e82fc, 0x3d3d477a, 0x6464acc8, 0x5d5de7ba, 0x19192b32, 0x737395e6, 0x6060a0c0, 0x81819819, 0x4f4fd19e, 0xdcdc7fa3, 0x22226644, 0x2a2a7e54, 0x9090ab3b, 0x8888830b, 0x4646ca8c, 0xeeee29c7, 0xb8b8d36b, 0x14143c28, 0xdede79a7, 0x5e5ee2bc, 0x0b0b1d16, 0xdbdb76ad, 0xe0e03bdb, 0x32325664, 0x3a3a4e74, 0x0a0a1e14, 0x4949db92, 0x06060a0c, 0x24246c48, 0x5c5ce4b8, 0xc2c25d9f, 0xd3d36ebd, 0xacacef43, 0x6262a6c4, 0x9191a839, 0x9595a431, 0xe4e437d3, 0x79798bf2, 0xe7e732d5, 0xc8c8438b, 0x3737596e, 0x6d6db7da, 0x8d8d8c01, 0xd5d564b1, 0x4e4ed29c, 0xa9a9e049, 0x6c6cb4d8, 0x5656faac, 0xf4f407f3, 0xeaea25cf, 0x6565afca, 0x7a7a8ef4, 0xaeaee947, 0x08081810, 0xbabad56f, 0x787888f0, 0x25256f4a, 0x2e2e725c, 0x1c1c2438, 0xa6a6f157, 0xb4b4c773, 0xc6c65197, 0xe8e823cb, 0xdddd7ca1, 0x74749ce8, 0x1f1f213e, 0x4b4bdd96, 0xbdbddc61, 0x8b8b860d, 0x8a8a850f, 0x707090e0, 0x3e3e427c, 0xb5b5c471, 0x6666aacc, 0x4848d890, 0x03030506, 0xf6f601f7, 0x0e0e121c, 0x6161a3c2, 0x35355f6a, 0x5757f9ae, 0xb9b9d069, 0x86869117, 0xc1c15899, 0x1d1d273a, 0x9e9eb927, 0xe1e138d9, 0xf8f813eb, 0x9898b32b, 0x11113322, 0x6969bbd2, 0xd9d970a9, 0x8e8e8907, 0x9494a733, 0x9b9bb62d, 0x1e1e223c, 0x87879215, 0xe9e920c9, 0xcece4987, 0x5555ffaa, 0x28287850, 0xdfdf7aa5, 0x8c8c8f03, 0xa1a1f859, 0x89898009, 0x0d0d171a, 0xbfbfda65, 0xe6e631d7, 0x4242c684, 0x6868b8d0, 0x4141c382, 0x9999b029, 0x2d2d775a, 0x0f0f111e, 0xb0b0cb7b, 0x5454fca8, 0xbbbbd66d, 0x16163a2c ]

            # Transformations for decryption
            T5 = [ 0x51f4a750, 0x7e416553, 0x1a17a4c3, 0x3a275e96, 0x3bab6bcb, 0x1f9d45f1, 0xacfa58ab, 0x4be30393, 0x2030fa55, 0xad766df6, 0x88cc7691, 0xf5024c25, 0x4fe5d7fc, 0xc52acbd7, 0x26354480, 0xb562a38f, 0xdeb15a49, 0x25ba1b67, 0x45ea0e98, 0x5dfec0e1, 0xc32f7502, 0x814cf012, 0x8d4697a3, 0x6bd3f9c6, 0x038f5fe7, 0x15929c95, 0xbf6d7aeb, 0x955259da, 0xd4be832d, 0x587421d3, 0x49e06929, 0x8ec9c844, 0x75c2896a, 0xf48e7978, 0x99583e6b, 0x27b971dd, 0xbee14fb6, 0xf088ad17, 0xc920ac66, 0x7dce3ab4, 0x63df4a18, 0xe51a3182, 0x97513360, 0x62537f45, 0xb16477e0, 0xbb6bae84, 0xfe81a01c, 0xf9082b94, 0x70486858, 0x8f45fd19, 0x94de6c87, 0x527bf8b7, 0xab73d323, 0x724b02e2, 0xe31f8f57, 0x6655ab2a, 0xb2eb2807, 0x2fb5c203, 0x86c57b9a, 0xd33708a5, 0x302887f2, 0x23bfa5b2, 0x02036aba, 0xed16825c, 0x8acf1c2b, 0xa779b492, 0xf307f2f0, 0x4e69e2a1, 0x65daf4cd, 0x0605bed5, 0xd134621f, 0xc4a6fe8a, 0x342e539d, 0xa2f355a0, 0x058ae132, 0xa4f6eb75, 0x0b83ec39, 0x4060efaa, 0x5e719f06, 0xbd6e1051, 0x3e218af9, 0x96dd063d, 0xdd3e05ae, 0x4de6bd46, 0x91548db5, 0x71c45d05, 0x0406d46f, 0x605015ff, 0x1998fb24, 0xd6bde997, 0x894043cc, 0x67d99e77, 0xb0e842bd, 0x07898b88, 0xe7195b38, 0x79c8eedb, 0xa17c0a47, 0x7c420fe9, 0xf8841ec9, 0x00000000, 0x09808683, 0x322bed48, 0x1e1170ac, 0x6c5a724e, 0xfd0efffb, 0x0f853856, 0x3daed51e, 0x362d3927, 0x0a0fd964, 0x685ca621, 0x9b5b54d1, 0x24362e3a, 0x0c0a67b1, 0x9357e70f, 0xb4ee96d2, 0x1b9b919e, 0x80c0c54f, 0x61dc20a2, 0x5a774b69, 0x1c121a16, 0xe293ba0a, 0xc0a02ae5, 0x3c22e043, 0x121b171d, 0x0e090d0b, 0xf28bc7ad, 0x2db6a8b9, 0x141ea9c8, 0x57f11985, 0xaf75074c, 0xee99ddbb, 0xa37f60fd, 0xf701269f, 0x5c72f5bc, 0x44663bc5, 0x5bfb7e34, 0x8b432976, 0xcb23c6dc, 0xb6edfc68, 0xb8e4f163, 0xd731dcca, 0x42638510, 0x13972240, 0x84c61120, 0x854a247d, 0xd2bb3df8, 0xaef93211, 0xc729a16d, 0x1d9e2f4b, 0xdcb230f3, 0x0d8652ec, 0x77c1e3d0, 0x2bb3166c, 0xa970b999, 0x119448fa, 0x47e96422, 0xa8fc8cc4, 0xa0f03f1a, 0x567d2cd8, 0x223390ef, 0x87494ec7, 0xd938d1c1, 0x8ccaa2fe, 0x98d40b36, 0xa6f581cf, 0xa57ade28, 0xdab78e26, 0x3fadbfa4, 0x2c3a9de4, 0x5078920d, 0x6a5fcc9b, 0x547e4662, 0xf68d13c2, 0x90d8b8e8, 0x2e39f75e, 0x82c3aff5, 0x9f5d80be, 0x69d0937c, 0x6fd52da9, 0xcf2512b3, 0xc8ac993b, 0x10187da7, 0xe89c636e, 0xdb3bbb7b, 0xcd267809, 0x6e5918f4, 0xec9ab701, 0x834f9aa8, 0xe6956e65, 0xaaffe67e, 0x21bccf08, 0xef15e8e6, 0xbae79bd9, 0x4a6f36ce, 0xea9f09d4, 0x29b07cd6, 0x31a4b2af, 0x2a3f2331, 0xc6a59430, 0x35a266c0, 0x744ebc37, 0xfc82caa6, 0xe090d0b0, 0x33a7d815, 0xf104984a, 0x41ecdaf7, 0x7fcd500e, 0x1791f62f, 0x764dd68d, 0x43efb04d, 0xccaa4d54, 0xe49604df, 0x9ed1b5e3, 0x4c6a881b, 0xc12c1fb8, 0x4665517f, 0x9d5eea04, 0x018c355d, 0xfa877473, 0xfb0b412e, 0xb3671d5a, 0x92dbd252, 0xe9105633, 0x6dd64713, 0x9ad7618c, 0x37a10c7a, 0x59f8148e, 0xeb133c89, 0xcea927ee, 0xb761c935, 0xe11ce5ed, 0x7a47b13c, 0x9cd2df59, 0x55f2733f, 0x1814ce79, 0x73c737bf, 0x53f7cdea, 0x5ffdaa5b, 0xdf3d6f14, 0x7844db86, 0xcaaff381, 0xb968c43e, 0x3824342c, 0xc2a3405f, 0x161dc372, 0xbce2250c, 0x283c498b, 0xff0d9541, 0x39a80171, 0x080cb3de, 0xd8b4e49c, 0x6456c190, 0x7bcb8461, 0xd532b670, 0x486c5c74, 0xd0b85742 ]
            T6 = [ 0x5051f4a7, 0x537e4165, 0xc31a17a4, 0x963a275e, 0xcb3bab6b, 0xf11f9d45, 0xabacfa58, 0x934be303, 0x552030fa, 0xf6ad766d, 0x9188cc76, 0x25f5024c, 0xfc4fe5d7, 0xd7c52acb, 0x80263544, 0x8fb562a3, 0x49deb15a, 0x6725ba1b, 0x9845ea0e, 0xe15dfec0, 0x02c32f75, 0x12814cf0, 0xa38d4697, 0xc66bd3f9, 0xe7038f5f, 0x9515929c, 0xebbf6d7a, 0xda955259, 0x2dd4be83, 0xd3587421, 0x2949e069, 0x448ec9c8, 0x6a75c289, 0x78f48e79, 0x6b99583e, 0xdd27b971, 0xb6bee14f, 0x17f088ad, 0x66c920ac, 0xb47dce3a, 0x1863df4a, 0x82e51a31, 0x60975133, 0x4562537f, 0xe0b16477, 0x84bb6bae, 0x1cfe81a0, 0x94f9082b, 0x58704868, 0x198f45fd, 0x8794de6c, 0xb7527bf8, 0x23ab73d3, 0xe2724b02, 0x57e31f8f, 0x2a6655ab, 0x07b2eb28, 0x032fb5c2, 0x9a86c57b, 0xa5d33708, 0xf2302887, 0xb223bfa5, 0xba02036a, 0x5ced1682, 0x2b8acf1c, 0x92a779b4, 0xf0f307f2, 0xa14e69e2, 0xcd65daf4, 0xd50605be, 0x1fd13462, 0x8ac4a6fe, 0x9d342e53, 0xa0a2f355, 0x32058ae1, 0x75a4f6eb, 0x390b83ec, 0xaa4060ef, 0x065e719f, 0x51bd6e10, 0xf93e218a, 0x3d96dd06, 0xaedd3e05, 0x464de6bd, 0xb591548d, 0x0571c45d, 0x6f0406d4, 0xff605015, 0x241998fb, 0x97d6bde9, 0xcc894043, 0x7767d99e, 0xbdb0e842, 0x8807898b, 0x38e7195b, 0xdb79c8ee, 0x47a17c0a, 0xe97c420f, 0xc9f8841e, 0x00000000, 0x83098086, 0x48322bed, 0xac1e1170, 0x4e6c5a72, 0xfbfd0eff, 0x560f8538, 0x1e3daed5, 0x27362d39, 0x640a0fd9, 0x21685ca6, 0xd19b5b54, 0x3a24362e, 0xb10c0a67, 0x0f9357e7, 0xd2b4ee96, 0x9e1b9b91, 0x4f80c0c5, 0xa261dc20, 0x695a774b, 0x161c121a, 0x0ae293ba, 0xe5c0a02a, 0x433c22e0, 0x1d121b17, 0x0b0e090d, 0xadf28bc7, 0xb92db6a8, 0xc8141ea9, 0x8557f119, 0x4caf7507, 0xbbee99dd, 0xfda37f60, 0x9ff70126, 0xbc5c72f5, 0xc544663b, 0x345bfb7e, 0x768b4329, 0xdccb23c6, 0x68b6edfc, 0x63b8e4f1, 0xcad731dc, 0x10426385, 0x40139722, 0x2084c611, 0x7d854a24, 0xf8d2bb3d, 0x11aef932, 0x6dc729a1, 0x4b1d9e2f, 0xf3dcb230, 0xec0d8652, 0xd077c1e3, 0x6c2bb316, 0x99a970b9, 0xfa119448, 0x2247e964, 0xc4a8fc8c, 0x1aa0f03f, 0xd8567d2c, 0xef223390, 0xc787494e, 0xc1d938d1, 0xfe8ccaa2, 0x3698d40b, 0xcfa6f581, 0x28a57ade, 0x26dab78e, 0xa43fadbf, 0xe42c3a9d, 0x0d507892, 0x9b6a5fcc, 0x62547e46, 0xc2f68d13, 0xe890d8b8, 0x5e2e39f7, 0xf582c3af, 0xbe9f5d80, 0x7c69d093, 0xa96fd52d, 0xb3cf2512, 0x3bc8ac99, 0xa710187d, 0x6ee89c63, 0x7bdb3bbb, 0x09cd2678, 0xf46e5918, 0x01ec9ab7, 0xa8834f9a, 0x65e6956e, 0x7eaaffe6, 0x0821bccf, 0xe6ef15e8, 0xd9bae79b, 0xce4a6f36, 0xd4ea9f09, 0xd629b07c, 0xaf31a4b2, 0x312a3f23, 0x30c6a594, 0xc035a266, 0x37744ebc, 0xa6fc82ca, 0xb0e090d0, 0x1533a7d8, 0x4af10498, 0xf741ecda, 0x0e7fcd50, 0x2f1791f6, 0x8d764dd6, 0x4d43efb0, 0x54ccaa4d, 0xdfe49604, 0xe39ed1b5, 0x1b4c6a88, 0xb8c12c1f, 0x7f466551, 0x049d5eea, 0x5d018c35, 0x73fa8774, 0x2efb0b41, 0x5ab3671d, 0x5292dbd2, 0x33e91056, 0x136dd647, 0x8c9ad761, 0x7a37a10c, 0x8e59f814, 0x89eb133c, 0xeecea927, 0x35b761c9, 0xede11ce5, 0x3c7a47b1, 0x599cd2df, 0x3f55f273, 0x791814ce, 0xbf73c737, 0xea53f7cd, 0x5b5ffdaa, 0x14df3d6f, 0x867844db, 0x81caaff3, 0x3eb968c4, 0x2c382434, 0x5fc2a340, 0x72161dc3, 0x0cbce225, 0x8b283c49, 0x41ff0d95, 0x7139a801, 0xde080cb3, 0x9cd8b4e4, 0x906456c1, 0x617bcb84, 0x70d532b6, 0x74486c5c, 0x42d0b857 ]
            T7 = [ 0xa75051f4, 0x65537e41, 0xa4c31a17, 0x5e963a27, 0x6bcb3bab, 0x45f11f9d, 0x58abacfa, 0x03934be3, 0xfa552030, 0x6df6ad76, 0x769188cc, 0x4c25f502, 0xd7fc4fe5, 0xcbd7c52a, 0x44802635, 0xa38fb562, 0x5a49deb1, 0x1b6725ba, 0x0e9845ea, 0xc0e15dfe, 0x7502c32f, 0xf012814c, 0x97a38d46, 0xf9c66bd3, 0x5fe7038f, 0x9c951592, 0x7aebbf6d, 0x59da9552, 0x832dd4be, 0x21d35874, 0x692949e0, 0xc8448ec9, 0x896a75c2, 0x7978f48e, 0x3e6b9958, 0x71dd27b9, 0x4fb6bee1, 0xad17f088, 0xac66c920, 0x3ab47dce, 0x4a1863df, 0x3182e51a, 0x33609751, 0x7f456253, 0x77e0b164, 0xae84bb6b, 0xa01cfe81, 0x2b94f908, 0x68587048, 0xfd198f45, 0x6c8794de, 0xf8b7527b, 0xd323ab73, 0x02e2724b, 0x8f57e31f, 0xab2a6655, 0x2807b2eb, 0xc2032fb5, 0x7b9a86c5, 0x08a5d337, 0x87f23028, 0xa5b223bf, 0x6aba0203, 0x825ced16, 0x1c2b8acf, 0xb492a779, 0xf2f0f307, 0xe2a14e69, 0xf4cd65da, 0xbed50605, 0x621fd134, 0xfe8ac4a6, 0x539d342e, 0x55a0a2f3, 0xe132058a, 0xeb75a4f6, 0xec390b83, 0xefaa4060, 0x9f065e71, 0x1051bd6e, 0x8af93e21, 0x063d96dd, 0x05aedd3e, 0xbd464de6, 0x8db59154, 0x5d0571c4, 0xd46f0406, 0x15ff6050, 0xfb241998, 0xe997d6bd, 0x43cc8940, 0x9e7767d9, 0x42bdb0e8, 0x8b880789, 0x5b38e719, 0xeedb79c8, 0x0a47a17c, 0x0fe97c42, 0x1ec9f884, 0x00000000, 0x86830980, 0xed48322b, 0x70ac1e11, 0x724e6c5a, 0xfffbfd0e, 0x38560f85, 0xd51e3dae, 0x3927362d, 0xd9640a0f, 0xa621685c, 0x54d19b5b, 0x2e3a2436, 0x67b10c0a, 0xe70f9357, 0x96d2b4ee, 0x919e1b9b, 0xc54f80c0, 0x20a261dc, 0x4b695a77, 0x1a161c12, 0xba0ae293, 0x2ae5c0a0, 0xe0433c22, 0x171d121b, 0x0d0b0e09, 0xc7adf28b, 0xa8b92db6, 0xa9c8141e, 0x198557f1, 0x074caf75, 0xddbbee99, 0x60fda37f, 0x269ff701, 0xf5bc5c72, 0x3bc54466, 0x7e345bfb, 0x29768b43, 0xc6dccb23, 0xfc68b6ed, 0xf163b8e4, 0xdccad731, 0x85104263, 0x22401397, 0x112084c6, 0x247d854a, 0x3df8d2bb, 0x3211aef9, 0xa16dc729, 0x2f4b1d9e, 0x30f3dcb2, 0x52ec0d86, 0xe3d077c1, 0x166c2bb3, 0xb999a970, 0x48fa1194, 0x642247e9, 0x8cc4a8fc, 0x3f1aa0f0, 0x2cd8567d, 0x90ef2233, 0x4ec78749, 0xd1c1d938, 0xa2fe8cca, 0x0b3698d4, 0x81cfa6f5, 0xde28a57a, 0x8e26dab7, 0xbfa43fad, 0x9de42c3a, 0x920d5078, 0xcc9b6a5f, 0x4662547e, 0x13c2f68d, 0xb8e890d8, 0xf75e2e39, 0xaff582c3, 0x80be9f5d, 0x937c69d0, 0x2da96fd5, 0x12b3cf25, 0x993bc8ac, 0x7da71018, 0x636ee89c, 0xbb7bdb3b, 0x7809cd26, 0x18f46e59, 0xb701ec9a, 0x9aa8834f, 0x6e65e695, 0xe67eaaff, 0xcf0821bc, 0xe8e6ef15, 0x9bd9bae7, 0x36ce4a6f, 0x09d4ea9f, 0x7cd629b0, 0xb2af31a4, 0x23312a3f, 0x9430c6a5, 0x66c035a2, 0xbc37744e, 0xcaa6fc82, 0xd0b0e090, 0xd81533a7, 0x984af104, 0xdaf741ec, 0x500e7fcd, 0xf62f1791, 0xd68d764d, 0xb04d43ef, 0x4d54ccaa, 0x04dfe496, 0xb5e39ed1, 0x881b4c6a, 0x1fb8c12c, 0x517f4665, 0xea049d5e, 0x355d018c, 0x7473fa87, 0x412efb0b, 0x1d5ab367, 0xd25292db, 0x5633e910, 0x47136dd6, 0x618c9ad7, 0x0c7a37a1, 0x148e59f8, 0x3c89eb13, 0x27eecea9, 0xc935b761, 0xe5ede11c, 0xb13c7a47, 0xdf599cd2, 0x733f55f2, 0xce791814, 0x37bf73c7, 0xcdea53f7, 0xaa5b5ffd, 0x6f14df3d, 0xdb867844, 0xf381caaf, 0xc43eb968, 0x342c3824, 0x405fc2a3, 0xc372161d, 0x250cbce2, 0x498b283c, 0x9541ff0d, 0x017139a8, 0xb3de080c, 0xe49cd8b4, 0xc1906456, 0x84617bcb, 0xb670d532, 0x5c74486c, 0x5742d0b8 ]
            T8 = [ 0xf4a75051, 0x4165537e, 0x17a4c31a, 0x275e963a, 0xab6bcb3b, 0x9d45f11f, 0xfa58abac, 0xe303934b, 0x30fa5520, 0x766df6ad, 0xcc769188, 0x024c25f5, 0xe5d7fc4f, 0x2acbd7c5, 0x35448026, 0x62a38fb5, 0xb15a49de, 0xba1b6725, 0xea0e9845, 0xfec0e15d, 0x2f7502c3, 0x4cf01281, 0x4697a38d, 0xd3f9c66b, 0x8f5fe703, 0x929c9515, 0x6d7aebbf, 0x5259da95, 0xbe832dd4, 0x7421d358, 0xe0692949, 0xc9c8448e, 0xc2896a75, 0x8e7978f4, 0x583e6b99, 0xb971dd27, 0xe14fb6be, 0x88ad17f0, 0x20ac66c9, 0xce3ab47d, 0xdf4a1863, 0x1a3182e5, 0x51336097, 0x537f4562, 0x6477e0b1, 0x6bae84bb, 0x81a01cfe, 0x082b94f9, 0x48685870, 0x45fd198f, 0xde6c8794, 0x7bf8b752, 0x73d323ab, 0x4b02e272, 0x1f8f57e3, 0x55ab2a66, 0xeb2807b2, 0xb5c2032f, 0xc57b9a86, 0x3708a5d3, 0x2887f230, 0xbfa5b223, 0x036aba02, 0x16825ced, 0xcf1c2b8a, 0x79b492a7, 0x07f2f0f3, 0x69e2a14e, 0xdaf4cd65, 0x05bed506, 0x34621fd1, 0xa6fe8ac4, 0x2e539d34, 0xf355a0a2, 0x8ae13205, 0xf6eb75a4, 0x83ec390b, 0x60efaa40, 0x719f065e, 0x6e1051bd, 0x218af93e, 0xdd063d96, 0x3e05aedd, 0xe6bd464d, 0x548db591, 0xc45d0571, 0x06d46f04, 0x5015ff60, 0x98fb2419, 0xbde997d6, 0x4043cc89, 0xd99e7767, 0xe842bdb0, 0x898b8807, 0x195b38e7, 0xc8eedb79, 0x7c0a47a1, 0x420fe97c, 0x841ec9f8, 0x00000000, 0x80868309, 0x2bed4832, 0x1170ac1e, 0x5a724e6c, 0x0efffbfd, 0x8538560f, 0xaed51e3d, 0x2d392736, 0x0fd9640a, 0x5ca62168, 0x5b54d19b, 0x362e3a24, 0x0a67b10c, 0x57e70f93, 0xee96d2b4, 0x9b919e1b, 0xc0c54f80, 0xdc20a261, 0x774b695a, 0x121a161c, 0x93ba0ae2, 0xa02ae5c0, 0x22e0433c, 0x1b171d12, 0x090d0b0e, 0x8bc7adf2, 0xb6a8b92d, 0x1ea9c814, 0xf1198557, 0x75074caf, 0x99ddbbee, 0x7f60fda3, 0x01269ff7, 0x72f5bc5c, 0x663bc544, 0xfb7e345b, 0x4329768b, 0x23c6dccb, 0xedfc68b6, 0xe4f163b8, 0x31dccad7, 0x63851042, 0x97224013, 0xc6112084, 0x4a247d85, 0xbb3df8d2, 0xf93211ae, 0x29a16dc7, 0x9e2f4b1d, 0xb230f3dc, 0x8652ec0d, 0xc1e3d077, 0xb3166c2b, 0x70b999a9, 0x9448fa11, 0xe9642247, 0xfc8cc4a8, 0xf03f1aa0, 0x7d2cd856, 0x3390ef22, 0x494ec787, 0x38d1c1d9, 0xcaa2fe8c, 0xd40b3698, 0xf581cfa6, 0x7ade28a5, 0xb78e26da, 0xadbfa43f, 0x3a9de42c, 0x78920d50, 0x5fcc9b6a, 0x7e466254, 0x8d13c2f6, 0xd8b8e890, 0x39f75e2e, 0xc3aff582, 0x5d80be9f, 0xd0937c69, 0xd52da96f, 0x2512b3cf, 0xac993bc8, 0x187da710, 0x9c636ee8, 0x3bbb7bdb, 0x267809cd, 0x5918f46e, 0x9ab701ec, 0x4f9aa883, 0x956e65e6, 0xffe67eaa, 0xbccf0821, 0x15e8e6ef, 0xe79bd9ba, 0x6f36ce4a, 0x9f09d4ea, 0xb07cd629, 0xa4b2af31, 0x3f23312a, 0xa59430c6, 0xa266c035, 0x4ebc3774, 0x82caa6fc, 0x90d0b0e0, 0xa7d81533, 0x04984af1, 0xecdaf741, 0xcd500e7f, 0x91f62f17, 0x4dd68d76, 0xefb04d43, 0xaa4d54cc, 0x9604dfe4, 0xd1b5e39e, 0x6a881b4c, 0x2c1fb8c1, 0x65517f46, 0x5eea049d, 0x8c355d01, 0x877473fa, 0x0b412efb, 0x671d5ab3, 0xdbd25292, 0x105633e9, 0xd647136d, 0xd7618c9a, 0xa10c7a37, 0xf8148e59, 0x133c89eb, 0xa927eece, 0x61c935b7, 0x1ce5ede1, 0x47b13c7a, 0xd2df599c, 0xf2733f55, 0x14ce7918, 0xc737bf73, 0xf7cdea53, 0xfdaa5b5f, 0x3d6f14df, 0x44db8678, 0xaff381ca, 0x68c43eb9, 0x24342c38, 0xa3405fc2, 0x1dc37216, 0xe2250cbc, 0x3c498b28, 0x0d9541ff, 0xa8017139, 0x0cb3de08, 0xb4e49cd8, 0x56c19064, 0xcb84617b, 0x32b670d5, 0x6c5c7448, 0xb85742d0 ]

            # Transformations for decryption key expansion
            U1 = [ 0x00000000, 0x0e090d0b, 0x1c121a16, 0x121b171d, 0x3824342c, 0x362d3927, 0x24362e3a, 0x2a3f2331, 0x70486858, 0x7e416553, 0x6c5a724e, 0x62537f45, 0x486c5c74, 0x4665517f, 0x547e4662, 0x5a774b69, 0xe090d0b0, 0xee99ddbb, 0xfc82caa6, 0xf28bc7ad, 0xd8b4e49c, 0xd6bde997, 0xc4a6fe8a, 0xcaaff381, 0x90d8b8e8, 0x9ed1b5e3, 0x8ccaa2fe, 0x82c3aff5, 0xa8fc8cc4, 0xa6f581cf, 0xb4ee96d2, 0xbae79bd9, 0xdb3bbb7b, 0xd532b670, 0xc729a16d, 0xc920ac66, 0xe31f8f57, 0xed16825c, 0xff0d9541, 0xf104984a, 0xab73d323, 0xa57ade28, 0xb761c935, 0xb968c43e, 0x9357e70f, 0x9d5eea04, 0x8f45fd19, 0x814cf012, 0x3bab6bcb, 0x35a266c0, 0x27b971dd, 0x29b07cd6, 0x038f5fe7, 0x0d8652ec, 0x1f9d45f1, 0x119448fa, 0x4be30393, 0x45ea0e98, 0x57f11985, 0x59f8148e, 0x73c737bf, 0x7dce3ab4, 0x6fd52da9, 0x61dc20a2, 0xad766df6, 0xa37f60fd, 0xb16477e0, 0xbf6d7aeb, 0x955259da, 0x9b5b54d1, 0x894043cc, 0x87494ec7, 0xdd3e05ae, 0xd33708a5, 0xc12c1fb8, 0xcf2512b3, 0xe51a3182, 0xeb133c89, 0xf9082b94, 0xf701269f, 0x4de6bd46, 0x43efb04d, 0x51f4a750, 0x5ffdaa5b, 0x75c2896a, 0x7bcb8461, 0x69d0937c, 0x67d99e77, 0x3daed51e, 0x33a7d815, 0x21bccf08, 0x2fb5c203, 0x058ae132, 0x0b83ec39, 0x1998fb24, 0x1791f62f, 0x764dd68d, 0x7844db86, 0x6a5fcc9b, 0x6456c190, 0x4e69e2a1, 0x4060efaa, 0x527bf8b7, 0x5c72f5bc, 0x0605bed5, 0x080cb3de, 0x1a17a4c3, 0x141ea9c8, 0x3e218af9, 0x302887f2, 0x223390ef, 0x2c3a9de4, 0x96dd063d, 0x98d40b36, 0x8acf1c2b, 0x84c61120, 0xaef93211, 0xa0f03f1a, 0xb2eb2807, 0xbce2250c, 0xe6956e65, 0xe89c636e, 0xfa877473, 0xf48e7978, 0xdeb15a49, 0xd0b85742, 0xc2a3405f, 0xccaa4d54, 0x41ecdaf7, 0x4fe5d7fc, 0x5dfec0e1, 0x53f7cdea, 0x79c8eedb, 0x77c1e3d0, 0x65daf4cd, 0x6bd3f9c6, 0x31a4b2af, 0x3fadbfa4, 0x2db6a8b9, 0x23bfa5b2, 0x09808683, 0x07898b88, 0x15929c95, 0x1b9b919e, 0xa17c0a47, 0xaf75074c, 0xbd6e1051, 0xb3671d5a, 0x99583e6b, 0x97513360, 0x854a247d, 0x8b432976, 0xd134621f, 0xdf3d6f14, 0xcd267809, 0xc32f7502, 0xe9105633, 0xe7195b38, 0xf5024c25, 0xfb0b412e, 0x9ad7618c, 0x94de6c87, 0x86c57b9a, 0x88cc7691, 0xa2f355a0, 0xacfa58ab, 0xbee14fb6, 0xb0e842bd, 0xea9f09d4, 0xe49604df, 0xf68d13c2, 0xf8841ec9, 0xd2bb3df8, 0xdcb230f3, 0xcea927ee, 0xc0a02ae5, 0x7a47b13c, 0x744ebc37, 0x6655ab2a, 0x685ca621, 0x42638510, 0x4c6a881b, 0x5e719f06, 0x5078920d, 0x0a0fd964, 0x0406d46f, 0x161dc372, 0x1814ce79, 0x322bed48, 0x3c22e043, 0x2e39f75e, 0x2030fa55, 0xec9ab701, 0xe293ba0a, 0xf088ad17, 0xfe81a01c, 0xd4be832d, 0xdab78e26, 0xc8ac993b, 0xc6a59430, 0x9cd2df59, 0x92dbd252, 0x80c0c54f, 0x8ec9c844, 0xa4f6eb75, 0xaaffe67e, 0xb8e4f163, 0xb6edfc68, 0x0c0a67b1, 0x02036aba, 0x10187da7, 0x1e1170ac, 0x342e539d, 0x3a275e96, 0x283c498b, 0x26354480, 0x7c420fe9, 0x724b02e2, 0x605015ff, 0x6e5918f4, 0x44663bc5, 0x4a6f36ce, 0x587421d3, 0x567d2cd8, 0x37a10c7a, 0x39a80171, 0x2bb3166c, 0x25ba1b67, 0x0f853856, 0x018c355d, 0x13972240, 0x1d9e2f4b, 0x47e96422, 0x49e06929, 0x5bfb7e34, 0x55f2733f, 0x7fcd500e, 0x71c45d05, 0x63df4a18, 0x6dd64713, 0xd731dcca, 0xd938d1c1, 0xcb23c6dc, 0xc52acbd7, 0xef15e8e6, 0xe11ce5ed, 0xf307f2f0, 0xfd0efffb, 0xa779b492, 0xa970b999, 0xbb6bae84, 0xb562a38f, 0x9f5d80be, 0x91548db5, 0x834f9aa8, 0x8d4697a3 ]
            U2 = [ 0x00000000, 0x0b0e090d, 0x161c121a, 0x1d121b17, 0x2c382434, 0x27362d39, 0x3a24362e, 0x312a3f23, 0x58704868, 0x537e4165, 0x4e6c5a72, 0x4562537f, 0x74486c5c, 0x7f466551, 0x62547e46, 0x695a774b, 0xb0e090d0, 0xbbee99dd, 0xa6fc82ca, 0xadf28bc7, 0x9cd8b4e4, 0x97d6bde9, 0x8ac4a6fe, 0x81caaff3, 0xe890d8b8, 0xe39ed1b5, 0xfe8ccaa2, 0xf582c3af, 0xc4a8fc8c, 0xcfa6f581, 0xd2b4ee96, 0xd9bae79b, 0x7bdb3bbb, 0x70d532b6, 0x6dc729a1, 0x66c920ac, 0x57e31f8f, 0x5ced1682, 0x41ff0d95, 0x4af10498, 0x23ab73d3, 0x28a57ade, 0x35b761c9, 0x3eb968c4, 0x0f9357e7, 0x049d5eea, 0x198f45fd, 0x12814cf0, 0xcb3bab6b, 0xc035a266, 0xdd27b971, 0xd629b07c, 0xe7038f5f, 0xec0d8652, 0xf11f9d45, 0xfa119448, 0x934be303, 0x9845ea0e, 0x8557f119, 0x8e59f814, 0xbf73c737, 0xb47dce3a, 0xa96fd52d, 0xa261dc20, 0xf6ad766d, 0xfda37f60, 0xe0b16477, 0xebbf6d7a, 0xda955259, 0xd19b5b54, 0xcc894043, 0xc787494e, 0xaedd3e05, 0xa5d33708, 0xb8c12c1f, 0xb3cf2512, 0x82e51a31, 0x89eb133c, 0x94f9082b, 0x9ff70126, 0x464de6bd, 0x4d43efb0, 0x5051f4a7, 0x5b5ffdaa, 0x6a75c289, 0x617bcb84, 0x7c69d093, 0x7767d99e, 0x1e3daed5, 0x1533a7d8, 0x0821bccf, 0x032fb5c2, 0x32058ae1, 0x390b83ec, 0x241998fb, 0x2f1791f6, 0x8d764dd6, 0x867844db, 0x9b6a5fcc, 0x906456c1, 0xa14e69e2, 0xaa4060ef, 0xb7527bf8, 0xbc5c72f5, 0xd50605be, 0xde080cb3, 0xc31a17a4, 0xc8141ea9, 0xf93e218a, 0xf2302887, 0xef223390, 0xe42c3a9d, 0x3d96dd06, 0x3698d40b, 0x2b8acf1c, 0x2084c611, 0x11aef932, 0x1aa0f03f, 0x07b2eb28, 0x0cbce225, 0x65e6956e, 0x6ee89c63, 0x73fa8774, 0x78f48e79, 0x49deb15a, 0x42d0b857, 0x5fc2a340, 0x54ccaa4d, 0xf741ecda, 0xfc4fe5d7, 0xe15dfec0, 0xea53f7cd, 0xdb79c8ee, 0xd077c1e3, 0xcd65daf4, 0xc66bd3f9, 0xaf31a4b2, 0xa43fadbf, 0xb92db6a8, 0xb223bfa5, 0x83098086, 0x8807898b, 0x9515929c, 0x9e1b9b91, 0x47a17c0a, 0x4caf7507, 0x51bd6e10, 0x5ab3671d, 0x6b99583e, 0x60975133, 0x7d854a24, 0x768b4329, 0x1fd13462, 0x14df3d6f, 0x09cd2678, 0x02c32f75, 0x33e91056, 0x38e7195b, 0x25f5024c, 0x2efb0b41, 0x8c9ad761, 0x8794de6c, 0x9a86c57b, 0x9188cc76, 0xa0a2f355, 0xabacfa58, 0xb6bee14f, 0xbdb0e842, 0xd4ea9f09, 0xdfe49604, 0xc2f68d13, 0xc9f8841e, 0xf8d2bb3d, 0xf3dcb230, 0xeecea927, 0xe5c0a02a, 0x3c7a47b1, 0x37744ebc, 0x2a6655ab, 0x21685ca6, 0x10426385, 0x1b4c6a88, 0x065e719f, 0x0d507892, 0x640a0fd9, 0x6f0406d4, 0x72161dc3, 0x791814ce, 0x48322bed, 0x433c22e0, 0x5e2e39f7, 0x552030fa, 0x01ec9ab7, 0x0ae293ba, 0x17f088ad, 0x1cfe81a0, 0x2dd4be83, 0x26dab78e, 0x3bc8ac99, 0x30c6a594, 0x599cd2df, 0x5292dbd2, 0x4f80c0c5, 0x448ec9c8, 0x75a4f6eb, 0x7eaaffe6, 0x63b8e4f1, 0x68b6edfc, 0xb10c0a67, 0xba02036a, 0xa710187d, 0xac1e1170, 0x9d342e53, 0x963a275e, 0x8b283c49, 0x80263544, 0xe97c420f, 0xe2724b02, 0xff605015, 0xf46e5918, 0xc544663b, 0xce4a6f36, 0xd3587421, 0xd8567d2c, 0x7a37a10c, 0x7139a801, 0x6c2bb316, 0x6725ba1b, 0x560f8538, 0x5d018c35, 0x40139722, 0x4b1d9e2f, 0x2247e964, 0x2949e069, 0x345bfb7e, 0x3f55f273, 0x0e7fcd50, 0x0571c45d, 0x1863df4a, 0x136dd647, 0xcad731dc, 0xc1d938d1, 0xdccb23c6, 0xd7c52acb, 0xe6ef15e8, 0xede11ce5, 0xf0f307f2, 0xfbfd0eff, 0x92a779b4, 0x99a970b9, 0x84bb6bae, 0x8fb562a3, 0xbe9f5d80, 0xb591548d, 0xa8834f9a, 0xa38d4697 ]
            U3 = [ 0x00000000, 0x0d0b0e09, 0x1a161c12, 0x171d121b, 0x342c3824, 0x3927362d, 0x2e3a2436, 0x23312a3f, 0x68587048, 0x65537e41, 0x724e6c5a, 0x7f456253, 0x5c74486c, 0x517f4665, 0x4662547e, 0x4b695a77, 0xd0b0e090, 0xddbbee99, 0xcaa6fc82, 0xc7adf28b, 0xe49cd8b4, 0xe997d6bd, 0xfe8ac4a6, 0xf381caaf, 0xb8e890d8, 0xb5e39ed1, 0xa2fe8cca, 0xaff582c3, 0x8cc4a8fc, 0x81cfa6f5, 0x96d2b4ee, 0x9bd9bae7, 0xbb7bdb3b, 0xb670d532, 0xa16dc729, 0xac66c920, 0x8f57e31f, 0x825ced16, 0x9541ff0d, 0x984af104, 0xd323ab73, 0xde28a57a, 0xc935b761, 0xc43eb968, 0xe70f9357, 0xea049d5e, 0xfd198f45, 0xf012814c, 0x6bcb3bab, 0x66c035a2, 0x71dd27b9, 0x7cd629b0, 0x5fe7038f, 0x52ec0d86, 0x45f11f9d, 0x48fa1194, 0x03934be3, 0x0e9845ea, 0x198557f1, 0x148e59f8, 0x37bf73c7, 0x3ab47dce, 0x2da96fd5, 0x20a261dc, 0x6df6ad76, 0x60fda37f, 0x77e0b164, 0x7aebbf6d, 0x59da9552, 0x54d19b5b, 0x43cc8940, 0x4ec78749, 0x05aedd3e, 0x08a5d337, 0x1fb8c12c, 0x12b3cf25, 0x3182e51a, 0x3c89eb13, 0x2b94f908, 0x269ff701, 0xbd464de6, 0xb04d43ef, 0xa75051f4, 0xaa5b5ffd, 0x896a75c2, 0x84617bcb, 0x937c69d0, 0x9e7767d9, 0xd51e3dae, 0xd81533a7, 0xcf0821bc, 0xc2032fb5, 0xe132058a, 0xec390b83, 0xfb241998, 0xf62f1791, 0xd68d764d, 0xdb867844, 0xcc9b6a5f, 0xc1906456, 0xe2a14e69, 0xefaa4060, 0xf8b7527b, 0xf5bc5c72, 0xbed50605, 0xb3de080c, 0xa4c31a17, 0xa9c8141e, 0x8af93e21, 0x87f23028, 0x90ef2233, 0x9de42c3a, 0x063d96dd, 0x0b3698d4, 0x1c2b8acf, 0x112084c6, 0x3211aef9, 0x3f1aa0f0, 0x2807b2eb, 0x250cbce2, 0x6e65e695, 0x636ee89c, 0x7473fa87, 0x7978f48e, 0x5a49deb1, 0x5742d0b8, 0x405fc2a3, 0x4d54ccaa, 0xdaf741ec, 0xd7fc4fe5, 0xc0e15dfe, 0xcdea53f7, 0xeedb79c8, 0xe3d077c1, 0xf4cd65da, 0xf9c66bd3, 0xb2af31a4, 0xbfa43fad, 0xa8b92db6, 0xa5b223bf, 0x86830980, 0x8b880789, 0x9c951592, 0x919e1b9b, 0x0a47a17c, 0x074caf75, 0x1051bd6e, 0x1d5ab367, 0x3e6b9958, 0x33609751, 0x247d854a, 0x29768b43, 0x621fd134, 0x6f14df3d, 0x7809cd26, 0x7502c32f, 0x5633e910, 0x5b38e719, 0x4c25f502, 0x412efb0b, 0x618c9ad7, 0x6c8794de, 0x7b9a86c5, 0x769188cc, 0x55a0a2f3, 0x58abacfa, 0x4fb6bee1, 0x42bdb0e8, 0x09d4ea9f, 0x04dfe496, 0x13c2f68d, 0x1ec9f884, 0x3df8d2bb, 0x30f3dcb2, 0x27eecea9, 0x2ae5c0a0, 0xb13c7a47, 0xbc37744e, 0xab2a6655, 0xa621685c, 0x85104263, 0x881b4c6a, 0x9f065e71, 0x920d5078, 0xd9640a0f, 0xd46f0406, 0xc372161d, 0xce791814, 0xed48322b, 0xe0433c22, 0xf75e2e39, 0xfa552030, 0xb701ec9a, 0xba0ae293, 0xad17f088, 0xa01cfe81, 0x832dd4be, 0x8e26dab7, 0x993bc8ac, 0x9430c6a5, 0xdf599cd2, 0xd25292db, 0xc54f80c0, 0xc8448ec9, 0xeb75a4f6, 0xe67eaaff, 0xf163b8e4, 0xfc68b6ed, 0x67b10c0a, 0x6aba0203, 0x7da71018, 0x70ac1e11, 0x539d342e, 0x5e963a27, 0x498b283c, 0x44802635, 0x0fe97c42, 0x02e2724b, 0x15ff6050, 0x18f46e59, 0x3bc54466, 0x36ce4a6f, 0x21d35874, 0x2cd8567d, 0x0c7a37a1, 0x017139a8, 0x166c2bb3, 0x1b6725ba, 0x38560f85, 0x355d018c, 0x22401397, 0x2f4b1d9e, 0x642247e9, 0x692949e0, 0x7e345bfb, 0x733f55f2, 0x500e7fcd, 0x5d0571c4, 0x4a1863df, 0x47136dd6, 0xdccad731, 0xd1c1d938, 0xc6dccb23, 0xcbd7c52a, 0xe8e6ef15, 0xe5ede11c, 0xf2f0f307, 0xfffbfd0e, 0xb492a779, 0xb999a970, 0xae84bb6b, 0xa38fb562, 0x80be9f5d, 0x8db59154, 0x9aa8834f, 0x97a38d46 ]
            U4 = [ 0x00000000, 0x090d0b0e, 0x121a161c, 0x1b171d12, 0x24342c38, 0x2d392736, 0x362e3a24, 0x3f23312a, 0x48685870, 0x4165537e, 0x5a724e6c, 0x537f4562, 0x6c5c7448, 0x65517f46, 0x7e466254, 0x774b695a, 0x90d0b0e0, 0x99ddbbee, 0x82caa6fc, 0x8bc7adf2, 0xb4e49cd8, 0xbde997d6, 0xa6fe8ac4, 0xaff381ca, 0xd8b8e890, 0xd1b5e39e, 0xcaa2fe8c, 0xc3aff582, 0xfc8cc4a8, 0xf581cfa6, 0xee96d2b4, 0xe79bd9ba, 0x3bbb7bdb, 0x32b670d5, 0x29a16dc7, 0x20ac66c9, 0x1f8f57e3, 0x16825ced, 0x0d9541ff, 0x04984af1, 0x73d323ab, 0x7ade28a5, 0x61c935b7, 0x68c43eb9, 0x57e70f93, 0x5eea049d, 0x45fd198f, 0x4cf01281, 0xab6bcb3b, 0xa266c035, 0xb971dd27, 0xb07cd629, 0x8f5fe703, 0x8652ec0d, 0x9d45f11f, 0x9448fa11, 0xe303934b, 0xea0e9845, 0xf1198557, 0xf8148e59, 0xc737bf73, 0xce3ab47d, 0xd52da96f, 0xdc20a261, 0x766df6ad, 0x7f60fda3, 0x6477e0b1, 0x6d7aebbf, 0x5259da95, 0x5b54d19b, 0x4043cc89, 0x494ec787, 0x3e05aedd, 0x3708a5d3, 0x2c1fb8c1, 0x2512b3cf, 0x1a3182e5, 0x133c89eb, 0x082b94f9, 0x01269ff7, 0xe6bd464d, 0xefb04d43, 0xf4a75051, 0xfdaa5b5f, 0xc2896a75, 0xcb84617b, 0xd0937c69, 0xd99e7767, 0xaed51e3d, 0xa7d81533, 0xbccf0821, 0xb5c2032f, 0x8ae13205, 0x83ec390b, 0x98fb2419, 0x91f62f17, 0x4dd68d76, 0x44db8678, 0x5fcc9b6a, 0x56c19064, 0x69e2a14e, 0x60efaa40, 0x7bf8b752, 0x72f5bc5c, 0x05bed506, 0x0cb3de08, 0x17a4c31a, 0x1ea9c814, 0x218af93e, 0x2887f230, 0x3390ef22, 0x3a9de42c, 0xdd063d96, 0xd40b3698, 0xcf1c2b8a, 0xc6112084, 0xf93211ae, 0xf03f1aa0, 0xeb2807b2, 0xe2250cbc, 0x956e65e6, 0x9c636ee8, 0x877473fa, 0x8e7978f4, 0xb15a49de, 0xb85742d0, 0xa3405fc2, 0xaa4d54cc, 0xecdaf741, 0xe5d7fc4f, 0xfec0e15d, 0xf7cdea53, 0xc8eedb79, 0xc1e3d077, 0xdaf4cd65, 0xd3f9c66b, 0xa4b2af31, 0xadbfa43f, 0xb6a8b92d, 0xbfa5b223, 0x80868309, 0x898b8807, 0x929c9515, 0x9b919e1b, 0x7c0a47a1, 0x75074caf, 0x6e1051bd, 0x671d5ab3, 0x583e6b99, 0x51336097, 0x4a247d85, 0x4329768b, 0x34621fd1, 0x3d6f14df, 0x267809cd, 0x2f7502c3, 0x105633e9, 0x195b38e7, 0x024c25f5, 0x0b412efb, 0xd7618c9a, 0xde6c8794, 0xc57b9a86, 0xcc769188, 0xf355a0a2, 0xfa58abac, 0xe14fb6be, 0xe842bdb0, 0x9f09d4ea, 0x9604dfe4, 0x8d13c2f6, 0x841ec9f8, 0xbb3df8d2, 0xb230f3dc, 0xa927eece, 0xa02ae5c0, 0x47b13c7a, 0x4ebc3774, 0x55ab2a66, 0x5ca62168, 0x63851042, 0x6a881b4c, 0x719f065e, 0x78920d50, 0x0fd9640a, 0x06d46f04, 0x1dc37216, 0x14ce7918, 0x2bed4832, 0x22e0433c, 0x39f75e2e, 0x30fa5520, 0x9ab701ec, 0x93ba0ae2, 0x88ad17f0, 0x81a01cfe, 0xbe832dd4, 0xb78e26da, 0xac993bc8, 0xa59430c6, 0xd2df599c, 0xdbd25292, 0xc0c54f80, 0xc9c8448e, 0xf6eb75a4, 0xffe67eaa, 0xe4f163b8, 0xedfc68b6, 0x0a67b10c, 0x036aba02, 0x187da710, 0x1170ac1e, 0x2e539d34, 0x275e963a, 0x3c498b28, 0x35448026, 0x420fe97c, 0x4b02e272, 0x5015ff60, 0x5918f46e, 0x663bc544, 0x6f36ce4a, 0x7421d358, 0x7d2cd856, 0xa10c7a37, 0xa8017139, 0xb3166c2b, 0xba1b6725, 0x8538560f, 0x8c355d01, 0x97224013, 0x9e2f4b1d, 0xe9642247, 0xe0692949, 0xfb7e345b, 0xf2733f55, 0xcd500e7f, 0xc45d0571, 0xdf4a1863, 0xd647136d, 0x31dccad7, 0x38d1c1d9, 0x23c6dccb, 0x2acbd7c5, 0x15e8e6ef, 0x1ce5ede1, 0x07f2f0f3, 0x0efffbfd, 0x79b492a7, 0x70b999a9, 0x6bae84bb, 0x62a38fb5, 0x5d80be9f, 0x548db591, 0x4f9aa883, 0x4697a38d ]

            def __init__(self, key):

                if len(key) not in (16, 24, 32):
                    raise_exception( ValueError('Invalid key size') )

                rounds = self.number_of_rounds[len(key)]

                # Encryption round keys
                self._Ke = [[0] * 4 for i in range(rounds + 1)]

                # Decryption round keys
                self._Kd = [[0] * 4 for i in range(rounds + 1)]

                round_key_count = (rounds + 1) * 4
                KC = len(key) // 4

                # Convert the key into ints
                tk = [ struct.unpack('>i', key[i:i + 4])[0] for i in range(0, len(key), 4) ]

                # Copy values into round key arrays
                for i in range(0, KC):
                    self._Ke[i // 4][i % 4] = tk[i]
                    self._Kd[rounds - (i // 4)][i % 4] = tk[i]

                # Key expansion (fips-197 section 5.2)
                rconpointer = 0
                t = KC
                while t < round_key_count:

                    tt = tk[KC - 1]
                    tk[0] ^= ((self.S[(tt >> 16) & 0xFF] << 24) ^
                              (self.S[(tt >>  8) & 0xFF] << 16) ^
                              (self.S[ tt        & 0xFF] <<  8) ^
                               self.S[(tt >> 24) & 0xFF]        ^
                              (self.rcon[rconpointer] << 24))
                    rconpointer += 1

                    if KC != 8:
                        for i in range(1, KC):
                            tk[i] ^= tk[i - 1]

                    # Key expansion for 256-bit keys is "slightly different" (fips-197)
                    else:
                        for i in range(1, KC // 2):
                            tk[i] ^= tk[i - 1]
                        tt = tk[KC // 2 - 1]

                        tk[KC // 2] ^= (self.S[ tt        & 0xFF]        ^
                                       (self.S[(tt >>  8) & 0xFF] <<  8) ^
                                       (self.S[(tt >> 16) & 0xFF] << 16) ^
                                       (self.S[(tt >> 24) & 0xFF] << 24))

                        for i in range(KC // 2 + 1, KC):
                            tk[i] ^= tk[i - 1]

                    # Copy values into round key arrays
                    j = 0
                    while j < KC and t < round_key_count:
                        self._Ke[t // 4][t % 4] = tk[j]
                        self._Kd[rounds - (t // 4)][t % 4] = tk[j]
                        j += 1
                        t += 1

                # Inverse-Cipher-ify the decryption round key (fips-197 section 5.3)
                for r in range(1, rounds):
                    for j in range(0, 4):
                        tt = self._Kd[r][j]
                        self._Kd[r][j] = (self.U1[(tt >> 24) & 0xFF] ^
                                          self.U2[(tt >> 16) & 0xFF] ^
                                          self.U3[(tt >>  8) & 0xFF] ^
                                          self.U4[ tt        & 0xFF])

            def encrypt(self, plaintext):
                'Encrypt a block of plain text using the AES block cipher.'

                if len(plaintext) != 16:
                    raise_exception( ValueError('wrong block length') )

                rounds = len(self._Ke) - 1
                (s1, s2, s3) = [1, 2, 3]
                a = [0, 0, 0, 0]

                # Convert plaintext to (ints ^ key)
                t = [(AES._compact_word(plaintext[4 * i:4 * i + 4]) ^ self._Ke[0][i]) for i in range(0, 4)]

                # Apply round transforms
                for r in range(1, rounds):
                    for i in range(0, 4):
                        a[i] = (self.T1[(t[ i          ] >> 24) & 0xFF] ^
                                self.T2[(t[(i + s1) % 4] >> 16) & 0xFF] ^
                                self.T3[(t[(i + s2) % 4] >>  8) & 0xFF] ^
                                self.T4[ t[(i + s3) % 4]        & 0xFF] ^
                                self._Ke[r][i])
                    t = copy.copy(a)

                # The last round is special
                result = [ ]
                for i in range(0, 4):
                    tt = self._Ke[rounds][i]
                    result.append((self.S[(t[ i           ] >> 24) & 0xFF] ^ (tt >> 24)) & 0xFF)
                    result.append((self.S[(t[(i + s1) % 4] >> 16) & 0xFF] ^ (tt >> 16)) & 0xFF)
                    result.append((self.S[(t[(i + s2) % 4] >>  8) & 0xFF] ^ (tt >>  8)) & 0xFF)
                    result.append((self.S[ t[(i + s3) % 4]        & 0xFF] ^  tt       ) & 0xFF)

                return result

            def decrypt(self, ciphertext):
                'Decrypt a block of cipher text using the AES block cipher.'

                if len(ciphertext) != 16:
                    raise_exception( ValueError('wrong block length') )

                rounds = len(self._Kd) - 1
                (s1, s2, s3) = [3, 2, 1]
                a = [0, 0, 0, 0]

                # Convert ciphertext to (ints ^ key)
                t = [(AES._compact_word(ciphertext[4 * i:4 * i + 4]) ^ self._Kd[0][i]) for i in range(0, 4)]

                # Apply round transforms
                for r in range(1, rounds):
                    for i in range(0, 4):
                        a[i] = (self.T5[(t[ i          ] >> 24) & 0xFF] ^
                                self.T6[(t[(i + s1) % 4] >> 16) & 0xFF] ^
                                self.T7[(t[(i + s2) % 4] >>  8) & 0xFF] ^
                                self.T8[ t[(i + s3) % 4]        & 0xFF] ^
                                self._Kd[r][i])
                    t = copy.copy(a)

                # The last round is special
                result = [ ]
                for i in range(0, 4):
                    tt = self._Kd[rounds][i]
                    result.append((self.Si[(t[ i           ] >> 24) & 0xFF] ^ (tt >> 24)) & 0xFF)
                    result.append((self.Si[(t[(i + s1) % 4] >> 16) & 0xFF] ^ (tt >> 16)) & 0xFF)
                    result.append((self.Si[(t[(i + s2) % 4] >>  8) & 0xFF] ^ (tt >>  8)) & 0xFF)
                    result.append((self.Si[ t[(i + s3) % 4]        & 0xFF] ^  tt       ) & 0xFF)

                return result

        class AES_128_CBC:

            def __init__(self, key, iv = None):
                self._aes = AES(key)
                if iv is None:
                    self._last_cipherblock = [ 0 ] * 16
                elif len(iv) != 16:
                    raise_exception( ValueError('initialization vector must be 16 bytes') )
                else:
                    self._last_cipherblock = iv


            def encrypt(self, plaintext):
                if len(plaintext) != 16:
                    raise_exception( ValueError('plaintext block must be 16 bytes') )

                precipherblock = [ (p ^ l) for (p, l) in zip(plaintext, self._last_cipherblock) ]
                self._last_cipherblock = self._aes.encrypt(precipherblock)

                return b''.join(map(lambda x: x.to_bytes(1, 'little'), self._last_cipherblock))

            def decrypt(self, ciphertext):
                if len(ciphertext) != 16:
                    raise_exception( ValueError('ciphertext block must be 16 bytes') )

                cipherblock = ciphertext
                plaintext = [ (p ^ l) for (p, l) in zip(self._aes.decrypt(cipherblock), self._last_cipherblock) ]
                self._last_cipherblock = cipherblock

                return b''.join(map(lambda x: x.to_bytes(1, 'little'), plaintext))

        ISP_PROG = '789cbcbc7d5c1357d6007c6792c924080a0e1890d82201a2acebc38a4aab960d428862eb636b85ea56171d10b5dacafa416dcb4a48263122453a60c0604bb182b25bd71535ada8011569edf787623fb4688080a2420522cac77befcc04d0769f7dff787faffec2ccbdf7dc73cf3df79c73cfb91f33f1e0dd331f5ec300061efdb7695144c4a64541f0a746bfe9161c00363b7bcca6dd2f44e8d4588c2e069bab9b8bc5ea62b1385d1ca6d169b0785d3ca6d569b179ba79d87cdd7c2c4197802dd02dc09ed53d8b3da77b0e5ba85b88fdafee7f8b576d2ac52336794780c500747c077f8b31f884bfc5387cc2df62117cc2df62317cc2df62023ee16fb1043ee16f31099ff0b7580a9ff0b758069ff0b7d8033ee16ff128f884bfc59ef0097f8bbde013fe168f864ff85b3c063ee1cfe283015617532cff9b0c50f85117f537bc6f53a8ba93c2fc40343636ffb5a08db12b7dc635de0b0e9a4eff8ce346bc6d2c5d84e32b7dc6375a7058371bbfbd49a9ee1c2ddafb0e4e4fc4f4477140efc041f6aa89d86b20287013088a40ef58baa4c9a37574fbd88e715de3ef3fd157d658de54d97ab8fd68c789ae93f7cff4cdbd1edf9cd0b6f0f60b9d89ddcb7a57f4dfb8ded27cb3edceed5f3b7bba1ff40ef4ab82306f55888fb76ad2446fd5943f79ab8262c6aa429e1fab9ab472ac6a4afa585590ce571592efab9af4beaf6acabf7d5541b5e35421df8c534dba3e4e35a5731cac1f00eb07c0fa01b07e00ac1f08eb07c2fa81b07e20ac3f01d69f00eb4f80f527c0fa4fc2fa4fc2fa4fc2fa4f6e0a0d9a7e2fd47bba87d117a79710e06ed0918501a57723364edae4ed37bd2c79eeca1b2bf1bf95fd6deea61b9b2429e529f1a92da992ade55be3335a323cd654ae49587b73adc71b956f24bc79f3cdd1eb0faf5fb8e1ce86d17f3ffcf785dbef6c2761df4c413a6f7222e6639aa8f32183b1b1a660dd5852895126a58e2243305f5388ce970cc5fc4ca13a3f320c1b670ad38d235598dca4d2c9c94998bf6992ce9f9c8c059826eb02c8706cbc295c379efc031668fa832e909c82294c53740af28fd804d31f7513c8a9d813a6a9ba27c8ffc19e34fd8fee490ac382d038010047a9d1a3696cebb8f6f11d4f7405df0febab6c3cdc74b4f544fbc98e335d67ef5fe84bb8beb0f985b6c4dbcb3a5774afea5ddd7ff3fa9de65fdb7a6e3fe81ce8be171c01f6f4de0bf69ebea71f2f93947b548e3e3cf6e8b813e34f3e71a6acacbcbcb2f2f0e1a3474f9c3879f2cc99b9fbe32b12feb1f05f2f5425da9655afb0dfd8df5271f31f77fef56b558fed41f5809d97adb99fbb650bc995f24830b02c02c099551a22945f74978bfe8d037ce5977fdbb47b1ab803ff8e9d6e0b06c09a8def409a969d1cbc72eeaa1babf04d659be66ebeb159925a9e1abfba65b524a33c23fef596d73dd656ae4d5877739dc79b956f26bc75f3add11b0e6f58f8ea9d57476f3fbc7d6cd0d1a01726fe3a71ecb4a3d35e88fc35725cc88990c4d09ed071334fcc4c8cea891a3fe9e4a465931f4c1e3febe4ac65b31fcc7e62ca99292bfe38f0c727a2cf44aff8f3c09fdddc8df191346d52a93b192dad7001426351a39e349aee65c4456c028bbcbbed166f94937ca42c19d3c460d95972020314c1b45848d85713d9429b2b805c04b22851ec715a2402b8de0da369b2c027cbd439ccb9b98c595b55d78deb3ee561f547ddb0088fbede749db98b68b100d45ad0030b09b25893ea88f933a1bd5fb812f82b4b66b472584789bbae217a1006049bf661eeb9181fbec5d026be56e8cf0246ae5e0c06db066940df2397624034efa51f27686743547c4fd27eb2c05cfd276b7ef29a5742cff6f7c722d3480c53159d0b34f50c5e3947688bea2b0be909c771f8f6d9e78b75a1812602d05d2740a04902749a4006a6e8669cf523715d7ef1bb53f7740e280f9240f90109304d76164188b4dd831f7d9769171d242591c409c0104a4060d76d3c35af7fc353c3cc13e8f996cf5ff32da4a6483a448df2033906e918775cbc6b314502bc9ab0a9a79a1ea363fd301d8476ea9ea2cf2802e0cccdfcf8a224bf1cc7130dbf4bd9161ba24aa421206507bf4bb5ef5a8c30ce961e57d39baf8040528ab0ef80d8d7b4021efbd43dc5ef6eb0454a61ad7952d49f5292ecb5633ec5da4900ce39f18c46d2ae1477027e541b3b6f40192256f263ce9ab4e74be840d2cd5bdf9863dfbd087f459f7dbf5817865aa6375f86adc23ec5073230f56a3360c7c156df0978f74461fa233de038ca5c028c0471f453fbb6f4b0f6fea44ac3164d7087a44be9db09e44d0050e20f8ef2f29d75a5b969825bd6bf7f46780b6ad069428577f5d57f6b266a2c119c5ea7d5a17ceebd7175be66b2f01eb4ba50f347e13d39b558f327377cca3ecd0c373cad48e6a475b6eb582d27b7fb25aea3eff3124cb88e5de2dfa4aea3823e5595d032c8bd2b9f29cb49dcdd4728e148223c39d859aec3ba783ea7622e166fd670b991aec33c97b37e2adb886fbe9182693490d39385fe645d982fbcd57ca24394f27dff52b19eab3dc75589dadfbf833c7888a7887455fea02db4613ec1ad85da704304f060187e3c817b3cc1e77aad0ea03155822e3037058d2ce643119d40d22ed0d227d2744208c28ccab6a59bb54acf4e604d22b0fdf0c926318075b9c60413cb73255dc11d539ba6352a27bcefc6fe73596af6ea49d2a9c67c8d203f5f107142d9032cd4318a19403de5fb89f9b064563f92350ebbf831eced4a3f37deaccbbc6cbab1667de2964a840348464a6ccd776e3916d2756ed8e5e9658d0bbb5ee8486c5fd6baa2c9d814d69770bfd23c75e73403eb01bca95100b78c82e3999353206b2f4f96a4dcd83c775bd936fc8d1bebe6be52f60aa6590971b0aede31b34d0fd4274df4a6265066b21a4830a124cc4c6fb6024a068da36d14f89659c8044a6420dbc2ca65b88ead3684c454cb9ec6a2f75eef5b6e9b90fec27d6aaf044fec5ad6b1aa955a7613937f0ee5dcf39fff237b257f5d59ebc5c6857d2bda8dede54de186a9e6a3e61339abf6068e0a0cb6eedc39917e4f065a92e3a15720597b63dbdc37cadec0dfbcf1cadcf5982614d1062d8bd52083f62d0a63c5002fd4d27732447a9507b861c936e56a794e8b054e1b00253770dcfe214fe9d709ca8d0970d426b9397e88b58821eda125d1c5d5e662f552db87ffa57e7f9252c26329d46cb0b3e41151f479413f740534924f91d69965d6565b9c40de0380287e4f26b29ef5e0873c3e2df93b21a4832fe854256795958963c28c1719374dea8f8edb20de51d1e7adb0e5e80b1617d227d59b103b7c1369c93747623f91f128f6b0d7ddd8116e96f40e5656f68cd6208c124829872b6deb6ea8c9e85d5fafda6ae986cfba199bf6c557c306aaf79c0097f22c1097fec2ea4db3e50d029d8ab3caf0c431efa31e8f7e943253fa30366d3a8f6dc9abbfc5667c95c7c6e35a3de64f36269e9ff5f65f7d3a3da1234a2605d083ea8a1487629506229e85da2ad32c6c97f4ed47f3f0d30620580909f408bcbbc5487f59e253acbc90e75bf2ff5a4938037c46e28a67034d72902dd7b1fe9f7f6951665500ff676bd36a49badb092047462bbebeb171eee6b2cdf8b61b6b31cd44a4ff490e8b73c037c5468a413e4999e240b985dedb027c5b154d3638bb9c2950fe530cda6c8a56ffa63a3bd2466f2f497b702bb2dfe106c106cc310fc9558d3a9811de52ad0401dc29f59f052f62d68d64de2a553230fe899f182fd3c863112f684c5fef0744f50428237fc8b39a9cbfb27b4851ed3b7e5a7a6dc313706001453afb584b1838692989dd961edc11d69ed02ae95ad874d272d430d5106ece3689ea0ae1583080d0220ba3af3f00ce92e8791cdc203f85fca737bb406ed29252914a0664398483ea768d11f4610f169a9f34bf590f4b58a70a28837a812ee9c3838a18734e6f030f536a13f8fd0f2c34b3f70b1b2afbe2277dfd1238c61a48791da4fc529efe422aa08c0c382b41ef5bc00dc9d5b7f5f597802e0cf54b54df0ce672cf6e60633ebacd32c4b455e4f2bc89aafea480bb6cbd6b907ebb073727edcfea02fc9c31776dd95a644d451a09389437511378450e989c6ab2437d3bafaa9ec43267e8545bba09496654ad4daf2d00a2f906484795538589e67f00e6caaad27a61de31b04a16b9b6176093a1cd12d5b2c55fe19bcb36f2d8e57590b7c48156cd4a5e2a453762b6446e39e4b6f91f30f38571b6220b3f6350affd1eeadb79288362ac8cfc264f14df041298b912f4d605564996bf8d8509a35eb1e5b408f65d0f79130c7ba987bd3fcb3dbbe188208df0d1d20627609230fb0e772bd7561ecfce8af16109b5d847037d457efe6e2d4b668945623fe8efca23398fd1b92d1dcd50480a04d9eae761d577047fe113997b7ebddf99ca4b1be477903b57fd23df73e247615c9f8e9248012531e23a8dbc1b9534cf164a9e146cd16cbe46f315b94b8ae6f75982accfd069dc584b7f853601ea3d6b943c2597406849d859f350a9fa571e834690a9a069f22ed8a6386e062b0eea97f7c2329979bae71aa659b1e8f62f8a45fd3f21dd42165929ce0716d4ea07e474812aafeb763dd49704260220dbbd5f8cb9b5f0334e2311f471324290708fe7a0feee27df07c8be1050efa047c0d1947c1e7a0350c2a03feac94b80a31ff9fdd093f5a4bd9b718a38e225b4d84711355ec35e3bfd90228f7839fc9b0784f20714f1b5579d8dd74e4957a5018bb342cb423b6d82342349ae321980a88e04539b08b1405b6f59ea75489da43dbc696aa390e7ca4e0d4e15f03e44140ad2d983e82a89a1039b81cec9684b6a271e549612a037299a817eb396363981399e7ebb01ce58fd362b0c3a108dd60632c6e1dd3c60d6d6424b5ee3458feb0645b57046f56cb3b192afbdfa931c3e97fa50ce11af54fb33b1e1263afd1cce66b840ade3f47576ab64f0999d27f7783a3c9d31a46343c380cf0dd80fc939f54e095aebd9b3272dab1cfa6736e849da8012fef613f0097ffbc5f0097ffb45f0097ffb71f884bffd187cc2df7e009ff00767f7eeee31ec1e065cca65f71018f717bf94bbd4c6ee5101be0d63b6332becc19eac5af984bce83d8ef473f7f7d996a697b7571aa63265d0533376093235da52cfcd4f47cf3432da334d0affb2d4e876b336faeb53f3c2fb0862eafdf0aeac35f9ce30c13667f93f2b1d8a3263f52af128264777570f3d01d64506153b2942ec21c8b6875e2ec6288b4a443f4702591af40cfcbb00aab12d2353de9ba79cd4e511c64448cbdc734040ff8b3ed70fc5fd5f38c1981734cf4a85f739e51b259bc3989694541491f03af76b25b38316a2c4ce4a13438aa095dc3018c954a833fd90a5086e94405f4ae97f1c2803ea80328200cae9f03789f050ce81cf2002578610f8c4789d06c6ac1e8265ba619173de7a97a28f7f4b73cd6914defae634f16fa641707f4e2ba2154fe1a49e9ba9627b2c7e0045b4be3c55b1cff0d682e914caef0be90e3eed007c9ae870d717d27785f201771f84f1e89f334ff799d022af67fd7c6ce1bc3fa75d9a023dbd90ae1758d2b058f954d70bc86b5646885f10eade95ae21e20f08be71e91de97a59fca76e4ff936a39df349aa4db14ee7d46991b6e81b082c20bdecfec58e6f5b8d7de55d5fb65f6efab17145dfaafbabbbd675bcdafe7eceb49d6866bd545fb2a1ae1e8d9efe690f40b954801e4b7ac3114da0b3487f4ca35b802da0c1a849b2dbcb8c87342b18617d6207ed45841144b5c79698c45df4a6bf60cb76499315eb7d17d15d15617171c74be8af0daa6b4c9851807f47915cc62430e51645a3901346fb13ded53bf7aa090d5dec0150295f521392d9a68ff2c0caad91a3acea2a8345ad7c6a2f38de77a8741806b4f627fde9d21f0fea4fca80fe9819d4cafaaf941be94d56f0a3714eb2e7ebbab0446302936da113a15c435c957bcdbb9054299faa04db7a75da968df19bcb374bb6b5ac8d5f57be4ef2ca8d37e7be55f6169e796343342383f219350a64e9127471d4825135cb6da815d169d44a5c5cb9c921f31a10417e4993d9ad64109d2df1a637ec93c2f7799f5e142ff25c5f2d2ec1bd72ad5e041cd509e0a6a5fa7c8188eeee024468b5f800466590eae5e7ca514ff839f809bfe67f6b914fc26990931423bdeb4ffad88e686017dc1ac49ea3163c1cf47ad6fcec7c9be7fa578de1c2aa4d4d3aa2a22c8dca70d9a83452aaf46f028a76f1d7772cd58663318ac6b8f3374d370df4a67e70d3244d8e365e66a2859a59db5e8a2b4b9bf0de4be7fd934fc211e1b8bd37d26bdf10b7757d9da7c38c6e1a83322b4dcb3b3dd7bbb99f1ccc6bbbcb856835db14ebe9e60a00c7fecdab38bd691fb8690883ad0954feede5b8d9268b5a91fcd27934facf3f1c1ec520c9d26f26db6e9ae87bffc07e3455d737e04fc1b14323576d6cc0714ba5c1115bdad37c5c5f0df95f6d0698a65656586df50804e955f4829f011ae915dc3843c805a53f669e5e65bce6f64a5f7939ee86a1da648a79f9bc22f9066ab91a4591617dc35164c2fd855de13b0fef64c5c40b581cb1a0ff2fe6f660e6b7f1238a1e451f430d396400fd4fd3dfcb8021f907bb3e4986d16f3e047af9648c36656017991798ecbdf3776121709e1f75dd3e21ddd85ed65ade84a2c217eea3987145fbaad6d54dac690b9cb71a71fa0d17ce76918336b49e86bcc32e0bfe6fada216d3fc5e9c58b69e8b13616ce8b873ac2fdc2c8ce44a96dcf8a4a50d5a10f3a7bfd28d1631db301de85428560894cbc16872a105a4b11272901ef73d00af9955f468935891e2bfde774da7b5cc5274c7f756511a95260745ce95a55443018c253a44d867f95abad929651b5280d564123d868d20073335b4ec18f04f49b7464a2c6afa853a8ffe2846253a26c32dcdc87e12b768fc98b77f4a7fbc00f1f30529ebf4058aa62a490180811e501e6db8c93d4f36b4b269e3c0ae3bbb6e96b4045bbc1d6ea9ab79115a67ecd2e96f102dc04ada8803707e5713b413463c0de721654ec93e1803aafdf89c2e989341e6db59897a094b36928ee6962eb62104b39aeac967ecbeebe97912a0585370b7e46615d90426db661a66d82d2d9082d3271ab9e7f1138d0826d8a248639d72a070ee83b83a9e147d6406f48d96715e7a4c1598a852132a261e71a36acf058e23552d124c8eea3f7df9475f9a82bcf66ef76d058eac3b810d103a36927200910de2589526a9da9a068a5b3aad12117acb57355fcb5c38ccdd18f942cbac1dd18c68fa0e8c0e100710a1ecd6192046dafc80ed8902f43e8902e161b5f7067bf3e4887711aeef518e4444a7c0992440a4809a82898ee500f68df383b4732f8834ed55f76be92f9ce1fc8c4b9a503d8a24dfcca27de9fea4c85d7fc1c20a66eda4f7f5f85362315e3664979233fb93c273e831dd41f46606a3adb3275afaa480ddd5be5354e10926bec779a0a5ce9df4b8f57256feac887e871ca7b7c9b0c4022ac51764398576b6eb21b43f4d6f75018ee23fbbdee24b9c993077a34bc1e53ee57a6b4925956801f9f1f4f50b6236310d588d4651a0711c081c370e8c962cdc43119241ef55b47f9d84d05a2f87a9abc635008ef3a8fe9c86b3d276ef56d006eea41fff269e6ebe00ac9213442df4ff90bc5c006c623dc4d822c944397e7c8e0be66c25d3ed1401e54502e5656ddd7d365185598d17c8a536ef75b4a40ef8aeeedceb78a56140faaac6e69be2bdbe736fd58e3d6afa2f4f88786956ac89240b40d99edd7715bc34db9ca7b8a7dd799275fa03cfbb9eb7144ee59171d81fabe8cfa410b2643592ad9216c51a54c7a77a9a21e0748cdcf795fe28c7db2d8d5ea7f355bc6c345f6baeaa345db5136999e4ac82fe8ccc5d85c7f5333de0cc40efe9f1e0da389ef657eaad8740a7a5259ea0565b056d5db495488ddc5901961564fa55657c00223d1ea823dfa804df0e8d6be35f2186806e18bdd38427f4543c07830bb104344a91446a4cb5498b85ef953be1d806bbd653ebc6f3ba7a24ed5fcae90b308771b623534bbf9a2462b4cae9d0f2c1f12e49ebb44642fb4e375b0094b44f9ce221fdf59f70a68acc89f9f83d0e5fb86bb5d9aeb7e500cab07320a688c9a9cd531e7b080ec45799724081b3e09623c3f433cb8cc286e6f8535baaa145c104bb01f9cc69e9c99e0f746790471dbe87f6ade3d6a3f55a0238726d0304d16fabaa3f00f6e54492753082d8a7a5efd4834a13bdb1d9437f81000cc910fbf31a061c379d03d0966edd02cbf22f8e2c617b3240bf8ddd6a1aa48c923ebaa35ea2af2280fe2803f4760213d9194c7f86c04567185c544588f41f31229661c4ca231940f41133a83c9604941fb930e52927a63cd220521eab17293f4ac395a7e422e8718a95a7c8c12db6dd2bdf27df2794a7ea071cb7202d4dce9eec2cfade017195b10ed0db2fe1aca66750a7ed97d36c378c1d224d3d40348f849a5c0fc22d4a4062576d91a66ea08f87796437a45c091a8043de037ba4d336dbe5cd9cff399f8fa4639f13d2f3f8b463c984f4b25663fb54c3a3f3d25126a03d3ea525f9d159275488cbceb1953ba735b9e3c0b254fd4cc320b4b0386bde82b1a3c48354ef8541fa419408cd64d443d9203f9ba589a05f53fa006009683e7b81791c378c4a47c1d9ecd5ea3e3a69ed0cde2a988cdeaf5499fe8015a5d1d21e406d710e46174a5309f3c4dbe9d62a591ba0bd7bc414310aa72f1c12ff68ad32af8de1e5338361db0280f2d86ce8c51a061399e09d6c6f00a86a5b8b29e74c1f14e4f1ee013b7d712d56f45ac92b457715b7ae196694a17d7a66279d2f09d64f170f5619ac6ad14903a0deb83898b0973692fe55322d462b7a3c5812b6f965efb8a23525eb29897990da29c614778b6e516496984ead97b2928df8b726baff02502497b42a524adae1bc2ca21df5e218316b12e3fec9450eff9422a7ff9aa25b55a6140c512e6f00689de1759ef228ac2485c9a96a4bc394c7a66389eef8ade99be38a35251d8af5255d34d902908d86f8441abb62237c1795dc1745c1b13089c5457de9f632e88108a3f4d35a3b7d61ad17ea2b472f23c6509f11fd886e16d1dd58ef41911b713ab31e40fa5a217ded14a2fa354435ac812b9215d715298a66c51a455b514a95716d4c663c9153659a8ed11b2f8faf5a7b0b205aab98148c6d19070a9a8bd26a894486f726049e6f77f7a4b101f1ec6a35e44087fffa22d89b1eae37b01dd14ad41b462ce67ba4873d2ae97bdee68e344bbf7cde46abd7c94ad617ad71f765a80f77eac5bfdb870df5e0b77df8d6fc47fbefb5dff93bed5f1f6effc2751bec45c7e020f458e9f09d0e9c68413014490cf65aaf59e82227d03fcd0cb2bd9f0e5e2cde508568e4686ba99770b46daf17fb27fb5ff74ff16fe668a3eb718a84fe334960be7481c337adc0e9ff4ad1ad32c6cdabe4f5d871ff35fe6dfeebfd6f73749270d44902ff14d1498a458a4edfcd302df2edaeb5559a824d1bec6e5a1bab37d82f9a275455b5b57163e3f6ed3e3c8de2d070c354c6922403ca7f925f4b9a2c47382b5bc8cf07281ffa075f97c4e69f53d49425e32968b717d59a6ad0178662109eb3caa57be8f90478794da5e5e55637148a0632f95502180fdcb6a1d8d3bd8abbb049d2c5ba48ef4ac354c334f309b3f93384cd1c8fc50b12fed6a3b5f57e21185abffcd298602c5b3b776d1883569684f521e2117af8faaff727a138880eec06fd19fd021637658cb08e31afb5df866a096b6063dddc38cacc34721cd94fd6b8391294339223ce338f7204f341168735a5b58435551a76d0c1ad12684d03eae6cc373b7919516322391c5d3929aa65d91e13f8f80edb4362e63b07b42535304e13a3382d73095a2b2fe356cbf37398cfa6acd77dc19271240d2dbb7bed063cab9c231623ee2843c48075d9fa514f14eb61bcc6458a26c0a78bb9b5178a044190cf93e81d4e184bbb71346ee4ca5c7240d42b1629c3c400ad2e2bbe57acc734a707b9151f17299df1933bee3c6033e760da7c87ffa297ce77da1f919932f230e45029c7f3e5233954ffcf473934bc767bbc168dfa48de64dd5d8f4e3df07bb5e3ffc3da11bf2a7c1d51b7cfc1c33c52d2364db31e08efe3b0f9cf950ef7b7d463ce9a707371bde7eb6128fa5f4c80cca5027629cc5def8653cffc3d8e374e471c9ff296ee53774e4d24cc91f0b4d7fc826851fac3b1108b3d981c6e958da322abd1fd56f32d0f0bae0dd398ec89d6471318b4228fd648f5165e3b280b298a61d15a2ad212e87300c42dfa1d893791063de7ac1ff28a34caa26e403fd7083e5a4a2734425fe7d17d83a752321b4487203d7ba244ca5231a07f944817ad41fdcdcf29ae57c44d787bcefae273735e82cf14cfd775f18827fd49fa44a82d13ba41897a8b964e7549a3487510414626b90091f3c7affa3358936bbbfffaee3cab85c4d0daaa7f23920c248394254a44bf44221fd417d5cf77cc6b9db25e591a829dfee6715e0605215e7e6cf37c1d8b6760cb386c39dce818dbdd53a2fef817d832e3044bb57481538cea4fb0b14e092781994bfe64d77fcc608e9db20ed1c704f0ca511e9981cd963d1da3d3fa384a9e7ff9bc6379d05d14f95f342e3472a3ac2d1d5a3bc9b45716cf961d5277daddebd409ad8fcba0ba1e491636fff8b961590cfaf5ff92c5c68f86252cab0941869bff136c8d7d78e46bda1f1df9619b38d520e98231fc0f286e9fef12e42b05f9d3449a218d255dfd910693bab328ace04f5999bed3c4f45fd13e8c403ffdb81ce83443ab49650847b9c531bebbaf8ac852bbf3b34ae1984de8c6872193df1341c8fef82ab259edf8aee701f2ad59a3b1b860151ffbfae55a5aa0d7feaff2ca95368453b78b6df20506a705faf2d097ad2c894d6066431a515af94fd34141bf97129a421b6d249e402719c29ac20d870d9276a17f89fae3d057318a07e597904f5ae7645dcd8391c61ee0bf5af4148131e6742b3de113f1498bb94d64130f16bfbd7bdd494bd1abfe77bc6f5190a6a216ce639ad5d0c4fb8ada3c1841b63b81608f8b77d1ee1dc9c6b660666eca8d64645fe5f70607e1ccb1c8bf059b57785d7f5c3c68b902e177b436e6be7dd8b26b1dbdd34fa6ffc8087d763f4cf9d147a08a6801bb52197361f3498bff3a7a825462b98456349aafd2729b447e195230e3f235eef9cce59f8bee14dd24e6f1d4214f5de17050d2fb14d9f1249de212530d51805f3360b455967ae09dfa4d1e57737acf152b2907568b1cbc4d565a8a68ca480eee86b8a0377037df46ccfbd0eefdaaf75dff9bcb6dd4650bf0d1d22ba19fd3900602499328502217a2e2f03d2c1f1517d549186d60924a1d0999a1485d9e67419cfab7f3db5d7776df2c68f3bd5377fa79a8ebf5b03e8a8a29b48a92560fa80694e3845131855651b81c17ccc98051310ba3620aada2b4d5dda71a54582059cf47c5304af15f9d6e75dc720e78c2a898f71186e6522d9c293e2413dc3345a9549829b468a650253c3a53cc480f6b3ecccde6c16d92dbd30cf4cf30d66a80f35da904208bcddc6549a09e7030423ad31d7d8c2d5bedf85fa2ef57ed3369446a6f9e2cad388fb5c178fa2c825434c248276b72297c172b1a31cdcde48494ca14af95fc6a38d23e4917d23f73ce5483f92b96dc4c2a1a15ed8c56f1b55b9f9036bd0822a02516e6899eb2d47073985bf3ce61b7853933689babd3caed26439bb5dc6e710e422fbce2ad53edc826481ba5edd01a49394f244df1f53b5ae61cf26b866c880cfb14c1210c720e034aa13d5ca57f085668ff0d473f2067ba395ad33392a3e48cdffa6b7c4daede41729abb5e63ebc87aa63ffd7e3d61fca6ba6ba96f3e327e531fad85fe8f262c0da8efce29488e337f41d608d34cd3e37ab4e737bf0d49226c6f991c6280f15df8c4d27c5279981c70dc760e4c6db20471b44d117ccb5eb9065986504638219625ec4d9904b8361eaed14b483bcb52e59707072949cb3a4c63698096a89a5c35f414f61a050b9f294dcbb65cb287bbfd58198fa3d4e1de89acb9278735a15df9ab82ee7c884e63629a6f6c01e9173bbe6c0f371f36cb0f70fbc37d96039c3d7860ec2bbb5fdef56debe5a6a3869982bc80f485c68b0c0fa97928e07dcd7288b3f3a388f9964af8b6b3f221e5e18d8b3e32702b2805c9a213329060b212bd3072954d76c700ac5986d78a1d13e6f7cb0fa1bde3f92a268eaf1fced5f74d163d2543f12e58dc3df36bab490ce6f645df9fd92578462b443365b0e4e9afad4cd7e0b4f6a9ade11d7c0958beeaf5b3197846d9d655abcfa686377eb92391318708f4a75232191e2376bc13f79022762f1678a5a7e43380a582df4b3b6911559100d797688a36e43b645fe85ba0edd6462676e3f4eb97c18179ba5b251b26e41575a2dde006bcd956054b441026708704446ee9c6ab1a60fc230122fa672926fa84009464a3887a7d1ea07dd10efd468220fffdeefe310d03a9f6ff7f5af834aff8ab82f98c36a0b4dad483cf86b81c6f5d1e3830cfec74b732fba56e7cf7fcd910f35963f5ff4bdc9fda96a72f6b15cd96e02f74bc3c57146e84767514286b9ced71533ddbe0548bb417003ac5b6b02bb1ddd8b4a20949d851837e9611f33997395d5f2f06e69cfcfa9279315a3adf29d9369d7e518dcd16c7c594245b4789c1819c03e7f475e741716d02935dcc43ef3bc741bfe714b30410b9f359228b80dea0033e4994476bd404ca0ff4100326e7d0ad44eb81d2895a47bef341e67464f5018ea0fa673b166c1c0c24bb06cb4cf46231d069678b5dea6d3608b9dbd987f02fb1bb5bc99cb5c536fcee58a0fe4dbd743bd7b2711dc678e8eb1e0cdeee2d499ea8c5420ee4d0d94efcf7f75bdc94644e772cc81ae8b44f65e44a6e9fb8b56025a60d8df59b7768dee4855692e867075c63742a7afb779895ecee45a7dae8e4fbb8952c7c403372ace0baff593882e41d9c9188ea7a069f79afd306e11e2238c7aafb0310aeefba1dcd4409d7bfecfbf6fee52ec9ede0b61f3ba0d7689ed6c4ca309cf2f81a673d80a82c8d32c9c1ac267d1d098adbf8b9c5636dcbb6f837cadf90bce9c59de25b84d366e403cf6cc48bb357cf349419db6c7aad4e845f53e298b8d6aaf4ecc4fb93ced47cd99add4e492270374e7466625bb3084252300ec02e6c8390d7718a2cc569aa793465527130709e9b4b198c20fa1afd130910348ae6a834180942e8e86b684d0e5aeb47b072387c9a3d791cfe6a8485250d805e4c82cca49335d1068996d6920051d9cbd1c792a564b811e2f1284b638d723093c3c36859c96e093dea9227ed28f766255904ed75692c7dabdcc3318ab8837a0e7dce0e965884435fbf78a28d1ea5c168b044e41857f72bc28de6cac9a5fc1ba2b713f7b1f12939f8c2ce8d231c9150ed4c836383ebd78dd229eed38cd77fd54eb00d97d3afb8c07069e92fbf6acfd43c63cfaef9a39d95d448745ac7844b5d65ab59d338100de99640ba1dbe755dac298c4b8f03666d28848c90d0e24b6359895ae278f252d3a1f813e7e9174940684fd6c8b4d428c89d12a7549a4cbf44405e7d8d4712a56a25de299ee22f58f423a907210e92f6b8349abe510e39d621a1b16e4fe877900e7977a3bbbfa8978c5606611791347109875c83e597aed5c2f6b0507d3c1c6d827940cdf003b7f77a104b72959eefe301a5bf43cd3e276c5b9a3cdf46206b80ff67cad41f3e7d50aa7697ce7eac34ebdf11fe17872299e413c441423bc51f6207d2e45adbfbda335cbb0ce4286a15b6a8be6ed36bc4509e511a2f5e6620aa15c9e8fd4ceb33ef598d24a0250d8021f5175c83ba1624d71a5bcb6a4672a2fd926d42fa99a639dee83ce1d4ae69f767f69d6c3cdb7aa13dbae95e98ba93f709ea0f6626461ba699fea7c2e989a9c6808e315b1e5e89f573305acecf9fe42ae7bcd8f2867254c6bdff93fc0003b9a5255abaa807102a2eef03e70775b621887f906518e84f24e25f56eb54dd83e8aec509d3bf545d9e3aae85dbae97d5dfdc421ebdf2605d29f72c6f2e45255c9b53c87731d07b8fa74f7b29dc58b67a076d21d07c9ffa9130f6a7510fa0e68cc0dafd5011475b7bc42fabad46d720e7e14fbebc974ef81a70341d70eee59eff228b86e8ac208b3080d680f8f3bf9e7174800d302a8e8a3fb8f6e8b4c76dfd490786fbf52fb20003acf46b82bf61b609d2b2c48ef98435210e571a368580235e1a7eb6562fc1fdb0fc48a210b769c7201f31247249377e4f058ee8f21cb72b06f89527e10cb686ff899e324a85f99dc67ca88cfb634e5af4f524086e9d668051bf30f757a49fb48435e93f22c161c39cbf3ff5c6f4ad53d64f5a13f137497b76d1a456849762e200bfaa854e99859b10afee858223f272745aae7c31ef191d582cac115cc34a79b8c3a6b3460e8e2b0f4d9cb683af615ce43e658f95224f6caab99291172298d414defffab21d7960d35a4f1866093e58cd95b9ab2f0a50042dd46fe07d30990cfa607b910fb58efeef3e58d0f78ffb60b250e88371f56faefaef3e58f285ffe483d59cffcf3e58cde7c33ed8a3e754641c5f679a8e1aa71a2b052f33b5cdbd129a7c87f3d8f8feb6fe06ee861baef1d6301c68791cae79082eb96d043ec76ff0fd3c84af6504beebbfc1f7d310bea611f8aefd06df8f43f8ae8fc0f7b3fe1a01d05a82a49d1d8806b9daa9067af78078570ca10dbcb205047ed70cac57ba81b54183b183dda4f5521dc83553afdfc702c788007bff3e16fdf66cb90dd03b7e11edd3300b69c68ecf345532478d7cabccb560a340d18fc3ad967eaf5b18b8e28c9a968c46a7e4ff8cf6b3de961e2dd21f9702a87ff30e5baa886ea0af2340e0133300415415d66155ad1f01742ada71ae79808abd37486d7912509b28c0fa3d05bcdae8bda371733c3dba01ed7083069c89a7c735006bd10ecc7a6547ccd1c28083d622297c97c65cb2eb26d5d91da6d103270a9547fcb061edb9f0e4d6a6f18d6502e5a99f09dc3a441171c07df21ac6b902b77273bc10aff63811af688c0a841ce239b50550033ca7223739c03ec82d17d69f4368ab9c6900f18a252270c439e853c9cee02cb111276269e2cc237c23be73f30dd40ff32da8168b652fd9d4e6bac7b946412e1cb6d032917866a1fe2902dd31da331354310d20f2f227e81e51561d08344a8043d33230c25e780ff7b7f9bcd0dfbd23fb3badf0397be60c382b2657e0313e320d3a6b37cd20442dbec18c3b52a588ac07d959136b2df57f45762c86ee41f092a6e1b65a64423b12415a0bca929f5f82eaa213974a5bc59aec2cf90c0fb46e15939d155a67b171e729628ba0bdfc771a6f87a32da210d3a05e553f5869c07db3e5d86e2fcdf25d42ccfad0e67a805b4da4b43aa91b8fd28c415c0cb9918c4ef4572575e17353221b2af02a57055ed488694a9a782b8a6c33531be33395a12459121d3a33fd35b7befc625932ead370df8623b4fa127784c668e9db158095878228e84d47172a62b8b5bd5a84357309c4aca5ef56000fc2068161f41e0be7849c80faa25842b3cd5a748e87599ebe4563143413bc05231fb14ee3c1f054942ec0e2e5fb21d744225f4a0abca9a444353b2e0ccabc0a9480bd7bce1496ccd51f24faa82d3d98f5b209637656ef2907552de3b089a4b2f4529f075900665af461649fb5c1823139d5b00397f29441ae3e22cc315ef270a709d346117f5834317ed762769c0a54ee51969e18bd2b9650e5c3fa273c1d7ef503e5c9fced1e8aecc02b4df4ba0ae835778cc95c42afb6e1d97ef20ab452a8f2e8d59d2c2c8ab149fa40ff388471275969d9925774cecd09e8c1e1f49d0ac9f01ad1c2a6171a11a6a986fe247a8d4dcc925924369f7ebb1baf344479fc61112b03a24042c671f75b4b492c1777ec35015a5a88622e52e0988b98ec98f074ff881d996e9d7678f5165f17cda035a77eee84f33de8ad502612b74980673039d3a20c82febbc5044eee91a5c154300994212440f72544da34b59fc346004f4ae22d46bc39bc07ad9a112ac7f8fa01426bb9006556d712cdee69005124f09c69b14982201e6e654d02e6a2b8d972410a58e3eae7294990f8844517af3c02f11f83fe5f582de9d87b6100d5807ebd64a6e5c5585d58f1d9fea8e641260d4a70d6bd0a6d04e299b7986eaec0918f654d5a02c693272d3bc92815f03c096589894763bd240fdda11ce632ac71b302e07e50e23cb7e9a20b3d876491eb3b1924ae323971e4bfc8ebd15a8c495b697907e2dd05c34e0e663a65d18ae845a4c7d3e9923e74b326a163613baa7b6fb23a02f18d2a6800330ba2c820106c898b154d26812e84da23c6b17728bf3028410573b1c9ba30df73149925dd14a58dd894268e70b7cbb7a9551fe5da2ca265f53bd2a636e196b2541bc4175d1057732f431c61463cd871af828cd8b47b7e843228041bbe79339541376fa6c2b1ecd4d2372a46e382049221db74b3a0fe31e693966c531419b748f1975eebd55ccf9fb2b350ea652ef5ec50ca5ae807baadfd36772a14dcb6d60da56680abd64fedee94069cb67e3354b604cd58fd4b864a5351fae192a1f22d28ed7a7ea89cbbb577f7f9a1f24294fea570a8fc004adb0b6d3649dca29f976566580b8fc3feb8b6f7e65dcdfdfcc7ec2c3edf5a5807d01eee6d9b3b7d096ccba8b3bb53cd203de38ba1b26eb032e39ba132028bc9f861a8cc0fc3325287ca42b128b26f3075a874064cdf1f5c3954ae81e98ec19543e54b60ba71f0c050792a4cd70c1e182adf02d35983ef0f9533300d06df1f2a2f44e981d0a1f20328dd173adc2b946e9c68e722fdd60adc3dbe5aaf91e38ba04be211a64c39c28978b5eb0292740ecf63259f5fb8cae12f4978acc6c55e6e5414499ca434d40aa991b28152c3b28152c3b28152c3b281528fc80687f5d9860ff9917f04ebcb8f607df911ac2f3f8215a578895932542ab432542e48d850392f51cff33c4d7c4ca22eb79de6f31f93a8c447242af111894a7c44a2121f91a8c447242af131894a1c92a0a1725e82560e950b123454ce4bd081a1725e42de1f2ae725f4fda1725ec24287ca05091b2a3f8ed2f7270e950b1236c43d5e7f8b4fbbd3bcfe161f8ff161a0378056ed057fe5e3c91a61eff9c96006dd30d069dc770cf6db58b40ae4a890209f27900c1dbcaaa51b9d38da957282a87a15089567e6118e28ed15909937c1519cb3cf397407f71bf79708782942ab378a862f6cee14897d611f7ac7afda902d6fd3d2ce8ab021dbd7ccebc690e55b9c6b46d2d66cfd224ff11dd20a3e779f19c919ebcae86bb60de770fd77fcc0f1a7e485cc0ce8af92ae2791d4f5e67d9157f2ada0157f3d6dae455af28bc6ee4e233985753b602bbface5ebaf386d46f2c620791bc3d5bf166373972089d340896be6724e9b4b5620498a223b07bbf9d1f82b778fc7457640bdf94518e115282fe6119c3f5f9bc195a19228121bfc99c39329bf24d480e38b212d6778edbfd6cf8ded9cd861ec53cedd3e8e604fcdfd2df653677b8f8fc47e6aee48eca7e2511e2a432d101857e342fa6977d9c896ff79e1f9e3a8e5b7b4c32dafaf6738d8bef8dfb6dc7721fff4c896fbe247b6dcf718f6f60b1338ec73168ce8d767329e9284980c948b30a316382a2f5eade6a8893deb57bbb536bf1be2587fee8b2a3e0fb574565ecbf22331473b0c33a53eb31ac95cbe966e479e052f73a6f3c33287244c383fe44768f837252ed35cb543cf19174a7ca3ea7661d0233f38f2fccac226e82113dd1ea15f98b534e8f6e4bef0331fd3f03b4741e72bcd090cff9e7cae9259289c5b2d9dcfed18f23b54b5958c1b06e82b0dc16ef89a4ae411f2f0f17c5ecd4758e8a3fbfa36d857d121133068b3b4d4b65e60fd3e0eb05d5d2242c688035ffc003cb303514d8811ddc76d3c743d38afadf90d34b4dd62a815f3bcb498c6da5081e5e638729cf785b92b03c60b75a4fbab11b74493c598781e98e7c6815a42789ed98185225c8418b361021ff7dfe62c4b7bc51437e7558779ce234b13dcc8f3df1d858dbcf714db476846a6456d324d1d4fe52226877e9b0cc334d71bdc7708158b904f686d9083dc1c4615b9a41b60a11b6c68fc043ffb3eea7dc95f4fe7e4960ee796f6f0b9d6062db83a023aa8db9d4f62bd23f24befb9f3ebc172fb08f85fb9fcc5d68628b00fb63f7b49373e6324be0e77791aa81b89ef8e3bdf02aedb08c1a226ffe86ec504747699900b7e40b97db148ca030eba734b1bf85c4429a342e7059eb7b9cb1a2fa1b253da5e6ee40f2ea0b6748f2142ad723f80a42210ca049c95b892c0250cf842b8e15cd384f27efe2b8a57326deed51d3e0f51d46c73dfa273e791d83776f7ea0e478df6ba3bddc8a73bdde95ff834c48399edeebed7032647f715a6c9af17faf43316cae3be6e776b5ddd1074c363d0353ff0d0a7623fb6fd16daf91874e36537b4dfefe0763d060dbe77434f1e01ed7e3b5435c2727ccbc7fbdab53b62d1a9427714740f460fd9597c597dda8ed86813d1cc59b817ac0d2ad85afe5766ade5045abfed49e1f351047eea5b29c48260a2204cf1b95cc84194d2c254db2f0c1c517d1ac1ad4f0cafbda6e94f5ad0b74a4ab468e4d81e17a0f35b70bee5b4e492589dca5caf585b7c4eba21dbe29eb1f7e5f8681d7b9d038a95fd0dd2d4661bee47255dc284f5d3bfebb4b30ae9c27a10c890203bcb77e595042267cb4f0573d1e972fe54f917420dd48ab2945cc6d7ac7b4358fb583aabb0281653a173253b62b150c8174254df3d287a8a00fab07918db23c19b07309532a81514c1989de3c3872d2f76dad0f762ace21383e88e7fb839b8239011835c2ddd5d815bf6a05348615b2909186329e4d6ddff2eac77e9792b99958b95166a69ff1e1cda646b8f98af61dc424922841a9a3785fdf72cc1d6eec44aa11d2fec11b0c76fa6241b0558e675be4f4ca6701ac08495ce6c9ada08713739bd71b9b0ee1d8ab1d196008d28ce6d25c12fd9a97800b5f4076cf692e378d9ea40dfe9a06ca335a90e50f75d6302f7d4039b6b0cc87cdb62e1eaa74517eba36460b6a44e1d98180f4415f51e986a9b5559eef4e0df978f787f867bd71fa8f7a0327ac6048e8b07ba50b6590394e5362ed7671fd2745d6877319f438ed285f6162b0fda3c3ed7224842fa79bdb28cc48ace45467d0d02e52aa0c953965678c6e429cbe114adba527f45cb7db1464565b85c57ea8b1660aa746bd16757e058a27b8457606cbc5b5454cf9f86e17926a1294996b7c0df549e679a75c26dc0cd58696a287fcecab114f76387642cf4a5e842c54ae5619b94fbda8b9cc0d12a19334fc7ca3f8191b6f4e017f43e3f922d84325e84ce644d5a72b848542505fa49b14037896d9d0494c114c64ab3f0aa1d72d1d922e5479f00e5a92b00d2825799eaf140f17170928994dc07d26f8399694d82fffb2078359c67b95d9be6cf8473690ff81361eef360fbbbccf31cfbfc1e0eb7bde6b947dbf67fbced23b0ed6357008a94c153beb1d6cb3dd8ed01452cf26c3ecd53706b1c313e5e9aa155ec539dc84a04a1b9c2066b14fd6fedd62d799933e6fac5e42fcdddf15591963b990dc7023dafd41768a3c8dec14c79efdb05f5df6bb7e4c1515ac0957c869e2af82c5ab00d8e5211972afa0ccd9cc2aa1fa78dceae9316425be4e0fb77ae869f7fa70ad141d0b3c2de1023fb54b0c209829def1b5e2545a78004ddeea07c6780326871244d4367774f0b36f06e9905ad1509b607a6507d94c39f8f0e6b4a68e4f6fd843b8a208e8554ca6d9c5fd61e6d61e27d1d7caae266b4c59fae34d04f3600f931f4c528c3ade8026972409d40f572658478e84469560f5af54d60ca52f0b5fc0e5370238f47d582a80db62846505b7a54a0cff1287da309815f8e4acb0e3a724629ba9f4f423f3649d1ecffa9e2b6a213dd32cfce52a416bd52d25cd456f48aa773d72dc5ca1d9d0ca9b80eed64aaff5a457ad14d5f67411acd96832267110d6be099f222c70e1aea0bb7aa66acd069679aa01553ef5a45ef3d00b2e52b353ab6ca548147122e889d515d9738d8fa012435c23adc07c335f26fa355e1ebf16895eea4658703adca293f22015a23e46abe57dfa7d37e6147bb8398f67fa29a3d318893db938ceaf644b9fd0f61af1ed92d44238346058dcea6c9eacefe2437ec69873b862ced9a70dd7d8612b864b787ce53f60ab2f2501f9505f0dd8ad44207a355342b9f0ac574716ea82c171a9f30065fcbaf5dfbafed7fd131563508f9d6dc66ef7ff10b9b70e3bdf3d13bf18d5d6e0ca5ed01754377fc9f425f9819e921ea3bf99d0d74aaf45e88ba53a0b373e8ab34adc3d407dd1aa61edc11fcaebb6eeacd7711f5e291a74479ca6ef9afa50b9b00a2f8926da8fe4dcb79384286b89d2529fd8343bdbdb5a177f80cbf7b2736a1b1d280b82bf06be83b0ce09770834fdbd01ab06023d42d8a35b4bc1757a4f4cb154df4bc0ed86b31ec3dfc41b947b4e16bc39811f45d1f3a972e7c4923e8469b5dbe07ed5fac1e8bcee008769712bcf3a04d68b79d97f713fd4ba24d878dff2a6ff0d48571bbd60fbe8f2dbcc168910e2927bb8e71b37c45fd316ecf19bd7f481e45725582665bc0847179071a8e0abbed366e3ffe0806321319cdcbb168b71dedf61e35fd4be51ade6d8f2d74c88f23fcc70f734fd5a5c35c6dce1790fc13edb6676749b574713960780fe1839e7feaa03fd49f74dd8ebe41caef2407376e4223ce9f234ee36765ed3f4a684a3e1dc67c272d3e6968cd19cb2f4b46dfacbb12ab7b074fc1e54bf298d550179f8a5c72092f889d5548c11908638bce61f957623f39c75b3c49136a45188fea11df6578fed1b2c653b26661e4e911503739a8212e9b4afb13673e72a2a1484bcb5bc43fc7069a5c8372d4bf909677d1597edea76a78977b569225433c2d234b3030dc6ef271bfe611edfd7508ee303a41f0a88e6fb1f3b302aa2dc0bf8ba2d9f0f6a9add39a366d1447b8a511ed7b95a5cd4dbbb19a971e63b7b05fde6369e46c7d53e612213a6de367b6a16f453a396b2e47a739554ba3a1cdf5200a68bef7aa8f8a5b2a2d994965c9451c77a16db7f8bf06ff6bfb6dcbd38d4d658dfc79b765ade816fe8aa6558dee7bec35d7c37304dada28dfd9c2dc52915b6629a22d1fa39dfbb61ccb7819da775f4c90458e489319f8d27481c45719a1c28a68e8df8d7709dfff00575971966795b8100fdfa95be0f7ece58230861925b4f33e6b30e08ea29c4108835789f7e27205ec89e7ae344b20c49e336afd688fb092556e3d7db7dcbac26d51de95fbc9d0fee0ab61c2b7b9c03e3ea72ec39dd368e5730ea4bb736af65ae4dc79dbf86fe19c69c2f854457cf45e65c41b98309f66a35e8a669809d43361fee5f2e84d1560878325b3e0acd18dc3a7274b9841e4a887f8b2c244779bee678330df65a159fbe3fa85058ae48f5ed34799093add2596a494273f7ac60e5fbf52b02afaabc2bee15ba8e67197823ec6d5735c6fe841dc3d64ffed093d543b3b0b7d5f047d5b049d9045a730467e5f44d0a8f3686616f0ff0de1a7df21c7b3e343851136155e867a1b6e0ef494436d3061f4584f09cfa3b4c8489309f8d3670cfe34718e4915e4f412cb145608fee797421bdff2d2a8fd13fafa50b0a580f6a6773bf8364daffa3a102739cef223f29d057a1aac2125b7caf42256126b0980ad99cd53e59510a7c7ce549d0a7b8e5ed787b39e50863c8b45722817d4a89c70cb3f00fabee09a2a722708b69659a31bf551a340097dc071b9a03fa9a42678af3eca03b0d0333df51a9ab7e19b67a4ec073cba7861b17ea60c4009bdd70088e778bac8b468383ef9e788e7d0098f75ccef7f8b049df7e05a794d7fda84e9cb7301bde56770b9a0a066be9d6572c15466aadbe7cdd09ff022ca52751729c64b24d8c92d65a9a2e3b984fec42840779503e5917f00b72cad2e5c58c84335a667a7e94fe412bbe939af3a9c3dbf12cf85da84f14a449cc39e43bc3b645b9a7eb1d5d855d651defe65d3b78d897dcbeeafe85ad5b1ba7d5debabee9b7807a800f758932f5e449acbdbe99788fae86246ab8ce805e81b402d29f16bcbd74ad6dd7863ee9b656fe26fdd583f7743d906f455a08b16cb07686c429e43de5aa42904f3a51574e5ce8255a736d1371b8094f6a461cc26ecd037eea6a09e471a76e202bd0b234d2a4c340b7aa6dc98cef7615e89de05c7115f9823df0747d7ebc3236cce3f3eb6c077367743659564afa8ca64045f424a27d617a5c5886716f8a72d2c2872d2be50f2d28a9c682507695d95e9017eb160557124518947172e2b54a496bc56d2a88c988f9524c3be7aa0952fe52c578a978d0ef000eb8cd79857dd5ec2c1ccf12beddc1c316c7d59e883f271a5a6126a44f16702fdcf4417faaf9cb39d21e70c2a56f2967cd8ee96e6b96b69e7a25a85e78475815928c63ab53dff3354b75f8eea9eda5eecd8942c8e403f1ecff274f4bd13f4f5136481f92fa01cced9141e043297b24b35226ae9a780ededdd8e85476e3b04d865dd223a4b86ce356ea7737b71463b5a764d8eee27b0e6801a6c812e2ef4204dc8a4ee9bfaa5d958a895640659d9d7359101bda0ca7c48dd66a74999849543bcb28eed5e0b6ae31c75641fdbb04094f9e29fb258976b7be4e6cd18fbd343d1c7f5146a47ef9410dad1e215f2a5bb5893bc06d3b2e3fe007e78bbcadcabee1ff7b136f2c21b18ddd2201162d0a29d92c37b4ae61eb6649b74f38905a76da815d9827d36af4f86be4bb88da72ad2b70b9d86ac31e76db1c93e67e5e701fd2589be73b2dd4b5b1bb7d6aed312dae7ed282dd3a6dbf8fce76d949f01d0af9bbdfb0374f1d48b045ef59219ef4fd2b16d79ba772233ccf8052612c685c8c7a0df22b1700bcbdc1fa4d32aa0869218cbb40e865b22493226f225131e9961c2ab8ca4889593f85c13ddd7002a2d1409a19d10babb015aaed641985340e085794b7755457580e59003bd7fa697748ca6323603af73322dba7b458b6f7a7a69e9d1373d687f0f406574a1b344a206e023a6e49b017f2fef86bc5f9e096bcbd414d9b8dd2b8bfeab0b98619d07d25c2d2d7920a5090f69e68b2c2c639b5e04994bd038fc49b732f75b39e5db235a9e1b935b5cb3a9d417fc8733d9e37aa1a40480bad389c604c33213c2ec422b37b8cb97d13ac6b9bab038a26c85b1d9c6361900168778996e27e216fa62f15eda4fed1307268af3ed937fbc6d9f31c0977e684f1d60ec8476df2d76eb66106cda7756e8eba89b52d857d14d69b009e914bb15f656431b4e406ec581952ca595032287d05491dd6a686945f4d91e295ac742377fccef55257e00d0a8474ecf024b76b19087b9e7cc3c5ee28118d23be6018e78c8f23cd4231eb27238de57481c416171b0373879876d0a019da7834d310f28d200d6da824d4bbfbd6adff660a2f853fb4ad80baf2c9dd6319abc49b97c41adddab4668037b80c336c807c02f8e967800222ea034346ec3805716c2a7d3ae3d1e1ab7e5c16d1be20be201165f1bb7eff470eac3e3bfafadf7a0b6f6bf48416dfd7716b5ad77bb2ebc6d17bb146aea181927cdf428a4a96f8bafc9afeea264484fb104bf83b5e787eebccee3f581825a5a5500b9c3dd933c7d9eb59c0714a7a331098efadfd7d1f73fe374d4f0fb3a7ad10235541379611b46ed9003baf9928785415a7a60e5b09662504b193bc569e981115ada18fdb8966ef88d96c624ace4b474bea0a56b052d9d3f82873109bf27cdb4d8036c0a1aff1fe439330963d9cb629c5d22c67b776ddb154914e0910623d4d61378155388b350efcb0a0f17d0dd06406871f9c93d992f62bb235d06b0321797875b285f0bd0ed4652b69c3d511093572e8e6c6a029c362e23a56c922f2076405d26efff995ed4e1e1d665f455153aefa604cab7f9a6842efa2fba4c4a055d762c72fd0a35cecc49b0ee8198cef210f3ba4cad5b0664b685c6305e2709d758a4edaeb1508ac7baee63714f733a19bd639ffdb95f278ab7d99fbf76dbbeed575e03bfb1a50e6c784c03390a73380dd4731a58fcff8d067278198efe3ca88145bfaf81088ad3402979835a170e428fff170d14938d54c6784103b936749c069a380d348ed440844fa7fda19ad7409e03d7ab86a5684bf53d15d4b2242a096a999eca706d67258d7f6ecbcbcca72fb400e2eebe5b281a9ad0067363e88b2d38138fa9be1d471111b197f202f605920d3591972a00da55c742cd5f31da4da572b4daa3c53457edb5dadbf097b9a4dbe68e69bdbea07c6144ba7b68d562341ccd58f37b1419113b9b70a9237d3f0054b76b7b7fd2bff599bb5ef08bc91dfa0a419c4e7bd536bca2b398201a11e536320b042edd82f5cbdbf2a08d18a353595fecc6282200500590b35b9ac760bb7dea2842f6d456b14eab2ba5c7ca70a8599f0fad7548ace412411777cf9acd54c0797c624d14a906bd798466a11fba6bb9553c7fd73b2445746ca7b6746fa7e41a51e612a47503be4b7335b9c5e7509ff995117e9d0e41a2f9354b1499d40d65dd3526c0715ddefd9082923221af0ae6c9196e5f21b892db879c4d54a8d13784d197c0310d7feb476411fccaafd01a5b8c8f4e23ac2071abf6ea52619dfdd00e7ace86fc73d916d89f64ceff4ac47cf8b2b4cae05679015a638cab9cb00badd67819ce187c9a86d770327d59f974500e7dab6c4bb3cd5d4f5eeeaeb7f900aa87d636bd0cbab86833bdc780f330aa0f7888900f26ec12cade333cc203d6321d5c84981971b6e5ba6d64ea07fb8474743fe24cd3d42efe8e84e0d7d594d0d3bdc38dbb5e896624edeefbafea513792d17d01c53af42d3bfe3be8c3df459f6628beab0c91004cf3fbf64e5f418c3a6ce6bef1b982148b9e9680ca9d997fd14f3703fd6c19c012cc59ba102be901e8af2c40b166a7384686be07286eededc334dcca5488182cb7b1f27070cdb22b76a13151d8cdae791f0b253c1c546a7fe692eb76cb112efa68e8b55118f69372ba4f88724e7eb0f2a9894ae5f43f29954fad9c78d830cd3c334719a10b5146c42895739e9fa89c9e3e11a627b60cde7c78c75569164ec9c728564633671a798cc967c25bb3dbb26fd33b65405f2123f29d0b19be24e8e294004238fd92d5adaf106ef2370cddce67c41ec20dde537acb635f392dea02a886f095d3835d1ea8defb39c5e74ad6bfef2847bbfa355c9c54e3f5e9ff89b966dd922901c2fbedfea4e876dd41043759cbf65460f4be1689c81282d1f34989086221727c6e3d8e21e8d43086a0b61f8d09c6f2a13305357f096fd7437e89a66321ab52f5d3754ad1d39852ffb42e58340b0bd6cfd24d14cdc626ea67eb824473b0a081b756649ec984dc0fcdce2a197ba633bb37fb129610bd2bbb3dbb156fc4fbb29bf0f60403452ec2f55a31283e475b9dd26a8f901834a37c99a18c988229a7bf8c5db69ce93d9c14e389be4f77f2d23e2d7dd50976fb7034f1d6ea0a4d112f529ed8b81b69d5a6242cba9dc3e678cd1b3cc792be603f8979f42fc73bb0b8430b429fd35f24017f2b8d95941294a414b79a3c06024d2470dc6a89cb96cb4ddcfec0afbd689f33169d1b20c4b9b685c2773582262a52a1243409b2b52fbccf5d92f5a4626d74e38d8cdc73d969c55fa13b2bbaafa814b11a0bc10eeab59d1e6627fab6fe7eb2d3a32cedb81d7d9beeaa4daf1a05268e8aee70349003e8065d74079512077ad1f7e4f11fecc1696569fa04123024fdee455c347514a42b07b0e346e3f4771290b9c2ea351accca896ed2d867bf5d2d6248fd45d760b5d71d60653cfaa79a1c5b4f0f4437f9d974cfd5c1d6c4d203f6b234bc03cfb0eef4e867c8d9a65bf86cd34d80eaccea083479f43b36dd1ea8859006f0b1ad2c4d548f66d02c09edef026569b07e1043426c0893f899a1f21aa11c95c112dc0795634f43fa73407417ea1de2bdd2b37334b680790ed362cfe916e89ea564ba31278df4621b76c7288aeff4b09a2420fa3e76c18aeecadd67b786009473a643577f36c3ac82391971d2335d1fdfcdce38bbb5dad8a0a6977d2dae9d27df01c7492abdbf6fe1e125ca084f6ce1d640c60f5432d4184fccf1d59549cae93f83a37b4ef4565eda17ffc62efaeb729c979993f785f5976301b5af79abc3e23390e4e8211d87ceb2924e0f65c4cf808947b5bfdc1ae3c9484ef41e4e44dfff3b0af1d05f5f780c4bf21184a571228fc598f1fe39df0084c13c84c1fc9f30740896f49f0843cd040987a13c83950029bdbb4132b2b731f3fe9ff6de04ae896bfd1f3e936d121605230404351871a1ad55e3be50628188556aad806b0b0e8b581565116d4bcb164258448c8a8a0b5ab77a7bfdb5a61a2b95c50db555ab15b0b65a34026ad5caad082890f739331308a35deef2fe7f9ff7ffdee1f3e599b36fcf9c6532df73b64e3e1054a0a5df9fdf550c6d45b8ac812bf66bf4dda0b493aff6b12eed0aebd2b2a9d4ecc6a984ca9854c693461535ab868e774830136fd46d1c6fa1d019723d24432ac4f1de71578cb88f46151c6d3950d95bed9543bd63ecf2e42517e158510f1ca77e85c02130d15420723f10a25cfd00e1a7173fb18a115f13ff68c1cfadcace74a97e4297f05be8f0dd70f818b46c1cd61ea23fa33dfa44016ffd45fe785b44f9daa21807790fcc24c4cf8fd23654a5512785509a07eff7d34ae31f3711fda9beb62b4dc9f662a19ada5abf12e27480f0c4dddfe0bf20a582ef668b9694c2bd1cee6d6d519291ff922d8a30ea13d3d1b18a89b6d20f6ccd7ad296009d1d6d8b4aeea68dce46250f32252c4ffd86d78f309beddb28088c7818814f5563ce7d2afb840a66f88d38577a729940a6a3f9f167a9aa1082b9979c65f247bc910bfa9fb2973fd21631e563e605353bf6df3df06076a9464d3937f21e465155e40b621c7cca743de419737ff7649251ffec691bfd0dbbfe99187a15be42dc6023251d44981b40a5dfc34faef0136c17de1fee878aa07eae195f29d4f4461d23d5762f1dd553f8323d82e03d97d8d1e705a30afd1ebe664ee79850a3657d084cd9e4b65547db42a894b64138b7c41bd48667885a678f96666ba6e9a3040e4b17a50c2c7994da7a6129351bef19d92e534e794a97b0a4952ec19a678356682eb3b3a4b2ad535dd9deb49aad9f3c463bc92fd645116cbd8716e036f0ba39248bdd5b7e85eb4d8ddafb47a6e78e3240bca271cd78d6cd84ad3078371764e0af07f6fc7d4ba49bb6cd7c2ec7bb767fa40db4e565cdd1c74cac68ed902caf5cf644af95f8b48b92663657c90732bc322e6b166918579fdf8e27fa276aecbc6e1a32ead180c4b4d3307fc92c244954f2f893bc9fdadb4286e40ec9a26c9a9c9346e39c8ebbebf5803d23e0bd2951f716ce6e60725ab19b3f4e8b087f7fcde58c7b1aff9beceefd71d4a4225ed642c85b86bfe69e65078a85d05a3d4f27e21db4a8ee648fe38975b5f87736fee926742052aa7d623e5acbaf7862a678150e52d11a3ee558e1703c915fb1177d9257d71e992585d6196fe3a5ba368f5afb8b7b420875f23ea2bedbaa68195798d16a1ef5a3f4c9d336a9d041206d7ada3dc58f72de8326e2af32ba6bfc14e8a61d1e8fa86a11f48bc5191b54b47ea206bbdd6aea5a752f29d960374ef3a99f543c54545c7f98271535990bb524ff93ee4dedc515877954e05567c6fca47d954c2af2b0a316ee75de4214934f7c4aee14e7aa09a1faa196f25313d2c49e88a89814559c5b8fe0a929859e0034a8e411336ad425ea2aa4f49371d346144fa8938e126fe09124bad82b7b7631f1c6a669aae2b69092c741873ec93bdcde784848e75f6214da7cd2fd5afb78ad5a659a4bb6d71edb931899057d2cbf58db8a1ec048152aa0b29f617e8960692eb5ee1972cbed0dbdb76bd1d2dc5cff79ae4f347a718a9d545c6ebb483b232350b3a299fdfaa711ebbb97eef847540184869c6f320d59147d4c0af119ec3e25a84dbff0d2fcf1af01888fbf8f5aa1c19a70198767daf38de31f494e09d5e3edf7aa16fd3827e4e816ec4e3f098c7b80e34d6861c8e7b022a948860ed6e2efa0864499161598c34a712aa675bfdcc635a6ac7f80888154d01aa1eae2f1a8f1da02a2d8de48e86d4245c78a866b4b320e1d129269ea26b350845be0ad4352d2c36e532ddd6b100d765272981d8cb67c9c860235a1dd87c67e733c0af7db4b4aa96fa7d26d52974b541c875629805897893cf61d8fc212b71ce5bf8618bf7aabaad0be0fb498c007ef08414c3365dbde4e79c3346b0de4ff51f7de4575b9b9a5383f9a690da590d3e905fcd4a8e29cfb3efc0a19b23fa121352f79d7a4d2330a936375fbadc4f1dabf11e3c9261e2ec7e043c2572a8d78de33eeb1144604dc3fbb562c88da68eaf741bfe898476ffe04b644c433f82f9080bd624d3dfec2325e205f10459c5424d7a39ba51b4f5c2ae58e2cf9dfe09185d1b214359ea5f81dc523c683263c62e0d1415731c94d3ad796dfc08e1bd20f9e752f2fe5613bde4d76867333515f41a6e15e56e1d2605390488fa3ef95dcc77113fd756abd4d3219c4faa567a121fcb1309e25b7f19666d03b60317df116af6c134fb8add8de5345bc71f728d817d1fd6c13debbbdcdc8cdbbae02c7af517f6ac4396e7cc6cdf17563678eefb2393e5bcae48ea44aee77c6b495ae05acbd2917295b3c32213e5d1a183b3e11bf654bf4676a48a76e39c684d7ce2fa753bdf95c3d2db1aaa7242393ea7c633fad46fdd511a1da945eef2c515379f536ad36d2c40ff0d7f8fc4ff2eadba573c723a9aec94cb9d8f2f42b7a22dd39acf398cdff49f71fdaa5ba7ab3b45bb9d3522df146b1fd1015d313e0563fa785f43e80d9f594569b4fa7a6bc24153feaee394d9958c8c7b109bddcd8f8a93c5b5e6a149e8d53bd9ef2a84c924fad58c2bf95b8278298a294b4f8786758be8a967f9c1a85634903ad4ca948c573da1a434821dfb46c498b77f6396d90512a29778a8cd2273e4349ae0c2b5d3af70d786a5a90c9c9b67d472976fff499307b6c35aec74fec1b7ac62007b149632350d8bdd51db7ff9cc7318ff22eaa448a11eec441985351d5072cf3b4d6c3cdec9acd9692093f8c4c3cbd42da9d70de1a285b89e7b99901e593cb47bd9f0365bf84c3db31e1bfdf6709fff8f023363c09e1570e48cc58a1ef06e127ab20dc0a08f7ea4fe574b8c32d072ba9ef8e74ce0f99319d4fb90be34589993d7008d5682f089177432f9a2ea2aa82675be63de09b19a3cca2c4250f587d7f0dcf1bf13eccade84088903cda6259a7a9ecac566acc9ab88d72152ec5b3bd6b21d4693581358fd292bd32a22645a9ec14635adb8f472926b4b65f483c4aaff95eb0e2637e656ca19c848b703c6e92a7662a582e2b9fb2f58d21211712a5223ba210fab2515aea84175f96488fb3a31423602539f43ef2de74aee530c4373c87faa9ba47cca398ea8204fafdf088725231f46b84579b253057a57efab16b7affa07a0b17ace9a11a3b3c27baf45a30e5fb9d33fb3cbcfad74b5ff480ea257c87293dd6f5c04443d45354999732f07c454694946f47e0b8a00620ae3f29ff5d28ff1c291f629a4355db088a6da6ab366bcbdfe83ded407060a28adeaffc6006553157a2f83284285881e73e91038e6e5e67aa82d6c7f155748def36946f268e0fafba15b0ea7e9db84ce7406ac7273a7271a2fea46326d54310c883b5496a08f576353a1eb220eaabeddef72f24e67f631d63cd0d98af4c4fad8479f90c5c62ddd74c4d0bfba8c81c93e2cb44e228b40435ff7c57fdf811f4632ace47f9b8cd5aa7d23a58256e262e6714e68a1035f773fe5258890c0961de0b7c4de0fde70ec2ba046a7a3ea73cd5503f9371ba0fb3a8efed51ca94e2ac792a2a64bab07c1aaca48299b6533bd12b29a8abc0c483197a58f150c7e73b611d38ba19d7536ff5901c6ecca1972817e1247abd9328f031d86c22f22f1ac80062ebb4921c6aa36d0fcac5be073653bf85102559a0e5a7182d5f7ff19fd5f1b27394543881d696b933368d97cc561593efab4ab2a9992da8d05682a879cbf8b8b5e6415d7c48dcf8fd77244c7b9c82e77b148eed8696fade16a5a8e7cc1e2ff1528d873ed0142c373dfffc982e7b9d67daec14ef8f9f0e7919d5473894793a124a55246e1bba75af9fe9aaffc740ff87e4400f533e6e48cedf8f51427b9ba4897ba2162432f5722bf1f97aa1ae3fe85aff5f41fd7be172f0a28ab5f3547c35f4ec57ea117e7f43cdafe1596ae43efb04a9ec0a336408f2f2f375d4b5c72bfb12ea7700b31ec66f234894e29f1aa59a8cfbf5f5dba9c98f04ccb851b2d9f3506a54dbf83699774d7ea92c81de37a4014a39f43384fb53baa43f5bf4b8c4d29f1e00fd976724e6f480fe77f4901cfc5c620d639e4cd3b4e6a7f829679eccd3f78f16e0770625a07343724c95e79bad4becb39fea2bec8573a929851ec61f6b3f2e93903cacd5db82cefafb13fa04e84793853d85fe25958a11dfa2a32d5803aabbead36eca4de8acb7259cb12696db2a8e3cc39af8f5b33fd544f94e68df1e38a4651c28b4796a6677c4dbe6597e20243051f1e55c265792a39b159fbf4454d1fd6cb92df4b35ddb6f6bc45d1cd31642f1f933743aca3f4a9a634be0fdf7b9b930fd587f24a6e6dd36d3dce96daa80ded368edccb0b5f4ee3eb3f9384da687df7bb50452fd0531a91ecc8e36329aeb590d9afb7931527cf912a3b973af77ed6fd6bd72734d8ff27107b3a719997ac3e1bf30a6264e4ac47ba399e6257f5e3e45b60aafbba32fe12704d7fe8544360fe7b3788a1139c87bdd4e3a9ca9b2fa40177d5f6db2137e46096db3ae692ceb6e1f63cca3ffd141aed86709fa2eced3e493bdaa11b7b66a44406967b832c392af2f24a6d4a75642784d17ff99096017837707d8dc7607d664b551bfbad9dac2fc23cc492af9c229e651f7fb78d74929417ca118e331adb150d1b38187dfc07be906b9969c4aabf684e7c5315031342550e1d4c0dbb24a31217fea90f492db5f870dbf3daaa6e4fe1689f77def66bcafa5f765ef9f52cb983d17e4535323fb45be2cb6ec062bcfda9f4e4d1122da86c9f31ac7f2b6996921293cfcae605385f5b942835c99587c26a741bafc1144e0000d7f2c312d6d44ca34c8e99bcc1eb55ee9cc2f32bbfd86dc1f7e67d46dd1632654e864a6071f28dd48ed8c9c1499365adbf756047ec34aca15139afa6c5427f951efd65a7ecf51b1bb44042605615e1b6613d89f913a8d46deeb15634e39f0f791c384fee39deb9072e119bc57e530c5984ab9ce9f925d41697bd4c382562bf6570cc56d2e21bb91eb2a8e1630f1fa4dc831b1bb6004107ef38df39707dfdf9fc5b869c6e15f43e6dcb1fc7afeceed21596c2e26b0f32632ed2b1209df48fb52d7776bcdf3dfc531f108478585c9bea7bfa49f94eceb26796cee2618b0ce142069a52436286d74ba9cd2a889a4b1613d1b8d5b7c7b86b78da60a06f215bbfa138d55fcbd8261e39d5f22d2fe968e96e7110325bfa66ed8e26bda98d89266d4f5356514b4be65c4dff8fe509ab6d77758dac8748706988ba4d4076b5237dc2c1d02ffcf965a4e2a62ce28c2bfee78651d481fcefede55f3393e3fbc9157a87d6c969235dda9c8261e3e4350134004b4cd19fc06251d2bc49c1aeeaf40f4371ca2749b01192fa31996f7e7a3da42f6eb4c3d1b5badf52429e89271023a5780f7ba9be78bbf5d9d75920a2191fb4c6a6a13a2b22208f750fc36dfa546916c84de6795b15f8625c6a2fe26972073127d2a34bdfbb24ee8b718e17d3520ff8cf6cdfd9ddd969956edd77112ddd4ae27d1d1f7f43974fd32ce59be847e805d0a0542f47bf1150da0776466eedfc69a384033299a39af504ffa1112a1a2afb0ddd4bb913e41e32db541d488f8552264c868443a52b1e634c2e7a862bfbb397ec37ec7af620b6610e4aba3fdb13b7d5a07f8e143fd51da3a24f4a3165623cc59d591a6350c07402ff2c35f8608c356f0ab45489f20439bca31534cdf381009d336ddc5cc3fc59a3a745ca61395eb4d7d2a5b5393dfca7b60d48b2208429d563d00b96d2009b760914aef24e251578408734770a8e332e98a81a85cef7a0f9f31a4c87f8226c95a9c557a93338e03a7510b2b653f4440ea69552494c2ad2a03bd95a7d85edfee569001bec16fcf46bafc745a5503518b4cba81f6b3b61e49ab3390c99971f783314143e8481c8f627b75bbc9ada95de12ea419161a420aee2d32da2dbf1ad16e3db0db4da114624ef1c77b17ad92b5381d2e480b56a3c3058afc46549ea67f224326696dfbf3fed6e7617febf3b8fe084715a5cfd4100a370229dc09942f1c214e92f2abc5a8c5b9c54558afd82e6a376d723243fba80dc2069456294406d113bafd0ed3ed877fb155927b79fcab039021310a1d2f905e25095c77fa1092c02d74b4e0788162cd134857b1fd49fbb4d2b4104f02ef77242d90f125bfe8494fd0147e48ad59526fdab2976e61a15fe77986ecef676d92bb7ca7fe845b5023d1f1bbbedff5d2349927d1f9cb3ef52329680b51ac013d83347644b5c992a0c4b530320a09aa57936048ba65af6279b3f0ac9e0c478a1e0224d59c34af72e5870cc6a5829634f5fab4ddfaf768c51a21f22bd593be482fdc45603f64bb69abb1bda154af8d408ab550c34edcf058ab134a7b2fc727c7e093cdbc74072ca71a3e0a78d0c14cf8d52bfdaddaac8ef386927fb373e870fb073f84406921048fcaa9e7e9d437fd95a206c40f1621e12d0707ef0df8cef51e3c15ebabdbfb692ca7a0e1dfbb85be113f26cd6c346afc1d4fb405a7a86ffa29491c92442e0ede05f49325ae43a3d24d1115ade305dff99c35422cdb8dad4b4a57cd9cdfa575885f3bbfa944b53b43f1ee8b4ccde33d843c89fd5a4b6dd4b7e3701e514932e8755cf1593c6397f76bc66737e35d6766dc09bebd5f37249dba24b41b6ff3b9cf0c5d8aefb12954c514bedbec00541e542cfc8ad77bca789dc6674a3ae5efc52f0c1a816e86146b1a79af6c11de518e5c83b6ee4babd611811ad5b8eb396c7e2e941bd32ab05dd8588b5dd1e9b346c65fd2084db6c536f45842a9e5d79c9a33e5234c5336b51706f9a2723a85de01c5822fd100487713cf3a5dfbdb845fe75e359316ed5c8477ab39903e31a0dc68890d1dbf39e2668729f468d288bbc6b410e81fac182eba8b98f546f85a78b4a15f87cd944a1e3df9fbbe345904227ca51264435d2279fd34d63a3740a3b2ec7077ccc4ef6f4eab0e478dd5f83f8e4d7302874a2b0847f83bd1011a21ebd7e7a02958d73ebfb4834973c4a37f837100d4061bd76726fbfe2d69d5bea8b149552a25855d5ad05861fed8fd6c6ab297360d746588262d6420da74fce68a4aba45f9c103d18ec836673d1985a8de55289aeeb9b6de02ddd952dfceee14f0b34a1846e23eaddebcca49e1588930a3d6c20ba65ac62e1ff0787fba8da65fb3a8d5c2b62bdbcaafbe8d0a65ccf909fa0d248f3a2be2291c083ab5843cbdf636a27a548b06d0b9da74a18353f498691d0f7a47288543032a2f9590a66df5ad161fa1eb3bb852956905b791e92ad9e1263f12dd9016d29f084bfc0a4af71805952a1c6fa2ac8c16191ff7eb22c55a189d363f6e77fc45d183403b353696981e461b35eab6201b8da24783e594e14ba78c58db99fd95b0ae8fd279a78b5af7a71fd00dcf3a9ac56ade0d989d4af0778454f55ede8ea81619757ca050afed8fee0a2c6d50d0febcc651efe22f165113f57a4bcf42a1a483e1178ad7de3da9741b87593eee3e944d93400abd135b3799f37ca464329f4aad77a62635f508535369f52e52723a9fcaa8771e4d12c949a3679d11aa15eeb7d12b6a9e6c18e9727b966f5a703ae1418ac87e050aa76ae45e46a9e4fc593e38d7945d134aab4e270668f0a94b2d96dd0fb4eebefc605f62aa8f7e830cedd980fbfae57952d1233135f930d20cfcc2cf0def7afafda91e6921be041ef971bfd29087c782b49070c2f0a41eda93caafef416d9538ccf3e587a41319e49e82b46a12b5e451eb49076aaa9c60734036759e3c92863578538565a7f9d08f85921d518a2d021831a9cb03bbe337de4d6645fe6398c1faa29b02c51a3c529bb63e6e9f76885bdfaa639a808463f8eb2a2aa59e27251d48537efdc3d15ae4836b282c11d7d060a8a1c164cbb1aef566af16c97a93370f8dc65f91914ddd679d81581cb08b2bf8772593c00509c0e5630811e54692c995c6e7fd3a825f4732e090146a70c0067e10f4e9e57836a27010210d597ec8d4d7e6e11e4d67cb8626371ea28224302b10a04bc58afcfe448b61ecf21977f8733c51bfe621e94c7f1b7c7b4ecd709dd4d69f1f08b37db6d60ea7cdec8f9436fb3b4fa63fa4cb9963a9c308aad297df4f3329fed63246f778ef9dd3eec9e0adda194fa8613dede76139dfec127df612f30e2b2225800a28429d36352b35011d7146a7859c15f4d3b4f5c43aa3701e2b64fd44bd55ba7c79bf86010f026b67dc14354eb95bd57aadf9c6e35b781fe9f483ba5159acbfa4dee5173496564e9ebd7f994dfcbdf029d1fba36d16d5bdefffc19e0f441f4e8327a49f25edf789531734fd34e51dfd5f917e6207cbb166adebd982089ac72ee9788632069fefd0aa35aeb51dbdc39a61672de9d624d23b9130ebc7442a7b17ef66a262530bea1851f2761b997885828eb492031a3bc688fd3b8c8a4d1284739565a9b7847e1a3b07766d1ccf9fe981d2667af0a24fa68578f00664b77c931a22954ce1eb6def09145e4f797a328b6fd1e1447356bad4aebc3d650abf329d909cb7735883d87727d4394d267b8fde490b392798a269e969b8f7d46237d724dbd27a4ee3eec08739a14ec8ce553627981b56cc59a7135dd6e2a760e706c2bf4a237660f36ee89883383689a04fe65de874dba639867b7a1823ce75f48e6b9482229f574ab3b4b3c4a6b5f5ed1def7526e41f727798e562caac6f67c2b45db3c4139aabccdee533d648f7e13c3fe3b0e5fd5a06344e6908ae15b5053e987177cecd1badb79aeb1eb36762b1ba219f273c75ae4337ca46df5b36257e7fbccdaa7bd15316ed5f64f35edd07fe1feef970b09576a0d90484e8a769615bcbf3ae25348a1c7caa43cb96edd7594294c5509b248261e73b4eb408e9d484e4604ab7cb1d34c1b5a5f3ac9998bf97327147982cfe7c42e737749c22a3fbb434a1c5e23bf9a52f8c9d1a51f376a746c8dfc6da80b5824a1140dfe98176665399644f5e885e9bc597668356ecbfc72bd1597ab128b3980d5936843f2f0ca91625f532d84de5a785a8209630de717267c18c74aaae1529af68f9937aaad664413d58f4c6c7c7cea1436f06516f17f172908da5662674baf90ca05e2fea96340287efb4ad192b7650acd1219d84350f37398d6f7171d08bc2f847b5297efc2a35e8eda55cd39627ed299e86919f439f3c85cfac9d24a4a22fac7b7a3d6bcf8f34a4c7abda9cab681ddc033a68d18e9aac0e0decc368e0398da5b435098319add2d6dfb3d22a26e70b0da089970e59692853eb9106db5d3ef38f5934d4123bacb06e295c25c8e9d82a2821ae01d51ab64e5f929432ba391b7fa379fd465349b69e74900c79942a7b79799b4c3134057fafe95165bef64c31c2b19f6242be5c3162988762a8cae3d66f75bfdefbe561bd7fcdf0c7254fbd407bc7654f4ad79d1f13a4511717d4a38da77e3ac57cb398fc8562a8442476c811b3a92ec964ef6a5ea5ba099d356af7b25c3595f3d4f9922f9563830ac96766bc5b7d613a8cb0339b905e50c44b1ba892658abd2d2c372f583b31fdd25a939bb0071e45735c32c50aaf0667b67f16806e8989296e05b01a0e81b99733ccbd7e10213c8b6fc9532d52383688937ad949609a8a79d2bbd878093e8432f524edb6c08cc2438cdbb211af43dc9bda7324628b1e0cb09364b2f745284792e9c2a6e9097960ede5e635bd725c2004d39fac4b9b5dee265b0c69d92dfe1f6ab304ddd25842d5bc44c984efe06f3aa89e367836c453881b7ae4aa076451854fd1786d3ac23b2b8dcbc26fd9a53645bc4fd5d4fa96506825fe27e00feff4af9034f490da0d9352b37d08fa974f30278d93daa9a4c2fed46c9b77fa653075e597bac0726ef7ce18e44028e4021476e89af6ad636932425c10448f1f1f53df931fe5b830f5b27b2d5b4a0fc9256a9e70829d6b47591fe647156aebc5508f76782dea7da721513750358d29e3679bbd2facebe520b173b53068cb3e7fd9c5527f45f78e47a5cdde2130b4b5a07fa88bb56da824979af648d051a7f5859b2444e10f1295be40c2a32e930e29ea312ede05788ebc51c2aef292eb4630798cc864b54aec793ec7d29e5acbef6a3fe0338024c53946558e64904b5d2efba4dca242d6d86e91446a8ff953dfd6f10aaba621698188b7459294e65d006b27bc2b6a30bd9f4c4cb1d60833b7c3f4cc0de7a0314fe1d084be2ac5a3966ab48e2c3776ea02712a473244f396511644bff7fc88cd85eb7e9dc58f8fcbfe1c2a4bd283e2091d185f111f5a34a6d357683bb5f6d36e1df12a53d42e124ef9b7d5412f13a036adab6fb773b5d42caa1c2fc8456fd91544d1bf8d664ae7f74626f7d63a7816ecb0668346ba7eb57d79a21b39b0e9abedb8edd8fab8044f029d1b4d1c9b83ef848b0b66d37cebb80268537dcee2543bd748cb9b75640a28ba60e7daf1a6dd4cf916f11c5c0f6ad6f5b2cc0d8af21d24eb7a1decfc4d3066bc200749e7b92353f6a66f2e49a695b2e55f9c637966ce5a4a8ceebb36429ebbd12b18c7866e84d1d453782fc79509e1176dd1413b9b8e3a7a003d5df7b4f91eddd3667b38d2736497866e06cd441535eb739e5d2f31fb6d75d1290863f98eee648eabb8179bf64983e62b150efb55b99e7cf484bad828b2f84b26f6e7f271ec2184230e4db93759bef5aedcd20bf7ea173222331e6a2c6984be9252d4994a72d9b00796d094b8097568c257af1c82323ae69ad264618e98e3d491c713d0d758e272723ce46e2325c37ae0be5e775a2351b80e733c85df6ab834b55796a64c33bd5df4c4aa7c46abf21db62adfe189a56c7ebed54cfdd448ebce86fa73f30db89f645a3a20fcec45dc9be55beaf76a8babd46e7a5b5a484ab7add95ffd0a4fbf25ef5f88d934420f59eecabeec742f3b01b1dae60e54b836d8c0486dfbe05788c32eff576c4bfdd2027da6d815d6ed4c7e3e3339a43febec397d44c3f6ad71b1d69cd0379246e01eca5449b677f6b63e7b2c3aeb37992de3ee94a96dab0ae663566fee28a9bd8f8352bb952808a19f05750eeb3bc26fdc1d654e01c16ada954951d48c22418e649c65b67299f215f2d648b02e2fb0cc745e6774b9c33c697c3acc0bd497ec8acfb6f04c5b3f6bc1ee4c0f1af1da70cb781cd670d0523b353b71d93503db0e75e47f77676feab3a5c3df27963b9f4ff0d3cad6e701763461caf92ad4078c2711470b75123e1e013e110f935a46815bba62ad4e454d7f0a2360b99ba35a9ad36236bddbb4cd494d25d78b6f69a5a21a9e5e98ccc7dff9b4c9f0575fd2c426929a6183bf60e5e32fb684fd5b0e768c4e9b3b7359936fc94ff2a68efc6eeccc65e82eeb5c96f54f5397bb6924f4b787792ded7f37da75b41dbac3d4d56e6f8befe4e2890da6a936ebd22aee9af5da816d985f849fe25bf4773e9aec1d4daf1ca51c2a787cb0a3596675754838107f61647f50d81fe7bcb294aaab053b5c82b10715c9d5c8de5848f6448aa267480f65beacc56525eaa5e474c1d87dd20c19a204d5e8a0f681117f07a721715c49cfce1bdb6469a7a17f4daf43a6f79eb62b9249e8be35e4b0fd8775bd77b6b92a9225885fd162c6bbf62bb5012a53457d3bcc5d363d157b6ea142044821267a288a6cd1655dda5e5b343e3b8ab07f49d15f22ca574bb515449aa74e4425fdd27132badc5531f453d1658de54d70d92ba951f915065d806ae726c5e7a3897e9a349881f14710fdd246a478f0c7121e696353e4fc7184bcfdfd773e28f9a0cf87ed8bdf5952b204e66e8ad4648da7a2ff57227a6fc052cf97a28d785c36499b5299baae459883cadc7b9ac5bd24e16c3fed21153c5eb6330a664ff21497ce1954d1dfa5368494b86b99ab95ad354984f7f09ed74dcb709d5ec67b14f1f4a2ef78f49783dd2bee9becabef5fd66948ba8d325ce92f5f4d4ee47d895aa3a632ef217c2a0675251de67702bcf7383fe2987bd8d8e57662ef1af7081b8da8d532bb2bfb06af1509bfcef7e862360fc959f82dad50786b197e7bc48cf5b51473c7f7f38b863ab8a9725c8c083fc773ab8252cea5a945684b39df4f84f0fe4eccdb5d5770d1715cf0f97513923a77acc2bf55e57e73e443bd6c2c3a5a90498dbd29f41ddfb33fe1267a6cf610d988347e1dfb7a663a9e57f4f7247c4ef52ec23bb0ef60f7040dd5ee6b0d6b20fcacdf7bba846d34e1dd8c1a8dbab35bfcf08e7e1392f0eee21b6fe698989d838c02948cd3d7870827e94f3e361b9e1480fe0ad168d1a38fbdb4d4cfa705caba3d881830ec1cb6495a3d24dde916d3bf91f63914c34f924fc4a1a5a2a2562f2d0eef50e6e05358e5af2acc1850f6c5b69e65469143729b73639e5154f35a655e5b70cada545942defc3c26a7e33438a78ecb4b1af119eeb805bcaf789f2b4f2cd46ae507ef1e7e70b4e178cbe936ef6f9919c6de60afdb5e8f32a9759221192fa38cda51ec6e4445829d51f8c93910ea08b1ed87274f084f9846889fb18467d846728ed9235043263963db8867de1b287d05e648c29348c2c8f6bb9c31ddc1f43fe28c59769249bec172c696d1b53237ad5a4230bc317ca2e4fa6fd28c3a626bbd5e88f0d3984cf765bb159f7f8a145f7f8a5c6bbf502be42da82dc4fbd1fcbf6126aba2a885f73b0caa47039e6350adf3b130a8b6a0df67505dd058f64d285b4cf5601854a9893483ea9185415533d58a4175ff2f32a842e8eff0ef776550759c0c7b9e6550d1f55214e0d5dab186ffe65f6650ddef6050ddff7f9941757f41d40b1854f7ffcf32a876b9fe2bfca95b515df853b368fed4dd17f2a7caae7abd883f8535e66833bbaa0ef857f953d6b1c8fdfe15fe141dc3232606a47a317fcabab42c7f8aeea9eaaf3dc79f0a78317fca3a95a2717fc09fa2e38daa7c8e3f15f062fe54e773e733f239fed4c64efed416f41c7fea32e64f59851f66cd9f5af387fca932c7e7f8533a2bfe94d4f67d532acd9fcaaf7f3fc6a1a8fb7f843fc53cf1595ed739fc29a6d77993cb9f2af0c5bbeef82660fe14732f48b0e64fedb0e64f31e3dfb43fe64f31b1f45f8ef953ccfded6556fca98d7f993ff533c39f829a67faf337f6a7532e983f2561f9532d88bec7aca8f5e42e0b479697f0cf7064db42a8e47f9949b5fdd9009a3fc27ccd1ef0b22bfb962f95e5a68f2f50d37a3a8f6652312d30a98349c5983d6826d575999afe6efa1d2b26151d76e0bbdecd05fef43eacb31926d59eae4c2ae6edce449a4945a78afab34c2a26572f7730a9e4ccd7837f894925e9c2a462fa0d19cba4a2733af02d0e938a7966fb7098544cbf25c5bfedb14caa6e7fc0a422582695c38b98549b7deecda3f23b98543f6ff5609954d7ff4526d50f7f814935ed392655d47f8249157494786397ebf262afec309a471540f3a8e6d33caa369647e5c8e1513df8a7785413383caa299807c5acc476606ddf9fde9547b59ce151e5ec627854a7052fe251316dfcc48a47757d91358f8a717ffca73caaf57f8d4775ac0b8f6af69ff0a8fefe9fe051e5d03caad9ff091ed5b017f2a878899847b5333ce6d1af3f5af3a878899d3c2a5ee23fc7a38a38f86ff3a8e8bea6def98f785469233a795403d83eb948ed956dea26dc526cbfde8778e3ec518b7de827ff511e159d3b6db77f994745872725ff3c8f6a13e651e5d6f794a8a9d52fe251e9d35fc8a3cabbd2ae4fb7e6516df3b1f0a82efeb8e777795438362b1ed5ea0e1e95eb531e05bd109560e1516dcdf1cee8f8b5d0eb775854cb318b6a8f76bef1b60dc3a16aeb69c5a14a7e4c73a8be28bd6db3c32ccc1ef66327836a0d694aff3306153d53c30c2ae684bbed94731706d5643cd35d38cec2a07af53906151d1e33a898f08510fe050caaeecf31a8ac6788c91b29372e832a8661505576615031e3d7df680615ad0bea5ffe8c43d439e393af855907cda0baf72f30a83ae329caa57a320caa42016650ad717e11836a338f195ff70e548c8095e4d0fba864dd9e2e0caa37ab0bfce8df6d3c5fc411b14a2f8372c70caaf2119841758f615031f3911fff7ae97d522957864175ef5f62505de8f81ab02809ca4f33a8eefd1506153de7f19771195456f1ad84f27530a8f4e8771854c7690695a3207001ac4e6ea91906152ff1abedde8f180655678cc971304fc10caa3e0c836ac7d74c4dd7767b9e41d5194abe0cf4e32f30a8b6a01731a8accaf31ed4cf1f31a898f9a0e8390655f98b19549d31a3484a66c5a0ca5a8719545a5f86415560db8392d9f7c066864175ef9f665075a614fa2ed5836150dd9b7b795d71fa4c0b83eaca6354982df84b0c2aabf69803cf771706d5bd99c582cd3e5bb79842d6dc7a017feafbcddf322d76eab7df7d369819fa4c863f859f8de7f95356e59961cd9f3af44ff0a7acf423f0dfe14fb1fd1d531f017f953ff58a357fca8ffe5df7d68bf85338f61236f6a2d7ff127f8a7e2e4f5f7f9e3f65a56faf71f9535bd05fe74f59b5ffb87f8e3f65d5bea35ec89f62ca39c5b31ceb8d4680b5a6aa40f17921c2bca6922efc29abf61bfe97f9533f75f2a7ca7d9fe34f95cde45715b0ebbcb3983bd5992acd9fa235d7f38c853f55883af9539db9f119fc62fed4ad28963f351ff3a7987577f871863fb505fd2e7faa0af3a7acf45d61b2b7f0a72ceb6e1feac5fc29abf6965bf3a72ce1cade4df8fa42229547a677c97f6f980361e6547edb3d5883ddef644ee9059839f5eb7dcc42c2ec11d1e3c0dbf83bf3e1e9aea72604e8ea0b42e9b700b6ee33e79dc45c8f1dd9bb2fba2f3ef40d668ce85b1e77bf904ef346e69222f7c5e2d0de5bdda753018d6867477ed06b63efcef3157ab68d9e77b293c1329a007fbabd08c7a8c9def4cda76a6ad363ab5045e385373b7923ccd95c9dae3ee6804b6d334f19ad992aec6e62831edbec2e65cac2fe1e7946f4d82bfd707a6bdca69b847f9626b5006a41d688144502fcbd87d8bd8c39010ca7e0468a50fe793df9a83bd554cfb89663d6083e2b59c89edb6ed09ce231ac02b666c67aa53b9de78fd298a564b260f9e63067eabd0a815eb40c9f8ddb7a1a594e5780d51f9ffab502e1932f2ce7bee213263acf02c1bf582826609f429ea96f5d2b3ee302eef9109ad7624cf163d24bfea6c5e8bea8f7f2c056cc08c0cc8019cdc18fe73c7ae7fe823b91b717d51cd43db8c81f2f425e5943d253a61001b96f48a652628988ffca4944519fdaf2315f27919c7cf6a260badd62f7d0e2f4425e6e5e610e09fd8b3b3ab7a1f8643a9f7a720515a6cb50717a7f58cf913ed1157b3433346c79bdbc729de8b7f64fe9d64b0ab2309814472448b14b82544569e36c117f6c3652d9ce36da2d8ecc6042d624315ca126238410d32126ec2204df456e2d4e5fa7520cdd45f89e74b397a042810451719f120372c5a18b32aa2c6b1bcd3cdf3d9b95924d3ec5dabd2aac4bde5bf139f2389c264f71a405e9cc3875c2cfc262b8b56ad2fb3bdfe77d70ebbd498b772ee62dc1ac86019833c5e8a5d62b57d560b7d862f67979a411efe7e811a5bf2ae427c9da42cad3a4df8bf886e63b48d9dc489fdcdd98d796dfb696da043651fbd0d87aa19a9249f9ae4594930956d515a837b6d9b61051eecd88ea750a51599588da20a67d2b47d7a0711ad021f583d2b85017f44a11fe428a5a7387875d898bd259cd3c9340dc8e6d857e948b09cd5f2d397d4cdff023d63c7c12af1ced582885bcb5b9d079ab16f1952b5d08e56f90b74419c1e6ad970b6158f809a272c5229c4a4b48ef7d94b38c30dca940a68de2764a2a166177fd111724a9573eac4014ea26a00ac5885a07799d4b121a757e397336725bc8831b1af5f5522ae80e6a0b696b69349a6e45b553eebf21d3d23dad296ad347a75a6b8d20378b5bef1a4d31bf81dd4da3c9966c097a963239c8f8afe558a7fedfcb71efe5c18f236f5b9eabc0d619cdcc737530e770d66f83b16eb4cdd4ff88b5a33cd9d0f40b4a19fc2047fa63233fb7c22b0befc44a096ac5d2906bfcd502bfbce5091adf0b3d85c21f72bad918b2f722622a1170689fa17e17f24aaf3df169d900963b8a4e139e52d2c9ac1795f1f1fb40fc959494fc8eef96351a15934d3e8675be8421e431ba9ea3ece54b347c70cad690fd379f69ec9e8ff2e3105a2814249516a68f6e35f45c8788290da5867a5fe28713fa0201b13fdb7eaa2ac074826c4e0a51a5291fdf8332482b6da004ca15b5a84eabbff6943ff1b89b5084f36e87cff6d057fdc457deae43cb1384ea409950383b475f30010d5f8f771e7e19fdb0fa9df56dce63fd9593e7127ab113a2c2ab1c64a3f03901fe1159a2831bd64d3ab8213523c5979892f28670ea5823bedb9f2d99ea683444ad23765f1c56d68f2d77f261c2530fe59692506efc857f60134f2afa8e5fa81d858a45553e4ad96364a8fa09e1bc180a5ad1f2443f5229dcebb3bb34928d21f42053f625a56eda51adca75f761a67ab75409e9482e4a6174a2024964af5605ec30e2bd5b093fa17a6229be93a87b97daabed4b85ea1d91de32c2afcd9998ac0af0886c0b4972d6579244c3eae3ce2db995b99ab48f5cda720db54282821e294eee8a5edcb378b2fb1a1bb2a0a5d2b448faae0d4f5f45f20ca55308c3c1df90f2fd7ba825cfa051f30b57778735040f1948334f49fecc3364f8f3a5d784bc920da33653094f616d982af32ec0e1c76dc7312ae3ee21431384ce955ec371f279ca2613e24987e80d9a7a88e11e4f69730d6279c2d3570b7947371c2ea01aeb11de3779dc66fc7bb3f406c96bcc533655a25499be52c03b5ad098230d11f0127294b678df650dcfa0a985780a78fa99b6bc7e05473bf75d5e2fad06ffebe9723db98d941ffc8294da7ac230ba9ef0de365e54e613bb59b9229818dfed3bd58c0d06f3bbc830fa2932c47d8494ab4fa0f602e5387fc2d03dcae77281a1db4355aab372d4056418de44786fb8b6c130fa0641f81a56bfe343ad682294dd2eaaa423fa2025791829337ef6512e8576d794f8188c1791a1a40419b44f7c085feaf14524fdd20995ac371cae44a30a0c4baf104ab242a5975541c86ad528527a6524df501f8598fddca7adbd94775828957d89cee751734891b45a8634d952a7c7fc1ff2cee60993f323db9c4f6fa082bfb3933625a291788fe8685744e5dc15d8aba9f4bb02fccdb6b4a90939fa53820a8154ab86f235c1fceda8d673df9ccc01e997b50bb43a7fcab6ba4fae3f655fdd47e36f92553f2540cb7ed81f9c79ddb83f735529251323a9568b7e309a7a8bdb715ef02ed34921336449b2fcc85539a737ec88906a6bcd544035ca4d933a5de1cfcf95868c405b8b756a2aad8597abd667349aa9ac1684f75f4d0a3a9a218d9e8dbcb49b8a4dbdc4ed84dff95293084becebba51e8ffe93de99344d44feb719c2d8dee2e0f4a937c97d74f4b6d90f0a44f9af07ed2c4619ed45861c6bb49f72b70dc076e2e904fa3d6dc66eca735b9434e83d57ca9bf33126669fc0c19953e52d287a42657dbe9858ff86e5ae829ce55c2fc0609366d3354d623a5d315783eabd1b45c7a1ffd5c65c86da44f4c40bb2b744c2e56b7e0dda7335aa0cf9608f4898d78f7e98c6a01e6ae2a0fed455e05de9a91fbdc84642bfe424019b40ba54ca6320f23bd1889c76beff8185c6e23437d33626227d441465caf7a5283ced2f5aa97c188f01389705ab8fea1256c45c7a5d183d1c42ff4b26abe7dcafc5cfbb4147f13121dd727ba22530e5976dea8acd5a2dee56c0ed35be8bdab5bd07af88fcf0df128daada6dbac7234c23111ea14ff5387c1ce45dc7edeb82312a7d3e6dc72d8ba07293f6c7d8aed8c9adffacb51db0cfd651eb12346fa3d8c817df557457ce90f8d7ce98d277c436310323c0946d299957c65dc6fc46aa1b4ef48b45a240daa8219473391d27fb3ae3cf7ec6a7d9f51885adf4c18eaab884d2669601f1813a42a8f08bc8a958a403bdc870ca3dea9e946ad158b95e0c7f557aae789658687b50495d22d5e5f50890e643c5d4d9d2605e5eacafd98553eccf474db810dcad287c4d30dfa82d388aa2617ef88d248a4e006bae2951414e894e49490abafec83f4ed00e746bee1612561785845e8839da02e3c77510e2778741a79dd165bd2786b9f893cd1ae515f905d5fadc71a73a11edaf8119f3a51cf930a90c0758ba1200329ab1e22c3b6d5e8529ec1fb3b88b39a3054d5a1634618f95aa5a05386ea27089e7671058230e2f1e46d1fe53ae8ffe169b7f84ff14f31e2bc607365e9aa8b540fbe58595b4b383e38ada3f2cf84e29aa2b2c905fa822ac82b7581747635260551bdf6a215db0f6c3078ff4c3cd9f074f5699da391d29e11e0ef6edc32f12fa990e393a484cef1595228055d1c2f14aa0c21dd09e5badd48d9f77fd0fc1ce56b358432e636a1bc2a24566c1fb5d130ea67e2f88669a5d4e633884e378d9c87d33dad9b6d1c2f7ee443d7466e90d14d206ec5dfb628af68607e4a899b11c42f1e2f16aa94eb8510632d618999981c6154dec6e66454592aed26859cd59a9509ed68762d2e25e5c017504838834e4d47be4cb7e5970f09832603e90b60c6f93d39bd2df882739bf383d5296a4d80f4c94768f6434a448ec1bf02a6fc8dea7b82470985b3f4d59e7c4d36fef66f2d496d59889475109f48142cdd5085a8d745a85ced7aca80edf4a211b8757744b7b90695c2cc69fd99f614f5d9524a7081f7749b32bd12190e3f2494ddaf809e98f9fa1b7d106e9b7fe8f4c17d61340e30e69f84fe71c31544b94ad03f745f14419fb9ee0a32b949dadb82dbde29d1ad574bfc31239ed29d9c62ef4fa59c9c426d104c913e69677aaa297a4d208c0295d0660756077c9a7f12fab38db711e52641a00781ebd5d33e93a8a975b791c9958951afab3713ea25466a768d0db55e2cc2cf8489242f60cd773219bafdacc23d9af2b59f0943469d8ad5ff094933472627e4acc86afbcc243c7199d1857a11a30b7faebd4b8c269b131718cdbff44f69b2a6b45393977f4339319a4c3ca0d69f1941b7700a3986d1a7589d53316871efbd4899f75095bbda50026d9e51a5c29a1cabf32c35e9ceb4625d4e1948f7d66f3689a438f7be98cf8904bdb72a679991458f95e1820e7d335437d231e25116b7a421a3da27c1684a3dd38c677ff83ba31f72938c6ee950a64efdcdaca7f5b7986cf451ae87f056fa9ba29e566aa5bf62467f0d89b01eda463a2bef804b2d94ab07df8672108ba89ec20152dd6db374ac2b4af123de342c2d8531b8db20a9735fa40f31f3a5054e48bf6205f22e005d3e0ea362f6e3fef82483c7fd34ea943bfa154f90a39f74d4693355b8a7df5becf908585b53023c0c413fc00c4ba51cf52bcc202a7df2f3a41b609c9827a24bab4c3fcc945678c52756176d54c63421cab17b9fcebc6c2da59f1489b87f972765f3429ee3a9ce6784ea21e6c5ea4c3d841734fe3ba25302898073ce6daee5ea61fbe04959cb3c292642f82d76c56e29816dae52ac73f3489887439f2b823e37edac7b5248a00c9f430a73f3f555f0147923989f475412b9a9d4a6bb282837c55f724ae35fe24cf811013b229242da9ca4c1246168fc0a1d776a585d992b4cfbc8b50566aa9e04731640e799e6bc45f8bd86d206f47ef49b043caf3ebd73e8933e6e90226596a5260209a79c58dd2bf884107a3fc6b256c2d34de467c64fc0f03cea5485088ff7f9db943d4f2243f035149463e8730e51bea324c592d7548519ae88d63675b5006bbed33665df934859790329375c00ed008d1b550612e6734157d0b063ca982c64ead5bd39e0d80c4b7a8d6e308f5f05fda4df3365cf2c9412087d669e2ba373ef42afe88f77f180b8c510b733c45d77a123cefc634c7f67d09df5b9b9da942fd97058b3226f7e31d683f3a5f8e96834621b8f63259a7179ab8a356ae87d7e928eca30e339cef0829b067cf28ce4a73623ee5140cf0e61795a77bd34c5ff7c29731fababc5ae01e761ee21417acd6a74e8b0a9b7a4dd6443ded2d70f44230fa5046efa167aba8dd0d3d94a10f443927af330e8ed4c8557da4d1249bbbe3e043dc9101e02bdd8b8f0a75a83492cdc1ff1a569fbc2cfa67dcd9c7fa1dfe0841c23cbd34ead959275e607b036863917da5d77368f507ff52b7e732025e1c979bb9a379a44c9527593f995ed5f9dd20beb0815f4a98705fa2a19b1e35689ec6cde5958d94c92fd90b73c316580dfc091db9505f56876ae63941bfe855c54ed63a8aea6df826f2a1f4fd6f8ccbf24f4f728c26f2554fe71726734bbd4b213c6d8f3f88b16fdcc463e355388705f804fb4a0cfcea05b2df45a7e64a1b68e3f5ebbd7a710d620301f945d41b08e0a4e72965e1111cbf36ed2dfbae2bc6852f5eb1ff31bf37686137ed773f197afb02253a7f89eed480dd7023e03049f0082cf5891217c1e4efdc7d1393807f9dfe447e9b5649977813ec417c5f684beb3c8c394a28ef8c9929be44b6e90dbafd4d4c57a744caddbee463af1f1ba59d9f336c265af28936cbf0bbdb393d9002b4bc2b7d138f8a410d6b4a3f93757e338bd65fac3cee8873c8fa8b5a2d89e49328f88a4e024277d908888ce9b246bcbfd215798dadeb321f754eea6e37145cec8b2d3022e8b47548a3a4976c8f8db00dc923b16e2771d42be34b3d92cad6ae4b7e5ea0b4622652249e8832af9d7735b5c70e90ccd32226580becf4844658b9d977f24edd6cd67dc367cb60cf56385e4d3e3b9f8ac6d9efd85b61069b79a8f09f5fac93a3f7c46329577d82517fae0c32e9beaf48db042f1a3d276a37c92b8884f6f96ecd3a94d054f5aa3ab52d4d26e8f3e5e3f595aa0c56f4990b01b7d9e10ffa1735bf00d67fc5d3236e7a651ce0f514a051ebd08ffa4106942fbc7c3d26638b5e47de43c3ff7ad5c2a47dc33aec805a52653af97d9eac9b256eacdf66ed8b794ff1d9445c93fa1c2bd849bb01ba2ce4709dcc423117e7b21d96e28e84628ab1fd2f3f61ff20c30cf399f4704367c232d90217d4222ccf2379dd7f951b9876d72fd3493a98cc336509e044b791c49cb793744607e51e3ace2cc7d98c12f305c7582391225fa0db9912305ca8db548b9f02aa11c8360862c26fc8c7a59029da2f4ea05580d92c45a21a4aa4e99ac6f4c44a635c2fb2609f950dae482ce1e33d45712443df6fb7763ee455873c8a07dae7af2f17ba6b5627df505fe5ae1f55c8dfae6a66bb2f379b82e615e510ae38e71e23f3cc85ca366f2d81bb5a5d83e65f2f2632647d19d1de4a163267b515d2dcc93741760a652508724e798f61b5c24519b0aebda975cd3df9985661fb29c4783cf114df1871caaf5e2357c7ca2a8573a354788c60b927d18bd46fb5079d24c37a10059de135b87f94e88c350ef08117e27ed952ebadd193274172a278a88a291cb07d48a1e1c48ef77374bd31912095f949a7c074e8d6614333c899e38e57ba153c2f787dbd3e74fbe8c325ad95f7b9eb68550924634dccf2da8d247a8ab5b864f4f24fc6a4bd9b2b129d5bcb05cc99b714ad627615b8779f4c2303e055dc3148ca6bf9f89dd48e1d05e69de99bd7f61ce6685de1a6209b5c7b1402edd1b115b3efd176afc4e9f39a30f875718f72ee58f11e3f987bf52c8272c3960c24ed29b7a46b4d2fe0c7b174fd2dc3476cd2712bc289f65395df3b9254ce1d088b644281ce17fc0bcf29f02143de16e9ac2a911fd344de10cf7cb1532f8bfcafdeed76113ee6e993fa1f6eb08f7075f2f716ffc3ac1bd2d351912418b279acd9f01ae01867b9bcde9806f017b7ccce6fd80d3800f01f75566f32c90aac5d1514b23c2e511b1b131b11e3668aeafdfa420f57cb9dfd2f88858b9ffe2b0b885f26931e11188bd2ceeb40b7618278f5e1a1d2f4f088b8d873b08149bb02cfe85fe16c7c42c43366c3c094b17862d0d5f0c295b05c25a1a131b210f4f58b26c9cdc33cede06bd1e961017211fbad273e8b0518b57be2cf79bfe7a87099c516c44d45ccfa1c3c3e70ff28c1b2c9f68e5f3f75cece92c44fe9ef320cfc8c12fcbffd019c7e03204d1f5cd9593df7ab1bd457e37fd8fdd77bdf6c7ee455718b98f95475859c6caef587995957758f98895a892916256bab052ceca311cb30fc73c9995d359b98c952b5999c9ca35ac3cc23197b1f20c2bef70cc8f38e6668e195575358b396607d6ecc2ca411cf3508e790cc7ecc3314fe698a773ccb338e6508e7921c7bcacaa6b7daee4989339e64c8ed9e17b363e560ee2988772cc6338661f8e7932c73c9d639ec53187b272212b9339e64c56ae61e5e71cf3115696b1f22ac75cc331dfe1981f71cccd1c3362f55ccc4a39c73c88631eca318fe1987d38e6c91cf3748e7916c71cca312f64e532566672cc6b38e68d1c7364fc503996fed3e5f1114b96c5c486c54647c461fb6172c67d382b95ac1cc1ca91ac1cc5cad18c8ceb882f2e6c0574c7d0f145c7418f1c47d726b8b3f18675f80b8b8d4a5812b1343eeed5d888f884d8a5f215618b13222cfec32cfe873fe7dfda6364189bbf30367f616cfec2d8fc8559f2d711cfdb2fce1f1b4f1c1b4f1c1b4f1c1b4f9c259e31ac1ccbca614359398ca98f3196746676d6abfcf5b0c58b23626977365c3c1b2e9e09f77e446c0c76981c161bfe4a62742ce4105ba1d830b91cdbcf60aa282c3c3c36220ef21cb78cb17f3b3e8c7a4fbe2c861efdc01cc5daab17c72c085bdce910cfdacf5c181b11166e653f94b57f5166e10275a0dd411d681937f4d5c86538dd2e95f86a646cd89208ab6ca038365c577f0885b1e9f9272ca5e2a36396feb116807f369eb0e1bf17ae6b005007c6ff08568e64e528568e66cb31fc45f98b43716cf838367c1c1b3e8e0d1f67093f86956359396c282b8731f5c5c613cfc613cfc613cfc6b36f0c3bceb2b29995f2b1ecf3cacac9ac3c3d8e7d7e5973fba83f960ba099dfa3db83a997c8b084c5f1f2c888786aa19579714c58b8b57b5c3c4c9b687334a840142850f4d2b8f8d804baca69fb25d17161ec54af3332b882e5833c17270c86c9d638b9951f9c00d42e15b32202ab7458bcdc73e898c52b87c817472c1d87e7452f638d1e475bbe0cadc0d88587c5878d63e75f717444e33c8785bf1c09b1c5e33bb7b94397b013404e5abf970fba60ff5e465e947a97f43b2b0ffd777ef5dff955d7f9ce7fe7575dcdffb7cfafa09318af1cb6c4cfaa3b7a33215e1e13295f12b124267695bd0dd38dbc3dfbedd75553a732fe954b42acfcc7ad8a7b376225ac89293c1e87cb17ac92d3ab5acfc5e1f2c4e8f885782d8997a15dfaa317a41bb4342e61190ceef1b88f5a158763c3718c93870d9de88957b861c358391c4b0f4e8cffe225628480632db436f078ff66225617f9cf78e6ff659f2b4733edf9841d57a7b3e6dbe3197994959b2730f229eb6f086b064d41048007e0f785fa78ed732404880024400c90006c00b6003bf0630fe806e80e70406bf88e207b407829c89e209d00ce702f03b8f45d835c01bd006e0077406f401f405f801ce001e8075000fa033c0103000301830083015e8097002f035e010c01bc0a180a1806180e50024600460246014603c600c602c601c60326002602bc01af017c20af2ac8e72490af83f405e907d21fcaaa064c060400a600de004c054c0304829f3701d3016f0166403dbc0d7226b805411cc1801030cf02cc06cc01f35cc03cc07cc03b60f72e201410065800a000e18008708f0444011602a2c16e11e03dc062c012c052400c6019b82f07c402e200f160970058014804ac84165e05781ff001e0434012e023874de86340322005900a4803a443180d2003a085f832013a4016201b9003c805ac06e401f05f3e60edd04d480f5807f7eb011b0005808d804d10d7664021600b602b601b603ba008b003b013fc7d02d805d80dd803d80bf6fb009f02f603fe06f80cf077c001c0ff003e077f5f000e020c802f0187c0fe30c0083802f80a7014500cf81a700c500228059401ca01c70127002701a700a70115803380b38073806f00df02ce032e002e02be035c025c067c0fb8d2174f8dd6c0f4620daa065c05fc003574adef26f423dcff04b80eb8016df033c81af07f13700b6002dc06d402ea00f5803b80bb807b805f00f7010f000f01bf021e011a00ff00fc06780c68043c0134019a012d80a780678056401ba01d60ee4b770033d8aee46d46f49fce9a67e27f57e69bcdb7008f00ed00bb77cce65e8041803180c9805980858095804c4011e0734009e05bc035c01dc01380e85db3d9193000300ae00f08064402560032003e8039805840166023600fe04bc071c077801ac043402bc026d46c76018c02a48799cdeb00fe703f00100c88047c04580dd802d80f3802380db8021801fe6f837c0c10c07d4f802f6026a03f201c100f380eb80ab8076805382f8034001300c1808580f701ab01fb016580ab80fb00310579063c0608c2cde63e20c70166002201a9808d80cf0127018f001700556cb8db009f08b33910f00e6001600d600fe021a05b24e40550c2ba79c37d157b8fdd4bc07c1950071812056503b9089001780ab001bb5e518cdf87567162390fecb30047001bc1ee6064a77b1dd88d8a60b08005b643c883d5a37eac54d012af58de4d8c0e87e981f744f948f98001722bab0913e56318dfb05859b600e6161e13e541aa1933df7d7be69bd3df1dfe3bf6c3de1d69190f3dfa052c85057774b87c59586c74fcaa7eacfd8a776171b5e2dd0509911e1303836042c35eafe2d45f9d1e1bb328828235fef0a1c3c6befa5ec4d2f0d855f111ef26c6c4be17b72c8c8ae8b07a252e3e6c6978d8e298a5701bfedeab8ba317bc1a1e1b0d8bb6b857f14f03432836de4130b3f10c1fccbcdca7f345bf09c1cb3b58a825ca3dfafdc7d28f8c8d88888d8f897b3506e6634be36357e14cf883e58c996fbe6d29e70be65d9d59b49a4fad9c1916f7de7f385ff110651c5b33092b67c62c9b1e1b1d831b07d7937c71745cfcd480b767be1bf0f6bb7ed3a6cf9c3d48be6ca56fc4e2b05511e1383353c17d6ec2cae971b101e1f3e583e58351bf95a0ab803eacf45fd5691ec002db6133cf0a4300a11f30580198c722f0fd4e33be9fc7bacfb1c2ba0fb14ec345f0787cb804ec25e45ca23fb9c87ff312ff2f5f2fa740df9fcbc0dbea1ee36172e7bd2fb8cd63dd83412e60ef3f0379f02fc03a5e2e4ea633d23d15fab174c66c01d76f95555c07b2baba796533725176a7dde7d97f9c3637fd399cf47f4a61ec9c53193fad6cfa8b21ed2f01ed0087d4cef4b1bf6556693e62efb1fdf3b37dcbd5fa5a5733dfa7abb9fdb580407ffa2e7a69242d035581b45c1ac6bc271b3a6cb872c4c851a3c78c0d5b408547445a4276daab26bdeeebe7df61cf4a39e71acab9e481618172ecef9580a591f817d35572265c5723026fb4f4f30ca725d48cb9d5dc6c7e64ae31979993cdc88cda512b6a468f500d2ab3ac55201ff2d68b277628524cafdcd87ee1f219c1f53d576dc253bfb97cef1f577a7806dc7e65d48837df3e70e13dcfd71a373ef9febd59c41eedb1b2906bbb53f7ec3c347c58fd15c13f4cc3bf1fbedcfdb2e2c7e10f03d6cc19ebbd53fcf6b3f620c7fca7635ddfa73c5f1f56f6d98425b76efc38ffbb27860f3f2bbafd75f887fedf5d0ff2967bf55f6050576f54bcb6fbeed8dd03ef7dbccfebb5b9b6ff9892b2fb81cb8da8a3ebc6fafdbdcf1717d7bdb6bcd4f0a96ed5c2922153e7de9c76b264ddfabab3af4d9b38f1c3a3a35eb23fded67a212cdd31f1dbbfdd7e2da87cdfae401f69d889ef5f8a70bd354b66bcd4f09a4df527cb2676f9d7fcdaf96fb9d7334edbb357b299b65f11b176ca94e4d79ca69edd5c20cfe2cd083de999307cd18c0b9b875f18346defedf9134fcd1f9fbd6ded9cc5332e4ccf6e1834d13e426697909291b0e2ece469915b9a674dff7ae6bc886f4fe777db73a0c8d5f4897f1f8df15efb46b735c5d7736fb46c7df6cb47fbdf7a7d246f34f1c5a8c5ca98d33fe7dc4d3eab3eaadfa76a9efeccf3bd8ae5ef954ea8dc73d11cd077e5f1ef3b7452fe68eba1652fedfbfba9add15df554507ad66df5088eee22f9d725ae5c3be4b3c5ee393b7446f8bc5d11ef793babeb75564e7ff3ed8059208774719dfefaea2f60ae738c4191d53dc6742bf31eb82f61cd47409e64efbb1d84f9e35f8075bc5cf43fc4c88fc0df975f32660bb87ec758c5e55cdcd56d2d6bbe6c65eff2f51fa7cd4dff28277d6fd66e259bee3bacbc7214fa43482712107bb0337decefaa55fab3d8f4b13dddd87fd29f747a18842fae77b93cd3a1eb25e8b8580b157d112fb818f749f4c57bc1855de57fa44cff87ae5ddf9acd185f03b6b1083fd769c6f7db58f72d56d87301d6638f3afa4ee66516c1bed32298774c5e42f6fda8a0b38fc5575923fb5ef909fb7eb3a9abfbffd72f8295dd94e7ff36a2c792bafb3784c8f67f3547ffbdfe7bfdf7faeff5dfebff4fd71d765cb5c8668e143777952e1c398823c770e4648e9cc5910b397225476672e4468edcc7914738f20c475ee5c83b1cd9cc91e296aed285230771e4188e9ccc91b338722147aee4c84c8edcc891fb38f208479ee1c8ab1c7987239b3952fcb4ab74e1c8411c3986232773e42c8e5cc8912b393293233772e43e8e3cc2916738f22a47dee1c8668e143feb2a5d387210478ee1c8c91c398b231772e44a8ecce4c88d1cb98f238f70e4198ebcca917738b29923c5ad5da50b470ee2c8311c3999236771e4428e5cc991991cb99123f771e4118e3cc3915739f20e473673a4b8adab74e1c8411c3986232773e42c8e5cc8912b393293233772e43e8e3cc2916738f22a47dee1c8668e14b777952e1c398823c770e4648e9cc5910b397225476672e4468edcc7914738f20c475ee5c83b1cd9cc91627357e9c2918338720c474ee6c8591cb9902357726426476ee4c87d1c798423cf70e4558eb45c66f31fbdeffde7afff747cffa9ebf5ffcbddd77ec9b46b4961d7f675f995d5ab078cacf9e93f23cd5d2efc5e43f5f6eb01017f90c33f73672ecb7ba3ce9899f7463ecb6c3aca95fcc05bf6a711fdc5ebff019e470e55'
        ISP_PROG = binascii.unhexlify(ISP_PROG)
        ISP_PROG = zlib.decompress(ISP_PROG)

        def printProgressBar (iteration, total, prefix = '', suffix = '', filename = '', decimals = 1, length = 100, fill = '='):
            """
            Call in a loop to create terminal progress bar
            @params:
                iteration   - Required  : current iteration (Int)
                total       - Required  : total iterations (Int)
                prefix      - Optional  : prefix string (Str)
                suffix      - Optional  : suffix string (Str)
                decimals    - Optional  : positive number of decimals in percent complete (Int)
                length      - Optional  : character length of bar (Int)
                fill        - Optional  : bar fill character (Str)
            """
            percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
            filledLength = int(length * iteration // total)
            bar = fill * filledLength + '-' * (length - filledLength)
            KFlash.log('\r%s |%s| %s%% %s' % (prefix, bar, percent, suffix), end = '\r')
            # Print New Line on Complete
            if iteration == total:
                KFlash.log()
            if callback:
                fileTypeStr = filename
                if prefix == "Downloading ISP:":
                    fileTypeStr = "ISP"
                elif prefix == "Programming BIN:" and fileTypeStr == "":
                    fileTypeStr = "BIN"
                callback(fileTypeStr, iteration, total, suffix)

        def slip_reader(port):
            partial_packet = None
            in_escape = False

            while True:
                waiting = port.inWaiting()
                read_bytes = port.read(1 if waiting == 0 else waiting)
                if read_bytes == b'':
                    raise_exception( Exception("Timed out waiting for packet %s" % ("header" if partial_packet is None else "content")) )
                for b in read_bytes:

                    if type(b) is int:
                        b = bytes([b])  # python 2/3 compat

                    if partial_packet is None:  # waiting for packet header
                        if b == b'\xc0':
                            partial_packet = b""
                        else:
                            raise_exception( Exception('Invalid head of packet (%r)' % b) )
                    elif in_escape:  # part-way through escape sequence
                        in_escape = False
                        if b == b'\xdc':
                            partial_packet += b'\xc0'
                        elif b == b'\xdd':
                            partial_packet += b'\xdb'
                        else:
                            raise_exception( Exception('Invalid SLIP escape (%r%r)' % (b'\xdb', b)) )
                    elif b == b'\xdb':  # start of escape sequence
                        in_escape = True
                    elif b == b'\xc0':  # end of packet
                        yield partial_packet
                        partial_packet = None
                    else:  # normal byte in packet
                        partial_packet += b


        class ISPResponse:
            class ISPOperation(Enum):
                ISP_ECHO = 0xC1
                ISP_NOP = 0xC2
                ISP_MEMORY_WRITE = 0xC3
                ISP_MEMORY_READ = 0xC4
                ISP_MEMORY_BOOT = 0xC5
                ISP_DEBUG_INFO = 0xD1
                ISP_CHANGE_BAUDRATE = 0xc6

            class ErrorCode(Enum):
                ISP_RET_DEFAULT = 0
                ISP_RET_OK = 0xE0
                ISP_RET_BAD_DATA_LEN = 0xE1
                ISP_RET_BAD_DATA_CHECKSUM = 0xE2
                ISP_RET_INVALID_COMMAND = 0xE3

            @staticmethod
            def parse(data):
                # type: (bytes) -> (int, int, str)
                op = 0
                reason = 0
                text = ''

                if (sys.version_info > (3, 0)):
                    op = int(data[0])
                    reason = int(data[1])
                else:
                    op = ord(data[0])
                    reason = ord(data[1])

                try:
                    if ISPResponse.ISPOperation(op) == ISPResponse.ISPOperation.ISP_DEBUG_INFO:
                        text = data[2:].decode()
                except ValueError:
                    KFlash.log('Warning: recv unknown op', op)

                return (op, reason, text)


        class FlashModeResponse:
            class Operation(Enum):
                ISP_DEBUG_INFO = 0xD1
                ISP_NOP = 0xD2
                ISP_FLASH_ERASE = 0xD3
                ISP_FLASH_WRITE = 0xD4
                ISP_REBOOT = 0xD5
                ISP_UARTHS_BAUDRATE_SET = 0xD6
                FLASHMODE_FLASH_INIT = 0xD7

            class ErrorCode(Enum):
                ISP_RET_DEFAULT = 0
                ISP_RET_OK = 0xE0
                ISP_RET_BAD_DATA_LEN = 0xE1
                ISP_RET_BAD_DATA_CHECKSUM = 0xE2
                ISP_RET_INVALID_COMMAND = 0xE3
                ISP_RET_BAD_INITIALIZATION = 0xE4

            @staticmethod
            def parse(data):
                # type: (bytes) -> (int, int, str)
                op = 0
                reason = 0
                text = ''

                if (sys.version_info > (3, 0)):
                    op = int(data[0])
                    reason = int(data[1])
                else:
                    op = ord(data[0])
                    reason = ord(data[1])

                if FlashModeResponse.Operation(op) == FlashModeResponse.Operation.ISP_DEBUG_INFO:
                    text = data[2:].decode()

                return (op, reason, text)


        def chunks(l, n):
            """Yield successive n-sized chunks from l."""
            for i in range(0, len(l), n):
                yield l[i:i + n]

        class TerminalSize:
            @staticmethod
            def getTerminalSize():
                import platform
                current_os = platform.system()
                tuple_xy=None
                if current_os == 'Windows':
                    tuple_xy = TerminalSize._getTerminalSize_windows()
                    if tuple_xy is None:
                        tuple_xy = TerminalSize._getTerminalSize_tput()
                        # needed for window's python in cygwin's xterm!
                if current_os == 'Linux' or current_os == 'Darwin' or  current_os.startswith('CYGWIN'):
                    tuple_xy = TerminalSize._getTerminalSize_linux()
                if tuple_xy is None:
                    # Use default value
                    tuple_xy = (80, 25)      # default value
                return tuple_xy

            @staticmethod
            def _getTerminalSize_windows():
                res=None
                try:
                    from ctypes import windll, create_string_buffer

                    # stdin handle is -10
                    # stdout handle is -11
                    # stderr handle is -12

                    h = windll.kernel32.GetStdHandle(-12)
                    csbi = create_string_buffer(22)
                    res = windll.kernel32.GetConsoleScreenBufferInfo(h, csbi)
                except:
                    return None
                if res:
                    import struct
                    (bufx, bufy, curx, cury, wattr,
                    left, top, right, bottom, maxx, maxy) = struct.unpack("hhhhHhhhhhh", csbi.raw)
                    sizex = right - left + 1
                    sizey = bottom - top + 1
                    return sizex, sizey
                else:
                    return None

            @staticmethod
            def _getTerminalSize_tput():
                # get terminal width
                # src: http://stackoverflow.com/questions/263890/how-do-i-find-the-width-height-of-a-terminal-window
                try:
                    import subprocess
                    proc=subprocess.Popen(["tput", "cols"],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
                    output=proc.communicate(input=None)
                    cols=int(output[0])
                    proc=subprocess.Popen(["tput", "lines"],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
                    output=proc.communicate(input=None)
                    rows=int(output[0])
                    return (cols,rows)
                except:
                    return None

            @staticmethod
            def _getTerminalSize_linux():
                def ioctl_GWINSZ(fd):
                    try:
                        import fcntl, termios, struct, os
                        cr = struct.unpack('hh', fcntl.ioctl(fd, termios.TIOCGWINSZ,'1234'))
                    except:
                        return None
                    return cr
                cr = ioctl_GWINSZ(0) or ioctl_GWINSZ(1) or ioctl_GWINSZ(2)
                if not cr:
                    try:
                        fd = os.open(os.ctermid(), os.O_RDONLY)
                        cr = ioctl_GWINSZ(fd)
                        os.close(fd)
                    except:
                        pass
                if not cr:
                    try:
                        cr = (os.env['LINES'], os.env['COLUMNS'])
                    except:
                        return None
                return int(cr[1]), int(cr[0])

            @staticmethod
            def get_terminal_size(fallback=(100, 24), terminal = False):
                try:
                    columns, rows = TerminalSize.getTerminalSize()
                    if not terminal:
                        if not terminal_auto_size:
                            columns, rows = terminal_size
                except:
                    columns, rows = fallback

                return columns, rows

        class MAIXLoader:
            def change_baudrate(self, baudrate):
                KFlash.log(INFO_MSG,"Selected Baudrate: ", baudrate, BASH_TIPS['DEFAULT'])
                out = struct.pack('III', 0, 4, baudrate)
                crc32_checksum = struct.pack('I', binascii.crc32(out) & 0xFFFFFFFF)
                out = struct.pack('HH', 0xd6, 0x00) + crc32_checksum + out
                self.write(out)
                time.sleep(0.05)
                self._port.baudrate = baudrate
                if args.Board == "goE":
                    if baudrate >= 4500000:
                        # OPENEC super baudrate
                        KFlash.log(INFO_MSG, "Enable OPENEC super baudrate!!!",  BASH_TIPS['DEFAULT'])
                        if baudrate == 4500000:
                            self._port.baudrate = 300
                        if baudrate == 6000000:
                            self._port.baudrate = 250
                        if baudrate == 7500000:
                            self._port.baudrate = 350

            def change_baudrate_stage0(self, baudrate):
                # Dangerous, here are dinosaur infested!!!!!
                # Don't touch this code unless you know what you are doing
                # Stage0 baudrate is fixed
                # Contributor: [@rgwan](https://github.com/rgwan)
                #              rgwan <dv.xw@qq.com>
                baudrate = 1500000
                if args.Board == "goE" or args.Board == "trainer":
                    KFlash.log(INFO_MSG,"Selected Stage0 Baudrate: ", baudrate, BASH_TIPS['DEFAULT'])
                    # This is for openec, contained ft2232, goE and trainer
                    KFlash.log(INFO_MSG,"FT2232 mode", BASH_TIPS['DEFAULT'])
                    baudrate_stage0 = int(baudrate * 38.6 / 38)
                    out = struct.pack('III', 0, 4, baudrate_stage0)
                    crc32_checksum = struct.pack('I', binascii.crc32(out) & 0xFFFFFFFF)
                    out = struct.pack('HH', 0xc6, 0x00) + crc32_checksum + out
                    self.write(out)
                    time.sleep(0.05)
                    self._port.baudrate = baudrate

                    retry_count = 0
                    while 1:
                        self.checkKillExit()
                        retry_count = retry_count + 1
                        if retry_count > 3:
                            err = (ERROR_MSG,'Fast mode failed, please use slow mode by add parameter ' + BASH_TIPS['GREEN'] + '--Slow', BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        try:
                            self.greeting()
                            break
                        except TimeoutError:
                            pass
                elif args.Board == "dan" or args.Board == "bit" or args.Board == "kd233":
                    KFlash.log(INFO_MSG,"CH340 mode", BASH_TIPS['DEFAULT'])
                    # This is for CH340, contained dan, bit and kd233
                    baudrate_stage0 = int(baudrate * 38.4 / 38)
                    # CH340 can not use this method, test failed, take risks at your own risk
                else:
                    # This is for unknown board
                    KFlash.log(WARN_MSG,"Unknown mode", BASH_TIPS['DEFAULT'])

            def __init__(self, port='/dev/ttyUSB1', baudrate=115200):
                # configure the serial connections (the parameters differs on the device you are connecting to)
                self._port = serial.Serial(
                    port=port,
                    baudrate=baudrate,
                    parity=serial.PARITY_NONE,
                    stopbits=serial.STOPBITS_ONE,
                    bytesize=serial.EIGHTBITS,
                    timeout=0.1
                )
                KFlash.log(INFO_MSG, "Default baudrate is", baudrate, ", later it may be changed to the value you set.",  BASH_TIPS['DEFAULT'])

                self._port.isOpen()
                self._slip_reader = slip_reader(self._port)
                self._kill_process = False

            """ Read a SLIP packet from the serial port """

            def read(self):
                return next(self._slip_reader)

            """ Write bytes to the serial port while performing SLIP escaping """

            def write(self, packet):
                buf = b'\xc0' \
                      + (packet.replace(b'\xdb', b'\xdb\xdd').replace(b'\xc0', b'\xdb\xdc')) \
                      + b'\xc0'
                #KFlash.log('[WRITE]', binascii.hexlify(buf))
                return self._port.write(buf)

            def read_loop(self):
                #out = b''
                # while self._port.inWaiting() > 0:
                #     out += self._port.read(1)

                # KFlash.log(out)
                while 1:
                    sys.stdout.write('[RECV] raw data: ')
                    sys.stdout.write(binascii.hexlify(self._port.read(1)).decode())
                    sys.stdout.flush()

            def recv_one_return(self):
                timeout_init = time.time()
                data = b''
                # find start boarder
                #sys.stdout.write('[RECV one return] raw data: ')
                while 1:
                    if time.time() - timeout_init > ISP_RECEIVE_TIMEOUT:
                        raise TimeoutError
                    c = self._port.read(1)
                    #sys.stdout.write(binascii.hexlify(c).decode())
                    sys.stdout.flush()
                    if c == b'\xc0':
                        break

                in_escape = False
                while 1:
                    if time.time() - timeout_init > ISP_RECEIVE_TIMEOUT:
                        self.raise_exception( TimeoutError )
                    c = self._port.read(1)
                    #sys.stdout.write(binascii.hexlify(c).decode())
                    sys.stdout.flush()
                    if c == b'\xc0':
                        break

                    elif in_escape:  # part-way through escape sequence
                        in_escape = False
                        if c == b'\xdc':
                            data += b'\xc0'
                        elif c == b'\xdd':
                            data += b'\xdb'
                        else:
                            self.raise_exception( Exception('Invalid SLIP escape (%r%r)' % (b'\xdb', c)) )
                    elif c == b'\xdb':  # start of escape sequence
                        in_escape = True

                    data += c

                #sys.stdout.write('\n')
                return data

            # kd233 or open-ec or new cmsis-dap
            def reset_to_isp_kd233(self):
                self._port.setDTR (False)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW, IO16 to HIGH --')
                # Pull reset down and keep 10ms
                self._port.setDTR (True)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- IO16 to LOW, RESET to HIGH --')
                # Pull IO16 to low and release reset
                self._port.setRTS (True)
                self._port.setDTR (False)
                time.sleep(0.1)
            def reset_to_boot_kd233(self):
                self._port.setDTR (False)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW --')
                # Pull reset down and keep 10ms
                self._port.setDTR (True)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to HIGH, BOOT --')
                # Pull IO16 to low and release reset
                self._port.setRTS (False)
                self._port.setDTR (False)
                time.sleep(0.1)

            #dan dock
            def reset_to_isp_dan(self):
                self._port.setDTR (False)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW, IO16 to HIGH --')
                # Pull reset down and keep 10ms
                self._port.setDTR (False)
                self._port.setRTS (True)
                time.sleep(0.1)
                #KFlash.log('-- IO16 to LOW, RESET to HIGH --')
                # Pull IO16 to low and release reset
                self._port.setRTS (False)
                self._port.setDTR (True)
                time.sleep(0.1)
            def reset_to_boot_dan(self):
                self._port.setDTR (False)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW --')
                # Pull reset down and keep 10ms
                self._port.setDTR (False)
                self._port.setRTS (True)
                time.sleep(0.1)
                #KFlash.log('-- RESET to HIGH, BOOT --')
                # Pull IO16 to low and release reset
                self._port.setRTS (False)
                self._port.setDTR (False)
                time.sleep(0.1)

            # maix goD for old cmsis-dap firmware
            def reset_to_isp_goD(self):
                self._port.setDTR (True)   ## output 0
                self._port.setRTS (True)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW --')
                # Pull reset down and keep 10ms
                self._port.setRTS (False)
                self._port.setDTR (True)
                time.sleep(0.1)
                #KFlash.log('-- RESET to HIGH, BOOT --')
                # Pull IO16 to low and release reset
                self._port.setRTS (False)
                self._port.setDTR (True)
                time.sleep(0.1)
            def reset_to_boot_goD(self):
                self._port.setDTR (False)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW --')
                # Pull reset down and keep 10ms
                self._port.setRTS (False)
                self._port.setDTR (True)
                time.sleep(0.1)
                #KFlash.log('-- RESET to HIGH, BOOT --')
                # Pull IO16 to low and release reset
                self._port.setRTS (True)
                self._port.setDTR (True)
                time.sleep(0.1)

            # maix goE for openec or new cmsis-dap  firmware
            def reset_to_boot_maixgo(self):
                self._port.setDTR (False)
                self._port.setRTS (False)
                time.sleep(0.1)
                #KFlash.log('-- RESET to LOW --')
                # Pull reset down and keep 10ms
                self._port.setRTS (False)
                self._port.setDTR (True)
                time.sleep(0.1)
                #KFlash.log('-- RESET to HIGH, BOOT --')
                # Pull IO16 to low and release reset
                self._port.setRTS (False)
                self._port.setDTR (False)
                time.sleep(0.1)

            def greeting(self):
                self._port.write(b'\xc0\xc2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0')
                op, reason, text = ISPResponse.parse(self.recv_one_return())

                #KFlash.log('MAIX return op:', ISPResponse.ISPOperation(op).name, 'reason:', ISPResponse.ErrorCode(reason).name)


            def flash_greeting(self):
                retry_count = 0
                while 1:
                    self.checkKillExit()
                    self._port.write(b'\xc0\xd2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0')
                    retry_count = retry_count + 1
                    try:
                        op, reason, text = FlashModeResponse.parse(self.recv_one_return())
                    except IndexError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Index Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except TimeoutError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Timeout Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Unexcepted Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    # KFlash.log('MAIX return op:', FlashModeResponse.Operation(op).name, 'reason:',
                    #      FlashModeResponse.ErrorCode(reason).name)
                    if FlashModeResponse.Operation(op) == FlashModeResponse.Operation.ISP_NOP and FlashModeResponse.ErrorCode(reason) == FlashModeResponse.ErrorCode.ISP_RET_OK:
                        KFlash.log(INFO_MSG,"Boot to Flashmode Successfully",BASH_TIPS['DEFAULT'])
                        self._port.flushInput()
                        self._port.flushOutput()
                        break
                    else:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Unexcepted Return recevied, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue

            def boot(self, address=0x80000000):
                KFlash.log(INFO_MSG,"Booting From " + hex(address),BASH_TIPS['DEFAULT'])

                out = struct.pack('II', address, 0)

                crc32_checksum = struct.pack('I', binascii.crc32(out) & 0xFFFFFFFF)

                out = struct.pack('HH', 0xc5, 0x00) + crc32_checksum + out  # op: ISP_MEMORY_WRITE: 0xc3
                self.write(out)

            def recv_debug(self):
                op, reason, text = ISPResponse.parse(self.recv_one_return())
                #KFlash.log('[RECV] op:', ISPResponse.ISPOperation(op).name, 'reason:', ISPResponse.ErrorCode(reason).name)
                if text:
                    KFlash.log('-' * 30)
                    KFlash.log(text)
                    KFlash.log('-' * 30)
                if ISPResponse.ErrorCode(reason) not in (ISPResponse.ErrorCode.ISP_RET_DEFAULT, ISPResponse.ErrorCode.ISP_RET_OK):
                    KFlash.log('Failed, retry, errcode=', hex(reason))
                    return False
                return True

            def flash_recv_debug(self):
                op, reason, text = FlashModeResponse.parse(self.recv_one_return())
                #KFlash.log('[Flash-RECV] op:', FlashModeResponse.Operation(op).name, 'reason:',
                #      FlashModeResponse.ErrorCode(reason).name)
                if text:
                    KFlash.log('-' * 30)
                    KFlash.log(text)
                    KFlash.log('-' * 30)

                if FlashModeResponse.ErrorCode(reason) not in (FlashModeResponse.ErrorCode.ISP_RET_OK, FlashModeResponse.ErrorCode.ISP_RET_OK):
                    KFlash.log('Failed, retry')
                    return False
                return True

            def init_flash(self, chip_type):
                chip_type = int(chip_type)
                KFlash.log(INFO_MSG,"Selected Flash: ",("In-Chip", "On-Board")[chip_type],BASH_TIPS['DEFAULT'])
                out = struct.pack('II', chip_type, 0)
                crc32_checksum = struct.pack('I', binascii.crc32(out) & 0xFFFFFFFF)
                out = struct.pack('HH', 0xd7, 0x00) + crc32_checksum + out
                '''Retry when it have error'''
                retry_count = 0
                while 1:
                    self.checkKillExit()
                    sent = self.write(out)
                    retry_count = retry_count + 1
                    try:
                        op, reason, text = FlashModeResponse.parse(self.recv_one_return())
                    except IndexError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to initialize flash",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Index Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except TimeoutError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to initialize flash",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Timeout Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to initialize flash",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Unexcepted Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    # KFlash.log('MAIX return op:', FlashModeResponse.Operation(op).name, 'reason:',
                    #      FlashModeResponse.ErrorCode(reason).name)
                    if FlashModeResponse.Operation(op) == FlashModeResponse.Operation.FLASHMODE_FLASH_INIT and FlashModeResponse.ErrorCode(reason) == FlashModeResponse.ErrorCode.ISP_RET_OK:
                        KFlash.log(INFO_MSG,"Initialization flash Successfully",BASH_TIPS['DEFAULT'])
                        break
                    else:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to initialize flash",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            self.raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Unexcepted Return recevied, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue

            def flash_dataframe(self, data, address=0x80000000):
                DATAFRAME_SIZE = 1024
                data_chunks = chunks(data, DATAFRAME_SIZE)
                #KFlash.log('[DEBUG] flash dataframe | data length:', len(data))
                total_chunk = math.ceil(len(data)/DATAFRAME_SIZE)

                time_start = time.time()
                for n, chunk in enumerate(data_chunks):
                    self.checkKillExit()
                    while 1:
                        self.checkKillExit()
                        #KFlash.log('[INFO] sending chunk', i, '@address', hex(address), 'chunklen', len(chunk))
                        out = struct.pack('II', address, len(chunk))

                        crc32_checksum = struct.pack('I', binascii.crc32(out + chunk) & 0xFFFFFFFF)

                        out = struct.pack('HH', 0xc3, 0x00) + crc32_checksum + out + chunk  # op: ISP_MEMORY_WRITE: 0xc3
                        sent = self.write(out)
                        #KFlash.log('[INFO]', 'sent', sent, 'bytes', 'checksum', binascii.hexlify(crc32_checksum).decode())

                        address += len(chunk)

                        if self.recv_debug():
                            break

                    columns, lines = TerminalSize.get_terminal_size((100, 24), terminal)
                    time_delta = time.time() - time_start
                    speed = ''
                    if (time_delta > 1):
                        speed = str(int((n + 1) * DATAFRAME_SIZE / 1024.0 / time_delta)) + 'kiB/s'
                    printProgressBar(n+1, total_chunk, prefix = 'Downloading ISP:', suffix = speed, length = columns - 35)

            def dump_to_flash(self, data, address=0):
                '''
                typedef struct __attribute__((packed)) {
                    uint8_t op;
                    int32_t checksum; /* All the fields below are involved in the calculation of checksum */
                    uint32_t address;
                    uint32_t data_len;
                    uint8_t data_buf[1024];
                } isp_request_t;
                '''

                DATAFRAME_SIZE = ISP_FLASH_DATA_FRAME_SIZE
                data_chunks = chunks(data, DATAFRAME_SIZE)
                #KFlash.log('[DEBUG] flash dataframe | data length:', len(data))



                for n, chunk in enumerate(data_chunks):
                    #KFlash.log('[INFO] sending chunk', i, '@address', hex(address))
                    out = struct.pack('II', address, len(chunk))

                    crc32_checksum = struct.pack('I', binascii.crc32(out + chunk) & 0xFFFFFFFF)

                    out = struct.pack('HH', 0xd4, 0x00) + crc32_checksum + out + chunk
                    #KFlash.log("[$$$$]", binascii.hexlify(out[:32]).decode())
                    retry_count = 0
                    while True:
                        try:
                            sent = self.write(out)
                            #KFlash.log('[INFO]', 'sent', sent, 'bytes', 'checksum', crc32_checksum)
                            self.flash_recv_debug()
                        except:
                            retry_count = retry_count + 1
                            if retry_count > MAX_RETRY_TIMES:
                                err = (ERROR_MSG,"Error Count Exceeded, Stop Trying",BASH_TIPS['DEFAULT'])
                                err = tuple2str(err)
                                self.raise_exception( Exception(err) )
                            continue
                        break
                    address += len(chunk)



            def flash_erase(self):
                #KFlash.log('[DEBUG] erasing spi flash.')
                self._port.write(b'\xc0\xd3\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0')
                op, reason, text = FlashModeResponse.parse(self.recv_one_return())
                #KFlash.log('MAIX return op:', FlashModeResponse.Operation(op).name, 'reason:',
                #      FlashModeResponse.ErrorCode(reason).name)

            def install_flash_bootloader(self, data):
                # Download flash bootloader
                self.flash_dataframe(data, address=0x80000000)

            def load_elf_to_sram(self, f):
                try:
                    from elftools.elf.elffile import ELFFile
                    from elftools.elf.descriptions import describe_p_type
                except ImportError:
                    err = (ERROR_MSG,'pyelftools must be installed, run '+BASH_TIPS['GREEN']+'`' + ('pip', 'pip3')[sys.version_info > (3, 0)] + ' install pyelftools`',BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    self.raise_exception( Exception(err) )

                elffile = ELFFile(f)
                if elffile['e_entry'] != 0x80000000:
                    KFlash.log(WARN_MSG,"ELF entry is 0x%x instead of 0x80000000" % (elffile['e_entry']), BASH_TIPS['DEFAULT'])

                for segment in elffile.iter_segments():
                    t = describe_p_type(segment['p_type'])
                    KFlash.log(INFO_MSG, ("Program Header: Size: %d, Virtual Address: 0x%x, Type: %s" % (segment['p_filesz'], segment['p_vaddr'], t)), BASH_TIPS['DEFAULT'])
                    if not (segment['p_vaddr'] & 0x80000000):
                        continue
                    if segment['p_filesz']==0 or segment['p_vaddr']==0:
                        KFlash.log("Skipped")
                        continue
                    self.flash_dataframe(segment.data(), segment['p_vaddr'])

            def flash_firmware(self, firmware_bin, aes_key = None, address_offset = 0, sha256Prefix = True, filename = ""):
                # type: (bytes, bytes, int, bool) -> None
                # Don't remove above code!

                #KFlash.log('[DEBUG] flash_firmware DEBUG: aeskey=', aes_key)

                if sha256Prefix == True:
                    # Add header to the firmware
                    # Format: SHA256(after)(32bytes) + AES_CIPHER_FLAG (1byte) + firmware_size(4bytes) + firmware_data
                    aes_cipher_flag = b'\x01' if aes_key else b'\x00'

                    # Encryption
                    if aes_key:
                        enc = AES_128_CBC(aes_key, iv=b'\x00'*16).encrypt
                        padded = firmware_bin + b'\x00'*15 # zero pad
                        firmware_bin = b''.join([enc(padded[i*16:i*16+16]) for i in range(len(padded)//16)])

                    firmware_len = len(firmware_bin)

                    data = aes_cipher_flag + struct.pack('I', firmware_len) + firmware_bin

                    sha256_hash = hashlib.sha256(data).digest()

                    firmware_with_header = data + sha256_hash

                    total_chunk = math.ceil(len(firmware_with_header)/ISP_FLASH_DATA_FRAME_SIZE)
                    # Slice download firmware
                    data_chunks = chunks(firmware_with_header, ISP_FLASH_DATA_FRAME_SIZE)  # 4kiB for a sector, 16kiB for dataframe
                else:
                    total_chunk = math.ceil(len(firmware_bin)/ISP_FLASH_DATA_FRAME_SIZE)
                    data_chunks = chunks(firmware_bin, ISP_FLASH_DATA_FRAME_SIZE)

                time_start = time.time()
                for n, chunk in enumerate(data_chunks):
                    self.checkKillExit()
                    chunk = chunk.ljust(ISP_FLASH_DATA_FRAME_SIZE, b'\x00')  # align by size of dataframe

                    # Download a dataframe
                    #KFlash.log('[INFO]', 'Write firmware data piece')
                    self.dump_to_flash(chunk, address= n * ISP_FLASH_DATA_FRAME_SIZE + address_offset)
                    columns, lines = TerminalSize.get_terminal_size((100, 24), terminal)
                    time_delta = time.time() - time_start
                    speed = ''
                    if (time_delta > 1):
                        speed = str(int((n + 1) * ISP_FLASH_DATA_FRAME_SIZE / 1024.0 / time_delta)) + 'kiB/s'
                    printProgressBar(n+1, total_chunk, prefix = 'Programming BIN:', filename=filename, suffix = speed, length = columns - 35)

            def kill(self):
                self._kill_process = True

            def checkKillExit(self):
                if self._kill_process:
                    self._port.close()
                    self._kill_process = False
                    raise Exception("Cancel")

        def open_terminal(reset):
            control_signal = '0' if reset else '1'
            control_signal_b = not reset
            import serial.tools.miniterm
            # For using the terminal with MaixPy the 'filter' option must be set to 'direct'
            # because some control characters are emited
            sys.argv = [sys.argv[0], _port, '115200', '--dtr='+control_signal, '--rts='+control_signal,  '--filter=direct']
            serial.tools.miniterm.main(default_port=_port, default_baudrate=115200, default_dtr=control_signal_b, default_rts=control_signal_b)
            sys.exit(0)

        boards_choices = ["kd233", "dan", "bit", "bit_mic", "goE", "goD", "maixduino", "trainer"]
        if terminal:
            parser = argparse.ArgumentParser()
            parser.add_argument("-p", "--port", help="COM Port", default="DEFAULT")
            parser.add_argument("-f", "--flash", help="SPI Flash type, 0 for SPI3, 1 for SPI0", default=1)
            parser.add_argument("-b", "--baudrate", type=int, help="UART baudrate for uploading firmware", default=115200)
            parser.add_argument("-l", "--bootloader", help="Bootloader bin path", required=False, default=None)
            parser.add_argument("-k", "--key", help="AES key in hex, if you need encrypt your firmware.", required=False, default=None)
            parser.add_argument("-v", "--version", help="Print version.", action='version', version='0.8.3')
            parser.add_argument("--verbose", help="Increase output verbosity", default=False, action="store_true")
            parser.add_argument("-t", "--terminal", help="Start a terminal after finish (Python miniterm)", default=False, action="store_true")
            parser.add_argument("-n", "--noansi", help="Do not use ANSI colors, recommended in Windows CMD", default=False, action="store_true")
            parser.add_argument("-s", "--sram", help="Download firmware to SRAM and boot", default=False, action="store_true")
            parser.add_argument("-B", "--Board",required=False, type=str, help="Select dev board", choices=boards_choices)
            parser.add_argument("-S", "--Slow",required=False, help="Slow download mode", default=False)
            parser.add_argument("firmware", help="firmware bin path")
            args = parser.parse_args()
        else:
            args = argparse.Namespace()
            setattr(args, "port", "DEFAULT")
            setattr(args, "flash", 1)
            setattr(args, "baudrate", 115200)
            setattr(args, "bootloader", None)
            setattr(args, "key", None)
            setattr(args, "verbose", False)
            setattr(args, "terminal", False)
            setattr(args, "noansi", False)
            setattr(args, "sram", False)
            setattr(args, "Board", None)
            setattr(args, "Slow", False)

        # udpate args for none terminal call
        if not terminal:
            args.port = dev
            args.baudrate = baudrate
            args.noansi = noansi
            args.sram = sram
            args.Board = board
            args.firmware = file

        if args.Board == "maixduino" or args.Board == "bit_mic":
            args.Board = "goE"

        if (args.noansi == True):
            BASH_TIPS = dict(NORMAL='',BOLD='',DIM='',UNDERLINE='',
                                DEFAULT='', RED='', YELLOW='', GREEN='',
                                BG_DEFAULT='', BG_WHITE='')
            ERROR_MSG   = BASH_TIPS['RED']+BASH_TIPS['BOLD']+'[ERROR]'+BASH_TIPS['NORMAL']
            WARN_MSG    = BASH_TIPS['YELLOW']+BASH_TIPS['BOLD']+'[WARN]'+BASH_TIPS['NORMAL']
            INFO_MSG    = BASH_TIPS['GREEN']+BASH_TIPS['BOLD']+'[INFO]'+BASH_TIPS['NORMAL']
            KFlash.log(INFO_MSG,'ANSI colors not used',BASH_TIPS['DEFAULT'])

        manually_set_the_board = False
        if args.Board:
            manually_set_the_board = True

        if args.port == "DEFAULT":
            if args.Board == "goE":
                list_port_info = list(serial.tools.list_ports.grep("0403")) #Take the second one
                if len(list_port_info) == 0:
                    err = (ERROR_MSG,"No vaild COM Port found in Auto Detect, Check Your Connection or Specify One by"+BASH_TIPS['GREEN']+'`--port/-p`',BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    raise_exception( Exception(err) )
                list_port_info.sort()
                if len(list_port_info) == 1:
                    _port = list_port_info[0].device
                elif len(list_port_info) > 1:
                    _port = list_port_info[1].device
                KFlash.log(INFO_MSG,"COM Port Auto Detected, Selected ", _port, BASH_TIPS['DEFAULT'])
            elif args.Board == "trainer":
                list_port_info = list(serial.tools.list_ports.grep("0403")) #Take the first one
                if(len(list_port_info)==0):
                    err = (ERROR_MSG,"No vaild COM Port found in Auto Detect, Check Your Connection or Specify One by"+BASH_TIPS['GREEN']+'`--port/-p`',BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    raise_exception( Exception(err) )
                list_port_info.sort()
                _port = list_port_info[0].device
                KFlash.log(INFO_MSG,"COM Port Auto Detected, Selected ", _port, BASH_TIPS['DEFAULT'])
            else:
                try:
                    list_port_info = next(serial.tools.list_ports.grep(VID_LIST_FOR_AUTO_LOOKUP)) #Take the first one within the list
                    _port = list_port_info.device
                    KFlash.log(INFO_MSG,"COM Port Auto Detected, Selected ", _port, BASH_TIPS['DEFAULT'])
                except StopIteration:
                    err = (ERROR_MSG,"No vaild COM Port found in Auto Detect, Check Your Connection or Specify One by"+BASH_TIPS['GREEN']+'`--port/-p`',BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    raise_exception( Exception(err) )
        else:
            _port = args.port
            KFlash.log(INFO_MSG,"COM Port Selected Manually: ", _port, BASH_TIPS['DEFAULT'])

        self.loader = MAIXLoader(port=_port, baudrate=115200)
        file_format = ProgramFileFormat.FMT_BINARY

        # 0. Check firmware
        try:
            firmware_bin = open(args.firmware, 'rb')
        except FileNotFoundError:
            err = (ERROR_MSG,'Unable to find the firmware at ', args.firmware, BASH_TIPS['DEFAULT'])
            err = tuple2str(err)
            raise_exception( Exception(err) )

        with open(args.firmware, 'rb') as f:
            file_header = f.read(4)
            #if file_header.startswith(bytes([0x50, 0x4B])):
            if file_header.startswith(b'\x50\x4B'):
                if ".kfpkg" != os.path.splitext(args.firmware)[1]:
                    KFlash.log(INFO_MSG, 'Find a zip file, but not with ext .kfpkg:', args.firmware, BASH_TIPS['DEFAULT'])
                else:
                    file_format = ProgramFileFormat.FMT_KFPKG

            #if file_header.startswith(bytes([0x7F, 0x45, 0x4C, 0x46])):
            if file_header.startswith(b'\x7f\x45\x4c\x46'):
                file_format = ProgramFileFormat.FMT_ELF
                if args.sram:
                    KFlash.log(INFO_MSG, 'Find an ELF file:', args.firmware, BASH_TIPS['DEFAULT'])
                else:
                    err = (ERROR_MSG, 'This is an ELF file and cannot be programmed to flash directly:', args.firmware, BASH_TIPS['DEFAULT'] , '\r\nPlease retry:', args.firmware + '.bin', BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    raise_exception( Exception(err) )

        # 1. Greeting.
        KFlash.log(INFO_MSG,"Trying to Enter the ISP Mode...",BASH_TIPS['DEFAULT'])

        retry_count = 0

        while 1:
            self.checkKillExit()
            try:
                retry_count = retry_count + 1
                if retry_count > 15:
                    err = (ERROR_MSG,"No vaild Kendryte K210 found in Auto Detect, Check Your Connection or Specify One by"+BASH_TIPS['GREEN']+'`-p '+('/dev/ttyUSB0', 'COM3')[sys.platform == 'win32']+'`',BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    raise_exception( Exception(err) )
                if args.Board == "dan" or args.Board == "bit" or args.Board == "trainer":
                    try:
                        KFlash.log('.', end='')
                        self.loader.reset_to_isp_dan()
                        self.loader.greeting()
                        break
                    except TimeoutError:
                        pass
                elif args.Board == "kd233":
                    try:
                        KFlash.log('_', end='')
                        self.loader.reset_to_isp_kd233()
                        self.loader.greeting()
                        break
                    except TimeoutError:
                        pass
                elif args.Board == "goE":
                    try:
                        KFlash.log('*', end='')
                        self.loader.reset_to_isp_kd233()
                        self.loader.greeting()
                        break
                    except TimeoutError:
                        pass
                elif args.Board == "goD":
                    try:
                        KFlash.log('#', end='')
                        self.loader.reset_to_isp_goD()
                        self.loader.greeting()
                        break
                    except TimeoutError:
                        pass
                else:
                    try:
                        KFlash.log('.', end='')
                        self.loader.reset_to_isp_dan()
                        self.loader.greeting()
                        args.Board = "dan"
                        KFlash.log()
                        KFlash.log(INFO_MSG,"Automatically detected dan/bit/trainer",BASH_TIPS['DEFAULT'])
                        break
                    except TimeoutError:
                        pass
                    try:
                        KFlash.log('_', end='')
                        self.loader.reset_to_isp_kd233()
                        self.loader.greeting()
                        args.Board = "kd233"
                        KFlash.log()
                        KFlash.log(INFO_MSG,"Automatically detected goE/kd233",BASH_TIPS['DEFAULT'])
                        break
                    except TimeoutError:
                        pass
                    try:
                        KFlash.log('.', end='')
                        self.loader.reset_to_isp_goD()
                        self.loader.greeting()
                        args.Board = "goD"
                        KFlash.log()
                        KFlash.log(INFO_MSG,"Automatically detected goD",BASH_TIPS['DEFAULT'])
                        break
                    except TimeoutError:
                        pass
                    try:
                        # Magic, just repeat, don't remove, it may unstable, don't know why.
                        KFlash.log('_', end='')
                        self.loader.reset_to_isp_kd233()
                        self.loader.greeting()
                        args.Board = "kd233"
                        KFlash.log()
                        KFlash.log(INFO_MSG,"Automatically detected goE/kd233",BASH_TIPS['DEFAULT'])
                        break
                    except TimeoutError:
                        pass
            except Exception as e:
                KFlash.log()
                raise_exception( Exception("Greeting fail, check serial port ("+str(e)+")" ) )

        # Don't remove this line
        # Dangerous, here are dinosaur infested!!!!!
        ISP_RECEIVE_TIMEOUT = 3

        KFlash.log()
        KFlash.log(INFO_MSG,"Greeting Message Detected, Start Downloading ISP",BASH_TIPS['DEFAULT'])

        if manually_set_the_board and (not args.Slow):
            if (args.baudrate >= 1500000) or args.sram:
                self.loader.change_baudrate_stage0(args.baudrate)

        # 2. download bootloader and firmware
        if args.sram:
            if file_format == ProgramFileFormat.FMT_KFPKG:
                err = (ERROR_MSG, "Unable to load kfpkg to SRAM")
                err = tuple2str(err)
                raise_exception( Exception(err) )
            elif file_format == ProgramFileFormat.FMT_ELF:
                self.loader.load_elf_to_sram(firmware_bin)
            else:
                self.loader.install_flash_bootloader(firmware_bin.read())
        else:
            # install bootloader at 0x80000000
            isp_loader = open(args.bootloader, 'rb').read() if args.bootloader else ISP_PROG
            self.loader.install_flash_bootloader(isp_loader)

        # Boot the code from SRAM
        self.loader.boot()

        if args.sram:
            # Dangerous, here are dinosaur infested!!!!!
            # Don't touch this code unless you know what you are doing
            self.loader._port.baudrate = args.baudrate
            KFlash.log(INFO_MSG,"Boot user code from SRAM", BASH_TIPS['DEFAULT'])
            if(args.terminal == True):
                open_terminal(False)
            msg = "Burn SRAM OK"
            raise_exception( Exception(msg) )

        # Dangerous, here are dinosaur infested!!!!!
        # Don't touch this code unless you know what you are doing
        self.loader._port.baudrate = 115200

        KFlash.log(INFO_MSG,"Wait For 0.1 second for ISP to Boot", BASH_TIPS['DEFAULT'])

        time.sleep(0.1)

        self.loader.flash_greeting()

        if args.baudrate != 115200:
            self.loader.change_baudrate(args.baudrate)
            KFlash.log(INFO_MSG,"Baudrate changed, greeting with ISP again ... ", BASH_TIPS['DEFAULT'])
            self.loader.flash_greeting()

        self.loader.init_flash(args.flash)

        if file_format == ProgramFileFormat.FMT_KFPKG:
            KFlash.log(INFO_MSG,"Extracting KFPKG ... ", BASH_TIPS['DEFAULT'])
            firmware_bin.close()
            with tempfile.TemporaryDirectory() as tmpdir:
                try:
                    with zipfile.ZipFile(args.firmware) as zf:
                        zf.extractall(tmpdir)
                except zipfile.BadZipFile:
                    err = (ERROR_MSG,'Unable to Decompress the kfpkg, your file might be corrupted.',BASH_TIPS['DEFAULT'])
                    err = tuple2str(err)
                    raise_exception( Exception(err) )

                fFlashList = open(os.path.join(tmpdir, 'flash-list.json'), "r")
                sFlashList = re.sub(r'"address": (.*),', r'"address": "\1",', fFlashList.read()) #Pack the Hex Number in json into str
                fFlashList.close()
                jsonFlashList = json.loads(sFlashList)
                for lBinFiles in jsonFlashList['files']:
                    self.checkKillExit()
                    KFlash.log(INFO_MSG,"Writing",lBinFiles['bin'],"into","0x%08x"%int(lBinFiles['address'], 0),BASH_TIPS['DEFAULT'])
                    with open(os.path.join(tmpdir, lBinFiles["bin"]), "rb") as firmware_bin:
                        self.loader.flash_firmware(firmware_bin.read(), None, int(lBinFiles['address'], 0), lBinFiles['sha256Prefix'], filename=lBinFiles['bin'])
        else:
            if args.key:
                aes_key = binascii.a2b_hex(args.key)
                if len(aes_key) != 16:
                    raise_exception( ValueError('AES key must by 16 bytes') )

                self.loader.flash_firmware(firmware_bin.read(), aes_key=aes_key)
            else:
                self.loader.flash_firmware(firmware_bin.read())

        # 3. boot
        if args.Board == "dan" or args.Board == "bit" or args.Board == "trainer":
            self.loader.reset_to_boot_dan()
        elif args.Board == "kd233":
            self.loader.reset_to_boot_kd233()
        elif args.Board == "goE":
            self.loader.reset_to_boot_maixgo()
        elif args.Board == "goD":
            self.loader.reset_to_boot_goD()
        else:
            KFlash.log(WARN_MSG,"Board unknown !! please press reset to boot!!")

        KFlash.log(INFO_MSG,"Rebooting...", BASH_TIPS['DEFAULT'])
        try:
            self.loader._port.close()
        except Exception:
            pass

        if(args.terminal == True):
            open_terminal(True)

    def kill(self):
        if self.loader:
            self.loader.kill()
        self.killProcess = True

    def checkKillExit(self):
        if self.killProcess:
            if self.loader:
                self.loader._port.close()
            raise Exception("Cancel")


def main():
    kflash = KFlash()
    try:
        kflash.process()
    except Exception as e:
        if str(e) == "Burn SRAM OK":
            sys.exit(0)
        kflash.log(str(e))
        sys.exit(1)

if __name__ == '__main__':
    main()
