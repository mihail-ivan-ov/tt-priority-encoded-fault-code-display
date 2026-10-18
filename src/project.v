/*
 * ASCII code on ONE seven-segment display, shown in decimal by multiplexing.
 * Each button picks the digit by its OWN NUMBER, not by binary value:
 *
 *   ui_in[0] (button 1) pressed -> digit 1 -> shows 49
 *   ui_in[1] (button 2) pressed -> digit 2 -> shows 50
 *   ...
 *   ui_in[7] (button 8) pressed -> digit 8 -> shows 56
 *   no button pressed            -> digit 0 -> shows 48
 *
 * If more than one button is pressed at once, the LOWEST-numbered pressed
 * button wins (a priority encoder) -- "which digit" stops being well
 * defined once more than one button is down, so a choice has to be made.
 *
 *   uo_out[6:0]  the display, segments g f e d c b a, 1 = lit
 *   uio_out[0]   1 while the TENS digit is shown, 0 while the ONES digit is
 *                shown (lets a testbench, or a keen eye, tell them apart)
 *
 *        a
 *       ---
 *    f |   | b
 *       -g-
 *    e |   | c
 *       ---
 *        d
 */

`default_nettype none

module tt_um_mihail_ivan_ov_priority_encoded_fault_code_display #(
    parameter CLK_HZ     = 10_000_000,
    parameter REFRESH_HZ = 0.5          // how many times per second it
                                         // switches between the two digits
)(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Priority encoder: lowest-numbered pressed button wins. digit is 0
    // (nothing pressed) to 8 (button 8 is the only one that can win here,
    // since it's checked last).
    reg [3:0] digit;
    always @(*) begin
             if (ui_in[0]) digit = 4'd1;
        else if (ui_in[1]) digit = 4'd2;
        else if (ui_in[2]) digit = 4'd3;
        else if (ui_in[3]) digit = 4'd4;
        else if (ui_in[4]) digit = 4'd5;
        else if (ui_in[5]) digit = 4'd6;
        else if (ui_in[6]) digit = 4'd7;
        else if (ui_in[7]) digit = 4'd8;
        else                digit = 4'd0;
    end


    reg [3:0] tens;
    reg [3:0] ones;

    always @(*) begin
        case (digit)
            4'd0: {tens, ones} = 8'h48;
            4'd1: {tens, ones} = 8'h49;
            4'd2: {tens, ones} = 8'h50;
            4'd3: {tens, ones} = 8'h51;
            4'd4: {tens, ones} = 8'h52;
            4'd5: {tens, ones} = 8'h53;
            4'd6: {tens, ones} = 8'h54;
            4'd7: {tens, ones} = 8'h55;
            4'd8: {tens, ones} = 8'h56;
            default: {tens, ones} = 8'h00;   // unreachable, digit is 0..8
        endcase
    end

    // Decimal digit (0 to 9) -> segments, in the order g f e d c b a.
    function [6:0] seg7;
        input [3:0] n;
        begin
            case (n)
                //            gfedcba
                4'd0: seg7 = 7'b0111111;
                4'd1: seg7 = 7'b0000110;
                4'd2: seg7 = 7'b1011011;
                4'd3: seg7 = 7'b1001111;
                4'd4: seg7 = 7'b1100110;
                4'd5: seg7 = 7'b1101101;
                4'd6: seg7 = 7'b1111101;
                4'd7: seg7 = 7'b0000111;
                4'd8: seg7 = 7'b1111111;
                4'd9: seg7 = 7'b1101111;
                default: seg7 = 7'b0000000;
            endcase
        end
    endfunction

    // Switch between tens and ones at REFRESH_HZ.
    localparam [31:0] DIV = CLK_HZ / (2 * REFRESH_HZ);   // half-period count

    reg [31:0] cnt;
    reg        show_tens;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt       <= 32'd0;
            show_tens <= 1'b1;
        end else if (cnt >= DIV - 32'd1) begin
            cnt       <= 32'd0;
            show_tens <= ~show_tens;
        end else begin
            cnt <= cnt + 32'd1;
        end
    end

    assign uo_out  = {1'b0, seg7(show_tens ? tens : ones)};
    assign uio_out = {7'b0, show_tens};
    assign uio_oe  = 8'h01;            // bit 0 is an output, rest inputs

    wire _unused_ok = &{ena, uio_in};

endmodule
