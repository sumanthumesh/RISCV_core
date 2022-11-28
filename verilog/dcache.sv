// module dcache(
//     input clock,
//     input reset,
//     input dcache_enable,
//     input STORE_PACKET_RET [`N_WR_PORTS-1:0] store_packet_in,
//     input LOAD_PACKET_RET [`N_RD_PORTS-1:0] load_packet_in,
//     input  [3:0] mem2dcache_response,// 0 = can't accept, other=tag of transaction
// 	input [63:0] mem2dcache_data,    // data resulting from a load
// 	input  [3:0] mem2dcache_tag,     // 0 = no value, other=tag of transaction
//     input flush,
//     output LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out,
//     output logic [$clog2(`N_WR_PORTS):0] store_count,
//     output logic icache_enable,
//     output logic [`XLEN-1:0] dcache2mem_addr,    // address for current command
// 	output logic [63:0] dcache2mem_data,    // address for current command
// 	output logic [1:0]   dcache2mem_command // `BUS_NONE `BUS_LOAD or `BUS_STORE
// );

// logic [`CACHE_LINE_BITS-1:0] line_idx;
// logic [`CACHE_LINE_BITS-1:0] line_idx1;
// logic [`N_RD_PORTS-1:0] load_victim_hit;
// VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_hit_data;
// LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next;
// logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx;
// LOAD_PACKET_EX_STAGE [`N_RD_PORTS-1:0] load_packet_out_next2;
// logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx2;
// logic [$clog2(`N_RD_PORTS):0] load_packet_out_idx1;
// VICTIM_CACHE_ROW [`N_RD_PORTS:0] load_victim_cache_in;
// logic [$clog2(`N_RD_PORTS+1):0] load_victim_cache_in_idx;
// VICTIM_CACHE_ROW [`N_RD_PORTS:0] load_victim_cache_in1;
// logic [$clog2(`N_RD_PORTS+1):0] load_victim_cache_in_idx1;
// VICTIM_CACHE_ROW [`N_RD_PORTS+4:0] load_victim_cache_out;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_next;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_next2;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_next3;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_next4;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_next5;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_wire;
// MSHR_ROW [`MSHR_SIZE-1:0] mshr_wire2;
// logic [$clog2(`MSHR_SIZE):0] mshr_idx;
// logic [$clog2(`MSHR_SIZE):0] mshr_idx_next;

// DCACHE_ROW [`CACHE_LINES-1:0] dcache;
// DCACHE_ROW [`CACHE_LINES-1:0] dcache_next;
// DCACHE_ROW [`CACHE_LINES-1:0] dcache_wire;

// logic tmp;

// logic  [3:0] latched_mem2dcache_response;

// victim_cache vc0(
//     .clock(clock),
//     .reset(reset),
//     .load_packet_in(load_packet_in),
//     .flush(flush),
//     .load_victim_cache_in(load_victim_cache_in1),
//     .load_victim_hit(load_victim_hit),
//     .load_victim_hit_data(load_victim_hit_data),
//     .load_victim_cache_out_wire(load_victim_cache_out)
// );


// always_comb 
// begin
//     load_victim_cache_in_idx = 0;
//     load_victim_cache_in = 0;
//     dcache_next = dcache;
//     mshr_next = mshr;
//     if(mshr[mshr_idx].valid && mshr[mshr_idx].dispatched && !mshr[mshr_idx].expected_tag_assigned)
//     begin
//         mshr_next[mshr_idx].expected_tag = latched_mem2dcache_response;
//         mshr_next[mshr_idx].expected_tag_assigned = 1;
//     end

//     for(int i = 0; i < `MSHR_SIZE; i++)
//     begin
//         if(mshr_next[i].valid && mshr_next[i].dispatched && mshr_next[i].ready && mshr_next[i].load)
//         begin
//             line_idx = mshr_next[i].address[`CACHE_LINE_BITS+3-1:3];

//             if(dcache[line_idx].valid)
//             begin
//                 load_victim_cache_in[load_victim_cache_in_idx].valid = dcache[line_idx].valid;
//                 load_victim_cache_in[load_victim_cache_in_idx].tag = dcache[line_idx].tag;
//                 load_victim_cache_in[load_victim_cache_in_idx].data = dcache[line_idx].data;
//                 load_victim_cache_in[load_victim_cache_in_idx].dirty = dcache[line_idx].dirty;
//                 load_victim_cache_in[load_victim_cache_in_idx].line_idx = line_idx;
//                 load_victim_cache_in_idx = load_victim_cache_in_idx + 1;
//             end
//             dcache_next[line_idx].data = mshr_next[i].data;
//             dcache_next[line_idx].tag = mshr_next[i].address[`XLEN-1:`CACHE_LINE_BITS+3];
//             dcache_next[line_idx].valid = 1;
//             dcache_next[line_idx].dirty = 0;

//             mshr_next[i].valid = 0;
//         end
//     end

// end

// always_comb
// begin
//     mshr_next4 = mshr_next;
//     // Logic for setting mshr[i].ready
//     for(int i = 0; i < `MSHR_SIZE; i++)
//     begin
//         if(mshr_next4[i].valid && mshr_next4[i].dispatched && !mshr_next4[i].ready && mshr_next4[i].load)
//         begin
//             if(mshr_next4[i].expected_tag_assigned && mshr_next4[i].expected_tag == mem2dcache_tag)
//             begin
//                 mshr_next4[i].ready = 1;
//                 mshr_next4[i].data = mem2dcache_data;
//                 for(int j = 0; j < `MSHR_SIZE; j++)
//                 begin
//                     if(mshr_next4[j].valid && mshr_next4[j].dispatched && !mshr_next4[j].ready && mshr_next4[j].load)
//                     begin
//                         if(mshr_next4[j].address[`XLEN-1:3] == mshr_next4[i].address[`XLEN-1:3])
//                         begin
//                             mshr_next4[j].ready = 1;
//                             mshr_next4[j].data = mem2dcache_data;
//                         end
//                     end
//                 end
//                 break;
//             end
//         end
//     end

// end


// always_comb
// begin
//     mshr_next3 = mshr_next4;
//     mshr_idx_next = 0;
//     tmp = 0;
//     // Logic for setting mshr[i].dispatched
//     for(int i = 0; i < `MSHR_SIZE; i++)
//     begin
//         if(mshr_next3[i].valid && !mshr_next3[i].dispatched && mshr_next3[i].load)
//         begin
//             mshr_idx_next = i;
//             mshr_next3[i].dispatched = 1;
//             for(int j = 0; j < `MSHR_SIZE;j++)
//             begin
//                 if(mshr_next3[j].valid && !mshr_next3[j].dispatched && mshr_next3[j].load)
//                 begin
//                     if(mshr_next4[j].address[`XLEN-1:3] == mshr_next4[i].address[`XLEN-1:3])
//                         mshr_next3[j].dispatched = 1;
//                 end
//             end
//             dcache2mem_addr = {mshr_next[i].address[`XLEN-1:3], 3'b0};
//             dcache2mem_command = BUS_LOAD;
//             tmp = 1;
//             break;
//         end
//     end
//     if(!tmp)
//         dcache2mem_command = BUS_NONE;
// end

// always_comb
// begin
//     dcache_wire = dcache_next;
//     load_victim_cache_in1 = load_victim_cache_in;
//     load_victim_cache_in_idx1 = load_victim_cache_in_idx;
//     load_packet_out_idx1 = 0;
//     mshr_next2 = mshr_next3;
//     for(int i = 0; i < `N_RD_PORTS; i++)
//     begin
//         line_idx1 = load_packet_in[i].address[`CACHE_LINE_BITS+3-1:3];
//         if(load_packet_in[i].valid &&
//         dcache_next[line_idx1].valid &&
//         dcache_next[line_idx1].tag == load_packet_in[i].address[`XLEN-1:`CACHE_LINE_BITS+3])
//         begin
//             // This means that it is a load l1 hit.
//             casez(load_packet_in[i].size)
//                 BYTE: 
//                 begin
//                     casez(load_packet_in[i].address[2:0])
//                         3'd0: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[7:0]};
//                         3'd1: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[15:8]};
//                         3'd2: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[23:16]};
//                         3'd3: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[31:24]};
//                         3'd4: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[39:32]};
//                         3'd5: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[47:40]};
//                         3'd6: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[55:48]};
//                         3'd7: load_packet_out_next[load_packet_out_idx1].data = {24'b0, dcache_next[line_idx1].data[63:56]};
//                         default: load_packet_out_next[load_packet_out_idx1].data = 0;
//                     endcase
//                 end
//                 HALF:
//                 begin
//                     casez(load_packet_in[i].address[2:0])
//                         3'd0: load_packet_out_next[load_packet_out_idx1].data = {16'b0, dcache_next[line_idx1].data[15:0]};
//                         3'd2: load_packet_out_next[load_packet_out_idx1].data = {16'b0, dcache_next[line_idx1].data[31:16]};
//                         3'd4: load_packet_out_next[load_packet_out_idx1].data = {16'b0, dcache_next[line_idx1].data[49:32]};
//                         3'd6: load_packet_out_next[load_packet_out_idx1].data = {16'b0, dcache_next[line_idx1].data[63:48]};
//                         default: load_packet_out_next[load_packet_out_idx1].data = 0;
//                     endcase
//                 end
//                 WORD:
//                 begin
//                     casez(load_packet_in[i].address[2:0])
//                         3'd0:
//                             load_packet_out_next[load_packet_out_idx1].data = dcache_next[line_idx1].data[31:0];
//                         3'd4: load_packet_out_next[load_packet_out_idx1].data = dcache_next[line_idx1].data[63:32];
//                         default: load_packet_out_next[load_packet_out_idx1].data = 0;
//                     endcase
//                 end
//                 default: load_packet_out_next[load_packet_out_idx1].data = 0;
//             endcase
//             load_packet_out_next[load_packet_out_idx1].dest_tag = load_packet_in[i].dest_tag;
//             load_packet_out_next[load_packet_out_idx1].valid = 1;
//             load_packet_out_idx1 = load_packet_out_idx1 + 1;
//         end
//         else if(load_victim_hit[i])
//         begin
//             // This means that it is a load victim cache hit.
//             casez(load_packet_in[i].size)
//                 BYTE: 
//                 begin
//                     casez(load_packet_in[i].address[2:0])
//                         3'd0: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[7:0]};
//                         3'd1: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[15:8]};
//                         3'd2: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[23:16]};
//                         3'd3: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[31:24]};
//                         3'd4: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[39:32]};
//                         3'd5: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[47:40]};
//                         3'd6: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[55:48]};
//                         3'd7: load_packet_out_next[load_packet_out_idx1].data = {24'b0, load_victim_hit_data[i].data[63:56]};
//                         default: load_packet_out_next[load_packet_out_idx1].data = 0;
//                     endcase
//                 end
//                 HALF:
//                 begin
//                     casez(load_packet_in[i].address[2:0])
//                         3'd0: load_packet_out_next[load_packet_out_idx1].data = {16'b0, load_victim_hit_data[i].data[15:0]};
//                         3'd2: load_packet_out_next[load_packet_out_idx1].data = {16'b0, load_victim_hit_data[i].data[31:16]};
//                         3'd4: load_packet_out_next[load_packet_out_idx1].data = {16'b0, load_victim_hit_data[i].data[49:32]};
//                         3'd6: load_packet_out_next[load_packet_out_idx1].data = {16'b0, load_victim_hit_data[i].data[63:48]};
//                         default: load_packet_out_next[load_packet_out_idx1].data = 0;
//                     endcase
//                 end
//                 WORD:
//                 begin
//                     casez(load_packet_in[i].address[2:0])
//                         3'd0: load_packet_out_next[load_packet_out_idx1].data = load_victim_hit_data[i].data[31:0];
//                         3'd4: load_packet_out_next[load_packet_out_idx1].data = load_victim_hit_data[i].data[63:32];
//                         default: load_packet_out_next[load_packet_out_idx1].data = 0;
//                     endcase
//                 end
//                 default: load_packet_out_next[load_packet_out_idx1].data = 0;
//             endcase

//             load_packet_out_next[load_packet_out_idx1].dest_tag = load_packet_in[i].dest_tag;
//             load_packet_out_next[load_packet_out_idx1].valid = 1;
//             load_packet_out_idx1 = load_packet_out_idx1 + 1;
//             // In this case, the data will also have to be exchanged between the L1 cache and the victim cache.
            
//             load_victim_cache_in1[load_victim_cache_in_idx1].valid = dcache_next[line_idx1].valid;
//             load_victim_cache_in1[load_victim_cache_in_idx1].tag = dcache_next[line_idx1].tag;
//             load_victim_cache_in1[load_victim_cache_in_idx1].data = dcache_next[line_idx1].data;
//             load_victim_cache_in1[load_victim_cache_in_idx1].dirty = dcache_next[line_idx1].dirty;
//             load_victim_cache_in1[load_victim_cache_in_idx1].line_idx = line_idx1;
//             load_victim_cache_in_idx1 = load_victim_cache_in_idx1 + 1;

//             dcache_wire[load_victim_hit_data[i].line_idx].data = load_victim_hit_data[i].data;
//             dcache_wire[load_victim_hit_data[i].line_idx].dirty = load_victim_hit_data[i].dirty; 
//             dcache_wire[load_victim_hit_data[i].line_idx].valid = load_victim_hit_data[i].valid;
//             dcache_wire[load_victim_hit_data[i].line_idx].tag = load_victim_hit_data[i].tag;
//         end
//         else if(load_packet_in[i].valid)
//         begin
//             // This means that it was neither found in the L1 cache nor in the victim cache.
//             // Here we need to update the MSHR.
//             for(int j = 0; j < `MSHR_SIZE; j++)
//             begin
//                 if(mshr_next2[j].tail)
//                 begin
//                     mshr_next2[j].valid = 1;
//                     mshr_next2[j].dispatched = 0;
//                     mshr_next2[j].ready = 0;
//                     mshr_next2[j].data = 0;
//                     mshr_next2[j].address = load_packet_in[i].address;
//                     mshr_next2[j].dest_tag = load_packet_in[i].dest_tag;
//                     mshr_next2[j].load = 1;
//                     mshr_next2[j].store = 0;
//                     mshr_next2[(j+1)%`MSHR_SIZE].tail = 1;
//                     mshr_next2[j].tail = 0;
//                     mshr_next2[j].expected_tag = 0;
//                     mshr_next2[j].expected_tag_assigned = 0;
//                     mshr_next2[j].size = load_packet_in[i].size;
//                     break;
//                 end
//             end
//         end
//     end

//     for(int i = 0; i < `N_RD_PORTS+1; i++)
//     begin
//         if(i >= load_victim_cache_in_idx1)
//             load_victim_cache_in1[load_victim_cache_in_idx1].valid = 0;
//     end
// end

// always_comb
// begin
//     load_packet_out_next2 = load_packet_out_next;
//     load_packet_out_idx2 = load_packet_out_idx1;
//     mshr_next5 = mshr_next2;
//     for(int i = 0; i < `MSHR_SIZE; i++)
//     begin
//         if(mshr_next5[i].head && mshr_next5[i].dispatched && mshr_next5[i].ready && mshr_next5[i].load && load_packet_out_idx2 < `N_RD_PORTS)
//         begin
//             casez(mshr_next5[i].size)
//                 BYTE:
//                 begin
//                     casez(mshr_next5[i].address[2:0])
//                         3'd0: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[7:0]};
//                         3'd1: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[15:8]};
//                         3'd2: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[23:16]};
//                         3'd3: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[31:24]};
//                         3'd4: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[39:32]};
//                         3'd5: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[47:40]};
//                         3'd6: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[55:48]};
//                         3'd7: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next5[i].data[63:56]};
//                         default: load_packet_out_next2[load_packet_out_idx2].data = 0;
//                     endcase
//                 end
//                 HALF:
//                 begin
//                     casez(mshr_next5[i].address[2:0])
//                         3'd0: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next5[i].data[15:0]};
//                         3'd2: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next5[i].data[31:16]};
//                         3'd4: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next5[i].data[47:32]};
//                         3'd6: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next5[i].data[63:48]};
//                         default: load_packet_out_next2[load_packet_out_idx2].data = 0;
//                     endcase
//                 end
//                 WORD:
//                 begin
//                     casez(mshr_next5[i].address[2:0])
//                         3'd0: load_packet_out_next2[load_packet_out_idx2].data = mshr_next5[i].data[31:0];
//                         3'd4: load_packet_out_next2[load_packet_out_idx2].data = mshr_next5[i].data[63:32];
//                         default: load_packet_out_next2[load_packet_out_idx2].data = 0;
//                     endcase
//                 end
//                 default: load_packet_out_next2[load_packet_out_idx2].data = 0;
//             endcase
//             load_packet_out_next2[load_packet_out_idx2].dest_tag = mshr_next5[i].dest_tag;
//             load_packet_out_next2[load_packet_out_idx2].valid = 1;
//             load_packet_out_idx2 = load_packet_out_idx2 + 1;

//             mshr_next5[i].head = 0;
//             mshr_next5[(i+1)%`MSHR_SIZE].head = 1;

//             break;
//         end
//     end


//     for(int i = 0; i < `N_RD_PORTS; i++)
//     begin
//         if(i >= load_packet_out_idx2)
//             load_packet_out_next2[i] = 0;
//     end
// end
// always_comb
// begin
//     mshr_wire = mshr_next5;
//     for(int i = 0; i < `N_RD_PORTS+4; i++)
//     begin
//         if(load_victim_cache_out[i].valid && load_victim_cache_out[i].dirty)
//         begin
//             for(int j = 0; j < `MSHR_SIZE; j++)
//             begin
//                 if(mshr_wire[j].tail)
//                 begin
//                     mshr_wire[j].valid = 1;
//                     mshr_wire[j].dispatched = 0;
//                     mshr_wire[j].ready = 0;
//                     mshr_wire[j].data = load_victim_cache_out[i].data;
//                     mshr_wire[j].address = {16'b0, load_victim_cache_out[i].tag, load_victim_cache_out[i].line_idx, 3'b0};
//                     mshr_wire[j].dest_tag = 0;
//                     mshr_wire[j].load = 0;
//                     mshr_wire[j].store = 1;
//                     mshr_wire[(j+1)%`MSHR_SIZE].tail = 1;
//                     mshr_wire[j].tail = 0;
//                     mshr_wire[j].expected_tag = 0;
//                     mshr_wire[j].expected_tag_assigned = 0;
//                     mshr_wire[j].size = DOUBLE;
//                     break;
//                 end
//             end
//         end
//     end
// end

// always_comb
// begin
//     mshr_wire2 = mshr_wire;
//     if(flush)
//     begin
//         for(int i = 0; i < `CACHE_LINES; i++)
//         begin
//             if(dcache_wire[i].valid && dcache_wire[i].dirty)
//             begin
//                 for(int j = 0; j < `MSHR_SIZE; j++)
//                 begin
//                     if(mshr_wire2[j].tail)
//                     begin
//                         mshr_wire2[j].valid = 1;
//                         mshr_wire2[j].dispatched = 0;
//                         mshr_wire2[j].ready = 0;
//                         mshr_wire2[j].data = dcache_wire[i].data;
//                         mshr_wire2[j].address = {16'b0, dcache_wire[i].tag, i, 3'b0};
//                         mshr_wire2[j].dest_tag = 0;
//                         mshr_wire2[j].load = 0;
//                         mshr_wire2[j].store = 1;
//                         mshr_wire2[(j+1)%`MSHR_SIZE].tail = 1;
//                         mshr_wire2[j].tail = 0;
//                         mshr_wire2[j].expected_tag = 0;
//                         mshr_wire2[j].expected_tag_assigned = 0;
//                         mshr_wire2[j].size = DOUBLE;
//                         break;
//                     end
//                 end
//             end
//         end
//     end
// end

// always_ff @ (posedge clock)
// begin
//     if(reset)
//     begin
//         dcache <= `SD 0;
//         mshr_idx <= `SD 0;
//         latched_mem2dcache_response <= `SD 0;
//         for(int i = 0; i < `MSHR_SIZE; i++)
//         begin
//             mshr[i].load <= `SD 1'b0;
//             mshr[i].store <= `SD 1'b0;
//             mshr[i].dispatched <= `SD 1'b0;
//             mshr[i].valid <= `SD 1'b0;
//             mshr[i].ready <= `SD 0;
//             mshr[i].data <= `SD 0;
//             mshr[i].address <= `SD 0;
//             mshr[i].expected_tag <= `SD 0;
//             mshr[i].expected_tag_assigned <= `SD 0;
//             mshr[i].dest_tag <= `SD 0;
//             if(i == 0)
//                 mshr[i].head <= `SD 1'b1;
//             else
//                 mshr[i].head <= `SD 1'b0;
//             if(i == 0)
//                 mshr[i].tail <= `SD 1'b1;
//             else 
//                 mshr[i].tail <= `SD 1'b0;
//         end
//         load_packet_out <= `SD 0;
//     end
//     else
//     begin
//         dcache <= `SD dcache_wire;
//         mshr <= `SD mshr_wire2;
//         mshr_idx <= `SD mshr_idx_next;
//         latched_mem2dcache_response <= `SD mem2dcache_response;
//         load_packet_out <= `SD load_packet_out_next2;
//     end
// end

// endmodule












// module victim_cache(
//     input clock,
//     input reset,
//     input LOAD_PACKET_RET [`N_RD_PORTS-1:0] load_packet_in, // this data is current load data
//     input VICTIM_CACHE_ROW [`N_RD_PORTS:0] load_victim_cache_in, // will contain rows to be added to the end of the queue
//     input flush,
//     output logic [`N_RD_PORTS-1:0] load_victim_hit, // boolean to signal whether victim hit or miss
//     output VICTIM_CACHE_ROW [`N_RD_PORTS-1:0] load_victim_hit_data, // will contain data for a victim hit
//     output VICTIM_CACHE_ROW [`N_RD_PORTS+4:0] load_victim_cache_out_wire //will contain rows flushed out of the victim cache
// );

// VICTIM_CACHE_ROW [3:0] victim_cache;
// VICTIM_CACHE_ROW [3:0] victim_cache_next;
// VICTIM_CACHE_ROW [3:0] victim_cache_wire;
// VICTIM_CACHE_ROW [3:0] victim_cache_wire2;
// logic [$clog2(`N_RD_PORTS+1):0] load_victim_cache_in_valid_counter;
// logic [2:0] victim_cache_not_valid_counter;
// logic [2:0] victim_cache_clutter_counter;
// logic [$clog2(`N_RD_PORTS+1):0] flush_out_counter;
// logic [$clog2(`N_RD_PORTS+1):0] flush_out_counter1;
// VICTIM_CACHE_ROW [`N_RD_PORTS+4:0] load_victim_cache_out_next;

// always_comb
// begin
//     load_victim_hit = 0;
//     load_victim_hit_data = 0;
//     victim_cache_next = victim_cache;
//     for(int i = 0; i < `N_RD_PORTS; i++)
//     begin
//         for(int j = 0; j < 4; j++)
//         begin
//             if(load_packet_in[i].valid &&
//             victim_cache[j].valid &&
//             victim_cache[j].line_idx == load_packet_in[i].address[`CACHE_LINE_BITS+3-1:3] &&
//             victim_cache[j].tag == load_packet_in[i].address[`XLEN-1:`CACHE_LINE_BITS+3])
//             begin
//                 load_victim_hit[i] = 1;
//                 load_victim_hit_data[i].data = victim_cache[j].data;
//                 load_victim_hit_data[i].tag = victim_cache[i].tag;
//                 load_victim_hit_data[i].valid = 1;
//                 load_victim_hit_data[i].dirty = victim_cache[i].dirty;
//                 load_victim_hit_data[i].line_idx = victim_cache[i].line_idx;

//                 victim_cache_next[i].valid = 0;
//             end
//         end
//     end
// end


// always_comb
// begin
//     victim_cache_not_valid_counter = 0;
//     load_victim_cache_in_valid_counter = 0;
//     flush_out_counter = 0; 
//     victim_cache_wire = victim_cache_next;
//     victim_cache_clutter_counter = 0;
//     for(int i = 0; i <= `N_RD_PORTS; i++)
//     begin
//         if(load_victim_cache_in[i].valid)
//             load_victim_cache_in_valid_counter = load_victim_cache_in_valid_counter + 1;
//     end

//     for(int i = 0; i < 4; i++)
//     begin
//         if(victim_cache_next[i].valid)
//             victim_cache_not_valid_counter = victim_cache_not_valid_counter + 1;
//     end

//     if(load_victim_cache_in_valid_counter > victim_cache_not_valid_counter)
//     begin
//         for(int i = 3; i >= 0; i--)
//         begin
//             if(victim_cache_next[i].valid)
//             begin
//                 if(flush_out_counter < (load_victim_cache_in_valid_counter - victim_cache_not_valid_counter))
//                 begin
//                     load_victim_cache_out_next[flush_out_counter] = victim_cache_next[i];
//                     victim_cache_wire[i].valid = 0;
//                     flush_out_counter = flush_out_counter + 1;
//                 end
//             end
//         end
//     end
    
//     for(int i = 0; i < 4; i++)
//     begin
//         if(victim_cache_wire[i].valid)
//         begin
//             victim_cache_wire[victim_cache_clutter_counter] = victim_cache_wire[i];
//             victim_cache_clutter_counter = victim_cache_clutter_counter + 1;
//         end
//     end

//     for(int i = 3; i >= 0; i--)
//     begin
//         if(victim_cache_wire[i].valid)
//         begin
//             victim_cache_wire[i+load_victim_cache_in_valid_counter] = victim_cache_wire[i];
//         end
//     end
//     // We need to flush out a total of (load_victim_cache_in_valid_counter - victim_cache_not_valid_counter) instructions to the MSHR

//     for(int i = 0; i <= `N_RD_PORTS+1; i++)
//     begin
//         victim_cache_wire[i] = load_victim_cache_in;
//     end

    
// end

// always_comb
// begin
//     load_victim_cache_out_wire = load_victim_cache_out_next;
//     flush_out_counter1 = flush_out_counter;
//     victim_cache_wire2 = victim_cache_wire;
//     if(flush)
//     begin
//         for(int i = 0;i < 4; i++)
//         begin
//             if(victim_cache_wire2[i].valid && victim_cache_wire2[i].dirty)
//             begin
//                 load_victim_cache_out_wire[flush_out_counter1] = victim_cache_wire2[i];
//                 victim_cache_wire2[i].valid = 0;
//                 flush_out_counter1 = flush_out_counter1 + 1;
//             end 
//         end
//     end

//     for(int i = 0; i < 4; i++)
//     begin
//         if(i >= flush_out_counter1)
//             load_victim_cache_out_wire[i].valid = 0;
//     end
// end

// always_ff @ (posedge clock)
// begin
//     if(reset)
//         victim_cache <= `SD 0;
//     else
//         victim_cache <= `SD victim_cache_wire2;
// end



// endmodule








module dcache(
    input clock,
    input reset,
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
    output logic victim_cache_full_evict_next,
    output logic victim_cache_partial_evict_next,
    output logic [`XLEN-1:0] dcache2mem_addr,
    output logic [1:0] dcache2mem_command,
    output logic [63:0] dcache2mem_data,
    input  logic [3:0] mem2dcache_response,
	input logic [63:0] mem2dcache_data,
	input  logic [3:0] mem2dcache_tag
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
logic [`CACHE_LINE_BITS-1:0] line_idx;
logic [`CACHE_LINE_BITS-1:0] line_idx1;
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
logic [$clog2(`MSHR_SIZE):0] load_mshr_invalidated_order_idx;
logic [$clog2(`MSHR_SIZE):0] store_mshr_invalidated_order_idx;
logic [$clog2(`MSHR_SIZE):0] load_mshr_invalidated_order_idx1;
logic [$clog2(`MSHR_SIZE):0] store_mshr_invalidated_order_idx1;
logic [$clog2(`MSHR_SIZE):0] load_mshr_invalidated_order_idx2;
logic [$clog2(`MSHR_SIZE):0] store_mshr_invalidated_order_idx2;
logic [3:0] latched_mem2dcache_response;
logic load_tmp;
logic store_tmp;
logic tmp1;


always_comb
begin   
    order_idx_next = order_idx;
    mshr_next = mshr;
    dcache_next = dcache;

    // The next combinational block updates the expected tag so that the MSHR entry knows that
    // its request has been processed by the memory and that the data is ready. 


    if(mshr[mshr_idx].valid && mshr[mshr_idx].dispatched && !mshr[mshr_idx].expected_tag_assigned)
    begin
        mshr_next[mshr_idx].expected_tag = latched_mem2dcache_response;
        mshr_next[mshr_idx].expected_tag_assigned = 1;
    end


    // Both the store and the load entries are now added here. The assumption here is that
    // the new entries will not be from the same cache line, as two lines evicted from the 
    // victim cache would never have the same line_idx. 

    // First, the stores.
    if(victim_cache_full_evict && store_victim_cache_out[0].valid && store_victim_cache_out[0].dirty)
    begin
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next[i].valid)
            begin
                mshr_next[i].load = 0;
                mshr_next[i].store = 1;
                mshr_next[i].dispatched = 1'b0;
                mshr_next[i].valid = 1'b1;
                mshr_next[i].ready = 0;
                mshr_next[i].data = store_victim_cache_out[i].data;
                mshr_next[i].address = {store_victim_cache_out[0].tag, store_victim_cache_out[0].line_idx, 3'b0};
                mshr_next[i].expected_tag = 0;
                mshr_next[i].expected_tag_assigned = 0;
                mshr_next[i].dest_tag = 0;
                mshr_next[i].order_idx = order_idx_next;
                mshr_next[i].store_data = store_victim_cache_out[i].data;
                order_idx_next = order_idx_next+1;
                break;
            end
        end
    end
    else if(victim_cache_partial_evict && store_victim_cache_out[0].valid)
    begin
        dcache_next[store_victim_cache_out[0].line_idx].data = store_victim_cache_out[0].data;
        dcache_next[store_victim_cache_out[0].line_idx].tag = store_victim_cache_out[0].tag;
        dcache_next[store_victim_cache_out[0].line_idx].valid = 1;
    end




    // Then, the loads.
    if(victim_cache_full_evict && load_victim_cache_out[0].valid && load_victim_cache_out[0].dirty)
    begin
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next[i].valid)
            begin
                mshr_next[i].load = 0;
                mshr_next[i].store = 1;
                mshr_next[i].dispatched = 1'b0;
                mshr_next[i].valid = 1'b1;
                mshr_next[i].ready = 0;
                mshr_next[i].data = load_victim_cache_out[i].data;
                mshr_next[i].address = {load_victim_cache_out[0].tag, load_victim_cache_out[0].line_idx, 3'b0};
                mshr_next[i].expected_tag = 0;
                mshr_next[i].expected_tag_assigned = 0;
                mshr_next[i].dest_tag = 0;
                mshr_next[i].order_idx = order_idx_next;
                mshr_next[i].store_data = load_victim_cache_out[i].data;
                order_idx_next = order_idx_next+1;
                break;
            end
        end
    end
    else if(victim_cache_partial_evict && load_victim_cache_out[0].valid)
    begin
        dcache_next[load_victim_cache_out[0].line_idx].data = load_victim_cache_out[0].data;
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
            if(mshr_next[j].valid && mshr_next[j].dispatched && !mshr_next[j].ready && mshr_next[j].store && mshr_next[j].order_idx == i)
            begin
                if(mshr_next[j].expected_tag_assigned && mshr_next[j].expected_tag == mem2dcache_tag)
                begin
                    mshr_next2[j].ready = 1;
                    mshr_next2[j].data = mem2dcache_data;
                    line_idx = mshr_next2[j].address[`CACHE_LINE_BITS+3-1:3];
                    store_tmp = 0;
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
                    dcache_next2[line_idx].dirty = 0;
                    store_packet_out_next[store_packet_out_idx].store_pos = mshr_next2[j].store_pos;
                    store_packet_out_next[store_packet_out_idx].valid = 1;
                    casez(mshr_next2[j].size)
                        BYTE:
                        begin
                            casez(mshr_next2[j].address[2:0])
                                3'd0: dcache_next2[line_idx].data[7:0] = mshr_next2[j].store_data[7:0];
                                3'd1: dcache_next2[line_idx].data[15:8] = mshr_next2[j].store_data[7:0];
                                3'd2: dcache_next2[line_idx].data[23:16] = mshr_next2[j].store_data[7:0];
                                3'd3: dcache_next2[line_idx].data[31:24] = mshr_next2[j].store_data[7:0];
                                3'd4: dcache_next2[line_idx].data[39:32] = mshr_next2[j].store_data[7:0];
                                3'd5: dcache_next2[line_idx].data[47:40] = mshr_next2[j].store_data[7:0];
                                3'd6: dcache_next2[line_idx].data[55:48] = mshr_next2[j].store_data[7:0];
                                3'd7: dcache_next2[line_idx].data[63:56] = mshr_next2[j].store_data[7:0];
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next2[j].address[2:1])
                                2'd0: dcache_next2[line_idx].data[15:0] = mshr_next2[j].store_data[15:0];
                                2'd1: dcache_next2[line_idx].data[31:16] = mshr_next2[j].store_data[15:0];
                                2'd2: dcache_next2[line_idx].data[47:32] = mshr_next2[j].store_data[15:0];
                                2'd3: dcache_next2[line_idx].data[63:48] = mshr_next2[j].store_data[15:0];
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next2[j].address[2])
                                1'd0: dcache_next2[line_idx].data[31:0] = mshr_next2[j].store_data[31:0];
                                1'd1: dcache_next2[line_idx].data[63:32] = mshr_next2[j].store_data[31:0];
                            endcase
                        end
                    endcase
                    
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
            if(load_tmp && mshr_next[j].valid && mshr_next[j].dispatched && !mshr_next[j].ready && mshr_next[j].load && mshr_next[j].order_idx == i)
            begin
                if(mshr_next[j].expected_tag_assigned && mshr_next[j].expected_tag == mem2dcache_tag)
                begin
                    mshr_next2[j].ready = 1;
                    mshr_next2[j].data = mem2dcache_data;
                    line_idx = mshr_next2[j].address[`CACHE_LINE_BITS+3-1:3];
                    load_tmp = 0;
                    if(dcache_next[line_idx].valid)
                    begin
                        load_victim_cache_in1[load_victim_cache_in_idx].valid = dcache_next[line_idx].valid;
                        load_victim_cache_in1[load_victim_cache_in_idx].tag = dcache_next[line_idx].tag;
                        load_victim_cache_in1[load_victim_cache_in_idx].data = dcache_next[line_idx].data;
                        load_victim_cache_in1[load_victim_cache_in_idx].dirty = dcache_next[line_idx].dirty;
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
                                3'd0: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[7:0]};
                                3'd1: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[15:8]};
                                3'd2: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[23:16]};
                                3'd3: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[31:24]};
                                3'd4: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[39:32]};
                                3'd5: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[47:40]};
                                3'd6: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[55:48]};
                                3'd7: load_packet_out_next[load_packet_out_idx].data = {24'b0, mshr_next2[j].data[63:56]};
                                default: load_packet_out_next[load_packet_out_idx].data = 0;
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next2[j].address[2:0])
                                3'd0: load_packet_out_next[load_packet_out_idx].data = {16'b0, mshr_next2[j].data[15:0]};
                                3'd2: load_packet_out_next[load_packet_out_idx].data = {16'b0, mshr_next2[j].data[31:16]};
                                3'd4: load_packet_out_next[load_packet_out_idx].data = {16'b0, mshr_next2[j].data[47:32]};
                                3'd6: load_packet_out_next[load_packet_out_idx].data = {16'b0, mshr_next2[j].data[63:48]};
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
    if(victim_cache_full_evict_next)
    begin
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
    end
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
                if(mshr_next5[i].load)
                begin
                    mshr_idx_next = j;
                    mshr_next6[j].dispatched = 1;
                    dcache2mem_addr = {mshr_next5[j].address[`XLEN-1:3], 3'b0};
                    dcache2mem_command = BUS_LOAD;
                    tmp1 = 0;
                end
                else if(mshr_next5[i].store)
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

    // First, for stores. 
    if(!victim_cache_full_evict_next)
    begin
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next6[j].valid && mshr_next6[j].victim_hit && mshr_next6[j].store && mshr_next6[j].order_idx == i)
                begin
                    // This means that the data for this particular MSHR entry is present in the victim cache.
                    line_idx1 = mshr_next6[j].address[`CACHE_LINE_BITS+3-1:3];
                    victim_cache_partial_evict_next = 1;
                    store_victim_cache_in2[store_victim_cache_in_idx1].valid = dcache_next[line_idx1].valid;
                    store_victim_cache_in2[store_victim_cache_in_idx1].tag = dcache_next[line_idx1].tag;
                    store_victim_cache_in2[store_victim_cache_in_idx1].data = dcache_next[line_idx1].data;
                    store_victim_cache_in2[store_victim_cache_in_idx1].dirty = dcache_next[line_idx1].dirty;
                    store_victim_cache_in2[store_victim_cache_in_idx1].line_idx = line_idx1;
                    store_victim_cache_in_idx1 = store_victim_cache_in_idx1 + 1;

                    mshr_next7[j].valid = 0;
                    // casez(mshr_next6[j].size)
                    //     BYTE:
                    //     begin
                    //         casez(mshr_next6[j].address[2:0])
                    //             3'd0: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[7:0]};
                    //             3'd1: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[15:8]};
                    //             3'd2: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[23:16]};
                    //             3'd3: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[31:24]};
                    //             3'd4: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[39:32]};
                    //             3'd5: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[47:40]};
                    //             3'd6: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[55:48]};
                    //             3'd7: store_packet_out_next1[store_packet_out_idx1].data = {24'b0, mshr_next6[j].data[63:56]};
                    //             default: store_packet_out_next1[store_packet_out_idx1].data = 0;
                    //         endcase
                    //     end
                    //     HALF:
                    //     begin
                    //         casez(mshr_next6[j].address[2:0])
                    //             3'd0: store_packet_out_next1[store_packet_out_idx1].data = {16'b0, mshr_next6[j].data[15:0]};
                    //             3'd2: store_packet_out_next1[store_packet_out_idx1].data = {16'b0, mshr_next6[j].data[31:16]};
                    //             3'd4: store_packet_out_next1[store_packet_out_idx1].data = {16'b0, mshr_next6[j].data[47:32]};
                    //             3'd6: store_packet_out_next1[store_packet_out_idx1].data = {16'b0, mshr_next6[j].data[63:48]};
                    //             default: store_packet_out_next1[store_packet_out_idx1].data = 0;
                    //         endcase
                    //     end
                    //     WORD:
                    //     begin
                    //         casez(mshr_next6[j].address[2:0])
                    //             3'd0: store_packet_out_next1[store_packet_out_idx1].data = mshr_next6[j].data[31:0];
                    //             3'd4: store_packet_out_next1[store_packet_out_idx1].data = mshr_next6[j].data[63:32];
                    //             default: store_packet_out_next1[store_packet_out_idx1].data = 0;
                    //         endcase
                    //     end
                    //     default: store_packet_out_next1[store_packet_out_idx1].data = 0;
                    // endcase
                    store_packet_out_next1[store_packet_out_idx1].store_pos = mshr_next6[j].store_pos;
                    store_packet_out_next1[store_packet_out_idx1].valid = 1;
                    store_packet_out_idx1 = store_packet_out_idx1 + 1;
                    store_mshr_invalidated_order_idx1 = i;
                    order_idx_next3 = order_idx_next3 - 1;
                    break;
                end
            end
        end
    end

    // Then, for loads. 

    if(!victim_cache_full_evict_next && !victim_cache_partial_evict_next)
    begin
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next6[j].valid && mshr_next6[j].load && mshr_next6[j].victim_hit && mshr_next6[j].order_idx == i)
                begin
                    // This means that the data for this particular MSHR entry is present in the victim cache.
                    line_idx1 = mshr_next6[j].address[`CACHE_LINE_BITS+3-1:3];
                    victim_cache_partial_evict_next = 1;
                    load_victim_cache_in2[load_victim_cache_in_idx1].valid = dcache_next[line_idx1].valid;
                    load_victim_cache_in2[load_victim_cache_in_idx1].tag = dcache_next[line_idx1].tag;
                    load_victim_cache_in2[load_victim_cache_in_idx1].data = dcache_next[line_idx1].data;
                    load_victim_cache_in2[load_victim_cache_in_idx1].dirty = dcache_next[line_idx1].dirty;
                    load_victim_cache_in2[load_victim_cache_in_idx1].line_idx = line_idx1;
                    load_victim_cache_in_idx1 = load_victim_cache_in_idx1 + 1;

                    mshr_next7[j].valid = 0;
                    casez(mshr_next6[j].size)
                        BYTE:
                        begin
                            casez(mshr_next6[j].address[2:0])
                                3'd0: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[7:0]};
                                3'd1: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[15:8]};
                                3'd2: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[23:16]};
                                3'd3: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[31:24]};
                                3'd4: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[39:32]};
                                3'd5: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[47:40]};
                                3'd6: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[55:48]};
                                3'd7: load_packet_out_next1[load_packet_out_idx1].data = {24'b0, mshr_next6[j].data[63:56]};
                                default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next6[j].address[2:0])
                                3'd0: load_packet_out_next1[load_packet_out_idx1].data = {16'b0, mshr_next6[j].data[15:0]};
                                3'd2: load_packet_out_next1[load_packet_out_idx1].data = {16'b0, mshr_next6[j].data[31:16]};
                                3'd4: load_packet_out_next1[load_packet_out_idx1].data = {16'b0, mshr_next6[j].data[47:32]};
                                3'd6: load_packet_out_next1[load_packet_out_idx1].data = {16'b0, mshr_next6[j].data[63:48]};
                                default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next6[j].address[2:0])
                                3'd0: load_packet_out_next1[load_packet_out_idx1].data = mshr_next6[j].data[31:0];
                                3'd4: load_packet_out_next1[load_packet_out_idx1].data = mshr_next6[j].data[63:32];
                                default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                            endcase
                        end
                        default: load_packet_out_next1[load_packet_out_idx1].data = 0;
                    endcase
                    load_packet_out_next1[load_packet_out_idx1].dest_tag = mshr_next6[j].dest_tag;
                    load_packet_out_next1[load_packet_out_idx1].valid = 1;
                    load_packet_out_idx1 = load_packet_out_idx1 + 1;
                    load_mshr_invalidated_order_idx1 = i;
                    order_idx_next3 = order_idx_next2 - 1;
                    break;
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
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next8[j].valid && mshr_next8[j].store && mshr_next8[j].l1_hit && mshr_next8[j].order_idx == i)
                begin
                    store_l1_hit_next = 1;
                    mshr_next9[j].valid = 0;
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
                    break;
                end
            end
        end
    end


    // Then, the loads. 
    if(load_packet_out_idx2 < 1)
    begin
        for(int i = 1; i <= `MSHR_SIZE; i++)
        begin
            for(int j = 0; j < `MSHR_SIZE; j++)
            begin
                if(mshr_next8[j].valid && mshr_next8[j].load && mshr_next8[j].l1_hit && mshr_next8[j].order_idx == i)
                begin
                    load_l1_hit_next = 1;
                    mshr_next9[j].valid = 0;
                    casez(mshr_next8[j].size)
                        BYTE:
                        begin
                            casez(mshr_next8[j].address[2:0])
                                3'd0: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[7:0]};
                                3'd1: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[15:8]};
                                3'd2: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[23:16]};
                                3'd3: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[31:24]};
                                3'd4: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[39:32]};
                                3'd5: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[47:40]};
                                3'd6: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[55:48]};
                                3'd7: load_packet_out_next2[load_packet_out_idx2].data = {24'b0, mshr_next8[j].data[63:56]};
                                default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                            endcase
                        end
                        HALF:
                        begin
                            casez(mshr_next8[j].address[2:0])
                                3'd0: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next8[j].data[15:0]};
                                3'd2: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next8[j].data[31:16]};
                                3'd4: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next8[j].data[47:32]};
                                3'd6: load_packet_out_next2[load_packet_out_idx2].data = {16'b0, mshr_next8[j].data[63:48]};
                                default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                            endcase
                        end
                        WORD:
                        begin
                            casez(mshr_next8[j].address[2:0])
                                3'd0: load_packet_out_next2[load_packet_out_idx2].data = mshr_next8[j].data[31:0];
                                3'd4: load_packet_out_next2[load_packet_out_idx2].data = mshr_next8[j].data[63:32];
                                default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                            endcase
                        end
                        default: load_packet_out_next2[load_packet_out_idx2].data = 0;
                    endcase
                    load_packet_out_next2[load_packet_out_idx2].dest_tag = mshr_next8[j].dest_tag;
                    load_packet_out_next2[load_packet_out_idx2].valid = 1;
                    load_packet_out_idx2 = load_packet_out_idx2 + 1;
                    order_idx_next4 = order_idx_next4 - 1;
                    load_mshr_invalidated_order_idx2 = i;
                    break;
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

    // First the stores. 
    if(store_packet_in[0].valid &&
    dcache_next2[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].valid &&
    dcache_next2[store_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].tag == store_packet_in[0].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
    store_packet_out_idx3 < 1)
    begin
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
    else 
    begin
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next10[i].valid &&
            store_packet_in[0].valid)
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
                break;
            end
        end
    end

    // Then, the loads. 
    if(load_packet_in[0].valid &&
    dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].valid &&
    dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].tag == load_packet_in[0].address[`XLEN-1:`CACHE_LINE_BITS+3] &&
    load_packet_out_idx3 < 1)
    begin
        casez(load_packet_in[0].size)
            BYTE:
            begin
                casez(load_packet_in[0].address[2:0])
                    3'd0: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[7:0]};
                    3'd1: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:8]};
                    3'd2: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[23:16]};
                    3'd3: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:24]};
                    3'd4: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[39:32]};
                    3'd5: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:40]};
                    3'd6: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[55:48]};
                    3'd7: load_packet_out_next3[load_packet_out_idx3].data = {24'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:56]};
                    default: load_packet_out_next3[load_packet_out_idx3].data = 0;
                endcase
            end
            HALF:
            begin
                casez(load_packet_in[0].address[2:0])
                    3'd0: load_packet_out_next3[load_packet_out_idx3].data = {16'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[15:0]};
                    3'd2: load_packet_out_next3[load_packet_out_idx3].data = {16'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:16]};
                    3'd4: load_packet_out_next3[load_packet_out_idx3].data = {16'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[47:32]};
                    3'd6: load_packet_out_next3[load_packet_out_idx3].data = {16'b0, dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:48]};
                    default: load_packet_out_next3[load_packet_out_idx3].data = 0;
                endcase
            end
            WORD:
            begin
                casez(load_packet_in[0].address[2:0])
                    3'd0: load_packet_out_next3[load_packet_out_idx3].data = dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[31:0];
                    3'd4: load_packet_out_next3[load_packet_out_idx3].data = dcache_next2[load_packet_in[0].address[`CACHE_LINE_BITS+3-1:3]].data[63:32];
                    default: load_packet_out_next3[load_packet_out_idx3].data = 0;
                endcase
            end
            default: load_packet_out_next3[load_packet_out_idx3].data = 0;
        endcase
        load_packet_out_next3[load_packet_out_idx3].dest_tag = load_packet_in[0].dest_tag;
        load_packet_out_next3[load_packet_out_idx3].valid = 1;
        load_packet_out_idx3 = load_packet_out_idx3 + 1;
        
    end
    else 
    begin
        for(int i = 0; i < `MSHR_SIZE; i++)
        begin
            if(!mshr_next10[i].valid &&
            load_packet_in[0].valid)
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
                order_idx_next5 = order_idx_next5 + 1;
                break;
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
    end
    else
    begin
        load_packet_out <= `SD load_packet_out_next4;
        store_packet_out <= `SD store_packet_out_next4;
        mshr_idx <= `SD mshr_idx_next;
        victim_cache_full_evict <= `SD victim_cache_full_evict_next;
        victim_cache_partial_evict <= `SD victim_cache_partial_evict_next;
        load_l1_hit <= `SD load_l1_hit_next;
        store_l1_hit <= `SD store_l1_hit_next;
        mshr <= `SD mshr_next11;
        dcache <= `SD dcache_next4;
        order_idx <= `SD order_idx_next5;
        latched_mem2dcache_response <= `SD mem2dcache_response;
    end
end

endmodule






module victim_cache(
    input clock, 
    input reset,
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
VICTIM_CACHE_ROW load_victim_cache_out_next;
VICTIM_CACHE_ROW store_victim_cache_out_next;

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
                store_victim_cache_in[0].line_idx == victim_cache[i].line_idx)
                begin
                    store_victim_cache_out_next = victim_cache[i];
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
        victim_cache <= `SD victim_cache_next;
        load_victim_cache_out <= `SD load_victim_cache_out_next;
        store_victim_cache_out <= `SD 0;
    end
end


endmodule
