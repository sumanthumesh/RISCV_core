module dcache(
    input clock,
    input reset,
    input flush,
    input LOAD_PACKET_RET [`N_RD_PORTS-1:0] load_packet_in,
    output LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out,
    input STORE_PACKET_RET [`N_WR_PORTS-1:0] store_packet_in,
    output STORE_PACKET_EX_STAGE [`N_WR_PORTS-1:0] store_packet_out,
    output VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_cache_in3,
    output VICTIM_CACHE_ROW [`N_WR_PORTS-1:0] store_victim_cache_in3,
    input VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_cache_out,
    input VICTIM_CACHE_ROW [`N_WR_PORTS-1:0] store_victim_cache_out,
    output logic [`MSHR_SIZE-1:0][`XLEN-1:0] victim_cache_hit_in,
    output logic [`MSHR_SIZE-1:0] victim_cache_hit_valid_in,
    input logic [`MSHR_SIZE-1:0] victim_cache_hit_valid_out,
    input logic [`MSHR_SIZE-1:0][63:0] victim_cache_hit_out,
    output logic victim_cache_full_evict_next2,
    output logic victim_cache_partial_evict_next,
    output logic [`XLEN-1:0] dcache2mem_addr,
    output logic [1:0] dcache2mem_command,
    output logic [63:0] dcache2mem_data,
    input  logic [3:0] mem2dcache_response,
	input logic [63:0] mem2dcache_data,
	input  logic [3:0] mem2dcache_tag,
    output logic all_mshr_requests_processed_reg,
	output MSHR_ROW [`N_WR_PORTS-1:0] store_victim_mshr_in,
    output logic flush_victim
);

MSHR_ROW [`MSHR_SIZE-1:0] mshr;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next2;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next3;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next4;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next5;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next6;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next7;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next8;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next9;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next10;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next11;
MSHR_ROW [`MSHR_SIZE-1:0] mshr_next12;
logic [$clog2(`MSHR_SIZE):0] mshr_idx;
logic [$clog2(`MSHR_SIZE):0] mshr_idx_next;
logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx;
logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx1;
logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx2;
logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx3;
logic [$clog2(`N_WR_PORTS):0] store_packet_out_idx;
logic [$clog2(`N_WR_PORTS):0] store_packet_out_idx1;
logic [$clog2(`N_WR_PORTS):0] store_packet_out_idx2;
logic [$clog2(`N_WR_PORTS):0] store_packet_out_idx3;
logic [$clog2(`N_RD_PORTS):0] load_victim_cache_in_idx;
VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_cache_in1;
logic [$clog2(`N_WR_PORTS):0] store_victim_cache_in_idx;
VICTIM_CACHE_ROW [`N_WR_PORTS-1:0] store_victim_cache_in1;
VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_cache_in2;
logic [$clog2(`N_RD_PORTS):0] load_victim_cache_in_idx1;
VICTIM_CACHE_ROW [`N_WR_PORTS-1:0] store_victim_cache_in2;
logic [$clog2(`N_WR_PORTS):0] store_victim_cache_in_idx1;
LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next;
STORE_PACKET_EX_STAGE [`N_WR_PORTS-1:0] store_packet_out_next;
LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next1;
STORE_PACKET_EX_STAGE [`N_WR_PORTS-1:0] store_packet_out_next1;
LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next2;
STORE_PACKET_EX_STAGE [`N_WR_PORTS-1:0] store_packet_out_next2;
LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next3;
STORE_PACKET_EX_STAGE [`N_WR_PORTS-1:0] store_packet_out_next3;
LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next4;
STORE_PACKET_EX_STAGE [`N_WR_PORTS-1:0] store_packet_out_next4;
logic victim_cache_full_evict;
logic victim_cache_partial_evict;
DCACHE_ROW [`CACHE_LINES-1:0] dcache;
DCACHE_ROW [`CACHE_LINES-1:0] dcache_next;
DCACHE_ROW [`CACHE_LINES-1:0] dcache_next2;
DCACHE_ROW [`CACHE_LINES-1:0] dcache_next3;
DCACHE_ROW [`CACHE_LINES-1:0] dcache_next4;
DCACHE_ROW [`CACHE_LINES-1:0] dcache_next5;
logic [`CACHE_LINE_BITS-1:0] line_idx;
logic [`CACHE_LINE_BITS-1:0] line_idx1;
logic [`CACHE_LINE_BITS:0] line_idx2;
logic load_l1_hit_next;
logic load_l1_hit;
logic store_l1_hit_next;
logic store_l1_hit;
logic [$clog2(`MSHR_SIZE):0] order_idx;
logic [$clog2(`MSHR_SIZE):0] order_idx_next;
logic [$clog2(`MSHR_SIZE):0] order_idx_next2;
logic [$clog2(`MSHR_SIZE):0] order_idx_next3;
logic [$clog2(`MSHR_SIZE):0] order_idx_next4;
logic [$clog2(`MSHR_SIZE):0] order_idx_next5;
logic [$clog2(`MSHR_SIZE):0] order_idx_next6;
logic [$clog2(`MSHR_SIZE):0] load_mshr_invalidated_order_idx;
logic [$clog2(`MSHR_SIZE):0] store_mshr_invalidated_order_idx;
logic [$clog2(`MSHR_SIZE):0] load_mshr_invalidated_order_idx1;
logic [$clog2(`MSHR_SIZE):0] store_mshr_invalidated_order_idx1;
logic [$clog2(`MSHR_SIZE):0] load_mshr_invalidated_order_idx2;
logic [$clog2(`MSHR_SIZE):0] store_mshr_invalidated_order_idx2;
logic [3:0] latched_mem2dcache_response,latched_mem2dcache_tag ;
logic [63:0] latched_mem2dcache_data;
logic load_tmp;
logic store_tmp;
logic tmp1,tmp2,tmp3,tmp4,tmp5,tmp6,tmp7,tmp8,tmp9,tmp10;
logic all_mshr_requests_processed;
    logic tmp_check;
logic victim_cache_full_evict_next;
logic load_forward;

always_comb
begin   
    //if(store_packet_in[0].address == 32'hfc0)
    //    $display("%t", $time);
    order_idx_next = order_idx;
    mshr_next = mshr;
    dcache_next = dcache;

    // The next combinational block updates the expected tag so that the MSHR entry knows that
    // its request has been processed by the memory and that the data is ready. 


    if(mshr[mshr_idx].valid && mshr[mshr_idx].dispatched && !mshr[mshr_idx].expected_tag_assigned)
    begin
        if(mshr[mshr_idx].load||(mshr[mshr_idx].store && mshr[mshr_idx].size!=DOUBLE))
        begin
            mshr_next[mshr_idx].expected_tag = latched_mem2dcache_response;
            mshr_next[mshr_idx].expected_tag_assigned = 1;
        end
        else if(mshr[mshr_idx].store && mshr[mshr_idx].size==DOUBLE && latched_mem2dcache_response)
        begin
            mshr_next[mshr_idx].ready = 1;
        end
    end


    // Both the store and the load entries are now added here. The assumption here is that
    // the new entries will not be from the same cache line, as two lines evicted from the 
    // victim cache would never have the same line_idx. 

    // First, the stores.
	tmp_check = 0;
    for (int i=0; i<`MSHR_SIZE; i++) begin
    	if(victim_cache_full_evict && mshr_next[i].valid && store_victim_cache_out[0].valid && store_victim_cache_out[0].dirty && (store_victim_cache_out[0].line_idx == mshr_next[i].address[`CACHE_LINE_BITS+2:3]) && (store_victim_cache_out[0].tag==mshr_next[i].address[`XLEN-1:`CACHE_LINE_BITS+3]) && mshr_next[i].victim_hit && !tmp_check ) begin
		tmp_check=1;
    	    //dcache_next[store_victim_cache_out[0].line_idx].tag = store_victim_cache_out[0].tag;
    	    //dcache_next[store_victim_cache_out[0].line_idx].valid = 1;
		if (mshr_next[i].store) begin
           	 case(mshr_next[i].size)
           	     BYTE:
           	     begin
           	         casez(mshr_next[i].address[2:0])
           	             3'd0: mshr_next[i].data = {store_victim_cache_out[i][63:8], mshr_next[i].store_data[7:0]};
           	             3'd1: mshr_next[i].data = {store_victim_cache_out[i][63:16], mshr_next[i].store_data[7:0], store_victim_cache_out[i][7:0]};
           	             3'd2: mshr_next[i].data = {store_victim_cache_out[i][63:24], mshr_next[i].store_data[7:0], store_victim_cache_out[i][15:8]};
           	             3'd3: mshr_next[i].data = {store_victim_cache_out[i][63:32], mshr_next[i].store_data[7:0], store_victim_cache_out[i][23:16]};
           	             3'd4: mshr_next[i].data = {store_victim_cache_out[i][63:40], mshr_next[i].store_data[7:0], store_victim_cache_out[i][31:24]};
           	             3'd5: mshr_next[i].data = {store_victim_cache_out[i][63:48], mshr_next[i].store_data[7:0], store_victim_cache_out[i][39:32]};
           	             3'd6: mshr_next[i].data = {store_victim_cache_out[i][63:56], mshr_next[i].store_data[7:0], store_victim_cache_out[i][47:40]};
           	             3'd7: mshr_next[i].data = {mshr_next[i].store_data[7:0], store_victim_cache_out[i][55:48]};
           	         endcase
           	     end
           	     HALF:
           	     begin
           	         casez(mshr_next[i].address[2:1])
           	             2'd0: mshr_next[i].data = {store_victim_cache_out[i][63:16], mshr_next[i].store_data[15:0]};
           	             2'd1: mshr_next[i].data = {store_victim_cache_out[i][63:32], mshr_next[i].store_data[15:0], store_victim_cache_out[i][15:0]};
           	             2'd2: mshr_next[i].data = {store_victim_cache_out[i][63:48], mshr_next[i].store_data[15:0], store_victim_cache_out[i][31:16]};
           	             2'd3: mshr_next[i].data = {mshr_next[i].store_data[15:0], store_victim_cache_out[i][47:32]};
           	         endcase
           	     end
           	     WORD:
           	     begin
           	         casez(mshr_next[i].address[2])
           	             1'd0: mshr_next[i].data = {store_victim_cache_out[i][63:32], mshr_next[i].store_data[31:0]};
           	             1'd1: mshr_next[i].data = {mshr_next[i].store_data[31:0], store_victim_cache_out[i][31:0]};
           	         endcase
           	     end
           	 endcase
            end
    	end	
    end
   if(victim_cache_full_evict && store_victim_cache_out[0].valid && store_victim_cache_out[0].dirty && !tmp_check)
    begin
	tmp3 = 0;
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next[i].valid && !tmp3)
            begin
                mshr_next[i].load = 0;
                mshr_next[i].store = 1;
                mshr_next[i].dispatched = 1'b0;
                mshr_next[i].valid = 1'b1;
                mshr_next[i].ready = 0;
                mshr_next[i].data = store_victim_cache_out[0].data;
                mshr_next[i].address = {store_victim_cache_out[0].tag, store_victim_cache_out[0].line_idx, 3'b0};
                mshr_next[i].expected_tag = 0;
                mshr_next[i].expected_tag_assigned = 0;
                mshr_next[i].dest_tag = 0;
                mshr_next[i].order_idx = order_idx_next;
                mshr_next[i].store_data = store_victim_cache_out[0].data;
                order_idx_next = order_idx_next+1;
                mshr_next[i].victim_hit = 0;
                mshr_next[i].l1_hit = 0;
                mshr_next[i].size = DOUBLE;
                mshr_next[i].store_data = 0;
                mshr_next[i].sign = 0;
                //break;
                tmp3 =1;
            end
        end
    end
    else if(victim_cache_partial_evict && store_victim_cache_out[0].valid && !tmp_check)
    begin
        dcache_next[store_victim_cache_out[0].line_idx].data = store_victim_cache_out[0].data;
        dcache_next[store_victim_cache_out[0].line_idx].tag = store_victim_cache_out[0].tag;
        dcache_next[store_victim_cache_out[0].line_idx].valid = 1;
	dcache_next[store_victim_cache_out[0].line_idx].dirty = store_victim_cache_out[0].dirty;
    end




    // Then, the loads.
    if(victim_cache_full_evict && load_victim_cache_out[0].valid && load_victim_cache_out[0].dirty)
    begin
	tmp4 = 0;
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next[i].valid && !tmp4)
            begin
                mshr_next[i].load = 0;
                mshr_next[i].store = 1;
                mshr_next[i].dispatched = 1'b0;
                mshr_next[i].valid = 1'b1;
                mshr_next[i].ready = 0;
                mshr_next[i].data = load_victim_cache_out[0].data;
                mshr_next[i].address = {load_victim_cache_out[0].tag, load_victim_cache_out[0].line_idx, 3'b0};
                mshr_next[i].expected_tag = 0;
                mshr_next[i].expected_tag_assigned = 0;
                mshr_next[i].dest_tag = 0;
                mshr_next[i].order_idx = order_idx_next;
                mshr_next[i].store_data = load_victim_cache_out[0].data;
                order_idx_next = order_idx_next+1;
                mshr_next[i].victim_hit = 0;
                mshr_next[i].l1_hit = 0;
                mshr_next[i].size = DOUBLE;
                mshr_next[i].store_data = 0;
                mshr_next[i].sign = 0;
                //break;
                tmp4 =1;
            end
        end
    end
    else if(victim_cache_partial_evict && load_victim_cache_out[0].valid)
    begin
        dcache_next[load_victim_cache_out[0].line_idx].data = load_victim_cache_out[0].data;
        dcache_next[load_victim_cache_out[0].line_idx].dirty = load_victim_cache_out[0].dirty;
        dcache_next[load_victim_cache_out[0].line_idx].tag = load_victim_cache_out[0].tag;
        dcache_next[load_victim_cache_out[0].line_idx].valid = 1;
    end
end


// The oldest memory returned data is put onto the loaded output packet. 
always_comb
begin
    mshr_next2 = mshr_next;
    dcache_next2 = dcache_next;
    load_victim_cache_in_idx = 0;
    store_victim_cache_in_idx = 0;
    victim_cache_full_evict_next = 0;
    line_idx = 0;
    order_idx_next2 = order_idx_next;
    load_mshr_invalidated_order_idx = `MSHR_SIZE;
    store_mshr_invalidated_order_idx = `MSHR_SIZE;
    load_packet_out_idx = 0;
    store_packet_out_idx = 0;
    load_tmp = 1;
    store_tmp = 1;

    // Store logic
    for(int i = 1; i <= `MSHR_SIZE; i++)
    begin
        for(int j = 0; j < `MSHR_SIZE; j++)
        begin
            if(store_tmp && mshr_next[j].valid && mshr_next[j].dispatched && mshr_next[j].store && mshr_next[j].order_idx == i)
            begin
                if(mshr_next[j].size!=DOUBLE && !mshr_next[j].ready && mshr_next[j].expected_tag_assigned && mshr_next[j].expected_tag == mem2dcache_tag)
                begin
                    mshr_next2[j].ready = 1;
                    mshr_next2[j].data = mem2dcache_data;
                    line_idx = mshr_next2[j].address[`CACHE_LINE_BITS+3-1:3];
                    store_tmp = 0;
                    store_packet_out_next[store_packet_out_idx].store_pos = mshr_next2[j].store_pos;
                    store_packet_out_next[store_packet_out_idx].valid = 1;
                    store_packet_out_idx = store_packet_out_idx + 1;

                    if(dcache_next[line_idx].valid)
                    begin
                        store_victim_cache_in1[store_victim_cache_in_idx].valid = dcache_next[line_idx].valid;
                        store_victim_cache_in1[store_victim_cache_in_idx].tag = dcache_next[line_idx].tag;
                        store_victim_cache_in1[store_victim_cache_in_idx].data = dcache_next[line_idx].data;
                        store_victim_cache_in1[store_victim_cache_in_idx].dirty = dcache_next[line_idx].dirty;
                        store_victim_cache_in1[store_victim_cache_in_idx].line_idx = line_idx;
                        store_victim_cache_in_idx = store_victim_cache_in_idx + 1;
                        victim_cache_full_evict_next = 1;
                    end
                    dcache_next2[line_idx].tag = mshr_next2[j].address[`XLEN-1:`CACHE_LINE_BITS+3];
                    dcache_next2[line_idx].valid = 1;
                    dcache_next2[line_idx].dirty = 1;
                    
                    casez(mshr_next2[j].size)
                        BYTE:
                        begin
                            casez(mshr_next2[j].address[2:0])
                                3'd0: dcache_next2[line_idx].data = {mshr_next2[j].data[63:8], mshr_next2[j].store_data[7:0]};
                                3'd1: dcache_next2[line_idx].data = {mshr_next2[j].data[63:16], mshr_next2[j].store_data[7:0], mshr_next2[j].data[7:0]};
                                3'd2: dcache_next2[line_idx].data = {mshr_next2[j].data[63:24], mshr_next2[j].store_data[7:0], mshr_next2[j].data[15:0]};
                                3'd3: dcache_next2[line_idx].data = {mshr_next2[j].data[63:32], mshr_next2[j].store_data[7:0], mshr_next2[j].data[23:0]};
                                3'd4: dcache_next2[line_idx].data = {mshr_next2[j].data[63:40], mshr_next2[j].store_data[7:0], mshr_next2[j].data[31:0]};
                                3'd5: dcache_next2[line_idx].data = {mshr_next2[j].data[63:48], mshr_next2[j].store_data[7:0], mshr_next2[j].data[39:0]};
                                3'd6: dcache_next2[line_idx].data = {mshr_next2[j].data[63:56], mshr_next2[j].store_data[7:0], mshr_next2[j].data[47:0]};
                                3'd7: dcache_next2[line_idx].data = {mshr_next2[j].store_data[7:0], mshr_next2[j].data[55:0]};
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next2[j].address[2:1])
                                2'd0: dcache_next2[line_idx].data = {mshr_next2[j].data[63:16], mshr_next2[j].store_data[15:0]};
                                2'd1: dcache_next2[line_idx].data = {mshr_next2[j].data[63:32], mshr_next2[j].store_data[15:0], mshr_next2[j].data[15:0]};
                                2'd2: dcache_next2[line_idx].data = {mshr_next2[j].data[63:48], mshr_next2[j].store_data[15:0], mshr_next2[j].data[31:0]};
                                2'd3: dcache_next2[line_idx].data = {mshr_next2[j].store_data[15:0], mshr_next2[j].data[47:0]};
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next2[j].address[2])
                                1'd0: dcache_next2[line_idx].data = {mshr_next2[j].data[63:32], mshr_next2[j].store_data[31:0]};
                                1'd1: dcache_next2[line_idx].data = {mshr_next2[j].store_data[31:0], mshr_next2[j].data[31:0]};
                            endcase
                        end
                    endcase
                    mshr_next2[j].valid = 0;
                    order_idx_next2 = order_idx_next2 - 1;
                    store_mshr_invalidated_order_idx = i;
                end
                else if(mshr_next[j].size==DOUBLE && mshr_next[j].ready)
                begin
                    store_tmp = 0;
                    store_packet_out_next[store_packet_out_idx].store_pos = mshr_next2[j].store_pos;
                    store_packet_out_next[store_packet_out_idx].valid = 1;
                    store_packet_out_idx = store_packet_out_idx + 1;
                    mshr_next2[j].valid = 0;
                    order_idx_next2 = order_idx_next2 - 1;
                    store_mshr_invalidated_order_idx = i;
                end
                
            end
        end
    end



    // Load logic
    for(int i = 1; i <= `MSHR_SIZE; i++)
    begin
        for(int j = 0; j < `MSHR_SIZE; j++)
        begin
            if(load_tmp && mshr_next2[j].valid && mshr_next2[j].dispatched && !mshr_next2[j].ready && mshr_next2[j].load && mshr_next2[j].order_idx == i)
            begin
                if(mshr_next2[j].expected_tag_assigned && mshr_next2[j].expected_tag == mem2dcache_tag)
                begin
                    mshr_next2[j].ready = 1;
                    mshr_next2[j].data =mem2dcache_data;
                    line_idx = mshr_next2[j].address[`CACHE_LINE_BITS+3-1:3];
                    load_tmp = 0;
                    if(dcache_next2[line_idx].valid)
                    begin
                        load_victim_cache_in1[load_victim_cache_in_idx].valid = dcache_next2[line_idx].valid;
                        load_victim_cache_in1[load_victim_cache_in_idx].tag = dcache_next2[line_idx].tag;
                        load_victim_cache_in1[load_victim_cache_in_idx].data = dcache_next2[line_idx].data;
                        load_victim_cache_in1[load_victim_cache_in_idx].dirty = dcache_next2[line_idx].dirty;
                        load_victim_cache_in1[load_victim_cache_in_idx].line_idx = line_idx;
                        load_victim_cache_in_idx = load_victim_cache_in_idx + 1;
                        victim_cache_full_evict_next = 1;
                    end
                    dcache_next2[line_idx].data = mshr_next2[j].data;
                    dcache_next2[line_idx].tag = mshr_next2[j].address[`XLEN-1:`CACHE_LINE_BITS+3];
                    dcache_next2[line_idx].valid = 1;
                    dcache_next2[line_idx].dirty = 0;

                    casez(mshr_next2[j].size)
                        BYTE:
                        begin
                            casez(mshr_next2[j].address[2:0])
                                3'd0: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[7]}}, mshr_next2[j].data[7:0]} : {24'b0, mshr_next2[j].data[7:0]};
                                3'd1: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[15]}}, mshr_next2[j].data[15:8]} : {24'b0, mshr_next2[j].data[15:8]};
                                3'd2: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[23]}}, mshr_next2[j].data[23:16]} : {24'b0, mshr_next2[j].data[23:16]};
                                3'd3: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[31]}}, mshr_next2[j].data[31:24]} : {24'b0, mshr_next2[j].data[31:24]};
                                3'd4: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[39]}}, mshr_next2[j].data[39:32]} : {24'b0, mshr_next2[j].data[39:32]};
                                3'd5: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[47]}}, mshr_next2[j].data[47:40]} : {24'b0, mshr_next2[j].data[47:40]};
                                3'd6: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[55]}}, mshr_next2[j].data[55:48]} : {24'b0, mshr_next2[j].data[55:48]};
                                3'd7: load_packet_out_next[load_packet_out_idx].data = !mshr_next2[j].sign ? {{24{mshr_next2[j].data[63]}}, mshr_next2[j].data[63:56]} : {24'b0, mshr_next2[j].data[63:56]};
                                default: load_packet_out_next[load_packet_out_idx].data = 0;
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next2[j].address[2:0])
                                3'd0: load_packet_out_next[load_packet_out_idx].data = (!mshr_next2[j].sign) ? {{16{mshr_next2[j].data[15]}}, mshr_next2[j].data[15:0]}  : {16'b0, mshr_next2[j].data[15:0]};
                                3'd2: load_packet_out_next[load_packet_out_idx].data = (!mshr_next2[j].sign) ? {{16{mshr_next2[j].data[31]}}, mshr_next2[j].data[31:16]} : {16'b0, mshr_next2[j].data[31:16]};
                                3'd4: load_packet_out_next[load_packet_out_idx].data = (!mshr_next2[j].sign) ? {{16{mshr_next2[j].data[47]}}, mshr_next2[j].data[47:32]} : {16'b0, mshr_next2[j].data[47:32]};
                                3'd6: load_packet_out_next[load_packet_out_idx].data = (!mshr_next2[j].sign) ? {{16{mshr_next2[j].data[63]}}, mshr_next2[j].data[63:48]} : {16'b0, mshr_next2[j].data[63:48]};
                                default: load_packet_out_next[load_packet_out_idx].data = 0;
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next2[j].address[2:0])
                                3'd0: load_packet_out_next[load_packet_out_idx].data = mshr_next2[j].data[31:0];
                                3'd4: load_packet_out_next[load_packet_out_idx].data = mshr_next2[j].data[63:32];
                                default: load_packet_out_next[load_packet_out_idx].data = 0;
                            endcase
                        end
                        default: load_packet_out_next[load_packet_out_idx].data = 0;
                    endcase
                    load_packet_out_next[load_packet_out_idx].dest_tag = mshr_next2[j].dest_tag;
                    load_packet_out_next[load_packet_out_idx].address= mshr_next2[j].address;
                    load_packet_out_next[load_packet_out_idx].valid = 1;
                    load_packet_out_idx = load_packet_out_idx + 1;
                    mshr_next2[j].valid = 0;
                    order_idx_next2 = order_idx_next2 - 1;
                    load_mshr_invalidated_order_idx = i;
                end
            end
        end
    end
end


// The order index of each entry of the MSHR is updated. 
always_comb
begin
    mshr_next3 = mshr_next2;
    //if(victim_cache_full_evict_next)
   // begin
        if(load_mshr_invalidated_order_idx < store_mshr_invalidated_order_idx)
        begin
            for(int i = 0; i < `MSHR_SIZE; i++)
            begin
                if(mshr_next2[i].valid)
                begin
                    if(mshr_next2[i].order_idx >= load_mshr_invalidated_order_idx && mshr_next2[i].order_idx < store_mshr_invalidated_order_idx)
                        mshr_next3[i].order_idx = mshr_next3[i].order_idx - 1;
                    else if(mshr_next2[i].order_idx >= store_mshr_invalidated_order_idx)
                        mshr_next3[i].order_idx = mshr_next3[i].order_idx - 2;
                end
            end
        end
        else
        begin
            for(int i = 0; i < `MSHR_SIZE; i++)
            begin
                if(mshr_next2[i].valid)
                begin
                    if(mshr_next2[i].order_idx >= store_mshr_invalidated_order_idx && mshr_next2[i].order_idx < load_mshr_invalidated_order_idx)
                        mshr_next3[i].order_idx = mshr_next3[i].order_idx - 1;
                    else if(mshr_next2[i].order_idx >= load_mshr_invalidated_order_idx)
                        mshr_next3[i].order_idx = mshr_next3[i].order_idx - 2;
                end
            end
        end
    //end
end



// L1 hits are set in the MSHR. This step is same for loads as well as stores. 
always_comb
begin
    mshr_next4 = mshr_next3;
    for(int i = 0; i < `MSHR_SIZE; i++)
    begin
        if(mshr_next3[i].valid &&
        dcache_next2[mshr_next3[i].address[`CACHE_LINE_BITS+3-1:3]].valid &&
        dcache_next2[mshr_next3[i].address[`CACHE_LINE_BITS+3-1:3]].tag == mshr_next3[i].address[`XLEN-1:`CACHE_LINE_BITS+3])
        begin
            mshr_next4[i].data = dcache_next2[mshr_next3[i].address[`CACHE_LINE_BITS+3-1:3]].data;
            mshr_next4[i].l1_hit = 1;
            mshr_next4[i].dispatched = 1;
            mshr_next4[i].ready = 1;
        end
        else
        begin
            mshr_next4[i].l1_hit = 0;
        end
    end
end


// Data is prepared for querying the victim cache for victim hits. This step is same for loads and stores. 
always_comb
begin
    for(int i = 0; i < `MSHR_SIZE; i++)
    begin
        victim_cache_hit_in[i] = mshr_next3[i].address;
        if(mshr_next3[i].valid && (!mshr_next3[i].l1_hit))
            victim_cache_hit_valid_in[i] = 1;
        else
            victim_cache_hit_valid_in[i] = 0;
    end
end


// Depending on the output of the victim cache, victim hits are recorded in the MSHR. This step is same for loads and stores
always_comb
begin
    mshr_next5 = mshr_next4;
    for(int i = 0; i < `MSHR_SIZE; i++)
    begin
        if(victim_cache_hit_valid_out[i])
        begin
            mshr_next5[i].dispatched = 1;
            mshr_next5[i].ready = 1;
            mshr_next5[i].victim_hit = 1;
            mshr_next5[i].data = victim_cache_hit_out[i];
	    if (mshr_next5[i].store) begin
           	 case(mshr_next5[i].size)
           	     BYTE:
           	     begin
           	         casez(mshr_next5[i].address[2:0])
           	             3'd0: mshr_next5[i].data = {victim_cache_hit_out[i][63:8], mshr_next5[i].store_data[7:0]};
           	             3'd1: mshr_next5[i].data = {victim_cache_hit_out[i][63:16], mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][7:0]};
           	             3'd2: mshr_next5[i].data = {victim_cache_hit_out[i][63:24], mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][15:8]};
           	             3'd3: mshr_next5[i].data = {victim_cache_hit_out[i][63:32], mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][23:16]};
           	             3'd4: mshr_next5[i].data = {victim_cache_hit_out[i][63:40], mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][31:24]};
           	             3'd5: mshr_next5[i].data = {victim_cache_hit_out[i][63:48], mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][39:32]};
           	             3'd6: mshr_next5[i].data = {victim_cache_hit_out[i][63:56], mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][47:40]};
           	             3'd7: mshr_next5[i].data = {mshr_next5[i].store_data[7:0], victim_cache_hit_out[i][55:48]};
           	         endcase
           	     end
           	     HALF:
           	     begin
           	         casez(mshr_next5[i].address[2:1])
           	             2'd0: mshr_next5[i].data = {victim_cache_hit_out[i][63:16], mshr_next5[i].store_data[15:0]};
           	             2'd1: mshr_next5[i].data = {victim_cache_hit_out[i][63:32], mshr_next5[i].store_data[15:0], victim_cache_hit_out[i][15:0]};
           	             2'd2: mshr_next5[i].data = {victim_cache_hit_out[i][63:48], mshr_next5[i].store_data[15:0], victim_cache_hit_out[i][31:16]};
           	             2'd3: mshr_next5[i].data = {mshr_next5[i].store_data[15:0], victim_cache_hit_out[i][47:32]};
           	         endcase
           	     end
           	     WORD:
           	     begin
           	         casez(mshr_next5[i].address[2])
           	             1'd0: mshr_next5[i].data = {victim_cache_hit_out[i][63:32], mshr_next5[i].store_data[31:0]};
           	             1'd1: mshr_next5[i].data = {mshr_next5[i].store_data[31:0], victim_cache_hit_out[i][31:0]};
           	         endcase
           	     end
           	 endcase
            end
        end
    end
end

// This combinational block sends a new request to the memory.
always_comb
begin
    mshr_next6 = mshr_next5;
    dcache2mem_command = BUS_NONE;
    tmp1 = 1;
    for(int i = 1; i <= `MSHR_SIZE; i++)
    begin
        for(int j = 0; j < `MSHR_SIZE; j++)
        begin
            if(tmp1 && mshr_next5[j].valid && !mshr_next5[j].dispatched && !mshr_next5[j].victim_hit && mshr_next5[j].order_idx == i)
            begin
                if(mshr_next5[j].load)
                begin
                    mshr_idx_next = j;
                    mshr_next6[j].dispatched = 1;
                    dcache2mem_addr = {mshr_next5[j].address[`XLEN-1:3], 3'b0};
                    dcache2mem_command = BUS_LOAD;
                    tmp1 = 0;
                end
                else if(mshr_next5[j].store)
                begin
                    if(mshr_next5[j].size!=DOUBLE)
                    begin
                        mshr_idx_next = j;
                        mshr_next6[j].dispatched = 1;
                        // dcache2mem_addr = {mshr_next5[j].address[`XLEN-1:3], 3'b0};
                        // dcache2mem_command = BUS_STORE;
                        // dcache2mem_data = mshr_next5[j].data;
                        dcache2mem_addr = {mshr_next5[j].address[`XLEN-1:3], 3'b0};
                        dcache2mem_command = BUS_LOAD;
                        tmp1 = 0;
                    end
                    else
                    begin
                        mshr_idx_next = j;
                        mshr_next6[j].dispatched = 1;
                        dcache2mem_addr = {mshr_next5[j].address[`XLEN-1:3], 3'b0};
                        dcache2mem_command = BUS_STORE;
                        dcache2mem_data = mshr_next5[j].data;
                        tmp1 = 0;
                    end
                end
            end
        end
    end
end


// The below block will load see if no data has been received from memory, and if some data is ready in the victim cache to be evicted.
always_comb
begin
    victim_cache_partial_evict_next = 0;
    load_victim_cache_in2 = load_victim_cache_in1;
    store_victim_cache_in2 = store_victim_cache_in1;
    load_victim_cache_in_idx1 = load_victim_cache_in_idx;
    store_victim_cache_in_idx1 = store_victim_cache_in_idx;
    line_idx1 = 0;
    load_packet_out_next1 = load_packet_out_next;
    load_packet_out_idx1 = load_packet_out_idx;
    store_packet_out_next1 = store_packet_out_next;
    store_packet_out_idx1 = store_packet_out_idx;
    mshr_next7 = mshr_next6;
    order_idx_next3 = order_idx_next2;
    load_mshr_invalidated_order_idx1 = `MSHR_SIZE;
    store_mshr_invalidated_order_idx1 = `MSHR_SIZE; 
    store_victim_mshr_in = 0;
    // First, for stores. 
    if(!victim_cache_full_evict_next)
    begin
        tmp5 =0;
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next6[j].valid && mshr_next6[j].victim_hit && mshr_next6[j].store && (mshr_next6[j].order_idx == i) && !tmp5)
                begin
		// if victim hit and forwarding from store in to victim cache
		    store_victim_mshr_in[0] = mshr_next6[j]; 
                    // This means that the data for this particular MSHR entry is present in the victim cache.
                    line_idx1 = mshr_next6[j].address[`CACHE_LINE_BITS+3-1:3];
                    victim_cache_partial_evict_next = 1;
                    store_victim_cache_in2[store_victim_cache_in_idx1].valid = dcache_next2[line_idx1].valid;
                    store_victim_cache_in2[store_victim_cache_in_idx1].tag = dcache_next2[line_idx1].tag;
                    store_victim_cache_in2[store_victim_cache_in_idx1].data = dcache_next2[line_idx1].data;
                    store_victim_cache_in2[store_victim_cache_in_idx1].dirty = dcache_next2[line_idx1].dirty;
                    store_victim_cache_in2[store_victim_cache_in_idx1].line_idx = line_idx1;
                    store_victim_cache_in_idx1 = store_victim_cache_in_idx1 + 1;

                    mshr_next7[j].valid = 0;
                    store_packet_out_next1[store_packet_out_idx1].store_pos = mshr_next6[j].store_pos;
                    store_packet_out_next1[store_packet_out_idx1].valid = 1;
                    store_packet_out_idx1 = store_packet_out_idx1 + 1;
                    store_mshr_invalidated_order_idx1 = i;
                    order_idx_next3 = order_idx_next3 - 1;
                    //break;
                    tmp5 =1;
                end
            end
        end
    end

    // Then, for loads. 

    if(!victim_cache_full_evict_next && !victim_cache_partial_evict_next)
    begin
                	tmp6 =0;
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next7[j].valid && mshr_next7[j].load && mshr_next7[j].victim_hit && mshr_next7[j].order_idx == i && !tmp6)
                begin
                    // This means that the data for this particular MSHR entry is present in the victim cache.
                    line_idx1 = mshr_next7[j].address[`CACHE_LINE_BITS+3-1:3];
                    victim_cache_partial_evict_next = 1;
                    load_victim_cache_in2[load_victim_cache_in_idx1].valid = dcache_next2[line_idx1].valid;
                    load_victim_cache_in2[load_victim_cache_in_idx1].tag = dcache_next2[line_idx1].tag;
                    load_victim_cache_in2[load_victim_cache_in_idx1].data = dcache_next2[line_idx1].data;
                    load_victim_cache_in2[load_victim_cache_in_idx1].dirty = dcache_next2[line_idx1].dirty;
                    load_victim_cache_in2[load_victim_cache_in_idx1].line_idx = line_idx1;
                    load_victim_cache_in_idx1 = load_victim_cache_in_idx1 + 1;

                    mshr_next7[j].valid = 0;
                    casez(mshr_next7[j].size)
                        BYTE:
                        begin
                            casez(mshr_next7[j].address[2:0])
                                3'd0: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[7]}},  mshr_next7[j].data[7:0]}   : {24'b0, mshr_next7[j].data[7:0]};
                                3'd1: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[15]}}, mshr_next7[j].data[15:8]}  : {24'b0, mshr_next7[j].data[15:8]};
                                3'd2: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[23]}}, mshr_next7[j].data[23:16]} : {24'b0, mshr_next7[j].data[23:16]};
                                3'd3: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[31]}}, mshr_next7[j].data[31:24]} : {24'b0, mshr_next7[j].data[31:24]};
                                3'd4: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[39]}}, mshr_next7[j].data[39:32]} : {24'b0, mshr_next7[j].data[39:32]};
                                3'd5: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[47]}}, mshr_next7[j].data[47:40]} : {24'b0, mshr_next7[j].data[47:40]};
                                3'd6: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[55]}}, mshr_next7[j].data[55:48]} : {24'b0, mshr_next7[j].data[55:48]};
                                3'd7: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{24{mshr_next7[j].data[63]}}, mshr_next7[j].data[63:56]} : {24'b0, mshr_next7[j].data[63:56]};
                                default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next7[j].address[2:0])
                                3'd0: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{16{mshr_next7[j].data[15]}}, mshr_next7[j].data[15:0]}  : {16'b0, mshr_next7[j].data[15:0]};
                                3'd2: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{16{mshr_next7[j].data[31]}}, mshr_next7[j].data[31:16]} : {16'b0, mshr_next7[j].data[31:16]};
                                3'd4: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{16{mshr_next7[j].data[47]}}, mshr_next7[j].data[47:32]} : {16'b0, mshr_next7[j].data[47:32]};
                                3'd6: load_packet_out_next1[load_packet_out_idx1].data = (!mshr_next7[j].sign) ? {{16{mshr_next7[j].data[63]}}, mshr_next7[j].data[63:48]} : {16'b0, mshr_next7[j].data[63:48]};
                                default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next7[j].address[2:0])
                                3'd0: load_packet_out_next1[load_packet_out_idx1].data = mshr_next7[j].data[31:0];
                                3'd4: load_packet_out_next1[load_packet_out_idx1].data = mshr_next7[j].data[63:32];
                                default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                            endcase
                        end
                        default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                    endcase
                    load_packet_out_next1[load_packet_out_idx1].dest_tag = mshr_next7[j].dest_tag;
                    load_packet_out_next1[load_packet_out_idx1].address= mshr_next7[j].address;
                    load_packet_out_next1[load_packet_out_idx1].valid = 1;
                    load_packet_out_idx1 = load_packet_out_idx1 + 1;
                    load_mshr_invalidated_order_idx1 = i;
                    order_idx_next3 = order_idx_next3 - 1;
                    //break;
                	tmp6 =1;
                end
            end
        end
    end
end


// Order indices are updated in the MSHR. 

// At this stage, if it is a partial evict, then either the load will be processed or the store would be processed. 
always_comb
begin
    mshr_next8 = mshr_next7;
    if(victim_cache_partial_evict_next)
    begin
        if(load_mshr_invalidated_order_idx1!=`MSHR_SIZE)
        begin
            for(int i = 0; i < `MSHR_SIZE; i++)
            begin
                if(mshr_next7[i].valid && mshr_next7[i].order_idx >= load_mshr_invalidated_order_idx1)
                    mshr_next8[i].order_idx = mshr_next8[i].order_idx - 1;
            end 
        end
        else
        begin
            for(int i = 0; i < `MSHR_SIZE; i++)
            begin
                if(mshr_next7[i].valid && mshr_next7[i].order_idx >= store_mshr_invalidated_order_idx1)
                    mshr_next8[i].order_idx = mshr_next8[i].order_idx - 1;
            end
        end
    end
end


// L1 hit data is loaded into the output packet.  
always_comb
begin
    dcache_next3 = dcache_next2;
    load_packet_out_next2 = load_packet_out_next1;
    load_packet_out_idx2 = load_packet_out_idx1;
    store_packet_out_next2 = store_packet_out_next1;
    store_packet_out_idx2 = store_packet_out_idx1;
    mshr_next9 = mshr_next8;
    load_mshr_invalidated_order_idx2 = `MSHR_SIZE;
    store_mshr_invalidated_order_idx2 = `MSHR_SIZE;
    load_l1_hit_next = 0;
    store_l1_hit_next = 0;
    order_idx_next4 = order_idx_next3;

    // First, the stores.
    if(store_packet_out_idx2 < 1)
    begin
                	tmp7 =0;
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
		//$display("valid:%x , store:%x , hit:%x , order:%x , i:%x , j:%x, time: %t",mshr_next8[j].valid,mshr_next8[j].store,mshr_next8[j].l1_hit,mshr_next8[j].order_idx,i,j,$time);
                if(mshr_next8[j].valid && mshr_next8[j].store && mshr_next8[j].l1_hit && mshr_next8[j].order_idx == i && !tmp7)
                begin
		//$display("entered the if time: %t",$time);

                    store_l1_hit_next = 1;
                    mshr_next9[j].valid = 0;
		    dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].dirty = 1;
                    casez(mshr_next8[j].size)
                        BYTE:
                        begin
                            casez(mshr_next8[j].address[2:0])
                                3'd0: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[7:0] = mshr_next8[j].store_data[7:0];
                                3'd1: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[15:8] = mshr_next8[j].store_data[7:0];
                                3'd2: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[23:16] = mshr_next8[j].store_data[7:0];
                                3'd3: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[31:24] = mshr_next8[j].store_data[7:0];
                                3'd4: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[39:32] = mshr_next8[j].store_data[7:0];
                                3'd5: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[47:40] = mshr_next8[j].store_data[7:0];
                                3'd6: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[55:48] = mshr_next8[j].store_data[7:0];
                                3'd7: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[63:56] = mshr_next8[j].store_data[7:0];
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next8[j].address[2:1])
                                2'd0: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[15:0] = mshr_next8[j].store_data[15:0];
                                2'd1: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[31:16] = mshr_next8[j].store_data[15:0];
                                2'd2: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[47:32] = mshr_next8[j].store_data[15:0];
                                2'd3: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[63:48] = mshr_next8[j].store_data[15:0];
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next8[j].address[2])
                                1'd0: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[31:0] = mshr_next8[j].store_data[31:0];
                                1'd1: dcache_next3[mshr_next8[j].address[`CACHE_LINE_BITS+3-1:3]].data[63:32] = mshr_next8[j].store_data[31:0];
                            endcase
                        end
                    endcase
                    
                    store_packet_out_next2[store_packet_out_idx2].store_pos = mshr_next8[j].store_pos;
                    store_packet_out_next2[store_packet_out_idx2].valid = 1;
                    store_packet_out_idx2 = store_packet_out_idx2 + 1;
                    order_idx_next4 = order_idx_next4 - 1;
                    store_mshr_invalidated_order_idx2 = i;
                    //break;
                	tmp7 =1;
                end
            end
        end
    end


    // Then, the loads. 
    if(load_packet_out_idx2 < 1)
    begin
                	tmp8 =0;
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next9[j].valid && mshr_next9[j].load && mshr_next9[j].l1_hit && mshr_next9[j].order_idx == i && !tmp8)
                begin
                    load_l1_hit_next = 1;
                    mshr_next9[j].valid = 0;
                    casez(mshr_next9[j].size)
                        BYTE:
                        begin
                            casez(mshr_next9[j].address[2:0])
                                3'd0: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[7]}},  mshr_next9[j].data[7:0]}   : {24'b0, mshr_next9[j].data[7:0]};
                                3'd1: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[15]}}, mshr_next9[j].data[15:8]}  : {24'b0, mshr_next9[j].data[15:8]};
                                3'd2: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[23]}}, mshr_next9[j].data[23:16]} : {24'b0, mshr_next9[j].data[23:16]};
                                3'd3: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[31]}}, mshr_next9[j].data[31:24]} : {24'b0, mshr_next9[j].data[31:24]};
                                3'd4: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[39]}}, mshr_next9[j].data[39:32]} : {24'b0, mshr_next9[j].data[39:32]};
                                3'd5: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[47]}}, mshr_next9[j].data[47:40]} : {24'b0, mshr_next9[j].data[47:40]};
                                3'd6: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[55]}}, mshr_next9[j].data[55:48]} : {24'b0, mshr_next9[j].data[55:48]};
                                3'd7: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{24{mshr_next9[j].data[63]}}, mshr_next9[j].data[63:56]} : {24'b0, mshr_next9[j].data[63:56]};
                                default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next9[j].address[2:0])
                                3'd0: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{16{mshr_next9[j].data[15]}}, mshr_next9[j].data[15:0]}  : {16'b0, mshr_next9[j].data[15:0]};
                                3'd2: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{16{mshr_next9[j].data[31]}}, mshr_next9[j].data[31:16]} : {16'b0, mshr_next9[j].data[31:16]};
                                3'd4: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{16{mshr_next9[j].data[47]}}, mshr_next9[j].data[47:32]} : {16'b0, mshr_next9[j].data[47:32]};
                                3'd6: load_packet_out_next2[load_packet_out_idx2].data = (!mshr_next9[j].sign) ? {{16{mshr_next9[j].data[63]}}, mshr_next9[j].data[63:48]} : {16'b0, mshr_next9[j].data[63:48]};
                                default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next9[j].address[2:0])
                                3'd0: load_packet_out_next2[load_packet_out_idx2].data = mshr_next9[j].data[31:0];
                                3'd4: load_packet_out_next2[load_packet_out_idx2].data = mshr_next9[j].data[63:32];
                                default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                            endcase
                        end
                        default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                    endcase
                    load_packet_out_next2[load_packet_out_idx2].dest_tag = mshr_next9[j].dest_tag;
                    load_packet_out_next2[load_packet_out_idx2].address= mshr_next9[j].address;
                    load_packet_out_next2[load_packet_out_idx2].valid = 1;
                    load_packet_out_idx2 = load_packet_out_idx2 + 1;
                    order_idx_next4 = order_idx_next4 - 1;
                    load_mshr_invalidated_order_idx2 = i;
                	tmp8 =1;
                end
            end
        end
    end
end


/// Order indices are updated in the MSHR. 
always_comb
begin
    mshr_next10 = mshr_next9;
    if(load_l1_hit_next||store_l1_hit_next)
    begin
        if(load_mshr_invalidated_order_idx2 > store_mshr_invalidated_order_idx2)
        begin
            for(int i = 0; i < `MSHR_SIZE; i++)
            begin
                if(mshr_next9[i].valid && mshr_next9[i].order_idx >= store_mshr_invalidated_order_idx2 && mshr_next9[i].order_idx < load_mshr_invalidated_order_idx2)
                    mshr_next10[i].order_idx = mshr_next10[i].order_idx -1;
                else if(mshr_next9[i].valid && mshr_next9[i].order_idx >= load_mshr_invalidated_order_idx2)
                    mshr_next10[i].order_idx = mshr_next10[i].order_idx - 2;
            end
        end
        else
        begin
            for(int i = 0; i < `MSHR_SIZE; i++)
            begin
                if(mshr_next9[i].valid && mshr_next9[i].order_idx >= load_mshr_invalidated_order_idx2 && mshr_next9[i].order_idx < store_mshr_invalidated_order_idx2)
                    mshr_next10[i].order_idx = mshr_next10[i].order_idx -1;
                else if(mshr_next9[i].valid && mshr_next9[i].order_idx >= store_mshr_invalidated_order_idx2)
                    mshr_next10[i].order_idx = mshr_next10[i].order_idx - 2;
            end
        end
    end
end

// If the load packet is an L1 hit, it is loaded into the output packet, otherwise sent to the MSHR. 
always_comb
begin
    dcache_next4 = dcache_next3;
    load_packet_out_next3 = load_packet_out_next2;
    load_packet_out_idx3 = load_packet_out_idx2;
    store_packet_out_next3 = store_packet_out_next2;
    store_packet_out_idx3 = store_packet_out_idx2;
    mshr_next11 = mshr_next10;
    order_idx_next5 = order_idx_next4;
//	$display("store_dispaly1, time  %x %t",store_packet_in[0].address,$time);
    // First the stores. 
    if(store_packet_in[0].valid &&
    dcache_next3[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].valid &&
    dcache_next3[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].tag == store_packet_in[0].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
    store_packet_out_idx3 < 1 && !flush)
    begin
        dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].dirty = 1;
        casez(store_packet_in[0].size)
            BYTE:
            begin
                casez(store_packet_in[0].address[2:0])
                    3'd0: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[7:0] = store_packet_in[0].data[7:0];
                    3'd1: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:8] = store_packet_in[0].data[7:0];
                    3'd2: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[23:16] = store_packet_in[0].data[7:0];
                    3'd3: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:24] = store_packet_in[0].data[7:0];
                    3'd4: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[39:32] = store_packet_in[0].data[7:0];
                    3'd5: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:40] = store_packet_in[0].data[7:0];
                    3'd6: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[55:48] = store_packet_in[0].data[7:0];
                    3'd7: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:56] = store_packet_in[0].data[7:0];
                endcase
            end
            HALF:
            begin
                casez(store_packet_in[0].address[2:1])
                    2'd0: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:0] = store_packet_in[0].data[15:0];
                    2'd1: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:16] = store_packet_in[0].data[15:0];
                    2'd2: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:32] = store_packet_in[0].data[15:0];
                    2'd3: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:48] = store_packet_in[0].data[15:0];
                endcase
            end
            WORD:
            begin
                casez(store_packet_in[0].address[2])
                    1'd0: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:0] = store_packet_in[0].data[31:0];
                    1'd1: dcache_next4[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:32] = store_packet_in[0].data[31:0];
                endcase
            end
        endcase

        store_packet_out_next3[store_packet_out_idx3].store_pos = store_packet_in[0].store_pos;
        store_packet_out_next3[store_packet_out_idx3].valid = 1;
        store_packet_out_idx3 = store_packet_out_idx3 + 1;
        
    end
    else if(!flush)
    begin
        tmp9 =0;
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next10[i].valid &&
            store_packet_in[0].valid && !tmp9)
            begin
                mshr_next11[i].load = 0;
                mshr_next11[i].store = 1;
                mshr_next11[i].dispatched = 1'b0;
                mshr_next11[i].valid = 1'b1;
                mshr_next11[i].ready = 0;
                mshr_next11[i].data = store_packet_in[0].data;
                mshr_next11[i].address = store_packet_in[0].address;
                mshr_next11[i].store_pos = store_packet_in[0].store_pos;
                mshr_next11[i].expected_tag = 0;
                mshr_next11[i].expected_tag_assigned = 0;
                mshr_next11[i].dest_tag = 0;
                mshr_next11[i].order_idx = order_idx_next5;
                mshr_next11[i].victim_hit = 0;
                mshr_next11[i].l1_hit = 0;
                mshr_next11[i].size = store_packet_in[0].size;
                mshr_next11[i].store_data = store_packet_in[0].data;
                order_idx_next5 = order_idx_next5 + 1;
                	tmp9 =1;
            end
        end
    end
	//load_forward = 0;	
    // T//hen, the loads. 
	//for(int i=0; i<`MSHR_SIZE; i++) begin
	//	if(mshr_next11[i].valid && mshr_next11[i].store && (!mshr_next11[i].ready || mshr_next11[i].l1_hit) && (mshr_next11[i].address[`XLEN-1:3] == load_packet_in[0].address[`XLEN-1:3])) load_forward = 1;
	////	if( mshr_next11[i].store && !mshr_next11[i].ready && (mshr_next11[i].address[`XLEN-1:3] == load_packet_in[0].address[`XLEN-1:3])) load_forward = 1;
	//end
    if(load_packet_in[0].valid &&
    dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].valid &&
    dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].tag == load_packet_in[0].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
    load_packet_out_idx3 < 1 && !flush )
    begin
        casez(load_packet_in[0].size)
            BYTE:
            begin
                casez(load_packet_in[0].address[2:0])
                    3'd0: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[7]}},  dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[7:0]}   : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[7:0]};
                    3'd1: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:8]}  : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:8]};
                    3'd2: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[23]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[23:16]} : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[23:16]};
                    3'd3: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:24]} : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:24]};
                    3'd4: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[39]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[39:32]} : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[39:32]};
                    3'd5: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:40]} : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:40]};
                    3'd6: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[55]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[55:48]} : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[55:48]};
                    3'd7: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{24{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:56]} : {24'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:56]};
                    default: load_packet_out_next3[load_packet_out_idx3].data = 0;
                endcase
            end
            HALF:
            begin
                casez(load_packet_in[0].address[2:0])
                    3'd0: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{16{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:0]}  : {16'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:0]};
                    3'd2: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{16{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:16]} : {16'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:16]};
                    3'd4: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{16{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:32]} : {16'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:32]};
                    3'd6: load_packet_out_next3[load_packet_out_idx3].data = (!load_packet_in[0].sign) ? {{16{dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63]}}, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:48]} : {16'b0, dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:48]};
                    default: load_packet_out_next3[load_packet_out_idx3].data = 0;
                endcase
            end
            WORD:
            begin
                casez(load_packet_in[0].address[2:0])
                    3'd0: load_packet_out_next3[load_packet_out_idx3].data = dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:0];
                    3'd4: load_packet_out_next3[load_packet_out_idx3].data = dcache_next4[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:32];
                    default: load_packet_out_next3[load_packet_out_idx3].data = 0;
                endcase
            end
            default: load_packet_out_next3[load_packet_out_idx3].data = 0;
        endcase
        load_packet_out_next3[load_packet_out_idx3].dest_tag = load_packet_in[0].dest_tag;
        load_packet_out_next3[load_packet_out_idx3].address = load_packet_in[0].address;
        load_packet_out_next3[load_packet_out_idx3].valid = 1;
        load_packet_out_idx3 = load_packet_out_idx3 + 1;
        
    end
    else if(!flush) 
    begin
        tmp10 =0;
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next11[i].valid &&
            load_packet_in[0].valid && !tmp10)
            begin
                mshr_next11[i].load = 1;
                mshr_next11[i].store = 0;
                mshr_next11[i].dispatched = 1'b0;
                mshr_next11[i].valid = 1'b1;
                mshr_next11[i].ready = 0;
                mshr_next11[i].data = 0;
                mshr_next11[i].address = load_packet_in[0].address;
                mshr_next11[i].store_pos = 0;
                mshr_next11[i].expected_tag = 0;
                mshr_next11[i].expected_tag_assigned = 0;
                mshr_next11[i].dest_tag = load_packet_in[0].dest_tag;
                mshr_next11[i].order_idx = order_idx_next5;
                mshr_next11[i].victim_hit = 0;
                mshr_next11[i].l1_hit = 0;
                mshr_next11[i].size = load_packet_in[0].size;
                mshr_next11[i].store_data = 0;
                mshr_next11[i].sign = load_packet_in[0].sign;
                order_idx_next5 = order_idx_next5 + 1;
                	tmp10 =1;
            end
        end
    end


end
always_comb
begin
    load_packet_out_next4 = load_packet_out_next3;
    store_packet_out_next4 = store_packet_out_next3;
    for(int i = 0; i < `N_RD_PORTS; i++)
    begin
        if(i >= load_packet_out_idx3)
            load_packet_out_next4[i] = 0;
    end
    for(int i = 0; i < `N_WR_PORTS; i++)
    begin
        if(i >= store_packet_out_idx3)
            store_packet_out_next4[i] = 0;
    end
end


always_comb
begin
    load_victim_cache_in3 = load_victim_cache_in2;
    store_victim_cache_in3 = store_victim_cache_in2;
    for(int i = 0;i < `N_RD_PORTS; i++)
    begin
        if(i >= load_victim_cache_in_idx1)
            load_victim_cache_in3[i] = 0;
    end
    for(int i = 0;i < `N_WR_PORTS; i++)
    begin
        if(i >= store_victim_cache_in_idx1)
            store_victim_cache_in3[i] = 0;
    end
    
end

always_comb
begin
    all_mshr_requests_processed = 1;
    for(int i = 0; i < `CACHE_LINES; i++)
    begin
        if(mshr_next11[i].valid)
        begin
            all_mshr_requests_processed = 0;
        end
    end
end

always_comb
begin
    mshr_next12 = mshr_next11;
    dcache_next5 = dcache_next4;
    tmp2 = 1;
    order_idx_next6 = order_idx_next5;
    flush_victim = 0;
    victim_cache_full_evict_next2 = victim_cache_full_evict_next;
    if(flush && all_mshr_requests_processed_reg)
    begin
        for(line_idx2 = 0; line_idx2 < `CACHE_LINES; line_idx2++)
        begin
            if(tmp2 && dcache_next4[line_idx2].valid && dcache_next4[line_idx2].dirty)
            begin
                dcache_next5[line_idx2].dirty = 0;
                dcache_next5[line_idx2].valid = 0;
                for(int i = 0; i < `MSHR_SIZE; i++)
                begin
                    if(tmp2 && !mshr_next11[i].valid)
                    begin
                        mshr_next12[i].load = 0;
                        mshr_next12[i].store = 1;
                        mshr_next12[i].dispatched = 1'b0;
                        mshr_next12[i].valid = 1'b1;
                        mshr_next12[i].ready = 0;
                        mshr_next12[i].data = dcache_next4[line_idx2].data;
                        mshr_next12[i].address = {dcache_next4[line_idx2].tag, line_idx2[`CACHE_LINE_BITS-1:0], 3'b0};
                        mshr_next12[i].store_pos = 0;
                        mshr_next12[i].expected_tag = 0;
                        mshr_next12[i].expected_tag_assigned = 0;
                        mshr_next12[i].dest_tag = 0;
                        mshr_next12[i].order_idx = order_idx_next6;
                        mshr_next12[i].victim_hit = 0;
                        mshr_next12[i].l1_hit = 0;
                        mshr_next12[i].size = DOUBLE;
                        mshr_next12[i].store_data = 0;
                        mshr_next12[i].sign = 0;
                        order_idx_next6 = order_idx_next6 + 1;
                        tmp2 = 0;
                    end
                end
            end
        end
        if(tmp2)
        begin
            flush_victim = 1;
            victim_cache_full_evict_next2 = 1;
        end
    end
end

always_ff @ (posedge clock)
begin
    if(reset)
    begin
        load_packet_out <= `SD 0;
        store_packet_out <= `SD 0;
        mshr_idx <= `SD 0;
        victim_cache_full_evict <= `SD 0;
        victim_cache_partial_evict <= `SD 0;
        load_l1_hit <= `SD 0;
        store_l1_hit <= `SD 0;
        dcache <= `SD 0;
        order_idx <= `SD 1;
        mshr <= `SD 0;
        latched_mem2dcache_response <= `SD 0;
        latched_mem2dcache_data<= `SD 0;
        latched_mem2dcache_tag<= `SD 0;
        all_mshr_requests_processed_reg <= `SD 0;
    end
    else
    begin
        load_packet_out <= `SD load_packet_out_next4;
        store_packet_out <= `SD store_packet_out_next4;
        mshr_idx <= `SD mshr_idx_next;
        victim_cache_full_evict <= `SD victim_cache_full_evict_next2;
        victim_cache_partial_evict <= `SD victim_cache_partial_evict_next;
        load_l1_hit <= `SD load_l1_hit_next;
        store_l1_hit <= `SD store_l1_hit_next;
        mshr <= `SD mshr_next12;
        dcache <= `SD dcache_next5;
        order_idx <= `SD order_idx_next6;
        latched_mem2dcache_response <= `SD mem2dcache_response;
        latched_mem2dcache_data<= `SD mem2dcache_data;
        latched_mem2dcache_tag<= `SD mem2dcache_tag;
        all_mshr_requests_processed_reg <= `SD all_mshr_requests_processed;
    end
end

endmodule






module victim_cache(
    input flush_victim,
    input clock, 
    input reset,
    input MSHR_ROW [`N_WR_PORTS-1:0] store_victim_mshr_in,
    input logic [`MSHR_SIZE-1:0][`XLEN-1:0] victim_cache_hit_in,
    input logic [`MSHR_SIZE-1:0] victim_cache_hit_valid_in,
    output logic [`MSHR_SIZE-1:0] victim_cache_hit_valid_out,
    output logic [`MSHR_SIZE-1:0][63:0] victim_cache_hit_out,
    input VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_cache_in,
    output VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_cache_out,
    input VICTIM_CACHE_ROW [`N_WR_PORTS-1:0] store_victim_cache_in,
    output VICTIM_CACHE_ROW [`N_WR_PORTS-1:0] store_victim_cache_out,
    input logic victim_cache_full_evict,
    input logic victim_cache_partial_evict
);

VICTIM_CACHE_ROW [3:0] victim_cache;
VICTIM_CACHE_ROW [3:0] victim_cache_next;
VICTIM_CACHE_ROW [3:0] victim_cache_next2;
VICTIM_CACHE_ROW load_victim_cache_out_next;
VICTIM_CACHE_ROW store_victim_cache_out_next;
VICTIM_CACHE_ROW store_victim_cache_out_next2;
logic tmp2;
logic [`CACHE_LINE_BITS-1:0] line_idx2;
always_comb
begin
    victim_cache_next = victim_cache;
    load_victim_cache_out_next = 0;
    store_victim_cache_out_next = 0;
    if(load_victim_cache_in[0].valid||store_victim_cache_in[0].valid)
    begin
        if(victim_cache_full_evict)
        begin
            if(store_victim_cache_in[0].valid && load_victim_cache_in[0].valid)
            begin
                load_victim_cache_out_next = victim_cache[3];
                store_victim_cache_out_next = victim_cache[2];
                victim_cache_next[3] = victim_cache[1];
                victim_cache_next[2] = victim_cache[0];
                victim_cache_next[1] = store_victim_cache_in;
                victim_cache_next[0] = load_victim_cache_in;
            end
            else if(store_victim_cache_in[0].valid)
            begin
                store_victim_cache_out_next = victim_cache[3];
                victim_cache_next[3] = victim_cache[2];
                victim_cache_next[2] = victim_cache[1];
                victim_cache_next[1] = victim_cache[0];
                victim_cache_next[0] = store_victim_cache_in;
            end
            else
            begin
                load_victim_cache_out_next = victim_cache[3];
                victim_cache_next[3] = victim_cache[2];
                victim_cache_next[2] = victim_cache[1];
                victim_cache_next[1] = victim_cache[0];
                victim_cache_next[0] = load_victim_cache_in;
            end
            
        end
        else if(victim_cache_partial_evict)
        begin
            for(int i = 0; i < 4; i++)
            begin
                if(victim_cache[i].valid &&
                load_victim_cache_in[0].valid &&
                load_victim_cache_in[0].line_idx == victim_cache[i].line_idx)
                begin
                    load_victim_cache_out_next = victim_cache[i];
                    for(int j = 3; j >= 0; j--)
                    begin
                        if(j<=i && j>0)
                        begin
                            victim_cache_next[j] = victim_cache[j-1];
                        end
                        else if(j == 0)
                        begin
                            victim_cache_next[j] = load_victim_cache_in;
                        end
                    end 
                end
                else if(victim_cache[i].valid &&
                store_victim_cache_in[0].valid &&
                store_victim_cache_in[0].line_idx == victim_cache[i].line_idx && 
                victim_cache[i].tag == store_victim_mshr_in[0].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
                store_victim_mshr_in[0].valid && store_victim_mshr_in[0].store)
                begin
			store_victim_cache_out_next.dirty = 1;
			store_victim_cache_out_next.valid= 1;
			store_victim_cache_out_next.line_idx= victim_cache[i].line_idx;
			store_victim_cache_out_next.tag= victim_cache[i].tag;
			 case(store_victim_mshr_in[0].size)
           	     BYTE:
           	     begin
           	         casez(store_victim_mshr_in[0].address[2:0])
           	             3'd0: store_victim_cache_out_next.data = {victim_cache[i].data[63:8], store_victim_mshr_in[0].store_data[7:0]};
           	             3'd1: store_victim_cache_out_next.data = {victim_cache[i].data[63:16], store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[7:0]};
           	             3'd2: store_victim_cache_out_next.data = {victim_cache[i].data[63:24], store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[15:0]};
           	             3'd3: store_victim_cache_out_next.data = {victim_cache[i].data[63:32], store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[23:0]};
           	             3'd4: store_victim_cache_out_next.data = {victim_cache[i].data[63:40], store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[31:0]};
           	             3'd5: store_victim_cache_out_next.data = {victim_cache[i].data[63:48], store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[39:0]};
           	             3'd6: store_victim_cache_out_next.data = {victim_cache[i].data[63:56], store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[47:0]};
           	             3'd7: store_victim_cache_out_next.data = {store_victim_mshr_in[0].store_data[7:0], victim_cache[i].data[55:48]};
           	         endcase
           	     end
           	     HALF:
           	     begin
           	         casez(store_victim_mshr_in[0].address[2:1])
           	             2'd0: store_victim_cache_out_next.data = {victim_cache[i].data[63:16], store_victim_mshr_in[0].store_data[15:0]};
           	             2'd1: store_victim_cache_out_next.data = {victim_cache[i].data[63:32], store_victim_mshr_in[0].store_data[15:0], victim_cache[i].data[15:0]};
           	             2'd2: store_victim_cache_out_next.data = {victim_cache[i].data[63:48], store_victim_mshr_in[0].store_data[15:0], victim_cache[i].data[31:0]};
           	             2'd3: store_victim_cache_out_next.data = {store_victim_mshr_in[0].store_data[15:0], victim_cache[i].data[47:32]};
           	         endcase
           	     end
           	     WORD:
           	     begin
           	         casez(store_victim_mshr_in[0].address[2])
           	             1'd0: store_victim_cache_out_next.data = {victim_cache[i].data[63:32], store_victim_mshr_in[0].store_data[31:0]};
           	             1'd1: store_victim_cache_out_next.data = {store_victim_mshr_in[0].store_data[31:0], victim_cache[i].data[31:0]};
           	         endcase
           	     end
           	 endcase
                   // store_victim_cache_out_next = victim_cache[i];
                    //store_victim_cache_out_next = store_victim_mshr_in[0].store_data;
                    for(int j = 3; j >= 0; j--)
                    begin
                        if(j<=i && j>0)
                        begin
                            victim_cache_next[j] = victim_cache[j-1];
                        end
                        else if(j == 0)
                        begin
                            victim_cache_next[j] = store_victim_cache_in;
                        end
                    end 
                end
            end
        end
    end
end

always_comb
begin
    victim_cache_hit_valid_out = 0;
    victim_cache_hit_out = 0;
    for(int i = 0; i < `MSHR_SIZE; i++)
    begin
        for(int j = 0; j < 4; j++)
        begin
            if(victim_cache_hit_valid_in[i] &&
            victim_cache[j].valid &&
            victim_cache[j].tag == victim_cache_hit_in[i][`XLEN-1:`CACHE_LINE_BITS+3] &&
            victim_cache[j].line_idx == victim_cache_hit_in[i][`CACHE_LINE_BITS+3-1:3]
            )
            begin
                victim_cache_hit_valid_out[i] = 1;
                victim_cache_hit_out[i] = victim_cache[j].data;
            end
        end
    end
end

always_comb
begin
    tmp2 = 1;
    victim_cache_next2 = victim_cache_next;
    store_victim_cache_out_next2 = store_victim_cache_out_next;
    if(flush_victim)
    begin
        for(line_idx2 = 0; line_idx2 < 4; line_idx2++)
        begin
            if(tmp2 && victim_cache_next[line_idx2].valid && victim_cache_next[line_idx2].dirty)
            begin
                victim_cache_next2[line_idx2].dirty = 0;
                victim_cache_next2[line_idx2].valid = 0;
                store_victim_cache_out_next2 = victim_cache_next[line_idx2];
                tmp2 = 0;
            end
        end
    end
end



always_ff @ (posedge clock)
begin
    if(reset)
    begin
        victim_cache <= `SD 0;
        load_victim_cache_out <= `SD 0;
        store_victim_cache_out <= `SD 0;
    end
    else
    begin
        victim_cache <= `SD victim_cache_next2;
        load_victim_cache_out <= `SD load_victim_cache_out_next;
        store_victim_cache_out <= `SD store_victim_cache_out_next2;
    end
end


endmodule

