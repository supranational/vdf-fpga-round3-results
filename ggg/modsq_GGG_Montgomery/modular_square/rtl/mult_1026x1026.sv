/*******************************************************************************
  Copyright 2020 Steve Golson and Kurt Baty

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

module mult_1026x1026 #(
      parameter INPUT_WIDTH  = 1026,
      parameter OUTPUT_WIDTH = INPUT_WIDTH * 2
   )   
   (
      input  logic [INPUT_WIDTH-1:0]   x,
      input  logic [INPUT_WIDTH-1:0]   y,
      input  logic [OUTPUT_WIDTH-1:0]  accum_in,
      output logic [OUTPUT_WIDTH-1:0]  p
);

`ifdef FASTSIM
   initial $display("####### FASTSIM enabled in %m");
   assign p = (x * y) + accum_in;
`else

   localparam integer NUM_TERMS_MID = (28+33+13)+(40+15);

   logic [61*17-1:0]          in_x1;
   logic [40*26-1:0]          in_x2;
   logic [26+17-1:0]          terms_p1 [61][29];
   logic [26+17-1:0]          terms_p2 [40][16];
   logic [INPUT_WIDTH*2+43:0] terms_mid           [NUM_TERMS_MID];
   logic [OUTPUT_WIDTH-1:0]   terms_compressor_in [NUM_TERMS_MID+1];
   logic [OUTPUT_WIDTH-1:0]   terms_compressor_out            [2];

   genvar    q,r,s,t;
   integer   a,b,c,d,e,f;

   assign in_x1 = x;
   assign in_x2 = x;

   generate
      begin : gens
         for (q=0;q<61;q++) begin : loop_q
            for (r=0;r<29;r++) begin : loop_r
               mult_26x17 mult_inst (
                  .x(y[26*r+:26]),
                  .y(in_x1[17*q+:17]),
                  .p(terms_p1[q][r])
               );
            end
         end
         for (s=0;s<40;s++) begin : loop_s
            for (t=0;t<16;t++) begin : loop_t
               mult_26x17 mult_inst (
                  .x(in_x2[26*s+:26]),
                  .y(y[(17*t+26*29)+:17]),
                  .p(terms_p2[s][t])
               );
            end
         end
      end
   endgenerate


//   logic [26+17-1:0]          terms_00_28;
//   assign                     terms_00_28 = terms_p1[00][28];
//   logic [INPUT_WIDTH*2+43:0] terms_mid_0;
//   assign                     terms_mid_0 = terms_mid[0];

   always_comb begin
      for (a=0;a<NUM_TERMS_MID;a++) begin
         terms_mid[a] = 'b0;
         if (a<15) begin
            for (b=0;b<a+1;b++) begin
               terms_mid[a][(26*(28-a+b))+(17*b)+:(26+17)] = terms_p1[b][28-a+b];
            end
            for (c=0;c<15-a;c++) begin
               terms_mid[a][(26*c)+(17*(46+a+c))+:(26+17)] = terms_p1[46+a+c][c];
            end
         end
         else if (a<28) begin
            for (b=0;b<a+1;b++) begin
               terms_mid[a][(26*(28-a+b))+(17*b)+:(26+17)] = terms_p1[b][28-a+b];
            end
         end
         else if (a<61) begin
            for (b=0;b<29;b++) begin
               terms_mid[a][(26*b)+(17*(a-28+b))+:(26+17)] = terms_p1[a-28+b][b];
            end
         end
         else if (a<28+33+13) begin
            for (b=0;b<29+(60-a);b++) begin
               terms_mid[a][(26*b)+(17*(a-28+b))+:(26+17)] = terms_p1[a-28+b][b];
            end
         end
         else if (a<28+33+13+15) begin
            for (b=0;b<(1+a-(28+33+13));b++) begin
               terms_mid[a][(26*(b+29))+(17*(15-(a-(28+33+13))+b))+:(26+17)] = terms_p2[b][15-(a-(28+33+13))+b];
            end
         end
         else if (a<28+33+13+40) begin
            for (b=0;b<16;b++) begin
               terms_mid[a][(26*(a-(28+33+13+15)+b+29))+(17*b)+:(26+17)] = terms_p2[a-(28+33+13+15)+b][b];
            end
         end
         else if (a<28+33+13+40+15) begin
            for (b=0;b<16+((28+33+13+40-1)-a);b++) begin
               terms_mid[a][(26*(a-(28+33+13+15)+b+29))+(17*b)+:(26+17)] = terms_p2[a-(28+33+13+15)+b][b];
            end
         end
      end

      for (e=0;e<NUM_TERMS_MID;e++) begin
         terms_compressor_in[e] = terms_mid[e][OUTPUT_WIDTH-1:0];
      end
      terms_compressor_in[NUM_TERMS_MID] = accum_in;
      
   end

   compressor_tree_3_to_2 #(
      .NUM_ELEMENTS(NUM_TERMS_MID+1),
      .BIT_LEN(OUTPUT_WIDTH)
   )
   compressor_tree_3_to_2 (
      .terms(terms_compressor_in),
      .C(terms_compressor_out[1]),
      .S(terms_compressor_out[0])
   );

   faster_full_adder_wide #(
     .WIDTH(OUTPUT_WIDTH)
   )
   final_fa (
      .a(terms_compressor_out[1]),
      .b(terms_compressor_out[0]),
      .s(p)
   );


`endif

endmodule
