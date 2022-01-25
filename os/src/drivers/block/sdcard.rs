#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(unused)]

use super::BlockDevice;
use crate::sync::UPSafeCell;
use core::convert::TryInto;
use k210_hal::prelude::*;
use k210_pac::{Peripherals, SPI0};
use k210_soc::{
    fpioa::{self, io},
    //dmac::{dma_channel, DMAC, DMACExt},
    gpio,
    gpiohs,
    sleep::usleep,
    spi::{aitm, frame_format, tmod, work_mode, SPIExt, SPIImpl, SPI},
    sysctl,
};
use lazy_static::*;

pub struct SDCard<SPI> {
    spi: SPI,
    spi_cs: u32,
    cs_gpionum: u8,
    //dmac: &'a DMAC,
    //channel: dma_channel,
}

/*
 * Start Data tokens:
 *         Tokens (necessary because at nop/idle (and CS active) only 0xff is
 *         on the data/command line)
 */
/** Data token start byte, Start Single Block Read */
pub const SD_START_DATA_SINGLE_BLOCK_READ: u8 = 0xFE;
/** Data token start byte, Start Multiple Block Read */
pub const SD_START_DATA_MULTIPLE_BLOCK_READ: u8 = 0xFE;
/** Data token start byte, Start Single Block Write */
pub const SD_START_DATA_SINGLE_BLOCK_WRITE: u8 = 0xFE;
/** Data token start byte, Start Multiple Block Write */
pub const SD_START_DATA_MULTIPLE_BLOCK_WRITE: u8 = 0xFC;

pub const SEC_LEN: usize = 512;

/** SD commands */
#[repr(u8)]
#[derive(Debug, PartialEq, Eq, Copy, Clone)]
#[allow(unused)]
pub enum CMD {
    /** Software reset */
    CMD0 = 0,
    /** Check voltage range (SDC V2) */
    CMD8 = 8,
    /** Read CSD register */
    CMD9 = 9,
    /** Read CID register */
    CMD10 = 10,
    /** Stop to read data */
    CMD12 = 12,
    /** Change R/W block size */
    CMD16 = 16,
    /** Read block */
    CMD17 = 17,
    /** Read multiple blocks */
    CMD18 = 18,
    /** Number of blocks to erase (SDC) */
    ACMD23 = 23,
    /** Write a block */
    CMD24 = 24,
    /** Write multiple blocks */
    CMD25 = 25,
    /** Initiate initialization process (SDC) */
    ACMD41 = 41,
    /** Leading command for ACMD* */
    CMD55 = 55,
    /** Read OCR */
    CMD58 = 58,
    /** Enable/disable CRC check */
    CMD59 = 59,
}

#[allow(unused)]
#[derive(Debug, Copy, Clone)]
pub enum InitError {
    CMDFailed(CMD, u8),
    CardCapacityStatusNotSet([u8; 4]),
    CannotGetCardInfo,
}

/**
 * Card Specific Data: CSD Register
 */
#[derive(Debug, Copy, Clone)]
pub struct SDCardCSD {
    pub CSDStruct: u8,        /* CSD structure */
    pub SysSpecVersion: u8,   /* System specification version */
    pub Reserved1: u8,        /* Reserved */
    pub TAAC: u8,             /* Data read access-time 1 */
    pub NSAC: u8,             /* Data read access-time 2 in CLK cycles */
    pub MaxBusClkFrec: u8,    /* Max. bus clock frequency */
    pub CardComdClasses: u16, /* Card command classes */
    pub RdBlockLen: u8,       /* Max. read data block length */
    pub PartBlockRead: u8,    /* Partial blocks for read allowed */
    pub WrBlockMisalign: u8,  /* Write block misalignment */
    pub RdBlockMisalign: u8,  /* Read block misalignment */
    pub DSRImpl: u8,          /* DSR implemented */
    pub Reserved2: u8,        /* Reserved */
    pub DeviceSize: u32,      /* Device Size */
    //MaxRdCurrentVDDMin: u8,   /* Max. read current @ VDD min */
    //MaxRdCurrentVDDMax: u8,   /* Max. read current @ VDD max */
    //MaxWrCurrentVDDMin: u8,   /* Max. write current @ VDD min */
    //MaxWrCurrentVDDMax: u8,   /* Max. write current @ VDD max */
    //DeviceSizeMul: u8,        /* Device size multiplier */
    pub EraseGrSize: u8,         /* Erase group size */
    pub EraseGrMul: u8,          /* Erase group size multiplier */
    pub WrProtectGrSize: u8,     /* Write protect group size */
    pub WrProtectGrEnable: u8,   /* Write protect group enable */
    pub ManDeflECC: u8,          /* Manufacturer default ECC */
    pub WrSpeedFact: u8,         /* Write speed factor */
    pub MaxWrBlockLen: u8,       /* Max. write data block length */
    pub WriteBlockPaPartial: u8, /* Partial blocks for write allowed */
    pub Reserved3: u8,           /* Reserded */
    pub ContentProtectAppli: u8, /* Content protection application */
    pub FileFormatGroup: u8,     /* File format group */
    pub CopyFlag: u8,            /* Copy flag (OTP) */
    pub PermWrProtect: u8,       /* Permanent write protection */
    pub TempWrProtect: u8,       /* Temporary write protection */
    pub FileFormat: u8,          /* File Format */
    pub ECC: u8,                 /* ECC code */
    pub CSD_CRC: u8,             /* CSD CRC */
    pub Reserved4: u8,           /* always 1*/
}

/**
 * Card Identification Data: CID Register
 */
#[derive(Debug, Copy, Clone)]
pub struct SDCardCID {
    pub ManufacturerID: u8, /* ManufacturerID */
    pub OEM_AppliID: u16,   /* OEM/Application ID */
    pub ProdName1: u32,     /* Product Name part1 */
    pub ProdName2: u8,      /* Product Name part2*/
    pub ProdRev: u8,        /* Product Revision */
    pub ProdSN: u32,        /* Product Serial Number */
    pub Reserved1: u8,      /* Reserved1 */
    pub ManufactDate: u16,  /* Manufacturing Date */
    pub CID_CRC: u8,        /* CID CRC */
    pub Reserved2: u8,      /* always 1 */
}

/**
 * Card information
 */
#[derive(Debug, Copy, Clone)]
pub struct SDCardInfo {
    pub SD_csd: SDCardCSD,
    pub SD_cid: SDCardCID,
    pub CardCapacity: u64,  /* Card Capacity */
    pub CardBlockSize: u64, /* Card Block Size */
}

impl</*'a,*/ X: SPI> SDCard</*'a,*/ X> {
    pub fn new(
        spi: X,
        spi_cs: u32,
        cs_gpionum: u8, /*, dmac: &'a DMAC, channel: dma_channel*/
    ) -> Self {
        Self {
            spi,
            spi_cs,
            cs_gpionum,
            /*
            dmac,
            channel,
             */
        }
    }

    fn CS_HIGH(&self) {
        gpiohs::set_pin(self.cs_gpionum, true);
    }

    fn CS_LOW(&self) {
        gpiohs::set_pin(self.cs_gpionum, false);
    }

    fn HIGH_SPEED_ENABLE(&self) {
        self.spi.set_clk_rate(10000000);
    }

    fn lowlevel_init(&self) {
        gpiohs::set_direction(self.cs_gpionum, gpio::direction::OUTPUT);
        self.spi.set_clk_rate(200000);
    }

    fn write_data(&self, data: &[u8]) {
        self.spi.configure(
            work_mode::MODE0,
            frame_format::STANDARD,
            8, /* data bits */
            0, /* endian */
            0, /*instruction length*/
            0, /*address length*/
            0, /*wait cycles*/
            aitm::STANDARD,
            tmod::TRANS,
        );
        self.spi.send_data(self.spi_cs, data);
    }

    /*
    fn write_data_dma(&self, data: &[u32]) {
        self.spi.configure(
            work_mode::MODE0,
            frame_format::STANDARD,
            8, /* data bits */
            0, /* endian */
            0, /*instruction length*/
            0, /*address length*/
            0, /*wait cycles*/
            aitm::STANDARD,
            tmod::TRANS,
        );
        self.spi
            .send_data_dma(self.dmac, self.channel, self.spi_cs, data);
    }
     */

    fn read_data(&self, data: &mut [u8]) {
        self.spi.configure(
            work_mode::MODE0,
            frame_format::STANDARD,
            8, /* data bits */
            0, /* endian */
            0, /*instruction length*/
            0, /*address length*/
            0, /*wait cycles*/
            aitm::STANDARD,
            tmod::RECV,
        );
        self.spi.recv_data(self.spi_cs, data);
    }

    /*
    fn read_data_dma(&self, data: &mut [u32]) {
        self.spi.configure(
            work_mode::MODE0,
            frame_format::STANDARD,
            8, /* data bits */
            0, /* endian */
            0, /*instruction length*/
            0, /*address length*/
            0, /*wait cycles*/
            aitm::STANDARD,
            tmod::RECV,
        );
        self.spi
            .recv_data_dma(self.dmac, self.channel, self.spi_cs, data);
    }
     */

    /*
     * Send 5 bytes command to the SD card.
     * @param  cmd: The user expected command to send to SD card.
     * @param  arg: The command argument.
     * @param  crc: The CRC.
     * @retval None
     */
    fn send_cmd(&self, cmd: CMD, arg: u32, crc: u8) {
        /* SD chip select low */
        self.CS_LOW();
        /* Send the Cmd bytes */
        self.write_data(&[
            /* Construct byte 1 */
            ((cmd as u8) | 0x40),
            /* Construct byte 2 */
            (arg >> 24) as u8,
            /* Construct byte 3 */
            ((arg >> 16) & 0xff) as u8,
            /* Construct byte 4 */
            ((arg >> 8) & 0xff) as u8,
            /* Construct byte 5 */
            (arg & 0xff) as u8,
            /* Construct CRC: byte 6 */
            crc,
        ]);
    }

    /* Send end-command sequence to SD card */
    fn end_cmd(&self) {
        /* SD chip select high */
        self.CS_HIGH();
        /* Send the cmd byte */
        self.write_data(&[0xff]);
    }

    /*
     * Returns the SD response.
     * @param  None
     * @retval The SD Response:
     *         - 0xFF: Sequence failed
     *         - 0: Sequence succeed
     */
    fn get_response(&self) -> u8 {
        let result = &mut [0u8];
        let mut timeout = 0x0FFF;
        /* Check if response is got or a timeout is happen */
        while timeout != 0 {
            self.read_data(result);
            /* Right response got */
            if result[0] != 0xFF {
                return result[0];
            }
            timeout -= 1;
        }
        /* After time out */
        0xFF
    }

    /*
     * Get SD card data response.
     * @param  None
     * @retval The SD status: Read data response xxx0<status>1
     *         - status 010: Data accecpted
     *         - status 101: Data rejected due to a crc error
     *         - status 110: Data rejected due to a Write error.
     *         - status 111: Data rejected due to other error.
     */
    fn get_dataresponse(&self) -> u8 {
        let response = &mut [0u8];
        /* Read resonse */
        self.read_data(response);
        /* Mask unused bits */
        response[0] &= 0x1F;
        if response[0] != 0x05 {
            return 0xFF;
        }
        /* Wait null data */
        self.read_data(response);
        while response[0] == 0 {
            self.read_data(response);
        }
        /* Return response */
        0
    }

    /*
     * Read the CSD card register
     *         Reading the contents of the CSD register in SPI mode is a simple
     *         read-block transaction.
     * @param  SD_csd: pointer on an SCD register structure
     * @retval The SD Response:
     *         - `Err()`: Sequence failed
     *         - `Ok(info)`: Sequence succeed
     */
    fn get_csdregister(&self) -> Result<SDCardCSD, ()> {
        let mut csd_tab = [0u8; 18];
        /* Send CMD9 (CSD register) */
        self.send_cmd(CMD::CMD9, 0, 0);
        /* Wait for response in the R1 format (0x00 is no errors) */
        if self.get_response() != 0x00 {
            self.end_cmd();
            return Err(());
        }
        if self.get_response() != SD_START_DATA_SINGLE_BLOCK_READ {
            self.end_cmd();
            return Err(());
        }
        /* Store CSD register value on csd_tab */
        /* Get CRC bytes (not really needed by us, but required by SD) */
        self.read_data(&mut csd_tab);
        self.end_cmd();
        /* see also: https://cdn-shop.adafruit.com/datasheets/TS16GUSDHC6.pdf */
        Ok(SDCardCSD {
            /* Byte 0 */
            CSDStruct: (csd_tab[0] & 0xC0) >> 6,
            SysSpecVersion: (csd_tab[0] & 0x3C) >> 2,
            Reserved1: csd_tab[0] & 0x03,
            /* Byte 1 */
            TAAC: csd_tab[1],
            /* Byte 2 */
            NSAC: csd_tab[2],
            /* Byte 3 */
            MaxBusClkFrec: csd_tab[3],
            /* Byte 4, 5 */
            CardComdClasses: (u16::from(csd_tab[4]) << 4) | ((u16::from(csd_tab[5]) & 0xF0) >> 4),
            /* Byte 5 */
            RdBlockLen: csd_tab[5] & 0x0F,
            /* Byte 6 */
            PartBlockRead: (csd_tab[6] & 0x80) >> 7,
            WrBlockMisalign: (csd_tab[6] & 0x40) >> 6,
            RdBlockMisalign: (csd_tab[6] & 0x20) >> 5,
            DSRImpl: (csd_tab[6] & 0x10) >> 4,
            Reserved2: 0,
            // DeviceSize: (csd_tab[6] & 0x03) << 10,
            /* Byte 7, 8, 9 */
            DeviceSize: ((u32::from(csd_tab[7]) & 0x3F) << 16)
                | (u32::from(csd_tab[8]) << 8)
                | u32::from(csd_tab[9]),
            /* Byte 10 */
            EraseGrSize: (csd_tab[10] & 0x40) >> 6,
            /* Byte 10, 11 */
            EraseGrMul: ((csd_tab[10] & 0x3F) << 1) | ((csd_tab[11] & 0x80) >> 7),
            /* Byte 11 */
            WrProtectGrSize: (csd_tab[11] & 0x7F),
            /* Byte 12 */
            WrProtectGrEnable: (csd_tab[12] & 0x80) >> 7,
            ManDeflECC: (csd_tab[12] & 0x60) >> 5,
            WrSpeedFact: (csd_tab[12] & 0x1C) >> 2,
            /* Byte 12,13 */
            MaxWrBlockLen: ((csd_tab[12] & 0x03) << 2) | ((csd_tab[13] & 0xC0) >> 6),
            /* Byte 13 */
            WriteBlockPaPartial: (csd_tab[13] & 0x20) >> 5,
            Reserved3: 0,
            ContentProtectAppli: (csd_tab[13] & 0x01),
            /* Byte 14 */
            FileFormatGroup: (csd_tab[14] & 0x80) >> 7,
            CopyFlag: (csd_tab[14] & 0x40) >> 6,
            PermWrProtect: (csd_tab[14] & 0x20) >> 5,
            TempWrProtect: (csd_tab[14] & 0x10) >> 4,
            FileFormat: (csd_tab[14] & 0x0C) >> 2,
            ECC: (csd_tab[14] & 0x03),
            /* Byte 15 */
            CSD_CRC: (csd_tab[15] & 0xFE) >> 1,
            Reserved4: 1,
            /* Return the reponse */
        })
    }

    /*
     * Read the CID card register.
     *         Reading the contents of the CID register in SPI mode is a simple
     *         read-block transaction.
     * @param  SD_cid: pointer on an CID register structure
     * @retval The SD Response:
     *         - `Err()`: Sequence failed
     *         - `Ok(info)`: Sequence succeed
     */
    fn get_cidregister(&self) -> Result<SDCardCID, ()> {
        let mut cid_tab = [0u8; 18];
        /* Send CMD10 (CID register) */
        self.send_cmd(CMD::CMD10, 0, 0);
        /* Wait for response in the R1 format (0x00 is no errors) */
        if self.get_response() != 0x00 {
            self.end_cmd();
            return Err(());
        }
        if self.get_response() != SD_START_DATA_SINGLE_BLOCK_READ {
            self.end_cmd();
            return Err(());
        }
        /* Store CID register value on cid_tab */
        /* Get CRC bytes (not really needed by us, but required by SD) */
        self.read_data(&mut cid_tab);
        self.end_cmd();
        Ok(SDCardCID {
            /* Byte 0 */
            ManufacturerID: cid_tab[0],
            /* Byte 1, 2 */
            OEM_AppliID: (u16::from(cid_tab[1]) << 8) | u16::from(cid_tab[2]),
            /* Byte 3, 4, 5, 6 */
            ProdName1: (u32::from(cid_tab[3]) << 24)
                | (u32::from(cid_tab[4]) << 16)
                | (u32::from(cid_tab[5]) << 8)
                | u32::from(cid_tab[6]),
            /* Byte 7 */
            ProdName2: cid_tab[7],
            /* Byte 8 */
            ProdRev: cid_tab[8],
            /* Byte 9, 10, 11, 12 */
            ProdSN: (u32::from(cid_tab[9]) << 24)
                | (u32::from(cid_tab[10]) << 16)
                | (u32::from(cid_tab[11]) << 8)
                | u32::from(cid_tab[12]),
            /* Byte 13, 14 */
            Reserved1: (cid_tab[13] & 0xF0) >> 4,
            ManufactDate: ((u16::from(cid_tab[13]) & 0x0F) << 8) | u16::from(cid_tab[14]),
            /* Byte 15 */
            CID_CRC: (cid_tab[15] & 0xFE) >> 1,
            Reserved2: 1,
        })
    }

    /*
     * Returns information about specific card.
     * @param  cardinfo: pointer to a SD_CardInfo structure that contains all SD
     *         card information.
     * @retval The SD Response:
     *         - `Err(())`: Sequence failed
     *         - `Ok(info)`: Sequence succeed
     */
    fn get_cardinfo(&self) -> Result<SDCardInfo, ()> {
        let mut info = SDCardInfo {
            SD_csd: self.get_csdregister()?,
            SD_cid: self.get_cidregister()?,
            CardCapacity: 0,
            CardBlockSize: 0,
        };
        info.CardBlockSize = 1 << u64::from(info.SD_csd.RdBlockLen);
        info.CardCapacity = (u64::from(info.SD_csd.DeviceSize) + 1) * 1024 * info.CardBlockSize;

        Ok(info)
    }

    /*
     * Initializes the SD/SD communication in SPI mode.
     * @param  None
     * @retval The SD Response info if succeeeded, otherwise Err
     */
    pub fn init(&self) -> Result<SDCardInfo, InitError> {
        /* Initialize SD_SPI */
        self.lowlevel_init();
        /* SD chip select high */
        self.CS_HIGH();
        /* NOTE: this reset doesn't always seem to work if the SD access was broken off in the
         * middle of an operation: CMDFailed(CMD0, 127). */

        /* Send dummy byte 0xFF, 10 times with CS high */
        /* Rise CS and MOSI for 80 clocks cycles */
        /* Send dummy byte 0xFF */
        self.write_data(&[0xff; 10]);
        /*------------Put SD in SPI mode--------------*/
        /* SD initialized and set to SPI mode properly */

        /* Send software reset */
        self.send_cmd(CMD::CMD0, 0, 0x95);
        let result = self.get_response();
        self.end_cmd();
        if result != 0x01 {
            return Err(InitError::CMDFailed(CMD::CMD0, result));
        }

        /* Check voltage range */
        self.send_cmd(CMD::CMD8, 0x01AA, 0x87);
        /* 0x01 or 0x05 */
        let result = self.get_response();
        let mut frame = [0u8; 4];
        self.read_data(&mut frame);
        self.end_cmd();
        if result != 0x01 {
            return Err(InitError::CMDFailed(CMD::CMD8, result));
        }
        let mut index = 255;
        while index != 0 {
            /* <ACMD> */
            self.send_cmd(CMD::CMD55, 0, 0);
            let result = self.get_response();
            self.end_cmd();
            if result != 0x01 {
                return Err(InitError::CMDFailed(CMD::CMD55, result));
            }
            /* Initiate SDC initialization process */
            self.send_cmd(CMD::ACMD41, 0x40000000, 0);
            let result = self.get_response();
            self.end_cmd();
            if result == 0x00 {
                break;
            }
            index -= 1;
        }
        if index == 0 {
            return Err(InitError::CMDFailed(CMD::ACMD41, result));
        }
        index = 255;
        let mut frame = [0u8; 4];
        while index != 0 {
            /* Read OCR */
            self.send_cmd(CMD::CMD58, 0, 1);
            let result = self.get_response();
            self.read_data(&mut frame);
            self.end_cmd();
            if result == 0 {
                break;
            }
            index -= 1;
        }
        if index == 0 {
            return Err(InitError::CMDFailed(CMD::CMD58, result));
        }
        if (frame[0] & 0x40) == 0 {
            return Err(InitError::CardCapacityStatusNotSet(frame));
        }
        self.HIGH_SPEED_ENABLE();
        self.get_cardinfo()
            .map_err(|_| InitError::CannotGetCardInfo)
    }

    /*
     * Reads a block of data from the SD.
     * @param  data_buf: slice that receives the data read from the SD.
     * @param  sector: SD's internal address to read from.
     * @retval The SD Response:
     *         - `Err(())`: Sequence failed
     *         - `Ok(())`: Sequence succeed
     */
    pub fn read_sector(&self, data_buf: &mut [u8], sector: u32) -> Result<(), ()> {
        assert!(data_buf.len() >= SEC_LEN && (data_buf.len() % SEC_LEN) == 0);
        /* Send CMD17 to read one block, or CMD18 for multiple */
        let flag = if data_buf.len() == SEC_LEN {
            self.send_cmd(CMD::CMD17, sector, 0);
            false
        } else {
            self.send_cmd(CMD::CMD18, sector, 0);
            true
        };
        /* Check if the SD acknowledged the read block command: R1 response (0x00: no errors) */
        if self.get_response() != 0x00 {
            self.end_cmd();
            return Err(());
        }
        let mut error = false;
        //let mut dma_chunk = [0u32; SEC_LEN];
        let mut tmp_chunk = [0u8; SEC_LEN];
        for chunk in data_buf.chunks_mut(SEC_LEN) {
            if self.get_response() != SD_START_DATA_SINGLE_BLOCK_READ {
                error = true;
                break;
            }
            /* Read the SD block data : read NumByteToRead data */
            //self.read_data_dma(&mut dma_chunk);
            self.read_data(&mut tmp_chunk);
            /* Place the data received as u32 units from DMA into the u8 target buffer */
            for (a, b) in chunk.iter_mut().zip(/*dma_chunk*/ tmp_chunk.iter()) {
                //*a = (b & 0xff) as u8;
                *a = *b;
            }
            /* Get CRC bytes (not really needed by us, but required by SD) */
            let mut frame = [0u8; 2];
            self.read_data(&mut frame);
        }
        self.end_cmd();
        if flag {
            self.send_cmd(CMD::CMD12, 0, 0);
            self.get_response();
            self.end_cmd();
            self.end_cmd();
        }
        /* It is an error if not everything requested was read */
        if error {
            Err(())
        } else {
            Ok(())
        }
    }

    /*
     * Writes a block to the SD
     * @param  data_buf: slice containing the data to be written to the SD.
     * @param  sector: address to write on.
     * @retval The SD Response:
     *         - `Err(())`: Sequence failed
     *         - `Ok(())`: Sequence succeed
     */
    pub fn write_sector(&self, data_buf: &[u8], sector: u32) -> Result<(), ()> {
        assert!(data_buf.len() >= SEC_LEN && (data_buf.len() % SEC_LEN) == 0);
        let mut frame = [0xff, 0x00];
        if data_buf.len() == SEC_LEN {
            frame[1] = SD_START_DATA_SINGLE_BLOCK_WRITE;
            self.send_cmd(CMD::CMD24, sector, 0);
        } else {
            frame[1] = SD_START_DATA_MULTIPLE_BLOCK_WRITE;
            self.send_cmd(
                CMD::ACMD23,
                (data_buf.len() / SEC_LEN).try_into().unwrap(),
                0,
            );
            self.get_response();
            self.end_cmd();
            self.send_cmd(CMD::CMD25, sector, 0);
        }
        /* Check if the SD acknowledged the write block command: R1 response (0x00: no errors) */
        if self.get_response() != 0x00 {
            self.end_cmd();
            return Err(());
        }
        //let mut dma_chunk = [0u32; SEC_LEN];
        let mut tmp_chunk = [0u8; SEC_LEN];
        for chunk in data_buf.chunks(SEC_LEN) {
            /* Send the data token to signify the start of the data */
            self.write_data(&frame);
            /* Write the block data to SD : write count data by block */
            for (a, &b) in /*dma_chunk*/ tmp_chunk.iter_mut().zip(chunk.iter()) {
                //*a = b.into();
                *a = b;
            }
            //self.write_data_dma(&mut dma_chunk);
            self.write_data(&tmp_chunk);
            /* Put dummy CRC bytes */
            self.write_data(&[0xff, 0xff]);
            /* Read data response */
            if self.get_dataresponse() != 0x00 {
                self.end_cmd();
                return Err(());
            }
        }
        self.end_cmd();
        self.end_cmd();
        Ok(())
    }
}

/** GPIOHS GPIO number to use for controlling the SD card CS pin */
const SD_CS_GPIONUM: u8 = 7;
/** CS value passed to SPI controller, this is a dummy value as SPI0_CS3 is not mapping to anything
 * in the FPIOA */
const SD_CS: u32 = 3;

/** Connect pins to internal functions */
fn io_init() {
    fpioa::set_function(io::SPI0_SCLK, fpioa::function::SPI0_SCLK);
    fpioa::set_function(io::SPI0_MOSI, fpioa::function::SPI0_D0);
    fpioa::set_function(io::SPI0_MISO, fpioa::function::SPI0_D1);
    fpioa::set_function(io::SPI0_CS0, fpioa::function::gpiohs(SD_CS_GPIONUM));
    fpioa::set_io_pull(io::SPI0_CS0, fpioa::pull::DOWN); // GPIO output=pull down
}

lazy_static! {
    static ref PERIPHERALS: UPSafeCell<Peripherals> =
        unsafe { UPSafeCell::new(Peripherals::take().unwrap()) };
}

fn init_sdcard() -> SDCard<SPIImpl<SPI0>> {
    // wait previous output
    usleep(100000);
    let peripherals = unsafe { Peripherals::steal() };
    sysctl::pll_set_freq(sysctl::pll::PLL0, 800_000_000).unwrap();
    sysctl::pll_set_freq(sysctl::pll::PLL1, 300_000_000).unwrap();
    sysctl::pll_set_freq(sysctl::pll::PLL2, 45_158_400).unwrap();
    let clocks = k210_hal::clock::Clocks::new();
    peripherals.UARTHS.configure(115_200.bps(), &clocks);
    io_init();

    let spi = peripherals.SPI0.constrain();
    let sd = SDCard::new(spi, SD_CS, SD_CS_GPIONUM);
    let info = sd.init().unwrap();
    let num_sectors = info.CardCapacity / 512;
    assert!(num_sectors > 0);

    println!("init sdcard!");
    sd
}

pub struct SDCardWrapper(UPSafeCell<SDCard<SPIImpl<SPI0>>>);

impl SDCardWrapper {
    pub fn new() -> Self {
        unsafe { Self(UPSafeCell::new(init_sdcard())) }
    }
}

impl BlockDevice for SDCardWrapper {
    fn read_block(&self, block_id: usize, buf: &mut [u8]) {
        self.0
            .exclusive_access()
            .read_sector(buf, block_id as u32)
            .unwrap();
    }
    fn write_block(&self, block_id: usize, buf: &[u8]) {
        self.0
            .exclusive_access()
            .write_sector(buf, block_id as u32)
            .unwrap();
    }
}
