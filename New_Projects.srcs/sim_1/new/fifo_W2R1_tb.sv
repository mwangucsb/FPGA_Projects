`timescale 1ns / 1ps

module fifo_W2R1_tb;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 3;

    logic clk;
    logic reset;

    logic rd;
    logic wr;

    logic [DATA_WIDTH-1:0] w_data1;
    logic [DATA_WIDTH-1:0] w_data2;

    logic empty;
    logic full;

    logic [DATA_WIDTH-1:0] r_data;

    fifo_W2R1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk     (clk),
        .reset   (reset),
        .rd      (rd),
        .wr      (wr),
        .w_data1 (w_data1),
        .w_data2 (w_data2),
        .empty   (empty),
        .full    (full),
        .r_data  (r_data)
    );

    // 100 MHz clock = 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // One write operation
    task write_fifo(
        input logic [7:0] data1,
        input logic [7:0] data2
    );
        begin
            @(negedge clk);

            w_data1 = data1;
            w_data2 = data2;

            wr = 1'b1;
            rd = 1'b0;

            // One clock-cycle write pulse
            @(negedge clk);

            wr = 1'b0;

            // 10 ns interval before next operation
            #10;
        end
    endtask

    // One read operation
    task read_fifo;
        begin
            @(negedge clk);

            rd = 1'b1;
            wr = 1'b0;

            // One clock-cycle read pulse
            @(negedge clk);

            rd = 1'b0;

            // 10 ns interval before next operation
            #10;
        end
    endtask

    initial begin

        reset   = 1'b1;
        rd      = 1'b0;
        wr      = 1'b0;
        w_data1 = 8'h00;
        w_data2 = 8'h00;

        #20;
        reset = 1'b0;

        // -------------------------
        // Basic write/read
        // -------------------------

        write_fifo(8'hAA, 8'hBB);

        read_fifo;
        read_fifo;

        // -------------------------
        // Multiple writes
        // -------------------------

        write_fifo(8'h10, 8'h11);
        write_fifo(8'h20, 8'h21);
        write_fifo(8'h30, 8'h31);

        // -------------------------
        // Read them back
        // -------------------------

        read_fifo;
        read_fifo;
        read_fifo;
        read_fifo;
        read_fifo;
        read_fifo;

        // -------------------------
        // Fill FIFO
        // -------------------------

        write_fifo(8'h01, 8'h02);
        write_fifo(8'h03, 8'h04);
        write_fifo(8'h05, 8'h06);
        write_fifo(8'h07, 8'h08);

        // Attempt write while full
        write_fifo(8'hAA, 8'hBB);

        // Read one byte
        read_fifo;

        // Write again
        write_fifo(8'hCC, 8'hDD);

        #20;

        $finish;

    end

endmodule