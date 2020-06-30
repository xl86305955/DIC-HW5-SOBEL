`timescale 1ns/10ps
//`include "fe.v"
//`include "conv.v"
module  SOBEL(clk,reset,busy,ready,iaddr,idata,cdata_rd,cdata_wr,caddr_rd,caddr_wr,cwr,crd,csel);
input								clk;
input								reset;
output							busy;	
input								ready;	
output		[16:0]		iaddr;
input  		[ 7:0]		idata;	
input			[ 7:0]		cdata_rd;
output		[ 7:0]		cdata_wr;
output 		[15:0]		caddr_rd;
output 		[15:0]		caddr_wr;
output							cwr,crd;
output 		[ 1:0]		csel;

reg				[ 7:0]    cdata_wr;
reg				[15:0]    caddr_wr;
reg									busy;
reg									crd;
reg									cwr;
reg				[ 1:0]    csel;

reg				[ 2:0]   	cs;
reg 			[ 2:0]    ns;

wire			[ 7:0]    _data0;
wire			[ 7:0]    _data1;
wire			[ 7:0]    _data2;
wire			[ 7:0]    _data3;
wire			[ 7:0]    _data4;
wire			[ 7:0]    _data5;
wire			[ 7:0]    _data6;
wire			[ 7:0]    _data7;
wire			[ 7:0]    _data8;

reg 			[ 7:0] 		data0;
reg				[ 7:0] 		data1;
reg				[ 7:0] 		data2;
reg				[ 7:0] 		data3;
reg				[ 7:0] 		data4;
reg				[ 7:0] 		data5;
reg				[ 7:0] 		data6;
reg				[ 7:0] 		data7;
reg				[ 7:0] 		data8;

reg 			[ 7:0]    convx;
reg 			[ 7:0]    convy;

wire								is_rnd;
wire 			[ 8:0]    rnd;
wire 			[ 8:0]    comb;

wire 			[11:0]    tmp;

parameter	THRESHHOLD = 12'h0FF;
parameter  IDLE  = 3'b000,
					 FETCH = 3'b001,
					 CONVX = 3'b010,
					 CONVY = 3'b011,
					 COMB  = 3'b100,
					 WB		 = 3'b101,
					 DONE  = 3'b110;

reg fetch_act;

wire fe_done;

always @(posedge clk or posedge reset) begin
	if(reset) begin
		busy <= 0;
	end
	else begin
		if(ready) begin
			busy <= 1;
		end
		else if(cs == DONE) begin
			busy <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end

always @(*) begin
	ns = IDLE;
	case(cs)
		IDLE: begin
			ns = FETCH;
		end
		FETCH: begin
			ns = fe_done ? CONVX : FETCH;
		end
		CONVX: begin
			ns = CONVY;	
		end
		CONVY: begin
			ns = COMB;
		end
		COMB: begin
			ns = WB;
		end
		WB: begin
			ns = caddr_wr == 16'hffff ? DONE : FETCH;
		end
		DONE: begin
			ns = DONE;
		end
		default: ns = IDLE;
	endcase
end

assign is_rnd = rnd[0];
assign rnd = {1'b0, convx} + {1'b0, convy};
assign comb = is_rnd ? (rnd + 1)>> 1 : rnd >> 1;

always @(*) begin
  fetch_act = 0;
	crd = 0;
	cwr = 0;
	csel = 2'b00;
	cdata_wr = 0;
	case(cs)
		FETCH: begin
			fetch_act = 1;
		end
		CONVX: begin
			cwr  = 1;
			csel = 2'b01;
			cdata_wr = tmp[11] ? 8'b0 : tmp > THRESHHOLD ? THRESHHOLD : tmp[7:0]; 
		end
		CONVY: begin
			cwr  = 1;
			csel = 2'b10;
			cdata_wr = tmp[11] ? 8'b0 : tmp > THRESHHOLD ? THRESHHOLD : tmp[7:0]; 
		end
		COMB: begin
			cwr = 1;
			csel = 2'b11;
			cdata_wr = comb[7:0];
		end
	endcase
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		data0 <= 0;
		data1 <= 0;
		data2 <= 0;
		data3 <= 0;
		data4 <= 0;
		data5 <= 0;
		data6 <= 0;
		data7 <= 0;
		data8 <= 0;
	end
	else begin
		if(fe_done) begin
			data0 <= _data0;
			data1 <= _data1;
			data2 <= _data2;
			data3 <= _data3;
			data4 <= _data4;
			data5 <= _data5;
			data6 <= _data6;
			data7 <= _data7;
			data8 <= _data8;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		caddr_wr <= 0;
	end
	else begin
		if(cs == WB) begin
			caddr_wr <= caddr_wr + 1'b1;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		convx <= 0;
	end
	else begin
		if(cs == CONVX) begin
			convx <= cdata_wr;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		convy <= 0;
	end
	else begin
		if(cs == CONVY) begin
			convy <= cdata_wr;
		end
	end
end

fe fe1(
	.clk			(clk), 
	.reset		(reset), 
	.fe_act   (fetch_act), 
	.idata    (idata), 
	.iaddr    (iaddr), 
	.fe_done  (fe_done),
	.data0		(_data0),
	.data1		(_data1),
	.data2		(_data2),
	.data3		(_data3),
	.data4		(_data4),
	.data5		(_data5),
	.data6		(_data6),
	.data7		(_data7),
	.data8		(_data8)
);

conv conv1(
	.sel			(csel[1]), 
	.buf0			(data0), 
	.buf1			(data1), 
	.buf2			(data2), 
	.buf3			(data3), 
	.buf4			(data4), 
	.buf5			(data5), 
	.buf6			(data6), 
	.buf7			(data7), 
	.buf8			(data8), 
	.tmp		  (tmp)
);

endmodule
