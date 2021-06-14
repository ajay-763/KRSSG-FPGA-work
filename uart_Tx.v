`timescale 1ns / 1ps

/*------------This module is for data transmitting-------------------------
* Tick is a pulse whose frequency is 16 times the baudrate.
* Start bit is sent, 8 tick cycles later than the TxEn bit is set.
* After that the data bits are sent 16-bits later to maintain the baudrate.
*/

module uart_Tx(tick,clk,reset,TxEn,data,Tx);

	// inputs
	input tick,clk,reset,TxEn;
	input [7:0]data;
	
	// outputs
	output reg Tx = 1'b1;

	// local variables 
	reg [7:0]data_in = 8'd0;		// temporary storage for input data so that assignment can be done inside procedural blocks
	reg [3:0]count = 4'd0;			// counter that counts for 16 ticks and then the data is written
	reg [3:0]bit_count = 4'd0;		// for keeping track of number of bits sent
	reg start_bit = 1'b1;			
	reg write_En = 1'b0;				// when high then the data is written 
	reg write_comp = 1'b0;			// indicate that the write operation is finished
	
	reg state = 1'b0, next_state = 1'b0;	// for keeping track of different states

	parameter IDLE = 1'b0, WRITE = 1'b1;	// declaring states
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
	// If state is IDLE and TxEn is high then the state will change to WRITE
	// If the write function is complete then the state will change to IDLE
	// default state is set to IDLE for avoiding unnecessary errors
	
	always @(state or write_comp or TxEn)
	begin
		case(state)
			IDLE : if(TxEn) next_state = WRITE; else next_state = IDLE;
			WRITE : if(!write_comp) next_state = WRITE; else next_state = IDLE;
			default : next_state = IDLE;
		endcase
	end
	
	// This always block is for enabling the write function.
	// If the state is WRITE then the write_En control signal will be set else it will be low
	
	always @(state)
	begin
		case(state)
			IDLE : write_En = 1'b0;
			WRITE : write_En = 1'b1;
		endcase
	end
	
	//-------------------------------------------------------------------------------------------
	// This always block will describe the functions when the write_En bit is set for transmission
	
	always @(posedge tick)
	begin
		if(write_En)
		begin
			count <= count + 1;						// counter start counting
			
			// If 8 tick cycles passes then counter will be 8, so we will write the start bit
			if(count == 4'b1000 && start_bit)	
			begin
				start_bit <= 1'b0;
				Tx <= 1'b0;				// Start bit is written ( start bit --> 0 )
				count <= 4'b0000;		// Counter is reset
				data_in <= data;		// assigned the data to temporary reg data_in for processing
				write_comp <= 1'b0;	// write_comp is set to 0 as the write function is in process
			end
			
			// Now after every 16 tick cycles we will write the next data bit
			// Here conditioned is checked for counter = 15 and also the start bit is low or not to ensure that start bit is sent
			// bit_count keeps track of how many bits are sent
			if((count == 4'b1111) && (!start_bit) && (bit_count < Nbits))
			begin
				Tx <= data_in[0];								// sending the LSB first
				data_in <= {data_in[0],data_in[7:1]}; 	// Making the 2nd bit as LSB 
				bit_count <= bit_count + 1;				// increment bit count
				count <= 4'b0000;								// reset count
			end
			
			// After all the bits are sent then this condition is satisfied and write_comp is set to 1
			if((count == 4'b1111) && (bit_count == Nbits))
			begin
				write_comp <= 1'b1;		// write_comp is set to indicate that all bit of data are sent
				Tx <= 1'b1;					// We write the stop bit
				start_bit <= 1'b1;		// again start bit is set to 1
				bit_count <= 4'b0000;	// bit_count is reset to 0
				count <= 4'b0000;			// reset count
			end
		end					
	end

endmodule
