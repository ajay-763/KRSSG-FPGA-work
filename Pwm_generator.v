`timescale 1ns / 1ps

/*---------------------------------------------------------------------------------------
* This is the implementation of PWM generator module
* We get 8-bit input from PID module named as pwm_val
* The most significant bit pwm_val[7] gives the direction of the motor and rest gives
    the data for duty cycle.
* We decreased the frequency for PWM by prescaling the clock.
* Finally we generate the PWM output.
---------------------------------------------------------------------------------------*/

module Pwm_generator(reset, pwm_val, clk, pwm, dir);
	
	// inputs 
	input reset;
	input [7:0]pwm_val;		// input data from PID module
	input clk;
		
	// outputs
	output reg pwm = 0;		// output pwm signal
	output dir;					// output for direction

   reg [6:0]count = 0;		// this counter is used for pwm generation purpose
	reg [5:0]prescaler = 0;	// this is a counter which is used for prescalar
	reg new_clk = 0;			// prescaled clock
//------------------------------------------------------------------------------------------------------------------------------

	// This always block does prescaling of clock.
	// Whenever the prescalar becomes zero we toggle the new clock else we increment the counter
	always @(posedge clk)
	begin
		if(prescaler == 0)
			new_clk <= ~new_clk;
		prescaler <= prescaler +1;
	end
//------------------------------------------------------------------------------------------------------------------------------

	// This always block generated pwm signal
	always @(posedge new_clk)
	begin
		// reset is high -> pwm is set to 0
		if (reset == 1)
			pwm <= 0;
			
		// if the counter value is less than duty cycle data then pwm output is 1 else 0.
		// this is non-inverted mode of pwm
		else
			begin
				if(count < pwm_val[6:0])
					pwm <= 1;
				else
					pwm <= 0;
				count <= count + 1;
			end
	end
//------------------------------------------------------------------------------------------------------------------------------

	// assigning the direction of the motor rotation
	assign dir = pwm_val[7];

endmodule
