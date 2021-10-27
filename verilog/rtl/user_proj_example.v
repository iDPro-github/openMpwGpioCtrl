// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

//`default_nettype none
`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    // gpio interface
    wire            GPIO_WE;
    wire   [3:0]    GPIO_ADDR;
    wire   [31:0]   GPIO_DATA_IN;
    wire   [31:0]   GPIO_DATA_OUT;
    // RAM interface 1 (wishbone bus)
    wire            WB_RAM_CSb;
    wire            WB_RAM_WEb;
    wire    [7:0]   WB_RAM_ADDR;
    wire    [31:0]  WB_RAM_DATA_IN;
    wire    [31:0]  WB_RAM_DATA_OUT;
    // RAM interface 2 (gpio control)
    wire            GPIO_RAM_CSb;
    wire            GPIO_RAM_WEb;
    wire    [7:0]   GPIO_RAM_ADDR;
    wire    [31:0]  GPIO_RAM_DATA_IN;
    wire    [31:0]  GPIO_RAM_DATA_OUT;
    // open RAM
    wire            RAM_CSb[3:0];
    wire            RAM_WEb[3:0];
    wire    [4:0]   RAM_ADDR[3:0];
    wire    [7:0]   RAM_DATA_IN[3:0];
    wire    [7:0]   RAM_DATA_OUT[3:0];

    // IRQ
    assign irq = 3'b000;	// Unused

    // logic analyzer output signals
    assign la_data_out[0]       = GPIO_WE;
    assign la_data_out[1+:2]    = GPIO_ADDR[3:2];
    assign la_data_out[3+:32]   = GPIO_DATA_IN;
    assign la_data_out[35]      = RAM_CSb[0];
    assign la_data_out[36]      = RAM_WEb[0];
    assign la_data_out[37+:5]   = RAM_ADDR[0];
    assign la_data_out[42+:8]   = RAM_DATA_IN[0];
    assign la_data_out[50+:8]   = RAM_DATA_OUT[0];
    assign la_data_out[58]      = RAM_CSb[0];
    assign la_data_out[59]      = RAM_WEb[0];
    assign la_data_out[60+:5]   = RAM_ADDR[0];
    assign la_data_out[65+:8]   = RAM_DATA_IN[0];
    assign la_data_out[73+:8]  = RAM_DATA_OUT[0];
    assign la_data_out[81]     = RAM_CSb[0];
    assign la_data_out[82]     = RAM_WEb[0];
    assign la_data_out[83+:5]  = RAM_ADDR[0];
    assign la_data_out[88+:8]   = RAM_DATA_IN[0];
    assign la_data_out[96+:8]   = RAM_DATA_OUT[0];
    assign la_data_out[104]      = RAM_CSb[0];
    assign la_data_out[105]      = RAM_WEb[0];
    assign la_data_out[106+:5]   = RAM_ADDR[0];
    assign la_data_out[111+:8]   = RAM_DATA_IN[0];
    assign la_data_out[119+:8]   = RAM_DATA_OUT[0];
    // logic analyter input signals (unused)
    //la_data_in
    //la_oenb

    // wishbone slave interface
    wbSlave wbSlave_inst (
        // wishbone slave interface
        .CLK_I          (wb_clk_i),  // bus clock signal
        .RST_I          (wb_rst_i),  // bus reset signal
        .STB_I          (wbs_stb_i),  // bus transaction request
        .CYC_I          (wbs_cyc_i),  // active transaction
        .WE_I           (wbs_we_i),   // write request
        .SEL_I          (wbs_sel_i),  // byte select for request
        .DAT_I          (wbs_dat_i),  // data for request
        .ADR_I          (wbs_adr_i),  // address for request
        .ACK_O          (wbs_ack_o),  // request acknowledge, read data valid
        .DAT_O          (wbs_dat_o),  // requested read data
        .CTRL_WE        (GPIO_WE),
        .CTRL_ADDR      (GPIO_ADDR),
        .CTRL_DATA_IN   (GPIO_DATA_IN),
        .CTRL_DATA_OUT  (GPIO_DATA_OUT),
        .RAM_CSb        (WB_RAM_CSb),
        .RAM_WEb        (WB_RAM_WEb),
        .RAM_ADDR       (WB_RAM_ADDR),
        .RAM_DATA_IN    (WB_RAM_DATA_IN),
        .RAM_DATA_OUT   (WB_RAM_DATA_OUT)
    );

    // gpio control module
    gpioCtrl gpioCtrl_inst (
        // system
        .CLK            (wb_clk_i), 
        .RSTb           (!wb_rst_i),
        // control interface
        .CTRL_WE        (GPIO_WE),
        .CTRL_ADDR      (GPIO_ADDR),
        .CTRL_DATA_IN   (GPIO_DATA_IN),
        .CTRL_DATA_OUT  (GPIO_DATA_OUT),
        // caravel gpio signaling
        .GPIO_IN        (io_in),
        .GPIO_OUT       (io_out),
        .GPIO_OEb       (io_oeb),
        // RAM interface
        .RAM_CSb        (GPIO_RAM_CSb),
        .RAM_WEb        (GPIO_RAM_WEb),
        .RAM_ADDR       (GPIO_RAM_ADDR),
        .RAM_DATA_IN    (GPIO_RAM_DATA_IN),
        .RAM_DATA_OUT   (GPIO_RAM_DATA_OUT)
    );

    // ram arbiter
    ramArbiter ramArbiter_inst (
        // system
        .CLK            (CLK_I_tb),
        .RSTb           (!RST_I_tb),
        // ctrl interface 1
        .CTRL_CSb1      (WB_RAM_CSb),
        .CTRL_WEb1      (WB_RAM_WEb),
        .CTRL_ADDR1     (WB_RAM_ADDR),
        .CTRL_DATA_IN1  (WB_RAM_DATA_IN),
        .CTRL_DATA_OUT1 (WB_RAM_DATA_OUT),
        // ctrl interface 2
        .CTRL_CSb2      (GPIO_RAM_CSb),
        .CTRL_WEb2      (GPIO_RAM_WEb),
        .CTRL_ADDR2     (GPIO_RAM_ADDR),
        .CTRL_DATA_IN2  (GPIO_RAM_DATA_IN),
        .CTRL_DATA_OUT2 (GPIO_RAM_DATA_OUT),
        // RAM interface byte0
        .RAM_CSb0       (RAM_CSb[0]),
        .RAM_WEb0       (RAM_WEb[0]),
        .RAM_ADDR0      (RAM_ADDR[0]),
        .RAM_DATA_IN0   (RAM_DATA_IN[0]),
        .RAM_DATA_OUT0  (RAM_DATA_OUT[0]),
        // RAM interface byte1
        .RAM_CSb1       (RAM_CSb[1]),
        .RAM_WEb1       (RAM_WEb[1]),
        .RAM_ADDR1      (RAM_ADDR[1]),
        .RAM_DATA_IN1   (RAM_DATA_IN[1]),
        .RAM_DATA_OUT1  (RAM_DATA_OUT[1]),
        // RAM interface byte2
        .RAM_CSb2       (RAM_CSb[2]),
        .RAM_WEb2       (RAM_WEb[2]),
        .RAM_ADDR2      (RAM_ADDR[2]),
        .RAM_DATA_IN2   (RAM_DATA_IN[2]),
        .RAM_DATA_OUT2  (RAM_DATA_OUT[2]),
        // RAM interface byte3
        .RAM_CSb3       (RAM_CSb[3]),
        .RAM_WEb3       (RAM_WEb[3]),
        .RAM_ADDR3      (RAM_ADDR[3]),
        .RAM_DATA_IN3   (RAM_DATA_IN[3]),
        .RAM_DATA_OUT3  (RAM_DATA_OUT[3])
    );

    // 32-bit open RAM instanciation
    generate
        genvar vRamByte;
        for (vRamByte=0; vRamByte<4; vRamByte=vRamByte+1) begin
            openRam openRam_inst (
                .CLK        (CLK_I_tb),
                .CSb        (RAM_CSb[vRamByte]),
                .WEb        (RAM_WEb[vRamByte]),
                .ADDR       (RAM_ADDR[vRamByte]),
                .DATA_IN    (RAM_DATA_IN[vRamByte]),
                .DATA_OUT   (RAM_DATA_OUT[vRamByte])
            );
        end
    endgenerate
endmodule