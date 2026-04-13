`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.11.2025 22:35:40
// Design Name: 
// Module Name: tx
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


// FILE: uart_tx.v
`timescale 1ns/1ps
module uart_tx #(
    parameter DATA_BITS = 8,
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)( input  wire  clk,input  wire   reset, input  wire [DATA_BITS-1:0]   din,
    input  wire     start, output reg   tx,output reg     busy);
    localparam integer DIV = CLK_FREQ / BAUD_RATE;

    reg [DATA_BITS+1:0] shift_reg;  // {stop, data[7:0], start}
    reg [31:0]          counter;
    reg [4:0]           bit_idx;
    reg                 sending;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx        <= 1'b1;
            busy      <= 1'b0;
            sending   <= 1'b0;
            counter   <= 0;
            bit_idx   <= 0;
            shift_reg <= {(DATA_BITS+2){1'b1}};
        end else begin
            if (start && !busy) begin
                shift_reg <= {1'b1, din, 1'b0}; // stop, data, start(LSB)
                sending   <= 1'b1;
                busy      <= 1'b1;
                counter   <= 0;
                bit_idx   <= 0;
            end else if (sending) begin
                if (counter == DIV-1) begin
                    counter <= 0;
                    tx      <= shift_reg[bit_idx];
                    bit_idx <= bit_idx + 1'b1;
                    if (bit_idx == DATA_BITS+1) begin
                        sending <= 1'b0;
                        busy    <= 1'b0;
                        tx      <= 1'b1; // idle
                    end
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end

endmodule

