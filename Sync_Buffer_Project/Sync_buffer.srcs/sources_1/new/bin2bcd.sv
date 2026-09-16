`timescale 1ns / 1ps

module bin2bcd
(
    input logic clk, reset, 
    input logic start, 
    input logic [7:0] bin, 
    output logic ready, done_tick, 
    output logic [3:0] bcd3, bcd2, bcd1, bcd0
);

typedef enum {idle, op, done} state_type; 

state_type state_reg, state_next; 
logic [7:0] p2s_reg, p2s_next; 
logic [3:0] bcd3_reg, bcd2_reg, bcd1_reg, bcd0_reg; 
logic [3:0] bcd3_next, bcd2_next, bcd1_next, bcd0_next; 
logic [3:0] n_reg, n_next; 
logic [3:0] bcd3_tmp, bcd2_tmp, bcd1_tmp, bcd0_tmp; 

always_ff @(posedge clk) begin
    if(reset) begin
        state_reg <= idle; 
        p2s_reg <= 0; 
        n_reg <= 0; 
        bcd3_reg <= 0; 
        bcd2_reg <= 0; 
        bcd1_reg <= 0; 
        bcd0_reg <= 0; 
    end
    else begin
        state_reg <= state_next; 
        p2s_reg <= p2s_next; 
        n_reg <= n_next; 
        bcd3_reg <= bcd3_next; 
        bcd2_reg <= bcd2_next; 
        bcd1_reg <= bcd1_next; 
        bcd0_reg <= bcd0_next; 
    end
end

always_comb begin
    ready = 1'b0; 
    state_next = state_reg; 
    bcd3_next = bcd3_reg; 
    bcd2_next = bcd2_reg; 
    bcd1_next = bcd1_reg; 
    bcd0_next = bcd0_reg;
    n_next = n_reg; 
    p2s_next = p2s_reg;  
    done_tick = 1'b0; 
    
    case(state_reg)
        idle: begin
            ready = 1'b1;
            if(start) begin
                state_next = op; 
                p2s_next = bin; 
                n_next = 4'd8;
                bcd3_next = 0; 
                bcd2_next = 0; 
                bcd1_next = 0; 
                bcd0_next = 0; 
            end
        end
        
        op: begin
            n_next = n_reg - 1; 
            p2s_next = p2s_reg << 1;
            bcd3_next = {bcd3_tmp[2:0], bcd2_tmp[3]}; 
            bcd2_next = {bcd2_tmp[2:0], bcd1_tmp[3]}; 
            bcd1_next = {bcd1_tmp[2:0], bcd0_tmp[3]}; 
            bcd0_next = {bcd0_tmp[2:0], p2s_reg[7]}; 
            if(n_next == 0) begin
                state_next = done; 
            end
        end
        
        done: begin
            done_tick = 1'b1; 
            state_next = idle; 
        end
    endcase
    end
    
    assign bcd0_tmp = (bcd0_reg > 4) ? bcd0_reg + 3 : bcd0_reg; 
    assign bcd1_tmp = (bcd1_reg > 4) ? bcd1_reg + 3 : bcd1_reg;
    assign bcd2_tmp = (bcd2_reg > 4) ? bcd2_reg + 3 : bcd2_reg;
    assign bcd3_tmp = (bcd3_reg > 4) ? bcd3_reg + 3 : bcd3_reg;   
    
    assign bcd0 = bcd0_reg; 
    assign bcd1 = bcd1_reg; 
    assign bcd2 = bcd2_reg; 
    assign bcd3 = bcd3_reg;  

endmodule
