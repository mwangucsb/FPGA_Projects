module uart
   #(
    parameter DBIT = 8,
              SB_TICK = 16,
              FIFO_W = 2
    )
    (
    input logic clk,
    input logic reset,
    input logic rd_uart,
    input logic wr_uart,
    input logic rx,
    input logic [7:0] w_data,
    input logic [10:0] dvsr,

    output logic tx_full,
    output logic rx_empty,
    output logic tx,
    output logic [7:0] r_data
    );

    // Internal signals
    logic tick;
    logic rx_done_tick;
    logic tx_done_tick;

    logic tx_empty;
    logic tx_fifo_not_empty;

    logic [7:0] tx_fifo_out;
    logic [7:0] rx_data_out;


    // =========================================================
    // Baud rate generator
    // =========================================================

    baud_gen baud_gen_unit (
        .clk   (clk),
        .reset (reset),
        .dvsr  (dvsr),
        .tick  (tick)
    );


    // =========================================================
    // UART Receiver
    // =========================================================

    uart_rx #(
        .DBIT    (DBIT),
        .SB_TICK (SB_TICK)
    ) uart_rx_unit (
        .clk          (clk),
        .reset        (reset),
        .rx           (rx),
        .s_tick       (tick),
        .rx_done_tick (rx_done_tick),
        .dout         (rx_data_out)
    );


    // =========================================================
    // UART Transmitter
    // =========================================================

    uart_tx tx_unit (
        .clk          (clk),
        .reset        (reset),
        .tx_start     (tx_fifo_not_empty),
        .s_tick       (tick),
        .din          (tx_fifo_out),
        .tx_done_tick (tx_done_tick),
        .tx            (tx)
    );


    // =========================================================
    // RX FIFO
    // =========================================================

    fifo #(
        .DATA_WIDTH (DBIT),
        .ADDR_WIDTH (FIFO_W)
    ) fifo_rx_unit (
        .clk   (clk),
        .reset (reset),
        .rd    (rd_uart),
        .wr    (rx_done_tick), //Finish storing byte in buffer
        .w_data (rx_data_out), //Store value of rx_data_out in buffer 
        .empty (rx_empty),
        .full  (),
        .r_data (r_data)
    );


    // =========================================================
    // TX FIFO
    // =========================================================

    fifo #(
        .DATA_WIDTH (DBIT),
        .ADDR_WIDTH (FIFO_W)
    ) fifo_tx_unit (
        .clk   (clk),
        .reset (reset),
        .rd    (tx_done_tick),
        .wr    (wr_uart),
        .w_data (w_data), //Put write data of uart into a fifo buffer
        .empty (tx_empty),
        .full  (tx_full),
        .r_data (tx_fifo_out)
    );


    // TX FIFO has data waiting for transmitter
    assign tx_fifo_not_empty = ~tx_empty;

endmodule