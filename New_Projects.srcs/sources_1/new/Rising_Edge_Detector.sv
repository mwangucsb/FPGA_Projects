`timescale 1ns / 1ps

// Rising Edge Detector
module Rising_Edge_Detector 
(
    input  logic clk,
    input  logic in,
    input  logic reset,
    output logic out
);

    logic [1:0] state, next_state;

    localparam logic [1:0] LOW    = 2'b00;
    localparam logic [1:0] RISING = 2'b01;
    localparam logic [1:0] HIGH   = 2'b10;

    // State register
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= LOW;
        end
        else begin
            state <= next_state;
        end
    end

    // Next-state logic
    always_comb begin
        case (state)

            LOW: begin
                if (in)
                    next_state = RISING;
                else
                    next_state = LOW;
            end

            RISING: begin
                if (in)
                    next_state = HIGH;
                else
                    next_state = LOW;
            end

            HIGH: begin
                if (!in)
                    next_state = LOW;
                else
                    next_state = HIGH;
            end

            default:
                next_state = LOW;

        endcase
    end

    // Output
    assign out = (state == RISING);

endmodule