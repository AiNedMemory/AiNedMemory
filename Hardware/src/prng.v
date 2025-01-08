// Copyright (c) 2024 Radboud Universiteit
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// SPDX-License-Identifier: MIT

module prng #(
    parameter SEED = 32'hffff_ffff
)(
    input  clk,
    input  resetn,
    input  sample,
    output valid,
    output [31:0] value,
    output [127 : 0] state_rd,
    input  [31 : 0] state_wr,
    input  [1 : 0] state_wr_valid
);

reg [31:0] s0_r, s0_nxt;
reg [31:0] s1_r, s1_nxt;
reg [31:0] s2_r, s2_nxt;
reg [31:0] value_r, value_nxt;
reg valid_r, valid_nxt;

always @(posedge clk) begin
    if (resetn) begin
        s0_r <= s0_nxt;
        s1_r <= s1_nxt;
        s2_r <= s2_nxt;
        value_r <= value_nxt;
        valid_r <= valid_nxt;
    end else begin
        s0_r <= SEED;
        s1_r <= SEED;
        s2_r <= SEED;
        value_r <= 32'b0;
        valid_r <= 1'b0;
    end
end

always @(*) begin
    s0_nxt = s0_r;
    s1_nxt = s1_r;
    s2_nxt = s2_r;
    value_nxt = value_r;
    valid_nxt = valid_r;

    if (|state_wr_valid[1:0]) begin
        case (state_wr_valid)
        2'd1: s0_nxt = state_wr;
        2'd2: s1_nxt = state_wr;
        2'd3: s2_nxt = state_wr;
        default: ;
        endcase
        value_nxt = s0_nxt ^ s1_nxt ^ s2_nxt;
    end
    else
    if (sample | ~valid_r) begin
        s0_nxt = {s0_r[19:1], s0_r[31:19]} ^ {19'b0, s0_r[18:6]};
        s1_nxt = {s1_r[27:3], s1_r[31:25]} ^ {25'b0, s1_r[29:23]};
        s2_nxt = {s2_r[14:4], s2_r[31:11]} ^ {11'b0, s2_r[28:8]};
        value_nxt = s0_nxt ^ s1_nxt ^ s2_nxt;
        valid_nxt = 1'b1;
    end
end

assign value = value_r;
assign valid = valid_r;
assign state_rd = {s2_r, s1_r, s0_r, value_r};

endmodule
