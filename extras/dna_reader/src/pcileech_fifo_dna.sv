//
// PCILeech FPGA - DNA Reader Module
//
// This module reads the FPGA DNA and exposes it through the register interface
//

`timescale 1ns / 1ps

module dna_reader(
    input clk,
    input rst,
    output reg [56:0] dna_value,
    output reg dna_ready
);

    reg [6:0] bit_counter;
    reg dna_read;
    reg dna_shift;
    wire dna_dout;

    reg [1:0] state;
    localparam IDLE = 0;
    localparam READ_START = 1;
    localparam SHIFTING = 2;
    localparam DONE = 3;

    DNA_PORT #(
        .SIM_DNA_VALUE(57'h0)
    ) dna_port_inst (
        .DOUT(dna_dout),
        .CLK(clk),
        .DIN(1'b0),
        .READ(dna_read),
        .SHIFT(dna_shift)
    );

    initial begin
        state <= IDLE;
        bit_counter <= 0;
        dna_read <= 0;
        dna_shift <= 0;
        dna_value <= 0;
        dna_ready <= 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bit_counter <= 0;
            dna_read <= 0;
            dna_shift <= 0;
            dna_value <= 0;
            dna_ready <= 0;
        end else begin
            case (state)
                IDLE: begin
                    dna_read <= 1;
                    dna_shift <= 0;
                    bit_counter <= 0;
                    state <= READ_START;
                end

                READ_START: begin
                    dna_read <= 0;
                    dna_shift <= 1;
                    state <= SHIFTING;
                end

                SHIFTING: begin
                    if (bit_counter < 57) begin
                        dna_value <= {dna_value[55:0], dna_dout};
                        bit_counter <= bit_counter + 1;
                    end else begin
                        dna_shift <= 0;
                        dna_ready <= 1;
                        state <= DONE;
                    end
                end

                DONE: begin
                    // Stay in DONE state
                end
            endcase
        end
    end

endmodule
