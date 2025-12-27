//////////////////////////////////////////////////////////////////////////////////
// Company:        <Your Company Name>
// Engineer:       Sailaxmi Anumula
//
// Create Date:    13-09-2025
// Design Name:    AXI3 Verification Test
// Module Name:    test_c
// Project Name:   AXI3 Master Environment
// Target Devices: FPGA / ASIC
// Tool Versions:  Any SystemVerilog compatible simulator (VCS, Questa, etc.)
//
// Description: 
//   Top-level test program that:
//     - Instantiates the AXI3 master environment
//     - Configures the transaction generator repeat count
//     - Starts simulation for AXI read/write transactions
//
// Dependencies: 
//   - axi3_master_env.sv
//   - configure.sv
//
// Revision:
//   Revision 0.1 - File created by Sailaxmi
//////////////////////////////////////////////////////////////////////////////////


`include "interface.sv"
`include "enviornment.sv"
`ifndef test 
`define test
program test_c (axi vif);

  // Environment and configuration handles
  environment_c env;
  
  initial begin
    // Create environment instance (with vif, interface, and config)
    env = new(vif);
    
    // Configure generator repeat count
    
    // Start environment execution
    env.run();
  end

endprogram
`endif
