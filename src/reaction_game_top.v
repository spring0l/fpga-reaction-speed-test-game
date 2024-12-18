///////////////////////////////////////////////////////
// reaction_game_top.v
// Top-level module: Reaction speed measurement game logic and peripheral module connections
//
// Functionality:
// - Start the game using the start button (BTNC)
// - LED turns on after a random delay
// - Measure reaction time using the reaction button (BTNL)
// - Display FAIL if button is pressed before LED turns on or time exceeds 9999ms
// - Reset records using the reset button (BTNR)
//
// Outputs:
// - Display current record and best record on 7-segment display
// - LED output status
///////////////////////////////////////////////////////

module reaction_game_top(
    input CLK100MHZ,   // 100MHz system clock
    input BTNC,        // Start button
    input BTNL,        // Reaction button
    input BTNR,        // Reset button
    output [6:0] SEG,  // 7-segment display segments
    output [7:0] AN,   // 7-segment display anodes (digit select)
    output DP,         // 7-segment display decimal point
    output LED15       // LED output
    );

    // Button debouncing
    wire btnc_deb, btnl_deb, btnr_deb;
    debouncer db_start(.clk(CLK100MHZ), .I(BTNC), .O(btnc_deb));
    debouncer db_react(.clk(CLK100MHZ), .I(BTNL), .O(btnl_deb));
    debouncer db_reset(.clk(CLK100MHZ), .I(BTNR), .O(btnr_deb));

    // 1ms tick generation (100MHz clock -> 1ms)
    wire tick_1ms;
    clock_divider clkdiv(.clk(CLK100MHZ), .tick_1ms(tick_1ms));

    // Random delay (range: 500ms ~ 3500ms)
    wire [11:0] random_delay;
    lfsr_random lfsr(
        .clk(CLK100MHZ),
        .reset(btnr_deb),          // Reset only on global reset button
        .random_value(random_delay)
    );

    // Reaction timer: Time elapsed (ms) between LED on and reaction button press
    wire [15:0] reaction_time;
    reg timer_start = 0;
    reg timer_stop = 0;
    reg timer_reset = 0;
    reaction_timer rt(
        .clk(CLK100MHZ),
        .tick_1ms(tick_1ms),
        .start(timer_start),
        .stop(timer_stop),
        .reset(timer_reset),
        .time_ms(reaction_time)
    );

    // Best record management
    wire [15:0] best_time;
    reg record_reset = 0;

    // Fail state flag
    reg fail = 0;

    // Edge detection for timer stop signal
    reg timer_stop_d;
    always @(posedge CLK100MHZ) timer_stop_d <= timer_stop;

    // Update record only when not in fail state and stop signal is triggered
    wire update_record = (!fail && timer_stop && !timer_stop_d);

    // Best record tracker module
    max_record_tracker mr(
        .clk(CLK100MHZ),
        .rst(record_reset),
        .update(update_record),
        .current_time(reaction_time),
        .best_time(best_time)
    );

    // State machine implementation
    reg [2:0] state;
    localparam S_IDLE=0, S_WAIT_RANDOM=1, S_LED_ON=2, S_WAIT_REACT=3, S_SHOW=4;

    reg [15:0] delay_counter;
    reg LED_reg = 0;
    assign LED15 = LED_reg;

    // State machine logic
    always @(posedge CLK100MHZ) begin
        if(btnr_deb) begin
            // Reset button pressed: reset all states and records
            state <= S_IDLE;
            record_reset <= 1;
            timer_reset <= 1;
            LED_reg <= 0;
            timer_start <= 0;
            timer_stop <= 0;
            fail <= 0;
        end else begin
            // Clear reset signals every cycle
            record_reset <= 0;
            timer_reset <= 0;

            case(state)
                S_IDLE: begin
                    // Idle state
                    LED_reg <= 0;
                    timer_start <= 0;
                    timer_stop <= 0;
                    fail <= 0;
                    if(btnc_deb) begin
                        // Start button pressed -> Transition to wait for random delay
                        state <= S_WAIT_RANDOM;
                    end
                end
                S_WAIT_RANDOM: begin
                    // Sample random delay value
                    delay_counter <= random_delay; 
                    if(btnl_deb) begin
                        // Reaction button pressed before LED -> FAIL
                        fail <= 1;
                        state <= S_SHOW;
                    end else begin
                        // Transition to LED on after countdown
                        state <= S_LED_ON;
                    end
                end
                S_LED_ON: begin
                    // Countdown for random delay
                    if(btnl_deb) begin
                        // Reaction button pressed before LED -> FAIL
                        fail <= 1;
                        state <= S_SHOW;
                    end else if(tick_1ms) begin
                        if(delay_counter > 0) begin
                            // Decrement delay counter
                            delay_counter <= delay_counter - 1;
                        end else begin
                            // Delay complete -> Turn on LED and start timer
                            LED_reg <= 1;
                            timer_start <= 1; 
                            state <= S_WAIT_REACT;
                        end
                    end
                end
                S_WAIT_REACT: begin
                    // Wait for reaction after LED turns on
                    timer_start <= 0; // Hold start signal for one cycle
                    if(btnl_deb) begin
                        // Reaction button pressed -> Stop timer and show result
                        timer_stop <= 1;  
                        LED_reg <= 0;
                        state <= S_SHOW;
                    end else begin
                        timer_stop <= 0;
                        // If reaction time exceeds 9999ms -> FAIL
                        if(reaction_time >= 16'd10000) begin
                            fail <= 1;
                            LED_reg <= 0;
                            state <= S_SHOW;
                        end
                    end
                end
                S_SHOW: begin
                    // Display results
                    timer_start <= 0;
                    timer_stop <= 0;
                    // Start new game if start button is pressed again
                    if(btnc_deb) begin
                        timer_reset <= 1;
                        fail <= 0;
                        state <= S_WAIT_RANDOM;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    // 7-segment display: show current record, best record, FAIL, or ---- + DP control
    seven_seg_display ssd(
        .clk(CLK100MHZ),
        .fail(fail),
        .current_time(reaction_time),
        .best_time(best_time),
        .an(AN),
        .seg(SEG),
        .dp(DP)
    );

endmodule
