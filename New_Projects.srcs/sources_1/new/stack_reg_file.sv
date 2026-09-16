`timescale 1ns / 1ps 
 
module stack_reg_file #( 
    parameter DATA_WIDTH = 8,  
              ADDR_WIDTH = 3 
) 
( 
    input logic clk, 
    input logic push_en,  
    input logic pop_en,  
    input logic [ADDR_WIDTH - 1 : 0] addr,  
    input logic [DATA_WIDTH - 1 : 0] w_data, 
    output logic [DATA_WIDTH - 1 : 0] r_data 
); 
 
    logic [DATA_WIDTH - 1 : 0] array_reg [0 : 2**ADDR_WIDTH - 1];  
 
    always_ff @(posedge clk) begin 
        if (push_en) begin 
            array_reg[addr] <= w_data; 
        end 
    end 
 
    always_ff @(posedge clk) begin 
        if (pop_en) begin 
            r_data <= array_reg[addr]; 
        end 
    end 
 
endmodule