`timescale 1ns/100ps

module icache(
    input clock,
    input reset,
	input enable,

    // from memory
    input [3:0]  Imem2proc_response,
    input [63:0] Imem2proc_data,
    input [3:0]  Imem2proc_tag,

    // from fetch stage
    input [`XLEN-1:0] proc2Icache_addr, //Address or PC to fetch instructions from
    input [$clog2(`N_WAY):0] proc2Icache_count, //Number of instructions that can be sent to instruction buffer based on free slots in buffer, will be PC, PC+1, ... PC+count-1

    // to memory
    output logic [1:0] proc2Imem_command,
    output logic [`XLEN-1:0] proc2Imem_addr,

    // to fetch stage
    output logic [`N_WAY-1:0][`XLEN-1:0] Icache_data_out, // value is memory[proc2Icache_addr]
    output logic [`N_WAY-1:0][`XLEN-1:0] Icache_addr_out,
    output logic [`N_WAY-1:0] Icache_valid_out,        // when this is high
    output logic [$clog2(`N_WAY):0] Icache_hit_count
    );

    ICACHE_PACKET [`CACHE_LINES-1:0] icache_data, icache_data_next;

    ICACHE_REQ [`N_WAY-1:0] proc2icache_req;
    ICACHE_REQ [`N_IC_PREFETCH-1:0] prefetch_req;
    

    logic [`N_WAY-1:0] hit; //Vector to keep track of hits
    logic [`N_IC_PREFETCH-1:0] hit_prefetch; //Vector to keep track of hits

    logic [`XLEN-1:0] addr_to_mem;
    logic [$clog2(`ICACHE_Q_SIZE)-1:0] saved_req_idx;
    logic saved_req_idx_valid;

    logic addr_in_stored_req;
    logic req_sent, req_sent_d;
    logic [`XLEN-1:0] proc2Imem_addr_d;

    //Check how many instructions actually need to be fetched
    always_comb begin
        logic [$clog2(`N_WAY):0] counter;
        counter = 0;
        for(int i=0;i<`N_WAY;i++) begin
            proc2icache_req[i].addr     = proc2Icache_addr + 4 * i;
            proc2icache_req[i].tags     = proc2icache_req[i].addr[`XLEN-1:`CACHE_LINE_BITS+3];
            proc2icache_req[i].line_idx = proc2icache_req[i].addr[`CACHE_LINE_BITS+3-1:3];
            proc2icache_req[i].valid    = (counter <= proc2Icache_count) && enable && proc2Icache_count != 0 ? 1'b1 : 1'b0;
            counter += 1;
        end
    //Check how many instructions actually need to be pre-fetched
        for(int i=0;i<`N_IC_PREFETCH;i++) begin
            prefetch_req[i].addr        = {proc2Icache_addr[`XLEN-1:3],3'b0} + 4 * proc2Icache_count + 8 * i + 8;
            prefetch_req[i].tags        = prefetch_req[i].addr[`XLEN-1:`CACHE_LINE_BITS+3];
            prefetch_req[i].line_idx    = prefetch_req[i].addr[`CACHE_LINE_BITS+3-1:3];
            prefetch_req[i].valid       = enable ? 1 : 0;
        end
        //Check if {tags,line_idx} matches address, set hit to 1 or 0
        for(int i=0;i<`N_WAY;i++) begin
            hit[i] = 0;
            for(int j=0;j<`CACHE_LINES;j++) begin
                hit[i] = ({icache_data[j].tags,j[`CACHE_LINE_BITS-1:0]} == proc2icache_req[i].addr[`XLEN-1:3]) && 
                         icache_data[j].valids ? 1'b1 : hit[i];   //Add addrs-valid to condition    
            end
        end
        //Check if {tags,line_idx} matches address, set hit_prefetch to 1 or 0
        for(int i=0;i<`N_IC_PREFETCH;i++) begin
            hit_prefetch[i] = 0;
            for(int j=0;j<`CACHE_LINES;j++) begin
                hit_prefetch[i] = ({icache_data[j].tags,j[`CACHE_LINE_BITS-1:0]} == prefetch_req[i].addr[`XLEN-1:3]) && 
                                  icache_data[j].valids ? 1'b1 : hit_prefetch[i];   //Add addrs-valid to condition    
            end
        end
    end

    //FIFO variables
    logic [$clog2(`ICACHE_Q_SIZE)-1:0] head, tail, tail_next, fifo_save_head, current_req_idx, req_ptr, req_ptr_d;
    logic queue_empty, wr_enable;
    logic fifo_empty;
    STORE_REQ [`ICACHE_Q_SIZE-1:0] fifo_data, fifo_data_next;
    logic [`XLEN-1:0] current_req_addr;
    logic [3:0] current_req_tag;
    logic addr_in_fifo;
    logic rcvd_from_mem;

    //Empty/full signal
    assign fifo_empty = req_ptr == tail_next;
    assign addr_to_mem = fifo_data_next[req_ptr].addr;

    //Writing to N_WAY FIFO
    always_comb begin
        for(int i=0;i<`ICACHE_Q_SIZE;i++) begin
            fifo_data_next[i] = fifo_data[i];
        end
        tail_next = tail;
        for(int i=0;i<`N_WAY;i++) begin
            addr_in_fifo = 0;
            for(int k=0;k<`ICACHE_Q_SIZE;k++) begin
                addr_in_fifo = proc2icache_req[i].addr[`XLEN-1:3] == fifo_data_next[k].addr[`XLEN-1:3] &&
                                      proc2icache_req[i].valid && fifo_data_next[k].valid ? 1 : addr_in_fifo;
                //$display("match:%b, i:%d, k:%d, addr:%h, faddr:%h, addr.v:%b, faddr.v:%b",addr_in_fifo,i,k,proc2icache_req[i].addr,fifo_data_next[k].addr,proc2icache_req[i].valid,fifo_data_next[k].valid);
            end
            if(~hit[i] && proc2icache_req[i].valid && ~addr_in_fifo) begin
                //$display("Add i:%d, ireq:%h, ival:%b, amatch %b", i, proc2icache_req[i].addr, proc2icache_req[i].valid, addr_in_fifo);
                fifo_data_next[tail_next].addr = proc2icache_req[i].addr;
                fifo_data_next[tail_next].valid = 1;
                tail_next = tail_next + 1;
            end
            //else
                //$display("Cant add i:%d, ireq:%h, amatch %b", i, proc2icache_req[i].addr, addr_in_fifo);
        end
        //Handle pre-fetching
        for(int i=0;i<`N_IC_PREFETCH;i++) begin
            addr_in_fifo = 0;
            for(int k=0;k<`ICACHE_Q_SIZE;k++) begin
                addr_in_fifo = prefetch_req[i].addr[`XLEN-1:3] == fifo_data_next[k].addr[`XLEN-1:3] &&
                                      prefetch_req[i].valid && fifo_data_next[k].valid ? 1 : addr_in_fifo;
                //$display("match:%b, i:%d, k:%d, addr:%h, faddr:%h, addr.v:%b, faddr.v:%b",addr_in_fifo,i,k,prefetch_req[i].addr,fifo_data_next[k].addr,prefetch_req[i].valid,fifo_data_next[k].valid);
            end
            if(~hit_prefetch[i] && prefetch_req[i].valid && ~addr_in_fifo) begin
                //$display("Pre Add i:%d, ireq:%h, ival:%b, amatch %b", i, prefetch_req[i].addr, prefetch_req[i].valid, addr_in_fifo);
                fifo_data_next[tail_next].addr = prefetch_req[i].addr;
                fifo_data_next[tail_next].valid = 1;
                tail_next = tail_next + 1;
            end
            //else
                //$display("Pre Cant add i:%d, ireq:%h, amatch %b", i, prefetch_req[i].addr, addr_in_fifo);
        end
        if(~fifo_empty) begin
            fifo_save_head = head;
        end
    end

    //Send requests to memory whose address is taken from head of FIFO
    always_ff@(posedge clock) begin
        if(reset) begin
            tail <= `SD 0;
            head <= `SD 0;
            fifo_data <= `SD 0;
            proc2Imem_command <= `SD BUS_NONE;
            proc2Imem_addr    <= `SD 32'hffffffff;
            req_sent          <= `SD 0;
            wr_enable         <= `SD 0;
            req_ptr           <= `SD 0;
        end
        else if(enable) begin
            for(int i=0;i<`ICACHE_Q_SIZE;i++) begin
                fifo_data[i].addr <= `SD fifo_data_next[i].addr;
                fifo_data[i].valid <= `SD rcvd_from_mem && i[$clog2(`ICACHE_Q_SIZE)-1:0] == head ? 0 : fifo_data_next[i].valid;
            end     
            req_sent_d       <= `SD req_sent;
            current_req_addr <= `SD fifo_data_next[req_ptr].addr;
            current_req_idx  <= `SD req_ptr;
            if(~fifo_empty) begin
                //Send request to memory
                proc2Imem_command <= `SD BUS_LOAD;
                proc2Imem_addr    <= `SD {fifo_data_next[req_ptr].addr[`XLEN-1:3],3'b0};
                req_sent          <= `SD 1;
                wr_enable         <= `SD 1;
                req_ptr           <= `SD req_ptr + 1;
            end
            else begin
                //Send request to memory
                proc2Imem_command <= `SD BUS_NONE;
                proc2Imem_addr    <= `SD proc2Imem_addr;
                req_sent          <= `SD 0;
                wr_enable         <= `SD 0;
                req_ptr           <= `SD req_ptr;
            end
            if(rcvd_from_mem) begin
                head <= `SD head + 1;
            end
            else begin
                head <= `SD head;
            end
            tail             <= `SD tail_next;
            proc2Imem_addr_d <= `SD proc2Imem_addr;
            req_ptr_d        <= req_ptr;
        end
    end

    //Queue to keep track of already sent requests
    logic [`ICACHE_Q2_SIZE-1:0][`XLEN-1:0] queue_addr, queue_addr_next;
    logic [`ICACHE_Q2_SIZE-1:0][3:0] queue_expected_tag, queue_expected_tag_next;
    logic [$clog2(`ICACHE_Q_SIZE)-1:0] queue_idx, queue_idx_next;
    logic [$clog2(`ICACHE_Q2_SIZE)-1:0] q_head, q_tail, q_tail_next;
    
    logic [`CACHE_LINE_BITS-1:0] line_to_evict;

    //Add instruction already sent to queue at tail. Check if tag matches for head
    always_ff@(posedge clock) begin
        if(reset) begin
            q_head <= `SD 0;
            q_tail <= `SD 0;
            for(int i=0; i<`ICACHE_Q2_SIZE;i++) begin
                queue_addr[i]         <= `SD 0;
                queue_expected_tag[i] <= `SD 0;
            end
            rcvd_from_mem <= `SD 0;
        end
        else if(enable) begin
            if(req_sent && (proc2Imem_addr != proc2Imem_addr_d) && proc2Imem_addr != 32'hffffffff) begin
                queue_addr[q_tail]         <= `SD fifo_data_next[req_ptr_d].addr;
                queue_expected_tag[q_tail] <= `SD Imem2proc_response;
                q_tail                     <= `SD q_tail + 1;
            end
            else begin
                for(int i=0;i<`ICACHE_Q2_SIZE;i++) begin
                    queue_addr[i]         <= `SD queue_addr[i];
                    queue_expected_tag[i] <= `SD queue_expected_tag[i];
                end
            end
            if(Imem2proc_tag == queue_expected_tag[q_head] && Imem2proc_tag != 0) begin
                q_head        <= `SD q_head + 1;
                rcvd_from_mem <= `SD 1;
            end
            else begin
                q_head        <= `SD q_head;
                rcvd_from_mem <= `SD 0;
            end
        end
    end

    assign line_to_evict = queue_addr[q_head][`CACHE_LINE_BITS+2:3];
    //If tag matches with head of queue evict cache line and store new
    always_ff@(posedge clock) begin
        if(reset) begin
            for(int i=0;i<`CACHE_LINES;i++) begin
                icache_data[i].valids <= `SD 0;
            end
        end
        else if(enable) begin
            if(Imem2proc_tag == queue_expected_tag[q_head] && Imem2proc_tag != 0) begin
                icache_data[line_to_evict].data   <= `SD Imem2proc_data;
                icache_data[line_to_evict].tags   <= `SD queue_addr[q_head][`XLEN-1:`CACHE_LINE_BITS+3];
                icache_data[line_to_evict].valids <= `SD 1;
            end
        end
    end

    //Sequential logic to output values from cache in case of hits
    always_ff@(posedge clock) begin
        if(reset) begin
			for(int i=0;i<`N_WAY;i++) begin
                Icache_data_out[i]  <= 0;
                Icache_valid_out[i] <= 0;
                Icache_addr_out[i]  <= 0;
            end
        end
        else if(enable) begin
            for(int i=0;i<`N_WAY;i++) begin
                //$display("hit[%h]: %b",i,hit[i]);
                if(hit[i]) begin
                    Icache_data_out[i]  <= `SD ~proc2icache_req[i].addr[2] ? icache_data[proc2icache_req[i].line_idx].data[31:0] : icache_data[proc2icache_req[i].line_idx].data[63:32];
                                       		//icache_data[0].data : icache_data[0].data;
					Icache_valid_out[i] <= `SD proc2icache_req[i].valid;
                    Icache_addr_out[i]  <= `SD proc2icache_req[i].addr;
                    //$display("DOUT[%h]: %h, addr:%h, icache_data[0]: %h",i,Icache_data_out[i],proc2icache_req[i].addr,icache_data[0].data[31:0]);
                end
                else begin
                    Icache_valid_out[i] <= `SD 0;
                    Icache_data_out[i]  <= `SD 0;
                end
            end
        end
    end
    
endmodule

