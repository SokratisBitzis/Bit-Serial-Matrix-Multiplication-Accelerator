`timescale 1ns / 1ps
module first_accumulator_tree #(
  parameter bits = 2,
  parameter tree_levels = 4,
  parameter max_tree_columns = 8
)(
  input logic clk,
  input logic rst,
  input logic [bits-1:0][bits-1:0] in,
  input logic [tree_levels-1:0] load_carry,
  input logic [bits-2:0] loadPartial,
  output logic [bits-1:0] sum
);
  logic [tree_levels-1:0][max_tree_columns-1:0][bits-1:0] calculation;
  generate
    genvar i,j;
    localparam lasti = $clog2(bits) - 1;
    for (i = 0; i <= lasti; i++) begin
      localparam lastj = (bits + (2**(i + 1)) - 1) / (2**(i + 1)) - 1;
      for (j = 0; j <= lastj; j++) begin
        localparam reg_needed = !(bits > (2**i + j * (2**(i + 1))));
        if (i == 0) begin
          if (i == lasti) begin// Final cell needed at the start in case of bits == 2
            first_accumulator_tree_final_cell #(.bits(bits)) accumulator_first_n_final_cell(
              .clk(clk),
              .rst(rst),
              .in_immediate(in[j*2]),
              .in_delayed(in[j*2+1]),
              .load_carry(load_carry[0]),
              .loadOut(loadPartial),
              .out(calculation[0][j]));
          end else if (j == lastj && bits % 2) begin
            multi_bit_register #(.bits(bits)) delay_register(
              .clk(clk),
              .rst(rst),
              .in(in[j*2]),
              .out(calculation[0][j]));
          end else begin
            first_accumulator_tree_cell #(.bits(bits)) accumulator_cell0(
                .clk(clk),
                .rst(rst),
                .in_immediate(in[j*2]),
                .in_delayed(in[j*2+1]),
                .load_carry(load_carry[0]),
                .out(calculation[0][j]));
          end
        end else if (i != lasti && j == lastj && reg_needed) begin// Registers needed
          multi_bit_register #(.bits(bits)) delay_register(
              .clk(clk),
              .rst(rst),
              .in(calculation[i-1][j*2]),
              .out(calculation[i][j]));
        end else if (i == lasti) begin// Final cell needed
          first_accumulator_tree_final_cell #(.bits(bits)) accumulator_final_cell(
              .clk(clk),
              .rst(rst),
              .in_immediate(calculation[i-1][j*2]),
              .in_delayed(calculation[i-1][j*2+1]),
              .load_carry(load_carry[i]),
              .loadOut(loadPartial),
              .out(calculation[i][j]));
        end else begin// Normal cells are needed
          first_accumulator_tree_cell #(.bits(bits)) accumulator_cell(
              .clk(clk),
              .rst(rst),
              .in_immediate(calculation[i-1][j*2]),
              .in_delayed(calculation[i-1][j*2+1]),
              .load_carry(load_carry[i]),
              .out(calculation[i][j]));
        end
      end
    end
    assign sum = calculation[lasti][0];
  endgenerate
endmodule