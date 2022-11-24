//ROB
//
module rob (
	input clock,
	input reset,
	input [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag,
	input take_branch, //from ex stage
	input [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_result,
	input  ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis,
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag, 
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told,
	output logic [`N_WAY-1:0]retire_valid,
	output logic [`N_WAY-1:0]dispatched,
	output logic branch_haz,
	output logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_target_pc,
	output logic [`N_ROB-1:0][`CDB_BITS-1:0] free_list_haz, //input to freelist
	output ROB_PACKET [`N_ROB-1:0] rob_packet,
	output logic [$clog2(`N_WAY):0] empty_rob,
	output logic [$clog2(`N_WAY):0] store_num_ret //from rob, make zero in rob for branch hazard
);
	ROB_PACKET [`N_ROB-1:0] rob_packet_next;
	ROB_PACKET [`N_ROB-1:0] rob_packet_wire;
	//ROB_PACKET [`N_ROB-1:0] rob_packet;
	logic [$clog2(`N_ROB):0] empty_rob_reg, empty_rob_wire, empty_rob_next;
	logic tmp, tmp1;

	assign empty_rob = (empty_rob_wire <=`N_WAY ) ?  empty_rob_wire : `N_WAY;
 

	always_comb begin
		rob_packet_wire = rob_packet;
		retire_valid = 0 ;		
		retire_tag =  0;		
		retire_told = 0;
		branch_haz = 0;
		empty_rob_wire = empty_rob_reg;		
		store_num_ret = 0;
		//retire_stage
		for(int i=0; i<`N_WAY; i=i+1) begin	
			tmp = 0;
				for(int j=0; j<`N_ROB; j=j+1) begin
					if(!tmp && !branch_haz) begin
						if((rob_packet_wire[j].head) && rob_packet[j].completed ) begin
							if (rob_packet[j].branch_inst && rob_packet[j].take_branch) begin
								branch_haz = rob_packet[j].take_branch;
								br_target_pc = rob_packet[j].br_result;
								empty_rob_wire = `N_ROB; 
								for(int k=0; k<`N_ROB; k=k+1) begin
									if(branch_haz) begin
										rob_packet_wire[k].completed = 0;
										rob_packet_wire[k].branch_inst = 0;
										rob_packet_wire[k].take_branch = 0;
										rob_packet_wire[k].br_result = 0;
										rob_packet_wire[k].ld_st_bits = 0;
										if (k==0)        rob_packet_wire[k].head =  1;
										else             rob_packet_wire[k].head =  0;
										if (k==`N_ROB-1) rob_packet_wire[k].tail =  1;
										else             rob_packet_wire[k].tail =  0;
									end
								end
							end
							if(!branch_haz) begin
								if(rob_packet[j].ld_st_bits == 2'b01) store_num_ret = store_num_ret + 1;
								if(rob_packet[j].tag_old != `ZERO_REG_PR) begin
									retire_valid[i] = 1 ;		
									retire_tag[i] = rob_packet[j].tag ;		
									retire_told[i] = rob_packet[j].tag_old ;
								end else begin
									retire_valid[i] = 0 ;		
									retire_told[i] = rob_packet[j].tag ;
								end
								if(j == `N_ROB-1)
									rob_packet_wire[0].head = 1;
								else
									rob_packet_wire[j+1].head = 1;
								rob_packet_wire[j].tag = 0;
								rob_packet_wire[j].tag_old = 0;
								rob_packet_wire[j].branch_inst = 0;
								rob_packet_wire[j].head = 0;
								rob_packet_wire[j].completed = 0;
								rob_packet_wire[j].take_branch = 0;
								rob_packet_wire[j].br_result = 0;
								rob_packet_wire[j].ld_st_bits = 0;
								empty_rob_wire = empty_rob_wire + 1;	
							end
							tmp = 1;
						end
					end
				end
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
				if ((rob_packet_wire[j].tag == complete_dest_tag[i]) && (complete_dest_tag[i]!=0) && (!branch_haz)) begin
					rob_packet_wire[j].completed = 1;
					if(rob_packet_wire[j].branch_inst) begin
						rob_packet_wire[j].take_branch = take_branch;
						rob_packet_wire[j].br_result = br_result;
					end
				end
			end
		end	
	end


	always_comb begin //dispatch stage logic
		rob_packet_next = rob_packet_wire;
		empty_rob_next =  empty_rob_wire;
		dispatched = 0 ;	//check zero if no packet is dispatched
		for(int k=0 ; k<`N_WAY; k=k+1) begin
			if(rob_packet_dis[k].valid) begin
				tmp1 = 0;
				for(int y=0; y<`N_ROB; y=y+1) begin
					if(rob_packet_next[y].tail && !tmp1) begin
						rob_packet_next[y].tail = 0;
						empty_rob_next =empty_rob_next - 1;
						tmp1 = 1;
						dispatched[k] = 1; 
						if(y == `N_ROB-1) begin
							rob_packet_next[0].tag = rob_packet_dis[k].tag; //compare unique tag in instruction buffer to get the number of inst dispatched each cycle
							rob_packet_next[0].tag_old = rob_packet_dis[k].tag_old; 
							rob_packet_next[0].branch_inst = rob_packet_dis[k].branch_inst; 
							rob_packet_next[0].completed = 0; 
							rob_packet_next[0].take_branch = 0; 
							rob_packet_next[0].br_result = 0; 
							rob_packet_next[0].tail = 1;
							rob_packet_next[0].ld_st_bits = rob_packet_dis[k].ld_st_bits;
						end else begin
							rob_packet_next[y+1].tag = rob_packet_dis[k].tag; 
							rob_packet_next[y+1].tag_old = rob_packet_dis[k].tag_old; 
							rob_packet_next[y+1].branch_inst = rob_packet_dis[k].branch_inst; 
							rob_packet_next[y+1].completed = 0; 
							rob_packet_next[y+1].take_branch = 0; 
							rob_packet_next[y+1].br_result = 0; 
							rob_packet_next[y+1].tail = 1; 
							rob_packet_next[y+1].ld_st_bits = rob_packet_dis[k].ld_st_bits;
						end
					end
				end
			end
		end
	end 

	always_ff @(posedge clock) begin
		if(reset) begin
			for (int m=0; m<`N_ROB; m=m+1) begin
				rob_packet[m].tag <= `SD 0;
				rob_packet[m].tag_old <= `SD 0;
				rob_packet[m].completed <= `SD 0;
				rob_packet[m].branch_inst <= `SD 0;
				rob_packet[m].take_branch <= `SD 0;
				rob_packet[m].br_result <= `SD 0;
				rob_packet[m].ld_st_bits <= `SD 0;
				if (m==0) 
				rob_packet[m].head <= `SD 1;
				else 
				rob_packet[m].head <= `SD 0;
				if (m==`N_ROB-1) 
				rob_packet[m].tail <= `SD 1;
				else 
				rob_packet[m].tail <= `SD 0;
			end
			empty_rob_reg <= `SD `N_ROB;
		end else begin
			rob_packet <= `SD rob_packet_next;
			empty_rob_reg <= `SD empty_rob_next;
		end
	end
endmodule
