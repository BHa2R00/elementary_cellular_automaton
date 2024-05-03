module center_cell (
	output reg nst, 
	input [2:0] cst, 
	input [7:0] rule, 
	input rstn, setn, clk 
);

always@(negedge rstn or posedge clk) begin
	if(!rstn) nst <= 0;
	else if(setn) nst <= rule[cst];
end

endmodule


module evolution (
	output idle, 
	output reg [255:0] nst, 
	input [255:0] cst, 
	input [7:0] rule, 
	input rstn, setn, clk 
);

reg [7:0] bth;
wire [7:0] bth0 = bth - 8'd1;
wire [7:0] bth1 = bth + 8'd1;

wire [2:0] cst1 = {cst[bth1], cst[bth], cst[bth0]};
wire nst1;

center_cell u_center_cell(
	.nst(nst1), 
	.cst(cst1), 
	.rule(rule), 
	.rstn(rstn), .setn(setn), .clk(clk) 
);

assign idle = bth1 == 256'd0;

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		nst <= 256'd0;
		bth <= 8'd0;
	end
	else if(setn) begin
		bth <= bth1;
		nst[bth] <= nst1;
	end
end

endmodule




`timescale 1ns/1ps
module tb;

wire idle;
wire [255:0] nst;
reg [255:0] cst;
reg [7:0] rule;
reg rstn, setn, clk;

evolution u_evolution(
	.idle(idle), 
	.nst(nst), 
	.cst(cst), 
	.rule(rule), 
	.rstn(rstn), .setn(setn), .clk(clk) 
);

reg [7:0] b;

initial clk = 0;
always #1 clk = ~clk;

task t1;
	$write("rule = %d\n", rule);
	cst = 1;
	@(posedge clk) rstn = 1;
	@(posedge clk) setn = 1;
	repeat(256) begin
		@(posedge idle);
		cst = nst;
		//$write("%b\n", cst);
		b = 0;
		repeat(256) begin
			if(cst[b]) $write("#");
			else $write(" ");
			b = b + 1;
		end
		$write("\n");
	end
	@(posedge clk) setn = 0;
	@(posedge clk) rstn = 0;
endtask

initial begin
	//$dumpfile("a.fst");
	//$dumpvars(0, tb);
	rstn = 0;
	setn = 0;
	rule = 8'd0;
	repeat(1<<8) begin
		t1;
		rule = rule + 8'd1;
	end
	$finish;
end

endmodule
