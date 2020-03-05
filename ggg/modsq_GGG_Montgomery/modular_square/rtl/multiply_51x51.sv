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
// multiply_51x51
//
//  10/19/2019
//
//  by Kurt Baty
//

module multiply_51x51
   (
     input  logic [51-1  :0] a,b,
     output logic [17*2-1:0] term_34w,
     output logic [17*3-1:0] term_51w,
     output logic [17*4-1:0] term_68w,
     output logic [17*6-1:0] term_102w
   );

   wire  [52-1:0]   x_in;
   wire  [43-1:0]   prod  [6];

   assign x_in = {a,1'b0};

   mult_26x17 mult_c1 (.x(x_in[26+:26]),.y(b[2*17+:17]),.p(prod[5]));
   mult_26x17 mult_b1 (.x(x_in[26+:26]),.y(b[1*17+:17]),.p(prod[4]));
   mult_26x17 mult_a1 (.x(x_in[26+:26]),.y(b[0*17+:17]),.p(prod[3]));
   mult_26x17 mult_c0 (.x(x_in[ 0+:26]),.y(b[2*17+:17]),.p(prod[2]));
   mult_26x17 mult_b0 (.x(x_in[ 0+:26]),.y(b[1*17+:17]),.p(prod[1]));
   mult_26x17 mult_a0 (.x(x_in[ 0+:26]),.y(b[0*17+:17]),.p(prod[0]));

   assign term_34w  = prod[2][34:1];
   assign term_51w  = {prod[2][43-1:35],prod[3]};
   assign term_68w  = {prod[4],prod[0][43-1:18]};
   assign term_102w = {prod[5],prod[1][43-1:1],prod[0][17:1]};

endmodule

