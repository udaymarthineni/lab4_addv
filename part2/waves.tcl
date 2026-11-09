set win ""
foreach name {_nWave3 _nWave2 _nWave1} {
    if {$win eq "" && [info exists ::$name]} {
        set win [set ::$name]
    }
}
wvGetSignalOpen -win $win
wvGetSignalSetScope -win $win /fifo_tb
# Write checking
foreach s [list /fifo_tb/bus/wclk /fifo_tb/bus/winc /fifo_tb/bus/wdata /fifo_tb/checker/writes] { wvAddSignal -win $win $s }
# Read checking
foreach s [list /fifo_tb/bus/rclk /fifo_tb/bus/rinc /fifo_tb/bus/rdata /fifo_tb/checker/expected_data /fifo_tb/checker/reads] { wvAddSignal -win $win $s }
# Full and empty checking
foreach s [list /fifo_tb/bus/wfull /fifo_tb/checker/model_full /fifo_tb/checker/full_checks /fifo_tb/bus/rempty /fifo_tb/checker/model_empty /fifo_tb/checker/empty_checks] { wvAddSignal -win $win $s }
# Additional checks and errors
foreach s [list /fifo_tb/bus/almost_wfull /fifo_tb/checker/model_almost_full /fifo_tb/bus/almost_rempty /fifo_tb/checker/model_almost_empty /fifo_tb/checker/head_data /fifo_tb/checker/fwft_idle_checks /fifo_tb/checker/errors] { wvAddSignal -win $win $s }


#foreach s [list /fifo_tb/bus/wclk /fifo_tb/bus/rclk /fifo_tb/bus/winc /fifo_tb/bus/wdata /fifo_tb/bus/wfull /fifo_tb/bus/rinc /fifo_tb/bus/rdata /fifo_tb/bus/rempty /fifo_tb/checker/expected_data /fifo_tb/checker/errors /fifo_tb/dut/fifomem/write_number] { wvAddSignal -win $win $s }
#foreach s [list /fifo_tb/checker/writes /fifo_tb/checker/reads /fifo_tb/checker/full_checks /fifo_tb/checker/empty_checks /fifo_tb/checker/model_full /fifo_tb/checker/model_empty] { wvAddSignal -win $win $s 
#foreach s [list /fifo_tb/bus/almost_wfull /fifo_tb/bus/almost_rempty] { wvAddSignal -win $win $s }
#foreach s [list /fifo_tb/checker/head_data /fifo_tb/checker/model_almost_full /fifo_tb/checker/model_almost_empty /fifo_tb/checker/almost_full_checks /fifo_tb/checker/almost_empty_checks /fifo_tb/checker/fwft_checks /fifo_tb/checker/fwft_idle_checks] { wvAddSignal -win $win $s }}
wvGetSignalClose -win $win
wvZoomAll -win $win
