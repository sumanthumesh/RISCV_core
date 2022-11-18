//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  ex_stage.v                                           //
//                                                                      //
//  Description :  instruction execute (EX) stage of the pipeline;      //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the result,// 
//                 and compute the condition for branches, and pass all //
//                 the results down the pipeline. MWB                   // 
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////
`ifndef __EX_STAGE_V__
`define __EX_STAGE_V__

`timescale 1ns/100ps

//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
module alu(
	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,
	ALU_FUNC     func,
	input start,
	input [`CDB_BITS-1:0] dest_tag_in,

	output logic [`XLEN-1:0] result
);
	wire signed [`XLEN-1:0] signed_opa, signed_opb;
	wire signed [2*`XLEN-1:0] signed_mul, mixed_mul;
	wire        [2*`XLEN-1:0] unsigned_mul;
	assign signed_opa = opa;
	assign signed_opb = opb;
	assign signed_mul = signed_opa * signed_opb;
	assign unsigned_mul = opa * opb;
	assign mixed_mul = signed_opa * opb;

	always_comb begin
		case (func)
			ALU_ADD:      result = opa + opb;
			ALU_SUB:      result = opa - opb;
			ALU_AND:      result = opa & opb;
			ALU_SLT:      result = signed_opa < signed_opb;
			ALU_SLTU:     result = opa < opb;
			ALU_OR:       result = opa | opb;
			ALU_XOR:      result = opa ^ opb;
			ALU_SRL:      result = opa >> opb[4:0];
			ALU_SLL:      result = opa << opb[4:0];
			ALU_SRA:      result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
			ALU_MUL:      result = signed_mul[`XLEN-1:0];
			ALU_MULH:     result = signed_mul[2*`XLEN-1:`XLEN];
			ALU_MULHSU:   result = mixed_mul[2*`XLEN-1:`XLEN];
			ALU_MULHU:    result = unsigned_mul[2*`XLEN-1:`XLEN];

			default:      result = `XLEN'hfacebeec;  // here to prevent latches
		endcase
	end

endmodule // alu
//
// BrCond module
//
// Given the instruction code, compute the proper condition for the
// instruction; for branches this condition will indicate whether the
// target is taken.
//
// This module is purely combinational
//
module brcond(// Inputs
	input [`XLEN-1:0] rs1,    // Value to check against condition
	input [`XLEN-1:0] rs2,
	input  [2:0] func,  // Specifies which condition to check
	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,

	output logic cond,    // 0/1 condition result (False/True)
	output logic [`XLEN-1:0] result
);

	logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
	assign signed_rs1 = rs1;
	assign signed_rs2 = rs2;
	always_comb begin
		cond = 0;
		case (func)
			3'b000: cond = signed_rs1 == signed_rs2;  // BEQ
			3'b001: cond = signed_rs1 != signed_rs2;  // BNE
			3'b100: cond = signed_rs1 < signed_rs2;   // BLT
			3'b101: cond = signed_rs1 >= signed_rs2;  // BGE
			3'b110: cond = rs1 < rs2;                 // BLTU
			3'b111: cond = rs1 >= rs2;                // BGEU
		endcase
		result = opa + opb;
	end
	
endmodule // brcond

module mult  (
				input clock, reset,
				input start,
				input [1:0] sign,
       				input [`CDB_BITS-1:0] dest_tag_in,
				input [`XLEN-1:0] mcand, mplier,
				
				output [(2*`XLEN)-1:0] product,
       				output [`CDB_BITS-1:0] dest_tag_out,
				output done
			);
	logic [(2*`XLEN)-1:0] mcand_out, mplier_out, mcand_in, mplier_in;
	logic [`NUM_STAGE:0][2*`XLEN-1:0] internal_mcands, internal_mpliers;
	logic [`NUM_STAGE:0][2*`XLEN-1:0] internal_products,internal_products_comb;
	logic [`NUM_STAGE:0] internal_dones;
       logic  [`NUM_STAGE:0][`CDB_BITS-1:0]  internal_dest_tag;

	assign mcand_in  = sign[0] ? {{`XLEN{mcand[`XLEN-1]}}, mcand}   : {{`XLEN{1'b0}}, mcand} ;
	assign mplier_in = sign[1] ? {{`XLEN{mplier[`XLEN-1]}}, mplier} : {{`XLEN{1'b0}}, mplier};

	assign internal_mcands[0]   = mcand_in;
	assign internal_mpliers[0]  = mplier_in;
	assign internal_products[0] = 'h0;
	assign internal_products_comb[0] = 'h0;
	assign internal_dones[0]    = start;
	assign internal_dest_tag[0]    = dest_tag_in;

	assign done    = internal_dones[`NUM_STAGE-1];
	//assign product = internal_products[`NUM_STAGE];
	assign product = internal_products_comb[`NUM_STAGE];
	assign dest_tag_out = internal_dest_tag[`NUM_STAGE-1];

	genvar i;
	for (i = 0; i < `NUM_STAGE; ++i) begin : mstage
		mult_stage  ms (
			.clock(clock),
			.reset(reset),
			.product_in(internal_products[i]),
			.mplier_in(internal_mpliers[i]),
			.mcand_in(internal_mcands[i]),
       			.dest_tag_in(internal_dest_tag[i]),
			.start(internal_dones[i]),
			.product_out_comb(internal_products_comb[i+1]),
			.product_out(internal_products[i+1]),
			.mplier_out(internal_mpliers[i+1]),
			.mcand_out(internal_mcands[i+1]),
       			.dest_tag_out(internal_dest_tag[i+1]),
			.done(internal_dones[i+1])
		);
	end
endmodule



module mult_stage (
					input clock, reset, start,
					input [(2*`XLEN)-1:0] mplier_in, mcand_in,
					input [(2*`XLEN)-1:0] product_in,
       					input [`CDB_BITS-1:0] dest_tag_in,

					output logic done,
					output logic [(2*`XLEN)-1:0] mplier_out, mcand_out,
       					output logic[`CDB_BITS-1:0] dest_tag_out,
					output logic [(2*`XLEN)-1:0] product_out_comb,
					output logic [(2*`XLEN)-1:0] product_out
				);


	logic [(2*`XLEN)-1:0] prod_in_reg, partial_prod, next_partial_product, partial_prod_unsigned;
	logic [(2*`XLEN)-1:0] next_mplier, next_mcand;

	assign product_out = prod_in_reg + partial_prod;
	assign product_out_comb = product_in + next_partial_product;

	assign next_partial_product = mplier_in[(`NUM_BITS-1):0] * mcand_in;

	assign next_mplier = {{(`NUM_BITS){1'b0}},mplier_in[2*`XLEN-1:(`NUM_BITS)]};
	assign next_mcand  = {mcand_in[(2*`XLEN-1-`NUM_BITS):0],{(`NUM_BITS){1'b0}}};

	//synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		prod_in_reg      <= product_in;
		partial_prod     <= next_partial_product;
		mplier_out       <= next_mplier;
		mcand_out        <= next_mcand;
	end

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if(reset) begin
			done     <= 1'b0;
       			dest_tag_out <= `SD 0;
		end else begin
			done     <= start;
       			dest_tag_out <= `SD dest_tag_in;
		end
	end

endmodule



module ex_stage(
	input clock,               // system clock
	input reset,               // system reset
	input ISSUE_EX_PACKET   [`N_WAY-1 : 0] issue_ex_packet_in,
	output logic [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag,//to r10k
	output logic [`N_WAY-1 : 0]  reg_wr_en_out,//to r10k
	output logic [`N_WAY-1 : 0] [`XLEN-1:0] ex_result_out,
	output logic take_branch_out,
	output logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_result,
	output EX_MEM_PACKET [`N_WAY-1 : 0] ex_packet_out
);
	// Pass-throughs
	always_comb begin
		for(int i=0; i<`N_WAY; i=i+1) begin
			ex_packet_out[i].NPC = issue_ex_packet_in[i].NPC;
			ex_packet_out[i].rs2_value = issue_ex_packet_in[i].rs2_value;
			ex_packet_out[i].rd_mem = issue_ex_packet_in[i].rd_mem;
			ex_packet_out[i].wr_mem = issue_ex_packet_in[i].wr_mem;
			ex_packet_out[i].dest_reg_idx = issue_ex_packet_in[i].dest_reg_idx;
			ex_packet_out[i].halt = issue_ex_packet_in[i].halt;
			ex_packet_out[i].illegal = issue_ex_packet_in[i].illegal;
			ex_packet_out[i].csr_op = issue_ex_packet_in[i].csr_op;
			ex_packet_out[i].valid = issue_ex_packet_in[i].valid;
			ex_packet_out[i].mem_size = issue_ex_packet_in[i].inst.r.funct3;
		end
	end

	logic [`EX_ALU_UNITS-1 : 0] [`XLEN-1:0] opa_mux_out, opb_mux_out;
	logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] opa_mux_out_br, opb_mux_out_br;
	ALU_FUNC [`EX_ALU_UNITS-1:0] alu_func;
	//
	// ALU opA mux
	//
	logic [$clog2(`EX_ALU_UNITS) : 0] count_alu_a;
	logic [`EX_ALU_UNITS-1 : 0] start_alu,done_alu;
	logic [`EX_ALU_UNITS-1 : 0] [`XLEN-1:0] alu_result;
	logic [`EX_ALU_UNITS-1 : 0][`CDB_BITS-1:0] dest_tag_in_alu, dest_tag_out_alu;
	logic tmp,tmp2;
	always_comb begin
		start_alu = 0;
		count_alu_a = 0; 
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp2=0;
			if(issue_ex_packet_in[i].execution_unit == ALU && !tmp2 && issue_ex_packet_in[i].valid) begin
				opa_mux_out[count_alu_a] = `XLEN'hdeadfbac;
				case (issue_ex_packet_in[i].opa_select)
					OPA_IS_RS1:  opa_mux_out[count_alu_a] = issue_ex_packet_in[i].rs1_value;
					OPA_IS_NPC:  opa_mux_out[count_alu_a] = issue_ex_packet_in[i].NPC;
					OPA_IS_PC:   opa_mux_out[count_alu_a] = issue_ex_packet_in[i].PC;
					OPA_IS_ZERO: opa_mux_out[count_alu_a] = 0;
				endcase
				start_alu[count_alu_a] = 1; 
				dest_tag_in_alu[count_alu_a] = issue_ex_packet_in[i].dest_reg_idx; 
				alu_func[count_alu_a] = issue_ex_packet_in[i].alu_func;
				count_alu_a = count_alu_a+1;
				tmp2=1;
			end
		end
	end

	 //
	 // ALU opB mux
	 //
	logic [$clog2(`EX_ALU_UNITS) : 0] count_alu_b;
	always_comb begin
		// Default value, Set only because the case isnt full.  If you see this
		// value on the output of the mux you have an invalid opb_select
		count_alu_b = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp=0;
			if(issue_ex_packet_in[i].execution_unit == ALU && !tmp && issue_ex_packet_in[i].valid ) begin
				opb_mux_out[count_alu_b] = `XLEN'hfacefeed;
				case (issue_ex_packet_in[i].opb_select)
					OPB_IS_RS2:   opb_mux_out[count_alu_b] = issue_ex_packet_in[i].rs2_value;
					OPB_IS_I_IMM: opb_mux_out[count_alu_b] = `RV32_signext_Iimm(issue_ex_packet_in[i].inst);
					OPB_IS_S_IMM: opb_mux_out[count_alu_b] = `RV32_signext_Simm(issue_ex_packet_in[i].inst);
					OPB_IS_B_IMM: opb_mux_out[count_alu_b] = `RV32_signext_Bimm(issue_ex_packet_in[i].inst);
					OPB_IS_U_IMM: opb_mux_out[count_alu_b] = `RV32_signext_Uimm(issue_ex_packet_in[i].inst);
					OPB_IS_J_IMM: opb_mux_out[count_alu_b] = `RV32_signext_Jimm(issue_ex_packet_in[i].inst);
				endcase 
				tmp=1;
				count_alu_b = count_alu_b+1;
			end
		end
	end

// MULT inputs
	logic [$clog2(`EX_MULT_UNITS) : 0] count_mult;
	logic tmp1;
  	logic [`EX_MULT_UNITS-1 : 0] [`XLEN-1:0] mcand, mplier;
	logic [`EX_MULT_UNITS-1 : 0] start_mult,done_mult;
	logic [`EX_MULT_UNITS-1 : 0] [`XLEN-1:0] mult_result;
	logic [`EX_MULT_UNITS-1 : 0][`CDB_BITS-1:0] dest_tag_in_mult, dest_tag_out_mult;
	logic [`EX_MULT_UNITS-1 : 0][1:0] sign_mult;
	always_comb begin
		count_mult = 0;
		start_mult = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp1=0;
			if(issue_ex_packet_in[i].execution_unit == MULT && !tmp1 && issue_ex_packet_in[i].valid) begin
				mcand[count_mult] = issue_ex_packet_in[i].rs1_value;
				mplier[count_mult] = issue_ex_packet_in[i].rs2_value;
				sign_mult[count_mult] = 0;
				start_mult[count_mult] = 1;
				dest_tag_in_mult[count_mult] = issue_ex_packet_in[i].dest_reg_idx; 
				tmp1 = 1;
				count_mult = count_mult + 1;
			end
		end
	end

// Branch inputs
	logic [$clog2(`EX_BRANCH_UNITS) : 0] count_branch;
	logic tmp_br;
  	logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] rs1_branch,rs2_branch;
	logic [`EX_BRANCH_UNITS-1 : 0] start_branch;
	logic [`EX_BRANCH_UNITS-1 : 0][2:0] func_branch;
	logic [`EX_BRANCH_UNITS-1 : 0][`CDB_BITS-1:0] dest_tag_in_branch;
	logic [`EX_BRANCH_UNITS-1 : 0] brcond_result;
	logic [`EX_BRANCH_UNITS-1 : 0] [`XLEN-1:0] br_result_next;
	always_comb begin
		count_branch = 0;
		start_branch = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp_br=0;
			if(issue_ex_packet_in[i].execution_unit == BRANCH && !tmp_br && issue_ex_packet_in[i].valid ) begin
				rs1_branch[count_branch] = issue_ex_packet_in[i].rs1_value;
				rs2_branch[count_branch] = issue_ex_packet_in[i].rs2_value;
				func_branch[count_branch]= issue_ex_packet_in[i].inst.b.funct3; 
				start_branch[count_branch] = 1;
				dest_tag_in_branch[count_branch] = issue_ex_packet_in[i].dest_reg_idx; 
				tmp_br = 1;
				//opa_mux_out_br[count_branch] = issue_ex_packet_in[i].PC;
				//opb_mux_out_br[count_branch] = `RV32_signext_Bimm(issue_ex_packet_in[i].inst);
				opa_mux_out_br[count_branch] = `XLEN'hdeadfbac;
				case (issue_ex_packet_in[i].opa_select)
				      OPA_IS_RS1:  opa_mux_out_br[count_branch] = issue_ex_packet_in[i].rs1_value;
				      OPA_IS_NPC:  opa_mux_out_br[count_branch] = issue_ex_packet_in[i].NPC;
				      OPA_IS_PC:   opa_mux_out_br[count_branch] = issue_ex_packet_in[i].PC;
				      OPA_IS_ZERO: opa_mux_out_br[count_branch] = 0;
				endcase
				opb_mux_out_br[count_branch] = `XLEN'hfacefeed;
				case (issue_ex_packet_in[i].opb_select)
					OPB_IS_RS2:   opb_mux_out_br[count_branch] = issue_ex_packet_in[i].rs2_value;
					OPB_IS_I_IMM: opb_mux_out_br[count_branch] = `RV32_signext_Iimm(issue_ex_packet_in[i].inst);
					OPB_IS_S_IMM: opb_mux_out_br[count_branch] = `RV32_signext_Simm(issue_ex_packet_in[i].inst);
					OPB_IS_B_IMM: opb_mux_out_br[count_branch] = `RV32_signext_Bimm(issue_ex_packet_in[i].inst);
					OPB_IS_U_IMM: opb_mux_out_br[count_branch] = `RV32_signext_Uimm(issue_ex_packet_in[i].inst);
					OPB_IS_J_IMM: opb_mux_out_br[count_branch] = `RV32_signext_Jimm(issue_ex_packet_in[i].inst);
				endcase 

				count_branch = count_branch + 1;
			end
		end
	end

	//
	// instantiate the ALU
	//
	
	genvar j;
	generate
		for(j=0; j<`EX_ALU_UNITS; j=j+1) begin
			alu alu_0 (// Inputsissue_ex_packet_in[i].
				.opa(opa_mux_out[j]),
				.opb(opb_mux_out[j]),
				.func(alu_func[j]),
				.start(start_alu[j]),
				.dest_tag_in(dest_tag_in_alu[j]),
				// Output
				.result(alu_result[j])
			);
		end
	endgenerate

	//
	//Instantiate the mult  unit
	//
	genvar k;
	generate
		for(k=0; k<`EX_MULT_UNITS; k=k+1) begin
			mult m0 (//Inputs
				.clock(clock),
				.reset(reset),
				.sign(sign_mult[k]),
				.mcand(mcand[k]),
				.mplier(mplier[k]),
				.start(start_mult[k]),
				.dest_tag_in(dest_tag_in_mult[k]),
				//outputs
				.product(mult_result[k]),
				.dest_tag_out(dest_tag_out_mult[k]),
				.done(done_mult[k])
				);
		end
	endgenerate
		
	 //
	 // instantiate the branch condition tester
	 //
	genvar l;
	generate
		for(l=0; l<`EX_BRANCH_UNITS; l=l+1) begin
			brcond brcond (// Inputs
				.rs1(rs1_branch[l]), 
				.rs2(rs2_branch[l]),
				.opa(opa_mux_out_br[l]),
				.opb(opb_mux_out_br[l]),
				.func(func_branch[l]), // inst bits to determine check
				// Output
				.cond(brcond_result[l]),
				.result(br_result_next[l])
			);
		end
	endgenerate

	logic take_branch,take_branch_out_wire;
	always_comb begin
		 // ultimate "take branch" signal:
		 //	unconditional, or conditional and the condition is true
		for(int i=0; i<`N_WAY; i=i+1) begin
			if(issue_ex_packet_in[i].execution_unit == BRANCH) begin
				take_branch = issue_ex_packet_in[i].uncond_branch
			        		                  | (issue_ex_packet_in[i].cond_branch & brcond_result);
			end
		end
	 end


//complete stage
	logic [$clog2(`N_WAY) : 0] count_out;
	logic [$clog2(2*`N_WAY) : 0] count_comp;
	logic [`EX_MULT_UNITS-1 : 0] completed_mult;
	logic [`EX_ALU_UNITS-1 : 0]  completed_alu;
	logic [`EX_BRANCH_UNITS-1 : 0]  completed_branch;
	logic [2*`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag_wire,complete_dest_tag_next,complete_dest_tag_fifo;
	logic [2*`N_WAY-1 : 0] head,head_next,tail,tail_next;
	logic [2*`N_WAY-1 : 0] [`XLEN-1:0] result_out_wire,result_out_next,result_out_fifo;
	logic tmp3,tmp_out;
	always_comb begin
		count_comp = 0;
		completed_mult = 0;
		completed_alu = 0;
		completed_branch = 0;
		complete_dest_tag_wire = 0;
		result_out_wire = 0;
		take_branch_out_wire = 0;  
		//for(int i=0; i<`N_WAY; i=i+1) begin
			for(int j=0; j<`EX_MULT_UNITS; j=j+1) begin
				if(done_mult[j] && !completed_mult[j] && (count_comp<`N_WAY)) begin
					complete_dest_tag_wire[count_comp] = dest_tag_out_mult[j];
					result_out_wire[count_comp] = mult_result[j];
					completed_mult[j] = 1;
					count_comp =  count_comp + 1;
				end	
			end
			for(int j=0; j<`EX_BRANCH_UNITS; j=j+1) begin
				if(start_branch[j] && !completed_branch[j] && (count_comp<`N_WAY)) begin
					complete_dest_tag_wire[count_comp] = dest_tag_in_branch[j];
					take_branch_out_wire = take_branch;  
					result_out_wire[count_comp] = 0; 
					completed_branch[j] = 1;
					count_comp =  count_comp + 1;
				end	
			end
			for(int j=0; j<`EX_ALU_UNITS; j=j+1) begin
				//if(done_alu[j] && !completed_alu[j]) begin
				if(start_alu[j] && !completed_alu[j] && (count_comp<`N_WAY)) begin
					//complete_dest_tag_wire[count_comp] = dest_tag_out_alu[j];
					complete_dest_tag_wire[count_comp] = dest_tag_in_alu[j];
					result_out_wire[count_comp] = alu_result[j];
					completed_alu[j] = 1;
					count_comp =  count_comp + 1;
				end	
			end		
		//end	
	end 
	always_comb begin
		complete_dest_tag_next = complete_dest_tag_fifo;
		result_out_next = result_out_fifo;
		head_next = head;
		tail_next = tail;
		count_out = 0;
		complete_dest_tag= 0 ; 
		for(int j=0; j<`N_WAY; j=j+1) begin
			tmp_out = 0;
			for(int i=0; i<2*`N_WAY; i=i+1) begin
				if(head_next[i] && !tmp_out) begin
					complete_dest_tag[j] = complete_dest_tag_next[i];
					ex_result_out[j] = result_out_next[i];
					if(complete_dest_tag_next[i] != 0) begin
						head_next[i] = 0; 	
						if(i == 2*`N_WAY-1)
							head_next[0] = 1; 	
						else
							head_next[i+1] = 1; 	
					end
					complete_dest_tag_next[i] = 0;
					result_out_next[i] = 0;
					tmp_out = 1;	
					//count_out = count_out + 1;	
				end
			end
		end
		for(int i=0; i<2*`N_WAY; i=i+1) begin
			tmp3 = 0;
			for(int j=0; j<2*`N_WAY; j=j+1) begin
				if(tail_next[j] && (complete_dest_tag_wire[i]!=0) && !tmp3) begin
					tmp3 = 1;
					tail_next[j] = 0; 	
					if(j == 2*`N_WAY-1) begin
						complete_dest_tag_next[0] = complete_dest_tag_wire[i];
						result_out_next[0] = result_out_wire[i];
						tail_next[0] = 1; 	
					end else begin
						complete_dest_tag_next[j+1] = complete_dest_tag_wire[i];
						result_out_next[j+1] = result_out_wire[i];
						tail_next[j+1] = 1; 	
					end
				end
			end
		end
	end	

	always_comb begin
		for(int i=0; i<`N_WAY; i=i+1) begin
		//	reg_wr_en_out[i]  = complete_dest_tag[i]!= `ZERO_REG_PR;
			reg_wr_en_out[i]  = (complete_dest_tag[i]!= `ZERO_REG_PR) && (complete_dest_tag[i]!=0);
		end	
	end

	always_ff @(posedge clock) begin
		if(reset) begin
			complete_dest_tag_fifo <=`SD 0;
			result_out_fifo <=`SD 0;
			br_result <=`SD 0;
			take_branch_out <= `SD 0;
			for(int m = 0; m<2*`N_WAY; m = m+1) begin
				if(m == 0) begin
					head[m] <= `SD 1;
					tail[m] <= `SD 0;
				end else if(m == 2*`N_WAY-1) begin
					tail[m] <= `SD 1;
					head[m] <= `SD 0;
				end else begin
					head[m] <= `SD 0;	
					tail[m] <= `SD 0;	
				end
			end
		end else begin
			complete_dest_tag_fifo <=`SD complete_dest_tag_next;
			result_out_fifo <=`SD result_out_next;
			br_result <=`SD br_result_next;
			head <= `SD head_next;
			tail <= `SD tail_next;
			take_branch_out <= `SD take_branch_out_wire;
		end
	end


endmodule // module ex_stage
`endif // __EX_STAGE_V__
