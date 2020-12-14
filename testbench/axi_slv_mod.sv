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
// module axi_slv_lite #(TAGW=1) (
// input                   aclk,
// input                   rst_l,
// input                   arvalid,
// output reg              arready,
// input [31:0]            araddr,
// input [TAGW-1:0]        arid,
// input [7:0]             arlen,
// input [1:0]             arburst,
// input [2:0]             arsize,

// output reg              rvalid,
// input                   rready,
// output reg [63:0]       rdata,
// output reg [1:0]        rresp,
// output reg [TAGW-1:0]   rid,
// output                  rlast,

// input                   awvalid,
// output                  awready,
// input [31:0]            awaddr,
// input [TAGW-1:0]        awid,
// input [7:0]             awlen,
// input [1:0]             awburst,
// input [2:0]             awsize,

// input [63:0]            wdata,
// input [7:0]             wstrb,
// input                   wvalid,
// output                  wready,

// output  reg             bvalid,
// input                   bready,
// output reg [1:0]        bresp,
// output reg [TAGW-1:0]   bid
// );

////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	demofull.v
//
// Project:	WB2AXIPSP: bus bridges and other odds and ends
//
// Purpose:	Demonstrate a formally verified AXI4 core with a (basic)
//		interface.  This interface is explained below.
//
// Performance: This core has been designed for a total throughput of one beat
//		per clock cycle.  Both read and write channels can achieve
//	this.  The write channel will also introduce two clocks of latency,
//	assuming no other latency from the master.  This means it will take
//	a minimum of 3+AWLEN clock cycles per transaction of (1+AWLEN) beats,
//	including both address and acknowledgment cycles.  The read channel
//	will introduce a single clock of latency, requiring 2+ARLEN cycles
//	per transaction of 1+ARLEN beats.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2019-2020, Gisselquist Technology, LLC
//
// This file is part of the WB2AXIP project.
//
// The WB2AXIP project contains free software and gateware, licensed under the
// Apache License, Version 2.0 (the "License").  You may not use this project,
// or this file, except in compliance with the License.  You may obtain a copy
// of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module demofull #(
	parameter integer C_S_AXI_ID_WIDTH	= 1,
	parameter integer C_S_AXI_DATA_WIDTH	= 30,
	parameter integer C_S_AXI_ADDR_WIDTH	= 30,
	// Some useful short-hand definitions
	localparam	AW = C_S_AXI_ADDR_WIDTH,
	localparam	DW = C_S_AXI_DATA_WIDTH,
	localparam	IW = C_S_AXI_ID_WIDTH,
	localparam	LSB = $clog2(C_S_AXI_DATA_WIDTH)-3,

	parameter [0:0]	OPT_NARROW_BURST = 1
	) (
		// Users to add ports here

		// A very basic protocol-independent peripheral interface
		// 1. A value will be written any time o_we is true
		// 2. A value will be read any time o_rd is true
		// 3. Such a slave might just as easily be written as:
		//
		//	always @(posedge S_AXI_ACLK)
		//	if (o_we)
		//	begin
		//	    for(k=0; k<C_S_AXI_DATA_WIDTH/8; k=k+1)
		//	    begin
		//		if (o_wstrb[k])
		//		mem[o_waddr[AW-1:LSB]][k*8+:8] <= o_wdata[k*8+:8]
		//	    end
		//	end
		//
		//	always @(posedge S_AXI_ACLK)
		//	if (o_rd)
		//		i_rdata <= mem[o_raddr[AW-1:LSB]];
		//
		// 4. The rule on the input is that i_rdata must be registered,
		//    and that it must only change if o_rd is true.  Violating
		//    this rule will cause this core to violate the AXI
		//    protocol standard, as this value is not registered within
		//    this core
		output	reg					o_we,
		output	reg	[C_S_AXI_ADDR_WIDTH-LSB-1:0]	o_waddr,
		output	reg	[C_S_AXI_DATA_WIDTH-1:0]	o_wdata,
		output	reg	[C_S_AXI_DATA_WIDTH/8-1:0]	o_wstrb,
		//
		output	reg					o_rd,
		output	reg	[C_S_AXI_ADDR_WIDTH-LSB-1:0]	o_raddr,
		input	wire	[C_S_AXI_DATA_WIDTH-1:0]	i_rdata,
		//
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write Address ID
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
		// Write address
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of
		// transfers in a burst
		input wire [7 : 0] S_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer
		// in the burst
		input wire [2 : 0] S_AXI_AWSIZE,
		// Burst type. The burst type and the size information,
		// determine how the address for each transfer within the burst
		// is calculated.
		input wire [1 : 0] S_AXI_AWBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		input wire  S_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		input wire [3 : 0] S_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each
		// write transaction.
		input wire [3 : 0] S_AXI_AWQOS,
		// Region identifier. Permits a single physical interface
		// on a slave to be used for multiple logical interfaces.
		// Write address valid. This signal indicates that
		// the channel is signaling valid write address and
		// control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that
		// the slave is ready to accept an address and associated
		// control signals.
		output wire  S_AXI_AWREADY,
		// Write Data
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte
		// lanes hold valid data. There is one write strobe
		// bit for each eight bits of the write data bus.
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write last. This signal indicates the last transfer
		// in a write burst.
		input wire  S_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
		// Write valid. This signal indicates that valid write
		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Response ID tag. This signal is the ID tag of the
		// write response.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
		// Write response. This signal indicates the status
		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Optional User-defined signal in the write response channel.
		// Write response valid. This signal indicates that the
		// channel is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address ID. This signal is the identification
		// tag for the read address group of signals.
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
		// Read address. This signal indicates the initial
		// address of a read burst transaction.
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of
		// transfers in a burst
		input wire [7 : 0] S_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer
		// in the burst
		input wire [2 : 0] S_AXI_ARSIZE,
		// Burst type. The burst type and the size information,
		// determine how the address for each transfer within the
		// burst is calculated.
		input wire [1 : 0] S_AXI_ARBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		input wire  S_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		input wire [3 : 0] S_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each
		// read transaction.
		input wire [3 : 0] S_AXI_ARQOS,
		// Region identifier. Permits a single physical interface
		// on a slave to be used for multiple logical interfaces.
		// Optional User-defined signal in the read address channel.
		// Write address valid. This signal indicates that
		// the channel is signaling valid read address and
		// control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that
		// the slave is ready to accept an address and associated
		// control signals.
		output wire  S_AXI_ARREADY,
		// Read ID tag. This signal is the identification tag
		// for the read data group of signals generated by the slave.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
		// Read Data
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of
		// the read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read last. This signal indicates the last transfer
		// in a read burst.
		output wire  S_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
		// Read valid. This signal indicates that the channel
		// is signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// Double buffer the write response channel only
	reg	[IW-1 : 0]	r_bid;
	reg			r_bvalid;
	reg	[IW-1 : 0]	axi_bid;
	reg			axi_bvalid;

	reg			axi_awready, axi_wready;
	reg	[AW-1:0]	waddr;
	wire	[AW-1:0]	next_wr_addr;

	// Vivado will warn about wlen only using 4-bits.  This is
	// to be expected, since the axi_addr module only needs to use
	// the bottom four bits of wlen to determine address increments
	reg	[7:0]		wlen;
	// Vivado will also warn about the top bit of wsize being unused.
	// This is also to be expected for a DATA_WIDTH of 32-bits.
	reg	[2:0]		wsize;
	reg	[1:0]		wburst;

	////////////////////////////////////////////////////////////////////////
	//
	// Skid buffer
	//
	wire			m_awvalid;
	reg			m_awready;
	wire	[AW-1:0]	m_awaddr;
	wire	[1:0]		m_awburst;
	wire	[2:0]		m_awsize;
	wire	[7:0]		m_awlen;
	wire	[IW-1:0]	m_awid;
	//
	skidbuffer #(.DW(AW+2+3+8+IW), .OPT_OUTREG(1'b0))
		awbuf(S_AXI_ACLK, !S_AXI_ARESETN,
		S_AXI_AWVALID, S_AXI_AWREADY,
			{ S_AXI_AWADDR, S_AXI_AWBURST, S_AXI_AWSIZE,
					S_AXI_AWLEN, S_AXI_AWID },
		m_awvalid, m_awready,
			{ m_awaddr, m_awburst, m_awsize, m_awlen, m_awid });

	////////////////////////////////////////////////////////////////////////
	//
	// Write processing
	//

	wire	[AW-1:0]	next_rd_addr;
	reg	[IW-1:0]	axi_rid;
	reg	[DW-1:0]	axi_rdata;

	initial	axi_awready = 1;
	initial	axi_wready  = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
	begin
		axi_awready  <= 1;
		axi_wready   <= 0;
	end else if (m_awvalid && m_awready)
	begin
		axi_awready <= 0;
		axi_wready  <= 1;
	end else if (S_AXI_WVALID && S_AXI_WREADY)
	begin
		axi_awready <= (S_AXI_WLAST)&&(!S_AXI_BVALID || S_AXI_BREADY);
		axi_wready  <= (!S_AXI_WLAST);
	end else if (!axi_awready)
	begin
		if (S_AXI_WREADY)
			axi_awready <= 1'b0;
		else if (r_bvalid && !S_AXI_BREADY)
			axi_awready <= 1'b0;
		else
			axi_awready <= 1'b1;
	end

	always @(posedge S_AXI_ACLK)
	if (m_awready)
	begin
		waddr    <= m_awaddr;
		wburst   <= m_awburst;
		wsize    <= m_awsize;
		wlen     <= m_awlen;
	end else if (S_AXI_WVALID)
		waddr <= next_wr_addr;

	axi_addr #(.AW(AW), .DW(DW))
		get_next_wr_addr(waddr, wsize, wburst, wlen,
			next_wr_addr);

	always @(*)
	begin
		o_we = (S_AXI_WVALID && S_AXI_WREADY);
		o_waddr = waddr[AW-1:LSB];
		o_wdata = S_AXI_WDATA;
		o_wstrb = S_AXI_WSTRB;
	end

	initial	r_bvalid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		r_bvalid <= 1'b0;
	else if (S_AXI_WVALID && S_AXI_WREADY && S_AXI_WLAST
			&&(S_AXI_BVALID && !S_AXI_BREADY))
		r_bvalid <= 1'b1;
	else if (S_AXI_BREADY)
		r_bvalid <= 1'b0;

	always @(posedge S_AXI_ACLK)
	begin
		if (m_awready)
			r_bid    <= m_awid;

		if (!S_AXI_BVALID || S_AXI_BREADY)
			axi_bid <= r_bid;
	end

	initial	axi_bvalid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		axi_bvalid <= 0;
	else if (S_AXI_WVALID && S_AXI_WREADY && S_AXI_WLAST)
		axi_bvalid <= 1;
	else if (S_AXI_BREADY)
		axi_bvalid <= r_bvalid;

	always @(*)
	begin
		m_awready = axi_awready;
		if (S_AXI_WVALID && S_AXI_WREADY && S_AXI_WLAST
			&& (!S_AXI_BVALID || S_AXI_BREADY))
			m_awready = 1;
	end

	// At one time, axi_awready was the same as S_AXI_AWREADY.  Now, though,
	// with the extra write address skid buffer, this is no longer the case.
	// S_AXI_AWREADY is handled/created/managed by the skid buffer.
	//
	// assign S_AXI_AWREADY = axi_awready;
	//
	// The rest of these signals can be set according to their registered
	// values above.
	assign	S_AXI_WREADY  = axi_wready;
	assign	S_AXI_BVALID  = axi_bvalid;
	assign	S_AXI_BID     = axi_bid;
	//
	// This core does not produce any bus errors, nor does it support
	// exclusive access, so 2'b00 will always be the correct response.
	assign	S_AXI_BRESP = 0;

	////////////////////////////////////////////////////////////////////////
	//
	// Read half
	//
	// Vivado will warn about rlen only using 4-bits.  This is
	// to be expected, since for a DATA_WIDTH of 32-bits, the axi_addr
	// module only uses the bottom four bits of rlen to determine
	// address increments
	reg	[7:0]		rlen;
	// Vivado will also warn about the top bit of wsize being unused.
	// This is also to be expected for a DATA_WIDTH of 32-bits.
	reg	[2:0]		rsize;
	reg	[1:0]		rburst;
	reg	[IW-1:0]	rid;
	reg			axi_arready, axi_rlast, axi_rvalid;
	reg	[8:0]		axi_rlen;
	reg	[AW-1:0]	raddr;

	initial axi_arready = 1;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		axi_arready <= 1;
	else if (S_AXI_ARVALID && S_AXI_ARREADY)
		axi_arready <= (S_AXI_ARLEN==0)&&(o_rd);
	else if (!S_AXI_RVALID || S_AXI_RREADY)
	begin
		if ((!axi_arready)&&(S_AXI_RVALID))
			axi_arready <= (axi_rlen <= 2);
	end

	initial	axi_rlen = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		axi_rlen <= 0;
	else if (S_AXI_ARVALID && S_AXI_ARREADY)
		axi_rlen <= (S_AXI_ARLEN+1)
				+ ((S_AXI_RVALID && !S_AXI_RREADY) ? 1:0);
	else if (S_AXI_RREADY && S_AXI_RVALID)
		axi_rlen <= axi_rlen - 1;

	always @(posedge S_AXI_ACLK)
	if (o_rd)
		raddr <= next_rd_addr;
	else if (S_AXI_ARREADY)
		raddr <= S_AXI_ARADDR;

	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARREADY)
	begin
		rburst   <= S_AXI_ARBURST;
		rsize    <= S_AXI_ARSIZE;
		rlen     <= S_AXI_ARLEN;
		rid      <= S_AXI_ARID;
	end

	axi_addr #(.AW(AW), .DW(DW))
		get_next_rd_addr((S_AXI_ARREADY ? S_AXI_ARADDR : raddr),
				(S_AXI_ARREADY  ? S_AXI_ARSIZE : rsize),
				(S_AXI_ARREADY  ? S_AXI_ARBURST: rburst),
				(S_AXI_ARREADY  ? S_AXI_ARLEN  : rlen),
				next_rd_addr);

	always @(*)
	begin
		o_rd = (S_AXI_ARVALID || !S_AXI_ARREADY);
		if (S_AXI_RVALID && !S_AXI_RREADY)
			o_rd = 0;
		o_raddr = (S_AXI_ARREADY ? S_AXI_ARADDR[AW-1:LSB] : raddr[AW-1:LSB]);
	end

	initial	axi_rvalid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		axi_rvalid <= 0;
	else if (o_rd)
		axi_rvalid <= 1;
	else if (S_AXI_RREADY)
		axi_rvalid <= 0;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_RVALID || S_AXI_RREADY)
	begin
		if (S_AXI_ARVALID && S_AXI_ARREADY)
			axi_rid <= S_AXI_ARID;
		else
			axi_rid <= rid;
	end

	initial axi_rlast   = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_RVALID || S_AXI_RREADY)
	begin
		if (S_AXI_ARVALID && S_AXI_ARREADY)
			axi_rlast <= (S_AXI_ARLEN == 0);
		else if (S_AXI_RVALID)
			axi_rlast <= (axi_rlen == 2);
		else
			axi_rlast <= (axi_rlen == 1);
	end

	always @(*)
		axi_rdata = i_rdata;

	//
	assign	S_AXI_ARREADY = axi_arready;
	assign	S_AXI_RVALID  = axi_rvalid;
	assign	S_AXI_RID     = axi_rid;
	assign	S_AXI_RDATA   = axi_rdata;
	assign	S_AXI_RRESP   = 0;
	assign	S_AXI_RLAST   = axi_rlast;
	//

	// Make Verilator happy
	// Verilator lint_off UNUSED
	wire	[23:0]	unused;
	assign	unused = { S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT,
			S_AXI_AWQOS,
		S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS };
	// Verilator lint_on  UNUSED

`ifdef	FORMAL
	//
	// The following properties are only some of the properties used
	// to verify this core
	//
	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge S_AXI_ACLK)
		f_past_valid <= 1;

	always @(*)
	if (!f_past_valid)
		assume(!S_AXI_ARESETN);

	faxi_slave	#(
		// {{{
		.C_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH))
		// ...
		// }}}
	f_slave(
		// {{{
		.i_clk(S_AXI_ACLK),
		.i_axi_reset_n(S_AXI_ARESETN),
		//
		// Address write channel
		//
		.i_axi_awvalid(m_awvalid),
		.i_axi_awready(m_awready),
		.i_axi_awid(   m_awid),
		.i_axi_awaddr( m_awaddr),
		.i_axi_awlen(  m_awlen),
		.i_axi_awsize( m_awsize),
		.i_axi_awburst(m_awburst),
		.i_axi_awlock( 1'b0),
		.i_axi_awcache(4'h0),
		.i_axi_awprot( 3'h0),
		.i_axi_awqos(  4'h0),
	//
	//
		//
		// Write Data Channel
		//
		// Write Data
		.i_axi_wdata(S_AXI_WDATA),
		.i_axi_wstrb(S_AXI_WSTRB),
		.i_axi_wlast(S_AXI_WLAST),
		.i_axi_wvalid(S_AXI_WVALID),
		.i_axi_wready(S_AXI_WREADY),
	//
	//
		// Response ID tag. This signal is the ID tag of the
		// write response.
		.i_axi_bvalid(S_AXI_BVALID),
		.i_axi_bready(S_AXI_BREADY),
		.i_axi_bid(   S_AXI_BID),
		.i_axi_bresp( S_AXI_BRESP),
	//
	//
		//
		// Read address channel
		//
		.i_axi_arvalid(S_AXI_ARVALID),
		.i_axi_arready(S_AXI_ARREADY),
		.i_axi_arid(   S_AXI_ARID),
		.i_axi_araddr( S_AXI_ARADDR),
		.i_axi_arlen(  S_AXI_ARLEN),
		.i_axi_arsize( S_AXI_ARSIZE),
		.i_axi_arburst(S_AXI_ARBURST),
		.i_axi_arlock( S_AXI_ARLOCK),
		.i_axi_arcache(S_AXI_ARCACHE),
		.i_axi_arprot( S_AXI_ARPROT),
		.i_axi_arqos(  S_AXI_ARQOS),
	//
	//
		//
		// Read data return channel
		//
		.i_axi_rvalid(S_AXI_RVALID),
		.i_axi_rready(S_AXI_RREADY),
		.i_axi_rid(S_AXI_RID),
		.i_axi_rdata(S_AXI_RDATA),
		.i_axi_rresp(S_AXI_RRESP),
		.i_axi_rlast(S_AXI_RLAST),
		//
		// ...
		// }}}
	);

	//

	////////////////////////////////////////////////////////////////////////
	//
	// Write induction properties
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{


	//
	// ...
	//

	always @(*)
	if (r_bvalid)
		assert(S_AXI_BVALID);

	always @(*)
		assert(axi_awready == (!S_AXI_WREADY&& !r_bvalid));

	always @(*)
	if (axi_awready)
		assert(!S_AXI_WREADY);


	//
	// ...
	//

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Read induction properties
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	//
	// ...
	//

	always @(posedge S_AXI_ACLK)
	if (f_past_valid && $rose(S_AXI_RLAST))
		assert(S_AXI_ARREADY);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Contract checking
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	//
	// ...
	//

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Cover properties
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{
	reg	f_wr_cvr_valid, f_rd_cvr_valid;

	initial	f_wr_cvr_valid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		f_wr_cvr_valid <= 0;
	else if (S_AXI_AWVALID && S_AXI_AWREADY && S_AXI_AWLEN > 4)
		f_wr_cvr_valid <= 1;

	always @(*)
		cover(!S_AXI_BVALID && axi_awready && !m_awvalid
			&& f_wr_cvr_valid /* && ... */));

	initial	f_rd_cvr_valid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		f_rd_cvr_valid <= 0;
	else if (S_AXI_ARVALID && S_AXI_ARREADY && S_AXI_ARLEN > 4)
		f_rd_cvr_valid <= 1;

	always @(*)
		cover(S_AXI_ARREADY && f_rd_cvr_valid /* && ... */);

	//
	// Generate cover statements associated with multiple successive bursts
	//
	// These will be useful for demonstrating the throughput of the core.
	//
	reg	[4:0]	f_dbl_rd_count, f_dbl_wr_count;

	initial	f_dbl_wr_count = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		f_dbl_wr_count = 0;
	else if (S_AXI_AWVALID && S_AXI_AWREADY && S_AXI_AWLEN == 3)
	begin
		if (!(&f_dbl_wr_count))
			f_dbl_wr_count <= f_dbl_wr_count + 1;
	end

	always @(*)
		cover(S_AXI_ARESETN && (f_dbl_wr_count > 1));	//!

	always @(*)
		cover(S_AXI_ARESETN && (f_dbl_wr_count > 3));	//!

	always @(*)
		cover(S_AXI_ARESETN && (f_dbl_wr_count > 3) && !m_awvalid
			&&(!S_AXI_AWVALID && !S_AXI_WVALID && !S_AXI_BVALID)
			&& (f_axi_awr_nbursts == 0)
			&& (f_axi_wr_pending == 0));	//!!

	initial	f_dbl_rd_count = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		f_dbl_rd_count = 0;
	else if (S_AXI_ARVALID && S_AXI_ARREADY && S_AXI_ARLEN == 3)
	begin
		if (!(&f_dbl_rd_count))
			f_dbl_rd_count <= f_dbl_rd_count + 1;
	end

	always @(*)
		cover(!S_AXI_ARESETN && (f_dbl_rd_count > 3)
			/* && ... */
			&& !S_AXI_ARVALID && !S_AXI_RVALID);

`ifdef	VERIFIC
	cover property (@(posedge S_AXI_ACLK)
		disable iff (!S_AXI_ARESETN)
		// Accept a burst request for 4 beats
		S_AXI_ARVALID && S_AXI_ARREADY && (S_AXI_ARLEN == 3)
		// The first three beats
		##1 S_AXI_RVALID && S_AXI_RREADY [*3]
		// The last read beat, where we accept the next request
		##1 S_AXI_ARVALID && S_AXI_ARREADY && (S_AXI_ARLEN == 3)
			&& S_AXI_RVALID && S_AXI_RDATA && S_AXI_RLAST
		// The next three beats of data, and
		##1 S_AXI_RVALID && S_AXI_RREADY [*3]
		// The final beat of the transaction
		##1 S_AXI_RVALID && S_AXI_RDATA && S_AXI_RLAST
		// The return to idle
		##1 !S_AXI_RVALID && !S_AXI_ARVALID);
`endif
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Assumptions necessary to pass a formal check
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(posedge S_AXI_ACLK)
	if (S_AXI_RVALID && !$past(o_rd))
		assume($stable(i_rdata));

`endif
endmodule

 module dumb_slave #(
	parameter integer C_S_AXI_ID_WIDTH	= 1,
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	parameter integer C_S_AXI_ADDR_WIDTH	= 32,
	// Some useful short-hand definitions
	localparam	AW = C_S_AXI_ADDR_WIDTH,
	localparam	DW = C_S_AXI_DATA_WIDTH,
	localparam	IW = C_S_AXI_ID_WIDTH,
	localparam	LSB = $clog2(C_S_AXI_DATA_WIDTH)-3,

	parameter [0:0]	OPT_NARROW_BURST = 1
	) (
 // Users to add ports here

    // A very basic protocol-independent peripheral interface
    // 1. A value will be written any time o_we is true
    // 2. A value will be read any time o_rd is true
    // 3. Such a slave might just as easily be written as:
    //
    //	always @(posedge S_AXI_ACLK)
    //	if (o_we)
    //	begin
    //	    for(k=0; k<C_S_AXI_DATA_WIDTH/8; k=k+1)
    //	    begin
    //		if (o_wstrb[k])
    //		mem[o_waddr[AW-1:LSB]][k*8+:8] <= o_wdata[k*8+:8]
    //	    end
    //	end
    //
    //	always @(posedge S_AXI_ACLK)
    //	if (o_rd)
    //		i_rdata <= mem[o_raddr[AW-1:LSB]];
    //
    // 4. The rule on the input is that i_rdata must be registered,
    //    and that it must only change if o_rd is true.  Violating
    //    this rule will cause this core to violate the AXI
    //    protocol standard, as this value is not registered within
    //    this core
    input   wire  S_AXI_ACLK,
    input   wire     i_we,
    input   wire     [C_S_AXI_ADDR_WIDTH-LSB-1:0]	i_waddr,
    input   wire     [C_S_AXI_DATA_WIDTH-1:0]	    i_wdata,
    input   wire     [C_S_AXI_DATA_WIDTH/8-1:0]	    i_wstrb,
    //
    input   wire     i_rd,
    input   wire     [C_S_AXI_ADDR_WIDTH-LSB-1:0]	i_raddr,
    output  reg     [C_S_AXI_DATA_WIDTH-1:0]	    o_rdata
);

    always @(posedge S_AXI_ACLK) begin 
        if (i_we) begin
            for(int k=0; k<C_S_AXI_DATA_WIDTH/8; k=k+1) begin
                if (i_wstrb[k]) begin
                    //mem[i_waddr[AW-1:LSB]][k*8+:8] <= i_wdata[k*8+:8];
                end
            end
        end
    end

    always @(posedge S_AXI_ACLK)
    if (i_rd)
        //o_rdata <= mem[i_raddr[AW-1:LSB]];
        //o_rdata <= 64'hFEEDBEEFDEADBABE;
		o_rdata <= "@";

endmodule
`endif

module	axi_addr #(
		// {{{
		parameter	AW = 32,
				DW = 32,
		parameter [0:0]	OPT_AXI3 = 1'b0,
		localparam	LENB = 8
		// }}}
	) (
		// {{{
		input	wire	[AW-1:0]	i_last_addr,
		input	wire	[2:0]		i_size, // 1b, 2b, 4b, 8b, etc
		input	wire	[1:0]		i_burst, // fixed, incr, wrap, reserved
		input	wire	[LENB-1:0]	i_len,
		output	reg	[AW-1:0]	o_next_addr
		// }}}
	);

	// Parameter/register declarations
	// {{{
	localparam		DSZ = $clog2(DW)-3;
	localparam [1:0]	FIXED     = 2'b00;
	localparam [1:0]	INCREMENT = 2'b01;
	localparam [1:0]	WRAP      = 2'b10;

	reg	[AW-1:0]	wrap_mask, increment;
	// }}}

	// Address increment
	// {{{
	always @(*)
	begin
		increment = 0;
		if (i_burst != 0)
		begin
			// Addresses increment from one beat to the next
			// {{{
			if (DSZ == 0)
				increment = 1;
			else if (DSZ == 1)
				increment = (i_size[0]) ? 2 : 1;
			else if (DSZ == 2)
				increment = (i_size[1]) ? 4 : ((i_size[0]) ? 2 : 1);
			else if (DSZ == 3)
				case(i_size[1:0])
				2'b00: increment = 1;
				2'b01: increment = 2;
				2'b10: increment = 4;
				2'b11: increment = 8;
				endcase
			else
				increment = (1<<i_size);
			// }}}
		end
	end
	// }}}

	// wrap_mask
	// {{{
	// The wrap_mask is used to determine which bits remain stable across
	// the burst, and which are allowed to change.  It is only used during
	// wrapped addressing.
	always @(*)
	begin
		// Start with the default, minimum mask
		wrap_mask = 1;

		/*
		// Here's the original code.  It works, but it's
		// not economical (uses too many LUTs)
		//
		if (i_len[3:0] == 1)
			wrap_mask = (1<<(i_size+1));
		else if (i_len[3:0] == 3)
			wrap_mask = (1<<(i_size+2));
		else if (i_len[3:0] == 7)
			wrap_mask = (1<<(i_size+3));
		else if (i_len[3:0] == 15)
			wrap_mask = (1<<(i_size+4));
		wrap_mask = wrap_mask - 1;
		*/

		// Here's what we *want*
		//
		// wrap_mask[i_size:0] = -1;
		//
		// On the other hand, since we're already guaranteed that our
		// addresses are aligned, do we really care about
		// wrap_mask[i_size-1:0] ?

		// What we want:
		//
		// wrap_mask[i_size+3:i_size] |= i_len[3:0]
		//
		// We could simplify this to
		//
		// wrap_mask = wrap_mask | (i_len[3:0] << (i_size));
		//
		// But verilator complains about the left-hand side of
		// the shift having only 3 bits.
		//
		if (DSZ < 2)
			wrap_mask = wrap_mask | ({{(AW-4){1'b0}},i_len[3:0]} << (i_size[0]));
		else if (DSZ < 4)
			wrap_mask = wrap_mask | ({{(AW-4){1'b0}},i_len[3:0]} << (i_size[1:0]));
		else
			wrap_mask = wrap_mask | ({{(AW-4){1'b0}},i_len[3:0]} << (i_size));

		if (AW > 12)
			wrap_mask[((AW>12)?(AW-1):(AW-1)):((AW>12)?12:(AW-1))] = 0;
	end
	// }}}

	// o_next_addr
	// {{{
	always @(*)
	begin
		o_next_addr = i_last_addr + increment;
		if (i_burst != FIXED)
		begin
			// Align subsequent beats in any burst
			// {{{
			//
			// We use the bus size here to simplify the logic
			// required in case the bus is smaller than the
			// maximum.  This depends upon AxSIZE being less than
			// $clog2(DATA_WIDTH/8).
			if (DSZ < 2)
			begin
				// {{{
				// Align any subsequent address
				if (i_size[0])
					o_next_addr[0] = 0;
				// }}}
			end else if (DSZ < 4)
			begin
				// {{{
				// Align any subsequent address
				case(i_size[1:0])
				2'b00:  o_next_addr = o_next_addr;
				2'b01:  o_next_addr[  0] = 0;
				2'b10:  o_next_addr[(AW-1>1) ? 1 : (AW-1):0]= 0;
				2'b11:  o_next_addr[(AW-1>2) ? 2 : (AW-1):0]= 0;
				endcase
				// }}}
			end else begin
				// {{{
				// Align any subsequent address
				case(i_size)
				3'b001:  o_next_addr[  0] = 0;
				3'b010:  o_next_addr[(AW-1>1) ? 1 : (AW-1):0]=0;
				3'b011:  o_next_addr[(AW-1>2) ? 2 : (AW-1):0]=0;
				3'b100:  o_next_addr[(AW-1>3) ? 3 : (AW-1):0]=0;
				3'b101:  o_next_addr[(AW-1>4) ? 4 : (AW-1):0]=0;
				3'b110:  o_next_addr[(AW-1>5) ? 5 : (AW-1):0]=0;
				3'b111:  o_next_addr[(AW-1>6) ? 6 : (AW-1):0]=0;
				default: o_next_addr = o_next_addr;
				endcase
				// }}}
			end
			// }}}
		end

		// WRAP addressing
		// {{{
		if (i_burst[1])
		begin
			// WRAP!
			o_next_addr[AW-1:0] = (i_last_addr & ~wrap_mask)
					| (o_next_addr & wrap_mask);
		end
		// }}}

		// Guarantee only the bottom 12 bits change
		// {{{
		// This is really a logic simplification.  AXI bursts aren't
		// allowed to cross 4kB boundaries.  Given that's the case,
		// we don't have to suffer from the propagation across all
		// AW bits, and can limit any address propagation to just the
		// lower 12 bits
		if (AW > 12)
			o_next_addr[AW-1:((AW>12)? 12:(AW-1))]
				= i_last_addr[AW-1:((AW>12) ? 12:(AW-1))];
		// }}}
	end
	// }}}

	// Make Verilator happy
	// {{{
	// Verilator lint_off UNUSED
	// wire	unused;
	// assign	unused = (LENB <= 4) ? {1'b0, i_len[0] }
	// 			: &{ 1'b0, i_len[LENB-1:4], i_len[0] };
	// Verilator lint_on UNUSED
	// }}}
endmodule


module skidbuffer #(
		// {{{
		parameter	[0:0]	OPT_LOWPOWER = 0,
		parameter	[0:0]	OPT_OUTREG = 1,
		//
		parameter	[0:0]	OPT_PASSTHROUGH = 0,
		parameter		DW = 8
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_reset,
		input	wire			i_valid,
		output	reg			o_ready,
		input	wire	[DW-1:0]	i_data,
		output	reg			o_valid,
		input	wire			i_ready,
		output	reg	[DW-1:0]	o_data
		// }}}
	);

	reg	[DW-1:0]	r_data;

	generate if (OPT_PASSTHROUGH)
	begin : PASSTHROUGH
		// {{{
		always @(*)
			o_ready = i_ready;
		always @(*)
			o_valid = i_valid;
		always @(*)
		if (!i_valid && OPT_LOWPOWER)
			o_data = 0;
		else
			o_data = i_data;

		always @(*)
			r_data = 0;
		// }}}
	end else begin : LOGIC
		// We'll start with skid buffer itself
		// {{{
		reg			r_valid;

		// r_valid
		// {{{
		initial	r_valid = 0;
		always @(posedge i_clk)
		if (i_reset)
			r_valid <= 0;
		else if ((i_valid && o_ready) && (o_valid && !i_ready))
			// We have incoming data, but the output is stalled
			r_valid <= 1;
		else if (i_ready)
			r_valid <= 0;
		// }}}

		// r_data
		// {{{
		initial	r_data = 0;
		always @(posedge i_clk)
		if (OPT_LOWPOWER && i_reset)
			r_data <= 0;
		else if (OPT_LOWPOWER && (!o_valid || i_ready))
			r_data <= 0;
		else if ((!OPT_LOWPOWER || !OPT_OUTREG || i_valid) && o_ready)
			r_data <= i_data;
		// }}}

		// o_ready
		// {{{
		always @(*)
			o_ready = !r_valid;
		// }}}

		//
		// And then move on to the output port
		//
		if (!OPT_OUTREG)
		begin : NET_OUTPUT
			// Outputs are combinatorially determined from inputs
			// {{{
			// o_valid
			// {{{
			always @(*)
				o_valid = !i_reset && (i_valid || r_valid);
			// }}}

			// o_data
			// {{{
			always @(*)
			if (r_valid)
				o_data = r_data;
			else if (!OPT_LOWPOWER || i_valid)
				o_data = i_data;
			else
				o_data = 0;
			// }}}
			// }}}
		end else begin : REG_OUTPUT
			// Register our outputs
			// {{{
			// o_valid
			// {{{
			initial	o_valid = 0;
			always @(posedge i_clk)
			if (i_reset)
				o_valid <= 0;
			else if (!o_valid || i_ready)
				o_valid <= (i_valid || r_valid);
			// }}}

			// o_data
			// {{{
			initial	o_data = 0;
			always @(posedge i_clk)
			if (OPT_LOWPOWER && i_reset)
				o_data <= 0;
			else if (!o_valid || i_ready)
			begin

				if (r_valid)
					o_data <= r_data;
				else if (!OPT_LOWPOWER || i_valid)
					o_data <= i_data;
				else
					o_data <= 0;
			end
			// }}}

			// }}}
		end
		// }}}
	end endgenerate

`ifdef	FORMAL
`ifdef	VERIFIC
`define	FORMAL_VERIFIC
`endif
`endif
//
`ifdef	FORMAL_VERIFIC
	// Reset properties
	property RESET_CLEARS_IVALID;
		@(posedge i_clk) i_reset |=> !i_valid;
	endproperty

	property IDATA_HELD_WHEN_NOT_READY;
		@(posedge i_clk) disable iff (i_reset)
		i_valid && !o_ready |=> i_valid && $stable(i_data);
	endproperty

`ifdef	SKIDBUFFER
	assume	property (IDATA_HELD_WHEN_NOT_READY);
`else
	assert	property (IDATA_HELD_WHEN_NOT_READY);
`endif

	generate if (!OPT_PASSTHROUGH)
	begin

		assert property (@(posedge i_clk)
			OPT_OUTREG && i_reset |=> o_ready && !o_valid);

		assert property (@(posedge i_clk)
			!OPT_OUTREG && i_reset |-> !o_valid);

		// Rule #1:
		//	Once o_valid goes high, the data cannot change until the
		//	clock after i_ready
		assert property (@(posedge i_clk)
			disable iff (i_reset)
			o_valid && !i_ready
			|=> (o_valid && $stable(o_data)));

		// Rule #2:
		//	All incoming data must either go directly to the
		//	output port, or into the skid buffer
		assert property (@(posedge i_clk)
			disable iff (i_reset)
			(i_valid && o_ready
				&& (!OPT_OUTREG || o_valid) && !i_ready)
				|=> (!o_ready && r_data == $past(i_data)));

		// Rule #3:
		//	After the last transaction, o_valid should become idle
		if (!OPT_OUTREG)
		begin

			assert property (@(posedge i_clk)
				disable iff (i_reset)
				i_ready |=> (o_valid == i_valid));

		end else begin

			assert property (@(posedge i_clk)
				disable iff (i_reset)
				i_valid && o_ready |=> o_valid);

			assert property (@(posedge i_clk)
				disable iff (i_reset)
				!i_valid && o_ready && i_ready |=> !o_valid);

		end

		// Rule #4
		//	Same thing, but this time for r_valid
		assert property (@(posedge i_clk)
			!o_ready && i_ready |=> o_ready);


		if (OPT_LOWPOWER)
		begin
			//
			// If OPT_LOWPOWER is set, o_data and r_data both need
			// to be zero any time !o_valid or !r_valid respectively
			assert property (@(posedge i_clk)
				(OPT_OUTREG || !i_reset) && !o_valid |-> o_data == 0);

			assert property (@(posedge i_clk)
				o_ready |-> r_data == 0);

			// else
			//	if OPT_LOWPOWER isn't set, we can lower our
			//	logic count by not forcing these values to zero.
		end

`ifdef	SKIDBUFFER
		reg	f_changed_data;

		// Cover test
		cover property (@(posedge i_clk)
			disable iff (i_reset)
			(!o_valid && !i_valid)
			##1 i_valid &&  i_ready [*3]
			##1 i_valid && !i_ready
			##1 i_valid &&  i_ready [*2]
			##1 i_valid && !i_ready [*2]
			##1 i_valid &&  i_ready [*3]
			// Wait for the design to clear
			##1 o_valid && i_ready [*0:5]
			##1 (!o_valid && !i_valid && f_changed_data));

		initial	f_changed_data = 0;
		always @(posedge i_clk)
		if (i_reset)
			f_changed_data <= 1;
		else if (i_valid && $past(!i_valid || o_ready))
		begin
			if (i_data != $past(i_data + 1))
				f_changed_data <= 0;
		end else if (!i_valid && i_data != 0)
			f_changed_data <= 0;

`endif	// SKIDCOVER
	end endgenerate

`endif	// FORMAL_VERIFIC
endmodule
`ifndef	YOSYS
`default_nettype wire
`endif