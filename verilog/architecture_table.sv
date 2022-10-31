`timescale 1ns/100ps

module architecture_table(
	input clock,
	input reset,
	input RETIRE_ROB_PACKET [`N_WAY-1:0] ret_packet
);

	logic [`XLEN-1:0][`CDB_BITS-1:0] arch_reg;
	logic [`XLEN_BITS : 0] i;
	logic [3 : 0] n1;
	always_ff @(posedge clock) begin
		if(reset) begin
			for (i=0; i<`XLEN; i=i+1) begin
				arch_reg[i] <= `SD i+1;	
			end
		end else begin
			for (n1=0; n1<`N_WAY; n1=n1+1) begin
				if(ret_packet[n1].ret_valid) begin //updating the arch table in retire stage from ROB
					arch_reg[ret_packet[n1].tag_old] <= `SD ret_packet[n1].tag;
				end
			end	
		end
	end
	
endmodule
