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

module thirty_two64 (
    input  clk,
    input  resetn,

    input  [191 : 0] coeffs_lo,
    input  [191 : 0] coeffs_hi,

    input  write_valid,
    output reg write_ready,
    input  [63:0] write_strobe,
    input  [63:0] write_data,

    input  [16*16-1:0] area_in,
    output [16*16-1:0] area_out,

    input [3:0] axlo,
    input [3:0] axhi,
    input [3:0] aylo,
    input [3:0] ayhi,

    output [256*4*32-1:0] state_rd,
    input  [31:0] state_wr,
    input  [9:0] state_wr_valid
);

localparam IDLE = 2'd0;
localparam PROC = 2'd1;
localparam DONE = 2'd2;
localparam NUM_DIPOLES = 32;

//wire [191 : 0] coeffs_lo =  192'h22_2b_34_3b_3d__2b_38_47_53_58__34_47_5d_73_7d__3b_53_73_9b_b3__3d_58_7d_b3;
//wire [191 : 0] coeffs_hi =  192'h22_2b_34_3b_3d__2b_38_47_53_58__34_47_5d_73_7d__3b_53_73_9b_b3__3d_58_7d_b3;

wire [255:0] strobe = {16'b0, 16'b0, 16'b0, 16'b0, 4'b0, write_strobe[63:56], 4'b0, 4'b0, write_strobe[55:48], 4'b0, 4'b0, write_strobe[47:40], 4'b0, 4'b0, write_strobe[39:32], 4'b0, 4'b0, write_strobe[31:24], 4'b0, 4'b0, write_strobe[23:16], 4'b0, 4'b0, write_strobe[15: 8], 4'b0, 4'b0, write_strobe[ 7: 0], 4'b0, 16'b0, 16'b0, 16'b0, 16'b0};
wire [255:0] data = {16'b0, 16'b0, 16'b0, 16'b0, 4'b0, write_data[63:56], 4'b0, 4'b0, write_data[55:48], 4'b0, 4'b0, write_data[47:40], 4'b0, 4'b0, write_data[39:32], 4'b0, 4'b0, write_data[31:24], 4'b0, 4'b0, write_data[23:16], 4'b0, 4'b0, write_data[15: 8], 4'b0, 4'b0, write_data[ 7: 0], 4'b0, 16'b0, 16'b0, 16'b0, 16'b0};

wire [NUM_DIPOLES-1:0] random_sample;
wire [NUM_DIPOLES-1:0] random_ready;
wire [31:0] random_value [NUM_DIPOLES-1:0];

reg [1:0] state_r, state_nxt;

reg [3:0] dpx_r [NUM_DIPOLES-1:0];
reg [3:0] dpy_r [NUM_DIPOLES-1:0];
reg [3:0] dpx_nxt [NUM_DIPOLES-1:0];
reg [3:0] dpy_nxt [NUM_DIPOLES-1:0];

reg [16*16-1:0] area_r, area_nxt;

wire [NUM_DIPOLES-1:0] wr_ready;
reg [NUM_DIPOLES-1:0] wr_valid_r;
reg [NUM_DIPOLES-1:0] wr_valid_nxt;
reg [NUM_DIPOLES-1:0] wr_valid;

wire [NUM_DIPOLES-1:0] dipole_update, dipole_value;

reg [NUM_DIPOLES-1:0] done_r, done_nxt;

integer i, j;
reg [$clog2(NUM_DIPOLES)-1:0] n;

reg [$clog2(256/NUM_DIPOLES)-1:0] pos_nxt [NUM_DIPOLES-1:0];
reg [$clog2(256/NUM_DIPOLES)-1:0] pos_r [NUM_DIPOLES-1:0];

always @(posedge clk) begin
    if (resetn) begin
        state_r <= state_nxt;
        area_r <= area_nxt;
        wr_valid_r <= wr_valid_nxt;
        done_r <= done_nxt;
        for (i=0;i<NUM_DIPOLES;i=i+1) begin
            dpx_r[i] <= dpx_nxt[i];
            dpy_r[i] <= dpy_nxt[i];
            pos_r[i] <= pos_nxt[i];
        end
    end else begin
        state_r <= IDLE;
        area_r <= 0;
        wr_valid_r <= 0;
        done_r <= 0;
        for (i=0;i<NUM_DIPOLES;i=i+1) begin
            dpx_r[i] <= 0;
            dpy_r[i] <= 0;
            pos_r[i] <= 0;
        end
    end
end

always @(*) begin
    state_nxt = state_r;
    area_nxt = area_r;
    write_ready = 1'b0;
    wr_valid_nxt = wr_valid_r;
    wr_valid = {NUM_DIPOLES{1'b0}};
    done_nxt = done_r;
    for (i=0;i<NUM_DIPOLES;i=i+1) begin
        dpx_nxt[i] = dpx_r[i];
        dpy_nxt[i] = dpy_r[i];
        pos_nxt[i] = pos_r[i];
    end

    case (state_r)
        IDLE:
        begin
            if (write_valid) begin
                area_nxt = area_in;
                for (j=0;j<4;j=j+1) begin
                    for (i=0;i<8;i=i+1) begin
                        n = {j[1:0], i[2:0]};
                        dpx_nxt[n] = i[3:0];
                        dpy_nxt[n] = j[3:0];
                        wr_valid_nxt[n] = (((i[3:0] >= axlo) && (i[3:0] <= axhi)) && ((j[3:0] >= aylo) && (j[3:0] <= ayhi)));
                        pos_nxt[n] = 3'b000;
                    end
                end
                state_nxt = PROC;
                done_nxt = 0;
            end
        end
        PROC:
        begin
            for (i=0;i<NUM_DIPOLES;i=i+1) begin
                if (!done_r[i]) begin
                    if (strobe[{dpy_r[i], dpx_r[i]}]) begin
                        wr_valid[i] = 1'b0;
                        area_nxt[{dpy_r[i], dpx_r[i]}] = data[{dpy_r[i], dpx_r[i]}];
                    end else begin
                        wr_valid[i] = wr_valid_r[i];
                    end
                    if (wr_ready[i] | ~wr_valid[i]) begin
                        if (wr_ready[i]) begin
                            if (dipole_update[i]) begin
                                area_nxt[{dpy_r[i], dpx_r[i]}] = dipole_value[i];
                            end
                        end
                        if (pos_r[i] == 3'h7) begin
                            wr_valid_nxt[i] = 1'b0;
                            done_nxt[i] = 1'b1;
                        end else begin
                            pos_nxt[i] = pos_r[i] + 1;
                            dpx_nxt[i] = {pos_nxt[i][0], dpx_r[i][2:0]};
                            dpy_nxt[i] = {pos_nxt[i][2:1], dpy_r[i][1:0]};
                            wr_valid_nxt[i] = (((dpx_nxt[i] >= axlo) && (dpx_nxt[i] <= axhi)) && ((dpy_nxt[i] >= aylo) && (dpy_nxt[i] <= ayhi)));
                        end
                    end
                end
            end
            if (&done_nxt) begin
                state_nxt = DONE;
            end
        end
        DONE:
        begin
            write_ready = 1'b1;
            state_nxt = IDLE;
        end
        default: ;
    endcase
end

assign area_out = area_r;

function [3:0] min(input [3:0] a, input [3:0] b);
    min = ((a < b) ? a : b);
endfunction

function [3:0] max(input [3:0] a, input [3:0] b);
    max = ((a > b) ? a : b);
endfunction

genvar g;
wire [31:0] t [NUM_DIPOLES-1:0];
localparam SEEDS = 1024'h7d236041eddbab9cd89af315c24a48340695d1dcc728f1cffacafb0dbc607cbecd18272942908c1280f56345b383f91b3124f56e38ed359b2388a33b87c2efe3a0237c31036e7fb2976be41b95f69fdd86960ca115e1a328cf10db3cf11b521b8bd162385ecd5cced9d7b2c1063239fc5cd29ae107685a803f512f4793c04b5b;

generate
for (g=0;g<NUM_DIPOLES;g=g+1) begin
assign t[g] = g;

prng #(
    .SEED(SEEDS[g*32 +: 32])
) RAND (
    .clk(clk),
    .resetn(resetn),

    .sample(random_sample[g]),
    .valid(random_ready[g]),
    .value(random_value[g]),

    .state_rd(state_rd[g*4*32 +: 4*32]),
    .state_wr(state_wr[31:0]),
    .state_wr_valid((state_wr_valid[9:2] == t[g][7:0]) ? state_wr_valid[1:0] : 2'b0)
);

dipole #(
    .WRITE_WIDTH(8),
    .WRITE_HEIGHT(8),
    .RADIUS(4),
    .COEFF_WIDTH(8)
) DP (
    .clk(clk),
    .resetn(resetn),

    .coeffs_lo(coeffs_lo),
    .coeffs_hi(coeffs_hi),

    .random_value(random_value[g][31:24]),
    .random_ready(random_ready[g]),
    .random_sample(random_sample[g]),

    .write_valid(wr_valid[g]),
    .write_ready(wr_ready[g]),
    .write_strobe(write_strobe),
    .write_data(write_data),

    .dipole_x(dpx_r[g]),
    .dipole_y(dpy_r[g]),

    .dipole_update(dipole_update[g]),
    .dipole_value(dipole_value[g])
);
end
endgenerate

assign state_rd[256*4*32-1:NUM_DIPOLES*4*32] = 0;

endmodule
