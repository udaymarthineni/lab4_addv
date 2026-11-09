# Part 3 – How to Run

Run everything from the `sim/` directory (VCS and Verdi must be set up, with `VCS_HOME` and `VERDI_HOME` defined).

1. Clean and compile (also builds the Verdi database and enables the waveform dump):

```
make clean
make compile_verdi
```

2. Run the simulation with each logger setting (plusarg `+LOG_LEVEL`: 0 = off, 1 = brief, 2 = detailed):

```
./simv +LOG_LEVEL=0 | tee log0.txt
./simv +LOG_LEVEL=1 | tee log1.txt
./simv +LOG_LEVEL=2 | tee log2.txt
```

3. Open the waveform in Verdi:

```
make verdi
```

The run is successful when the end of the output shows `SCB RESULT: PASS`.
