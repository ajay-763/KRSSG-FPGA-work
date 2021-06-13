`timescale 1ns / 1ps

/*---------------------------------------------------------------------------------------
* This is the implementation of Motor controller module
* We take data from HALL sensors and based on the commutation table generate the output 
   mosfets of different phases of motor
* pwm, dir inputs are obtained from PWM generator module
* brake input is obtained from PID module.
---------------------------------------------------------------------------------------*/

module Motor_control(brake ,Hall, pwm ,dir , a ,b ,c);

	input brake;		
	input [2:0]Hall;	// hall sensors data
	input pwm;
	input dir;
	
	output [1:0]a;		// output for inputs of the mosfets of phase A
	output [1:0]b;		// output for inputs of the mosfets of phase B
	output [1:0]c;		// output for inputs of the mosfets of phase C

	reg [1:0]x;			// temporary register for calculation of the output for phase A
	reg [1:0]y;			// temporary register for calculation of the output for phase B
	reg [1:0]z;			// temporary register for calculation of the output for phase C

	// wires for hall sensors. Not necessarily needed but used so that code looks simple
	wire H1 = Hall[0];	
	wire H2 = Hall[1];
	wire H3 = Hall[2];
//------------------------------------------------------------------------------------------------------------------------------

	// whenever hall sensors value is changed or pwm is changed, this always block gets activated
	always@(Hall or pwm) 
	begin
	
		// if pwm is high then we run the motor
		if(pwm) 
			begin
				// this condition can't be achieved in normal running.
				// in case it occurs then we set motor to float condition.
				if(Hall == 7 || Hall == 0)
				begin
					x = 2'b01;	 // float condition
					y = 2'b01;
					z = 2'b01;
				end
				// here we calculate how to switch phases depending on the inputs of hall sensor.
				// if brake is 1 then overrides the commutation calculation and gives a stall condition.
				else 
					begin
					x[0] = (((~dir&~H2)|(H1&H2)|(dir&~H1))|brake);
					x[1] = (((~dir&H1&~H2)|(dir&~H1&H2))|brake);
					y[0] = (((~dir&~H3)|(H2&H3)|(dir&~H2))|brake);
					y[1] = (((~dir&H2&~H3)|(dir&~H2&H3))|brake);
					z[0] = (((~dir&~H1)|(H1&H3)|(dir&~H3))|brake);
					z[1] = (((~dir&~H1&H3)|(dir&H1&~H3))|brake);
					end
			end
		
		// if pwm is not high and if brake is high then we set motor to stall condition else float
		else 
			begin
				if(brake == 1) 
					begin
					x = 2'b11; 	// stall condition
					y = 2'b11;
					z = 2'b11;
					end
				else
					begin
					x = 2'b01;	// float condition
					y = 2'b01;
					z = 2'b01;
					end
			end
	end
//------------------------------------------------------------------------------------------------------------------------------
	
	// assignment of temporary variables to output
	assign a = x;
	assign b = y;
	assign c = z;

endmodule
