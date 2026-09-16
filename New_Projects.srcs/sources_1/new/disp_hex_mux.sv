`timescale 1ns / 1ps

module disp_hex_mux
(
    input logic clk, reset, disp_hi, full, empty,  
    input logic [3:0] hex4, hex3, hex2, hex1, hex0,
    input logic [3:0] dp_in,
    output logic [7:0] an,
    output logic [7:0] sseg
);

    localparam N = 18;

    logic [N-1:0] q_reg;
    logic [N-1:0] q_next;

    logic [3:0] hex_in;
    logic dp;

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
    // Display Multiplexing + Seven Segment Decoder
    //==========================================================

    always_comb begin

        // Default values
        an      = 8'b1111_1111;
        hex_in  = 4'h0;
        dp      = 1'b1;
        sseg    = 8'b1111_1111;

        //======================================================
        // HI Display
        //======================================================

        if (disp_hi) begin

            // H on hex1
            // I on hex0

            case (q_reg[N-1:N-2])

                2'b00: begin
                    an = 8'b1111_1110;
                    sseg[6:0] = 7'b1111001; // I
                    sseg[7] = 1'b1;
                end

                2'b01: begin
                    an = 8'b1111_1101;
                    sseg[6:0] = 7'b0001001; // H
                    sseg[7] = 1'b1;
                end

                default: begin
                    an = 8'b1111_1111;
                    sseg = 8'b1111_1111;
                end

            endcase

        end
        //======================================================
        // Normal Hex Display
        //======================================================

       else begin
    
        case (q_reg[N-1:N-3])
    
            //==================================================
            // FULL on upper four digits
            //==================================================
    
            3'b000: begin
                an = 8'b0111_1111; 
                hex_in = full ? 4'hF :
                         empty ? 4'hE : hex4; //E
                dp = 1'b1;
            end
    
            3'b001: begin
                an = full ? 8'b1011_1111 : 8'b1111_1111;
                hex_in = full ? 4'hB : 4'hA; //U
                dp = 1'b1;
            end
            
            3'b010: begin
                an = full ? 8'b1101_1111 : 8'b1111_1111;
                hex_in = full ? 4'hC : 4'hA; //L
                dp = 1'b1;
            end
            
            3'b011: begin
                an = full ? 8'b1110_1111 : 8'b1111_1111;
                hex_in = full ? 4'hC : 4'hA; //L
                dp = 1'b1;
            end 

        //==================================================
        // Lower four digits
        //==================================================

        3'b100: begin
            an = 8'b1111_1110;
            hex_in = hex0;
            dp = dp_in[0];
        end

        3'b101: begin
            an = 8'b1111_1101;
            hex_in = hex1;
            dp = dp_in[1];
        end

        3'b110: begin
            an = 8'b1111_1011;
            hex_in = hex2;
            dp = dp_in[2];
        end

        3'b111: begin
            an = 8'b1111_0111;
            hex_in = hex3;
            dp = dp_in[3];
        end

        default: begin
            an = 8'b1111_1111;
            hex_in = 4'h0;
            dp = 1'b1;
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
        4'hB: sseg[6:0] = 7'b1000001; // U
        4'hC: sseg[6:0] = 7'b1000111; // L
        // E
        4'hE: sseg[6:0] = 7'b0000110;

        // F
        4'hF: sseg[6:0] = 7'b0001110;

        // Blank
        4'hA: sseg[6:0] = 7'b1111111;

        default:
            sseg[6:0] = 7'b1111111;

    endcase

        sseg[7] = dp;
   end
end

endmodule