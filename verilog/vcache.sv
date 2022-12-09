module victim_cache(
    input flush_victim,
    input clock, 
    input reset,
    input MSHR_ROW [`N_WR_PORTS-1:0] store_victim_mshr_in,
   // input logic [`MSHR_SIZE-1:0][`XLEN-1:0] victim_cache_hit_in,
    input MSHR_ROW [`MSHR_SIZE-1:0]victim_cache_hit_in,
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
        for(int j = 0; j < 6; j++)
        begin
	if (j<4) begin
            if(victim_cache_hit_valid_in[i] &&
            victim_cache[j].valid &&
            victim_cache[j].tag == victim_cache_hit_in[i].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
            victim_cache[j].line_idx == victim_cache_hit_in[i].address[`CACHE_LINE_BITS+3-1:3]
            )
            begin
                victim_cache_hit_valid_out[i] = 1;
                victim_cache_hit_out[i] = victim_cache[j].data;
            end
	end else if (j==4) begin
		if (victim_cache_hit_valid_in[i] &&
            load_victim_cache_out[0].valid &&
            load_victim_cache_out[0].tag == victim_cache_hit_in[i].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
            load_victim_cache_out[0].line_idx == victim_cache_hit_in[i].address[`CACHE_LINE_BITS+3-1:3] &&
	    victim_cache_hit_in[i].load
		)
            begin
                victim_cache_hit_valid_out[i] = 1;
                victim_cache_hit_out[i] = load_victim_cache_out[0].data;
            end
	end else begin
		if (victim_cache_hit_valid_in[i] &&
            store_victim_cache_out[0].valid &&
            store_victim_cache_out[0].tag == victim_cache_hit_in[i].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
            store_victim_cache_out[0].line_idx == victim_cache_hit_in[i].address[`CACHE_LINE_BITS+3-1:3] &&
		victim_cache_hit_in[i].load
		)
            begin
                victim_cache_hit_valid_out[i] = 1;
                victim_cache_hit_out[i] = store_victim_cache_out[0].data;
            end
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

