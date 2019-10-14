module FC1003_RMII (
    //Sys/Common
    input  Clk,                    // 100 MHz
    input  Reset,                  // Active high
    input  UseDHCP,                // '1' to use DHCP
    input  [31:0] IP_Addr,         // IP address if not using DHCP
    output IP_Ok,                  // DHCP ready

    //MAC/RMII
    output RMII_CLK_50M,           // RMII continous 50 MHz reference clock
    output RMII_RST_N,             // Phy reset, active low
    input  RMII_CRS_DV,            // Carrier sense/Receive data valid
    input  RMII_RXD0,              // Receive data bit 0
    input  RMII_RXD1,              // Receive data bit 1
    input  RMII_RXERR,             // Receive error, optional
    output RMII_TXEN,              // Transmit enable
    output RMII_TXD0,              // Transmit data bit 0
    output RMII_TXD1,              // Transmit data bit 1
    output RMII_MDC,               // Management clock
    inout  RMII_MDIO,              // Management data

    //SPI/Boot Control
    output SPI_CSn,                // Chip select
    output SPI_SCK,                // Serial clock
    output SPI_MOSI,               // Master out slave in
    input  SPI_MISO,               // Master in slave out

    //Logic Analyzer
    input  LA0_TrigIn,             // Trigger input
    input  LA0_Clk,                // Clock
    output LA0_TrigOut,            // Trigger out
    input  [31:0] LA0_Signals,     // Signals
    input  LA0_SampleEn,           // Sample enable

    //UDP Basic Server
    input  UDP0_Reset,             // Reset interface, active high
    input  [15:0] UDP0_Service,    // Service
    input  [15:0] UDP0_ServerPort, // UDP local server port
    output UDP0_Connected,         // Client connected
    output UDP0_OutIsEmpty,        // All outgoing data acked
    input  [7:0] UDP0_TxData,      // Transmit data
    input  UDP0_TxValid,           // Transmit data valid
    output UDP0_TxReady,           // Transmit data ready
    input  UDP0_TxLast,            // Transmit data last
    output [7:0] UDP0_RxData,      // Receive data
    output UDP0_RxValid,           // Receive data valid
    input  UDP0_RxReady,           // Receive data ready
    output UDP0_RxLast             // Transmit data last
);

endmodule
