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

module dipole #(
    parameter WRITE_WIDTH = 8,
    parameter WRITE_HEIGHT = 8,
    parameter RADIUS = 4,
    parameter COEFF_WIDTH = 8
)(
    input  clk,
    input  resetn,
    input  [ COEFF_BITS-1 : 0] coeffs_lo,
    input  [ COEFF_BITS-1 : 0] coeffs_hi,
    input  [ COEFF_WIDTH-1 : 0] random_value,
    input  random_ready,
    output reg random_sample,
    input  write_valid,
    output reg write_ready,
    input  [ NUM_WRITES-1 : 0] write_strobe,
    input  [ NUM_WRITES-1 : 0] write_data,
    input  [ WIDTH_BITS-1 : 0] dipole_x,
    input  [HEIGHT_BITS-1 : 0] dipole_y,
    output reg dipole_update,
    output reg dipole_value
);

//wire [ COEFF_BITS-1 : 0] coeffs_lo =  192'h22_2b_34_3b_3d__2b_38_47_53_58__34_47_5d_73_7d__3b_53_73_9b_b3__3d_58_7d_b3;
//wire [ COEFF_BITS-1 : 0] coeffs_hi =  192'h22_2b_34_3b_3d__2b_38_47_53_58__34_47_5d_73_7d__3b_53_73_9b_b3__3d_58_7d_b3;

localparam NUM_COEFFS = ((RADIUS+1)**2)-1;
localparam COEFF_BITS = NUM_COEFFS*COEFF_WIDTH;
localparam NUM_WRITES = WRITE_WIDTH*WRITE_HEIGHT;
localparam WIDTH = WRITE_WIDTH + 2*RADIUS;
localparam HEIGHT = WRITE_HEIGHT + 2*RADIUS;
localparam WIDTH_BITS = $clog2(WRITE_WIDTH + 2*RADIUS);
localparam HEIGHT_BITS = $clog2(WRITE_HEIGHT + 2*RADIUS);
localparam COEFF_SQ_WIDTH = 2*RADIUS+1;
localparam COEFF_SQ_ROW_BITS = COEFF_SQ_WIDTH*COEFF_WIDTH;
localparam COEFF_SQ_WIDTH_BITS = $clog2(COEFF_SQ_WIDTH);

wire [COEFF_BITS+COEFF_WIDTH-1 : 0] coeffs_lo_corner = {coeffs_lo, {COEFF_WIDTH{1'b0}}};
wire [COEFF_BITS+COEFF_WIDTH-1 : 0] coeffs_hi_corner = {coeffs_hi, {COEFF_WIDTH{1'b0}}};
wire [COEFF_SQ_ROW_BITS-1 : 0] coeffs_lo_test [COEFF_SQ_WIDTH-1:0];
wire [COEFF_SQ_ROW_BITS-1 : 0] coeffs_hi_test [COEFF_SQ_WIDTH-1:0];

genvar n, m;
generate
for (m=0; m<COEFF_SQ_WIDTH; m=m+1) begin
for (n=0; n<COEFF_SQ_WIDTH; n=n+1) begin
    //assign coeffs_hi_sq[m*COEFF_SQ_ROW_BITS+n*COEFF_WIDTH +: COEFF_WIDTH] = coeffs_hi_corner[(m<RADIUS?RADIUS-m:m-RADIUS)*(RADIUS+1)*COEFF_WIDTH+(n<RADIUS?RADIUS-n:n-RADIUS)*COEFF_WIDTH +: COEFF_WIDTH];
    //assign coeffs_lo_sq[m*COEFF_SQ_ROW_BITS+n*COEFF_WIDTH +: COEFF_WIDTH] = coeffs_lo_corner[(m<RADIUS?RADIUS-m:m-RADIUS)*(RADIUS+1)*COEFF_WIDTH+(n<RADIUS?RADIUS-n:n-RADIUS)*COEFF_WIDTH +: COEFF_WIDTH];
    assign coeffs_lo_test[m][n*COEFF_WIDTH +: COEFF_WIDTH] = coeffs_lo_corner[(m<RADIUS?RADIUS-m:m-RADIUS)*(RADIUS+1)*COEFF_WIDTH+(n<RADIUS?RADIUS-n:n-RADIUS)*COEFF_WIDTH +: COEFF_WIDTH];
    assign coeffs_hi_test[m][n*COEFF_WIDTH +: COEFF_WIDTH] = coeffs_hi_corner[(m<RADIUS?RADIUS-m:m-RADIUS)*(RADIUS+1)*COEFF_WIDTH+(n<RADIUS?RADIUS-n:n-RADIUS)*COEFF_WIDTH +: COEFF_WIDTH];
end
end
endgenerate

localparam IDLE = 3'd0;
localparam PROC = 3'd1;
localparam CPHI = 3'd2;
localparam CPLO = 3'd3;
localparam DONE = 3'd4;

reg [2:0] state_r, state_nxt;

reg [COEFF_WIDTH*2-1:0] phi_r, phi_nxt;
reg [COEFF_WIDTH*2-1:0] plo_r, plo_nxt;

reg [ WIDTH_BITS-1 : 0] wxlo_r, wxlo_nxt;
reg [ WIDTH_BITS-1 : 0] wxhi_r, wxhi_nxt;
reg [ WIDTH_BITS-1 : 0] wx_r, wx_nxt;
reg [HEIGHT_BITS-1 : 0] wylo_r, wylo_nxt;
reg [HEIGHT_BITS-1 : 0] wyhi_r, wyhi_nxt;
reg [HEIGHT_BITS-1 : 0] wy_r, wy_nxt;

reg [COEFF_SQ_WIDTH_BITS-1 : 0] cxlo_r, cxlo_nxt;
reg [COEFF_SQ_WIDTH_BITS-1 : 0] cxhi_r, cxhi_nxt;
reg [COEFF_SQ_WIDTH_BITS-1 : 0] cx_r, cx_nxt;
reg [COEFF_SQ_WIDTH_BITS-1 : 0] cylo_r, cylo_nxt;
reg [COEFF_SQ_WIDTH_BITS-1 : 0] cyhi_r, cyhi_nxt;
reg [COEFF_SQ_WIDTH_BITS-1 : 0] cy_r, cy_nxt;

reg du_r, du_nxt;
reg dv_r, dv_nxt;

reg [1:0] hilo_r, hilo_nxt;
reg done_r, done_nxt;

always @(posedge clk) begin
    if (resetn) begin
        state_r <= state_nxt;
        phi_r <= phi_nxt;
        plo_r <= plo_nxt;
        wxlo_r <= wxlo_nxt;
        wxhi_r <= wxhi_nxt;
        wx_r   <= wx_nxt;
        wylo_r <= wylo_nxt;
        wyhi_r <= wyhi_nxt;
        wy_r   <= wy_nxt;
        cxlo_r <= cxlo_nxt;
        cxhi_r <= cxhi_nxt;
        cx_r   <= cx_nxt;
        cylo_r <= cylo_nxt;
        cyhi_r <= cyhi_nxt;
        cy_r   <= cy_nxt;
        du_r <= du_nxt;
        dv_r <= dv_nxt;
        hilo_r <= hilo_nxt;
        done_r <= done_nxt;
    end else begin
        state_r <= IDLE;
        phi_r <= 0;
        plo_r <= 0;
        wxlo_r <= 0;
        wxhi_r <= WRITE_WIDTH-1;
        wx_r <= 0;
        wylo_r <= 0;
        wyhi_r <= WRITE_HEIGHT-1;
        wy_r <= 0;
        cxlo_r <= 0;
        cxhi_r <= COEFF_SQ_WIDTH-1;
        cx_r <= 0;
        cylo_r <= 0;
        cyhi_r <= COEFF_SQ_WIDTH-1;
        cy_r <= 0;
        du_r <= 1'b0;
        dv_r <= 1'b0;
        hilo_r <= 0;
        done_r <= 0;
    end
end

always @(*) begin
    state_nxt = state_r;
    phi_nxt = phi_r;
    plo_nxt = plo_r;
    wxlo_nxt = wxlo_r;
    wxhi_nxt = wxhi_r;
    wx_nxt = wx_r;
    wylo_nxt = wylo_r;
    wyhi_nxt = wyhi_r;
    wy_nxt = wy_r;
    cxlo_nxt = cxlo_r;
    cxhi_nxt = cxhi_r;
    cx_nxt = cx_r;
    cylo_nxt = cylo_r;
    cyhi_nxt = cyhi_r;
    cy_nxt = cy_r;
    du_nxt = du_r;
    dv_nxt = dv_r;
    hilo_nxt = hilo_r;
    done_nxt = done_r;

    random_sample = 1'b0;
    dipole_update = 1'b0;
    dipole_value = 1'b0;
    write_ready = 1'b0;

    a = 0;
    b = 0;

    case (state_r)
        IDLE:
        begin
            phi_nxt = 0;
            plo_nxt = 0;
            wxlo_nxt = 0;
            wxhi_nxt = WRITE_WIDTH-1;
            wylo_nxt = 0;
            wyhi_nxt = WRITE_HEIGHT-1;
            cxlo_nxt = 0;
            cxhi_nxt = COEFF_SQ_WIDTH-1;
            cylo_nxt = 0;
            cyhi_nxt = COEFF_SQ_WIDTH-1;
            du_nxt = 1'b0;
            dv_nxt = 1'b0;
            done_nxt = 1'b0;
            hilo_nxt = 2'b0;
        
            if (dipole_x < WRITE_WIDTH) begin
                wxhi_nxt = dipole_x;
                cxlo_nxt = WRITE_WIDTH - dipole_x;
            end else begin
                cxhi_nxt = WIDTH-1 - dipole_x;
            end
            
            if (dipole_x > WRITE_WIDTH) begin
                wxlo_nxt = dipole_x - WRITE_WIDTH;
            end
            
            if (dipole_x <= RADIUS) begin
                cxlo_nxt = COEFF_SQ_WIDTH-1 - dipole_x;
            end

            if (dipole_y < WRITE_HEIGHT) begin
                wyhi_nxt = dipole_y;
                cylo_nxt = WRITE_HEIGHT - dipole_y;
            end else begin
                cyhi_nxt = HEIGHT-1 - dipole_y;
            end

            if (dipole_y > WRITE_HEIGHT) begin
                wylo_nxt = dipole_y - WRITE_HEIGHT;
            end
            
            if (dipole_y <= RADIUS) begin
                cylo_nxt = COEFF_SQ_WIDTH-1 - dipole_y;
            end

            cx_nxt = cxlo_nxt;
            cy_nxt = cylo_nxt;
            wx_nxt = wxlo_nxt;
            wy_nxt = wylo_nxt;

            if (random_ready & write_valid) begin
                state_nxt = PROC;
            end
        end
        PROC:
        begin
            case (hilo_r)
                2'b10:
                    begin
                        plo_nxt = plo_r + c; 
                    end
                2'b11:
                    begin
                        phi_nxt = phi_r + c; 
                    end
                default: ;
            endcase
            if (done_r == 1'b0) begin
                if (write_strobe[wy_r*WRITE_WIDTH+wx_r] == 1'b1) begin
                    if (write_data[wy_r*WRITE_WIDTH+wx_r] == 1'b1) begin
                        //a = coeffs_hi_sq[cy_r*COEFF_SQ_ROW_BITS+cx_r*COEFF_WIDTH +: COEFF_WIDTH];
                        a = coeffs_hi_test[cy_r][cx_r*COEFF_WIDTH +: COEFF_WIDTH];
                        b = (2**COEFF_WIDTH - phi_r[COEFF_WIDTH:0]);
                        hilo_nxt = 2'b11;
                        //phi_nxt = phi_r + c;
                    end else begin
                        //a = coeffs_lo_sq[cy_r*COEFF_SQ_ROW_BITS+cx_r*COEFF_WIDTH +: COEFF_WIDTH];
                        a = coeffs_lo_test[cy_r][cx_r*COEFF_WIDTH +: COEFF_WIDTH];
                        b = (2**COEFF_WIDTH - plo_r[COEFF_WIDTH:0]);
                        hilo_nxt = 2'b10;
                        //plo_nxt = plo_r + c;
                    end
                end
                if (wx_r == wxhi_r) begin
                    wx_nxt = wxlo_r;
                    cx_nxt = cxlo_r;
                    if (wy_r == wyhi_r) begin
                        done_nxt = 1'b1;
                        //state_nxt = CPHI;
                    end else begin
                        wy_nxt = wy_r + 1;
                        cy_nxt = cy_r + 1;
                    end
                end else begin
                    wx_nxt = wx_r + 1;
                    cx_nxt = cx_r + 1;
                end
            end else begin
                state_nxt = CPHI;
            end
        end
        CPHI:
        begin
            a = phi_r[COEFF_WIDTH-1:0];
            b = (2**COEFF_WIDTH - plo_r[COEFF_WIDTH:0]);
            state_nxt = CPLO;
        end
        CPLO:
        begin
            a = plo_r[COEFF_WIDTH-1:0];
            b = (2**COEFF_WIDTH - phi_r[COEFF_WIDTH:0]);
            phi_nxt = c;
            state_nxt = DONE;
        end
        DONE:
        begin
            plo_nxt = c;
            state_nxt = IDLE;
            write_ready = 1'b1;
            random_sample = 1'b1;

            if ({1'b0, random_value} < phi_r[0 +: COEFF_WIDTH+1]) begin
                dipole_update = 1'b1;
                dipole_value = 1'b1;
            end else if ({1'b0, random_value} < (phi_r[0 +: COEFF_WIDTH+1] + plo_nxt[0 +: COEFF_WIDTH+1])) begin
                dipole_update = 1'b1;
                dipole_value = 1'b0;
            end
        end
        default: ;
    endcase
end

reg [COEFF_WIDTH-1:0] a;
reg [COEFF_WIDTH:0] b;
wire [COEFF_WIDTH*2-1:0] c;

mulshift #(
    .WIDTH_A(COEFF_WIDTH),
    .WIDTH_B(COEFF_WIDTH+1),
    .WIDTH_C(COEFF_WIDTH*2),
    .SHIFT(COEFF_WIDTH)
) MS (
    .clk(clk),
    .a(a),
    .b(b),
    .c(c)
);

endmodule
