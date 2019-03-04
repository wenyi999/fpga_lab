module calculator(clk,key_add,key_multi,key_display,key_reset, hex0,hex1,hex2,hex3,hex4,hex5,led0,led1,led2,led3,sw );
 input clk,key_add,key_multi,key_display,key_reset;
 input [9:0] sw;
 output [6:0] hex0,hex1,hex2,hex3,hex4,hex5;
 output led0,led1,led2,led3;
 reg led0,led1,led2,led3;
 reg display_work;
 // 显示刷新，即显示寄存器的值 实时 更新为 计数寄存器 的值。
 reg [19:0] number1;
 reg [19:0] number2;
 reg [15:0] opr;
 
 reg [9:0] answer;
 reg counter_work;
 // 计数（计时）工作 状态，由按键 “计时/暂停” 控制。
 parameter DELAY_TIME = 10000000;
 // 定义一个常量参数。 10000000 ->200ms；
 // 定义 6 个显示数据（变量）寄存器：
 reg [3:0] minute_display_high;
 reg [3:0] minute_display_low;
 reg [3:0] second_display_high;
 reg [3:0] second_display_low;
 reg [3:0] msecond_display_high;
 reg [3:0] msecond_display_low;
 // 定义 6 个计时数据（变量）寄存器：

 reg [9:0] minute_counter_high;
 reg [9:0] minute_counter_low;
 reg [9:0] second_counter_high;
 reg [9:0] second_counter_low;
 reg [9:0] msecond_counter_high;
 reg [9:0] msecond_counter_low;

 reg [31:0] counter_50M; // 计时用计数器， 每个 50MHz 的 clock 为 20ns。
// DE1-SOC 板上有 4 个时钟， 都为 50MHz，所以需要 500000 次 20ns 之后，才是 10ms。
 reg reset_1_time; // 消抖动用状态寄存器 -- for reset KEY
 reg [31:0] counter_reset; // 按键状态时间计数器
 reg start_1_time; //消抖动用状态寄存器 -- for counter/pause KEY
 reg [31:0] counter_start; //按键状态时间计数器
 reg display_1_time; //消抖动用状态寄存器 -- for KEY_display_refresh/pause
 reg multi_1_time;
 reg [31:0] counter_display; //按键状态时间计数器
 reg [31:0] counter_multi;
 reg start; // 工作状态寄存器
 reg display; // 工作状态寄存器
 reg multi;
 reg swdisplay;
 reg clk_counter;
 reg [9:0] last_sw;
 reg [31:0] i;
 reg [31:0] length;
 
// sevenseg 模块为 4 位的 BCD 码至 7 段 LED 的译码器，
//下面实例化 6 个 LED 数码管的各自译码器。
sevenseg LED8_minute_display_high ( minute_display_high, hex5 );
sevenseg LED8_minute_display_low ( minute_display_low, hex4 );
sevenseg LED8_second_display_high ( second_display_high, hex3 );
sevenseg LED8_second_display_low ( second_display_low, hex2 );
sevenseg LED8_msecond_display_high ( msecond_display_high, hex1 );
sevenseg LED8_msecond_display_low ( msecond_display_low, hex0 );

always @ (key_reset) begin
    led0 = key_reset;
end

always @ (key_add) begin
    led3 = key_add;
end
always @ (key_multi) begin
    led2 = key_multi;
end
always @ (key_display) begin
    led1 = key_display;
end
 always @ (posedge clk) // 每一个时钟上升沿开始触发下面的逻辑，
// 进行计时后各部分的刷新工作
 begin
//此处功能代码省略，由同学自行设计。

    if (clk) begin
		if(sw!=last_sw)begin
				number2[9:0]=sw[9:0];
				msecond_counter_low=(number2[9:0]%10);
				msecond_display_low=msecond_counter_low[3:0];
				number2[9:0]=number2[9:0]/10;
				msecond_counter_high=(number2[9:0]%10);
				msecond_display_high=msecond_counter_high[3:0];
				number2[9:0]=number2[9:0]/10;
				second_counter_low=(number2[9:0]%10);
				second_display_low=second_counter_low[3:0];
				number2[9:0]=number2[9:0]/10;
				second_counter_high=(number2[9:0]%10);
				second_display_high=second_counter_high[3:0];
				last_sw=sw;
				//swdisplay=0;
				//number1[9:0]=number2[9:0];
		end
        // eliminate vibration of key
        if (reset_1_time && !key_reset) begin  // state is about to change
            counter_reset = counter_reset + 1;
            if (counter_reset == DELAY_TIME) begin  // signal has been in new state for long enough time
                counter_reset = 0;  // clear counter
                reset_1_time = ~reset_1_time;  // flip the state

                // reset stopwatch by setting all counters to 0
                minute_counter_high = 0;
                minute_counter_low = 0;
                second_counter_high = 0;
                second_counter_low = 0;
                msecond_counter_high = 0;
                msecond_counter_low = 0;
					 number1=20'b0;
					 opr=16'b0;
					 msecond_display_low=0;
					 msecond_display_high=0;
					 second_display_low=0;
					 second_display_high=0;
            end
        end else if (!reset_1_time && key_reset) begin
            counter_reset = counter_reset + 1;
            if (counter_reset == DELAY_TIME) begin
                counter_reset = 0;
                reset_1_time = ~reset_1_time;
            end
        end else begin
            counter_reset = 0;  // in case of noise
        end

        if (start_1_time && !key_add) begin
            counter_start = counter_start + 1;
            if (counter_start == DELAY_TIME) begin
                counter_start = 0;
                start_1_time = ~start_1_time;
            end
        end else if (!start_1_time && key_add) begin
            counter_start = counter_start + 1;
            if (counter_start == DELAY_TIME) begin
                counter_start = 0;
                start_1_time = ~start_1_time;

                start = !start;
            end
        end else begin
            counter_start = 0;
        end

        if (display_1_time && !key_display) begin
            counter_display = counter_display + 1;
            if (counter_display == DELAY_TIME) begin
                counter_display = 0;
                display_1_time = ~display_1_time;
            end
        end else if (!display_1_time && key_display) begin
            counter_display = counter_display + 1;
            if (counter_display == DELAY_TIME) begin
                counter_display = 0;
                display_1_time = ~display_1_time;

                display = !display;
            end
        end else begin
            counter_display = 0;
        end
		  
        if (multi_1_time && !key_multi) begin
            counter_multi = counter_multi + 1;
            if (counter_multi == DELAY_TIME) begin
                counter_multi = 0;
                multi_1_time = ~multi_1_time;
            end
        end else if (!multi_1_time && key_multi) begin
            counter_multi = counter_multi + 1;
            if (counter_multi == DELAY_TIME) begin
                counter_multi = 0;
                multi_1_time = ~multi_1_time;

                multi = !multi;
            end
        end else begin
            counter_multi = 0;
        end

        // update display, if needed
        if (display) begin
				if(opr[7:0]=="*")
				begin
					number1[9:0] = sw*number1[9:0];
					opr[7:0]="_";
					if(opr[15:8]=="+")
					begin
						number1[9:0]=number1[9:0]+number1[19:10];
						number1[19:10]=10'b0;
						opr={"_","_"};
					end
				end
				if(opr[7:0]=="+")
					number1[9:0]=number1[9:0]+sw;
					
				number2[9:0]=number1[9:0];
				msecond_counter_low=(number1[9:0]%10);
				msecond_display_low=msecond_counter_low[3:0];
				number1[9:0]=number1[9:0]/10;
				msecond_counter_high=(number1[9:0]%10);
				msecond_display_high=msecond_counter_high[3:0];
				number1[9:0]=number1[9:0]/10;
				second_counter_low=(number1[9:0]%10);
				second_display_low=second_counter_low[3:0];
				number1[9:0]=number1[9:0]/10;
				second_counter_high=(number1[9:0]%10);
				second_display_high=second_counter_high[3:0];
				number1[9:0]=number2[9:0];
				display=0;
				swdisplay=0;
/*            minute_display_high = minute_counter_high;
            minute_display_low = minute_counter_low;
            second_display_high = second_counter_high;
            second_display_low = second_counter_low;
            msecond_display_high = msecond_counter_high;
            msecond_display_low = msecond_counter_low;*/
        end

        // update clock counter, if needed
        if (start) begin
		  
            //counter_50M = counter_50M + 1;
				if(opr[7:0]=="*")
				begin
					number1[9:0] = sw*number1[9:0];
					opr[7:0]="+";
					if(opr[15:8]=="+")
					begin
						number1[9:0]=number1[9:0]+number1[19:10];
						number1[19:10]=10'b0;
						opr={"_","+"};
					end
				end
				else if(opr[7:0]=="+")
				begin
					number1[9:0]=number1[9:0]+sw;
					//opr[7:0]="+";
				end
				else 
				begin
					number1[9:0]=sw;
					opr[7:0]="+";
				end
				start=0;
            // when 10 ms has passed, cascade update the counters
            /*if (counter_50M == 500000) begin
                counter_50M = 0;
                msecond_counter_low = msecond_counter_low + 1;

                if (msecond_counter_low == 10) begin
                    msecond_counter_low = 0;
                    msecond_counter_high = msecond_counter_high + 1;

                    if (msecond_counter_high == 10) begin
                        msecond_counter_high = 0;
                        second_counter_low = second_counter_low + 1;

                        if (second_counter_low == 10) begin
                            second_counter_low = 0;
                            second_counter_high = second_counter_high + 1;

                            if (second_counter_high == 6) begin
                                second_counter_high = 0;
                                minute_counter_low = minute_counter_low + 1;

                                if (minute_counter_low == 10) begin
                                    minute_counter_low = 0;
                                    minute_counter_high = minute_counter_high + 1;

                                    if (minute_counter_high == 10) begin
                                        minute_counter_high = 0;
                                    end
                                end
                            end
                        end
                    end
                end
            end*/
        end
	     if(multi)begin
				if(opr[7:0]=="*")
					number1[9:0] = sw*number1[9:0];
				else if(opr[7:0]=="+")
				begin
					number1={number1[9:0],sw};
					opr="+*";
				end
				else 
				begin
					number1[9:0]=sw;
					opr[7:0]="*";
				end
				multi=0;
		  end
     end
 end
 /*
always @ (!key_add||!key_multi||!key_display||!key_reset) begin
	if(!key_add)
	begin
		led3 = key_add;
		if(opr[7:0]=="*")
		begin
			number1[9:0] = sw*number1[9:0];
			opr[7:0]="+";
			if(opr[15:8]=="+")
			begin
				number1[9:0]=number1[9:0]+number1[19:10];
				number1[19:10]=10'b0;
				opr={"_","+"};
			end
		end
		else if(opr[7:0]=="+")
		begin
			number1[9:0]=number1[9:0]+sw;
			//opr[7:0]="+";
		end
		else 
		begin
			number1[9:0]=sw;
			opr[7:0]="+";
		end
	end
	
	else if(!key_multi)
	begin
		led2=key_multi;
		if(opr[7:0]=="*")
			number1[9:0] = sw*number1[9:0];
		else if(opr[7:0]=="+")
		begin
			number1={number1[9:0],sw};
			opr="+*";
		end
		else 
		begin
			number1[9:0]=sw;
			opr[7:0]="*";
		end
	end
	
	else if(!key_display)
	begin
		led1=key_display;
		if(opr[7:0]=="*")
			number1[9:0] = sw*number1[9:0];
		if(opr[7:0]=="+")
			number1[9:0]=number1[9:0]+sw;
		number2[9:0]=number1[9:0];
		msecond_counter_low=(number1[9:0]%10);
		msecond_display_low=msecond_counter_low[3:0];
		number1[9:0]=number1[9:0]/10;
		msecond_counter_high=(number1[9:0]%10);
		msecond_display_high=msecond_counter_high[3:0];
		number1[9:0]=number1[9:0]/10;
		second_counter_low=(number1[9:0]%10);
		second_display_low=second_counter_low[3:0];
		number1[9:0]=number1[9:0]/10;
		second_counter_high=(number1[9:0]%10);
		second_display_high=second_counter_high[3:0];
		number1[9:0]=number2[9:0];
	end
	else
	begin
		led0=!key_reset;
		number1=20'b0;
		opr=16'b0;
		msecond_display_low=0;
		msecond_display_high=0;
		second_display_low=0;
		second_display_high=0;
	end
end
*/
endmodule
//4bit 的 BCD 码至 7 段 LED 数码管译码器模块
//可供实例化共 6 个显示译码模块
module sevenseg ( data, ledsegments);
input [3:0] data;
output ledsegments;
reg [6:0] ledsegments;
always @ (*)
 case(data)
 // gfe_dcba // 7 段 LED 数码管的位段编号
 // 654_3210 // DE1-SOC 板上的信号位编号
 0: ledsegments = 7'b100_0000; // DE1-SOC 板上的数码管为共阳极接法。
 1: ledsegments = 7'b111_1001;
 2: ledsegments = 7'b010_0100;
 3: ledsegments = 7'b011_0000;
 4: ledsegments = 7'b001_1001;
 5: ledsegments = 7'b001_0010;
 6: ledsegments = 7'b000_0010;
 7: ledsegments = 7'b111_1000;
 8: ledsegments = 7'b000_0000;
 9: ledsegments = 7'b001_0000;

 default: ledsegments = 7'b100_0000; // 其它值时全灭。
endcase
endmodule