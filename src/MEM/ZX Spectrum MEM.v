
//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.10.02
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Fri Sep 27 13:26:19 2024

module ZX_Spectrum_MEM(

    input       CLK,
    input       RESET,
	input [ 7:0]PAGING,

    output [7:0]ULA_RD_DATA,
    input [15:0]ULA_ADDRESS,
    input       ULA_RD,

    input  [7:0]SD_WR_DATA,
    input [15:0]SD_ADDRESS,
    input       SD_WR,

    output [7:0]CPU_RD_DATA,
    input [ 7:0]CPU_WR_DATA,
    input [15:0]CPU_ADDRESS,
    input       CPU_RD,
    input       CPU_WR,
    input       CPU_MREQ
);

// NB ULA Read (DPB Channel A) ONLY has access to Page 1 (Video RAM)
//    SD Write (
//    Page 0 is ROM and so has WRE hard coded to 0

wire wreb;
wire ceb;
wire oen;

assign ceb  =  ~CPU_MREQ;                           // MREQ drives the Clock EnaBle
assign wreb = ~(CPU_MREQ | CPU_WR);                 // MREQ and WR active drives the WRite EnaBle
assign oen  = ~(CPU_MREQ | CPU_RD);                 // MREQ and RD active drives the Output ENable

wire wreb0;
wire wreb2;
wire wreb4;

assign wreb0 =  PAGING[6] & wreb;					// Page 0 (ROM) writable when paged in to $8000 (Bit 6)
assign wreb2 = ~PAGING[6] & wreb;					// Page 2 (RAM) writable when ROM NOT paged in to $8000 (Bit 6)
assign wreb4 =  PAGING[4] & CPU_ADDRESS[13] & wreb;	// Page 4 (SD)  writable when paged in (Bit 4) and accessing the upper 8K

///////////////////////////////////////////////////////////////////////////////////////////////////
// Page 0 - ROM - 0-16383

wire [15:0] p0_b0_ula_w;
wire [14:0] p0_b0_cpu_w;
wire  [0:0] p0_b0_cpu;
wire [15:0] p0_b1_ula_w;
wire [14:0] p0_b1_cpu_w;
wire  [1:1] p0_b1_cpu;
wire [15:0] p0_b2_ula_w;
wire [14:0] p0_b2_cpu_w;
wire  [2:2] p0_b2_cpu;
wire [15:0] p0_b3_ula_w;
wire [14:0] p0_b3_cpu_w;
wire  [3:3] p0_b3_cpu;
wire [15:0] p0_b4_ula_w;
wire [14:0] p0_b4_cpu_w;
wire  [4:4] p0_b4_cpu;
wire [15:0] p0_b5_ula_w;
wire [14:0] p0_b5_cpu_w;
wire  [5:5] p0_b5_cpu;
wire [15:0] p0_b6_ula_w;
wire [14:0] p0_b6_cpu_w;
wire  [6:6] p0_b6_cpu;
wire [15:0] p0_b7_ula_w;
wire [14:0] p0_b7_cpu_w;
wire  [7:7] p0_b7_cpu;

DPB p0_b0 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),						// NB Not selected as this is block 000
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b0_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),				// When paged in it's writable
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[0]}),
    .DOB({p0_b0_cpu_w,p0_b0_cpu})
);

defparam p0_b0.READ_MODE0 = 1'b0;
defparam p0_b0.READ_MODE1 = 1'b0;
defparam p0_b0.WRITE_MODE0 = 2'b00;
defparam p0_b0.WRITE_MODE1 = 2'b00;
defparam p0_b0.BIT_WIDTH_0 = 1;
defparam p0_b0.BIT_WIDTH_1 = 1;
defparam p0_b0.BLK_SEL_0 = 3'b000;
defparam p0_b0.BLK_SEL_1 = 3'b000;
defparam p0_b0.RESET_MODE = "ASYNC";


DPB p0_b1 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b1_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[1]}),
    .DOB({p0_b1_cpu_w,p0_b1_cpu})
);

defparam p0_b1.READ_MODE0 = 1'b0;
defparam p0_b1.READ_MODE1 = 1'b0;
defparam p0_b1.WRITE_MODE0 = 2'b00;
defparam p0_b1.WRITE_MODE1 = 2'b00;
defparam p0_b1.BIT_WIDTH_0 = 1;
defparam p0_b1.BIT_WIDTH_1 = 1;
defparam p0_b1.BLK_SEL_0 = 3'b000;
defparam p0_b1.BLK_SEL_1 = 3'b000;
defparam p0_b1.RESET_MODE = "ASYNC";


DPB p0_b2 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b2_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[2]}),
    .DOB({p0_b2_cpu_w,p0_b2_cpu})
);

defparam p0_b2.READ_MODE0 = 1'b0;
defparam p0_b2.READ_MODE1 = 1'b0;
defparam p0_b2.WRITE_MODE0 = 2'b00;
defparam p0_b2.WRITE_MODE1 = 2'b00;
defparam p0_b2.BIT_WIDTH_0 = 1;
defparam p0_b2.BIT_WIDTH_1 = 1;
defparam p0_b2.BLK_SEL_0 = 3'b000;
defparam p0_b2.BLK_SEL_1 = 3'b000;
defparam p0_b2.RESET_MODE = "ASYNC";


DPB p0_b3 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b3_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[3]}),
    .DOB({p0_b3_cpu_w,p0_b3_cpu})
);

defparam p0_b3.READ_MODE0 = 1'b0;
defparam p0_b3.READ_MODE1 = 1'b0;
defparam p0_b3.WRITE_MODE0 = 2'b00;
defparam p0_b3.WRITE_MODE1 = 2'b00;
defparam p0_b3.BIT_WIDTH_0 = 1;
defparam p0_b3.BIT_WIDTH_1 = 1;
defparam p0_b3.BLK_SEL_0 = 3'b000;
defparam p0_b3.BLK_SEL_1 = 3'b000;
defparam p0_b3.RESET_MODE = "ASYNC";


DPB p0_b4 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b4_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[4]}),
    .DOB({p0_b4_cpu_w,p0_b4_cpu})
);

defparam p0_b4.READ_MODE0 = 1'b0;
defparam p0_b4.READ_MODE1 = 1'b0;
defparam p0_b4.WRITE_MODE0 = 2'b00;
defparam p0_b4.WRITE_MODE1 = 2'b00;
defparam p0_b4.BIT_WIDTH_0 = 1;
defparam p0_b4.BIT_WIDTH_1 = 1;
defparam p0_b4.BLK_SEL_0 = 3'b000;
defparam p0_b4.BLK_SEL_1 = 3'b000;
defparam p0_b4.RESET_MODE = "ASYNC";


DPB p0_b5 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA( p0_b5_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[5]}),
    .DOB({p0_b5_cpu_w,p0_b5_cpu})
);

defparam p0_b5.READ_MODE0 = 1'b0;
defparam p0_b5.READ_MODE1 = 1'b0;
defparam p0_b5.WRITE_MODE0 = 2'b00;
defparam p0_b5.WRITE_MODE1 = 2'b00;
defparam p0_b5.BIT_WIDTH_0 = 1;
defparam p0_b5.BIT_WIDTH_1 = 1;
defparam p0_b5.BLK_SEL_0 = 3'b000;
defparam p0_b5.BLK_SEL_1 = 3'b000;
defparam p0_b5.RESET_MODE = "ASYNC";


DPB p0_b6 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b6_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[6]}),
    .DOB({p0_b6_cpu_w,p0_b6_cpu})
);

defparam p0_b6.READ_MODE0 = 1'b0;
defparam p0_b6.READ_MODE1 = 1'b0;
defparam p0_b6.WRITE_MODE0 = 2'b00;
defparam p0_b6.WRITE_MODE1 = 2'b00;
defparam p0_b6.BIT_WIDTH_0 = 1;
defparam p0_b6.BIT_WIDTH_1 = 1;
defparam p0_b6.BLK_SEL_0 = 3'b000;
defparam p0_b6.BLK_SEL_1 = 3'b000;
defparam p0_b6.RESET_MODE = "ASYNC";


DPB p0_b7 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p0_b7_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb0),
    .BLKSELB({ 1'b0, PAGING[6] ^ CPU_ADDRESS[15], CPU_ADDRESS[14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[7]}),
    .DOB({p0_b7_cpu_w,p0_b7_cpu})
);

defparam p0_b7.READ_MODE0 = 1'b0;
defparam p0_b7.READ_MODE1 = 1'b0;
defparam p0_b7.WRITE_MODE0 = 2'b00;
defparam p0_b7.WRITE_MODE1 = 2'b00;
defparam p0_b7.BIT_WIDTH_0 = 1;
defparam p0_b7.BIT_WIDTH_1 = 1;
defparam p0_b7.BLK_SEL_0 = 3'b000;
defparam p0_b7.BLK_SEL_1 = 3'b000;
defparam p0_b7.RESET_MODE = "ASYNC";


///////////////////////////////////////////////////////////////////////////////////////////////////
// Page 1 - Video RAM - 16384 - 32767

wire [14:0] p1_b0_ula_w;
wire  [0:0] p1_b0_ula;
wire [14:0] p1_b0_cpu_w;
wire  [0:0] p1_b0_cpu;
wire [14:0] p1_b1_ula_w;
wire  [1:1] p1_b1_ula;
wire [14:0] p1_b1_cpu_w;
wire  [1:1] p1_b1_cpu;
wire [14:0] p1_b2_ula_w;
wire  [2:2] p1_b2_ula;
wire [14:0] p1_b2_cpu_w;
wire  [2:2] p1_b2_cpu;
wire [14:0] p1_b3_ula_w;
wire  [3:3] p1_b3_ula;
wire [14:0] p1_b3_cpu_w;
wire  [3:3] p1_b3_cpu;
wire [14:0] p1_b4_ula_w;
wire  [4:4] p1_b4_ula;
wire [14:0] p1_b4_cpu_w;
wire  [4:4] p1_b4_cpu;
wire [14:0] p1_b5_ula_w;
wire  [5:5] p1_b5_ula;
wire [14:0] p1_b5_cpu_w;
wire  [5:5] p1_b5_cpu;
wire [14:0] p1_b6_ula_w;
wire  [6:6] p1_b6_ula;
wire [14:0] p1_b6_cpu_w;
wire  [6:6] p1_b6_cpu;
wire [14:0] p1_b7_ula_w;
wire  [7:7] p1_b7_ula;
wire [14:0] p1_b7_cpu_w;
wire  [7:7] p1_b7_cpu;

DPB p1_b0 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b0_ula_w[14:0], ULA_RD_DATA[0]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[0]}),
    .DOB({p1_b0_cpu_w, p1_b0_cpu})
);

defparam p1_b0.READ_MODE0 = 1'b0;
defparam p1_b0.READ_MODE1 = 1'b0;
defparam p1_b0.WRITE_MODE0 = 2'b00;
defparam p1_b0.WRITE_MODE1 = 2'b00;
defparam p1_b0.BIT_WIDTH_0 = 1;
defparam p1_b0.BIT_WIDTH_1 = 1;
defparam p1_b0.BLK_SEL_0 = 3'b001;
defparam p1_b0.BLK_SEL_1 = 3'b001;
defparam p1_b0.RESET_MODE = "ASYNC";


DPB p1_b1 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b1_ula_w[14:0], ULA_RD_DATA[1]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[1]}),
    .DOB({p1_b1_cpu_w,p1_b1_cpu})
);

defparam p1_b1.READ_MODE0 = 1'b0;
defparam p1_b1.READ_MODE1 = 1'b0;
defparam p1_b1.WRITE_MODE0 = 2'b00;
defparam p1_b1.WRITE_MODE1 = 2'b00;
defparam p1_b1.BIT_WIDTH_0 = 1;
defparam p1_b1.BIT_WIDTH_1 = 1;
defparam p1_b1.BLK_SEL_0 = 3'b001;
defparam p1_b1.BLK_SEL_1 = 3'b001;
defparam p1_b1.RESET_MODE = "ASYNC";


DPB p1_b2 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b2_ula_w[14:0], ULA_RD_DATA[2]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[2]}),
    .DOB({p1_b2_cpu_w,p1_b2_cpu})
);

defparam p1_b2.READ_MODE0 = 1'b0;
defparam p1_b2.READ_MODE1 = 1'b0;
defparam p1_b2.WRITE_MODE0 = 2'b00;
defparam p1_b2.WRITE_MODE1 = 2'b00;
defparam p1_b2.BIT_WIDTH_0 = 1;
defparam p1_b2.BIT_WIDTH_1 = 1;
defparam p1_b2.BLK_SEL_0 = 3'b001;
defparam p1_b2.BLK_SEL_1 = 3'b001;
defparam p1_b2.RESET_MODE = "ASYNC";


DPB p1_b3 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b3_ula_w[14:0], ULA_RD_DATA[3]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[3]}),
    .DOB({p1_b3_cpu_w,p1_b3_cpu})
);

defparam p1_b3.READ_MODE0 = 1'b0;
defparam p1_b3.READ_MODE1 = 1'b0;
defparam p1_b3.WRITE_MODE0 = 2'b00;
defparam p1_b3.WRITE_MODE1 = 2'b00;
defparam p1_b3.BIT_WIDTH_0 = 1;
defparam p1_b3.BIT_WIDTH_1 = 1;
defparam p1_b3.BLK_SEL_0 = 3'b001;
defparam p1_b3.BLK_SEL_1 = 3'b001;
defparam p1_b3.RESET_MODE = "ASYNC";


DPB p1_b4 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b4_ula_w[14:0], ULA_RD_DATA[4]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[4]}),
    .DOB({p1_b4_cpu_w,p1_b4_cpu})
);

defparam p1_b4.READ_MODE0 = 1'b0;
defparam p1_b4.READ_MODE1 = 1'b0;
defparam p1_b4.WRITE_MODE0 = 2'b00;
defparam p1_b4.WRITE_MODE1 = 2'b00;
defparam p1_b4.BIT_WIDTH_0 = 1;
defparam p1_b4.BIT_WIDTH_1 = 1;
defparam p1_b4.BLK_SEL_0 = 3'b001;
defparam p1_b4.BLK_SEL_1 = 3'b001;
defparam p1_b4.RESET_MODE = "ASYNC";


DPB p1_b5 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b5_ula_w[14:0], ULA_RD_DATA[5]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[5]}),
    .DOB({p1_b5_cpu_w,p1_b5_cpu})
);

defparam p1_b5.READ_MODE0 = 1'b0;
defparam p1_b5.READ_MODE1 = 1'b0;
defparam p1_b5.WRITE_MODE0 = 2'b00;
defparam p1_b5.WRITE_MODE1 = 2'b00;
defparam p1_b5.BIT_WIDTH_0 = 1;
defparam p1_b5.BIT_WIDTH_1 = 1;
defparam p1_b5.BLK_SEL_0 = 3'b001;
defparam p1_b5.BLK_SEL_1 = 3'b001;
defparam p1_b5.RESET_MODE = "ASYNC";


DPB p1_b6 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b6_ula_w[14:0], ULA_RD_DATA[6]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[6]}),
    .DOB({p1_b6_cpu_w,p1_b6_cpu})
);

defparam p1_b6.READ_MODE0 = 1'b0;
defparam p1_b6.READ_MODE1 = 1'b0;
defparam p1_b6.WRITE_MODE0 = 2'b00;
defparam p1_b6.WRITE_MODE1 = 2'b00;
defparam p1_b6.BIT_WIDTH_0 = 1;
defparam p1_b6.BIT_WIDTH_1 = 1;
defparam p1_b6.BLK_SEL_0 = 3'b001;
defparam p1_b6.BLK_SEL_1 = 3'b001;
defparam p1_b6.RESET_MODE = "ASYNC";


DPB p1_b7 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(ULA_RD),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA({ 1'b0, ULA_ADDRESS[15:14] }),
    .ADA(ULA_ADDRESS[13:0]),
    .DIA(16'h0),
    .DOA({p1_b7_ula_w[14:0], ULA_RD_DATA[7]}),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[7]}),
    .DOB({p1_b7_cpu_w,p1_b7_cpu})
);

defparam p1_b7.READ_MODE0 = 1'b0;
defparam p1_b7.READ_MODE1 = 1'b0;
defparam p1_b7.WRITE_MODE0 = 2'b00;
defparam p1_b7.WRITE_MODE1 = 2'b00;
defparam p1_b7.BIT_WIDTH_0 = 1;
defparam p1_b7.BIT_WIDTH_1 = 1;
defparam p1_b7.BLK_SEL_0 = 3'b001;
defparam p1_b7.BLK_SEL_1 = 3'b001;
defparam p1_b7.RESET_MODE = "ASYNC";


///////////////////////////////////////////////////////////////////////////////////////////////////
// Page 2 - RAM - 32768-49151

wire [15:0] p2_b0_ula_w;
wire [14:0] p2_b0_cpu_w;
wire  [0:0] p2_b0_cpu;
wire [15:0] p2_b1_ula_w;
wire [14:0] p2_b1_cpu_w;
wire  [1:1] p2_b1_cpu;
wire [15:0] p2_b2_ula_w;
wire [14:0] p2_b2_cpu_w;
wire  [2:2] p2_b2_cpu;
wire [15:0] p2_b3_ula_w;
wire [14:0] p2_b3_cpu_w;
wire  [3:3] p2_b3_cpu;
wire [15:0] p2_b4_ula_w;
wire [14:0] p2_b4_cpu_w;
wire  [4:4] p2_b4_cpu;
wire [15:0] p2_b5_ula_w;
wire [14:0] p2_b5_cpu_w;
wire  [5:5] p2_b5_cpu;
wire [15:0] p2_b6_ula_w;
wire [14:0] p2_b6_cpu_w;
wire  [6:6] p2_b6_cpu;
wire [15:0] p2_b7_ula_w;
wire [14:0] p2_b7_cpu_w;
wire  [7:7] p2_b7_cpu;

DPB p2_b0 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b0_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),	// Don't select if paged out
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[0]}),
    .DOB({p2_b0_cpu_w,p2_b0_cpu})
);

defparam p2_b0.READ_MODE0 = 1'b0;
defparam p2_b0.READ_MODE1 = 1'b0;
defparam p2_b0.WRITE_MODE0 = 2'b00;
defparam p2_b0.WRITE_MODE1 = 2'b00;
defparam p2_b0.BIT_WIDTH_0 = 1;
defparam p2_b0.BIT_WIDTH_1 = 1;
defparam p2_b0.BLK_SEL_0 = 3'b010;
defparam p2_b0.BLK_SEL_1 = 3'b010;
defparam p2_b0.RESET_MODE = "ASYNC";


DPB p2_b1 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
	.DIA(16'h0),
    .DOA(p2_b1_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
	.ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[1]}),
    .DOB({p2_b1_cpu_w,p2_b1_cpu})
);

defparam p2_b1.READ_MODE0 = 1'b0;
defparam p2_b1.READ_MODE1 = 1'b0;
defparam p2_b1.WRITE_MODE0 = 2'b00;
defparam p2_b1.WRITE_MODE1 = 2'b00;
defparam p2_b1.BIT_WIDTH_0 = 1;
defparam p2_b1.BIT_WIDTH_1 = 1;
defparam p2_b1.BLK_SEL_0 = 3'b010;
defparam p2_b1.BLK_SEL_1 = 3'b010;
defparam p2_b1.RESET_MODE = "ASYNC";


DPB p2_b2 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b2_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[2]}),
    .DOB({p2_b2_cpu_w,p2_b2_cpu})
);

defparam p2_b2.READ_MODE0 = 1'b0;
defparam p2_b2.READ_MODE1 = 1'b0;
defparam p2_b2.WRITE_MODE0 = 2'b00;
defparam p2_b2.WRITE_MODE1 = 2'b00;
defparam p2_b2.BIT_WIDTH_0 = 1;
defparam p2_b2.BIT_WIDTH_1 = 1;
defparam p2_b2.BLK_SEL_0 = 3'b010;
defparam p2_b2.BLK_SEL_1 = 3'b010;
defparam p2_b2.RESET_MODE = "ASYNC";


DPB p2_b3 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b3_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[3]}),
    .DOB({p2_b3_cpu_w,p2_b3_cpu})
);

defparam p2_b3.READ_MODE0 = 1'b0;
defparam p2_b3.READ_MODE1 = 1'b0;
defparam p2_b3.WRITE_MODE0 = 2'b00;
defparam p2_b3.WRITE_MODE1 = 2'b00;
defparam p2_b3.BIT_WIDTH_0 = 1;
defparam p2_b3.BIT_WIDTH_1 = 1;
defparam p2_b3.BLK_SEL_0 = 3'b010;
defparam p2_b3.BLK_SEL_1 = 3'b010;
defparam p2_b3.RESET_MODE = "ASYNC";


DPB p2_b4 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b4_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[4]}),
    .DOB({p2_b4_cpu_w,p2_b4_cpu})
);

defparam p2_b4.READ_MODE0 = 1'b0;
defparam p2_b4.READ_MODE1 = 1'b0;
defparam p2_b4.WRITE_MODE0 = 2'b00;
defparam p2_b4.WRITE_MODE1 = 2'b00;
defparam p2_b4.BIT_WIDTH_0 = 1;
defparam p2_b4.BIT_WIDTH_1 = 1;
defparam p2_b4.BLK_SEL_0 = 3'b010;
defparam p2_b4.BLK_SEL_1 = 3'b010;
defparam p2_b4.RESET_MODE = "ASYNC";


DPB p2_b5 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b5_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[5]}),
    .DOB({p2_b5_cpu_w,p2_b5_cpu})
);

defparam p2_b5.READ_MODE0 = 1'b0;
defparam p2_b5.READ_MODE1 = 1'b0;
defparam p2_b5.WRITE_MODE0 = 2'b00;
defparam p2_b5.WRITE_MODE1 = 2'b00;
defparam p2_b5.BIT_WIDTH_0 = 1;
defparam p2_b5.BIT_WIDTH_1 = 1;
defparam p2_b5.BLK_SEL_0 = 3'b010;
defparam p2_b5.BLK_SEL_1 = 3'b010;
defparam p2_b5.RESET_MODE = "ASYNC";


DPB p2_b6 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b6_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[6]}),
    .DOB({p2_b6_cpu_w,p2_b6_cpu})
);

defparam p2_b6.READ_MODE0 = 1'b0;
defparam p2_b6.READ_MODE1 = 1'b0;
defparam p2_b6.WRITE_MODE0 = 2'b00;
defparam p2_b6.WRITE_MODE1 = 2'b00;
defparam p2_b6.BIT_WIDTH_0 = 1;
defparam p2_b6.BIT_WIDTH_1 = 1;
defparam p2_b6.BLK_SEL_0 = 3'b010;
defparam p2_b6.BLK_SEL_1 = 3'b010;
defparam p2_b6.RESET_MODE = "ASYNC";


DPB p2_b7 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p2_b7_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb2),
    .BLKSELB({ 1'b0, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[7]}),
    .DOB({p2_b7_cpu_w,p2_b7_cpu})
);

defparam p2_b7.READ_MODE0 = 1'b0;
defparam p2_b7.READ_MODE1 = 1'b0;
defparam p2_b7.WRITE_MODE0 = 2'b00;
defparam p2_b7.WRITE_MODE1 = 2'b00;
defparam p2_b7.BIT_WIDTH_0 = 1;
defparam p2_b7.BIT_WIDTH_1 = 1;
defparam p2_b7.BLK_SEL_0 = 3'b010;
defparam p2_b7.BLK_SEL_1 = 3'b010;
defparam p2_b7.RESET_MODE = "ASYNC";


///////////////////////////////////////////////////////////////////////////////////////////////////
// Page 3 - RAM - 49152-65535

wire [15:0] p3_b0_ula_w;
wire [14:0] p3_b0_cpu_w;
wire  [0:0] p3_b0_cpu;
wire [15:0] p3_b1_ula_w;
wire [14:0] p3_b1_cpu_w;
wire  [1:1] p3_b1_cpu;
wire [15:0] p3_b2_ula_w;
wire [14:0] p3_b2_cpu_w;
wire  [2:2] p3_b2_cpu;
wire [15:0] p3_b3_ula_w;
wire [14:0] p3_b3_cpu_w;
wire  [3:3] p3_b3_cpu;
wire [15:0] p3_b4_ula_w;
wire [14:0] p3_b4_cpu_w;
wire  [4:4] p3_b4_cpu;
wire [15:0] p3_b5_ula_w;
wire [14:0] p3_b5_cpu_w;
wire  [5:5] p3_b5_cpu;
wire [15:0] p3_b6_ula_w;
wire [14:0] p3_b6_cpu_w;
wire  [6:6] p3_b6_cpu;
wire [15:0] p3_b7_ula_w;
wire [14:0] p3_b7_cpu_w;
wire  [7:7] p3_b7_cpu;

DPB p3_b0 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b0_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[0]}),
    .DOB({p3_b0_cpu_w,p3_b0_cpu})
);

defparam p3_b0.READ_MODE0 = 1'b0;
defparam p3_b0.READ_MODE1 = 1'b0;
defparam p3_b0.WRITE_MODE0 = 2'b00;
defparam p3_b0.WRITE_MODE1 = 2'b00;
defparam p3_b0.BIT_WIDTH_0 = 1;
defparam p3_b0.BIT_WIDTH_1 = 1;
defparam p3_b0.BLK_SEL_0 = 3'b011;
defparam p3_b0.BLK_SEL_1 = 3'b011;
defparam p3_b0.RESET_MODE = "ASYNC";

DPB p3_b1 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b1_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[1]}),
    .DOB({p3_b1_cpu_w,p3_b1_cpu})
);

defparam p3_b1.READ_MODE0 = 1'b0;
defparam p3_b1.READ_MODE1 = 1'b0;
defparam p3_b1.WRITE_MODE0 = 2'b00;
defparam p3_b1.WRITE_MODE1 = 2'b00;
defparam p3_b1.BIT_WIDTH_0 = 1;
defparam p3_b1.BIT_WIDTH_1 = 1;
defparam p3_b1.BLK_SEL_0 = 3'b011;
defparam p3_b1.BLK_SEL_1 = 3'b011;
defparam p3_b1.RESET_MODE = "ASYNC";

DPB p3_b2 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b2_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[2]}),
    .DOB({p3_b2_cpu_w,p3_b2_cpu})
);

defparam p3_b2.READ_MODE0 = 1'b0;
defparam p3_b2.READ_MODE1 = 1'b0;
defparam p3_b2.WRITE_MODE0 = 2'b00;
defparam p3_b2.WRITE_MODE1 = 2'b00;
defparam p3_b2.BIT_WIDTH_0 = 1;
defparam p3_b2.BIT_WIDTH_1 = 1;
defparam p3_b2.BLK_SEL_0 = 3'b011;
defparam p3_b2.BLK_SEL_1 = 3'b011;
defparam p3_b2.RESET_MODE = "ASYNC";

DPB p3_b3 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b3_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[3]}),
    .DOB({p3_b3_cpu_w,p3_b3_cpu})
);

defparam p3_b3.READ_MODE0 = 1'b0;
defparam p3_b3.READ_MODE1 = 1'b0;
defparam p3_b3.WRITE_MODE0 = 2'b00;
defparam p3_b3.WRITE_MODE1 = 2'b00;
defparam p3_b3.BIT_WIDTH_0 = 1;
defparam p3_b3.BIT_WIDTH_1 = 1;
defparam p3_b3.BLK_SEL_0 = 3'b011;
defparam p3_b3.BLK_SEL_1 = 3'b011;
defparam p3_b3.RESET_MODE = "ASYNC";


DPB p3_b4 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b4_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[4]}),
    .DOB({p3_b4_cpu_w,p3_b4_cpu})
);

defparam p3_b4.READ_MODE0 = 1'b0;
defparam p3_b4.READ_MODE1 = 1'b0;
defparam p3_b4.WRITE_MODE0 = 2'b00;
defparam p3_b4.WRITE_MODE1 = 2'b00;
defparam p3_b4.BIT_WIDTH_0 = 1;
defparam p3_b4.BIT_WIDTH_1 = 1;
defparam p3_b4.BLK_SEL_0 = 3'b011;
defparam p3_b4.BLK_SEL_1 = 3'b011;
defparam p3_b4.RESET_MODE = "ASYNC";


DPB p3_b5 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b5_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[5]}),
    .DOB({p3_b5_cpu_w,p3_b5_cpu})
);

defparam p3_b5.READ_MODE0 = 1'b0;
defparam p3_b5.READ_MODE1 = 1'b0;
defparam p3_b5.WRITE_MODE0 = 2'b00;
defparam p3_b5.WRITE_MODE1 = 2'b00;
defparam p3_b5.BIT_WIDTH_0 = 1;
defparam p3_b5.BIT_WIDTH_1 = 1;
defparam p3_b5.BLK_SEL_0 = 3'b011;
defparam p3_b5.BLK_SEL_1 = 3'b011;
defparam p3_b5.RESET_MODE = "ASYNC";

DPB p3_b6 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b6_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[6]}),
    .DOB({p3_b6_cpu_w,p3_b6_cpu})
);

defparam p3_b6.READ_MODE0 = 1'b0;
defparam p3_b6.READ_MODE1 = 1'b0;
defparam p3_b6.WRITE_MODE0 = 2'b00;
defparam p3_b6.WRITE_MODE1 = 2'b00;
defparam p3_b6.BIT_WIDTH_0 = 1;
defparam p3_b6.BIT_WIDTH_1 = 1;
defparam p3_b6.BLK_SEL_0 = 3'b011;
defparam p3_b6.BLK_SEL_1 = 3'b011;
defparam p3_b6.RESET_MODE = "ASYNC";

DPB p3_b7 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(1'b0),
    .RESETA(RESET),
    .WREA(1'b0),
    .BLKSELA(3'b111),
    .ADA(14'h0),
    .DIA(16'h0),
    .DOA(p3_b7_ula_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb),
    .BLKSELB({1'b0,CPU_ADDRESS[15:14]}),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[7]}),
    .DOB({p3_b7_cpu_w,p3_b7_cpu})
);

defparam p3_b7.READ_MODE0 = 1'b0;
defparam p3_b7.READ_MODE1 = 1'b0;
defparam p3_b7.WRITE_MODE0 = 2'b00;
defparam p3_b7.WRITE_MODE1 = 2'b00;
defparam p3_b7.BIT_WIDTH_0 = 1;
defparam p3_b7.BIT_WIDTH_1 = 1;
defparam p3_b7.BLK_SEL_0 = 3'b011;
defparam p3_b7.BLK_SEL_1 = 3'b011;
defparam p3_b7.RESET_MODE = "ASYNC";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Page 4 - RAM - SD card system paged at 0 (32768 dev)

wire [15:0] p4_b0_sd_w;
wire [14:0] p4_b0_cpu_w;
wire  [0:0] p4_b0_cpu;
wire [15:0] p4_b1_sd_w;
wire [14:0] p4_b1_cpu_w;
wire  [1:1] p4_b1_cpu;
wire [15:0] p4_b2_sd_w;
wire [14:0] p4_b2_cpu_w;
wire  [2:2] p4_b2_cpu;
wire [15:0] p4_b3_sd_w;
wire [14:0] p4_b3_cpu_w;
wire  [3:3] p4_b3_cpu;
wire [15:0] p4_b4_sd_w;
wire [14:0] p4_b4_cpu_w;
wire  [4:4] p4_b4_cpu;
wire [15:0] p4_b5_sd_w;
wire [14:0] p4_b5_cpu_w;
wire  [5:5] p4_b5_cpu;
wire [15:0] p4_b6_sd_w;
wire [14:0] p4_b6_cpu_w;
wire  [6:6] p4_b6_cpu;
wire [15:0] p4_b7_sd_w;
wire [14:0] p4_b7_cpu_w;
wire  [7:7] p4_b7_cpu;

DPB p4_b0 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[0] }),
    .DOA(p4_b0_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[0]}),
    .DOB({p4_b0_cpu_w,p4_b0_cpu})
);

defparam p4_b0.READ_MODE0 = 1'b0;
defparam p4_b0.READ_MODE1 = 1'b0;
defparam p4_b0.WRITE_MODE0 = 2'b00;
defparam p4_b0.WRITE_MODE1 = 2'b00;
defparam p4_b0.BIT_WIDTH_0 = 1;
defparam p4_b0.BIT_WIDTH_1 = 1;
defparam p4_b0.BLK_SEL_0 = 3'b100;
defparam p4_b0.BLK_SEL_1 = 3'b100;
defparam p4_b0.RESET_MODE = "ASYNC";

DPB p4_b1 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[1] }),
    .DOA(p4_b1_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[1]}),
    .DOB({p4_b1_cpu_w,p4_b1_cpu})
);

defparam p4_b1.READ_MODE0 = 1'b0;
defparam p4_b1.READ_MODE1 = 1'b0;
defparam p4_b1.WRITE_MODE0 = 2'b00;
defparam p4_b1.WRITE_MODE1 = 2'b00;
defparam p4_b1.BIT_WIDTH_0 = 1;
defparam p4_b1.BIT_WIDTH_1 = 1;
defparam p4_b1.BLK_SEL_0 = 3'b100;
defparam p4_b1.BLK_SEL_1 = 3'b100;
defparam p4_b1.RESET_MODE = "ASYNC";

DPB p4_b2 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[2] }),
    .DOA(p4_b2_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[2]}),
    .DOB({p4_b2_cpu_w,p4_b2_cpu})
);

defparam p4_b2.READ_MODE0 = 1'b0;
defparam p4_b2.READ_MODE1 = 1'b0;
defparam p4_b2.WRITE_MODE0 = 2'b00;
defparam p4_b2.WRITE_MODE1 = 2'b00;
defparam p4_b2.BIT_WIDTH_0 = 1;
defparam p4_b2.BIT_WIDTH_1 = 1;
defparam p4_b2.BLK_SEL_0 = 3'b100;
defparam p4_b2.BLK_SEL_1 = 3'b100;
defparam p4_b2.RESET_MODE = "ASYNC";


DPB p4_b3 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[3] }),
    .DOA(p4_b3_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[3]}),
    .DOB({p4_b3_cpu_w,p4_b3_cpu})
);

defparam p4_b3.READ_MODE0 = 1'b0;
defparam p4_b3.READ_MODE1 = 1'b0;
defparam p4_b3.WRITE_MODE0 = 2'b00;
defparam p4_b3.WRITE_MODE1 = 2'b00;
defparam p4_b3.BIT_WIDTH_0 = 1;
defparam p4_b3.BIT_WIDTH_1 = 1;
defparam p4_b3.BLK_SEL_0 = 3'b100;
defparam p4_b3.BLK_SEL_1 = 3'b100;
defparam p4_b3.RESET_MODE = "ASYNC";


DPB p4_b4 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[4] }),
    .DOA(p4_b4_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[4]}),
    .DOB({p4_b4_cpu_w,p4_b4_cpu})
);

defparam p4_b4.READ_MODE0 = 1'b0;
defparam p4_b4.READ_MODE1 = 1'b0;
defparam p4_b4.WRITE_MODE0 = 2'b00;
defparam p4_b4.WRITE_MODE1 = 2'b00;
defparam p4_b4.BIT_WIDTH_0 = 1;
defparam p4_b4.BIT_WIDTH_1 = 1;
defparam p4_b4.BLK_SEL_0 = 3'b100;
defparam p4_b4.BLK_SEL_1 = 3'b100;
defparam p4_b4.RESET_MODE = "ASYNC";


DPB p4_b5 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[5] }),
    .DOA(p4_b5_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[5]}),
    .DOB({p4_b5_cpu_w,p4_b5_cpu})
);

defparam p4_b5.READ_MODE0 = 1'b0;
defparam p4_b5.READ_MODE1 = 1'b0;
defparam p4_b5.WRITE_MODE0 = 2'b00;
defparam p4_b5.WRITE_MODE1 = 2'b00;
defparam p4_b5.BIT_WIDTH_0 = 1;
defparam p4_b5.BIT_WIDTH_1 = 1;
defparam p4_b5.BLK_SEL_0 = 3'b100;
defparam p4_b5.BLK_SEL_1 = 3'b100;
defparam p4_b5.RESET_MODE = "ASYNC";


DPB p4_b6 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[6] }),
    .DOA(p4_b6_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[6]}),
    .DOB({p4_b6_cpu_w,p4_b6_cpu})
);

defparam p4_b6.READ_MODE0 = 1'b0;
defparam p4_b6.READ_MODE1 = 1'b0;
defparam p4_b6.WRITE_MODE0 = 2'b00;
defparam p4_b6.WRITE_MODE1 = 2'b00;
defparam p4_b6.BIT_WIDTH_0 = 1;
defparam p4_b6.BIT_WIDTH_1 = 1;
defparam p4_b6.BLK_SEL_0 = 3'b100;
defparam p4_b6.BLK_SEL_1 = 3'b100;
defparam p4_b6.RESET_MODE = "ASYNC";


DPB p4_b7 (
    .CLKA(CLK),
    .OCEA(1'b0),
    .CEA(SD_WR),
    .RESETA(RESET),
    .WREA(SD_WR),
    .BLKSELA({1'b1,SD_ADDRESS[15:14]}),
	.ADA(SD_ADDRESS[13:0]),
    .DIA({ 15'b0, SD_WR_DATA[7] }),
    .DOA(p4_b7_sd_w),

    .CLKB(CLK),
    .OCEB(1'b0),
    .CEB(ceb),
    .RESETB(RESET),
    .WREB(wreb4),
    .BLKSELB({ 1'b1, CPU_ADDRESS[15:14] }),
    .ADB(CPU_ADDRESS[13:0]),
    .DIB({15'b0,CPU_WR_DATA[7]}),
    .DOB({p4_b7_cpu_w,p4_b7_cpu})
);

defparam p4_b7.READ_MODE0 = 1'b0;
defparam p4_b7.READ_MODE1 = 1'b0;
defparam p4_b7.WRITE_MODE0 = 2'b00;
defparam p4_b7.WRITE_MODE1 = 2'b00;
defparam p4_b7.BIT_WIDTH_0 = 1;
defparam p4_b7.BIT_WIDTH_1 = 1;
defparam p4_b7.BLK_SEL_0 = 3'b100;
defparam p4_b7.BLK_SEL_1 = 3'b100;
defparam p4_b7.RESET_MODE = "ASYNC";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Combine page/bit outputs into memory area

wire tb_b0;
wire tb_b1;
wire tb_b2;
wire tb_b3;
wire tb_b4;
wire tb_b5;
wire tb_b6;
wire tb_b7;

MUX4 mx_b0 (
    .I0(PAGING[4] ? p4_b0_cpu : p0_b0_cpu),
    .I1(p1_b0_cpu),
    .I2(PAGING[6] ? p0_b0_cpu : p2_b0_cpu),
    .I3(p3_b0_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b0)
);

MUX4 mx_b1 (
    .I0(PAGING[4] ? p4_b1_cpu : p0_b1_cpu),
    .I1(p1_b1_cpu),
    .I2(PAGING[6] ? p0_b1_cpu : p2_b1_cpu),
    .I3(p3_b1_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b1)
);

MUX4 mx_b2 (
    .I0(PAGING[4] ? p4_b2_cpu : p0_b2_cpu),
    .I1(p1_b2_cpu),
    .I2(PAGING[6] ? p0_b2_cpu : p2_b2_cpu),
    .I3(p3_b2_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b2)
);

MUX4 mx_b3 (
    .I0(PAGING[4] ? p4_b3_cpu : p0_b3_cpu),
    .I1(p1_b3_cpu),
    .I2(PAGING[6] ? p0_b3_cpu : p2_b3_cpu),
    .I3(p3_b3_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b3)
);

MUX4 mx_b4 (
    .I0(PAGING[4] ? p4_b4_cpu : p0_b4_cpu),
    .I1(p1_b4_cpu),
    .I2(PAGING[6] ? p0_b4_cpu : p2_b4_cpu),
    .I3(p3_b4_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b4)
);

MUX4 mx_b5 (
    .I0(PAGING[4] ? p4_b5_cpu : p0_b5_cpu),
    .I1(p1_b5_cpu),
    .I2(PAGING[6] ? p0_b5_cpu : p2_b5_cpu),
    .I3(p3_b5_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b5)
);

MUX4 mx_b6 (
    .I0(PAGING[4] ? p4_b6_cpu : p0_b6_cpu),
    .I1(p1_b6_cpu),
    .I2(PAGING[6] ? p0_b6_cpu : p2_b6_cpu),
    .I3(p3_b6_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b6)
);

MUX4 mx_b7 (
    .I0(PAGING[4] ? p4_b7_cpu : p0_b7_cpu),
    .I1(p1_b7_cpu),
    .I2(PAGING[6] ? p0_b7_cpu : p2_b7_cpu),
    .I3(p3_b7_cpu),
    .S0(CPU_ADDRESS[14]),
    .S1(CPU_ADDRESS[15]),
    .O(tb_b7)
);

assign CPU_RD_DATA[0] = oen ? tb_b0 : 1'bz;
assign CPU_RD_DATA[1] = oen ? tb_b1 : 1'bz;
assign CPU_RD_DATA[2] = oen ? tb_b2 : 1'bz;
assign CPU_RD_DATA[3] = oen ? tb_b3 : 1'bz;
assign CPU_RD_DATA[4] = oen ? tb_b4 : 1'bz;
assign CPU_RD_DATA[5] = oen ? tb_b5 : 1'bz;
assign CPU_RD_DATA[6] = oen ? tb_b6 : 1'bz;
assign CPU_RD_DATA[7] = oen ? tb_b7 : 1'bz;

`include "48K ROM Image.v"

//`include "Hobbit Image.v"

`include "SD.v"

endmodule
