/*
Author  -->  Jatin Ramchandani
Brief   -->  NEC Infrared Decoder for GOW1NR-LV9QN88P C6/I5
Company -->  DSA GmbH, Aachen
Version -->  1.1
Date    -->  26/09/2023
*/

module ir_decoder (
  input clkin,                                                                                                      // Input clock: 20MHz
  input wire ir_signal,                                                                                             // Incoming IR signal (active-low receiver)
  output wire [31:0] decoded_data                                                                                   // Decoded data output (32-bit)
);
  // Defined states for Finite State Machine
  parameter IDLE  = 2'b00;
  parameter START = 2'b01;
  parameter DATA  = 2'b10;
  parameter BIT   = 2'b11;

  reg [31:0] counter;    // bit counter (0..32)
  reg [31:0] counter2;   // measures the 9 ms leader burst (low)
  reg [31:0] counter3;   // measures the 4.5 ms leader space (high)
  reg [31:0] duration;   // measures each bit's space (high)

  // Define other parameters
  parameter DATA_WIDTH = 32;            // Width of the decoded data
  // Internal registers
  reg [DATA_WIDTH-1:0] data_reg = 0;
  reg [1:0] state = 2'b00;

  wire clkout_o;

  reg prev_signal = 0;
  wire falling_edge;
  assign falling_edge = prev_signal && ~ir_signal;   // high->low : a burst starts

  // Always block to implement the state machine
  always @(posedge clkout_o) begin
    prev_signal <= ir_signal;
    case (state)
      IDLE: begin
        if (!ir_signal) begin
          counter2 <= counter2 + 1;                  // timing the leader burst
        end else begin                               // burst ended (line went high)
          if (counter2 >= 160000) begin              // ~9 ms (nominal 180000) -> valid leader
            state <= START;
          end
          counter2 <= 0;                             // FIX: reset every time (also clears false starts)
          counter3 <= 0;
        end
      end
      START: begin
        if (ir_signal) begin
          counter3 <= counter3 + 1;                  // timing the leader space
        end else begin                               // FIX: transition on the edge that ends the space,
          if (counter3 >= 80000) begin               //      so DATA starts exactly at bit0's burst
            state    <= DATA;                         //      (no spurious first bit). ~4.5 ms (nominal 90000)
          end else begin
            state    <= IDLE;
          end
          counter3 <= 0;
          counter  <= 0;                             // FIX: reset bit counter / data each frame
          duration <= 0;
          data_reg <= 0;
        end
      end
      DATA: begin
        if (ir_signal == 1'b1) begin
          duration <= duration + 1;                  // measure the space (high time = the bit value)
        end
        if (falling_edge) begin
          if (counter < 32) begin
            counter <= counter + 1;
            state   <= BIT;
          end else begin
            state    <= IDLE;
            duration <= 0;
            counter  <= 0;                            // FIX: reset for next frame
          end
        end
      end
      BIT: begin
        if (duration >= 22500) begin                 // FIX: threshold = midpoint of 562.5us('0') and 1687.5us('1')
          data_reg <= data_reg << 1;
          data_reg[0] <= 1'b1;
        end else begin
          data_reg <= data_reg << 1;
          data_reg[0] <= 1'b0;
        end
        duration <= 0;
        state    <= DATA;
      end
    endcase
  end

  // FIX: full 32-bit register exposed (your old 1-bit port truncated it to bit 0).
  // Holds the last decoded frame until the next one starts shifting in.
  assign decoded_data = data_reg;

  Gowin_rPLL your_instance_name (
    .clkout (clkout_o),   //output clkout  -- configure this IP for 20 MHz
    .clkin  (clkin)       //input clkin
  );
endmodule
