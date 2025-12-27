`include "transaction.sv"

`ifndef GENERATOR_C
`define GENERATOR_C

class generator_c #(parameter int DATAWIDTH = 32, int SIZE = 3);

  // Transaction handle
  transaction_c #(DATAWIDTH, SIZE) trans;
  transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
  
  // Mailbox to send transaction to driver
  mailbox gen2driv;

//   int pattern_arr[2:0];
  
  // Events to indicate completion points
  event error_incr_ev, error_wrap_ev, all_size, wrap_size_ev, incr_size, incr_size2, fix_size1, fix_size0, fix_size3;
  event ended, wrap_size, wrap_size2, strobe_size0, pattern0,pattern2, second;
  event ended1 = ended;
  event all_sizes = all_size;
  event wrap_size_ev1= wrap_size_ev;
  event incr_size1 = incr_size;
  event incr_size3 = incr_size2;
  event wrap_size1 = wrap_size;
  event wrap_size3 = wrap_size2;
  event fix_size2 = fix_size1;
  event fix_size = fix_size0;
  event fix_size4 = fix_size3;
  event strobe_size1 = strobe_size0;
  event pattern1 = pattern0;
  event second1 = second;

  // Optional repeat count
  int repeat_count = 0;

  //--------------------------------------
  // Constructor
  //--------------------------------------
  function new(mailbox gen2driv = null);
    if (gen2driv == null) begin
      $error("generator_c: mailbox handle must be provided to constructor");
    end
//     pattern_arr = '{ 32'hAAAAAAAA, 32'h55555555, 32'h00000000 };
//     $display("%h, %h, %h",pattern_arr[0], pattern_arr[1], pattern_arr[2]);
    this.gen2driv = gen2driv;
    $display("%%%%%%%%%%%%%%%%%%%% gen created %%%%%%%%%%%%%%%%%%%%");
  endfunction:new

  //--------------------------------------
  // Main run task
  //--------------------------------------
  task run();
  begin    
//    sample_testcase(3);
     strobe_incr(15);
     fix_len_size2(15);
     fix_len_size1(15);
     fix_len_size0(15);
     recursive_incr_len(15);
     wrap_all_len(15);
     wrap_len_size1(15);
     wrap_len_size0(15);
     incr_len_size1(15);
     incr_len_size0(15);
     recursive_incr_size(2);
     wrap_all_size(2);
     incr_error_addr();
     wrap_err_addr();
  end
  endtask:run


  //--------------------------------------
  // fix all lengths with size->2
  //--------------------------------------
  task automatic fix_len_size2(int n);
  ->>second1;
     @(second);$display($time, " [[[[[[[[[[[[[[[[[[[[ _size<->triggered ]]]]]]]]]]]]]]]]]]]]");
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b00;
      AWlen   == n;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b00;
      ARlen   == n;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      fix_len_size2(n-1);
    end
    else
      ->>fix_size0;
  endtask:fix_len_size2
  
  //--------------------------------------
  // fix all lengths with size->1
  //--------------------------------------
  task automatic fix_len_size1(int n);
    ->>fix_size;
    @(fix_size0);$display($time, " [[[[[[[[[[[[[[[[[[[[ fix_size0<->triggered ]]]]]]]]]]]]]]]]]]]]");
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b00;
      AWlen   == n;
      AWsize == 2'b01;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b00;
      ARlen   == n;
      ARsize == 2'b01;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      fix_len_size1(n-1);
    end
    else
      ->>fix_size3;
  endtask:fix_len_size1

  //--------------------------------------
  // fix all lengths with size->0
  //--------------------------------------
  task automatic fix_len_size0(int n);
    ->>fix_size4;
    @(fix_size3);$display($time, " [[[[[[[[[[[[[[[[[[[[ fix_size3<->triggered ]]]]]]]]]]]]]]]]]]]]");
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b00;
      AWlen   == n;
      AWsize == 2'b00;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b00;
      ARlen   == n;
      ARsize == 2'b00;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      fix_len_size0(n-1);
    end
    else
      ->>fix_size1;
  endtask:fix_len_size0
  
  //--------------------------------------
  // Incremental all lengths with size->2
  //--------------------------------------
  task automatic recursive_incr_len(int n);
    ->>fix_size2;
    @(fix_size1);
    //     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b01;
      AWlen   == n;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b01;
      ARlen   == n;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 1 )begin
      recursive_incr_len(n-1);
    end
    else
      ->>ended;
  endtask:recursive_incr_len
  
  //--------------------------------------
  // wrap all length with size->2
  //--------------------------------------
  task automatic wrap_all_len(int wn);
    ->>ended1;
    @(ended);$display($time, " [[[[[[[[[[[[[[[[[[[[ ended1<->triggered ]]]]]]]]]]]]]]]]]]]]");
    #900;
//     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
        transaction_type == 0;
        AWburst == 2'b10;
        AWlen   == wn;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
        transaction_type == 1;
        ARburst == 2'b10;
        ARlen   == wn;
        ARaddr  == incr_min_write.AWaddr;
        ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if(wn > 1) begin
      wrap_all_len(wn >> 1);
    end
    else begin
      ->>wrap_size;
    end
  endtask:wrap_all_len
  
  //--------------------------------------
  // wrap all lengths with size->1
  //--------------------------------------
  task automatic wrap_len_size1(int n);
    int size = 'd1;
    ->>wrap_size1;
    @(wrap_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ wrap_size1<->triggered ]]]]]]]]]]]]]]]]]]]]");
    #900;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b10;
      AWlen   == n;
      AWsize == size;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b10;
      ARlen   == n;
      ARsize == size;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 1 )begin
      wrap_len_size1(n >> 1);
    end
    else
      ->>wrap_size2;
  endtask:wrap_len_size1

  //--------------------------------------
  // wrap all lengths with size->0
  //--------------------------------------
  task automatic wrap_len_size0(int n);
    ->>wrap_size3;
    @(wrap_size2);$display($time, " [[[[[[[[[[[[[[[[[[[[ wrap_size2<->triggered ]]]]]]]]]]]]]]]]]]]]");
    #900;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b10;
      AWlen   == n;
      AWsize == 2'b00;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b10;
      ARlen   == n;
      ARsize == 2'b00;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 1 )begin
      wrap_len_size0(n >> 1);
    end
    else
      ->>incr_size;
  endtask:wrap_len_size0
  
  //--------------------------------------
  // Incremental all lengths with size->1
  //--------------------------------------
  task automatic incr_len_size1(int n);
    int size = 'd1;
    ->>incr_size1;
    @(incr_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ incr_size1<->triggered ]]]]]]]]]]]]]]]]]]]]");
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b01;
      AWlen   == n;
      AWsize == size;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b01;
      ARlen   == n;
      ARsize == size;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      incr_len_size1(n-1);
    end
    else
      ->>incr_size2;
  endtask:incr_len_size1

  //--------------------------------------
  // Incremental all lengths with size->0
  //--------------------------------------
  task automatic incr_len_size0(int n);
    ->>incr_size3;
    @(incr_size2);$display($time, " [[[[[[[[[[[[[[[[[[[[ incr_size2<->triggered ]]]]]]]]]]]]]]]]]]]]");
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b01;
      AWlen   == n;
      AWsize == 2'b00;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b01;
      ARlen   == n;
      ARsize == 2'b00;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      incr_len_size0(n-1);
    end
    else
      ->>all_size;
  endtask:incr_len_size0
  
  //--------------------------------------
  // Incremental all sizes by using recursive task calling
  //--------------------------------------
  task automatic recursive_incr_size(int sz);
    ->>all_sizes;
    @(all_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ all_size<->triggered ]]]]]]]]]]]]]]]]]]]]");
    #900;
//     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
        transaction_type == 0;
        AWburst == 2'b01;
        AWlen   == 4'h3;
      AWsize == sz;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
        transaction_type == 1;
        ARburst == 2'b01;
        ARlen   == 4'h3;
      ARsize == sz;
        ARaddr  == incr_min_write.AWaddr;
        ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( sz > 1 )begin
      recursive_incr_size(sz-1);
    end
    else
      ->>wrap_size_ev;
    $display($time, " [[[[[[[[[[[[[[[[[[[[ error_incr_ev<->triggered here ]]]]]]]]]]]]]]]]]]]]");
  endtask:recursive_incr_size
  
  //--------------------------------------
  // wrap all size
  //--------------------------------------
  task automatic wrap_all_size(int ws);
    ->>wrap_size_ev1;
    @(wrap_size_ev);$display($time, " [[[[[[[[[[[[[[[[[[[[ ended1<->triggered ]]]]]]]]]]]]]]]]]]]]");
    #900;
//     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
        transaction_type == 0;
        AWburst == 2'b10;
        AWlen   == 4'h3;
      AWsize == ws;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
        transaction_type == 1;
        ARburst == 2'b10;
        ARlen   == 4'h3;
      ARsize == ws;
        ARaddr  == incr_min_write.AWaddr;
        ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #300;
    if(ws > 1) begin
      wrap_all_size(ws - 1);
    end
    else begin
//      ->>strobe_size0;
       ->>error_incr_ev;
    end
  endtask:wrap_all_size
  
  //--------------------------------------
  // all strobes with size->2
  //--------------------------------------
  task automatic strobe_incr(int n);
    ->>strobe_size1;
    @(strobe_size0);
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b01;
      AWlen   == 4'd3;
      WStrb == n;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b01;
      ARlen   == 4'd3;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      strobe_incr(n-1);
    end
    else
      ->>second;
  endtask:strobe_incr
      
  //--------------------------------------
  // Incremental error addr
  //--------------------------------------
  task automatic incr_error_addr();
    @(error_incr_ev);$display($time, " [[[[[[[[[[[[[[[[[[[[ error_incr_ev<->triggered ]]]]]]]]]]]]]]]]]]]]");
//     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
        transaction_type == 0;
        AWburst == 2'b00;
        AWlen   == 4'h0;
      AWaddr > 32'd4096;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
        transaction_type == 1;
        ARburst == 2'b00;
        ARlen   == 4'h0;
        ARaddr  == incr_min_write.AWaddr;
        ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #600;
    ->> error_wrap_ev;
  endtask:incr_error_addr
  
  //--------------------------------------
  // wrap error addr
  //--------------------------------------
  task automatic wrap_err_addr();
    @(error_wrap_ev);$display($time, " [[[[[[[[[[[[[[[[[[[[ error_wrap_ev<->triggered ]]]]]]]]]]]]]]]]]]]]");
//     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
    // WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
        transaction_type == 0;
        AWburst == 2'b10;
        AWlen   == 4'h0;
      AWaddr == 32'd4098;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
        transaction_type == 1;
        ARburst == 2'b10;
        ARlen   == 4'h0;
        ARaddr  == incr_min_write.AWaddr;
        ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #300;
    $display($time, " [[[[[[[[[[[[[[[[[[[[ error_wrap_ev<->ended ]]]]]]]]]]]]]]]]]]]]");
//     ->> e8;
  endtask:wrap_err_addr
  
  //--------------------------------------
  // sample test case all lengths with size->2
  //--------------------------------------
  task automatic sample_testcase(int n);
    ->>fix_size2;
    @(fix_size1);
//         transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//     WRITE transaction
    incr_min_write = new();
    if (!incr_min_write.randomize() with {
      transaction_type == 0;
      AWburst == 2'b01;
      AWlen   == n;
      ARaddr == ARaddr; //added
    }) begin
      $display("generator_c::write_read - randomize failed for write");
    end
    gen2driv.put(incr_min_write);
    #10;
    // READ transaction
    incr_min_read = new();
    if (!incr_min_read.randomize() with {
      transaction_type == 1;
      ARburst == 2'b01;
      ARlen   == n;
      ARaddr  == incr_min_write.AWaddr;
      ARid    == incr_min_write.AWid;
      WData == WData;//added
      AWaddr == AWaddr;//added
    }) begin
      $error("generator_c::write_read - randomize failed for read");
    end
    gen2driv.put(incr_min_read);
    #900;
    if( n > 0 )begin
      sample_testcase(n-1);
    end
//     else
//       ->>ended;
  endtask:sample_testcase
  
endclass:generator_c

`endif // GENERATOR_C


//`include "transaction.sv"

//`ifndef GENERATOR_C
//`define GENERATOR_C

//class generator_c #(parameter int DATAWIDTH = 32, int SIZE = 3);

//  // Transaction handle
//  transaction_c #(DATAWIDTH, SIZE) trans;
//  transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
  
//  // Mailbox to send transaction to driver
//  mailbox gen2driv;

////   int pattern_arr[2:0];
  
//  // Events to indicate completion points
//  event error_incr_ev, error_wrap_ev, all_size, wrap_size_ev, incr_size, incr_size2, fix_size1, fix_size0, fix_size3;
//  event ended, wrap_size, wrap_size2, strobe_size0, pattern0,pattern2;
//  event ended1 = ended;
//  event all_sizes = all_size;
//  event wrap_size_ev1= wrap_size_ev;
//  event incr_size1 = incr_size;
//  event incr_size3 = incr_size2;
//  event wrap_size1 = wrap_size;
//  event wrap_size3 = wrap_size2;
//  event fix_size2 = fix_size1;
//  event fix_size = fix_size0;
//  event fix_size4 = fix_size3;
//  event strobe_size1 = strobe_size0;
//  event pattern1 = pattern0;

//  // Optional repeat count
//  int repeat_count = 0;

//  //--------------------------------------
//  // Constructor
//  //--------------------------------------
//  function new(mailbox gen2driv = null);
//    if (gen2driv == null) begin
//      $error("generator_c: mailbox handle must be provided to constructor");
//    end
////     pattern_arr = '{ 32'hAAAAAAAA, 32'h55555555, 32'h00000000 };
////     $display("%h, %h, %h",pattern_arr[0], pattern_arr[1], pattern_arr[2]);
//    this.gen2driv = gen2driv;
//    $display("%%%%%%%%%%%%%%%%%%%% gen created %%%%%%%%%%%%%%%%%%%%");
//  endfunction:new

//  //--------------------------------------
//  // Main run task
//  //--------------------------------------
//  task run();
//  begin    
////    sample_testcase(3);
////     fix_len_size2(15);
////     fix_len_size1(15);
////     fix_len_size0(15);
////     recursive_incr_len(15);
////     wrap_all_len(15);
////     wrap_len_size1(15);
////     wrap_len_size0(15);
////     incr_len_size1(15);
////     incr_len_size0(15);
////     recursive_incr_size(2);
////     wrap_all_size(2);
//     strobe_incr(15);
////     incr_error_addr();
////     wrap_err_addr();
//  end
//  endtask:run


//  //--------------------------------------
//  // fix all lengths with size->2
//  //--------------------------------------
//  task automatic fix_len_size2(int n);
////     @(fix_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ _size<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b00;
//      AWlen   == n;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b00;
//      ARlen   == n;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      fix_len_size2(n-1);
//    end
//    else
//      ->>fix_size0;
//  endtask:fix_len_size2
  
//  //--------------------------------------
//  // fix all lengths with size->1
//  //--------------------------------------
//  task automatic fix_len_size1(int n);
//    ->>fix_size;
//    @(fix_size0);$display($time, " [[[[[[[[[[[[[[[[[[[[ fix_size0<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b00;
//      AWlen   == n;
//      AWsize == 2'b01;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b00;
//      ARlen   == n;
//      ARsize == 2'b01;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      fix_len_size1(n-1);
//    end
//    else
//      ->>fix_size3;
//  endtask:fix_len_size1

//  //--------------------------------------
//  // fix all lengths with size->0
//  //--------------------------------------
//  task automatic fix_len_size0(int n);
//    ->>fix_size4;
//    @(fix_size3);$display($time, " [[[[[[[[[[[[[[[[[[[[ fix_size3<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b00;
//      AWlen   == n;
//      AWsize == 2'b00;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b00;
//      ARlen   == n;
//      ARsize == 2'b00;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      fix_len_size0(n-1);
//    end
//    else
//      ->>fix_size1;
//  endtask:fix_len_size0
  
//  //--------------------------------------
//  // Incremental all lengths with size->2
//  //--------------------------------------
//  task automatic recursive_incr_len(int n);
//    ->>fix_size2;
//    @(fix_size1);
//    //     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b01;
//      AWlen   == n;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b01;
//      ARlen   == n;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      recursive_incr_len(n-1);
//    end
//    else
//      ->>ended;
//  endtask:recursive_incr_len
  
//  //--------------------------------------
//  // wrap all length with size->2
//  //--------------------------------------
//  task automatic wrap_all_len(int wn);
//    ->>ended1;
//    @(ended);$display($time, " [[[[[[[[[[[[[[[[[[[[ ended1<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    #900;
////     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//        transaction_type == 0;
//        AWburst == 2'b10;
//        AWlen   == wn;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//        transaction_type == 1;
//        ARburst == 2'b10;
//        ARlen   == wn;
//        ARaddr  == incr_min_write.AWaddr;
//        ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if(wn > 1) begin
//      wrap_all_len(wn >> 1);
//    end
//    else begin
//      ->>wrap_size;
//    end
//  endtask:wrap_all_len
  
//  //--------------------------------------
//  // wrap all lengths with size->1
//  //--------------------------------------
//  task automatic wrap_len_size1(int n);
//    int size = 'd1;
//    ->>wrap_size1;
//    @(wrap_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ wrap_size1<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    #900;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b10;
//      AWlen   == n;
//      AWsize == size;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b10;
//      ARlen   == n;
//      ARsize == size;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      wrap_len_size1(n >> 1);
//    end
//    else
//      ->>wrap_size2;
//  endtask:wrap_len_size1

//  //--------------------------------------
//  // wrap all lengths with size->0
//  //--------------------------------------
//  task automatic wrap_len_size0(int n);
//    ->>wrap_size3;
//    @(wrap_size2);$display($time, " [[[[[[[[[[[[[[[[[[[[ wrap_size2<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    #900;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b10;
//      AWlen   == n;
//      AWsize == 2'b00;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b10;
//      ARlen   == n;
//      ARsize == 2'b00;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      wrap_len_size0(n >> 1);
//    end
//    else
//      ->>incr_size;
//  endtask:wrap_len_size0
  
//  //--------------------------------------
//  // Incremental all lengths with size->1
//  //--------------------------------------
//  task automatic incr_len_size1(int n);
//    int size = 'd1;
//    ->>incr_size1;
//    @(incr_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ incr_size1<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b01;
//      AWlen   == n;
//      AWsize == size;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b01;
//      ARlen   == n;
//      ARsize == size;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      incr_len_size1(n-1);
//    end
//    else
//      ->>incr_size2;
//  endtask:incr_len_size1

//  //--------------------------------------
//  // Incremental all lengths with size->0
//  //--------------------------------------
//  task automatic incr_len_size0(int n);
//    ->>incr_size3;
//    @(incr_size2);$display($time, " [[[[[[[[[[[[[[[[[[[[ incr_size2<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b01;
//      AWlen   == n;
//      AWsize == 2'b00;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b01;
//      ARlen   == n;
//      ARsize == 2'b00;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      incr_len_size0(n-1);
//    end
//    else
//      ->>all_size;
//  endtask:incr_len_size0
  
//  //--------------------------------------
//  // Incremental all sizes by using recursive task calling
//  //--------------------------------------
//  task automatic recursive_incr_size(int sz);
//    ->>all_sizes;
//    @(all_size);$display($time, " [[[[[[[[[[[[[[[[[[[[ all_size<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    #900;
////     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//        transaction_type == 0;
//        AWburst == 2'b01;
//        AWlen   == 4'h3;
//      AWsize == sz;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//        transaction_type == 1;
//        ARburst == 2'b01;
//        ARlen   == 4'h3;
//      ARsize == sz;
//        ARaddr  == incr_min_write.AWaddr;
//        ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( sz > 0 )begin
//      recursive_incr_size(sz-1);
//    end
//    else
//      ->>wrap_size_ev;
//    $display($time, " [[[[[[[[[[[[[[[[[[[[ error_incr_ev<->triggered here ]]]]]]]]]]]]]]]]]]]]");
//  endtask:recursive_incr_size
  
//  //--------------------------------------
//  // wrap all size
//  //--------------------------------------
//  task automatic wrap_all_size(int ws);
//    ->>wrap_size_ev1;
//    @(wrap_size_ev);$display($time, " [[[[[[[[[[[[[[[[[[[[ ended1<->triggered ]]]]]]]]]]]]]]]]]]]]");
//    #900;
////     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//        transaction_type == 0;
//        AWburst == 2'b10;
//        AWlen   == 4'h3;
//      AWsize == ws;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//        transaction_type == 1;
//        ARburst == 2'b10;
//        ARlen   == 4'h3;
//      ARsize == ws;
//        ARaddr  == incr_min_write.AWaddr;
//        ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #300;
//    if(ws > 0) begin
//      wrap_all_size(ws - 1);
//    end
//    else begin
//      ->>strobe_size0;
////       ->>error_incr_ev;
//    end
//  endtask:wrap_all_size
  
//  //--------------------------------------
//  // all strobes with size->2
//  //--------------------------------------
//  task automatic strobe_incr(int n);
//    ->>strobe_size1;
//    @(strobe_size0);
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b01;
//      AWlen   == 4'd3;
//      WStrb == n;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b01;
//      ARlen   == 4'd3;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      strobe_incr(n-1);
//    end
//    else
//      ->>error_incr_ev;
//  endtask:strobe_incr
      
//  //--------------------------------------
//  // Incremental error addr
//  //--------------------------------------
//  task automatic incr_error_addr();
//    @(error_incr_ev);$display($time, " [[[[[[[[[[[[[[[[[[[[ error_incr_ev<->triggered ]]]]]]]]]]]]]]]]]]]]");
////     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//        transaction_type == 0;
//        AWburst == 2'b10;
//        AWlen   == 4'h3;
//      AWaddr > 32'd4096;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//        transaction_type == 1;
//        ARburst == 2'b10;
//        ARlen   == 4'h3;
//        ARaddr  == incr_min_write.AWaddr;
//        ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #600;
//    ->> error_wrap_ev;
//  endtask:incr_error_addr
  
//  //--------------------------------------
//  // wrap error addr
//  //--------------------------------------
//  task automatic wrap_err_addr();
//    @(error_wrap_ev);$display($time, " [[[[[[[[[[[[[[[[[[[[ error_wrap_ev<->triggered ]]]]]]]]]]]]]]]]]]]]");
////     transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
//    // WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//        transaction_type == 0;
//        AWburst == 2'b10;
//        AWlen   == 4'h0;
//      AWaddr == 32'd4098;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//        transaction_type == 1;
//        ARburst == 2'b10;
//        ARlen   == 4'h0;
//        ARaddr  == incr_min_write.AWaddr;
//        ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #300;
//    $display($time, " [[[[[[[[[[[[[[[[[[[[ error_wrap_ev<->ended ]]]]]]]]]]]]]]]]]]]]");
////     ->> e8;
//  endtask:wrap_err_addr
  
//  //--------------------------------------
//  // sample test case all lengths with size->2
//  //--------------------------------------
//  task automatic sample_testcase(int n);
//    ->>fix_size2;
//    @(fix_size1);
////         transaction_c #(DATAWIDTH, SIZE) incr_min_write, incr_min_read;
////     WRITE transaction
//    incr_min_write = new();
//    if (!incr_min_write.randomize() with {
//      transaction_type == 0;
//      AWburst == 2'b01;
//      AWlen   == n;
//      ARaddr == ARaddr; //added
//    }) begin
//      $display("generator_c::write_read - randomize failed for write");
//    end
//    gen2driv.put(incr_min_write);
//    #10;
//    // READ transaction
//    incr_min_read = new();
//    if (!incr_min_read.randomize() with {
//      transaction_type == 1;
//      ARburst == 2'b01;
//      ARlen   == n;
//      ARaddr  == incr_min_write.AWaddr;
//      ARid    == incr_min_write.AWid;
//      WData == WData;//added
//      AWaddr == AWaddr;//added
//    }) begin
//      $error("generator_c::write_read - randomize failed for read");
//    end
//    gen2driv.put(incr_min_read);
//    #900;
//    if( n > 1 )begin
//      sample_testcase(n-1);
//    end
////     else
////       ->>ended;
//  endtask:sample_testcase
  
//endclass:generator_c

//`endif // GENERATOR_C
