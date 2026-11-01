// RGMII RX only: skip preamble, accept IPv4/UDP port 5000, magic 8TUN.
// Broadcast OK. No TX, no extra PLL.
module udp_gain_rx (
	input  wire       clk,
	input  wire       rst_n,
	input  wire [7:0] gmii_rxd,
	input  wire       gmii_rx_dv,
	output reg  [2:0] r_gain,
	output reg  [2:0] g_gain,
	output reg  [2:0] b_gain,
	output reg  [7:0] analog_gain,
	output reg        analog_we,
	output reg [15:0] cam_addr,
	output reg  [7:0] cam_data,
	output reg        cam_we
);

reg        dv_d;
reg [10:0] idx;
reg        in_frame;
reg [7:0]  et0;
reg [7:0]  proto;
reg [15:0] dport;
reg [7:0]  p [0:11];
integer    i;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		dv_d        <= 1'b0;
		idx         <= 11'd0;
		in_frame    <= 1'b0;
		et0         <= 8'd0;
		proto       <= 8'd0;
		dport       <= 16'd0;
		r_gain      <= 3'd6;
		g_gain      <= 3'd7;
		b_gain      <= 3'd5;
		analog_gain <= 8'd40;
		analog_we   <= 1'b0;
		cam_addr    <= 16'd0;
		cam_data    <= 8'd0;
		cam_we      <= 1'b0;
		for (i = 0; i < 12; i = i + 1)
			p[i] <= 8'd0;
	end else begin
		dv_d      <= gmii_rx_dv;
		analog_we <= 1'b0;
		cam_we    <= 1'b0;

		if (!gmii_rx_dv) begin
			in_frame <= 1'b0;
			idx      <= 11'd0;
		end else if (!in_frame) begin
			if (gmii_rxd == 8'hD5)
				in_frame <= 1'b1;
		end else begin
			idx <= idx + 11'd1;
			if (idx == 11'd12)
				et0 <= gmii_rxd;
			if (idx == 11'd23)
				proto <= gmii_rxd;
			if (idx == 11'd36)
				dport[15:8] <= gmii_rxd;
			if (idx == 11'd37)
				dport[7:0] <= gmii_rxd;
			if (idx >= 11'd42 && idx <= 11'd53)
				p[idx - 11'd42] <= gmii_rxd;
			if (dv_d && (idx == 11'd54)) begin
				if ((et0 == 8'h08) && (proto == 8'd17) && (dport == 16'd5000) &&
					(p[0] == 8'h38) && (p[1] == 8'h54) && (p[2] == 8'h55) && (p[3] == 8'h4E) &&
					(p[4] == 8'h57)) begin
					case (p[5])
						8'h00: r_gain <= p[7][2:0];
						8'h01: g_gain <= p[7][2:0];
						8'h02: b_gain <= p[7][2:0];
						8'h10: begin
							analog_gain <= p[7];
							analog_we   <= 1'b1;
						end
						8'h20: begin
							cam_addr <= {p[6], p[7]};
							cam_data <= p[8];
							cam_we   <= 1'b1;
						end
						default: ;
					endcase
				end
			end
		end
	end
end

endmodule
