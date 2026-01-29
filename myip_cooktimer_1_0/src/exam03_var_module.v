`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 09:38:58 AM
// Design Name: 
// Module Name: exam03_var_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module watch(
    input clk, reset_p,
    input [2:0] btn,
    output reg [7:0] sec, min);
    
    reg set_watch;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)set_watch = 0;
        else if(btn[0])set_watch = ~set_watch;
    end
    
    integer cnt_sysclk;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            sec = 0;
            min = 0;
        end
        else begin
            if(set_watch)begin
                if(btn[1])begin
                    if(sec >= 59)sec = 0;
                    else sec = sec + 1;
                end
                if(btn[2])begin
                    if(min >= 59)min = 0;
                    else min = min + 1;
                end
            end
            else begin
                if(cnt_sysclk >= 27'd99_999_999)begin
                    cnt_sysclk = 0;
                    if(sec >= 59)begin
                        sec = 0;
                        if(min >= 59)min = 0;
                        else min = min + 1;
                    end
                    else sec = sec + 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;
            end
        end
    end
endmodule

module cook_timer(
    input clk, reset_p,
    // 버튼 입력 정의
    input btn_start_pause, // 버튼 1: 시작 / 일시정지
    input btn_add_30s,     // 버튼 2: +30초 증가 (최대 5분)
    input btn_clear,       // 버튼 3: 초기화 / 알람 끄기
    
    output reg [7:0] sec, min,
    output reg alarm
    );

    // --------------------------------------------------------
    // 1. Edge Detector 인스턴스 (버튼 3개에 대해 상승 엣지 검출)
    // --------------------------------------------------------
    wire start_pause_pedge;
    wire add_30s_pedge;
    wire clear_pedge;

    edge_detector_p ed_btn1 (.clk(clk), .reset_p(reset_p), .cp(btn_start_pause), .p_edge(start_pause_pedge));
    edge_detector_p ed_btn2 (.clk(clk), .reset_p(reset_p), .cp(btn_add_30s),     .p_edge(add_30s_pedge));
    edge_detector_p ed_btn3 (.clk(clk), .reset_p(reset_p), .cp(btn_clear),       .p_edge(clear_pedge));

    // --------------------------------------------------------
    // 2. 내부 변수 및 상태 레지스터
    // --------------------------------------------------------
    reg run_enable;     // 타이머 동작 활성화 플래그 (1: 동작 중, 0: 일시정지/정지)
    integer cnt_sysclk; // 1초 카운터

    // --------------------------------------------------------
    // 3. 메인 동작 로직 (시간 설정, 시작/정지, 알람)
    // --------------------------------------------------------
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            sec <= 0;
            min <= 0;
            alarm <= 0;
            run_enable <= 0;
            cnt_sysclk <= 0;
        end else begin
            
            // [우선순위 1] 초기화(Clear) 버튼 (버튼 3)
            if (clear_pedge) begin
                sec <= 0;
                min <= 0;
                alarm <= 0;
                run_enable <= 0;
                cnt_sysclk <= 0;
            end

            // [우선순위 2] +30초 버튼 (버튼 2) - 전자레인지처럼 동작 중에도 추가 가능
            else if (add_30s_pedge) begin
                alarm <= 0; // 시간 추가 시 알람 해제

                // 5분 미만일 때만 시간 추가
                if (min < 5) begin
                    if (sec >= 30) begin
                        // 예: 0:30 -> 1:00, 4:40 -> 5:10(Clamp필요)
                        if (min == 4) begin // 4분대에서 30초 넘게 있으면 5분으로 고정
                            sec <= 0;
                            min <= 5;
                        end else begin
                            sec <= sec - 30; // 30초 빼고
                            min <= min + 1;  // 1분 올림
                        end
                    end else begin
                        // 예: 0:10 -> 0:40
                        sec <= sec + 30;
                    end
                end 
                else begin 
                    // 이미 5분 이상이면 5:00으로 유지
                    min <= 5; 
                    sec <= 0; 
                end
            end

            // [우선순위 3] 시작/일시정지 버튼 (버튼 1)
            else if (start_pause_pedge) begin
                // 시간이 0이 아닐 때만 동작 상태 토글
                if (min != 0 || sec != 0) begin
                    run_enable <= ~run_enable; // Toggle (Start <-> Pause)
                    alarm <= 0;                // 다시 시작하면 알람 끄기
                end
            end

            // [우선순위 4] 타이머 카운트 다운 로직
            else if (run_enable) begin
                if (cnt_sysclk >= 99_999_999) begin // 1초 경과 (100MHz 기준)
                    cnt_sysclk <= 0;

                    // 시간이 0:00이 되었을 때
                    if (min == 0 && sec == 0) begin
                        run_enable <= 0; // 타이머 정지
                        alarm <= 1;      // 알람 울림
                    end
                    else if (sec == 0) begin
                        sec <= 59;
                        min <= min - 1;
                    end
                    else begin
                        sec <= sec - 1;
                    end
                end 
                else begin
                    cnt_sysclk <= cnt_sysclk + 1;
                end
            end
        end
    end

endmodule

module stop_watch(
    input clk, reset_p,
    input btn_start, btn_lap, btn_clear,
    output reg [7:0] fnd_sec, fnd_csec,
    output reg start_stop, lap);
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            start_stop = 0;
        end
        else begin
            if(btn_start)start_stop = ~start_stop;
            else if(btn_clear)start_stop = 0;
        end
    end
    
    reg [7:0] sec, csec, lap_sec, lap_csec;
    integer cnt_sysclk;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            sec = 0;
            csec = 0;
        end
        else begin
            if(start_stop)begin
                if(cnt_sysclk >= 999_999)begin
                    cnt_sysclk = 0;
                    if(csec >= 99)begin
                        csec = 0;
                        if(sec >= 59)begin
                            sec = 0;
                        end
                        else sec = sec + 1;
                    end
                    else csec = csec + 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;
            end
            if(btn_clear)begin
                sec = 0;
                csec = 0;
                cnt_sysclk = 0;
            end
        end
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            lap_sec = 0;
            lap_csec = 0;
            lap = 0;
        end
        else begin
            if(btn_lap)begin
                if(start_stop)lap = ~lap;
                lap_sec = sec;
                lap_csec = csec;
            end
            if(btn_clear)begin
                lap = 0;
                lap_sec = 0;
                lap_csec = 0;
            end
        end
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            fnd_sec = 0;
            fnd_csec = 0;
        end
        else begin
            if(lap)begin
                fnd_sec = lap_sec;
                fnd_csec = lap_csec;
            end
            else begin
                fnd_sec = sec;
                fnd_csec = csec;
            end
        end
    end
    

endmodule





























