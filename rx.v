`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.11.2025 22:36:01
// Design Name: 
// Module Name: rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// FILE: uart_rx.v
`timescale 1ns/1ps
module uart_rx #(
    parameter DATA_BITS = 8,
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 rx,
    output reg  [DATA_BITS-1:0] dout,
    output reg                  ready
);
    localparam integer DIV  = CLK_FREQ / BAUD_RATE;
    localparam integer HALF = DIV / 2;

    reg [31:0]          counter;
    reg [4:0]           bit_idx;
    reg [DATA_BITS-1:0] shift;
    reg                 receiving;
    reg                 half_wait;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dout      <= 0;
            ready     <= 0;
            counter   <= 0;
            bit_idx   <= 0;
            shift     <= 0;
            receiving <= 0;
            half_wait <= 0;
        end else begin
            ready <= 0;
               if (!receiving) begin
                if (!rx) begin             // start bit detected
                    receiving <= 1'b1;
                    half_wait <= 1'b1;
                    counter   <= 0;
                    bit_idx   <= 0;
                end
            end else begin
                counter <= counter + 1'b1;

                if (half_wait) begin
                    if (counter == HALF-1) begin
                        counter   <= 0;
                        half_wait <= 1'b0;
                    end
                end else if (counter == DIV-1) begin
                    counter <= 0;
                    if (bit_idx < DATA_BITS) begin
                        shift[bit_idx] <= rx; // LSB-first
                        bit_idx        <= bit_idx + 1'b1;
                    end else begin
                        dout      <= shift;
                        ready     <= 1'b1;
                        receiving <= 1'b0;
                    end
                end
            end
        end end  endmodule

