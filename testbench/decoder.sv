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

axi_bus  lmem(
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

// axi_slv  uart(
//     .aclk(aclk),
//     .rst_l(rst_l),
//     .arvalid(u_arvalid),
//     .arready(u_arready),
//     .araddr(u_araddr),
//     .arid(u_arid),
//     .arlen(u_arlen),
//     .arburst(u_arburst),
//     .arsize(u_arsize),

//     .rvalid(u_rvalid),
//     .rready(u_rready),
//     .rdata(u_rdata),
//     .rresp(u_rresp),
//     .rid(u_rid),
//     .rlast(u_rlast),

//     .awvalid(u_awvalid),
//     .awready(u_awready),
//     .awaddr(u_awaddr),
//     .awid(u_awid),
//     .awlen(u_awlen),
//     .awburst(u_awburst),
//     .awsize(u_awsize),

//     .wdata(u_wdata),
//     .wstrb(u_wstrb),
//     .wvalid(u_wvalid),
//     .wready(u_wready),

//     .bvalid(u_bvalid),
//     .bready(u_bready),
//     .bresp(u_bresp),
//     .bid(u_bid)
// );

/*
uart_dpi 
    #(
        .UART_DPI_ADDR_WIDTH(32),
        // .tcp_port( 5678),
        // .port_name("UART DPI"),
        // .welcome_message("Welcome to the UART DPI simulated serial interface.\n\r"),
        // .character_timeout_clk_count(100),
        // parameter listen_on_local_addr_only = 1,
        // parameter receive_buffer_size  = (100 * 1024),
        // parameter transmit_buffer_size = (100 * 1024),

        // parameter print_informational_messages = 1,
        // TRACE_DATA = 0
    )
    uart_port
    ( 
        .wb_clk_i(aclk),
        .wb_rst_i(~rst_l), // There is no need to assert reset at the beginning.

        .wb_adr_i(u_awaddr), //[UART_DPI_ADDR_WIDTH-1:0] 
        .wb_dat_i(u_wdata[31:0]), //[UART_DPI_DATA_WIDTH-1:0]
        .wb_dat_o(u_rdata[31:0]), //[UART_DPI_DATA_WIDTH-1:0]

        .wb_we_i(u_awvalid),
        .wb_stb_i(1),
        .wb_cyc_i(1),
        .wb_ack_o(wb_ack_o),
        .wb_err_o(wb_err_o),
        .wb_sel_i(1), //[3:0]

        .int_o(int_o)  // UART interrupt request
    );

wire int_o;
wire wb_ack_o;
wire wb_err_o;
*/
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

// uart
wire            u_arvalid;
wire            u_arready;
wire [31:0]     u_araddr;
wire [TAGW-1:0] u_arid;
wire [7:0]      u_arlen;
wire [1:0]      u_arburst;
wire [2:0]      u_arsize;

wire            u_rvalid;
wire            u_rready;
wire [63:0]     u_rdata;
wire [1:0]      u_rresp;
wire [TAGW-1:0] u_rid;
wire            u_rlast;

wire            u_awvalid;
wire            u_awready;
wire [31:0]     u_awaddr;
wire [TAGW-1:0] u_awid;
wire [7:0]      u_awlen;
wire [1:0]      u_awburst;
wire [2:0]      u_awsize;

wire            u_wvalid;
wire            u_wready;
wire [63:0]     u_wdata;
wire [7:0]      u_wstrb;

wire            u_bvalid;
wire            u_bready;
wire [1:0]      u_bresp;
wire [3:0]      u_bid;

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


// uart
assign u_arvalid = (araddr >= BOUNDARY2) ? arvalid : 1'b0;
assign u_araddr  = (araddr >= BOUNDARY2) ? araddr  : 32'b0;
assign u_arid    = (araddr >= BOUNDARY2) ? arid    : 4'b0;
assign u_arlen   = (araddr >= BOUNDARY2) ? arlen   : 8'b0;
assign u_arburst = (araddr >= BOUNDARY2) ? arburst : 2'b0;
assign u_arsize  = (araddr >= BOUNDARY2) ? arsize  : 3'b0;

assign u_rready  = (araddr >= BOUNDARY2) ? rready  : 1'b0;

assign u_awvalid = (araddr >= BOUNDARY2) ? awvalid : 1'b0;
assign u_awaddr  = (araddr >= BOUNDARY2) ? {28'h0, awaddr[3:0]}  : 32'b0;
assign u_awid    = (araddr >= BOUNDARY2) ? awid    : 4'b0;
assign u_awlen   = (araddr >= BOUNDARY2) ? awlen   : 8'b0;
assign u_awburst = (araddr >= BOUNDARY2) ? awburst : 2'b0;
assign u_awsize  = (araddr >= BOUNDARY2) ? awsize  : 3'b0;

assign u_wvalid  = (araddr >= BOUNDARY2) ? wvalid  : 1'b0;
assign u_wdata   = (araddr >= BOUNDARY2) ? wdata   : 64'b0;
assign u_wstrb   = (araddr >= BOUNDARY2) ? wstrb   : 8'b0;

assign u_bready  = (araddr >= BOUNDARY2) ? bready  : 1'b0;


// Slave Channels
assign arready   = (araddr <  BOUNDARY1) ? w_arready : (araddr < BOUNDARY2) ? x_arready  : u_arready;

assign rvalid    = (araddr <  BOUNDARY1) ? w_rvalid  : (araddr < BOUNDARY2) ? x_rvalid   : u_rvalid;
assign rdata     = (araddr <  BOUNDARY1) ? w_rdata   : (araddr < BOUNDARY2) ? x_rdata    : u_rdata;
assign rresp     = (araddr <  BOUNDARY1) ? w_rresp   : (araddr < BOUNDARY2) ? x_rresp    : u_rresp;
assign rid       = (araddr <  BOUNDARY1) ? w_rid     : (araddr < BOUNDARY2) ? x_rid      : u_rid;
assign rlast     = (araddr <  BOUNDARY1) ? w_rlast   : (araddr < BOUNDARY2) ? x_rlast    : u_rlast;

assign awready   = (araddr <  BOUNDARY1) ? w_awready : (araddr < BOUNDARY2) ? x_awready  : u_awready;

assign wready    = (araddr <  BOUNDARY1) ? w_wready  : (araddr < BOUNDARY2) ? x_wready   : u_wready;

assign bvalid    = (araddr <  BOUNDARY1) ? w_bvalid  : (araddr < BOUNDARY2) ? x_bvalid   : u_bvalid;
assign bresp     = (araddr <  BOUNDARY1) ? w_bresp   : (araddr < BOUNDARY2) ? x_bresp    : u_bresp;
assign bid       = (araddr <  BOUNDARY1) ? w_bid     : (araddr < BOUNDARY2) ? x_bid      : u_bid;

endmodule
`endif