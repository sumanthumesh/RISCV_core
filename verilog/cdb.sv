`timescale 1ns/100ps

module cdb(
	input clock,
	input reset,
	input [`N_WAY-1 : 0] [`CDB_BITS-1 : 0]  input_tag,
	output logic [`N_WAY-1 : 0] [`CDB_BITS-1 : 0] cdb_tag
);
	
	always_ff @(posedge clock) begin
		if(reset)
			cdb_tag <= `SD 0;
		else
			cdb_tag <= `SD input_tag;  //complete stage will send 0 in the cycles where nothing is getting completed
	end

endmodule //module cdb
