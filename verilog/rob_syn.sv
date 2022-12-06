//ROB
//
module rob (
	input clock,
	input reset,
	input [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag,
	input [`N_WAY-1 : 0] take_branch, //from ex stage
	input [`N_WAY-1 : 0] [`XLEN-1:0] br_result,
	input  ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis,
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag, 
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told,
	output logic [`N_WAY-1:0][`XLEN-1:0] retire_PC,
	output logic [`N_WAY-1:0] retire_halt,
	output logic [`N_WAY-1:0] retire_illegal,
	output logic [`N_WAY-1:0]retire_valid,
	output logic [`N_WAY-1:0]dispatched,
	output logic branch_haz,
	output logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_target_pc,
	output logic [`N_ROB-1:0][`CDB_BITS-1:0] free_list_haz, //input to freelist
	output ROB_PACKET [`N_ROB-1:0] rob_packet,
	output logic [$clog2(`N_WAY):0] empty_rob,
	output logic [`XLEN-1:0] retire_branch_PC,
	output logic retire_branch,
	output logic [$clog2(`N_WAY):0] store_num_ret, //from rob, make zero in rob for branch hazard
	output logic [`N_WAY-1:0] retire_inst_is_branch
);
	ROB_PACKET [`N_ROB-1:0] rob_packet_next;
	ROB_PACKET [`N_ROB-1:0] rob_packet_wire;
	//ROB_PACKET [`N_ROB-1:0] rob_packet;
	logic tmp, tmp1;

	logic [$clog2(`N_ROB) : 0] head, head_next;
	logic [$clog2(`N_ROB) : 0] tail, tail_next;
 

	always_comb begin
		rob_packet_wire = rob_packet;
		retire_valid = 0 ;		
		retire_tag =  0;		
		retire_told = 0;
		retire_PC = 0;
		retire_branch= 0;
		retire_halt = 0;
		retire_illegal = 0;
		branch_haz = 0;
		br_target_pc = 0;
		store_num_ret = 0;
		retire_inst_is_branch = 0;
		head_next = head;
		//retire_stage
		for(int i=0; i<`N_WAY; i=i+1) begin	
			tmp = 1;
				//for(int j=0; j<`N_ROB; j=j+1) begin
					if(!branch_haz) begin
						if(rob_packet[head_next].completed && tmp) begin
							if (rob_packet[head_next].branch_inst && rob_packet[head_next].take_branch) begin
								branch_haz = rob_packet[head_next].take_branch;
								retire_branch= 0;
								retire_branch_PC= rob_packet[head_next].PC;
								retire_inst_is_branch[i] = rob_packet[head_next].branch_inst;
								br_target_pc = rob_packet[head_next].br_result;
								//for jal
								if(rob_packet[head_next].tag_old != `ZERO_REG_PR) begin
									retire_valid[i] = 1 ;		
									retire_tag[i] = rob_packet[head_next].tag ;		
									retire_told[i] = rob_packet[head_next].tag_old ;
								end else begin
									retire_valid[i] = 1 ;		
									retire_told[i] = rob_packet[head_next].tag ;
								end
								retire_PC[i] = rob_packet[head_next].PC;
								rob_packet_wire[head_next].tag = 0;
								rob_packet_wire[head_next].tag_old = 0;
								//for jal
								//for(int k=0; k<`N_ROB; k=k+1) begin
								//end
							end
							if(!branch_haz) begin
								if(rob_packet[head_next].ld_st_bits == 2'b01) store_num_ret = store_num_ret + 1;
								if(rob_packet[head_next].tag_old != `ZERO_REG_PR) begin
									retire_valid[i] = 1 ;		
									retire_tag[i] = rob_packet[head_next].tag ;		
									retire_told[i] = rob_packet[head_next].tag_old ;
								end else begin
									retire_valid[i] = 1 ;		
									retire_told[i] = rob_packet[head_next].tag ;
								end
								retire_PC[i] = rob_packet[head_next].PC;
								retire_inst_is_branch[i] = rob_packet[head_next].branch_inst;
								retire_halt[i] = rob_packet[head_next].halt;
								retire_illegal[i] = rob_packet[head_next].illegal;
								rob_packet_wire[head_next].tag = 0;
								rob_packet_wire[head_next].tag_old = 0;
								rob_packet_wire[head_next].branch_inst = 0;
								rob_packet_wire[head_next].head = 0;
								rob_packet_wire[head_next].completed = 0;
								rob_packet_wire[head_next].take_branch = 0;
								rob_packet_wire[head_next].br_result = 0;
								rob_packet_wire[head_next].PC = 0;
								rob_packet_wire[head_next].halt = 0;
								rob_packet_wire[head_next].illegal = 0;
								rob_packet_wire[head_next].ld_st_bits = 0;
								if(head_next == `N_ROB-1)
									head_next = 0;
								else
									head_next = head_next + 1;
							end
						end else begin
							tmp = 0;
						end
					end
				//end
		end 
		//freeing reg's if branch_haz
		free_list_haz = 0;
		if (branch_haz) begin
			for(int i=0; i<`N_ROB; i=i+1) begin
				free_list_haz[i] = rob_packet_wire[i].tag;		
				rob_packet_wire[i].tag = 0;;		
			end	
		end
		//completer_stage
		for(int i=0; i<`N_WAY; i=i+1) begin
			for(int j=0; j<`N_ROB; j=j+1) begin
			//	if ((rob_packet_wire[j].tag == complete_dest_tag[i]) && (complete_dest_tag[i]!=0) && (!branch_haz)) begin
				if (rob_packet_wire[j].tag!=0 && (((rob_packet_wire[j].tag == complete_dest_tag[i]) && (complete_dest_tag[i]!=0) && (!branch_haz))||rob_packet_wire[j].halt)) begin
					rob_packet_wire[j].completed = 1;
					if(rob_packet_wire[j].branch_inst) begin
						rob_packet_wire[j].take_branch = take_branch[i];
						rob_packet_wire[j].br_result = br_result[i];
					end
				end
			end
		end	
	end


	always_comb begin //dispatch stage logic
		rob_packet_next = rob_packet_wire;
		dispatched = 0 ;	//check zero if no packet is dispatched
		tail_next = tail;
		for(int k=0 ; k<`N_WAY; k=k+1) begin
			if(rob_packet_dis[k].valid) begin
				dispatched[k] = 1; 
				//tmp1 = 0;
				//for(int y=0; y<`N_ROB; y=y+1) begin
					//if(rob_packet_next[y].tail && !tmp1) begin
						rob_packet_next[tail_next].tail = 0;
						//tmp1 = 1;
						//dispatched[k] = 1; 
						if(tail_next == `N_ROB-1) begin
							rob_packet_next[0].tag = rob_packet_dis[k].tag; //compare unique tag in instruction buffer to get the number of inst dispatched each cycle
							rob_packet_next[0].tag_old = rob_packet_dis[k].tag_old; 
							rob_packet_next[0].branch_inst = rob_packet_dis[k].branch_inst; 
							rob_packet_next[0].completed = 0; 
							rob_packet_next[0].take_branch = 0; 
							rob_packet_next[0].br_result = 0; 
							rob_packet_next[0].tail = 1;
							rob_packet_next[0].PC = rob_packet_dis[k].PC;
							rob_packet_next[0].halt = rob_packet_dis[k].halt;
							rob_packet_next[0].illegal = rob_packet_dis[k].illegal;
							rob_packet_next[0].ld_st_bits = rob_packet_dis[k].ld_st_bits;
							tail_next = 0;
						end else begin
							rob_packet_next[tail_next+1].tag = rob_packet_dis[k].tag; 
							rob_packet_next[tail_next+1].tag_old = rob_packet_dis[k].tag_old; 
							rob_packet_next[tail_next+1].branch_inst = rob_packet_dis[k].branch_inst; 
							rob_packet_next[tail_next+1].completed = 0;
							rob_packet_next[tail_next+1].take_branch = 0; 
							rob_packet_next[tail_next+1].br_result = 0; 
							rob_packet_next[tail_next+1].tail = 1;
							rob_packet_next[tail_next+1].PC = rob_packet_dis[k].PC;
							rob_packet_next[tail_next+1].halt = rob_packet_dis[k].halt;
							rob_packet_next[tail_next+1].illegal = rob_packet_dis[k].illegal;
							rob_packet_next[tail_next+1].ld_st_bits = rob_packet_dis[k].ld_st_bits;
							tail_next = tail_next + 1;
						end
					//end
				//end
			end
		end
	end 

	//synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if(reset) begin
			rob_packet<= `SD 0;
			head <= `SD 0;
			tail <= `SD `N_ROB-1;
		end else begin
			if(!branch_haz) begin
			rob_packet <= `SD rob_packet_next;
			head <= `SD head_next;
			tail <= `SD tail_next;
			end else begin
			rob_packet <= `SD 0;
			head <= `SD 0;
			tail <= `SD `N_ROB-1;
			end
		end
	end
endmodule
