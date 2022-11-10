`timescale 1ns/100ps

module architecture_table(
	input clock,
	input reset,
	input RETIRE_ROB_PACKET [`N_WAY-1:0] ret_packet,
	output logic [`XLEN-1:0][`CDB_BITS-1:0] arch_reg_next
);

	logic [`XLEN-1:0][`CDB_BITS-1:0] arch_reg;
	logic [`XLEN_BITS : 0] i;
	always_ff @(posedge clock) begin
		if(reset) begin
			for (i=0; i<`XLEN; i=i+1) begin
				arch_reg[i] <= `SD i+1;	
			end
		end else begin
			arch_reg <= `SD arch_reg_next;
		end
	end

	always_comb begin
		arch_reg_next = arch_reg ;
		for (int n=0; n<`N_WAY; n=n+1) begin
			for(int i=0; i<`XLEN; i=i+1)begin
				if(ret_packet[n].ret_valid) begin //updating the arch table in retire stage from ROB
					if(arch_reg_next[i] == ret_packet[n].tag_old) begin
						arch_reg_next[i] =  ret_packet[n].tag;
					end
				end
			end

		end	

	end
	
endmodule
