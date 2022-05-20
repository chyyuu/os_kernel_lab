pub const CLOCK_FREQ: usize = 403000000 / 62;

pub const MMIO: &[(usize, usize)] = &[
    // we don't need clint in S priv when running
    // we only need claim/complete for target0 after initializing
    (0x0C00_0000, 0x3000), /* PLIC      */
    (0x0C20_0000, 0x1000), /* PLIC      */
    (0x3800_0000, 0x1000), /* UARTHS    */
    (0x3800_1000, 0x1000), /* GPIOHS    */
    (0x5020_0000, 0x1000), /* GPIO      */
    (0x5024_0000, 0x1000), /* SPI_SLAVE */
    (0x502B_0000, 0x1000), /* FPIOA     */
    (0x502D_0000, 0x1000), /* TIMER0    */
    (0x502E_0000, 0x1000), /* TIMER1    */
    (0x502F_0000, 0x1000), /* TIMER2    */
    (0x5044_0000, 0x1000), /* SYSCTL    */
    (0x5200_0000, 0x1000), /* SPI0      */
    (0x5300_0000, 0x1000), /* SPI1      */
    (0x5400_0000, 0x1000), /* SPI2      */
];

pub type BlockDeviceImpl = crate::drivers::block::SDCardWrapper;
