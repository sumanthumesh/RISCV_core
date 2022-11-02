`timescale 1ns/100ps


module test_top_r10k;

 // Inputs
	logic clock;
	logic reset;
	logic [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag; //i/p from complete stage
	DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_packet; //from dispatch stage
	logic    [`N_WAY-1:0] [`CDB_BITS-1:0]  ex_rs_dest_idx;
	logic  [$clog2(`N_WAY)-1:0] issue_num;

 // Outputs
 //
 	RS_PACKET_ISSUE [`N_WAY-1:0] rs_packet_issue;
	RS_PACKET   [`N_RS-1:0] rs_data;
	ROB_PACKET [`N_ROB-1:0] rob_packet;//debug
	logic [`N_WAY-1:0]dispatched;   //to dispatch stage
	logic [`N_ROB+32-1 : 0] free; //debug




 // Instantiate the Unit Under Test (UUT)

 top_r10k top_r10k_0 (
		.clock(clock), 
                .reset(reset), 
		.complete_dest_tag(complete_dest_tag),
		.dispatch_packet(dispatch_packet),
		.ex_rs_dest_idx(ex_rs_dest_idx),
		.issue_num(issue_num),
		.rs_packet_issue(rs_packet_issue),
		.rs_data(rs_data),
		.rob_packet(rob_packet),
		.dispatched(dispatched),
		.free(free)	
                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;
	
	complete_dest_tag[0] = 0;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;

	ex_rs_dest_idx[0] = 0;
	ex_rs_dest_idx[1] = 0;
	ex_rs_dest_idx[2] = 0;

	issue_num =0;
		
	dispatch_packet[0].src1 = 0;
	dispatch_packet[0].src2 = 0;
	dispatch_packet[0].dest = 0;
	dispatch_packet[0].opcode = 56;
	dispatch_packet[0].valid= 0;

	dispatch_packet[1].src1 = 0;
	dispatch_packet[1].src2 = 0;
	dispatch_packet[1].dest = 0;
	dispatch_packet[1].opcode = 57;
	dispatch_packet[1].valid= 0;

	dispatch_packet[2].src1 = 0;
	dispatch_packet[2].src2 = 0;
	dispatch_packet[2].dest = 0;
	dispatch_packet[2].opcode = 58;
	dispatch_packet[2].valid= 0;

  // Wait 100 ns for global reset to finish

	@(posedge clock);
	@(posedge clock);
	@(posedge clock);
	#1;        

	reset  = 1'b0;

	issue_num =3;

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

	issue_num =2;
	//RAW
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
	issue_num =3;
	//WAW
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


	ex_rs_dest_idx[0] = 33;
	ex_rs_dest_idx[1] = 34;
	ex_rs_dest_idx[2] = 0;
	@(negedge clock);
	complete_dest_tag[0] = 33;
	complete_dest_tag[1] = 34;
	complete_dest_tag[2] = 0;


	@(posedge clock);
	#1;        
	//WAR
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

	ex_rs_dest_idx[0] = 36;
	ex_rs_dest_idx[1] = 0;
	ex_rs_dest_idx[2] = 0;
	@(negedge clock);
	complete_dest_tag[0] = 36;
	complete_dest_tag[1] = 0;
	complete_dest_tag[2] = 0;


	@(posedge clock);
	#1;        

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


	ex_rs_dest_idx[0] = 35;
	ex_rs_dest_idx[1] = 37;
	ex_rs_dest_idx[2] = 39;
	//ex_rs_dest_idx[0] = 0;
	//ex_rs_dest_idx[1] = 0;
	//ex_rs_dest_idx[2] = 0;
	@(negedge clock);
	complete_dest_tag[0] = 35;
	complete_dest_tag[1] = 37;
	complete_dest_tag[2] = 39;


	@(posedge clock);
	#1;        
	dispatch_packet[0].valid= 0;
	dispatch_packet[1].valid= 0;
	dispatch_packet[2].valid= 0;
	ex_rs_dest_idx[0] = 0;
	ex_rs_dest_idx[1] = 0;
	ex_rs_dest_idx[2] = 0;
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



