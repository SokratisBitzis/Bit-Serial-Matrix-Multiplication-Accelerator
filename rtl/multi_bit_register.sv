`timescale 1ns / 1ps
module multi_bit_register #(parameter bits = 1)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] in,
  output logic [bits-1:0] out
);
  always_ff @(posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin
      out <= in;
    end
  end
endmodule