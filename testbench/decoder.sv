// SPDX-License-Identifier: Apache-2.0
// Copyright 2019 Western Digital Corporation or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Comment
`ifdef RV_BUILD_AXI4
module decoder #(TAGW=1) (
input                   aclk,
input                   rst_l,
input                   arvalid,
output                  arready,
input [31:0]            araddr,
input [TAGW-1:0]        arid,
input [7:0]             arlen,
input [1:0]             arburst,
input [2:0]             arsize,

output                  rvalid,
input                   rready,
output  [63:0]          rdata,
output  [1:0]           rresp,
output  [TAGW-1:0]      rid,
output                  rlast,

input                   awvalid,
output                  awready,
input [31:0]            awaddr,
input [TAGW-1:0]        awid,
input [7:0]             awlen,
input [1:0]             awburst,
input [2:0]             awsize,

input [63:0]            wdata,
input [7:0]             wstrb,
input                   wvalid,
output                  wready,

output                  bvalid,
input                   bready,
output  [1:0]           bresp,
output  [TAGW-1:0]      bid
);
axi_bus #(.TAGW(TAGW)) lmem(
    .aclk(aclk),
    .rst_l(rst_l),
    .arvalid(w_arvalid),
    .arready(w_arready),
    .araddr(w_araddr),
    .arid(w_arid),
    .arlen(w_arlen),
    .arburst(w_arburst),
    .arsize(w_arsize),

    .rvalid(w_rvalid),
    .rready(w_rready),
    .rdata(w_rdata),
    .rresp(w_rresp),
    .rid(w_rid),
    .rlast(w_rlast),

    .awvalid(w_awvalid),
    .awready(w_awready),
    .awaddr(w_awaddr),
    .awid(w_awid),
    .awlen(w_awlen),
    .awburst(w_awburst),
    .awsize(w_awsize),

    .wdata(w_wdata),
    .wstrb(w_wstrb),
    .wvalid(w_wvalid),
    .wready(w_wready),

    .bvalid(w_bvalid),
    .bready(w_bready),
    .bresp(w_bresp),
    .bid(w_bid)
);

star_m star(
    .aclk(aclk),
    .rst_l(rst_l),
    .arvalid(x_arvalid),
    .arready(x_arready),
    .araddr(x_araddr),
    .arid(x_arid),
    .arlen(x_arlen),
    .arburst(x_arburst),
    .arsize(x_arsize),

    .rvalid(x_rvalid),
    .rready(x_rready),
    .rdata(x_rdata),
    .rresp(x_rresp),
    .rid(x_rid),
    .rlast(x_rlast),

    .awvalid(x_awvalid),
    .awready(x_awready),
    .awaddr(x_awaddr),
    .awid(x_awid),
    .awlen(x_awlen),
    .awburst(x_awburst),
    .awsize(x_awsize),

    .wdata(x_wdata),
    .wstrb(x_wstrb),
    .wvalid(x_wvalid),
    .wready(x_wready),

    .bvalid(x_bvalid),
    .bready(x_bready),
    .bresp(x_bresp),
    .bid(x_bid)
);

parameter   MAILBOX_ADDR = 32'hd0580000;
parameter   BOUNDARY1 = 32'h80000000;
parameter   BOUNDARY2 = 32'hF8000000;
wire [63:0] WriteData;
wire        mailbox_write;

assign mailbox_write = awvalid && awaddr==MAILBOX_ADDR && rst_l;
assign WriteData = wdata;

initial begin
    $readmemh("program.hex",  lmem.mem);
    $readmemh("program.hex",  star.mem);
end

// lmem
wire            w_arvalid;
wire            w_arready;
wire [31:0]     w_araddr;
wire [TAGW-1:0] w_arid;
wire [7:0]      w_arlen;
wire [1:0]      w_arburst;
wire [2:0]      w_arsize;

wire            w_rvalid;
wire            w_rready;
wire [63:0]     w_rdata;
wire [1:0]      w_rresp;
wire [TAGW-1:0] w_rid;
wire            w_rlast;

wire            w_awvalid;
wire            w_awready;
wire [31:0]     w_awaddr;
wire [TAGW-1:0] w_awid;
wire [7:0]      w_awlen;
wire [1:0]      w_awburst;
wire [2:0]      w_awsize;

wire            w_wvalid;
wire            w_wready;
wire [63:0]     w_wdata;
wire [7:0]      w_wstrb;

wire            w_bvalid;
wire            w_bready;
wire [1:0]      w_bresp;
wire [3:0]      w_bid;


// star
wire            x_arvalid;
wire            x_arready;
wire [31:0]     x_araddr;
wire [TAGW-1:0] x_arid;
wire [7:0]      x_arlen;
wire [1:0]      x_arburst;
wire [2:0]      x_arsize;

wire            x_rvalid;
wire            x_rready;
wire [63:0]     x_rdata;
wire [1:0]      x_rresp;
wire [TAGW-1:0] x_rid;
wire            x_rlast;

wire            x_awvalid;
wire            x_awready;
wire [31:0]     x_awaddr;
wire [TAGW-1:0] x_awid;
wire [7:0]      x_awlen;
wire [1:0]      x_awburst;
wire [2:0]      x_awsize;

wire            x_wvalid;
wire            x_wready;
wire [63:0]     x_wdata;
wire [7:0]      x_wstrb;

wire            x_bvalid;
wire            x_bready;
wire [1:0]      x_bresp;
wire [3:0]      x_bid;

// lmem
assign w_arvalid = (araddr <  BOUNDARY1) ? arvalid : 1'b0;
assign w_araddr  = (araddr <  BOUNDARY1) ? araddr  : 32'b0;
assign w_arid    = (araddr <  BOUNDARY1) ? arid    : 4'b0;
assign w_arlen   = (araddr <  BOUNDARY1) ? arlen   : 8'b0;
assign w_arburst = (araddr <  BOUNDARY1) ? arburst : 2'b0;
assign w_arsize  = (araddr <  BOUNDARY1) ? arsize  : 3'b0;

assign w_rready  = (araddr <  BOUNDARY1) ? rready  : 1'b0;

assign w_awvalid = (araddr <  BOUNDARY1) ? awvalid : 1'b0;
assign w_awaddr  = (araddr <  BOUNDARY1) ? awaddr  : 32'b0;
assign w_awid    = (araddr <  BOUNDARY1) ? awid    : 4'b0;
assign w_awlen   = (araddr <  BOUNDARY1) ? awlen   : 8'b0;
assign w_awburst = (araddr <  BOUNDARY1) ? awburst : 2'b0;
assign w_awsize  = (araddr <  BOUNDARY1) ? awsize  : 3'b0;

assign w_wvalid  = (araddr <  BOUNDARY1) ? wvalid  : 1'b0;
assign w_wdata   = (araddr <  BOUNDARY1) ? wdata   : 64'b0;
assign w_wstrb   = (araddr <  BOUNDARY1) ? wstrb   : 8'b0;

assign w_bready  = (araddr <  BOUNDARY1) ? bready  : 1'b0;


// star
assign x_arvalid = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? arvalid : 1'b0;
assign x_araddr  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? araddr  : 32'b0;
assign x_arid    = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? arid    : 4'b0;
assign x_arlen   = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? arlen   : 8'b0;
assign x_arburst = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? arburst : 2'b0;
assign x_arsize  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? arsize  : 3'b0;

assign x_rready  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? rready  : 1'b0;

assign x_awvalid = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? awvalid : 1'b0;
assign x_awaddr  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? awaddr  : 32'b0;
assign x_awid    = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? awid    : 4'b0;
assign x_awlen   = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? awlen   : 8'b0;
assign x_awburst = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? awburst : 2'b0;
assign x_awsize  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? awsize  : 3'b0;

assign x_wvalid  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? wvalid  : 1'b0;
assign x_wdata   = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? wdata   : 64'b0;
assign x_wstrb   = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? wstrb   : 8'b0;

assign x_bready  = (araddr >= BOUNDARY1 && araddr < BOUNDARY2) ? bready  : 1'b0;



// Slave Channels
assign arready   = (araddr <  BOUNDARY1) ? w_arready : x_arready;

assign rvalid    = (araddr <  BOUNDARY1) ? w_rvalid  : x_rvalid ;
assign rdata     = (araddr <  BOUNDARY1) ? w_rdata   : x_rdata  ;
assign rresp     = (araddr <  BOUNDARY1) ? w_rresp   : x_rresp  ;
assign rid       = (araddr <  BOUNDARY1) ? w_rid     : x_rid    ;
assign rlast     = (araddr <  BOUNDARY1) ? w_rlast   : x_rlast  ;

assign awready   = (araddr <  BOUNDARY1) ? w_awready : x_awready;

assign wready    = (araddr <  BOUNDARY1) ? w_wready  : x_wready ;

assign bvalid    = (araddr <  BOUNDARY1) ? w_bvalid  : x_bvalid ;
assign bresp     = (araddr <  BOUNDARY1) ? w_bresp   : x_bresp  ;
assign bid       = (araddr <  BOUNDARY1) ? w_bid     : x_bid    ;

endmodule
`endif