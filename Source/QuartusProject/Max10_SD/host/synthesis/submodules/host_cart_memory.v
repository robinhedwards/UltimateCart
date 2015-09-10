//Legal Notice: (C)2015 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module host_cart_memory (
                          // inputs:
                           address,
                           address2,
                           chipselect,
                           chipselect2,
                           clk,
                           clken,
                           clken2,
                           reset,
                           reset_req,
                           write,
                           write2,
                           writedata,
                           writedata2,

                          // outputs:
                           readdata,
                           readdata2
                        )
;

  parameter INIT_FILE = "boot_rom.hex";


  output  [  7: 0] readdata;
  output  [  7: 0] readdata2;
  input   [ 12: 0] address;
  input   [ 12: 0] address2;
  input            chipselect;
  input            chipselect2;
  input            clk;
  input            clken;
  input            clken2;
  input            reset;
  input            reset_req;
  input            write;
  input            write2;
  input   [  7: 0] writedata;
  input   [  7: 0] writedata2;

  wire             clocken0;
  wire             not_clken;
  wire             not_clken2;
  wire    [  7: 0] readdata;
  wire    [  7: 0] readdata2;
  wire             wren;
  wire             wren2;
  assign wren = chipselect & write & clken;
  assign not_clken = ~clken;
  assign not_clken2 = ~clken2;
  assign clocken0 = ~reset_req;
  assign wren2 = chipselect2 & write2 & clken2;
  altsyncram the_altsyncram
    (
      .address_a (address),
      .address_b (address2),
      .addressstall_a (not_clken),
      .addressstall_b (not_clken2),
      .clock0 (clk),
      .clocken0 (clocken0),
      .data_a (writedata),
      .data_b (writedata2),
      .q_a (readdata),
      .q_b (readdata2),
      .wren_a (wren),
      .wren_b (wren2)
    );

  defparam the_altsyncram.address_reg_b = "CLOCK0",
           the_altsyncram.byte_size = 8,
           the_altsyncram.byteena_reg_b = "CLOCK0",
           the_altsyncram.indata_reg_b = "CLOCK0",
           the_altsyncram.init_file = INIT_FILE,
           the_altsyncram.lpm_type = "altsyncram",
           the_altsyncram.maximum_depth = 8192,
           the_altsyncram.numwords_a = 8192,
           the_altsyncram.numwords_b = 8192,
           the_altsyncram.operation_mode = "BIDIR_DUAL_PORT",
           the_altsyncram.outdata_reg_a = "UNREGISTERED",
           the_altsyncram.outdata_reg_b = "UNREGISTERED",
           the_altsyncram.ram_block_type = "AUTO",
           the_altsyncram.read_during_write_mode_mixed_ports = "DONT_CARE",
           the_altsyncram.width_a = 8,
           the_altsyncram.width_b = 8,
           the_altsyncram.widthad_a = 13,
           the_altsyncram.widthad_b = 13,
           the_altsyncram.wrcontrol_wraddress_reg_b = "CLOCK0";

  //s1, which is an e_avalon_slave
  //s2, which is an e_avalon_slave

endmodule

