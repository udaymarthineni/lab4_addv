Part 2
From this directory - 
    make sim_clean     # no injected bug
    make sim_bug       # drops write 4, 8, 12, ...; checker should fail
    make clean

Or run any other N:
    make compile
    ./simv +DROP_N=3

The C model never drops data. Only the RTL memory write is suppressed;
the DUT pointer still advances, making incorrect data visible on reads.

