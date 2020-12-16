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
module axi_bus #(TAGW=1) (
input                   aclk,
input                   rst_l,
input                   arvalid,
output reg              arready,
input [31:0]            araddr,
input [TAGW-1:0]        arid,
input [7:0]             arlen,
input [1:0]             arburst,
input [2:0]             arsize,

output reg              rvalid,
input                   rready,
output reg [63:0]       rdata,
output reg [1:0]        rresp,
output reg [TAGW-1:0]   rid,
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

output  reg             bvalid,
input                   bready,
output reg [1:0]        bresp,
output reg [TAGW-1:0]   bid
);

parameter MAILBOX_ADDR = 32'hD0580000;
parameter UART_ADDR =    32'hC0000000;
parameter MEM_SIZE_DW = 8192;

bit [7:0] mem [bit[31:0]];
bit [63:0] memdata;
wire [63:0] WriteData;
wire mailbox_write;
wire uart_enable;


assign mailbox_write = awvalid && awaddr==MAILBOX_ADDR && rst_l;
assign uart_enable = (
        (awvalid && awaddr[31:28]==UART_ADDR[31:28]) ||
        (arvalid && araddr[31:28]==UART_ADDR[31:28])
        ) && rst_l;

assign WriteData = wdata;

always @ ( posedge aclk or negedge rst_l) begin
    if(!rst_l) begin
        rvalid  <= 0;
        bvalid  <= 0;
    end
    else begin
        bid     <= awid;
        rid     <= arid;
        rvalid  <= arvalid;
        bvalid  <= awvalid;
        rdata   <= memdata;
    end
end

wire uart_enable;
assign uart_enable = awvalid && awaddr[31:28]==UART_ADDR[31:28] && rst_l;

always @ ( negedge aclk) begin
    if(arvalid)
        if (!uart_enable) memdata <= {mem[araddr+7], mem[araddr+6], mem[araddr+5], mem[araddr+4],
                            mem[araddr+3], mem[araddr+2], mem[araddr+1], mem[araddr]};
        else
            memdata <= {32'h0,wb_dat_o};
    
    if(awvalid) begin
        if(wstrb[7]) mem[awaddr+7] = wdata[63:56];
        if(wstrb[6]) mem[awaddr+6] = wdata[55:48];
        if(wstrb[5]) mem[awaddr+5] = wdata[47:40];
        if(wstrb[4]) mem[awaddr+4] = wdata[39:32];
        if(wstrb[3]) mem[awaddr+3] = wdata[31:24];
        if(wstrb[2]) mem[awaddr+2] = wdata[23:16];
        if(wstrb[1]) mem[awaddr+1] = wdata[15:08];
        if(wstrb[0]) mem[awaddr+0] = wdata[07:00];
    end
end


assign arready = 1'b1;
assign awready = 1'b1;
assign wready  = 1'b1;
assign rresp   = 2'b0;
assign bresp   = 2'b0;
assign rlast   = 1'b1;


wire wb_we_i;
wire wb_stb_i;
wire wb_cyc_i;
wire wb_ack_o;
wire wb_err_o;
wire [31:0]wb_dat_o;
wire[3:0]wb_sel_i;

wire int_o;


uart_dpi 
    #(
        .UART_DPI_ADDR_WIDTH(32),
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

        .wb_adr_i({28'h0,araddr[3:0]}), //[UART_DPI_ADDR_WIDTH-1:0] 
        .wb_dat_i(wdata[31:0]), //[UART_DPI_DATA_WIDTH-1:0]
        .wb_dat_o(wb_dat_o), //[UART_DPI_DATA_WIDTH-1:0]

        .wb_we_i(awvalid),
        .wb_stb_i(uart_enable),
        .wb_cyc_i(1),
        .wb_ack_o(wb_ack_o),
        .wb_err_o(wb_err_o),
        .wb_sel_i(1), //[3:0]

        .int_o(int_o)  // UART interrupt request
    );

endmodule
`endif

