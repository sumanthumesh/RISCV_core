`timescale 1ns/100ps

module testbench;

	// Inputs
    logic   clock;  // system clock
    logic   reset;  // system reset
    RS_PACKET_ISSUE [`N_WAY-1:0]	rs_packet_issue;   // packet of instructions sent to the reservation station to issue
	logic	[`N_WAY-1:0]	wb_reg_wr_en_out;
	logic	[`N_WAY-1:0][`CDB_BITS-1:0]	wb_reg_wr_idx_out;
	logic	[`N_WAY-1:0][`XLEN-1:0]	wb_reg_wr_data_out;
	// Outputs
	ISSUE_EX_PACKET		[`N_WAY-1:0]	issue_packet;
	logic	[$clog2(`N_WAY):0] count;
    logic	[$clog2(`N_WAY):0] issue_num;
    logic	[$clog2(`N_WAY):0] actual_issue_num;
    
    logic   [$clog2(`N_PHY_REG):0]  zero_reg_pr; // shows which physical register is mapped to the zero register
    logic [$clog2(`N_PHY_REG):0]    i;

    RS_PACKET_ISSUE         [35:0]    rs_packet_issue_test;
    logic                   [35:0]      enable_test;
    logic                   [35:0]      memory_index;
    logic                   [35:0]      memory_data;

    int inst_counter;


    issue_stage dut(
	.clock(clock),
	.reset(reset),
	.rs_packet_issue(rs_packet_issue),
	.wb_reg_wr_en_out(wb_reg_wr_en_out),
	.wb_reg_wr_idx_out(wb_reg_wr_idx_out),
    .wb_reg_wr_data_out(wb_reg_wr_data_out),
	.issue_packet(issue_packet),
    .count(count),
    .issue_num(issue_num),
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
                `CDB_BITS'b0, // source_tag_1
                `CDB_BITS'b0, // source_tag_2
                `CDB_BITS'b0, //dest_tag
                `XLEN'b0, // inst
                1'b0 // valid
            };

            wb_reg_wr_en_out[i] = 0;
            wb_reg_wr_idx_out[i] = 0;
            wb_reg_wr_data_out[i] = 0;
        end
        inst_counter = 0;

        rs_packet_issue_test[0].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[0].inst.r.funct3 = `MD_MUL_FUN3;
        rs_packet_issue_test[0].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[0].inst.r.rs1 = $random%32;
        rs_packet_issue_test[0].inst.r.rs2 = $random%32;
        rs_packet_issue_test[0].inst.r.rd = $random%32;
        rs_packet_issue_test[0].source_tag_1 = 1;
        rs_packet_issue_test[0].source_tag_2 = 2;
        rs_packet_issue_test[0].dest_tag = 32;
        rs_packet_issue_test[0].valid = 1;

        rs_packet_issue_test[1].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[1].inst.r.funct3 = `MD_MULH_FUN3;
        rs_packet_issue_test[1].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[1].inst.r.rs1 = $random%32;
        rs_packet_issue_test[1].inst.r.rs2 = $random%32;
        rs_packet_issue_test[1].inst.r.rd = $random%32;
        rs_packet_issue_test[1].source_tag_1 = 3;
        rs_packet_issue_test[1].source_tag_2 = 4;
        rs_packet_issue_test[1].dest_tag = 33;
        rs_packet_issue_test[1].valid = 1;

        rs_packet_issue_test[2].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[2].inst.r.funct3 = `MD_MULHU_FUN3;
        rs_packet_issue_test[2].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[2].inst.r.rs1 = $random%32;
        rs_packet_issue_test[2].inst.r.rs2 = $random%32;
        rs_packet_issue_test[2].inst.r.rd = $random%32;
        rs_packet_issue_test[2].source_tag_1 = 5;
        rs_packet_issue_test[2].source_tag_2 = 6;
        rs_packet_issue_test[2].dest_tag = 34;
        rs_packet_issue_test[2].valid = 1;

        rs_packet_issue_test[3].inst.i.imm = $random%4096;
        rs_packet_issue_test[3].inst.i.rs1 = $random%32;
        rs_packet_issue_test[3].inst.i.funct3 = 3'b000;
        rs_packet_issue_test[3].inst.i.rd = $random%32;
        rs_packet_issue_test[3].inst.i.opcode = 7'b0010011;
        rs_packet_issue_test[3].source_tag_1 = 7;
        rs_packet_issue_test[3].source_tag_2 = 8;
        rs_packet_issue_test[3].dest_tag = 35;
        rs_packet_issue_test[3].valid = 1;

        rs_packet_issue_test[4].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[4].inst.r.funct3 = `MD_MUL_FUN3;
        rs_packet_issue_test[4].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[4].inst.r.rs1 = $random%32;
        rs_packet_issue_test[4].inst.r.rs2 = $random%32;
        rs_packet_issue_test[4].inst.r.rd = $random%32;
        rs_packet_issue_test[4].source_tag_1 = 1;
        rs_packet_issue_test[4].source_tag_2 = 2;
        rs_packet_issue_test[4].dest_tag = 32;
        rs_packet_issue_test[4].valid = 1;

        rs_packet_issue_test[5].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[5].inst.r.funct3 = `MD_MULH_FUN3;
        rs_packet_issue_test[5].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[5].inst.r.rs1 = $random%32;
        rs_packet_issue_test[5].inst.r.rs2 = $random%32;
        rs_packet_issue_test[5].inst.r.rd = $random%32;
        rs_packet_issue_test[5].source_tag_1 = 3;
        rs_packet_issue_test[5].source_tag_2 = 4;
        rs_packet_issue_test[5].dest_tag = 33;
        rs_packet_issue_test[5].valid = 1;

        rs_packet_issue_test[6].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[6].inst.r.funct3 = `MD_MULHU_FUN3;
        rs_packet_issue_test[6].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[6].inst.r.rs1 = $random%32;
        rs_packet_issue_test[6].inst.r.rs2 = $random%32;
        rs_packet_issue_test[6].inst.r.rd = $random%32;
        rs_packet_issue_test[6].source_tag_1 = 5;
        rs_packet_issue_test[6].source_tag_2 = 6;
        rs_packet_issue_test[6].dest_tag = 34;
        rs_packet_issue_test[6].valid = 1;

        rs_packet_issue_test[7].inst.i.imm = $random%4096;
        rs_packet_issue_test[7].inst.i.rs1 = $random%32;
        rs_packet_issue_test[7].inst.i.funct3 = 3'b000;
        rs_packet_issue_test[7].inst.i.rd = $random%32;
        rs_packet_issue_test[7].inst.i.opcode = 7'b0010011;
        rs_packet_issue_test[7].source_tag_1 = 7;
        rs_packet_issue_test[7].source_tag_2 = 8;
        rs_packet_issue_test[7].dest_tag = 35;
        rs_packet_issue_test[7].valid = 1;

        rs_packet_issue_test[8].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[8].inst.r.funct3 = `MD_MUL_FUN3;
        rs_packet_issue_test[8].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[8].inst.r.rs1 = $random%32;
        rs_packet_issue_test[8].inst.r.rs2 = $random%32;
        rs_packet_issue_test[8].inst.r.rd = $random%32;
        rs_packet_issue_test[8].source_tag_1 = 1;
        rs_packet_issue_test[8].source_tag_2 = 2;
        rs_packet_issue_test[8].dest_tag = 32;
        rs_packet_issue_test[8].valid = 1;

        rs_packet_issue_test[9].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[9].inst.r.funct3 = `MD_MULH_FUN3;
        rs_packet_issue_test[9].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[9].inst.r.rs1 = $random%32;
        rs_packet_issue_test[9].inst.r.rs2 = $random%32;
        rs_packet_issue_test[9].inst.r.rd = $random%32;
        rs_packet_issue_test[9].source_tag_1 = 3;
        rs_packet_issue_test[9].source_tag_2 = 4;
        rs_packet_issue_test[9].dest_tag = 33;
        rs_packet_issue_test[9].valid = 1;

        rs_packet_issue_test[10].inst.r.funct7 = 7'b0000001;
        rs_packet_issue_test[10].inst.r.funct3 = `MD_MULHU_FUN3;
        rs_packet_issue_test[10].inst.r.opcode = `RV32_OP;
        rs_packet_issue_test[10].inst.r.rs1 = $random%32;
        rs_packet_issue_test[10].inst.r.rs2 = $random%32;
        rs_packet_issue_test[10].inst.r.rd = $random%32;
        rs_packet_issue_test[10].source_tag_1 = 5;
        rs_packet_issue_test[10].source_tag_2 = 6;
        rs_packet_issue_test[10].dest_tag = 34;
        rs_packet_issue_test[10].valid = 1;

        rs_packet_issue_test[11].inst.i.imm = $random%4096;
        rs_packet_issue_test[11].inst.i.rs1 = $random%32;
        rs_packet_issue_test[11].inst.i.funct3 = 3'b000;
        rs_packet_issue_test[11].inst.i.rd = $random%32;
        rs_packet_issue_test[11].inst.i.opcode = 7'b0010011;
        rs_packet_issue_test[11].source_tag_1 = 7;
        rs_packet_issue_test[11].source_tag_2 = 8;
        rs_packet_issue_test[11].dest_tag = 35;
        rs_packet_issue_test[11].valid = 1;

        for(i = 0;i < `N_PHY_REG; i++)
        begin
            @(negedge clock);
            wb_reg_wr_idx_out[0] = i;
            wb_reg_wr_data_out[0] = i;
            wb_reg_wr_en_out[0] = (i != zero_reg_pr);
        end

        for(i = 0; i < 12; i++)
        begin
            @(negedge clock);
            reset = 0;
            actual_issue_num = $random%(issue_num + 1);
            for(int i = 0; i < `N_WAY; i++)
            begin
                wb_reg_wr_en_out[i] = 0;
            end
            for(int j = 0; j < actual_issue_num; j++)
            begin
                if(inst_counter <= 35)
                begin
                    rs_packet_issue[j].inst = rs_packet_issue_test[inst_counter].inst;
                    rs_packet_issue[j].source_tag_1 = rs_packet_issue_test[inst_counter].source_tag_1;
                    rs_packet_issue[j].source_tag_2 = rs_packet_issue_test[inst_counter].source_tag_2;
                    rs_packet_issue[j].dest_tag = rs_packet_issue_test[inst_counter].dest_tag;
                    rs_packet_issue[j].valid = rs_packet_issue_test[inst_counter].valid;
                    inst_counter++;
                end
                else
                begin
                    rs_packet_issue[j].valid = 0;
                end
            end
            for(int j = actual_issue_num; j < `N_WAY; j++)
            begin
                rs_packet_issue[j].valid = 0;
            end
        end

        @(negedge clock);
    $finish;

    end
endmodule
