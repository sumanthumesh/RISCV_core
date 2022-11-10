`timescale 1ns/100ps


module test_top_r10k;

 // Inputs
	logic clock;
	logic reset;
	DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_packet; //from dispatch stage
	logic [`N_WAY-1:0] branch_inst; // BRANCH instruction identification

 // Outputs
 //
 	RS_PACKET_ISSUE [`N_WAY-1:0] rs_packet_issue;
	ISSUE_EX_PACKET [`N_WAY-1:0] issue_packet;
	RS_PACKET   [`N_RS-1:0] rs_data;
	ROB_PACKET [`N_ROB-1:0] rob_packet;//debug
	logic [`N_WAY-1:0]dispatched;   //to dispatch stage
	logic [`N_ROB+32-1 : 0] free; //debug
	EX_MEM_PACKET [`N_WAY-1 : 0] ex_packet_out;




 // Instantiate the Unit Under Test (UUT)

 top_r10k top_r10k_0 (
		.clock(clock), 
                .reset(reset), 
		.dispatch_packet(dispatch_packet),
		.branch_inst(branch_inst),
		.rs_packet_issue(rs_packet_issue),
		.rs_data(rs_data),
		.issue_packet(issue_packet),
		.rob_packet(rob_packet),
		.dispatched(dispatched),
		.free(free),	
		.ex_packet_out(ex_packet_out)	
                  );

  program_dispatch pd0 (
		.clock(clock),
		.reset(reset),
		.dispatched(dispatched),
		.branch_inst(branch_inst),
		.dispatch_out(dispatch_packet)
		);

 initial begin

  // Initialize Inputs

  clock  = 1'b0;
  reset  = 1'b1;
	
			
//	dispatch_packet[0].src1 = 0;
//	dispatch_packet[0].src2 = 0;
//	dispatch_packet[0].dest = 0;
//	dispatch_packet[0].inst = `RV32_ADD;
//	dispatch_packet[0].valid= 0;
//       
//	dispatch_packet[1].src1 = 0;
//	dispatch_packet[1].src2 = 0;
//	dispatch_packet[1].dest = 0;
//	dispatch_packet[1].inst = `RV32_ADD;
//	dispatch_packet[1].valid= 0;
//
//	dispatch_packet[2].src1 = 0;
//	dispatch_packet[2].src2 = 0;
//	dispatch_packet[2].dest = 0;
//	dispatch_packet[2].inst = `RV32_ADD;
//	dispatch_packet[2].valid= 0;
  // Wait 100 ns for global reset to finish

	@(posedge clock);
	@(posedge clock);
	@(posedge clock);
	#1;        

	reset  = 1'b0;


//	dispatch_packet[0].src1 = 1;
//	dispatch_packet[0].src2 = 2;
//	dispatch_packet[0].dest = 3;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 1;
//	dispatch_packet[1].src2 = 2;
//	dispatch_packet[1].dest = 4;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 1;
//	dispatch_packet[2].src2 = 2;
//	dispatch_packet[2].dest = 5;
//	dispatch_packet[2].valid= 1;
//
//	@(posedge clock);
//	#1;        
//
//	//RAW
//	dispatch_packet[0].src1 = 1;
//	dispatch_packet[0].src2 = 2;
//	dispatch_packet[0].dest = 6;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 1;
//	dispatch_packet[1].src2 = 6;
//	dispatch_packet[1].dest = 7;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 1;
//	dispatch_packet[2].src2 = 7;
//	dispatch_packet[2].dest = 8;
//	dispatch_packet[2].valid= 1;
//
//	@(posedge clock);
//	#1;        
//	//WAW
//	dispatch_packet[0].src1 = 1;
//	dispatch_packet[0].src2 = 2;
//	dispatch_packet[0].dest = 9;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 1;
//	dispatch_packet[1].src2 = 6;
//	dispatch_packet[1].dest = 10;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 1;
//	dispatch_packet[2].src2 = 7;
//	dispatch_packet[2].dest = 10;
//	dispatch_packet[2].valid= 1;
//
//	@(posedge clock);
//	#1;        
//	//WAR
//	dispatch_packet[0].src1 = 1;
//	dispatch_packet[0].src2 = 10;
//	dispatch_packet[0].dest = 11;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 1;
//	dispatch_packet[1].src2 = 16;
//	dispatch_packet[1].dest = 10;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 1;
//	dispatch_packet[2].src2 = 7;
//	dispatch_packet[2].dest = 10;
//	dispatch_packet[2].valid= 0;
//
//
//	@(posedge clock);
//	#1;        
//
//	dispatch_packet[0].src1 = 2;
//	dispatch_packet[0].src2 = 10;
//	dispatch_packet[0].dest = 11;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 2;
//	dispatch_packet[1].src2 = 16;
//	dispatch_packet[1].dest = 10;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 2;
//	dispatch_packet[2].src2 = 7;
//	dispatch_packet[2].dest = 17;
//	dispatch_packet[2].valid= 1;
//	@(posedge clock);
//	#1;      
//		
//	dispatch_packet[0].src1 = 1;
//	dispatch_packet[0].src2 = 2;
//	dispatch_packet[0].dest = 3;
//	dispatch_packet[0].inst = `RV32_MUL;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 4;
//	dispatch_packet[1].src2 = 5;
//	dispatch_packet[1].dest = 6;
//	dispatch_packet[1].inst = `RV32_MUL;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 7;
//	dispatch_packet[2].src2 = 8;
//	dispatch_packet[2].dest = 9;
//	dispatch_packet[2].inst = `RV32_ADD;
//	dispatch_packet[2].valid= 1;
//	@(posedge clock);
//	#1;  
//    
//  	dispatch_packet[0].src1 = 1;
//	dispatch_packet[0].src2 = 2;
//	dispatch_packet[0].dest = 10;
//	dispatch_packet[0].inst =`RV32_ADD ;
//	dispatch_packet[0].valid= 1;
//
//	dispatch_packet[1].src1 = 4;
//	dispatch_packet[1].src2 = 5;
//	dispatch_packet[1].dest = 11;
//	dispatch_packet[1].inst = `RV32_ADD;
//	dispatch_packet[1].valid= 1;
//
//	dispatch_packet[2].src1 = 7;
//	dispatch_packet[2].src2 = 8;
//	dispatch_packet[2].dest = 12;
//	dispatch_packet[2].inst = `RV32_ADD;
//	dispatch_packet[2].valid= 1;
//
//
//
//	@(posedge clock);
//	#1;        
//	dispatch_packet[0].valid= 0;
//	dispatch_packet[1].valid= 0;
//	dispatch_packet[2].valid= 0;
//		@(posedge clock);
//	@(posedge clock);
//	@(posedge clock);
//	@(posedge clock);

	#1000;
	$finish;

 end 

   always #10 clock = ~clock;    

endmodule



