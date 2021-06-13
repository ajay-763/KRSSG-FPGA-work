`timescale 1ns / 1ps

/*------------------------------------------------------------------------------------
* This is the implemetation of rotary encoder.
* This module takes input pulses from the motor and give a 7-bit output.
* The output is used to determine the speed of the motor.
* Implemented using FSM. 
* In state Increment_enc we detect whether there is a pulse or not and then 
    if there is a pulse then we increment the temp_enc register
* In latch state we send the data.
* The prescalar value is calculated such that that at max speed we will get 
   output as 127
--------------------------------------------------------------------------------------*/

module Rotary_encoder(clk, pulse, reset, enc, temp_pulse);
	//inputs 
	input clk;
	input pulse;
	input reset;
	
	// outputs
	output reg [6:0]enc = 7'd0;	// output encoder data
	output reg temp_pulse = 1'b0;	// output pulse indicating the state

	reg [1:0] state = 2'b0;			// variable to store present state
	reg [1:0] next_state = 2'b0;	// variable to store next state
	reg [1:0] data = 2'b0;			// to detect pulse data received from motor

	reg [32:0]count = 32'd0;		// counter used for determining the duration of any particular state
	
	reg [6:0]temp_enc = 7'd0; 		// temporary storage for data calculation

	parameter IDLE = 2'b00, Increment_enc = 2'b01, Latch = 2'b10;	// state parameters
	
	parameter prescaler = 60000;	// prescalar used for determining the duration of any particular state
//------------------------------------------------------------------------------------------------------------------------------
	// This always block generates temp_pulse 
	// temp_pulse is low for two clock cycle where we send data
	// temp_pulse is high for some clock cycles which is decided by prescalar for getting data for calculating speed
	always @(posedge clk)
	begin
		// low for two clock cycle
		if(count == (prescaler-1'b1)) 
		begin
			count <= count+1;
			temp_pulse <= 0;
		end
		
		else if(count == prescalar)
		begin
			count <=0;
			temp_pulse <= 0;
		end
		
		else
		begin
			count <= count+1;
			temp_pulse <= 1; 
		end
	end
//------------------------------------------------------------------------------------------------------------------------------

	// FSM implementation
	always @(posedge clk)
	 begin 
		 if (reset == 1'b1) state <=   IDLE;
		 else state <=  next_state;
	 end
//------------------------------------------------------------------------------------------------------------------------------

	// This module determines the next state of our FSM
	always @(temp_pulse)
	begin
		case(state)
		
			IDLE : if (temp_pulse == 1'b1) next_state = Increment_enc;
					  else next_state = IDLE;
			  
			Increment_enc : if (temp_pulse == 1'b1) next_state = Increment_enc;
									else next_state = Latch;
			  
			Latch : if(temp_pulse == 1) next_state = Increment_enc;
						else next_state = IDLE;
			  
			default : next_state = IDLE;
		  
		 endcase
	end
//------------------------------------------------------------------------------------------------------------------------------

	// This module detects if a pulse comes from motor and stores it
	always @(posedge clk)
	begin
	
		data[1] <= data[0]; // This is a shift register. We store previous pulse in data[1] and new pulse in data[0]
		data[0] <= pulse;
	
		case(state)
			IDLE : temp_enc <= 0;
			
			Increment_enc : temp_enc <= temp_enc + (data[0]^data[1]);	// Here increment if a pulse comes. Here temp_enc give [0,128]
			
			Latch : if(temp_enc == 0) enc <= 0; else enc <= temp_enc-1;		// Here we send data. We send data from [0,127]
			
			default : temp_enc <= 0;
		endcase
	end
	
endmodule
