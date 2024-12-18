///////////////////////////////////////////////////////
// lfsr_random.v
// 기능: 선형 귀환 시프트 레지스터(LFSR)를 사용하여 난수를 생성
//       생성된 난수를 특정 범위(500~3500ms)로 매핑
///////////////////////////////////////////////////////

module lfsr_random(
    input clk,          // 시스템 클럭
    input reset,        // 전역 리셋 신호 (게임 리셋에 사용)
    output reg [11:0] random_value // 생성된 난수 값 (500 ~ 3500ms)
    );
    // LFSR 초기화 및 구현
    reg [11:0] lfsr_reg = 12'hACE; // 초기 LFSR 값
    wire feedback = lfsr_reg[11] ^ lfsr_reg[3] ^ lfsr_reg[2] ^ lfsr_reg[0]; 
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            // 리셋 시 LFSR을 초기 값으로 설정
            lfsr_reg <= 12'hACE;
        end else begin
            // 피드백과 함께 LFSR 시프트
            lfsr_reg <= {lfsr_reg[10:0], feedback};
        end
    end
    
    always @(*) begin
        // 0~4095 범위의 난수를 500~3500ms 범위로 매핑
        random_value = (lfsr_reg % 3001) + 500; 
    end
endmodule
