// (C) 2001-2015 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/14.1/ip/merlin/altera_merlin_router/altera_merlin_router.sv.terp#1 $
// $Revision: #1 $
// $Date: 2014/10/06 $
// $Author: swbranch $

// -------------------------------------------------------
// Merlin Router
//
// Asserts the appropriate one-hot encoded channel based on 
// either (a) the address or (b) the dest id. The DECODER_TYPE
// parameter controls this behaviour. 0 means address decoder,
// 1 means dest id decoder.
//
// In the case of (a), it also sets the destination id.
// -------------------------------------------------------

`timescale 1 ns / 1 ns

module host_mm_interconnect_0_router_default_decode
  #(
     parameter DEFAULT_CHANNEL = 1,
               DEFAULT_WR_CHANNEL = -1,
               DEFAULT_RD_CHANNEL = -1,
               DEFAULT_DESTID = 3 
   )
  (output [86 - 83 : 0] default_destination_id,
   output [12-1 : 0] default_wr_channel,
   output [12-1 : 0] default_rd_channel,
   output [12-1 : 0] default_src_channel
  );

  assign default_destination_id = 
    DEFAULT_DESTID[86 - 83 : 0];

  generate
    if (DEFAULT_CHANNEL == -1) begin : no_default_channel_assignment
      assign default_src_channel = '0;
    end
    else begin : default_channel_assignment
      assign default_src_channel = 12'b1 << DEFAULT_CHANNEL;
    end
  endgenerate

  generate
    if (DEFAULT_RD_CHANNEL == -1) begin : no_default_rw_channel_assignment
      assign default_wr_channel = '0;
      assign default_rd_channel = '0;
    end
    else begin : default_rw_channel_assignment
      assign default_wr_channel = 12'b1 << DEFAULT_WR_CHANNEL;
      assign default_rd_channel = 12'b1 << DEFAULT_RD_CHANNEL;
    end
  endgenerate

endmodule


module host_mm_interconnect_0_router
(
    // -------------------
    // Clock & Reset
    // -------------------
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                       sink_valid,
    input  [100-1 : 0]    sink_data,
    input                       sink_startofpacket,
    input                       sink_endofpacket,
    output                      sink_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output                          src_valid,
    output reg [100-1    : 0] src_data,
    output reg [12-1 : 0] src_channel,
    output                          src_startofpacket,
    output                          src_endofpacket,
    input                           src_ready
);

    // -------------------------------------------------------
    // Local parameters and variables
    // -------------------------------------------------------
    localparam PKT_ADDR_H = 57;
    localparam PKT_ADDR_L = 36;
    localparam PKT_DEST_ID_H = 86;
    localparam PKT_DEST_ID_L = 83;
    localparam PKT_PROTECTION_H = 90;
    localparam PKT_PROTECTION_L = 88;
    localparam ST_DATA_W = 100;
    localparam ST_CHANNEL_W = 12;
    localparam DECODER_TYPE = 0;

    localparam PKT_TRANS_WRITE = 60;
    localparam PKT_TRANS_READ  = 61;

    localparam PKT_ADDR_W = PKT_ADDR_H-PKT_ADDR_L + 1;
    localparam PKT_DEST_ID_W = PKT_DEST_ID_H-PKT_DEST_ID_L + 1;



    // -------------------------------------------------------
    // Figure out the number of bits to mask off for each slave span
    // during address decoding
    // -------------------------------------------------------
    localparam PAD0 = log2ceil(64'h200000 - 64'h100000); 
    localparam PAD1 = log2ceil(64'h210000 - 64'h208000); 
    localparam PAD2 = log2ceil(64'h214000 - 64'h212000); 
    localparam PAD3 = log2ceil(64'h215000 - 64'h214800); 
    localparam PAD4 = log2ceil(64'h215020 - 64'h215000); 
    localparam PAD5 = log2ceil(64'h215040 - 64'h215020); 
    localparam PAD6 = log2ceil(64'h215050 - 64'h215040); 
    localparam PAD7 = log2ceil(64'h215060 - 64'h215050); 
    localparam PAD8 = log2ceil(64'h215070 - 64'h215060); 
    localparam PAD9 = log2ceil(64'h215080 - 64'h215070); 
    localparam PAD10 = log2ceil(64'h215088 - 64'h215080); 
    localparam PAD11 = log2ceil(64'h215090 - 64'h215088); 
    // -------------------------------------------------------
    // Work out which address bits are significant based on the
    // address range of the slaves. If the required width is too
    // large or too small, we use the address field width instead.
    // -------------------------------------------------------
    localparam ADDR_RANGE = 64'h215090;
    localparam RANGE_ADDR_WIDTH = log2ceil(ADDR_RANGE);
    localparam OPTIMIZED_ADDR_H = (RANGE_ADDR_WIDTH > PKT_ADDR_W) ||
                                  (RANGE_ADDR_WIDTH == 0) ?
                                        PKT_ADDR_H :
                                        PKT_ADDR_L + RANGE_ADDR_WIDTH - 1;

    localparam RG = RANGE_ADDR_WIDTH-1;
    localparam REAL_ADDRESS_RANGE = OPTIMIZED_ADDR_H - PKT_ADDR_L;

      reg [PKT_ADDR_W-1 : 0] address;
      always @* begin
        address = {PKT_ADDR_W{1'b0}};
        address [REAL_ADDRESS_RANGE:0] = sink_data[OPTIMIZED_ADDR_H : PKT_ADDR_L];
      end   

    // -------------------------------------------------------
    // Pass almost everything through, untouched
    // -------------------------------------------------------
    assign sink_ready        = src_ready;
    assign src_valid         = sink_valid;
    assign src_startofpacket = sink_startofpacket;
    assign src_endofpacket   = sink_endofpacket;
    wire [PKT_DEST_ID_W-1:0] default_destid;
    wire [12-1 : 0] default_src_channel;




    // -------------------------------------------------------
    // Write and read transaction signals
    // -------------------------------------------------------
    wire read_transaction;
    assign read_transaction  = sink_data[PKT_TRANS_READ];


    host_mm_interconnect_0_router_default_decode the_default_decode(
      .default_destination_id (default_destid),
      .default_wr_channel   (),
      .default_rd_channel   (),
      .default_src_channel  (default_src_channel)
    );

    always @* begin
        src_data    = sink_data;
        src_channel = default_src_channel;
        src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = default_destid;

        // --------------------------------------------------
        // Address Decoder
        // Sets the channel and destination ID based on the address
        // --------------------------------------------------

    // ( 0x100000 .. 0x200000 )
    if ( {address[RG:PAD0],{PAD0{1'b0}}} == 22'h100000   ) begin
            src_channel = 12'b000000000010;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 3;
    end

    // ( 0x208000 .. 0x210000 )
    if ( {address[RG:PAD1],{PAD1{1'b0}}} == 22'h208000   ) begin
            src_channel = 12'b000000010000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 6;
    end

    // ( 0x212000 .. 0x214000 )
    if ( {address[RG:PAD2],{PAD2{1'b0}}} == 22'h212000   ) begin
            src_channel = 12'b000010000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 1;
    end

    // ( 0x214800 .. 0x215000 )
    if ( {address[RG:PAD3],{PAD3{1'b0}}} == 22'h214800   ) begin
            src_channel = 12'b000000001000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 2;
    end

    // ( 0x215000 .. 0x215020 )
    if ( {address[RG:PAD4],{PAD4{1'b0}}} == 22'h215000   ) begin
            src_channel = 12'b001000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 9;
    end

    // ( 0x215020 .. 0x215040 )
    if ( {address[RG:PAD5],{PAD5{1'b0}}} == 22'h215020   ) begin
            src_channel = 12'b000001000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 11;
    end

    // ( 0x215040 .. 0x215050 )
    if ( {address[RG:PAD6],{PAD6{1'b0}}} == 22'h215040   ) begin
            src_channel = 12'b100000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 7;
    end

    // ( 0x215050 .. 0x215060 )
    if ( {address[RG:PAD7],{PAD7{1'b0}}} == 22'h215050  && read_transaction  ) begin
            src_channel = 12'b010000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 0;
    end

    // ( 0x215060 .. 0x215070 )
    if ( {address[RG:PAD8],{PAD8{1'b0}}} == 22'h215060   ) begin
            src_channel = 12'b000100000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 8;
    end

    // ( 0x215070 .. 0x215080 )
    if ( {address[RG:PAD9],{PAD9{1'b0}}} == 22'h215070   ) begin
            src_channel = 12'b000000100000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 5;
    end

    // ( 0x215080 .. 0x215088 )
    if ( {address[RG:PAD10],{PAD10{1'b0}}} == 22'h215080  && read_transaction  ) begin
            src_channel = 12'b000000000100;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 10;
    end

    // ( 0x215088 .. 0x215090 )
    if ( {address[RG:PAD11],{PAD11{1'b0}}} == 22'h215088   ) begin
            src_channel = 12'b000000000001;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 4;
    end

end


    // --------------------------------------------------
    // Ceil(log2()) function
    // --------------------------------------------------
    function integer log2ceil;
        input reg[65:0] val;
        reg [65:0] i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule


