

module top_r10k (
	input clock,
	input reset,
	input  DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_packet, //from dispatch stage to rob and rs
	//input [$clog2(`N_WAY):0] dispatch_num, //from dispatch stage to rob and rs
	output  RS_PACKET_ISSUE [`N_WAY-1:0]    rs_packet_issue,
	output  ISSUE_EX_PACKET issue_packet,
	output RS_PACKET   [`N_RS-1:0] rs_data,
	//output logic [$clog2(`N_RS):0]  rs_empty,
	output ROB_PACKET [`N_ROB-1:0] rob_packet,//debug
	//output logic [$clog2(`N_WAY):0] empty_rob, //to dispatch stage
	output logic [`N_WAY-1:0]dispatched,   //to dispatch stage
	output EX_MEM_PACKET [`N_WAY-1 : 0] ex_packet_out,
	//output logic [$clog2(`N_WAY) : 0] free_num, //to dispatch stage
	//debug signals
	output logic [`N_ROB+32-1 : 0] free //debug
	);

	RS_PACKET_DISPATCH [`N_WAY-1:0] rs_packet_dispatch;
	DISPATCH_PACKET[`N_WAY-1:0] dispatch_packet_rob; //generated internally to rob 
	PR_PACKET [`N_WAY-1 : 0] pr_packet_out1; //to reservation station
	PR_PACKET [`N_WAY-1 : 0] pr_packet_out2; //to reservation station
	//logic [`N_WAY-1 : 0] [`CDB_BITS-1 : 0] cdb_tag; // to reservation station
	logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out;
	logic [$clog2(`N_WAY):0] ex_count;
	logic [$clog2(`N_WAY):0] dispatch_num; //generated internally to rob and rs
	logic [$clog2(`N_RS):0]  rs_empty;
	ISSUE_EX_PACKET   [`N_WAY-1 : 0] issue_ex_packet_in;
	logic [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag; //i/p from  execute stage to rob, not latched from the execute stage
	logic   [`N_WAY-1:0] [`CDB_BITS-1:0]  ex_rs_dest_idx,ex_rs_dest_idx_reg; //from issue stage latched 
	logic [$clog2(`N_WAY)-1:0] issue_num,issue_num_reg;
	logic [`N_WAY-1:0] wr_en;
	logic [`N_WAY-1:0][`XLEN-1:0] wr_data;

	always_comb begin
		ex_count = 0 ;
		for (int j=0; j<`N_WAY ; j=j+1) begin
			if(ex_rs_dest_idx[j] > 0)
				ex_count = ex_count + 1;
		end
	end

	always_comb begin // to rs 
		for (int i=0; i<`N_WAY ; i=i+1) begin
			if(dispatch_packet[i].valid) begin
			//	rs_packet_dispatch[i].busy = 1; 
				rs_packet_dispatch[i].inst = dispatch_packet[i].inst;
				//rs_packet_dispatch[i].valid = 1;
				rs_packet_dispatch[i].source_tag_1 = pr_packet_out1[i].phy_reg ;
				rs_packet_dispatch[i].source_tag_1_plus = pr_packet_out1[i].status ;
				rs_packet_dispatch[i].source_tag_2 = pr_packet_out2[i].phy_reg ;
				rs_packet_dispatch[i].source_tag_2_plus = pr_packet_out2[i].status ;
				rs_packet_dispatch[i].dest_tag= free_list_out[i];
				rs_packet_dispatch[i].order_idx = `N_RS - rs_empty - ex_count + i + 1;
				rs_packet_dispatch[i].NPC = dispatch_packet[i].NPC;
				rs_packet_dispatch[i].PC = dispatch_packet[i].PC;
				if(rs_packet_dispatch[i].order_idx <= `N_RS ) begin
					rs_packet_dispatch[i].valid = 1;
					rs_packet_dispatch[i].busy = 1; 
				end else begin
					rs_packet_dispatch[i].valid = 0;
					rs_packet_dispatch[i].busy = 0; 
				end
			end
				
		end
	end

	always_comb begin
		dispatch_num = 0 ;
		for (int k=0; k<`N_WAY ; k=k+1) begin
			dispatch_packet_rob[k].src1 = dispatch_packet[k].src1;
			dispatch_packet_rob[k].src2 = dispatch_packet[k].src2;
			dispatch_packet_rob[k].dest = dispatch_packet[k].dest;
			dispatch_packet_rob[k].valid = rs_packet_dispatch[k].valid && dispatch_packet[k].valid;
			if (dispatch_packet_rob[k].valid) dispatch_num = dispatch_num + 1;
		end
	end
 top_rob top_rob0 (
		.clock(clock), 
                .reset(reset), 
		.complete_dest_tag(complete_dest_tag),
		.dispatch_packet(dispatch_packet_rob), 
		.dispatch_num(dispatch_num), 
		.rob_packet(rob_packet),
		.pr_packet_out1(pr_packet_out1), 
		.pr_packet_out2(pr_packet_out2),
		.dispatched(dispatched),
		.free_list_out(free_list_out),
		//.cdb_tag(cdb_tag),
		.free(free)
        );

reservation_station rs0 (

                  .clock(clock), 
                  .reset(reset),
		  .rs_packet_dispatch(rs_packet_dispatch), //generated internally
		  .ex_rs_dest_idx(ex_rs_dest_idx_reg), //from ex stage
		  .cdb_rs_reg_idx(complete_dest_tag),
		  .issue_num(issue_num_reg), //from issue stage
		  .dispatched_rob(dispatched),
		  .rs_packet_issue(rs_packet_issue), //to issue stage
		  .rs_data(rs_data), //debug
		  .rs_empty(rs_empty) // to dispatch stage 
                  );


issue_stage		is0 (
		.clock(clock),
		.reset(reset),
		.rs_packet_issue(rs_packet_issue),
		.wb_reg_wr_en_out(wr_en),
		.wb_reg_wr_idx_out(complete_dest_tag),
		.wb_reg_wr_data_out(wr_data),
		.issue_packet(issue_packet),
		.issue_num(issue_num),
		.ex_dest_tag(ex_rs_dest_idx)
);

	always_ff @(posedge clock) begin
		if(reset)begin
			issue_ex_packet_in <= `SD 0;
			issue_num_reg <= `SD 0;
			ex_rs_dest_idx_reg <= `SD 0;
		end else begin
			issue_ex_packet_in <= `SD issue_packet;
			issue_num_reg <= `SD issue_num;
			ex_rs_dest_idx_reg <= `SD ex_rs_dest_idx;
		end
	end

ex_stage ex0 (
		.clock(clock),
		.reset(reset),
		.issue_ex_packet_in(issue_ex_packet_in),
		.complete_dest_tag(complete_dest_tag),
		.reg_wr_en_out(wr_en),
		.ex_result_out(wr_data),
		.ex_packet_out(ex_packet_out)
);
endmodule

