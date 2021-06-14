`timescale 1ns / 1ps

/*------------This module is for data receiving-------------------------
* Tick is a pulse whose frequency is 16 times the baudrate.
* Start bit is received, we count till 8 tick pulse and then read it to make sure that 
	data is read in middle to avoid any error
* After that the data bits are read 16-bits later to maintain the baudrate.
*/


module UART_RX(clk, Rx, tick, reset, data_out);

	// inputs 
	input clk, Rx, tick, reset;
	
	// outputs
	output reg [7:0]data_out = 8'd0;
	
	// local variables
	reg read_comp = 0;				// indicate that the read function is complete or not
	reg [7:0]temp_data = 8'd0;		// Received data is temporarily stored in this register
	reg [3:0]count = 4'd0;			// counter to count 16 tick pulses
	reg start_bit = 1;				// This is for detecting start bit, default is set to 1
	reg read_En = 0;				// enables the read function
	reg [3:0]bit_count = 4'd0;						// counter to keep track of number of bits that are read
	
	reg state, next_state;						// variable that stores the state

	parameter IDLE = 1'b0, READ = 1'b1;		// declaring states
	parameter Nbits = 4'b1000;					// data length
	
	//---------------------------------------------------------------------------------------
	//				Finite State Machine implementation
	
	// This always block describes the change of state 
	// Asynchronous high level triggered reset changes the state to IDLE else the state is next state
	
	always @(posedge clk or posedge reset)
	begin
		if(reset) state <= IDLE;
		else state <= next_state;
	end
	
	// This always block is for defining the next state on the basis of some control signals
	// If state is IDLE and Rx becomes low then the state will change to READ
	// If the read function is complete then the state will change to IDLE
	// default state is set to IDLE for avoiding unnecessary errors
	
	always @(state or Rx or read_comp)
	begin
		case(state)
			IDLE : if(!Rx) next_state = READ; else next_state = IDLE;
			READ : if(read_comp) next_state = IDLE; else next_state = READ;
			default : next_state = IDLE;
		endcase
	end
	
	// This always block is for enabling the write function.
	// If the state is WRITE then the write_En control signal will be set else it will be low
		
	always @(state)
	begin
		case(state)
			IDLE : read_En = 0;
			READ : read_En = 1;
		endcase
	end
	
	//-------------------------------------------------------------------------------------------
	// This always block will describe the functions when the read_En bit is set for transmission
	
	always @(posedge tick)
	begin
		if(read_En)
		begin
			count <= count + 1'b1;  		// counter starts counting
			
			// If the read enable is set then we need to detect start bit.
			// We count till 8 and at the middle we read the data 
			if((count == 4'b1000) && start_bit)
			begin
				start_bit <= 0;		// start bit detected
				read_comp <= 0;		// read in process so set to 
				count <= 4'b0000;		// counter reset
			end
			
			// Now after every 16 tick cycles we will read the next data bit
			// Here conditioned is checked for counter = 15 and also the start bit is low or not to ensure that start bit is read
			// bit_count keeps track of how many bits are sent
			else if((count == 4'b1111) && (bit_count < Nbits) && (!start_bit))
			begin
				temp_data <= {Rx,temp_data[7:1]};		// read the bit to MSB and then shift to right to keep it in LSB after all bits are read
				count <= 4'b0000;								// reset counter
				bit_count <= bit_count + 1'b1;			// increment bit count
			end
			
			// After all the bits are read then this condition is satisfied and read_comp is set to 1
			else if((count == 4'b1111) && (bit_count == Nbits) && (Rx)) 
			begin
				data_out <= temp_data;		// temp_data is finally written to data_out to get output
				start_bit <= 1;				// start bit set to default value i.e. : 1
				read_comp <= 1;				// read_comp is set to indicate that the read function is complete
				count <= 4'b0000;				// reset counter
				bit_count <= 4'b0000;		// reset bit counter
			end
		end
	end
	
endmodule
