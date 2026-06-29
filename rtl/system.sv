`timescale 1ns / 1ps
module system #(
  parameter bits = 2,
  parameter rows = 2,
  parameter columns = 2, 
  parameter tree_levels = 4,
  parameter max_tree_columns = 8
)(
  input logic clk,
  input logic rst,
  input logic [rows-1:0][bits-1:0] A,
  input logic [bits-1:0][columns-1:0] B,
  input logic [rows-1:0] loadB,
  input logic [bits-1:0] complement_dotP,
  input logic [bits-1:0] complement_additive,
  input logic [bits-1:0] load_dotP,
  input logic [tree_levels-1:0] load_first_tree_carry,
  input logic [bits-2:0] loadPartial,
  input logic [tree_levels-1:0][max_tree_columns-1:0] load_final_tree_carry,
  output logic [columns-1:0] FINAL_RESULT
);
  logic [bits-1:0][columns-1:0][bits-1:0] dotP;
  logic [bits-1:0][columns-1:0][bits-1:0] complemented_dotP;
  logic [columns-1:0][bits-1:0][bits-1:0] reformed_dotP;
  logic [columns-1:0][bits-1:0] partial_result;
  logic [bits-2:0][rows-1:0][bits-1:0] A_reg_line;
  always_ff @(posedge clk) begin
    if (rst) begin
      A_reg_line <= 0;
    end else begin
      A_reg_line[0] <= A;
      for (int i = 1; i <= bits - 2; i++) A_reg_line[i] <= A_reg_line[i-1];
    end
  end
  generate
    genvar i, j;
    for(i = 0; i < bits; i++)begin
      // Generate the arrays that give the partial dot products of B x A single bit sub-arrays
      single_bit_array_multiplier #(.bits(bits), .rows(rows), .columns(columns)) B_array(
          .clk(clk),
          .rst(rst),
          .A((!i)?A:A_reg_line[i-1]),
          .B(B[i]),
          .loadB(loadB),
          .dotP(dotP[i]));
      // Generate the cells that complement each dot product when needed
      for (j = 0; j < columns; j++) begin
        if (i == bits - 1) begin
          MSB_complement_cell #(.bits(bits)) msb_comp_cell(
              .clk(clk),
              .rst(rst),
              .in(dotP[i][j]),
              .complement(complement_dotP[i]),
              .additive(complement_additive[i]),
              .load_dotP(load_dotP[i]),
              .out(complemented_dotP[i][j]));
        end else begin
          complement_cell #(.bits(bits)) comp_cell(
              .clk(clk),
              .rst(rst),
              .in(dotP[i][j]),
              .complement(complement_dotP[i]),
              .additive(complement_additive[i]),
              .load_dotP(load_dotP[i]),
              .out(complemented_dotP[i][j]));
        end
      end
    end
    // Process the complemented dot products to be compatible with the accumulator tree inputs
    for(i = 0; i < bits; i++)begin
      for(j = 0; j < columns; j++)begin
        assign reformed_dotP[j][i] = complemented_dotP[i][j];
      end
    end
    for(i = 0; i < columns; i++)begin
      // Generate the first accumulator trees that calculate partial results
      first_accumulator_tree #(
          .bits(bits),
          .tree_levels(tree_levels),
          .max_tree_columns(max_tree_columns))
          first_tree(
          .clk(clk),
          .rst(rst),
          .in(reformed_dotP[i]),
          .load_carry(load_first_tree_carry),
          .loadPartial(loadPartial),
          .sum(partial_result[i]));
      // Generate the accumulator trees that calculate the final results
      final_accumulator_tree #(
          .bits(bits),
          .tree_levels(tree_levels),
          .max_tree_columns(max_tree_columns))
          fin_tree(
          .clk(clk),
          .rst(rst),
          .in(partial_result[i]),
          .load_carry(load_final_tree_carry),
          .sum(FINAL_RESULT[i]));
    end
  endgenerate
endmodule