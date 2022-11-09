//ROB
//
module rob (
	input clock,
	input reset,
	input [`N_WAY-1 : 0] [`CDB_BITS-1:0] complete_dest_tag,
	input  ROB_PACKET_DISPATCH [`N_WAY-1:0] rob_packet_dis,
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_tag, 
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] retire_told,
	output logic [`N_WAY-1:0]retire_valid,
	output logic [`N_WAY-1:0]dispatched,
	output ROB_PACKET [`N_ROB-1:0] rob_packet,
	output logic [$clog2(`N_WAY):0] empty_rob
);
	ROB_PACKET [`N_ROB-1:0] rob_packet_next;
	ROB_PACKET [`N_ROB-1:0] rob_packet_wire;
	//ROB_PACKET [`N_ROB-1:0] rob_packet;
	logic [$clog2(`N_ROB):0] empty_rob_reg, empty_rob_wire, empty_rob_next;
	logic tmp, tmp1;

	assign empty_rob = (empty_rob_wire <=`N_WAY ) ?  empty_rob_wire : `N_WAY;
 

	always_comb begin
		rob_packet_wire = rob_packet;
		retire_valid = 0 ;		
		retire_tag =  0;		
		retire_told = 0;
		empty_rob_wire = empty_rob_reg;		
		//retire_stage
		for(int i=0; i<`N_WAY; i=i+1) begin	
			tmp = 0;
				for(int j=0; j<`N_ROB; j=j+1) begin
					if(!tmp) begin
						if((rob_packet_wire[j].head) && rob_packet[j].completed ) begin
							retire_valid[i] = 1 ;		
							retire_tag[i] = rob_packet[j].tag ;		
							retire_told[i] = rob_packet[j].tag_old ;		
							if(j == `N_ROB-1)
								rob_packet_wire[0].head = 1;
							else
								rob_packet_wire[j+1].head = 1;
							rob_packet_wire[j] = 0;
							tmp = 1;
							empty_rob_wire = empty_rob_wire + 1;	
						end
					end
				end
		end 
		//completer_stage
		for(int i=0; i<`N_WAY; i=i+1) begin
			for(int j=0; j<`N_ROB; j=j+1) begin
				if ((rob_packet_wire[j].tag == complete_dest_tag[i]) && (complete_dest_tag[i]!=0)) begin
					rob_packet_wire[j].completed = 1;
				end
			end
		end	
	end

	always_comb begin //dispatch stage logic
		rob_packet_next = rob_packet_wire;
		empty_rob_next =  empty_rob_wire;
		dispatched = 0 ;	//check zero if no packet is dispatched
		for(int k=0 ; k<`N_WAY; k=k+1) begin
			if(rob_packet_dis[k].valid) begin
				tmp1 = 0;	
				for(int y=0; y<`N_ROB; y=y+1) begin
					if(rob_packet_next[y].tail && !tmp1) begin
						rob_packet_next[y].tail = 0;
						empty_rob_next =empty_rob_next - 1;
						tmp1 = 1;
						dispatched[k] = 1; 
						if(y == `N_ROB-1) begin
							rob_packet_next[0].tag = rob_packet_dis[k].tag; //compare unique tag in instruction buffer to get the number of inst dispatched each cycle
							rob_packet_next[0].tag_old = rob_packet_dis[k].tag_old; 
							rob_packet_next[0].tail = 1;
						end else begin
							rob_packet_next[y+1].tag = rob_packet_dis[k].tag; 
							rob_packet_next[y+1].tag_old = rob_packet_dis[k].tag_old; 
							rob_packet_next[y+1].tail = 1; 
						end
					end
				end
			end
		end
	end 

	always_ff @(posedge clock) begin
		if(reset) begin
			for (int m=0; m<`N_ROB; m=m+1) begin
				rob_packet[m].tag <= `SD 0;
				rob_packet[m].tag_old <= `SD 0;
				rob_packet[m].completed <= `SD 0;
				if (m==0) 
				rob_packet[m].head <= `SD 1;
				else 
				rob_packet[m].head <= `SD 0;
				if (m==`N_ROB-1) 
				rob_packet[m].tail <= `SD 1;
				else 
				rob_packet[m].tail <= `SD 0;
			end
			empty_rob_reg <= `SD `N_ROB;
		end else begin
			rob_packet <= `SD rob_packet_next;
			empty_rob_reg <= `SD empty_rob_next;
		end
	end
endmodule
