/*******************************************************************************
  Copyright 2019 Kurt Baty

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

//
// square_wide_51s
//
//  10/20/2019
//
//  by Kurt Baty
//

`include "msuconfig.vh"

module square_wide_51s
   (
     input  logic [1024-1  :0] x,
     output logic [1024*2-1:0] square
   );

   localparam NUM_MULTS = 20;
   logic [8-1:0]      term_8w;
   logic [29-1:0]     term_29w     [NUM_MULTS];
   logic [30-1:0]     term_30w     [NUM_MULTS];
   logic [34-1:0]     term_34w     [NUM_MULTS][NUM_MULTS];
   logic [51-1:0]     term_51w     [NUM_MULTS][NUM_MULTS];
   logic [68-1:0]     term_68w     [NUM_MULTS][NUM_MULTS];
   logic [102-1:0]    term_102w    [NUM_MULTS][NUM_MULTS];
   logic [1024*2-1:0] terms_input  [52];
   logic [1024*2-1:0] terms_packed [52];
   logic [1024*2-1:0] terms_mid1   [27];
   logic [1024*2-1:0] terms_mid2   [14];
   logic [1024*2-1:0] terms_mid3   [8];
   logic [1024*2-1:0] terms_mid4   [5];
   logic [1024*2-1:0] terms_mid5   [3];
   logic [1024*2-1:0] terms6_out   [2];
   logic [1024*2-1:0] two_rail_out [2];

   genvar    i,j,k,m;
   integer   zero_ptr;
   integer   bt; // bit is a key word
   integer   term,packed_term;

   generate
      begin : multipliers
         for (i=0;i<NUM_MULTS;i=i+1) begin : squares
            square_51 sq_51_inst (
               .x(x[(51*i+4)+:51]),
               .term_34w( term_34w[0][i]),
               .term_68w( term_68w[0][i]),
               .term_102w(term_102w[0][i])
            );
            assign term_51w[0][i] = 51'b0;
         end

         for (j=1;j<NUM_MULTS;j=j+1) begin : mults
            for (k=0;k<(NUM_MULTS-j);k=k+1) begin : loop_k
               multiply_51x51 mult_51x51_inst(
                  .a(x[(51*(j+k)+4)+:51]),
                  .b(x[(51*k+4)+:51]),
                  .term_34w( term_34w[j][k]),
                  .term_51w( term_51w[j][k]),
                  .term_68w( term_68w[j][k]),
                  .term_102w(term_102w[j][k])
               );
            end
         end

         for (m=0;m<NUM_MULTS;m=m+1) begin : edge_51x4
            logic discard;
            mult_26x4 mult_26x4_inst0 (
               .x({x[51*m+4+:25],1'b0}),
               .y(x[3:0]),
               .p({term_29w[m],discard})
            );
            mult_26x4 mult_26x4_inst1 (
               .x(x[51*m+25+4+:26]),
               .y(x[3:0]),
               .p(term_30w[m])
            );
         end

      end
   endgenerate

   mult_4x4 mult_4x4_inst (
      .x(x[3:0]),
      .y(x[3:0]),
      .p(term_8w)
   );


   // pack the first two diagonals in to 5 terms
   assign terms_input[0]
      = {term_102w[0][19],term_102w[0][18],term_102w[0][17],term_102w[0][16],
         term_102w[0][15],term_102w[0][14],term_102w[0][13],term_102w[0][12],
         term_102w[0][11],term_102w[0][10],term_102w[0][ 9],term_102w[0][ 8],
         term_102w[0][ 7],term_102w[0][ 6],term_102w[0][ 5],term_102w[0][ 4],
         term_102w[0][ 3],term_102w[0][ 2],term_102w[0][ 1],term_102w[0][ 0],
         term_8w};
   localparam [1024*2-1:0] EN00 = {1024*2{1'b1}};

   assign terms_input[1]
      = {term_68w[0][19],term_34w[1][18],term_68w[0][18],term_34w[1][17],
         term_68w[0][17],term_34w[1][16],term_68w[0][16],term_34w[1][15],
         term_68w[0][15],term_34w[1][14],term_68w[0][14],term_34w[1][13],
         term_68w[0][13],term_34w[1][12],term_68w[0][12],term_34w[1][11],
         term_68w[0][11],term_34w[1][10],term_68w[0][10],term_34w[1][ 9],
         term_68w[0][ 9],term_34w[1][ 8],term_68w[0][ 8],term_34w[1][ 7],
         term_68w[0][ 7],term_34w[1][ 6],term_68w[0][ 6],term_34w[1][ 5],
         term_68w[0][ 5],term_34w[1][ 4],term_68w[0][ 4],term_34w[1][ 3],
         term_68w[0][ 3],term_34w[1][ 2],term_68w[0][ 2],term_34w[1][ 1],
         term_68w[0][ 1],term_34w[1][ 0],term_68w[0][ 0],
         17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN01 = {{(20*68+19*34){1'b1}},{(17+8+1){1'b0}}};

   assign terms_input[2]
      = {term_51w[0][19],term_51w[1][18],term_51w[0][18],term_51w[1][17],
         term_51w[0][17],term_51w[1][16],term_51w[0][16],term_51w[1][15],
         term_51w[0][15],term_51w[1][14],term_51w[0][14],term_51w[1][13],
         term_51w[0][13],term_51w[1][12],term_51w[0][12],term_51w[1][11],
         term_51w[0][11],term_51w[1][10],term_51w[0][10],term_51w[1][ 9],
         term_51w[0][ 9],term_51w[1][ 8],term_51w[0][ 8],term_51w[1][ 7],
         term_51w[0][ 7],term_51w[1][ 6],term_51w[0][ 6],term_51w[1][ 5],
         term_51w[0][ 5],term_51w[1][ 4],term_51w[0][ 4],term_51w[1][ 3],
         term_51w[0][ 3],term_51w[1][ 2],term_51w[0][ 2],term_51w[1][ 1],
         term_51w[0][ 1],term_51w[1][ 0],term_51w[0][ 0],
         25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN02 = {{19{{51{1'b1}},51'b0}},{(25+8+1){1'b0}}};

   assign terms_input[3]
      = {term_34w[0][19],term_68w[1][18],term_34w[0][18],term_68w[1][17],
         term_34w[0][17],term_68w[1][16],term_34w[0][16],term_68w[1][15],
         term_34w[0][15],term_68w[1][14],term_34w[0][14],term_68w[1][13],
         term_34w[0][13],term_68w[1][12],term_34w[0][12],term_68w[1][11],
         term_34w[0][11],term_68w[1][10],term_34w[0][10],term_68w[1][ 9],
         term_34w[0][ 9],term_68w[1][ 8],term_34w[0][ 8],term_68w[1][ 7],
         term_34w[0][ 7],term_68w[1][ 6],term_34w[0][ 6],term_68w[1][ 5],
         term_34w[0][ 5],term_68w[1][ 4],term_34w[0][ 4],term_68w[1][ 3],
         term_34w[0][ 3],term_68w[1][ 2],term_34w[0][ 2],term_68w[1][ 1],
         term_34w[0][ 1],term_68w[1][ 0],term_34w[0][ 0],
         34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN03 = {{(20*34+19*68){1'b1}},{(34+8+1){1'b0}}};

   assign terms_input[4]
      = {                 term_102w[1][18],term_102w[1][17],term_102w[1][16],
         term_102w[1][15],term_102w[1][14],term_102w[1][13],term_102w[1][12],
         term_102w[1][11],term_102w[1][10],term_102w[1][ 9],term_102w[1][ 8],
         term_102w[1][ 7],term_102w[1][ 6],term_102w[1][ 5],term_102w[1][ 4],
         term_102w[1][ 3],term_102w[1][ 2],term_102w[1][ 1],term_102w[1][ 0],
         51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN04 = {{(19*102){1'b1}},{(51+8+1){1'b0}}};


   // pack the second two diagonals in to 5 terms
   assign terms_input[5]
      = {                                  term_102w[2][17],term_102w[2][16],
         term_102w[2][15],term_102w[2][14],term_102w[2][13],term_102w[2][12],
         term_102w[2][11],term_102w[2][10],term_102w[2][ 9],term_102w[2][ 8],
         term_102w[2][ 7],term_102w[2][ 6],term_102w[2][ 5],term_102w[2][ 4],
         term_102w[2][ 3],term_102w[2][ 2],term_102w[2][ 1],term_102w[2][ 0],
         102'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN05 = {{(18*102){1'b1}},{(102+8+1){1'b0}}};

   assign terms_input[6]
      = {term_68w[2][17],term_34w[3][16],term_68w[2][16],term_34w[3][15],
         term_68w[2][15],term_34w[3][14],term_68w[2][14],term_34w[3][13],
         term_68w[2][13],term_34w[3][12],term_68w[2][12],term_34w[3][11],
         term_68w[2][11],term_34w[3][10],term_68w[2][10],term_34w[3][ 9],
         term_68w[2][ 9],term_34w[3][ 8],term_68w[2][ 8],term_34w[3][ 7],
         term_68w[2][ 7],term_34w[3][ 6],term_68w[2][ 6],term_34w[3][ 5],
         term_68w[2][ 5],term_34w[3][ 4],term_68w[2][ 4],term_34w[3][ 3],
         term_68w[2][ 3],term_34w[3][ 2],term_68w[2][ 2],term_34w[3][ 1],
         term_68w[2][ 1],term_34w[3][ 0],term_68w[2][ 0],
         102'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN06 = {{(18*68+17*34){1'b1}},{(102+17+8+1){1'b0}}};

   assign terms_input[7]
      = {term_51w[2][17],term_51w[3][16],term_51w[2][16],term_51w[3][15],
         term_51w[2][15],term_51w[3][14],term_51w[2][14],term_51w[3][13],
         term_51w[2][13],term_51w[3][12],term_51w[2][12],term_51w[3][11],
         term_51w[2][11],term_51w[3][10],term_51w[2][10],term_51w[3][ 9],
         term_51w[2][ 9],term_51w[3][ 8],term_51w[2][ 8],term_51w[3][ 7],
         term_51w[2][ 7],term_51w[3][ 6],term_51w[2][ 6],term_51w[3][ 5],
         term_51w[2][ 5],term_51w[3][ 4],term_51w[2][ 4],term_51w[3][ 3],
         term_51w[2][ 3],term_51w[3][ 2],term_51w[2][ 2],term_51w[3][ 1],
         term_51w[2][ 1],term_51w[3][ 0],term_51w[2][ 0],
         102'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN07 = {{(18+17)*51{1'b1}},{(102+25+8+1){1'b0}}};

   assign terms_input[8]
      = {term_34w[2][17],term_68w[3][16],term_34w[2][16],term_68w[3][15],
         term_34w[2][15],term_68w[3][14],term_34w[2][14],term_68w[3][13],
         term_34w[2][13],term_68w[3][12],term_34w[2][12],term_68w[3][11],
         term_34w[2][11],term_68w[3][10],term_34w[2][10],term_68w[3][ 9],
         term_34w[2][ 9],term_68w[3][ 8],term_34w[2][ 8],term_68w[3][ 7],
         term_34w[2][ 7],term_68w[3][ 6],term_34w[2][ 6],term_68w[3][ 5],
         term_34w[2][ 5],term_68w[3][ 4],term_34w[2][ 4],term_68w[3][ 3],
         term_34w[2][ 3],term_68w[3][ 2],term_34w[2][ 2],term_68w[3][ 1],
         term_34w[2][ 1],term_68w[3][ 0],term_34w[2][ 0],
         102'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN08 = {{(18*34+17*68){1'b1}},{(102+34+8+1){1'b0}}};

   assign terms_input[9]
      = {                                                   term_102w[3][16],
         term_102w[3][15],term_102w[3][14],term_102w[3][13],term_102w[3][12],
         term_102w[3][11],term_102w[3][10],term_102w[3][ 9],term_102w[3][ 8],
         term_102w[3][ 7],term_102w[3][ 6],term_102w[3][ 5],term_102w[3][ 4],
         term_102w[3][ 3],term_102w[3][ 2],term_102w[3][ 1],term_102w[3][ 0],
         102'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN09 = {{(17*102){1'b1}},{(102+51+8+1){1'b0}}};


   // pack the third two diagonals in to 5 terms
   assign terms_input[10]
      = {term_102w[4][15],term_102w[4][14],term_102w[4][13],term_102w[4][12],
         term_102w[4][11],term_102w[4][10],term_102w[4][ 9],term_102w[4][ 8],
         term_102w[4][ 7],term_102w[4][ 6],term_102w[4][ 5],term_102w[4][ 4],
         term_102w[4][ 3],term_102w[4][ 2],term_102w[4][ 1],term_102w[4][ 0],
         204'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN10 = {{(16*102){1'b1}},{(204+8+1){1'b0}}};

   assign terms_input[11]
      = {term_68w[4][15],term_34w[5][14],term_68w[4][14],term_34w[5][13],
         term_68w[4][13],term_34w[5][12],term_68w[4][12],term_34w[5][11],
         term_68w[4][11],term_34w[5][10],term_68w[4][10],term_34w[5][ 9],
         term_68w[4][ 9],term_34w[5][ 8],term_68w[4][ 8],term_34w[5][ 7],
         term_68w[4][ 7],term_34w[5][ 6],term_68w[4][ 6],term_34w[5][ 5],
         term_68w[4][ 5],term_34w[5][ 4],term_68w[4][ 4],term_34w[5][ 3],
         term_68w[4][ 3],term_34w[5][ 2],term_68w[4][ 2],term_34w[5][ 1],
         term_68w[4][ 1],term_34w[5][ 0],term_68w[4][ 0],
         204'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN11 = {{(16*68+15*34){1'b1}},{(204+17+8+1){1'b0}}};

   assign terms_input[12]
      = {term_51w[4][15],term_51w[5][14],term_51w[4][14],term_51w[5][13],
         term_51w[4][13],term_51w[5][12],term_51w[4][12],term_51w[5][11],
         term_51w[4][11],term_51w[5][10],term_51w[4][10],term_51w[5][ 9],
         term_51w[4][ 9],term_51w[5][ 8],term_51w[4][ 8],term_51w[5][ 7],
         term_51w[4][ 7],term_51w[5][ 6],term_51w[4][ 6],term_51w[5][ 5],
         term_51w[4][ 5],term_51w[5][ 4],term_51w[4][ 4],term_51w[5][ 3],
         term_51w[4][ 3],term_51w[5][ 2],term_51w[4][ 2],term_51w[5][ 1],
         term_51w[4][ 1],term_51w[5][ 0],term_51w[4][ 0],
         204'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN12 = {{(16+15)*51{1'b1}},{(204+25+8+1){1'b0}}};

   assign terms_input[13]
      = {term_34w[4][15],term_68w[5][14],term_34w[4][14],term_68w[5][13],
         term_34w[4][13],term_68w[5][12],term_34w[4][12],term_68w[5][11],
         term_34w[4][11],term_68w[5][10],term_34w[4][10],term_68w[5][ 9],
         term_34w[4][ 9],term_68w[5][ 8],term_34w[4][ 8],term_68w[5][ 7],
         term_34w[4][ 7],term_68w[5][ 6],term_34w[4][ 6],term_68w[5][ 5],
         term_34w[4][ 5],term_68w[5][ 4],term_34w[4][ 4],term_68w[5][ 3],
         term_34w[4][ 3],term_68w[5][ 2],term_34w[4][ 2],term_68w[5][ 1],
         term_34w[4][ 1],term_68w[5][ 0],term_34w[4][ 0],
         204'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN13 = {{(16*34+15*68){1'b1}},{(204+34+8+1){1'b0}}};

   assign terms_input[14]
      = {                 term_102w[5][14],term_102w[5][13],term_102w[5][12], 
         term_102w[5][11],term_102w[5][10],term_102w[5][ 9],term_102w[5][ 8],
         term_102w[5][ 7],term_102w[5][ 6],term_102w[5][ 5],term_102w[5][ 4],
         term_102w[5][ 3],term_102w[5][ 2],term_102w[5][ 1],term_102w[5][ 0],
         204'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN14 = {{(15*102){1'b1}},{(204+51+8+1){1'b0}}};


   // pack the forth two diagonals in to 5 terms
   assign terms_input[15]
      = {                                  term_102w[6][13],term_102w[6][12],
         term_102w[6][11],term_102w[6][10],term_102w[6][ 9],term_102w[6][ 8],
         term_102w[6][ 7],term_102w[6][ 6],term_102w[6][ 5],term_102w[6][ 4],
         term_102w[6][ 3],term_102w[6][ 2],term_102w[6][ 1],term_102w[6][ 0],
         306'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN15 = {{(14*102){1'b1}},{(306+8+1){1'b0}}};

   assign terms_input[16]
      = {term_68w[6][13],term_34w[7][12],term_68w[6][12],term_34w[7][11],
         term_68w[6][11],term_34w[7][10],term_68w[6][10],term_34w[7][ 9],
         term_68w[6][ 9],term_34w[7][ 8],term_68w[6][ 8],term_34w[7][ 7],
         term_68w[6][ 7],term_34w[7][ 6],term_68w[6][ 6],term_34w[7][ 5],
         term_68w[6][ 5],term_34w[7][ 4],term_68w[6][ 4],term_34w[7][ 3],
         term_68w[6][ 3],term_34w[7][ 2],term_68w[6][ 2],term_34w[7][ 1],
         term_68w[6][ 1],term_34w[7][ 0],term_68w[6][ 0],
         306'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN16 = {{(14*68+13*34){1'b1}},{(306+17+8+1){1'b0}}};

   assign terms_input[17]
      = {term_51w[6][13],term_51w[7][12],term_51w[6][12],term_51w[7][11],
         term_51w[6][11],term_51w[7][10],term_51w[6][10],term_51w[7][ 9],
         term_51w[6][ 9],term_51w[7][ 8],term_51w[6][ 8],term_51w[7][ 7],
         term_51w[6][ 7],term_51w[7][ 6],term_51w[6][ 6],term_51w[7][ 5],
         term_51w[6][ 5],term_51w[7][ 4],term_51w[6][ 4],term_51w[7][ 3],
         term_51w[6][ 3],term_51w[7][ 2],term_51w[6][ 2],term_51w[7][ 1],
         term_51w[6][ 1],term_51w[7][ 0],term_51w[6][ 0],
         306'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN17 = {{(14+13)*51{1'b1}},{(306+25+8+1){1'b0}}};

   assign terms_input[18]
      = {term_34w[6][13],term_68w[7][12],term_34w[6][12],term_68w[7][11],
         term_34w[6][11],term_68w[7][10],term_34w[6][10],term_68w[7][ 9],
         term_34w[6][ 9],term_68w[7][ 8],term_34w[6][ 8],term_68w[7][ 7],
         term_34w[6][ 7],term_68w[7][ 6],term_34w[6][ 6],term_68w[7][ 5],
         term_34w[6][ 5],term_68w[7][ 4],term_34w[6][ 4],term_68w[7][ 3],
         term_34w[6][ 3],term_68w[7][ 2],term_34w[6][ 2],term_68w[7][ 1],
         term_34w[6][ 1],term_68w[7][ 0],term_34w[6][ 0],
         306'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN18 = {{(14*34+13*68){1'b1}},{(306+34+8+1){1'b0}}};

   assign terms_input[19]
      = {                                                   term_102w[7][12], 
         term_102w[7][11],term_102w[7][10],term_102w[7][ 9],term_102w[7][ 8],
         term_102w[7][ 7],term_102w[7][ 6],term_102w[7][ 5],term_102w[7][ 4],
         term_102w[7][ 3],term_102w[7][ 2],term_102w[7][ 1],term_102w[7][ 0],
         306'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN19 = {{(13*102){1'b1}},{(306+51+8+1){1'b0}}};


   // pack the fifth two diagonals in to 5 terms
   assign terms_input[20]
      = {term_102w[8][11],term_102w[8][10],term_102w[8][ 9],term_102w[8][ 8],
         term_102w[8][ 7],term_102w[8][ 6],term_102w[8][ 5],term_102w[8][ 4],
         term_102w[8][ 3],term_102w[8][ 2],term_102w[8][ 1],term_102w[8][ 0],
         408'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN20 = {{(12*102){1'b1}},{(408+8+1){1'b0}}};

   assign terms_input[21]
      = {term_68w[8][11],term_34w[9][10],term_68w[8][10],term_34w[9][ 9],
         term_68w[8][ 9],term_34w[9][ 8],term_68w[8][ 8],term_34w[9][ 7],
         term_68w[8][ 7],term_34w[9][ 6],term_68w[8][ 6],term_34w[9][ 5],
         term_68w[8][ 5],term_34w[9][ 4],term_68w[8][ 4],term_34w[9][ 3],
         term_68w[8][ 3],term_34w[9][ 2],term_68w[8][ 2],term_34w[9][ 1],
         term_68w[8][ 1],term_34w[9][ 0],term_68w[8][ 0],
         408'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN21 = {{(12*68+11*34){1'b1}},{(408+17+8+1){1'b0}}};

   assign terms_input[22]
      = {term_51w[8][11],term_51w[9][10],term_51w[8][10],term_51w[9][ 9],
         term_51w[8][ 9],term_51w[9][ 8],term_51w[8][ 8],term_51w[9][ 7],
         term_51w[8][ 7],term_51w[9][ 6],term_51w[8][ 6],term_51w[9][ 5],
         term_51w[8][ 5],term_51w[9][ 4],term_51w[8][ 4],term_51w[9][ 3],
         term_51w[8][ 3],term_51w[9][ 2],term_51w[8][ 2],term_51w[9][ 1],
         term_51w[8][ 1],term_51w[9][ 0],term_51w[8][ 0],
         408'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN22 = {{(12+11)*51{1'b1}},{(408+25+8+1){1'b0}}};

   assign terms_input[23]
      = {term_34w[8][11],term_68w[9][10],term_34w[8][10],term_68w[9][ 9],
         term_34w[8][ 9],term_68w[9][ 8],term_34w[8][ 8],term_68w[9][ 7],
         term_34w[8][ 7],term_68w[9][ 6],term_34w[8][ 6],term_68w[9][ 5],
         term_34w[8][ 5],term_68w[9][ 4],term_34w[8][ 4],term_68w[9][ 3],
         term_34w[8][ 3],term_68w[9][ 2],term_34w[8][ 2],term_68w[9][ 1],
         term_34w[8][ 1],term_68w[9][ 0],term_34w[8][ 0],
         408'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN23 = {{(12*34+11*68){1'b1}},{(408+34+8+1){1'b0}}};

   assign terms_input[24]
      = {                 term_102w[9][10],term_102w[9][ 9],term_102w[9][ 8],
         term_102w[9][ 7],term_102w[9][ 6],term_102w[9][ 5],term_102w[9][ 4],
         term_102w[9][ 3],term_102w[9][ 2],term_102w[9][ 1],term_102w[9][ 0],
         408'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN24 = {{(11*102){1'b1}},{(408+51+8+1){1'b0}}};


   // pack the sixth two diagonals in to 5 terms
   assign terms_input[25]
      = {                                  term_102w[10][9],term_102w[10][8],
         term_102w[10][7],term_102w[10][6],term_102w[10][5],term_102w[10][4],
         term_102w[10][3],term_102w[10][2],term_102w[10][1],term_102w[10][0],
         510'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN25 = {{(10*102){1'b1}},{(510+8+1){1'b0}}};

   assign terms_input[26]
      = {term_68w[10][9],term_34w[11][8],term_68w[10][8],term_34w[11][7],
         term_68w[10][7],term_34w[11][6],term_68w[10][6],term_34w[11][5],
         term_68w[10][5],term_34w[11][4],term_68w[10][4],term_34w[11][3],
         term_68w[10][3],term_34w[11][2],term_68w[10][2],term_34w[11][1],
         term_68w[10][1],term_34w[11][0],term_68w[10][0],
         510'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN26 = {{(10*68+9*34){1'b1}},{(510+17+8+1){1'b0}}};

   assign terms_input[27]
      = {term_51w[10][9],term_51w[11][8],term_51w[10][8],term_51w[11][7],
         term_51w[10][7],term_51w[11][6],term_51w[10][6],term_51w[11][5],
         term_51w[10][5],term_51w[11][4],term_51w[10][4],term_51w[11][3],
         term_51w[10][3],term_51w[11][2],term_51w[10][2],term_51w[11][1],
         term_51w[10][1],term_51w[11][0],term_51w[10][0],
         510'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN27 = {{(10+9)*51{1'b1}},{(510+25+8+1){1'b0}}};

   assign terms_input[28]
      = {term_34w[10][9],term_68w[11][8],term_34w[10][8],term_68w[11][7],
         term_34w[10][7],term_68w[11][6],term_34w[10][6],term_68w[11][5],
         term_34w[10][5],term_68w[11][4],term_34w[10][4],term_68w[11][3],
         term_34w[10][3],term_68w[11][2],term_34w[10][2],term_68w[11][1],
         term_34w[10][1],term_68w[11][0],term_34w[10][0],
         510'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN28 = {{(10*34+9*68){1'b1}},{(510+34+8+1){1'b0}}};

   assign terms_input[29]
      = {                                                   term_102w[11][8],
         term_102w[11][7],term_102w[11][6],term_102w[11][5],term_102w[11][4],
         term_102w[11][3],term_102w[11][2],term_102w[11][1],term_102w[11][0],
         510'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN29 = {{(9*102){1'b1}},{(510+51+8+1){1'b0}}};


   // pack the seventh two diagonals in to 5 terms
   assign terms_input[30]
      = {term_102w[12][7],term_102w[12][6],term_102w[12][5],term_102w[12][4],
         term_102w[12][3],term_102w[12][2],term_102w[12][1],term_102w[12][0],
         612'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN30 = {{(8*102){1'b1}},{(612+8+1){1'b0}}};

   assign terms_input[31]
      = {term_68w[12][7],term_34w[13][6],term_68w[12][6],term_34w[13][5],
         term_68w[12][5],term_34w[13][4],term_68w[12][4],term_34w[13][3],
         term_68w[12][3],term_34w[13][2],term_68w[12][2],term_34w[13][1],
         term_68w[12][1],term_34w[13][0],term_68w[12][0],
         612'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN31 = {{(8*68+7*34){1'b1}},{(612+17+8+1){1'b0}}};

   assign terms_input[32]
      = {term_51w[12][7],term_51w[13][6],term_51w[12][6],term_51w[13][5],
         term_51w[12][5],term_51w[13][4],term_51w[12][4],term_51w[13][3],
         term_51w[12][3],term_51w[13][2],term_51w[12][2],term_51w[13][1],
         term_51w[12][1],term_51w[13][0],term_51w[12][0],
         612'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN32 = {{(8+7)*51{1'b1}},{(612+25+8+1){1'b0}}};

   assign terms_input[33]
      = {term_34w[12][7],term_68w[13][6],term_34w[12][6],term_68w[13][5],
         term_34w[12][5],term_68w[13][4],term_34w[12][4],term_68w[13][3],
         term_34w[12][3],term_68w[13][2],term_34w[12][2],term_68w[13][1],
         term_34w[12][1],term_68w[13][0],term_34w[12][0],
         612'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN33 = {{(8*34+7*68){1'b1}},{(612+34+8+1){1'b0}}};

   assign terms_input[34]
      = {                 term_102w[13][6],term_102w[13][5],term_102w[13][4],
         term_102w[13][3],term_102w[13][2],term_102w[13][1],term_102w[13][0],
         612'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN34 = {{(7*102){1'b1}},{(612+51+8+1){1'b0}}};


   // pack the eighth two diagonals in to 5 terms
   assign terms_input[35]
      = {                                  term_102w[14][5],term_102w[14][4],
         term_102w[14][3],term_102w[14][2],term_102w[14][1],term_102w[14][0],
         714'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN35 = {{(6*102){1'b1}},{(714+8+1){1'b0}}};

   assign terms_input[36]
      = {term_68w[14][5],term_34w[15][4],term_68w[14][4],term_34w[15][3],
         term_68w[14][3],term_34w[15][2],term_68w[14][2],term_34w[15][1],
         term_68w[14][1],term_34w[15][0],term_68w[14][0],
         714'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN36 = {{(6*68+5*34){1'b1}},{(714+17+8+1){1'b0}}};

   assign terms_input[37]
      = {term_51w[14][5],term_51w[15][4],term_51w[14][4],term_51w[15][3],
         term_51w[14][3],term_51w[15][2],term_51w[14][2],term_51w[15][1],
         term_51w[14][1],term_51w[15][0],term_51w[14][0],
         714'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN37 = {{(6+5)*51{1'b1}},{(714+25+8+1){1'b0}}};

   assign terms_input[38]
      = {term_34w[14][5],term_68w[15][4],term_34w[14][4],term_68w[15][3],
         term_34w[14][3],term_68w[15][2],term_34w[14][2],term_68w[15][1],
         term_34w[14][1],term_68w[15][0],term_34w[14][0],
         714'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN38 = {{(6*34+5*68){1'b1}},{(714+34+8+1){1'b0}}};

   assign terms_input[39]
      = {                                                   term_102w[15][4],
         term_102w[15][3],term_102w[15][2],term_102w[15][1],term_102w[15][0],
         714'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN39 = {{(5*102){1'b1}},{(714+51+8+1){1'b0}}};


   // pack the ninth two diagonals in to 5 terms
   assign terms_input[40]
      = {term_102w[16][3],term_102w[16][2],term_102w[16][1],term_102w[16][0],
         816'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN40 = {{(4*102){1'b1}},{(816+8+1){1'b0}}};

   assign terms_input[41]
      = {term_68w[16][3],term_34w[17][2],term_68w[16][2],term_34w[17][1],
         term_68w[16][1],term_34w[17][0],term_68w[16][0],
         816'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN41 = {{(4*68+3*34){1'b1}},{(816+17+8+1){1'b0}}};

   assign terms_input[42]
      = {term_51w[16][3],term_51w[17][2],term_51w[16][2],term_51w[17][1],
         term_51w[16][1],term_51w[17][0],term_51w[16][0],
         816'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN42 = {{(4+3)*51{1'b1}},{(816+25+8+1){1'b0}}};

   assign terms_input[43]
      = {term_34w[16][3],term_68w[17][2],term_34w[16][2],term_68w[17][1],
         term_34w[16][1],term_68w[17][0],term_34w[16][0],
         816'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN43 = {{(4*34+3*68){1'b1}},{(816+34+8+1){1'b0}}};

   assign terms_input[44]
      = {                term_102w[17][2],term_102w[17][1],term_102w[17][0],
         816'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN44 = {{(3*102){1'b1}},{(816+51+8+1){1'b0}}};


   // pack the tenth (and final) two diagonals in to 5 terms
   assign terms_input[45]
      = {                term_102w[18][1],term_102w[18][0],
         918'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN45 = {{(2*102){1'b1}},{(918+8+1){1'b0}}};

   assign terms_input[46]
      = {term_68w[18][1],term_34w[19][0],term_68w[18][0],
         918'b0,17'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN46 = {{(2*68+1*34){1'b1}},{(918+17+8+1){1'b0}}};

   assign terms_input[47]
      = {term_51w[18][1],term_51w[19][0],term_51w[18][0],
         918'b0,25'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN47 = {{(2+1)*51{1'b1}},{(918+25+8+1){1'b0}}};

   assign terms_input[48]
      = {term_34w[18][1],term_68w[19][0],term_34w[18][0],
         918'b0,34'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN48 = {{(2*34+1*68){1'b1}},{(918+34+8+1){1'b0}}};

   assign terms_input[49]
      = {                                term_102w[19][0],
         918'b0,51'b0,8'b0,1'b0};
   localparam [1024*2-1:0] EN49 = {{(1*102){1'b1}},{(918+51+8+1){1'b0}}};


   // place the 4 bt wide edge multipliers in the last two terms
   assign terms_input[50]
      = {term_30w[19],21'b0,term_30w[18],21'b0,term_30w[17],21'b0,term_30w[16],21'b0,
         term_30w[15],21'b0,term_30w[14],21'b0,term_30w[13],21'b0,term_30w[12],21'b0,
         term_30w[11],21'b0,term_30w[10],21'b0,term_30w[ 9],21'b0,term_30w[ 8],21'b0,
         term_30w[ 7],21'b0,term_30w[ 6],21'b0,term_30w[ 5],21'b0,term_30w[ 4],21'b0,
         term_30w[ 3],21'b0,term_30w[ 2],21'b0,term_30w[ 1],21'b0,term_30w[ 0],21'b0,
         8'b0,1'b0};
   localparam [1024*2-1:0] EN50 = {{20{{30{1'b1}},21'b0}},{(8+1){1'b0}}};

   assign terms_input[51]
      = {term_29w[19],22'b0,term_29w[18],22'b0,term_29w[17],22'b0,term_29w[16],22'b0,
         term_29w[15],22'b0,term_29w[14],22'b0,term_29w[13],22'b0,term_29w[12],22'b0,
         term_29w[11],22'b0,term_29w[10],22'b0,term_29w[ 9],22'b0,term_29w[ 8],22'b0,
         term_29w[ 7],22'b0,term_29w[ 6],22'b0,term_29w[ 5],22'b0,term_29w[ 4],22'b0,
         term_29w[ 3],22'b0,term_29w[ 2],22'b0,term_29w[ 1],22'b0,term_29w[ 0],
         4'b0,1'b0};
   localparam [1024*2-1:0] EN51 = {{20{22'b0,{29{1'b1}}}},{(4+1){1'b0}}};

`ifdef FASTSIM
   initial $display("####### FASTSIM enabled in %m");
   assign square = x * x;
`else


   logic [52-1:0] virtical_enables;
   always_comb begin
      for (zero_ptr=0;zero_ptr<52;zero_ptr++) begin
         terms_packed[zero_ptr] = 'b0;
      end
      for (bt=0;bt<1024*2;bt++) begin
       
         virtical_enables =
          {EN51[bt],EN50[bt],
           EN49[bt],EN48[bt],EN47[bt],EN46[bt],EN45[bt],EN44[bt],EN43[bt],EN42[bt],EN41[bt],EN40[bt],
           EN39[bt],EN38[bt],EN37[bt],EN36[bt],EN35[bt],EN34[bt],EN33[bt],EN32[bt],EN31[bt],EN30[bt],
           EN29[bt],EN28[bt],EN27[bt],EN26[bt],EN25[bt],EN24[bt],EN23[bt],EN22[bt],EN21[bt],EN20[bt],
           EN19[bt],EN18[bt],EN17[bt],EN16[bt],EN15[bt],EN14[bt],EN13[bt],EN12[bt],EN11[bt],EN10[bt],
           EN09[bt],EN08[bt],EN07[bt],EN06[bt],EN05[bt],EN04[bt],EN03[bt],EN02[bt],EN01[bt],EN00[bt]};
         packed_term = 0;

         for (term=0;term<52;term++) begin
            if(virtical_enables[term]) begin
               terms_packed[packed_term][bt] = terms_input[term][bt];
               packed_term += 1;             
            end
         end
      end
   end


   faster_carry_save_adder_tree_level #(
      .NUM_ELEMENTS(52),
      .BIT_LEN(1024*2)
   )
   fcsatl_1 (
//      .terms(terms_input),
      .terms(terms_packed),
      .results(terms_mid1)
   );

   faster_carry_save_adder_tree_level #(
      .NUM_ELEMENTS(27),
      .BIT_LEN(1024*2)
   )
   fcsatl_2 (
      .terms(terms_mid1),
      .results(terms_mid2)
   );

   faster_carry_save_adder_tree_level #(
      .NUM_ELEMENTS(14),
      .BIT_LEN(1024*2)
   )
   fcsatl_3 (
      .terms(terms_mid2),
      .results(terms_mid3)
   );

   faster_carry_save_adder_tree_level #(
      .NUM_ELEMENTS(8),
      .BIT_LEN(1024*2)
   )
   fcsatl_4 (
      .terms(terms_mid3),
      .results(terms_mid4)
   );

   faster_carry_save_adder_tree_level #(
      .NUM_ELEMENTS(5),
      .BIT_LEN(1024*2)
   )
   fcsatl_5 (
      .terms(terms_mid4),
      .results(terms_mid5)
   );

   carry_save_adder #(.BIT_LEN(1024*2))
     csa_inst (
       .A(   terms_mid5[0]),
       .B(   terms_mid5[1]),
       .Cin( terms_mid5[2]),
       .Cout(terms6_out[1]),
       .S(   terms6_out[0])
   );

   assign two_rail_out[0] =  terms6_out[0];
   assign two_rail_out[1] = {terms6_out[1],1'b0};

   faster_full_adder_wide #(
     .WIDTH(1024*2)
   )
   final_fa (
      .a(two_rail_out[1]),
      .b(two_rail_out[0]),
      .s(square)
   );

`endif

endmodule

