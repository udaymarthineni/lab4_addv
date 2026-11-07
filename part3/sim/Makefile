# ============================================================
#  EDIT THIS SECTION ONLY
# ============================================================
TOP        = fifo_tb

# SystemVerilog sources: DUT first, testbench last (the interfaces live in fifo1.sv)

SRC_FILES  =  ../fifo_tb_m.sv ../fifo1.sv  ../fifomem.sv   ../rptr_empty.sv ../wptr_full.sv ../sync_r2w.sv ../sync_w2r.sv 



# Logger level for the sim targets: make sim LOG=0 | 1 | 2
LOG        = 0

EXTRA_OPTS = +define+FSDB


SHELL      = /bin/bash
VCS        = ${VCS_HOME}/bin/vcs
VCS_FLAGS  = -full64 -sverilog -debug_access+all $(EXTRA_OPTS)

all: clean compile_and_sim

# compile + run in one step
compile_and_sim:
	$(VCS) -R $(VCS_FLAGS) $(SRC_FILES) $(C_FILES) +LOG_LEVEL=$(LOG) 2>&1 | tee compile_and_sim.log

compile:
	$(VCS) $(VCS_FLAGS) $(SRC_FILES) $(C_FILES) 2>&1 | tee compile.log

compile_verdi:
	$(VCS) $(VCS_FLAGS) -kdb -lca $(SRC_FILES) $(C_FILES) 2>&1 | tee compile_verdi.log

# run an already-compiled simv with the chosen logger level
sim:
	./simv +LOG_LEVEL=$(LOG) 2>&1 | tee sim_log$(LOG).log

# the three logger runs needed for the report
log0: ; ./simv +LOG_LEVEL=0 2>&1 | tee log0.txt
log1: ; ./simv +LOG_LEVEL=1 2>&1 | tee log1.txt
log2: ; ./simv +LOG_LEVEL=2 2>&1 | tee log2.txt


verdi:

	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -nologo -play load_waves.tcl &

waves_verdi: verdi

clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.txt novas.conf novas.rc verdi_config_file verdiLog novas.fsdb novas.log novas_dump.log

.PHONY: all compile_and_sim compile compile_verdi sim log0 log1 log2 verdi waves_verdi clean
