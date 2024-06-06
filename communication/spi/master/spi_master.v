`timescale 1ns/10ps

module spi_master #(parameter
    fifo_depth = 8 
    
) (
    input wire clk,
    input wire aReset,
    input wire i_stream_in,
    output wire o_stream_out,
    input wire i_datapck_in,
    output wire o_datapck_out

);
    
// Reg declarations
reg datapck_in;
reg datapck_out;
reg stream_in;
reg stream_out;

// Wire declarations

// Wire assignments

assign o_stream_out = stream_out;
assign o_datapck_out = datapck_out;



endmodule