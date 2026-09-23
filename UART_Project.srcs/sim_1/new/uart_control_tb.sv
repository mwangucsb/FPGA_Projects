`timescale 1ns / 1ps

module uart_control_tb;

logic clk;
logic reset;

// UART signals
logic rx;
logic tx;

logic [15:0] led;

// Instantiate DUT
top dut (
    .clk   (clk),
    .reset (reset),
    .rx    (rx),
    .tx    (tx),
    .led   (led)
);


// =========================================================
// 100 MHz Clock
// Period = 10 ns
// =========================================================

always begin
    #5 clk = ~clk;
end


// =========================================================
// UART Timing
// 9600 baud
// 1 bit ≈ 104.167 us
// =========================================================

localparam integer BIT_TIME = 104167;


// =========================================================
// UART Send Byte Task
//
// Format:
// 1 start bit
// 8 data bits, LSB first
// 1 stop bit
// =========================================================

task uart_send_byte(input logic [7:0] data);

    integer i;

    begin

        // UART idle
        rx = 1'b1;

        // Start bit
        rx = 1'b0;
        #BIT_TIME;

        // 8 data bits, LSB first
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #BIT_TIME;
        end

        // Stop bit
        rx = 1'b1;
        #BIT_TIME;

        // Return to idle
        rx = 1'b1;

    end

endtask


// =========================================================
// Testbench
// =========================================================

initial begin

    clk   = 1'b0;
    reset = 1'b1;
    rx    = 1'b1;

    // Hold reset
    #100;

    reset = 1'b0;

    // Allow system to settle
    #1000;


    // =====================================================
    // TEST 1: Start at LED 0
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 1: Start sequence at LED 0");
    $display("====================================");

    uart_send_byte(8'h30);     // ASCII '0'

    #1000;

    $display("LED0 = %b", led[0]);

    if (led[0] == 1'b1)
        $display("PASS: LED 0 is ON");
    else
        $display("FAIL: LED 0 is not ON");


    // =====================================================
    // TEST 2: Start at LED 1
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 2: Start sequence at LED 1");
    $display("====================================");

    uart_send_byte(8'h31);     // ASCII '1'

    #1000;

    $display("LED1 = %b", led[1]);

    if (led[1] == 1'b1)
        $display("PASS: LED 1 is ON");
    else
        $display("FAIL: LED 1 is not ON");


    // =====================================================
    // TEST 3: Start at LED 2
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 3: Start sequence at LED 2");
    $display("====================================");

    uart_send_byte(8'h32);     // ASCII '2'

    #1000;

    $display("LED2 = %b", led[2]);

    if (led[2] == 1'b1)
        $display("PASS: LED 2 is ON");
    else
        $display("FAIL: LED 2 is not ON");


    // =====================================================
    // TEST 4: Start at LED 10 ('a')
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 4: Start sequence at LED 10");
    $display("====================================");

    uart_send_byte(8'h61);     // ASCII 'a'

    #1000;

    $display("LED10 = %b", led[10]);

    if (led[10] == 1'b1)
        $display("PASS: LED 10 is ON");
    else
        $display("FAIL: LED 10 is not ON");


    // =====================================================
    // TEST 5: Start at LED 11 ('b')
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 5: Start sequence at LED 11");
    $display("====================================");

    uart_send_byte(8'h62);     // ASCII 'b'

    #1000;

    $display("LED11 = %b", led[11]);

    if (led == 16'b0000_1000_0000_0000)
        $display("PASS: LED 11 is ON");
    else
        $display("FAIL: LED 11 is not ON");


    // =====================================================
    // TEST 6: Start at LED 12 ('c')
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 6: Start sequence at LED 12");
    $display("====================================");

    uart_send_byte(8'h63);     // ASCII 'c'

    #1000;

    $display("LED12 = %b", led[12]);

    if (led == 16'b0001_0000_0000_0000)
        $display("PASS: LED 12 is ON");
    else
        $display("FAIL: LED 12 is not ON");


    // =====================================================
    // TEST 7: Increase speed to maximum
    //
    // Initial speed = 0
    //
    // + -> speed 1
    // + -> speed 2
    // + -> speed 3
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 7: Increase speed to maximum");
    $display("====================================");

    // Start from speed 0
    if (dut.speed == 2'd0)
        $display("PASS: Initial speed = 0");
    else
        $display("FAIL: Initial speed is %d", dut.speed);


    // First +
    uart_send_byte(8'h2B);     // '+'
    #1000;

    $display("Speed after first + = %d", dut.speed);

    if (dut.speed == 2'd1)
        $display("PASS: Speed increased to 1");
    else
        $display("FAIL: Speed did not increase to 1");


    // Second +
    uart_send_byte(8'h2B);     // '+'
    #1000;

    $display("Speed after second + = %d", dut.speed);

    if (dut.speed == 2'd2)
        $display("PASS: Speed increased to 2");
    else
        $display("FAIL: Speed did not increase to 2");


    // Third +
    uart_send_byte(8'h2B);     // '+'
    #1000;

    $display("Speed after third + = %d", dut.speed);

    if (dut.speed == 2'd3)
        $display("PASS: Speed reached maximum = 3");
    else
        $display("FAIL: Speed did not reach maximum");


    // =====================================================
    // TEST 8: Additional + should NOT exceed maximum
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 8: Test maximum speed limit");
    $display("====================================");

    uart_send_byte(8'h2B);     // '+'
    #1000;

    $display("Speed after extra + = %d", dut.speed);

    if (dut.speed == 2'd3)
        $display("PASS: Speed stayed at maximum");
    else
        $display("FAIL: Speed exceeded maximum");


    // =====================================================
    // TEST 9: Decrease speed to minimum
    //
    // speed 3
    // - -> speed 2
    // - -> speed 1
    // - -> speed 0
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 9: Decrease speed to minimum");
    $display("====================================");


    // First -
    uart_send_byte(8'h2D);     // '-'
    #1000;

    $display("Speed after first - = %d", dut.speed);

    if (dut.speed == 2'd2)
        $display("PASS: Speed decreased to 2");
    else
        $display("FAIL: Speed did not decrease to 2");


    // Second -
    uart_send_byte(8'h2D);     // '-'
    #1000;

    $display("Speed after second - = %d", dut.speed);

    if (dut.speed == 2'd1)
        $display("PASS: Speed decreased to 1");
    else
        $display("FAIL: Speed did not decrease to 1");


    // Third -
    uart_send_byte(8'h2D);     // '-'
    #1000;

    $display("Speed after third - = %d", dut.speed);

    if (dut.speed == 2'd0)
        $display("PASS: Speed reached minimum = 0");
    else
        $display("FAIL: Speed did not reach minimum");


    // =====================================================
    // TEST 10: Additional - should NOT go below minimum
    // =====================================================

    $display("");
    $display("====================================");
    $display("TEST 10: Test minimum speed limit");
    $display("====================================");

    uart_send_byte(8'h2D);     // '-'
    #1000;

    $display("Speed after extra - = %d", dut.speed);

    if (dut.speed == 2'd0)
        $display("PASS: Speed stayed at minimum");
    else
        $display("FAIL: Speed went below minimum");


    // =====================================================
    // Finish
    // =====================================================

    $display("");
    $display("====================================");
    $display("ALL TESTS COMPLETE");
    $display("====================================");

    #100000;

    $finish;

end

endmodule