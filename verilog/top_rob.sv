

module top_rob (
	input clock,
	input reset,
	input [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag, //i/p from complete stage, not latched from the complete stage
	input  DISPATCH_PACKET [`N_WAY-1:0] dispatch_packet, //from dispatch stage
	input [`N_WAY-1:0] branch_inst, // BRANCH instruction identification
	input take_branch, //from ex stage
	input [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_result,
	input [$clog2(`N_WAY):0] dispatch_num, //from dispatch stage
	output ROB_PACKET [`N_ROB-1:0] rob_packet,//debug
	output PR_PACKET [`N_WAY-1 : 0] pr_packet_out1, //to reservation station
	output PR_PACKET [`N_WAY-1 : 0] pr_packet_out2, //to reservation station
	output logic [`N_WAY-1:0]dispatched,   //to dispatch stage
	output logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out,
	output logic branch_haz,
	output logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_target_pc,
	//output logic [$clog2(`N_WAY) : 0] free_num, //to dispatch stage
	//output logic [$clog2(`N_WAY):0] empty_rob, //to dispatch stage
	//output RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet,
	output logic [`N_ROB+32-1 : 0] free, //debug
	//output DISPATCH_PACKET [`N_WAY-1:0] dis_packet, // to map table
	//output logic [`N_WAY-1:0][`CDB_BITS-1:0] pr_old
	output RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet,
	output logic retire_branch,
	output logic [`XLEN-1:0] retire_branch_PC,
	output logic [`XLEN-1:0][`CDB_BITS-1:0] arch_reg_next,
	output logic [$clog2(`N_WAY):0] store_num_ret //from rob, make zero in rob for branch hazard
);

	ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis;//generated from dis packet and free list output
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag; 
	logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told;
	logic [`N_WAY-1:0][`XLEN-1:0] retire_PC;
	logic [`N_WAY-1:0] retire_halt;
	logic [`N_WAY-1:0] retire_illegal;
	logic [`N_WAY-1:0]retire_valid;
	//logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out;
	logic [$clog2(`N_WAY) : 0] free_num; //to dispatch stage
	logic [$clog2(`N_WAY):0] empty_rob; //to dispatch stage
//	RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet;
	//logic [`N_ROB+32-1 : 0] free; //debug
	DISPATCH_PACKET [`N_WAY-1:0] dis_packet; // to map table
	logic [`N_WAY-1:0][`CDB_BITS-1:0] pr_old;
	logic [`N_ROB-1:0][`CDB_BITS-1:0] free_list_haz; //input to freelist

	
	always_comb begin // to rob 
		for (int i=0; i<`N_WAY ; i=i+1) begin
			rob_packet_dis[i].tag = free_list_out[i];
			rob_packet_dis[i].tag_old = pr_old[i];
			rob_packet_dis[i].branch_inst = branch_inst[i];
			rob_packet_dis[i].PC = dispatch_packet[i].PC;
			rob_packet_dis[i].halt = dispatch_packet[i].halt;
			rob_packet_dis[i].illegal = dispatch_packet[i].illegal;
			rob_packet_dis[i].ld_st_bits= dispatch_packet[i].ld_st_bits;
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
			retire_packet[i].PC = retire_PC[i];
			retire_packet[i].halt = retire_halt[i];
			retire_packet[i].illegal = retire_illegal[i];
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
		.complete_dest_tag(complete_dest_tag),
		.take_branch(take_branch),
		.br_result(br_result),
		.rob_packet_dis(rob_packet_dis), //generated internally
		.retire_tag(retire_tag),
		.retire_told(retire_told),
		.retire_valid(retire_valid),
		.retire_PC(retire_PC),
		.retire_branch_PC(retire_branch_PC),
		.retire_branch(retire_branch),
		.retire_halt(retire_halt),
		.retire_illegal(retire_illegal),
		.empty_rob(empty_rob),
		.free_list_haz(free_list_haz),
		.rob_packet(rob_packet),
		.branch_haz(branch_haz),
		.br_target_pc(br_target_pc),
		.dispatched(dispatched),	
		.store_num_ret(store_num_ret)
                  );

map_table map_table0 (

                  .clock(clock), 
                  .reset(reset),
		  .dis_packet(dispatch_packet),
		  .branch_haz(branch_haz),
		  .arch_reg(arch_reg_next),
		  .pr_freelist(free_list_out),
		  .pr_reg_complete(complete_dest_tag),
		  .pr_packet_out1(pr_packet_out1), 
		  .pr_packet_out2(pr_packet_out2),
		  .pr_old(pr_old)
                  );

 architecture_table arch_table0 (

                  .clock(clock), 
                  .reset(reset),
		  .ret_packet(retire_packet),
		  .arch_reg_next(arch_reg_next)
                  );

 free_list free_list0 (

                  .clock(clock), 
                  .reset(reset), 
		  .rob_told(retire_told),
		  .free_list_haz(free_list_haz),
		  .branch_haz(branch_haz),
		  .dispatch_num(dispatch_num),
		  .free_list_out(free_list_out),
		  .free_num(free_num),
		  .free(free),
		  .dispatched(dispatched)	
                  );


endmodule

