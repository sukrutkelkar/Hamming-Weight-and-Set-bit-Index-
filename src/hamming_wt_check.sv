//#################################################################################
// Project       :  Hamming weight counter and index indentifier
// Editor        :  Notepad++ on Windows 8
// File          :  ref_design.sv
// Description      : The module below is a hamming weight checker which
// 										 takes 1024-bit packet as input in the form of 
// 										 8-bit packets and a start of packet signal, which
// 										 then is analysed for total number of 1's in all 1024
// 										 bits collected in consucutive 128 cycles.
//
// 										 Also, after the complete packet is received, the module
// 										 gives a location data of each bit in 1024-bit string
// 										 as a 10-bit value. To validate the data user will need
// 										 to use location_data_valid signal which is generated 
// 										 along side each 10-bit packet of location data.
//
// 										 The last bit i.e. bit 1023 takes couple more cycles to
// 										 compute if it is preceded by series of ZERO packets,
// 										 to mitigate this you will need to used location_data_valid.
//
// 										 For notifying about the last location data packet
// 										 a last_data_of_packet_valid signal is asserted with
// 										 last packet.
//
// 										 An error signal pulse is generated when number
// 										 of one's count in string of 1024 goes above 31.
// 										 When this signal is generated it resets all but one
// 										 FSMs (Resets main capture FSM, Packer FSM but not 
// 										 Unpacker FSM)
//
// 										 The error signal also resets the packed_data FIFO,
// 										 but flushes out any remaining old location_data packet
// 										 of previous cycle safely before resetting Unpacker FSM
// 										 and flusing unpacker FIFO completely 
// Created by    :  Sukrut Kelkar
// Date          :  10/20/2017                 
//#################################################################################

module hamming_wt_check (
				input 			clk,													// System Clock Input
				input 			rst,													// Active High Asynchronous Reset
				input				start_of_packet,							// Active High Pulse needed as input along with first packet as input
				input [7:0] packet_data,									// 8-bit packet data input starting from LSB of 1024-bit string
				
				output [9:0] location_data,								// 10-bit location data output stating position of 1's with values from 0 to 1023
				output [5:0] ones_count_out,							// 6-bit output of total number of one's in 1024-bits
				output    	 ones_count_valid,						// Active high pulse generated along with ones_count_out output
				output reg	 location_data_valid,					// Active high pulse/level signal generated alongside to location_data output
				output reg	 last_data_of_packet_valid,		// Active high pulse generated for last location_data packet
				output			 wt_err												// Active high pulse generated when number of one's is more than 31

);

				// State machine parameters

				parameter	IDLE = 1'd0,
									PACC = 1'd1;

				parameter ISAV = 2'd0,
									CAPP = 2'd1,
									ANLS = 2'd2,
									CHCK = 2'd3;

				parameter VLCK = 1'd0,
									EXTR = 1'd1;
				
				// Internal signals and registers for location calculation,
				// checking packet for ZERO value to reduce unnecessary state jumps

				logic	[9:0]	location_0;
				logic	[9:0]	location_1;
				logic	[9:0]	location_2;
				logic	[9:0]	location_3;
				logic	[9:0]	location_4;
				logic	[9:0]	location_5;
				logic	[9:0]	location_6;
				logic	[9:0]	location_7;
				
				logic is_pk0_0;
				logic is_pk1_0;
				logic is_pk2_0;
				logic is_pk3_0;
				logic is_pk4_0;
				logic is_pk5_0;
				logic is_pk6_0;
				logic is_pk7_0;

				// Registers and wires for internal data movement

				logic	[7:0]	 packet_data_latch;

				logic [79:0] location_pak_din;
				logic [79:0] location_pak_dout;
				logic [79:0] location_pak_dout_latch;

				logic				 valid_location;
				logic				 out_valid_latch;

				logic				 wr_location_pak_fifo;
				logic				 rd_location_pak_fifo;
				logic				 location_pak_fifo_empty;

				logic				 max_bit_err;
				logic				 rst_n_err;

				logic				 rd_location_unpak_fifo;
				logic				 wr_location_unpak_fifo;
				logic				 location_unpak_fifo_empty;
				logic				 location_unpak_fifo_full;
				logic				 flush_unpak_fifo;
				logic				 en_flush_for_err;
				logic	[9:0]	 location_unpak_din;
				logic	[9:0]	 location_unpak_dout;

				// Counters for calculating location, number of packets, number of ones
				// and location_data count to be extracted
				logic	[10:0] bit_count;
				logic	[7:0]	 packet_count;
				logic [5:0]  ones_count;
				logic [5:0]	 ones_count_loc_num;
				logic [4:0]  extr_count;

				// Signal to mitigate the zero packet check logic
				// It checks if location zero in 1024-bit (Lowest packet i.e. LSB of packet 0)
				// is '1'. If yes then this directly adds location value ZERO to location_data FIFO
				// i.e. unpacker FIFO

				logic				 push_zero_location;

				// State machine variables
				logic state; 						// Main state machine to watch and record all packet and ones counts
																// this also packs calculated location data total of 80-bits, 10-bit
																// for each bit location and pushes it to packed FIFO

				logic [1:0] unpk_state; // Unpacker FSM unpacks the data from packed FIFO, analyze zero value data
																// it removes zero value data from 80-bit packed data and pushes only valid 
																// data to final location_data FIFO i.e. unpacker FIFO 

				logic ext_state;				// Extractor FSM extracts all the location data in the 31 cycles after all 1024-bits
																// i.e. 128 packets of 8-bits are received.
																// It also analyzes whether all location data is properly pushed out or not and waits
																// if a data is unavailable in unpacker FIFO (ex. Location of 1023rd bit) 

				// Location calculation

				assign location_0 = packet_data_latch[0] ? (10'd0 + bit_count[9:0]) : 10'd0;
				assign location_1 = packet_data_latch[1] ? (10'd1 + bit_count[9:0]) : 10'd0;
				assign location_2 = packet_data_latch[2] ? (10'd2 + bit_count[9:0]) : 10'd0;
				assign location_3 = packet_data_latch[3] ? (10'd3 + bit_count[9:0]) : 10'd0;
				assign location_4 = packet_data_latch[4] ? (10'd4 + bit_count[9:0]) : 10'd0;
				assign location_5 = packet_data_latch[5] ? (10'd5 + bit_count[9:0]) : 10'd0;
				assign location_6 = packet_data_latch[6] ? (10'd6 + bit_count[9:0]) : 10'd0;
				assign location_7 = packet_data_latch[7] ? (10'd7 + bit_count[9:0]) : 10'd0;

				// Check if any of location have non-zero value
				assign valid_location = ( (!(|bit_count[9:0]) & packet_data_latch[0]) | (|location_0) | (|location_1) | (|location_2) | (|location_3) 
														      | (|location_4) | (|location_5) | (|location_6) | (|location_7)) & (state == PACC);

				// Synchronous error bit ored with reset to restart packet capture
				assign rst_n_err = rst | max_bit_err;
				assign wt_err = max_bit_err;

				// Output wire assignments
				assign ones_count_out = ones_count;

				assign location_data = location_unpak_dout;

				assign ones_count_valid = out_valid_latch;

				// Main state machine to capture packets and analyze location data
				always_ff @(posedge clk or posedge rst_n_err) begin : main_state_machine
					if (rst_n_err) begin
									state 							<= IDLE;
									bit_count 					<= 11'd0;
									packet_count 				<= 8'd0;
									packet_data_latch 	<= 8'd0;
									out_valid_latch			<= 1'd0;
									location_pak_din		<= 80'd0;
									wr_location_pak_fifo<= 1'd0;
									max_bit_err 				<= 1'd0;
					end
					else begin

									packet_data_latch <= packet_data;
									location_pak_din		 <= {location_7,location_6,location_5,location_4,location_3,location_2,location_1,location_0};
									wr_location_pak_fifo	 <= valid_location;

									case(state)
													IDLE	:	begin
																		bit_count <= 11'd0;
																		packet_count <= 8'd0;
																		ones_count	<= 6'd0;
																		out_valid_latch	<= 1'd0;
																		max_bit_err <= 1'd0;
																		
																		if (start_of_packet) begin
																						state <= PACC;
																		end
																		else begin
																						state <= IDLE;
																		end
																	end

													PACC	:	begin
																	bit_count 	<= bit_count + 11'd8;
																	packet_count<= packet_count + 8'd1;
																	ones_count  <= ones_count + {5'd0,packet_data_latch[0]} + {5'd0,packet_data_latch[1]}
																													  + {5'd0,packet_data_latch[2]} + {5'd0,packet_data_latch[3]}
																													  + {5'd0,packet_data_latch[4]} + {5'd0,packet_data_latch[5]}
																													  + {5'd0,packet_data_latch[6]} + {5'd0,packet_data_latch[7]};
																	max_bit_err <= (ones_count > 6'd31);
																	if(packet_count == 8'd127) begin
																					out_valid_latch <= 1'd1;
																					state <= IDLE;
																	end
																	else begin
																					out_valid_latch <= 1'd0;
																					state <= PACC;
																	end

																	end
									endcase
					end
				end : main_state_machine

				// Unpacker FSM to analyze non-zero data in a packed location data packet of 80-bit
				always_ff @(posedge clk or posedge rst_n_err) begin : unpacking_fsm
								if (rst_n_err) begin
												unpk_state <= ISAV;
												wr_location_unpak_fifo <= 1'd0;
												location_unpak_din <= 10'd0;
												location_pak_dout_latch <= 80'd0;
												rd_location_pak_fifo <= 1'd0;
												is_pk0_0 <= 1'b0;
												is_pk1_0 <= 1'b0;
												is_pk2_0 <= 1'b0;
												is_pk3_0 <= 1'b0;
												is_pk4_0 <= 1'b0;
												is_pk5_0 <= 1'b0;
												is_pk6_0 <= 1'b0;
												is_pk7_0 <= 1'b0;
												push_zero_location  <= 1'd0;
								end
								else begin
												case (unpk_state)
																ISAV	:	begin
																				push_zero_location  <= 1'd0;
																				wr_location_unpak_fifo <= 1'd0;
																				location_unpak_din <= 10'd0;
																				location_pak_dout_latch <= 80'd0;
																				is_pk0_0 <= 1'b0;
																				is_pk1_0 <= 1'b0;
																				is_pk2_0 <= 1'b0;
																				is_pk3_0 <= 1'b0;
																				is_pk4_0 <= 1'b0;
																				is_pk5_0 <= 1'b0;
																				is_pk6_0 <= 1'b0;
																				is_pk7_0 <= 1'b0;
																				if (!location_pak_fifo_empty) begin
																								rd_location_pak_fifo <= 1'd1;
																								unpk_state <= CAPP;
																				end
																				else begin
																								rd_location_pak_fifo <= 1'd0;
																								unpk_state <= ISAV;
																				end
																				end
																CAPP	: begin
																								push_zero_location  <= 1'd0;
																								rd_location_pak_fifo <= 1'd0;
																								wr_location_unpak_fifo <= 1'd0;
																								location_unpak_din <= 10'd0;
																								location_pak_dout_latch <= 80'd0;
																								is_pk0_0 <= 1'b0;
																								is_pk1_0 <= 1'b0;
																								is_pk2_0 <= 1'b0;
																								is_pk3_0 <= 1'b0;
																								is_pk4_0 <= 1'b0;
																								is_pk5_0 <= 1'b0;
																								is_pk6_0 <= 1'b0;
																								is_pk7_0 <= 1'b0;
																								unpk_state <= ANLS;
																					
																				end
																ANLS	: begin
																								rd_location_pak_fifo <= 1'd0;
																								wr_location_unpak_fifo <= 1'd0;
																								location_unpak_din <= 10'd0;
																								location_pak_dout_latch <= location_pak_dout;
																								is_pk0_0 <= |location_pak_dout[9:0]  ;
																								is_pk1_0 <= |location_pak_dout[19:10];
																								is_pk2_0 <= |location_pak_dout[29:20];
																								is_pk3_0 <= |location_pak_dout[39:30];
																								is_pk4_0 <= |location_pak_dout[49:40];
																								is_pk5_0 <= |location_pak_dout[59:50];
																								is_pk6_0 <= |location_pak_dout[69:60];
																								is_pk7_0 <= |location_pak_dout[79:70];
																								push_zero_location  <= ! ((|location_pak_dout[9:0]) | (|location_pak_dout[19:10]) | 
																							 												 (|location_pak_dout[29:20]) | (|location_pak_dout[39:30]) |
																							 												 (|location_pak_dout[49:40]) | (|location_pak_dout[59:50]) |
																							 												 (|location_pak_dout[69:60]) | (|location_pak_dout[79:70])) ;
																								unpk_state <= CHCK;
																				end
																CHCK	: begin
																				rd_location_pak_fifo <= 1'd0;
																				push_zero_location <= 1'd0;
																						if(push_zero_location) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= 10'd0;
																										location_pak_dout_latch <= location_pak_dout_latch ;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0};
																						end
																						else if(is_pk0_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[9:0];
																										location_pak_dout_latch <= location_pak_dout_latch ;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,1'b0};
																						end
																						else if(is_pk1_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[19:10];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,1'b0,is_pk0_0};
																						end
																						else if(is_pk2_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[29:20];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,1'b0,is_pk1_0,is_pk0_0};
																						end
																						else if(is_pk3_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[39:30];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,1'b0,is_pk2_0,is_pk1_0,is_pk0_0};
																						end
																						else if(is_pk4_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[49:40];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,is_pk5_0,1'b0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0};
																						end
																						else if(is_pk5_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[59:50];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,is_pk6_0,1'b0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0};
																						end
																						else if(is_pk6_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[69:60];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{is_pk7_0,1'b0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0};
																						end
																						else if(is_pk7_0) begin
																										unpk_state <= CHCK;
																										wr_location_unpak_fifo <= 1'd1;
																										location_unpak_din <= location_pak_dout_latch[79:70];
																										location_pak_dout_latch <= location_pak_dout_latch;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <=
																														{1'b0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0};
																						end
																						else begin
																										unpk_state <= ISAV;
																										wr_location_unpak_fifo <= 1'd0;
																										location_unpak_din <= 10'd0;
																										location_pak_dout_latch <= 80'd0;
																										{is_pk7_0,is_pk6_0,is_pk5_0,is_pk4_0,is_pk3_0,is_pk2_0,is_pk1_0,is_pk0_0} <= 8'd0;
																						end
																				end
												endcase
									
								end
					
				end : unpacking_fsm

				// Extractor FSM to push the location_data of all ones preset in 1024-bit string
				always_ff @(posedge clk or posedge rst) begin : Location_Data_Extractor
					if (rst) begin
									rd_location_unpak_fifo <= 1'b0;
									ext_state <= VLCK;
									ones_count_loc_num <= 5'd0;
									extr_count <= 5'd0;
									flush_unpak_fifo <= 1'd0;
									en_flush_for_err <= 1'd0;
									location_data_valid <= 1'd0;
									last_data_of_packet_valid <= 1'd0;
					end
					else begin
									case (ext_state)
													VLCK	:	begin
																		extr_count <= 5'd0;
																		flush_unpak_fifo <= 1'd0;
																		en_flush_for_err <= 1'd0;
																		location_data_valid <= 1'd0;
																		last_data_of_packet_valid <= 1'd0;
																		if (packet_count == 8'd127) begin
																						ext_state <= EXTR;
																						ones_count_loc_num <= ones_count[4:0] + {5'd0,packet_data_latch[0]} + {5'd0,packet_data_latch[1]}
																													  											+ {5'd0,packet_data_latch[2]} + {5'd0,packet_data_latch[3]}
																													  											+ {5'd0,packet_data_latch[4]} + {5'd0,packet_data_latch[5]}
																													  											+ {5'd0,packet_data_latch[6]} + {5'd0,packet_data_latch[7]};
																						rd_location_unpak_fifo <= 1'd1;
																		end
																		else begin
																						ext_state <= VLCK;
																						ones_count_loc_num <= 6'd0;
																						rd_location_unpak_fifo <= 1'd0;
																		end
																	end
													EXTR	:	begin
																		extr_count <= ((extr_count != ones_count_loc_num) & !location_unpak_fifo_empty) ? extr_count + 5'd1 : extr_count ;
																		en_flush_for_err <= max_bit_err ? 1'b1 : en_flush_for_err;
																	  ones_count_loc_num <= ones_count_loc_num;
																		location_data_valid <= ((extr_count != ones_count_loc_num) & !location_unpak_fifo_empty);
																		last_data_of_packet_valid <= ((ones_count_loc_num != 5'd0) & (extr_count == (ones_count_loc_num-5'd1)) & !location_unpak_fifo_empty);
																		if(extr_count == ones_count_loc_num) begin
																						rd_location_unpak_fifo <= 1'd0;
																						ext_state <= VLCK;
																						flush_unpak_fifo <= en_flush_for_err ? 1'b1 : flush_unpak_fifo;
																		end
																		else begin
																						rd_location_unpak_fifo <= (|ones_count_loc_num) ? ((extr_count != (ones_count_loc_num - 5'd1)) & !location_unpak_fifo_empty) : 1'd0;
																						ext_state <= EXTR;
																						flush_unpak_fifo <= 1'd0;
																		end
																	end
									endcase
					end
				end : Location_Data_Extractor

				// FIFO for Packed data of 80-bits
				sync_fifo_80 #(.DEPTH(32)) sync_fifo_80_inst(
								.clk(clk),
								.rst(rst_n_err),
								.wr(wr_location_pak_fifo),
								.rd(rd_location_pak_fifo),
								.data_in(location_pak_din),
								.data_out(location_pak_dout),
								.emp(location_pak_fifo_empty),
								.full()
				);

				// FIFO for Unpacked data of 10-bits
				sync_fifo #(.DEPTH(32), .WIDTH(10)) sync_fifo_inst(
								.clk(clk),
								.rst(rst | flush_unpak_fifo),
								.wr(wr_location_unpak_fifo),
								.rd(rd_location_unpak_fifo),
								.data_in(location_unpak_din),
								.data_out(location_unpak_dout),
								.emp(location_unpak_fifo_empty),
								.full(location_unpak_fifo_full)
				);
	
endmodule
