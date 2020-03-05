/*******************************************************************************
  Copyright 2019 Supranational LLC
  Copyright 2020 Steve Golson

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*******************************************************************************/

`include "msuconfig.vh"

module tb();
   localparam integer MOD_LEN = `MOD_LEN_DEF;
   localparam integer   R_MSB = `R_MSB_DEF;

   localparam [MOD_LEN-1:0]  MODULUS = `MODULUS_DEF;

   localparam [R_MSB:0]            r = 1'b1 << R_MSB;
   localparam [MOD_LEN-1:0]    r_inv = modinv(r,MODULUS);

   localparam [MOD_LEN-1:0]        n = MODULUS;
   localparam [R_MSB-1:0]    n_prime = create_n_prime(r,r_inv,n);

   
   logic                   clk;
   logic                   reset;
   logic                   start, start_toggle;
   logic                   valid;
   logic [MOD_LEN-1:0]     sq_in, sq_in_montgomery;
   logic [MOD_LEN-1:0]     sq_out, sq_out_montgomery;
   logic [MOD_LEN-1:0]     sq_out_expected;
   logic [MOD_LEN-1:0]     sq_out_actual;

   integer                 t_start;
   integer                 t_final;
   integer                 t_curr;
   
   integer                 test_file;
   integer                 i, ret;
   integer                 cycle_count;
   integer                 error_count;
   
   integer                 total_cycle_count;
   integer                 total_squarings;
   
   modular_square_wrapper
      uut(
          clk,
          reset,
          start,
          start_toggle,
          sq_in_montgomery,
          sq_out_montgomery,
          valid
          );

   assign sq_in_montgomery = to_Montgomery(sq_in, r, n);
   assign sq_out = from_Montgomery(sq_out_montgomery, r_inv, n);
   
   initial begin
      test_file = $fopen("../../../../../test.txt", "r");
      if(test_file == 0) begin
         $display("test_file handle was NULL");
         $finish;
      end
   end
                
   always begin
      #4 clk = ~clk;
   end
    
   initial begin
      logic [MOD_LEN+R_MSB:0] temp_wide;

      // Reset the design
      clk           = 1'b0;
      reset         = 1'b1;
      sq_in         = 0;
      start         = 1'b0;
      start_toggle  = 1'b0;
      t_start       = 0;
      t_curr        = 0;

      $display("#### MOD_LEN ='d%0d", MOD_LEN);
      $display("####   R_MSB ='d%0d", R_MSB);
      $display("#### modulus n      ='d%0d", n);
      $display("####         n_prime='d%0d", n_prime);
      $display("####         r      ='d%0d", r);
      $display("####         r_inv  ='d%0d", r_inv);
      $display("#### modulus n      ='h%0h", n);
      $display("####         n_prime='h%0h", n_prime);
      $display("####         r      ='h%0h", r);
      $display("####         r_inv  ='h%0h", r_inv);
      temp_wide = r*r_inv;
      $display("#### confirm equal to 1 : ( r * r_inv ) mod n = %0d", temp_wide % n);
      $display("#### confirm equal to 1 : ( r * r_inv ) - ( n * n_prime ) = %0d", (r*r_inv) - (n*n_prime));
      
      @(negedge clk);
      @(negedge clk);
	  for( int kk = 0; kk < 150; kk++ ) // delay for 1.5usec untill pll starts
	      @(negedge clk);
      @(negedge clk);

      reset      = 1'b0;

      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);

      // Scan in the modulus and initial value
      $fscanf(test_file, "%x\n", sq_in); 
      @(negedge clk);

      start         = 1'b1;
      start_toggle  = !start_toggle;
      @(negedge clk);
      start         = 1'b0;

      // Run the squarer and periodically check results
      error_count   = 0;
      total_cycle_count          = 0;
      total_squarings            = 0;
      while(1) begin
         ret = $fscanf(test_file, "%d, %x\n", t_final, sq_out_expected);
         if(ret != 2) begin
            break;
         end 

         // Run to the next checkpoint specified in the test file
         cycle_count   = 1;
         t_start       = t_curr;
         while(t_curr < t_final) begin
            if(valid == 1'b1) begin
               t_curr        = t_curr + 1;
               sq_out_actual = sq_out;
               total_squarings   = total_squarings + 1;
            end

            @(negedge clk);
            cycle_count = cycle_count + 1;
            total_cycle_count    = total_cycle_count + 1;
         end

         $display("%5d %0.2f %x", t_final, 
                  real'(cycle_count) / real'(t_final - t_start), 
                  sq_out_actual);

         // Check correctness
         if(sq_out_actual !== sq_out_expected) begin
            $display("MISMATCH expected %x", sq_out_expected);
            $display("           actual %x", sq_out_actual);
            error_count = error_count + 1;
            break;
         end
         @(negedge clk);
         total_cycle_count       = total_cycle_count + 1;
      end
      $display("Overall %d cycles, %d squarings, %0.2f cyc/sq", 
               total_cycle_count, total_squarings,
               real'(total_cycle_count) / real'(total_squarings)); 
      if(error_count == 0) begin
         $display("SUCCESS!");
         $finish();
      end
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      $error("FAILURE %d mismatches", error_count);
      $finish();
   end

   //----------------------------------------------------------------------
   // functions used by Montgomery logic
   
   function [R_MSB-1:0] create_n_prime;
      input [R_MSB:0] 	           r;
      input [MOD_LEN-1:0] 	   r_inv, n;
      logic [MOD_LEN+R_MSB:0] 	   temp_wide;
      begin
	 // r*r_inv - n*n_prime = 1
	 // so
	 // n_prime = (r*r_inv - 1) / n
	 temp_wide = r * r_inv;
	 create_n_prime = (temp_wide - 1'b1) / n;
      end
   endfunction

   function [MOD_LEN-1:0] modinv;
      input [R_MSB:0] 	   u; // input
      input [MOD_LEN-1:0]  v; // modulus
      
      logic [R_MSB:0] 	   u3;

      logic [MOD_LEN-1:0]  inv, u1, v1, v3, t1, t3, q;
      logic 		   iter;

      // adapted from
      // https://www.di-mgt.com.au/euclidean.html
      // 
      //   Computing the modular inverse
      // 
      // This code is an adaptation of the extended Euclidean algorithm from
      // Knuth [Vol 2 Algorithm X p 342] avoiding negative integers. It
      // computes the multiplicative inverse of u modulo v, u-1 (mod v), and
      // returns either the inverse as a positive integer less than v, or zero
      // if no inverse exists.

      begin
	 /* Step X1. Initialise */
	 u1 = 1;
	 u3 = u;
	 v1 = 0;
	 v3 = v;

	 /* Remember odd/even iterations */
	 iter = 1'b1;

	 /* Step X2. Loop while v3 != 0 */
	 while (v3 != 0) begin
	    /* Step X3. Divide and "Subtract" */
	    q = u3 / v3;
	    t3 = u3 % v3;
	    t1 = u1 + q * v1;
	    /* Swap */
            u1 = v1; v1 = t1; u3 = v3; v3 = t3;
            iter = !iter;
	 end

	 /* Ensure a positive result */
	 if (!iter)
	   modinv = v - u1;
	 else
	   modinv = u1;

	 /* Make sure u3 = gcd(u,v) == 1 */
	 if (u3 != 1)
	   /* Error: No inverse exists */
	   modinv = 0;

      end
   endfunction

   function [MOD_LEN-1:0] to_Montgomery;
      input [MOD_LEN-1:0] a;
      input [R_MSB:0] 	  r;
      input [MOD_LEN-1:0] n;
      logic [MOD_LEN+R_MSB:0] temp_wide;
      // a_bar = a*r mod n
      begin
	 temp_wide = a*r;
	 to_Montgomery = temp_wide % n;
      end
   endfunction

   function [MOD_LEN-1:0] from_Montgomery;
      input [MOD_LEN-1:0] a_bar;
      input [MOD_LEN-1:0] r_inv;
      input [MOD_LEN-1:0] n;
      logic [MOD_LEN*2-1:0] temp_wide;
      // a = a_bar*r_inv mod n
      begin
	 temp_wide = a_bar*r_inv;
	 from_Montgomery = temp_wide % n;
      end
   endfunction

endmodule

