`timescale 1ns / 1ps

/*---------------------------------------------------------------------------------------
* This is the implementation of Control unit module
* Control unit gets data and a receive flag from UART receiver module and outputs data
   for motors kicker and dribbler.
---------------------------------------------------------------------------------------*/

module Control_unit(clk, reset, data, receive_flag, Motor1, Motor2, Motor3, Motor4, charge_flag, kick, dribller);

	// inputs 
	input clk;
	input reset;
	input [7:0]data;			// data received from UART receiver
	input receive_flag;		// flag received from UART receiver
	
	// outputs
	output reg [7:0]Motor1 = 8'd0;	// output for motor modules
	output reg [7:0]Motor2 = 8'd0;	
	output reg [7:0]Motor3 = 8'd0;
	output reg [7:0]Motor4 = 8'd0;
	output reg charge_flag = 1'b0;	// flag to indicate when to charge and when not to charge
	output [6:0]kick;						// output to kicker, data for kicking
	output dribbler;						// output to dribbler, it decides when to enable dribbler

	// temporary variables
	reg [2:0]count = 0;			// for keeping track of all functions
	reg [7:0]Kicker = 0;			// temporary register for storing data for kicker and dribbler enable			
	reg [7:0]key = 0 ;			// stores key received from UART receiver
	
//--------------------------------------------------------------------------------------------------------------------
// this always block 
	always @ (posedge clk)
	begin
		// if reset is true then we set all the outputs to 0.
		if (reset)
		begin
			Motor1 <= 0;
			Motor2 <= 0;
			Motor3 <= 0;
			Motor4 <= 0;
			Kicker <=0;
			count <=0;
			key<=0;
			charge_flag <=0;
		end
		
		// receive flag is true when the data is received
		// we load the data into key, key here acts as a flag for changing data of motors and kicker
		// it is 8-bit as we have set the uart data length to 8-bit
		// if the key = 255 then we start counter and then load the received data into motor1 to 4 and the kicker
		// data is received in a fixed order, hence a counter is used to keep track of states
		else	if(receive_flag)	
		begin
				case (count)
					// set key and begin counter
					3'b000 : begin 
									key <= data;	
									count <= count + 1;	
								end		
					// for motor 1
					3'b001 : if(key == 255) 
								begin 
									Motor1 <= data;
									count <= count + 1;
								end 
								else count <=0;
					// for motor 2
					3'b010 : if(key == 255) 
								begin 
									Motor2 <= data;
									count <= count + 1;
								end 
								else count <=0;
					// for motor 3
					3'b011 : if(key == 255) 
								begin 
									Motor3 <= data;
									count <= count + 1;
								end
								else count <=0;
					// for motor 4
					3'b100 : if(key == 255) 
								begin 
									Motor4 <= data;
									count <= count + 1; 
								end 
								else count <=0;
					// for kicker, also here we reset key and count
					3'b101 : if(key == 255) 
								begin 
									Kicker <=data; 
									key <= 0; 
									count <= 0;
								end
				endcase
		end
		
		// for charging the capacitor control signal (charge flag) is active low.
		// if kicker[6:0] != 0 then charge flag is set to 1 (i.e. : don't charge), if set to 0 then charge
		if (Kicker[6:0] != 0) charge_flag <= 1;
		else charge_flag <= 0; 
		
	end
//--------------------------------------------------------------------------------------------------------------------

	assign kick = Kicker[6:0];				// output to kicker for kicking 
	assign dribller = Kicker[7];			// for enabling dribbler
	
endmodule
