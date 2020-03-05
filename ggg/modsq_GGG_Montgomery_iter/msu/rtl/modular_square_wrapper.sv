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

   logic 	modsqr_reset;

   logic modsqr_start_pipe3;
   logic modsqr_start;

   logic valid_pipe3;
   logic modsqr_valid, modsqr_valid_toggle;
      
   modular_square_GGG_Montgomery modsqr(
          .clk_phase          ( modsqr_clk_phase ),
          .reset              ( modsqr_reset ),
          .start              ( modsqr_start ),
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

   ///// PLL /////////

   MMCME4_BASE #(
		 .CLKIN1_PERIOD    ( 8.000 ),   // 125 MHz
		 .DIVCLK_DIVIDE    (  1    ),   // 125 MHz at input to phase detect
		 .CLKFBOUT_MULT_F  ( 12.75 ),   // 1593.75 MHz VCO
		 .CLKFBOUT_PHASE(0.0),       

		 .CLKOUT0_DIVIDE_F ( 32    ),   // 49.805 MHz = 20.078 ns
		 .CLKOUT0_DUTY_CYCLE(0.5),
		 .CLKOUT0_PHASE(0.0),        

		 .CLKOUT1_DIVIDE   ( 20    ),
		 .CLKOUT1_DUTY_CYCLE(0.50),
		 .CLKOUT1_PHASE(0.0),        

		 .CLKOUT2_DIVIDE   ( 20    ),
		 .CLKOUT2_DUTY_CYCLE(0.50),
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
		 .CLKOUT1  ( ),
		 .CLKOUT2  ( ),
		 .CLKOUT3  ( ),
		 .CLKOUT0B ( ),
		 .CLKOUT1B ( ),
		 .CLKOUT2B ( ),
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
