`timescale 1ns/100ps

module free_list(
	input clock,
	input reset,
	input [`CDB_BITS-1 : 0] data_in,
	input rd,
	input wr,
	output logic [`CDB_BITS-1 : 0] data_out,
	output logic empty
	//output full
);

	logic [`FIFO_BITS : 0] count;
	logic [`FIFO_BITS : 0] read_count;
	logic [`FIFO_BITS : 0] write_count;
	logic rd_wr_prev; //1: previos read 0: previous write
	logic rd_wr_curr; 
	logic [`FIFO_BITS : 0] i;
	logic full;
	logic [`N_ROB-1 : 0] [`CDB_BITS-1 : 0] free_list;

	assign empty = ((count == 0) && rd_wr_prev) ? 1 :0;
	assign full = ((count == 0) && !rd_wr_prev) ? 1 :0;
	
	always_ff @(posedge clock) begin
		if(reset) begin
			read_count <= `SD 0;
			write_count <= `SD 0;
			data_out <= `SD 0;
			rd_wr_prev <= `SD 0;
			rd_wr_curr <= `SD 0;
			for (i=0; i<`N_ROB; i=i+1) begin
				free_list[i] <= `SD i+33;	
			end
		end else begin
			if(rd == 1 && wr == 0 && empty == 0) begin
				data_out <= `SD free_list[read_count];
				free_list[read_count] <= `SD 0 ;
				rd_wr_curr <= `SD 1;
				rd_wr_prev <= `SD rd_wr_curr;
				if(read_count < `N_ROB-1)
					read_count <= `SD read_count + 1;
				else 
					read_count <= `SD 0;
			end else if (wr == 1 && rd == 0  && full == 0) begin
				free_list[write_count] <= `SD data_in;
				rd_wr_curr <= `SD 0;
				rd_wr_prev <= `SD rd_wr_curr;
				if(write_count < `N_ROB-1)
					write_count <= `SD write_count + 1;
				else
					write_count <= `SD 0;
			end else if (rd == 1 && wr == 1) begin
				if (full == 0) begin
					if (empty == 0)
						free_list[write_count] <= `SD data_in;
					if(write_count < `N_ROB-1)
						write_count <= `SD write_count + 1;
					else
						write_count <= `SD 0;
				end
				if (empty == 0) begin
					data_out <= `SD free_list[read_count];
					free_list[read_count] <= `SD 0 ;
				end else begin
					data_out <= `SD data_in;
				end
				rd_wr_curr <= `SD 1;
				rd_wr_prev <= `SD rd_wr_curr;
				if(read_count < `N_ROB-1)
					read_count <= `SD read_count + 1;
				else 
					read_count <= `SD 0;
			end
			else;
//		        if(write_count > read_count) begin
//		        	count = write_count - read_count;
//		        end else begin
//		        	count = read_count - write_count;
//		        end
		end
	end

	always_comb begin
		if(write_count > read_count) begin
			count = write_count - read_count;
		end else begin
			count = read_count - write_count;
		end
	end

endmodule
