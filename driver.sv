
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.12.2025 23:36:18
// Design Name: 
// Module Name: driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



  `include "interface.sv"
  `include "transaction.sv"
  
`ifndef DRIVER_C
`define DRIVER_C

class driver_c #(parameter DATAWIDTH = 32, SIZE = 3);

  transaction_c #(DATAWIDTH, SIZE) trans;
  transaction_c #(DATAWIDTH, SIZE) trans1;

  // Virtual interface
  virtual axi #(DATAWIDTH, SIZE) vif;

  // Mailboxes
  mailbox gen2driv;
  mailbox driv2scb;

  int     no_transactions;
  int     AWADDR_r;
  int     beat_addr;

  // Local memory (byte-addressable)
  logic [4095:0][7:0] slave_memory;
  logic [DATAWIDTH-1:0] rdata_word;

  // Constructor
  function new(mailbox gen2driv,
               mailbox driv2scb,
               virtual axi #(DATAWIDTH, SIZE) vif);
    this.gen2driv = gen2driv;
    this.driv2scb = driv2scb;
    this.vif      = vif;
    this.trans    = new();
    this.trans1   = new();
    $display("%%%%%%%%%%%%%%%%%%%% dri created %%%%%%%%%%%%%%%%%%%%");
  endfunction

  // RESET TASK
  task reset;
    wait (!vif.reset);
    $display("[%0t][DRIVER] Reset asserted", $time);

    vif.AWaddr   <= '0;
    vif.AWlen    <= '0;
    vif.AWid     <= '0;
    vif.AWsize   <= '0;
    vif.AWburst  <= '0;

    vif.WData    <= '0;
    vif.WStrb    <= '0;

    vif.ARaddr   <= '0;
    vif.ARlen    <= '0;
    vif.ARid     <= '0;
    vif.ARsize   <= '0;
    vif.ARburst  <= '0;

    vif.AWREADY  <= 1'b0;
    vif.WREADY   <= 1'b0;
    vif.BVALID   <= 1'b0;
    vif.BID      <= '0;
    vif.BRESP    <= '0;

    vif.ARREADY  <= 1'b0;
    vif.RID      <= '0;
    vif.RDATA    <= '0;
    vif.RRESP    <= '0;
    vif.RLAST    <= 1'b0;
    vif.RVALID   <= 1'b0;

    for (int i = 0; i < 4096; i++) begin
      slave_memory[i] = '0;
    end

    wait (vif.reset);
    $display("[%0t][DRIVER] Reset deasserted", $time);
  endtask

  // MAIN DRIVER LOOP
  task main;
    transaction_c #(DATAWIDTH, SIZE) t;
    forever begin
      gen2driv.get(t);
      if (t == null) $fatal("[%0t][DRIVER] Null transaction received", $time);

      if (t.transaction_type == 1'b0)
        drive_write_transaction(t);
      else
        drive_read_transaction(t);

      no_transactions++;
    end
  endtask

  int number_bytes;
  int burst_length;
  int wrap_boundary;
  int wrap_size;
  int wrap_base;
  int offset;
  // WRITE TRANSACTION
  task drive_write_transaction(transaction_c #(DATAWIDTH, SIZE) trans);
    $display("[%0t][DRIVER] WRITE transaction start", $time);

    @(posedge vif.clock);
    vif.AWaddr   <= trans.AWaddr;
    vif.AWlen    <= trans.AWlen;
    vif.AWid     <= trans.AWid;
    vif.AWsize   <= trans.AWsize;
    vif.AWburst  <= trans.AWburst;

    vif.AWREADY  <= 1'b1;
    wait (vif.AWVALID == 1'b1);

    AWADDR_r = vif.AWaddr;

    @(posedge vif.clock);
    vif.AWREADY  <= 1'b0;

    for (int i = 0; i <= trans.AWlen; i++) begin
      trans1 = new();

      std::randomize(trans.WData)
      with { soft trans.WData dist{ 32'hAAAAAAAA := 10, 32'h55555555 := 10, 32'd0 := 1, 32'hFFFFFFFF := 10,[32'h80000000:32'hFFFFFFFF] := 1, [32'h00000000:32'h7FFFFFFF] := 1};};

      vif.WData     <= trans.WData;
      vif.WStrb     <= trans.WStrb;

      case (trans.AWburst)
        2'b00: begin beat_addr = trans.AWaddr;
          trans1.AWaddr = beat_addr;
        end
        2'b01: begin
          beat_addr = trans.AWaddr + i * (1 << trans.AWsize);
          trans1.AWaddr = beat_addr;
        end
        2'b10: begin
          number_bytes = (1 << trans.AWsize);          // bytes per beat
          burst_length = (trans.AWlen + 1);            // beats in burst
          wrap_size  = number_bytes * burst_length;

          // Base of wrap region
          wrap_base  = (trans.AWaddr / wrap_size) * wrap_size;

          // Offset of current beat within wrap region
          offset     = (trans.AWaddr % wrap_size) + i * number_bytes;
          if (offset >= wrap_size)
            offset -= wrap_size;

          beat_addr      = wrap_base + offset;
          trans1.AWaddr  = beat_addr;
        end
        default: begin beat_addr = trans.AWaddr;
          trans1.AWaddr = beat_addr;
        end
      endcase
//       trans1.AWaddr = beat_addr;
      trans1.WData  = trans.WData;
      trans1.WStrb  = trans.WStrb;
      trans1.AWid   = trans.AWid;
      trans1.AWlen   = trans.AWlen;
      trans1.AWsize    = trans.AWsize ;
      trans1.AWburst    = trans.AWburst ;
      trans1.transaction_type = trans.transaction_type;

      driv2scb.put(trans1);
//       trans1.display("  [driver] to scb (write beat)");

      @(posedge vif.clock);
      vif.WREADY <= 1'b1;
      if(trans.AWaddr > 32'h5ff && trans.AWaddr <= 32'hfff && trans.AWsize < 2'b11)
        wait (vif.WVALID == 1'b1);
      else
        vif.WREADY <= 1'b0;
      

      for (int b = 0; b < DATAWIDTH/8; b++) begin
        if (vif.WStrb[b]) begin
          if (beat_addr + b < 4096) begin
            slave_memory[beat_addr + b] = vif.WData[b*8 +: 8];
            trans1.scb_memory[beat_addr + b] = vif.WData[b*8 +: 8];
          end
        end
      end

      @(posedge vif.clock);
      @(posedge vif.clock);
      vif.WREADY <= 1'b0;
    end

    @(posedge vif.clock);
    vif.BID    <= trans.AWid;
    vif.BRESP  <= (trans.AWaddr < 32'h600) ? 2'b00 : 2'b10;
    vif.BVALID <= 1'b1;

    wait (vif.BREADY == 1'b1);
    @(posedge vif.clock);
    vif.BVALID <= 1'b0;

//     $display("[%0t][DRIVER] WRITE transaction end", $time);
  endtask

//   int number_bytes;
//   int burst_length;
//   int wrap_boundary;
//   int wrap_size;
//   int wrap_base;
//   int offset;
  // READ TRANSACTION
  task drive_read_transaction(transaction_c #(DATAWIDTH, SIZE) trans);
//     $display("[%0t][DRIVER] READ transaction start", $time);

    @(posedge vif.clock);
    vif.ARaddr  <= trans.ARaddr;
    vif.ARlen   <= trans.ARlen;
    vif.ARid    <= trans.ARid;
    vif.ARsize  <= trans.ARsize;
    vif.ARburst <= trans.ARburst;

    vif.ARREADY <= 1'b1;
    if(trans.ARaddr > 32'h5ff && trans.ARaddr <= 32'hfff && trans.ARsize < 2'b11)
      wait (vif.ARVALID == 1'b1);
    else begin
      vif.ARREADY <= 1'b0;
      //vif.RLAST  <= 1;
    end
    
    @(posedge vif.clock);
    vif.ARREADY <= 1'b0;

    for (int i = 0; i <= trans.ARlen; i++) begin
      trans1 = new();
      case (trans.ARburst)
        2'b00: begin beat_addr = trans.ARaddr;
          trans1.ARaddr = beat_addr;
        end
        2'b01: begin beat_addr = trans.ARaddr + i * (1 << trans.ARsize);
          trans1.ARaddr = beat_addr;
        end
        2'b10: begin
          // WRAP burst logic (correct AXI formula)
          number_bytes = (1 << trans.ARsize);      // bytes per beat
          burst_length = (trans.ARlen + 1);        // number of beats
          wrap_size = number_bytes * burst_length;

          // Base of wrap region
          wrap_base = (trans.ARaddr / wrap_size) * wrap_size;

          // Offset for current beat
          offset = (trans.ARaddr % wrap_size) + i * number_bytes;
          if (offset >= wrap_size)
            offset -= wrap_size;                  // wrap around

          beat_addr = wrap_base + offset;
          trans1.ARaddr = beat_addr;
        end
        default: begin beat_addr = trans.ARaddr;
          trans1.ARaddr = beat_addr;
        end
      endcase

      trans1.ARid      = trans.ARid;
      trans1.ARaddr    = beat_addr;
      trans1.ARsize    = trans.ARsize;
      trans1.ARburst   = trans.ARburst;
      trans1.scb_rdata = rdata_word;
      trans1.transaction_type = trans.transaction_type;
      
      driv2scb.put(trans1);
//       trans1.display("  [driver] to scb (read beat)");
      
      rdata_word = {
        slave_memory[beat_addr+3],
        slave_memory[beat_addr+2],
        slave_memory[beat_addr+1],
        slave_memory[beat_addr+0]
      };


      @(posedge vif.clock);
      vif.RID    <= trans.ARid;
      vif.RDATA  <= rdata_word;
      vif.RRESP  <= 2'b00;
      vif.RLAST  <= (i == trans.ARlen);
      vif.RVALID <= 1'b1;
      
//       driv2scb.put(trans1);
//       trans1.display("  [driver] to scb (read beat)");

      wait (vif.RREADY == 1'b1);
      @(posedge vif.clock);
      vif.RVALID <= 1'b0;
      vif.RLAST  <= 1'b0;

//       driv2scb.put(trans1);
//       trans1.display("  [driver] to scb (read beat)");
    end

//     $display("[%0t][DRIVER] READ transaction end", $time);
  endtask

endclass : driver_c

`endif

//`include "interface.sv"
//`include "transaction.sv"
//`ifndef DRIVER_C
//`define DRIVER_C

//class driver_c #(parameter DATAWIDTH = 32, SIZE = 3);

//  transaction_c #(DATAWIDTH, SIZE) trans;
//  transaction_c #(DATAWIDTH, SIZE) trans1;

//  // Virtual interface
//  virtual axi #(DATAWIDTH, SIZE) vif;

//  // Mailboxes
//  mailbox gen2driv;
//  mailbox driv2scb;

//  int     no_transactions;
//  int     AWADDR_r;
//  int     beat_addr;

//  // Local memory (byte-addressable)
//  logic [4095:0][7:0] slave_memory;
//  logic [DATAWIDTH-1:0] rdata_word;

//  // Constructor
//  function new(mailbox gen2driv,
//               mailbox driv2scb,
//               virtual axi #(DATAWIDTH, SIZE) vif);
//    this.gen2driv = gen2driv;
//    this.driv2scb = driv2scb;
//    this.vif      = vif;
//    this.trans    = new();
//    this.trans1   = new();
//    $display("%%%%%%%%%%%%%%%%%%%% dri created %%%%%%%%%%%%%%%%%%%%");
//  endfunction

//  // RESET TASK
//  task reset;
//    wait (!vif.reset);
//    $display("[%0t][DRIVER] Reset asserted", $time);

//    vif.AWaddr   <= '0;
//    vif.AWlen    <= '0;
//    vif.AWid     <= '0;
//    vif.AWsize   <= '0;
//    vif.AWburst  <= '0;

//    vif.WData    <= '0;
//    vif.WStrb    <= '0;

//    vif.ARaddr   <= '0;
//    vif.ARlen    <= '0;
//    vif.ARid     <= '0;
//    vif.ARsize   <= '0;
//    vif.ARburst  <= '0;

//    vif.AWREADY  <= 1'b0;
//    vif.WREADY   <= 1'b0;
//    vif.BVALID   <= 1'b0;
//    vif.BID      <= '0;
//    vif.BRESP    <= '0;

//    vif.ARREADY  <= 1'b0;
//    vif.RID      <= '0;
//    vif.RDATA    <= '0;
//    vif.RRESP    <= '0;
//    vif.RLAST    <= 1'b0;
//    vif.RVALID   <= 1'b0;

//    for (int i = 0; i < 4096; i++) begin
//      slave_memory[i] = '0;
//    end

//    wait (vif.reset);
//    $display("[%0t][DRIVER] Reset deasserted", $time);
//  endtask

//  // MAIN DRIVER LOOP
//  task main;
//    transaction_c #(DATAWIDTH, SIZE) t;
//    forever begin
//      gen2driv.get(t);
//      //if (t == null) $fatal("[%0t][DRIVER] Null transaction received", $time);

//      if (t.transaction_type == 1'b0)
//        drive_write_transaction(t);
//      else
//        drive_read_transaction(t);

//      no_transactions++;
//    end
//  endtask

////internal variables for wrap condition
//  int number_bytes;
//  int burst_length;
//  int wrap_boundary;
//  int wrap_size;
//  int wrap_base;
//  int offset;
//  // WRITE TRANSACTION
//  task drive_write_transaction(transaction_c #(DATAWIDTH, SIZE) trans);
//    $display("[%0t][DRIVER] WRITE transaction start", $time);

//    @(posedge vif.clock);
//    if(vif.reset)begin
//    vif.AWaddr   <= trans.AWaddr;
//    vif.AWlen    <= trans.AWlen;
//    vif.AWid     <= trans.AWid;
//    vif.AWsize   <= trans.AWsize;
//    vif.AWburst  <= trans.AWburst;

//    vif.AWREADY  <= 1'b1;
//    wait (vif.AWVALID == 1'b1);

//    AWADDR_r = vif.AWaddr;

//    @(posedge vif.clock);
//    vif.AWREADY  <= 1'b0;

//    for (int i = 0; i <= trans.AWlen; i++) begin
//      trans1 = new();

//      std::randomize(trans.WData)
//      with { soft trans.WData dist{ 32'hAAAAAAAA := 10, 32'h55555555 := 10, 32'd0 := 1, 32'hFFFFFFFF := 10, [32'h80000000:32'hFFFFFFFF] := 1, [32'h00000000:32'h7FFFFFFF] := 1};};

//      vif.WData     <= trans.WData;
//      vif.WStrb     <= trans.WStrb;

//      case (trans.AWburst)
//        2'b00: begin beat_addr = trans.AWaddr;
//          trans1.AWaddr = beat_addr;
//        end
//        2'b01: begin
//          beat_addr = trans.AWaddr + i * (1 << trans.AWsize);
//          trans1.AWaddr = beat_addr;
//        end
//        2'b10: begin
//         number_bytes = (1 << trans.AWsize);          // bytes per beat
//          burst_length = (trans.AWlen + 1);            // beats in burst
//          wrap_size  = number_bytes * burst_length;

//          // Base of wrap region
//          wrap_base  = (trans.AWaddr / wrap_size) * wrap_size;

//          // Offset of current beat within wrap region
//          offset     = (trans.AWaddr % wrap_size) + i * number_bytes;
//          if (offset >= wrap_size)
//            offset -= wrap_size;

//          beat_addr      = wrap_base + offset;
//          trans1.AWaddr  = beat_addr;
//        end
//        default: begin beat_addr = trans.AWaddr;
//          trans1.AWaddr = beat_addr;
//        end
//      endcase
////       trans1.AWaddr = beat_addr;
//      trans1.WData  = trans.WData;
//      trans1.WStrb  = trans.WStrb;
//      trans1.AWid   = trans.AWid;
//      trans1.AWlen   = trans.AWlen;
//      trans1.AWsize    = trans.AWsize ;
//      trans1.AWburst    = trans.AWburst ;
//      trans1.transaction_type = trans.transaction_type;

//      driv2scb.put(trans1);
//      trans1.display("  [driver] to scb (write beat)");

//      @(posedge vif.clock);
//      vif.WREADY <= 1'b1;
//      wait (vif.WVALID == 1'b1);

//      for (int b = 0; b < DATAWIDTH/8; b++) begin
//        if (vif.WStrb[b]) begin
//          if (beat_addr + b < 4096) begin
//            slave_memory[beat_addr + b] = vif.WData[b*8 +: 8];
//            trans1.scb_memory[beat_addr + b] = vif.WData[b*8 +: 8];
//          end
//        end
//      end

//      @(posedge vif.clock);
//      @(posedge vif.clock);
//      vif.WREADY <= 1'b0;
//    end

//    @(posedge vif.clock);
//    vif.BID    <= trans.AWid;
//    vif.BRESP  <= (trans.AWaddr < 32'h600) ? 2'b00 : 2'b10;
//    vif.BVALID <= 1'b1;

//    wait (vif.BREADY == 1'b1);
//    @(posedge vif.clock);
//    vif.BVALID <= 1'b0;

//    $display("[%0t][DRIVER] WRITE transaction end", $time);
//    end else begin
//     reset();
//    end
//  endtask

//  // READ TRANSACTION
//  task drive_read_transaction(transaction_c #(DATAWIDTH, SIZE) trans);
//    $display("[%0t][DRIVER] READ transaction start", $time);

//    @(posedge vif.clock);
//    if(vif.reset)begin
//    vif.ARaddr  <= trans.ARaddr;
//    vif.ARlen   <= trans.ARlen;
//    vif.ARid    <= trans.ARid;
//    vif.ARsize  <= trans.ARsize;
//    vif.ARburst <= trans.ARburst;

//    vif.ARREADY <= 1'b1;
//    wait (vif.ARVALID == 1'b1);
//    @(posedge vif.clock);
//    vif.ARREADY <= 1'b0;

//    for (int i = 0; i <= trans.ARlen; i++) begin
//      trans1 = new();
//      case (trans.ARburst)
//        2'b00: begin beat_addr = trans.ARaddr;
//          trans1.ARaddr = beat_addr;
//        end
//        2'b01: begin beat_addr = trans.ARaddr + i * (1 << trans.ARsize);
//          trans1.ARaddr = beat_addr;
//        end
//        2'b10: begin
//          // WRAP burst logic (correct AXI formula)
//          number_bytes = (1 << trans.ARsize);      // bytes per beat
//          burst_length = (trans.ARlen + 1);        // number of beats
//          wrap_size = number_bytes * burst_length;

//          // Base of wrap region
//          wrap_base = (trans.ARaddr / wrap_size) * wrap_size;

//          // Offset for current beat
//          offset = (trans.ARaddr % wrap_size) + i * number_bytes;
//          if (offset >= wrap_size)
//            offset -= wrap_size;                  // wrap around

//          beat_addr = wrap_base + offset;
//          trans1.ARaddr = beat_addr;
//        end
//        default: begin beat_addr = trans.ARaddr;
//          trans1.ARaddr = beat_addr;
//        end
//      endcase

//      trans1.ARid      = trans.ARid;
//       trans1.ARaddr    = beat_addr;
//      trans1.ARsize    = trans.ARsize;
//      trans1.ARburst   = trans.ARburst;
//      trans1.scb_rdata = rdata_word;
//      trans1.transaction_type = trans.transaction_type;
      
////       driv2scb.put(trans1);
////       trans1.display("  [driver] to scb (read beat)");
      
//      rdata_word = {
//        slave_memory[beat_addr+3],
//        slave_memory[beat_addr+2],
//        slave_memory[beat_addr+1],
//        slave_memory[beat_addr+0]
//      };


//      @(posedge vif.clock);
//      vif.RID    <= trans.ARid;
//      vif.RDATA  <= rdata_word;
//      vif.RRESP  <= 2'b00;
//      vif.RLAST  <= (i == trans.ARlen);
//      vif.RVALID <= 1'b1;
      
//      driv2scb.put(trans1);
//      trans1.display("  [driver] to scb (read beat)");

//      wait (vif.RREADY == 1'b1);
//      @(posedge vif.clock);
//      vif.RVALID <= 1'b0;
//      vif.RLAST  <= 1'b0;

////       driv2scb.put(trans1);
////       trans1.display("  [driver] to scb (read beat)");
//    end

//    $display("[%0t][DRIVER] READ transaction end", $time);
//    end else begin
//     reset();
//    end
//  endtask

//endclass : driver_c

//`endif

