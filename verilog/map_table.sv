`timescale 1ns/100ps

module map_table(
	input clock,
	input reset,
	input DISPATCH_PACKET [`N_WAY -1 : 0] dis_packet,
	input [`N_WAY-1 : 0] [`CDB_BITS -1 :0] pr_freelist,
	input [`N_WAY-1 : 0] [`CDB_BITS-1 :0] pr_reg_complete,
	input [`XLEN-1:0][`CDB_BITS-1:0] arch_reg,
	input branch_haz,
	output PR_PACKET [`N_WAY-1 : 0] pr_packet_out1,
	output PR_PACKET [`N_WAY-1 : 0] pr_packet_out2,
	output logic [`N_WAY-1:0][`CDB_BITS-1:0] pr_old
);

	PR_PACKET [`XLEN-1:0] map_reg;
	logic [`XLEN_BITS : 0] i;
	logic [`XLEN_BITS : 0] j;
	logic [3 : 0] n,n1,n2,k,k1;
	logic [`N_WAY-1 : 0]src1_complete,src2_complete;
	logic [`N_WAY-1 : 0] src1_match,src2_match, dest_match;
	logic [`N_WAY-1 : 0] [`XLEN_BITS-1 : 0] arch_reg_complete;
	always_ff @(posedge clock) begin
		if(reset) begin
			for (i=0; i<`XLEN; i=i+1) begin
				map_reg[i].phy_reg <= `SD i+1;	
				map_reg[i].status <= `SD 1;	
			end
		end else begin
			if(branch_haz) begin
				for(int i=0; i<`XLEN; i=i+1) begin
					map_reg[i].phy_reg <= `SD arch_reg[i];
					map_reg[i].status <= `SD 1;
				end
			end
			for (n1=0; n1<`N_WAY; n1=n1+1) begin
				map_reg[arch_reg_complete[n1]].status <= `SD 1;
				if(dis_packet[n1].valid && (pr_freelist[n1] !=0)) begin //updating the map table in dispatch stage based on the inst
					if (dis_packet[n1].dest!=0) begin
						map_reg[dis_packet[n1].dest].status <= `SD 0;
						map_reg[dis_packet[n1].dest].phy_reg <= `SD pr_freelist[n1];
					end else begin 
						map_reg[dis_packet[n1].dest].status <= `SD 1;
						map_reg[dis_packet[n1].dest].phy_reg <= `SD 1;
					end
				end
			end	
		end
	end
	
	always_comb begin //outputs to reservation station tags
		arch_reg_complete = 0;
		for (n2=0; n2<`N_WAY; n2=n2+1) begin
			for (j=0; j<`XLEN; j=j+1) begin  //linear search for updating status in complete stage
				if (map_reg[j].phy_reg == pr_reg_complete[n2])	
					arch_reg_complete[n2] = j;
			end
		end
	end
	
	always_comb begin //sending told to rob
		dest_match = 0;
		pr_old = 0;
		for(int n_d=0; n_d<`N_WAY; n_d=n_d+1) begin
			if(dis_packet[n_d].valid) begin
				for(int n_d1=0; n_d1<`N_WAY; n_d1=n_d1+1) begin
					if(n_d1<n_d) begin
						if((dis_packet[n_d].dest == dis_packet[n_d1].dest) && (dis_packet[n_d1].valid) && (dis_packet[n_d1].dest!=0)) begin
							dest_match[n_d] = 1;
							pr_old[n_d] = pr_freelist[n_d1];
							
						end
					end
				end
				if(!dest_match[n_d]) begin
					pr_old[n_d] = map_reg[dis_packet[n_d].dest].phy_reg;
				end
			end
		end
	end

	always_comb begin
		src1_complete= 0;
		src2_complete = 0;
		src1_match = 0;
		src2_match = 0;
		pr_packet_out1 = 0;
		pr_packet_out2 = 0;
		for (n=0; n<`N_WAY; n=n+1) begin
			for (k=0; k<`N_WAY; k=k+1) begin //check for N-way completion 
				if(dis_packet[n].src1 == arch_reg_complete[k])
					src1_complete[n] = 1;
				if(dis_packet[n].src2 == arch_reg_complete[k])
					src2_complete[n] = 1;
			end
			if (dis_packet[n].valid) begin
				for(k1=0;k1<`N_WAY;k1=k1+1) begin
					if (k1<n) begin
						if((dis_packet[n].src1 == dis_packet[k1].dest) && (dis_packet[k1].valid)) begin
							src1_match[n] = 1;
							pr_packet_out1[n].phy_reg = pr_freelist[k1];
							if (dis_packet[k1].dest!=0)
								pr_packet_out1[n].status  = 0; 
							else
								pr_packet_out1[n].status  = 1; 
						end
						if((dis_packet[n].src2 == dis_packet[k1].dest) && (dis_packet[k1].valid)) begin
							src2_match[n] = 1;
							pr_packet_out2[n].phy_reg = pr_freelist[k1];
							if (dis_packet[k1].dest!=0)
								pr_packet_out2[n].status  = 0; 
							else
								pr_packet_out2[n].status  = 1; 
						end
					end
				end
				if(src1_match[n] == 0) begin
					if(src1_complete[n] == 1) begin
						pr_packet_out1[n].phy_reg = map_reg[dis_packet[n].src1].phy_reg;
						pr_packet_out1[n].status  = 1; 
					end else begin
						pr_packet_out1[n] = map_reg[dis_packet[n].src1];
					end
				end
				if(src2_match[n] == 0) begin
					if(src2_complete[n] == 1) begin
						pr_packet_out2[n].phy_reg = map_reg[dis_packet[n].src2].phy_reg;
						pr_packet_out2[n].status  = 1; 
					end else begin
						pr_packet_out2[n] = map_reg[dis_packet[n].src2];
					end
				end
			end
			if((dis_packet[n].src1 == 0) && dis_packet[n].valid) begin
				pr_packet_out1[n].phy_reg = 1;
				pr_packet_out1[n].status  = 1;
			end
			if((dis_packet[n].src2 == 0) && dis_packet[n].valid) begin
				pr_packet_out2[n].phy_reg = 1;
				pr_packet_out2[n].status  = 1;
			end
		end
	end


endmodule
