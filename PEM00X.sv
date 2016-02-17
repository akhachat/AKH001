// Module:    PEM00X_model
// Revision:  01
// Engineer:  Ashot Khachatryan
// Function:  PEM001 and PEM002 RF modules' behavioral model (2-channel 16-bit DACs)
// Features:  Requested features
//             1) Single model to emulate R/W operations for both devices.  For our purposes, we don't care whether it  is Rx or Tx module.
//             2) The RX/TX modules are differentiated by an ID code (RX=111, TX=110),  but for this model.... ID code is ignored.
//             3) Create a simple 1B x 16 memory  in model that I can R/W to. Do not define individual bit locations.
//             4) All memory locations are cleared on Async Reset
//             5) If disabled,  No R/W operations occur.  Data shifted out = 0.
// Comments:  20160215 AKH: Created.
//

`timescale  1ns/1ns

module  PEM00X_model(
    input   RESET
   ,input   CLOCK
   ,input   ENABLE
   ,input   DATA
   ,output  SCANOUT
);

parameter TX_RX = 3'b110;  // Rx = 111, Tx = 110. For ID code

reg  [0:17] sh__in;
reg   [0:7] sh_out;
reg   [4:0] cnt_bit;
reg   [3:0] adr;
reg         op;
reg   [3:0] adr_w;
reg   [2:0] sel_w;
reg   [0:7] reg_bank[0:15];
bit   [4:0] i, j, k;

wire        sel, ld_out, en_out, en_op, en_mwr, en_adr, cnt_rst;

assign sel      =  sel_w == TX_RX;
assign en_out   = ~ENABLE & ~op;
assign ld_out   =  ENABLE & ~op;
assign en_op    =  sel & (cnt_bit == 5'd18);
assign en_mwr   =  sel & ~CLOCK & sh__in[14] & (cnt_bit == 5'd18) & (sh__in[8:9] == 2'b00);  // bits [8:9] "must be 00"
assign en_adr   =  sel & ~CLOCK & (cnt_bit == 5'd18);
assign cnt_rst  =  ENABLE | RESET;

assign SCANOUT  =  ENABLE ? 1'b0 : sh_out[0];

// bit reversal
always @*
   for(j=0; j<4; j=j+1)
      adr_w[j] = sh__in[10+j];

always @*
   for(k=0; k<3; k=k+1)
      sel_w[k] = sh__in[15+k];
//

// register bank init
initial
   for(i=0; i<16; i=i+1)
      reg_bank[i] = 0;

always @( posedge RESET )
   for(i=0; i<16; i=i+1)
      reg_bank[i] = 0;
//

// register write
always @( posedge ENABLE )
   if( en_mwr )  reg_bank[adr_w] <= sh__in[0:7];

// counter: bit
always @( posedge CLOCK, posedge cnt_rst )
   if( cnt_rst )       cnt_bit <= 0;
   else if( ~ENABLE )  cnt_bit <= cnt_bit +1;
   else                cnt_bit <= 0;

// shift: input
always @( posedge CLOCK, posedge RESET )
   if( RESET )         sh__in <= 0;
   else if( ~ENABLE )  sh__in <= {sh__in[1:17], DATA};

// operation
always @( posedge ENABLE, posedge RESET )
   if( RESET )       op <= 1;
   else if( en_op )  op <= sh__in[14];

// register address
always @( posedge ENABLE, posedge RESET )
   if( RESET )        adr <= 0;
   else if( en_adr )  adr <= adr_w;

// shift: output
always @( negedge CLOCK, posedge RESET )
   if( RESET )        sh_out <= 0;
   else if( ld_out )  sh_out <= reg_bank[adr];
   else if( en_out )  sh_out <= {sh_out[1:7], 1'b0};

// some tiing relations
specify
$setuphold(posedge CLOCK, DATA,2,2);
$setuphold(posedge CLOCK, ENABLE,2,2);
endspecify
       
endmodule
