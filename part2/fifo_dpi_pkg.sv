package fifo_dpi_pkg;
    import "DPI-C" function void fifo_init();
    import "DPI-C" function int fifo_push(input int data);
    import "DPI-C" function int fifo_pop();
    import "DPI-C" function int fifo_is_empty();
    import "DPI-C" function int fifo_is_full();
    import "DPI-C" function int fifo_get_count();
    import "DPI-C" function int fifo_peek();
    import "DPI-C" function int fifo_is_almost_full();
    import "DPI-C" function int fifo_is_almost_empty();
endpackage
