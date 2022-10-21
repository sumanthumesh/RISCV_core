`timescale 1ns/100ps


module test_map_table;

 // Inputs
 logic clock;
 DISPATCH_ROB_PACKET [`N_WAY-1 : 0] dis_packet;
 logic [`N_WAY-1 : 0] [`CDB_BITS -1 :0] pr_freelist;
 logic [`N_WAY-1 : 0] [`CDB_BITS-1 :0] pr_reg_complete;
 logic reset;
 // Outputs
 PR_PACKET [`N_WAY-1 : 0] pr_packet_out1;
 PR_PACKET [`N_WAY-1 : 0] pr_packet_out2;
//logic [`N_WAY-1 : 0] src1_match;
//logic [`N_WAY-1 : 0] src2_match;
//logic [`N_WAY-1 :0] valid_comp;

 // Instantiate the Unit Under Test (UUT)

 map_table map_table0 (

                  .clock(clock), 
                  .reset(reset),
		  .dis_packet(dis_packet),
		  .pr_freelist(pr_freelist),
		  .pr_reg_complete(pr_reg_complete),
		  .pr_packet_out1(pr_packet_out1), 
		  .pr_packet_out2(pr_packet_out2)
		  //.src1_match(src1_match),
		  //.src2_match(src2_match),
		  //.valid_comp(valid_comp)
                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;

  pr_reg_complete[0] = 0;
  pr_freelist[0] = 33;
  dis_packet[0].valid = 0;
  dis_packet[0].src1 = 0;
  dis_packet[0].src2 = 0;
  dis_packet[0].dest = 0;

  pr_reg_complete[1] = 0;
  pr_freelist[1] = 34;
  dis_packet[1].valid = 0;
  dis_packet[1].src1 = 0;
  dis_packet[1].src2 = 0;
  dis_packet[1].dest = 0;

  pr_reg_complete[2] = 0;
  pr_freelist[2] = 35;
  dis_packet[2].valid = 0;
  dis_packet[2].src1 = 0;
  dis_packet[2].src2 = 0;
  dis_packet[2].dest = 0;


  // Wait 100 ns for global reset to finish

  #100;        

  // Add stimulus here


  reset  = 1'b1;

  #20;

  reset  = 1'b0;

  #20;
  pr_reg_complete[0] = 0;
  pr_freelist[0] = 33;
  dis_packet[0].valid = 1;
  dis_packet[0].src1 = 0;
  dis_packet[0].src2 = 1;
  dis_packet[0].dest = 2;

  pr_reg_complete[1] = 0;
  pr_freelist[1] = 34;
  dis_packet[1].valid = 1;
  dis_packet[1].src1 = 3;
  dis_packet[1].src2 = 4;
  dis_packet[1].dest = 5;

  pr_reg_complete[2] = 0;
  pr_freelist[2] = 35;
  dis_packet[2].valid = 1;
  dis_packet[2].src1 = 6;
  dis_packet[2].src2 = 7;
  dis_packet[2].dest = 8;

  #20;
  pr_reg_complete[0] = 0;
  pr_freelist[0] = 36;
  dis_packet[0].valid = 1;
  dis_packet[0].src1 = 1;
  dis_packet[0].src2 = 2;
  dis_packet[0].dest = 3;

  pr_reg_complete[1] = 0;
  pr_freelist[1] = 37;
  dis_packet[1].valid = 1;
  dis_packet[1].src1 = 3;
  dis_packet[1].src2 = 4;
  dis_packet[1].dest = 5;

  pr_reg_complete[2] = 0;
  pr_freelist[2] = 38;
  dis_packet[2].valid = 1;
  dis_packet[2].src1 = 7;
  dis_packet[2].src2 = 5;
  dis_packet[2].dest = 8;

  #20;
  pr_reg_complete[0] = 33;
  pr_freelist[0] = 39;
  dis_packet[0].valid = 1;
  dis_packet[0].src1 = 5;
  dis_packet[0].src2 = 6;
  dis_packet[0].dest = 8;

  pr_reg_complete[1] = 34;
  pr_freelist[1] = 40;
  dis_packet[1].valid = 1;
  dis_packet[1].src1 = 2;
  dis_packet[1].src2 = 3;
  dis_packet[1].dest = 4;

  pr_reg_complete[2] = 0;
  pr_freelist[2] = 41;
  dis_packet[2].valid = 1;
  dis_packet[2].src1 = 6;
  dis_packet[2].src2 = 7;
  dis_packet[2].dest = 0;

  #20;

  dis_packet[0].valid = 0;
  dis_packet[1].valid = 0;
  dis_packet[2].valid = 0;
  #20;

  $finish;

 end 

   always #10 clock = ~clock;    

endmodule



