`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2025 11:37:30 AM
// Design Name: 
// Module Name: exam01_combinational_logic
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



module half_adder_structural(
    input A, B, 
    output sum, carry);

    xor (sum, A, B);
    and (carry , A, B);

endmodule

module half_adder_behavioral(
    input A, B,
    output reg sum, carry);

    always @(A, B)begin
        case({A, B})
            2'b00: begin
                 sum = 0;
                 carry = 0;
            end
            2'b01: begin
                 sum = 1;
                 carry = 0;
            end
            2'b10: begin
                 sum = 1;
                 carry = 0;
            end
            2'b11: begin
                 sum = 0;
                 carry = 1;
            end
        endcase
    end

endmodule

module half_adder_dataflow(
    input A, B,
    output sum, carry);

    wire [1:0] sum_value;
    
    assign sum_value = A + B;
    assign sum = sum_value[0];
    assign carry = sum_value[1];

endmodule

module full_adder_behavioral(
    input A, B, carry_in,
    output reg sum, carry);

    always @(A, B, carry_in)begin
        case({A, B, carry_in})
            3'b000: begin sum = 0; carry = 0; end
            3'b001: begin sum = 1; carry = 0; end
            3'b010: begin sum = 1; carry = 0; end
            3'b011: begin sum = 0; carry = 1; end
            3'b100: begin sum = 1; carry = 0; end
            3'b101: begin sum = 0; carry = 1; end
            3'b110: begin sum = 0; carry = 1; end
            3'b111: begin sum = 1; carry = 1; end
        endcase
    end

endmodule

module full_adder_structural(
    input A, B, carry_in,
    output wire sum, carry);

    wire sum_0, carry_0, carry_1;
    half_adder_structural ha0(.A(A), .B(B), .sum(sum_0), .carry(carry_0));
    half_adder_structural ha1(.A(sum_0), .B(carry_in), 
                            .sum(sum), .carry(carry_1));
                            
    or (carry, carry_0, carry_1);

endmodule

module full_adder_dataflow(
    input A, B, carry_in,
    output sum, carry);

    wire [1:0] sum_value;
    
    assign sum_value = A + B + carry_in;
    assign sum = sum_value[0];
    assign carry = sum_value[1];

endmodule

module fadder_4bit_structural(
    input wire [3:0] A, B,
    output [3:0] sum,
    output carry);

    wire [2:0] carry_w;
    
    full_adder_structural fa0(.A(A[0]), .B(B[0]), .carry_in(0),
                                .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1(.A(A[1]), .B(B[1]), .carry_in(carry_w[0]),
                                .sum(sum[1]), .carry(carry_w[1]));                            
    full_adder_structural fa2(.A(A[2]), .B(B[2]), .carry_in(carry_w[1]),
                                .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3(.A(A[3]), .B(B[3]), .carry_in(carry_w[2]),
                                .sum(sum[3]), .carry(carry));
endmodule

module fadder_4bit_dataflow(
    input [3:0] A, B, 
    input carry_in,
    output [3:0] sum, 
    output carry);

    wire [4:0] sum_value;
    
    assign sum_value = A + B + carry_in;
    assign sum = sum_value[3:0];
    assign carry = sum_value[4];

endmodule

module comparator(
    input [3:0] A, B,
    output equal, not_equal, less, more);

    assign equal = (A == B);
    assign not_equal = (A != B);
    assign less = (A < B);
    assign more = (A > B);

endmodule

module encoder_4_2(
    input [3:0] signal,
    output reg [1:0] code);

//    assign code = (signal == 4'b0001) ? 2'b00 : 
//                  (signal == 4'b0010) ? 2'b01 : 
//                  (signal == 4'b0100) ? 2'b10 : 2'b11;
//    always @(signal)begin
//        if(signal == 4'b0001) code = 2'b00;
//        else if(signal == 4'b0010) code = 2'b01;
//        else if(signal == 4'b0100) code = 2'b10;
//        else code = 2'b11;
//    end   

    always @(signal)begin
        case(signal)
            4'b0001: begin code = 2'b00; end
            4'b0010: begin code = 2'b01; end
            4'b0100: begin code = 2'b10; end
            default: code = 2'b11;
        endcase           
    end   
endmodule

module decoder_2_4(
    input [1:0] code,
    output [3:0] signal);

    assign signal = (code == 2'b00) ? 4'b0001 : 
                    (code == 2'b01) ? 4'b0010 : 
                    (code == 2'b10) ? 4'b0100 : 4'b1000;

endmodule

module mux_2_1(
    input [1:0] d,
    input s,
    output f);

    assign f = s ? d[1] : d[0];

endmodule

module mux_4_1(
    input [3:0] d,
    input [1:0] s,
    output f);

    assign f = d[s];

endmodule

module mux_8_1(
    input [7:0] d,
    input [2:0] s,
    output f);

    assign f = d[s];

endmodule

module demux_1_4(
    input d,
    input [1:0] s,
    output [3:0] f);

//    assign f[0] = (s == 2'b00) ? d : 0;
//    assign f[1] = (s == 2'b01) ? d : 0;
//    assign f[2] = (s == 2'b10) ? d : 0;
//    assign f[3] = (s == 2'b11) ? d : 0;
    assign f = (s == 2'b00) ? {3'b000, d} : 
               (s == 2'b01) ? {2'b00, d , 1'b0} :
               (s == 2'b10) ? {1'b0, d, 2'b00} : {d, 3'b000};

endmodule

module seg_decoder(
    input [3:0] hex_value,
    output reg [7:0] seg);
    always @(hex_value)begin
        case(hex_value)
            //             pgfe_dcba
            4'd0: seg = 8'b1100_0000;   // 0
            4'd1: seg = 8'b1111_1001;   // 1
            4'd2: seg = 8'b1010_0100;   // 2
            4'd3: seg = 8'b1011_0000;   // 3
            4'd4: seg = 8'b1001_1001;   // 4
            4'd5: seg = 8'b1001_0010;   // 5
            4'd6: seg = 8'b1000_0010;   // 6
            4'd7: seg = 8'b1111_1000;   // 7
            4'd8: seg = 8'b1000_0000;   // 8
            4'd9: seg = 8'b1001_0000;   // 9
            4'd10: seg = 8'b1000_1000;   // A
            4'd11: seg = 8'b1000_0011;   // b
            4'd12: seg = 8'b1100_0110;   // C
            4'd13: seg = 8'b1010_0001;   // d
            4'd14: seg = 8'b1000_0110;   // E
            4'd15: seg = 8'b1000_1110;   // F
        endcase
    end
endmodule

module bin_to_dec(
    input [11:0] bin,
    output reg [15:0] bcd);
    integer i;
    always @(bin)begin
        bcd = 0;
        for(i=0;i<12;i=i+1)begin
            if(bcd[3:0] >= 5) bcd[3:0] = bcd[3:0] + 3;
            if(bcd[7:4] >= 5) bcd[7:4] = bcd[7:4] + 3;
            if(bcd[11:8] >= 5) bcd[11:8] = bcd[11:8] + 3;
            if(bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
            bcd = {bcd[14:0], bin[11-i]};
        end
    end

endmodule

































