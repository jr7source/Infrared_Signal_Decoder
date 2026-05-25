/*
Author  -->  Jatin Ramchandani
Brief   -->  NEC Infrared Decoder for GOW1NR-LV9QN88P C6/I5
Company -->  DSA GmbH, Aachen
Version -->  1.0
Date    -->  26/09/2023
*/


module ir_decoder (
  input clkin,                                                                                                      //Input clock: 20MHz
  input wire ir_signal,                                                                                             // Incoming IR signal
  output wire decoded_data                                                                                          // Decoded data output
);

  // Defined states for Finite State Machine
  parameter IDLE = 2'b00;
  parameter START = 2'b01;
  parameter DATA = 2'b10;
  parameter BIT = 2'b11;

  integer i;

  reg [31:0]counter;
  reg [31:0]counter2;
  reg [31:0]counter3;
  reg [31:0]counter4;
  reg [31:0]duration;
  
  // Define other parameters
  parameter DATA_WIDTH = 32; // Width of the decoded data

  // Internal registers
  reg [DATA_WIDTH-1:0] data_reg;
  reg [1:0] state = 2'b00;
  wire inv_IR;
  assign inv_IR = ~ir_signal;
  wire clkout_o;
  wire pe;
  
  reg prev_signal;
  assign falling_edge = prev_signal && ~ir_signal;

  // Always block to implement the state machine
  always @(posedge clkout_o) begin

    prev_signal <= ir_signal;

    case (state)
      IDLE: begin
        if (!ir_signal) begin
          counter2 <= counter2 + 1;
            if (counter2 == 180000) begin
                state <= START; end
          //data_reg <= 0; // Reset data register
        end
      end

      START: begin
        
        counter2 <= counter2;
        if (ir_signal) begin
          counter3 <= counter3 + 1;
            if (counter3 == 90000) begin
                state <= DATA; 
            end
        end
      end

      DATA: begin
//            counter4 <= counter4 + 1;
//            if (counter4 > 0 && counter4 <= 46000) begin
                if (ir_signal == 1'b1) begin
                    duration <= duration + 1;  end
                if (falling_edge) begin
                    if (counter < 32) begin
                        counter <= counter + 1;
                        state <= BIT; 
                    end else begin 
                        state <= IDLE; duration <= 0;
                    end    
                end  end 

      BIT:  begin 
//            state <= BIT; 
            
                if (duration >= 11500) begin 
                    data_reg <= data_reg << 1; 
                    data_reg[0] <= 1'b1;
                    duration <= 0;
                end else begin 
                    data_reg <= data_reg << 1; 
                    data_reg[0] <= 1'b0; 
                    duration <= 0; 
                end      state <= DATA;                
                end
    endcase  
  end

  assign decoded_data = (state == DATA) ? data_reg : 32'b0;

Gowin_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout
        .clkin(clkin) //input clkin
    );

endmodule
