`timescale 1ns / 1ps

module stack_ctrl
#(
    parameter ADDR_WIDTH = 3
)
(
    input  logic clk,
    input  logic reset,
    input  logic push,
    input  logic pop,

    output logic [ADDR_WIDTH:0] count,
    output logic empty,
    output logic full,

    output logic [ADDR_WIDTH-1:0] addr
);
    logic [ADDR_WIDTH : 0] sp, sp_next; 

    localparam int DEPTH = 2**ADDR_WIDTH;  
    
    always_ff @(posedge clk) begin
        if(reset) begin
            sp <= 0; 
        end
        else begin
            sp <= sp_next; 
        end
    end
    
    always_comb begin
        sp_next = sp; 
        if(~full & push) begin
            sp_next = sp + 1; 
        end
        else if(~empty & pop) begin
            sp_next = sp - 1; 
        end
    end
    
    assign full = (sp == DEPTH); 
    assign empty = (sp == 0); 
    assign count = sp; 
    assign addr = pop ? (sp - 1) : sp; 
    
endmodule
