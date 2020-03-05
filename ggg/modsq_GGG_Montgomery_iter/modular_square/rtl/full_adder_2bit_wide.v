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
// full_adder_2bit_wide
//
//  11/8/2019
//
//  by Kurt Baty
//

(* keep_hierarchy = "yes" *) 
module full_adder_2bit_wide(a,b,ci,s);
   input   [1:0] a,b;
   input         ci;
   output  [1:0] s;

   wire    [1:0] s;


//   assign s[0] = a[0] ^ b[0] ^ ci;
//   assign s[1] = a[1] ^ b[1] ^ ((a[0] & b[0]) | (a[0] & ci) | (b[0] & ci));


// LUT6: 6-Bit Look-Up Table
//         UltraScale
// Xilinx HDL Libraries Guide, version 2014.1

   LUT6_2 #(
      .INIT(64'he817_17e8_9696_9696) // Logic function
   )
   LUT6_2_inst0
   (
      .O6(s[1]),    //1-bit output: LUT
      .O5(s[0]),    //1-bit output: LUT
      .I0(ci),      //1-bit input:  LUT
      .I1(a[0]),    //1-bit input:  LUT
      .I2(b[0]),    //1-bit input:  LUT
      .I3(a[1]),    //1-bit input:  LUT
      .I4(b[1]),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );


endmodule

