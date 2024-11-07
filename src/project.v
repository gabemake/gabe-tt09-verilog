/*
 * Copyright (c) 2024 GabeMake
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`include "parameters.vh"

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:0], ui_in[1:3], 1'b0};

  // countdown
  //typedef enum states { IDLE, COUNTING, SCORE1, SCORE2, SCORE3, SCORE4, SCOREB, OVER1, OVER2, OVER3, OVER4, OVERB} states_t;

  logic [3:0] current_state;
  logic [3:0] next_state;

  logic [3:0] counter_dig1;
  logic [3:0] counter_dig2;
  logic [3:0] counter_dig3;
  logic [3:0] counter_dig4;
  logic [19:0] counter_ms;
  logic over;
  
  //typedef enum display {d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, dB, dV, dE, dR, dD} display_t;
  logic [3:0] disp;

  always @(posedge clk) begin
    if (!rst_n) begin
      // reset to IDLE
      next_state = IDLE;
      current_state = IDLE;
      counter_ms = 0;
      counter_dig1 = 0;
      counter_dig2 = 0;
      counter_dig3 = 0;
      counter_dig4 = 0;
      over = 0;
      disp = dD;
    end else begin
      over = 0;
      current_state = next_state;
      if (current_state == IDLE) begin
        // set up intial game values
        counter_ms = 1000;
        counter_dig1 = ui_in[7:4]; //technically this can be A-F too, but I'm not going to validate.
        counter_dig2 = 9;
        counter_dig3 = 9;
        counter_dig4 = 9;
      end else if (current_state == COUNTING) begin
        // go digit by digit, decrementing and resetting
        if (counter_ms > 0) begin
          // count to 1000 cycles every ms
          counter_ms -= 1;
        end else begin
          if (counter_dig4 > 0) begin
            // do the rest of the digits 1 at a time
            counter_dig4 -= 1;
            counter_ms = 1000;
          end else begin
            if (counter_dig3 > 0) begin
              counter_dig3 -= 1;
              counter_dig4 = 9;
              counter_ms = 1000;
            end else begin
              if (counter_dig2 > 0) begin
                counter_dig2 -= 1;
                counter_dig3 = 9;
                counter_dig4 = 9;
                counter_ms = 1000;
              end else begin
                if (counter_dig1 > 0) begin
                  counter_dig1 -= 1;
                  counter_dig2 = 9;
                  counter_dig3 = 9;
                  counter_dig4 = 9;
                  counter_ms = 1000;
                end else begin
                  // if dig1 reaches 0, it's game over (yeah I know it's a second behind)
                  over = 1;
                end //dig1
              end //dig2
            end //dig3
          end//dig4
        end //counter_ms
      end else if (current_state == SCORE1 or current_state == OVER1 or 
                  current_state == SCORE2 or current_state == OVER2 or 
                  current_state == SCORE3 or current_state == OVER3 or 
                  current_state == SCORE4 or current_state == OVER4 or 
                  current_state == SCOREB or current_state == OVERB) begin
        if (counter_ms > 0) begin
          counter_ms -= 1;
        end else begin
          counter_ms = 10000000;
       // count down a full second per OVER/SCORE character
        end
      end //state if
      
    end // reset
  end // always block

  always_comb begin
      case (current_state)
        IDLE: begin
          if (ui_in[0] == 1'b0) begin
            next_state = COUNTING;
          end else begin
            next_state = IDLE;
          end
        end
        COUNTING: begin
          if (over) begin
            next_state = OVERB;
          end else if (ui_in[0] == 1'b0) begin
            next_state = SCOREB;
          end else begin
            next_state = COUNTING;
          end
        end
        SCOREB: begin
          if (counter_ms = 0)
            next_state = SCORE1;
          else
            next_state = SCOREB;
          disp = dB;
        end
        SCORE1: begin
          if (counter_ms = 0)
            next_state = SCORE2;
          else
            next_state = SCORE1;
          disp = display_t[counter_dig1-1]; //account for the fact that the game ends at 1000ms
        end
        SCORE2: begin
          if (counter_ms = 0)
            next_state = SCORE3;
          else
            next_state = SCORE2;
          
          disp = display_t[counter_dig2];
        end
        SCORE3: begin
          if (counter_ms = 0)
            next_state = SCORE4;
          else
            next_state = SCORE3;
          
          disp = display_t[counter_dig3];
        end
        SCORE4: begin
          if (counter_ms = 0)
            next_state = SCOREB;
          else
            next_state = SCORE4;
          
          disp = display_t[counter_dig4];
        end
        OVERB: begin
          if (counter_ms = 0)
            next_state = OVER1;
          else
            next_state = OVERB;
          
          disp = dB;
        end
        OVER1: begin
          if (counter_ms = 0)
            next_state = OVER2;
          else
            next_state = OVER1;
          
          disp = d0;
        end
        OVER2: begin
          if (counter_ms = 0)
            next_state = OVER3;
          else
            next_state = OVER2;
          
          disp = dV;
          
        end
        OVER3: begin
          if (counter_ms = 0)
            next_state = OVER4;
          else
            next_state = OVER3;
          
          disp = dE;
        end
        OVER4: begin
          if (counter_ms = 0)
            next_state = OVERB;
          else
            next_state = OVER4;
          
          disp = dR;
        end
      endcase
       
  end

  always_comb begin
    case (disp)
      //note that the order of segments is .GFEDCBA
      d0: uo_out[7:0] = 8'b00111111;
      d1: uo_out[7:0] = 8'b00000110;
      d2: uo_out[7:0] = 8'b01011011;
      d3: uo_out[7:0] = 8'b01001111;
      d4: uo_out[7:0] = 8'b01100110;
      d5: uo_out[7:0] = 8'b01101101;
      d6: uo_out[7:0] = 8'b01111101;
      d7: uo_out[7:0] = 8'b00000111;
      d8: uo_out[7:0] = 8'b01111111;
      d9: uo_out[7:0] = 8'b01101111;
      dB: uo_out[7:0] = 8'b00000000;
      dV: uo_out[7:0] = 8'b00111110; //going with the uppercase here
      dE: uo_out[7:0] = 8'b01111001;
      dR: uo_out[7:0] = 8'b01010000;
      dD: uo_out[7:0] = 8'b01000000;
      default: uo_out[7:0] = 8'b10000000; // invalid characters get the .
    endcase
  end
          

endmodule
