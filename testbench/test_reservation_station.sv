`timescale 1ns/100ps

module testbench;

	logic           clock;
	logic           reset;
	RS_PACKET_DISPATCH [`N_WAY-1:0] rs_packet_dispatch;
	logic   [`N_WAY-1:0] [`CDB_BITS-1:0]  ex_rs_dest_idx;      
	logic   [`N_WAY-1:0][`CDB_BITS-1:0] cdb_rs_reg_idx;    
	logic [$clog2(`N_WAY)-1:0] issue_num;
    logic [$clog2(`N_WAY)-1:0] previous_issue_num;
	RS_PACKET_ISSUE [`N_WAY-1:0]    rs_packet_issue;
	logic [$clog2(`N_RS):0]  rs_empty;
    RS_PACKET   [`N_RS-1:0] rs_data;

    logic [$clog2(`N_RS):0] rs_empty_count;
    RS_PACKET   [`N_RS-1:0] rs_expected_data;
    RS_PACKET_ISSUE [`N_WAY-1:0]    rs_expected_packet_issue;
    logic [$clog2(`N_RS):0] count;

    // `ifndef TESTBENCH
    // `define TESTBENCH
    // `endif


    reservation_station dut(
	.clock(clock),
	.reset(reset),
	.rs_packet_dispatch(rs_packet_dispatch),
	.ex_rs_dest_idx(ex_rs_dest_idx),
	.cdb_rs_reg_idx(cdb_rs_reg_idx),
	.issue_num(issue_num),
	.rs_packet_issue(rs_packet_issue),
    .rs_data(rs_data),
	.rs_empty(rs_empty)
    );

    always #10 clock = ~clock;

    always_ff @ (negedge clock)
    begin
        previous_issue_num <= `SD issue_num;
    end

    task check_rs_table_data;
        `SD
        count = 0;
        if(reset)
            rs_expected_data = 0;
        else
        begin
            for(int i = 0; i < `N_RS; i++)
            begin
                for(int j = 0; j < `N_WAY; j++)
                begin
                    if(rs_expected_data[i].busy)
                    begin
                        if(rs_expected_data[i].source_tag_1 == cdb_rs_reg_idx[j])
                        begin
                            rs_expected_data[i].source_tag_1_plus = 1;
                        end
                        if(rs_expected_data[i].source_tag_2 == cdb_rs_reg_idx[j])
                        begin
                            rs_expected_data[i].source_tag_2_plus = 1;
                        end                    
                    end
                end
            end

            count = 0;
            for(int i = 0; i < `N_WAY; i++)
            begin
                for(int j = 0; j < `N_RS; j++)
                begin
                    if(rs_expected_data[j].busy && rs_expected_data[j].dest_tag == ex_rs_dest_idx[i])
                    begin
                        rs_expected_data[j].busy = 0;
                        count = count+1;
                        break;                   
                    end
                end
            end

            for(int i = 0; i < `N_RS; i++)
            begin
                if(rs_expected_data[i].busy)
                begin
                    rs_expected_data[i].order_idx = rs_expected_data[i].order_idx - count;
                end
            end


            for(int i = 0; i < `N_WAY; i++)
            begin
                for(int j = 0; j < `N_RS; j++)
                begin
                    if(!rs_expected_data[j].busy)
                    begin
                        rs_expected_data[j].busy = rs_packet_dispatch[i].busy;
                        rs_expected_data[j].opcode = rs_packet_dispatch[i].opcode;
                        rs_expected_data[j].dest_tag = rs_packet_dispatch[i].dest_tag;
                        rs_expected_data[j].source_tag_1 = rs_packet_dispatch[i].source_tag_1;
                        rs_expected_data[j].source_tag_1_plus = rs_packet_dispatch[i].source_tag_1_plus;
                        rs_expected_data[j].source_tag_2 = rs_packet_dispatch[i].source_tag_2;
                        rs_expected_data[j].source_tag_2_plus = rs_packet_dispatch[i].source_tag_2_plus;
                        rs_expected_data[j].order_idx = rs_packet_dispatch[i].order_idx;
                        rs_expected_data[j].issued = 0;
                        break;
                    end
                end
            end


            count = 0;
            for(int i = 1; i <= `N_RS; i++)
            begin
                for(int j = 0; j < `N_RS; j++)
                begin
                    if(rs_expected_data[j].order_idx == i)
                    begin
                        // This is the instruction which shall be examined for ready to issue. 
                        if(rs_expected_data[j].busy && rs_expected_data[j].source_tag_1_plus && rs_expected_data[j].source_tag_2_plus && count < previous_issue_num && (!rs_expected_data[j].issued))
                        begin
                            rs_expected_data[j].issued = 1;
                            count = count + 1;
                        end
                        break;
                    end
                end
            end

            count = 0;
            $display("The number of instructions issued in the previous cycle are: %h", previous_issue_num);
            for(int i = 1; i <= `N_RS; i++)
            begin
                for(int j = 0; j < `N_RS; j++)
                begin
                    if(rs_expected_data[j].order_idx == i)
                    begin
                        // This is the instruction which shall be examined for ready to issue. 
                        if(rs_expected_data[j].busy && rs_expected_data[j].source_tag_1_plus && rs_expected_data[j].source_tag_2_plus && count < issue_num && (!rs_expected_data[j].issued))
                        begin
                            //if(!((rs_packet_issue[count].valid == 1) && (rs_packet_issue[count].source_tag_1 == rs_expected_data[j].source_tag_1) && (rs_packet_issue[count].source_tag_2 == rs_expected_data[j].source_tag_2) && (rs_packet_issue[count].dest_tag == rs_expected_data[j].dest_tag) && (rs_packet_issue[count].opcode == rs_expected_data[j].opcode)))
                            if(!((rs_packet_issue[count].source_tag_1 == rs_expected_data[j].source_tag_1) && (rs_packet_issue[count].source_tag_2 == rs_expected_data[j].source_tag_2) && (rs_packet_issue[count].dest_tag == rs_expected_data[j].dest_tag) && (rs_packet_issue[count].opcode == rs_expected_data[j].opcode)))
                            begin
                                $display("The issue packet row number %h is wrong.", count);
                                $display("%d", i);
                                $display("%d", j);
                                $display("|%b    |%02h   |%02h    |%02h   |", 
				                rs_packet_issue[count].valid, 
				                rs_packet_issue[count].source_tag_1, 
				                rs_packet_issue[count].source_tag_2, 
				                rs_packet_issue[count].dest_tag);
                                $display("|%02h   |%02h    |%02h   |", 
				                rs_expected_data[j].source_tag_1, 
				                rs_expected_data[j].source_tag_2, 
				                rs_expected_data[j].dest_tag);


                                $display("----------------------------------------------------------------------------------");
                                $display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
                                for(integer i = 0; i < `N_RS; i++)
                                begin
                                    $display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
                                    rs_expected_data[i].busy, 
                                    rs_expected_data[i].opcode, 
                                    rs_expected_data[i].dest_tag, 
                                    rs_expected_data[i].source_tag_1, 
                                    rs_expected_data[i].source_tag_1_plus, 
                                    rs_expected_data[i].source_tag_2, 
                                    rs_expected_data[i].source_tag_2_plus,
                                    rs_expected_data[i].order_idx,
                                    rs_empty,
                                    rs_expected_data[i].issued);
                                end

                                
                                $display("--------------------------------------------------------------------------------");

                                $display("----------------------------------------------------------------------------------");
                                $display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
                                for(integer i = 0; i < `N_RS; i++)
                                begin
                                    $display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
                                    rs_data[i].busy, 
                                    rs_data[i].opcode, 
                                    rs_data[i].dest_tag, 
                                    rs_data[i].source_tag_1, 
                                    rs_data[i].source_tag_1_plus, 
                                    rs_data[i].source_tag_2, 
                                    rs_data[i].source_tag_2_plus,
                                    rs_data[i].order_idx,
                                    rs_empty,
                                    rs_data[i].issued);
                                end

                                $display("--------------------------------------------------------------------------------");
                                
                                $display("@@@Failed");

                                $finish;
                            end
                            count = count + 1;
                        end
                        break;
                    end
                end
            end




        end

        if(rs_expected_data!=rs_data)
        begin
            $display("The reservation station data is inaccurate.");

            $display("----------------------------------------------------------------------------------");
			$display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
			for(integer i = 0; i < `N_RS; i++)
			begin
				$display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
				rs_expected_data[i].busy, 
				rs_expected_data[i].opcode, 
				rs_expected_data[i].dest_tag, 
				rs_expected_data[i].source_tag_1, 
				rs_expected_data[i].source_tag_1_plus, 
				rs_expected_data[i].source_tag_2, 
				rs_expected_data[i].source_tag_2_plus,
				rs_expected_data[i].order_idx,
				rs_empty,
                rs_expected_data[i].issued);
			end

            
			$display("--------------------------------------------------------------------------------");

            $display("----------------------------------------------------------------------------------");
			$display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
			for(integer i = 0; i < `N_RS; i++)
			begin
				$display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
				rs_data[i].busy, 
				rs_data[i].opcode, 
				rs_data[i].dest_tag, 
				rs_data[i].source_tag_1, 
				rs_data[i].source_tag_1_plus, 
				rs_data[i].source_tag_2, 
				rs_data[i].source_tag_2_plus,
				rs_data[i].order_idx,
				rs_empty,
                rs_data[i].issued);
			end

			$display("--------------------------------------------------------------------------------");

            $display("@@@Failed");
            
            $finish;
        end

    endtask


    task check_rs_empty;
        rs_empty_count = 0;
        for(int i = 0 ; i < `N_RS; i++)
        begin
           if(!rs_expected_data[i].busy) rs_empty_count = rs_empty_count + 1;
        end
        if(rs_empty_count != rs_empty)
        begin
            $display("The number of empty rows in the reservation station has not been computed accurately.");

            $display("-----------------------------------------------------------------------------------");
			$display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
			for(integer i = 0; i < `N_RS; i++)
			begin
				$display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
				rs_expected_data[i].busy, 
				rs_expected_data[i].opcode, 
				rs_expected_data[i].dest_tag, 
				rs_expected_data[i].source_tag_1, 
				rs_expected_data[i].source_tag_1_plus, 
				rs_expected_data[i].source_tag_2, 
				rs_expected_data[i].source_tag_2_plus,
				rs_expected_data[i].order_idx,
				rs_empty,
                rs_expected_data[i].issued);
			end


			$display("-----------------------------------------------------------------------------------");

            $display("-----------------------------------------------------------------------------------");
			$display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
			for(integer i = 0; i < `N_RS; i++)
			begin
				$display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
				rs_data[i].busy, 
				rs_data[i].opcode, 
				rs_data[i].dest_tag, 
				rs_data[i].source_tag_1, 
				rs_data[i].source_tag_1_plus, 
				rs_data[i].source_tag_2, 
				rs_data[i].source_tag_2_plus,
				rs_data[i].order_idx,
				rs_empty,
                rs_data[i].issued);
			end

			$display("-----------------------------------------------------------------------------------");

            $display("Output of rs_empty from reservation station: %h", rs_empty);

            $display("@@@Failed");
            $finish;
        end
    endtask

    task check_all;
        check_rs_table_data();
        check_rs_empty();

        $display("----------------------------------------------------------------------------------");
			$display("|BUSY |INST     |DTAG |STAG1 |STAG1+ |STAG2 |STAG2+ |ORDER_INDEX| RS_EMPTY |ISSUED|");
			for(integer i = 0; i < `N_RS; i++)
			begin
				$display("|%b    |%08h |%02h   |%02h    |%b      |%02H    |%b      |%02H         | %01h        |%b     |", 
				rs_data[i].busy, 
				rs_data[i].opcode, 
				rs_data[i].dest_tag, 
				rs_data[i].source_tag_1, 
				rs_data[i].source_tag_1_plus, 
				rs_data[i].source_tag_2, 
				rs_data[i].source_tag_2_plus,
				rs_data[i].order_idx,
				rs_empty,
                rs_data[i].issued);
			end

			$display("----------------------------------------------------------------------------------");

            $display("--------------------------------------------------------------------------");
			$display("|VALID|OPCODE|T |T1|T2|");
			for(integer i = 0; i < `N_WAY; i++)
			begin
				$display("|%b    |%02h    |%02h|%02h|%02h|", 
                rs_packet_issue[i].valid,
				rs_packet_issue[i].opcode,
				rs_packet_issue[i].dest_tag,
				rs_packet_issue[i].source_tag_1,
				rs_packet_issue[i].source_tag_2);
			end

			$display("--------------------------------------------------------------------------");
    endtask


    
    initial begin
        clock = 1'b0;
        reset = 1'b1;

        issue_num = 0;

        rs_expected_data = 0;

        rs_packet_dispatch[0].busy = 0;
        rs_packet_dispatch[0].opcode= 0;
        rs_packet_dispatch[0].dest_tag= 0;
        rs_packet_dispatch[0].source_tag_1= 0;
        rs_packet_dispatch[0].source_tag_1_plus= 0;
        rs_packet_dispatch[0].source_tag_2= 0;
        rs_packet_dispatch[0].source_tag_2_plus= 0;
        rs_packet_dispatch[0].valid= 0;
        rs_packet_dispatch[0].order_idx= 0;
    
        rs_packet_dispatch[1].busy = 0;
        rs_packet_dispatch[1].opcode= 0;
        rs_packet_dispatch[1].dest_tag= 0;
        rs_packet_dispatch[1].source_tag_1= 0;
        rs_packet_dispatch[1].source_tag_1_plus= 0;
        rs_packet_dispatch[1].source_tag_2= 0;
        rs_packet_dispatch[1].source_tag_2_plus= 0;
        rs_packet_dispatch[1].valid= 0;
        rs_packet_dispatch[1].order_idx= 0;
    
        rs_packet_dispatch[2].busy = 0;
        rs_packet_dispatch[2].opcode= 0;
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

        @(negedge clock);
        @(negedge clock);

        reset = 1'b0;

        issue_num = 3;

        rs_packet_dispatch[0].busy = 1;
        rs_packet_dispatch[0].opcode= $random%128;
        rs_packet_dispatch[0].dest_tag= 32;
        rs_packet_dispatch[0].source_tag_1= 1;
        rs_packet_dispatch[0].source_tag_1_plus= 1;
        rs_packet_dispatch[0].source_tag_2= 2;
        rs_packet_dispatch[0].source_tag_2_plus= 1;
        rs_packet_dispatch[0].valid= 1;
        rs_packet_dispatch[0].order_idx= 1;
    
        rs_packet_dispatch[1].busy = 1;
        rs_packet_dispatch[1].opcode= $random%128;
        rs_packet_dispatch[1].dest_tag= 33;
        rs_packet_dispatch[1].source_tag_1= 4;
        rs_packet_dispatch[1].source_tag_1_plus= 1;
        rs_packet_dispatch[1].source_tag_2= 5;
        rs_packet_dispatch[1].source_tag_2_plus= 1;
        rs_packet_dispatch[1].valid= 1;
        rs_packet_dispatch[1].order_idx= 2;
    
        rs_packet_dispatch[2].busy = 1;
        rs_packet_dispatch[2].opcode= $random%128;
        rs_packet_dispatch[2].dest_tag= 34;
        rs_packet_dispatch[2].source_tag_1= 7;
        rs_packet_dispatch[2].source_tag_1_plus= 1;
        rs_packet_dispatch[2].source_tag_2= 8;
        rs_packet_dispatch[2].source_tag_2_plus= 1;
        rs_packet_dispatch[2].valid= 1;
        rs_packet_dispatch[2].order_idx= 3;
    
        ex_rs_dest_idx[0] = 0;
        ex_rs_dest_idx[1] = 0;
        ex_rs_dest_idx[2] = 0;
        cdb_rs_reg_idx[0] = 0;
        cdb_rs_reg_idx[1] = 0;
        cdb_rs_reg_idx[2] = 0;


        @(negedge clock);
        check_all();
        
        `SD 
        // Send the same instructions once again.

        issue_num = 2;
        rs_packet_dispatch[0].dest_tag= 35;
        rs_packet_dispatch[1].dest_tag= 36;
        rs_packet_dispatch[2].dest_tag= 37;
        rs_packet_dispatch[0].order_idx= 4;
        rs_packet_dispatch[1].order_idx= 5;
        rs_packet_dispatch[2].order_idx= 6;


        @(negedge clock);
        check_all();

        `SD 
        issue_num = 1;
        rs_packet_dispatch[0].dest_tag= 38;
        rs_packet_dispatch[1].dest_tag= 39;
        rs_packet_dispatch[2].dest_tag= 40;
        rs_packet_dispatch[0].order_idx= 6;
        rs_packet_dispatch[1].order_idx= 7;
        rs_packet_dispatch[2].order_idx= 8;
        ex_rs_dest_idx[0] = 32; 
        // change the dispatch signals here

        @(negedge clock);
        check_all();

        `SD
        issue_num = 0;
        rs_packet_dispatch[0].dest_tag= 41;
        rs_packet_dispatch[1].dest_tag= 42;
        rs_packet_dispatch[2].dest_tag= 43;
        rs_packet_dispatch[0].order_idx= 9;
        rs_packet_dispatch[1].order_idx= 10;
        rs_packet_dispatch[2].order_idx= 11;

        // change the dispatch signals here

        @(negedge clock);
        check_all();

        `SD

        issue_num = 3;
        rs_packet_dispatch[0].dest_tag= 44;
        rs_packet_dispatch[1].dest_tag= 45;
        rs_packet_dispatch[2].dest_tag= 46;
        rs_packet_dispatch[0].order_idx= 12;
        rs_packet_dispatch[1].order_idx= 13;
        rs_packet_dispatch[2].order_idx= 14;

        // // change the dispatch signals here

        @(negedge clock);
        check_all();

        @(negedge clock);
        check_all();


        $display("@@@Passed");
        $finish;

        


    end



endmodule
