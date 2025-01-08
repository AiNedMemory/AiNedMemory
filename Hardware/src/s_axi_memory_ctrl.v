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

module s_axi_memory_ctrl
#(
    parameter ADDR_WIDTH = 10
)(
    // AXI4-Lite interface signals
    // Global
    input  s_aclk,
    input  s_aresetn,

    // Write address channel
    input  s_awvalid,
    output s_awready,
    input  [ADDR_WIDTH-1 : 0] s_awaddr,
    input  [2 : 0] s_awprot,
    // Write data channel
    input  s_wvalid,
    output s_wready,
    input  [31 : 0] s_wdata,
    input  [3 : 0] s_wstrb,
    // Write response channel
    output s_bvalid,
    input  s_bready,
    output [1 : 0] s_bresp,

    // Read address channel
    input  s_arvalid,
    output s_arready,
    input  [ADDR_WIDTH-1 : 0] s_araddr,
    input  [2 : 0] s_arprot,
    // Read data channel
    output s_rvalid,
    input  s_rready,
    output [31 : 0] s_rdata,
    output [1 : 0] s_rresp,

    output en,
    output [3: 0] we,
    output [ADDR_WIDTH-3:0] addr,
    output [31:0] din,
    input  wrready,
    input  [31:0] dout
);

reg [3:0] we_nxt [0:2];
reg [3:0] we_r [0:2];
reg [ADDR_WIDTH-3:0] addr_nxt [0:2];
reg [ADDR_WIDTH-3:0] addr_r [0:2];
reg [31:0] data_nxt [0:2];
reg [31:0] data_r [0:2];

reg [1:0] ptr_nxt, ptr_r;

reg [ADDR_WIDTH-1:0] addr_wr_nxt, addr_wr_r;
reg [3:0] we_wr_nxt, we_wr_r;
reg [31:0] data_wr_nxt, data_wr_r;

reg wvalid_r, wvalid_nxt, awvalid_r, awvalid_nxt;

reg wrready_r;

reg write;
reg read;
integer i, j;

always @(posedge s_aclk) begin
    if (s_aresetn) begin
        for (i=0; i<3; i=i+1) begin
            we_r[i] <= we_nxt[i];
            addr_r[i] <= addr_nxt[i];
            data_r[i] <= data_nxt[i];
        end
        ptr_r <= ptr_nxt;
        addr_wr_r <= addr_wr_nxt;
        data_wr_r <= data_wr_nxt;
        we_wr_r <= we_wr_nxt;
        wvalid_r <= wvalid_nxt;
        awvalid_r <= awvalid_nxt;
        wrready_r <= wrready;
    end else begin
        for (i=0; i<3; i=i+1) begin
            we_r[i] <= 4'b0;
            addr_r[i] <= {ADDR_WIDTH-2{1'b0}};
            data_r[i] <= 32'b0;
        end
        ptr_r <= 2'b0;
        addr_wr_r <= {ADDR_WIDTH{1'b0}};
        data_wr_r <= 32'b0;
        we_wr_r <= 4'b0;
        wvalid_r <= 1'b0;
        awvalid_r <= 1'b0;
        wrready_r <= 1'b0;
    end
end 

always @(*) begin
    for (j=0; j<3; j=j+1) begin
        we_nxt[j] = we_r[j];
        addr_nxt[j] = addr_r[j];
        data_nxt[j] = data_r[j];
    end
    ptr_nxt = ptr_r;

    addr_wr_nxt = addr_wr_r;
    we_wr_nxt = we_wr_r;
    data_wr_nxt = data_wr_r;

    write = (s_awvalid & s_awready & s_wvalid & s_wready)
          | (s_awvalid & s_awready & wvalid_r)
          |             (awvalid_r & s_wvalid & s_wready);
    wvalid_nxt  = ~write & (wvalid_r  | (s_wvalid & s_wready));
    awvalid_nxt = ~write & (awvalid_r | (s_awvalid & s_awready));

    read = s_arvalid & s_arready;

    if (ptr_r != 2'b0) begin
        if (we_r[0] == 4'b0 ? (s_rready & s_rvalid) : (s_bready & s_bvalid)) begin
            for (j=0; j<2; j=j+1) begin
                we_nxt[j] = we_r[j+1];
                addr_nxt[j] = addr_r[j+1];
                data_nxt[j] = data_r[j+1];
            end
            we_nxt[2] = 4'b0;
            addr_nxt[2] = {ADDR_WIDTH-2{1'b0}};
            data_nxt[2] = 32'b0;
            ptr_nxt = ptr_r - 1'b1;
        end
    end

    if (s_awvalid & s_awready) begin
        addr_wr_nxt = s_awaddr;
    end

    if (s_wvalid & s_wready) begin
        data_wr_nxt = s_wdata;
        we_wr_nxt = s_wstrb;
    end

    if (read) begin
        addr_nxt[ptr_nxt] = s_araddr[ADDR_WIDTH-1:2];
        ptr_nxt = ptr_nxt + 1'b1;
    end

    if (write) begin
        we_nxt[ptr_nxt] = we_wr_nxt;
        addr_nxt[ptr_nxt] = addr_wr_nxt[ADDR_WIDTH-1:2];
        data_nxt[ptr_nxt] = data_wr_nxt;
        ptr_nxt = ptr_nxt + 1'b1;
    end
end

assign s_awready = ~(ptr_r[1] | awvalid_r);
assign s_wready  = ~(ptr_r[1] |  wvalid_r);
assign s_bvalid = (ptr_r == 2'b0) ? 1'b0 : |we_r[0] & wrready_r;
assign s_bresp = 2'b0;

assign s_arready = ~(ptr_r[1]);
assign s_rvalid = (ptr_r == 2'b0) ? 1'b0 : ~|we_r[0] & wrready_r;
assign s_rdata = dout;
assign s_rresp = 2'b0;

assign en = |ptr_nxt;
assign we = we_nxt[0];
assign addr = addr_nxt[0];
assign din = data_nxt[0];

endmodule
