// =============================================================
// Testbench: Audio Packet Processor
// =============================================================

module tb_audio_packet_processor;

    reg         clk;
    reg         rst_n;
    reg  [31:0] packet_in;
    reg         packet_valid;

    wire        packet_accepted;
    wire        packet_rejected;
    wire [15:0] audio_data;
    wire [7:0]  device_id;
    wire [7:0]  sequence_num;
    wire [7:0]  bus_key;
    wire        bus_grant;
    wire        bus_busy;

    // -------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------
    audio_packet_processor dut (
        .clk(clk),
        .rst_n(rst_n),
        .packet_in(packet_in),
        .packet_valid(packet_valid),
        .packet_accepted(packet_accepted),
        .packet_rejected(packet_rejected),
        .audio_data(audio_data),
        .device_id(device_id),
        .sequence_num(sequence_num),
        .bus_key(bus_key),
        .bus_grant(bus_grant),
        .bus_busy(bus_busy)
    );

    // -------------------------------------------------------------
    // Clock Generation (10 ns period)
    // -------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------
    // Test Stimulus
    // -------------------------------------------------------------
    initial begin
        // Initialize
        rst_n        = 0;
        packet_in    = 32'b0;
        packet_valid = 0;

        // Apply reset
        #20 rst_n = 1;

        // =============================================================
        // Test Case 1: Valid packet with authorized device (0xA5)
        // =============================================================
        #10;
        $display("\n=== Test Case 1: Valid packet with authorized device ===");

        // Packet: DevID=0xA5, SeqNum=0x01, Data=0xAB
        // Checksum = 0xA5 ^ 0x01 ^ 0xAB = 0x0F
        packet_in = {8'h0F, 8'hA5, 8'h01, 8'hAB};

        $display("Sending packet: 0x%08X", packet_in);
        $display("Expected checksum: 0x%02X, Actual in packet: 0x%02X",
                 (8'hA5 ^ 8'h01 ^ 8'hAB), packet_in[31:24]);

        packet_valid = 1;
        #10 packet_valid = 0;

        // Wait for processing
        wait (packet_accepted || packet_rejected);
        #10;
        $display("Packet accepted: %b", packet_accepted);
        $display("Device ID: 0x%02X", device_id);
        $display("Sequence: 0x%02X", sequence_num);
        $display("Audio Data: 0x%04X", audio_data);

        #40; // Wait for bus controller
        $display("Bus Grant: %b", bus_grant);
        $display("Bus Key: 0x%02X", bus_key);

        // Wait for bus release
        #150;

        // =============================================================
        // Test Case 2: Invalid checksum
        // =============================================================
        #10;
        $display("\n=== Test Case 2: Invalid checksum ===");

        // DevID=0x5A, SeqNum=0x02, Data=0xCD
        // Correct checksum: 0x5A ^ 0x02 ^ 0xCD = 0x93
        // We’ll send wrong checksum 0xFF
        packet_in = {8'hFF, 8'h5A, 8'h02, 8'hCD}; // Wrong checksum
        packet_valid = 1;
        #10 packet_valid = 0;

        wait (packet_accepted || packet_rejected);
        #10;
        $display("Packet rejected: %b", packet_rejected);
        $display("Bus Grant: %b", bus_grant);

        #20; // Delay before next test

        // =============================================================
        // Test Case 3: Valid packet with unauthorized device (0x11)
        // =============================================================
        #10;
        $display("\n=== Test Case 3: Valid packet with unauthorized device ===");

        // DevID=0x11, SeqNum=0x03, Data=0xCD
        // Checksum: 0x11 ^ 0x03 ^ 0xCD = 0xDF
        packet_in = {8'hDF, 8'h11, 8'h03, 8'hCD};
        $display("Sending packet: 0x%08X (checksum = 0x%02X)",
                 packet_in, (8'h11 ^ 8'h03 ^ 8'hCD));

        packet_valid = 1;
        #10 packet_valid = 0;

        wait (packet_accepted || packet_rejected);
        #10;
        $display("Packet accepted: %b", packet_accepted);
        $display("Device ID: 0x%02X", device_id);
        $display("Bus Grant: %b", bus_grant);

        // =============================================================
        // Test Case 4: Different audio data patterns with authorized device
        // =============================================================
        #150;
        $display("\n=== Test Case 4: Different audio data patterns ===");

        // Packet 1: DevID=0x5A, SeqNum=0x20, Data=0xFF
        // Checksum = 0x5A ^ 0x20 ^ 0xFF = 0x85
        packet_in = {8'h85, 8'h5A, 8'h20, 8'hFF};
        packet_valid = 1;
        #10 packet_valid = 0;

        wait (packet_accepted || packet_rejected);
        #10;
        $display("Audio data 0xFF - Data out: 0x%04X", audio_data);

        #40;
        $display("Bus Grant: %b, Bus Key: 0x%02X", bus_grant, bus_key);

        #150; // Wait for bus release

        // Packet 2: DevID=0x5A, SeqNum=0x21, Data=0x55
        // Checksum = 0x5A ^ 0x21 ^ 0x55 = 0x2E
        packet_in = {8'h2E, 8'h5A, 8'h21, 8'h55};
        packet_valid = 1;
        #10 packet_valid = 0;

        wait (packet_accepted || packet_rejected);
        #10;
        $display("Audio data 0x55 - Data out: 0x%04X", audio_data);

        #40;
        $display("Bus Grant: %b, Bus Key: 0x%02X", bus_grant, bus_key);

        // =============================================================
        // Test Case 5: Third authorized device (0xFF)
        // =============================================================
        #150;
        $display("\n=== Test Case 5: Third authorized device (0xFF) ===");

        // DevID=0xFF, SeqNum=0x30, Data=0xAA
        // Checksum = 0xFF ^ 0x30 ^ 0xAA = 0x65
        packet_in = {8'h65, 8'hFF, 8'h30, 8'hAA};
        packet_valid = 1;
        #10 packet_valid = 0;

        wait (packet_accepted || packet_rejected);
        #10;
        $display("Device ID: 0x%02X", device_id);
        $display("Packet accepted: %b", packet_accepted);

        #40;
        $display("Bus Grant: %b, Bus Key: 0x%02X", bus_grant, bus_key);

        // =============================================================
        // End Simulation
        // =============================================================
        #200;
        $display("\n=== Simulation Complete ===");
        $finish;
    end

    // -------------------------------------------------------------
    // Monitor signals
    // -------------------------------------------------------------
    initial begin
        $monitor("Time=%0t | rst_n=%b | packet_valid=%b | accepted=%b | rejected=%b | bus_grant=%b | bus_busy=%b",
                 $time, rst_n, packet_valid, packet_accepted, packet_rejected,
                 bus_grant, bus_busy);
    end

endmodule
