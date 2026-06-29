`timescale 1ns / 1ps
module store_n_calc_cell #(parameter bits = 2)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] a,
  input logic b,
  input logic [bits-1:0] upper_input,
  input logic load_new_b,
  output logic [bits-1:0] sum
);
  // Temporary signals
  logic [bits-1:0] local_input;
  logic local_b;
  logic [bits-1:0] carry;
  logic [bits-1:0] temp_carry;
  logic [bits-1:0] temp_sum;
  // Pre-calculate
  generate
    genvar i;
    for (i = 0; i < bits; i++) begin
      assign local_input[i] = carry[i] | (a[i] & local_b);
      assign temp_carry[i] = local_input[i] & upper_input[i];
      assign temp_sum[i] = local_input[i] ^ upper_input[i];
    end
  endgenerate
  // Store next values
  always_ff @(posedge clk) begin
    if (rst) begin
      carry <= 0;
      sum <= 0;
    end else begin
      carry <= temp_carry;
      sum <= temp_sum;
    end
    if (load_new_b) local_b <= b;
  end
endmodule