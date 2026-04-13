# AES-Based Secure Data Transmission Using UART

## Overview
This project implements a secure data transmission system using the Advanced Encryption Standard (AES) algorithm over UART communication. The transmitter encrypts the input data before sending it through UART, and the receiver decrypts the received data to retrieve the original message.

The project ensures secure and reliable serial communication, making it suitable for embedded systems and hardware security applications.

## Features
- AES encryption for secure data transmission
- UART-based serial communication
- Real-time encryption and decryption
- Reliable transmitter and receiver modules
- Suitable for FPGA / embedded system implementation

## Technologies Used
- Verilog / HDL
- UART Protocol
- AES Encryption Algorithm
- FPGA / Simulation Tools (Vivado / ModelSim)

## Project Structure
- `aes_encrypt.v` – AES encryption module  
- `aes_decrypt.v` – AES decryption module  
- `uart_tx.v` – UART transmitter module  
- `uart_rx.v` – UART receiver module  
- `top_module.v` – Top-level integration  
- `testbench.v` – Simulation testbench  

## Working
1. User enters input data.
2. AES module encrypts the plaintext.
3. Encrypted data is sent through UART transmitter.
4. UART receiver receives ciphertext.
5. AES module decrypts the received data.
6. Original message is displayed/recovered.

## Applications
- Secure embedded communication
- IoT device security
- Serial data protection
- FPGA-based security systems

## Future Enhancements
- Higher baud rate support
- Wireless secure communication
- Low-power optimization

## Author
Your Name
