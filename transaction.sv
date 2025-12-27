//////////////////////////////////////////////////////////////////////////////////
// Company:        <Your Company Name>
// Engineer:       Sailaxmi Anumula
//
// Create Date:    13-09-2025
// Design Name:    AXI3 Transaction Class
// Module Name:    transaction_c
// Project Name:   AXI3 Verification Environment
// Target Devices: FPGA / ASIC
// Tool Versions:  Any SystemVerilog compatible simulator (VCS, Questa, etc.)
//
// Description: 
//   Class defining AXI3 transactions for verification. Includes:
//     - All AXI3 transaction fields for read/write operations
//     - Randomization constraints for addresses, burst types, lengths, and sizes
//     - Utility function to display transaction details
//     - Optional mirrored memory for checking read data
//
// Dependencies: 
//   None (standalone class)
//
// Revision:
//   Revision 0.1 - File created by Sailaxmi
//////////////////////////////////////////////////////////////////////////////////


`ifndef TRANSACTION_C
`define TRANSACTION_C

class transaction_c #(parameter DATAWIDTH = 32, SIZE = 3);

  // ---------------------------------------------------
  // Transaction Fields
  // ---------------------------------------------------
  rand bit [DATAWIDTH-1:0]      AWaddr;
  rand bit [DATAWIDTH-1:0]      WData;
  rand bit [(DATAWIDTH/8)-1:0]  AWlen;
  rand bit [(DATAWIDTH/8)-1:0]  AWid;
  rand bit [(DATAWIDTH/8)-1:0]  WStrb;
  rand bit [(DATAWIDTH/8)-1:0]  ARid;
  rand bit [(DATAWIDTH/8)-1:0]  ARlen;
  rand bit [SIZE-2:0]           AWsize;
  rand bit [SIZE-2:0]           AWburst;
  rand bit [DATAWIDTH-1:0]      ARaddr;
  rand bit [SIZE-2:0]           ARsize;
  rand bit [SIZE-2:0]           ARburst;
  rand bit [DATAWIDTH-1:0]      RData;

  rand bit transaction_type; // 0 = Write, 1 = Read

  // Mirror memory (optional)
  bit [4095:0][7:0] read_memory;
  bit [4095:0][7:0] scb_memory;

  bit [DATAWIDTH-1:0] scb_rdata;
  // ---------------------------------------------------
  // Utility: Display transaction content
  // ---------------------------------------------------
  function void display(string name);
    $display("-------------------------");
    $display($time,"- %s ", name);
    $display("-------------------------");
    $display("AWaddr = %0h, WData = %0h", AWaddr, WData);
    $display("AWlen = %0h, AWid = %0h, WStrb = %0h", AWlen, AWid, WStrb);
    $display("AWsize = %0h, AWburst = %0h", AWsize, AWburst);
    $display("ARaddr = %0h, ARlen = %0h, ARid = %0h", ARaddr, ARlen, ARid);
    $display("ARsize = %0h, ARburst = %0h", ARsize, ARburst);
//     for (int i = 0; i <= AWlen; i++)begin
//       if(transaction_type == 0)
//         $display("read_memory = %h",scb_memory[AWaddr + i * (1 << AWsize)+i]);
//     end
//     for (int i = 0; i <= ARlen; i++)begin
//       if(transaction_type == 1)
//         $display("read_memory = %h",read_memory[ARaddr]);
//     end
    $display("transaction_type = %0d", transaction_type);
    $display("-------------------------");
  endfunction

  // ---------------------------------------------------
  // Constraints
  // ---------------------------------------------------
  constraint c_awaddr_range { soft (AWaddr > 32'h5ff) && (AWaddr <= 32'hfff); }
  constraint c_araddr_range { soft (ARaddr > 32'h5ff) && (ARaddr <= 32'hfff); }

  // AXI burst type (AWBURST/ARBURST): 0=FIXED, 1=INCR, 2=WRAP
  constraint c_awburst { soft AWburst inside {[0:2]}; }
  constraint c_arburst { soft ARburst inside {[0:2]}; }

  // Wrap burst alignment: address aligned to burst length
//  constraint c_awaddr_wrap_alignment {
//    if (AWburst == 2) {
//      (AWaddr % ((1 << AWsize) * (AWlen + 1))) == 0;
//      AWlen inside {1, 3, 7, 15};
//    }
//  }

  constraint c_awlen { AWlen inside {[0:15]}; }
  constraint c_arlen { ARlen inside {[0:15]}; }

  // AXI burst size (AWSIZE/ARSIZE) = log2(bytes per transfer)
      constraint c_awsize { soft AWsize == $clog2(DATAWIDTH/8); }
      constraint c_arsize { soft ARsize == $clog2(DATAWIDTH/8); }

  // WStrb: Write strobe. Ensure at least one byte written.
  // For DATAWIDTH=32, WStrb is 4 bits wide.
      constraint c_wstrb { soft WStrb == 4'b1111; }
      
      constraint c_wdata { soft WData dist{ 32'hAAAAAAAA := 4, 32'h55555555 :=4, 32'd0 := 4, 32'hFFFFFFFF := 4};}

 

endclass

`endif
