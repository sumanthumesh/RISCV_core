/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench.v                                         //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

import "DPI-C" function void print_header(string str);
import "DPI-C" function void print_cycles();
import "DPI-C" function void print_stage(string div, int inst, int npc, int valid_inst);
import "DPI-C" function void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                                       int wb_reg_wr_idx_out, int wb_reg_wr_en_out);
import "DPI-C" function void print_membus(int proc2mem_command, int mem2proc_response,
                                          int proc2mem_addr_hi, int proc2mem_addr_lo,
						 			     int proc2mem_data_hi, int proc2mem_data_lo);
import "DPI-C" function void print_close();


module testbench;

	// variables used in the testbench
//	logic        clock;
//	logic        reset;
	logic [31:0] clock_count;
	logic [31:0] instr_count;
	logic [31:0] final_clock_count;
	logic [31:0] final_instr_count;
	int          wb_fileno;
	
//	logic [1:0]  proc2mem_command;
//	logic [`XLEN-1:0] proc2mem_addr;
//	logic [63:0] proc2mem_data;
//	logic  [3:0] mem2proc_response;
//	logic [63:0] mem2proc_data;
//	logic  [3:0] mem2proc_tag;
//`ifndef CACHE_MODE
//	MEM_SIZE     proc2mem_size;
//`endif
 	logic  [$clog2(`N_WAY):0] pipeline_retired_insts;
//	EXCEPTION_CODE   pipeline_error_status;
//	logic  [4:0] pipeline_commit_wr_idx;
//	logic [`XLEN-1:0] pipeline_commit_wr_data;
//	logic        pipeline_commit_wr_en;
//	logic [`XLEN-1:0] pipeline_commit_NPC;
//	
//	
//	logic [`XLEN-1:0] if_NPC_out;
//	logic [31:0] if_IR_out;
//	logic        if_valid_inst_out;
//	logic [`XLEN-1:0] if_id_NPC;
//	logic [31:0] if_id_IR;
//	logic        if_id_valid_inst;
//	logic [`XLEN-1:0] id_ex_NPC;
//	logic [31:0] id_ex_IR;
//	logic        id_ex_valid_inst;
//	logic [`XLEN-1:0] ex_mem_NPC;
//	logic [31:0] ex_mem_IR;
//	logic        ex_mem_valid_inst;
//	logic [`XLEN-1:0] mem_wb_NPC;
//	logic [31:0] mem_wb_IR;
//	logic        mem_wb_valid_inst;
	logic clock;
	logic reset;
	DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_packet;
	RS_PACKET_ISSUE [`N_WAY-1:0]    rs_packet_issue;
	ISSUE_EX_PACKET [`N_WAY-1:0]  issue_packet;
	RS_PACKET   [`N_RS-1:0] rs_data;
	ROB_PACKET [`N_ROB-1:0] rob_packet;
	logic [`N_WAY-1:0]dispatched;
	EX_MEM_PACKET [`N_WAY-1 : 0] ex_packet_out;
	logic [`N_ROB+32-1 : 0] free;
	RETIRE_ROB_PACKET [`N_WAY-1:0] retire_packet;
	logic [`N_WAY-1:0] reg_wr_en;
	logic [`N_WAY-1:0][`XLEN-1:0] reg_wr_data;
	logic [`N_WAY-1:0] [`CDB_BITS-1:0] reg_complete_dest_tag;
	logic [`XLEN-1:0][`CDB_BITS-1:0] arch_reg_next;

    //counter used for when pipeline infinite loops, forces termination
    logic [63:0] debug_counter;


	logic	[`N_PHY_REG:0][`XLEN-1:0] reg_data_lookup;
	logic [`N_WAY-1:0] branch_inst; // BRANCH instruction identification


	logic branch_haz;
	logic retire_branch;
	logic [`XLEN-1:0] retire_branch_PC;
	logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_result;
	logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_target_pc;

	logic [5:0] j;
	logic [5:0] k;
	
	logic found;

	logic [`CDB_BITS-1:0] tag;
	logic [`CDB_BITS-1:0] retire_packet_tag;
	logic tmp;

	logic retire_packet_halt;
	logic retire_packet_illegal;


////memory connectionsw
 
	logic [1:0] imem_command;
	logic mode_mem; 	// controls which would go into command port of memory
	logic [1:0] ex_command;
	logic [63:0] imem_data, ex_data;
	logic [`XLEN-1:0] imem_addr, ex_addr;
        logic [3:0]  mem2proc_response;
        logic [63:0] mem2proc_data;
        logic [3:0]  mem2proc_tag;
        logic [1:0] proc2Imem_command;
        logic [`XLEN-1:0] proc2Imem_addr;
	logic [1:0] mem_command;
	logic [63:0] mem_data;
	logic [`XLEN-1:0] mem_addr;
	logic all_mshr_requests_processed_reg;
	logic flush;

	//assign imem_command = mode_mem ? dcache2mem_command : proc2Imem_command;
	//assign imem_data = dcache2mem_data;
	//assign imem_addr = mode_mem ? dcache2mem_addr : proc2Imem_addr;



	top_r10k dut(
		.clock(clock),
		.reset(reset),
		.mem2proc_response(mem2proc_response),
		.mem2proc_data(mem2proc_data),
		.mem2proc_tag(mem2proc_tag),
		//.dispatch_packet(dispatch_packet),
		//.branch_inst(branch_inst),
		.rs_packet_issue(rs_packet_issue),
		.issue_packet(issue_packet),
		.rs_data(rs_data),
		.rob_packet(rob_packet),
		.dispatched(dispatched),
		.ex_packet_out(ex_packet_out),
		.free(free),
		.retire_packet(retire_packet),
		.retire_branch(retire_branch),
		.retire_branch_PC(retire_branch_PC),
		.wr_en(reg_wr_en),
		.wr_data(reg_wr_data),
		.complete_dest_tag(reg_complete_dest_tag),
		.arch_reg_next(arch_reg_next),
		.branch_haz(branch_haz),
		.br_target_pc(br_target_pc),
		.mem_command(mem_command),
		.mem_data(mem_data),
		.mem_addr(mem_addr),
		.flush(flush),
		.all_mshr_requests_processed_reg(all_mshr_requests_processed_reg)
	);

//	program_dispatch pd0 (
//		.clock(clock),
//		.reset(reset),
//		.dispatched(dispatched),
//		.dispatch_out(dispatch_packet),
//		.branch_haz(branch_haz),
//		.br_result(br_target_pc),
//		.branch_inst(branch_inst)
//		);
	
	
	
	// Instantiate the Data Memory
	mem memory(.clk(clock),
               .proc2mem_addr(mem_addr),
               .proc2mem_data(mem_data),
               .proc2mem_command(mem_command),
               .mem2proc_response(mem2proc_response),
               .mem2proc_data(mem2proc_data),
               .mem2proc_tag(mem2proc_tag));

	
//	mem memory (
//		// Inputs
//		.clk               (clock),
//		.proc2mem_command  (proc2mem_command),
//		.proc2mem_addr     (proc2mem_addr),
//		.proc2mem_data     (proc2mem_data),
//`ifndef CACHE_MODE
//		.proc2mem_size     (proc2mem_size),
//`endif
//
//		// Outputs
//
//		.mem2proc_response (mem2proc_response),
//		.mem2proc_data     (mem2proc_data),
//		.mem2proc_tag      (mem2proc_tag)
//	);
	
	// Generate System Clock
	always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	
	// Task to display # of elapsed clock edges
	task show_clk_count;
		real cpi;
		
		begin
			cpi = (final_clock_count + 1.0) / final_instr_count;
			$display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
			          final_clock_count+1, final_instr_count, cpi);
			$display("@@  %4.2f ns total time to execute\n@@\n",
			          final_clock_count*`VERILOG_CLOCK_PERIOD);
		end
	endtask  // task show_clk_count

 
	task print_rob_packet;
		begin
			$display("|TAG    |TAG_OLD|BRANCH_INST|HEAD|TAIL|COMPLETED|TAKE_BRANCH|PC      |HALT|ILLEGAL|");
			for(int i = 0; i < `N_ROB; i++)
			begin
				$display("|%07h|%07h|%b          |%b   |%b   |%b        |%b          |%08h|%b   |%b      |", 
                        rob_packet[i].tag,
						rob_packet[i].tag_old,
						rob_packet[i].branch_inst,
						rob_packet[i].head,
						rob_packet[i].tail,
						rob_packet[i].completed,
						rob_packet[i].take_branch,
						rob_packet[i].PC,
						rob_packet[i].halt,
						rob_packet[i].illegal);
			end

		end
	endtask

	task print_arch_table;
		begin
			$display("|ARCH_REG|PHY_REG |");
			for(int i = 0; i < `XLEN; i++)
			begin
				$display("|%02d      |%08h|", 
                        i,
						arch_reg_next[i]);
			end

		end
	endtask
	
	// Show contents of a range of Unified Memory, in both hex and decimal
	task show_mem_with_decimal;
		input [31:0] start_addr;
		input [31:0] end_addr;
		int showing_data;
		begin
			$display("@@@");
			showing_data=0;
			for(int k=start_addr;k<=end_addr; k=k+1)
				if (memory.unified_memory[k] != 0) begin
					$display("@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k], 
				                                            memory.unified_memory[k]);
					showing_data=1;
				end else if(showing_data!=0) begin
					$display("@@@");
					showing_data=0;
				end
			$display("@@@");
		end
	endtask  // task show_mem_with_decimal
	
	initial begin
		//$dumpvars;
	
		clock = 1'b0;
		reset = 1'b0;
		mode_mem = 1'b0;
		ex_data = 0;
		ex_addr= 0;
		ex_command = 0;
		flush = 0;
		
		// Pulse the reset signal
		$display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
		reset = 1'b1;
		@(posedge clock);
		@(posedge clock);
		
		$readmemh("program.mem", memory.unified_memory);
		
		@(posedge clock);
		@(posedge clock);
		`SD;
		// This reset is at an odd time to avoid the pos & neg clock edges
		
		reset = 1'b0;
		$display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);
		
		wb_fileno = $fopen("writeback.out");
		
		//Open header AFTER throwing the reset otherwise the reset state is displayed
		print_header("                                                                            D-MEM Bus &\n");
		print_header("Cycle:      IF      |     ID      |     EX      |     MEM     |     WB      Reg Result");
	end


	always_comb
	begin
		for(int i = 0; i < `N_WAY; i++)
		begin
			if(retire_packet[i].illegal) 
			begin
				retire_packet_illegal = 1;
				retire_packet_halt = 0;
			end
			else if(retire_packet[i].halt)
			begin
				retire_packet_halt = 1;
				retire_packet_illegal = 0;
			end
		end
		

	end



	// Count the number of posedges and number of instructions completed
	// till simulation ends
	always @(posedge clock) begin
		if(reset) begin
			clock_count <= `SD 0;
			instr_count <= `SD 0;
		end else begin
			clock_count <= `SD (clock_count + 1);
			instr_count <= `SD (instr_count + pipeline_retired_insts);
		end
	end 

	always_comb
	begin
		pipeline_retired_insts = 0;
		for(int i = 0;i < `N_WAY; i++)
		begin
			if(retire_packet[i].ret_valid)
				pipeline_retired_insts = pipeline_retired_insts + 1;
		end
	end
	
 
	
	
	always @(negedge clock) begin
        if(reset) begin
			$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
			         $realtime);
            debug_counter <= 0;
        end else begin
			`SD;
			`SD;
			
			 // print the piepline stuff via c code to the pipeline.out
		//	 print_cycles();
		//	 print_stage(" ", if_IR_out, if_NPC_out[31:0], {31'b0,if_valid_inst_out});
		//	 print_stage("|", if_id_IR, if_id_NPC[31:0], {31'b0,if_id_valid_inst});
		//	 print_stage("|", id_ex_IR, id_ex_NPC[31:0], {31'b0,id_ex_valid_inst});
		//	 print_stage("|", ex_mem_IR, ex_mem_NPC[31:0], {31'b0,ex_mem_valid_inst});
		//	 print_stage("|", mem_wb_IR, mem_wb_NPC[31:0], {31'b0,mem_wb_valid_inst});
		//	 print_reg(32'b0, pipeline_commit_wr_data[31:0],
		//		{27'b0,pipeline_commit_wr_idx}, {31'b0,pipeline_commit_wr_en});
		//	 print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
		//		32'b0, proc2mem_addr[31:0],
		//		proc2mem_data[63:32], proc2mem_data[31:0]);
			
			
			 // print the writeback information to writeback.out

			if(pipeline_retired_insts>0) begin
				for(int i = 0; i < `N_WAY; i++)
				begin
					found = 1'b0;
					if(retire_packet[i].ret_valid)
					begin
						if(retire_packet[i].tag!=0)
						begin
							for(j = 0; j < `XLEN; j++)
							begin
								if(retire_packet[i].tag == arch_reg_next[j])
								begin
									found = 1'b1;
									break;
								end
							end
							if(found)
							begin
								$fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
								retire_packet[i].PC,
								j,
								reg_data_lookup[retire_packet[i].tag]);
								continue;
							end
							else
							begin
								tag = retire_packet[i].tag;
								while(!found)
								begin
									for(int j = 0; j < `N_ROB; j++)
									begin
										if(rob_packet[j].tag_old == tag)
										begin
											for(k = 0; k < `XLEN; k++)
											begin
												if(rob_packet[j].tag == arch_reg_next[k])
												begin
													found = 1'b1;
													break;
												end
											end
											if(!found)
												tag = rob_packet[j].tag;
											else
												break;
										end
										if(found)
											break;
									end
								end
							end
							if(k != 0)
							begin
								$fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
								retire_packet[i].PC,
								k,
								reg_data_lookup[retire_packet[i].tag]);
							end
							else
							begin
								$fdisplay(wb_fileno, "PC=%x, ---", retire_packet[i].PC);
							end
						


						end
						else //if(retire_packet[i].inst_is_branch)
						begin
							$fdisplay(wb_fileno, "PC=%x, ---", retire_packet[i].PC);
						end
						
					end
					//else
					//	$fdisplay(wb_fileno, "PC=%x, ---",retire_packet[i].PC);
				end
			end
			

			
				tmp = 0;
			// deal with any halting conditions
			for(int i = 0; i < `N_WAY; i++)
			begin
				//if(retire_packet[i].ret_valid && (retire_packet[i].illegal || retire_packet[i].halt || debug_counter > 5000)) begin
				if(retire_packet[i].ret_valid && (retire_packet[i].illegal || retire_packet[i].halt || debug_counter > 50000000 || retire_branch)) begin
					$display("@@@ Unified Memory contents hex on left, decimal on right: ");
					// show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
					// 8Bytes per line, 16kB total
					
					
					// case(pipeline_error_status)
					// 	LOAD_ACCESS_FAULT:  
					// 		$display("@@@ System halted on memory error");
					// 	HALTED_ON_WFI:          
					// 		$display("@@@ System halted on WFI instruction");
					// 	ILLEGAL_INST:
					// 		$display("@@@ System halted on illegal instruction");
					// 	default: 
					// 		$display("@@@ System halted on unknown error code %x", 
					// 			pipeline_error_status);
					// endcase
					//if (retire_branch && !tmp && branch_haz) begin
					//tmp = 1;
					//$fdisplay(wb_fileno, "PC=%x, ---",
					//		retire_branch_PC);
					//end
					if(!retire_branch) begin
					begin
						flush = 1'b1;
						final_clock_count = clock_count;
						final_instr_count = instr_count;
					end
					//$fdisplay(wb_fileno, "PC=%x, ---",
					//		retire_packet[i].PC);
					
						
					print_close(); // close the pipe_print output file
					$fclose(wb_fileno);
					#10000;
					show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
					$display("@@  %t : System halted\n@@", $realtime);
					if(retire_packet_illegal)
						$display("@@@ System halted on illegal instruction");
					else if(retire_packet_halt)
						$display("@@@ System halted on WFI instruction");
					
					$display("@@@\n@@");
					show_clk_count;
					$finish;
					end

				end
			end
            debug_counter <= debug_counter + 1;
		end  // if(reset)   
	end

	always_ff @ (posedge clock)
	begin
		for(int i = 0; i < `N_WAY; i++)
		begin
			if(reg_wr_en[i] && reg_complete_dest_tag[i]!=0)
				reg_data_lookup[reg_complete_dest_tag[i]] = reg_wr_data[i];
		end
	end

	int timeout_counter;
	always_ff@(posedge clock) begin
		if(timeout_counter > 1000000) begin
			$display("Hard Timeout");
			$finish;
		end
		timeout_counter = timeout_counter + 1;
	end

endmodule  // module testbench
