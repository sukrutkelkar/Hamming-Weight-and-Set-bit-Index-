###################################################################################
## Project       :  Hamming weight counter and index indentifier
## Editor        :  Notepad++ on Windows 8
## File          :  test_vec_gen.py
## Description   :  Generates random data packets for 1024 data in and creates a text file
## Script by     :  Sukrut Kelkar
## Date          :  10/20/2017                 
###################################################################################

import re
import random


def generate_random():
   
   location = []
   for i in range (1024):
      location.append(0);
   
   file=open('test_vectors.txt','w')
   
   for i in range (100):
      #initializing to zero
      for i in range (1024):
         location[i]=0;
      
      rand_1 = random.randint(0,31);
      for j in range (rand_1):
         rand_index = random.randint(1,1023);
         location [rand_index] = 1;
         
      for i in location:
         file.write("%s"%i);
    
      file.write("\n")

   file.close()   
   
def main():
    generate_random();
    return
    
if __name__ == '__main__':
     main()