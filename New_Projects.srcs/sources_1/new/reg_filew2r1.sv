`timescale 1ns / 1ps

module reg_filew2r1
    #(
        parameter DATA_WIDTH = 8, 
        parameter ADDR_WIDTH = 3
    )
    (
        input  logic                      clk, 
        input  logic                      wr_en, 
        input logic                       rd_en, 
        input  logic [ADDR_WIDTH-1:0]     w_addr1, w_addr2, 
        input  logic [DATA_WIDTH-1:0]     w_data1, w_data2, 
        input  logic [ADDR_WIDTH-1:0]     r_addr,   
        output logic [DATA_WIDTH-1:0]     r_data
    );

    logic [DATA_WIDTH - 1 : 0] array_reg [0: 2 ** ADDR_WIDTH - 1]; 

    always_ff @(posedge clk) begin
        if(wr_en) begin
            array_reg[w_addr1] <= w_data1; 
            array_reg[w_addr2] <= w_data2; 
        end
    end
    
    always_ff @(posedge clk) begin
        if (rd_en) begin
             r_data <= array_reg[r_addr];
        end
    end
endmodule