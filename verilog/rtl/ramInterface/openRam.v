// open RAM implemented as flip flops (fall back solution)

module openRam (
    input   wire            CLK,
    input   wire            CSb,
    input   wire            WEb,
    input   wire    [4:0]   ADDR,
    input   wire    [7:0]   DATA_IN,
    output  wire    [7:0]   DATA_OUT
);
    
    // control signal flip flops
    reg       CSb_Q;
    reg       WEb_Q;
    reg [4:0] ADDR_Q;
    reg [7:0] DATA_IN_Q;
    // "RAM" flip flops (32 x 8bit = 256bit)
    reg [7:0] RAM_Q [31:0];
    reg [7:0] RAM_OUT_Q;

    // module output
    assign DATA_OUT = RAM_OUT_Q;

    // latch control signals first
    always @(posedge(CLK)) begin
        CSb_Q       <= CSb;
        WEb_Q       <= WEb;
        ADDR_Q      <= ADDR;
        DATA_IN_Q   <= DATA_IN;
    end

    // actual ram cell access
    always @(negedge(CLK)) begin
        // new ram access
        if (CSb_Q == 1'b0) begin
            // valid write access
            if (WEb_Q == 1'b0) begin
                RAM_Q[ADDR_Q] <= DATA_IN_Q;
                RAM_OUT_Q     <= DATA_IN_Q;
            // valid read access
            end else RAM_OUT_Q <= RAM_Q[ADDR_Q];
        end
    end
endmodule