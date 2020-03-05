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
// faster_full_adder_wide
//
//  11/8/2019
//
//  by Kurt Baty
//

`include "msuconfig.vh"

module faster_full_adder_wide #(
      parameter WIDTH = 1024
   )
   (
      input  logic [WIDTH-1:0] a,b,
      output logic [WIDTH-1:0] s
   );

`ifdef FASTSIM
// This is intended for simulation only to improve compile and run time
   initial $display("####### FASTSIM enabled in %m");
   always_comb begin
      s = a + b;
   end

`else

   localparam NUM_2BYTES = (WIDTH%16 == 0)? WIDTH/16 : WIDTH/16 + 1;
   genvar  i;

   logic [NUM_2BYTES*16-1:0] a_padded,b_padded,s_padded;
   logic [NUM_2BYTES:0]      carries;

   always_comb begin
      a_padded   = a;
      b_padded   = b;
      s          = s_padded;
      carries[0] = 1'b0;
   end

   generate
      for(i=0;i<NUM_2BYTES;i++) begin : fa2bws

         full_adder_2byte_wide inst(
            .a(a_padded[i*16+:16]),
            .b(b_padded[i*16+:16]),
            .ci(carries[i]),
            .s(s_padded[i*16+:16]),
            .co(carries[i+1])
         );

      end
   endgenerate

`endif

endmodule

