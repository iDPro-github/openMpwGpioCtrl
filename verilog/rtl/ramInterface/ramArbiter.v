// RAM Arbiter for dual port access

module ramArbiter (
    // system
    input   wire            CLK,
    input   wire            RSTb,
    // ctrl interfaces 1
    input   wire            CTRL_CSb1,
    input   wire            CTRL_WEb1,
    input   wire    [7:0]   CTRL_ADDR1,
    input   wire    [31:0]  CTRL_DATA_IN1,
    output  wire    [31:0]  CTRL_DATA_OUT1,
    // ctrl interface 2
    input   wire            CTRL_CSb2,
    input   wire            CTRL_WEb2,
    input   wire    [7:0]   CTRL_ADDR2,
    input   wire    [31:0]  CTRL_DATA_IN2,
    output  wire    [31:0]  CTRL_DATA_OUT2,
    // RAM interface byte0
    output   wire            RAM_CSb0,
    output   wire            RAM_WEb0,
    output   wire    [4:0]   RAM_ADDR0,
    output   wire    [7:0]   RAM_DATA_IN0,
    input    wire    [7:0]   RAM_DATA_OUT0,
    // RAM interface byte1
    output   wire            RAM_CSb1,
    output   wire            RAM_WEb1,
    output   wire    [4:0]   RAM_ADDR1,
    output   wire    [7:0]   RAM_DATA_IN1,
    input    wire    [7:0]   RAM_DATA_OUT1,
    // RAM interface byte2
    output   wire            RAM_CSb2,
    output   wire            RAM_WEb2,
    output   wire    [4:0]   RAM_ADDR2,
    output   wire    [7:0]   RAM_DATA_IN2,
    input    wire    [7:0]   RAM_DATA_OUT2,
    // RAM interface byte3
    output   wire            RAM_CSb3,
    output   wire            RAM_WEb3,
    output   wire    [4:0]   RAM_ADDR3,
    output   wire    [7:0]   RAM_DATA_IN3,
    input    wire    [7:0]   RAM_DATA_OUT3
);
    // internal output signals
    reg         RAM_WEb_i;
    reg [4:0]   RAM_ADDR_i;
    reg [31:0]  RAM_DATA_IN_i;
    // interface read data
    reg [31:0]  READ_DATA1_Q;
    reg [31:0]  READ_DATA1_D;
    reg [31:0]  READ_DATA2_Q;
    reg [31:0]  READ_DATA2_D;

    // module outputs
    assign RAM_CSb0     = 1'b0;
    assign RAM_WEb0     = RAM_WEb_i;
    assign RAM_ADDR0    = RAM_ADDR_i;
    assign RAM_DATA_IN0 = RAM_DATA_IN_i[7:0];   
    assign RAM_CSb1     = 1'b0;
    assign RAM_WEb1     = RAM_WEb_i;
    assign RAM_ADDR1    = RAM_ADDR_i;
    assign RAM_DATA_IN1 = RAM_DATA_IN_i[15:8];   
    assign RAM_CSb2     = 1'b0;
    assign RAM_WEb2     = RAM_WEb_i;
    assign RAM_ADDR2    = RAM_ADDR_i;
    assign RAM_DATA_IN2 = RAM_DATA_IN_i[23:16];   
    assign RAM_CSb3     = 1'b0;
    assign RAM_WEb3     = RAM_WEb_i;
    assign RAM_ADDR3    = RAM_ADDR_i;
    assign RAM_DATA_IN3 = RAM_DATA_IN_i[31:24];

    // interface read access (if1 always wins)
    always @(*) begin : if_read_access
        reg [31:0] vRamDataOut;
        // default
        READ_DATA1_D <= READ_DATA1_Q;
        READ_DATA2_D <= READ_DATA2_Q;
        // concatenate RAM data
        vRamDataOut = {RAM_DATA_OUT3, RAM_DATA_OUT2, RAM_DATA_OUT1, RAM_DATA_OUT0};
        // interface selection
        if(CTRL_CSb1 == 1'b0) READ_DATA1_D <= vRamDataOut;
        else if(CTRL_CSb2 == 1'b0 ) READ_DATA2_D <= vRamDataOut;
    end
    assign CTRL_DATA_OUT1 = (CTRL_CSb1 == 1'b0) ? {RAM_DATA_OUT3, RAM_DATA_OUT2, RAM_DATA_OUT1, RAM_DATA_OUT0} : READ_DATA1_Q;
    assign CTRL_DATA_OUT2 = (CTRL_CSb2 == 1'b0) ? {RAM_DATA_OUT3, RAM_DATA_OUT2, RAM_DATA_OUT1, RAM_DATA_OUT0} : READ_DATA2_Q;

    // interface multiplexer (if1 always wins)
    always @(*) begin
        if(CTRL_CSb1 == 1'b0) begin
            RAM_WEb_i = CTRL_WEb1;
            RAM_ADDR_i = CTRL_ADDR1[7:2];
            RAM_DATA_IN_i = CTRL_DATA_IN1;
        end else begin
            RAM_WEb_i = CTRL_WEb2;
            RAM_ADDR_i = CTRL_ADDR2[7:2];
            RAM_DATA_IN_i = CTRL_DATA_IN2;
        end
    end
    
    // flip flops
    always @(posedge CLK, negedge RSTb) begin
        if(RSTb == 1'b0) begin
            READ_DATA1_Q <= 32'h00_00_00_00;
            READ_DATA2_Q <= 32'h00_00_00_00;
        end else begin
            READ_DATA1_Q <= READ_DATA1_D;
            READ_DATA2_Q <= READ_DATA2_D;
        end
    end
endmodule