`timescale 1ns / 1ps 
 
module fifo_stack 
#( 
    parameter DATA_WIDTH = 8,  
              ADDR_WIDTH = 3 
) 
( 
    input logic clk, reset,  
    input logic push, pop,  
    input logic [DATA_WIDTH - 1 : 0] w_data, 
    output logic empty, full, 
    output logic [ADDR_WIDTH:0] count,
    output logic [DATA_WIDTH - 1 : 0] r_data 
); 
 
    logic [ADDR_WIDTH - 1 : 0] addr; 
    
    logic push_en;  
    logic pop_en; 
 
    assign push_en = push & ~full;  
    assign pop_en  = pop && !empty; 
     
    stack_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) c_unit  
    (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .empty(empty),
        .full(full),
        .count(count), 
        .addr(addr)
    ); 
     
    stack_reg_file #(
        .DATA_WIDTH(DATA_WIDTH), 
        .ADDR_WIDTH(ADDR_WIDTH)
    ) f_unit
    (
        .clk(clk), 
        .push_en(push_en), 
        .pop_en(pop_en), 
        .addr(addr), 
        .w_data(w_data), 
        .r_data(r_data) 
    );   
     
endmodule