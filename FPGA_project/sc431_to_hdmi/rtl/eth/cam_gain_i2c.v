// Map analog index 0..177 to SC431 0x3E08/0x3E09 (from ver1_4_xml_v0006).
module cam_gain_i2c (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        analog_we,
	input  wire [7:0]  analog_gain,
	input  wire        cam_we,
	input  wire [15:0] cam_addr,
	input  wire [7:0]  cam_data,
	output reg         extra_req,
	output reg  [15:0] extra_addr,
	output reg  [7:0]  extra_data,
	input  wire        extra_ack
);

reg [7:0]  ag;
reg [7:0]  d3e08, d3e09;
reg [15:0] raw_a;
reg [7:0]  raw_d;
reg [2:0]  st;

always @(*) begin
	if (ag < 8'd18) begin
		d3e08 = 8'h00;
		d3e09 = 8'h20 + ag;
	end else if (ag < 8'd50) begin
		d3e08 = 8'h80;
		d3e09 = 8'h20 + (ag - 8'd18);
	end else if (ag < 8'd82) begin
		d3e08 = 8'h81;
		d3e09 = 8'h20 + (ag - 8'd50);
	end else if (ag < 8'd114) begin
		d3e08 = 8'h83;
		d3e09 = 8'h20 + (ag - 8'd82);
	end else if (ag < 8'd146) begin
		d3e08 = 8'h87;
		d3e09 = 8'h20 + (ag - 8'd114);
	end else begin
		d3e08 = 8'h8F;
		d3e09 = 8'h20 + (ag - 8'd146);
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		st         <= 3'd0;
		extra_req  <= 1'b0;
		extra_addr <= 16'd0;
		extra_data <= 8'd0;
		ag         <= 8'd40;
		raw_a      <= 16'd0;
		raw_d      <= 8'd0;
	end else begin
		if (analog_we)
			ag <= (analog_gain > 8'd177) ? 8'd177 : analog_gain;
		if (cam_we) begin
			raw_a <= cam_addr;
			raw_d <= cam_data;
		end
		case (st)
			3'd0: begin
				extra_req <= 1'b0;
				if (analog_we)
					st <= 3'd1;
				else if (cam_we)
					st <= 3'd5;
			end
			3'd1: begin
				extra_addr <= 16'h3E08;
				extra_data <= d3e08;
				extra_req  <= 1'b1;
				if (extra_ack)
					st <= 3'd2;
			end
			3'd2: begin
				extra_req <= 1'b0;
				if (!extra_ack)
					st <= 3'd3;
			end
			3'd3: begin
				extra_addr <= 16'h3E09;
				extra_data <= d3e09;
				extra_req  <= 1'b1;
				if (extra_ack)
					st <= 3'd4;
			end
			3'd4: begin
				extra_req <= 1'b0;
				if (!extra_ack)
					st <= 3'd0;
			end
			3'd5: begin
				extra_addr <= raw_a;
				extra_data <= raw_d;
				extra_req  <= 1'b1;
				if (extra_ack)
					st <= 3'd4;
			end
			default: st <= 3'd0;
		endcase
	end
end

endmodule
