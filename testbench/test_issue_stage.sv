`timescale 1ns/100ps

module testbench;

	// Inputs
    logic   clock;  // system clock
    logic   reset;  // system reset
    RS_PACKET_ISSUE [`N_WAY-1:0]	rs_packet_issue;   // packet of instructions sent to the reservation station to issue
	RS_PACKET_RETIRE	[`N_WAY-1:0]	rs_packet_retire; // packet of relevant data from the retire stage
	ROB_PACKET_ISSUE	[`N_ROB-1:0]	rob_packet;	// relevant data from the ROB that issue stage needs
	logic	[`N_WAY-1:0]	wb_reg_wr_en_out;
	logic	[`N_WAY-1:0][`CDB_BITS-1:0]	wb_reg_wr_idx_out;
	logic	[`N_WAY-1:0][`XLEN-1:0]	wb_reg_wr_data_out;
	// Outputs
	ISSUE_EX_PACKET		[`N_WAY-1:0]	issue_packet;
	logic 		[$clog2(`N_WAY):0] 	issue_num;
    logic	[$clog2(`N_WAY):0] count;
    logic   [$clog2(`N_PHY_REG):0]  zero_reg_pr; // shows which physical register is mapped to the zero register
    logic [$clog2(`N_PHY_REG):0]    i;


    issue_stage dut(
	.clock(clock),
	.reset(reset),
	.rs_packet_issue(rs_packet_issue),
	.rs_packet_retire(rs_packet_retire),
	.rob_packet(rob_packet),
	.wb_reg_wr_en_out(wb_reg_wr_en_out),
	.wb_reg_wr_idx_out(wb_reg_wr_idx_out),
    .wb_reg_wr_data_out(wb_reg_wr_data_out),
	.issue_packet(issue_packet),
    .issue_num(issue_num),
    .count(count),
    .zero_reg_pr(zero_reg_pr)
    );

    always #5 clock = ~clock;

    initial
    begin
        clock = 0;
        reset = 1;
        zero_reg_pr = 45;
        for(int i = 0; i < `N_WAY; i++)
        begin
            rs_packet_issue[i] = {
                0, // source_tag_1
                0, // source_tag_2
                0, //dest_tag
                0, // inst
                0 // valid
            };

            rs_packet_retire[i] = {
                0 // dest_tag
            };

            wb_reg_wr_en_out[i] = 0;
            wb_reg_wr_idx_out[i] = 0;
            wb_reg_wr_data_out[i] = 0;
        end


        for(int i = 0; i < `N_ROB; i++)
        begin
            rob_packet[i] = {
                0, // busy
                0 //phy_reg_idx
            };
        end

        for(i = 0;i < `N_PHY_REG; i++)
        begin
            @(negedge clock);
            wb_reg_wr_idx_out[0] = i;
            wb_reg_wr_data_out[0] = i;
            wb_reg_wr_en_out[0] = (i != zero_reg_pr);
        end

        @(negedge clock);
        reset = 0;
        for(int i = 0; i < `N_WAY; i++)
        begin
            wb_reg_wr_en_out[i] = 0;
        end

        rs_packet_issue[0].inst.r.funct7 = 7'b0000001;
        rs_packet_issue[0].inst.r.funct3 = `MD_MUL_FUN3;
        rs_packet_issue[0].inst.r.opcode = `RV32_OP;
        rs_packet_issue[0].inst.r.rs1 = $random%32;
        rs_packet_issue[0].inst.r.rs2 = $random%32;
        rs_packet_issue[0].inst.r.rd = $random%32;

        rs_packet_issue[0].source_tag_1 = 1;
        rs_packet_issue[0].source_tag_2 = 2;
        rs_packet_issue[0].dest_tag = 32;

        rs_packet_issue[1].inst.r.funct7 = 7'b0000001;
        rs_packet_issue[1].inst.r.funct3 = `MD_MULH_FUN3;
        rs_packet_issue[1].inst.r.opcode = `RV32_OP;
        rs_packet_issue[1].inst.r.rs1 = $random%32;
        rs_packet_issue[1].inst.r.rs2 = $random%32;
        rs_packet_issue[1].inst.r.rd = $random%32;
        rs_packet_issue[1].source_tag_1 = 3;
        rs_packet_issue[1].source_tag_2 = 4;
        rs_packet_issue[1].dest_tag = 33;

        rs_packet_issue[2].inst.r.funct7 = 7'b0000001;
        rs_packet_issue[2].inst.r.funct3 = `MD_MULHU_FUN3;
        rs_packet_issue[2].inst.r.opcode = `RV32_OP;
        rs_packet_issue[2].inst.r.rs1 = $random%32;
        rs_packet_issue[2].inst.r.rs2 = $random%32;
        rs_packet_issue[2].inst.r.rd = $random%32;
        rs_packet_issue[2].source_tag_1 = 5;
        rs_packet_issue[2].source_tag_2 = 6;
        rs_packet_issue[2].dest_tag = 34;

        rob_packet[0].busy = 1;
        rob_packet[1].busy = 1;
        rob_packet[2].busy = 1;
        
        rob_packet[0].phy_reg_idx = 32;
        rob_packet[1].phy_reg_idx = 33;
        rob_packet[2].phy_reg_idx = 34;

        @(negedge clock);

        @(negedge clock);

        @(negedge clock);

        @(negedge clock);
    $finish;

    end
endmodule
