`timescale 1ns/100ps


module test_rob;

 // Inputs
	logic clock;
	logic reset;
	logic [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag;
	ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis;
 // Outputs
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag; 
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told;
	logic [`N_WAY-1:0]retire_valid;
	logic [`N_WAY-1:0]dispatched;
	logic [$clog2(`N_WAY):0] empty_rob;
	 ROB_PACKET [`N_ROB-1:0] rob_packet;

 // Instantiate the Unit Under Test (UUT)

 rob rob0 (
		.clock(clock), 
                .reset(reset), 
		.complete_dest_tag(complete_dest_tag),
		.rob_packet_dis(rob_packet_dis),
		.retire_tag(retire_tag),
		.retire_told(retire_told),
		.retire_valid(retire_valid),
		.empty_rob(empty_rob),
		.rob_packet(rob_packet),
		.dispatched(dispatched)	
                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;
	rob_packet_dis[0].tag = 0;
	rob_packet_dis[0].tag_old = 0;
	rob_packet_dis[0].valid = 0;

	rob_packet_dis[1].tag = 0;
	rob_packet_dis[1].tag_old = 0;
	rob_packet_dis[1].valid = 0;

	rob_packet_dis[2].tag = 0;
	rob_packet_dis[2].tag_old = 0;
	rob_packet_dis[2].valid = 0;

	complete_dest_tag[0] = 0;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;

  // Wait 100 ns for global reset to finish

	#51;        

	reset  = 1'b0;
	#20;
	rob_packet_dis[0].tag = 33;
	rob_packet_dis[0].tag_old = 3;
	rob_packet_dis[0].valid = 1;

	rob_packet_dis[1].tag = 34;
	rob_packet_dis[1].tag_old = 6;
	rob_packet_dis[1].valid = 1;

	rob_packet_dis[2].tag = 35;
	rob_packet_dis[2].tag_old = 9;
	rob_packet_dis[2].valid = 1;

	complete_dest_tag[0] = 0;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;

	#20;
	rob_packet_dis[0].tag = 36;
	rob_packet_dis[0].tag_old = 10;
	rob_packet_dis[0].valid = 1;

	rob_packet_dis[1].tag = 37;
	rob_packet_dis[1].tag_old = 11;
	rob_packet_dis[1].valid = 1;

	rob_packet_dis[2].tag = 38;
	rob_packet_dis[2].tag_old = 12;
	rob_packet_dis[2].valid = 1;

	complete_dest_tag[0] = 0;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;

	#20;
	rob_packet_dis[0].tag = 39;
	rob_packet_dis[0].tag_old = 1;
	rob_packet_dis[0].valid = 1;

	rob_packet_dis[1].tag = 40;
	rob_packet_dis[1].tag_old = 2;
	rob_packet_dis[1].valid = 1;

	rob_packet_dis[2].tag = 41;
	rob_packet_dis[2].tag_old = 33;
	rob_packet_dis[2].valid = 1;

	complete_dest_tag[0] = 33;
	complete_dest_tag[1] = 34;
	complete_dest_tag[2] = 36;

	#20;
	rob_packet_dis[0].tag = 42;
	rob_packet_dis[0].tag_old = 5;
	rob_packet_dis[0].valid = 1;

	rob_packet_dis[1].tag = 44;
	rob_packet_dis[1].tag_old = 14;
	rob_packet_dis[1].valid = 1;

	rob_packet_dis[2].tag = 44;
	rob_packet_dis[2].tag_old = 7;
	rob_packet_dis[2].valid = 0;

	complete_dest_tag[0] = 35;
	complete_dest_tag[1] = 38;
	complete_dest_tag[2] = 0;

	#20;
	rob_packet_dis[0].tag = 45;
	rob_packet_dis[0].tag_old = 5;
	rob_packet_dis[0].valid = 1;

	rob_packet_dis[1].tag = 46;
	rob_packet_dis[1].tag_old = 14;
	rob_packet_dis[1].valid = 1;

	rob_packet_dis[2].tag = 47;
	rob_packet_dis[2].tag_old = 7;
	rob_packet_dis[2].valid = 0;

	complete_dest_tag[0] = 35;
	complete_dest_tag[1] = 42;
	complete_dest_tag[2] = 44;


	#20;
	#20;
	$finish;

 end 

   always #10 clock = ~clock;    

endmodule



