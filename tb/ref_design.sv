//#################################################################################
// Project       :  Hamming weight counter and index indentifier
// Editor        :  Notepad++ on Windows 8
// File          :  ref_design.sv
// Description   :  Ref Model Output is Count followed by location of set bits 
// Created by    :  Sukrut Kelkar
// Date          :  10/20/2017                 
//#################################################################################
module ref_design #(parameter start_bit=1, count_vec=100) (
);

            logic [1023:0] in_stream;
            logic [1023:0] rand_data;
            logic [9:0] count_1;
            logic [9:0] location [0:32];
            logic [6:0] count_vec_1;
            integer file_r,file_w,r,i,j,k;

            initial 
            begin
             //Opening File for Reading Test Vectors
            file_r = $fopen("test_vectors.txt", "r");
            
            if (file_r == 0)
               begin
                  $display("file_r handle was NULL");
                  $finish;
               end
               
            // ref Model will write its out put in this file. 
            file_w = $fopen("ref_result.txt", "w");
            
            if (file_w == 0)
               begin
                  $display("file_w handle was NULL");
                  $finish;
               end
             
            //####################################### Ref Model #######################################
            // Generates a Text file with name ref_results
            // First number is no. of counts followed by the location of the packets
            $fwrite (file_w,"##COUNT LOC0 LOC1 LOC2 LOC3 ... LOC31\n");
            repeat(count_vec)
            begin
                  r = $fscanf(file_r, "%b\n",rand_data);
                  
                  in_stream = rand_data;
                  
                  count_1 = 0;
                  j = 0;
                  //Reference
                  if (start_bit)
                  begin
                        j=0;
                        for (i=0;i<1024;i++)
                        begin
                              if (in_stream[i] == 1'd0)begin count_1 = count_1;end
                              else 
                              begin 
                                 count_1 = count_1 + 1;
                                 location[j] = i;
                                 j=j+1;
                              end
                        end
                     
                        // Writing to the file
                        $fwrite (file_w,"%d ",count_1);
                        
                        for (k=0;k<32;k++)
                        begin
                           $fwrite (file_w,"%d ",location[k]);
                        end
                        $fwrite (file_w,"\n");
                     
                  end
            end
            $fclose(file_r);
            $fclose(file_w);
end

endmodule