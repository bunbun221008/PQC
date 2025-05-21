// let's goooo


// "MADD","MSUB","MMUL","MMAC","KMUL","KMAC","CT-BFO","GS-BFO","P2R",
//         "DCP1","DCP2","DCP3","MHINT","UHINT","CHKZ","CHKW0","CHKH",
//         "DCMP-1","DCMP-4","DCMP-5","DCMP-10","DCMP-11",
//         "CMP-1","CMP-4","CMP-5","CMP-10","CMP-11"
typedef enum logic [4:0] {
    MADD    = 5'd0,
    MSUB    = 5'd1,
    MMUL    = 5'd2,
    MMAC    = 5'd3,
    KMUL    = 5'd4,
    KMAC    = 5'd5,
    CT_BFO  = 5'd6,
    GS_BFO  = 5'd7,
    P2R     = 5'd8,
    DCP1    = 5'd9,
    DCP2    = 5'd10,
    DCP3    = 5'd11,
    MHINT   = 5'd12,
    UHINT   = 5'd13,
    CHKZ    = 5'd14,
    CHKW0   = 5'd15,
    CHKH    = 5'd16,
    DCMP_1  = 5'd17,
    DCMP_4  = 5'd18,
    DCMP_5  = 5'd19,
    DCMP_10 = 5'd20,
    DCMP_11 = 5'd21,
    CMP_1   = 5'd22,
    CMP_4   = 5'd23,
    CMP_5   = 5'd24,
    CMP_11  = 5'd25
} pe_instr_t;

typedef enum logic [4:0] {
    KEM_512 = 5'd0,
    KEM_768 = 5'd1,
    KEM_1024 = 5'd2,
    DSA_44 = 5'd3,
    DSA_65 = 5'd4,
    DSA_87 = 5'd5
} pe_alg_t;


module pe_array #(
    parameter NUM = 4,
    parameter OUT_NUM = 2,
    parameter IN_NUM = 3,
    parameter WIDTH = 32
) (
    input logic clk,
    input logic rst,
    input pe_alg_t alg,
    input pe_instr_t instr,
    input logic [WIDTH-1:0] data_in[0:NUM-1][0:IN_NUM-1],
    output logic [WIDTH-1:0] data_out[0:NUM-1][0:OUT_NUM-1],
);

    ///////////////////////////////// parameter declare/////////////////////////////////////
    integer i;
    logic [WIDTH-1:0] Q;
    logic [WIDTH-1:0] D;
    logic [WIDTH-1:0] Alpha;
    logic [WIDTH-1:0] Beta;
    logic [WIDTH-1:0] Gamma1;
    logic [WIDTH-1:0] Gamma2;


    ////////////////////////////////// madd declare ////////////////////////////////////
    logic [WIDTH-1:0] madd_in0[0:NUM-1], madd_in1[0:NUM-1];
    logic [WIDTH-1:0] madd_cmp[0:NUM-1], madd_sft[0:NUM-1];
    logic [WIDTH-1:0] madd_add[0:NUM-1], madd_sub[0:NUM-1];
    logic [WIDTH-1:0] madd_out_w[0:NUM-1], madd_out_r[0:NUM-1];


    ////////////////////////////////// msub declare ////////////////////////////////////
    logic [WIDTH-1:0] msub_in0[0:NUM-1], msub_in1[0:NUM-1];
    logic [WIDTH-1:0] msub_cmp[0:NUM-1];
    logic [WIDTH-1:0] msub_add[0:NUM-1], msub_sub[0:NUM-1];
    logic [WIDTH-1:0] msub_out_w[0:NUM-1], msub_out_r[0:NUM-1];

    

    ////////////////////////////////////////// madd /////////////////////////////////////
    always_comb begin
        for (i = 0; i < NUM; i++) madd_out_w[i] = madd_sft[i];

        case (instr)
            MADD: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i] + madd_in1[i];
                    madd_cmp[i] = (madd_add[i] >= Q)? Q : 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            ADD: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i] + madd_in1[i];
                    madd_cmp[i] = 0
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            P2R: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i] + ((1<<(D-1)) - 1);
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i] >> D;
                end
            end
                
            DCP1: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i] + 127;
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i] >> 7;
                end
            end
                
            DCP2, DCMP-1, DCMP-4, DCMP-5, DCMP-10, DCMP-11, CMP-1, CMP-4, CMP-5, CMP-10, CMP-11: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i] + 1;
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i] >> 1;
                end
            end
               
            DCP3: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (((Q-1)>>1) >= madd_add[i])? 1:0;
                    madd_sub[i] = madd_cmp[i] & (madd_add[i] != 0);
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            MHINT: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = ((Q - 1 - Gamma2) >= madd_add[i])? 1:0;
                    madd_sub[i] = madd_cmp[i] | ((madd_in1[i] != 0)<<1);
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            UHINT: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= 1)? (Alpha - 1):0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = (madd_in1[i][0])? madd_sub[i]:0;
                end
            end
                
            CHKZ: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma1 - Beta))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            CHKW0: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma2 - Beta))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            CHKH: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma2))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            default: begin
                for (i = 0; i < NUM; i++) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma2))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end
        endcase
    end

    ////////////////////////////////////////// msub /////////////////////////////////////
    always_comb begin
        for (i = 0; i < NUM; i++) msub_out_w[i] = msub_add[i];

        case (instr)
            MSUB: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end
                
            KMUL, KMAC: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - Q;
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            DCP2: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - Alpha;
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Alpha : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_1: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - (1<<1);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<1) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_4: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - (1<<4);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<4) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_5: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - (1<<5);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<5) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_10: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - (1<<10);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<10) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_11: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - (1<<11);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<11) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end
               
            MHINT: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = (msub_sub[i] >= (Gamma2 + 1))? 1 : 0;
                    msub_add[i] = msub_cmp[i] | ((msub_sub[i] == (Q-Gamma2))<<1);
                end
            end
                
            UHINT: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Alpha : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end
                
            CHKZ: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - (Gamma1 - Beta)) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end

            CHKW0: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - (Gamma2 - Beta)) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end

            CHKH: begin
                for (i = 0; i < NUM; i++) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - Gamma2) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end
        endcase
    end


    ///////////////////////////////////// sequential circuits //////////////////////////////
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM; i++) begin
                madd_out_r[i] <= 0;
                msub_out_r[i] <= 0;
            end
        end else begin
            for (int i = 0; i < NUM; i++) begin
                madd_out_r[i] <= madd_out_w[i];
                msub_out_r[i] <= msub_out_w[i];
            end
        end
    end

endmodule

