`timescale 1ns/1ps

module fifo_controller_w1r1
    #(
        parameter ADDR_WIDTH = 3
    ) (
        input  logic clk,
        input  logic reset,
        input  logic rd,
        input  logic wr,
        output logic empty,
        output logic full,
        output logic [ADDR_WIDTH:0] count,
        output logic [ADDR_WIDTH-1:0] w_addr,
        output logic [ADDR_WIDTH-1:0] r_addr
    );

    // Pointer registers
    logic [ADDR_WIDTH-1:0] w_ptr_reg, w_ptr_next;
    logic [ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next;

    // Occupancy counter
    logic [ADDR_WIDTH:0] count_reg, count_next;

    localparam MAX_CAPACITY = 1 << ADDR_WIDTH;

    // Registers
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            w_ptr_reg <= '0;
            r_ptr_reg <= '0;
            count_reg <= '0;
        end
        else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            count_reg <= count_next;
        end
    end

    // Next-state logic
    always_comb begin

        // Hold previous values by default
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        count_next = count_reg;
        
        unique case ({wr, rd})

            2'b01: begin
                // Read only
                if (!empty) begin
                    r_ptr_next = r_ptr_reg + 1;
                    count_next = count_reg - 1;
                end
            end

            2'b10: begin
                // Write only
                if (!full) begin
                    w_ptr_next = w_ptr_reg + 1;
                    count_next = count_reg + 1;
                end
            end

            2'b11: begin
                // Simultaneous read and write
                if (empty) begin
                    // Can't read from an empty FIFO.
                    // Write only.
                    w_ptr_next = w_ptr_reg + 1;
                    count_next = count_reg + 1;
                end

                else if (full) begin
                    // Can't write to a full FIFO.
                    // Read only.
                    r_ptr_next = r_ptr_reg + 1;
                    count_next = count_reg - 1;
                end

                else begin
                    // Both happen.
                    // +1 write -1 read = no change in count.
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                    count_next = count_reg;
                end
            end

            default: begin
                // Nothing happens
            end

        endcase
    end

    // Outputs
    assign w_addr = w_ptr_reg;
    assign r_addr = r_ptr_reg;
    assign count = count_reg; 

    assign empty = (count_reg == 0);
    assign full  = (count_reg >= MAX_CAPACITY);

endmodule