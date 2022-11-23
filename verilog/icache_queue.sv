module icache_queue(
    input clock,
    input reset,
    input enable,
    input wr_en,
    input DISP_REQ data_in,
    input [3:0] tag_from_mem,
    input [63:0] data_from_mem,
    output logic empty,
    output DISP_REQ data_out,
    output logic [63:0] data_from_queue,
    output logic data_out_valid,
    output logic already_in_queue
);

    DISP_REQ [`DISP_Q_SIZE-1:0] reqs;
    logic [$clog2(`DISP_Q_SIZE)-1:0] tail,head;

    assign empty = (head == tail) ? 1'b1 : 1'b0;

    logic already_in_queue;

    always_comb begin
        already_in_queue = 0;
        for(int i=0;i<`DISP_Q_SIZE;i++) begin
            if(data_in.addr[`CACHE_LINE_BITS-1:3] == reqs[i].addr[`CACHE_LINE_BITS-1:3] && reqs[i].valid)
                already_in_queue = 1;
        end
    end

    always_ff@(posedge clock) begin
        if(reset) begin
            head            <= 0;
            tail            <= 0;
            data_out        <= 0;
            data_out_valid  <= 0;
            data_from_queue <= 0;
            for(int i=0;i<`DISP_Q_SIZE;i++) begin
                reqs[i] <= 0;
            end
        end
        else if(enable) begin
            //If tag matches evict head
            if(tag_from_mem == reqs[head].expected_tag & ~empty) begin
                data_out         <= reqs[head];
                head             <= head + 1;
                data_out_valid   <= 1;
                data_from_queue  <= data_from_mem;
            end
            else begin
                data_out_valid <= 0;
            end
            //If wr_en write data to tail
            if(wr_en & ~already_in_queue) begin
                reqs[tail] <= data_in;
                tail <= tail + 1;
            end
        end
    end

endmodule
