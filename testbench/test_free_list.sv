`timescale 1ns/100ps


module test_free_list;

 // Inputs
	logic clock;
	logic reset;
	logic [`N_WAY-1:0][`CDB_BITS-1 : 0] rob_told;
	logic [$clog2(`N_WAY):0] dispatch_num;
 // Outputs
	logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out;
	logic [$clog2(`N_WAY) : 0] free_num;

 // Instantiate the Unit Under Test (UUT)

 free_list free_list0 (
                  .clock(clock), 
                  .reset(reset), 
		  .rob_told(rob_told),
		  .dispatch_num(dispatch_num),
		  .free_list_out(free_list_out),
		  .free_num(free_num)	
                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;
  rob_told[0] = 0;
  rob_told[1] = 0;
  rob_told[2] = 0;
  dispatch_num = 0;

  // Wait 100 ns for global reset to finish

	#51;        

	reset  = 1'b0;
	dispatch_num = 3;
	#200;
	rob_told[0] = 1;
	rob_told[1] = 2;
	rob_told[2] = 3;
	#20;
	dispatch_num = 2;
	rob_told[0] = 4;
	rob_told[1] = 5;
	rob_told[2] = 6;
	#20;
	dispatch_num = 0;
	rob_told[0] = 7;
	rob_told[1] = 8;
	rob_told[2] = 9;
	#20;
	dispatch_num = 1;
	rob_told[0] = 10;
	rob_told[1] = 11;
	rob_told[2] = 12;
	#20;
	dispatch_num = 3;
  rob_told[0] = 0;
  rob_told[1] = 0;
  rob_told[2] = 0;
	#260;
	dispatch_num = 1;
	#20;
	dispatch_num = 3;
	rob_told[0] = 13;
	rob_told[1] = 14;
	rob_told[2] = 15;
	#40;
  $finish;

 end 

   always #10 clock = ~clock;    

endmodule



