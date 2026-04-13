`timescale 1ns/1ps
module tb_uart_aes_top;

    reg clk = 0;
    reg reset = 1;
    reg rx;
    wire tx;

    uart_aes_top DUT (.clk(clk), .reset(reset), .rx(rx), .tx(tx));

    always #5 clk = ~clk; //100MHz

    localparam integer CLK_FREQ = 100_000_000;
    localparam integer BAUD     = 115200;
    localparam integer DIV      = CLK_FREQ / BAUD;

    integer i;
    reg [127:0] PLAINTEXT;
    reg [7:0] dummy_ct [0:15];      // not used for decryption
    reg [7:0] captured_pt [0:15];
    reg [127:0] rec_pt;

    // ---------- FIXED PRE-STORED KNOWN AES-128 CIPHERTEXT ----------
    localparam [127:0] PRE_STORED_CT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    initial begin
        $dumpfile("tb_uart_aes_top.vcd");
        $dumpvars(0, tb_uart_aes_top);

        PLAINTEXT = 128'h00112233445566778899aabbccddeeff;  // input PT

        rx = 1'b1;
        #200;
        reset = 0;
        #200;

        // -------------------------------
        // SEND PLAINTEXT to DUT for ENCRYPTION
        // -------------------------------
        $display("\n=== SEND PLAINTEXT ===");
        for (i=0;i<16;i=i+1) begin
            send_uart_byte(PLAINTEXT[8*i +: 8]);
            repeat (DIV/30) @(posedge clk);
        end

        // CAPTURE DUT ENCRYPT RESULT (not used later)
        for (i=0;i<16;i=i+1)
            capture_byte_from_tx(dummy_ct[i]);

        // Small wait so DUT goes to WAIT_RX_CT state
        #(DIV*50);

        // -------------------------------
        // SEND PRE-STORED CIPHERTEXT FOR DECRYPTION
        // -------------------------------
        $display("\n=== SEND PRE-STORED CT FOR DECRYPT ===");
        $display("CT = %032h", PRE_STORED_CT);

        for (i=0;i<16;i=i+1) begin
            send_uart_byte(PRE_STORED_CT[8*i +: 8]);
            repeat (DIV/30) @(posedge clk);
        end

        // CAPTURE DECRYPTED PLAINTEXT
        for (i=0;i<16;i=i+1)
            capture_byte_from_tx(captured_pt[i]);

        rec_pt = 128'h0;
        for (i=0;i<16;i=i+1)
            rec_pt[8*i +: 8] = captured_pt[i];

        $display("DECRYPTED PT = %032h", rec_pt);

        if (rec_pt === PLAINTEXT)
            $display("\n### RESULT = SUCCESS : DECRYPT OK ###");
        else
            $display("\n### RESULT = FAIL : expected %032h ###", PLAINTEXT);

        #2000 $finish;
    end

    // ================= UART byte sender to DUT =================
    task send_uart_byte(input [7:0] data);
        integer k;
        begin
            rx <= 1'b0; repeat (DIV) @(posedge clk);      // start
            for (k=0;k<8;k=k+1) begin
                rx <= data[k]; repeat (DIV) @(posedge clk);
            end
            rx <= 1'b1; repeat (DIV) @(posedge clk);      // stop
            repeat (2) @(posedge clk);
        end
    endtask

    // ================= CAPTURE byte from DUT =================
    task capture_byte_from_tx(output [7:0] outb);
        integer k, timeout;
        reg [7:0] bits;
        begin
            timeout = 0;
            while (tx !== 1'b0) begin       // wait start bit
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 2000000) begin
                    $display("TIMEOUT WAITING FOR TX");
                    $finish;
                end
            end

            repeat (DIV/2) @(posedge clk);   // center of start
            for (k=0;k<8;k=k+1) begin        // LSB first
                bits[k] = tx;
                repeat (DIV) @(posedge clk);
            end
            repeat (DIV) @(posedge clk);     // stop
            outb = bits;
            repeat (2) @(posedge clk);
        end
    endtask

endmodule
