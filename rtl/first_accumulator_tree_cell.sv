`timescale 1ns / 1ps
module first_accumulator_tree_cell #(parameter bits = 2)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] in_immediate,
  input logic [bits-1:0] in_delayed,
  input logic load_carry,
  output logic [bits-1:0] out
);
  logic [bits-1:0] carry;
  always_ff @(posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin
      out <= in_delayed ^ in_immediate ^ carry;
    end
    for (int i = 0; i < bits - 1; i++) begin
      carry[i] <= ((in_delayed[i] & in_immediate[i]) | ((in_delayed[i] ^ in_immediate[i]) & carry[i]));
    end
    carry[bits-1] <= load_carry & ((in_delayed[bits-1] & in_immediate[bits-1]) | ((in_delayed[bits-1] ^ in_immediate[bits-1]) & carry[bits-1]));
  end
endmodule