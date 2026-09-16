`timescale 1ns / 1ps

module fifo_stack_tb;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 3;

    // Signals
    logic clk;
    logic reset;
    logic push;
    logic pop;
    logic [DATA_WIDTH-1:0] w_data;

    logic empty;
    logic full;
    logic [DATA_WIDTH-1:0] r_data;

    // Instantiate stack
    fifo_stack
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    dut
    (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .w_data(w_data),
        .empty(empty),
        .full(full),
        .r_data(r_data)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin

        // Initial values
        clk = 0;
        reset = 1;
        push = 0;
        pop = 0;
        w_data = 0;

        // Reset
        #10;
        reset = 0;

        // -------------------------
        // Push 10
        // -------------------------
        @(negedge clk);
        push = 1;
        w_data = 8'd10;

        @(negedge clk);
        push = 0;

        // -------------------------
        // Push 20
        // -------------------------
        @(negedge clk);
        push = 1;
        w_data = 8'd20;

        @(negedge clk);
        push = 0;

        // -------------------------
        // Push 30
        // -------------------------
        @(negedge clk);
        push = 1;
        w_data = 8'd30;

        @(negedge clk);
        push = 0;

        // -------------------------
        // Pop → should get 30
        // -------------------------
        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        // -------------------------
        // Pop → should get 20
        // -------------------------
        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        // -------------------------
        // Pop → should get 10
        // -------------------------
        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        // End simulation
        #20;
        $finish;

    end

endmodule
