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
// carry8_w_Ps_n_Gs_wrapper
//
//  11/8/2019
//
//  by Kurt Baty
//

(* keep_hierarchy = "yes" *) 
module carry8_w_Ps_n_Gs_wrapper(a,b,ci,co);
   input   [15:0] a,b;
   input          ci;
   output  [7:0]  co;

   wire    [7:0]  co;

   wire    [7:0] p;
   wire    [7:0] g;
   wire    [7:0] o;


//   assign p[0] = (a[1] ^ b[1]) & (a[0] ^ b[0]);
//   assign g[0] = (a[1] & b[1]) | ((a[1] | b[1]) & a[0] & b[0]);


// LUT6: 6-Bit Look-Up Table
//         UltraScale
// Xilinx HDL Libraries Guide, version 2014.1

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst0
   (
      .O6(p[0]),    //1-bit output: LUT
      .O5(g[0]),    //1-bit output: LUT
      .I0(a[0]),    //1-bit input:  LUT
      .I1(b[0]),    //1-bit input:  LUT
      .I2(a[1]),    //1-bit input:  LUT
      .I3(b[1]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst1
   (
      .O6(p[1]),    //1-bit output: LUT
      .O5(g[1]),    //1-bit output: LUT
      .I0(a[2]),    //1-bit input:  LUT
      .I1(b[2]),    //1-bit input:  LUT
      .I2(a[3]),    //1-bit input:  LUT
      .I3(b[3]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst2
   (
      .O6(p[2]),    //1-bit output: LUT
      .O5(g[2]),    //1-bit output: LUT
      .I0(a[4]),    //1-bit input:  LUT
      .I1(b[4]),    //1-bit input:  LUT
      .I2(a[5]),    //1-bit input:  LUT
      .I3(b[5]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst3
   (
      .O6(p[3]),    //1-bit output: LUT
      .O5(g[3]),    //1-bit output: LUT
      .I0(a[6]),    //1-bit input:  LUT
      .I1(b[6]),    //1-bit input:  LUT
      .I2(a[7]),    //1-bit input:  LUT
      .I3(b[7]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst4
   (
      .O6(p[4]),    //1-bit output: LUT
      .O5(g[4]),    //1-bit output: LUT
      .I0(a[8]),    //1-bit input:  LUT
      .I1(b[8]),    //1-bit input:  LUT
      .I2(a[9]),    //1-bit input:  LUT
      .I3(b[9]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst5
   (
      .O6(p[5]),    //1-bit output: LUT
      .O5(g[5]),    //1-bit output: LUT
      .I0(a[10]),    //1-bit input:  LUT
      .I1(b[10]),    //1-bit input:  LUT
      .I2(a[11]),    //1-bit input:  LUT
      .I3(b[11]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst6
   (
      .O6(p[6]),    //1-bit output: LUT
      .O5(g[6]),    //1-bit output: LUT
      .I0(a[12]),    //1-bit input:  LUT
      .I1(b[12]),    //1-bit input:  LUT
      .I2(a[13]),    //1-bit input:  LUT
      .I3(b[13]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );

   LUT6_2 #(
      .INIT(64'h0660_0660_f880_f880) // Logic function
   )
   LUT6_2_inst7
   (
      .O6(p[7]),    //1-bit output: LUT
      .O5(g[7]),    //1-bit output: LUT
      .I0(a[14]),    //1-bit input:  LUT
      .I1(b[14]),    //1-bit input:  LUT
      .I2(a[15]),    //1-bit input:  LUT
      .I3(b[15]),    //1-bit input:  LUT
      .I4(1'b0),    //1-bit input:  LUT
      .I5(1'b1)     //1-bit input:  LUT
   );


// CARRY8: Fast Carry Logic with Look Ahead
//         UltraScale
// Xilinx HDL Libraries Guide, version 2014.1 

   CARRY8 #(
      .CARRY_TYPE("SINGLE_CY8") // 8-bit or dual 4-bit carry (SINGLE_CY8, DUAL_CY4)
   )
   CARRY8_inst (
      .CO(co),         // 8-bit output: Carry-out
      .O(o),           // 8-bit output: Carry chain XOR data out
      .CI(ci),         // 1-bit input : Lower Carry-In
      .CI_TOP(1'b0),   // 1-bit input : Upper Carry-In
      .DI(g),          // 8-bit input : Carry-MUX data in
      .S(p)            // 8-bit input : Carry-MUX select
   );

// End of CARRY8_inst instantiation


endmodule

