`timescale 1ns/1ps

module reg_file_w1r1
    #(
        parameter DATA_WIDTH = 8,
                  ADDR_WIDTH = 3
    ) (
        input  logic clk,
        input  logic wr_en,
        input logic rd_en, 
        input  logic [ADDR_WIDTH-1:0] w_addr,
        input  logic [ADDR_WIDTH-1:0] r_addr,
        input  logic [DATA_WIDTH-1:0] w_data,
        output logic [DATA_WIDTH-1:0] r_data
    );

    localparam DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write
    always_ff @(posedge clk) begin
        if (wr_en) begin
            mem[w_addr] <= w_data;
        end
    end
    always_ff @(posedge clk) begin
        if (rd_en) begin
             r_data <= mem[r_addr];
        end
    end

endmodule