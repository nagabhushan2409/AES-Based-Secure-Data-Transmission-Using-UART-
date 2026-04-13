// FILE: uart_bitmaker.v
`timescale 1ns/1ps
module uart_bitmaker #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       reset,
    // TX side (128-bit -> serial)
    input  wire       start,
    input  wire [127:0] din128,
    output wire       tx,
    output reg        busy,
    // RX side (serial -> 128-bit)
    input  wire       rx,
    output reg  [127:0] dout128,
    output reg        ready
);
    localparam DATA_BITS = 8;

    // --------------- TX path ---------------
    reg        tx_start_pulse;
    reg [7:0]  tx_data;
    wire       tx_busy;
    reg [3:0]  tx_index;
    reg [127:0] tx_buf;
    reg        tx_active;

    uart_tx #(
        .DATA_BITS(DATA_BITS),
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) UTX (
        .clk  (clk),
        .reset(reset),
        .din  (tx_data),
        .start(tx_start_pulse),
        .tx   (tx),
        .busy (tx_busy)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_start_pulse <= 1'b0;
            tx_data        <= 8'h00;
            tx_index       <= 4'd0;
            tx_buf         <= 128'h0;
            tx_active      <= 1'b0;
            busy           <= 1'b0;
        end else begin
            tx_start_pulse <= 1'b0;

            if (start && !tx_active && !busy) begin
                tx_buf    <= din128;
                tx_index  <= 4'd0;
                tx_active <= 1'b1;
                busy      <= 1'b1;
            end

            if (tx_active) begin
                if (!tx_busy && !tx_start_pulse) begin
                    tx_data        <= tx_buf[7:0];
                    tx_buf         <= {8'h00, tx_buf[127:8]};
                    tx_start_pulse <= 1'b1;
                    tx_index       <= tx_index + 1'b1;
                    if (tx_index == 4'd15) begin
                        tx_active <= 1'b0;
                    end
                end
            end else begin
                if (!tx_busy && busy)
                    busy <= 1'b0;
            end
        end
    end

    // --------------- RX path ---------------
    wire [7:0] rx_byte;
    wire       rx_ready;
    reg  [3:0] rx_index;
    reg [127:0] rx_buf;

    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) URX (
        .clk  (clk),
        .reset(reset),
        .rx   (rx),
        .dout (rx_byte),
        .ready(rx_ready)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_index <= 4'd0;
            rx_buf   <= 128'h0;
            dout128  <= 128'h0;
            ready    <= 1'b0;
        end else begin
            ready <= 1'b0;
            if (rx_ready) begin
                rx_buf   <= {rx_byte, rx_buf[127:8]};
                rx_index <= rx_index + 1'b1;
                if (rx_index == 4'd15) begin
                    dout128  <= {rx_byte, rx_buf[127:8]};
                    ready    <= 1'b1;
                    rx_index <= 4'd0;
                end
            end
        end
    end

endmodule
