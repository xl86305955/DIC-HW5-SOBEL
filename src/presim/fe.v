module fe(clk, reset, fe_act, idata, iaddr, fe_done, data0, data1, data2, data3, data4, data5, data6, data7, data8);
input			 		 clk;
input 		 		 reset;
input 		 		 fe_act;
input		[ 7:0] idata;

output 	[16:0] iaddr;
output 				 fe_done;
output 	[ 7:0] data0;
output 	[ 7:0] data1;
output 	[ 7:0] data2;
output 	[ 7:0] data3;
output 	[ 7:0] data4;
output 	[ 7:0] data5;
output 	[ 7:0] data6;
output 	[ 7:0] data7;
output 	[ 7:0] data8;

reg			[16:0] iaddr;

reg			[ 2:0] cs;
reg 		[ 2:0] ns;

reg 					 act;
reg						 trap;
reg						 fe_done;

reg			[ 1:0] cnt;

reg			[16:0] base_addr;
reg			[16:0] curr_addr;
reg 		[ 7:0] data [0:8];
 
parameter NEXT_LINE  = 12'd258,
					THIRD_LINE = 12'd516;

parameter IDLE = 3'b000,
					FL   = 3'b001,
					NL   = 3'b010,
					TL   = 3'b011,
					DONE = 3'b100;

always @(posedge clk or posedge reset) begin
	if(reset) begin
		act <= 0;
	end
	else begin
		act <= fe_act;
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		cs <= IDLE;
	end
	else begin
		if(act) begin
			cs <= ns;
		end
		else begin
			cs <= IDLE;
		end
	end
end

always @(*) begin
	case(cs)
		IDLE: begin
			ns = fe_act ? FL : IDLE;
		end
		FL:	begin
			if(trap) begin
				ns = cnt == 2 ? NL : FL;
			end
			else begin
				ns = NL;
			end
		end
		NL:	begin
			if(trap) begin
				ns = cnt == 2 ? TL : NL;
			end
			else begin
				ns = TL;
			end
		end
		TL: begin
			if(trap) begin
				ns = cnt == 2 ? DONE : TL;
			end
			else begin
				ns = DONE;
			end
		end
		DONE: begin
				ns = IDLE;
		end
		default: ns = IDLE;
	endcase
end

always @(*) begin
	fe_done = 0;
	case(cs)
		DONE: fe_done = 1;
	endcase
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		cnt <= 0;
	end
	else begin
		if(cs == IDLE) begin
			cnt <= 0;
		end
		else begin
			if(trap) begin
				if(cnt == 2) begin
					cnt <= 0;
				end
				else begin
					cnt <= cnt + 1'b1;
				end
			end
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		trap <= 0;
	end
	else begin
		if(cs == DONE) trap <= 0;
		if(cs == IDLE && fe_act) begin
			if(base_addr == curr_addr) begin
				trap <= 1;
			end
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		base_addr <= 0;
	end
	else begin
		if(trap && cs == IDLE) begin
			base_addr <= base_addr + NEXT_LINE; 
		end
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		curr_addr <= 0;
	end
	else begin 
		if(cs == DONE) begin
			if(trap) begin
				curr_addr <= curr_addr + 2'b11;
			end
			else
				curr_addr <= curr_addr + 1'b1;
		end
	end
end

always @(*) begin
	iaddr = 0;
	case(cs) 
		FL: begin
			iaddr = curr_addr + cnt;
		end
		NL: begin
			iaddr = (curr_addr + NEXT_LINE) + cnt;
		end
		TL: begin
			iaddr = (curr_addr + THIRD_LINE) + cnt;
		end
	endcase
end

integer i;
always @(posedge clk or posedge reset) begin
	if(reset) begin
		for(i=0; i<9; i=i+1) begin
			data[i] <= 0;
		end
	end
	else begin
		if(trap) begin
			if(cs != IDLE && cs != DONE) begin
				data[8] <= idata;
				for(i=0; i<8;i=i+1) begin
					data[i] <= data[i+1];
				end
			end
		end
		else begin
			if(cs == FL) begin
				data[0] <= data[1];
				data[1] <= data[2];
				data[2] <= idata;
			end
			else if(cs == NL) begin
				data[3] <= data[4];
				data[4] <= data[5];
				data[5] <= idata;
			end
			else if(cs == TL) begin
				data[6] <= data[7];
				data[7] <= data[8];
				data[8] <= idata;
			end
		end	
	end
end

assign data0 = data[0];
assign data1 = data[1];
assign data2 = data[2];
assign data3 = data[3];
assign data4 = data[4];
assign data5 = data[5];
assign data6 = data[6];
assign data7 = data[7];
assign data8 = data[8];

endmodule
