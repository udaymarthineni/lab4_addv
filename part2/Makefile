FILES = fifo1.sv fifomem.sv rptr_empty.sv sync_r2w.sv sync_w2r.sv wptr_full.sv fifo_dpi_pkg.sv fifo_checker.sv fifo_tb.sv fifo_model.c

compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(FILES) -top fifo_tb -debug_access+all

compile_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(FILES) -top fifo_tb -debug_access+all -kdb -lca

sim:
	./simv

verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -nologo

waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -play waves.tcl -nologo &

sim_clean: compile_verdi
	./simv -l sim_clean.log && ( $(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -play waves.tcl -nologo & )

sim_bug: compile_verdi
	./simv +DROP_N=4 -l sim_bug.log; ( $(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -play waves.tcl -nologo & )

clean:
	rm -rf simv simv.daidir csrc *.log *.fsdb
