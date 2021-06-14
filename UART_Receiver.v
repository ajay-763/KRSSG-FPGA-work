	`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:58:00 05/04/2021 
// Design Name: 
// Module Name:    UART_Receiver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module UART_Receiver(clk, Rx, tick, reset, data_out, read_comp);

	input clk, Rx, tick, reset;
	output reg read_comp = 0;
	output [7:0]data_out;
	
	reg [7:0]temp_data = 8'd0;
	reg [3:0]count = 4'd0;
	reg start_bit = 1;
	reg read_enable = 0;
	
	parameter idle = 1'b0, read = 1'b1;
	parameter number_of_bits = 8;
	reg [3:0]bits = 4'd0;
	reg state, next_state;

	always @(posedge clk or posedge reset)
	begin
		if(reset) state <= idle;
		else state <= next_state;
	end
	
	always @(state or Rx or read_comp)
	begin
		case(state)
			idle : if(!Rx) next_state = read; else next_state = idle;
			read : if(read_comp) next_state = idle; else next_state = read;
			default : next_state = idle;
		endcase
	end
	
	always @(state)
	begin
		case(state)
			idle : read_enable = 0;
			read : read_enable = 1;
		endcase
	end
	
	always @(posedge tick)
	begin
		if(read_enable)
		begin
			count <= count + 1'b1;
			read_comp <= 0;
			if((count == 4'b1000) && start_bit)
			begin
				start_bit <= 0;
				count <= 4'b0000;
			end
			else if((count == 4'b1111) && (bits < number_of_bits) && (!start_bit))
			begin
				temp_data <= {Rx,temp_data[7:1]};
				count <= 4'b0000;
				bits <= bits + 1'b1;
			end
			else if((count == 4'b1111) && (bits == number_of_bits) && (Rx)) 
			begin
				start_bit <= 1;
				read_comp <= 1;
				count <= 4'b0000;
				bits <= 4'b0000;
			end
		end
	end
		
		assign data_out = temp_data;
	
endmodule
