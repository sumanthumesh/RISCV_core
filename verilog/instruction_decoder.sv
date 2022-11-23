module instruction_decoder(
	input [`N_WAY-1:0][`XLEN-1:0] input_PC,
    input INST [`N_WAY-1:0] input_inst,
	input [`N_WAY-1:0] in_valid,
	
	output logic [`N_WAY-1:0][`XLEN-1:0] out_PC,
	output logic [`N_WAY-1:0][`XLEN-1:0] out_NPC,
    //output logic [`N_WAY-1:0][`XLEN-1:0] out_inst,
    output INST[`N_WAY-1:0] out_inst,
	output logic [`N_WAY-1:0][`XLEN_BITS-1:0] src1,
	output logic [`N_WAY-1:0][`XLEN_BITS-1:0] src2,
	output logic [`N_WAY-1:0][`XLEN_BITS-1:0] dest,
	output logic [`N_WAY-1:0] is_branch,
	output logic [`N_WAY-1:0] halt,
	output logic [`N_WAY-1:0] out_valid,
	output logic [`N_WAY-1:0] illegal	
);
	ALU_OPA_SELECT [`N_WAY-1:0] opa_select;
	ALU_OPB_SELECT [`N_WAY-1:0] opb_select;
	DEST_REG_SEL   [`N_WAY-1:0] dest_reg;

	always_comb begin
		for(int i=0; i<`N_WAY; i++) begin
			out_PC[i] = input_PC[i];
			out_NPC[i] = input_PC[i] + 4;
			out_inst[i] = input_inst[i];
			opa_select[i] = OPA_IS_RS1;
			opb_select[i] = OPB_IS_RS2;
			dest_reg[i] = DEST_NONE;
			halt[i] = `FALSE;
			illegal[i] = `FALSE;
			is_branch[i] = 0;

			casez (input_inst[i])
				`RV32_LUI: begin
					dest_reg[i] = DEST_RD;
					opa_select[i] = OPA_IS_ZERO;
					opb_select[i] = OPB_IS_U_IMM;
				end
				`RV32_AUIPC: begin
					dest_reg[i]   = DEST_RD;
					opa_select[i] = OPA_IS_PC;
					opb_select[i] = OPB_IS_U_IMM;
				end
				`RV32_JAL: begin
					dest_reg[i]      = DEST_RD;
					opa_select[i]    = OPA_IS_PC;
					opb_select[i]    = OPB_IS_J_IMM;
				end
				`RV32_JALR: begin
					dest_reg[i]      = DEST_RD;
					opa_select[i]    = OPA_IS_RS1;
					opb_select[i]    = OPB_IS_I_IMM;
				end
				`RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
				`RV32_BLTU, `RV32_BGEU: begin
					is_branch[i] = 1;
				end
				`RV32_LB, `RV32_LH, `RV32_LW,
				`RV32_LBU, `RV32_LHU: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SB, `RV32_SH, `RV32_SW: begin
					opb_select[i] = OPB_IS_S_IMM;
				end
				`RV32_ADDI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SLTI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SLTIU: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_ANDI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_ORI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_XORI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SLLI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SRLI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_SRAI: begin
					dest_reg[i]   = DEST_RD;
					opb_select[i] = OPB_IS_I_IMM;
				end
				`RV32_ADD: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_SUB: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_SLT: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_SLTU: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_AND: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_OR: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_XOR: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_SLL: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_SRL: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_SRA: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_MUL: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_MULH: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_MULHSU: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_MULHU: begin
					dest_reg[i]   = DEST_RD;
				end
				`RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
					illegal[i] = `FALSE;
				end
				`WFI: begin
					halt[i] = `TRUE;
				end
				default: begin
					illegal[i] = `TRUE;
				end	
			endcase

			case (dest_reg[i])
				DEST_RD: dest[i] = input_inst[i].r.rd;
				DEST_NONE: dest[i] = 0;
				default: dest[i] = 0;
			endcase

			if(opa_select[i] == OPA_IS_RS1)
				src1[i] = input_inst[i].r.rs1;
			else src1[i] = 0;

			if(opb_select[i] == OPB_IS_RS2)
				src2[i] = input_inst[i].r.rs2;
			else src2[i] = 0;

			out_valid[i] = in_valid[i];
		end
	end
endmodule

