`timescale 1ns/1ps

module fifo_controller_W2R1
    #(
        parameter ADDR_WIDTH = 3
    ) (
    input logic clk, reset,
    input logic rd, wr,
    output logic empty, full,
    output logic [ADDR_WIDTH:0] count,
    output logic [ADDR_WIDTH-1:0] w_addr1, w_addr2, r_addr
);

    // Declarations 
    logic [ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next;
    logic [ADDR_WIDTH-1:0] w_ptr1_reg, w_ptr1_next;
    logic [ADDR_WIDTH-1:0] w_ptr2_reg, w_ptr2_next;
    
    // Byte occupancy counter to accurately track asymmetric write (+2 bytes) vs read (-1 byte)
    logic [ADDR_WIDTH:0] count_reg, count_next;
    localparam MAX_CAPACITY = 1 << ADDR_WIDTH; //Max Capacity is 8 

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            r_ptr_reg  <= '0;
            w_ptr1_reg <= '0;
            w_ptr2_reg <= 1'b1;
            count_reg  <= '0;
        end else begin
            r_ptr_reg  <= r_ptr_next;
            w_ptr1_reg <= w_ptr1_next;
            w_ptr2_reg <= w_ptr2_next;
            count_reg  <= count_next;
        end
    end

    // Next State Logic
    always_comb begin
        r_ptr_next  = r_ptr_reg;
        w_ptr1_next = w_ptr1_reg;
        w_ptr2_next = w_ptr2_reg;
        count_next  = count_reg;

        unique case({wr, rd})
            2'b01 : begin // Read only (consumes 1 byte)
                if (~empty) begin
                    r_ptr_next = r_ptr_reg + 1;
                    count_next = count_reg - 1;
                end
            end
            2'b10 : begin // Write only (produces 2 bytes / 16-bit word)
                if (~full) begin
                    w_ptr1_next = w_ptr1_reg + 2;
                    w_ptr2_next = w_ptr2_reg + 2;
                    count_next  = count_reg + 2;
                end
            end
            2'b11 : begin // Simultaneous Read & Write (+2 written, -1 read = +1 net)
                if (empty) begin
                    w_ptr1_next = w_ptr1_reg + 2;
                    w_ptr2_next = w_ptr2_reg + 2;
                    count_next  = count_reg + 2;
                end else if (full) begin
                    r_ptr_next  = r_ptr_reg + 1;
                    count_next  = count_reg - 1;
                end else begin
                    w_ptr1_next = w_ptr1_reg + 2;
                    w_ptr2_next = w_ptr2_reg + 2;
                    r_ptr_next  = r_ptr_reg + 1;
                    count_next  = count_reg + 1;
                end
            end
            default : ;
        endcase
    end

    // Output Logic
    assign w_addr1 = w_ptr1_reg;
    assign w_addr2 = w_ptr2_reg;
    assign r_addr  = r_ptr_reg;
    assign empty = (count_reg == 0);
    assign count = count_reg; 
    assign full = (count_reg >= MAX_CAPACITY - 1);

endmodule