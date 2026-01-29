`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2025 09:15:43 AM
// Design Name: 
// Module Name: test_top
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


module test_top(
    input [15:0] slide,
    output [15:0] led);
    
    assign led = slide;
    
endmodule

module FND_top(
    input clk, reset_p,
    input [15:0] hex_value,
    output [7:0] seg,
    output [3:0] com);

    FND_cntr fnd(.clk(clk), .reset_p(reset_p),
                .fnd_value(hex_value), .seg(seg), .com(com));

endmodule

module watch_top(
    input clk, reset_p,
    input [3:0] button,
    output [7:0] seg,
    output [3:0] com);
    
    
    wire [2:0] btn_pedge, btn_nedge;
    button_cntr btncntr0(.clk(clk), .reset_p(reset_p), 
        .btn(button[0]), .btn_pedge(btn_pedge[0]), .btn_nedge(btn_nedge[0]));
    button_cntr btncntr1(.clk(clk), .reset_p(reset_p), 
        .btn(button[1]), .btn_pedge(btn_pedge[1]), .btn_nedge(btn_nedge[1]));
    button_cntr btncntr2(.clk(clk), .reset_p(reset_p), 
        .btn(button[2]), .btn_pedge(btn_pedge[2]), .btn_nedge(btn_nedge[2]));
    
    wire [7:0] sec, min;
    watch watch0(.clk(clk), .reset_p(reset_p), 
                 .btn(btn_pedge), .sec(sec), .min(min));
    
    wire [7:0] sec_bcd, min_bcd;
    bin_to_dec btd_sec(.bin(sec), .bcd(sec_bcd));
    bin_to_dec btd_min(.bin(min), .bcd(min_bcd));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p),
                .fnd_value({min_bcd, sec_bcd}), .seg(seg), .com(com));
    
endmodule

module cook_timer_top(
    input clk, reset_p,
    input [3:0] button,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led);
    
    wire [3:0] btn_pedge, btn_nedge;
    button_cntr btncntr0(.clk(clk), .reset_p(reset_p), 
        .btn(button[0]), .btn_pedge(btn_pedge[0]), .btn_nedge(btn_nedge[0]));
    button_cntr btncntr1(.clk(clk), .reset_p(reset_p), 
        .btn(button[1]), .btn_pedge(btn_pedge[1]), .btn_nedge(btn_nedge[1]));
    button_cntr btncntr2(.clk(clk), .reset_p(reset_p), 
        .btn(button[2]), .btn_pedge(btn_pedge[2]), .btn_nedge(btn_nedge[2]));
    button_cntr btncntr3(.clk(clk), .reset_p(reset_p), 
        .btn(button[3]), .btn_pedge(btn_pedge[3]), .btn_nedge(btn_nedge[3]));

    wire [7:0] sec, min;
    wire alarm;
    cook_timer ctimer(.clk(clk), .reset_p(reset_p),
                      .btn_start(btn_pedge[0]), .inc_sec(btn_pedge[1]), 
                      .inc_min(btn_pedge[2]), .alarm_off(btn_pedge[3]),
                      .sec(sec), .min(min), .alarm(alarm));
                      
    wire [7:0] sec_bcd, min_bcd;
    bin_to_dec btd_sec(.bin(sec), .bcd(sec_bcd));
    bin_to_dec btd_min(.bin(min), .bcd(min_bcd));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p),
                .fnd_value({min_bcd, sec_bcd}), .seg(seg), .com(com));
                
    assign led[0] = alarm;

endmodule

module stop_watch_top(
    input clk, reset_p,
    input [2:0] button,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led);

    wire [2:0] btn_pedge, btn_nedge;
    button_cntr btncntr0(.clk(clk), .reset_p(reset_p), 
        .btn(button[0]), .btn_pedge(btn_pedge[0]), .btn_nedge(btn_nedge[0]));
    button_cntr btncntr1(.clk(clk), .reset_p(reset_p), 
        .btn(button[1]), .btn_pedge(btn_pedge[1]), .btn_nedge(btn_nedge[1]));
    button_cntr btncntr2(.clk(clk), .reset_p(reset_p), 
        .btn(button[2]), .btn_pedge(btn_pedge[2]), .btn_nedge(btn_nedge[2]));
    wire [7:0] fnd_sec, fnd_csec;    
    wire start_stop, lap;
    assign led[0] = start_stop;
    assign led[5] = lap;
    stop_watch sw0(.clk(clk), .reset_p(reset_p),
                   .btn_start(btn_pedge[0]), .btn_lap(btn_pedge[1]), 
                   .btn_clear(btn_pedge[2]),
                   .fnd_sec(fnd_sec), .fnd_csec(fnd_csec),
                   .start_stop(start_stop), .lap(lap));
                   
    wire [7:0] sec_bcd, csec_bcd;
    bin_to_dec btd_sec(.bin(fnd_sec), .bcd(sec_bcd));
    bin_to_dec btd_min(.bin(fnd_csec), .bcd(csec_bcd));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p),
                .fnd_value({sec_bcd, csec_bcd}), .seg(seg), .com(com));

endmodule

module multifunction_watch_top(
    input clk, reset_p,
    input [3:0] button,
    input [15:0] slide,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led,
    output buz);
    
    localparam WATCH = 3'b001;
    localparam COOK_TIMER = 3'b010;
    localparam STOPWATCH = 3'b100;
    
    wire [3:0] btn_pedge, btn_nedge;
    button_cntr btncntr0(.clk(clk), .reset_p(reset_p), 
        .btn(button[0]), .btn_pedge(btn_pedge[0]), .btn_nedge(btn_nedge[0]));
    button_cntr btncntr1(.clk(clk), .reset_p(reset_p), 
        .btn(button[1]), .btn_pedge(btn_pedge[1]), .btn_nedge(btn_nedge[1]));
    button_cntr btncntr2(.clk(clk), .reset_p(reset_p), 
        .btn(button[2]), .btn_pedge(btn_pedge[2]), .btn_nedge(btn_nedge[2]));
    button_cntr btncntr3(.clk(clk), .reset_p(reset_p), 
        .btn(button[3]), .btn_pedge(btn_pedge[3]), .btn_nedge(btn_nedge[3]));
        
    reg [2:0] mode, next_mode;
    assign led[7:5] = mode;
    always @(*)begin
        if(reset_p)next_mode = WATCH;
        else if(btn_pedge[3])begin
            if(mode == WATCH)next_mode = COOK_TIMER;
            else if(mode == COOK_TIMER && next_mode == COOK_TIMER)next_mode = STOPWATCH;
            else if(mode == STOPWATCH)next_mode = WATCH;
        end
        else if(mode == COOK_TIMER && (btn_pedge[0] || btn_pedge[1] || btn_pedge[1]))next_mode = WATCH;
        else next_mode = WATCH;
    end
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)mode = WATCH;
        else if(btn_pedge[3])begin
            mode = next_mode;
        end
    end
    reg [2:0] watch_btn, cook_btn, stopwatch_btn;
    always @(*)begin
        case(mode)
            WATCH: begin
                watch_btn = btn_pedge[2:0];
                cook_btn = 0;
                stopwatch_btn = 0;
            end
            COOK_TIMER: begin
                watch_btn = 0;
                cook_btn = btn_pedge[2:0];
                stopwatch_btn = 0;
            end
            STOPWATCH: begin
                watch_btn = 0;
                cook_btn = 0;
                stopwatch_btn = btn_pedge[2:0];
            end
        endcase
    end
        
    wire [7:0] watch_sec, watch_min;
    watch watch0(.clk(clk), .reset_p(reset_p), 
                 .btn(watch_btn), .sec(watch_sec), .min(watch_min));
                 
    wire [7:0] cook_sec, cook_min;
    wire alarm;
    cook_timer ctimer(.clk(clk), .reset_p(reset_p),
                      .btn_start(cook_btn[0]), .inc_sec(cook_btn[1]), 
                      .inc_min(cook_btn[2]), .alarm_off(slide[0]),
                      .sec(cook_sec), .min(cook_min), .alarm(alarm));
                      
    wire [7:0] stopwatch_sec, stopwatch_csec;    
    wire start_stop, lap;
    assign led[0] = start_stop;
    assign led[1] = lap;
    stop_watch sw0(.clk(clk), .reset_p(reset_p),
                   .btn_start(stopwatch_btn[0]), .btn_lap(stopwatch_btn[1]), 
                   .btn_clear(stopwatch_btn[2]),
                   .fnd_sec(stopwatch_sec), .fnd_csec(stopwatch_csec),
                   .start_stop(start_stop), .lap(lap)); 
                   
    wire [7:0] bcd_low, bcd_high, bin_low, bin_high;
    
    assign bin_low = mode == COOK_TIMER ? cook_sec :
                     mode == STOPWATCH ? stopwatch_csec : watch_sec;
                     
    assign bin_high = mode == COOK_TIMER ? cook_min :
                      mode == STOPWATCH ? stopwatch_sec : watch_min;                 
    
    bin_to_dec btd_sec(.bin(bin_low), .bcd(bcd_low));
    bin_to_dec btd_min(.bin(bin_high), .bcd(bcd_high));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p),
                .fnd_value({bcd_high, bcd_low}), .seg(seg), .com(com)); 
                
    assign buz = alarm;
    assign led[15] = alarm;            
 
endmodule

module play_buzz_top(
    input clk, reset_p,
    output trans_cp);

    freq_generator #(.FREQ(15_000)) fg (
        .clk(clk), .reset_p(reset_p), .trans_cp(trans_cp));

endmodule

module led_pwm_top(
    input clk, reset_p,
    output led_r, led_g, led_b,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] com);

    integer cnt;
    always @(posedge clk)cnt = cnt + 1;
    
    reg [7:0] cnt_200;
    reg flag;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_200 = 0;
            flag = 0;
        end
        else if(cnt[23] && flag == 0)begin
            flag = 1;
            if(cnt_200 >= 199)cnt_200 = 0;
            else cnt_200 = cnt_200 + 1;
        end
        else if(cnt[23] == 0)flag = 0;
        
    end
    
    pwm_Nfreq_Nstep led_pwm(.clk(clk), .reset_p(reset_p), .duty(cnt_200), .pwm(led[0]));
    
    pwm_Nfreq_Nstep red_pwm(.clk(clk), .reset_p(reset_p), .duty(cnt[27:20]), .pwm(led_r));
    pwm_Nfreq_Nstep green_pwm(.clk(clk), .reset_p(reset_p), .duty(cnt[28:21]), .pwm(led_g));
    pwm_Nfreq_Nstep blue_pwm(.clk(clk), .reset_p(reset_p), .duty(cnt[29:22]), .pwm(led_b));
    
    wire [15:0] bcd_duty;
    bin_to_dec btd_duty(.bin(cnt_200), .bcd(bcd_duty));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p),
                .fnd_value(bcd_duty), .seg(seg), .com(com)); 

endmodule

module sg_90_top(
    input clk, reset_p,
    input [3:0] button, 
    output sg90_pwm,
    output [7:0] seg,
    output [3:0] com);
    
    wire [3:0] btn_pedge, btn_nedge;
    button_cntr btncntr0(.clk(clk), .reset_p(reset_p), 
        .btn(button[0]), .btn_pedge(btn_pedge[0]), .btn_nedge(btn_nedge[0]));
    button_cntr btncntr1(.clk(clk), .reset_p(reset_p), 
        .btn(button[1]), .btn_pedge(btn_pedge[1]), .btn_nedge(btn_nedge[1]));
    button_cntr btncntr2(.clk(clk), .reset_p(reset_p), 
        .btn(button[2]), .btn_pedge(btn_pedge[2]), .btn_nedge(btn_nedge[2]));
    button_cntr btncntr3(.clk(clk), .reset_p(reset_p), 
        .btn(button[3]), .btn_pedge(btn_pedge[3]), .btn_nedge(btn_nedge[3]));
    
    reg [7:0] duty;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)duty = 12;
        else begin
            if(btn_pedge[1] && duty > 3)duty = duty - 1;
            if(btn_pedge[2] && duty < 21)duty = duty + 1;
        end
    end
    
    pwm_Nfreq_Nstep #(.PWM_FREQ(50), .DUTY_STEP(180)) sg_pwm(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(sg90_pwm));

    wire [15:0] bcd_duty;
    bin_to_dec btd_duty(.bin(duty-3), .bcd(bcd_duty));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p), 
            .fnd_value({4'd0, bcd_duty[7:0], 4'd0}), .seg(seg), .com(com)); 
endmodule

module adc_ch6_top(
    input clk, reset_p,
    input vauxp6, vauxn6,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led);
    
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    xadc_wiz_0 adc_ch6(
          .daddr_in({2'b00, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out));
     
     wire eoc_out_pedge;
     edge_detector_n ed(.clk(clk), .reset_p(reset_p),
                        .cp(eoc_out), .p_edge(eoc_out_pedge));     
     reg [11:0] adc_value;
     always @(posedge clk, posedge reset_p)begin
        if(reset_p)adc_value = 0;
        else if(eoc_out_pedge)adc_value = do_out[15:4];
     end
     
    wire [15:0] bcd_adc_value;
    bin_to_dec btd(.bin(adc_value), .bcd(bcd_adc_value));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p), 
            .fnd_value(bcd_adc_value), .seg(seg), .com(com)); 
            
    assign led[0] = adc_value[11:8] >= 1;
    assign led[1] = adc_value[11:8] >= 2;
    assign led[2] = adc_value[11:8] >= 3;
    assign led[3] = adc_value[11:8] >= 4;
    assign led[4] = adc_value[11:8] >= 5;
    assign led[5] = adc_value[11:8] >= 6;
    assign led[6] = adc_value[11:8] >= 7;
    assign led[7] = adc_value[11:8] >= 8;
    assign led[8] = adc_value[11:8] >= 9;
    assign led[9] = adc_value[11:8] >= 10;
    assign led[10] = adc_value[11:8] >= 11;
    assign led[11] = adc_value[11:8] >= 12;
    assign led[12] = adc_value[11:8] >= 13;
    assign led[13] = adc_value[11:8] >= 14;
    assign led[14] = adc_value[11:8] >= 15;

endmodule

module adc_sequence_top(
    input clk, reset_p,
    input vauxp6, vauxn6, vauxp15, vauxn15,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led);
    
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    adc_2ch_sequence joystick(
          .daddr_in({2'b00, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .vauxp15(vauxp15),             // Auxiliary channel 15
          .vauxn15(vauxn15),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out));
          
    reg [11:0] adc_value_x, adc_value_y;
    wire eoc_out_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p),
                        .cp(eoc_out), .p_edge(eoc_out_pedge));
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            adc_value_x = 0;
            adc_value_y = 0;
        end
        else if(eoc_out_pedge)begin
            case(channel_out[3:0])
                6: adc_value_x = do_out[15:4];
                15:adc_value_y = do_out[15:4];
            endcase
        end
    end
    
    wire [7:0] x_bcd, y_bcd;
    bin_to_dec btd_x(.bin(adc_value_x[11:6]), .bcd(x_bcd));
    bin_to_dec btd_y(.bin(adc_value_y[11:6]), .bcd(y_bcd));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p), 
            .fnd_value({x_bcd, y_bcd}), .seg(seg), .com(com));
            
            
    assign led[0] = adc_value_x[11:9] >= 8;
    assign led[1] = adc_value_x[11:9] >= 7;
    assign led[2] = adc_value_x[11:9] >= 6;
    assign led[3] = adc_value_x[11:9] >= 5;
    assign led[4] = adc_value_x[11:9] >= 4;
    assign led[5] = adc_value_x[11:9] >= 3;
    assign led[6] = adc_value_x[11:9] >= 2;
    assign led[7] = adc_value_x[11:9] >= 1;
    assign led[8] = adc_value_y[11:9] >= 1;
    assign led[9] = adc_value_y[11:9] >= 2;
    assign led[10] = adc_value_y[11:9] >= 3;
    assign led[11] = adc_value_y[11:9] >= 4;
    assign led[12] = adc_value_y[11:9] >= 5;
    assign led[13] = adc_value_y[11:9] >= 6;
    assign led[14] = adc_value_y[11:9] >= 7;        
    assign led[15] = adc_value_y[11:9] >= 8;        
            
endmodule

module ultra_sonic_top(
    input clk, reset_p,
    input echo,
    output trig,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led);

    wire [8:0] distance_cm;
    hc_sr04_cntr ultra(
        .clk(clk), .reset_p(reset_p),
        .echo(echo), .trig(trig),
        .distance_cm(distance_cm));
    wire [15:0] distance_bcd;
    bin_to_dec btd_x(.bin(distance_cm), .bcd(distance_bcd));
    
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p), 
            .fnd_value(distance_bcd), .seg(seg), .com(com));

endmodule

module dht11_top(
    input clk, reset_p,
    inout dht11_data,
    output [7:0] seg,
    output [3:0] com,
    output [15:0] led);
    
    wire [7:0] humidity, temperature;
    dht11_cntr dht(clk, reset_p, dht11_data, humidity, temperature, led);
    
    wire [7:0] humidity_bcd, temperature_bcd;
    bin_to_dec btd_humi(.bin(humidity), .bcd(humidity_bcd));
    bin_to_dec btd_tmpr(.bin(temperature), .bcd(temperature_bcd));
    
    FND_cntr fnd(.clk(clk), .reset_p(reset_p), 
            .fnd_value({humidity_bcd, temperature_bcd}), .seg(seg), .com(com));

endmodule

module i2c_master_top(
    input clk, reset_p,
    input slide,
    input comm_start,
    output scl, sda,
    output [15:0] led
);
    localparam light_on  = 8'b0000_1000;
    localparam light_off = 8'b0000_0000;
    
    wire [7:0] data;
    wire busy;
    assign data = slide ? light_on : light_off;
    I2C_master i2c(clk, reset_p, 7'h27, data, 1'b0, comm_start, scl, sda, busy, led);

endmodule

//module i2c_txtlcd_top(
//    input clk, reset_p,
//    input [3:0] button,
//    output scl, sda,
//    output [15:0] led);

//    wire [3:0] btn_pedge;
//    button_cntr btncntr0(clk, reset_p, button[0], btn_pedge[0]);
//    button_cntr btncntr1(clk, reset_p, button[1], btn_pedge[1]);
//    button_cntr btncntr2(clk, reset_p, button[2], btn_pedge[2]);
//    button_cntr btncntr3(clk, reset_p, button[3], btn_pedge[3]);
    
//    integer cnt_sysclk;
//    reg count_clk_e;
//    always @(negedge clk, posedge reset_p)begin
//        if(reset_p)cnt_sysclk = 0;
//        else if(count_clk_e)cnt_sysclk = cnt_sysclk + 1;
//        else cnt_sysclk = 0;
//    end
    
//    reg [7:0] send_buffer;
//    reg send, rs;
//    wire busy;
//    i2c_lcd_send_byte send_byte(
//        clk, reset_p, 7'h27, send_buffer,
//        send, rs, scl, sda, busy, led);
    
//    localparam IDLE                 = 6'b00_0001;
//    localparam INIT                 = 6'b00_0010;
//    localparam SEND_CHARACTER       = 6'b00_0100;
//    localparam SHIFT_RIGHT_DISPLAY  = 6'b00_1000;
//    localparam SHIFT_LEFT_DISPLAY   = 6'b01_0000;
    
//    reg [5:0] state, next_state;
//    always @(negedge clk, posedge reset_p)begin
//        if(reset_p)state = IDLE;
//        else state = next_state;
//    end
    
//    reg init_flag;
//    reg [10:0] cnt_data;
//    always @(posedge clk, posedge reset_p)begin
//        if(reset_p)begin
//            next_state = IDLE;
//            init_flag = 0;
//            cnt_data  = 0;
//            count_clk_e = 0;
//            send = 0;
//            send_buffer = 0;
//            rs = 0;
//        end
//        else begin
//            case(state)
//                IDLE               :begin
//                    if(init_flag)begin
//                        if(btn_pedge[0])next_state = SEND_CHARACTER;
//                        if(btn_pedge[1])next_state = SHIFT_LEFT_DISPLAY;
//                        if(btn_pedge[2])next_state = SHIFT_RIGHT_DISPLAY;
//                    end
//                    else begin
//                        if(cnt_sysclk <= 80_000_00)begin
//                            count_clk_e = 1;
//                        end
//                        else begin
//                            count_clk_e = 0;
//                            next_state = INIT;
//                        end
//                    end
//                end
//                INIT               :begin
//                    if(busy)begin
//                        send = 0;
//                        if(cnt_data >= 6)begin
//                            cnt_data = 0;
//                            next_state = IDLE;
//                            init_flag = 1;
//                        end
//                    end
//                    else if(!send)begin
//                        case(cnt_data)
//                            0: send_buffer = 8'h33;
//                            1: send_buffer = 8'h32;
//                            2: send_buffer = 8'h28;
//                            3: send_buffer = 8'h0f;
//                            4: send_buffer = 8'h01;
//                            5: send_buffer = 8'h06;
//                        endcase
//                        send = 1;
//                        cnt_data = cnt_data + 1;
//                    end
//                end
//                SEND_CHARACTER     :begin
//                    if(busy)begin
//                        send = 0;
//                        next_state = IDLE;
//                    end
//                    else if(!send)begin
//                        rs =1;
//                        send_buffer = "A";
//                        send = 1;
//                    end
//                end
//                SHIFT_RIGHT_DISPLAY:begin
//                    if(busy)begin
//                        send = 0;
//                        next_state = IDLE;
//                    end
//                    else if(!send)begin
//                        rs = 0;
//                        send_buffer = 8'h1c;
//                        send = 1;
//                    end
//                end
//                SHIFT_LEFT_DISPLAY :begin
//                    if(busy)begin
//                        send = 0;
//                        next_state = IDLE;
//                    end
//                    else if(!send)begin
//                        rs = 0;
//                        send_buffer = 8'h18;
//                        send = 1;
//                    end
//                end
            
//            endcase
//        end
//    end
    
    

//endmodule

module i2c_txtlcd_top(
    input clk, reset_p,
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output busy,
    output [15:0]led);

    wire send_pedge;
    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
        
    integer cnt_sysclk;
    reg count_clk_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)cnt_sysclk = 0;
        else if(count_clk_e)cnt_sysclk = cnt_sysclk + 1;
        else cnt_sysclk = 0;
    end
    
    reg [7:0] send_buffer_byte;
    i2c_lcd_send_byte send_byte_a(clk, reset_p, 7'h27, send_buffer_byte,     
                                send_byte, rs_byte, scl, sda, busy, led);
      
    localparam IDLE           = 6'b00_0001;
    localparam INIT           = 6'b00_0010;
    localparam SEND_BYTE      = 6'b00_0100;
    
    reg [5:0] state, next_state;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg init_flag;
    reg [10:0] cnt_data;
    reg send_byte, rs_byte;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            init_flag = 0;
            cnt_data = 0;
            count_clk_e = 0;
            send_byte = 0;
            send_buffer_byte = 0;
            rs_byte = 0;
        end
        else begin
            case(state)
                IDLE               :begin
                    if(init_flag)begin
                        if(send_pedge)next_state = SEND_BYTE;
                    end
                    else begin
                        if(cnt_sysclk <= 80_000_00)begin
                            count_clk_e = 1;    
                        end
                        else begin
                            count_clk_e = 0;
                            next_state = INIT;
                        end                     
                    end
                end
                INIT               :begin
                    if(busy)begin
                        send_byte = 0;
                        if(cnt_data >= 6)begin
                            cnt_data = 0;
                            next_state = IDLE;
                            init_flag = 1;
                        end
                    end
                    else if(!send_byte)begin
                        case(cnt_data)
                            0: send_buffer_byte = 8'h33;
                            1: send_buffer_byte = 8'h32;
                            2: send_buffer_byte = 8'h28;
                            3: send_buffer_byte = 8'h0F; // 화면켜짐, 커서있음, 커서깜빡임
                            4: send_buffer_byte = 8'h01; // clear display
                            5: send_buffer_byte = 8'h06; // 커서 오른쪽으로 shift
                        endcase
                        send_byte = 1;
                        cnt_data = cnt_data + 1;
                    end
                end
                SEND_BYTE     :begin
                    if(busy)begin
                        send_byte = 0;
                        next_state = IDLE;
                    end
                    else if(!send_byte) begin
                        rs_byte = rs; // 0이면 명령어, 1이면 데이터 
                        send_buffer_byte = send_buffer;
                        send_byte = 1;
                    end                
                end
            endcase
        end
    end   
endmodule









