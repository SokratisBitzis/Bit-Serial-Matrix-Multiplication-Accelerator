`timescale 1ns / 1ps
module single_bit_array_multiplier #(parameter bits = 2, parameter rows = 2, parameter columns = 2)
(
  input logic clk,
  input logic rst,
  input logic [rows-1:0][bits-1:0] A,
  input logic [columns-1:0] B,
  input logic [rows-1:0] loadB,
  output logic [columns-1:0][bits-1:0] dotP
);
  logic [rows-1:0][columns-1:0][bits-1:0] local_dotP;
  // Only the last row needs to be outputted
  assign dotP = local_dotP[rows-1];
  generate
    genvar i, j;
    for (j = 0; j < columns; j++) begin
      for (i = 0; i < rows; i++) begin
        // The first row doesn't have an upper/previous input to receive
        if (i == 0) begin
          store_n_calc_cell0 #(.bits(bits)) B_cell0(
              .clk(clk),
              .rst(rst),
              .a(A[i]),
              .b(B[j]),
              .load_new_b(loadB[i]),
              .sum(local_dotP[i][j]));
        end
        else begin
          store_n_calc_cell #(.bits(bits)) B_cell(
              .clk(clk),
              .rst(rst),
              .a(A[i]),
              .b(B[j]),
              .upper_input(local_dotP[i-1][j]),
              .load_new_b(loadB[i]),
              .sum(local_dotP[i][j]));
        end
      end
    end
  endgenerate
endmodule