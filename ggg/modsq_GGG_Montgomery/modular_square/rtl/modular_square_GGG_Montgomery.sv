/*******************************************************************************
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

module modular_square_GGG_Montgomery
   #(
     parameter int MOD_LEN = 1024,
     parameter int R_MSB   = 1026
    )
   (
    input logic [15:0] 	       clk_phase,
    input logic 	       reset,
    input logic 	       start,
    input logic 	       bypass,
    input logic [MOD_LEN-1:0]  sq_in,
    output logic [MOD_LEN-1:0] sq_out,
    output logic 	       valid,
    output logic 	       valid_toggle
   );

   // Montgomery modular square and reduction
   // Using the notation from Koc, Acar, Kaliski 1996
   // and https://en.wikipedia.org/wiki/Montgomery_modular_multiplication

   localparam [MOD_LEN-1:0]  MODULUS = `MODULUS_DEF;

   localparam [R_MSB:0]            r = 1'b1 << R_MSB;
   localparam [MOD_LEN-1:0]    r_inv = modinv(r,MODULUS);

   localparam [MOD_LEN-1:0]        n = MODULUS;
   localparam [R_MSB-1:0]    n_prime = create_n_prime(r,r_inv,n);

   logic [MOD_LEN-1:0]            cur_sq_in;
   logic [MOD_LEN*2-1:0]          squared;
   logic [MOD_LEN-1:0]            sq_out_comb;
   logic                          running;

   always @ (posedge clk_phase[0]) begin
      if (reset) begin
	 running <= 1'b0;
	 valid <= 1'b0;
	 valid_toggle <= 1'b0;
      end
      else if (start) begin
	 running <= 1'b1;
	 valid <= 1'b0;
      end
      else if (running) begin
	 valid <= 1'b1;
	 valid_toggle <= !valid_toggle;
      end
   end

   // Store the square input, circulate the result back to the input
   always @ (posedge clk_phase[0]) begin
      if (start) begin
	 sq_out <= sq_in;
      end else begin
         sq_out <= sq_out_comb;
      end
   end

   assign cur_sq_in = sq_out;

   //----------------------------------------------------------------------
   // Montgomery modular square and reduction
   // Using the notation from Koc, Acar, Kaliski 1996
   // and https://en.wikipedia.org/wiki/Montgomery_modular_multiplication

   logic [MOD_LEN*2-1:0]   	t, t_reg, t_comb;
   logic [R_MSB-1:0] 		tMODr, m, m_reg, m_comb;
   logic [MOD_LEN-1+R_MSB:0] 	u;

   // 1024-bit square -> 2048-bit result
   (* keep_hierarchy = "yes" *) 
   square_wide_51s square
     (
      .x(cur_sq_in),
      .square(t_comb)
      );

   // lower half feeds mult1
   always_ff @ (posedge clk_phase[5])
     t_reg[R_MSB-1:0] <= t_comb[R_MSB-1:0];
   // upper half feeds only mult2 so has more time
   always_ff @ (posedge clk_phase[8])
     t_reg[MOD_LEN*2-1:R_MSB] <= t_comb[MOD_LEN*2-1:R_MSB];

   assign t = bypass ? t_comb : t_reg;

   // lower 1026-bit (mod R)
   assign tMODr = t[R_MSB-1:0];

   // 1026-bit multiply by 1026-bit constant -> 2052-bit result
   // but keep only lower 1026-bit (mod R)
   (* keep_hierarchy = "yes" *) 
   mult_1026x1026 #(
      .INPUT_WIDTH(R_MSB),
      .OUTPUT_WIDTH(R_MSB)
   )
   mult1
   (
      .x(tMODr),
      .y(n_prime),
      .accum_in({R_MSB{1'b0}}),
      .p(m_comb)
      );

   always_ff @ (posedge clk_phase[10])
     m_reg <= m_comb;

   assign m = bypass ? m_comb : m_reg;

   // 1026-bit multiply by 1024-bit constant -> 2050-bit result
   // 2050-bit sum from adding 2050-bit and 2048-bit
   (* keep_hierarchy = "yes" *) 
   mult_1026x1026 #(
      .INPUT_WIDTH(R_MSB),
      .OUTPUT_WIDTH(MOD_LEN+R_MSB)
   )
   mult2
   (
      .x(m),
      .y({2'b0,n}),
      .accum_in({2'b0,t}),
      .p(u)	// u = mXn + t
      );

   // note bottom 1026 bits are guaranteed to be zero
   // perhaps some optimization possible there

   // throw away bottom 1026 bits (divide by R)
   assign sq_out_comb = u[MOD_LEN-1+R_MSB:R_MSB];

   //----------------------------------------------------------------------
   // functions used to calculate Montgomery constants
   
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

endmodule
