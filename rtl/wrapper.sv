`timescale 1ns / 1ps
module wrapper #(
  parameter bits = 4,
  parameter rows = 2,
  parameter columns = 2, 
  parameter tree_levels = 2,
  parameter max_tree_columns = 2
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
  // Input signals
  logic [rows-1:0][bits-1:0] tmp_A;
  logic [bits-1:0][columns-1:0] tmp_B;
  logic [rows-1:0] tmp_loadB;
  logic [bits-1:0] tmp_complement_dotP;
  logic [bits-1:0] tmp_complement_additive;
  logic [bits-1:0] tmp_load_dotP;
  logic [tree_levels-1:0] tmp_load_first_tree_carry;
  logic [bits-2:0] tmp_loadPartial;
  logic [tree_levels-1:0][max_tree_columns-1:0] tmp_load_final_tree_carry;
  // Output signals
  logic [columns-1:0] tmp_FINAL_RESULT;
  
  always_ff @(posedge clk) begin
    tmp_A <= A;
    tmp_B <= B;
    tmp_loadB <= loadB;
    tmp_complement_dotP <= complement_dotP;
    tmp_complement_additive <= complement_additive;
    tmp_load_dotP <= load_dotP;
    tmp_load_first_tree_carry <= load_first_tree_carry;
    tmp_loadPartial <= loadPartial;
    tmp_load_final_tree_carry <= load_final_tree_carry;
    FINAL_RESULT <= tmp_FINAL_RESULT;
  end
  
  system #(
      .bits(bits),
      .rows(rows),
      .columns(columns),
      .tree_levels(tree_levels),
      .max_tree_columns(max_tree_columns))
      DUT(
      .clk(clk),
      .rst(rst),
      .A(tmp_A),
      .B(tmp_B),
      .loadB(tmp_loadB),
      .complement_dotP(tmp_complement_dotP),
      .complement_additive(tmp_complement_additive),
      .load_dotP(tmp_load_dotP),
      .load_first_tree_carry(tmp_load_first_tree_carry),
      .loadPartial(tmp_loadPartial),
      .load_final_tree_carry(tmp_load_final_tree_carry),
      .FINAL_RESULT(tmp_FINAL_RESULT));
endmodule