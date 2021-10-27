// wishbone slave module
//      address space:
//          caraval user block:  0x30000000 to 0x7FFFFFFFF
//            GPIO user block:   0x30000000 to 0x30000000F
//            RAM user block:    0x30000080 to 0x3000000FF

module wbSlave (
    // wishbone slave interface
    input   wire            CLK_I,  // bus clock signal
    input   wire            RST_I,  // bus reset signal
    input   wire            STB_I,  // bus transaction request
    input   wire            CYC_I,  // active transaction
    input   wire            WE_I,   // write request
    input   wire    [3:0]   SEL_I,  // byte select for request
    input   wire    [31:0]  DAT_I,  // data for request
    input   wire    [31:0]  ADR_I,  // address for request
    output  wire            ACK_O,  // request acknowledge, read data valid
    output  wire    [31:0]  DAT_O,  // requested read data
    // gpio interface
    output  wire            CTRL_WE,
    output  wire    [3:0]   CTRL_ADDR,
    output  wire    [31:0]  CTRL_DATA_IN,
    input   wire    [31:0]  CTRL_DATA_OUT,
    // RAM interface
    output  wire            RAM_CSb,
    output  wire            RAM_WEb,
    output  wire    [7:0]   RAM_ADDR,
    output  wire    [31:0]  RAM_DATA_IN,
    input   wire    [31:0]  RAM_DATA_OUT
);

    // acknowledge shift register
    reg     [1:0]   ACK_O_Q;
    // ram write enable edge detection 
    wire            RAM_WE_i;
    reg             RAM_WE_Q;
    // control write enable edge detection
    wire            CTRL_WE_i;
    reg             CTRL_WE_Q;

    // module output
    assign DAT_O = DAT_O_i;

    // ram access
    assign RAM_CSb      = (ADR_I[7] == 1'b1) ? 1'b0 : 1'b1;
    assign RAM_WE_i     = (ADR_I[7] == 1'b1) ? CYC_I & STB_I & WE_I : 1'b0;
    assign RAM_WEb      = !(!RAM_WE_Q & RAM_WE_i);
    assign RAM_ADDR     = ADR_I[7:0];
    assign RAM_DATA_IN  = DAT_I;

    // gpio access
    assign CTRL_WE_i    = (ADR_I[7] == 1'b0) ? CYC_I & STB_I & WE_I : 1'b0;
    assign CTRL_WE      = !CTRL_WE_Q & CTRL_WE_i;
    assign CTRL_ADDR    = ADR_I[3:0];
    assign CTRL_DATA_IN = DAT_I;

    // read multiplexer
    assign DAT_O = (ADR_I[7] == 1'b1) ? RAM_DATA_OUT : CTRL_DATA_OUT;

    // acknowledge
    assign ACK_O = ((CYC_I & STB_I) == 1'b0) ? 1'b0 : ACK_O_Q[1];

    // flip flops
    always @(posedge CLK_I, posedge RST_I) begin
        if (RST_I == 1'b1) begin
            ACK_O_Q     <= 1'b0;
            RAM_WE_Q    <= 1'b0;
            CTRL_WE_Q   <= 1'b0;
        end else begin
            ACK_O_Q         <= {ACK_O_Q[0], CYC_I & STB_I}; 
            RAM_WE_Q    <= RAM_WE_i;
            CTRL_WE_Q   <= CTRL_WE_i;
        end
    end
    
endmodule