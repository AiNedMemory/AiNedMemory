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

module dpsram #(
    parameter ADDR_WIDTH = 10, // 2^10 * 32-bit words (4Kib)
    parameter INIT_FILE = ""
)(
    input clk_a,
    input en_a,
    input [3:0] we_a,
    input [ADDR_WIDTH-1:0] addr_a,
    input [31:0] din_a,
    output reg [31:0] dout_a,

    input clk_b,
    input en_b,
    input [3:0] we_b,
    input [ADDR_WIDTH-1:0] addr_b,
    input [31:0] din_b,
    output reg [31:0] dout_b
);

reg [31:0] memory [(2**ADDR_WIDTH)-1:0];
integer i;

initial begin
    if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, memory, 0, (2**ADDR_WIDTH)-1);
    end
end

always @(posedge clk_a) begin
    if (en_a) begin
        for (i=0; i<4; i=i+1) begin
            if (we_a[i]) begin
                memory[addr_a][i*8 +: 8] <= din_a[i*8 +: 8];
            end
        end
        dout_a <= memory[addr_a];
    end
end

always @(posedge clk_b) begin
    if (en_b) begin
        for (i=0; i<4; i=i+1) begin
            if (we_b[i]) begin
                memory[addr_b][i*8 +: 8] <= din_b[i*8 +: 8];
            end
        end
        dout_b <= memory[addr_b];
    end
end

`ifdef DEBUG

wire [63:0] row00, row01, row02, row03;
wire [63:0] row04, row05, row06, row07;
wire [63:0] row08, row09, row10, row11;
wire [63:0] row12, row13, row14, row15;

genvar g;
generate
for (g=0;g<8;g=g+1) begin
assign row00[g*8 +: 8] = memory[g*2][ 7: 0];
assign row01[g*8 +: 8] = memory[g*2][15: 8];
assign row02[g*8 +: 8] = memory[g*2][23:16];
assign row03[g*8 +: 8] = memory[g*2][31:24];

assign row04[g*8 +: 8] = memory[(g*2)+1][ 7: 0];
assign row05[g*8 +: 8] = memory[(g*2)+1][15: 8];
assign row06[g*8 +: 8] = memory[(g*2)+1][23:16];
assign row07[g*8 +: 8] = memory[(g*2)+1][31:24];

assign row08[g*8 +: 8] = memory[(g+8)*2][ 7: 0];
assign row09[g*8 +: 8] = memory[(g+8)*2][15: 8];
assign row10[g*8 +: 8] = memory[(g+8)*2][23:16];
assign row11[g*8 +: 8] = memory[(g+8)*2][31:24];

assign row12[g*8 +: 8] = memory[((g+8)*2)+1][ 7: 0];
assign row13[g*8 +: 8] = memory[((g+8)*2)+1][15: 8];
assign row14[g*8 +: 8] = memory[((g+8)*2)+1][23:16];
assign row15[g*8 +: 8] = memory[((g+8)*2)+1][31:24];
end
endgenerate

`endif //DEBUG

endmodule
