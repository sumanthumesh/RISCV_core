/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__

/* Synthesis testing definition, used in DUT module instantiation */

`ifdef  SYNTH_TEST
`define DUT(mod) mod``_svsim
`else
`define DUT(mod) mod
`endif

//////////////////////////////////////////////
//
// Memory/testbench attribute definitions
//
//////////////////////////////////////////////
`define CACHE_MODE //removes the byte-level interface from the memory mode, DO NOT MODIFY!
`define NUM_MEM_TAGS           15

`define MEM_SIZE_IN_BYTES      (64*1024)
`define MEM_64BIT_LINES        (`MEM_SIZE_IN_BYTES/8)

//you can change the clock period to whatever, 10 is just fine
`define VERILOG_CLOCK_PERIOD   10.0
`define SYNTH_CLOCK_PERIOD     10.0 // Clock period for synth and memory latency

`define MEM_LATENCY_IN_CYCLES (100.0/`SYNTH_CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

typedef union packed {
    logic [7:0][7:0] byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

//////////////////////////////////////////////
// Exception codes
// This mostly follows the RISC-V Privileged spec
// except a few add-ons for our infrastructure
// The majority of them won't be used, but it's
// good to know what they are
//////////////////////////////////////////////

typedef enum logic [3:0] {
	INST_ADDR_MISALIGN  = 4'h0,
	INST_ACCESS_FAULT   = 4'h1,
	ILLEGAL_INST        = 4'h2,
	BREAKPOINT          = 4'h3,
	LOAD_ADDR_MISALIGN  = 4'h4,
	LOAD_ACCESS_FAULT   = 4'h5,
	STORE_ADDR_MISALIGN = 4'h6,
	STORE_ACCESS_FAULT  = 4'h7,
	ECALL_U_MODE        = 4'h8,
	ECALL_S_MODE        = 4'h9,
	NO_ERROR            = 4'ha, //a reserved code that we modified for our purpose
	ECALL_M_MODE        = 4'hb,
	INST_PAGE_FAULT     = 4'hc,
	LOAD_PAGE_FAULT     = 4'hd,
	HALTED_ON_WFI       = 4'he, //another reserved code that we used
	STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;


//////////////////////////////////////////////
//
// Datapath control signals
//
//////////////////////////////////////////////

//
// ALU opA input mux selects
//
typedef enum logic [1:0] {
	OPA_IS_RS1  = 2'h0,
	OPA_IS_NPC  = 2'h1,
	OPA_IS_PC   = 2'h2,
	OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

//
// ALU opB input mux selects
//
typedef enum logic [3:0] {
	OPB_IS_RS2    = 4'h0,
	OPB_IS_I_IMM  = 4'h1,
	OPB_IS_S_IMM  = 4'h2,
	OPB_IS_B_IMM  = 4'h3,
	OPB_IS_U_IMM  = 4'h4,
	OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

//
// Destination register select
//
typedef enum logic [1:0] {
	DEST_RD = 2'h0,
	DEST_NONE  = 2'h1
} DEST_REG_SEL;

//
// ALU function code input
// probably want to leave these alone
//
typedef enum logic [4:0] {
	ALU_ADD     = 5'h00,
	ALU_SUB     = 5'h01,
	ALU_SLT     = 5'h02,
	ALU_SLTU    = 5'h03,
	ALU_AND     = 5'h04,
	ALU_OR      = 5'h05,
	ALU_XOR     = 5'h06,
	ALU_SLL     = 5'h07,
	ALU_SRL     = 5'h08,
	ALU_SRA     = 5'h09,
	ALU_MUL     = 5'h0a,
	ALU_MULH    = 5'h0b,
	ALU_MULHSU  = 5'h0c,
	ALU_MULHU   = 5'h0d,
	ALU_DIV     = 5'h0e,
	ALU_DIVU    = 5'h0f,
	ALU_REM     = 5'h10,
	ALU_REMU    = 5'h11
} ALU_FUNC;

typedef enum logic [1:0] {
	MUL     = 2'b00,
	MULH    = 2'b01,
	MULHSU  = 2'b10,
	MULHU   = 2'b11
} MULT_FUNC;


//////////////////////////////////////////////
//
// Assorted things it is not wise to change
//
//////////////////////////////////////////////

//
// actually, you might have to change this if you change VERILOG_CLOCK_PERIOD
// JK you don't ^^^
//
`define SD #1


// the RISCV register file zero register, any read of this register always
// returns a zero value, and any write to this register is thrown away
//
`define ZERO_REG 5'd0

//
// Memory bus commands control signals
//
typedef enum logic [1:0] {
	BUS_NONE     = 2'h0,
	BUS_LOAD     = 2'h1,
	BUS_STORE    = 2'h2
} BUS_COMMAND;

typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;
//
// useful boolean single-bit definitions
//
`define FALSE  1'h0
`define TRUE  1'h1

// RISCV ISA SPEC
`define XLEN 32
typedef union packed {
	logic [31:0] inst;
	struct packed {
		logic [6:0] funct7;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} r; //register to register instructions
	struct packed {
		logic [11:0] imm;
		logic [4:0]  rs1; //base
		logic [2:0]  funct3;
		logic [4:0]  rd;  //dest
		logic [6:0]  opcode;
	} i; //immediate or load instructions
	struct packed {
		logic [6:0] off; //offset[11:5] for calculating address
		logic [4:0] rs2; //source
		logic [4:0] rs1; //base
		logic [2:0] funct3;
		logic [4:0] set; //offset[4:0] for calculating address
		logic [6:0] opcode;
	} s; //store instructions
	struct packed {
		logic       of; //offset[12]
		logic [5:0] s;   //offset[10:5]
		logic [4:0] rs2;//source 2
		logic [4:0] rs1;//source 1
		logic [2:0] funct3;
		logic [3:0] et; //offset[4:1]
		logic       f;  //offset[11]
		logic [6:0] opcode;
	} b; //branch instructions
	struct packed {
		logic [19:0] imm;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} u; //upper immediate instructions
	struct packed {
		logic       of; //offset[20]
		logic [9:0] et; //offset[10:1]
		logic       s;  //offset[11]
		logic [7:0] f;	//offset[19:12]
		logic [4:0] rd; //dest
		logic [6:0] opcode;
	} j;  //jump instructions
`ifdef ATOMIC_EXT
	struct packed {
		logic [4:0] funct5;
		logic       aq;
		logic       rl;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} a; //atomic instructions
`endif
`ifdef SYSTEM_EXT
	struct packed {
		logic [11:0] csr;
		logic [4:0]  rs1;
		logic [2:0]  funct3;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} sys; //system call instructions
`endif

} INST; //instruction typedef, this should cover all types of instructions

//
// Basic NOP instruction.  Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
//
`define NOP 32'h00000013

//////////////////////////////////////////////
//
// IF Packets:
// Data that is exchanged between the IF and the ID stages  
//
//////////////////////////////////////////////

typedef struct packed {
	logic valid; // If low, the data in this struct is garbage
    INST  inst;  // fetched instruction out
	logic [`XLEN-1:0] NPC; // PC + 4
	logic [`XLEN-1:0] PC;  // PC 
} IF_ID_PACKET;

//////////////////////////////////////////////
//
// ID Packets:
// Data that is exchanged from ID to EX stage
//
//////////////////////////////////////////////

typedef struct packed {
	logic [`XLEN-1:0] NPC;   // PC + 4
	logic [`XLEN-1:0] PC;    // PC

	logic [`XLEN-1:0] rs1_value;    // reg A value                                  
	logic [`XLEN-1:0] rs2_value;    // reg B value                                  
	                                                                                
	ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
	ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)
	INST inst;                 // instruction
	
	logic [4:0] dest_reg_idx;  // destination (writeback) register index      
	ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
	logic       rd_mem;        // does inst read memory?
	logic       wr_mem;        // does inst write memory?
	logic       cond_branch;   // is inst a conditional branch?
	logic       uncond_branch; // is inst an unconditional branch?
	logic       halt;          // is this a halt?
	logic       illegal;       // is this instruction illegal?
	logic       csr_op;        // is this a CSR operation? (we only used this as a cheap way to get return code)
	logic       valid;         // is inst a valid instruction to be counted for CPI calculations?
} ID_EX_PACKET;

typedef struct packed {
	logic [`XLEN-1:0] result; // result
	logic [`XLEN-1:0] NPC; //pc + 4
	logic             take_branch; // is this a taken branch?
	//pass throughs from decode stage
	logic [`XLEN-1:0] rs2_value;
	logic             rd_mem, wr_mem;
	logic [4:0]       dest_reg_idx;
	logic             halt, illegal, csr_op, valid;
	logic [2:0]       mem_size; // byte, half-word or word
} EX_MEM_PACKET;
//OOO
`define N_WAY_3
`define CDB_BITS 7
`define N_ROB 16
`define N_SQ 32
`define N_SC 8
`define FIFO_BITS 6
`define XLEN_BITS 5
`define N_RS 16
`define N_RS_IDX 4
`define ARCH_REG 32
`define N_PHY_REG `ARCH_REG+`N_ROB
`define ZERO_REG_PR `CDB_BITS'b1
`define DISP_Q_SIZE 8
`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)
`define ICACHE_Q_SIZE 16
`define N_IC_PREFETCH 2
`define ICACHE_Q2_SIZE 16
`define MAX_EX_UNITS `EX_MULT_UNITS+`EX_ALU_UNITS+2*`EX_LOAD_UNITS+`EX_BRANCH_UNITS
`define STOREQ_DCACHE_FIFO_SIZE 16

//`define PIPELINE_DEPTH 2
//`define MULT_WIDTH 16
`define NUM_STAGE 2 //mult stage
`define NUM_BITS 32 
//`define NUM_BITS (2*`XLEN)/`NUM_STAGE 


// Functional unit macros
`ifdef N_WAY_1
`define N_WAY 1
`define EX_MULT_UNITS	1
`define EX_ALU_UNITS	1
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_2
`define N_WAY 2
`define EX_MULT_UNITS	1
`define EX_ALU_UNITS	2
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_3
`define N_WAY 3
`define EX_MULT_UNITS	2
`define EX_ALU_UNITS	3
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_4
`define N_WAY 4
`define EX_MULT_UNITS	2
`define EX_ALU_UNITS	3
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_5
`define N_WAY 5
`define EX_MULT_UNITS	3
`define EX_ALU_UNITS	5
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_6
`define N_WAY 6
`define EX_MULT_UNITS	3
`define EX_ALU_UNITS	5
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_7
`define N_WAY 7
`define EX_MULT_UNITS	3
`define EX_ALU_UNITS	5
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`elsif N_WAY_8
`define N_WAY 8
`define EX_MULT_UNITS	3
`define EX_ALU_UNITS	5
`define EX_LOAD_UNITS	1
`define EX_STORE_UNITS	1
`define EX_BRANCH_UNITS	1

`endif

`define N_RD_PORTS	1
`define N_WR_PORTS	1

`define VICTIM_CACHE_LINES 4

`define MSHR_SIZE	16

typedef enum logic [2:0] {
	ALU  	= 3'h0,
	MULT   	= 3'h1,
	LOAD	= 3'h2,
	STORE	= 3'h3,
	BRANCH  = 3'h4
} EXECUTION_UNIT;




//Packet of dispatched requests - icache

typedef struct packed {
	logic [63:0]                     data;
    logic [12 - `CACHE_LINE_BITS:0]  tags;
    logic                            valids;
	logic req_sent;
} ICACHE_PACKET;

typedef struct packed {
    logic [`XLEN-1:0] addr;
    logic [12 - `CACHE_LINE_BITS:0] tags;
    logic [`CACHE_LINE_BITS-1:0] line_idx;
    logic  valid;
} ICACHE_REQ;

typedef enum logic[1:0] { 
    IDLE = 2'b00,
    WAIT  = 2'b01
} state;

typedef struct packed {
    logic [`XLEN-1:0] addr;
    logic valid;
	logic req_sent;
} STORE_REQ;

typedef struct packed {
    logic [`XLEN-1:0] addr;
    logic [3:0] expected_tag;
    logic valid;
} DISP_REQ;

typedef struct packed {
	logic [`CDB_BITS-1:0] phy_reg; // physical registor number
	logic 		      status; //status of completion
} PR_PACKET; //source tag and reg number to RS

typedef struct packed {
	logic [`XLEN_BITS-1 :0] src1;
	logic [`XLEN_BITS-1 :0] src2;
	logic [`XLEN_BITS-1 :0] dest;
	logic valid;
	logic [`XLEN-1:0] PC;
	logic halt;
	logic illegal;
	logic [1:0] ld_st_bits; //00: no ld store, 01: store, 10: load , 11:reserve
} DISPATCH_PACKET;

typedef struct packed {
	logic [`XLEN_BITS-1 :0] src1;
	logic [`XLEN_BITS-1 :0] src2;
	logic [`XLEN_BITS-1 :0] dest;
	INST inst;
	logic valid;
	logic [`XLEN-1:0]	NPC;
	logic [`XLEN-1:0]	PC;
	logic halt;
	logic illegal;
	logic [1:0] ld_st_bits; //00: no ld store, 01: store, 10: load , 11:reserve
} DISPATCH_PACKET_R10K;


typedef struct packed {
	logic [`CDB_BITS-1:0] tag; // physical registor number
	logic [`CDB_BITS-1:0] tag_old; // physical registor number
	logic ret_valid;
	logic [`XLEN-1:0] PC;
	logic halt;
	logic illegal;
	logic inst_is_branch;
} RETIRE_ROB_PACKET;

typedef struct packed {
	logic busy; // alu_result
	INST inst; //pc + 4
	logic [`CDB_BITS-1:0] dest_tag; 
	logic [`CDB_BITS-1:0] source_tag_1; 
	logic source_tag_1_plus;
	logic [`CDB_BITS-1:0] source_tag_2; 
	logic source_tag_2_plus;
	logic issued;
	logic [$clog2(`N_RS):0] order_idx; //to track the oldest instruction 
	logic [$clog2(`N_SQ):0] storeq_idx;
	logic [1:0] ld_st_bits; //00: no ld store, 01: store, 10: load , 11:reserve
	logic [`XLEN-1:0] NPC; // PC + 4
	logic [`XLEN-1:0] PC;  // PC
} RS_PACKET;  
typedef struct packed {
	logic busy; 
	INST inst; 
	logic [`CDB_BITS-1:0] dest_tag; 
	logic [`CDB_BITS-1:0] source_tag_1; 
	logic source_tag_1_plus;
	logic [`CDB_BITS-1:0] source_tag_2; 
	logic source_tag_2_plus;
	logic valid;
	logic [$clog2(`N_RS):0] order_idx;
	logic [$clog2(`N_SQ):0] storeq_idx;
	logic [1:0] ld_st_bits; //00: no ld store, 01: store, 10: load , 11:reserve
	logic [`XLEN-1:0] NPC; // PC + 4
	logic [`XLEN-1:0] PC;  // PC
} RS_PACKET_DISPATCH;  
typedef struct packed {
	logic [`CDB_BITS-1 : 0] source_tag_1;
	logic [`CDB_BITS-1 : 0] source_tag_2;
	logic [`CDB_BITS-1 : 0] dest_tag;
	INST 		inst;
	logic valid;
	logic [$clog2(`N_SQ):0] storeq_idx;
	logic [`XLEN-1:0] NPC; // PC + 4
	logic [`XLEN-1:0] PC;  // PC 
} RS_PACKET_ISSUE; //output packet from RS to issue

typedef struct packed {
	logic busy;
	logic [`CDB_BITS-1:0] phy_reg_idx;
} ROB_PACKET_ISSUE;


typedef struct packed {
	logic	valid;
	logic [`XLEN-1:0] rs1_value;    // reg A value                                  
	logic [`XLEN-1:0] rs2_value;    // reg B value                                  
	                                                                                
	ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
	ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)
	INST inst;                 // instruction
	
	logic [`CDB_BITS-1:0] dest_reg_idx;  // destination (writeback) register index      
	ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
	MULT_FUNC    mult_func;      // ALU function select (ALU_xxx *)
	logic       rd_mem;        // does inst read memory?
	logic       wr_mem;        // does inst write memory?
	logic       cond_branch;   // is inst a conditional branch?
	logic       uncond_branch; // is inst an unconditional branch?
	logic       halt;          // is this a halt?
	logic       illegal;       // is this instruction illegal?
	logic       csr_op;        // is this a CSR operation? (we only used this as a cheap way to get return code)
	EXECUTION_UNIT execution_unit;
	logic [$clog2(`N_SQ):0] storeq_idx;
	logic [`XLEN-1:0] NPC; // PC + 4
	logic [`XLEN-1:0] PC;  // PC 
} ISSUE_EX_PACKET;

typedef struct packed {
	logic	[`CDB_BITS-1:0] dest_tag;
} RS_PACKET_RETIRE;


typedef struct packed {
	logic	busy;
	logic	[$clog2(`N_WAY):0]	order_idx;
	ISSUE_EX_PACKET		issue_ex_packet;
} ISSUE_PACKET;

typedef struct packed {
	logic [`CDB_BITS-1 : 0] tag;
	logic [`CDB_BITS-1 : 0] tag_old;
	logic branch_inst;
	logic head;
	logic tail;
	logic completed;
	logic take_branch;
	logic [`XLEN-1:0] br_result;
	logic [`XLEN-1:0] PC;
	logic halt;
	logic illegal;
	logic [1:0] ld_st_bits; //00: no ld store, 01: store, 10: load , 11:reserve

} ROB_PACKET; //Rob packet

typedef struct packed {
	logic [`CDB_BITS-1:0] tag; 
	logic [`CDB_BITS-1:0] tag_old; 
	logic valid;
	logic branch_inst;
	logic [`XLEN-1:0] PC;
	logic halt;
	logic illegal;
	logic [1:0] ld_st_bits; //00: no ld store, 01: store, 10: load , 11:reserve
} ROB_PACKET_DISPATCH;

typedef struct packed {
	logic [`XLEN-1:0] address; 
	logic [`XLEN-1:0] value; 
	logic [$clog2(`N_SQ):0] store_pos;
	MEM_SIZE size;
	logic valid;
} STORE_PACKET;

typedef struct packed {
	logic [`XLEN-1:0] address; 
	logic [`CDB_BITS-1:0] dest_tag; 
	logic valid;
	MEM_SIZE size;
	logic sign; //0: signed 1: unsigned
} LOAD_PACKET_RET;

typedef struct packed {
	logic [`XLEN-1:0] address; 
	logic [`XLEN-1:0] data; 
	logic valid;
	logic [$clog2(`N_SQ):0] store_pos;
	MEM_SIZE size;
} STORE_PACKET_RET;


typedef struct packed {
	logic [`XLEN-1:0] address; 
	logic [`XLEN-1:0] value; 
	logic head;
	logic tail;
	logic valid;
	logic ex; // tracks if store is executed or not
	logic [$clog2(`N_SQ):0] order_idx;
	MEM_SIZE size;
	logic retired;
} STORE_PACKET_REG;

typedef struct packed {
	logic [`XLEN-1:0] value; 
	logic [`CDB_BITS-1:0] dest_tag; 
	logic valid;
} LOAD_PACKET_OUT;

typedef struct packed {
	logic [`XLEN-1:0] address; 
	logic [$clog2(`N_SQ):0] load_pos; 
	logic [`CDB_BITS-1:0] dest_tag; 
	MEM_SIZE size;
	logic sign; //0: signed 1: unsigned
	logic valid;
} LOAD_PACKET_IN;
typedef struct packed {
	logic [`XLEN-1:0] data; 
	logic [`CDB_BITS-1:0] dest_tag; 
	logic valid;
	logic [`XLEN-1:0] address; 
} LOAD_PACKET_EX_STAGE;

typedef struct packed {
	logic [$clog2(`N_SQ):0] store_pos;
	logic valid;
	logic [`XLEN-1:0] address; 
} STORE_PACKET_EX_STAGE;

typedef struct packed {
	logic [63:0] data;
	logic [7:0] tag;
	logic valid;
	logic dirty;
}DCACHE_ROW;

typedef struct packed {
	logic [63:0] data;
	logic [7:0] tag;
	logic [4:0] line_idx;
	logic valid;
	logic dirty;
} VICTIM_CACHE_ROW;


typedef struct packed {
	logic valid;
	logic load;
	logic store;
	logic dispatched;
	logic ready;
	logic [63:0] data;
	logic [`XLEN-1:0] address;
	logic [`CDB_BITS-1:0] dest_tag;
	logic [3:0] expected_tag;
	logic expected_tag_assigned;
	MEM_SIZE size;
	logic [$clog2(`MSHR_SIZE):0] order_idx;
	logic l1_hit;
	logic victim_hit;
	logic [`XLEN-1:0] store_data;
	logic [$clog2(`N_SQ):0] store_pos;
	logic sign;
} MSHR_ROW;

typedef struct packed {
	logic [`CDB_BITS-1:0] dest_tag;
	logic valid;
	logic [`XLEN-1:0] address; 
} LOAD_BUFFER;




`endif // __SYS_DEFS_VH__

