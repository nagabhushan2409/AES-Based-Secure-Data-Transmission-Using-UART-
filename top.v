// FILE: uart_aes_top.v
`timescale 1ns/1ps

module uart_aes_top (
    input  wire clk,
    input  wire reset,   // active-high
    input  wire rx,      // UART RX from PC / TB
    output wire tx       // UART TX to PC / TB
);

   
    wire [127:0] rx_block;
    wire         rx_ready;
    reg          start_tx_block;
    wire         busy_tx_block;
    reg  [127:0] tx_block;

    uart_bitmaker #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(115200)
    ) BIT (
        .clk    (clk),
        .reset  (reset),
        .start  (start_tx_block),
        .din128 (tx_block),
        .tx     (tx),
        .busy   (busy_tx_block),
        .rx     (rx),
        .dout128(rx_block),
        .ready  (rx_ready)
    );

   
    reg  [127:0] aes_block;
    wire [127:0] aes_result;
    wire         aes_result_valid_raw;
    wire         aes_ready;

    reg          encdec;        // 1 = enc, 0 = dec
    reg          init_pulse;    // key schedule
    reg          next_pulse;    // process block

    reg  [127:0] key_const;
    wire [255:0] key_full = {key_const, 128'h0};
    wire         keylen   = 1'b0;  // 0 = 128-bit key

    aes_core AES (
        .clk         (clk),
        .reset_n     (~reset),
        .encdec      (encdec),
        .init        (init_pulse),
        .next        (next_pulse),
        .ready       (aes_ready),
        .key         (key_full),
        .keylen      (keylen),
        .block       (aes_block),
        .result      (aes_result),
        .result_valid(aes_result_valid_raw)
    );

   
    reg  aes_valid_d;
    wire aes_valid = aes_result_valid_raw & ~aes_valid_d;

    reg [127:0] aes_latched;

    reg [127:0] captured_block;
    reg         captured_valid;

    reg [127:0] first_plaintext;
    reg         first_plaintext_valid;

 
    localparam S_AES_INIT   = 4'd0,
               S_WAIT_READY = 4'd1,
               S_IDLE       = 4'd2,
               S_ENC_START  = 4'd3,
               S_ENC_WAIT   = 4'd4,
               S_SEND_CT    = 4'd5,
               S_WAIT_TX1   = 4'd6,
               S_WAIT_RX_CT = 4'd7,
               S_DEC_START  = 4'd8,
               S_DEC_WAIT   = 4'd9,
               S_SEND_PT    = 4'd10,
               S_WAIT_TX2   = 4'd11;

    reg [3:0] state, next_state;
    initial begin
        key_const             = 128'h000102030405060708090A0B0C0D0E0F;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state                <= S_AES_INIT;

            init_pulse           <= 1'b0;
            next_pulse           <= 1'b0;
            start_tx_block       <= 1'b0;

            encdec               <= 1'b1;

            aes_block            <= 128'h0;
            aes_latched          <= 128'h0;

            captured_block       <= 128'h0;
            captured_valid       <= 1'b0;

            first_plaintext      <= 128'h0;
            first_plaintext_valid<= 1'b0;

            tx_block             <= 128'h0;

            aes_valid_d          <= 1'b0;
        end
        else begin
            init_pulse     <= 1'b0;
            next_pulse     <= 1'b0;
            start_tx_block <= 1'b0;

            aes_valid_d    <= aes_result_valid_raw;

            if (rx_ready) begin
                captured_block <= rx_block;
                captured_valid <= 1'b1;

                if (!first_plaintext_valid) begin
                    first_plaintext       <= rx_block;
                    first_plaintext_valid <= 1'b1;
                end
            end

            state <= next_state;
            case (state)
                S_AES_INIT: begin
                    init_pulse <= 1'b1;
                end
                S_ENC_START: begin
                    aes_block      <= captured_block;
                    encdec         <= 1'b1;   // encrypt
                    next_pulse     <= 1'b1;
                    captured_valid <= 1'b0;   // consumed
                end

                S_ENC_WAIT: begin
                    if (aes_valid) begin
                        aes_latched <= aes_result;  // latch ciphertext
                    end
                end

                S_SEND_CT: begin
                    tx_block       <= aes_latched; // send ciphertext
                    start_tx_block <= 1'b1;
                end

                S_DEC_START: begin
                    aes_block      <= captured_block;
                    encdec         <= 1'b0;   // decrypt
                    next_pulse     <= 1'b1;
                    captured_valid <= 1'b0;
                end

                S_DEC_WAIT: begin
                    if (aes_valid) begin
                        tx_block <= aes_result; 
                    end
                end

                S_SEND_PT: begin
                    start_tx_block <= 1'b1;
                end

                default: begin
                end
            endcase
        end
    end
    always @* begin
        next_state = state;

        case (state)
            S_AES_INIT:   next_state = S_WAIT_READY;

            S_WAIT_READY: begin
                if (aes_ready)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (captured_valid)
                    next_state = S_ENC_START;
            end
            S_ENC_START:  next_state = S_ENC_WAIT;

            S_ENC_WAIT: begin
                if (aes_valid)
                    next_state = S_SEND_CT;
            end

            S_SEND_CT:    next_state = S_WAIT_TX1;

            S_WAIT_TX1: begin
                if (!busy_tx_block)
                    next_state = S_WAIT_RX_CT;
            end

            S_WAIT_RX_CT: begin
                if (captured_valid)
                    next_state = S_DEC_START;
            end

            S_DEC_START:  next_state = S_DEC_WAIT;

            S_DEC_WAIT: begin
                if (aes_valid)
                    next_state = S_SEND_PT;
            end

            S_SEND_PT:    next_state = S_WAIT_TX2;

            S_WAIT_TX2: begin
                if (!busy_tx_block)
                    next_state = S_IDLE;
            end

            default:      next_state = S_IDLE;
        endcase
    end

endmodule
