
// typedef enum logic [4:0] {
//     MADD    = 5'd0,
//     MSUB    = 5'd1,
//     MMUL    = 5'd2,
//     MMAC    = 5'd3,
//     PREMUL  = 5'd4,
//     KMUL    = 5'd5,
//     KMAC    = 5'd6,
//     NTT     = 5'd7,
//     INTT    = 5'd8,
//     P2R     = 5'd9,
//     DCP1    = 5'd10,
//     DCP2    = 5'd11,
//     DCP3    = 5'd12,
//     DCP4    = 5'd13,
//     MHINT   = 5'd14,
//     UHINT   = 5'd15,
//     CHKZ    = 5'd16,
//     CHKW0   = 5'd17,
//     CHKH    = 5'd18,
//     NEQL    = 5'd19,
//     DCMP_1  = 5'd20,
//     DCMP_4  = 5'd21,
//     DCMP_5  = 5'd22,
//     DCMP_10 = 5'd23,
//     DCMP_11 = 5'd24,
//     CMP_1   = 5'd25,
//     CMP_4   = 5'd26,
//     CMP_5   = 5'd27,
//     CMP_10  = 5'd28,
//     CMP_11  = 5'd29,
//     SHFL    = 5'd30,
//     BYPASS  = 5'd31
// } pe_instr_t;

// typedef enum logic [4:0] {
//     KEM_512 = 5'd0,
//     KEM_768 = 5'd1,
//     KEM_1024 = 5'd2,
//     DSA_44 = 5'd3,
//     DSA_65 = 5'd4,
//     DSA_87 = 5'd5
// } pe_alg_t;


module pe_array #(
    parameter NUM = 4,
    parameter OUT_NUM = 2,
    parameter IN_NUM = 3,
    parameter WIDTH = 24
) (
    input logic clk,
    input logic rst,
    input pe_alg_t alg,
    input pe_instr_t instr,
    input logic [WIDTH-1:0] data_in[0:NUM-1][0:IN_NUM-1],
    output logic [WIDTH-1:0] data_out[0:NUM-1][0:OUT_NUM-1]
);

    ///////////////////////////////// parameter declare/////////////////////////////////////
    logic [WIDTH-1:0] Q;
    logic [WIDTH-1:0] D;
    logic [WIDTH-1:0] Alpha;
    logic [WIDTH-1:0] Beta;
    logic [WIDTH-1:0] Gamma1;
    logic [WIDTH-1:0] Gamma2;
    logic [WIDTH-1:0] D_sub1_ls1_sub1; // (1 << (D - 1)) - 1
    logic [WIDTH-1:0] Q_sub1_rs1; // (Q - 1) >> 1
    logic [WIDTH-1:0] Q_sub1_subGamma2; // Q - 1 - Gamma2
    logic [WIDTH-1:0] Gamma1_subBeta; // Gamma1 - Beta
    logic [WIDTH-1:0] Alpha_sub1; // Alpha - 1
    logic [WIDTH-1:0] Gamma2_add1; // Gamma2 + 1
    logic [WIDTH-1:0] Q_subGamma2; // (Q-Gamma2)
    logic [WIDTH-1:0] Q_subGamma1_addBeta; // Q - (Gamma1 - Beta)
    logic [WIDTH-1:0] Q_subGamma2_addBeta; // Q - (Gamma2 - Beta)
    logic [WIDTH-1:0] Alpha_eql16_1025or11275; // (Alpha == 16)? 1025 : 11275
    logic [WIDTH-1:0] Alpha_eql16_21or23; // (Alpha == 16)? 21 : 23




    ////////////////////////////////// madd declare ////////////////////////////////////
    logic [WIDTH-1:0] madd_in0[0:NUM-1], madd_in1[0:NUM-1];
    logic [WIDTH-1:0] madd_cmp[0:NUM-1], madd_sft[0:NUM-1], madd_add[0:NUM-1], madd_sub[0:NUM-1];
    logic [WIDTH-1:0] madd_out_w[0:NUM-1], madd_out_r[0:NUM-1];

    logic [WIDTH-1:0] madd_add_in0[0:NUM-1], madd_add_in1[0:NUM-1], madd_add_out[0:NUM-1];
    logic [WIDTH-1:0] madd_cmp_in0[0:NUM-1], madd_cmp_in1[0:NUM-1], madd_cmp_out[0:NUM-1];
    logic [WIDTH-1:0] madd_sub_in0[0:NUM-1], madd_sub_in1[0:NUM-1], madd_sub_out[0:NUM-1];
    logic [WIDTH-1:0] madd_sft_in0[0:NUM-1], madd_sft_in1[0:NUM-1], madd_sft_out[0:NUM-1];

    ////////////////////////////////// msub declare ////////////////////////////////////
    logic [WIDTH-1:0] msub_in0[0:NUM-1], msub_in1[0:NUM-1];
    logic [WIDTH-1:0] msub_cmp[0:NUM-1], msub_add[0:NUM-1], msub_sub[0:NUM-1];
    logic [WIDTH-1:0] msub_out_w[0:NUM-1], msub_out_r[0:NUM-1];

    logic [WIDTH-1:0] msub_add_in0[0:NUM-1], msub_add_in1[0:NUM-1], msub_add_out[0:NUM-1];
    logic [WIDTH-1:0] msub_cmp_in0[0:NUM-1], msub_cmp_in1[0:NUM-1], msub_cmp_out[0:NUM-1];
    logic [WIDTH-1:0] msub_sub_in0[0:NUM-1], msub_sub_in1[0:NUM-1], msub_sub_out[0:NUM-1];

    /////////////////////////////////// mmul declare ///////////////////////////////////
    logic [WIDTH-1:0] mmul_in0[0:NUM-1], mmul_in1[0:NUM-1];
    logic [2*WIDTH-1:0] mmul_mul_w[0:NUM-1], mmul_mul_r[0:NUM-1];
    logic [2*WIDTH-1:0] mmul_add_w[0:NUM-1], mmul_add_r[0:NUM-1];
    logic [2*WIDTH-1:0] mmul_red[0:NUM-1], mmul_red_in[0:NUM-1], mmul_sft[0:NUM-1];
    logic [WIDTH-1:0] MR_output[0:NUM-1];
    logic [WIDTH-1:0] mmul_out_w[0:NUM-1], mmul_out_r[0:NUM-1];

    logic [WIDTH-1:0] mmul_mul_in0[0:NUM-1], mmul_mul_in1[0:NUM-1];
    logic [2*WIDTH-1:0] mmul_mul_out[0:NUM-1];
    logic mmul_dplx_mode;
    // sft
    logic [2*WIDTH-1:0] mmul_sft_in0[0:NUM-1], mmul_sft_in1[0:NUM-1], mmul_sft_out[0:NUM-1];

    ////////////////////////////// data_in, data_out pipeline declare //////////////////////////////////
    logic [WIDTH-1:0] data_in_p1_w[0:NUM-1][0:IN_NUM-1], data_in_p1_r[0:NUM-1][0:IN_NUM-1];
    logic [WIDTH-1:0] data_in_p2_w[0:NUM-1][0:IN_NUM-1], data_in_p2_r[0:NUM-1][0:IN_NUM-1];
    logic [WIDTH-1:0] data_in_p3_w[0:NUM-1][0:IN_NUM-1], data_in_p3_r[0:NUM-1][0:IN_NUM-1];
    logic [WIDTH-1:0] data_in_p4_w[0:NUM-1][0:IN_NUM-1], data_in_p4_r[0:NUM-1][0:IN_NUM-1];
    logic [WIDTH-1:0] data_in_p5_w[0:NUM-1][0:IN_NUM-1], data_in_p5_r[0:NUM-1][0:IN_NUM-1];
    logic [WIDTH-1:0] data_in_p6_w[0:NUM-1][0:IN_NUM-1], data_in_p6_r[0:NUM-1][0:IN_NUM-1];

    logic [WIDTH-1:0] data_out_p1_w[0:NUM-1][0:OUT_NUM-1], data_out_p1_r[0:NUM-1][0:OUT_NUM-1];
    logic [WIDTH-1:0] data_out_p2_w[0:NUM-1][0:OUT_NUM-1], data_out_p2_r[0:NUM-1][0:OUT_NUM-1];
    logic [WIDTH-1:0] data_out_p3_w[0:NUM-1][0:OUT_NUM-1], data_out_p3_r[0:NUM-1][0:OUT_NUM-1];
    logic [WIDTH-1:0] data_out_p4_w[0:NUM-1][0:OUT_NUM-1], data_out_p4_r[0:NUM-1][0:OUT_NUM-1];
    logic [WIDTH-1:0] data_out_p5_w[0:NUM-1][0:OUT_NUM-1], data_out_p5_r[0:NUM-1][0:OUT_NUM-1];
    logic [WIDTH-1:0] data_out_p6_w[0:NUM-1][0:OUT_NUM-1], data_out_p6_r[0:NUM-1][0:OUT_NUM-1];

    /////////////////////////////////////////// parameter assign ////////////////////////
    always_comb begin
        case (alg)
            KEM_512: begin
                Q = 3329;
                D = 13;
                Alpha = 16;
                Beta = 120;
                Gamma1 = 1<<19;
                Gamma2 = 104;
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  1664;
                Q_sub1_subGamma2 =  3224;
                Gamma1_subBeta =  524168;
                Alpha_sub1 =  15;
                Gamma2_add1 =  105;
                Q_subGamma2 =  3225;
                Q_subGamma1_addBeta =  -520839;
                Q_subGamma2_addBeta =  3345;
                Alpha_eql16_1025or11275 =  1025;
                Alpha_eql16_21or23 =  21;
            end
            KEM_768: begin
                Q = 3329;
                D = 13;
                Alpha = 16;
                Beta = 120;
                Gamma1 = 1<<19;
                Gamma2 = 104;
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  1664;
                Q_sub1_subGamma2 =  3224;
                Gamma1_subBeta =  524168;
                Alpha_sub1 =  15;
                Gamma2_add1 =  105;;
                Q_subGamma2 =  3225;
                Q_subGamma1_addBeta =  -520839;
                Q_subGamma2_addBeta =  3345;
                Alpha_eql16_1025or11275 =  1025;
                Alpha_eql16_21or23 =  21;
            end
            KEM_1024: begin
                Q = 3329;
                D = 13;
                Alpha = 16;
                Beta = 120;
                Gamma1 = 1<<19;
                Gamma2 = 104;
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  1664;
                Q_sub1_subGamma2 =  3224;
                Gamma1_subBeta =  524168;
                Alpha_sub1 =  15;
                Gamma2_add1 =  105;
                Q_subGamma2 =  3225;
                Q_subGamma1_addBeta =  -520839;
                Q_subGamma2_addBeta =  3345;
                Alpha_eql16_1025or11275 =  1025;
                Alpha_eql16_21or23 =  21;
            end
            DSA_44: begin
                Q = 8380417;
                D = 13;
                Alpha = 44;
                Beta = 78;
                Gamma1 = 1<<17;
                Gamma2 = 95232;
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  4190208;
                Q_sub1_subGamma2 =  8285184;
                Gamma1_subBeta =  130994;
                Alpha_sub1 =  43;
                Gamma2_add1 =  95233;
                Q_subGamma2 =  8285185;
                Q_subGamma1_addBeta =  8249423;
                Q_subGamma2_addBeta =  8285263;
                Alpha_eql16_1025or11275 =  11275;
                Alpha_eql16_21or23 =  23;
            end
            DSA_65: begin
                Q = 8380417;
                D = 13;
                Alpha = 16;
                Beta = 196;
                Gamma1 = 1<<19;
                Gamma2 = 261888; 
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  4190208;
                Q_sub1_subGamma2 =  8118528;
                Gamma1_subBeta =  524092;
                Alpha_sub1 =  15;
                Gamma2_add1 =  261889;
                Q_subGamma2 =  8118529;
                Q_subGamma1_addBeta =  7856325;
                Q_subGamma2_addBeta =  8118725;
                Alpha_eql16_1025or11275 =  1025;
                Alpha_eql16_21or23 =  21;
            end
            DSA_87: begin
                Q = 8380417;
                D = 13;
                Alpha = 16; 
                Beta = 120; 
                Gamma1 = 1<<19; 
                Gamma2 = 261888; 
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  4190208;
                Q_sub1_subGamma2 =  8118528;
                Gamma1_subBeta =  524168;
                Alpha_sub1 =  15;
                Gamma2_add1 =  261889;
                Q_subGamma2 =  8118529;
                Q_subGamma1_addBeta =  7856249;
                Q_subGamma2_addBeta =  8118649;
                Alpha_eql16_1025or11275 =  1025;
                Alpha_eql16_21or23 =  21;
            end
            default: begin
                Q = 8380417;
                D = 13;
                Alpha = 16; 
                Beta = 120; 
                Gamma1 = 1<<19; 
                Gamma2 = 261888; 
                D_sub1_ls1_sub1 =  4095;
                Q_sub1_rs1 =  4190208;
                Q_sub1_subGamma2 =  8118528;
                Gamma1_subBeta =  524168;
                Alpha_sub1 =  15;
                Gamma2_add1 =  261889;
                Q_subGamma2 =  8118529;
                Q_subGamma1_addBeta =  7856249;
                Q_subGamma2_addBeta =  8118649;
                Alpha_eql16_1025or11275 =  1025;
                Alpha_eql16_21or23 =  21;
            end
        endcase
        // D_sub1_ls1_sub1 = (1 << (D - 1)) - 1;
        // Q_sub1_rs1 = (Q - 1) >> 1;
        // Q_sub1_subGamma2 = Q - 1 - Gamma2;
        // Gamma1_subBeta = Gamma1 - Beta;
        // Alpha_sub1 = Alpha - 1;
        // Gamma2_add1 = Gamma2 + 1;
        // Q_subGamma2 = (Q-Gamma2);
        // Q_subGamma1_addBeta = Q - (Gamma1 - Beta);
        // Q_subGamma2_addBeta = Q - (Gamma2 - Beta);
        // Alpha_eql16_1025or11275 = (Alpha == 16)? 1025 : 11275;
        // Alpha_eql16_21or23 = (Alpha == 16)? 21 : 23;
    end

    ////////////////////////////////////////// madd ///////////////////////////////////
    genvar gi;
    generate
        for (gi = 0; gi < NUM; gi = gi + 1) begin : MADD_ARRAY
            assign madd_add_out[gi] = madd_add_in0[gi] + madd_add_in1[gi];
            assign madd_cmp_out[gi] = madd_cmp_in0[gi] >= madd_cmp_in1[gi];
            assign madd_sub_out[gi] = madd_sub_in0[gi] - madd_sub_in1[gi];
            assign madd_sft_out[gi] = madd_sft_in0[gi] >> madd_sft_in1[gi];
        end
    endgenerate

    always_comb begin // madd
        integer i, j;
        //default values
        for (i = 0; i < NUM; i = i+1) begin
            // madd_add[i] = madd_in0[i] + madd_in1[i];
            madd_add_in0[i] = madd_in0[i];
            madd_add_in1[i] = madd_in1[i];
            madd_add[i] = madd_add_out[i];
            // madd_cmp[i] = (madd_add[i] >= Q)? Q : 0;
            madd_cmp_in0[i] = madd_add[i];
            madd_cmp_in1[i] = Q;
            madd_cmp[i] = (madd_cmp_out[i])? Q : 0;
            // madd_sub[i] = madd_add[i] - madd_cmp[i];
            madd_sub_in0[i] = madd_add[i];
            madd_sub_in1[i] = madd_cmp[i];
            madd_sub[i] = madd_sub_out[i];

            // madd_sft[i] = madd_sub[i];
            madd_sft_in0[i] = madd_sub[i];
            madd_sft_in1[i] = 0;
            madd_sft[i] = madd_sft_out[i];
        end

        case (instr)
            MADD, MMAC, KMAC, NTT, INTT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // madd_add[i] = madd_in0[i] + madd_in1[i];
                    madd_add_in0[i] = madd_in0[i];
                    madd_add_in1[i] = madd_in1[i];
                    madd_add[i] = madd_add_out[i];
                    // madd_cmp[i] = (madd_add[i] >= Q)? Q : 0;
                    madd_cmp_in0[i] = madd_add[i];
                    madd_cmp_in1[i] = Q;
                    madd_cmp[i] = (madd_cmp_out[i])? Q : 0;
                    // madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sub_in0[i] = madd_add[i];
                    madd_sub_in1[i] = madd_cmp[i];
                    madd_sub[i] = madd_sub_out[i];
                    // madd_sft[i] = madd_sub[i];
                    madd_sft_in0[i] = madd_sub[i];
                    madd_sft_in1[i] = 0;
                    madd_sft[i] = madd_sft_out[i];
                end
            end
                
            P2R: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // madd_add[i] = madd_in0[i] + ((1<<(D-1)) - 1);
                    madd_add_in0[i] = madd_in0[i];
                    madd_add_in1[i] = D_sub1_ls1_sub1; //(1 << (D - 1)) - 1
                    madd_add[i] = madd_add_out[i];
                    madd_cmp[i] = 0;
                    // madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sub_in0[i] = madd_add[i];
                    madd_sub_in1[i] = madd_cmp[i];
                    madd_sub[i] = madd_sub_out[i];
                    // madd_sft[i] = madd_sub[i] >> D;
                    madd_sft_in0[i] = madd_sub[i];
                    madd_sft_in1[i] = D;
                    madd_sft[i] = madd_sft_out[i];
                end
            end
                
            DCP1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // madd_add[i] = madd_in0[i] + 127;
                    madd_add_in0[i] = madd_in0[i];
                    madd_add_in1[i] = 127;
                    madd_add[i] = madd_add_out[i];
                    madd_cmp[i] = 0;
                    // madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sub_in0[i] = madd_add[i];
                    madd_sub_in1[i] = madd_cmp[i];
                    madd_sub[i] = madd_sub_out[i];
                    // madd_sft[i] = madd_sub[i] >> 7;
                    madd_sft_in0[i] = madd_sub[i];
                    madd_sft_in1[i] = 7;
                    madd_sft[i] = madd_sft_out[i];
                end
            end
                
            DCP2, DCMP_1, DCMP_4, DCMP_5, DCMP_10, DCMP_11, CMP_1, CMP_4, CMP_5, CMP_10, CMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // madd_add[i] = madd_in0[i] + 1;
                    madd_add_in0[i] = madd_in0[i];
                    madd_add_in1[i] = 1;
                    madd_add[i] = madd_add_out[i];
                    madd_cmp[i] = 0;
                    // madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sub_in0[i] = madd_add[i];
                    madd_sub_in1[i] = madd_cmp[i];
                    madd_sub[i] = madd_sub_out[i];
                    // madd_sft[i] = madd_sub[i] >> 1;
                    madd_sft_in0[i] = madd_sub[i];
                    madd_sft_in1[i] = 1;
                    madd_sft[i] = madd_sft_out[i];
                end
            end
               
            DCP4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = (((Q-1)>>1) >= madd_add[i])? 1:0;
                    madd_cmp_in0[i] = Q_sub1_rs1; // (Q - 1) >> 1
                    madd_cmp_in1[i] = madd_add[i];
                    madd_cmp[i] = (madd_cmp_out[i])? 1 : 0;

                    madd_sub[i] = madd_cmp[i] & (madd_add[i] != 0);

                    madd_sft[i] = madd_sub[i];
                end
            end

            NEQL: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] != 0;
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            MHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = ((Q - 1 - Gamma2) >= madd_add[i])? 1:0;
                    madd_cmp_in0[i] = Q_sub1_subGamma2; // Q - 1 - Gamma2
                    madd_cmp_in1[i] = madd_add[i];
                    madd_cmp[i] = (madd_cmp_out[i])? 1 : 0;
                
                    madd_sub[i] = madd_cmp[i] | ((madd_in1[i] != 0)<<1);
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            UHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = (madd_add[i] >= 1)? (Alpha - 1):0;
                    madd_cmp_in0[i] = madd_add[i];
                    madd_cmp_in1[i] = 1;
                    madd_cmp[i] = (madd_cmp_out[i])? Alpha_sub1 : 0; // Alpha - 1

                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = (madd_in1[i][0])? madd_sub[i]:0;
                end
            end
                
            CHKZ: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = (madd_add[i] >= (Gamma1 - Beta))? 1:0;
                    madd_cmp_in0[i] = madd_add[i];
                    madd_cmp_in1[i] = Gamma1_subBeta; // Gamma1 - Beta
                    madd_cmp[i] = (madd_cmp_out[i])? 1 : 0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            CHKW0: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = (madd_add[i] >= (Gamma2 - Beta))? 1:0;
                    madd_cmp_in0[i] = madd_add[i];
                    madd_cmp_in1[i] = Gamma1_subBeta; // Gamma1 - Beta
                    madd_cmp[i] = (madd_cmp_out[i])? 1 : 0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            CHKH: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = (madd_add[i] >= (Gamma2))? 1:0;
                    madd_cmp_in0[i] = madd_add[i];
                    madd_cmp_in1[i] = Gamma2;
                    madd_cmp[i] = (madd_cmp_out[i])? 1 : 0;

                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    // madd_cmp[i] = (madd_add[i] >= (Gamma2))? 1:0;
                    madd_cmp_in0[i] = madd_add[i];
                    madd_cmp_in1[i] = Gamma2;
                    madd_cmp[i] = (madd_cmp_out[i])? 1 : 0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end
        endcase

        for (i = 0; i < NUM; i = i+1) madd_out_w[i] = madd_sft[i];
    end

    ////////////////////////////////////////// msub ///////////////////////////////////
    generate
        for (gi = 0; gi < NUM; gi = gi + 1) begin : MSUB_ARRAY
            assign msub_sub_out[gi] = msub_sub_in0[gi] - msub_sub_in1[gi];
            assign msub_cmp_out[gi] = msub_cmp_in0[gi] >= msub_cmp_in1[gi];
            assign msub_add_out[gi] = msub_add_in0[gi] + msub_add_in1[gi];
        end
    endgenerate

    always_comb begin //msub
        integer i, j;
        for (i = 0; i < NUM; i = i+1) begin
            // msub_sub[i] = msub_in0[i] - msub_in1[i];
            msub_sub_in0[i] = msub_in0[i];
            msub_sub_in1[i] = msub_in1[i];
            msub_sub[i] = msub_sub_out[i];

            // msub_cmp[i] = (msub_sub[i] >= (Gamma2 + 1))? 1 : 0;
            msub_cmp_in0[i] = msub_sub[i];
            msub_cmp_in1[i] = Gamma2_add1; // Gamma2 + 1
            msub_cmp[i] = (msub_cmp_out[i])? 1 : 0;

            // msub_add[i] = msub_sub[i] + msub_cmp[i];
            msub_add_in0[i] = msub_sub[i];
            msub_add_in1[i] = msub_cmp[i];
            msub_add[i] = msub_add_out[i];
        end

        case (instr)
            MSUB, NTT, INTT, DCP3, DCP4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = msub_in1[i];
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;

                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];
                end
            end

            P2R: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - (msub_in1[i] << D);
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = (msub_in1[i] << D);
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;

                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];
                end
            end

            SHFL: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = (msub_in1[i] << D);
                    msub_cmp[i] = 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];
                end
            end

            NEQL: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = msub_in1[i];
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end
                
            KMUL, KMAC: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - Q;
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = Q;
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;

                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end

            DCP2: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - Alpha;
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = Alpha;
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Alpha : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];
                end
            end

            CMP_1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - (1<<1);
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = (1<<1);
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<1) : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end

            CMP_4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - (1<<4);
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = (1<<4);
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<4) : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end

            CMP_5: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - (1<<5);
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = (1<<5);
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<5) : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end

            CMP_10: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - (1<<10);
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = (1<<10);
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<10) : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];
                end
            end

            CMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - (1<<11);
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = (1<<11);
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<11) : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end
               
            MHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    // msub_cmp[i] = (msub_sub[i] >= (Gamma2 + 1))? 1 : 0;
                    msub_cmp_in0[i] = msub_sub[i];
                    msub_cmp_in1[i] = Gamma2_add1; //Gamma2 + 1
                    msub_cmp[i] = (msub_cmp_out[i])? 1 : 0;

                    msub_add[i] = msub_cmp[i] | ((msub_sub[i] == Q_subGamma2)<<1); // Q - Gamma2
                end
            end
                
            UHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_sub_in0[i] = msub_in0[i];
                    msub_sub_in1[i] = msub_in1[i];
                    msub_sub[i] = msub_sub_out[i];

                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Alpha : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end
                
            CHKZ: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    // msub_cmp[i] = ((Q - (Gamma1 - Beta)) >= msub_sub[i])? 1 : 0;
                    msub_cmp_in0[i] = Q_subGamma1_addBeta; // Q - (Gamma1 - Beta);
                    msub_cmp_in1[i] = msub_sub[i];
                    msub_cmp[i] = (msub_cmp_out[i])? 1 : 0;

                    msub_add[i] = msub_cmp[i];
                end
            end

            CHKW0: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    // msub_cmp[i] = ((Q - (Gamma2 - Beta)) >= msub_sub[i])? 1 : 0;
                    msub_cmp_in0[i] = Q_subGamma2_addBeta; // Q - (Gamma2 - Beta);
                    msub_cmp_in1[i] = msub_sub[i];
                    msub_cmp[i] = (msub_cmp_out[i])? 1 : 0;

                    msub_add[i] = msub_cmp[i];
                end
            end

            CHKH: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    // msub_cmp[i] = ((Q - Gamma2) >= msub_sub[i])? 1 : 0;
                    msub_cmp_in0[i] = Q_subGamma2; //Q - Gamma2;
                    msub_cmp_in1[i] = msub_sub[i];
                    msub_cmp[i] = (msub_cmp_out[i])? 1 : 0;

                    msub_add[i] = msub_cmp[i];
                end
            end

            PREMUL: begin
                msub_sub[0] = 0;
                msub_sub[1] = msub_in0[1];
                msub_sub[2] = 0;
                // msub_sub[3] = Q - msub_in0[3];
                msub_sub_in0[3] = Q;
                msub_sub_in1[3] = msub_in0[3];
                msub_sub[3] = msub_sub_out[3];

                for (i = 0; i < NUM; i = i+1) begin
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    // msub_add[i] = msub_sub[i] + msub_cmp[i];
                    msub_add_in0[i] = msub_sub[i];
                    msub_add_in1[i] = msub_cmp[i];
                    msub_add[i] = msub_add_out[i];

                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    // msub_cmp[i] = ((Q - Gamma2) >= msub_sub[i])? 1 : 0;
                    msub_cmp_in0[i] = Q_subGamma2; //Q - Gamma2;
                    msub_cmp_in1[i] = msub_sub[i];
                    msub_cmp[i] = (msub_cmp_out[i])? 1 : 0;

                    msub_add[i] = msub_cmp[i];
                end
            end
        endcase

        for (i = 0; i < NUM; i = i+1) msub_out_w[i] = msub_add[i];
    end

    ////////////////////////////////////////// mmul ///////////////////////////////////
    generate
        for (gi = 0; gi < NUM; gi = gi + 1) begin : mr_array
            MR mr (
                .clk(clk),
                .mode(((alg == DSA_44) || (alg == DSA_65) || (alg == DSA_87))? 1'b1:1'b0),
                .d(mmul_red_in[gi][45:0]),
                .MR_output(MR_output[gi])
            );
        end
    endgenerate

    generate
        for (gi = 0; gi < NUM; gi = gi + 1) begin : mult_dx_array
            DW_mult_dx #(WIDTH, 12)
            U1 (
                .a(mmul_mul_in0[gi]),
                .b(mmul_mul_in1[gi]),
                .tc(1'b0),
                .dplx(mmul_dplx_mode),
                .product(mmul_mul_out[gi])
            );
        end
    endgenerate

    generate
        for (gi = 0; gi < NUM; gi = gi + 1) begin : mult_r_array
            assign mmul_sft_out[gi] = mmul_sft_in0[gi] >> mmul_sft_in1[gi];
        end
    endgenerate
    
    always_comb begin // mmul
        integer i, j;

        for (i = 0; i < NUM; i = i+1) begin
            // mmul_mul_w[i] = mmul_in0[i][WIDTH-1:12] * mmul_in1[i][WIDTH-1:12]; 
            // mmul_mul2_w[i] = mmul_in0[i][11:0] * mmul_in1[i][11:0];
            mmul_dplx_mode = 1;
            mmul_mul_in0[i] = mmul_in0[i];
            mmul_mul_in1[i] = mmul_in1[i];
            mmul_mul_w[i] = mmul_mul_out[i];
            mmul_add_w[i] = mmul_mul_r[i][2*WIDTH-1 : WIDTH] + mmul_mul_r[i][WIDTH-1 : 0];

            mmul_red_in[i] = mmul_add_r[i];
            mmul_red[i] = MR_output[i];
            mmul_sft_in0[i] = mmul_red[i];
            mmul_sft_in1[i] = Alpha_eql16_21or23; //((Alpha == 16)?  21 : 23);
            mmul_sft[i] = mmul_sft_out[i];
        end

        case (instr)
            MMUL, MMAC, NTT, INTT, PREMUL: begin // 4 stages
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * mmul_in1[i];
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = mmul_in1[i];
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red_in[i] = mmul_mul_r[i];
                    mmul_red[i] = MR_output[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end

            KMUL, KMAC: begin // 5 stages
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i][WIDTH-1:12] * mmul_in1[i][WIDTH-1:12]; 
                    // mmul_mul2_w[i] = mmul_in0[i][11:0] * mmul_in1[i][11:0];
                    mmul_dplx_mode = 1;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = mmul_in1[i];
                    mmul_mul_w[i] = mmul_mul_out[i];
                    mmul_add_w[i] = mmul_mul_r[i][2*WIDTH-1 : 24] + mmul_mul_r[i][WIDTH-1 : 0];

                    mmul_red_in[i] = mmul_add_r[i];
                    mmul_red[i] = MR_output[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end

            DCP2: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * ((Alpha == 16)?  1025 : 11275);
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = Alpha_eql16_1025or11275; //(Alpha == 16)? 1025 : 11275;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> Alpha_eql16_21or23; //((Alpha == 16)?  21 : 23);
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = Alpha_eql16_21or23; //((Alpha == 16)?  21 : 23);
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            DCMP_1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = Q;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end
            DCMP_4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = Q;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 3;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 3;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            DCMP_5: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = Q;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 4;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 4;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            DCMP_10: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = Q;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 9;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 9;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            DCMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = Q;
                    mmul_mul_w[i] = mmul_mul_out[i];
                    
                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 10;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 10;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            CMP_1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * 10079;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = 10079;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 23;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 23;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            CMP_4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * 315;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = 315;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 15;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 15;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            CMP_5: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * 630;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = 630;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 15;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 15;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            CMP_10: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * 5160669;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = 5160669;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 23;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 23;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end
            CMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * 5160670;
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = 5160670;
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    // mmul_sft[i] = mmul_red[i] >> 22;
                    mmul_sft_in0[i] = mmul_red[i];
                    mmul_sft_in1[i] = 22;
                    mmul_sft[i] = mmul_sft_out[i];
                end
            end

            DCP3, DCP4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * (2 * Gamma2);
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = (2 * Gamma2);
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) begin
                    // mmul_mul_w[i] = mmul_in0[i] * (2 * Gamma2);
                    mmul_dplx_mode = 0;
                    mmul_mul_in0[i] = mmul_in0[i];
                    mmul_mul_in1[i] = (2 * Gamma2);
                    mmul_mul_w[i] = mmul_mul_out[i];

                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end
        endcase

        for (i = 0; i < NUM; i = i+1) mmul_out_w[i] = mmul_sft[i];
    end


    ////////////////////////////////////////// exe logic///////////////////////////////////
    always_comb begin // exe
        integer i, j;
        for (i = 0; i < NUM; i = i+1) begin
            madd_in0[i] = data_in[i][0];
            madd_in1[i] = data_in[i][1];
            msub_in0[i] = data_in[i][0];
            msub_in1[i] = data_in[i][1];
            mmul_in0[i] = data_in[i][0];
            mmul_in1[i] = data_in[i][1];

            data_out[i][0] = 0;
            data_out[i][1] = 0;
            for (j = 0; j < IN_NUM; j = j+1) begin
                data_in_p1_w[i][j] = data_in[i][j];
                data_in_p2_w[i][j] = data_in_p1_r[i][j];
                data_in_p3_w[i][j] = data_in_p2_r[i][j];
                data_in_p4_w[i][j] = data_in_p3_r[i][j];
                data_in_p5_w[i][j] = data_in_p4_r[i][j];
                data_in_p6_w[i][j] = data_in_p5_r[i][j];
            end
            for (j = 0; j < OUT_NUM; j = j+1) begin
                data_out_p1_w[i][j] = 0;
                data_out_p2_w[i][j] = data_out_p1_r[i][j];
                data_out_p3_w[i][j] = data_out_p2_r[i][j];
                data_out_p4_w[i][j] = data_out_p3_r[i][j];
                data_out_p5_w[i][j] = data_out_p4_r[i][j];
                data_out_p6_w[i][j] = data_out_p5_r[i][j];
            end
        end

        

        case (instr)
            MADD: begin // 1 stages
                for (i = 0; i < NUM; i = i+1) data_out[i][0] = madd_out_r[i];
            end

            MSUB: begin // 1 stages
                for (i = 0; i < NUM; i = i+1) data_out[i][0] = msub_out_r[i];
         
            end

            MMUL: begin // 4 stages
                for (i = 0; i < NUM; i = i+1) data_out[i][0] = mmul_out_r[i];
            end

            PREMUL: begin // 5 stages
                for (i = 0; i < NUM; i = i+1) begin
                    msub_in0[i] = data_in[i][1];
                    msub_in1[i] = 0;
                    mmul_in0[i] = data_in_p1_r[i][0];
                    mmul_in1[i] = msub_out_r[i];
                end
                for (i = 0; i < NUM/2; i = i+1) begin
                    data_out[2*i][0] = (data_in_p5_r[2*i][0] << 12) | mmul_out_r[2*i+1];
                    data_out[2*i+1][0] = (data_in_p5_r[2*i][0] << 12) | data_in_p5_r[2*i+1][0];
                end
            end

            KMUL: begin // 6 stages
                for (i = 0; i < NUM; i = i+1) begin
                    msub_in0[i] = mmul_out_r[i];
                    msub_in1[i] = 0;

                    data_out[i][0] = msub_out_r[i];
                end
            end

            KMAC: begin // 7 stages
                for (i = 0; i < NUM; i = i+1) begin
                    msub_in0[i] = mmul_out_r[i];
                    msub_in1[i] = 0;
                    madd_in0[i] = msub_out_r[i];
                    madd_in1[i] = data_in_p6_r[i][2];

                    data_out[i][0] = madd_out_r[i];
                end
            end

            NTT: begin // 5 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_in0[i] = data_in[i][1];
                    mmul_in1[i] = data_in[i][2];
                    madd_in0[i] = data_in_p4_r[i][0];
                    madd_in1[i] = mmul_out_r[i];
                    msub_in0[i] = data_in_p4_r[i][0];
                    msub_in1[i] = mmul_out_r[i];

                    data_out[i][0] = madd_out_r[i];
                    data_out[i][1] = msub_out_r[i];
                end            
            end

            INTT: begin // 5 stages
                for (i = 0; i < NUM; i = i+1) begin
                    madd_in0[i] = data_in[i][0];
                    madd_in1[i] = data_in[i][1];
                    msub_in0[i] = data_in[i][0];
                    msub_in1[i] = data_in[i][1];
                    mmul_in0[i] = msub_out_r[i];
                    mmul_in1[i] = data_in_p1_r[i][2];

                    data_out_p1_w[i][0] = madd_out_r[i];
                    data_out[i][0] = data_out_p4_r[i][0];
                    data_out[i][1] = mmul_out_r[i];
                end            
            end

            P2R: begin // 2 stages
                for (i = 0; i < NUM; i = i+1) begin
                    madd_in0[i] = data_in[i][0];
                    madd_in1[i] = 0;
                    msub_in0[i] = data_in_p1_r[i][0];
                    msub_in1[i] = madd_out_r[i];

                    data_out_p1_w[i][1] = madd_out_r[i];
                    data_out[i][0] = msub_out_r[i];
                    data_out[i][1] = data_out_p1_r[i][1];
                end            
            end

            DCP1: begin // 1 stages
                for (i = 0; i < NUM; i = i+1) begin
                    madd_in0[i] = data_in[i][0];
                    madd_in1[i] = 0;

                    data_out[i][0] = madd_out_r[i];
                end            
            end

            DCP2, CMP_1, CMP_4, CMP_5, CMP_10, CMP_11: begin // 4 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_in0[i] = data_in[i][0];
                    mmul_in1[i] = 0;
                    madd_in0[i] = mmul_out_r[i];
                    madd_in1[i] = 0;
                    msub_in0[i] = madd_out_r[i];
                    msub_in1[i] = 0;
                    data_out[i][0] = msub_out_r[i];
                end            
            end

            DCP3: begin // 3 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_in0[i] = data_in[i][1];
                    mmul_in1[i] = 0;
                    msub_in0[i] = data_in_p2_r[i][0];
                    msub_in1[i] = mmul_out_r[i];

                    data_out[i][0] = msub_out_r[i];
                end            
            end

            DCP4: begin // 4 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_in0[i] = data_in[i][1];
                    mmul_in1[i] = 0;
                    msub_in0[i] = data_in_p2_r[i][0];
                    msub_in1[i] = mmul_out_r[i];
                    madd_in0[i] = msub_out_r[i];
                    madd_in1[i] = 0;

                    data_out[i][0] = madd_out_r[i];
                end            
            end

            MHINT: begin // 1 stages
                for (i = 0; i < NUM; i = i+1) begin
                    msub_in0[i] = data_in[i][0];
                    msub_in1[i] = 0;
                    madd_in0[i] = data_in[i][0];
                    madd_in1[i] = data_in[i][1];

                    data_out[i][0] = ((msub_out_r[i]>>1)&(madd_out_r[i]>>1)) | ((msub_out_r[i][0])&(madd_out_r[i][0]));
                end            
            end

            UHINT: begin // 2 stages
                for (i = 0; i < NUM; i = i+1) begin
                    madd_in0[i] = data_in[i][0];
                    madd_in1[i] = data_in[i][2];
                    msub_in0[i] = data_in_p1_r[i][1];
                    msub_in1[i] = madd_out_r[i];

                    data_out[i][0] = msub_out_r[i];
                end            
            end

            CHKZ, CHKW0, CHKH: begin // 1 stages
                for (i = 0; i < NUM; i = i+1) begin
                    madd_in0[i] = data_in[i][0];
                    madd_in1[i] = 0;
                    msub_in0[i] = data_in[i][0];
                    msub_in1[i] = 0;

                    data_out[i][0] = msub_out_r[i] & madd_out_r[i];
                end            
            end

            DCMP_1, DCMP_4, DCMP_5, DCMP_10, DCMP_11: begin // 3 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_in0[i] = data_in[i][0];
                    mmul_in1[i] = 0;
                    madd_in0[i] = mmul_out_r[i];
                    madd_in1[i] = 0;

                    data_out[i][0] = madd_out_r[i];
                end            
            end

            NEQL: begin // 2 stages
                for (i = 0; i < NUM; i = i+1) begin
                    msub_in0[i] = data_in[i][0];
                    msub_in1[i] = data_in[i][1];
                    madd_in0[i] = msub_out_r[i];
                    madd_in1[i] = 0;

                    data_out[i][0] = madd_out_r[i];
                end            
            end

            SHFL: begin // 1 stages
                for (i = 0; i < NUM; i = i+1) begin
                    msub_in0[i] = 0;
                    msub_in1[i] = data_in[i][0];

                    data_out[i][0] = msub_out_r[i];
                end            
            end

            BYPASS: begin // 0 stages
                for (i = 0; i < NUM; i = i+1) begin
                    data_out[i][0] = data_in[i][0];
                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) data_out[i][0] = madd_out_r[i];
            end
        endcase
    end

    ///////////////////////////////////// sequential circuits /////////////////////////
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM; i = i+1) begin
                madd_out_r[i] <= 0;
                msub_out_r[i] <= 0;
                mmul_out_r[i] <= 0;
                mmul_mul_r[i] <= 0;
                mmul_add_r[i] <= 0;
                for (int j = 0; j < IN_NUM; j = j+1) begin
                    data_in_p1_r[i][j] <= 0;
                    data_in_p2_r[i][j] <= 0;
                    data_in_p3_r[i][j] <= 0;
                    data_in_p4_r[i][j] <= 0;
                    data_in_p5_r[i][j] <= 0;
                    data_in_p6_r[i][j] <= 0;
                end

                for (int j = 0; j < OUT_NUM; j = j+1) begin
                    data_out_p1_r[i][j] <= 0;
                    data_out_p2_r[i][j] <= 0;
                    data_out_p3_r[i][j] <= 0;
                    data_out_p4_r[i][j] <= 0;
                    data_out_p5_r[i][j] <= 0;
                    data_out_p6_r[i][j] <= 0;
                end

            end
        end else begin
            for (int i = 0; i < NUM; i = i+1) begin
                madd_out_r[i] <= madd_out_w[i];
                msub_out_r[i] <= msub_out_w[i];
                mmul_out_r[i] <= mmul_out_w[i];
                mmul_mul_r[i] <= mmul_mul_w[i];
                mmul_add_r[i] <= mmul_add_w[i];
                for (int j = 0; j < IN_NUM; j = j+1) begin
                    data_in_p1_r[i][j] <= data_in_p1_w[i][j];
                    data_in_p2_r[i][j] <= data_in_p2_w[i][j];
                    data_in_p3_r[i][j] <= data_in_p3_w[i][j];
                    data_in_p4_r[i][j] <= data_in_p4_w[i][j];
                    data_in_p5_r[i][j] <= data_in_p5_w[i][j];
                    data_in_p6_r[i][j] <= data_in_p6_w[i][j];
                end

                for (int j = 0; j < OUT_NUM; j = j+1) begin
                    data_out_p1_r[i][j] <= data_out_p1_w[i][j];
                    data_out_p2_r[i][j] <= data_out_p2_w[i][j];
                    data_out_p3_r[i][j] <= data_out_p3_w[i][j];
                    data_out_p4_r[i][j] <= data_out_p4_w[i][j];
                    data_out_p5_r[i][j] <= data_out_p5_w[i][j];
                    data_out_p6_r[i][j] <= data_out_p6_w[i][j];
                end
            end
        end
    end

endmodule


 

module MR(
    input clk,
    input mode, // 0: Kyber, 1: Dilithium
    input [45:0] d,

    output [23:0] MR_output
);  
    wire [24:0] Q;

    wire [24:0] D_CSA_input[0:4];
    wire [24:0] D_CSA_sum[0:2], D_CSA_carry[0:2];

    wire [14:0] K_CSA_input[0:7];
    wire [24:0] K_CSA_sum[0:5], K_CSA_carry[0:5];

    reg [24:0] CPA_input[0:1];
    reg signed [24:0] CPA_output_w, CPA_output_r;

    reg [24:0] MR_output_w, MR_output_r;

    assign MR_output = (mode) ? MR_output_r[23:0] : {11'd0, MR_output_r[12:0]}; // Output the result
    assign Q = (mode) ? 25'd8380417 : 25'd3329; // Q value for Kyber and Dilithium

    // Dilithium CSA logic
    assign D_CSA_input[0] = {2'd0, d[45:23]}; 
    assign D_CSA_input[1] = {2'd0, ~d[22:0]};
    assign D_CSA_input[2] = {2'd0, ~d[9:0], d[22:10]}; 
    assign D_CSA_input[3] = {1'd1, 10'd0, 1'd1, d[9:0], 3'd1}; 
    assign D_CSA_input[4] = 25'd8380417;
    
    assign D_CSA_sum[0] = D_CSA_input[0] ^ D_CSA_input[1] ^ D_CSA_input[2];
    assign D_CSA_carry[0] = ((D_CSA_input[0] & D_CSA_input[1]) | (D_CSA_input[1] & D_CSA_input[2]) | (D_CSA_input[2] & D_CSA_input[0])) << 1;
    assign D_CSA_sum[1] = D_CSA_sum[0] ^ D_CSA_carry[0] ^ D_CSA_input[3];
    assign D_CSA_carry[1] = ((D_CSA_sum[0] & D_CSA_carry[0]) | (D_CSA_carry[0] & D_CSA_input[3]) | (D_CSA_input[3] & D_CSA_sum[0])) << 1;
    assign D_CSA_sum[2] = D_CSA_sum[1] ^ D_CSA_carry[1] ^ D_CSA_input[4];
    assign D_CSA_carry[2] = ((D_CSA_sum[1] & D_CSA_carry[1]) | (D_CSA_carry[1] & D_CSA_input[4]) | (D_CSA_input[4] & D_CSA_sum[1])) << 1;


    // Kyber CSA logic
    assign K_CSA_input[0] = {2'd0, d[24:12]};
    assign K_CSA_input[1] = {3'd0, ~d[11:0]};
    assign K_CSA_input[2] = {6'd0, d[11:4], 1'd0};
    assign K_CSA_input[3] = {7'd0, d[11:4]};
    assign K_CSA_input[4] = {3'd0, d[3:2], ~d[3:2], d[3:2], 4'd0, d[3:2]};
    assign K_CSA_input[5] = {4'd0, ~d[1:0], ~d[1:0],1'd0, d[1:0], 4'd0};
    assign K_CSA_input[6] = 15'b110_0101_1000_0001;
    assign K_CSA_input[7] = (d[1:0] > d[3:2]) ? 15'd3329 : 15'd0; 

    assign K_CSA_sum[0] = K_CSA_input[0] ^ K_CSA_input[1] ^ K_CSA_input[2];
    assign K_CSA_carry[0] = ((K_CSA_input[0] & K_CSA_input[1]) | (K_CSA_input[1] & K_CSA_input[2]) | (K_CSA_input[2] & K_CSA_input[0])) << 1;
    assign K_CSA_sum[1] = K_CSA_sum[0] ^ K_CSA_carry[0] ^ K_CSA_input[3];
    assign K_CSA_carry[1] = ((K_CSA_sum[0] & K_CSA_carry[0]) | (K_CSA_carry[0] & K_CSA_input[3]) | (K_CSA_input[3] & K_CSA_sum[0])) << 1;
    assign K_CSA_sum[2] = K_CSA_sum[1] ^ K_CSA_carry[1] ^ K_CSA_input[4];
    assign K_CSA_carry[2] = ((K_CSA_sum[1] & K_CSA_carry[1]) | (K_CSA_carry[1] & K_CSA_input[4]) | (K_CSA_input[4] & K_CSA_sum[1])) << 1;
    assign K_CSA_sum[3] = K_CSA_sum[2] ^ K_CSA_carry[2] ^ K_CSA_input[5];
    assign K_CSA_carry[3] = ((K_CSA_sum[2] & K_CSA_carry[2]) | (K_CSA_carry[2] & K_CSA_input[5]) | (K_CSA_input[5] & K_CSA_sum[2])) << 1;
    assign K_CSA_sum[4] = K_CSA_sum[3] ^ K_CSA_carry[3] ^ K_CSA_input[6];
    assign K_CSA_carry[4] = ((K_CSA_sum[3] & K_CSA_carry[3]) | (K_CSA_carry[3] & K_CSA_input[6]) | (K_CSA_input[6] & K_CSA_sum[3])) << 1;
    assign K_CSA_sum[5] = K_CSA_sum[4] ^ K_CSA_carry[4] ^ K_CSA_input[7];
    assign K_CSA_carry[5] = ((K_CSA_sum[4] & K_CSA_carry[4]) | (K_CSA_carry[4] & K_CSA_input[7]) | (K_CSA_input[7] & K_CSA_sum[4])) << 1;


    reg larger, smaller;

    always @(*) begin
        // First stage
        CPA_input[0] = 25'd0; 
        CPA_input[1] = 25'd0; 
        if(mode) begin
            // Dilithium mode
            CPA_input[0] = D_CSA_sum[2]; 
            CPA_input[1] = D_CSA_carry[2]; 
        end else begin
            // Kyber mode
            CPA_input[0] = K_CSA_sum[5];
            CPA_input[1] = K_CSA_carry[5];
        end
        CPA_output_w = CPA_input[0] + CPA_input[1]; // CPA output
    
        // Second stage
        MR_output_w = 24'd0; // Initialize MR output
        if(mode) begin

            if ($signed(CPA_output_r) >= $signed(Q)) begin
                MR_output_w = CPA_output_r - Q; // Subtract Q if the result is greater than or equal to Q
            end else if($signed(CPA_output_r)  < 0)begin
                MR_output_w = CPA_output_r + Q;
            end else begin
                MR_output_w = CPA_output_r; // Otherwise, keep the result as is
            end
        end else begin
            if ($signed(CPA_output_r[14:0]) >= $signed(Q)) begin
                MR_output_w = CPA_output_r - Q; // Subtract Q if the result is greater than or equal to Q
            end else if($signed(CPA_output_r[14:0])  < 0)begin
                MR_output_w = CPA_output_r + Q;
            end else begin
                MR_output_w = CPA_output_r; // Otherwise, keep the result as is
            end
        end

    end


    always @(posedge clk ) begin
        CPA_output_r <= CPA_output_w; // Register the output
        MR_output_r <= MR_output_w; // Register the output
    end

endmodule


module DW_mult_dx (a, b, tc, dplx, product );

   parameter integer width = 16;
   parameter integer p1_width = 8;

   `define DW_p2_width (width-p1_width)

   input [width-1 : 0] a;
   input [width-1 : 0] b;
   input 	       tc;
   input 	       dplx;
   output [2*width-1 : 0] product;

   wire [width-1 : 0] 	  a;
   wire [width-1 : 0] 	  b;
   wire 		  tc;
   wire 		  dplx;
   wire [2*width-1 : 0]   product;
   wire [2*width-1 : 0]   duplex_prod;
   wire [2*width-1 : 0]   simplex_prod;

// synopsys translate_off
  
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
    
    if (width < 4) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter width (lower bound: 4)",
	width );
    end
    
    if ( (p1_width < 2) || (p1_width > width-2) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter p1_width (legal range: 2 to width-2)",
	p1_width );
    end
  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 

     
     DW02_mult 	#(width, width)
	U1 (
	    .A(a),
	    .B(b),
	    .TC(tc),
	    .PRODUCT(simplex_prod)
	    );

   DW02_mult #(p1_width, p1_width)
      U2_1 (
	    .A(a[p1_width-1 : 0]),
	    .B(b[p1_width-1 : 0]),
	    .TC(tc),
	    .PRODUCT(duplex_prod[2*p1_width-1 : 0])
	    );

   DW02_mult #(`DW_p2_width, `DW_p2_width)
      U2_2 (
	    .A(a[width-1 : p1_width]),
	    .B(b[width-1 : p1_width]),
	    .TC(tc),
	    .PRODUCT(duplex_prod[2*width-1 : 2*p1_width])
	    );

   assign  product =  dplx == 1'b0 ? simplex_prod : 
		      dplx == 1'b1 ? duplex_prod : 
		      {2*width{1'bx}};

// synopsys translate_on

`undef DW_p2_width

endmodule


module DW02_mult(A,B,TC,PRODUCT);
parameter	integer A_width = 8;
parameter	integer B_width = 8;
   
input	[A_width-1:0]	A;
input	[B_width-1:0]	B;
input			TC;
output	[A_width+B_width-1:0]	PRODUCT;

wire	[A_width+B_width-1:0]	PRODUCT;

wire	[A_width-1:0]	temp_a;
wire	[B_width-1:0]	temp_b;
wire	[A_width+B_width-2:0]	long_temp1,long_temp2;

  // synopsys translate_off 
  //-------------------------------------------------------------------------
  // Parameter legality check
  //-------------------------------------------------------------------------

  
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
    
    if (A_width < 1) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter A_width (lower bound: 1)",
	A_width );
    end
    
    if (B_width < 1) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter B_width (lower bound: 1)",
	B_width );
    end 
  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 

     
assign	temp_a = (A[A_width-1])? (~A + 1'b1) : A;
assign	temp_b = (B[B_width-1])? (~B + 1'b1) : B;

assign	long_temp1 = temp_a * temp_b;
assign	long_temp2 = ~(long_temp1 - 1'b1);

assign	PRODUCT = ((^(A ^ A) !== 1'b0) || (^(B ^ B) !== 1'b0) || (^(TC ^ TC) !== 1'b0) ) ? {A_width+B_width{1'bX}} :
		  (TC)? (((A[A_width-1] ^ B[B_width-1]) && (|long_temp1))?
			 {1'b1,long_temp2} : {1'b0,long_temp1})
		     : A * B;
   // synopsys translate_on
endmodule


