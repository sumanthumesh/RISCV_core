`timescale 1ns/100ps

module free_list(
	input clock,
	input reset,
	input [`N_WAY-1:0][`CDB_BITS-1 : 0] rob_told,
	input [$clog2(`N_WAY):0] dispatch_num,
	output logic [`N_WAY-1:0][`CDB_BITS-1 : 0] free_list_out,
	output logic [$clog2(`N_WAY) : 0] free_num
	//output full
);

	
	logic tmp,tmp1;
	logic [$clog2(`N_WAY):0] count;
	logic [`N_WAY-1:0] rob_told_used;
	logic [`N_ROB+32-1 : 0] free, free_next;
	logic [$clog2(`N_ROB+32):0] free_num_int, free_num_int_reg;
	//logic [`N_ROB+32-1 : 0] [`CDB_BITS-1 : 0] free_list;
	assign free_num = (free_num_int_reg <=`N_WAY ) ?  free_num_int_reg : `N_WAY;
			 	
	//dispatch stage
	always_comb begin
		free_next = free;
		free_num_int = free_num_int_reg;
		count = 0;
	 	rob_told_used = 0;	
		for (int i=0; i<`N_WAY; i=i+1) begin
			tmp = 0;
			if(i < dispatch_num && free_num_int > 0) begin
				for (int j=0; j<(`N_ROB+32); j=j+1) begin
					if((free_next[j]==1) && (!tmp)) begin
						free_list_out[i] = j+1;
						free_next[j] = 0;
						tmp = 1;
						count = count + 1;
					end
				end
				if(tmp)	free_num_int = free_num_int - 1;
			end 
		end
		for (int i=0; i<`N_WAY; i=i+1) begin
			tmp1 = 0;
			if(i< (dispatch_num-count)) begin
				for (int j=0; j<`N_WAY; j=j+1) begin
					if(!tmp1 && !rob_told_used[j]) begin
						free_list_out[i] = rob_told[j];
						rob_told_used[j] = 1;
						tmp1 = 1;
					end
				end
			end
		end
	
		for (int i=0; i<`N_WAY; i=i+1) begin
			if((rob_told[i] != 0) && (!rob_told_used[i])) begin
				free_next[rob_told[i]-1] = 1;
				free_num_int = free_num_int + 1;
			end
		end//retire_stage
	end	
	always_ff @(posedge clock) begin
		if(reset) begin
			free_num_int_reg <= `SD `N_ROB;
			for (int i=0; i<(`N_ROB+32); i=i+1) begin
			//	free_list[i] <= `SD i+1;
				if(i > 31) 
					free[i] <= `SD 1;
				else
					free[i] <= `SD 0;	
			end
		end else begin
			free_num_int_reg <= `SD free_num_int;
			free <= `SD free_next;
		end
	end

	always_comb begin
	end

endmodule
