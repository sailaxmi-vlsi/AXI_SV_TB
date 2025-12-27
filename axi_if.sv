

// Simple AXI3 interface with Master/Slave modports
interface axi #(parameter DATAWIDTH = 32, parameter SIZE = 3)
  (input logic clock, reset);

// Control signals
logic	AWREADY, AWVALID,RLAST, WREADY,WVALID,WLAST,BVALID,BREADY,ARREADY,ARVALID,RVALID,RREADY;  //handshaking signals valid, ready for all the write & read address ,data ,response channels, last signal
logic	[SIZE-2:0]	AWBURST,BRESP,ARBURST,RRESP; // Write Burst type, Write Response, Read Burst type, Read response signals
logic	[(DATAWIDTH/8)-1:0]	AWLEN ,AWID,WSTRB, WID,BID,ARID,ARLEN,RID; // control info for number of transfers, ids, strobe signals
  logic	[DATAWIDTH-1:0]	WDATA;  // write data
logic	[DATAWIDTH-1:0]	ARADDR,RDATA,AWADDR; //read address, read data, write address signals
  logic	[SIZE-2:0]	ARSIZE,AWSIZE; //transfer size for read write transactions

  //%%%%%%%%%%%%%%%%%%%%%%%%%% modified custom %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // --------------------------------------------------------------------------
  // Signal Declarations
  // --------------------------------------------------------------------------

  // Write Address Channel
  logic [DATAWIDTH-1:0]       AWaddr;
  logic [(DATAWIDTH/8)-1:0]   AWlen;
  logic [(SIZE-2):0]          AWsize;
  logic [(SIZE-2):0]          AWburst;
  logic [(DATAWIDTH/8)-1:0]   AWid;

  // Write Data Channel
  logic [DATAWIDTH-1:0]       WData;
  logic [(DATAWIDTH/8)-1:0]   WStrb;

  // Read Address Channel
  logic [DATAWIDTH-1:0]       ARaddr;
  logic [(SIZE-2):0]          ARsize;
  logic [(SIZE-2):0]          ARburst;
  logic [(DATAWIDTH/8)-1:0]   ARid;
  logic [(DATAWIDTH/8)-1:0]   ARlen;

  // Memory for monitor/checking
  logic [4095:0][7:0]          read_memory;
  
  // --------------------------------------------------------------------------
  // Driver Clocking Block
  // --------------------------------------------------------------------------
  clocking driver_cb @(posedge clock);
    default input #1 output #1;
    output AWaddr, AWlen, AWsize, AWburst, AWid;
    output WData, WStrb;
    output ARaddr, ARsize, ARburst, ARid, ARlen;
    input  read_memory;
  endclocking

  // --------------------------------------------------------------------------
  // Monitor Clocking Block
  // --------------------------------------------------------------------------
  clocking monitor_cb @(posedge clock);
    default input #1 output #1;
    input AWaddr, AWlen, AWsize, AWburst, AWid;
    input WData, WStrb;
    input ARaddr, ARsize, ARburst, ARid, ARlen;
    input read_memory;
  endclocking

  // --------------------------------------------------------------------------
  // Modports
  // --------------------------------------------------------------------------
  modport DRIVER  (clocking driver_cb, input clock, reset);
  modport MONITOR (clocking monitor_cb, input clock, reset);
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    modport Slave(
    
	output	WREADY,     //write ready signal from slave
	input	WVALID,		//valid signal for write 
	input	WLAST,		//write last signal
	input	WSTRB,		// strobe signal for writing in
	input	WDATA,		//write data
	input	WID,        //write data id
	output	BID, 		//response id
	output	BRESP,	 	//write response signal from slave
	output	BVALID,     //write response valid signal
	input	BREADY,     //write response ready signal
	output	AWREADY,    //write address ready signal from slave
	input	AWVALID,    // write address valid signal
	input	AWBURST,	//write address channel signal for burst type
	input	AWSIZE,     //size of each transfer in bytes(encoded)
	input	AWLEN,      //burst length- number of transfers in a burst
	input	AWADDR,     //write address signal 
	input	AWID,		// write address id 
	output	ARREADY,  //read address ready signal from slave
	input	ARID,      //read address id
	input	ARADDR,		//read address signal
	input	ARLEN,      //length of the burst
	input	ARSIZE,		//number of bytes in a transfer
	input	ARBURST,	//burst type - fixed, incremental, wrapping
	input	ARVALID,	//address read valid signal
	output	RID,		//read data id
	output	RDATA,     //read data from slave
 	output	RRESP,		//read response signal
	output	RLAST,		//read data last signal
	output	RVALID,		//read data valid signal
	input	RREADY		//read ready signal
);

//Master modport
modport Master(


	input	AWREADY, ////////////////////////////////////inputs to the Master 
	input	BID, 	 //	
	input	BRESP,   //
	input	BVALID,  // 
	input	WREADY,  //
	input	ARREADY,  //
	input	RID,      //      ready, id , response,read data signals to the master for various channels
	input	RDATA,    //
	input	RRESP,    //
	input	RLAST,    //
	input	RVALID,   ///////////////////////////////
	output	AWVALID,  //	write address valid signal from Master
	output	AWBURST,  // 
	output	AWSIZE,   //
	output	AWLEN,    //
	output	AWADDR,   //  	signals specifying the length of a burst , size of each transfer, id, valid, last, strobe etc. for various- write & read address ,data, response channels
	output	AWID,     //
	output	WVALID,   //
	output	WLAST,    //
	output	WSTRB,    //
	output	WDATA,    //	write data from Master
	output	WID,      //
	output	BREADY,   //
	output	ARID,     //
	output	ARADDR,   //
	output	ARLEN,    //
	output	ARSIZE,   //
	output	ARBURST,   //
	output	ARVALID,   //
	output	RREADY     ////////////////////////
);



endinterface
