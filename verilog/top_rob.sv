

module top_rob (
	input clock,
	input reset,
	input [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag, //i/p from complete stage, not latched from the complete stage
	input  DISPATCH_PACKET [`N_WAY-1:0] dispatch_packet, //from dispatch stage
	input [$clog2(`N_WAY):0] dispatch_num, //from dispatch stage
	output ROB_PACKET [`N_ROB-1:0] rob_packet,//debug
	output PR_PACKET [`N_WAY-1 : 0] pr_packet_out1, //to reservation station
	output PR_PACKET [`N_WAY-1 : 0] pr_packet_out2, //to reservation station
	//output logic [$clog2(`N_WAY):0] empty_rob, //to dispatch stage
	output logic [`N_WAY-1:0]dispatched,   //to dispatch stage
	output logic [`N_WAY-1 : 0] [`CDB_BITS-1 : 0] cdb_tag,  // to reservation station
	//output logic [$clog2(`N_WAY) : 0] free_num, //to dispatch stage
	//debug signals
	//output ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis,//generated from dis packet and free list output
	//output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag, 
	//output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told,
	//output logic [`N_WAY-1:0]retire_valid,
	output logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out,
	//output logic [$clog2(`N_WAY) : 0] free_num, //to dispatch stage
	//output logic [$clog2(`N_WAY):0] empty_rob, //to dispatch stage
	//output RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet,
	output logic [`N_ROB+32-1 : 0] free //debug
	//output DISPATCH_PACKET [`N_WAY-1:0] dis_packet, // to map table
	//output logic [`N_WAY-1:0][`CDB_BITS-1:0] pr_old
);

	ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis;//generated from dis packet and free list output
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag; 
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told;
	logic [`N_WAY-1:0]retire_valid;
	//logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out;
	logic [$clog2(`N_WAY) : 0] free_num; //to dispatch stage
	logic [$clog2(`N_WAY):0] empty_rob; //to dispatch stage
	RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet;
	//logic [`N_ROB+32-1 : 0] free; //debug
	DISPATCH_PACKET [`N_WAY-1:0] dis_packet; // to map table
	logic [`N_WAY-1:0][`CDB_BITS-1:0] pr_old;

	
	always_comb begin // to rob 
		for (int i=0; i<`N_WAY ; i=i+1) begin
			rob_packet_dis[i].tag = free_list_out[i];
			rob_packet_dis[i].tag_old = pr_old[i];
			if(free_list_out[i] == 0)
				rob_packet_dis[i].valid = 0;
			else
				rob_packet_dis[i].valid = dispatch_packet[i].valid;
				
		end
	end

	always_comb begin // to arch map
		for (int i=0; i<`N_WAY ; i=i+1) begin
			retire_packet[i].tag = retire_tag[i];
			retire_packet[i].tag_old = retire_told[i];
			retire_packet[i].ret_valid = retire_valid[i];
		end
	end

	always_comb begin // to map table 
		for (int i=0; i<`N_WAY ; i=i+1) begin
			dis_packet[i].src1 = dispatch_packet[i].src1;
			dis_packet[i].src2 = dispatch_packet[i].src2 ;
			dis_packet[i].dest = dispatch_packet[i].dest ;
			dis_packet[i].valid= dispatch_packet[i].valid && dispatched[i]   ;
				
		end
	end

 rob rob0 (
		.clock(clock), 
                .reset(reset), 
		.complete_dest_tag(cdb_tag),
		.rob_packet_dis(rob_packet_dis), //generated internally
		.retire_tag(retire_tag),
		.retire_told(retire_told),
		.retire_valid(retire_valid),
		.empty_rob(empty_rob),
		.rob_packet(rob_packet),
		.dispatched(dispatched)	
                  );

map_table map_table0 (

                  .clock(clock), 
                  .reset(reset),
		  .dis_packet(dispatch_packet),
		  .pr_freelist(free_list_out),
		  .pr_reg_complete(cdb_tag),
		  .pr_packet_out1(pr_packet_out1), 
		  .pr_packet_out2(pr_packet_out2),
		  .pr_old(pr_old)
                  );

 architecture_table arch_table0 (

                  .clock(clock), 
                  .reset(reset),
		  .ret_packet(retire_packet)
                  );

 free_list free_list0 (

                  .clock(clock), 
                  .reset(reset), 
		  .rob_told(retire_told),
		  .dispatch_num(dispatch_num),
		  .free_list_out(free_list_out),
		  .free_num(free_num),
		  .free(free),
		  .dispatched(dispatched)	
                  );

 cdb cdb0 (
		.clock(clock),
		.reset(reset),
		.input_tag(complete_dest_tag),
		.cdb_tag(cdb_tag)
		 );

endmodule

