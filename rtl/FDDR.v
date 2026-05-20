`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 04:40:42 PM
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


module FDDR #(

    parameter latency     = 20,       // simulate latency in ddr
    parameter data_width  = 64,
    parameter addr_width  = 12,
    parameter memory_size = 65536,
    parameter len_width   = 8,         // use for number of burst register 
    parameter w_base      = 0,
    parameter a_base      = 16384,
    parameter c_base      = 32768

    )(
    
    input clk, rst,

    // ======REQUEST========
    input                       req_valid,      // controller has a request to DDR
    output reg                  req_ready,      // DDR is ready for request
    input [addr_width-1:0]      req_addr,   
    input [len_width-1:0]       req_numberBurst,         // number of burst

    // ======STREAM DATA====
    input                       data_ready,      //buffer is ready to recieve data from DDR
    output reg                  data_valid,      //DDR has valid data for streaming
    output reg [data_width-1:0] data,
    output reg                  data_last       //the last burst of the stream

    );


    // base ram for matrix w, a , c stored  
    localparam BASE_W = w_base;
    localparam BASE_A = a_base;
    localparam BASE_C = c_base;


    // simutaling DDR by using FPGA internal memory
    reg [data_width-1:0] DDR [memory_size-1:0];


    // register signal
    reg [addr_width-1:0] addr;
    reg [len_width-1:0]  numberBurst;
    reg [len_width-1:0]  burst_cnt;             // if bust_cnt == numberBurst then stop transfer
    reg [7:0]            latency_cnt;


    // state in FSM
    reg [1:0]               state;
    // FSM state
    localparam  IDLE  = 2'b00;
    localparam  WAIT  = 2'b01;
    localparam  TRANS = 2'b10;


    integer i;
    initial begin

        for (i = 0; i < BASE_C; i = i + 1 ) begin
            DDR[i] = 0;
        end

    end


    always @(posedge clk or posedge rst) begin

        if(rst) begin

            state       <= IDLE;
            addr        <= 0;
            numberBurst <= 0;
            burst_cnt   <= 0;
            latency_cnt <= 0;
            req_ready   <= 1'b1;
            data_valid  <= 1'b0;
            data        <= {data_width{1'b0}};
            data_last   <= 1'b0;

        end

        // FSM controller
        else begin

            data_last <= 1'b0;

            case(state)
                IDLE: begin

                    req_ready   <= 1'b1;         // when idle DDR is ready to recieve request from master
                    data_valid  <= 1'b0;          // DDR is not transfering data
                    
                    if( req_ready && req_valid ) begin

                        req_ready   <= 1'b0;
                        addr        <= req_addr;
                        numberBurst <= req_numberBurst;
                        burst_cnt   <= 0;                       
                        latency_cnt <= 0;
                        state       <= WAIT;
                    end
                end       
//==============================================
                WAIT: begin

                    if( latency_cnt == latency-1 ) begin

                        data        <= DDR[addr];
                        data_valid  <= 1'b1;
                        state       <= TRANS;
                        burst_cnt   <= 1;
                    end
                    else latency_cnt <= latency_cnt + 1;
                end
//=================================================
                TRANS: begin
                    if( data_valid && data_ready ) begin 

                        if( burst_cnt == numberBurst ) begin

                            data_last   <= 1'b1;
                            data_valid  <= 1'b0;
                            req_ready   <= 1'b1;
                            state       <= IDLE;
                        end               
                        else begin

                            data      <= DDR[addr + burst_cnt];
                            burst_cnt <= burst_cnt + 1; 
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end


endmodule
