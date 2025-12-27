`include "interface.sv"
`ifndef SCOREBOARD_C 
`define SCOREBOARD_C 
`define compare_logic_en
class scoreboard_c #(
  parameter DATAWIDTH = 32,
  parameter SIZE      = 3,      // matches axi #(DATAWIDTH, SIZE)
  parameter MSIZE     = 4096    // reference memory size in bytes
);

  // Mailboxes and virtual interfaces
  mailbox mon2scb;
  mailbox driv2scb;
  virtual axi #(DATAWIDTH, SIZE) vif;

  // Reference memory model (byte-addressable)
  bit [MSIZE-1:0][7:0] ref_memory;
  
  //events
  event check;
  event ckeck1 = check;

  // Bookkeeping
  transaction_c #(DATAWIDTH, SIZE) tr;   // from driver (expected)
  transaction_c #(DATAWIDTH, SIZE) tr1;  // from monitor (actual)
  integer error_count;

  // -----------------------------------------
  // Constructor
  // -----------------------------------------
  function new( transaction_c tr , tr1,
    mailbox mon2scb,
               mailbox driv2scb,
               virtual axi #(DATAWIDTH, SIZE) vif);
    this.mon2scb  = mon2scb;
    this.driv2scb = driv2scb;
    this.vif      = vif;
    this.tr       = tr;
    this.tr1      = tr1;
    error_count   = 0;
    $display("%%%%%%%%%%%%%%%%%%%% scb created %%%%%%%%%%%%%%%%%%%%");

  endfunction



  //variables for write trans
  int beat, nbeats, bytes_per_xfer;
  int base_addr, eff_base;

//   //variables for read trans
  logic [DATAWIDTH-1:0] expected_word, actual_word;

  // -----------------------------------------
  // Main scoreboard task
  // -----------------------------------------
  task main();
    forever begin
      $display($time ,"\n========== SCOREBOARD: started TRANSACTION ==========");
      // get matching transactions from driver & monitor
      driv2scb.get(tr);
//       mon2scb.get(tr1);

      $display($time," \n========== SCOREBOARD: NEW TRANSACTION ==========");
      tr.display("  [SCB] From driver");
//       tr1.display("  [SCB] From monitor");

      // ------------------------------------------------
      // WRITE transaction
      // ------------------------------------------------
      if (!tr.transaction_type) begin
        $display("\n========== SCOREBOARD: write TRANSACTION ==========");
          // Match driver pattern: WData + beat
          write_beat_to_ref(tr, tr.AWaddr, tr.WData, tr.AWsize);
      end
      
      mon2scb.get(tr1);
      tr1.display("  [SCB] From monitor");
      // ------------------------------------------------
      // READ transaction
      // ------------------------------------------------
      if (tr.transaction_type) begin
        $display("\n========== SCOREBOARD: READ TRANSACTION ==========");

        //$display($time, " <<<<<<<<<<<<<<<calling1>>>>>>>>>>>>>>");
        expected_word = expected_read_beat(tr, tr.ARaddr, tr.ARsize);
        //$display($time, " <<<<<<<<<<<<<<<calling_1>>>>>>>>>>>>>>");
        actual_word   = actual_read_beat(tr1, tr.ARaddr, tr1.ARsize);

        `ifdef compare_logic_en
        compare_logic(); // task calling to compare
        `endif

      end // READ

    end // forever
  endtask : main

  // -----------------------------------------
  // Helper: bytes per transfer from size
  // size encoding: 000 = 1B, 001 = 2B, 010 = 4B, ...
  // -----------------------------------------
  function int bytes_per_transfer(input bit [2:0] size);
    return (1 << size);
//    return DATAWIDTH/8;
  endfunction

  // -----------------------------------------
  // Write a beat into reference memory
  // -----------------------------------------
  task write_beat_to_ref(input transaction_c #(DATAWIDTH, SIZE) t, input int base_addr, input logic [DATAWIDTH-1:0] wdata,
                         input bit [2:0] size);
    int bytes, i;
    bytes = bytes_per_transfer(size);

    for (i = 0; i < bytes; i++) begin
    if (t.WStrb[i]) begin
      if (base_addr + i < MSIZE) begin
        ref_memory[base_addr + i] = wdata[8*i +: 8];
      end
      end
      else begin
//         $display("%t, [SCOREBOARD WARNING] write addr 0x%0h out of range", $time, base_addr + i);
      end
    end

    $display("%t, [SCOREBOARD] REF WRITE: %0d bytes @ 0x%0h : data = %0h", $time, bytes, base_addr, wdata);
  endtask

  // -----------------------------------------
  // Build expected DATAWIDTH word from ref_memory
  // -----------------------------------------
  function logic [DATAWIDTH-1:0]
    expected_read_beat(input transaction_c #(DATAWIDTH, SIZE) t, input int base_addr, input bit [2:0] size);
    int bytes;
    logic [DATAWIDTH-1:0] word;
    word  = '0;
    bytes = bytes_per_transfer(size);

    for (int i = 0; i < bytes; i++) begin
      if ((base_addr + i < MSIZE) && (base_addr + i > 32'h5ff))begin
        word[8*i +: 8] = ref_memory[base_addr + i];
        $display("%t, i = %d[SCOREBOARD] expected_read_beat: %0d bytes @ 0x%0h : data = %0h", $time,i, bytes, base_addr, word);
        end else
        word[8*i +: 8] = 8'h00;
    end
    ->>check;

    return word;
  endfunction

  // -----------------------------------------
  // Build actual DATAWIDTH word from DUT read_memory
  // tr1.read_memory is assumed: logic [MSIZE-1:0][7:0]
  // -----------------------------------------
  function logic [DATAWIDTH-1:0]
    actual_read_beat(input transaction_c #(DATAWIDTH, SIZE) t,
                     input int base_addr,
                     input bit [2:0] size);
    int bytes;
    logic [DATAWIDTH-1:0] word;
    $display($time, " <<<<<<<<<<<<<<<entering>>>>>>>>>>>>>>");
    word  = '0;
    bytes = bytes_per_transfer(size);

    for (int i = 0; i < bytes; i++) begin
      if (base_addr + i < MSIZE) begin
        word[8*i +: 8] = t.read_memory[base_addr + i];
        $display("%t, i = %d[SCOREBOARD] actual_read_beat: %0d bytes @ 0x%0h : data = %0h", $time,i, bytes, base_addr, word);
        end else begin
        word[8*i +: 8] = 8'h00;
          $display("%t, [SCOREBOARD] actual_read_beat failing: %0d bytes @ 0x%0h : data = %0h", $time, bytes, base_addr, word);
        end
    end
    ->>ckeck1;

    return word;
  endfunction

  // -----------------------------------------
  // Get the current error count
  // -----------------------------------------
  function int get_error_count();
    return error_count;
  endfunction

  task compare_logic();
  @(check);
    if ( expected_word !== actual_word) begin
      $display("%t, [SCOREBOARD ERROR] Read mismatch @ 0x%0h (beat %0d):%0h", $time, tr.ARaddr, beat, actual_word);
      $display("            expected = %0h", expected_word);
      $display("            actual   = %0h", actual_word);
      error_count++;
    end
    else begin
      $display("%t, [SCOREBOARD PASS] Read OK @ 0x%0h (beat %0d): %0h", $time, tr.ARaddr, beat, actual_word);
      $display("            expected = %0h", expected_word);
      $display("            actual   = %0h", actual_word);
    end
  endtask
endclass

`endif
