// Open-drain I2C master for J7. OE=1 drives 0; OE=0 releases (pull-up).
// Byte commands: START / WRITE / READ / STOP. After START/WRITE/READ, SCL stays low.
// After reset: 9 SCL clocks with SDA released, then STOP (unstick a stretching slave).
module j7_i2c_master #(
	parameter integer CLK_HZ = 25000000,
	parameter integer BUS_HZ = 100000
) (
	input  wire       clk,
	input  wire       rst_n,
	input  wire [1:0] cmd,
	input  wire       cmd_valid,
	output reg        cmd_ready,
	input  wire [7:0] wr_data,
	input  wire       rd_nack,
	output reg  [7:0] rd_data,
	output reg        ack_n,
	output wire       scl_oe,
	output wire       sda_oe,
	input  wire       sda_i
);

localparam [1:0] C_START = 2'b00;
localparam [1:0] C_WRITE = 2'b01;
localparam [1:0] C_READ  = 2'b10;
localparam [1:0] C_STOP  = 2'b11;

localparam integer QTR = CLK_HZ / (BUS_HZ * 4);

localparam [3:0] S_CLR_LO   = 4'd0;
localparam [3:0] S_CLR_HI   = 4'd1;
localparam [3:0] S_IDLE     = 4'd2;
localparam [3:0] S_START0   = 4'd3;
localparam [3:0] S_START1   = 4'd4;
localparam [3:0] S_BIT_SETUP= 4'd5;
localparam [3:0] S_BIT_HIGH = 4'd6;
localparam [3:0] S_BIT_HOLD = 4'd7;
localparam [3:0] S_BIT_LOW  = 4'd8;
localparam [3:0] S_ACK_SETUP= 4'd9;
localparam [3:0] S_ACK_HIGH = 4'd10;
localparam [3:0] S_ACK_HOLD = 4'd11;
localparam [3:0] S_ACK_LOW  = 4'd12;
localparam [3:0] S_STOP0    = 4'd13;
localparam [3:0] S_STOP1    = 4'd14;
localparam [3:0] S_STOP2    = 4'd15;

reg [3:0]  state;
reg [15:0] qcnt;
reg [2:0]  bit_i;
reg [3:0]  clr_i;
reg [7:0]  shreg;
reg        doing_read;
reg        nack_after;
reg        scl_lo;
reg        sda_lo;

assign scl_oe = scl_lo;
assign sda_oe = sda_lo;

wire tick = (qcnt >= QTR[15:0]);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state      <= S_CLR_LO;
		qcnt       <= 16'd0;
		bit_i      <= 3'd7;
		clr_i      <= 4'd0;
		shreg      <= 8'd0;
		doing_read <= 1'b0;
		nack_after <= 1'b0;
		scl_lo     <= 1'b1;
		sda_lo     <= 1'b0;
		cmd_ready  <= 1'b0;
		rd_data    <= 8'd0;
		ack_n      <= 1'b1;
	end else if (!tick) begin
		qcnt <= qcnt + 16'd1;
	end else begin
		qcnt <= 16'd0;
		case (state)
			S_CLR_LO: begin
				scl_lo <= 1'b1;
				sda_lo <= 1'b0;
				state  <= S_CLR_HI;
			end
			S_CLR_HI: begin
				scl_lo <= 1'b0;
				if (clr_i == 4'd8) begin
					sda_lo <= 1'b1;
					state  <= S_STOP0;
					clr_i  <= 4'd0;
				end else begin
					clr_i <= clr_i + 4'd1;
					state <= S_CLR_LO;
				end
			end
			S_IDLE: begin
				cmd_ready <= 1'b1;
				if (cmd_valid) begin
					cmd_ready  <= 1'b0;
					bit_i      <= 3'd7;
					shreg      <= wr_data;
					doing_read <= (cmd == C_READ);
					nack_after <= rd_nack;
					case (cmd)
						C_START: begin
							sda_lo <= 1'b1;
							state  <= S_START0;
						end
						C_WRITE: begin
							sda_lo <= ~wr_data[7];
							scl_lo <= 1'b1;
							state  <= S_BIT_SETUP;
						end
						C_READ: begin
							sda_lo <= 1'b0;
							scl_lo <= 1'b1;
							state  <= S_BIT_SETUP;
						end
						default: begin
							sda_lo <= 1'b1;
							scl_lo <= 1'b1;
							state  <= S_STOP0;
						end
					endcase
				end
			end
			S_START0: begin
				scl_lo <= 1'b1;
				state  <= S_START1;
			end
			S_START1: begin
				state <= S_IDLE;
			end
			S_BIT_SETUP: begin
				scl_lo <= 1'b0;
				state  <= S_BIT_HIGH;
			end
			S_BIT_HIGH: begin
				if (doing_read)
					shreg <= {shreg[6:0], sda_i};
				state <= S_BIT_HOLD;
			end
			S_BIT_HOLD: begin
				scl_lo <= 1'b1;
				state  <= S_BIT_LOW;
			end
			S_BIT_LOW: begin
				if (bit_i == 3'd0) begin
					if (doing_read)
						rd_data <= shreg;
					sda_lo <= doing_read ? (nack_after ? 1'b0 : 1'b1) : 1'b0;
					state  <= S_ACK_SETUP;
				end else begin
					bit_i <= bit_i - 3'd1;
					if (!doing_read) begin
						sda_lo <= ~shreg[6];
						shreg  <= {shreg[6:0], 1'b0};
					end
					state <= S_BIT_SETUP;
				end
			end
			S_ACK_SETUP: begin
				scl_lo <= 1'b0;
				state  <= S_ACK_HIGH;
			end
			S_ACK_HIGH: begin
				if (!doing_read)
					ack_n <= sda_i;
				else
					ack_n <= 1'b0;
				state <= S_ACK_HOLD;
			end
			S_ACK_HOLD: begin
				scl_lo <= 1'b1;
				state  <= S_ACK_LOW;
			end
			S_ACK_LOW: begin
				sda_lo <= 1'b0;
				state  <= S_IDLE;
			end
			S_STOP0: begin
				scl_lo <= 1'b0;
				state  <= S_STOP1;
			end
			S_STOP1: begin
				sda_lo <= 1'b0;
				state  <= S_STOP2;
			end
			S_STOP2: begin
				state     <= S_IDLE;
				cmd_ready <= 1'b1;
			end
			default: state <= S_IDLE;
		endcase
	end
end

endmodule
