`timescale 1ns/100ps


module test_arch_table;

 // Inputs
 logic clock;
 RETIRE_ROB_PACKET ret_packet[`N_WAY];
 logic reset;
 // Outputs

 // Instantiate the Unit Under Test (UUT)

 architecture_table arch_table0 (

                  .clock(clock), 
                  .reset(reset),
		  .ret_packet(ret_packet)
                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;

  ret_packet[0].valid = 0;
  ret_packet[0].tag_old = 0;
  ret_packet[0].tag = 0;

  ret_packet[1].valid = 0;
  ret_packet[1].tag_old = 0;
  ret_packet[1].tag = 0;

  ret_packet[2].valid = 0;
  ret_packet[2].tag_old = 0;
  ret_packet[2].tag = 0;


  // Wait 100 ns for global reset to finish

  #100;        

  // Add stimulus here


  reset  = 1'b1;

  #20;

  reset  = 1'b0;

  #20;
  ret_packet[0].valid = 1;
  ret_packet[0].tag_old = 1;
  ret_packet[0].tag = 33;

  ret_packet[1].valid = 1;
  ret_packet[1].tag_old = 2;
  ret_packet[1].tag = 34;

  ret_packet[2].valid = 1;
  ret_packet[2].tag_old = 3;
  ret_packet[2].tag = 35;

  #20;
  ret_packet[0].valid = 1;
  ret_packet[0].tag_old = 4;
  ret_packet[0].tag = 36;

  ret_packet[1].valid = 1;
  ret_packet[1].tag_old = 3;
  ret_packet[1].tag = 37;

  ret_packet[2].valid = 1;
  ret_packet[2].tag_old = 7;
  ret_packet[2].tag = 38;

  #20;
  
  ret_packet[0].valid = 0;
  ret_packet[1].valid = 0;
  ret_packet[2].valid = 0;
  #20;

  $finish;

 end 

   always #10 clock = ~clock;    

endmodule



