module ALU_unit #(
    parameter STAGE = 6,
    parameter D_WIDTH   = 64, //datas
	parameter N_MAX     = 20,
    parameter N_MIN     = 10,
    parameter A_MAX     = 61,
    parameter PA_WIDTH  = 6,
    parameter PN_WIDTH  = 5,
    parameter PK_WIDTH  = 16,
    parameter PREC_WIDTH = 6
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [4:0]              opcode,  //1bit constant + 3bit mode
    // prime dat for reducer
    input  logic [D_WIDTH-1:0]      mask_n,
    input  logic [D_WIDTH-1:0]      mask_a,
    input  logic [PN_WIDTH-1:0]     pn,
    input  logic [PK_WIDTH-1:0]     pk,
    input  logic [PA_WIDTH-1:0]     pa,
    input  logic [PREC_WIDTH-1:0]   precm1,
    input  logic [PA_WIDTH-1:0]     am2n,
    input  logic [PA_WIDTH-1:0]     amn,   
    // alu data
    input  logic valid_i,
    output logic valid_o,
    input  logic [D_WIDTH-1:0]      alu_in0,
    input  logic [D_WIDTH-1:0]      alu_in1,
    input  logic [D_WIDTH-1:0]      alu_inq,
    output logic [D_WIDTH-1:0]      alu_out0,
    output logic [D_WIDTH-1:0]      alu_out1
);  
    
    //--------------------------------------------------------Arithmetic---------------------------------------------------//
    logic [  D_WIDTH-1:0] mul_i0, mul_i1;
    logic [2*D_WIDTH-1:0] mul_o;
    assign mul_o = $signed(mul_i0)*$signed(mul_i1);
    logic [D_WIDTH-1:0] addsub_i0, addsub_i1;
    logic [D_WIDTH-1:0] add_o, sub_o;
    assign add_o = $signed(addsub_i0) + $signed(addsub_i1);
    assign sub_o = $signed(addsub_i0) - $signed(addsub_i1);
    //---------------------------------------------------------buffer------------------------------------------------------//
    localparam BUF_LEN = 9;
    logic [D_WIDTH-1:0] dat_r[0:BUF_LEN-1], dat_w[0:BUF_LEN-1];
    logic [3:0] mode_r[0:STAGE-1], mode_w[0:STAGE-1];
    logic const_r[0:STAGE-1], const_w[0:STAGE-1];
    logic valid_r[0:STAGE-1], valid_w[0:STAGE-1];


    //---------------------------------------------------------reducer-----------------------------------------------------//
    logic [2:0] rd_mode_r, rd_mode_w;
    logic [2*D_WIDTH-1:0] rd_in_r, rd_in_w;
    wire [D_WIDTH-1:0] rd_out;

    reducer RD(
        .clk    (clk),
        .rst_n  (rst_n      ),
        .mode   (rd_mode_r  ),
        .mask_n (mask_n     ),
        .mask_a (mask_a     ),
        .pn     (pn         ),
        .pk     (pk         ),
        .pa     (pa         ),
        .precm1 (precm1     ), 
        .am2n   (am2n       ), 
        .amn    (amn        ), 
        .c_in   (rd_in_r    ),
        .c_out  (rd_out     )
    );


    //-------------------------------------------------------Buffer & FSM--------------------------------------------------//
    // ALU mode
    localparam A_IDLE = 0;
    localparam A_ADD = 1;
    localparam A_SUB = 2;
    localparam A_MUL = 3;
    localparam A_MMUL = 4;
    localparam A_MAC = 5;
    localparam A_MMAC = 6;
    localparam A_BFU = 7;
    localparam A_IBFU = 8;
    localparam A_RED = 9;
    localparam A_ROUND = 10;
    // reducer mode
    localparam R_IDLE = 0;
    localparam R_MRED = 1;
    localparam R_RED = 2;
    localparam R_RED64 = 3;
    localparam R_ROUND = 4;
    
    assign alu_out0 = dat_r[BUF_LEN-2];
    assign alu_out1 = dat_r[BUF_LEN-1];
    assign valid_o = valid_r[STAGE-1];
    always_comb begin
        mode_w[0] = opcode[3:0];
        const_w[0] = opcode[4];
        valid_w[0] = valid_i;
        for(int i=1;i<STAGE;i=i+1) mode_w[i] = mode_r[i-1];
        for(int i=1;i<STAGE;i=i+1) const_w[i] = const_r[i-1];
        for(int i=1;i<STAGE;i=i+1) valid_w[i] = valid_r[i-1];
    end
    // stage 0: ADD/SUB
    always_comb begin
        case(mode_w[0])
            A_ADD: begin
                dat_w[0] = add_o;
                dat_w[1] = dat_r[1];
                dat_w[2] = dat_r[2];
            end
            A_SUB: begin
                dat_w[0] = sub_o;
                dat_w[1] = dat_r[1];
                dat_w[2] = dat_r[2];
            end
            A_MUL, A_MMUL, A_MAC, A_MMAC: begin
                dat_w[0] = alu_in0;
                dat_w[1] = alu_in1;
                dat_w[2] = alu_inq;
            end
            A_BFU: begin
                dat_w[0] = alu_in0;
                dat_w[1] = alu_in1;
                dat_w[2] = alu_inq;
            end
            A_IBFU: begin
                dat_w[0] = add_o;
                dat_w[1] = sub_o;
                dat_w[2] = alu_inq;
            end
            A_RED, A_ROUND: begin
                dat_w[0] = alu_in0;
                dat_w[1] = dat_r[1];
                dat_w[2] = dat_r[2];
            end
            default: begin
                for(int i=0;i<3;i=i+1) dat_w[i] = dat_r[i];
            end
        endcase
    end
    
    // stage 1: MUL
    always_comb begin
        case(mode_r[0])
            A_ADD, A_SUB: begin
                dat_w[3] = dat_r[0];
                rd_in_w = 0;
                mul_i0 = 0;
                mul_i1 = 0;
                rd_mode_w = R_IDLE;
            end
            A_MUL, A_MAC: begin
                dat_w[3] = dat_r[3];
                rd_in_w = mul_o;
                mul_i0 = dat_r[0];
                mul_i1 = (const_r[0])? dat_r[2] : dat_r[1];
                rd_mode_w = R_RED64;
            end
            A_MMUL, A_MMAC: begin
                dat_w[3] = dat_r[3];
                rd_in_w = mul_o;
                mul_i0 = dat_r[0];
                mul_i1 = (const_r[0])? dat_r[2] : dat_r[1];
                rd_mode_w = R_MRED;
            end
            A_BFU: begin
                dat_w[3] = dat_r[0]; //a
                rd_in_w = mul_o;     //b*q
                mul_i0 = dat_r[1];
                mul_i1 = dat_r[2];
                rd_mode_w = R_MRED;
            end
            A_IBFU: begin
                dat_w[3] = dat_r[0]; //a+b
                rd_in_w = mul_o;     //(a-b)*q
                mul_i0 = dat_r[1];
                mul_i1 = dat_r[2];
                rd_mode_w = R_MRED;
            end
            A_RED: begin
                dat_w[3] = dat_r[3];
                rd_in_w = $signed(dat_r[0]);
                mul_i0 = 0;
                mul_i1 = 0;
                rd_mode_w = R_RED;
            end
            A_ROUND: begin
                dat_w[3] = dat_r[3];
                rd_in_w = $signed(dat_r[0]);
                mul_i0 = 0;
                mul_i1 = 0;
                rd_mode_w = R_ROUND;
            end
            default: begin
                for(int i=3;i<4;i=i+1) dat_w[i] = dat_r[i];
                rd_in_w = 0;
                mul_i0 = 0;
                mul_i1 = 0;
                rd_mode_w = R_IDLE;
            end
        endcase
    end

    // stage 2-4: reducer 
    //assign rd_valid_i = valid_r[1];
    always_comb begin
        dat_w[4] = dat_r[3];
        dat_w[5] = dat_r[4];
        dat_w[6] = dat_r[5];
    end

    // stage 5: ADD/SUB
    always_comb begin
        case(mode_r[4])
            A_ADD, A_SUB: begin
                dat_w[7] = dat_r[6];
                dat_w[8] = dat_r[8];
            end
            A_MUL, A_MMUL: begin
                dat_w[7] = rd_out;
                dat_w[8] = dat_r[8];
            end
            A_MAC, A_MMAC: begin
                dat_w[7] = add_o;
                dat_w[8] = dat_r[8];
            end
            A_BFU: begin
                dat_w[7] = add_o; //a+(b*q)
                dat_w[8] = sub_o; //a-(b*q)
            end
            A_IBFU: begin
                dat_w[7] = dat_r[6]; //a+b
                dat_w[8] = rd_out;   //(a-b)*q
            end
            A_RED, A_ROUND: begin
                dat_w[7] = rd_out; 
                dat_w[8] = dat_r[8];   
            end
            default: begin
                for(int i=7;i<9;i=i+1) dat_w[i] = dat_r[i];
            end
        endcase
    end

    // MAC/MMAC/IBFU should always after function that needs add/sub
    // when launching functions that needs add/sub, make sure the previous functions are not MAC/MMAC/IBFU
    // ohterwise bubbles (idle) cycles are required

    // ADD/SUB module
    always_comb begin
        if(mode_r[4]==A_BFU) begin
            addsub_i0 = dat_r[6];
            addsub_i1 = rd_out;
        end
        else if((mode_r[4]==A_MAC)||(mode_r[4]==A_MMAC)) begin
            addsub_i0 = dat_r[7];
            addsub_i1 = rd_out;
        end
        else if((mode_w[0]==A_ADD)||(mode_w[0]==A_SUB)||(mode_w[0]==A_IBFU)) begin
            addsub_i0 = alu_in0;
            addsub_i1 = alu_in1;            
        end
        else begin
            addsub_i0 = 0;
            addsub_i1 = 0; 
        end
    end
    

    //---------------------------------------------------------- FF -------------------------------------------------------//
    always_ff @(posedge clk) begin
        if(~rst_n) begin
            rd_in_r <= 0;
            rd_mode_r <= 0;
            for(int i=0;i<BUF_LEN;i=i+1) dat_r[i] <= 0;
            for(int i=0;i<STAGE;i=i+1) mode_r[i] <= 0;
            for(int i=0;i<STAGE;i=i+1) const_r[i] <= 0;
            for(int i=0;i<STAGE;i=i+1) valid_r[i] <= 0;
        end
        else begin
            rd_in_r <= rd_in_w;
            rd_mode_r <= rd_mode_w;
            for(int i=0;i<BUF_LEN;i=i+1) dat_r[i] <= dat_w[i];
            for(int i=0;i<STAGE;i=i+1) mode_r[i] <= mode_w[i];
            for(int i=0;i<STAGE;i=i+1) const_r[i] <= const_w[i];
            for(int i=0;i<STAGE;i=i+1) valid_r[i] <= valid_w[i];
        end
    end

endmodule