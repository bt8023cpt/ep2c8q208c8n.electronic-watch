module Shake_Remove(shake_clk, shake_in, shake_out);	
	input wire shake_clk;
	input wire shake_in;
	output reg shake_out;
	
	reg[7:0] counter;
	reg state;
	
	always@(posedge shake_clk)
		begin
			case(state)
				/*状态0：按键消抖。连续检测到10次低电平，才会进入下一个状态，并将标志位置1*/
				0:	if(counter < 4'd15)
						begin
							if(!shake_in)
								counter <= counter + 1'b1;
							else 
								counter <= 1'b0;
						end
					else
						begin
							shake_out <= 1'b1;
							state <= 1'b1;
						end
				/*状态1：松手检测。先清除标志位，然后检测有没有松手，松手后进入状态0*/
				1:	begin
						shake_out <= 1'b0;
						if(!shake_in)
							counter <= counter;
						else
							begin 
								counter <= 1'b0;
								state <= 1'b0;
							end
					end
				default:	state <= 1'b0;
			endcase
		end
		
endmodule 