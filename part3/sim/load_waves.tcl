# ============================================================
#  load_waves.tcl  -  fifo_tb (async FIFO)
# ============================================================
set FSDB "novas.fsdb"
set TB   "/fifo_tb"
set WR   "/fifo_tb/wr_bus"
set RD   "/fifo_tb/rd_bus"
set DUT  "/fifo_tb/dut"

# Adds a named group of signals
proc add_group {name scope sigs} {
    global _nWave2
    wvSetPosition -win $_nWave2 "(\"$name\" 0)"
    set n 0
    foreach s $sigs {
        wvAddSignal -win $_nWave2 "$scope/$s"
        incr n
    }
    wvSetPosition -win $_nWave2 "(\"$name\" $n)"
}

wvCreateWindow
wvOpenFile -win $_nWave2 [file normalize $FSDB]
wvGetSignalOpen -win $_nWave2

# ---------------- Write interface (wclk domain) ----------------
add_group "WR_interface" $WR {
    wclk wrst_n winc wdata[7:0] wfull almost_wfull
}

# ---------------- Read interface (rclk domain) ----------------
add_group "RD_interface" $RD {
    rclk rrst_n rinc rdata[7:0] rempty almost_rempty
}

# ---------------- DUT internals: pointers and addresses ----------------
add_group "DUT_write_side" $DUT {
    waddr[3:0] wptr[4:0] wq2_rptr[4:0]
}
add_group "DUT_read_side" $DUT {
    raddr[3:0] rptr[4:0] rq2_wptr[4:0]
}

# ---------------- wptr_full (write pointer / full logic) ----------------
add_group "wptr_full" "$DUT/wptr_full" {
    wbin[4:0] wgraynext[4:0] wbinnext[4:0] rbinnext[4:0] almost_wfull_val
}

# ---------------- rptr_empty (read pointer / empty logic) ----------------
add_group "rptr_empty" "$DUT/rptr_empty" {
    rbin[4:0] rgraynext[4:0] rbinnext[4:0] wbinnext[4:0] almost_rempty_val
}

wvGetSignalClose -win $_nWave2
wvZoomAll -win $_nWave2
