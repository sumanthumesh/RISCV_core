/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  regfile.v                                           //
//                                                                     //
//  Description :  This module creates the Regfile used by the ID and  // 
//                 WB Stages of the Pipeline.                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __REGFILE_V__
`define __REGFILE_V__

`timescale 1ns/100ps

module regfile(
        input   [`N_WAY-1:0][`CDB_BITS-1:0]       rda_idx, // read index for register A
        input   [`N_WAY-1:0][`CDB_BITS-1:0]       rdb_idx, // read index for register B
        input   [`N_WAY-1:0][`CDB_BITS-1:0]       wr_idx,  // write index
        input   [`N_WAY-1:0][`XLEN-1:0] wr_data,        // write data
        input   [`N_WAY-1:0] wr_en,
        input   wr_clk,
        input   [$clog2(`N_PHY_REG):0]  zero_reg_pr,
        //`ifdef TESTBENCH
        output logic [`N_PHY_REG-1:0] [`XLEN-1:0] registers,
        //`endif
        output logic [`N_WAY-1:0][`XLEN-1:0]  rda_out,  // data read from register A
        output logic [`N_WAY-1:0][`XLEN-1:0]  rdb_out    // data read from register B
        
      );
  //`ifndef TESTBENCH
  //logic    [`N_PHY_REG-1:0] [`XLEN-1:0] registers;   // 32, 64-bit Registers
  //`endif
  logic  [`XLEN-1:0] write_value_a;
  logic  [`XLEN-1:0] write_value_b;
  wire   [`XLEN-1:0] rda_reg = registers[rda_idx];
  wire   [`XLEN-1:0] rdb_reg = registers[rdb_idx];
  logic a_write_flag; // Flag to check if register is being written to in this cycle
  logic b_write_flag; // Flag to check if register is being written to in this cycle


  //
  // Read port A
  //
  always_comb
    for(int i = 0; i < `N_WAY; i++)
    begin
      a_write_flag = 0;
      write_value_a = 0;
      if(rda_idx[i] == zero_reg_pr)
        rda_out[i] = 0;
      else if(wr_en[i])
      begin
        for(int j = 0; j < `N_WAY; j++)
        begin
          if(rda_idx[i] == wr_idx[j])
          begin
            write_value_a = wr_data[j];
            a_write_flag = 1;            
          end
        end // for-loop with loop variable j
        if(a_write_flag)
          rda_out[i] = write_value_a;
        else
          rda_out[i] = registers[rda_idx[i]];
      end // if(wr_en)
      else
        rda_out[i] = registers[rda_idx[i]];
    end // for-loop with loop variable i


  //
  // Read port B
  //
  always_comb
    for(int i = 0; i < `N_WAY; i++)
    begin
      b_write_flag = 0;
      write_value_b = 0;
      if(rdb_idx[i] == zero_reg_pr)
        rdb_out[i] = 0;
      else if(wr_en[i])
      begin
        for(int j = 0; j < `N_WAY; j++)
        begin
          if(rdb_idx[i] == wr_idx[j])
          begin
            write_value_b = wr_data[j];
            b_write_flag = 1;            
          end
        end // for-loop with loop variable j
        if(b_write_flag)
          rdb_out[i] = write_value_b;
        else
          rdb_out[i] = registers[rdb_idx[i]];
      end // if(wr_en)
      else
        rdb_out[i] = registers[rdb_idx[i]];
    end // for-loop with loop variable i

  
  //
  // Write port
  //
  always_ff @(posedge wr_clk)
      for(int i = 0; i < `N_WAY; i++)
      begin
      if(wr_en[i])
          registers[wr_idx[i]] <= `SD wr_data[i];
      end

endmodule // regfile
`endif //__REGFILE_V__
