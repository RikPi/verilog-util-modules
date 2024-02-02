`timescale 1ns/10ps

module spi_master #(parameter
    fifo_depth = 8 
    
) (
    input wire clk,
    input wire aReset,
    input reg data_in,
    output reg data_out 

);
    
endmodule