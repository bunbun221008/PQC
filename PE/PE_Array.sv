
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


    ////////////////////////////////// madd declare ////////////////////////////////////
    logic [WIDTH-1:0] madd_in0[0:NUM-1], madd_in1[0:NUM-1];
    logic [WIDTH-1:0] madd_cmp[0:NUM-1], madd_sft[0:NUM-1], madd_add[0:NUM-1], madd_sub[0:NUM-1];
    logic [WIDTH-1:0] madd_out_w[0:NUM-1], madd_out_r[0:NUM-1];


    ////////////////////////////////// msub declare ////////////////////////////////////
    logic [WIDTH-1:0] msub_in0[0:NUM-1], msub_in1[0:NUM-1];
    logic [WIDTH-1:0] msub_cmp[0:NUM-1], msub_add[0:NUM-1], msub_sub[0:NUM-1];
    logic [WIDTH-1:0] msub_out_w[0:NUM-1], msub_out_r[0:NUM-1];


    /////////////////////////////////// mmul declare ///////////////////////////////////
    logic [WIDTH-1:0] mmul_in0[0:NUM-1], mmul_in1[0:NUM-1];
    logic [2*WIDTH-1:0] mmul_mul_w[0:NUM-1], mmul_mul_r[0:NUM-1], 
                        mmul_mul2_w[0:NUM-1],  mmul_mul2_r[0:NUM-1]; 
    logic [2*WIDTH-1:0] mmul_add_w[0:NUM-1], mmul_add_r[0:NUM-1];
    logic [2*WIDTH-1:0] mmul_red[0:NUM-1], mmul_red_in[0:NUM-1], mmul_sft[0:NUM-1];
    logic [WIDTH-1:0] MR_output[0:NUM-1];
    logic [WIDTH-1:0] mmul_out_w[0:NUM-1], mmul_out_r[0:NUM-1];

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
            end
            KEM_768: begin
                Q = 3329;
                D = 13;
                Alpha = 16;
                Beta = 120;
                Gamma1 = 1<<19;
                Gamma2 = 104;
            end
            KEM_1024: begin
                Q = 3329;
                D = 13;
                Alpha = 16;
                Beta = 120;
                Gamma1 = 1<<19;
                Gamma2 = 104;
            end
            DSA_44: begin
                Q = 8380417;
                D = 13;
                Alpha = 44;
                Beta = 78;
                Gamma1 = 1<<17;
                Gamma2 = 95232;
            end
            DSA_65: begin
                Q = 8380417;
                D = 13;
                Alpha = 16;
                Beta = 196;
                Gamma1 = 1<<19;
                Gamma2 = 261888; 
            end
            DSA_87: begin
                Q = 8380417;
                D = 13;
                Alpha = 16; 
                Beta = 120; 
                Gamma1 = 1<<19; 
                Gamma2 = 261888; 
            end
            default: begin
                Q = 8380417;
                D = 13;
                Alpha = 16; 
                Beta = 120; 
                Gamma1 = 1<<19; 
                Gamma2 = 261888; 
            end
        endcase
    end

    ////////////////////////////////////////// madd ///////////////////////////////////
    always_comb begin // madd
        integer i, j;
        case (instr)
            MADD, MMAC, KMAC, NTT, INTT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i] + madd_in1[i];
                    madd_cmp[i] = (madd_add[i] >= Q)? Q : 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            P2R: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i] + ((1<<(D-1)) - 1);
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i] >> D;
                end
            end
                
            DCP1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i] + 127;
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i] >> 7;
                end
            end
                
            DCP2, DCMP_1, DCMP_4, DCMP_5, DCMP_10, DCMP_11, CMP_1, CMP_4, CMP_5, CMP_10, CMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i] + 1;
                    madd_cmp[i] = 0;
                    madd_sub[i] = madd_add[i] - madd_cmp[i];
                    madd_sft[i] = madd_sub[i] >> 1;
                end
            end
               
            DCP4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (((Q-1)>>1) >= madd_add[i])? 1:0;
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
                    madd_cmp[i] = ((Q - 1 - Gamma2) >= madd_add[i])? 1:0;
                    madd_sub[i] = madd_cmp[i] | ((madd_in1[i] != 0)<<1);
                    madd_sft[i] = madd_sub[i];
                end
            end
                
            UHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= 1)? (Alpha - 1):0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = (madd_in1[i][0])? madd_sub[i]:0;
                end
            end
                
            CHKZ: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma1 - Beta))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            CHKW0: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma2 - Beta))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            CHKH: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma2))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) begin
                    madd_add[i] = madd_in0[i];
                    madd_cmp[i] = (madd_add[i] >= (Gamma2))? 1:0;
                    madd_sub[i] = madd_cmp[i];
                    madd_sft[i] = madd_sub[i];
                end
            end
        endcase

        for (i = 0; i < NUM; i = i+1) madd_out_w[i] = madd_sft[i];
    end

    ////////////////////////////////////////// msub ///////////////////////////////////
    always_comb begin //msub
        integer i, j;
        case (instr)
            MSUB, NTT, INTT, DCP3, DCP4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            P2R: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - (msub_in1[i] << D);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            SHFL: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = (msub_in1[i] << D);
                    msub_cmp[i] = 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            NEQL: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_cmp[i] = 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end
                
            KMUL, KMAC: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - Q;
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            DCP2: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - Alpha;
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Alpha : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - (1<<1);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<1) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - (1<<4);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<4) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_5: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - (1<<5);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<5) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_10: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - (1<<10);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<10) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            CMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - (1<<11);
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? (1<<11) : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end
               
            MHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = (msub_sub[i] >= (Gamma2 + 1))? 1 : 0;
                    msub_add[i] = msub_cmp[i] | ((msub_sub[i] == (Q-Gamma2))<<1);
                end
            end
                
            UHINT: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i] - msub_in1[i];
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Alpha : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end
                
            CHKZ: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - (Gamma1 - Beta)) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end

            CHKW0: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - (Gamma2 - Beta)) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end

            CHKH: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - Gamma2) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end

            PREMUL: begin
                msub_sub[0] = 0;
                msub_sub[1] = msub_in0[1];
                msub_sub[2] = 0;
                msub_sub[3] = Q - msub_in0[3];
                for (i = 0; i < NUM; i = i+1) begin
                    msub_cmp[i] = (msub_sub[i][WIDTH-1])? Q : 0;
                    msub_add[i] = msub_sub[i] + msub_cmp[i];
                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) begin
                    msub_sub[i] = msub_in0[i];
                    msub_cmp[i] = ((Q - Gamma2) >= msub_sub[i])? 1 : 0;
                    msub_add[i] = msub_cmp[i];
                end
            end
        endcase

        for (i = 0; i < NUM; i = i+1) msub_out_w[i] = msub_add[i];
    end

    ////////////////////////////////////////// mmul ///////////////////////////////////
    genvar gi;
    generate
        for (gi = 0; gi < NUM; gi = gi + 1) begin : PE_ARRAY
            MR mr (
                .clk(clk),
                .mode((alg == DSA_44 || alg == DSA_65 || alg == DSA_87)? 1'b1:1'b0),
                .d(mmul_red_in[gi][45:0]),
                .MR_output(MR_output[gi])
            );
        end
    endgenerate
    
    always_comb begin // mmul
        integer i, j;

        for (i = 0; i < NUM; i = i+1) begin
            mmul_mul_w[i] = mmul_in0[i][WIDTH-1:12] * mmul_in1[i][WIDTH-1:12]; 
            mmul_mul2_w[i] = mmul_in0[i][11:0] * mmul_in1[i][11:0];
            mmul_add_w[i] = mmul_mul_r[i] + mmul_mul2_r[i];
            mmul_red_in[i] = mmul_add_r[i];
            mmul_red[i] = MR_output[i];
            mmul_sft[i] = mmul_red[i];
        end

        case (instr)
            MMUL, MMAC, NTT, INTT, PREMUL: begin // 4 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * mmul_in1[i];
                    mmul_red_in[i] = mmul_mul_r[i];
                    mmul_red[i] = MR_output[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end

            KMUL, KMAC: begin // 5 stages
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i][WIDTH-1:12] * mmul_in1[i][WIDTH-1:12]; 
                    mmul_mul2_w[i] = mmul_in0[i][11:0] * mmul_in1[i][11:0];
                    mmul_add_w[i] = mmul_mul_r[i] + mmul_mul2_r[i];
                    mmul_red_in[i] = mmul_add_r[i];
                    mmul_red[i] = MR_output[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end

            DCP2: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * ((Alpha == 16)?  1025 : 11275);
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> ((Alpha == 16)?  21 : 23);
                end
            end
            DCMP_1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end
            DCMP_4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 3;
                end
            end
            DCMP_5: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 4;
                end
            end
            DCMP_10: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 9;
                end
            end
            DCMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * Q;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 10;
                end
            end
            CMP_1: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * 10079;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 23;
                end
            end
            CMP_4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * 315;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 15;
                end
            end
            CMP_5: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * 630;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 15;
                end
            end
            CMP_10: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * 5160669;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 23;
                end
            end
            CMP_11: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * 5160670;
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i] >> 22;
                end
            end

            DCP3, DCP4: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * (2 * Gamma2);
                    mmul_red[i] = mmul_mul_r[i];
                    mmul_sft[i] = mmul_red[i];
                end
            end

            default: begin
                for (i = 0; i < NUM; i = i+1) begin
                    mmul_mul_w[i] = mmul_in0[i] * (2 * Gamma2);
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
                mmul_mul2_r[i] <= 0;
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
                mmul_mul2_r[i] <= mmul_mul2_w[i];
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