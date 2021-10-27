// gpio control module
//      address space:
//          Ctrl Reg        0b00
//          GPIO Input      0b01
//          GPIO Output     0b10
//          GPIO OutEnable  0b11

module gpioCtrl (
    // system
    input   wire            CLK,
    input   wire            RSTb,
    // control interface
    input   wire            CTRL_WE,
    input   wire    [3:0]   CTRL_ADDR,
    input   wire    [31:0]  CTRL_DATA_IN,
    output  wire    [31:0]  CTRL_DATA_OUT,
    // caravel gpio signaling
    input   wire    [37:0]  GPIO_IN,
    output  wire    [37:0]  GPIO_OUT,
    output  wire    [37:0]  GPIO_OEb,
    // RAM interface
    output  wire            RAM_CSb,
    output  wire            RAM_WEb,
    output  wire    [7:0]   RAM_ADDR,
    output  wire    [31:0]  RAM_DATA_IN,
    input   wire    [31:0]  RAM_DATA_OUT
);
    // constants input fsm
    parameter sFSM_IN_STOP      	= 2'b00;
    parameter sFSM_IN_SHIFT     	= 2'b01;
    parameter sFSM_IN_STORE     	= 2'b10;
    // constants output fsm
    parameter sFSM_OUT_STOP     	= 2'b00;
    parameter sFSM_OUT_LOAD     	= 2'b01;
    parameter sFSM_OUT_SHIFT    	= 2'b10;
    parameter sFSM_OUT_LOAD_NEXT 	= 2'b11;

    // internal output signals
    reg [31:0]  CTRL_DATA_OUT_i;
    reg         RAM_WEb_i;
    reg [31:0]  RAM_ADDR_i;
    reg [31:0]  RAM_DATA_IN_i;
    // control register
    reg [31:0]  CTRL_REG_Q;
    reg [31:0]  CTRL_REG_D;
    // control register aliases
    wire        aSHIFT_IN_EN;
    wire [4:0]  aINPUT_SEL;
    wire        aSHIFT_OUT_EN;
    wire [4:0]  aOUTPUT_SEL;
    wire        aOUTPUT_LOOP;
    wire [9:0]  aOUTPUT_LEN;
    wire        aOUTPUT_LIMIT;
    // data registers
    reg [31:0]   DATA_IN_Q;
    reg [31:0]   DATA_IN_D;
    reg [31:0]   DATA_OUT_Q;
    reg [31:0]   DATA_OUT_D;
    reg [31:0]   DATA_OE_Q;
    reg [31:0]   DATA_OE_D;
    // Shift registers
    reg [31:0]   SHIFT_IN_Q;
    reg [31:0]   SHIFT_IN_D;
    reg [31:0]   SHIFT_OUT_Q;
    reg [31:0]   SHIFT_OUT_D;
    // fsm registers
    reg [1:0]   FSM_IN_Q;
    reg [1:0]   FSM_IN_D;
    reg [1:0]   FSM_OUT_Q;
    reg [1:0]   FSM_OUT_D;
    // fsm control signals
    reg         SET_SHIFT_DATA;
    reg         SET_OUT_DATA;
    reg         RST_SHIFT_IN_EN;
    reg         RST_SHIFT_OUT_EN;
    reg         OVERRIDE_RAM_ADDR;
    reg         RAM_CSb_IN;
    reg         RAM_CSb_OUT;
    // bit counters
    reg [9:0]   BIT_IN_COUNT_Q;
    reg [9:0]   BIT_IN_COUNT_D;
    reg [9:0]   BIT_OUT_COUNT_Q;
    reg [9:0]   BIT_OUT_COUNT_D;

    // module output
    assign CTRL_DATA_OUT = CTRL_DATA_OUT_i;
    assign GPIO_OUT[31:0] = DATA_OUT_Q;
    assign GPIO_OUT[37:32] = 6'b000000;
    assign GPIO_OEb[31:0] = ~(DATA_OE_Q);
    assign GPIO_OEb[37:32] = 6'b111111;
    assign RAM_WEb = RAM_WEb_i;
    assign RAM_ADDR = RAM_ADDR_i;
    assign RAM_DATA_IN = RAM_DATA_IN_i;

    // control register read aliases (...is there a way to define real aliases?)
    assign aSHIFT_OUT_EN    = CTRL_REG_Q[0];
    assign aOUTPUT_SEL      = CTRL_REG_Q[5:1];
    assign aSHIFT_IN_EN     = CTRL_REG_Q[6];
    assign aINPUT_SEL       = CTRL_REG_Q[11:7];
    assign aOUTPUT_LOOP     = CTRL_REG_Q[12];
    assign aOUTPUT_LEN      = CTRL_REG_Q[22:13];
    assign aOUTPUT_LIMIT    = CTRL_REG_Q[23];
    
    // control interface read access
    always @(*) begin : interface_read_access
        case (CTRL_ADDR[3:2])
            // control register
            2'b00: CTRL_DATA_OUT_i <= CTRL_REG_Q;
            // input data
            2'b01: CTRL_DATA_OUT_i <= DATA_IN_Q;
            // output data
            2'b10: CTRL_DATA_OUT_i <= DATA_OUT_Q;
            // output enable
            2'b11: CTRL_DATA_OUT_i <= DATA_OE_Q;
            // something's wrong
            default: CTRL_DATA_OUT_i <= 8'b0000_0000;
        endcase
    end

    // control interface write access
    always @(*) begin : interface_write_access
        // default
        CTRL_REG_D   <= CTRL_REG_Q;
        SET_OUT_DATA <= 1'b0;
        DATA_OE_D   <= DATA_OE_Q;
        // actual write request
        if (CTRL_WE == 1'b1) begin
            // address selection
            case (CTRL_ADDR[3:2])
                // control register
                2'b00: begin
                    CTRL_REG_D  <= CTRL_DATA_IN;
                end
                // output data
                2'b10: SET_OUT_DATA <= 1'b1;
                // output enable
                2'b11: DATA_OE_D  <= CTRL_DATA_IN;
            endcase
        end
        // auto set/reset shift enables
        if (RST_SHIFT_IN_EN == 1'b1) CTRL_REG_D[6] <= 1'b0;
        if (RST_SHIFT_OUT_EN == 1'b1) CTRL_REG_D[0] <= 1'b0;
        //if (SET_SHIFT_OUT_EN == 1'b1)  CTRL_REG_D[0] <= 1'b1;
    end

    // fsm data in
    always @(*) begin : fsm_data_in
        // default
        FSM_IN_D        <= FSM_IN_Q;
        BIT_IN_COUNT_D  <= BIT_IN_COUNT_Q;
        RST_SHIFT_IN_EN <= 1'b0;
        //RAM_CSb_IN      <= 1'b1;
        RAM_WEb_i       <= 1'b1;
        // fsm logic
        case (FSM_IN_Q)
            // input sampling inactive
            sFSM_IN_STOP: begin
                BIT_IN_COUNT_D <= 10'b00_0000_0000;
                if (aSHIFT_IN_EN == 1'b1) begin
                    RST_SHIFT_IN_EN <= 1'b1;
                    FSM_IN_D <= sFSM_IN_SHIFT;
                end
            end
            // input sampling active
            sFSM_IN_SHIFT: begin
                BIT_IN_COUNT_D <= BIT_IN_COUNT_Q + 1;
                if (BIT_IN_COUNT_Q[4:0] == 5'b1_1110) FSM_IN_D <= sFSM_IN_STORE;
            end
            // store 32bit input data to ram
            sFSM_IN_STORE: begin
                BIT_IN_COUNT_D  <= BIT_IN_COUNT_Q + 1;
                //RAM_CSb_IN      <= 1'b0;
                RAM_WEb_i       <= 1'b0;
                if (BIT_IN_COUNT_Q[9:5] == 5'b1_1111) FSM_IN_D <= sFSM_IN_STOP;
                else                                  FSM_IN_D <= sFSM_IN_SHIFT;
            end
            // error
            default: FSM_IN_D <= sFSM_IN_STOP;
        endcase
    end

    // fsm data out
    always @(*) begin : fsm_data_out
        // default
        FSM_OUT_D         <= FSM_OUT_Q;
        BIT_OUT_COUNT_D   <= BIT_OUT_COUNT_Q;
        RST_SHIFT_OUT_EN  <= 1'b0;
        SET_SHIFT_DATA    <= 1'b0;
        //RAM_CSb_OUT       <= 1'b1;
        OVERRIDE_RAM_ADDR <= 1'b0;
        // fsm logic
        case (FSM_OUT_Q)
            // output generation inactive
            sFSM_OUT_STOP: begin
                BIT_OUT_COUNT_D <= 10'b11_1111_1111;
                if (aSHIFT_OUT_EN == 1'b1) begin
                    RST_SHIFT_OUT_EN <= 1'b1;
                    //RAM_CSb_OUT      <= 1'b0;
                    FSM_OUT_D        <= sFSM_OUT_LOAD;
                end
            end
            // load first 32bit output data from ram
            sFSM_OUT_LOAD: begin
				BIT_OUT_COUNT_D <= 10'b00_0000_0000;
                SET_SHIFT_DATA  <= 1'b1;
                FSM_OUT_D       <= sFSM_OUT_SHIFT;
            end
            // output generation active
            sFSM_OUT_SHIFT: begin
                BIT_OUT_COUNT_D <= BIT_OUT_COUNT_Q + 1;
                // single shot: configured length reached
                if (   aOUTPUT_LOOP == 1'b0
                    && (aOUTPUT_LIMIT == 1'b1 && BIT_OUT_COUNT_Q == aOUTPUT_LEN-1)) 
                    FSM_OUT_D <= sFSM_OUT_STOP;
                // loop mode: configured length reached
                else if (   aOUTPUT_LOOP == 1'b1
                         && (aOUTPUT_LIMIT == 1'b1 && BIT_OUT_COUNT_Q == (aOUTPUT_LEN-2))) begin
                    OVERRIDE_RAM_ADDR <= 1'b1;
                    //RAM_CSb_OUT      <= 1'b0;
                    FSM_OUT_D <= sFSM_OUT_LOAD;
                // need new 32-bit data
                end else if (BIT_OUT_COUNT_Q[4:0] == 5'b1_1110) begin
                    //RAM_CSb_OUT      <= 1'b0;
                    FSM_OUT_D <= sFSM_OUT_LOAD_NEXT;
                end
            end 
            // load next 32bit output data from ram
            sFSM_OUT_LOAD_NEXT: begin
                // single shot: max or configured length reached
                if (   aOUTPUT_LOOP == 1'b0
                    && (   BIT_OUT_COUNT_Q[9:5] == 5'b1_1111
                        || (aOUTPUT_LIMIT == 1'b1 && BIT_OUT_COUNT_Q == aOUTPUT_LEN-1))) 
                        FSM_OUT_D <= sFSM_OUT_STOP;
                // loop mode: max or configured length reached
                else if (   aOUTPUT_LOOP == 1'b1
                    && (   BIT_OUT_COUNT_Q[9:5] == 5'b1_1111
                        || (aOUTPUT_LIMIT == 1'b1 && BIT_OUT_COUNT_Q == aOUTPUT_LEN-2))) begin
                        OVERRIDE_RAM_ADDR <= 1'b1;
                        //RAM_CSb_OUT      <= 1'b0;
                        FSM_OUT_D <= sFSM_OUT_LOAD;
                 // continue generating data bits
                end else begin
                    SET_SHIFT_DATA  <= 1'b1;
                    BIT_OUT_COUNT_D <= BIT_OUT_COUNT_Q + 1;
                    FSM_OUT_D <= sFSM_OUT_SHIFT;
                end
            end
            // error
            default: FSM_OUT_D <= sFSM_OUT_STOP;
        endcase
    end

    // input data path
    always @(*) begin : input_data_path
        reg vDataInMux;
        // input registers
        DATA_IN_D <= GPIO_IN[31:0];
        // input multiplexer
        vDataInMux = DATA_IN_Q[aINPUT_SEL];
        // input shift register
        SHIFT_IN_D <= {SHIFT_IN_Q[30:0], vDataInMux};
        // ram data input
        RAM_DATA_IN_i <= SHIFT_IN_Q;
    end

    // output data path
    always @(*) begin : output_data_path
        // default: output shift register
        SHIFT_OUT_D <= {SHIFT_OUT_Q[30:0], 1'b0};
        // set shift data
        if(SET_SHIFT_DATA == 1'b1) SHIFT_OUT_D <= RAM_DATA_OUT;
        // default: hold output data
        DATA_OUT_D <= DATA_OUT_Q;
        // bus write access
        if (SET_OUT_DATA == 1'b1) DATA_OUT_D <= CTRL_DATA_IN;
        // shift register input
        if (FSM_OUT_Q != sFSM_OUT_STOP) DATA_OUT_D[aOUTPUT_SEL] <= SHIFT_OUT_Q[31];
    end

    // logic for ram access
    always @(*) begin
        // default
        RAM_CSb_IN  <= 1'b1;
        RAM_CSb_OUT <= 1'b1;
        RAM_ADDR_i  <= 32'h00_00_00_00;
        if (OVERRIDE_RAM_ADDR == 1'b1) begin
            RAM_CSb_OUT <= 1'b0;
            RAM_ADDR_i  <= 32'h00_00_00_00;
        end else if (FSM_IN_Q != sFSM_IN_STOP) begin
            RAM_CSb_IN <= 1'b0; 
            RAM_ADDR_i <= {BIT_IN_COUNT_Q[9:5], 2'b00};
        end else if (FSM_OUT_Q != sFSM_OUT_STOP) begin
            RAM_CSb_OUT <= 1'b0;
            RAM_ADDR_i  <= {BIT_OUT_COUNT_Q[9:5] + 1, 2'b00};
        end
    end
    //assign RAM_ADDR = (FSM_IN_Q != sFSM_IN_STOP) ? {BIT_IN_COUNT_Q[9:5], 2'b00} : {BIT_OUT_COUNT_Q[9:5] + 1, 2'b00};
    assign RAM_CSb = RAM_CSb_IN & RAM_CSb_OUT;

    // flip flops
    always @(posedge CLK, negedge RSTb) begin : flip_flops
        if(RSTb == 1'b0) begin
            CTRL_REG_Q      <= 32'h00_00_00_00;
            DATA_IN_Q       <= 32'h00_00_00_00;
            DATA_OUT_Q      <= 32'h00_00_00_00;
            DATA_OE_Q       <= 32'h00_00_00_00;
            SHIFT_IN_Q      <= 32'h00_00_00_00;
            SHIFT_OUT_Q     <= 32'h00_00_00_00;
            FSM_IN_Q        <= sFSM_IN_STOP;
            FSM_OUT_Q       <= sFSM_OUT_STOP;
            BIT_IN_COUNT_Q  <= 10'b00_0000_0000;
            BIT_OUT_COUNT_Q <= 10'b00_0000_0000;
        end else begin
            CTRL_REG_Q  <= CTRL_REG_D;
            DATA_IN_Q   <= DATA_IN_D;
            DATA_OUT_Q  <= DATA_OUT_D; 
            DATA_OE_Q   <= DATA_OE_D; 
            SHIFT_IN_Q  <= SHIFT_IN_D;
            SHIFT_OUT_Q <= SHIFT_OUT_D;
            FSM_IN_Q    <= FSM_IN_D;
            FSM_OUT_Q   <= FSM_OUT_D;
            BIT_IN_COUNT_Q  <= BIT_IN_COUNT_D;
            BIT_OUT_COUNT_Q <= BIT_OUT_COUNT_D;
        end
    end

endmodule