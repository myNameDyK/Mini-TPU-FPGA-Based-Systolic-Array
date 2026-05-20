`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 04:41:09 PM
// Design Name: 
// Module Name: Tile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Tile #(

    parameter ROW = 8,
    parameter COL = 8

    )(

    input clk,
    input rst, init, en,    // init =1: PE start to count acc the 1st time : init only = 1 at the ist clk. then =0
                            // en = 1 :all pe activate, en = 0, all pe off.

    // valid = 1 only PE feeded data
    input valid_in [ROW-1:0],


    // EDGE INPUT FOR 1ST COL PE
    input   signed  [7:0]   ia  [ROW-1:0], 
    // EDGE INPUT FOR 1ST ROW PE
    input   signed  [7:0]   ib  [COL-1:0],
    

    // EDGE OUTPUT FOR THE LAST COL PE
    output  signed  [7:0]   oa  [ROW-1:0],  
    // EDGE OUTPUT FOR THE LAST row PE
    output  signed  [7:0]   ob   [COL-1:0],


    //  OUTPUT REGISTER FOR MAC RESULT (TRACKING EVERY CLOCK)
    output  signed  [31:0]  c    [ROW-1:0][COL-1:0]

);


// INTERCONNECTION - valid_in is in the same way and time with a
    wire inter_valid         [ROW-1:0][COL-1:0];

// INTERCONNECTION - a right-left
    wire signed  [7:0] in_a  [ROW-1:0][COL-1:0];

// INTERCONNECTION - b top-down
    wire signed  [7:0] in_b  [ROW-1:0][COL-1:0];



//get init form init Flip Flop
wire [ROW+COL-2:0] init_delay;


initControl #(
            .DEPTH(ROW+COL-1) 
            )
init_block(

            .clk    (clk),
            .rst    (rst),
            .en     (en),
            .init   (init),
            .initFF (init_delay)

            );



//  8x8 ARRAY 
genvar i, j;

generate


    for ( i=0; i< ROW; i= i+1 ) begin : ROW_
        for ( j=0; j< COL; j= j+1 ) begin : COL_


            PE pe_block(
                    .clk    (clk),
                    .rst    (rst),
                    .init   (init_delay[i+j]),
                    .en     (en),
                    .valid_in(  ( j==0 )        ?   valid_in[i]     :   inter_valid[i][j-1]    ),
                    .a      (   ( j==0 )        ?   ia[i]           :   in_a[i][j-1]    ),
                    .b      (   ( i==0 )        ?   ib[j]           :   in_b[i-1][j]    ),
                    .a_out  (   in_a[i][j]    ),
                    .b_out  (   in_b[i][j]    ),
                    .c_out  (   c[i][j]),
                    .valid_out( inter_valid[i][j]    )
                );
        

        end
    end    


endgenerate




endmodule
