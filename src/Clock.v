module Clock(clk_50mhz,wei,duan,reset,start,mode,state_led);
	input wire reset;		// 秒表:复位
	input wire start;		// 秒表:启动暂停 电子表:自加一
	input wire mode;		// 模式选择按键
	input wire clk_50mhz;		// 时钟信号
	output reg[7:0] wei;		// 位选输出
	output reg[7:0] duan;		// 段选输出
	output reg[7:0] state_led;	// 状态指示灯
	
	/*********************** 分频器模块 ***********************/
	/*********************************************************/
	
	// 分频器由50M分频到10k: 用于数码管动态显示的扫描频率
	reg[11:0] count_10khz;
	reg clk_10khz;
	
	always@(posedge clk_50mhz)
		begin
			if(count_10khz==12'd2499)
				begin
					clk_10khz<=~clk_10khz;
					count_10khz<=12'd0;
				end
			else
				begin
					count_10khz<=count_10khz+12'd1;
				end
		end
	
	// 分频器由10k分频到1khz: 
	reg[3:0] count_1khz;
	reg clk_1khz;
	
	always@(posedge clk_10khz)
		begin
			if(count_1khz==4'd4)
				begin
					clk_1khz<=~clk_1khz;
					count_1khz<=4'd0;
				end
			else
				begin
					count_1khz<=count_1khz+4'd1;
				end
		end
		
	// 分频器由1k分频到100hz: 用于秒表的基础时钟周期
	reg[3:0] count_100hz;
	reg clk_100hz;
	
	always@(posedge clk_1khz)
		begin
			if(count_100hz==4'd4)
				begin
					clk_100hz<=~clk_100hz;
					count_100hz<=4'd0;
				end
			else
				begin
					count_100hz<=count_100hz+4'd1;
				end
		end
		
	// 分频器由1k分频到4hz: 用于闪烁的切换
	reg[6:0] count_4hz;
	reg clk_4hz;
	
	always@(posedge clk_1khz)
		begin
			if(count_4hz==7'd124)
				begin
					clk_4hz<=~clk_4hz;
					count_4hz<=7'd0;
				end
			else
				begin
					count_4hz<=count_4hz+7'd1;
				end
		end
		
	// 分频器由100hz分频到1hz: 电子表的基础时钟
	reg[5:0] count_1hz;
	reg clk_1hz;
	
	always@(posedge clk_100hz)
		begin
			if(count_1hz==6'd49)
				begin
					clk_1hz<=~clk_1hz;
					count_1hz<=6'd0;
				end
			else
				begin
					count_1hz<=count_1hz+6'd1;
				end
		end
	
	/*********************** 计数模块 *************************/
	/*********************************************************/
	
	// 秒表计数模块
	reg[3:0] timer_miao_ge;
	reg[3:0]	timer_miao_shi;
	reg[3:0] timer_fen_ge;
	reg[3:0] timer_fen_shi;
	reg[3:0] timer_shi_ge;
	reg[3:0] timer_shi_shi;
	
	reg timer_enable;
	
	always @(negedge timer_start or negedge timer_reset)
		begin 
			if(~timer_start)
				begin
					timer_enable <= timer_enable + 1'b1;
				end 
			if(~timer_reset)
				begin
					timer_enable <= 1'b0;
				end 
		end 
	
	always @(posedge clk_100hz or negedge timer_reset)
	begin 
		if(~timer_reset)
			begin
				timer_miao_ge <= 4'b0;
				timer_miao_shi <= 4'b0;
				timer_fen_ge <= 4'b0;
				timer_fen_shi <= 4'b0;
				timer_shi_ge <= 4'b0;
				timer_shi_shi <= 2'b0;
			end 
		else if(timer_enable)
			begin
				if(timer_miao_ge==4'b1001)
					begin
						timer_miao_ge<=4'b0000;
						if(timer_miao_shi==4'b1001)
							begin
								timer_miao_shi<=4'b000;
								if(timer_fen_ge==4'b1001)
									begin
										timer_fen_ge<=4'b0000;
										if(timer_fen_shi==4'b101)
								 			begin
												timer_fen_shi<=4'b000;
												if(timer_shi_ge==4'b1001)
													begin
														timer_shi_ge<=4'b0000;
														if(timer_shi_shi==4'b101)
															timer_shi_shi<=4'b0000;
														else
															timer_shi_shi<=timer_shi_shi+4'b1;
													end
												else
													timer_shi_ge<=timer_shi_ge+4'b1;
											end
										else
											timer_fen_shi<=timer_fen_shi+4'b1;
									end
								else
									timer_fen_ge<=timer_fen_ge+4'b1;
							end
						else
							timer_miao_shi<=timer_miao_shi+4'b1;
					end
				else
					timer_miao_ge<=timer_miao_ge+4'b1;
			end
	end 
	
	// 时钟计数模块
	reg[3:0] clock_miao_ge;
	reg[3:0]	clock_miao_shi;
	reg[3:0] clock_fen_ge;
	reg[3:0] clock_fen_shi;
	reg[3:0] clock_shi_ge;
	reg[3:0] clock_shi_shi;

	reg clock_enable;
	reg clock_load;
	
	always @(posedge clk_1hz or negedge clock_load)
	begin
		if(~clock_load)
			begin 
				clock_miao_ge = set_miao_ge;
				clock_miao_shi = set_miao_shi;
				clock_fen_ge = set_fen_ge;
				clock_fen_shi = set_fen_shi;
				clock_shi_ge = set_shi_ge;
				clock_shi_shi = set_shi_shi;
			end 
		else if(clock_enable)
			begin 
				if(clock_miao_ge==4'b1001)
					begin
						clock_miao_ge<=4'b0000;
						if(clock_miao_shi==4'b101)
							begin
								clock_miao_shi<=4'b000;
								if(clock_fen_ge==4'b1001)
									begin
										clock_fen_ge<=4'b0000;
										if(clock_fen_shi==4'b101)
											begin
												clock_fen_shi<=4'b000;
												if(clock_shi_shi==4'b0010&&clock_shi_ge==4'b11)
													begin
														clock_shi_ge<=4'b00;
														clock_shi_shi<=4'b00;
													end
												else if(clock_shi_shi<4'b0010&&clock_shi_ge==4'b1001)
													begin 
														clock_shi_ge<=4'b00;
														clock_shi_shi<=clock_shi_shi+4'b1;
													end 
												else
													clock_shi_ge<=clock_shi_ge+4'b1;
											end
										else
											clock_fen_shi<=clock_fen_shi+4'b1;
									end
								else
									clock_fen_ge<=clock_fen_ge+4'b1;
							end
						else
							clock_miao_shi<=clock_miao_shi+4'b1;
					end
				else
					clock_miao_ge<=clock_miao_ge+4'b1;
			end 
	end 
	
	/*********************** 动态显示模块 *********************/
	/*********************************************************/
	
	// 译码函数
	function[7:0] code;							// 函数的作用: 将数值转化为对应的段选值
		input[3:0] n;
		case(n)
			4'h0: code = 8'hc0; 					// 显示"0" 1100 0000
			4'h1: code = 8'hf9; 					// 显示"1"
			4'h2: code = 8'ha4; 					// 显示"2" 1010 0100
			4'h3: code = 8'hb0; 					// 显示"3"
			4'h4: code = 8'h99; 					// 显示"4"
			4'h5: code = 8'h92; 					// 显示"5"
			4'h6: code = 8'h82; 					// 显示"6"
			4'h7: code = 8'hf8; 					// 显示"7"
			4'h8: code = 8'h80; 					// 显示"8"
			4'h9: code = 8'h90; 					// 显示"9"
			4'hf: code = 8'hff;					// 显示" "			
		endcase
	endfunction
	
	// 数码管动态显示模块
	reg[2:0] wei_count;
	
	reg[3:0] miao_ge;
	reg[3:0]	miao_shi;
	reg[3:0] fen_ge;
	reg[3:0] fen_shi;
	reg[3:0] shi_ge;
	reg[3:0] shi_shi;
	
	always @(posedge clk_10khz)
		begin 
			wei_count<=wei_count+3'd1;
			if(wei_count==3'd6)
				begin 
					wei_count<=3'd0;
				end 
			case(wei_count)
				3'd0: begin wei = 8'b11111110; duan <= code(miao_ge); end
				3'd1: begin wei = 8'b11111101; duan <= code(miao_shi); end
				3'd2: begin wei = 8'b11111011; duan <= code(fen_ge)&8'h7F; end
				3'd3: begin wei = 8'b11110111; duan <= code(fen_shi); end
				3'd4: begin wei = 8'b11101111; duan <= code(shi_ge)&8'h7F; end
				3'd5: begin wei = 8'b11011111; duan <= code(shi_shi); end
			endcase
		end
		
	/*********************** 按键消抖模块 *********************/
	/*********************************************************/
	
	wire reset_stabilize;
	wire start_stabilize;
	wire mode_stabilize;
	
//	Shake_Remove remove_reset(clk_10khz, reset, reset_stabilize);
//	Shake_Remove remove_start(clk_10khz, start, start_stabilize);
//	Shake_Remove remove_mode(clk_10khz, mode, mode_stabilize);
	
	assign reset_stabilize = reset;
	assign start_stabilize = start;
	assign mode_stabilize = mode;
	
	/*********************** 模式选择模块 *********************/
	/*********************************************************/
	
	parameter s0 = 3'd0,					// 模式0:开机等待状态 	除了模式切换键,其他按键失效
				 s1 = 3'd1,			// 模式1:秒表			
				 s2 = 3'd2,			// 模式2:时钟
				 s3 = 3'd3,			// 模式3:小时设置
				 s4 = 3'd4,			// 模式4:分钟设置
				 s5 = 3'd5;			// 模式5:秒钟设置
	
	// 模式切换模块
	reg[2:0] state;						// 当前模式
	
	always @(negedge mode_stabilize)
		begin 
			case(state)
				s0:begin
						key_select = welcome;						
						data_select = data_timer;
						state_led = 8'b11111110;
						state = s1;
					end 
				s1:begin
						key_select = timer_run;						
						data_select = data_timer;
						state_led = 8'b11111101;
						state = s2;
					end 
				s2:begin 
						clock_enable = 1'b1;
						key_select = clock_run;
						data_select = data_clock;
						state_led = 8'b11111011;
						state = s3;
					end 
				s3:begin	
						clock_enable = 1'b0;					
						key_select = clock_set;
						data_select = data_clock;
						state_led = 8'b11110111;
						state = s4;
					end 
				s4:begin
						key_select = clock_set;
						data_select = data_clock;
						state_led = 8'b11101111;
						state = s5;
					end 
				s5:begin
						key_select = clock_set;						
						data_select = data_clock;
						state_led = 8'b11011111;
						state = s0;
					end 
			endcase 
		end 
	
	/*********************** 闪烁显示模块 *********************/
	/*********************************************************/
		
	reg flicker_enable;
	
	always @(posedge clk_4hz)
		begin 
			case(state)
				s3:begin 
						control_miao_ge = 1'b1;
						control_miao_shi = 1'b1;
						control_fen_ge = 1'b1;
						control_fen_shi = 1'b1;
						control_shi_ge = 1'b1;
						control_shi_shi = 1'b1;
					end 
				s4:begin 
						control_miao_ge = 1'b1;
						control_miao_shi = 1'b1;
						control_fen_ge = 1'b1;
						control_fen_shi = 1'b1;
						control_shi_ge = ~control_shi_ge;
						control_shi_shi = ~control_shi_shi;
					end 
				s5:begin 
						control_miao_ge = 1'b1;
						control_miao_shi = 1'b1;
						control_fen_ge = ~control_fen_ge;
						control_fen_shi = ~control_fen_shi;
						control_shi_ge = 1'b1;
						control_shi_shi = 1'b1;
					end 
				s0:begin 
						control_miao_ge = ~control_miao_ge;
						control_miao_shi = ~control_miao_shi;
						control_fen_ge = 1'b1;
						control_fen_shi = 1'b1;
						control_shi_ge = 1'b1;
						control_shi_shi = 1'b1;
					end 
			endcase 
		end 
				
	wire[3:0] flicker_miao_ge;
	wire[3:0] flicker_miao_shi;
	wire[3:0] flicker_fen_ge;
	wire[3:0] flicker_fen_shi;
	wire[3:0] flicker_shi_ge;
	wire[3:0] flicker_shi_shi;
	
	assign flicker_miao_ge = control_miao_ge ? clock_miao_ge : 4'hf ;
	assign flicker_miao_shi = control_miao_shi ? clock_miao_shi : 4'hf;
	assign flicker_fen_ge = control_fen_ge ? clock_fen_ge : 4'hf;
	assign flicker_fen_shi = control_fen_shi ? clock_fen_shi : 4'hf;
	assign flicker_shi_ge = control_shi_ge ? clock_shi_ge : 4'hf;
	assign flicker_shi_shi = control_shi_shi ? clock_shi_shi : 4'hf;
	
	/*********************** 按键选择摸块 *********************/
	/*********************************************************/
	
	reg timer_reset;
	reg timer_start;
	reg clock_setting;
	reg clock_alarm;
	
	reg [1:0] key_select;
	
	parameter timer_run = 2'b00,
				 clock_run = 2'b01,
				 clock_set = 2'b10,
				 welcome = 2'b11;
	
	always @(key_select)
		begin 
			case(key_select)
				timer_run:
					begin 
						timer_reset = reset_stabilize;
						timer_start = start_stabilize;
						clock_setting = 1'b1;
						clock_alarm = 1'b1;
					end 
				clock_run:
					begin 
						timer_reset = 1'b0;
						timer_start = 1'b1;
						clock_setting = 1'b1;
						clock_alarm = reset_stabilize;
					end 
				clock_set:
					begin 
						timer_reset = 1'b1;
						timer_start = 1'b1;
						clock_setting = start_stabilize;
						clock_alarm = 1'b1;
					end 
				clock_alarm:
					begin 
						timer_reset = 1'b1;
						timer_start = 1'b1;
						clock_setting = 1'b1;
						clock_alarm = 1'b1;
					end 
			endcase 
		end 
		
	/********************** 显示数据选择摸块 *******************/
	/*********************************************************/
	
	// 数据选择器
	reg data_select;
	
	reg control_miao_ge;
	reg control_miao_shi;
	reg control_fen_ge;
	reg control_fen_shi;
	reg control_shi_ge;
	reg control_shi_shi;
	
	parameter data_timer = 2'b1,
				 data_clock = 2'b0;
	
	always @(data_select)
		begin
			if(data_select)
				begin 
					miao_ge = timer_miao_ge;
					miao_shi = timer_miao_shi;
					fen_ge = timer_fen_ge;
					fen_shi = timer_fen_shi;
					shi_ge = timer_shi_ge;
					shi_shi = timer_shi_shi;
				end 
			else 
				begin 
					miao_ge = flicker_miao_ge;
					miao_shi = flicker_miao_shi;
					fen_ge = flicker_fen_ge;
					fen_shi = flicker_fen_shi;
					shi_ge = flicker_shi_ge;
					shi_shi = flicker_shi_shi;
				end 
		end
		
	/*********************** 时间设置模块 *********************/
	/*********************************************************/
	
	reg[3:0] set_miao_ge;
	reg[3:0] set_miao_shi;
	reg[3:0] set_fen_ge;
	reg[3:0] set_fen_shi;
	reg[3:0] set_shi_ge;
	reg[3:0] set_shi_shi;
	
	reg count_load;
	
	always @(posedge clk_4hz)
		begin 
			count_load = ~count_load;
			if(count_load)
				begin
					if(~clock_setting)
						begin 
							case(state)
								s4:begin 
										set_miao_ge = clock_miao_ge;
										set_miao_shi = clock_miao_shi;
										set_fen_ge = clock_fen_ge;
										set_fen_shi = clock_fen_shi;
										set_shi_ge = clock_shi_ge + 4'b1;
										set_shi_shi = clock_shi_shi;
										if(set_shi_shi==4'b0010&&set_shi_ge==4'b0100)
											begin
												set_shi_ge = 4'b00;
												set_shi_shi = 4'b00;
											end
										else if(set_shi_shi<4'b0010&&set_shi_ge==4'b1010)
											begin 
												set_shi_ge<=4'b00;
												set_shi_shi = set_shi_shi+4'b1;
											end 
										clock_load = 1'b0;
									end
								s5:begin
										set_miao_ge = clock_miao_ge;
										set_miao_shi = clock_miao_shi;
										set_fen_ge = clock_fen_ge + 4'b1;
										set_fen_shi = clock_fen_shi;
										set_shi_ge = clock_shi_ge;
										set_shi_shi = clock_shi_shi;
										if(set_fen_ge==4'b1010)
											begin
												set_fen_ge = 4'b0;
												set_fen_shi = set_fen_shi + 4'b1;
												if(set_fen_shi==4'b0110)
													set_fen_shi = 4'b0;
											end 
										clock_load = 1'b0;
									end 
								s0:begin 
										set_miao_ge = clock_miao_ge + 4'b1;
										set_miao_shi = clock_miao_shi;
										set_fen_ge = clock_fen_ge;
										set_fen_shi = clock_fen_shi;
										set_shi_ge = clock_shi_ge;
										set_shi_shi = clock_shi_shi;
										if(set_miao_ge==4'b1010)
											begin
												set_miao_ge = 4'b0;
												set_miao_shi = set_miao_shi + 4'b1;
												if(set_miao_shi==4'b0110)
													set_miao_shi = 4'b0;
											end 
										clock_load = 1'b0;
									end 
							endcase 
						end 
				end 
			else 
				clock_load = 1'b1;
		end 
	
		
endmodule 