`timescale 1ns / 1ps
module final_accumulator_tree_cell #(parameter delay = 2)
(
  input logic clk,
  input logic rst,
  input logic in_immediate,
  input logic in_delayed,
  input logic load_carry,
  output logic out
);
  logic carry;
  logic [delay-1:0]in_delayed_reg;
  always_ff @(posedge clk) begin
    if (rst) begin
      in_delayed_reg <= 0;
      out <= 0;
    end else begin
      in_delayed_reg <= {in_delayed,in_delayed_reg[delay-1:1]};
      out <= in_delayed_reg[0] ^ in_immediate ^ carry;
    end
    carry <= load_carry & ((in_delayed_reg[0] & in_immediate) | ((in_delayed_reg[0] ^ in_immediate) & carry));
  end
endmodule