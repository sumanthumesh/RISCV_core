`timescale 1ns/100ps

module program_dispatch(
    input clock,
    input reset,
	input [`N_WAY-1:0] dispatched,
	input branch_haz,
	input [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_result,
	output logic [`N_WAY-1:0] branch_inst, // BRANCH instruction identification
    output DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_out
    );

reg [63:0] instructions [0:100];
integer i;
integer head;
integer next_head;

integer k;


logic [$clog2(`N_WAY):0] minimum; // Will store which of ROB, RS, Free list have the minimum value.
logic [$clog2(`N_WAY):0] count;
logic [`N_WAY-1:0] next_branch_inst,next_branch_inst_reg; // BRANCH instruction identification
DISPATCH_PACKET_R10K [`N_WAY-1:0] dispatch_out_reg;

ALU_OPA_SELECT opa_select;
ALU_OPB_SELECT opb_select;
DEST_REG_SEL   dest_reg;
DISPATCH_PACKET_R10K [`N_WAY-1:0] next_dispatch_out;

initial 
begin
    $readmemh("program.mem", instructions);

end

always_comb
begin
    next_head = head;
    count = 0;
    for(int i = `N_WAY-1; i >= 0; i--)
    begin
        if(dispatched[i]!=1'b1)
		begin
			if(next_head!=0)
            	next_head = next_head - 1;
		end
    end

	if(branch_haz) begin  
		next_head = (br_result/4); 
	end


    for(int i = 0; i < `N_WAY; i++)
    begin
        next_dispatch_out[count].inst = (next_head%2) ? instructions[next_head/2][63:32] : instructions[next_head/2][31:0];
        next_dispatch_out[count].valid = 1'b1;
        next_dispatch_out[count].PC = (next_head/2)*8 + (next_head%2)*4;
        next_dispatch_out[count].NPC = (next_head/2)*8 + (next_head%2)*4 + 4;
        opa_select = OPA_IS_RS1;
	opb_select = OPB_IS_RS2;
		dest_reg = DEST_NONE;
		next_branch_inst = 0;
        casez (next_dispatch_out[count].inst)
            `RV32_LUI: begin
				dest_reg   = DEST_RD;
				opa_select = OPA_IS_ZERO;
				opb_select = OPB_IS_U_IMM;
			end
			`RV32_AUIPC: begin
				dest_reg   = DEST_RD;
				opa_select = OPA_IS_PC;
				opb_select = OPB_IS_U_IMM;
			end
			`RV32_JAL: begin
				dest_reg      = DEST_RD;
				opa_select    = OPA_IS_PC;
				opb_select    = OPB_IS_J_IMM;
			end
			`RV32_JALR: begin
				dest_reg      = DEST_RD;
				opa_select    = OPA_IS_RS1;
				opb_select    = OPB_IS_I_IMM;
			end
			`RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
			`RV32_BLTU, `RV32_BGEU: begin
			//	opa_select  = OPA_IS_PC;
			//	opb_select  = OPB_IS_B_IMM;
				next_branch_inst = 1;
			end
			`RV32_LB, `RV32_LH, `RV32_LW,
			`RV32_LBU, `RV32_LHU: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_SB, `RV32_SH, `RV32_SW: begin
				opb_select = OPB_IS_S_IMM;
			end
			`RV32_ADDI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_SLTI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_SLTIU: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_ANDI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_ORI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_XORI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_SLLI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_SRLI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_SRAI: begin
				dest_reg   = DEST_RD;
				opb_select = OPB_IS_I_IMM;
			end
			`RV32_ADD: begin
				dest_reg   = DEST_RD;
			end
			`RV32_SUB: begin
				dest_reg   = DEST_RD;
			end
			`RV32_SLT: begin
				dest_reg   = DEST_RD;
			end
			`RV32_SLTU: begin
				dest_reg   = DEST_RD;
			end
			`RV32_AND: begin
				dest_reg   = DEST_RD;
			end
			`RV32_OR: begin
				dest_reg   = DEST_RD;
			end
			`RV32_XOR: begin
				dest_reg   = DEST_RD;
			end
			`RV32_SLL: begin
				dest_reg   = DEST_RD;
			end
			`RV32_SRL: begin
				dest_reg   = DEST_RD;
			end
			`RV32_SRA: begin
				dest_reg   = DEST_RD;
			end
			`RV32_MUL: begin
				dest_reg   = DEST_RD;
			end
			`RV32_MULH: begin
				dest_reg   = DEST_RD;
			end
			`RV32_MULHSU: begin
				dest_reg   = DEST_RD;
			end
			`RV32_MULHU: begin
				dest_reg   = DEST_RD;
			end
            default: begin
                opa_select = OPA_IS_RS1;
    	        opb_select = OPB_IS_RS2;
	            dest_reg = DEST_NONE;
		next_branch_inst = 0;
            end
        endcase
        case (dest_reg)
		    DEST_RD:    next_dispatch_out[count].dest = next_dispatch_out[count].inst.r.rd;
		    DEST_NONE:  next_dispatch_out[count].dest = 0;
		    default:    next_dispatch_out[count].dest = 0; 
		endcase
	next_branch_inst_reg[count] = next_branch_inst;
        if(opa_select == OPA_IS_RS1)
            next_dispatch_out[count].src1 = next_dispatch_out[count].inst.r.rs1;
        else
            next_dispatch_out[count].src1 = 0;
        if(opb_select == OPB_IS_RS2)
            next_dispatch_out[count].src2 = next_dispatch_out[count].inst.r.rs2;
        else
            next_dispatch_out[count].src2 = 0;
        count = count + 1;
        next_head = next_head + 1;
    end


end


always @ (posedge clock)
begin
    if(reset)
    begin
        head <= `SD 0;
        dispatch_out_reg <= `SD 0;
	branch_inst <= `SD 0;
    end
    else
    begin
        head <= `SD next_head;
        dispatch_out_reg <= `SD next_dispatch_out;
	branch_inst <= `SD next_branch_inst_reg;
    end
end

assign dispatch_out = branch_haz ? 0 : dispatch_out_reg;

endmodule

