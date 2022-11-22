`define ICACHE_BUFF_SIZE 16

module instruction_buffer(
    input clock,
    input reset,
	input enable,
	//input dispatch_en,
	// input from Icache
	input [`N_WAY-1:0][`XLEN-1:0] Icache2buff_addr,
    input [`N_WAY-1:0][`XLEN-1:0] Icache2buff_data,
    input [`N_WAY-1:0] Icache2buff_valid,
	input [$clog2(`N_WAY):0] Icache2buff_hit_count,
	// input from pipeline -> to handle branch
	input branch_taken,
	input [`XLEN-1:0] branch_addr,
	// input from issue
	input [`N_WAY-1:0] proc2buff_dispatched,
	
	//output to Icache
    output logic [`XLEN-1:0] buff2Icache_addr, //Address or PC to fetch instructions from
    output logic [$clog2(`N_WAY):0] buff2Icache_count, //Num of instructions that buff wants
	output logic [`XLEN-1:0] pc_wire,
	// output to pipeline
	output logic [`N_WAY-1:0][`XLEN-1:0] buff2proc_addr,
	output logic [`N_WAY-1:0][`XLEN-1:0] buff2proc_data,
	output logic [`N_WAY-1:0] buff2proc_valid
);
	
    logic [`ICACHE_BUFF_SIZE-1:0][`XLEN-1:0] data;
    logic [`ICACHE_BUFF_SIZE-1:0][`XLEN-1:0] next_data;
	logic [`ICACHE_BUFF_SIZE-1:0][`XLEN-1:0] addr;
	logic [`ICACHE_BUFF_SIZE-1:0][`XLEN-1:0] next_addr;


	logic [`ICACHE_BUFF_SIZE-1:0] valid;
	logic [`ICACHE_BUFF_SIZE-1:0] next_valid;

	
	logic [$clog2(`ICACHE_BUFF_SIZE)-1:0] next_head, next_tail;
	logic [$clog2(`ICACHE_BUFF_SIZE)-1:0] head, tail;
	logic [$clog2(`ICACHE_BUFF_SIZE)-1:0] data_pointer;
	
	logic [$clog2(`ICACHE_BUFF_SIZE):0] next_slots;
	logic [$clog2(`ICACHE_BUFF_SIZE):0] slots; // available_num_slots
	logic [$clog2(`N_WAY):0] fill_count;
	logic [`XLEN-1:0] next_pc;
	logic [$clog2(`N_WAY):0] num_request;
	logic empty;

	
	// interface with pipeline part
	logic [$clog2(`N_WAY):0] out_new_counter;  // count how many inst were newly dispatched
	logic [$clog2(`N_WAY):0] out_stay_counter; // count how many inst were dispatched repetedly
	logic [$clog2(`N_WAY):0] total_out_count;
	logic [$clog2(`N_WAY):0] out_pointer; // pointer pointing N-way inst
	logic [$clog2(`ICACHE_BUFF_SIZE)-1:0] out_data_pointer;
	logic [`N_WAY-1:0][`XLEN-1:0] next_output_addr;
	logic [`N_WAY-1:0][`XLEN-1:0] next_output_data;
	logic [`N_WAY-1:0] next_output_valid;
	//to keep track of instruction that I have shown to the pipeline, compare
	//at next cycle with input vector proc2buff_dispatched
	logic [`N_WAY-1:0] inst_showed;
	logic [`N_WAY-1:0] next_inst_showed;


	assign total_out_count = out_new_counter + out_stay_counter;
	assign empty = (slots==`ICACHE_BUFF_SIZE);
	assign pc_wire = next_pc;

	logic trailing_zeros, detected_1_before;
	//Check if Icache2buff_valid[`N_WAY-1:0] has any trailing zeros. Leading 0s are tolerated, but not trailing zeros
	always_comb begin
		trailing_zeros = 0;
		detected_1_before = 0;
		for(int i=0;i<`N_WAY;i++) begin
			if(Icache2buff_valid[i] == 1)
				detected_1_before = 1;
			else
				detected_1_before = 0;
			if(Icache2buff_valid[i] == 0 && detected_1_before == 0)
				trailing_zeros = 1;
			else
				trailing_zeros = trailing_zeros;
		end
	end

	// interface with Icache - combinational logic
    always_comb begin
		//Execute always comb block only if there are no trailing zeros
		//data_pointer = (next_slots ==`ICACHE_BUFF_SIZE)? tail : (tail + 1);
		data_pointer = (tail + 1);
		fill_count = 0;
		next_data = data;
		next_addr = addr;
		next_valid = valid;
		if(~trailing_zeros) begin
        	for(int i=0;i<`N_WAY;i=i+1) begin
        	    if(Icache2buff_valid[i] && (slots != 0) && (slots > fill_count) && enable) begin
        	        next_data[data_pointer] = Icache2buff_data[i];
					next_addr[data_pointer] = Icache2buff_addr[i];
					next_valid[data_pointer] = 1;
        	        data_pointer = data_pointer + 1;
					fill_count = fill_count + 1;
        	    end
        	end
		end

		// interface with pipeline - combinational logic
		out_new_counter = 0;
		out_stay_counter = 0;
		out_pointer = 0;
		next_inst_showed = 0;
		next_output_addr = 0;
		next_output_data = 0;
		next_output_valid = 0;
		out_data_pointer = head;
		for(int j=0;j<`N_WAY;j=j+1) begin
			// when showed instruction, but was not dispatched -> keep next
			if(proc2buff_dispatched[j]==0 && inst_showed[j]==1 && enable) begin	
				next_output_addr[out_pointer] = buff2proc_addr[j];
				next_output_data[out_pointer] = buff2proc_data[j];
				next_output_valid[out_pointer] = buff2proc_valid[j];
				next_inst_showed[out_pointer] = 1;
				out_pointer = out_pointer + 1;
				out_stay_counter = out_stay_counter + 1;
			end
		end
		for(int k=0;k<`N_WAY;k=k+1) begin
			if((inst_showed[k]==0 || proc2buff_dispatched[k]==1) && valid[out_data_pointer] && enable) begin
				next_output_addr[out_pointer] = addr[out_data_pointer];
				next_output_data[out_pointer] = data[out_data_pointer];
				next_output_valid[out_pointer] = valid[out_data_pointer];
				next_inst_showed[out_pointer] = 1;
				out_pointer = out_pointer + 1;
				out_new_counter = out_new_counter + 1;
				next_valid[out_data_pointer] = 0;
				out_data_pointer = out_data_pointer + 1;
			end
		end
		//finalize values to put in output registers
		next_pc = buff2Icache_addr + 4*fill_count;
		next_tail = tail + fill_count;
			//(empty ? ((fill_count==0)?0:(fill_count-1)) : fill_count) ;
		next_slots = (slots-fill_count+out_new_counter > `ICACHE_BUFF_SIZE) ? 0 :(slots - fill_count + out_new_counter);
		num_request = (slots >= 3) ? 3 : (slots==2) ? 2 : (slots==1) ? 1 : 0;
		// write from here
		next_head = head + (empty ? 0 : out_new_counter);
    end


	// synchronized - update every clock cycle
    always_ff@(posedge clock) begin
        if(reset) begin
            data       <= `SD 0;
			addr       <= `SD 0;
            valid      <= `SD 0;
			head       <= `SD 0;
			tail       <= `SD `ICACHE_BUFF_SIZE -1 ;
			slots	   <= `SD `ICACHE_BUFF_SIZE;
			buff2Icache_addr  <= `SD 32'h000;
			buff2Icache_count <= `SD 0;
			buff2proc_addr    <= `SD 0;
			buff2proc_data    <= `SD 0;
			buff2proc_valid   <= `SD 0;
			inst_showed <= `SD 0;
        end
        else if(enable) begin
			// enabled -> update registers
			if(branch_taken==0) begin
				// branch is not taken 
				buff2Icache_addr <= `SD next_pc;
				buff2Icache_count <= `SD num_request;
				head <= `SD next_head;
				tail <= `SD next_tail;
				slots <= `SD next_slots;
				data <= `SD next_data;
				addr <= `SD next_addr;
				valid <= `SD next_valid;
				buff2proc_addr <= `SD next_output_addr;
				buff2proc_data <= `SD next_output_data;
				buff2proc_valid <= `SD next_output_valid;
				inst_showed <= `SD next_inst_showed;
			end
			else begin
				// branch is taken
				buff2Icache_addr <= `SD branch_addr;
				buff2Icache_count <= `SD num_request;
				head <= `SD 0;
				tail <= `SD 0;
				slots <= `SD `ICACHE_BUFF_SIZE;
				data <= `SD 0;
				addr <= `SD 0;
				valid <= `SD 0;
				buff2proc_addr <= `SD 0;
				buff2proc_data <= `SD 0;
				buff2proc_valid <= `SD 0;
				inst_showed <= `SD 0;
			end
        end
        else begin
			// not enabled -> hold registers
			buff2Icache_addr <= `SD buff2Icache_addr;
			buff2Icache_count <= `SD buff2Icache_count;
			head <= `SD head;
			tail <= `SD tail;
			slots <= `SD slots;
			data <= `SD data;
			addr <= `SD addr;
			valid <= `SD valid;
			buff2proc_addr <= `SD buff2proc_addr;
			buff2proc_data <= `SD buff2proc_data;
			buff2proc_valid <= `SD buff2proc_valid;
			inst_showed <= `SD inst_showed;
        end
    end

endmodule

