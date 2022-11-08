`timescale 1ns/100ps


module test_rs;

 // Inputs
	logic	          clock;
	logic	          reset;
	RS_PACKET_DISPATCH [`N_WAY-1:0] rs_packet_dispatch;
	logic	  [`N_WAY-1:0] [`CDB_BITS-1:0]  ex_rs_dest_idx;      
	logic	  [`N_WAY-1:0][`CDB_BITS-1:0] cdb_rs_reg_idx;    
	//PR_PACKET       [`N_WAY-1:0]    pr_packet_out1;
	//PR_PACKET       [`N_WAY-1:0]    pr_packet_out2;
	//logic	  [`N_WAY-1:0] [`CDB_BITS-1:0]    pr_dest_tag;
	//logic	  [`N_WAY-1:0] [6:0]    issue_opcode;
	logic	 [$clog2(`N_RS):0]  rs_empty;
	logic [$clog2(`N_WAY)-1:0] issue_num;
	//logic [`N_WAY-1:0] issue_valid;
	RS_PACKET_ISSUE [`N_WAY-1:0]    rs_packet_issue;
	

 // Instantiate the Unit Under Test (UUT)

reservation_station rs0 (

                .clock(clock), 
                .reset(reset),
		.rs_packet_dispatch(rs_packet_dispatch),
	  	.ex_rs_dest_idx(ex_rs_dest_idx),
		.cdb_rs_reg_idx(cdb_rs_reg_idx),
		//.pr_packet_out1(pr_packet_out1),
		//.pr_packet_out2(pr_packet_out2),
		//.pr_dest_tag(pr_dest_tag),
		//.issue_opcode(issue_opcode),
		.rs_empty(rs_empty),
		.issue_num(issue_num),
		//.issue_valid(issue_valid)
		.rs_packet_issue(rs_packet_issue)
                  );

 initial begin

  // Initialize Inputs

	clock  = 1'b0;
	reset  = 1'b1;
	
	issue_num = 0;
	
	rs_packet_dispatch[0].busy = 0;
	rs_packet_dispatch[0].inst= 0;
	rs_packet_dispatch[0].dest_tag= 0;
	rs_packet_dispatch[0].source_tag_1= 0;
	rs_packet_dispatch[0].source_tag_1_plus= 0;
	rs_packet_dispatch[0].source_tag_2= 0;
	rs_packet_dispatch[0].source_tag_2_plus= 0;
	rs_packet_dispatch[0].valid= 0;
	rs_packet_dispatch[0].order_idx= 0;
  
	rs_packet_dispatch[1].busy = 0;
	rs_packet_dispatch[1].inst= 0;
	rs_packet_dispatch[1].dest_tag= 0;
	rs_packet_dispatch[1].source_tag_1= 0;
	rs_packet_dispatch[1].source_tag_1_plus= 0;
	rs_packet_dispatch[1].source_tag_2= 0;
	rs_packet_dispatch[1].source_tag_2_plus= 0;
	rs_packet_dispatch[1].valid= 0;
	rs_packet_dispatch[1].order_idx= 0;
  
	rs_packet_dispatch[2].busy = 0;
	rs_packet_dispatch[2].inst= 0;
	rs_packet_dispatch[2].dest_tag= 0;
	rs_packet_dispatch[2].source_tag_1= 0;
	rs_packet_dispatch[2].source_tag_1_plus= 0;
	rs_packet_dispatch[2].source_tag_2= 0;
	rs_packet_dispatch[2].source_tag_2_plus= 0;
	rs_packet_dispatch[2].valid= 0;
	rs_packet_dispatch[2].order_idx= 0;
  
	ex_rs_dest_idx[0] = 0;
	ex_rs_dest_idx[1] = 0;
	ex_rs_dest_idx[2] = 0;

	cdb_rs_reg_idx[0] = 0;
	cdb_rs_reg_idx[1] = 0;
	cdb_rs_reg_idx[2] = 0;



  // Wait 100 ns for global reset to finish

  #20;        

  // Add stimulus here


  reset  = 1'b1;

  #20;

  reset  = 1'b0;
	
	issue_num = 3;
		
	rs_packet_dispatch[0].busy = 1;
	rs_packet_dispatch[0].inst= 1;
	rs_packet_dispatch[0].dest_tag= 33;
	rs_packet_dispatch[0].source_tag_1= 1;
	rs_packet_dispatch[0].source_tag_1_plus= 1;
	rs_packet_dispatch[0].source_tag_2= 2;
	rs_packet_dispatch[0].source_tag_2_plus= 1;
	rs_packet_dispatch[0].valid= 1;
	rs_packet_dispatch[0].order_idx= 1;
  
	rs_packet_dispatch[1].busy = 1;
	rs_packet_dispatch[1].inst= 2;
	rs_packet_dispatch[1].dest_tag= 34;
	rs_packet_dispatch[1].source_tag_1= 4;
	rs_packet_dispatch[1].source_tag_1_plus= 1;
	rs_packet_dispatch[1].source_tag_2= 5;
	rs_packet_dispatch[1].source_tag_2_plus= 1;
	rs_packet_dispatch[1].valid= 1;
	rs_packet_dispatch[1].order_idx= 2;
  
	rs_packet_dispatch[2].busy = 1;
	rs_packet_dispatch[2].inst= 3;
	rs_packet_dispatch[2].dest_tag= 35;
	rs_packet_dispatch[2].source_tag_1= 7;
	rs_packet_dispatch[2].source_tag_1_plus= 1;
	rs_packet_dispatch[2].source_tag_2= 8;
	rs_packet_dispatch[2].source_tag_2_plus= 1;
	rs_packet_dispatch[2].valid= 1;
	rs_packet_dispatch[2].order_idx= 3;

  #20;
	rs_packet_dispatch[0].busy = 1;
	rs_packet_dispatch[0].inst= 1;
	rs_packet_dispatch[0].dest_tag= 36;
	rs_packet_dispatch[0].source_tag_1= 33;
	rs_packet_dispatch[0].source_tag_1_plus= 0;
	rs_packet_dispatch[0].source_tag_2= 1;
	rs_packet_dispatch[0].source_tag_2_plus= 1;
	rs_packet_dispatch[0].valid= 1;
	rs_packet_dispatch[0].order_idx= 4;
  
	rs_packet_dispatch[1].busy = 1;
	rs_packet_dispatch[1].inst= 2;
	rs_packet_dispatch[1].dest_tag= 37;
	rs_packet_dispatch[1].source_tag_1= 34;
	rs_packet_dispatch[1].source_tag_1_plus= 0;
	rs_packet_dispatch[1].source_tag_2= 2;
	rs_packet_dispatch[1].source_tag_2_plus= 1;
	rs_packet_dispatch[1].valid= 1;
	rs_packet_dispatch[1].order_idx= 5;
  
	rs_packet_dispatch[2].busy = 1;
	rs_packet_dispatch[2].inst= 3;
	rs_packet_dispatch[2].dest_tag= 38;
	rs_packet_dispatch[2].source_tag_1= 35;
	rs_packet_dispatch[2].source_tag_1_plus= 0;
	rs_packet_dispatch[2].source_tag_2= 4;
	rs_packet_dispatch[2].source_tag_2_plus= 1;
	rs_packet_dispatch[2].valid= 1;
	rs_packet_dispatch[2].order_idx= 6;
  
  #20;
	ex_rs_dest_idx[0] = 33;
	ex_rs_dest_idx[1] = 34;
	ex_rs_dest_idx[2] = 35;
	rs_packet_dispatch[0].busy = 1;
	rs_packet_dispatch[0].inst= 1;
	rs_packet_dispatch[0].dest_tag= 39;
	rs_packet_dispatch[0].source_tag_1= 13;
	rs_packet_dispatch[0].source_tag_1_plus= 1;
	rs_packet_dispatch[0].source_tag_2= 14;
	rs_packet_dispatch[0].source_tag_2_plus= 1;
	rs_packet_dispatch[0].valid= 1;
	rs_packet_dispatch[0].order_idx= 4;
  
	rs_packet_dispatch[1].busy = 1;
	rs_packet_dispatch[1].inst= 2;
	rs_packet_dispatch[1].dest_tag= 40;
	rs_packet_dispatch[1].source_tag_1= 39;
	rs_packet_dispatch[1].source_tag_1_plus= 0;
	rs_packet_dispatch[1].source_tag_2= 16;
	rs_packet_dispatch[1].source_tag_2_plus= 1;
	rs_packet_dispatch[1].valid= 1;
	rs_packet_dispatch[1].order_idx= 5;
  
	rs_packet_dispatch[2].busy = 1;
	rs_packet_dispatch[2].inst= 3;
	rs_packet_dispatch[2].dest_tag= 41;
	rs_packet_dispatch[2].source_tag_1= 40;
	rs_packet_dispatch[2].source_tag_1_plus= 0;
	rs_packet_dispatch[2].source_tag_2= 18;
	rs_packet_dispatch[2].source_tag_2_plus= 1;
	rs_packet_dispatch[2].valid= 1;
	rs_packet_dispatch[2].order_idx= 6;
  
  #20;
	cdb_rs_reg_idx[0] = 33;
	cdb_rs_reg_idx[1] = 34;
	cdb_rs_reg_idx[2] = 35;

	ex_rs_dest_idx[0] = 0;
	ex_rs_dest_idx[1] = 0;
	ex_rs_dest_idx[2] = 0;

	rs_packet_dispatch[0].busy = 1;
	rs_packet_dispatch[0].inst= 1;
	rs_packet_dispatch[0].dest_tag= 42;
	rs_packet_dispatch[0].source_tag_1= 20;
	rs_packet_dispatch[0].source_tag_1_plus= 1;
	rs_packet_dispatch[0].source_tag_2= 21;
	rs_packet_dispatch[0].source_tag_2_plus= 1;
	rs_packet_dispatch[0].valid= 1;
	rs_packet_dispatch[0].order_idx= 7;
  
	rs_packet_dispatch[1].busy = 1;
	rs_packet_dispatch[1].inst= 2;
	rs_packet_dispatch[1].dest_tag= 43;
	rs_packet_dispatch[1].source_tag_1= 23;
	rs_packet_dispatch[1].source_tag_1_plus= 1;
	rs_packet_dispatch[1].source_tag_2= 24;
	rs_packet_dispatch[1].source_tag_2_plus= 1;
	rs_packet_dispatch[1].valid= 1;
	rs_packet_dispatch[1].order_idx= 8;
  
	rs_packet_dispatch[2].busy = 1;
	rs_packet_dispatch[2].inst= 3;
	rs_packet_dispatch[2].dest_tag= 44;
	rs_packet_dispatch[2].source_tag_1= 26;
	rs_packet_dispatch[2].source_tag_1_plus= 1;
	rs_packet_dispatch[2].source_tag_2= 27;
	rs_packet_dispatch[2].source_tag_2_plus= 1;
	rs_packet_dispatch[2].valid= 1;
	rs_packet_dispatch[2].order_idx= 9;
  
  #20;

	cdb_rs_reg_idx[0] = 0;
	cdb_rs_reg_idx[1] = 0;
	cdb_rs_reg_idx[2] = 0;

	rs_packet_dispatch[0].busy = 1;
	rs_packet_dispatch[0].inst= 1;
	rs_packet_dispatch[0].dest_tag= 45;
	rs_packet_dispatch[0].source_tag_1= 1;
	rs_packet_dispatch[0].source_tag_1_plus= 1;
	rs_packet_dispatch[0].source_tag_2= 2;
	rs_packet_dispatch[0].source_tag_2_plus= 1;
	rs_packet_dispatch[0].valid= 1;
	rs_packet_dispatch[0].order_idx= 10;
  
	rs_packet_dispatch[1].busy = 1;
	rs_packet_dispatch[1].inst= 2;
	rs_packet_dispatch[1].dest_tag= 46;
	rs_packet_dispatch[1].source_tag_1= 4;
	rs_packet_dispatch[1].source_tag_1_plus= 1;
	rs_packet_dispatch[1].source_tag_2= 5;
	rs_packet_dispatch[1].source_tag_2_plus= 1;
	rs_packet_dispatch[1].valid= 1;
	rs_packet_dispatch[1].order_idx= 11;
  
	rs_packet_dispatch[2].busy = 1;
	rs_packet_dispatch[2].inst= 3;
	rs_packet_dispatch[2].dest_tag= 47;
	rs_packet_dispatch[2].source_tag_1= 7;
	rs_packet_dispatch[2].source_tag_1_plus= 1;
	rs_packet_dispatch[2].source_tag_2= 8;
	rs_packet_dispatch[2].source_tag_2_plus= 1;
	rs_packet_dispatch[2].valid= 1;
	rs_packet_dispatch[2].order_idx= 12;


  #20;

  $finish;

 end 

   always #10 clock = ~clock;    

endmodule



