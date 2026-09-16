`timescale 1ns / 1ps

module sync_buff_stack (
    input  logic       clk,
    input  logic       reset,
    input  logic [15:0] sw,
    input  logic       rd,
    input  logic       wr,
    output logic [7:0] an,
    output logic [7:0] sseg
);

    //==========================================================
    // Write Data
    //==========================================================

    logic [7:0] write_data;

    assign write_data = sw;


    //==========================================================
    // Signals
    //==========================================================

    logic [3:0] bcd4, bcd3, bcd2, bcd1, bcd0;

    logic       ready;
    logic       done_tick;

    logic [7:0] r_data;
    logic [7:0] display_data;

    logic [3:0] count;
    logic       empty;
    logic       full;

    logic wr_db, rd_db;
    logic wr_final, rd_final;

    logic rd_valid;
    logic rd_valid_d;
    logic display_start;


    //==========================================================
    // Stack Status Display
    //==========================================================

    always_comb begin
        if (full)
            bcd4 = 4'hF;
        else if (empty)
            bcd4 = 4'hE;
        else
            bcd4 = count;
    end


    //==========================================================
    // Determine if the pop was valid
    //==========================================================

    assign rd_valid = rd_final && !empty;


    //==========================================================
    // Delay the valid read by one clock
    //==========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_valid_d <= 1'b0;
        end
        else begin
            rd_valid_d <= rd_valid;
        end
    end


    //==========================================================
    // Store the value that should be displayed
    //==========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            display_data <= 8'd0;

        // Valid pop: r_data now contains the popped value
        else if (rd_valid_d)
            display_data <= r_data;

        // Pop attempted while stack is empty
        else if (rd_final && empty)
            display_data <= 8'd0;
    end


    //==========================================================
    // Delay display update before starting BCD conversion
    //==========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            display_start <= 1'b0;
        else
            display_start <= rd_valid_d || (rd_final && empty);
    end


    //==========================================================
    // Write Debouncer
    //==========================================================

    db_fsm wr_instdb (
        .clk(clk),
        .reset(reset),
        .sw(wr),
        .db(wr_db)
    );


    //==========================================================
    // Read Debouncer
    //==========================================================

    db_fsm rd_instdb (
        .clk(clk),
        .reset(reset),
        .sw(rd),
        .db(rd_db)
    );


    //==========================================================
    // Write Rising Edge Detector
    //==========================================================

    Rising_Edge_Detector wr_rise (
        .clk(clk),
        .reset(reset),
        .in(wr_db),
        .out(wr_final)
    );


    //==========================================================
    // Read Rising Edge Detector
    //==========================================================

    Rising_Edge_Detector rd_rise (
        .clk(clk),
        .reset(reset),
        .in(rd_db),
        .out(rd_final)
    );


    //==========================================================
    // Stack
    //==========================================================

    fifo_stack #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(3)
    ) stack (
        .clk(clk),
        .reset(reset),

        .push(wr_final),
        .pop(rd_final),

        .w_data(write_data),
        .r_data(r_data),

        .count(count),
        .empty(empty),
        .full(full)
    );


    //==========================================================
    // Binary to BCD
    //==========================================================

    bin2bcd u_bin2bcd (
        .clk(clk),
        .reset(reset),

        .start(display_start),
        .bin(display_data),

        .ready(ready),
        .done_tick(done_tick),

        .bcd3(bcd3),
        .bcd2(bcd2),
        .bcd1(bcd1),
        .bcd0(bcd0)
    );


    //==========================================================
    // Seven-Segment Display
    //==========================================================

    disp_hex_mux u_disp (
        .clk(clk),
        .reset(reset),
        .full(full), 
        .disp_hi(1'b0),
        .hex4(bcd4),
        .hex3(bcd3),
        .hex2(bcd2),
        .hex1(bcd1),
        .hex0(bcd0),

        .dp_in(4'b1111),

        .an(an),
        .sseg(sseg)
    );

endmodule