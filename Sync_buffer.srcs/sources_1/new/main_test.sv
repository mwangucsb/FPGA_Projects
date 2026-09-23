`timescale 1ns / 1ps

module main_test (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic        select,
    input  logic        select_buffer,

    input  logic [15:0] sw,
    input  logic        rd,
    input  logic        wr,

    output logic [7:0]  an,
    output logic [7:0]  sseg
);

    //==========================================================
    // FSM States
    //==========================================================

    typedef enum logic [2:0] {
        IDLE         = 3'b000,
        STATE1       = 3'b001,
        STATE2       = 3'b010,
        STATE3       = 3'b011,
        SYNC_BUFFER1 = 3'b100,
        SYNC_BUFFER2 = 3'b101,
        STACK_BUFFER = 3'b110
    } state_t;

    state_t state, next_state;


    //==========================================================
    // Debounce / Edge Detection Signals
    //==========================================================

    logic start_db;
    logic select_db;
    logic buffer_sel_db;

    logic start_final;
    logic select_final;
    logic buffer_sel_final;

    logic buffer_sel;


    //==========================================================
    // Buffer Select
    //==========================================================

    // Active-low switch
    assign buffer_sel = ~select_buffer;


    //==========================================================
    // Debounce START
    //==========================================================

    db_fsm start_instdb (
        .clk(clk),
        .reset(reset),
        .sw(start),
        .db(start_db)
    );


    //==========================================================
    // Debounce SELECT
    //==========================================================

    db_fsm select_instdb (
        .clk(clk),
        .reset(reset),
        .sw(select),
        .db(select_db)
    );


    //==========================================================
    // Debounce BUFFER SELECT
    //==========================================================

    db_fsm buffer_sel_instdb (
        .clk(clk),
        .reset(reset),
        .sw(buffer_sel),
        .db(buffer_sel_db)
    );


    //==========================================================
    // Rising Edge Detector - START
    //==========================================================

    Rising_Edge_Detector start_rise (
        .clk(clk),
        .reset(reset),
        .in(start_db),
        .out(start_final)
    );


    //==========================================================
    // Rising Edge Detector - SELECT
    //==========================================================

    Rising_Edge_Detector select_rise (
        .clk(clk),
        .reset(reset),
        .in(select_db),
        .out(select_final)
    );


    //==========================================================
    // Rising Edge Detector - BUFFER SELECT
    //==========================================================

    Rising_Edge_Detector buffer_sel_rise (
        .clk(clk),
        .reset(reset),
        .in(buffer_sel_db),
        .out(buffer_sel_final)
    );


    //==========================================================
    // State Register
    //==========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end


    //==========================================================
    // Next-State Logic
    //==========================================================

    always_comb begin

        // Default: stay in current state
        next_state = state;

        case (state)

            IDLE: begin
                if (start_final)
                    next_state = STATE1;
            end

            STATE1: begin
                if (buffer_sel_final)
                    next_state = SYNC_BUFFER1;
                else if (select_final)
                    next_state = STATE2;
            end

            STATE2: begin
                if (buffer_sel_final)
                    next_state = SYNC_BUFFER2;
                else if (select_final)
                    next_state = STATE3;
            end

            STATE3: begin
                if (buffer_sel_final)
                    next_state = STACK_BUFFER;
                else if (select_final)
                    next_state = STATE1;
            end

            SYNC_BUFFER1: begin
                next_state = SYNC_BUFFER1;
            end

            SYNC_BUFFER2: begin
                next_state = SYNC_BUFFER2;
            end

            STACK_BUFFER: begin
                next_state = STACK_BUFFER;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end


    //==========================================================
    // Buffer Display Signals
    //==========================================================

    logic [7:0] sync1_an;
    logic [7:0] sync1_sseg;

    logic [7:0] sync2_an;
    logic [7:0] sync2_sseg;

    logic [7:0] stack_an;
    logic [7:0] stack_sseg;


    //==========================================================
    // FSM Display Signals
    //==========================================================

    logic [3:0] hex4;
    logic [3:0] hex3;
    logic [3:0] hex2;
    logic [3:0] hex1;
    logic [3:0] hex0;

    logic [7:0] fsm_an;
    logic [7:0] fsm_sseg;


    //==========================================================
    // Buffer Operation Enables
    //==========================================================

    logic sync1_rd;
    logic sync1_wr;

    logic sync2_rd;
    logic sync2_wr;

    logic stack_rd;
    logic stack_wr;


    assign sync1_rd = rd && (state == SYNC_BUFFER1);
    assign sync1_wr = wr && (state == SYNC_BUFFER1);

    assign sync2_rd = rd && (state == SYNC_BUFFER2);
    assign sync2_wr = wr && (state == SYNC_BUFFER2);

    assign stack_rd = rd && (state == STACK_BUFFER);
    assign stack_wr = wr && (state == STACK_BUFFER);


    //==========================================================
    // SYNC BUFFER 1
    //==========================================================

    sync_buff_w1r1 u_sync_buffer1 (
        .clk(clk),
        .reset(reset),

        .sw(sw),

        .rd(sync1_rd),
        .wr(sync1_wr),

        .an(sync1_an),
        .sseg(sync1_sseg)
    );


    //==========================================================
    // SYNC BUFFER 2
    //==========================================================

    sync_buff_w2r1 u_sync_buffer2 (
        .clk(clk),
        .reset(reset),

        .sw(sw),

        .rd(sync2_rd),
        .wr(sync2_wr),

        .an(sync2_an),
        .sseg(sync2_sseg)
    );


    //==========================================================
    // STACK BUFFER
    //==========================================================

    sync_buff_stack u_stack_buffer (
        .clk(clk),
        .reset(reset),

        .sw(sw),

        .rd(stack_rd),
        .wr(stack_wr),

        .an(stack_an),
        .sseg(stack_sseg)
    );


    //==========================================================
    // FSM Display Logic
    //==========================================================

    always_comb begin

        // Default values
        hex4 = 4'h0;
        hex3 = 4'h0;
        hex2 = 4'h0;
        hex1 = 4'h0;
        hex0 = 4'h0;

        case (state)

            STATE1: begin
                hex4 = 4'hA;
                hex3 = 4'hA;
                hex2 = 4'hA;
                hex1 = 4'hA;
                hex0 = 4'h1;
            end

            STATE2: begin
                hex4 = 4'hA;
                hex3 = 4'hA;
                hex2 = 4'hA;
                hex1 = 4'hA;
                hex0 = 4'h2;
            end

            STATE3: begin
                hex4 = 4'hA;
                hex3 = 4'hA;
                hex2 = 4'hA;
                hex1 = 4'hA;
                hex0 = 4'h3;
            end

            default: begin
                hex4 = 4'h0;
                hex3 = 4'h0;
                hex2 = 4'h0;
                hex1 = 4'h0;
                hex0 = 4'h0;
            end

        endcase

    end


    //==========================================================
    // FSM Seven-Segment Display
    //==========================================================

    disp_hex_mux u_fsm_disp (
        .clk(clk),
        .reset(reset),

        .disp_hi(state == IDLE),

        .hex4(hex4),
        .hex3(hex3),
        .hex2(hex2),
        .hex1(hex1),
        .hex0(hex0),
        .full(full), 
        .empty(empty), 
        .dp_in(4'b1111),

        .an(fsm_an),
        .sseg(fsm_sseg)
    );


    //==========================================================
    // Final Display MUX
    //==========================================================

    always_comb begin

        case (state)

            SYNC_BUFFER1: begin
                an   = sync1_an;
                sseg = sync1_sseg;
            end

            SYNC_BUFFER2: begin
                an   = sync2_an;
                sseg = sync2_sseg;
            end

            STACK_BUFFER: begin
                an   = stack_an;
                sseg = stack_sseg;
            end

            default: begin
                an   = fsm_an;
                sseg = fsm_sseg;
            end

        endcase

    end

endmodule

