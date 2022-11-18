# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#
#

SOURCE = test_progs/sampler.s

CRT = crt.s
LINKERS = linker.lds
ASLINKERS = aslinker.lds

DEBUG_FLAG = -g
CFLAGS =  -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div
OFLAGS = -O0
ASFLAGS = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align
OBJFLAGS = -SD -M no-aliases 
OBJCFLAGS = --set-section-flags .bss=contents,alloc,readonly
OBJDFLAGS = -SD -M numeric,no-aliases

##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################
ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJCOPY = riscv objcopy
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJCOPY = riscv64-unknown-elf-objcopy
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif
all: simv
	./simv -cm line+cond+fsm+tgl+assert+path | tee program.out

compile: $(CRT) $(LINKERS)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
	$(GCC) $(CFLAGS) $(DEBUG_FLAG) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.debug.elf
assemble: $(ASLINKERS)
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf 
	cp program.elf program.debug.elf
disassemble: program.debug.elf
	$(OBJCOPY) $(OBJCFLAGS) program.debug.elf
	$(OBJDUMP) $(OBJFLAGS) program.debug.elf > program.dump
	$(OBJDUMP) $(OBJDFLAGS) program.debug.elf > program.debug.dump
	rm program.debug.elf
hex: program.elf
	$(ELF2HEX) 8 8192 program.elf > program.mem

program: compile disassemble hex
	@:

debug_program:
	gcc -lm -g -std=gnu11 -DDEBUG $(SOURCE) -o debug_bin
assembly: assemble disassemble hex
	@:

VCS = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -kdb -lca -debug_access+all -cm line+cond+fsm+tgl+assert+path +lint=TFIPC-L
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# For visual debugger
VISFLAGS = -lncurses


##### 
# Modify starting here
#####

##TESTBENCH = 	sys_defs.svh	\
##		ISA.svh         \
##		testbench/mem.sv  \
##		testbench/testbench.sv	\
##		testbench/pipe_print.c	 
##SIMFILES =	verilog/pipeline.sv	\
##		verilog/regfile.sv	\
##		verilog/if_stage.sv	\
##		verilog/id_stage.sv	\
##		verilog/ex_stage.sv	\
##		verilog/mem_stage.sv	\
##		verilog/wb_stage.sv	\

##TESTBENCH =     sys_defs.svh	\
##		testbench/test_top_r10k.sv
TESTBENCH =     sys_defs.svh	\
				ISA.svh \
		testbench/program_dispatch.sv \
		testbench/testbench.sv  \
		testbench/pipe_print.c
##SIMFILES =	verilog/top_rob.sv	\
##		verilog/map_table.sv	\
##		verilog/architecture_table.sv	\
##		verilog/cdb.sv	\
##		verilog/free_list.sv	\
##		verilog/rob.sv		
##SIMFILES =	verilog/free_list.sv
SIMFILES =	verilog/top_r10k.sv	\
		verilog/top_rob.sv	\
		verilog/map_table.sv	\
		verilog/architecture_table.sv	\
		verilog/ex_stage.sv	\
		verilog/free_list.sv	\
		verilog/reservation_station.sv	\
		verilog/rob.sv \
		verilog/regfile.sv \
		verilog/issue_stage.sv


##SYNFILES = synth/pipeline.vg
SYNFILES = synth/top_r10k.vg

# Don't ask me why spell VisUal TestBenchER like this...
VTUBER = sys_defs.svh	\
		ISA.svh         \
		testbench/mem.sv  \
		testbench/visual_testbench.v \
		testbench/visual_c_hooks.cpp \
		testbench/pipe_print.c

##synth/pipeline.vg:        $(SIMFILES) synth/pipeline.tcl
##	cd synth && dc_shell-t -f ./pipeline.tcl | tee synth.out 
##synth/top_r10k.vg:        $(SIMFILES) synth/top_r10k.tcl
##	cd synth && dc_shell-t -f ./top_r10k.tcl | tee synth.out 

synth/top_r10k.vg:        $(SIMFILES) synth/top_r10k.tcl
	cd synth && dc_shell-t -f ./top_r10k.tcl | tee synth.out 

#####
# Should be no need to modify after here
#####
simv:	$(SIMFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SIMFILES)	-o simv

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

verdi_syn:	syn_simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./syn_simv -gui=verdi

# For visual debugger
vis_simv:	$(SIMFILES) $(VTUBER)
	$(VCS) $(VISFLAGS) $(VTUBER) $(SIMFILES) -o vis_simv 
	./vis_simv

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv 

syn:	syn_simv
	./syn_simv | tee syn_program.out


clean:
	rm -rf *simv *simv.daidir csrc vcs.key program.out *.key
	rm -rf vis_simv vis_simv.daidir
	rm -rf dve* inter.vpd DVEfiles
	rm -rf syn_simv syn_simv.daidir syn_program.out
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	rm -f *.elf *.dump *.mem debug_bin
	rm -rf verdi* novas* *fsdb*

nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/command.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl

verdi_cov:	all novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -cm line+cond+fsm+tgl+assert+path -gui=verdi -cov -covdir simv.vdb

