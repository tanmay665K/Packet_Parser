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
