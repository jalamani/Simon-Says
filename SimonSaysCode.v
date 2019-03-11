
module ioTest (input  M_CLOCK,
					input  [3:0] IO_PB,       // IO Board Pushbutton Switches
				   //input  [7:0] IO_DSW,      // IO Board Dip Switchs
					output reg [3:0] F_LED,       // FPGA LEDs
				   output reg [7:0] IO_LED,  // IO Board LEDs
					output reg [3:0] IO_SSEGD,    // IO Board Seven Segment Digits					
					output reg [7:0] IO_SSEG,     //7=dp, 6=g, 5=f,4=e, 3=d,2=c,1=b, 0=a
					output IO_SSEG_COL       // Seven segment column
					//output DEC_POINT);        // Decimal point in the seven segment
					);
	//====================================
	//Variable declaration
	
	assign IO_SSEG_COL = 1; // deactivate the column displays
	reg idle = 1; //Initial state: idle
	reg shift = 0;//Flag to scroll idle message
	reg shift3 = 0;
	reg started = 0;//Flag for game in progress state
	reg clock = 0;//SSD clock
	reg clock2 = 0;//SSD scroll clock
	reg clock3 = 0;//Press button clock
	reg clock4 = 0;//F_LED clock
	reg clock5 = 0;
	reg [14:0] counter = 0;
	reg [16:0] counter2 = 0;
	reg [20:0] counter3 = 0;
	reg [23:0] counter4 = 0;
	reg [4:0] letterLeft = 0;
	reg [4:0] letterLMid = 0;
	reg [4:0] letterRMid = 0;
	reg [4:0] letterRight = 0;
	reg [4:0] letterOff1 = 0;
	reg [4:0] letterOff2 = 0;
	reg [4:0] letterOff3 = 0;
	reg [4:0] letterOff4 = 0;
	reg [4:0] letterOff5 = 0;
	reg [4:0] letterOff6 = 0;
	reg [14:0] twentymS = 0;
	reg [3:0] temp = 0;
	reg [1:0] oncounter;
	reg oncounter3 = 0;
	reg oncounter2 = 0;
	reg [1:0] rand_FLED = 0;
	reg [4:0] difficulty = 0; //8 levels of difficulty
	reg [2:0] numberBlinks = 0; //number of blinks so far in the level
	reg sequenceFinished = 0; //State output by the FPGA LED Control where the sequence has ended and user can enter pushbuttons
	reg [31:0] tobeMatched = 0; //register with the correct sequence
	reg [31:0] tobeMatchedCheck = 0;
	reg [3:0] enteredSequence = 0;
	reg [2:0] levelCheck = 0; //difficulty level of match push button
	reg didyouPressSequence = 0;
	reg youLose = 0;//Flag for lost game state
	reg youWin = 0;
	reg [2:0] oldDifficulty = 0;
	reg [1:0] rand_FLED2 = 0;
//	reg reset = 0;

	//State detector
	always@(posedge clock3) begin
		
		if(idle) begin//idle state waiting for any pushbutton to start the game
			
			if(~IO_PB[3] || ~IO_PB[2] || ~IO_PB[1] || ~IO_PB[0])begin
				idle <= 0;
				started <= 1;
				
			end
			
		end
		
		else if(youLose) begin
			started <= 0;
//			if(~IO_PB[3] || ~IO_PB[2] || ~IO_PB[1] || ~IO_PB[0])begin
//				idle <= 1;
//				reset <= 1;
//				
//			end
		end
//		else if(youWin) begin
//			started <= 0;
//			if(~IO_PB[3] || ~IO_PB[2] || ~IO_PB[1] || ~IO_PB[0])begin
//				idle <= 1;
//				reset <= 1;
//			end
//		end
//		
//		else if(started) begin
//			if(reset)
//				reset <= 0;
//		end
			
	end
		
	//Clock dividers
	always@(posedge M_CLOCK) begin
			if(counter == 21000) begin //5ms SSD time
				clock <= ~clock;
				counter <=0;
										  end
			else
				counter <= counter + 1;
			if(counter2 == 84000) begin //20ms SSD scroll time
				clock2 <= ~clock2;
				counter2 <= 0;
										  end
			else
				counter2 <= counter2 +1;
			if(counter3 == 1800000) begin //time slots for pressbutton
				clock3 <= ~clock3;
				counter3 <= 0;
										  end
			else
				counter3 <= counter3 +1;	
			if(counter4 == 16000000) begin //F_LED time
				clock4 <= ~clock4;
				counter4 <=0;
										  end
			else
				counter4 <= counter4 + 1;
			
	end
	
	always@(posedge clock3) begin
		if(~IO_PB[3] || ~IO_PB[2] || ~IO_PB[1] || ~IO_PB[0])
			clock5 <= 1;
		else
			clock5 <= 0;
	end
	//F_LED times
	always@(posedge clock4 /*or posedge reset*/) begin //F_LED time
		/*if(reset) begin
			numberBlinks = 0;
			sequenceFinished = 0;
			tobeMatched = 0;
			oldDifficulty = 0;
			oncounter2 = 0;
			tobeMatched = 0;
		end
		
		else */
		if(started) begin
			if(oldDifficulty < difficulty) begin
				numberBlinks = 0;
				sequenceFinished = 0;
				tobeMatched = 0;
				
				rand_FLED = rand_FLED + 1;
				if(rand_FLED > 3)
					rand_FLED = 0;
				
			end
			if(numberBlinks < difficulty+1) begin
				oldDifficulty = difficulty;
				rand_FLED = { rand_FLED[0], rand_FLED[1] ^ rand_FLED[0] };
				
				if(oncounter2 == 0) begin
					F_LED[rand_FLED] = 1;					
					oncounter2 = oncounter2 + 1;
					//32 bit register has the lit LED every 4 bits, up to 8 levels/sequences
					case(numberBlinks)
						0: tobeMatched[3:0] = F_LED;
						1: tobeMatched[7:4] = F_LED;
						2: tobeMatched[11:8] = F_LED;
						3: tobeMatched[15:12] = F_LED;
						4: tobeMatched[19:16] = F_LED;
						5: tobeMatched[23:20] = F_LED;
						6: tobeMatched[27:24] = F_LED;
						7: tobeMatched[31:28] = F_LED;
					endcase
				end
				else begin
					F_LED = 4'b0000;
					oncounter2 = 0;
					numberBlinks = numberBlinks + 1;
				end
			end
			else begin
				sequenceFinished = 1;
				
			end
		end
		else if(youLose) begin //replay sequence that you lost on
			numberBlinks = 0;
			if(numberBlinks < difficulty+1) begin
				
					//32 bit register has the lit LED every 4 bits, up to 8 levels/sequences
					case(numberBlinks)
						0: F_LED = tobeMatched[3:0];
						1: F_LED = tobeMatched[7:4];
						2: F_LED = tobeMatched[11:8];
						3: F_LED = tobeMatched[15:12];
						4: F_LED = tobeMatched[19:16];
						5: F_LED = tobeMatched[23:20];
						6: F_LED = tobeMatched[27:24];
						7: F_LED = tobeMatched[31:28];
					endcase
			end
			else begin
				F_LED = 4'b0000;
				oncounter2 = 0;
				numberBlinks = numberBlinks + 1;
			end
		end
	end
	
	//Push button combination matcher
	always@(posedge clock5 /*or posedge reset*/) begin
		
		/*if(reset) begin
			youWin = 0;
			youLose = 0;
			enteredSequence = 0;
			didyouPressSequence = 0;
			tobeMatchedCheck = 0;
			levelCheck = 0;
		end
		else */if(idle)
			IO_LED = 8'b00000000;
	else if(started) begin
		if(sequenceFinished) begin
			if(didyouPressSequence == 0) begin
				if(~IO_PB[0]) begin
					enteredSequence = 4'b1000;
					IO_LED = 8'b10000000;
					didyouPressSequence = 1;
					
				end
				else if(~IO_PB[1]) begin
					enteredSequence = 4'b0100;
					IO_LED = 8'b01000000;
					didyouPressSequence = 1;
				end
				else if(~IO_PB[2]) begin
					enteredSequence = 4'b0010;
					IO_LED = 8'b00100000;
					didyouPressSequence = 1;
				end
				else if(~IO_PB[3]) begin
					enteredSequence = 4'b0001;
					IO_LED = 8'b00010000;
					didyouPressSequence = 1;
				end
			end
		end
		if(didyouPressSequence == 1)begin
			case(levelCheck)
				0: tobeMatchedCheck = tobeMatched[3:0];
				1: tobeMatchedCheck = tobeMatched[7:4];
				1: tobeMatchedCheck = tobeMatched[7:4];
				2: tobeMatchedCheck = tobeMatched[11:8];
				3: tobeMatchedCheck = tobeMatched[15:12];
				4: tobeMatchedCheck = tobeMatched[19:16];
				5: tobeMatchedCheck = tobeMatched[23:20];
				6: tobeMatchedCheck = tobeMatched[27:24];
				7: tobeMatchedCheck = tobeMatched[31:28];
			endcase
			if(enteredSequence == tobeMatchedCheck) begin
				if(levelCheck == difficulty) begin
					if(difficulty == 3)
						youWin = 1;
						
					else begin
						difficulty = difficulty + 1;
					end
					
					levelCheck = 0;
				end
				
				else
					levelCheck = levelCheck + 1;
				didyouPressSequence = 0;
			end
			else
				youLose = 1;
		end
	end
//		if(youLose)
//			if(~IO_PB[3] || ~IO_PB[2] || ~IO_PB[1] || ~IO_PB[0]) begin
//				youLose = 0;
//			end
		
	end
	//Text scroll control								
	always@(posedge clock2 /*or posedge reset*/) begin //20ms - scroll
		/*if(reset) begin
					shift <= 0;
					shift3 <= 0;
		end
		else begin*/
		twentymS = twentymS + 1;
			if(twentymS == 200) begin
				twentymS = 0;
				
				
				if(shift) begin
					temp <= letterLeft;
					letterLeft <= letterLMid;
					letterLMid <= letterRMid;
					letterRMid <= letterRight;
					letterRight <= letterOff1;
					letterOff1 <= letterOff2;
					letterOff2 <= letterOff3;
					letterOff3 <= letterOff4;
					letterOff4 <= letterOff5;
					letterOff5 <= letterOff6;
					letterOff6 <= temp;
					end
				
				if(shift3) begin
					temp <= letterLeft;
					letterLeft <= letterLMid;
					letterLMid <= letterRMid;
					letterRMid <= letterRight;
					letterRight <= letterOff1;
					letterOff1 <= letterOff2;
					letterOff2 <= letterOff3;
					letterOff3 <= letterOff4;
					letterOff4 <= letterOff5;
					letterOff5 <= letterOff6;
					letterOff6 <= temp;
					end
				if(idle && ~shift) begin //idle state
					letterLeft <= 1;//P
					letterLMid <= 2;//r
					letterRMid <= 3;//E
					letterRight <= 4;//S
					letterOff1 <= 4;//S
					letterOff2 <= 0; // space
					letterOff3 <= 1; //P
					letterOff4 <= 5; //L
					letterOff5 <= 6; //A
					letterOff6 <= 7; //Y
					temp <= 0;
					shift <= 1;
					end
				if(started) begin//game has started
					letterLeft <= 2;//r
					letterLMid <= 10;//n
					letterRMid <= 11;//d
					letterRight <= difficulty + 12; //difficulty level
					shift <= 0;
				end
				if(youLose && ~shift3) begin
					letterLeft <= 7;//y
					letterLMid <= 8;//O
					letterRMid <= 9;//U
					letterRight <= 0;//space
					letterOff1 <= 5;//L
					letterOff2 <= 8; //O
					letterOff3 <= 4; //S
					letterOff4 <= 3; //E
					letterOff5 <= 0; //space
					letterOff6 <= 0; //space
					temp <= 0;
					shift3 <= 1;
				end
				if(youWin) begin
					if(oncounter3 == 0) begin
					letterLeft <= 20;//g
					letterLMid <= 8;//O
					letterRMid <= 8;//O
					letterRight <= 11;//d
					oncounter3 <= oncounter3 +1;
					end
					else begin
					letterLeft <= 0; //space
					letterLMid <= 21; //j
					letterRMid <= 8; //o
					letterRight <= 22; //b
					oncounter3 <= 0;
					end
				end
			end
	 end
							

	//SSD output. Letters used: "PrESS PLAy","rOUnd 1", "yOU LOSE" - P,r,E,S,L,A,y,O,U,n,d, - 11 letters, 9 numbers- 4 bits
	always@(posedge clock) begin//every 5ms
		
		if(oncounter == 3) begin//every 20ms, leftmost digit
			oncounter <= 0;			
			IO_SSEGD <= 4'b1110;			
			case(letterLeft)
				0: IO_SSEG <=  8'b11111111;//gfedcba - 0, 1 is off
				1: IO_SSEG <=  8'b10001100;//1 - P
				2: IO_SSEG <=  8'b10101111;//2 - r	
				3: IO_SSEG <=  8'b10000110;//3 - E
				4: IO_SSEG <=  8'b10010010;//4 - S
				5: IO_SSEG <=  8'b11000111;//5 - L
				6: IO_SSEG <=  8'b10001000;//6 - A
				7: IO_SSEG <=  8'b10010001;//7 - y
				8: IO_SSEG <=  8'b11000000;//8 - O
				9: IO_SSEG <=  8'b11000001;//9 - U
			  10: IO_SSEG <=  8'b10101011;//10 - n
			  11: IO_SSEG <=  8'b10100001;//11 - d
			  12: IO_SSEG <=  8'b11111001;//12 - 1
			  13: IO_SSEG <=  8'b10100100;//13 - 2
			  14: IO_SSEG <=  8'b10110000;//14 - 3
			  15: IO_SSEG <=  8'b10011001;//15 - 4
			  16: IO_SSEG <=  8'b10010010;//16 - 5
			  17: IO_SSEG <=  8'b10000010;//17 - 6
			  18: IO_SSEG <=  8'b11111000;//18 - 7
			  19: IO_SSEG <=  8'b10000000;//19 - 8
			  20: IO_SSEG <=  8'b10010000;//20 - 9
			  21: IO_SSEG <=  8'b11100001;//21 - j
			  22: IO_SSEG <=  8'b10000011;//22 - b
				default: IO_SSEG <=  8'b11111111;
			endcase
								 end
		else if(oncounter == 2) begin//leftmid digit
			oncounter <= oncounter + 1;
			IO_SSEGD <= 4'b1101;
			case(letterLMid)
				0: IO_SSEG <=  8'b11111111;//gfedcba - 0, 1 is off
				1: IO_SSEG <=  8'b10001100;//1 - P
				2: IO_SSEG <=  8'b10101111;//2 - r	
				3: IO_SSEG <=  8'b10000110;//3 - E
				4: IO_SSEG <=  8'b10010010;//4 - S
				5: IO_SSEG <=  8'b11000111;//5 - L
				6: IO_SSEG <=  8'b10001000;//6 - A
				7: IO_SSEG <=  8'b10010001;//7 - y
				8: IO_SSEG <=  8'b11000000;//8 - O
				9: IO_SSEG <=  8'b11000001;//9 - U
			  10: IO_SSEG <=  8'b10101011;//10 - n
			  11: IO_SSEG <=  8'b10100001;//11 - d
			  12: IO_SSEG <=  8'b11111001;//12 - 1
			  13: IO_SSEG <=  8'b10100100;//13 - 2
			  14: IO_SSEG <=  8'b10110000;//14 - 3
			  15: IO_SSEG <=  8'b10011001;//15 - 4
			  16: IO_SSEG <=  8'b10010010;//16 - 5
			  17: IO_SSEG <=  8'b10000010;//17 - 6
			  18: IO_SSEG <=  8'b11111000;//18 - 7
			  19: IO_SSEG <=  8'b10000000;//19 - 8
			  20: IO_SSEG <=  8'b10010000;//20 - 9
			  21: IO_SSEG <=  8'b11100001;//21 - j
			  22: IO_SSEG <=  8'b10000011;//22 - b
				default: IO_SSEG <=  8'b11111111;
			endcase
										end
		else if(oncounter == 1) begin//rightmid digit
			oncounter <= oncounter + 1;
			IO_SSEGD <= 4'b1011;			
			case(letterRMid)
				0: IO_SSEG <=  8'b11111111;//gfedcba - 0, 1 is off
				1: IO_SSEG <=  8'b10001100;//1 - P
				2: IO_SSEG <=  8'b10101111;//2 - r	
				3: IO_SSEG <=  8'b10000110;//3 - E
				4: IO_SSEG <=  8'b10010010;//4 - S
				5: IO_SSEG <=  8'b11000111;//5 - L
				6: IO_SSEG <=  8'b10001000;//6 - A
				7: IO_SSEG <=  8'b10010001;//7 - y
				8: IO_SSEG <=  8'b11000000;//8 - O
				9: IO_SSEG <=  8'b11000001;//9 - U
			  10: IO_SSEG <=  8'b10101011;//10 - n
			  11: IO_SSEG <=  8'b10100001;//11 - d
			  12: IO_SSEG <=  8'b11111001;//12 - 1
			  13: IO_SSEG <=  8'b10100100;//13 - 2
			  14: IO_SSEG <=  8'b10110000;//14 - 3
			  15: IO_SSEG <=  8'b10011001;//15 - 4
			  16: IO_SSEG <=  8'b10010010;//16 - 5
			  17: IO_SSEG <=  8'b10000010;//17 - 6
			  18: IO_SSEG <=  8'b11111000;//18 - 7
			  19: IO_SSEG <=  8'b10000000;//19 - 8
			  20: IO_SSEG <=  8'b10010000;//20 - 9
			  21: IO_SSEG <=  8'b11100001;//21 - j
			  22: IO_SSEG <=  8'b10000011;//22 - b
				default: IO_SSEG <=  8'b11111111;
			endcase
										end
		else if(oncounter == 0) begin//rightmost digit
			oncounter <= oncounter + 1;
			IO_SSEGD <= 4'b0111;			
			case(letterRight)
				0: IO_SSEG <=  8'b11111111;//gfedcba - 0, 1 is off
				1: IO_SSEG <=  8'b10001100;//1 - P
				2: IO_SSEG <=  8'b10101111;//2 - r	
				3: IO_SSEG <=  8'b10000110;//3 - E
				4: IO_SSEG <=  8'b10010010;//4 - S
				5: IO_SSEG <=  8'b11000111;//5 - L
				6: IO_SSEG <=  8'b10001000;//6 - A
				7: IO_SSEG <=  8'b10010001;//7 - y
				8: IO_SSEG <=  8'b11000000;//8 - O
				9: IO_SSEG <=  8'b11000001;//9 - U
			  10: IO_SSEG <=  8'b10101011;//10 - n
			  11: IO_SSEG <=  8'b10100001;//11 - d
			  12: IO_SSEG <=  8'b11111001;//12 - 1
			  13: IO_SSEG <=  8'b10100100;//13 - 2
			  14: IO_SSEG <=  8'b10110000;//14 - 3
			  15: IO_SSEG <=  8'b10011001;//15 - 4
			  16: IO_SSEG <=  8'b10010010;//16 - 5
			  17: IO_SSEG <=  8'b10000010;//17 - 6
			  18: IO_SSEG <=  8'b11111000;//18 - 7
			  19: IO_SSEG <=  8'b10000000;//19 - 8
			  20: IO_SSEG <=  8'b10010000;//20 - 9
			  21: IO_SSEG <=  8'b11100001;//21 - j
			  22: IO_SSEG <=  8'b10000011;//22 - b
				default: IO_SSEG <=  8'b11111111;
			endcase
										end
		
		
					  
										end

endmodule
	