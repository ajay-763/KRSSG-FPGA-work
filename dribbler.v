`timescale 1ns / 1ps

/*---------------------------------------------------------------------------------------
* This is the implementation of dribbler module
* Dribbler is controlled by a BLDC motor so it will be same as the motorcontrol module
* The difference between this and motormodule is that duty cycle for PWM is 100 %
* We take data from HALL sensors and based on the commutation table generate the output 
   mosfets of different phases of motor
---------------------------------------------------------------------------------------*/

module dribbler(enable ,Hall, a ,b ,c);

	input [2:0]Hall;	// inputs from hall sensors
	input enable;		// for enabling the dribbler

	output [1:0]a;		// output for inputs of the mosfets of phase A
	output [1:0]b;		// output for inputs of the mosfets of phase B
	output [1:0]c;		// output for inputs of the mosfets of phase C

	reg dir = 1;		// dribbler direction of rotation is constant.
	
	reg [1:0]x;			// temporary register for calculation of the output for phase A
	reg [1:0]y;			// temporary register for calculation of the output for phase B
	reg [1:0]z;			// temporary register for calculation of the output for phase C

	// wires for hall sensors. Not necessarily needed but used so that code looks simple
	wire H1 = Hall[0];	
	wire H2 = Hall[1];
	wire H3 = Hall[2];
//------------------------------------------------------------------------------------------------------------------------------

	// whenever hall sensors value is changed or enable is changed, this always block gets activated
	always@(Hall or enable) 
	begin
	
		// if enable is high then we run the dribbler
		if(enable) 
			begin
				// this condition can't be achieved in normal running.
				// in case it occurs then motor is at float condition.
				if(Hall == 7 || Hall == 0)
				begin
					x = 2'b01;
					y = 2'b01;
					z = 2'b01;
				end
				// here we calculate how to switch phases depending on the inputs of hall sensor.
				// direction is fixed to 1
				else 
					begin
					x[0] = ((~dir&~H2)|(H1&H2)|(dir&~H1));
					x[1] = ((~dir&H1&~H2)|(dir&~H1&H2));
					y[0] = ((~dir&~H3)|(H2&H3)|(dir&~H2));
					y[1] = ((~dir&H2&~H3)|(dir&~H2&H3));
					z[0] = ((~dir&~H1)|(H1&H3)|(dir&~H3));
					z[1] = ((~dir&~H1&H3)|(dir&H1&~H3));
				end
			end
			
		// if enable is not high then we set the motor to float condition
		else 
			begin
				x = 2'b01;
				y = 2'b01;
				z = 2'b01;
			end
	end
//------------------------------------------------------------------------------------------------------------------------------

	// assignment of temporary variables to output
	assign a = x;
	assign b = y;
	assign c = z;

endmodule
