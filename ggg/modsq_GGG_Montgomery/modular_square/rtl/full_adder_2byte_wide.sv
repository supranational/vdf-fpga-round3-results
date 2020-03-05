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
// full_adder_2byte_wide
//
//  11/8/2019
//
//  by Kurt Baty
//

(* keep_hierarchy = "yes" *) 
module full_adder_2byte_wide(
   input   logic [15:0] a,b,
   input   logic        ci,
   output  logic [15:0] s,
   output  logic        co
);

   wire [7:0] co_wide;

   carry8_w_Ps_n_Gs_wrapper c8PsnQs(
      .a(a),
      .b(b),
      .ci(ci),
      .co(co_wide)
   );

   assign co = co_wide[7];

   full_adder_2bit_wide fa2bw_inst0(.a(a[1:0]),  .b(b[1:0]),  .ci(ci),        .s(s[1:0]));
   full_adder_2bit_wide fa2bw_inst1(.a(a[3:2]),  .b(b[3:2]),  .ci(co_wide[0]),.s(s[3:2]));
   full_adder_2bit_wide fa2bw_inst2(.a(a[5:4]),  .b(b[5:4]),  .ci(co_wide[1]),.s(s[5:4]));
   full_adder_2bit_wide fa2bw_inst3(.a(a[7:6]),  .b(b[7:6]),  .ci(co_wide[2]),.s(s[7:6]));
   full_adder_2bit_wide fa2bw_inst4(.a(a[9:8]),  .b(b[9:8]),  .ci(co_wide[3]),.s(s[9:8]));
   full_adder_2bit_wide fa2bw_inst5(.a(a[11:10]),.b(b[11:10]),.ci(co_wide[4]),.s(s[11:10]));
   full_adder_2bit_wide fa2bw_inst6(.a(a[13:12]),.b(b[13:12]),.ci(co_wide[5]),.s(s[13:12]));
   full_adder_2bit_wide fa2bw_inst7(.a(a[15:14]),.b(b[15:14]),.ci(co_wide[6]),.s(s[15:14]));


endmodule

