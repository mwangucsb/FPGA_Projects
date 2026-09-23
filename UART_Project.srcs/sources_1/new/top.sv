`timescale 1ns/1ps
//Test p and r 
module top (
    input  logic        clk,
    input  logic        reset,
    input  logic        rx,
    output logic        tx,
    output logic [15:0] led,
    output logic [7:0]  an,
    output logic [7:0]  sseg
);

    // =========================================================
    // Timer
    //
    // 100 MHz clock
    //
    // speed = 0 -> 500 ms
    // speed = 1 -> 200 ms
    // speed = 2 -> 100 ms
    // speed = 3 ->  50 ms
    // =========================================================

    logic [25:0] timer_count;
    logic [25:0] timer_limit;
    logic        timer_tick;
    logic [1:0]  speed;


    // =========================================================
    // Seven-Segment Display
    // =========================================================

    disp_hex_mux disp_unit (
        .clk   (clk),
        .reset (reset),
        .speed (speed),
        .an    (an),
        .sseg  (sseg)
    );


    // =========================================================
    // Variable Timer
    // =========================================================

    always_comb begin

        case (speed)

            2'd0:
                timer_limit = 26'd49_999_999; // 500 ms

            2'd1:
                timer_limit = 26'd19_999_999; // 200 ms

            2'd2:
                timer_limit = 26'd9_999_999;  // 100 ms

            2'd3:
                timer_limit = 26'd4_999_999;  // 50 ms

            default:
                timer_limit = 26'd19_999_999; //200 ms

        endcase

    end


    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            timer_count <= 26'd0;
            timer_tick  <= 1'b0;

        end

        else if (timer_count == timer_limit) begin

            timer_count <= 26'd0;
            timer_tick  <= 1'b1;

        end

        else begin

            timer_count <= timer_count + 1'b1;
            timer_tick  <= 1'b0;

        end

    end


    // =========================================================
    // UART Signals
    // =========================================================

    logic       rd_uart;
    logic       wr_uart;

    logic [7:0] w_data;
    logic [7:0] r_data;

    logic       tx_full;
    logic       rx_empty;

    logic [10:0] dvsr;


    // 100 MHz / (16 * 9600) - 1 ≈ 650
    assign dvsr = 11'd650;


    // =========================================================
    // UART
    // =========================================================

    uart #(
        .DBIT(8),
        .SB_TICK(16),
        .FIFO_W(2)
    ) uart_unit (
        .clk      (clk),
        .reset    (reset),
        .rd_uart  (rd_uart),
        .wr_uart  (wr_uart),
        .rx       (rx),
        .w_data   (w_data),
        .dvsr     (dvsr),
        .tx_full  (tx_full),
        .rx_empty (rx_empty),
        .tx       (tx),
        .r_data   (r_data)
    );


    // =========================================================
    // FSM
    // =========================================================

    typedef enum logic [2:0] {
        IDLE,
        READ_RX,
        PROCESS_RX,
        WAIT_RX,
        FLASH_LED
    } state_t;

    state_t state;


    // =========================================================
    // LED Control
    // =========================================================

    logic [3:0] led_index;
    logic       running;
    logic       paused; 


    // =========================================================
    // Main FSM
    // =========================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            state     <= IDLE;

            led       <= 16'b0;
            led_index <= 4'd0;
            running   <= 1'b0;

            speed     <= 2'd0;
            paused    <= 1'b0; 
            rd_uart   <= 1'b0;
            wr_uart   <= 1'b0;
            w_data    <= 8'h00;

        end
        else begin

            // -------------------------------------------------
            // Default UART controls
            // -------------------------------------------------

            rd_uart <= 1'b0;
            wr_uart <= 1'b0;
            w_data  <= 8'h00;


            case (state)


                // =================================================
                // IDLE
                //
                // Wait for a character from PuTTY
                // =================================================

                IDLE: begin

                    if (!rx_empty)
                        state <= READ_RX;

                end


                // =================================================
                // READ_RX
                //
                // Remove one byte from RX FIFO
                // =================================================

                READ_RX: begin

                    rd_uart <= 1'b1;

                    state <= WAIT_RX;

                end
                
                //WAIT_RX
                //
                //Gives an extra clock cycle for r_data to update. 
                WAIT_RX: begin
                    state <= PROCESS_RX;
                end
                // =================================================
                // PROCESS_RX
                //
                // Valid commands:
                //
                // 0-9 -> Start LED sequence
                // a-f -> Start LED sequence
                // +   -> Increase speed
                // -   -> Decrease speed
                // =================================================

                PROCESS_RX: begin
                    
                    //This is when you press r equal to reset 
                    if(r_data == 8'h72) begin
                        state <= IDLE;
                        led <= 16'b0;
                        led_index <= 4'd0;
                        running <= 1'b0;
                        paused <=  1'b0; 
                        speed <= 2'd0;
                    end
                    // -------------------------------------------------
                    // CASE 1: ASCII '0' through '9'
                    // -------------------------------------------------

                    else if ((r_data >= 8'h30) &&
                        (r_data <= 8'h39)) begin

                        // Convert ASCII to LED number
                        //
                        // '0' = 0
                        // '1' = 1
                        // ...
                        // '9' = 9

                        led_index <= r_data - 8'h30;

                        // Light corresponding LED

                        led <= 16'b1 <<
                               (r_data - 8'h30);

                        running <= 1'b1;
                        paused  <= 1'b0;

                        // Send same character back to PuTTY

                        if (!tx_full) begin

                            wr_uart <= 1'b1;
                            w_data  <= r_data;

                        end

                    end


                    // -------------------------------------------------
                    // CASE 2: ASCII lowercase 'a' through 'f'
                    // -------------------------------------------------

                    else if ((r_data >= 8'h61) &&
                             (r_data <= 8'h66)) begin

                        // Convert:
                        //
                        // a -> 10
                        // b -> 11
                        // c -> 12
                        // d -> 13
                        // e -> 14
                        // f -> 15

                        led_index <= r_data - 8'h61 + 4'd10;

                        // Light corresponding LED

                        led <= 16'b1 <<
                               (r_data - 8'h61 + 4'd10);

                        running <= 1'b1;
                        paused  <= 1'b0;

                        // Send same character back to PuTTY

                        if (!tx_full) begin

                            wr_uart <= 1'b1;
                            w_data  <= r_data;

                        end

                    end


                    // -------------------------------------------------
                    // CASE 3: '+'
                    //
                    // Increase speed
                    //
                    // 500 -> 200 -> 100 -> 50 ms
                    // -------------------------------------------------

                    else if (r_data == 8'h2B) begin

                        if (speed < 2'd3)
                            speed <= speed + 1'b1;

                    end


                    // -------------------------------------------------
                    // CASE 4: '-'
                    //
                    // Decrease speed
                    //
                    // 50 -> 100 -> 200 -> 500 ms
                    // -------------------------------------------------

                    else if (r_data == 8'h2D) begin

                        if (speed > 2'd0)
                            speed <= speed - 1'b1;

                    end
                    // -------------------------------------------------
                    // CASE 5: 'p'
                    //
                    //Pause Command
                    else if (r_data == 8'h70) begin
                            paused <= ~paused;
                            running <= 1'b1; 
                            state <= FLASH_LED; 
                    end
                    // -------------------------------------------------
                    // Invalid character
                    // -------------------------------------------------

                    else begin

                        running <= 1'b0;
                        led     <= 16'b0;
                    end


                    // Go to LED state
                    if (r_data != 8'h72) begin
                        state <= FLASH_LED;    
                    end

                end


                // =================================================
                // FLASH_LED
                //
                // Move to next LED whenever timer_tick occurs.
                //
                // LED 0  -> '0'
                // LED 1  -> '1'
                // ...
                // LED 9  -> '9'
                // LED 10 -> 'a'
                // ...
                // LED 15 -> 'f'
                // =================================================

                FLASH_LED: begin
                    // Check if a new UART command has arrived. If new command arrives it will pause the flash and check the condition. 
                    if (!rx_empty) begin
                       state <= READ_RX;
                    end
                    else if (running && !paused && timer_tick) begin


                        // -------------------------------------------------
                        // LEDs 0 through 14
                        // -------------------------------------------------

                        if (led_index < 4'd15) begin

                            // Move to next LED

                            led_index <= led_index + 1'b1;

                            led <= 16'b1 <<
                                   (led_index + 1'b1);


                            // -------------------------------------------------
                            // Convert LED number to ASCII
                            // -------------------------------------------------

                            if (!tx_full) begin

                                wr_uart <= 1'b1;


                                // LED 0-9

                                if ((led_index + 1'b1) < 4'd10) begin

                                    w_data <= 8'h30 +
                                              (led_index + 1'b1);

                                end


                                // LED 10-15 -> a-f

                                else begin

                                    w_data <= 8'h61 +
                                              ((led_index + 1'b1) - 4'd10);

                                end

                            end

                        end
                        else begin
                            running <= 1'b0;
                        end
                    end
                    // -------------------------------------------------
                    // Sequence finished
                    // -------------------------------------------------

                    if (!running)
                        state <= IDLE;

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state   <= IDLE;
                    led     <= 16'b0;
                    running <= 1'b0;

                end

            endcase

        end

    end

endmodule



