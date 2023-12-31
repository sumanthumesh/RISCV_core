module storeq(
	input clock,
	input reset,
	input [$clog2(`N_WAY):0] store_num_dis, //from dispatch,  make zero in rob for branch hazard
	input [`N_WAY-1:0][$clog2(`N_SQ):0] order_idx_in,
	input branch_haz,    
	input STORE_PACKET [`N_WAY-1:0] store_ex_packet_in, //from execute
	input [$clog2(`N_WAY):0] store_num_ret, //from rob, make zero in rob for branch hazard
	input LOAD_PACKET_IN [`N_WAY-1:0] load_packet_in,
	input STORE_PACKET_EX_STAGE [`N_WR_PORTS-1 : 0] store_packet_dcache,
	//input STORE_PACKET_RET [`N_WR_PORTS-1 : 0] store_packet_dcache,
	output STORE_PACKET_RET [`N_WAY-1:0] store_ret_packet_out, //from storeQ to Dcache
	output logic [$clog2(`N_SQ):0] empty_storeq,
	output logic [$clog2(`N_SQ):0] last_str_ex_idx,
	output LOAD_PACKET_OUT [`N_WAY-1:0] load_packet_out //from storeQ
);

	STORE_PACKET_REG [`N_SQ-1:0] storeq_reg;
	STORE_PACKET_REG [`N_SC-1:0] storeq_copy;
	STORE_PACKET_REG [`N_SQ-1:0] storeq_wire_ret;
	STORE_PACKET_REG [`N_SQ-1:0] storeq_wire_ex;
	STORE_PACKET_REG [`N_SQ-1:0] storeq_next;
	logic [$clog2(`N_SQ):0] empty_storeq_reg;
	logic [$clog2(`N_SQ):0] empty_storeq_wire;
	logic [$clog2(`N_SQ):0] empty_storeq_next;
	logic tmp,tmp1;
	logic [`N_WAY-1:0] [$clog2(`N_SQ):0] order_pos;
	logic [$clog2(`N_SQ):0] tmp_order_pos;
	logic tmp_last;
	logic [$clog2(`N_SQ):0] last_str_ex_idx_next;
	logic branch_haz_reg;
	logic [2:0] copy_idx;

	//assign empty_storeq= (empty_storeq_wire <=`N_WAY ) ?  empty_storeq_wire : `N_WAY;
	assign empty_storeq= empty_storeq_wire ;

//retire stage logic
//
	always_comb begin
		storeq_wire_ret = storeq_reg;
		empty_storeq_wire = empty_storeq_reg;
		store_ret_packet_out = 0;
		if(store_packet_dcache[0].valid && storeq_wire_ret[store_packet_dcache[0].store_pos-1].ex && (storeq_wire_ret[store_packet_dcache[0].store_pos-1].address == store_packet_dcache[0].address)) begin 
			storeq_wire_ret[store_packet_dcache[0].store_pos-1].retired = 0;
			storeq_wire_ret[store_packet_dcache[0].store_pos-1].address = 0;
			storeq_wire_ret[store_packet_dcache[0].store_pos-1].value = 0;
			//storeq_wire_ret[store_packet_dcache[0].store_pos-1].ex = 0;
			//storeq_wire_ret[store_packet_dcache[0].store_pos-1].order_idx = 0;
			storeq_wire_ret[store_packet_dcache[0].store_pos-1].size = 0;
			empty_storeq_wire = empty_storeq_wire + 1;
			for(int k = 0; k<`N_SQ; k=k+1) begin
				if(storeq_wire_ret[k].order_idx != 0)  begin
					storeq_wire_ret[k].order_idx = storeq_wire_ret[k].order_idx - 1;
				end
			end
		end
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp = 0;
			if (i<store_num_ret) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					if(!tmp) begin
						if (storeq_wire_ret[j].head) begin
							store_ret_packet_out[i].data = storeq_reg[j].value; 
							store_ret_packet_out[i].address= storeq_reg[j].address; 
							store_ret_packet_out[i].valid= 1; 
							store_ret_packet_out[i].size= storeq_reg[j].size; 
							store_ret_packet_out[i].store_pos= j+1; 
							storeq_wire_ret[j].head = 0;
							storeq_wire_ret[j].valid= 0;
							storeq_wire_ret[j].retired = 1;
							//storeq_wire_ret[j].ex= 0;
							//storeq_wire_ret[j].address = 0;
							//storeq_wire_ret[j].value= 0;
							//storeq_wire_ret[j].order_idx= 0;
							//storeq_wire_ret[j].size= 0;
							tmp =1;
							//empty_storeq_wire = empty_storeq_wire + 1;
							if(j == `N_SQ-1)
								storeq_wire_ret[0].head = 1;
							else
								storeq_wire_ret[j+1].head = 1;
						end
					end
				end
			end
		end
		//for(int k = 0; k<`N_SQ; k=k+1) begin
		//	if(storeq_wire_ret[k].order_idx != 0)  begin
		//		storeq_wire_ret[k].order_idx = storeq_wire_ret[k].order_idx -  store_num_ret;
		//	end
		//end
	end

//execute stage logic

	always_comb begin
		storeq_wire_ex= storeq_wire_ret;
		for(int i=0; i<`N_WAY; i=i+1) begin
			if (store_ex_packet_in[i].valid && !branch_haz) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					if (j == store_ex_packet_in[i].store_pos-1) begin
						storeq_wire_ex[j].ex = 1;
						storeq_wire_ex[j].address = store_ex_packet_in[i].address;
						storeq_wire_ex[j].value = store_ex_packet_in[i].value;
						storeq_wire_ex[j].size = store_ex_packet_in[i].size;
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
					if (storeq_next[j].tail && !tmp1) begin
						storeq_next[j].tail = 0;
						empty_storeq_next= empty_storeq_next - 1;
						tmp1 = 1;
						if(j == `N_SQ-1) begin
							storeq_next[0].tail = 1;
							//storeq_next[0].order_idx = order_idx_in[i] - store_num_ret;
							storeq_next[0].order_idx = order_idx_in[i];
							storeq_next[0].retired = 0;
			                                storeq_next[0].ex = 0;
						end else begin
							storeq_next[j+1].tail = 1;
							//storeq_next[j+1].order_idx = order_idx_in[i] - store_num_ret;
							storeq_next[j+1].order_idx = order_idx_in[i];
							storeq_next[j+1].retired = 0;
			                                storeq_next[j+1].ex = 0;
						end
					end
				end
			end
		end
	end

//load logic
//
	//copy load logic to solve retired store packets clearing due to haz
	logic [`XLEN-1:0] tmp_copy_value; 
	LOAD_PACKET_OUT [`N_WAY-1:0] load_packet_copy_out; 
	logic check_store_copy;
	always_comb begin
		load_packet_copy_out = 0;
		tmp_copy_value=0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			if(check_store_copy && load_packet_in[i].valid) begin
				for(int j=0; j<`N_SC; j=j+1) begin
					case(storeq_copy[j].size)
						BYTE:	begin 
							  if((load_packet_in[i].size == BYTE) && (load_packet_in[i].address == storeq_copy[j].address)) begin
								load_packet_copy_out[i].valid = 1;
								load_packet_copy_out[i].value = load_packet_in[i].sign ? storeq_copy[j].value[7:0] :
														    {{(`XLEN-8){storeq_copy[j].value[7]}},storeq_copy[j].value[7:0]};
								load_packet_copy_out[i].dest_tag = load_packet_in[i].dest_tag;
							  end
							end
						HALF:	begin 
							  if((load_packet_in[i].size == HALF) && (load_packet_in[i].address == storeq_copy[j].address)) begin
								load_packet_copy_out[i].valid = 1;
								load_packet_copy_out[i].value = load_packet_in[i].sign ? storeq_copy[j].value[15:0] :
														    {{(`XLEN-16){storeq_copy[j].value[15]}},storeq_copy[j].value[15:0]};
								load_packet_copy_out[i].dest_tag = load_packet_in[i].dest_tag;
							  end 
							  else if((load_packet_in[i].size == BYTE) && (load_packet_in[i].address[`XLEN-1:1] == storeq_copy[j].address[`XLEN-1:1])) begin
								load_packet_copy_out[i].valid = 1;
								tmp_copy_value = load_packet_in[i].address[0] ? storeq_copy[j].value[15:8] : storeq_copy[j].value[7:0];
								load_packet_copy_out[i].value = load_packet_in[i].sign ? tmp_copy_value :
														    {{(`XLEN-8){tmp_copy_value[7]}},tmp_copy_value[7:0]};
								load_packet_copy_out[i].dest_tag = load_packet_in[i].dest_tag;
							  end
							end
						WORD:	begin 
							  if((load_packet_in[i].size == WORD) && (load_packet_in[i].address == storeq_copy[j].address)) begin
								load_packet_copy_out[i].valid = 1;
								load_packet_copy_out[i].value = storeq_copy[j].value;
								load_packet_copy_out[i].dest_tag = load_packet_in[i].dest_tag;
							  end 
							  else if((load_packet_in[i].size == HALF) && (load_packet_in[i].address[`XLEN-1:2] == storeq_copy[j].address[`XLEN-1:2])) begin
								load_packet_copy_out[i].valid = 1;
								tmp_copy_value = load_packet_in[i].address[1] ? storeq_copy[j].value[31:16] : storeq_copy[j].value[15:0];
								load_packet_copy_out[i].value = load_packet_in[i].sign ? tmp_copy_value :
														    {{(`XLEN-16){tmp_copy_value[15]}},tmp_copy_value[15:0]};
								load_packet_copy_out[i].dest_tag = load_packet_in[i].dest_tag;
							  end
							  else if((load_packet_in[i].size == BYTE) && (load_packet_in[i].address[`XLEN-1:2] == storeq_copy[j].address[`XLEN-1:2])) begin
								load_packet_copy_out[i].valid = 1;
								tmp_copy_value                = (load_packet_in[i].address[1:0] == 2'b11) ? storeq_copy[j].value[31:24] : 
											   (load_packet_in[i].address[1:0] == 2'b10) ? storeq_copy[j].value[23:16] :
											   (load_packet_in[i].address[1:0] == 2'b01) ? storeq_copy[j].value[15:8]  : storeq_copy[j].value[7:0];
								load_packet_copy_out[i].value = load_packet_in[i].sign ? tmp_copy_value :
														    {{(`XLEN-8){tmp_copy_value[7]}},tmp_copy_value[7:0]};
								load_packet_copy_out[i].dest_tag = load_packet_in[i].dest_tag;
							  end
							end
					endcase
				end
			end
		end
	end

	//main load logic
	logic [`XLEN-1:0] tmp_value; 
	LOAD_PACKET_OUT [`N_WAY-1:0] load_packet_main; 
	always_comb begin
		load_packet_main = 0;
		tmp_value=0;
		order_pos= 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
	    		for(int j=0; j<`N_SQ; j=j+1) begin
				if (j == load_packet_in[i].load_pos-1 && load_packet_in[i].valid) order_pos[i]=storeq_reg[j].order_idx;
			end
		end
		for(int i=0; i<`N_WAY; i=i+1) begin
			tmp_order_pos = 0;
			if (load_packet_in[i].valid) begin
				for(int j=0; j<`N_SQ; j=j+1) begin
					//if ((load_packet_in[i].address == storeq_reg[j].address) && (storeq_reg[j].order_idx < order_pos))begin
					if (storeq_reg[j].order_idx <= order_pos[i])begin
						//if(storeq_reg[j].order_idx >= tmp_order_pos) begin
							case(storeq_reg[j].size)
								BYTE:	begin 
									  if((load_packet_in[i].size == BYTE) && (load_packet_in[i].address == storeq_reg[j].address)) begin
										tmp_order_pos = (storeq_reg[j].order_idx >= tmp_order_pos)? storeq_reg[j].order_idx : tmp_order_pos;
										load_packet_main[i].valid = 1;
										load_packet_main[i].value = load_packet_in[i].sign ? storeq_reg[j].value[7:0] :
																    {{(`XLEN-8){storeq_reg[j].value[7]}},storeq_reg[j].value[7:0]};
										load_packet_main[i].dest_tag = load_packet_in[i].dest_tag;
									  end
									end
								HALF:	begin 
									  if((load_packet_in[i].size == HALF) && (load_packet_in[i].address == storeq_reg[j].address)) begin
										tmp_order_pos = (storeq_reg[j].order_idx >= tmp_order_pos)? storeq_reg[j].order_idx : tmp_order_pos;
										load_packet_main[i].valid = 1;
										load_packet_main[i].value = load_packet_in[i].sign ? storeq_reg[j].value[15:0] :
																    {{(`XLEN-16){storeq_reg[j].value[15]}},storeq_reg[j].value[15:0]};
										load_packet_main[i].dest_tag = load_packet_in[i].dest_tag;
									  end 
									  else if((load_packet_in[i].size == BYTE) && (load_packet_in[i].address[`XLEN-1:1] == storeq_reg[j].address[`XLEN-1:1])) begin
										tmp_order_pos = (storeq_reg[j].order_idx >= tmp_order_pos)? storeq_reg[j].order_idx : tmp_order_pos;
										load_packet_main[i].valid = 1;
										tmp_value = load_packet_in[i].address[0] ? storeq_reg[j].value[15:8] : storeq_reg[j].value[7:0];
										load_packet_main[i].value = load_packet_in[i].sign ? tmp_value :
																    {{(`XLEN-8){tmp_value[7]}},tmp_value[7:0]};
										load_packet_main[i].dest_tag = load_packet_in[i].dest_tag;
									  end
									end
								WORD:	begin 
									  if((load_packet_in[i].size == WORD) && (load_packet_in[i].address == storeq_reg[j].address)) begin
										tmp_order_pos = (storeq_reg[j].order_idx >= tmp_order_pos)? storeq_reg[j].order_idx : tmp_order_pos;
										load_packet_main[i].valid = 1;
										load_packet_main[i].value = storeq_reg[j].value;
										load_packet_main[i].dest_tag = load_packet_in[i].dest_tag;
									  end 
									  else if((load_packet_in[i].size == HALF) && (load_packet_in[i].address[`XLEN-1:2] == storeq_reg[j].address[`XLEN-1:2])) begin
										tmp_order_pos = (storeq_reg[j].order_idx >= tmp_order_pos)? storeq_reg[j].order_idx : tmp_order_pos;
										load_packet_main[i].valid = 1;
										tmp_value = load_packet_in[i].address[1] ? storeq_reg[j].value[31:16] : storeq_reg[j].value[15:0];
										load_packet_main[i].value = load_packet_in[i].sign ? tmp_value :
																    {{(`XLEN-16){tmp_value[15]}},tmp_value[15:0]};
										load_packet_main[i].dest_tag = load_packet_in[i].dest_tag;
									  end
									  else if((load_packet_in[i].size == BYTE) && (load_packet_in[i].address[`XLEN-1:2] == storeq_reg[j].address[`XLEN-1:2])) begin
										tmp_order_pos = (storeq_reg[j].order_idx >= tmp_order_pos)? storeq_reg[j].order_idx : tmp_order_pos;
										load_packet_main[i].valid = 1;
										tmp_value                = (load_packet_in[i].address[1:0] == 2'b11) ? storeq_reg[j].value[31:24] : 
													   (load_packet_in[i].address[1:0] == 2'b10) ? storeq_reg[j].value[23:16] :
													   (load_packet_in[i].address[1:0] == 2'b01) ? storeq_reg[j].value[15:8]  : storeq_reg[j].value[7:0];
										load_packet_main[i].value = load_packet_in[i].sign ? tmp_value :
																    {{(`XLEN-8){tmp_value[7]}},tmp_value[7:0]};
										load_packet_main[i].dest_tag = load_packet_in[i].dest_tag;
									  end
									end
							endcase
					     	//end			
					end
				end
			end
		end
	end

//mux b/w 2 load_packet_out's
	always_comb begin
		load_packet_out = 0;
		for(int i=0; i<`N_WAY; i=i+1) begin
			load_packet_out[i] = (load_packet_copy_out[i].valid && !load_packet_main[i].valid) ? load_packet_copy_out[i] : load_packet_main[i];
		end
	end

	always_comb begin
		last_str_ex_idx_next = last_str_ex_idx;
		tmp_last = 0;
		for (int k=1; k<=`N_SQ; k=k+1) begin
			if(!tmp_last) begin
				for (int j=0; j<`N_SQ; j=j+1) begin
					if(storeq_reg[j].order_idx == k) begin
						if(storeq_reg[j].ex) last_str_ex_idx_next = j+1;
						else tmp_last = 1;
					end
				end
			end
		end
	end

	always_ff @(posedge clock) begin
		if(reset) begin
			branch_haz_reg <= `SD 0;
			storeq_copy <= `SD 0;
			for (int m=0; m<`N_SQ; m=m+1) begin
				storeq_reg[m].valid <= `SD 0;
				storeq_reg[m].ex<= `SD 0;
				storeq_reg[m].address <= `SD 0;
				storeq_reg[m].value<= `SD 0;
				storeq_reg[m].order_idx<= `SD 0;
				storeq_reg[m].retired <= `SD 0;
				storeq_reg[m].size <= `SD 0;
				copy_idx <= `SD 0;
				if (m==0) 
				storeq_reg[m].head<= `SD 1;
				else 
				storeq_reg[m].head<= `SD 0;
				if (m==`N_SQ-1) 
				storeq_reg[m].tail <= `SD 1;
				else 
				storeq_reg[m].tail <= `SD 0;
			end
			last_str_ex_idx <= `SD 0;
			empty_storeq_reg <= `SD `N_SQ;
			check_store_copy <= `SD 0;
		end else begin
			branch_haz_reg <= `SD branch_haz;
			//acknowledge ment from dcache to storeq copy
			for(int j=0; j<`N_SC; j++) begin
				//if(store_packet_dcache[0].valid && (storeq_copy[j].address == store_packet_dcache[0].address) && (storeq_copy[j].store_pos == store_packet_dcache[0].store_pos)) begin 
				if(store_packet_dcache[0].valid && (storeq_copy[j].address == store_packet_dcache[0].address)) begin 
					storeq_copy[j] <= `SD 0;	
				end
			end

			if (!branch_haz_reg) begin
				storeq_reg <= `SD storeq_next;
				empty_storeq_reg <= `SD empty_storeq_next;
				last_str_ex_idx <= `SD last_str_ex_idx_next;
			end else begin
				copy_idx <= `SD 0;
				check_store_copy <= `SD 0;
				for (int m=0; m<`N_SQ; m=m+1) begin
					if(storeq_reg[m].retired) begin
						check_store_copy <= `SD 1;
						storeq_copy[copy_idx] <= `SD storeq_reg[m];
						copy_idx <= `SD copy_idx+1;
					end
					storeq_reg[m].valid <= `SD 0;
					storeq_reg[m].ex<= `SD 0;
					storeq_reg[m].address <= `SD 0;
					storeq_reg[m].value<= `SD 0;
					storeq_reg[m].order_idx<= `SD 0;
					storeq_reg[m].retired <= `SD 0;
					storeq_reg[m].size <= `SD 0;
					if (m==0) 
					storeq_reg[m].head<= `SD 1;
					else 
					storeq_reg[m].head<= `SD 0;
					if (m==`N_SQ-1) 
					storeq_reg[m].tail <= `SD 1;
					else 
					storeq_reg[m].tail <= `SD 0;
				end
				last_str_ex_idx <= `SD 0;
				empty_storeq_reg <= `SD `N_SQ;
			end
		end
	end
endmodule

