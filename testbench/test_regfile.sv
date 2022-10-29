`timescale 1ns/100ps
`ifndef TESTBENCH
`define TESTBENCH
`endif
module testbench;

	logic  [`N_WAY-1:0][`CDB_BITS-1:0]       rda_idx; // read index for register A
    logic  [`N_WAY-1:0][`CDB_BITS-1:0]       rdb_idx; // read index for register B
    logic  [`N_WAY-1:0][`CDB_BITS-1:0]       wr_idx;  // write index
    logic  [`N_WAY-1:0][`XLEN-1:0] wr_data;        // write data
    logic  [`N_WAY-1:0] wr_en;
    logic        clock;
    logic   [$clog2(`N_PHY_REG):0]  zero_reg_pr;
    logic [`N_WAY-1:0][`XLEN-1:0]  rda_out;  // data read from register A
    logic [`N_WAY-1:0][`XLEN-1:0]  rdb_out;    // data read from register B
    logic [`N_PHY_REG-1:0][`XLEN-1:0] registers;
    logic [$clog2(`N_PHY_REG):0]    i;
        
    // `ifndef TESTBENCH
    // `define TESTBENCH
    // `endif


    regfile dut(
	.rda_idx(rda_idx),
	.rdb_idx(rdb_idx),
	.wr_idx(wr_idx),
	.wr_data(wr_data),
	.wr_en(wr_en),
	.wr_clk(clock),
	.rda_out(rda_out),
    .rdb_out(rdb_out),
    .registers(registers),
    .zero_reg_pr(zero_reg_pr)
    );

    always #5 clock = ~clock;

   
    initial begin
        clock = 1'b0;
        zero_reg_pr = 45;
        for(int j = 0; j < `N_WAY; j++)
        begin
            rda_idx[j] = 0;
            rdb_idx[j] = 0;
            wr_idx[j] = 0;
            wr_data[j] = 0;
            wr_en[j] = 0;
        end
        
        for(i = 0; i < `N_PHY_REG; i++)
        begin
            @(negedge clock);
            for(int j = 0;j < (i%`N_WAY)+1; j++)
            begin
                wr_en[j] = (j != zero_reg_pr);
                wr_data[j] = i;
                wr_idx[j] = j;
            end
        end

        for(i = 0;i < `N_PHY_REG; i++)
        begin
            @(negedge clock);
            wr_idx[0] = i;
            wr_data[0] = i;
            wr_en[0] = (i != zero_reg_pr);
        end

        for(int j = 0; j < `N_PHY_REG; j++)
        begin
        @(negedge clock);
        rda_idx[0] = j;
        end

        @(negedge clock);

        
        $finish;




    end



endmodule
