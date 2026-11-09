FILES = fifo_syn.sv even_odd_alternating.sv tb.sv

compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(FILES) -top tb -debug_access+all -kdb -lca -assert enable_diag

sim_clean: compile
	./simv +fsdb+sva_success -assert success+filter+report -l sim_clean.log

sim_bug: compile
	./simv +EO_BUG +fsdb+sva_success -assert success+filter+report -l sim_bug.log

waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf eo_clean.fsdb -play waves.tcl -nologo &

waves_bug:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf eo_bug.fsdb -play waves.tcl -nologo &

clean:
	rm -rf simv simv.daidir csrc *.log *.fsdb assert.report
