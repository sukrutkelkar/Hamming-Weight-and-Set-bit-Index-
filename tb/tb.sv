//#################################################################################
// Project       :  Hamming weight counter and index indentifier
// Editor        :  Notepad++ on Windows 8
// File          :  testbench.sv
// Description   :  Test bench with a reference model to check the 
//                  Input sequence is 8bits/clk for 128 cycles
//                  Start bit indicates start of packet
//                  Output is number of set bits and location of set bits.
//                  Maximum allowed set bits is 31.
// Created by    :  Sukrut Kelkar
// Date          :  10/20/2017                 
//#################################################################################
module tb();

            logic clk_tb = 1'd0;
            logic rst_tb;
            logic start_bit_tb = 1'd1;
            logic [7:0] in_tb;

            logic [9:0] out;
            logic [5:0] ones_count_tb;
            logic [6:0] count; 
            logic valid_tb, wt_err_tb;

            logic [1023:0] in_stream;
            logic [6:0] count_vec;
            logic [1023:0] rand_data;
            logic [1023:0] in_data;
            logic [9:0] shift_data;
            logic start_bit = 1'd1;
            logic ones_count_valid_tb;
            logic location_data_valid_tb;
            logic last_data_of_packet_valid;
            integer file_rd,r,a;
    
            ref_design #(.start_bit(1), .count_vec(100)) ref_d();
 
            hamming_wt_check DUT(
                        .clk(clk_tb),
                        .rst(rst_tb),
                        .start_of_packet(start_bit_tb),
                        .packet_data(in_tb),
                        
                        .location_data(out),
                        .ones_count_out(ones_count_tb),
                        .ones_count_valid(ones_count_valid_tb),
                        .location_data_valid(location_data_valid_tb),
                        .last_data_of_packet_valid(last_data_of_packet_valid),
                        .wt_err(wt_err_tb)
            );

            //Block for generating clock
            initial
            begin
                  clk_tb = 0;
                  forever 
                  begin
                        #50 clk_tb = ~clk_tb;
                  end
            end

            initial 
            begin
                  //Opening file for reading test vectors
                  file_rd = $fopen("test_vectors.txt", "r");

                  if (file_rd == 0)
                  begin
                        $display("file_rd handle was NULL");
                        $finish;
                  end

                  $display("Reset active\n");

                  rst_tb = 1'd1;

                  #200;

                  rst_tb = 1'd0;

                  $display("Reset off\n");
                  count = 2;
                  start_bit_tb = 1;

                  //Pusing tests in the DUT
                  repeat (100)
                  begin
                        r = $fscanf(file_rd, "%b\n",rand_data);
                        in_data = rand_data;
                     
                        //Driving the DUT
                        repeat(128)
                        begin
                              @(negedge clk_tb);
                              in_tb = in_data [7:0];
                              in_data = in_data >> 8;
                        end
                        
                        @(negedge clk_tb);

                  end

                  $fclose(file_rd);
                  #2000;

                  $finish();

            end

endmodule