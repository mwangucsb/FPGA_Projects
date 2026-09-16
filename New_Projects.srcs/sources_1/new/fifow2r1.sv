`timescale 1ns / 1ps


module fifow2r1
#(
    parameter DATA_WIDTH = 8, 
              ADDR_WIDTH = 3
)

(
    input logic clk, reset, 
    input logic rd, wr, 
    input logic [DATA_WIDTH - 1 : 0] w_data1, w_data2, 
    output logic empty, full, 
    output logic [ADDR_WIDTH:0] count, 
    output logic [DATA_WIDTH - 1 : 0] r_data
);

    logic [ADDR_WIDTH - 1 : 0] w_addr1, w_addr2, r_addr; 
    logic wr_en, rd_en;
    
    assign wr_en = wr & ~full; 
    assign rd_en = rd && !empty; 

    fifo_controller_W2R1 #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) controller (
        .clk(clk),
        .reset(reset),
        .rd(rd),
        .wr(wr),
        .empty(empty),
        .full(full),
        .count(count), 
        .w_addr1(w_addr1),
        .w_addr2(w_addr2), 
        .r_addr(r_addr)
    );


    reg_filew2r1 #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH)
        ) memory (
            .clk(clk),
            .wr_en(wr_en),
            .rd_en(rd_en),
            .w_addr1(w_addr1),
            .w_addr2(w_addr2),
            .r_addr(r_addr),
            .w_data1(w_data1),
            .w_data2(w_data2), 
            .r_data(r_data)
        );
endmodule
