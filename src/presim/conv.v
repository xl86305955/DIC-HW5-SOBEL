module  conv(sel, buf0, buf1, buf2, buf3, buf4, buf5, buf6, buf7, buf8, tmp);

input						sel;
input 	[ 7:0]  buf0;
input 	[ 7:0]  buf1;
input 	[ 7:0]  buf2;
input 	[ 7:0]  buf3;
input 	[ 7:0]  buf4;
input 	[ 7:0]  buf5;
input 	[ 7:0]  buf6;
input 	[ 7:0]  buf7;
input 	[ 7:0]  buf8;

output 	[11:0]  tmp;

reg   	[11:0]  buff0;
reg   	[11:0]  buff1;
reg   	[11:0]  buff2;
reg   	[11:0]  buff3;
reg   	[11:0]  buff4;
reg   	[11:0]  buff5;
reg   	[11:0]  buff6;
reg   	[11:0]  buff7;
reg   	[11:0]  buff8;

wire  	[11:0]  tmp;

parameter	CONVX = 1'b0,
					CONVY = 1'b1;

assign tmp = ((buff0 + buff1) + (buff2 + buff3) + (buff4 + buff5) + (buff6 + buff7) + buff8);

always @(*) begin
	case(sel)
		CONVX: begin
			buff0 = {4'b0, buf0};
			buff1 = 10'b0;
			buff2 = ~{4'b0,buf2} + 1'b1;
			buff3 = {4'b0, buf3} << 1;
			buff4 = 10'b0;
			buff5 = ~({4'b0, buf5} << 1) + 1'b1;
			buff6 = {4'b0, buf6};
			buff7 = 10'b0;
			buff8 = ~{4'b0, buf8} + 1'b1;
		end
		CONVY: begin
			buff0 = {4'b0, buf0};
			buff1 = {4'b0, buf1} << 1;
			buff2 = {4'b0, buf2};
			buff3 = 10'b0;
			buff4 = 10'b0;
			buff5 = 10'b0;
			buff6 = ~{4'b0, buf6} + 1'b1;
			buff7 = ~({4'b0, buf7} << 1) + 1'b1;
			buff8 = ~{4'b0, buf8} + 1'b1;
		end
	endcase
end

endmodule
