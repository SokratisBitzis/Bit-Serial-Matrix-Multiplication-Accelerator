`timescale 1ns / 1ps
module store_n_calc_cell0 #(parameter bits = 2)
(
  input logic clk,
  input logic rst,
  input logic [bits-1:0] a,
  input logic b,
  input logic load_new_b,
  output logic [bits-1:0] sum
);
  // Temporary signals
  logic [bits-1:0] local_input;
  logic local_b;
  logic [bits-1:0] temp_sum;
  // Pre-calculate
  generate
    genvar i;
    for (i = 0; i < bits; i++) begin
      assign local_input[i] =  (a[i] & local_b);
      assign temp_sum[i] = local_input[i];
    end
  endgenerate
  // Store next values
  always_ff @(posedge clk) begin
    if (rst) begin
      sum <= 0;
    end else begin
      sum <= temp_sum;
    end
    if (load_new_b) local_b <= b;
  end
endmodule