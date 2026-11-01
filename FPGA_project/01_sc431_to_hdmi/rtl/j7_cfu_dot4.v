// RISC-V CUSTOM0 CFU: 4-lane INT8 MAC for pdti8 conv1x1.
// function_id[2:0] = funct3, function_id[9:3] = funct7 (Efinix / VexRiscv).
//   funct7 = 7'h48 (user CFU, bit9=1)
//   funct3 = 0 : SET_IZP  rd=0, izp <= rs1
//   funct3 = 1 : DOT4     rd = sum_i (rs1_i8[i] - izp) * rs2_i8[i]
module j7_cfu_dot4 (
	input             clk,
	input             reset,
	input             cmd_valid,
	output            cmd_ready,
	input      [9:0]  cmd_function_id,
	input      [31:0] cmd_inputs_0,
	input      [31:0] cmd_inputs_1,
	output            rsp_valid,
	input             rsp_ready,
	output     [31:0] rsp_outputs_0
);

reg  signed [31:0] izp;
reg  signed [31:0] custom_result;
reg                custom_result_ready;

wire signed [8:0] a0 = $signed(cmd_inputs_0[7:0]);
wire signed [8:0] a1 = $signed(cmd_inputs_0[15:8]);
wire signed [8:0] a2 = $signed(cmd_inputs_0[23:16]);
wire signed [8:0] a3 = $signed(cmd_inputs_0[31:24]);
wire signed [8:0] w0 = $signed(cmd_inputs_1[7:0]);
wire signed [8:0] w1 = $signed(cmd_inputs_1[15:8]);
wire signed [8:0] w2 = $signed(cmd_inputs_1[23:16]);
wire signed [8:0] w3 = $signed(cmd_inputs_1[31:24]);

/* izp part-select is unsigned in Verilog; keep the full signed 32-bit subtract. */
wire signed [31:0] d0 = a0 - izp;
wire signed [31:0] d1 = a1 - izp;
wire signed [31:0] d2 = a2 - izp;
wire signed [31:0] d3 = a3 - izp;

wire signed [31:0] p0 = d0 * w0;
wire signed [31:0] p1 = d1 * w1;
wire signed [31:0] p2 = d2 * w2;
wire signed [31:0] p3 = d3 * w3;
wire signed [31:0] dot4 = p0 + p1 + p2 + p3;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		izp                 <= 32'sd0;
		custom_result       <= 32'sd0;
		custom_result_ready <= 1'b0;
	end else if (cmd_ready & cmd_valid) begin
		case (cmd_function_id[2:0])
			3'd0: begin
				izp           <= $signed(cmd_inputs_0);
				custom_result <= 32'sd0;
			end
			default: begin
				custom_result <= dot4;
			end
		endcase
		custom_result_ready <= 1'b1;
	end else if (rsp_valid & rsp_ready)
		custom_result_ready <= 1'b0;
end

assign rsp_outputs_0 = custom_result;
assign rsp_valid     = rsp_ready & custom_result_ready;
assign cmd_ready     = rsp_ready & (~custom_result_ready) & (~rsp_valid);

endmodule
