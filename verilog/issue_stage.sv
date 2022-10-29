/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  issue_stage.v                                       //
//                                                                     //
//  Description :  issue (S) stage of the out-of-order pipeline;       // 
//                 decode the instruction fetch register operands, and // 
//                 compute immediate operand (if applicable)           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps

// Decode an instruction: given instruction bits IR produce the
  // appropriate datapath control signals.
  //
  // This is a *combinational* module (basically a PLA).
  //
module decoder(

	input RS_PACKET_ISSUE   [`N_WAY-1:0]  	rs_packet_issue,
	
    output ALU_OPA_SELECT   [`N_WAY-1:0]    opa_select,
	output ALU_OPB_SELECT   [`N_WAY-1:0]    opb_select,
	output DEST_REG_SEL     [`N_WAY-1:0]    dest_reg_select, // mux selects
	output ALU_FUNC         [`N_WAY-1:0]	alu_func,
	output logic 			[`N_WAY-1:0]	rd_mem,
	output logic 			[`N_WAY-1:0]	wr_mem, 
	output logic 			[`N_WAY-1:0]	cond_branch, 
	output logic 			[`N_WAY-1:0]	uncond_branch,
	output logic 			[`N_WAY-1:0]	csr_op,    // used for CSR operations, we only used this as a cheap way to get the return code out
	output logic 			[`N_WAY-1:0]	halt,      // non-zero on a halt
	output logic 			[`N_WAY-1:0]	illegal,    // non-zero on an illegal instruction
	output logic 			[`N_WAY-1:0]	valid_inst  // for counting valid instructions executed
	                        // and for making the fetch stage die on halts/
	                        // keeping track of when to allow the next
	                        // instruction out of fetch
	                        // 0 for HALT and illegal instructions (die on halt)

);

	INST inst;
	
	always_comb begin
		// default control values:
		// - valid instructions must override these defaults as necessary.
		//	 opa_select, opb_select, and alu_func should be set explicitly.
		// - invalid instructions should clear valid_inst.
		// - These defaults are equivalent to a noop
		// * see sys_defs.vh for the constants used here
		for(int i = 0; i < `N_WAY; i++)
		begin
			inst = rs_packet_issue[i].inst;
			opa_select[i] = OPA_IS_RS1;
			opb_select[i] = OPB_IS_RS2;
			alu_func[i] = ALU_ADD;
			dest_reg_select[i] = DEST_NONE;
			csr_op[i] = `FALSE;
			rd_mem[i] = `FALSE;
			wr_mem[i] = `FALSE;
			cond_branch[i] = `FALSE;
			uncond_branch[i] = `FALSE;
			halt[i] = `FALSE;
			illegal[i] = `FALSE;
			casez (inst) 
				`RV32_LUI: begin
					dest_reg_select[i]   = DEST_RD;
					opa_select[i] = OPA_IS_ZERO;
					opb_select[i] = OPB_IS_U_IMM;
				end
				`RV32_AUIPC: begin
					dest_reg_select[i]   = DEST_RD;
					opa_select[i] = OPA_IS_PC;
					opb_select[i] = OPB_IS_U_IMM;
				end
				`RV32_JAL: begin
					dest_reg_select[i]      = DEST_RD;
					opa_select[i]    = OPA_IS_PC;
					opb_select[i]    = OPB_IS_J_IMM;
					uncond_branch[i] = `TRUE;
				end
				`RV32_JALR: begin
					dest_reg_select[i]      = DEST_RD;
					opa_select[i]    = OPA_IS_RS1;
					opb_select[i]    = OPB_IS_I_IMM;
					uncond_branch[i] = `TRUE;
				end
				`RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
				`RV32_BLTU, `RV32_BGEU: begin
					opa_select[i]  = OPA_IS_PC;
					opb_select[i]  = OPB_IS_B_IMM;
					cond_branch[i] = `TRUE;
				end
				`RV32_LB, `RV32_LH, `RV32_LW,
				`RV32_LBU, `RV32_LHU: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					rd_mem[i]     = `TRUE;
				end
				`RV32_SB, `RV32_SH, `RV32_SW: begin
					opb_select[i] = OPB_IS_S_IMM;
					wr_mem[i]     = `TRUE;
				end
				`RV32_ADDI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SLTI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_SLT;
				end
				`RV32_SLTIU: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_SLTU;
				end
				`RV32_ANDI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_AND;
				end
				`RV32_ORI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_OR;
				end
				`RV32_XORI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_XOR;
				end
				`RV32_SLLI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_SLL;
				end
				`RV32_SRLI: begin
					dest_reg_select[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_SRL;
				end
				`RV32_SRAI: begin
					dest_reg_select[i]  = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
					alu_func[i]   = ALU_SRA;
				end
				`RV32_ADD: begin
					dest_reg_select[i]   = DEST_RD;
				end
				`RV32_SUB: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_SUB;
				end
				`RV32_SLT: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_SLT;
				end
				`RV32_SLTU: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_SLTU;
				end
				`RV32_AND: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_AND;
				end
				`RV32_OR: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_OR;
				end
				`RV32_XOR: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_XOR;
				end
				`RV32_SLL: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_SLL;
				end
				`RV32_SRL: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_SRL;
				end
				`RV32_SRA: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_SRA;
				end
				`RV32_MUL: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_MUL;
				end
				`RV32_MULH: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_MULH;
				end
				`RV32_MULHSU: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_MULHSU;
				end
				`RV32_MULHU: begin
					dest_reg_select[i]   = DEST_RD;
					alu_func[i]   = ALU_MULHU;
				end
				`RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
					csr_op[i] = `TRUE;
				end
				`WFI: begin
					halt[i] = `TRUE;
				end
				default: illegal[i] = `TRUE;
			endcase // casez (inst)
		end // for-loop
	end // always
endmodule // decoder



module issue_stage(
	// Inputs
    input   clock,  // system clock
    input   reset,  // system reset
    input   RS_PACKET_ISSUE [`N_WAY-1:0]	rs_packet_issue,   // packet of instructions sent to the reservation station to issue
	input	RS_PACKET_RETIRE	[`N_WAY-1:0]	rs_packet_retire, // packet of relevant data from the retire stage
	input	ROB_PACKET_ISSUE	[`N_ROB-1:0]	rob_packet,	// relevant data from the ROB that issue stage needs
	input	[`N_WAY-1:0]	wb_reg_wr_en_out,
	input	[`N_WAY-1:0][`CDB_BITS-1:0]	wb_reg_wr_idx_out,
	input	[`N_WAY-1:0][`XLEN-1:0]	wb_reg_wr_data_out,
	input   [$clog2(`N_PHY_REG):0]  zero_reg_pr, // shows which physical register is mapped to the zero register
    
	// Outputs
	output	ISSUE_EX_PACKET		[`N_WAY-1:0]	issue_packet,
	output	logic 		[$clog2(`N_WAY):0] 	issue_num,
	output logic	[$clog2(`N_WAY):0] count
);

	logic	[`N_PHY_REG-1:0]	issued_phy_reg; // This keeps track of which instructions have already been sent to the execution stage.
	logic	[`N_PHY_REG-1:0]	next_issued_phy_reg;
	//logic	[$clog2(`N_WAY):0] count;
	logic	[$clog2(`EX_MULT_UNITS):0]	mult_inst_counter;
	logic	[$clog2(`EX_ALU_UNITS):0]	alu_inst_counter;
	logic [`N_PHY_REG-1:0] [`XLEN-1:0] registers;



	
	
	ALU_OPA_SELECT   [`N_WAY-1:0]    opa_select;
	ALU_OPB_SELECT   [`N_WAY-1:0]    opb_select;
	DEST_REG_SEL     [`N_WAY-1:0]    dest_reg_select;
	ALU_FUNC         [`N_WAY-1:0]	alu_func;
	logic [`N_WAY-1:0][`CDB_BITS-1:0] dest_reg_idx;
	logic 			[`N_WAY-1:0]	rd_mem;
	logic 			[`N_WAY-1:0]	wr_mem; 
	logic 			[`N_WAY-1:0]	cond_branch;
	logic 			[`N_WAY-1:0]	uncond_branch;
	logic 			[`N_WAY-1:0]	csr_op;
	logic 			[`N_WAY-1:0]	halt;
	logic 			[`N_WAY-1:0]	illegal;
	logic 			[`N_WAY-1:0]	valid_inst;
	logic	[`N_WAY-1:0][`CDB_BITS-1:0]		regfile_rda_idx;
	logic	[`N_WAY-1:0][`CDB_BITS-1:0]		regfile_rdb_idx;
	logic	[`N_WAY-1:0][`XLEN-1:0]			regfile_rda_out;
	logic	[`N_WAY-1:0][`XLEN-1:0]			regfile_rdb_out;
	logic	found_dest_tag_in_rob;
	

	decoder decoder_0(
		// Inputs
		.rs_packet_issue(rs_packet_issue),
		// Outputs		
		.opa_select(opa_select),
		.opb_select(opb_select),
		.dest_reg_select(dest_reg_select),
		.alu_func(alu_func),
		.rd_mem(rd_mem),
		.wr_mem(wr_mem), 
		.cond_branch(cond_branch), 
		.uncond_branch(uncond_branch),
		.csr_op(csr_op),
		.halt(halt),
		.illegal(illegal),
		.valid_inst(valid_inst)
	);

	always_comb
	begin
		for(int i = 0; i < `N_WAY; i++)
		begin
			regfile_rda_idx[i] = rs_packet_issue[i].source_tag_1;
			regfile_rdb_idx[i] = rs_packet_issue[i].source_tag_2;
		end
	end
	// Instantiate the register file used by this pipeline
	regfile regf_0 (
		.rda_idx(regfile_rda_idx),
		.rdb_idx(regfile_rdb_idx),
		.rda_out(regfile_rda_out), 
		.rdb_out(regfile_rdb_out),
		.wr_clk(clock),
		.wr_en(wb_reg_wr_en_out),
		.wr_idx(wb_reg_wr_idx_out),
		.wr_data(wb_reg_wr_data_out),
		.registers(registers),
		.zero_reg_pr(zero_reg_pr)
	);

	
	always_comb
	begin
		count = 0;
		mult_inst_counter = `EX_MULT_UNITS;
		alu_inst_counter = `EX_ALU_UNITS;
		next_issued_phy_reg = issued_phy_reg;
		for(int i = 0; i < `N_WAY; i++)
		begin
			next_issued_phy_reg[rs_packet_retire[i].dest_tag] = 0;
		end // for-loop

		for(int i = 0; i < `N_WAY; i++)
		begin
			found_dest_tag_in_rob = 0;
			/* What to check?
			1. Check that the instruction in the issue packet doesn't have the same instruction as another instruction currently being executed, completed or retired. 
			2. Secondly, check that the instruction in the issue packet has a destination register which is currently present in one of the entries of the ROB. The same entry of ROB should also have its busy bit as 1.
			3. Thirdly, check that there is a functional unit available to whom we can send the instruction for execution.
			*/
			if(!next_issued_phy_reg[rs_packet_issue[i].dest_tag])
			begin
				if((((rs_packet_issue[i].inst.r.funct3 == `MD_MUL_FUN3)||
				(rs_packet_issue[i].inst.r.funct3 == `MD_MULH_FUN3)||
				(rs_packet_issue[i].inst.r.funct3 == `MD_MULHU_FUN3)||
				(rs_packet_issue[i].inst.r.funct3 == `MD_MULHSU_FUN3)) && mult_inst_counter >0)||
				(!(((rs_packet_issue[i].inst.r.funct3 == `MD_MUL_FUN3)||
				(rs_packet_issue[i].inst.r.funct3 == `MD_MULH_FUN3)||
				(rs_packet_issue[i].inst.r.funct3 == `MD_MULHU_FUN3)||
				(rs_packet_issue[i].inst.r.funct3 == `MD_MULHSU_FUN3))) && alu_inst_counter >0))
				begin
					for(int j = 0; j < `N_ROB; j++)
					begin
						if(rob_packet[j].busy && rob_packet[j].phy_reg_idx == rs_packet_issue[i].dest_tag)
							found_dest_tag_in_rob = 1;
					end

					if(found_dest_tag_in_rob)
					begin
						next_issued_phy_reg[rs_packet_issue[i].dest_tag] = 1;
						issue_packet[count] = {
							regfile_rda_out[i],// rs1_value
							regfile_rdb_out[i],// rs2_value
							opa_select[i],	// opa_select
							opb_select[i],	// opb_select
							rs_packet_issue[i].inst,	// instruction
							dest_reg_idx[i], 		// destination register index
							alu_func[i],		// alu_func
							rd_mem[i],			// rd_mem
							wr_mem[i],			// wr_mem
							cond_branch[i],		// boolean for conditional branch
							uncond_branch[i],	// boolean for unconditional branch
							halt[i],				// whether to halt execution
							illegal[i],				// whether the current instruction is illegal
							csr_op[i]				// whether the current instruction is a CSR operation
						};

						if((rs_packet_issue[i].inst.r.funct3 == `MD_MUL_FUN3)||
						(rs_packet_issue[i].inst.r.funct3 == `MD_MULH_FUN3)||
						(rs_packet_issue[i].inst.r.funct3 == `MD_MULHU_FUN3)||
						(rs_packet_issue[i].inst.r.funct3 == `MD_MULHSU_FUN3))
						begin
							mult_inst_counter = mult_inst_counter - 1;
						end
						else
							alu_inst_counter = alu_inst_counter - 1;

					count = count + 1;
					end
				end

				

			end // if-condition
		end // for-loop

		issue_num = `N_WAY - count;

	end // always_comb

	always_ff @ (posedge clock)
	begin
		if(reset)
			issued_phy_reg <= `SD 0;
		else
			issued_phy_reg <= `SD next_issued_phy_reg;
		
	end


	always_comb begin
		for(int i = 0; i < `N_WAY; i++)
		begin
			casez(dest_reg_select[i])
				DEST_RD:    dest_reg_idx[i] = rs_packet_issue[i].dest_tag;
				DEST_NONE:  dest_reg_idx[i] = `ZERO_REG;
				default:    dest_reg_idx[i] = `ZERO_REG; 
			endcase
		end
	end

endmodule // issue_stage
