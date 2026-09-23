`timescale 1ns / 1ps

module disp_hex_mux
(
    input  logic       clk,
    input  logic       reset,
    input  logic [1:0] speed,

    output logic [7:0] an,
    output logic [7:0] sseg
);

    localparam N = 18;

    logic [N-1:0] q_reg;
    logic [N-1:0] q_next;

    logic [3:0] hex_in;
    logic       dp;

    //==========================================================
    // Multiplexing Counter
    //==========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            q_reg <= 0;
        else
            q_reg <= q_next;
    end

    assign q_next = q_reg + 1'b1;


    //==========================================================
    // Display Multiplexing
    //
    // Upper 4 digits:
    //     S P D [blank]
    //
    // Lower 4 digits:
    //     speed value
    //
    // speed 0 = 500
    // speed 1 = 200
    // speed 2 = 100
    // speed 3 =  50
    //==========================================================

    always_comb begin

        // Default values
        an      = 8'b1111_1111;
        hex_in  = 4'hA;       // blank
        dp      = 1'b1;
        sseg    = 8'b1111_1111;


        case (q_reg[N-1:N-3])

            //==================================================
            // Upper four digits: S P D [blank]
            //==================================================

            3'b000: begin
                an     = 8'b0111_1111;
                hex_in = 4'hB;       // S
            end

            3'b001: begin
                an     = 8'b1011_1111;
                hex_in = 4'hC;       // P
            end

            3'b010: begin
                an     = 8'b1101_1111;
                hex_in = 4'h0;       // D
            end

            3'b011: begin
                an     = 8'b1110_1111;
                hex_in = 4'hA;       // blank
            end


            //==================================================
            // Lower four digits: speed
            //==================================================

            // Rightmost digit
            3'b100: begin
                an = 8'b1111_1110;

                case (speed)
                    2'd0: hex_in = 4'h0; // 500
                    2'd1: hex_in = 4'h0; // 200
                    2'd2: hex_in = 4'h0; // 100
                    2'd3: hex_in = 4'h0; //  50
                    default: hex_in = 4'hA;
                endcase
            end

            // Second digit from right
            3'b101: begin
                an = 8'b1111_1101;

                case (speed)
                    2'd0: hex_in = 4'h0; // 500
                    2'd1: hex_in = 4'h0; // 200
                    2'd2: hex_in = 4'h0; // 100
                    2'd3: hex_in = 4'h5; //  50
                    default: hex_in = 4'hA;
                endcase
            end

            // Third digit from right
            3'b110: begin
                an = 8'b1111_1011;

                case (speed)
                    2'd0: hex_in = 4'h5; // 500
                    2'd1: hex_in = 4'h2; // 200
                    2'd2: hex_in = 4'h1; // 100
                    2'd3: hex_in = 4'hA; //  50 -> blank
                    default: hex_in = 4'hA;
                endcase
            end

            // Fourth digit from right
            3'b111: begin
                an = 8'b1111_0111;
                hex_in = 4'hA; // blank
            end

            default: begin
                an     = 8'b1111_1111;
                hex_in = 4'hA;
            end

        endcase


        //==================================================
        // Seven Segment Decoder
        //==================================================

        case (hex_in)

            4'h0: sseg[6:0] = 7'b1000000;
            4'h1: sseg[6:0] = 7'b1111001;
            4'h2: sseg[6:0] = 7'b0100100;
            4'h3: sseg[6:0] = 7'b0110000;
            4'h4: sseg[6:0] = 7'b0011001;
            4'h5: sseg[6:0] = 7'b0010010;
            4'h6: sseg[6:0] = 7'b0000010;
            4'h7: sseg[6:0] = 7'b1111000;
            4'h8: sseg[6:0] = 7'b0000000;
            4'h9: sseg[6:0] = 7'b0010000;

            // Blank
            4'hA: sseg[6:0] = 7'b1111111;

            // S
            4'hB: sseg[6:0] = 7'b0010010;

            // P
            4'hC: sseg[6:0] = 7'b0001100;

            // D
            4'hD: sseg[6:0] = 7'b1000001;

            default:
                sseg[6:0] = 7'b1111111;

        endcase

        sseg[7] = dp;

    end

endmodule
