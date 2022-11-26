module storeq(
	input clock,
	input reset,
	input [$clog2(`N_WAY):0] store_num_dis, //from dispatch,  make zero in rob for branch hazard
	input [`N_WAY-1:0][$clog2(`N_SQ):0] order_idx_in,
	input branch_haz,    
	input STORE_PACKET [`N_WAY-1:0] store_ex_packet_in, //from execute
	input [$clog2(`N_WAY):0] store_num_ret, //from rob, make zero in rob for branch hazard
	input LOAD_PACKET_IN [`N_WAY-1:0] load_packet_in,
	output STORE_PACKET_RET [`N_WAY-1:0] store_ret_packet_out, //from storeQ to Dcache
	output logic [$clog2(`N_WAY):0] empty_storeq,
	output logic [$clog2(`N_SQ):0] last_str_ex_idx,
	output LOAD_PACKET_OUT [`N_WAY-1:0] load_packet_out //from storeQ
);

	STORE_PACKET_REG [`N_SQ-1:0] storeq_reg;
	STORE_PACKET_REG [`N_SQ-1:0] storeq_wire_ret;
	STORE_PACKET_REG [`N_SQ-1:0] storeq_wire_ex;
	STORE_PACKET_REG [`N_SQ-1:0] storeq_next;
	logic [$clog2(`N_SQ):0] empty_storeq_reg;
	logic [$clog2(`N_SQ):0] empty_storeq_wire;
	logic [$clog2(`N_SQ):0] empty_storeq_next;
	logic tmp,tmp1;
	logic [`N_WAY-1:0] [$clog2(`N_SQ):0] order_pos;
	logic [$clog2(`N_SQ):0] tmp_order_pos;
	

	assign empty_storeq= (empty_storeq_wire <=`N_WAY ) ?  empty_storeq_wire : `N_WAY;

//retire stage logic
//
	always_comb begin
		storeq_wire_ret = storeq_reg;
		empty_storeq_wire = empty_storeq_reg;
		store_ret_packet_out = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp = 0;
			if (i<store_num_ret) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					if(!tmp) begin
						if (storeq_wire_ret[j].head) begin
							store_ret_packet_out[i].value = storeq_reg[j].value; 
							store_ret_packet_out[i].address= storeq_reg[j].address; 
							store_ret_packet_out[i].valid= storeq_reg[j].valid; 
							storeq_wire_ret[j].head = 0;
							storeq_wire_ret[j].valid= 0;
							storeq_wire_ret[j].ex= 0;
							storeq_wire_ret[j].address = 0;
							storeq_wire_ret[j].value= 0;
							storeq_wire_ret[j].order_idx= 0;
							tmp =1;
							empty_storeq_wire = empty_storeq_wire + 1;
							if(j == `N_SQ-1)
								storeq_wire_ret[0].head = 1;
							else
								storeq_wire_ret[j+1].head = 1;
						end
					end
				end
			end
		end
		for(int k = 0; k<`N_SQ; k=k+1) begin
			if(storeq_wire_ret[k].order_idx != 0)  begin
				storeq_wire_ret[k].order_idx = storeq_wire_ret[k].order_idx -  store_num_ret;
			end
		end
	end

//execute stage logic

	always_comb begin
		storeq_wire_ex= storeq_wire_ret;
		for(int i=0; i<`N_WAY; i=i+1) begin
			if (store_ex_packet_in[i].valid && !branch_haz) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					if (j == store_ex_packet_in[i].store_pos) begin
						storeq_wire_ex[j].ex = 1;
						storeq_wire_ex[j].address = store_ex_packet_in[i].address;
						storeq_wire_ex[j].value = store_ex_packet_in[i].value;
					end
				end
			end
		end
	end	

//dispatch stage logic
//
	always_comb begin
		storeq_next= storeq_wire_ex;
		empty_storeq_next = empty_storeq_wire;
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp1=0;
			if (i < store_num_dis) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					if (!tmp1) begin
						storeq_next[j].tail = 0;
						empty_storeq_next= empty_storeq_next - 1;
						tmp1 = 1;
						if(j == `N_SQ-1) begin
							storeq_next[0].tail = 1;
							storeq_next[0].order_idx = order_idx_in[i] - store_num_ret;
						end else begin
							storeq_next[j+1].tail = 1;
							storeq_next[j+1].order_idx = order_idx_in[i] - store_num_ret;
						end
					end
				end
			end
		end
	end

//load logic
//
	always_comb begin
		load_packet_out = 0;
		last_str_ex_idx=0;
		for(int i=0; i<`N_WAY; i=i+1) begin
	    		for(int j=0; j<`N_SQ; j=j+1) begin
				if (j == load_packet_in[i].load_pos && load_packet_in[i].valid) order_pos[i]=storeq_reg[j].order_idx;
			end
		end
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp_order_pos = 0;
			if (load_packet_in[i].valid) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					if ((load_packet_in[i].address == storeq_reg[j].address) && (storeq_reg[j].order_idx < order_pos))begin
						if(storeq_reg[j].order_idx > tmp_order_pos) begin
							tmp_order_pos = storeq_reg[j].order_idx;
							load_packet_out[i].valid = 1;
							load_packet_out[i].value = storeq_reg[j].value;
					     	end			
					end
				end
			end
		end
		for (int k=1; k<=`N_SQ; k=k+1) begin
			if((k==storeq_reg[k].order_idx)&& storeq_reg[k].ex) begin
				last_str_ex_idx = storeq_reg[k].order_idx;
			end
		end
	end

	always_ff @(posedge clock) begin
		if(reset) begin
			for (int m=0; m<`N_SQ; m=m+1) begin
				storeq_reg[m].valid <= `SD 0;
				storeq_reg[m].ex<= `SD 0;
				storeq_reg[m].address <= `SD 0;
				storeq_reg[m].value<= `SD 0;
				storeq_reg[m].order_idx<= `SD 0;
				if (m==0) 
				storeq_reg[m].head<= `SD 1;
				else 
				storeq_reg[m].head<= `SD 0;
				if (m==`N_ROB-1) 
				storeq_reg[m].tail <= `SD 1;
				else 
				storeq_reg[m].tail <= `SD 0;
			end
			empty_storeq_reg <= `SD `N_SQ;
		end else begin
			if (!branch_haz) begin
				storeq_reg <= `SD storeq_next;
				empty_storeq_reg <= `SD empty_storeq_next;
			end else begin
				for (int m=0; m<`N_SQ; m=m+1) begin
					storeq_reg[m].valid <= `SD 0;
					storeq_reg[m].ex<= `SD 0;
					storeq_reg[m].address <= `SD 0;
					storeq_reg[m].value<= `SD 0;
					storeq_reg[m].order_idx<= `SD 0;
					if (m==0) 
					storeq_reg[m].head<= `SD 1;
					else 
					storeq_reg[m].head<= `SD 0;
					if (m==`N_ROB-1) 
					storeq_reg[m].tail <= `SD 1;
					else 
					storeq_reg[m].tail <= `SD 0;
				end
				empty_storeq_reg <= `SD `N_SQ;
			end
		end
	end
endmodule
