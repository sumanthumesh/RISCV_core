`timescale 1ns/100ps


module test_free_list;

 // Inputs
 logic clock;
 logic [`CDB_BITS-1 : 0] data_in;
 logic rd;
 logic wr;
 logic reset;
 // Outputs
 logic [`CDB_BITS-1 : 0] data_out;
 logic empty;
// logic full;

 // Instantiate the Unit Under Test (UUT)

 free_list free_list0 (

                  .clock(clock), 

                  .data_in(data_in), 

                  .rd(rd), 

                  .wr(wr), 

                  .data_out(data_out), 

                  .reset(reset), 

                  .empty(empty) 

                  //.full(full)

                  );

 initial begin

  // Initialize Inputs

  clock  = 1'b0;

  data_in  = 7'h0;

  rd  = 1'b0;

  wr  = 1'b0;


  reset  = 1'b1;

  // Wait 100 ns for global reset to finish

  #100;        

  // Add stimulus here


  reset  = 1'b1;

  #20;

  reset  = 1'b0;

  rd  = 1'b1;

  #100;

  rd  = 1'b0;
  wr = 1'b1;

  data_in  = 7'h12;

  #20;

  data_in  = 7'h1;

  #20;

  data_in  = 7'h2;

  #20;

  data_in  = 7'h3;

  #20;

  data_in  = 7'h4;

  #20;

  rd  = 1'b1;
  wr = 1'b0;

  #1350;

  wr = 1'b1;
  rd  = 1'b0;

  data_in  = 7'h5;

  #20;

  data_in  = 7'h6;

  #20;
  rd = 1'b1;
  data_in  = 7'h7;

  #20;
  rd = 1'b0;
  data_in  = 7'h8;

  #20;
  
  wr = 1'b0;
  rd  = 1'b1;

  #100
  wr = 1'b1;
  rd  = 1'b1;

  data_in  = 7'h9;
  #40;

  $finish;

 end 

   always #10 clock = ~clock;    

endmodule



