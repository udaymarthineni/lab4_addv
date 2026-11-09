 This folders contains the SVA for the even odd FIFO implementation 
## Files
- `even_odd_alternating.sv` — Even-odd circuit, SVA assertions, and error injection.
- `fifo_syn.sv` — Synchronous FIFO design.
- `tb.sv` — Testbench and waveform dumping.
- `waves.tcl` — Automatically loads signals and assertions in Verdi.
- `Makefile` — Compilation and simulation commands.

## Running the Simulation
Clean simulation:
    make sim_clean
    make waves_verdi

Bug-injected simulation:

    make sim_bug
    make waves_bug
Cleanup:
    make clean

## Expected Results

- **Clean simulation:** Assertions pass without failures.
- **Bug simulation:** Assertion `a5` fails due to corrupted output data.
- **Terminal logs:** `sim_clean.log` and `sim_bug.log`.

