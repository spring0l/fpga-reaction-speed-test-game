///////////////////////////////////////////////////////
// debouncer.v
// 기능: 입력 버튼 신호(I)에 대해 하드웨어적 디바운싱을 수행
// 방법: 일정한 기간 동안 입력 변화가 없을 경우에만 출력(O)을 입력 상태로 업데이트
///////////////////////////////////////////////////////
module debouncer(
    input clk,     // 시스템 클럭 (100MHz)
    input I,       // 노이즈가 포함된 원본 버튼 신호
    output reg O   // 디바운싱 처리된 출력 신호
    );
    
    reg [19:0] cnt = 0; // 안정화 카운터
    reg Iv = 0;          // 이전 안정화 기준 신호
    
    always @(posedge clk) begin
        if (I == Iv) begin
            // 입력 상태 변화가 없을 경우 카운트 증가
            if (cnt < 20'd999999) begin 
                cnt <= cnt + 1;
            end else begin
                // 충분히 긴 기간(약 10ms 이상) 변화가 없을 경우 O 업데이트
                O <= I;
            end
        end else begin
            // 입력 상태 변화 발생 시 카운터 리셋 및 기준값 갱신
            cnt <= 0;
            Iv <= I;
        end
    end
endmodule
