// =============================================================
// Audio Packet Parser Module
// =============================================================

module audio_packet_parser (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] packet_in,
    input  wire        packet_valid,
    output reg         packet_accepted,
    output reg         packet_rejected,
    output reg [15:0]  audio_data,
    output reg [7:0]   device_id,
    output reg [7:0]   sequence_num,
    output reg         parse_done
);

    // Packet format (32 bits total):
    // [31:24] − Checksum (8 bits)
    // [23:16] − Device ID (8 bits)
    // [15:8]  − Sequence Number (8 bits)
    // [7:0]   − Audio Data (8 bits) — simplified for demo

    reg [31:0] packet_reg;
    reg        processing;

    // State machine
    localparam IDLE   = 2'b00;
    localparam VERIFY = 2'b01;
    localparam OUTPUT = 2'b10;
    localparam DONE   = 2'b11;

    reg [1:0] state, next_state;

    // -------------------------------------------------------------
    // State register
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -------------------------------------------------------------
    // Next state logic
    // -------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (packet_valid)
                    next_state = VERIFY;
            end

            VERIFY: next_state = OUTPUT;
            OUTPUT: next_state = DONE;
            DONE:   next_state = IDLE;
        endcase
    end

    // -------------------------------------------------------------
    // Output logic
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_reg       <= 32'b0;
            packet_accepted  <= 1'b0;
            packet_rejected  <= 1'b0;
            audio_data       <= 16'b0;
            device_id        <= 8'b0;
            sequence_num     <= 8'b0;
            parse_done       <= 1'b0;
            processing       <= 1'b0;
        end else begin
            // Default
            parse_done <= 1'b0;

            case (state)
                IDLE: begin
                    packet_accepted <= 1'b0;
                    packet_rejected <= 1'b0;

                    // Don’t clear data outputs here — keep until next packet
                    if (packet_valid) begin
                        packet_reg <= packet_in;
                        processing <= 1'b1;
                    end
                end

                VERIFY: begin
                    if (packet_reg[31:24] == (packet_reg[23:16] ^ packet_reg[15:8] ^ packet_reg[7:0])) begin
                        packet_accepted <= 1'b1;
                        packet_rejected <= 1'b0;

                        // Extract data upon verification
                        audio_data   <= {8'b0, packet_reg[7:0]};
                        device_id    <= packet_reg[23:16];
                        sequence_num <= packet_reg[15:8];
                    end else begin
                        packet_accepted <= 1'b0;
                        packet_rejected <= 1'b1;
                    end
                end

                OUTPUT: begin
                    // Keep accepted/rejected status
                end

                DONE: begin
                    parse_done <= 1'b1;
                    processing <= 1'b0;
                    // Don’t clear accepted/rejected here
                end
            endcase
        end
    end

endmodule


// =============================================================
// Bus Controller Module
// =============================================================

module bus_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        request_bus,
    input  wire [7:0]  device_id,
    input  wire        packet_valid,
    output reg  [7:0]  bus_key,
    output reg         bus_grant,
    output reg         bus_busy
);

    // Authorized device IDs (simplified)
    localparam DEV_ID_1 = 8'hA5;
    localparam DEV_ID_2 = 8'h5A;
    localparam DEV_ID_3 = 8'hFF;

    // Bus keys for authorized devices
    localparam KEY_1 = 8'h3C;
    localparam KEY_2 = 8'hC3;
    localparam KEY_3 = 8'h69;

    reg [7:0] grant_counter;
    reg       device_authorized;

    // -------------------------------------------------------------
    // Authorization check
    // -------------------------------------------------------------
    always @(*) begin
        case (device_id)
            DEV_ID_1,
            DEV_ID_2,
            DEV_ID_3: device_authorized = 1'b1;
            default:  device_authorized = 1'b0;
        endcase
    end

    // -------------------------------------------------------------
    // Bus control logic
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_key       <= 8'b0;
            bus_grant     <= 1'b0;
            bus_busy      <= 1'b0;
            grant_counter <= 8'b0;
        end else begin
            if (request_bus && packet_valid && device_authorized && !bus_busy) begin
                bus_grant     <= 1'b1;
                bus_busy      <= 1'b1;
                grant_counter <= 8'd10; // Grant for 10 cycles

                // Assign key based on device ID
                case (device_id)
                    DEV_ID_1: bus_key <= KEY_1;
                    DEV_ID_2: bus_key <= KEY_2;
                    DEV_ID_3: bus_key <= KEY_3;
                    default:  bus_key <= 8'b0;
                endcase
            end else if (grant_counter > 0) begin
                grant_counter <= grant_counter - 1;
                if (grant_counter == 1) begin
                    bus_grant <= 1'b0;
                    bus_busy  <= 1'b0;
                    bus_key   <= 8'b0;
                end
            end
        end
    end

endmodule


// =============================================================
// Top Module − Cascaded System
// =============================================================

module audio_packet_processor (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] packet_in,
    input  wire        packet_valid,
    output wire        packet_accepted,
    output wire        packet_rejected,
    output wire [15:0] audio_data,
    output wire [7:0]  device_id,
    output wire [7:0]  sequence_num,
    output wire [7:0]  bus_key,
    output wire        bus_grant,
    output wire        bus_busy
);

    wire parse_done;
    wire internal_packet_accepted;
    reg  ready_for_bus;
    reg  [7:0] device_id_latched;

    // -------------------------------------------------------------
    // Capture device ID and ready state when packet is accepted
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_for_bus      <= 1'b0;
            device_id_latched  <= 8'b0;
        end else if (parse_done) begin
            if (internal_packet_accepted) begin
                ready_for_bus     <= 1'b1;
                device_id_latched <= device_id;
            end else begin
                ready_for_bus <= 1'b0;
            end
        end else if (bus_grant) begin
            ready_for_bus <= 1'b0;
        end
    end

    // -------------------------------------------------------------
    // Instantiate packet parser
    // -------------------------------------------------------------
    audio_packet_parser parser (
        .clk(clk),
        .rst_n(rst_n),
        .packet_in(packet_in),
        .packet_valid(packet_valid),
        .packet_accepted(internal_packet_accepted),
        .packet_rejected(packet_rejected),
        .audio_data(audio_data),
        .device_id(device_id),
        .sequence_num(sequence_num),
        .parse_done(parse_done)
    );

    // -------------------------------------------------------------
    // Instantiate bus controller
    // -------------------------------------------------------------
    bus_controller controller (
        .clk(clk),
        .rst_n(rst_n),
        .request_bus(ready_for_bus),
        .device_id(device_id_latched),
        .packet_valid(ready_for_bus),
        .bus_key(bus_key),
        .bus_grant(bus_grant),
        .bus_busy(bus_busy)
    );

    assign packet_accepted = internal_packet_accepted;

endmodule
