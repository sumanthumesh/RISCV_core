

module top_r10k (
	input clock,
	input reset,
        input [3:0]  mem2proc_response,
        input [63:0] mem2proc_data,
        input [3:0]  mem2proc_tag,
	input flush,
	//input [$clog2(`N_WAY):0] dispatch_num, //from dispatch stage to rob and rs
	output  RS_PACKET_ISSUE [`N_WAY-1:0]    rs_packet_issue,
	output  ISSUE_EX_PACKET [`N_WAY-1:0]  issue_packet,
	output RS_PACKET   [`N_RS-1:0] rs_data,
	//output logic [$clog2(`N_RS):0]  rs_empty,
	output ROB_PACKET [`N_ROB-1:0] rob_packet,//debug
	//output logic [$clog2(`N_WAY):0] empty_rob, //to dispatch stage
	output logic [`N_WAY-1:0]dispatched,   //to dispatch stage
	output logic branch_haz,
	output logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_target_pc,
	output EX_MEM_PACKET [`N_WAY-1 : 0] ex_packet_out,
	//output logic [$clog2(`N_WAY) : 0] free_num, //to dispatch stage
	//debug signals
	output logic [`N_ROB+32-1 : 0] free, //debug
	output logic [`N_WAY-1:0] wr_en,
	output logic [`N_WAY-1:0][`XLEN-1:0] wr_data,
	output logic [`N_WAY-1:0] [`CDB_BITS-1:0] complete_dest_tag,
	output logic [`XLEN-1:0][`CDB_BITS-1:0] arch_reg_next,
	output logic retire_branch,
	output logic [`XLEN-1:0] retire_branch_PC,
	output RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet,
	output logic [1:0] mem_command,
	output logic [63:0] mem_data, 
	output logic [`XLEN-1:0] mem_addr,
	output logic all_mshr_requests_processed_reg
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
	logic   [`N_WAY-1:0] [`CDB_BITS-1:0]  ex_rs_dest_idx,ex_rs_dest_idx_reg; //from issue stage latched 
	logic [$clog2(`N_WAY):0] issue_num,issue_num_reg;
	logic [`N_WAY-1 : 0] take_branch_ex;
	logic [`N_WAY-1 : 0] [`XLEN-1:0] br_result;

//////icache integration with pipeline
	DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_packet; //from dispatch stage to rob and rs
	logic [`N_WAY-1:0] branch_inst; // BRANCH instruction identification

 	logic [`N_WAY-1:0][`XLEN-1:0] Icache_data_out; 
 	logic [`N_WAY-1:0][`XLEN-1:0] Icache_addr_out; 
        logic [`N_WAY-1:0] Icache_valid_out;    
        logic [$clog2(`N_WAY):0] Icache_hit_count;  
	logic [`XLEN-1:0] buff2Icache_addr; //Address or PC to fetch instructions from
	logic [$clog2(`N_WAY):0] buff2Icache_count; //Num of instructions that buff wants
	logic [`N_WAY-1:0][`XLEN-1:0] buff2proc_addr;
	logic [`N_WAY-1:0][`XLEN-1:0] buff2proc_data;
	logic [`N_WAY-1:0] buff2proc_valid;
        logic [`XLEN-1:0] proc2Icache_addr; 
        logic [`N_WAY-1:0][`XLEN-1:0] Icache_data_out; 
        logic [`N_WAY-1:0] Icache_valid_out;    
    	logic [`N_WAY-1:0][`XLEN-1:0] out_PC;
	logic [`N_WAY-1:0][`XLEN-1:0] out_NPC;
	INST [`N_WAY-1:0] out_inst;
	logic [`N_WAY-1:0][`XLEN_BITS-1:0] src1;
	logic [`N_WAY-1:0][`XLEN_BITS-1:0] src2;
	logic [`N_WAY-1:0][`XLEN_BITS-1:0] dest;
	logic [`N_WAY-1:0] is_branch;
	logic [`N_WAY-1:0] halt;
	logic [`N_WAY-1:0] out_valid;
	logic [`N_WAY-1:0] illegal;


///////storeq and loadq
//
	logic [`N_WAY-1:0][1:0] ld_st_bits;
	logic [$clog2(`N_WAY):0] store_num_dis; //from dispatch,  make zero in rob for branch hazard
		
	logic [$clog2(`N_SQ):0] empty_storeq,empty_storeq_wire;
	logic [$clog2(`N_SQ):0] storeq_idx, storeq_idx_wire;
	logic [`N_WAY-1:0][$clog2(`N_SQ):0] store_order_idx_in;
	logic [$clog2(`N_WAY):0] store_num_ret; //from rob, make zero in rob for branch hazard
	logic [$clog2(`N_SQ):0] last_str_ex_idx;


//////icache integration with pipeline
	DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_packet; //from dispatch stage to rob and rs
	logic [`N_WAY-1:0] branch_inst; // BRANCH instruction identification

 	logic [`N_WAY-1:0][`XLEN-1:0] Icache_data_out; 
 	logic [`N_WAY-1:0][`XLEN-1:0] Icache_addr_out; 
    logic [`N_WAY-1:0] Icache_valid_out;    
    logic [$clog2(`N_WAY):0] Icache_hit_count;  
	logic [`XLEN-1:0] buff2Icache_addr; //Address or PC to fetch instructions from
	logic [$clog2(`N_WAY):0] buff2Icache_count; //Num of instructions that buff wants
	logic [`N_WAY-1:0][`XLEN-1:0] buff2proc_addr;
	logic [`N_WAY-1:0][`XLEN-1:0] buff2proc_data;
	logic [`N_WAY-1:0] buff2proc_valid;
    logic [`XLEN-1:0] proc2Icache_addr; 
    logic [`N_WAY-1:0][`XLEN-1:0] Icache_data_out; 
    logic [`N_WAY-1:0] Icache_valid_out;    
    //ICACHE_PACKET [`CACHE_LINES-1:0] icache_data;
    //STORE_REQ [`N_WAY-1:0] saved_reqs;
    //STORE_REQ [`N_WAY-1:0] saved_reqs_d; 
    //logic disp_queue_empty; 
    //logic data_out_valid;
    //logic queue_wr_en;
    //DISP_REQ queue_data_in;
    //DISP_REQ queue_data_out;
    //DISP_REQ delayed_fetch;
    //logic [63:0] data_to_place_in_cache;
    //logic queue_data_out_valid;
	logic [`N_WAY-1:0][`XLEN-1:0] out_PC;
	logic [`N_WAY-1:0][`XLEN-1:0] out_NPC;
	INST [`N_WAY-1:0] out_inst;
	logic [`N_WAY-1:0][`XLEN_BITS-1:0] src1;
	logic [`N_WAY-1:0][`XLEN_BITS-1:0] src2;
	logic [`N_WAY-1:0][`XLEN_BITS-1:0] dest;
	logic [`N_WAY-1:0] is_branch;
	logic [`N_WAY-1:0] halt;
	logic [`N_WAY-1:0] out_valid;
	logic [`N_WAY-1:0] illegal;
	logic mode_mem; 	// controls which would go into command port of memory
	logic [`XLEN-1:0] dcache2mem_addr;
	logic [1:0] dcache2mem_command;
	logic [63:0] dcache2mem_data;
        logic [1:0] proc2Imem_command;
        logic [`XLEN-1:0] proc2Imem_addr;
	logic enable_icache;
	logic [$clog2(`N_WAY):0] count_st;
	logic flush_ex_stage;
	
	//icache and dcache mux with memory
	//i/p mux
	always_comb begin
		assign mode_mem = (dcache2mem_command != BUS_NONE) ? 1 : 0;
		assign mem_command = mode_mem ? dcache2mem_command : proc2Imem_command;
		assign mem_data = dcache2mem_data;
		assign mem_addr = mode_mem ? dcache2mem_addr : proc2Imem_addr;
	end
	assign enable_icache = !mode_mem;
	
	always_comb begin
		ex_count = 0 ;
		for (int j=0; j<`N_WAY ; j=j+1) begin
			if(ex_rs_dest_idx_reg[j] > 0)
				ex_count = ex_count + 1;
		end
	end

	always_comb begin //can be latched
		for (int i=0; i<`N_WAY ; i=i+1) begin
			if(!branch_haz) begin
				dispatch_packet[i].src1 = src1[i]; 
				dispatch_packet[i].src2 = src2[i]; 
				dispatch_packet[i].dest = dest[i]; 
				dispatch_packet[i].inst = out_inst[i]; 
				dispatch_packet[i].valid = out_valid[i]; 
				dispatch_packet[i].PC = out_PC[i]; 
				dispatch_packet[i].NPC = out_NPC[i]; 
				dispatch_packet[i].halt= halt[i]; 
				dispatch_packet[i].illegal = illegal[i];
				branch_inst[i] = is_branch[i];
				dispatch_packet[i].ld_st_bits = ld_st_bits[i]; 
			end else begin
				dispatch_packet[i].src1 = 0; 
				dispatch_packet[i].src2 = 0; 
				dispatch_packet[i].dest = 0; 
				dispatch_packet[i].inst = 0; 
				dispatch_packet[i].valid = 0; 
				dispatch_packet[i].PC = 0; 
				dispatch_packet[i].NPC = 0; 
				dispatch_packet[i].halt= 0; 
				dispatch_packet[i].illegal = 0;
				branch_inst[i] = 0; 
				dispatch_packet[i].ld_st_bits =0; 
			end
		end	
	end

	always_comb begin // to rs
		storeq_idx_wire = storeq_idx;
		empty_storeq_wire = empty_storeq;
		store_num_dis = 0; 
		count_st = 0;
		for (int i=0; i<`N_WAY ; i=i+1) begin
			if(dispatch_packet[i].valid) begin
				rs_packet_dispatch[i].inst = dispatch_packet[i].inst;
				rs_packet_dispatch[i].source_tag_1 = pr_packet_out1[i].phy_reg ;
				rs_packet_dispatch[i].source_tag_1_plus = pr_packet_out1[i].status ;
				rs_packet_dispatch[i].source_tag_2 = pr_packet_out2[i].phy_reg ;
				rs_packet_dispatch[i].source_tag_2_plus = pr_packet_out2[i].status ;
				rs_packet_dispatch[i].dest_tag= free_list_out[i];
				rs_packet_dispatch[i].ld_st_bits=dispatch_packet[i].ld_st_bits;
				rs_packet_dispatch[i].order_idx = `N_RS - rs_empty - ex_count + i + 1;
				rs_packet_dispatch[i].NPC = dispatch_packet[i].NPC;
				rs_packet_dispatch[i].PC = dispatch_packet[i].PC;
				if(dispatch_packet[i].ld_st_bits == 2'b10) begin //for load postion
					rs_packet_dispatch[i].storeq_idx = storeq_idx_wire;
				end
				//for store position
				if(dispatch_packet[i].ld_st_bits == 2'b01 && (empty_storeq_wire > 0)) begin
					if(dispatched[i]) begin
						if(storeq_idx_wire < `N_SQ) 
							storeq_idx_wire = storeq_idx_wire + 1;
						else
							storeq_idx_wire = 1;
					end else begin
						storeq_idx_wire = storeq_idx;
					end
					rs_packet_dispatch[i].storeq_idx = storeq_idx_wire;
					empty_storeq_wire = empty_storeq_wire -1;
					store_num_dis = store_num_dis + 1;
					store_order_idx_in[count_st] = `N_SQ - empty_storeq_wire;
					count_st = count_st + 1;
				end
				if((rs_packet_dispatch[i].ld_st_bits == 2'b01) && (empty_storeq_wire == 0) ) begin
					rs_packet_dispatch[i].valid = 0;
					rs_packet_dispatch[i].busy = 0; 
				end else begin
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
	end

	always_comb begin
		dispatch_num = 0 ;
		for (int k=0; k<`N_WAY ; k=k+1) begin
			dispatch_packet_rob[k].PC = dispatch_packet[k].PC;
			dispatch_packet_rob[k].illegal = dispatch_packet[k].illegal;
			dispatch_packet_rob[k].halt = dispatch_packet[k].halt;
			dispatch_packet_rob[k].src1 = dispatch_packet[k].src1;
			dispatch_packet_rob[k].src2 = dispatch_packet[k].src2;
			dispatch_packet_rob[k].dest = dispatch_packet[k].dest;
			dispatch_packet_rob[k].ld_st_bits=dispatch_packet[k].ld_st_bits;
			dispatch_packet_rob[k].valid = rs_packet_dispatch[k].valid && dispatch_packet[k].valid;
			if (dispatch_packet_rob[k].valid) dispatch_num = dispatch_num + 1;
		end
	end

 

icache icache(.clock(clock),
               .reset(reset),
    		.enable(enable_icache),
               .Imem2proc_response(mem2proc_response),
               .Imem2proc_data(mem2proc_data),
               .Imem2proc_tag(mem2proc_tag),
               .proc2Icache_addr(proc2Icache_addr),
               .proc2Icache_count(buff2Icache_count),
               .proc2Imem_command(proc2Imem_command),
               .proc2Imem_addr(proc2Imem_addr),
               .Icache_data_out(Icache_data_out),
               .Icache_addr_out(Icache_addr_out),
               .Icache_valid_out(Icache_valid_out),
               .Icache_hit_count(Icache_hit_count));
               

 instruction_buffer inst_buff(
			   .clock(clock),
              		   .reset(reset),
			   .enable(1'b1),
			   .Icache2buff_addr(Icache_addr_out),
              		   .Icache2buff_data(Icache_data_out),
              		   .Icache2buff_valid(Icache_valid_out),
              		   .Icache2buff_hit_count(Icache_hit_count),
              		   .branch_taken(branch_haz),
              		   .branch_addr(br_target_pc),
			   .proc2buff_dispatched(dispatched),//from top r10k --> dispatched
        	           .buff2Icache_addr(buff2Icache_addr),//maybe for branch ??
			   .buff2Icache_count(buff2Icache_count),
        		   .pc_wire(proc2Icache_addr),
			   .buff2proc_addr(buff2proc_addr),
			   .buff2proc_data(buff2proc_data),
			   .buff2proc_valid(buff2proc_valid)
	);

instruction_decoder instruction_decoder(
		.input_PC(buff2proc_addr),
		.input_inst(buff2proc_data),
		.in_valid(buff2proc_valid),
		//outputs
		.out_PC(out_PC),
		.out_NPC(out_NPC),
		.out_inst(out_inst),
		.src1(src1),
		.src2(src2),
		.dest(dest),
		.is_branch(is_branch),
		.halt(halt),
		.out_valid(out_valid),
		.illegal(illegal),
		.ld_st_bits(ld_st_bits)
	);

 top_rob top_rob0 (
		.clock(clock), 
                .reset(reset), 
		.complete_dest_tag(complete_dest_tag),
		.dispatch_packet(dispatch_packet_rob), 
		.branch_inst(branch_inst),
		.take_branch(take_branch_ex),
		.br_result(br_result),
		.dispatch_num(dispatch_num), 
		.rob_packet(rob_packet),
		.pr_packet_out1(pr_packet_out1), 
		.pr_packet_out2(pr_packet_out2),
		.dispatched(dispatched),
		.branch_haz(branch_haz),
		.br_target_pc(br_target_pc),
		.free_list_out(free_list_out),
		.free(free),
		.retire_packet(retire_packet),
		.retire_branch(retire_branch),
		.retire_branch_PC(retire_branch_PC),
		.arch_reg_next(arch_reg_next),
		.store_num_ret(store_num_ret)
        );

reservation_station rs0 (

                  .clock(clock), 
                  .reset(reset),
		  .rs_packet_dispatch(rs_packet_dispatch), //generated internally
		  .branch_haz(branch_haz),
		  .last_str_ex_idx(last_str_ex_idx), //from sq module in ex stage
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
			issue_num_reg <= `SD 0;
			storeq_idx <= `SD 0;
			for(int i=0; i<`N_WAY; i=i+1)begin
				issue_ex_packet_in[i] <= `SD 0;
				ex_rs_dest_idx_reg[i] <= `SD 0;
			end
			flush_ex_stage <= `SD 0;
		end else begin
			if(!branch_haz) begin
				issue_num_reg <= `SD issue_num;
				storeq_idx <= `SD storeq_idx_wire;
			end else begin
				issue_num_reg <= `SD 0;
				storeq_idx <= `SD 0;
			end
			for(int i=0; i<`N_WAY; i=i+1)begin
				if(!branch_haz) begin
					issue_ex_packet_in[i] <= `SD issue_packet[i];
					ex_rs_dest_idx_reg[i] <= `SD ex_rs_dest_idx[i];
				end else begin
					issue_ex_packet_in[i] <= `SD 0;
					ex_rs_dest_idx_reg[i] <= `SD 0;
				end
			end
			flush_ex_stage <= `SD flush;
		end
	end

ex_stage ex0 (
		.clock(clock),
		.reset(reset),
		.store_order_idx_in(store_order_idx_in),
		.store_num_dis(store_num_dis),
		.store_num_ret(store_num_ret),
		.branch_haz(branch_haz),
		.issue_ex_packet_in(issue_ex_packet_in),
		.complete_dest_tag(complete_dest_tag),
		.reg_wr_en_out(wr_en),
		.ex_result_out(wr_data),
		.take_branch_out(take_branch_ex),
		.br_result(br_result),
		.ex_packet_out(ex_packet_out),
		.empty_storeq(empty_storeq),
		.last_str_ex_idx(last_str_ex_idx),
	        .dcache2mem_addr(dcache2mem_addr),
	        .dcache2mem_command(dcache2mem_command),
	        .mem2dcache_response(mem2proc_response),
	        .mem2dcache_data(mem2proc_data),
	        .mem2dcache_tag(mem2proc_tag),
	    .dcache2mem_data(dcache2mem_data),
		.flush(flush_ex_stage),
		.all_mshr_requests_processed_reg(all_mshr_requests_processed_reg)
);
endmodule

