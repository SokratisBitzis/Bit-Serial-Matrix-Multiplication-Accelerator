`timescale 1ns / 1ps
module final_accumulator_tree_cell0 
(
  input logic clk,
  input logic rst,
  input logic in_immediate,
  input logic in_delayed,
  input logic load_carry,
  output logic out
);
  logic carry;
  logic in_delayed_reg;
  always_ff @(posedge clk) begin
    if (rst) begin
      in_delayed_reg <= 0;
      out <= 0;
    end else begin
      in_delayed_reg <= in_delayed;
      out <= in_delayed_reg ^ in_immediate ^ carry;
    end
    carry <= load_carry & ((in_delayed_reg & in_immediate) | ((in_delayed_reg ^ in_immediate) & carry));
  end
endmodule