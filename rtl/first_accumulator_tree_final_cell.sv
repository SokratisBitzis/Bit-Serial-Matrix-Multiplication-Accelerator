`timescale 1ns / 1ps
// For the 1st stage of the tree, the second input is delayed by only 1 cycle
// and thus, the method of delay coded in the rest of the cells won't work
module first_accumulator_tree_final_cell #(parameter bits = 2)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] in_immediate,
  input logic [bits-1:0] in_delayed,
  input logic load_carry,
  input logic [bits-2:0] loadOut,
  output logic [bits-1:0] out
);
  logic [bits-1:0] carry;
  always_ff @(posedge clk) begin
    if (rst) begin
      out <= 0;
    end else begin
      for (int i = 0; i < bits - 1; i++) begin
        if (loadOut[i]) out[i] <= in_delayed[i] ^ in_immediate[i] ^ carry[i];
      end
      out[bits-1] <= in_delayed[bits-1] ^ in_immediate[bits-1] ^ carry[bits-1];
    end
    for (int j = 0; j < bits - 1; j++) begin
      carry[j] <= ((in_delayed[j] & in_immediate[j]) | ((in_delayed[j] ^ in_immediate[j]) & carry[j]));
    end
    carry[bits-1] <= load_carry & ((in_delayed[bits-1] & in_immediate[bits-1]) | ((in_delayed[bits-1] ^ in_immediate[bits-1]) & carry[bits-1]));
  end
endmodule