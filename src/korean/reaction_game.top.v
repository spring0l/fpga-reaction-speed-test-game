///////////////////////////////////////////////////////
// reaction_game_top.v
// 최상위 모듈: 반응 속도 측정 게임 로직 및 주변 모듈 연결
//
// 기능:
// - 시작 버튼(BTNC)으로 게임 시작
// - 랜덤 딜레이 후 LED 점등
// - 반응 버튼(BTNL)로 반응 시간 측정
// - LED가 점등되기 전 버튼을 누르거나 시간이 9999ms를 초과하면 FAIL 표시
// - 초기화 버튼(BTNR)으로 기록 리셋
//
// 출력:
// - 7세그먼트 디스플레이에 현재 기록과 최고 기록 표시
// - LED 출력 상태
///////////////////////////////////////////////////////

module reaction_game_top(
    input CLK100MHZ,   // 100MHz 시스템 클럭
    input BTNC,        // 시작 버튼
    input BTNL,        // 반응 버튼
    input BTNR,        // 초기화 버튼
    output [6:0] SEG,  // 7세그먼트 디스플레이의 세그먼트 출력
    output [7:0] AN,   // 7세그먼트 디스플레이 자릿수 선택
    output DP,         // 7세그먼트 디스플레이 소수점 출력
    output LED15       // LED 출력
    );

    // 버튼 디바운싱
    wire btnc_deb, btnl_deb, btnr_deb;
    debouncer db_start(.clk(CLK100MHZ), .I(BTNC), .O(btnc_deb));
    debouncer db_react(.clk(CLK100MHZ), .I(BTNL), .O(btnl_deb));
    debouncer db_reset(.clk(CLK100MHZ), .I(BTNR), .O(btnr_deb));

    // 1ms 틱 생성 (100MHz 클럭 → 1ms)
    wire tick_1ms;
    clock_divider clkdiv(.clk(CLK100MHZ), .tick_1ms(tick_1ms));

    // 랜덤 딜레이 (500ms ~ 3500ms 범위)
    wire [11:0] random_delay;
    // 게임 시작 시 LFSR 초기화를 방지
    lfsr_random lfsr(
        .clk(CLK100MHZ),
        .reset(btnr_deb),          // 전역 리셋 버튼으로만 초기화
        .random_value(random_delay)
    );

    // 반응 타이머: LED 점등부터 반응 버튼이 눌릴 때까지의 시간(ms)
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

    // 최고 기록 관리
    wire [15:0] best_time;
    reg record_reset = 0;

    // 실패 상태 플래그
    reg fail = 0;

    // 타이머 정지 신호 에지 감지
    reg timer_stop_d;
    always @(posedge CLK100MHZ) timer_stop_d <= timer_stop;

    // 실패 상태가 아닐 때만 기록 업데이트
    wire update_record = (!fail && timer_stop && !timer_stop_d);

    // 최고 기록 추적 모듈
    max_record_tracker mr(
        .clk(CLK100MHZ),
        .rst(record_reset),
        .update(update_record),
        .current_time(reaction_time),
        .best_time(best_time)
    );

    // 상태 머신 구현
    reg [2:0] state;
    localparam S_IDLE=0, S_WAIT_RANDOM=1, S_LED_ON=2, S_WAIT_REACT=3, S_SHOW=4;

    reg [15:0] delay_counter;
    reg LED_reg = 0;
    assign LED15 = LED_reg;

    // 상태 머신 로직
    always @(posedge CLK100MHZ) begin
        if(btnr_deb) begin
            // 초기화 버튼 눌림: 모든 상태 및 기록 초기화
            state <= S_IDLE;
            record_reset <= 1;
            timer_reset <= 1;
            LED_reg <= 0;
            timer_start <= 0;
            timer_stop <= 0;
            fail <= 0;
        end else begin
            // 매 사이클 초기화 신호 해제
            record_reset <= 0;
            timer_reset <= 0;

            case(state)
                S_IDLE: begin
                    // 대기 상태
                    LED_reg <= 0;
                    timer_start <= 0;
                    timer_stop <= 0;
                    fail <= 0;
                    if(btnc_deb) begin
                        // 시작 버튼 눌림 -> 랜덤 딜레이 대기 상태로 전환
                        state <= S_WAIT_RANDOM;
                    end
                end
                S_WAIT_RANDOM: begin
                    // 랜덤 딜레이 값 설정
                    delay_counter <= random_delay; 
                    if(btnl_deb) begin
                        // LED 점등 전에 반응 버튼 눌림 -> FAIL
                        fail <= 1;
                        state <= S_SHOW;
                    end else begin
                        // 카운트 다운 후 LED 점등
                        state <= S_LED_ON;
                    end
                end
                S_LED_ON: begin
                    // 랜덤 딜레이 카운트 다운
                    if(btnl_deb) begin
                        // LED 점등 전에 반응 버튼 눌림 -> FAIL
                        fail <= 1;
                        state <= S_SHOW;
                    end else if(tick_1ms) begin
                        if(delay_counter > 0) begin
                            // 딜레이 카운터 감소
                            delay_counter <= delay_counter - 1;
                        end else begin
                            // 딜레이 완료 -> LED 점등 및 타이머 시작
                            LED_reg <= 1;
                            timer_start <= 1; 
                            state <= S_WAIT_REACT;
                        end
                    end
                end
                S_WAIT_REACT: begin
                    // LED 점등 후 반응 대기
                    timer_start <= 0; // start 신호를 1 사이클 유지
                    if(btnl_deb) begin
                        // 반응 버튼 눌림 -> 타이머 정지 및 결과 표시
                        timer_stop <= 1;  
                        LED_reg <= 0;
                        state <= S_SHOW;
                    end else begin
                        timer_stop <= 0;
                        // 반응 시간이 9999ms를 초과하면 FAIL
                        if(reaction_time >= 16'd10000) begin
                            fail <= 1;
                            LED_reg <= 0;
                            state <= S_SHOW;
                        end
                    end
                end
                S_SHOW: begin
                    // 결과 표시 상태
                    timer_start <= 0;
                    timer_stop <= 0;
                    // 시작 버튼 눌리면 새로운 게임 시작
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

    // 7세그먼트 디스플레이: 현재 기록, 최고 기록, FAIL, 또는 ---- + 소수점 표시
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
