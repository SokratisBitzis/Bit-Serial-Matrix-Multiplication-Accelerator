`timescale 1ns / 1ps
module complement_cell #(parameter bits = 2)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] in,
  input logic complement,
  input logic additive,
  input logic load_dotP,
  output logic [bits-1:0] out
);
  logic local_in;
  assign local_in = complement ^ in[bits-1];
  logic temp_in;//
  logic carry;
  assign temp_in = carry | additive;//
  always_ff@ (posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin
      out[bits-2:0] <= in[bits-2:0];
      // In the simple cell, only the input referring to A's MSB is complemented
      //if (load_dotP) out[bits-1] <= (local_in ^ additive) ^ carry;
      if (load_dotP) out[bits-1] <= local_in ^ temp_in;//
    end
    //carry <= (((local_in ^ additive) & carry) | (local_in & additive));
    carry <= local_in & temp_in;//
  end
endmodule