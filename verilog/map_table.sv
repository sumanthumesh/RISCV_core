`timescale 1ns/100ps

module map_table(
	input clock,
	input reset,
	input DISPATCH_ROB_PACKET dis_packet[`N_WAY],
	input [`CDB_BITS -1 :0] pr_freelist[`N_WAY],
	input [`CDB_BITS-1 :0] pr_reg_complete[`N_WAY],
	output PR_PACKET pr_packet_out1[`N_WAY],
	output PR_PACKET pr_packet_out2[`N_WAY]
);

	PR_PACKET map_reg[`XLEN];
	logic [`XLEN_BITS : 0] i;
	logic [`XLEN_BITS : 0] j;
	logic [3 : 0] n,n1,k;
	logic src1_complete[`N_WAY],src2_complete[`N_WAY];
	logic [`XLEN_BITS-1 : 0] arch_reg_complete[`N_WAY];
	always_ff @(posedge clock) begin
		if(reset) begin
			for (i=0; i<`XLEN; i=i+1) begin
				map_reg[i].phy_reg <= `SD i+1;	
				map_reg[i].status <= `SD 1;	
			end
		end else begin
			for (n1=0; n1<`N_WAY; n1=n1+1) begin
				if(dis_packet[n1].valid) begin //updating the map table in dispatch stage based on the inst
					map_reg[dis_packet[n1].dest].phy_reg <= `SD pr_freelist[n1];
					if (dis_packet[n1].dest!=0)
						map_reg[dis_packet[n1].dest].status <= `SD 0;
					else 
						map_reg[dis_packet[n1].dest].status <= `SD 1;
				end
				map_reg[arch_reg_complete[n1]].status <= `SD 1;
			end	
		end
	end
	
	always_comb begin //outputs to reservation station tags
		for (n=0; n<`N_WAY; n=n+1) begin
			arch_reg_complete[n] = 0;
			for (j=0; j<`XLEN; j=j+1) begin  //linear search for updating status in complete stage
				if (map_reg[j].phy_reg == pr_reg_complete[n])	
					arch_reg_complete[n] = j;
			end
		end
		for (n=0; n<`N_WAY; n=n+1) begin
		        src1_complete[n] = 0;
			src2_complete[n] = 0;
			for (k=0; k<`N_WAY; k=k+1) begin //check for N-way completion 
				if(dis_packet[n].src1 == arch_reg_complete[k])
					src1_complete[n] = 1;
				if(dis_packet[n].src2 == arch_reg_complete[k])
					src2_complete[n] = 1;
			end
			if(dis_packet[n].valid) begin
				if(src1_complete[n] == 1) begin
					pr_packet_out1[n].phy_reg = map_reg[dis_packet[n].src1].phy_reg;
					pr_packet_out1[n].status  = 1; 
				end else begin
					pr_packet_out1[n] = map_reg[dis_packet[n].src1];
				end
				if(src2_complete[n] == 1) begin
					pr_packet_out2[n].phy_reg = map_reg[dis_packet[n].src2].phy_reg;
					pr_packet_out2[n].status  = 1; 
				end else begin
					pr_packet_out2[n] = map_reg[dis_packet[n].src2];
				end
			end
			if (n>0) begin
				for(k=0;k<n;k=k+1) begin
					if(dis_packet[n].src1 == dis_packet[k].dest) begin
						pr_packet_out1[n].phy_reg = pr_freelist[k];
						if (dis_packet[k].dest!=0)
							pr_packet_out1[n].status  = 0; 
						else
							pr_packet_out1[n].status  = 1; 
					end
					if(dis_packet[n].src2 == dis_packet[k].dest) begin
						pr_packet_out2[n].phy_reg = pr_freelist[k];
						if (dis_packet[k].dest!=0)
							pr_packet_out2[n].status  = 0; 
						else
							pr_packet_out2[n].status  = 1; 
					end
				end
			end
		end
	end


endmodule
