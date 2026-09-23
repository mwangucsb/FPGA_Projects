`timescale 1ns / 1ps

module uart_rx
#(
    parameter DBIT = 8, // # data bits
              SB_TICK = 16 //# ticks for stop bit
)
(
    input logic clk, reset, 
    input logic rx, s_tick, 
    output logic rx_done_tick, 
    output logic [7:0] dout
); 

    typedef enum {idle, start, data, stop} state_type; 
    
    state_type state_reg, state_next; 
    logic [3:0] s_reg, s_next; 
    logic [2:0] n_reg, n_next; 
    logic [7:0] b_reg, b_next; 

    always_ff @(posedge clk) begin
        if(reset) begin
            state_reg <= idle; 
            s_reg <= 0; 
            n_reg <= 0; 
            b_reg <= 0; 
        end
        else begin
            state_reg <= state_next; 
            s_reg <= s_next; 
            n_reg <= n_next; 
            b_reg <= b_next; 
        end
    end

    always_comb begin
        state_next = state_reg; 
        rx_done_tick = 1'b0; 
        s_next = s_reg; 
        n_next = n_reg; 
        b_next = b_reg; 
        
        case(state_reg) 
            idle: 
                if(~rx) begin //When detect bit 0 then the next state is start
                    s_next = 0; 
                    state_next = start; 
                end
            start: 
                if(s_tick) begin
                    if(s_reg == 7) begin //Waits 7 ticks middle of start bit to move to data bit
                        s_next = 0; 
                        n_next = 0; 
                        state_next = data; 
                    end
                    else begin
                        s_next = s_reg + 1;
                    end
                end
            data: 
                if(s_tick) begin
                    if(s_reg == 15) begin
                        s_next = 0; 
                        b_next = {rx, b_reg[7:1]}; //Value read at the middle of data bit is transmitted to MSB of b register
                        if(n_reg == (DBIT - 1)) begin
                            state_next = stop;  //Wait until n goes through 8 bits until transition to stop state
                        end
                        else begin
                            n_next = n_reg + 1;
                        end
                    end
                    else begin
                        s_next = s_reg + 1; 
                    end
                end
            stop: 
                if(s_tick) begin
                    if(s_reg == (SB_TICK - 1)) begin //Waits SB_Tick ticks for stop cycle to transition state
                        rx_done_tick = 1; 
                        state_next = idle; 
                    end
                    else begin
                        s_next = s_reg + 1; 
                    end
                end
        endcase
        
    end
    
    assign dout = b_reg; //The output data is equal to b_reg
    
endmodule
