`timescale 1ns / 1ps
module MSB_complement_cell #(parameter bits = 2)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] in,
  input logic complement,
  input logic additive,
  input logic load_dotP,
  output logic [bits-1:0] out
);
  logic [bits-2:0] local_in;
  logic [bits-2:0] carry;
  logic [bits-2:0] local_additive;
  logic [bits-2:0] tmp_load_dotP;
  logic [bits-2:0] temp_in;
  generate
    genvar i;
    // In the MSB complement cell, in opposition to the simple complement cell, every input (save for the one corresponding to A's MSB) is complemented
    for (i = 0; i < bits - 1; i++) begin
      assign local_in[i] = complement ^ in[i];
      assign local_additive[i] = additive;
      assign tmp_load_dotP[i] = load_dotP;
      assign temp_in[i] = carry[i] | local_additive[i];
    end
  endgenerate
  always_ff@ (posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin
      if (load_dotP) out[bits-2:0] <= local_in[bits-2:0] ^ temp_in[bits-2:0];
      out[bits-1] <= in[bits-1];
    end
    carry <= local_in & temp_in;
  end
endmodule
