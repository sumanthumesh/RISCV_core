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
	input clock,
	input reset,
	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,
	ALU_FUNC     func,
	input start,
	input [`CDB_BITS-1:0] dest_tag_in,
	output logic done,
	output logic [`CDB_BITS-1:0] dest_tag_out,

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

	always_ff @(posedge clock) begin
		if(reset) begin
			done <= #1 1'b0;
			dest_tag_out <= `SD 0;
		end else begin
			done <= #1 start;
			dest_tag_out <= `SD dest_tag_in;
		end
	end

endmodule // alu

module mult(
	input clock, reset,
	input [`XLEN-1:0] mcand, mplier,
	input start,
	input [`CDB_BITS-1:0] dest_tag_in,
	
	output [`XLEN-1:0] product,
	output [`CDB_BITS-1:0] dest_tag_out,
	output done
			);

  logic [`XLEN-1:0] mcand_out, mplier_out;
  logic [((`PIPELINE_DEPTH -1)*32)-1:0] internal_products, internal_mcands, internal_mpliers;
  logic [(`PIPELINE_DEPTH -2):0] internal_dones;
  logic [((`PIPELINE_DEPTH -1)*`CDB_BITS)-1:0] internal_dest_tag;
  
	mult_stage mstage [(`PIPELINE_DEPTH -1):0]  (
		.clock(clock),
		.reset(reset),
		.product_in({internal_products,32'h0}),
		.mplier_in({internal_mpliers,mplier}),
		.mcand_in({internal_mcands,mcand}),
		.start({internal_dones,start}),
		.dest_tag_in({internal_dest_tag,dest_tag_in}),
		.product_out({product,internal_products}),
		.mplier_out({mplier_out,internal_mpliers}),
		.mcand_out({mcand_out,internal_mcands}),
		.dest_tag_out({dest_tag_out, internal_dest_tag}),
		.done({done,internal_dones})
	);

endmodule

module mult_stage(
		input clock, reset, start,
		input [`XLEN-1:0] product_in, mplier_in, mcand_in,
		input [`CDB_BITS-1:0] dest_tag_in,

		output logic done,
		output logic[`CDB_BITS-1:0] dest_tag_out,
		output logic [`XLEN-1:0] product_out, mplier_out, mcand_out
				);



	logic [`XLEN-1:0] prod_in_reg, partial_prod_reg;
	logic [`XLEN-1:0] partial_product, next_mplier, next_mcand;

	assign product_out = prod_in_reg + partial_prod_reg;

	assign partial_product = mplier_in[(`MULT_WIDTH -1 ):0] * mcand_in;

	assign next_mplier = {`MULT_WIDTH'b0,mplier_in[(`XLEN-1):`MULT_WIDTH]};
	assign next_mcand = {mcand_in[((`XLEN-1)-`MULT_WIDTH):0],`MULT_WIDTH'b0};

	//synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		prod_in_reg      <= #1 product_in;
		partial_prod_reg <= #1 partial_product;
		mplier_out       <= #1 next_mplier;
		mcand_out        <= #1 next_mcand;
	end

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if(reset) begin
			done <= #1 1'b0;
			dest_tag_out <= `SD 0;
		end else begin
			done <= #1 start;
			dest_tag_out <= `SD dest_tag_in;
		end
	end


endmodule //mult stage

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

	output logic cond    // 0/1 condition result (False/True)
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
	end
	
endmodule // brcond


module ex_stage(
	input clock,               // system clock
	input reset,               // system reset
	input ISSUE_EX_PACKET   [`N_WAY-1 : 0] issue_ex_packet_in,
	output logic [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag,//to r10k
	output logic [`N_WAY-1 : 0]  reg_wr_en_out,//to r10k
	output logic [`N_WAY-1 : 0] [`XLEN-1:0] ex_result_out,
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
	logic [`N_WAY-1 : 0] brcond_result;
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
			if(issue_ex_packet_in[i].execution_unit == ALU && !tmp2) begin
				opa_mux_out[count_alu_a] = `XLEN'hdeadfbac;
				case (issue_ex_packet_in[count_alu_a].opa_select)
					OPA_IS_RS1:  opa_mux_out[count_alu_a] = issue_ex_packet_in[i].rs1_value;
					OPA_IS_NPC:  opa_mux_out[count_alu_a] = issue_ex_packet_in[i].NPC;
					OPA_IS_PC:   opa_mux_out[count_alu_a] = issue_ex_packet_in[i].PC;
					OPA_IS_ZERO: opa_mux_out[count_alu_a] = 0;
				endcase
				start_alu[count_alu_a] = 1; 
				dest_tag_in_alu[count_alu_a] = issue_ex_packet_in[i].dest_reg_idx; 
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
			if(issue_ex_packet_in[i].execution_unit == ALU && !tmp ) begin
				opb_mux_out[count_alu_b] = `XLEN'hfacefeed;
				case (issue_ex_packet_in[count_alu_b].opb_select)
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

	logic [$clog2(`EX_MULT_UNITS) : 0] count_mult;
	logic tmp1;
  	logic [`EX_MULT_UNITS-1 : 0] [`XLEN-1:0] mcand, mplier;
	logic [`EX_MULT_UNITS-1 : 0] start_mult,done_mult;
	logic [`EX_MULT_UNITS-1 : 0] [`XLEN-1:0] mult_result;
	logic [`EX_MULT_UNITS-1 : 0][`CDB_BITS-1:0] dest_tag_in_mult, dest_tag_out_mult;
	always_comb begin
		count_mult = 0;
		start_mult = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp1=0;
			if(issue_ex_packet_in[i].execution_unit == MULT && !tmp1 ) begin
				mcand[count_mult] = issue_ex_packet_in[i].rs1_value;
				mplier[count_mult] = issue_ex_packet_in[i].rs2_value;
				start_mult[count_mult] = 1;
				dest_tag_in_mult[count_mult] = issue_ex_packet_in[i].dest_reg_idx; 
				tmp1 = 1;
				count_mult = count_mult + 1;
			end
		end
	end

	//
	// instantiate the ALU
	//
	
	genvar j;
	generate
		for(j=0; j<`EX_ALU_UNITS; j=j+1) begin
			alu alu_0 (// Inputs
				.opa(opa_mux_out[j]),
				.opb(opb_mux_out[j]),
				.func(issue_ex_packet_in[j].alu_func),
				.start(start_alu[j]),
				.dest_tag_in(dest_tag_in_alu[j]),
				// Output
				.done(done_alu[j]),
				.dest_tag_out(dest_tag_out_alu[j]),
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
//	brcond brcond (// Inputs
//		.rs1(issue_ex_packet_in.rs1_value), 
//		.rs2(issue_ex_packet_in.rs2_value),
//		.func(issue_ex_packet_in.inst.b.funct3), // inst bits to determine check
//		// Output
//		.cond(brcond_result)
//	);count_alu_a
//
//	 // ultimate "take branch" signal:
//	 //	unconditional, or conditional and the condition is true
//	assign ex_packet_out.take_branch = issue_ex_packet_in.uncond_branch
//		                          | (issue_ex_packet_in.cond_branch & brcond_result);



//complete stage
	logic [$clog2(`N_WAY) : 0] count_out;
	logic [$clog2(2*`N_WAY) : 0] count_comp;
	logic [`EX_MULT_UNITS-1 : 0] completed_mult;
	logic [`EX_ALU_UNITS-1 : 0]  completed_alu;
	logic [2*`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag_wire,complete_dest_tag_next,complete_dest_tag_fifo;
	logic [2*`N_WAY-1 : 0] head,head_next,tail,tail_next;
	logic [2*`N_WAY-1 : 0] [`XLEN-1:0] result_out_wire,result_out_next,result_out_fifo;
	always_comb begin
		count_comp = 0;
		completed_mult = 0;
		completed_alu = 0;
		complete_dest_tag_wire = 0;
		result_out_wire = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			for(int j=0; j<`EX_MULT_UNITS; j=j+1) begin
				if(done_mult[j] && !completed_mult[j]) begin
					complete_dest_tag_wire[count_comp] = dest_tag_out_mult[j];
					result_out_wire[count_comp] = mult_result[j];
					completed_mult[j] = 1;
					count_comp =  count_comp + 1;
				end	
			end
			for(int j=0; j<`EX_ALU_UNITS; j=j+1) begin
				if(done_alu[j] && !completed_alu[j]) begin
					complete_dest_tag_wire[count_comp] = dest_tag_out_alu[j];
					result_out_wire[count_comp] = alu_result[j];
					completed_alu[j] = 1;
					count_comp =  count_comp + 1;
				end	
			end		
		end	
	end 
	always_comb begin
		complete_dest_tag_next = complete_dest_tag_fifo;
		result_out_next = result_out_fifo;
		head_next = head;
		tail_next = tail;
		count_out = 0;
		complete_dest_tag= 0 ; 
		for(int i=0; i<2*`N_WAY; i=i+1) begin
			if(head_next[i] && (count_out < `N_WAY)) begin
				complete_dest_tag[count_out] = complete_dest_tag_next[i];
				ex_result_out[count_out] = result_out_next[i];
				if(complete_dest_tag_next[i] != 0) begin
					head_next[i] = 0; 	
					if(i == 2*`N_WAY-1)
						head_next[0] = 1; 	
					else
						head_next[i+1] = 1; 	
				end
				count_out = count_out + 1;	
			end
		end
		for(int i=0; i<2*`N_WAY; i=i+1) begin
			for(int j=0; j<2*`N_WAY; j=j+1) begin
				if(tail_next[j] && (complete_dest_tag_wire[i]!=0)) begin
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
			reg_wr_en_out[i]  = complete_dest_tag[i]!= `ZERO_REG_PR;
		end	
	end

	always_ff @(posedge clock) begin
		if(reset) begin
			complete_dest_tag_fifo <=`SD 0;
			result_out_fifo <=`SD 0;
			for(int m = 0; m<2*`N_WAY; m = m+1) begin
				if(m == 0) begin
					head[m] <= `SD 1;
				end else if(m == 2*`N_WAY-1) begin
					tail[m] <= `SD 1;
				end else begin
					head[m] <= `SD 0;	
					tail[m] <= `SD 0;	
				end
			end
		end else begin
			complete_dest_tag_fifo <=`SD complete_dest_tag_next;
			result_out_fifo <=`SD result_out_next;
			head <= `SD head_next;
			tail <= `SD tail_next;
		end
	end


endmodule // module ex_stage
`endif // __EX_STAGE_V__
