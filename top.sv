//////////////////////////////////////////////////////////////////////////////////
// Company:      	AIKONIC Technologies
// Engineer:       Sailaxmi Anumula
//
// Create Date:    13-09-2025
// Design Name:    AXI3 Verification Top-Level Testbench
// Module Name:    testbench_top
// Project Name:   AXI3 Master Environment
// Target Devices: FPGA / ASIC
// Tool Versions:  Any SystemVerilog compatible simulator (VCS, Questa, etc.)
//
// Description: 
//   Top-level testbench for AXI3 master verification. This module:
//     - Instantiates the AXI3 interfaces and DUT
//     - Connects testcases (programs) to the DUT via interfaces
//     - Generates clock and reset
//     - Dumps waveforms for simulation analysis
//
// Dependencies: 
//   axi3_master_interface.sv
//   axi_master_wrapper.sv
//   axi3_master_test.sv
//   fixed_burst.sv
//   read_write.sv
//   write_read.sv
//   variable_length_fixed_burst.sv
//   increment_burst.sv
//   boundary_condition_4kb.sv
//   configure.sv
//
// Revision:
//   Revision 0.1 - File created by Sailaxmi
//   Revision 0.2 - Binding the assertion file with the the AXI dut
//////////////////////////////////////////////////////////////////////////////////
// `timescale 1ns/1ps
`include "interface.sv"
//`include "axi3_master_test.sv"
`timescale 1ps/1ps
// `define assertions
`ifdef assertions
 `include "assertions.sv"
`endif

`include "test.sv"


module testbench_top;

  parameter DATAWIDTH = 32;
  parameter SIZE      = 3;

  // Clock and Reset
  logic clock;
  logic reset;


  // ---------------------------------------------------
  // Clock Generation
  // ---------------------------------------------------
  always #5 clock = ~clock;

  // ---------------------------------------------------
  // Reset Generation
  // ---------------------------------------------------
  initial begin
    $display("%t testbench top started", $time);
    reset = 0;
    clock = 0;
    #20 reset = 1;
    #13533reset = 0;
    #20 reset = 1;
    #40000 reset = 0;
    #20 reset = 1;
  end

  // ---------------------------------------------------
  // Creating instance of interface to connect DUT
  // ---------------------------------------------------
  axi#(.DATAWIDTH(DATAWIDTH), .SIZE(SIZE)) vif(clock, reset);


  
  test_c    t6(vif);
  
  

  // ---------------------------------------------------
  // DUT Instantiation
  // ---------------------------------------------------
  Master_Axi3Protocol #(.DATAWIDTH(DATAWIDTH), .SIZE(SIZE)) DUT (
    .clock       (vif.clock),
    .reset       (vif.reset),
    .AMBA        (vif.Master),
    .AWaddr      (vif.AWaddr),
    .AWlen       (vif.AWlen),
    .WData       (vif.WData),
    .AWid        (vif.AWid),
    .WStrb       (vif.WStrb),
    .ARid        (vif.ARid),
    .ARlen       (vif.ARlen),
    .AWsize      (vif.AWsize),
    .AWburst     (vif.AWburst),
    .ARaddr      (vif.ARaddr),
    .ARsize      (vif.ARsize),
    .ARburst     (vif.ARburst),
    .read_memory (vif.read_memory)
  );

  `ifdef assertions
  bind Master_Axi3Protocol axi3_dut_assertions #(.DATAWIDTH(DATAWIDTH), .SIZE(SIZE)) axi3_chk (
    .clock   (clock),
    .reset   (reset),

    // DUT signals
    .AWaddr  (AWaddr),
    .AWlen   (AWlen),
    .AWid    (AWid),
    .WData   (WData),
    .WStrb   (WStrb),
    .ARid    (ARid),
    .ARlen   (ARlen),
    .ARaddr  (ARaddr),
    .AWburst (AWburst),
    .ARburst (ARburst),
    .AWsize  (AWsize),
    .ARsize  (ARsize),

    // AMBA.Master signals
    .AWREADY (DUT.AMBA.AWREADY),
    .AWVALID (AMBA.AWVALID),
    .WREADY  (AMBA.WREADY),
    .WVALID  (AMBA.WVALID),
    .WLAST   (AMBA.WLAST),
    .BVALID  (AMBA.BVALID),
    .BREADY  (AMBA.BREADY),
    .ARREADY (AMBA.ARREADY),
    .ARVALID (AMBA.ARVALID),
    .RVALID  (AMBA.RVALID),
    .RREADY  (AMBA.RREADY),
    .RLAST   (AMBA.RLAST),
    .BID     (AMBA.BID),
    .WID     (AMBA.WID)
  );
  `endif
   // Instantiate the test runner
 // test_runner runner;

  initial begin
    #50;
//     runner = new(vif, AMBA);
//     // Run a single testcase
//     runner.run_test("incr_min_len");

    // Or run multiple sequentially
    // runner.run_test("write_read");
    // runner.run_test("read_write");

    //#1250 $finish;
  end
   
  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd");$dumpvars;
    #50
    $display($time, ">>>>>>>>>>>>>>vif.AWREADY)=%d <<<<<<<<<<<<<<<<<<<<<<<<<<", vif.AWVALID);

    #200000 $finish;
  end  
endmodule