# Data Packet Parser 

Modern audio systems require secure, reliable data transmission between multiple
devices sharing a common communication bus. Without proper security measures,
unauthorized devices can access the bus, potentially corrupting data or compromising
system integrity. Additionally, data corruption during transmission can lead to audio glitches, system failures, or security vulnerabilities.

This project implements a secure audio packet processing system in Verilog RTL,
synthesized using Cadence Genus and physically implemented using Cadence Innovus.
The system features a two-stage pipeline: a packet parser that verifies 32-bit audio
packets using XOR checksum validation and extracts data fields (audio data, device ID,
sequence number), followed by a bus controller that grants time-limited bus access only
to authorized devices. The design implements hardware-based security by maintaining
a whitelist of three authorized device IDs (0xA5, 0x5A, 0xFF), each assigned a unique
8-bit access key, with bus grants limited to 10 clock cycles to ensure fair resource
sharing.
The implementation utilizes approximately 200 flip-flops and achieves 100MHz
operation through a 4-state FSM for packet parsing and a timer-based bus arbitration
mechanism. Testing validates complete functionality with 100% packet acceptance for
authorized devices, proper rejection of corrupted packets, and denial of bus access to
unauthorized devices. This hardware-based approach eliminates software vulnerabilities
while providing deterministic, real-time performance essential for secure audio
applications in embedded systems and SoCs.

The secure audio packet processing system consists of two primary modules operating
in cascade:
1. **Audio Packet Parser**: Receives and validates incoming packets.
2. **Bus Controller**: Manages secure bus access for authorized devices
Packet Format Specification
The system processes 32-bit packets with the following structure:


**Bits Field Description**
1. ```[31:24] Checksum``` : 8-bit XOR checksum for
verification

2. ```[23:16] Device ID```: 8-bit unique device identifier
3. ```[15:8] Sequence Number```: 8-bit packet sequence counter

4. ```[7:0] Data```: 8-bit sample(simplified)

## Data Flow
1. **Packet Reception**: 32-bit packet arrives with packet valid signal
2. **Checksum Verification**: Parser calculates XOR of data fields
3. **Data Extraction**: Valid packets have fields extracted
4. **Authorization Check**: Bus controller verifies device ID
5. **Bus Grant**: Authorized devices receive 10-cycle bus access with unique key
## Interface Specification
### System Inputs:
- ```clk```: System clock (100MHz)
- ```rst_n```: Active-low asynchronous reset
- ```packet_in[31:0]```: Input packet data
- ```packet_valid```: Packet ready signal
### System Outputs:
- ```packet_accepted```: Valid packet indicator
- ```packet_rejected```: Invalid packet indicator
- ``audio_data[15:0]``: Extracted audio data (zero-extended)
- ``device_id[7:0]``: Extracted device identifier
- ``sequence_num[7:0]``: Extracted sequence number
- `bus_key[7:0]`: Assigned security key
- `bus_grant`: Bus access granted signal
- `bus_busy`: Bus occupation status

### Finite State Machine Design
**The packet parser implements a 4-state Moore FSM:**
#### State Definitions:
- `IDLE (00)`: Waiting for incoming packet
- `VERIFY (01)`: Performing checksum verification
- `OUTPUT (10)`: Reserved for future data processing
- `DONE (11)`: Signalling completion
#### State Transitions:
1. `IDLE → VERIFY`: When packet_valid = 1
2. `VERIFY → OUTPUT`: Unconditional (1 cycle)
3. `OUTPUT → DONE`: Unconditional (1 cycle)
4. `DONE → IDLE`: Unconditional (1 cycle)
#### **Checksum Algorithm**
The checksum is calculated using bitwise XOR:

`checksum = device_id ^ sequence_num ^ audio_data`
