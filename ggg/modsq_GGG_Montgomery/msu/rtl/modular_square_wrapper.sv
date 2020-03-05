/*******************************************************************************
  Copyright 2019 Eric Pearson
  Copyright 2019 Steve Golson

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

`ifndef MOD_LEN_DEF
`define MOD_LEN_DEF 1024
`endif

module modular_square_wrapper
   #(
     parameter int MOD_LEN               = `MOD_LEN_DEF
    )
   (
    input logic                    clk,
    input logic                    reset,
    input logic                    start,
    input logic                    start_toggle,
    input logic [MOD_LEN-1:0]      sq_in,
    output logic [MOD_LEN-1:0]     sq_out,
    output logic                   valid
   );

   logic mmcm_fb;
   logic [15:0] modsqr_clk_phase;

   logic modsqr_bypass;
   logic modsqr_reset;

   logic modsqr_start_pipe3;
   logic modsqr_start;

   logic valid_pipe3;
   logic modsqr_valid, modsqr_valid_toggle;
      
   modular_square_GGG_Montgomery modsqr(
          .clk_phase          ( modsqr_clk_phase ),
          .reset              ( modsqr_reset ),
          .start              ( modsqr_start ),
          .bypass             ( modsqr_bypass ),
          .sq_in              ( sq_in ),
          .sq_out             ( sq_out ),
          .valid              ( modsqr_valid ),
          .valid_toggle       ( modsqr_valid_toggle )
          );

   //// Reset CDC ////
   (* ASYNC_REG = "TRUE" *) reg modsqr_reset_sync1, modsqr_reset_sync2;
   always_ff @(posedge modsqr_clk_phase[0]) begin
      modsqr_reset_sync1 <= reset;
      modsqr_reset_sync2 <= modsqr_reset_sync1;
   end
   assign modsqr_reset = modsqr_reset_sync2;

   ///// Start CDC ////
   (* ASYNC_REG = "TRUE" *) reg modsqr_start_sync1, modsqr_start_sync2;
   always_ff @(posedge modsqr_clk_phase[0]) begin
      modsqr_start_sync1 <= start_toggle;
      modsqr_start_sync2 <= modsqr_start_sync1;
      modsqr_start_pipe3 <= modsqr_start_sync2;
   end
   assign modsqr_start = modsqr_start_sync2 ^ modsqr_start_pipe3;
   
   ///// Valid CDC //////
   (* ASYNC_REG = "TRUE" *) reg valid_sync1, valid_sync2;
   always_ff @(posedge clk) begin
      valid_sync1 <= modsqr_valid_toggle;
      valid_sync2 <= valid_sync1;
      valid_pipe3 <= valid_sync2;
   end
   assign valid = valid_sync2 ^ valid_pipe3;

   // bypass flop
   // eventually this may be under software control
   // this always drives 1, which causes t and m regs to be bypassed
   // but during synth/impl we can set_case_analysis to 0
   // to reduce the number of timing paths
   (* DONT_TOUCH = "TRUE" *) FDCE #(
      .INIT(1'b1)		// initialize to 1
   ) bypass_reg (
      .Q(modsqr_bypass),
      .C(modsqr_clk_phase[0]),
      .CE(1'b1),		// always enable
      .CLR(1'b0),		// never clear
      .D(1'b1)			// always load 1
   );

   ///// PLL /////////

   MMCME4_BASE #(
		 .CLKIN1_PERIOD    ( 8.000 ),   // 125 MHz
		 .DIVCLK_DIVIDE    (  1    ),   // 125 MHz at input to phase detect
		 .CLKFBOUT_MULT_F  ( 12.75 ),   // 1593.75 MHz VCO
		 .CLKFBOUT_PHASE(0.0),       

		 .CLKOUT0_DIVIDE_F ( 112   ),   // 14.230 MHz = 70.275 ns
		 .CLKOUT0_DUTY_CYCLE(0.50),     // clk_phase[8] @ 35.137 ns
		 .CLKOUT0_PHASE(0.0),        

		 .CLKOUT1_DIVIDE   ( 112   ),   // 14.230 MHz = 70.275 ns
		 .CLKOUT1_DUTY_CYCLE(0.50),
		 .CLKOUT1_PHASE(126.161),       // clk_phase[5] @ 24.628 ns

		 .CLKOUT2_DIVIDE   ( 112   ),   // 14.230 MHz = 70.275 ns
		 .CLKOUT2_DUTY_CYCLE(0.675),    // clk_phase[10] @ 47.435 ns
		 .CLKOUT2_PHASE(0.0),        

		 .CLKOUT3_DIVIDE   ( 20    ),
		 .CLKOUT3_DUTY_CYCLE(0.50),
		 .CLKOUT3_PHASE(0.0),        

		 .CLKOUT4_DIVIDE   ( 20     ),
		 .CLKOUT4_DUTY_CYCLE(0.5),   
		 .CLKOUT4_PHASE(0.0),        

		 .CLKOUT5_DIVIDE   ( 20     ),
		 .CLKOUT5_DUTY_CYCLE(0.5),   
		 .CLKOUT5_PHASE(0.0),        

		 .CLKOUT6_DIVIDE   ( 20     ),
		 .CLKOUT6_DUTY_CYCLE(0.5),   
		 .CLKOUT6_PHASE(0.0),        

		 .BANDWIDTH("OPTIMIZED"),   
		 .CLKOUT4_CASCADE("FALSE"),  
		 .IS_CLKFBIN_INVERTED(1'b0), 
		 .IS_CLKIN1_INVERTED(1'b0),  
		 .IS_PWRDWN_INVERTED(1'b0),  
		 .IS_RST_INVERTED(1'b0),     
		 .REF_JITTER1(0.010),        
		 .STARTUP_WAIT("TRUE")       
		 )
   MMCME4_inst_ (
		 .CLKIN1   ( clk       ),                 
		 .CLKFBIN  ( mmcm_fb   ),        
		 .CLKFBOUT ( mmcm_fb   ),            

		 .CLKOUT0  ( modsqr_clk_phase[0] ),
		 .CLKOUT1  ( modsqr_clk_phase[5] ),
		 .CLKOUT2  ( ),
		 .CLKOUT3  ( ),
		 .CLKOUT0B ( modsqr_clk_phase[8] ),
		 .CLKOUT1B ( ),
		 .CLKOUT2B ( modsqr_clk_phase[10] ),
		 .CLKOUT3B ( ),

		 .CLKOUT4  ( ),  
		 .CLKOUT5  ( ),            
		 .CLKOUT6  ( ),  
		 .CLKFBOUTB( ),                     
		 .LOCKED   (   ),                        
		 .PWRDWN   ( 1'b0 ),                    
		 .RST      ( 1'b0 )          
		 );

endmodule
