module mdio_master(

    input wire clk_2m5_neg,                         //! Negated 2.5MHz clock
    input wire clk_core,                            //! Clock used for the core, sync with 2.5MHz
    input wire aReset,                              //! Asynchronous reset
    input wire i_mdio_en,                           //! MDIO enable signal, lifts clock gating
    input wire i_op_write,                          //! MDIO write operation signal
    input wire i_op_read,                           //! MDIO read operation signal
    input wire i_op_addr,                           //! MDIO address operation signal
    input wire i_op_read_inc,                       //! MDIO read and post read increment operation signal
    input wire [4:0] i_phyaddr,                     //! MDIO phyaddress
    input wire [4:0] i_addr,                        //! MDIO regaddress
    input wire [15:0] i_mmd,                        //! MDIO MMD (for CL45)
    input wire i_cl45,                              //! Clause 45 indication signal, active high
    input wire [15:0] i_data,                       //! MDIO data field
    output wire [15:0] o_data,                      //! MDIO read output

    output wire o_mdio,                             //! MDIO data pin interface
    output wire o_mdc                               //! MDIO clock pin interface


    );

    // Parameter declaration
    localparam ST_IDLE = 3'h0;                      //! MDIO FSM stays idle when it is not enabled
    localparam ST_START = 3'h1;                     //! MDIO starts when enabled and lifts clock gating
    localparam ST_SEND_PREAMBLE = 3'h2;             //! MDIO sends the first 32 high bits preamble to initiate the transaction
    localparam ST_SEND_MESSAGE = 3'h3;              //! MDIO sends the pattern
    localparam ST_TURNAROUND_WAIT = 3'h4;           //! MDIO waits the turnaround from the slave
    localparam ST_READ_RESPONSE = 3'h5;             //! If operation is a read, MDIO waits for the response after the turnaround
    localparam ST_STOP = 3'h6;                      //! Transaction is finished, now clear variables and go back in idle
    localparam ST_ERROR = 3'h7;                     //! Error state, triggered by wrong op passed

    // Reg declarations
    reg [15:0] data_out;                            //! If operation is read, this is the result in output
    reg [2:0] state;                                //! State of the MDIO fsm
    reg [2:0] state_next;                           //! Next state of the fsm
    reg mdio;                                       //! MDIO data pin
    reg mdio_next;                                  //! Next value of MDIO data pin
    reg [5:0] counter;                              //! Counter for MDIO bits (based on 2.5MHz clk)
    reg [5:0] counter_next;                         //! Next counter value
    reg counter_en;                                 //! Enable bit for MDIO bit counter
    reg preamble_en;                                //! Signal to send the preamble
    reg preamble_en_next;                           //! Next signal for preamble

    // Wire declarations
    wire [1:0] mdio_ST;                             //! ST field of MDIO message, indicates the clause. 01 for cl22, 00 for cl45
    wire [1:0] mdio_OP;                             //! OP field of MDIO message, indicates the operation
    /*
    Operation code is defined as follows:
        Clause 22:
            Write           -> 01
            Read            -> 10
        
        Clause 45:
            Address         -> 00
            Write           -> 01
            Read            -> 11
            Read + Addr     -> 10
    */
    wire [4:0] mdio_PHYADDR;                        //! PHYADDR field of MDIO message, indicates the address of the slave device
    wire [4:0] mdio_REGADDR;                        //! REGADDR field of MDIO message, indicates the target register address
    wire [1:0] mdio_TA;                             //! TA field of MDIO message, turnaround bit to allow the bus ownership to be passe from master to slave
    wire [15:0] mdio_DATA;                          //! DATA field of MDIO message, contains data. Driven by master during write and by slave during read
    wire cl_22_op_valid;                            //! Validity of CL22 operation
    wire cl45_op_valid;                             //! Validity of CL45 operation
    wire mdio_op_valid;                             //! Valid CL22 or CL45 operation
    wire mdc;                                       //! MDC internal wire, connects to the 2.5MHz negated clk


    // Wire assignments
    assign o_data = data_out;
    assign o_mdio = mdio;
    assign o_mdc = mdc;
    assign mdc = i_mdio_en ? clk_2m5_neg : 1'b0;

    assign mdio_ST = i_cl45 ? 2'b00 : 2'b01;        //! The ST field of MDIO is 01 for Clause 22 accesses and 00 for Clause 45
    assign mdio_OP = 
                     !i_cl45 ? (i_op_write ? 2'b01 : 2'b10) : //! Clause 22 operations
                     (i_op_addr ? 2'b00 :                     //! Clause 45 operations
                      i_op_write ? 2'b01 :
                      i_op_read ? 2'b11 :
                      2'b10);

    //! A clause 22 operation is considered valid if it is only one between the write or read operation, but not the cl45 ops
    assign cl22_op_valid = !i_cl45 & (i_op_write ^ i_op_read) & !(i_op_addr | i_op_read_inc);

    //! A clause 45 operation is considered valid if it is only one between all the possible operations
    assign cl45_op_valid = i_cl45 & (i_op_read ^ i_op_write ^ i_op_addr ^ i_op_read_inc) &
                                    (i_op_read | i_op_write | i_op_addr | i_op_read_inc);

    //! The MDIO operation is valid if either cl45 or cl22 operations are valid
    assign mdio_op_valid = cl22_op_valid | cl45_op_valid;

    always @(posedge clk_2m5_neg, posedge aReset) begin
        if(aReset) begin
            mdio_next <= 1'b0;

        end
        
    end

    always @(posedge clk_core, posedge aReset) begin : fsm_seq //! Sequential part of the MDIO master FSM
        if(aReset) begin
            state <= ST_IDLE;
            data_out <= 16'h0;         
        end
        else begin
            state <= state_next;
            mdio <= mdio_next;
            preamble_en <= preamble_en_next;
            
        end
    end

    always @(*) begin
        

        case (state)
            
        ST_START : begin
            mdio_next <= 1'b0;
            state_next <= ST_SEND_PREAMBLE;
        end

        ST_SEND_PREAMBLE : begin
            mdio_next <= 1'b1;
            preamble_en_next <= 1'b1;

        end

        endcase
    end

endmodule