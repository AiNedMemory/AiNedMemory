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

module pwrite_ctrl #(
    parameter ADDR_WIDTH = 10
)(
    input  clk,
    input  resetn,

    input  [63  : 0] strobe,
    input  [191 : 0] coeffs_lo,
    input  [191 : 0] coeffs_hi,
    input  write_bypass,

    output ready,

    input  en_in,
    input  [3:0] we_in,
    input  [ADDR_WIDTH-1:0] addr_in,
    input  [31:0] din_in,
    output [31:0] dout_in,

    output en_a,
    output [3:0] we_a,
    output [ADDR_WIDTH-1:0] addr_a,
    output [31:0] din_a,
    input  [31:0] dout_a,

    output en_b,
    output [3:0] we_b,
    output [ADDR_WIDTH-1:0] addr_b,
    output [31:0] din_b,
    input  [31:0] dout_b,

    output [256*4*32-1:0] state_rd,
    input  [31:0] state_wr,
    input  [9:0] state_wr_valid
);

localparam  IDLE = 2'd0;
localparam  READ = 2'd1;
localparam  PROC = 2'd2;
localparam WRITE = 2'd3;

reg [1:0] state_r, state_nxt;

reg [ADDR_WIDTH-1:0] word_addr_r, word_addr_nxt;

reg [63:0] write_data_r, write_data_nxt;
reg [ 7:0] write_bytes_r, write_bytes_nxt;

reg [63:0] area_r [8:0];
reg [63:0] area_nxt [8:0];

reg [3:0] mem_r, mem_nxt, mem_r2;
reg [8:0] mem_en_r, mem_en_nxt;
genvar g;

wire [255:0] area_in, area_out;
////assign area_in[  0 +: 16] = {area_r[2][32 +: 4], area_r[1][32 +: 8], area_r[0][32+4 +: 4]};
////assign area_in[ 16 +: 16] = {area_r[2][40 +: 4], area_r[1][40 +: 8], area_r[0][40+4 +: 4]};
////assign area_in[ 32 +: 16] = {area_r[2][48 +: 4], area_r[1][48 +: 8], area_r[0][48+4 +: 4]};
////assign area_in[ 48 +: 16] = {area_r[2][56 +: 4], area_r[1][56 +: 8], area_r[0][56+4 +: 4]};
  //assign area_in[ 64 +: 16] = {area_r[5][ 0 +: 4], area_r[4][ 0 +: 8], area_r[3][ 0+4 +: 4]};
  //assign area_in[ 80 +: 16] = {area_r[5][ 8 +: 4], area_r[4][ 8 +: 8], area_r[3][ 8+4 +: 4]};
  //assign area_in[ 96 +: 16] = {area_r[5][16 +: 4], area_r[4][16 +: 8], area_r[3][16+4 +: 4]};
  //assign area_in[112 +: 16] = {area_r[5][24 +: 4], area_r[4][24 +: 8], area_r[3][24+4 +: 4]};
  //assign area_in[128 +: 16] = {area_r[5][32 +: 4], area_r[4][32 +: 8], area_r[3][32+4 +: 4]};
  //assign area_in[144 +: 16] = {area_r[5][40 +: 4], area_r[4][40 +: 8], area_r[3][40+4 +: 4]};
  //assign area_in[160 +: 16] = {area_r[5][48 +: 4], area_r[4][48 +: 8], area_r[3][48+4 +: 4]};
  //assign area_in[176 +: 16] = {area_r[5][56 +: 4], area_r[4][56 +: 8], area_r[3][56+4 +: 4]};
////assign area_in[192 +: 16] = {area_r[8][ 0 +: 4], area_r[7][ 0 +: 8], area_r[6][ 0+4 +: 4]};
////assign area_in[208 +: 16] = {area_r[8][ 8 +: 4], area_r[7][ 8 +: 8], area_r[6][ 8+4 +: 4]};
////assign area_in[224 +: 16] = {area_r[8][16 +: 4], area_r[7][16 +: 8], area_r[6][16+4 +: 4]};
////assign area_in[240 +: 16] = {area_r[8][24 +: 4], area_r[7][24 +: 8], area_r[6][24+4 +: 4]};
generate
for (g=0; g<8;g=g+1) begin
assign area_in[(g*16)+64 +: 16] = {area_r[5][g*8 +: 4], area_r[4][g*8 +: 8], area_r[3][(g*8)+4 +: 4]};
if (g<4) begin : top_bottom
assign area_in[g*16 +: 16] = {area_r[2][(g*8)+32 +: 4], area_r[1][(g*8)+32 +: 8], area_r[0][(g*8)+36 +: 4]};
assign area_in[(g*16)+192 +: 16] = {area_r[8][g*8 +: 4], area_r[7][g*8 +: 8], area_r[6][(g*8)+4 +: 4]};
end
end
endgenerate

wire [63:0] area_write [8:0];
assign area_write[0][31: 0] = area_r[0][31: 0];
assign area_write[1][31: 0] = area_r[1][31: 0];
assign area_write[2][31: 0] = area_r[2][31: 0];
assign area_write[6][63:32] = area_r[6][63:32];
assign area_write[7][63:32] = area_r[7][63:32];
assign area_write[8][63:32] = area_r[8][63:32];
generate
for (g=0; g<8;g=g+1) begin
assign area_write[3][g*8 +: 8] = {area_out[(g*16)+64 +: 4], area_r[3][g*8 +: 4]};
assign area_write[4][g*8 +: 8] = area_out[(g*16)+68 +: 8];
assign area_write[5][g*8 +: 8] = {area_r[5][(g*8)+4 +: 4], area_out[(g*16)+76 +: 4]};

if (g<4) begin : top_bottom
assign area_write[0][(g*8)+32 +: 8] = {area_out[(g*16) +: 4], area_r[0][(g*8)+32 +: 4]};
assign area_write[1][(g*8)+32 +: 8] = {area_out[(g*16)+4 +: 8]};
assign area_write[2][(g*8)+32 +: 8] = {area_r[2][(g*8)+36 +: 4], area_out[(g*16)+12 +: 4]};

assign area_write[6][g*8 +: 8] = {area_out[(g*16)+192 +: 4], area_r[6][g*8 +: 4]};
assign area_write[7][g*8 +: 8] = {area_out[(g*16)+196 +: 8]};
assign area_write[8][g*8 +: 8] = {area_r[8][(g*8)+4 +: 4], area_out[(g*16)+204 +: 4]};
end
end
endgenerate

wire write_ready;

integer i;
always @(posedge clk) begin
    if (resetn) begin
        state_r <= state_nxt;
        mem_r <= mem_nxt;
        mem_r2 <= mem_r;
        mem_en_r <=  mem_en_nxt;
        for (i=0; i<9; i=i+1) begin
            area_r[i] <= area_nxt[i];
        end
        word_addr_r <= word_addr_nxt;
        write_data_r <= write_data_nxt;
        write_bytes_r <= write_bytes_nxt;
        en64_r <= en64_nxt;
        we64_r <= we64_nxt;
        addr64_r <= addr64_nxt;
    end else begin
        state_r <= IDLE;
        mem_r <= 4'hf;
        mem_r2 <= 4'hf;
        mem_en_r <= 0;
        for (i=0; i<9; i=i+1) begin
            area_r[i] <= 0;
        end
        word_addr_r <= 0;
        write_data_r <= 0;
        write_bytes_r <= 0;
        en64_r <= 0;
        we64_r <= 0;
        addr64_r <= 0;
    end
end

wire [31:0] right, left;
generate
for (g=0;g<8;g=g+1) begin
    assign right[g*4 +: 4] = write_data_nxt[ g*8    +: 4];
    assign  left[g*4 +: 4] = write_data_nxt[(g*8)+4 +: 4];
end
endgenerate

integer j,x,y;
always @(*) begin
    j=0;
    x=0;
    y=0;
    state_nxt = state_r;
    mem_nxt = 4'hf;
    mem_en_nxt = mem_en_r;
    for (j=0; j<9; j=j+1) begin
        area_nxt[j] = area_r[j];
    end
    word_addr_nxt = word_addr_r;
    write_data_nxt = write_data_r;
    write_bytes_nxt = write_bytes_r;

    en64_nxt = 1'b0;
    we64_nxt = 8'b0;
    addr64_nxt = addr64_r;

    case(state_r)
        IDLE:
        begin
            if (en_in & |we_in) begin
                if (addr_in[ADDR_WIDTH-1:1] != word_addr_r[ADDR_WIDTH-1:1]) begin
                    write_bytes_nxt = 0;
                    word_addr_nxt = addr_in;
                end
                write_bytes_nxt[4*addr_in[0] +: 4] = write_bytes_r[4*addr_in[0] +: 4] | we_in;
                for (j=0; j<4; j=j+1) begin
                    if (we_in[j]) begin
                        write_data_nxt[(32*addr_in[0])+(j*8) +: 8] = din_in[j*8 +: 8];
                    end
                end
            end
            if (&write_bytes_nxt) begin
                state_nxt = READ;
            end
            mem_en_nxt = -1;
            if ((addr_in[ADDR_WIDTH-1:4] == 0) || (addr_in[0] && ~|din_in)) begin
                mem_en_nxt = mem_en_nxt & 9'h1f8;
            end
            if ((addr_in[ADDR_WIDTH-1:4] == {ADDR_WIDTH-4{1'b1}}) || (addr_in[1] && ~|din_in)) begin
                mem_en_nxt = mem_en_nxt & 9'h03f;
            end
            if ((addr_in[3:1] == 0) || (&write_bytes_nxt && ~|right)) begin
                mem_en_nxt = mem_en_nxt & 9'h1b6;
            end
            if ((addr_in[3:1] == 3'h7) || (&write_bytes_nxt && ~|left)) begin
                mem_en_nxt = mem_en_nxt & 9'h0db;
            end
        end
        WRITE, READ:
        begin
            write_bytes_nxt = 0;
            j=0;
            for (y=0; y<3; y=y+1) begin
                for (x=0; x<3; x=x+1) begin
                    if ((mem_nxt == 4'hf) && mem_en_r[j] && ((mem_r == 4'hf) || (j > mem_r))) begin
                        mem_nxt = j[3:0];
                        addr64_nxt[0] = 0;
                        if (y==0) begin
                            addr64_nxt[ADDR_WIDTH-1:4] = word_addr_r[ADDR_WIDTH-1:4]-1;
                        end
                        else if (y==2) begin
                            addr64_nxt[ADDR_WIDTH-1:4] = word_addr_r[ADDR_WIDTH-1:4]+1;
                        end else begin
                            addr64_nxt[ADDR_WIDTH-1:4] = word_addr_r[ADDR_WIDTH-1:4];
                        end

                        if (x==0) begin
                            addr64_nxt[3:1] = word_addr_r[3:1]-1;
                        end
                        else if (x==2) begin
                            addr64_nxt[3:1] = word_addr_r[3:1]+1;
                        end else begin
                            addr64_nxt[3:1] = word_addr_r[3:1];
                        end
                    end
                    j=j+1;
                end
            end

            if (mem_nxt != 4'hf) begin
                en64_nxt = 1'b1; 
                if (state_r == WRITE) begin
                    we64_nxt = 8'hff;
                end
            end
            else if (state_r == WRITE) begin
                state_nxt = IDLE;
            end

            if (state_r == READ) begin
                if (mem_r2 != 4'he) begin
                    area_nxt[mem_r2] = dout64;
                    if (mem_r == 4'he) begin
                        state_nxt = PROC;
                    end
                end
            end
            
            if (mem_nxt == 4'hf) begin
                mem_nxt = 4'he;
            end
        end
        PROC:
        begin
            if (write_ready) begin
                for (j=0;j<9;j=j+1) begin
                    area_nxt[j] = area_write[j];
                end
                state_nxt = WRITE;
            end
        end
        default: ;
    endcase
end

thirty_two64 AREA_CALC (
    .clk(clk),
    .resetn(resetn),

    .coeffs_lo(coeffs_lo),
    .coeffs_hi(coeffs_hi),

    .write_valid(state_r == PROC),
    .write_ready(write_ready),
    .write_strobe(strobe),
    .write_data(write_data_r),

    .area_in(area_in),
    .area_out(area_out),

    .axlo(mem_en_r[3]?4'd0 :4'd4 ),
    .axhi(mem_en_r[5]?4'd15:4'd11),
    .aylo(mem_en_r[2]?4'd0 :4'd4 ),
    .ayhi(mem_en_r[7]?4'd15:4'd11),
    
    .state_rd(state_rd),
    .state_wr(state_wr),
    .state_wr_valid(state_wr_valid)
);

wire read_bypass = en_in & ~|we_in;
wire bypass = (read_bypass | write_bypass) && (state_r == IDLE);

reg en64_r, en64_nxt;
reg [7:0] we64_r, we64_nxt;
reg [ADDR_WIDTH-1:0] addr64_r, addr64_nxt;

wire [63:0] dout64 = {dout_b, dout_a};

assign dout_in = dout_a;

assign en_a = bypass ? en_in : en64_r;
assign we_a = bypass ? we_in : we64_r[3:0];
assign addr_a = bypass ? addr_in : {addr64_r[ADDR_WIDTH-1:1],1'b0};
assign din_a = bypass ? din_in : area_r[mem_r][31:0];

assign en_b = en64_r;
assign we_b = we64_r[7:4];
assign addr_b = {addr64_r[ADDR_WIDTH-1:1],1'b1};
assign din_b = area_r[mem_r][63:32];

assign ready = (state_r == IDLE);

endmodule
