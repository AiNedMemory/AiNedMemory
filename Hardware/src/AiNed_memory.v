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

module AiNed_memory
#(
    parameter ADDR_WIDTH = 10
)(
    // AXI4-Lite interface signals
    // Global
    input  s_mem_aclk,
    input  s_mem_aresetn,

    // Write address channel
    input  s_mem_awvalid,
    output s_mem_awready,
    input  [ADDR_WIDTH-1 : 0] s_mem_awaddr,
    input  [2 : 0] s_mem_awprot,
    // Write data channel
    input  s_mem_wvalid,
    output s_mem_wready,
    input  [31 : 0] s_mem_wdata,
    input  [3 : 0] s_mem_wstrb,
    // Write response channel
    output s_mem_bvalid,
    input  s_mem_bready,
    output [1 : 0] s_mem_bresp,

    // Read address channel
    input  s_mem_arvalid,
    output s_mem_arready,
    input  [ADDR_WIDTH-1 : 0] s_mem_araddr,
    input  [2 : 0] s_mem_arprot,
    // Read data channel
    output s_mem_rvalid,
    input  s_mem_rready,
    output [31 : 0] s_mem_rdata,
    output [1 : 0] s_mem_rresp,

    // AXI4-Lite interface signals
    // Global
    input  s_ctrl_aclk,
    input  s_ctrl_aresetn,

    // Write address channel
    input  s_ctrl_awvalid,
    output s_ctrl_awready,
    input  [12 : 0] s_ctrl_awaddr,
    input  [2 : 0] s_ctrl_awprot,
    // Write data channel
    input  s_ctrl_wvalid,
    output s_ctrl_wready,
    input  [31 : 0] s_ctrl_wdata,
    input  [3 : 0] s_ctrl_wstrb,
    // Write response channel
    output s_ctrl_bvalid,
    input  s_ctrl_bready,
    output [1 : 0] s_ctrl_bresp,

    // Read address channel
    input  s_ctrl_arvalid,
    output s_ctrl_arready,
    input  [12 : 0] s_ctrl_araddr,
    input  [2 : 0] s_ctrl_arprot,
    // Read data channel
    output s_ctrl_rvalid,
    input  s_ctrl_rready,
    output [31 : 0] s_ctrl_rdata,
    output [1 : 0] s_ctrl_rresp
);

wire clk = s_mem_aclk;
wire resetn = s_mem_aresetn;

wire [63 : 0] strobe;
wire [191:0] coeffs_lo;
wire [191:0] coeffs_hi;
wire write_bypass;

wire [256*4*32-1:0] state_rd;
wire [31:0] state_wr;
wire [9:0] state_wr_valid;

s_axi_registers S_AXI_REGS (
    .s_aclk(s_ctrl_aclk),
    .s_aresetn(s_ctrl_aresetn),

    // Write address channel
    .s_awvalid(s_ctrl_awvalid),
    .s_awready(s_ctrl_awready),
    .s_awaddr(s_ctrl_awaddr),
    .s_awprot(s_ctrl_awprot),
    // Write data channel
    .s_wvalid(s_ctrl_wvalid),
    .s_wready(s_ctrl_wready),
    .s_wdata(s_ctrl_wdata),
    .s_wstrb(s_ctrl_wstrb),
    // Write response channel
    .s_bvalid(s_ctrl_bvalid),
    .s_bready(s_ctrl_bready),
    .s_bresp(s_ctrl_bresp),

    // Read address channel
    .s_arvalid(s_ctrl_arvalid),
    .s_arready(s_ctrl_arready),
    .s_araddr(s_ctrl_araddr),
    .s_arprot(s_ctrl_arprot),
    // Read data channel
    .s_rvalid(s_ctrl_rvalid),
    .s_rready(s_ctrl_rready),
    .s_rdata(s_ctrl_rdata),
    .s_rresp(s_ctrl_rresp),

    .strobe(strobe),
    .coeffs_lo(coeffs_lo),
    .coeffs_hi(coeffs_hi),
    .write_bypass(write_bypass),
    
    .state_rd(state_rd),
    .state_wr(state_wr),
    .state_wr_valid(state_wr_valid)
);

s_axi_memory_ctrl #(
    .ADDR_WIDTH(ADDR_WIDTH)
) S_AXI_MEM (
    .s_aclk(s_mem_aclk),
    .s_aresetn(s_mem_aresetn),

    // Write address channel
    .s_awvalid(s_mem_awvalid),
    .s_awready(s_mem_awready),
    .s_awaddr(s_mem_awaddr),
    .s_awprot(s_mem_awprot),
    // Write data channel
    .s_wvalid(s_mem_wvalid),
    .s_wready(s_mem_wready),
    .s_wdata(s_mem_wdata),
    .s_wstrb(s_mem_wstrb),
    // Write response channel
    .s_bvalid(s_mem_bvalid),
    .s_bready(s_mem_bready),
    .s_bresp(s_mem_bresp),

    // Read address channel
    .s_arvalid(s_mem_arvalid),
    .s_arready(s_mem_arready),
    .s_araddr(s_mem_araddr),
    .s_arprot(s_mem_arprot),
    // Read data channel
    .s_rvalid(s_mem_rvalid),
    .s_rready(s_mem_rready),
    .s_rdata(s_mem_rdata),
    .s_rresp(s_mem_rresp),

    .en(en),
    .we(we),
    .addr(addr),
    .din(din),
    .wrready(wrready),
    .dout(dout)
);

wire en, en_a, en_b;
wire [3:0] we, we_a, we_b;
wire [ADDR_WIDTH-3:0] addr, addr_a, addr_b;
wire [31:0] din, dout, din_a, dout_a, din_b, dout_b;
wire wrready;

pwrite_ctrl #(
    .ADDR_WIDTH(ADDR_WIDTH-2)
) PW_CTRL (
    .clk(clk),
    .resetn(resetn),

    .strobe(strobe),
    .coeffs_lo(coeffs_lo),
    .coeffs_hi(coeffs_hi),
    .write_bypass(write_bypass),

    .ready(wrready),

    .en_in(en),
    .we_in(we),
    .addr_in(addr),
    .din_in(din),
    .dout_in(dout),

    .en_a(en_a),
    .we_a(we_a),
    .addr_a(addr_a),
    .din_a(din_a),
    .dout_a(dout_a),

    .en_b(en_b),
    .we_b(we_b),
    .addr_b(addr_b),
    .din_b(din_b),
    .dout_b(dout_b),
    
    .state_rd(state_rd),
    .state_wr(state_wr),
    .state_wr_valid(state_wr_valid)
);

dpsram #(
    .ADDR_WIDTH(ADDR_WIDTH-2)
) MEM (
    .clk_a(clk),
    .en_a(en_a),
    .we_a(we_a),
    .addr_a(addr_a),
    .din_a(din_a),
    .dout_a(dout_a),

    .clk_b(clk),
    .en_b(en_b),
    .we_b(we_b),
    .addr_b(addr_b),
    .din_b(din_b),
    .dout_b(dout_b)
);

endmodule
