/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  reservation_station.v                               //
//                                                                     //
//  Description :   reservation station (RS) of the pipeline;    // 
//                  store the instructions which have been dispatched, //
//                  track availability of required data                //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`timescale 1ns/100ps
/**********************************************************************************************************************************************/
/* Assumptions that this reservation station has made:
1. There are exactly the same number of valid bits in the 'valid' array variable as there are valid instructions to be allocated space in the reservation station.
2. The valid instructions are back-to-back since instructions are dispatched in order. 
3. The entries in the variable 'ex_rs_idx' are all valid. If something is not valid, then it has been previously flushed out.
4. There are minimum as many number of slots available in the reservation station as many instructions have been dispatched. 
*/
module reservation_station(
	input           clock,
	input           reset,
	input RS_PACKET_DISPATCH [`N_WAY-1:0] rs_packet_dispatch,
	input   [`N_WAY-1:0] [`CDB_BITS-1:0]  ex_rs_dest_idx,      
	input   [`N_WAY-1:0][`CDB_BITS-1:0] cdb_rs_reg_idx,    
	input [$clog2(`N_WAY)-1:0] issue_num,
	output  RS_PACKET_ISSUE [`N_WAY-1:0]    rs_packet_issue,
	//output  PR_PACKET       [`N_WAY-1:0]    pr_packet_out1,
	//output  PR_PACKET       [`N_WAY-1:0]    pr_packet_out2,
	//output  logic [`N_WAY-1:0] [`CDB_BITS-1:0]    pr_dest_tag,
	//output  logic [`N_WAY-1:0] [6:0]    issue_opcode,
	//output  logic [`N_WAY-1:0] issue_valid,
	output logic [$clog2(`N_RS):0]  rs_empty
);
	RS_PACKET   [`N_RS-1:0] rs_data;
	RS_PACKET   [`N_RS-1:0] rs_data_wire;
	RS_PACKET   [`N_RS-1:0] rs_data_next;
	logic [`N_RS-1:0] [$clog2(`N_RS):0] order_idx_ex; //to track the oldest instruction
	
	//completet stage logic
	logic [$clog2(`N_RS):0] i_c1,i1;
	logic [$clog2(`N_WAY):0] i_c2;
	always_comb begin
		for(i1=0; i1<`N_RS; i1=i1+1) begin
			rs_data_wire[i1].source_tag_1_plus = rs_data[i1].source_tag_1_plus;
			rs_data_wire[i1].source_tag_2_plus = rs_data[i1].source_tag_2_plus;
		end
		for (i_c1=0; i_c1 < `N_RS; i_c1=i_c1+1) begin
			for (i_c2=0; i_c2 < `N_WAY; i_c2=i_c2+1) begin
				if(rs_data[i_c1].busy) begin
					if(cdb_rs_reg_idx[i_c2] == rs_data[i_c1].source_tag_1) begin
						rs_data_wire[i_c1].source_tag_1_plus = 1;
					end
					if(cdb_rs_reg_idx[i_c2] == rs_data[i_c1].source_tag_2) begin
						rs_data_wire[i_c1].source_tag_2_plus = 1;
					end
				end
			end	
		end
	end
	//execute stage logic
	logic [$clog2(`N_RS):0] i_x1,i2;
	logic [$clog2(`N_WAY):0] i_x2;
	always_comb begin
		for(i2=0; i2<`N_RS; i2=i2+1) begin
			rs_data_wire[i2].busy = rs_data[i2].busy;
			order_idx_ex[i2]=rs_data[i2].order_idx;
		end
		for (i_x1=0; i_x1 < `N_RS; i_x1=i_x1+1) begin
			for (i_x2=0; i_x2 < `N_WAY; i_x2=i_x2+1) begin
				if(rs_data[i_x1].busy) begin
					if(ex_rs_dest_idx[i_x2] == rs_data[i_x1].dest_tag) begin
						rs_data_wire[i_x1].busy=0;
						order_idx_ex[i_x1] = 0;
					end
				end			
			end
		end
	end
 	//order tracking logci for oldest inst issue first
	logic [$clog2(`N_RS):0] i_ix, k,i3;
	always_comb begin
		rs_empty = `N_RS;
		for(i3=0; i3<`N_RS; i3=i3+1) begin
			rs_data_wire[i3].order_idx= rs_data[i3].order_idx;
		end
		for(i_ix=0; i_ix<`N_RS; i_ix=i_ix+1) begin
			if(rs_data[i_ix].busy) begin
				rs_empty = rs_empty - 1;
				if(rs_data[i_ix].order_idx != order_idx_ex[i_ix]) begin
					rs_data_wire[i_ix].order_idx = order_idx_ex[i_ix];
					for (k=0;k<`N_RS; k=k+1) begin
						if(rs_data[k].order_idx > rs_data[i_ix].order_idx) begin
							rs_data_wire[k].order_idx = rs_data_wire[k].order_idx - 1;
						end
					end
				end
			end
		end
	end
	//issue stage logic
	logic [$clog2(`N_RS):0] i_o, i_is,i5,i6;
	logic [$clog2(`N_WAY):0] count;
	always_comb begin
		count = 0;
		//rs_packet_issue = 0;
		for(i6=0; i6<`N_WAY; i6=i6+1) begin
			rs_packet_issue[i6].valid = 0;
		end
		for(i5=0; i5<`N_RS; i5=i5+1) begin
			rs_data_wire[i5].issued= rs_data[i5].issued;
		end
		for (i_o=1; i_o<=`N_RS; i_o=i_o+1) begin
			for(i_is=0; i_is<`N_RS; i_is=i_is+1) begin
				if(rs_data[i_is].busy) begin
					if((rs_data_wire[i_is].source_tag_1_plus && rs_data_wire[i_is].source_tag_2_plus) && (!rs_data_wire[i_is].issued) && (rs_data_wire[i_is].order_idx == i_o) && (count <issue_num)) begin
					//if((rs_data_wire[i_is].source_tag_1_plus && rs_data_wire[i_is].source_tag_2_plus) && (rs_data_wire[i_is].order_idx == i_o) && (count <issue_num)) begin
						rs_packet_issue[count].source_tag_1 = rs_data[i_is].source_tag_1;
						rs_packet_issue[count].source_tag_2 = rs_data[i_is].source_tag_2;
						rs_packet_issue[count].dest_tag = rs_data[i_is].dest_tag;
						rs_packet_issue[count].opcode = rs_data[i_is].opcode;
						//rs_packet_issue[count].valid = 1;
						rs_data_wire[i_is].issued = 1;
						count= count+1;
					end
				end
			end
		end
	end
	//dispatch state logic
	logic [$clog2(`N_RS):0] i_d2,i4;
	logic [$clog2(`N_WAY):0] i_d1;
	logic tmp;
	always_comb begin
		rs_data_next= rs_data;
		for(i4=0; i4<`N_RS; i4=i4+1) begin
			rs_data_next[i4].source_tag_1_plus= rs_data_wire[i4].source_tag_1_plus;
			rs_data_next[i4].source_tag_2_plus= rs_data_wire[i4].source_tag_2_plus;
			rs_data_next[i4].busy = rs_data_wire[i4].busy;
			rs_data_next[i4].order_idx = rs_data_wire[i4].order_idx;
			//rs_data_next[i4].issued = rs_data_wire[i4].issued;
		end
		for (i_d1=0; i_d1 < `N_WAY ; i_d1=i_d1+1) begin
			tmp = 1;
			if (rs_packet_dispatch[i_d1].valid) begin
				for (i_d2=0; i_d2<`N_RS; i_d2=i_d2+1) begin
					if(!rs_data_next[i_d2].busy && tmp) begin
						rs_data_next[i_d2].busy = rs_packet_dispatch[i_d1].busy;
						rs_data_next[i_d2].opcode= rs_packet_dispatch[i_d1].opcode;
						rs_data_next[i_d2].dest_tag= rs_packet_dispatch[i_d1].dest_tag;
						rs_data_next[i_d2].source_tag_1= rs_packet_dispatch[i_d1].source_tag_1;
						rs_data_next[i_d2].source_tag_2= rs_packet_dispatch[i_d1].source_tag_2;
						rs_data_next[i_d2].source_tag_1_plus= rs_packet_dispatch[i_d1].source_tag_1_plus;
						rs_data_next[i_d2].source_tag_2_plus= rs_packet_dispatch[i_d1].source_tag_2_plus;
						rs_data_next[i_d2].order_idx = rs_packet_dispatch[i_d1].order_idx;
						tmp = 0;
					end
				end
			end
		end
	end	
		
       //clocked register 
	always_ff @ (posedge clock) begin
		if(reset) begin
			rs_data <= `SD 0;
		end else begin
			rs_data <= `SD rs_data_next;
		end	
	end
    
endmodule  // module reservation_station
