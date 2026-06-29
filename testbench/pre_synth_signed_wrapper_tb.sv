`timescale 1ns / 1ps
module pre_synth_signed_wrapper_tb;
  // Basic parameters
  parameter bits = 16;
  parameter rows = 16;
  parameter columns = 9;
  parameter A_rows = 12;
  parameter A_columns = rows;
  
  // Load carry parameters
  parameter tree_levels = $clog2(bits);
  parameter max_tree_columns = (bits + 1) / 2;
  
  // Necessary design arguments
  // Input signals
  reg clk;
  reg rst;
  reg [rows-1:0][bits-1:0] A;
  reg [bits-1:0][columns-1:0] B;
  reg [rows-1:0] loadB;
  reg [bits-1:0] complement_dotP;
  reg [bits-1:0] complement_additive;
  reg [bits-1:0] load_dotP;
  reg [tree_levels-1:0] load_first_tree_carry;
  reg [bits-2:0] loadPartial;
  reg [tree_levels-1:0][max_tree_columns-1:0] load_final_tree_carry;
  // Output signals
  wire [columns-1:0] FINAL_RESULT;
  
  // Design to be tested
  wrapper #(
      .bits(bits),
      .rows(rows),
      .columns(columns),
      .tree_levels(tree_levels),
      .max_tree_columns(max_tree_columns)) DUT(
      .clk(clk),
      .rst(rst),
      .A(A),
      .B(B),
      .loadB(loadB),
      .complement_dotP(complement_dotP),
      .complement_additive(complement_additive),
      .load_dotP(load_dotP),
      .load_first_tree_carry(load_first_tree_carry),
      .loadPartial(loadPartial),
      .load_final_tree_carry(load_final_tree_carry),
      .FINAL_RESULT(FINAL_RESULT));
  
  // Local testbench clock
  always begin
    clk = 1;
    #5;
    clk = 0;
    #5;
  end
  
  // Calculate the closest power of 2 upwards
  function integer closest_power_of_2(input integer value);
    if (value && !(value & (value - 1))) // Check if 'value' is a power of 2
      closest_power_of_2 = value; // Assign 'value' itself if it's a power of 2
    else
      closest_power_of_2 = 2**$clog2(value); // Otherwise, calculate the closest power of 2 using $clog2 function
  endfunction
  parameter temp_rows = closest_power_of_2(rows);
    
  // Synchronization elements
  parameter dotP_size = $clog2(temp_rows + 1);
  parameter step = dotP_size + bits;
  parameter realStep = step + bits - 1;
  integer position[rows-1:0];
  integer iterationA = 0;
  integer iterationComp[bits-1:0];
  integer iterationTree = 0;
  integer iterationTreeSignEx = 0;
  integer iterationFinTree = 0;
  
  // Verification elements
  reg [realStep-1:0] PracticalResult[A_rows-1:0][columns-1:0];
  reg signed [realStep-1:0] TheoreticalResult[A_rows-1:0][columns-1:0];
  integer iterationPractical = 0;
  integer flag = 0;
  
  // Temporary B & A element arrays
  reg signed [bits-1:0] Bfull[0:rows-1][0:columns-1];
  reg [columns-1:0] Bin[bits-1:0][rows-1:0];
  reg signed [bits-1:0] Afull[0:A_rows-1][0:A_columns-1];
  
  
  // Task & loop variables
  integer iterationLocal1[bits-1:0];
  integer iterationLocal2 = 0;
  integer iterationLocal3 = 0;
  integer iterationLocal4 = 0;
  integer iterationLocal5 = 0;
  integer i = 0;
  integer j = 0;
  integer k = 0;
  integer z = 0;
  integer A_rowLocal = 0;
  
  // Handles the signals of dotP complement cells
  task complement_dotP_management;
	integer i;
	for (i = 0; i < bits; i = i + 1) begin
	  if (iterationA >= rows + i - 1 && iterationA < realStep * A_rows + rows + i - 1) begin
	    complement_dotP[i] = (iterationLocal1[i] <= dotP_size) ? 1 : 0;
        complement_additive[i] = (iterationLocal1[i] == 0) ? 1 : 0;
        load_dotP[i] = (iterationLocal1[i] > dotP_size && iterationLocal1[i] <= step - i) ? 0 : 1;
        iterationComp[i] = iterationComp[i] + 1;
        iterationLocal1[i] = iterationComp[i] % realStep;
	  end else begin
	    complement_dotP[i] = 0;
        complement_additive[i] = 0;
        load_dotP[i] = 1;
	  end
	end
  endtask
  
  // Erases the first tree's carries when needed
  task first_tree_carry_management;
	integer i;
    reg tmp_load_first_tree_carry[tree_levels-1:0];
    if (iterationA > rows && iterationTree < realStep * A_rows + $clog2(bits) - 2) begin
      for (i = 0; i < tree_levels; i = i + 1) begin
        tmp_load_first_tree_carry[i] = (iterationLocal2 == step - (1 - i)) ? 0 : 1;
      end
      for (i = 0; i < tree_levels; i = i + 1) begin
        load_first_tree_carry[i] = tmp_load_first_tree_carry[i];
      end
      
      iterationTree = iterationTree + 1;
      iterationLocal2 = iterationTree % realStep;
    end
	else begin
      for (i = 0; i < tree_levels; i = i + 1) begin
        load_first_tree_carry[i] = (1<<max_tree_columns) - 1;
      end
    end
  endtask
  
  // Sign extends the partial results
  task partial_result_sign_extend;
	integer i;
    if (iterationA > rows + $clog2(bits) - 1 && iterationTreeSignEx <= realStep * A_rows - 1) begin//the -1 at the > is because of the merge
      for (i = 0; i < bits - 1; i = i + 1) begin
        loadPartial[i] = (iterationLocal3 >= step && iterationLocal3 < realStep - i) ? 0 : 1;
      end
      iterationTreeSignEx = iterationTreeSignEx + 1;
      iterationLocal3 = iterationTreeSignEx % realStep;
    end
	else begin
      for (i = 0; i < bits - 1; i = i + 1) begin
        loadPartial[i] = 1;
      end
    end
  endtask
  
  // Erases the final tree's carries when needed
  task final_tree_carry_management;
	integer i, j, limit;
    reg [max_tree_columns-1:0] tmp_load_final_tree_carry[tree_levels-1:0];
    if (iterationA > rows + 1 + $clog2(bits) - 1 && iterationFinTree < realStep * A_rows + $clog2(bits) - 1) begin//the -1 at the > is because of the merge
      for (i = 0; i < tree_levels; i = i + 1) begin
        limit = (i == 0) ? max_tree_columns : (2**(tree_levels-1)) / (2**i);
        for (j = 0; j < limit; j = j + 1) begin
          if (i > 0 && j == 0) begin
            tmp_load_final_tree_carry[i][0] = (iterationLocal4 == i - 1) ? 0 : 1;
          end else begin
            tmp_load_final_tree_carry[i][j] = (iterationLocal4 == realStep - (1 - i + j * (2**(i + 1)))) ? 0 : 1;
          end
        end
      end
      for (i = 0; i < tree_levels; i = i + 1) begin
        load_final_tree_carry[i] = tmp_load_final_tree_carry[i];
      end
      
      iterationFinTree = iterationFinTree + 1;
      iterationLocal4 = iterationFinTree % realStep;
    end
	else begin
      for (i = 0; i < tree_levels; i = i + 1) begin
        load_final_tree_carry[i] = (1<<max_tree_columns) - 1;
      end
    end
  endtask
  
  // Calculates the practical multiplication result for verification
  task Calc_practical_multiplication;
	integer i;
    if (iterationA > rows + 3 + $clog2(bits) + $clog2(bits) - 1) begin//the -1 at the > is because of the merge // Needs a + 1 to work after the synthesis. This is the pre-synthesis tb
      for (i = 0; i < columns; i = i + 1) begin
        PracticalResult[A_rowLocal][i][iterationLocal5] = FINAL_RESULT[i];
      end
      iterationPractical = iterationPractical + 1;
      iterationLocal5 = iterationPractical % realStep;
      A_rowLocal = (iterationLocal5 == 0) ? (A_rowLocal + 1) : A_rowLocal;
    end
  endtask
  
  // Calls all the signal functions
  task Signal_handling;
    begin
      complement_dotP_management;
      first_tree_carry_management;
      partial_result_sign_extend;
      final_tree_carry_management;
      Calc_practical_multiplication;
    end
  endtask
  
  // Signal the testbench
  initial begin
    $display("Starting simulation");
    
    // The compiler doesn't allow these arrays to be intialized any other way
    for (i = 0; i < bits; i = i + 1) begin
      iterationLocal1[i] = 0;
      iterationComp[i] = 0;
    end
    
    // Empty verification arrays
    for (i = 0; i < A_rows; i = i + 1) begin
      for (j = 0; j < columns; j = j + 1) begin
        PracticalResult[i][j] = 0;
        TheoreticalResult[i][j] = 0;
      end
    end
    
    // RANDOM INITIALIZATION
    $srandom($time);
    // Randomize Bfull array
    for (i = 0; i < A_rows; i = i + 1) begin
      for (j = 0; j < A_columns; j = j + 1) begin
        Afull[i][j] = $urandom_range(-$signed((2**(bits-1))), $signed((2**(bits-1))-1));
        //Afull[i][j] = -1;
      end
    end

    // Randomize Afull array
    for (i = 0; i < rows; i = i + 1) begin
      for (j = 0; j < columns; j = j + 1) begin
        Bfull[i][j] = $urandom_range(-$signed((2**(bits-1))), $signed((2**(bits-1))-1));
        //Bfull[i][j] = -1;
      end
    end
    
    // MANUAL INITIALIZATION
    // Initialize A elements
    /*Afull = '{'{-1,0,2},
              '{1,-4,3},
              '{2,-3,-2}};
              
    // Initialize B elements in temp arrays
    Bfull = '{'{-3,-1,0},
              '{2,3,1},
              '{-1,-2,0}};*/
    
    // Transform B's inputs to be compatible with the system's input lines
    for (k = 0; k < bits; k = k + 1) begin
      for (i = 0; i < rows; i = i + 1) begin
        for (j = 0; j < columns; j = j + 1) begin
          Bin[k][i][j] = Bfull[i][j][k];
        end
      end
    end
    
    // Start the process
    clk = 0;
    rst = 1;
    A = 0;
    B = 0;
    loadB = 1;
    complement_dotP = 0;
    complement_additive = 0;
    load_dotP = 0;
    load_first_tree_carry = 0;
    load_final_tree_carry = 0;
    loadPartial = 0;
    @(posedge clk);#0.5;
    rst = 0;
    @(posedge clk);#0.5;
    
    // Start loading B
    loadB = 1;
    for (i = 0; i < rows; i = i + 1) begin
      for (k = 0; k < bits; k = k + 1) begin
        B[k] = Bin[k][i];
      end
      @(posedge clk);#0.5;
      loadB = {loadB[rows-2:0],1'b0};
    end
    loadB = 0;
    
    // Start automatically loading A
    if (realStep >= rows) begin// Serial version
      for (i = 0; i < A_rows; i = i + 1) begin
        for (j = 0; j < A_columns; j = j + 1) begin
        A[j] = Afull[i][j];
        Signal_handling;
        @(posedge clk);#0.5;
        iterationA = iterationA + 1;
        A[j] = 0;
        end
        for (z = 0; z < realStep - A_columns; z = z + 1) begin
          Signal_handling;
          @(posedge clk);#0.5;
          iterationA = iterationA + 1;
        end
      end
    end
	else begin// Parallel version
      for (i = 0; i < rows; i = i + 1) position[i] = 0;
      for (i = 0; i < realStep * A_rows + rows - realStep; i = i + 1) begin
        for (j = 0; j < rows; j = j + 1) begin
          A[j] = (iterationA - j >= 0 && (iterationA - j) % realStep == 0 && position[j] < A_rows) ?
              Afull[position[j]][j] : 0;
        end
        Signal_handling;
        @(posedge clk);#0.5;
        A = 0;
        for (j = 0; j < rows; j = j + 1) begin
          position[j] = (iterationA - j >= 0 && (iterationA - j) % realStep == 0) ?
              position[j] + 1 : position[j];
        end
        iterationA = iterationA + 1;
      end
    end
    
    // Continue the automated signals
    while (iterationPractical < realStep * A_rows + 1) begin
      Signal_handling;
      @(posedge clk);#0.5;
      iterationA = iterationA + 1;
    end
    
    // Calculate theoretical result of A x B multiplication
    for (i = 0; i < A_rows; i = i + 1) begin
      for (j = 0; j < columns; j = j + 1) begin
        for (k = 0; k < rows; k = k + 1) begin
          TheoreticalResult[i][j] = TheoreticalResult[i][j] + Afull[i][k] * Bfull[k][j];
        end
      end
    end
    
    // Search for differences between the practical and the theoretical multiplications
    for (i = 0; i < A_rows; i = i + 1) begin
      for (j = 0; j < columns; j = j + 1) begin
        if (PracticalResult[i][j] != TheoreticalResult[i][j]) flag = flag + 1;
      end
    end
    
    // Message user about failure or success of the simulation
    if (flag == 0) begin
      $display("Passed verification");
    end
	else begin
      $display("Failed verification with flag = %d", flag);
    end
    
    #100;
    //----------------------------
    $display("Simulation finished");
    $stop();
  end
  
endmodule