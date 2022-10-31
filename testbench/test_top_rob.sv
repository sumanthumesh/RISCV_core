`timescale 1ns/100ps


module test_top_rob;

 // Inputs
	logic clock;
	logic reset;
	logic [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag; //i/p from complete stage
	DISPATCH_PACKET [`N_WAY-1:0] dispatch_packet; //from dispatch stage
	logic [$clog2(`N_WAY):0] dispatch_num; //from dispatch stage
 // Outputs
 //
 	 ROB_PACKET [`N_ROB-1:0] rob_packet;//debug
	 PR_PACKET [`N_WAY-1 : 0] pr_packet_out1; //to reservation station
	 PR_PACKET [`N_WAY-1 : 0] pr_packet_out2; //to reservation station
	 logic [`N_WAY-1:0]dispatched;   //to dispatch stage
	 logic [`N_WAY-1 : 0] [`CDB_BITS-1 : 0] cdb_tag;  // to reservation station
	//debug signals
	ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis;//generated from dis packet and free list output
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag; 
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told;
	logic [`N_WAY-1:0]retire_valid;
	logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out;
	logic [$clog2(`N_WAY) : 0] free_num; //to dispatch stage
	logic [$clog2(`N_WAY):0] empty_rob; //to dispatch stage
	RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet;
	logic [`N_ROB+32-1 : 0] free; //debug
	DISPATCH_PACKET [`N_WAY-1:0] dis_packet; // to map table
	logic [`N_WAY-1:0][`CDB_BITS-1:0] pr_old;
	
 // Instantiate the Unit Under Test (UUT)

 top_rob top_rob0 (
		.clock(clock), 
                .reset(reset), 
		.complete_dest_tag(complete_dest_tag),
		.dispatch_packet(dispatch_packet),
		.dispatch_num(dispatch_num),
		.rob_packet(rob_packet),
		.pr_packet_out1(pr_packet_out1),
		.pr_packet_out2(pr_packet_out2),
		.dispatched(dispatched),
		.cdb_tag(cdb_tag),	
		.rob_packet_dis(rob_packet_dis),
		.retire_tag(retire_tag),	
		.retire_told(retire_told),	
		.retire_valid(retire_valid),	
		.free_list_out(free_list_out),	
		.free_num(free_num),	
		.retire_packet(retire_packet),	
		.empty_rob(empty_rob),	
		.free(free),	
		.dis_packet(dis_packet),	
		.pr_old(pr_old)
                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;
	
	complete_dest_tag[0] = 0;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;
		
	dispatch_num = 3;
	dispatch_packet[0].src1 = 0;
	dispatch_packet[0].src2 = 0;
	dispatch_packet[0].dest = 0;
	dispatch_packet[0].valid= 0;

	dispatch_packet[1].src1 = 0;
	dispatch_packet[1].src2 = 0;
	dispatch_packet[1].dest = 0;
	dispatch_packet[1].valid= 0;

	dispatch_packet[2].src1 = 0;
	dispatch_packet[2].src2 = 0;
	dispatch_packet[2].dest = 0;
	dispatch_packet[2].valid= 0;

  // Wait 100 ns for global reset to finish

	@(posedge clock);
	@(posedge clock);
	@(posedge clock);
	#1;        

	reset  = 1'b0;
	dispatch_num = 3;
	dispatch_packet[0].src1 = 1;
	dispatch_packet[0].src2 = 2;
	dispatch_packet[0].dest = 3;
	dispatch_packet[0].valid= 1;

	dispatch_packet[1].src1 = 1;
	dispatch_packet[1].src2 = 2;
	dispatch_packet[1].dest = 4;
	dispatch_packet[1].valid= 1;

	dispatch_packet[2].src1 = 1;
	dispatch_packet[2].src2 = 2;
	dispatch_packet[2].dest = 5;
	dispatch_packet[2].valid= 1;

	@(posedge clock);
	#1;        

	//RAW
	dispatch_num = 3;
	dispatch_packet[0].src1 = 1;
	dispatch_packet[0].src2 = 2;
	dispatch_packet[0].dest = 6;
	dispatch_packet[0].valid= 1;

	dispatch_packet[1].src1 = 1;
	dispatch_packet[1].src2 = 6;
	dispatch_packet[1].dest = 7;
	dispatch_packet[1].valid= 1;

	dispatch_packet[2].src1 = 1;
	dispatch_packet[2].src2 = 7;
	dispatch_packet[2].dest = 8;
	dispatch_packet[2].valid= 1;

	@(posedge clock);
	#1;        
	//WAW
	dispatch_num = 3;
	dispatch_packet[0].src1 = 1;
	dispatch_packet[0].src2 = 2;
	dispatch_packet[0].dest = 9;
	dispatch_packet[0].valid= 1;

	dispatch_packet[1].src1 = 1;
	dispatch_packet[1].src2 = 6;
	dispatch_packet[1].dest = 10;
	dispatch_packet[1].valid= 1;

	dispatch_packet[2].src1 = 1;
	dispatch_packet[2].src2 = 7;
	dispatch_packet[2].dest = 10;
	dispatch_packet[2].valid= 1;

	complete_dest_tag[0] = 33;
	complete_dest_tag[1] = 34;
	complete_dest_tag[2] = 0;


	@(posedge clock);
	#1;        
	//WAR
	dispatch_num = 2;
	dispatch_packet[0].src1 = 1;
	dispatch_packet[0].src2 = 10;
	dispatch_packet[0].dest = 11;
	dispatch_packet[0].valid= 1;

	dispatch_packet[1].src1 = 1;
	dispatch_packet[1].src2 = 16;
	dispatch_packet[1].dest = 10;
	dispatch_packet[1].valid= 1;

	dispatch_packet[2].src1 = 1;
	dispatch_packet[2].src2 = 7;
	dispatch_packet[2].dest = 10;
	dispatch_packet[2].valid= 0;

	complete_dest_tag[0] = 36;
	complete_dest_tag[1] = 38;
	complete_dest_tag[2] = 0;

	@(posedge clock);
	#1;        

	dispatch_num = 3;
	dispatch_packet[0].src1 = 2;
	dispatch_packet[0].src2 = 10;
	dispatch_packet[0].dest = 11;
	dispatch_packet[0].valid= 1;

	dispatch_packet[1].src1 = 2;
	dispatch_packet[1].src2 = 16;
	dispatch_packet[1].dest = 10;
	dispatch_packet[1].valid= 1;

	dispatch_packet[2].src1 = 2;
	dispatch_packet[2].src2 = 7;
	dispatch_packet[2].dest = 17;
	dispatch_packet[2].valid= 1;

	complete_dest_tag[0] = 35;
	complete_dest_tag[1] = 37;
	complete_dest_tag[2] = 0;

	@(posedge clock);
	#1;        
	dispatch_num = 0;
	dispatch_packet[0].valid= 0;
	dispatch_packet[1].valid= 0;
	dispatch_packet[2].valid= 0;
	complete_dest_tag[0] = 0;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;
	@(posedge clock);
	@(posedge clock);
	@(posedge clock);
	@(posedge clock);

	$finish;

 end 

   always #10 clock = ~clock;    

endmodule



