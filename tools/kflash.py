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
        KFlash.print_callback = print_callback

    @staticmethod
    def log(*args, **kwargs):
        if KFlash.print_callback:
            KFlash.print_callback(*args, **kwargs)
        else:
            print(*args, **kwargs)

    def process(self, terminal=True, dev="", baudrate=1500000, board=None, sram = False, file="", callback=None, noansi=False, terminal_auto_size=False, terminal_size=(50, 1), slow_mode = False, addr=None, length=None):
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

        ISP_PROG = '789cedbd0d545357d63f7c6e929b1b10140d102cb14522a04ceb5851b1d53aa084285ac7fa01b6535be80511452b554b6dcb3421b9848816e905828253c40a96697dda418d152d5245ac9d765aa78afdd0a201828a1f5420a260fefbdc7b1320759e79def5bc6bfdd7bbde49d7cf7dcfd73efb9cb3f739fb9c7b2e1dbbefd6e71f5f22108186fe362c9a3469c3a2204014c614b30821363b7bc486ed8b27e9a288685d34315b379b98a39b43c4e86208b54e4dc4ea62098d4e43ccd5cd25e6e9e61171ba3862be6e3eb140b7807856f72cb150b790f8a3ee8f3b5ed9502e9ab4c167125a82d0ed7f02961040014b4440014bc440014b2440014b48a0802552a080251450c0121950c0120fa080259e40014b8601052cf1020a58e20d14b0643850c092114001661db44957ffa9e28a0cc9457ffb45fe9aa86f434854a79cf043b3885105af06f9241019d216cff6e11da36efb773d72f7d1be8ae6ca96eaf6fd1d7fbb7da8ebc8ddcffb665f8e6d8dbbbaf0c6e2cef8ee177a5feabf72b9adf5dad59b377eedece9bed7fba03f2c88f0091b37d2276cfc589fb0c79ff4090b8a1e1536eeb95161e39346853d9e312a2c48e71b36aec0376cfc6edfb0c73ff50d0baaf70f1bf79d7fd8f8cbfe618f77fa43f9d1507e34941f0de54743f940281f08e503a17c20941f03e5c740f931507e0c947f0cca3f06e51f83f28f6d08099a7227c4678a678eaf885e46a25b41b7ff34bafcd6a4f2e736f8f84da9489c9d742549f45ac56bb3375cd9204dae4c8e4d694b91be5ef97a6c665ba6e7aaea557169d7d23cdfac7e33eead6b6f0d4fdf9fbe70edcdb5c3ffbcffcf0bdfb9f90e056d3306e97ca8b1c448e358dd482a9818650cd68da25484dca8d2c9a97184af719cce970a21fc8c213a3f2a94f03786eafca93042610cd329a8f1448071bc2e809a408c364ed08da6c289478ce1ba47a8df1181c6dfe902a9c709a5f1719d927a8218637c4237869a483c6a9ca87b94fa3df198f1f7bac7e40411b401054de235367aa4b46543585427a3a1957644aacd106fd396c7dcc98c99b4012df2e9ae33fbe098e33f552412ea68225babd884909c54079833410f8c8d0ada54851462a4958bc5ffa0c56224d2676b719abe91f2676e61fe66843934f79929a4658d557f377da548c13c1afcb814404522a351401995d43e0ad701b5bc819078eedd916334331414c1d745c9cd10ab3f2d937bcf2da36704041011a9144184959c0834f6382e9c2035258dd545f498832278faeaef4b7421814612d15d8750a0518a74ea40064274ab88f5a344ba821d7f9958dcf940b58f42aa0f2844a8b3b52429d6743b0eff33ab4ebc8f924690871043aa10495cb6f0d20478f0d2307305793cf97899274853227349a3fa4041801cfe07255b97c82924aa252d51138d6e72a40fc8416a2616977c25279188b956105b92e097677db4e9a1926db260a9c46a1224dbf7cf94baad4b30c719b28351f4c60b28909261eeb9c07d553be2b94f2cdef197b59608d9212c276e4f3945f5d611237768c62398796219b5b44325e944c218755e81512693f811648db6fb657420e5ec5bdfe803ff5c0a28f9eafb25ba505c33bdf13cd40a6d8a0d6420b4ae15b1fe50eb7ba3ff72a82863480bb81e65ce21468a7bf4cbbacd19a11dfd09d5864deae0dbd22e956f275224834e484e7e648ee2f46d5f6bcb1835ff1cb4f719e129b14aa70e119eb51f7faa1e2be86b7364038ee79e83220bd41384e7c46945ea279c3a3d7587fa4967fe29bbd4539df9a7281339dd9b6eefa8e7b4708fd87e6d37af8f227bc739fe89b45fe3fba4ea5a19ed01bd77e12b55252572b611741bd252bdb8bc91f6365d2c1f13369f8835a9b9d849f636be97b53f55ac176dbc924ca8d5d0d31384f61c2f9e273ca11d3a2c29dff6f795e95ce9a7ec5770fd7b18aaf9435e2289fdca0f9a220b3132b8bd48136e98843c19861f4fe41c4ff477bd4687f098aa50179a9d8c47961829273b91b44390a54facee841ca409a76dce3069545e9da8348124f600651318c4daed2382c915dba45dc1b727b64c6e568dd9ede4fe73454af6caf1b28939056a417fbe266384b47b44887518f300b7946f273192055bc0bac67197b871ef50f939f96acff3bae9e4aa3dedd44acc2388fc9ff0883a3b9447d4c9c13cb4fdff131ee89ba13cd0f1c13c9074b0e5447de5b427217ccc9977454645f3c2aec5b7e33b5e687fa925a725b42fee6eb569e296c906d613f9c8872191f92dd094bcbf9ef0e8a84c94265fd9387b73c566d19b5756cf5e53b1865027010fd6de3b6286f15ed41123bda10555184b0d141a53166aa2379622b9074cb99661e82cb39009947aa06c33abf010e9d85ac3b8e85a8fa788593b2ff7adb08cc9587c57be532a8aef7ae1f62bedf217ae118a17c1debc16f47aac29585dd17ea67961df4b1d391d952de18689a6bf990ee5bdb23370586070e9962d63e9f73d505b622cac73d2b42b9b67bf59f1a6e8ad2b6b66a713ea102c1b8c6aa9c103e6d948829520519186be9929d68779a22be66ce3360ddfd312a1a70d48ae3070bdfd43becaaf1355e6c481f68c77f6f86ed62c01d943ca66eda835ed887adef2f1bf29df9fa092f25c8ad46beb58ea13f1ac93bc9d867d5248633b116ba84f4c9a5ab30d295e8750eca18ff02cde887ec8e7c3a11f934238f8942eacec0b5575fc88d09c338c53a6e3ff75d0027c87cd3a590a35cf3ac573d7543bb987550fe67ebe7228f7d82a2777cc9ba57c8255d53dc3d598a3d429a971ef769851f83553b3d70cebabbe6159c5aed85a851dd5161f42e7f2cdc04b7f2aa76286a2499053f9852a3c7ec46edce2e14325ab2a1fe0965ace73dbb4ebb7dc2a77f1dc785e2b473c696162611d47a968cfc548e3e11bfd09728a9aac6b9537d81dd95a7d2c890ee6ef8e0d3caf404c5e2d753baa37ffd3fcfe69bab0fe1e92ec9f7ab9eea98cb8db911e32147c37b42b421242541bc85816661a0ff5c20e69df1e8a40faa70c4898c7ff01fe864fb704cf3d2cf925515924f4f5eba514ac5e5f5122e58240a302652b746cc0dfbf31abb4552860417d6a3d4577db10f4e270e5b757d6cfde58b151b4f94a1aa11e8be7ae04abd9f6c037d9424950012537c6a04a33bdb30df9b62b5b2cb0327e5ea8fa4882ae5a94ed012d0d75d8827dbca51dc1ed78ed093708569b6c72e962d0aa6086f77d82b69592248210175fbe52989592ae24f2336a35031e7cecd8580fb5620eee3ff1197da31f123792a882fa21bfd468fb952da6c4f5eff969e8d4a6d98a04b03b4a73823587a223e6b239cf6754dcaeec38d39ed3f54dcbd9e6f8be17eebed4f5caed951dabdbd7b51c314f364d34541bb28de28622184f06911a3c4be91bf7a22f284c0fa22bd4973086f4463bda96c094974479e48dbc25efb68f1066641311529030b6b52c8ab585a1b2e3ba84a9fb94d1a6bcce9f76abe5a441686be265b16629d26b621011124cadc8d76b92317fa01b813fd611da50253225ec41bda872bd74635b726c5a659a74f5953767bf55f196e8ed2be9b3d756ac4d81bed06bbe47fa9893d0f2867c7d4c0bfa42826917ba22b9b85537eeb3047a5797b37f3f12ea36132159bd7b2d7a4d215893014ae27a3f40e2980320c30ff9af48566c25c631a911a985a85f91953fda969519f2bea5c701334e1b62120e5aa2d7ec5ea39b27f7baef60b7de77906b676d61e298b535990682b9556b9c124d5f4d153b474f5b4e848cae2f4a18532784f3f13ab5cc519f5a6b8a249e29b3b6eee8eb3c569359486cb37165af640e942d214236770a33d556bedceed4cb969acc18e2b21de7b65eaeea77e64e2c2042a2fb85b69af8dcb5a6678819866d28ad0e8f8135976ad1379e037d6940782c2aa81a9b86109f6945b33d6b52ef417c377ac53362f53d448497925b847e2b3ff5efc6ca5a56d5827b531f6340cc6a7e243e40fd8f289661af3b64173f26078431a9b12f257eb0d56c7e81a0b77bc876af899644afe1fbd1bc02e6936d4ffc854cb776cfbb589fdaaf68cdafb7d5524f47d397533d9e8835033f9609d9493a7d95a250a1ed415ba0bd8f92ede6db0e0758d5662284d1583dbb1fb045b0321544afac70e5d4becbf7fcb1b28c3a41be42e9c6caf5ff4ac3f8194a7fb2c65e487c769d93a53d9374ca92f29e5396c4ad5003577b5016c8124036f321edfaa1b28c1d24cb7166776a511dee0fdd7dccd9da5ad53921f626e36a9fd1c9b37c03d7be1f85f6ad19ca33942181abd03e6dadc74ca2565286361d13c358eb1b1b10376a8dadfca835760ba3365263dd693b9b3b4fe8c1da1d9f656ba347b2649464a41af650bc3f6b62c945123fc173d5e6b26490c4e9eb961b2b12597292e409d8a52922b85ecad99c81bdb6d08eb8764127eff379a3b6091c567a086d2b2fc84866494990732613eacb72b6bd3c1fa7e01c63639dbb44ed5b0a351e31324be0fe54a45486e4d21c914ecdeff05a9f11521e33a7726bf2337c89d6b714a932a48ab0cf147a7eaa4eed9424d10cabd74ac89d237d5a2185dcd2533b4dae5464e639a8df14fa69b22219ea94c444b292a07e451aa47998a679ad625a958b6efca25cd4ff139ed1b1efa092142033aef5036a9a2095f7e53a3dccd271cc2484bd8c3d12c2391f7ec0ad0338f7416ab230929ecfc2aab187da8df0aa46421f810fcdf77c0af8cf30f7c10ece8bd74f6b3fdef7c2decf8bf66915c9c94fbc05be7d72f2b87745228c10978fbe2fa73ef1b606b43e10d2efc9c96fbd1b2c9b33f0a849bbaa0d444c29ac67b4cd82f83d03f6a46b8c06246ea0d0c4165222c8d65b917219a4937684b74c6c16e2ecd929c129ce71c712f2758a7bb05c65d174602bd2d9184d59fdd87daa7212f526cc6260a7a9a18d36648aa5df6d02dfaadf52aa20092c636913156df5697d60d2d483cf71dc9bf6ef4625f5e0fb795db5b0d26fbdfb13ac23cff5e1984fbc53ea9e99136ea4334e88d84c3baab71ebbccbe2e753cb3e548b197d5cb164d59d7363d187905da213d11b5458acfc88a8b53b595484559d01ea905a9007b48a0803d12a0803d62a0803d22a0803d0450c01e0414007e6877f708b69841e7b6b1c524c1fd2b3ab7ed790b5b1c86f83a72b26ddad07bc5da7ac598fc59c5d68c137777599ecfa8eca8364c642a606f93d325e8d470b386f3cb967ddecc683e6f510654a4ccea3069667d7b746e781f494ebc1bdea55d556073cd61010b646013415c4f1fd28749863179ba5b7af059593b15b4c32627259e7ceaf16ff40a0921378789e96729e4910a3e6c4017c225366766297af355e3bb3c439949b20ae78c34ba7fe9c8cb1fc6fc773c83feb958bd40c63f6bf7e3d53994694bc66bb16073f66a269716e6cdce6a2343891bed8eb58e08a62a2acb0fcf31c1cd52f0fa550107916a7403ec5349a49a02184f7aaa66020d2245aa71a4686cac0e3c06c653f094ae98159cb7d9a5ece39f52ed339b85a7be992dfc93d181eece6cc7b28a9239ad57715a7fc4ecc7ad1cbebc54739ee1670bb247483f2a84bbf9b0b8810f335dcef242f88e907ec2d906613cfa67ced57d25d4c8db593fbf1bb7dd9dd9214b863dc9b8aec52c6558a29adeb518efef5493248b85b2b764abc8d8bdc22eaefca62cdd23f64b2174fc06a399793ac5a25cadb3e934d85af44d24313aa3e2ee99db67db73fa2abbbee938dff263f34b7dafdc5dd9b5faf6ba8edd7993b74c34849bce3596ad6d68c4a3a77fca13c9ed61881e45f9c088c6d15a2a8050ebe613f369346cbcc78d17723e54bf24f89d89b9b437194a92b59e9ba2e3b7d21bfe44bcb05596a84cf75d44775585c6c41c2ca3bf35845d62427384fcef29132bc0f5a9342b9b8598503a80f4a9ddb2338a54d33b3c114e15cef3c6655dd5477a1295a511c34aa36a0ce628d5f49de860df87e50379507b7fc293e79ed8a73fe281f4074ca8dea3ff42650ebda114fd983333d1eb0d5d687c4e1c936da6e3cb3d31afea9da6ad58ab54d3abd1e65e9da66d7decc6ca8dd2cd6d69b1ab2b574bd75c796bf6db156f8bb2aeac9dc578807e460e435a5d9c2e463e7fd8f115165c8bf818ae2526a6d268f5f07e2086fe9225b2af534174b6d4875ebb4b06cf73bf3c2359e4950e2baac87b5ba93709a33a065d33d79e2c14d3dd5d880ca995ec25e49954d48a1395b825bcb7f6a85feba71a55502fe22cc84649b0ddf5277c56876560e75f7710cfcae7df77782f302d9867f14a5f97132e9c5a1ecfc05254a4ca33ed16792a255305b4206587e4db9be65ac381686573ccc96bc66b067a433fba669425ceca39cfcc124a6a372f8fa9481df3fef2930189476044b8dede19e1bdcbd5db3af03443739c320665551b57747aa53b7b3f3198b776bb1dcb6ab228d3e9d62a0463ffd64511bd6117ba660885da04295f7b316686d11ca54c5c7e128ffe73f707463148fafc77132cd78cf49dbf123f1a6b1b9b44d361ecf0c8d5e6348944e66a83754e794feb417d2df47fad0911ea7a8fa2da52cf40945143cfff19e1917e891b67c839bffcc7ac63afe45c12ea8d5af362cc1543add118fde24965e2155c732d3eef08ed1b38ef88bbbbb02b7ccbfe2dac845c4cc490f3fbff64ea08667e7bd281cf39c49f81857c6840fd4fd1df7b2043e20f75fa040f827eeb3ed22b2610b4319338c32c66b277ce831d01acf3c32ed78dc9c8e9a868af6cc1e7178befe2d38d973a5e695fd9c21a37c1bad52ca2dfb48bd82eca61c167cf30efd15d66d1a71a653da17ed88946453a77a2214122ebcd037de126e74e8fa5d63f667e1e6610d3bcb174b359c2364d41ba30bc430d5428d0706aa119a5b252ca41fb7f8fd0aba6307ab851a24c0e48f75dd5595a612eb9e97bbd24559eaa4025b6a472795321ec606f8b89af0a3474ab4dc63625a352a351ecc68da41c596adae3000a48ce288d909aa3e8c50d9efd914c98f8808788f77699d1b4e8804f40727fac90e3e75332d6e68b942d35d24264867da6ea505300473f6ff26753fdd1d69b5baf95b5059b7dac4ead3bbe146667e2dcb1efb02ca894b2907b617d8f22691becb39b4e826436e92e0bc4f8f1315d10934915d4b1d2a8652cd54c595bdbbad8a67144a9b1917aa6ce379d9e2b45ca5585b7caaed5502d6882659a616a9d391e24f8f4900f473f3b341ce709362b53599b02296dbb80d7edc7c4874d88bed2e6efad27c202e3c3a2c8302616f7464df129ae476adaa48402977fe6bccc9796435ffb74f8b623abf6666013e49e1321b722b10578bc922aad793d15ed68eb2c958af1534158eba5ac8503bd1bad58687e3a7716239e924bd0a325a3c910f6f5a9285ad67a8fed8944f42ea912f36135771cbdf978afae9a6217e118a9984e869564b458099642880fe421f6cd930edab61345187746f56be8af6de1fc8a6bcc53a4e23d3ea5d5d2be747f42c4d63f11a1854f6fa177f504c8251251856b5e4accea4f08cfa3477407d11b19822e9d31d69c2e43ecd68eade22a2f34f67dce032db76da5fdd315ac6281987e8ff2d75b3c88f84279b22fd2daf87a8c7a3de40ea0e9d7ed08c7805f9dcda7a46643ec7abb928b9d69d72eab96c79b51412c7df994848d4f45a53939e2c01c7f14e8ef8f864b1716cb49a9c3e7153aa0414a6a4acf8746d5f83721aee7713f4c6afa55d6e1d38eaea29b1907bf8ba55b4fa152e921b21efc3fac2fa7101bdf081cdba45938c68f8fb143cceb54469d9c047d9182bea435dc65e3c388d29c53d4f3169fd5b4b401f9aeecdc695dd3f440b64e6df14df649efdc59935b1c45ffe95131afcdca55115421aa28de7e4b798dd3e65a1b4f6b6cd7585b00f2bae5755d69537de24f3c51437f25839c652bb16e95b52957e132236b271b461f8b56f8aee98fb4bedbd6ec7dac208cd78dd64bad35d5c68b75646a16f574617f66d6d6a283fa699eb032d0c53d9e5c1dc75269f9dbf7914e434bbd50bda606e6ba59a5644ac4962af44261965f4de60728c2f35e54c49bd5e8ac6b5c9b5f060ea3bb513043935ee0a97839828b88383c4a11644a74ad514384ef5424c0d806dbd7c9573fc2dbea81d48baa29f3096bce0c6b96865e97206634aa2930f3c17897a5769646c0fc4eb79a1168da699bc465bf01633eafa1f2a23f7b9fe3176e5f65aad35bf290dcb0e541740993579faf3a701fed8dad31e6a1425be1756ba6f167961946b8d6f8a39b6a614621847903fa99b3d2cf7bceea3ec71e757831eddbc0bdc1d16b4864dd66794092fd969ac6bd68575e04d5003b885d1afa6623aa36d2eb5b3df5a748c4500cb927bfe981f59aed01cca5af6f82b482338353d89e4cd46f615f373ae439d23efa76a3545f4322fddf18a4af2309711d43e83f2745e2cf1991b88614eb0f336298eb24aa4f3291f830e3501d4840aac3764275d446a83e6912ab0e348a55875345aaa30a31d89e447594726cb26c4fda4ded2655471b1f58af832c2db69e6c2d7d67afa426a701d1ef9c13b1ea1e874ed3afa0d96ed83b44187b90782e0596dc88c2cd2a4411172d11c66ea48f8538aa1b2457a1266455f4408b749a56e1a482795621e7bccb914278011f163f3226a3a23da763a261e8baf4376674476c725be2d0552744d8979d60abb74c6e71ee032b52f4d30c0e986145ac6913c10e9338e4bda71cf4bd48315ec9e4f73d1cfc6a962a06bfa6fc1e22e2f07ab69871e70dbbd261b09aadabeda313d2a6f2678fd4419f3535c6df1125a9b4ac07c937d91cb38a6429a469ec8d8cd21a8fab88f6e991c8c96122fad487921f4b6b4c69d1bc7e66d6b05747039d015eacc111cf046f617b47a39aab69846ae61487a08fb7f6d6d167d2889257cbd694dc525ebf64985a81ef37305be80269b07e8ac45163288d121f3120f99b671c713be91c2aa0c64343d0ca1e4f96823abfe9f52f5955962e979a1cf22d124279abe4ba9cd24ae89446192b5d2f3a6ba4fb4f21656259bb32b9ac03d665316d6d94444b58a344149058620d482eb105ac2ab95e634c26b0e4dccc1569afe4258f24ca9299bc9aaba984eac01422deb97f6bf9eea07255d96d657a59174db5213c47033fb1ba4eb91e9ec56577c59130164689a4a42fa3ae023c1061947e4aaba34fa579e3b672f2321202b719cb8fe566b1dccd8d9e726abd88ce6a44205f3bc8d721c752bf8aa586122265a2f2b23259d9aa5ca5bc5a925c9393169d154be6d518a710f4faf38fd4a45d4758d61a269960dbfc51616b496a3d19cff0de84d0e7ef385bd2dc84fbec622df4c0ed80f412684d0fd71aa8479c845bc348247c8bf4d0a2b2bee72cce9d66f937cf59e8a8d51e65e925ab9c6d71b5e166a3e4a16d58db887edb86b3a627ea1e567fe743eabf3c50ffa9cb9678e7891d1dbec52a22db701e39453a7a4b2f99e9121bd23fc538d8de2f1d6776acadc13272b2b5354a39d9de69940424065c0e480e68e564a31b45720afc678a247ce942ab6f6aa12d604dc9f50ac6d95789e9c4c18055015703d2036e70725230ea1429fa12cb4949c4ca4edf8d1016fb76d75baa8dc1c6b5754e599b6bd7d69d318da9a9b97a951b1ba76ff7f131bc0f0d374c64cc8ddc3953a5f3dcae39825f0f703c6ba4f696cd2938a13c5e91284ac6b71d70a989067d510801f9b959b9bc989e47a21757559b5f6c77e6c2bb812cfe9400f603372c78efc99f13c5b52f6c9176b176caa7da30d130d974c864fa0a7333c512b18286bf3db4b4de6f1c21da58b1fe9b9cb89c8ab4d969a10c3e5912ce87c821f2f0e5dfe84fc0fb203ab01bf567f60b5c9c9231c239c6dcf67e0b2e259c818d72f6c6df9869395c8ffc952a74f6080a1fdc233676688f1023f18cc31a53af87b6541b72e9e07629cca6a31b66ce33d984335742ac80d15550e27a96ed31a2cf6eb23d1461bab95753761cf66912bc4fcb5a86dfd05470ef680af298af1e4fd77dcd5231140d33bbf3ec062d50cd944870efa8c649106bb7f4e39628d361bfc6ed148d880fefe0ce5ee4140a827e1e4fe7da602fede4d1bc9e4bb32b10d9a85ca40a9520fc7e4cf9bd329d501f7370273e764a36f527e7be73afc59447680aac018b969fecac1ba233d554b6ebacb76f700f35ea86f6d0c0c9eec17a3cea83fb467b2b1ddfe4e17791dbfec5d9117f0ab0174bb7cbcae71992f2f164753a1276902662deb3e503ed2df79cb92adcb4a3d1eb8d50bcfb5f42a2ace705ee32884d77e68b9af6b01e6f9e827bfcf1b7755fbacedd232046cacb7efc172c8b2a00c64222f164f2b85336de263e703e3517f379d1254e469eeb9ff1f9681ce8f1ec347c46aa37f3d6213753e268169fa5622b019f03e1dea2df93fa90a9d843ff21bf44ad2ae946f4b3cde8f0f3745c33f83afc49ebecb40a8ed3f4e4ac26f187204f71a458552e41f48f52d9a255b8bd05793b1a953163de9d99bee3c4cce54093bdded0c5e23ee94fd0c783b58ce94665519b34748a5d16494505915444821d91794ffca33f9335dadf0948efce2f3553043e5b0d68c69a8175506e8e14d3cb29ec83fae2f205d6b9ed8fa7abcac711c7be73efcba020dc979f59bcde206219a859043587e7584775f794457df60bd4ccd8d0f31abad026c1e5c758589b94d3c0ac654fd6e93f6308eb168fdbe2cf48e49da7fa642a31c3e3a9689d66a4b5ecb9174f5a5704ddc23bff33390b73b851d694bbce4eb2eaaa77ccf0f830aab3ce794e1dd7eeae83518d58b38879074f70bac8eb4df2bfd045de12b306344cdb8273869bfe95de36eb07463eeae5a1233f30274e3448bb600f3f0fefdbbf0c11f42b19fbd364aa2195a5ecfd11066354674968e193da2cdfc912fae5161427ac4151b4bb1ee8d4aed3a40acca3d26c7da4bbaf86d44639e3b5e5306663ba45033913df1743cefed81aaa35cafacf9e7bd8b7667372fe52f80abff7f5db668e07abffafca8f922c98a76e2bdbe28b0c367302b679e3476573e2981920230eab3e32560bf6fd3ca92eb2d039e4a3f8ee4f684bb861bf41da21b42f5e7f107c951c8943784fe2cfda5b1d11393d2860a5783a4930a68c527acc69c911b3e9aad82271ec7877fbea23e6927501377daecb41a6923685063ca6594da384f7d485b083ecb0217e3eb6edda4a3bdf6f365f0d6666275f49c4f3abe28ec3012bc7a28036626ed165fd4189c33c17f2e7ae1ab1edddfde6adabe92d7e1efac339e0b3fb11aac387510dd986b6a630a6a2d623e680d5f41899d4ace6dedf79d10a8b54118bef3b9df7e2e893e7bd4a6e965c23e7f2d2614f5d69b5ca6577e5d4edc7e864bb44de1489f833034653636e443e29dfe57325a7f7484b29052a352bd0bb54b5b98496e7508eedc00bbc815b051672eec7753eeb7c6e055c5b61919f37a3911a3a09fc9ca654144819c5815285b02b0e2f66f95d71498394d10426844545986d4899b2221fbf25501db4a1ad37b75f2bbcea7bb3e1d87360eb8d501eef8ae5f81425b511c99b708c0d76c5727c8ac2c5d821261376c52cec8ae5f814e56ac35d795318114835f2bb62d8a504accc28b55eb73df0825d31ef23b8d6520b68c35e2ac8b95268ab8495c282b526ecb1a12bc5d48cd0d6fddc6a1e7c557a63b281fe19f65a4db0de954b119eb1995b2c85a2c6ec9b249be6dc7d8caa5869fd23d9f7abe6995432a537df2375473e6b81fdf41738a7b2594e92da09e5f02c513613ea6b8971c9d5c9de49fc6938b63e6917b63f53de4483e91f2cb59152362b3b188df25ba73d616b5a8a26c14c2c58704f454ab8c9f96e35ea04714358338336db3b4bf1bd053c67ada833db1ce08557bd7db403cf09b2665907cc4632ce1349557efb9e863981fd1ad71ce2417c89f3610e0a8e030e45a4f5c2f338a2a8ee373dfa11e5e9ecd1f2a2c13d4a79fed65fe34b72e5ca2999b3dc71e3e07246e9c3cb09e32771960a320d193ff1d052fc7fc34973136ebd6634d6e4ac5ff07c44a827eb457afcd62fb85d7d63a2817f6b55f59202f8c8a930c7d8f2024ab59f7a60bd617bc0bf4716f6fc7b85b7c8fceafe8187f0eeaabc4658690b1521dcfddce784b7560b781ab55478e3641066e17d42385b98177b14e71d0eb93474460543a8cd1a68e521ea1517e5f3740bbce6c952b3cde7eac25b9c5208fe4a96f39d6554a74283db51f59292eebc8fef2213eaef2cf824227aa4622af77ea8cce99f9687f331ada54278829cdcbe4478febd1c12cd919c3f597ac42caea190486f8e85bece697b5ea79966944b51d4d657e89d7b51b62249ad636b8c55a208d28ec0b30dbb2cb5b28d0f70ad7c8953f103250a6ee0fb4997636b8c4da223e65cabea008554872984df0c7125df6fecd369beae1b816e8f2034bf8f6cf522806756c211e37f45767be1d8fefbd95a56f62dc97f09b001e4c5be2f1ecfd096b8e60d13a23afb139c798f599defb7cabbc65c76cec2c8ee71c33523f70a3d775f1fa945a2edca94222bd85dab6a7a08a18b71dd62b163af187c8534de330e48eb5f6a1d15e6602865ebd5bafea55f5b8477669d43dfaa3577b96e40758c6e70bd259c8e6f460d7ed7a6efc4ab92b403af4b77c64539efcb743a4b1f6f1f903ee8fa80f4e8a630fbdc724a6fba85a5970c5e6778c9ae07a4d1452d084b7ccee22a7fcd1c032364f860665972bfc3d5daeb6b7b077601c4c8d016dcbb71cdd506dcbb427fb9dee4a25fc20d23afba3c5541bba2da94ab6845af4899dcaf50b6d0736f43ab25d07ac02409c2b28960073548becb2ecf5678171f74e56a1dbf564b3ba03f631096335cac96a091ad03d2952592926cf30d8b534a90711cfac45bb0d3a8f9223fa220822c12593423f0ac342e6259b7e84e18fa44976fbd51f580e7c3df39bd1316d54994c37fa0b7c4d7e6a697f1bc728eeea842dc9a555be59fad551cf4c0365e97ad7d6e19e4c277b4a7e7c8cc61dc3aff0e31529e7977c411b3be9142c1ed930de0950a3614f6ee1173688b1ef47cbf61e69fa7bf39e5f5c7d3c7af9af49ab423bb647c3b9642cec420be455953190ddd5b259293da7bb87da6afc40d249adc2237f9a16c73f0ca334c96efc8e3adddce95613233e0c161af72b2d0572d8aab75136e8cc9707fcf83dffdac6cc1f75575318a3898013ccff8f6bfa0980f4fc3feea7b70fe840534be992af710e1d3b150469a5699fcdbf73dbc74fa484fb4ad113c5d729958beb17b840a99903e721862bd462346b2e3443078c156ef8df7adc30cf7579afa47afb0e012f575210d7cbf5451253431f2d3547eec6699c5e38c0e7d58a3a3da20f2cd5610dbbdd52bb60af3eb448bfd9ea8d448c96a13ba4591ea11782e1b772511cf2635095da2d9c9114d55a21a7b95a804d6d7b2164177618498fae8911319b9542bd5e13b41cddc5da4ab1589b80578ade05bc2af33c21c3ecf3947265e186aa77413cca35c1e728533cff13e5e739c29adf1ce94a0fb4353d4cb5d6703bd4353f62e767df161e753c02f40de9a6d7974990de9f791486ebf4bd162bb6897869c4323bbc82587abb6a82e4183e79436cd25022f58a268a90cdffafd033ef50cbc701ac933a72372ee8c807614d8741765e50da7269b03c0679f65d66922865721f1c2e1a8f4d1a98824231ebd44d4d81a89c0e124b2ce19ee086c7a03f2cb8b02c4c3297a3e29a2478b45a6587ac405fc5e84b820626269ff0be0351a615f668c7eba587965ec3ee72eedeb3a5d58bfc52a153f38525c7645cea811b71a71d287a85d3dddeed6eebfd85049b49c9c84efc350f826a59c5c2f82b66bab5c6d576b5cfdd9e26c3b9912b85c4394266422c22f621349f4e7e19b9ef27316542a93218f06577f2cb723f91b7789e1b2c925e2a9b066dec5cfd5667a9858f44571ee2b81098d88891d9337c3dc86bfd4289e8622729b50447c03f735c669149823455675db03be3db38b65aff45a9c72354c77ca857ee2e5e266904355976045c44fc7aa7e06bdc32b2c3773343eee5c61c1f26f55214fd20201f059e6c0cc9437bab1640ea9de5c5a7202e68665834f3136c04a0133f22496d2caee583493eea44a26c929ad28826a1199ab38bfe8f2e7865966df574da7641b26b6641757a4dcc9944c32a5821de5dea9a2266df099874b8b6aa82e51a5b9648db7b52c75c73f223548345cf27421ff0ede39cf4ce4e619f060b9ba0666dcfd062c07fef609d7ef5ab1ee8c9228f6cab03d9c0f2e5226ed38214bc9360fadfd4e6acc247e5de5ad7545c626758eb3e7de067f41a2537b32bcc56af713b1f8e68a5c6c7d462e433ef284f828d63f14b17e61a80ced2cfebca86c36d8499f7c530f517ade48305b6a8b2b514d9b3f319652959febf3a40ad134b33e94ea2b6d32134c5eadb90a9dcb5705d9fbc850eb23d2fb5b8c842692fcdda2b1b15b97b0fe61a8ba58557e68f8d6396418f883e587bcac7e8d0f2a13f92f0b601725aa36d2ab4127a9db23b296d12b2da26c3f4518f79e604aafee485149b445da87fafd31c72db08fda945f7202cf4578fc58284ddfac920e78fd0b5b1637634e130de0d3aeb248604428621efd6eb7a8da10e9f9bb45ac071207921e8805f53a6b2e9b836ff2d33b8d8896152196d4524eaf869c601df354ffa033b66e9d66603f2e5a3d8b1bc17eeece1ad64bb9911259a4c82b989a66560551486e36a223c51ea9100a06af6c1c85f0be56acd1ecf3b35a48e42597fa4870dfec2fc6fb2032ccfa48e3035263c6fb466d5b255bdc842229e435cd6c9106011f6eaf2445b3b1a767aec47e60ec31b9344872c8ac8b557d02fcc1f36342eb29ebce530f7009965a249d665e3a4717bae38bfec8560783f5447ba74a3309f7998f846ead12e1afee4a1396a147a823e62d546418f2827df81c26168ff5b27cfc1dd9402f43896b5548e407b6e4b55937abc8abde99c6b59d0a92d4186d22ec1f28aab0cf9c5a536d7e0ff86eb56eb77179a6c8cd1a31bd88f27c2a43da876fe8c7dd5ed881cbde019bc3fd262f6c42d30a23a920146c8e99239e4021dd3879b14444bc27f70b050d2a9c4d4cd085fa9e009b946d88d44cdac0d9275f2f5f67d8477fe3ea2ca13d1a73532782d956a45880dfacc298e36e96ba7dde2455d03862e006ff4406dfe09f0863d9a9a1af540d17091a687b76b3eee9226534633a62ce364652318b947fea2dbdb8cdeba76c2d0ebdc88516b842a5457ea8bbb4dfe20c85a01ba50daed05474b1f4cb3a67488d8e957ee74a5b865797fe65aed4141cbebfcc95be0987edcfb9d2b92f866e3de74a2fc2e15f8a5ce97b71b8aec86291c62cfaf985acccd2a283d01efb3bbdf917b7fdfdc76c2d1f5f5ad480f0a9fc0d8b337c0e6dce6ca873865a5146e6d7aeb46e9494f99d2b8d24a2337f70a5f91144668a2b2d8488a4fa1c29aed4a910beeb4872a5ab217cdb91e44a5f06e166c75e577a0a848f3bf6bad2374158ebd8ed4a67208c1cbb5de94538fc20c495be1787fb42065a85c3cd63ebc02e44747b95c839be619183c717e72e8bc59cb2149827eeabada7b0a6737cdc52fe7eea22c7bf2cceadc4995e6e5494099ca634d50ba1c1ba814303ba814303ba814303ba8143437483e3baa0e9637ee487707d7108d71787707d7108571ce23566992b55a8c5952e68982b9dd7a8e7f83e8d77d3a8f3578ff1f16e1a153f44a3e2876854fc108d8a1fa251f143342ade4da3e25d1ae44ae73528c9952e68902b9dd7a0bdae745e4376bbd2790ddded4ae7352cc4952e68982bfd200edf1deb4a1734ccd57bbcfdee38e60cf3f6bbe360f44806fc34ec1f0bbeda6713d4c2db8409bc7fac533b3de43d16962a17d1d62a29becd1d4885382e6ae8669b089f33da506463180a5164e593d648cd0594953fc6ba236f97cdf9fddff1ef9cdf4bf35a84df24299bbeb6384314f1759deb5974d182e7f2ab1ada5615ea9afb86f3b6e19af9966c33616d6b2dfd3a5ff94f6c157cec2e13d633d69ed9d76a1988e1da6ffd81eb9fb2c55999bb4ca02b8f61adebcdff3abfecac60152f1f33d5632bf9455de70c633d85b2b7a1965fd2f8f22f1d33617d63b0be8de0ca5f8ab63853b0c6a941e35ab99863a6b297b02645529d8e6e7e345ee66e66dba9db6037bf0823fc128e8b1ec2f3e74b53b9349c1249118e9f393e598a734209185f025b39c35bffa57e6e6c67ce19e0fef8891b0771dea3b37fcbfde817bd0707733f3a7b30f7a3b1380ea7e11a48822b712ae398336d70cd1f9d7aee20aef96dcd40cde98d0c97b72ff6b735f79d2a3836b8e6bed8c135f7b971ef383586e33e73fea0767de5c14b12179d896331675c0327e5998bb59c3473bef0ab7fbdbea01b78a49ff8ba868fc3357da1a867f99198a919c8f37863562dd6b9020d3e1570ea5ceacd019dc31a26bc11f623d5fc934ae4a1be5807bb4c9190e21bd9b095809ddbbec1befcc216f0fdc96ecf90af4d1a1a757b717feb621e219c636851b5c9750bd951cd2c74de44cae1ce80f9b38e07d5aefbab8975d506e79778c7fbaa19671ea4174e0ebb8990a16f6a2cd056f1874664d06835f2cdbda8f4fb18c4767589490f4612b8f403f44c2e969a9460b90f5af8dc8de8a4e6f86f72c3dc2d01ab98ebad21d4a54d55c4b63c6b9eedaeb07679c04ea78172be7fbc2e9e20212473d15c270f5c13e6f34c2e1182799112c24208fdb8e70637b374543deeec79ea02dff378a6096ee6fbdf79023c78d73ea78f540f0e8baf7aa81b7829173179f4bb5428a1bedce4dc992b17619fb0b44981b6e5316111cbba1111b2d682c74ff0b3efe2d697bd7c2c6f5bf9406c790f1f5bdaa4411707e50eea76c65344efa0f8f23bcef846b4a26e50fe5fb9f825a54d916817d43f6359b768ea607eb79de9a9a86130bf9bce7833ba6c71be3d4cfcd1598b11e9ea3c9cdf64ff8063fbe6602d1fbdcf195bdec4c762499930fc06e8398b33adf91c4e3baae9e5467edf7cf9a6ee116448a9c20f61ad08049d8055894b095cc6a0af2dc27cde82e37e7e19ef57b28438ad958fc312b55a9cdf4538e328e23be11b436804964673d9196ee6c39dcef02f7c18f810a63a67db61cf9ea7fb07a12e6814daf43311c2f3be5ce7b4ba0657ee26b7dcc77fe0731f9df399e5b7b96d6eb99bcf3b73fb3d84b7dd2d37fade997bc2a0dccea70f6b06cd1c6707763e78479dad15ce10bfcd9d33cb48b672b3dae2d2a630a8a1e01f268d791aecbf2a7abee1e3f17b9ba3676573b2b5384f24e4d971621bf41a0e692074f51706461173d4db8c5f712794dc1904b51fef42b296bd381fe46e94cdc1239cadd5a79222eeab2c573ee35f8f98f1df7228d3e051657bec882e6813f1126a4e95cdd185991a9569b0db5f9b6d76aee6bbf2b8eff41e2893fa9b6429ad42ed552706b88655e2da5f9c0f73b7e8868308919d000bf693279c238473a20f749aa78be8a24614c850285beb9b74218eccdbf453e16c7ce390bf69f8b5852f81b9ab3ea28ef22599725e36e3d1a78b4ae61061f85d63ee1c22245bcb90e2c66e87783a89f4a17309b6472a6a7d4084a982da5109ecfab95efdb0ed70a76573465c7ba0c72107dead871b423bf04e7c9b86be5f8584f3be52e1fbc622a2bc48433fda83600637f78884facb8477cc2c510e337c690f1a1a1ff51e513ead65623394b966f3142984feb010ec2cf368b53ec63957965fca4e11f96ed2ce58765054b1b2b4700aaa581f18df80d8cc9e11818a5328b26704cac85784e26fff620b2617fa24cea05aa30213346841ac68a32e846d25650b4ebdf8059b691fa1fc221036f63591df229ca714aaacb1851172485105b57935e4ab42a54817f6e2a91763f1faa00bc35e208466c3938d92010f6abb58790aaf1ac2795781f08e9dc1279ad84f4c0991b608712f0792be8430fb726fbcf57fe2dfd6e0afdba1d557abb83372d5deaa0a46b387ea448a29dcdf34d92d8b72be99914575a6f0df58b20c1924d8938dd722cdfb035ad4a8c3baa9da4fc9f49a4eeeef1d308d0a124b98f29d20cd69fce6818f232f38dfc1eb4f09fafb41196dbacea7aabfe14b240a27d5d49e32baf39fceafd7457e2cd64d3f8ef79bb38a9449aafd1619f7372e14a408b78e99ab631525b0c797b53f49eff2a3d8229032807bbf9fb9bf445c2343faf173906e3cdb3e1ea982e5042bd38a6a7215e22f4a54874f23d5d10b308e10636c14054a0ea2234c84f42e929d0d66260bfd9af86bf04a58e1497c03803cc5c735ffcabff571dd2db8619a6bdde5777fa0ee7daf0ead3bc0bdee4fa0ee031760e65f9181bf43c15fa5e06f51f82f53f6e76d080f4259cfb3cfabc5f2e7bf446c6fef3b4478c4e60f11fb42b798d67a8858eaf63bf4b65ef0f6877b5c52e0f7c6ac69f47162be2e26641f4d7ac85c77bd338990528a71b01edf1e8f18dd8b6a4c1f465dada3290f29ab00be1eb7dff19e5f1f636da0fad8a6f9e2aca54f6a6134df89d8b891607fba2ffeac518eebd1dba4a466b8e425c5f35b59a3e238a161fd7f877e78b7c6d41bd5efff9926e2d49b04ddd624e5bf9b23d3b648f71797cdde0f5e826e1e39ff9805d7e2317f97c5fbb4ebbdd73a5eaa08df2ec452df1e37e56fb278fc9d559c44f43714fefee41d6f4d7d4c5a9d4e436a9eabc3610f4d86858f7fce22f73320fa0d934fff685dac7c2929aa596e12f527e8d8abf9baf722324da2534c04f4b148b12c9f7e9b22c2cd2c73d741a756217a1345b04cbb23dc1c4151d111cb8da2884ca3a8268712b30a4a34db48f735a16ab31c767ab0d341747713783eed0e8829244545f9cf6fad89bc8d56400ff4fe815e767bb83c7323f23ee1a1c1776268c9352f6f0d3dfc9a271de089e4995df8b45edc84464ae48a8d88bf2f7545d1afc882d21e5172aaf91d6f2dfdb21d5be5f07b3298e3a4f76434e929cb5aca421adbb214652dc3e3f0a42e69db5985dcb747bc625bf4b61dc73794fba2877f9bc4faf782a68c460dc7e273e20c2f1831673b9e3d45765f4663f5b777113164c54b39ad16b6c5808818dc97197564cc425f22d65bf365ddd80763250575137ebc5137f5019ffa715dca03a68ed4ecbacebebe11051b777d21b475d83519b4557c4d166ca4477b22f67568ad9a361c82de8a4149ac5ca340641ea9aea1baa358a9564c7fd123c36b09be91617abf26fe0384473d628a162ddbca421f6e3b61e2f992f72420ef887b22dc872cdf877adc87ac02c6fb0225c2b98818688d88bac9b68c439dc7828dd1f7e49401a559828dcf9fbd58b7f9de58f08a93a015de5a9dc63a9cba26b7fba2fa3aefe3421dc43d11d441dd437e31b4d4139131a3cb4362d63ef0d6627e3a4ddac190984df76e5870bfe03e2062eb63761d1b087d7cf0e1d67a07acb57fa91cacf5532d78d8efe8c2af6e659f074b1de1c169333d0c5beabb924b8a8b5be51ed84e8938bf7df5275db7419ee1ed410e565a5308bdc3dd5f3b7692359f4472ce46a3e3ac8d0fb7d1dd5f71366a78b88d9e318385aa234e6d26e4b90a44b79ef3e4ad3465f280951260a54c9d9cb3d2bd83ac34688abb95aefd8d9546c72571563a4fb0d234c14ae70deac3e8b88769332df1441b821ef917fa9c9540b0ec7989885d2611f56eddbc35822c14451872c05a0f896a9822110b765f51b4bf90ee36205223521c29ce5a4a6c8fb01b50d2369122dc2cf73523dd76ac652bd84385d1f99592889616c459e30b948c4df045642ed83275f70ff4a2db9e4e5bc65fbbd0f9d7a4a0dfa66b52bae4dfd83225136cd9bac8fe2b589c89d360dd3d09adf594f0b62c5ffd02f2b02ccc09e56d92b48fc2d66e1f055a3cca7e9788798ab3c959b9bbea9efd75ac6473dd73976ed46dfe95b7c0ef2c290fd6ba592027611e67817ace0277fcbf63811c5f86933f1f2cb0e4e1168873711628a3aec85787a39083ffc6022554b33cf311c102b93a749c051a390bcc196c81989f4ef3432d6f817c0f5cae19d0a24db577c2c0ca12e40960657af0a1de61a5cd7fb89a9f55409f6a43e4ad5dd7b1673fe62ac446d367da444c2c1176d65f4e4e9a732e7ff4ae40aae978c4b92a84cfc68810d33f18cd867205be43037be78b75f59a1b80ac65dddc5d36bcc7f5fe5aee4b8a88edaebf972286d19c637a5f4e4d9a3383b44745f87e80e4ddf677fa133ed5676d5dec17bdcd753b3c46a7b90856a01547247423eceb8db65e5674df9743ef8fc9af8138de9b211f54733bf419645514fe2b3df8ef733977e0aae1bc9fa52173692c914e3df8ae4ba282ff7edde6914bcf5c5b7022dbecbafb124a8ce4d3c23c83db15bed8bf93788ed98adf1f7a1b3e378c6c19b8cf91e5cb820358097e5cb6b9d5e22c5725759593e27271cdb8a42e6696892e3688842fe8257c8e16f198ad42dafb06c47316a561deac790a3a039c1949b6f9b26570e807ee56aeebfdbf6462c7e4f6692dd22ee1b6c029be064d5f095db172f64a7da4f1b12b29261b4b5141aa99f6474b34596afae556e77e00f1a59aff9eb50c9fb1603fd9fbb4dc2f12cd2a524d6ff011efa39e246367f8b7a18855e06d414835fd5c902996567c8ff4959a2797bdabaa6e9c542a55200f6a3855d878c4ccf34db9bfd5ca738e6a24d42bc0438befa8de22dc1fe8c5b3fe0bedce35e0a596895b04298e087f55e0b6fe330a91f3f5074c8fed6a962657260e9ddd847d56775292c2caf98ef5da98408f2ec7704968a1759e471fede189f49186201a5433eba924df6e4b598c6f727f246d0e13ab3e1847749f1757499e9ce1ff3b42ff5703ec4488308f5bd9c56531d692cc5ebdc5f49835c7dcf79c05dffff9a14e5f15f3a47eaac1a7335f17a6b3c533d9c597eb26c2bf5fd6f15a3ef0175e59d97631bee1156ea05f20d10c8936caf9cd0eaacf5a1a484a5cdf530c2ef32d89cbd02f9188df8d485b064a467d8feaf12d1f7cc3537a63bf21f8ea1666a024221f561bfa0ed716ca6c71bedbf6c5350fdce11c9df138cae91324bbd79f407b74a3c9eac065e7a24853db7a0fee1e4aabb36d424dcd0f6d57e2195c53303370fb717099db0f2d13d438b48cb09fffa184c6a5c3f5b372c75c77fed55ccc25d11b73012995ddcebf2077027fdd0dda9ae82caf3a5cf5bd783afecb98446c0429269c12f06567b356df943e2edf81aab3b399cb96a17222c9c3e42c3f3a54ceb224954f372a4b518d847fe7bd58fff33c15bebbffaccaaf1bfdfcacca1f9e33540af877b3f2ead1a49957cb56cc6c3d9aa2bc7174adb2fbe826657fb61671bfb39f381ca33e7538a20025806b80c97f7338e20e381c0b01670f3a1ca1404f591c0e11d0e8f4b4d47529c94129afbdf6ea6b633dd1829475a91b57b98268da94351048da90e2edc9f18f983c34ec968cfe14a39ebd4cb32248bd6e63ca6b41b1e9491b56053dfb6a720a4243d3b9149cf07450dabab48d419b925edb084f50e8b54deb373e345ffaabafae4742352879d3daf52fd3afbe96f2345ff3a675ab92d625a7434b063181df9f7f8fb40fa3df463e3cde49e7fe9bf4fd4ffff7e9a7a6f0b459a0f704ea3b95a71305ea358da7a102bd22d0f393ff7bfaca6b29496bd6bf0a8de5fb6365d2a6f48d412b5336d2ab0685d35f4d4a1e9cbe6123f418174e4b4f4f494d4a87dedab0f1b54df4c6b457d771f16bd33624092a31c06c683cc774507880e9ffe64771ffc24c32f4271d1c1089fed7d5b87eb2ff2799c5ffe39c95c2f8ec1368b9403f12e8f8089e6e14e81b825e9c15d2bd843042db11011001c48f2124f9c32788044801144006f00078028601bc208f3760386004c0076d178f043a0acacb81fa02f503f8c3b30210f0d876341af0082010a0048c013c0a780c1004180b0806a800e3002180504018603c6002201cf03bc0e38027001301bf074c023c09980c88004c014c054c034402a6039e023c0d980198097806300bf0074014c81a0d72ce063a07680c5035d05868ab063017300f1007980f58007816b010f2fc11b008f01c6031f4c312a04b216d19f0880724407839e079c00b10fe13e045c00ac04b10f732201190047805400392012990be12900a58054883b8d580358074c05ac03ac0ab80f5909e01780db001b011e236015e076402de8011de0c7813f016e06d4016e0cf3e3bd03b002d4007c806e8010628c300720046e0970b3001b600f2005b01db00ef02f201f8bf02c07b937620165008cf45806280195002d801bc76024a0165805d80bf00de07940376032a20df1ec00780bd804a4015c4ef037c08a806fc15f011e063c07ec07f013e817c9f02fe06a8011c001c84f843000be030e033c011402de028e018e073401de038a01ef005e004e024a001700ad008380df8127006f015e0ef80af01df00fe01f816f01de02ce09f80ef01e74086f38026c005c00fd0433f3eb603fd04cf3f032e022ec118fc02b419f25f065c0158012d8056401bc00668075c055c035c0774006e006e026e016e033a01bf02ee00ba00dd801e801d7017d00bb807b80fe803f4031e001c8f7113c062614a59c293718b84f052fccfb49f1c8e18c0624022601de06dc016c04e4035e008e00ce047c03580e867f00d0041808980998038c072c02ac01b805c4009601fe030e034e002a01d5001380af81ed001b807905d7438fc01e3009301b3018b002f01d2016f024a006d971c8e1ec03e78ce051c069c0634036e031e00bc20fd11c078c03440312016100f5809781d50093804c8019c029c078cfbc5e1781ab000f012e00d402ee02f80c38033809f01b7015eb00f08063c0d5808580d987d19ea00ac0468215c063800380d6801dc038c82b450c062c024c0f4cb7cb95840c51587e313c071c049c0af0019ec1b1601d603720141563ead1ce874e119a707b5381c53007301db018720eeef8076c08b104e07bcddc2e75d348827a69f437c07e091569011c2be2d03e97321aee40a8f9302701c4263053d0a16a88aa3c9491b935ece4c4b06df6fd6334153834243830645cd7c26683a9f1b16fbf5af80bf36f699a065d18b97bebc64e91f17bd3cf95fc43ff9f254e7ba383678debad7c163480e5a9ff45adac6cdc142bcff758763386094409fee18083f2200c7e170cfb501044378e94d1eab018b04ccbe3110c6cf8b84f48583907b0bfa811089c4f093083fd2ed27fd373fea7ff993fd5ffeed4b76fa198877aa08c1b722785f2748ec4ae77ecd697cb864354f17ad199afefff59ff3ffc3323ce2ebbf4e19b5b6ade3128986fd5f95e83fbffffcfef3fbcfef3fbfff3ffd64e9fcbaeaa4016e74bc1b9dee46e7bad1e56e74951b7dc38de6bad11237bacf8d1e76a3a7dde80537daee46efba51d9daa134c08d8e77a3d3dde85c37badc8dae72a36fb8d15c375ae246f7b9d1c36ef4b41bbde046dbdde85d372a5b379406b8d1f16e74ba1b9deb4697bbd1556ef40d379aeb464bdce83e377ad88d9e76a317dc68bb1bbdeb4665af0ea5016e74bc1b9dee46e7bad1e56e74951b7dc38de6bad11237bacf8d1e76a3a7dde80537daee46efba51d9faa134c08d8e77a3d3dde85c37badc8dae72a36fb8d15c375ae246f7b9d1c36ef4b41bbde046dbdde85d372acb184a03dce878373add8dce75a3cbdde82a37fa861bcd75a3256e749f1b3dec464fbbd10b6eb4dd8dde75a3b2d786d200373ade8d4e77a373dde87237baca8dbee14673dd68891bdde7460fbbd1d36ef4821b6d77a377dda86cc3501ae046c7bbd1e96e74ae1b5dee4657b9d137dc68ae1b2d71a3fbdce861377ada8d5e70a3ed6ef4ae1b75eecb1dc2cfb93d3f7ec9838b1ffcfbdfbc0df93f99c1f709'
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
                if len(data) < 2:
                    return op, reason, "data null"

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
                ISP_RET_BAD_EXEC = 0xE5

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
                reason_enum = FlashModeResponse.ErrorCode(reason)
                if (not text) or (text.strip() == ""):
                    if reason_enum == FlashModeResponse.ErrorCode.ISP_RET_OK:
                        text = None
                    elif reason_enum == FlashModeResponse.ErrorCode.ISP_RET_BAD_DATA_LEN:
                        text = "bad data len"
                    elif reason_enum == FlashModeResponse.ErrorCode.ISP_RET_BAD_DATA_CHECKSUM:
                        text = "bad data checksum"
                    elif reason_enum == FlashModeResponse.ErrorCode.ISP_RET_BAD_INITIALIZATION:
                        text = "bad initialization"
                    elif reason_enum == FlashModeResponse.ErrorCode.ISP_RET_INVALID_COMMAND:
                        text = "invalid command"
                    elif reason_enum == FlashModeResponse.ErrorCode.ISP_RET_BAD_EXEC:
                        text = "execute cmd error"
                    else:
                        text = "unknown error"
                return (op, reason, text)


        def chunks(l, n, address=None):
            """Yield successive n-sized chunks from l."""
            if address != None and (address % n != 0):
                start_pos = n - (address - address // n * n)
                if start_pos % ISP_FLASH_SECTOR_SIZE != 0:
                    raise_exception(Exception("data should 4KiB align"))
                count_4k_blocks = start_pos // ISP_FLASH_SECTOR_SIZE
                count = math.ceil((len(l) - start_pos)/n) + count_4k_blocks
                for i in range(count):
                    if i < count_4k_blocks:
                        yield l[ISP_FLASH_SECTOR_SIZE*i:ISP_FLASH_SECTOR_SIZE*(i+1)]
                        if ISP_FLASH_SECTOR_SIZE*(i+1) > len(l):
                            break
                    else:
                        start = start_pos+(i-count_4k_blocks)*n
                        yield l[start:start+n]
                        if start+n > len(l):
                            break
            else:
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
                            raise_exception( Exception(err) )
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

            def recv_one_return(self, timeout_s = None):
                timeout_init = time.time()
                data = b''
                if timeout_s == None:
                    timeout_s = ISP_RECEIVE_TIMEOUT
                # find start boarder
                #sys.stdout.write('[RECV one return] raw data: ')
                while 1:
                    if time.time() - timeout_init > timeout_s:
                        raise_exception( TimeoutError )
                    c = self._port.read(1)
                    #sys.stdout.write(binascii.hexlify(c).decode())
                    sys.stdout.flush()
                    if c == b'\xc0':
                        break

                in_escape = False
                while 1:
                    if time.time() - timeout_init > timeout_s:
                        raise_exception( TimeoutError )
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
                            raise_exception( Exception('Invalid SLIP escape (%r%r)' % (b'\xdb', c)) )
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
                    try:
                        self._port.write(b'\xc0\xd2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0')
                    except Exception:
                        raise_exception( Exception("Connection disconnected, try again or maybe need use Slow mode, or decrease baudrate") )
                    retry_count = retry_count + 1
                    try:
                        op, reason, text = FlashModeResponse.parse(self.recv_one_return())
                    except IndexError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Index Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except TimeoutError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Timeout Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to Connect to K210's Stub",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            raise_exception( Exception(err) )
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
                            raise_exception( Exception(err) )
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
                ret = self.recv_one_return()
                if len(ret) < 2:
                    KFlash.log('-' * 30)
                    KFlash.log("receive data time out")
                    KFlash.log('-' * 30)
                    return False
                op, reason, text = ISPResponse.parse(ret)
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
                            raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Index Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except TimeoutError:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to initialize flash",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            raise_exception( Exception(err) )
                        KFlash.log(WARN_MSG,"Timeout Error, retrying...",BASH_TIPS['DEFAULT'])
                        time.sleep(0.1)
                        continue
                    except:
                        if retry_count > MAX_RETRY_TIMES:
                            err = (ERROR_MSG,"Failed to initialize flash",BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            raise_exception( Exception(err) )
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
                            raise_exception( Exception(err) )
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

            def dump_to_flash(self, data, address=0, size=None):
                '''
                typedef struct __attribute__((packed)) {
                    uint8_t op;
                    int32_t checksum; /* All the fields below are involved in the calculation of checksum */
                    uint32_t address;
                    uint32_t data_len;
                    uint8_t data_buf[1024];
                } isp_request_t;
                '''
                if size == None:
                    DATAFRAME_SIZE = ISP_FLASH_DATA_FRAME_SIZE
                    size = DATAFRAME_SIZE
                data_chunks = chunks(data, size)
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
                                raise_exception( Exception(err) )
                            continue
                        break
                    address += len(chunk)



            def flash_erase(self, erase_addr = 0, erase_len = 0):
                #KFlash.log('[DEBUG] erasing spi flash.')
                cmd0 = b'\xd3\x00\x00\x00'
                cmd = struct.pack("I", erase_addr)
                cmd += struct.pack("I", erase_len)
                cmd = cmd0 + struct.pack('I', binascii.crc32(cmd) & 0xFFFFFFFF) + cmd
                self.write(cmd)
                t = time.time()
                op, reason, text = FlashModeResponse.parse(self.recv_one_return(timeout_s=90))
                if FlashModeResponse.ErrorCode(reason) != FlashModeResponse.ErrorCode.ISP_RET_OK:
                    err = (ERROR_MSG,"erase error, error code: 0x{:02X}: {}".format(reason, text))
                    err = tuple2str(err)
                    raise_exception( Exception(err) )
                else:
                    KFlash.log(INFO_MSG,"erase ok")
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
                    raise_exception( Exception(err) )

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

                    total_len = (len(firmware_with_header) + ISP_FLASH_SECTOR_SIZE - 1)//ISP_FLASH_SECTOR_SIZE * ISP_FLASH_SECTOR_SIZE
                    # Slice download firmware
                    data_chunks = chunks(firmware_with_header, ISP_FLASH_DATA_FRAME_SIZE)  # 4kiB for a sector, 16kiB for dataframe
                else:
                    total_len = (len(firmware_bin) + ISP_FLASH_SECTOR_SIZE - 1)//ISP_FLASH_SECTOR_SIZE * ISP_FLASH_SECTOR_SIZE
                    data_chunks = chunks(firmware_bin, ISP_FLASH_DATA_FRAME_SIZE, address = address_offset)

                time_start = time.time()
                write_len = 0
                for n, chunk in enumerate(data_chunks):
                    self.checkKillExit()
                    # 4K align
                    aligned_chunk = len(chunk)
                    aligned_chunk = (ISP_FLASH_SECTOR_SIZE - (aligned_chunk % ISP_FLASH_SECTOR_SIZE))%ISP_FLASH_SECTOR_SIZE + aligned_chunk
                    chunk = chunk.ljust(aligned_chunk, b'\x00')  # align by size of dataframe

                    # Download a dataframe
                    #KFlash.log('[INFO]', 'Write firmware data piece')
                    chunk_len = len(chunk)
                    self.dump_to_flash(chunk, address= write_len + address_offset, size=chunk_len)
                    write_len += chunk_len
                    columns, lines = TerminalSize.get_terminal_size((100, 24), terminal)
                    time_delta = time.time() - time_start
                    speed = ''
                    if (time_delta > 1):
                        speed = str(int(write_len / 1024.0 / time_delta)) + 'kiB/s'
                    printProgressBar(write_len, total_len, prefix = 'Programming BIN:', filename=filename, suffix = speed, length = columns - 35)

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
            parser.add_argument("-B", "--Board",required=False, type=str, help="Select dev board, e.g. kd233, dan, bit, goD, goE or trainer")
            parser.add_argument("-S", "--Slow",required=False, help="Slow download mode", default=False)
            parser.add_argument("-A", "--addr",required=False, help="flash addr", type=str, default="-1")
            parser.add_argument("-L", "--length",required=False, help="flash addr", type=str, default="-1")
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
            setattr(args, "addr", -1)
            setattr(args, "length", -1)

        # udpate args for none terminal call
        if not terminal:
            args.port = dev
            args.baudrate = baudrate
            args.noansi = noansi
            args.sram = sram
            args.Board = board
            args.firmware = file
            args.Slow = slow_mode
            args.addr = addr
            args.length = length

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

        # 0. Check firmware or cmd
        cmds = ['erase']
        if not args.firmware in cmds:
            if not os.path.exists(args.firmware):
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
            if not self.loader._port.isOpen():
                self.loader._port.open()
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
                        if not self.loader._port.isOpen():
                            self.loader._port.open()
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
                        if not self.loader._port.isOpen():
                            self.loader._port.open()
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
                        if not self.loader._port.isOpen():
                            self.loader._port.open()
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
                        if not self.loader._port.isOpen():
                            self.loader._port.open()
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
            with open(args.firmware, 'rb') as firmware_bin:
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
            if args.bootloader:
                with open(args.bootloader, 'rb') as f:
                    isp_loader = f.read()
            else:
                isp_loader = ISP_PROG
            self.loader.install_flash_bootloader(isp_loader)

        # Boot the code from SRAM
        self.loader.boot()
        if args.sram:
            # Dangerous, here are dinosaur infested!!!!!
            # Don't touch this code unless you know what you are doing
            self.loader._port.baudrate = args.baudrate
            KFlash.log(INFO_MSG,"Boot user code from SRAM", BASH_TIPS['DEFAULT'])
            if(args.terminal == True):
                try:
                    self.loader._port.close()
                except Exception:
                    pass
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
            with tempfile.TemporaryDirectory() as tmpdir:
                try:
                    with zipfile.ZipFile(args.firmware) as zf:
                        zf.extractall(tmpdir)
                        if not os.path.exists(os.path.join(tmpdir, "flash-list.json")):
                            err = (ERROR_MSG,'Can not find flash-list.json in kfpkg root dir',BASH_TIPS['DEFAULT'])
                            err = tuple2str(err)
                            raise_exception( Exception(err) )
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
            if args.firmware == "erase":
                if args.addr.lower().startswith("0x"):
                    addr = int(args.addr, base=16)
                else:
                    addr = int(args.addr)
                if args.length.lower() == "all":
                    addr = 0
                    length = 0xFFFFFFEE
                    KFlash.log(INFO_MSG,"erase all")
                else:
                    if args.length.lower().startswith("0x"):
                        length = int(args.length, base=16)
                    else:
                        length = int(args.length)
                    KFlash.log(INFO_MSG,"erase '0x{:x}' - '0x{:x}' ({}B, {:.02}KiB, {:.02}MiB)".format(addr, addr+length, length, length/1024.0, length/1024.0/1024.0))
                if ((addr % 4096) != 0) or ( length != 0xFFFFFFEE and (length % 4096) != 0) or addr < 0 or addr > 0x01000000 or length < 0 or ( length > 0x01000000 and length != 0xFFFFFFEE):
                    err = (ERROR_MSG,"erase flash addr or length error, addr should >= 0x00000000, and length should >= 4096 or 'all'")
                    err = tuple2str(err)
                    raise_exception( Exception(err) )
                self.loader.flash_erase(addr, length)
            else:
                with open(args.firmware, 'rb') as firmware_bin:
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
