`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

typedef enum logic [4:0] {
    MADD    = 5'd0,
    MSUB    = 5'd1,
    MMUL    = 5'd2,
    MMAC    = 5'd3,
    PREMUL  = 5'd4,
    KMUL    = 5'd5,
    KMAC    = 5'd6,
    NTT     = 5'd7,
    INTT    = 5'd8,
    P2R     = 5'd9,
    DCP1    = 5'd10,
    DCP2    = 5'd11,
    DCP3    = 5'd12,
    DCP4    = 5'd13,
    MHINT   = 5'd14,
    UHINT   = 5'd15,
    CHKZ    = 5'd16,
    CHKW0   = 5'd17,
    CHKH    = 5'd18,
    NEQL    = 5'd19,
    DCMP_1  = 5'd20,
    DCMP_4  = 5'd21,
    DCMP_5  = 5'd22,
    DCMP_10 = 5'd23,
    DCMP_11 = 5'd24,
    CMP_1   = 5'd25,
    CMP_4   = 5'd26,
    CMP_5   = 5'd27,
    CMP_10  = 5'd28,
    CMP_11  = 5'd29,
    SHFL    = 5'd30,
    BYPASS  = 5'd31
} pe_instr_t;

typedef enum logic [4:0] {
    KEM_512 = 5'd0,
    KEM_768 = 5'd1,
    KEM_1024 = 5'd2,
    DSA_44 = 5'd3,
    DSA_65 = 5'd4,
    DSA_87 = 5'd5
} pe_alg_t;

module pe_array_tb;
    // port declaration for design-under-test
    parameter WIDTH = 24;
    parameter NUM = 4;
    parameter IN_NUM = 3;
    parameter OUT_NUM = 2;

    logic        Clk;
    pe_instr_t instr;
    pe_alg_t   alg;
    logic [WIDTH-1:0] data_in[0:NUM-1][0:IN_NUM-1], data_out[0:NUM-1][0:OUT_NUM-1];
    integer err_count;
    integer i,j;

    // instantiate the design-under-test
    pe_array pe_array (
        .clk(Clk),
        .rst(1'b0),
        .alg(alg),
        .instr(instr),
        .data_in(data_in),
        .data_out(data_out)
    );

    // waveform dump
    initial begin
        $fsdbDumpfile("PE_Array.fsdb");
        $fsdbDumpvars(0,pe_array_tb,"+mda");

    end
    
    // clock generation
    always#(`HCYCLE) Clk = ~Clk;
    

    
    // simulation
    parameter INS = DCP4;
    parameter ALG = DSA_44;
    parameter WAIT_CYCLE = 4;
    initial begin
        // initialization
        Clk = 1'b1;
        err_count = 0;
        
        // 4-bit x 4-bit unsigned multiplication
        $display( "Start" );
        
        
        #(`CYCLE*0.2)
        instr = INS;
        alg = ALG;
        data_in[0][0] = 24'd1340;
        data_in[0][1] = 24'd2;
        data_in[0][2] = 24'd337;
        data_in[1][0] = 24'd478;
        data_in[1][1] = 24'd5;
        data_in[1][2] = 24'd64;
        data_in[2][0] = 24'd7;
        data_in[2][1] = 24'd8;
        data_in[2][2] = 24'd93;
        data_in[3][0] = 24'd109;
        data_in[3][1] = 24'd16;
        data_in[3][2] = 24'd12;
        #(`CYCLE*0.8)

        #(`CYCLE*0.2)
        instr = INS;
        alg = ALG;
        data_in[0][0] = 24'd100;
        data_in[0][1] = 24'd3;
        data_in[0][2] = 24'd537;
        data_in[1][0] = 24'd718;
        data_in[1][1] = 24'd7;
        data_in[1][2] = 24'd64;
        data_in[2][0] = 24'd73;
        data_in[2][1] = 24'd15;
        data_in[2][2] = 24'd93;
        data_in[3][0] = 24'd9;
        data_in[3][1] = 24'd11;
        data_in[3][2] = 24'd12;
        #(`CYCLE*0.8);

    end
    initial begin   
        #(`CYCLE*WAIT_CYCLE)

        $display( "data 1" );
        #(`CYCLE*0.3)
        // display output
        for( i=0; i<NUM; i=i+1 ) begin
            for( j=0; j<OUT_NUM; j=j+1 ) begin
                $display( "data_out[%0d][%0d] = %d", i, j, data_out[i][j] );
            end
        end
        #(`CYCLE*0.7)

        $display( "data 2" );
        #(`CYCLE*0.3)
        // display output
        for( i=0; i<NUM; i=i+1 ) begin
            for( j=0; j<OUT_NUM; j=j+1 ) begin
                $display( "data_out[%0d][%0d] = %d", i, j, data_out[i][j] );
            end
        end
        #(`CYCLE*0.7)

        
        
        // show total results
        if( err_count==0 ) begin
            $display("****************************        /|__/|");
            $display("**                        **      / O,O  |");
            $display("**   Congratulations !!   **    /_____   |");
            $display("** All Patterns Passed!!  **   /^ ^ ^ \\  |");
            $display("**                        **  |^ ^ ^ ^ |w|");
            $display("****************************   \\m___m__|_|");
        end
        else begin
            $display("**************************** ");
            $display("           Failed ...        ");
            $display("     Total %2d Errors ...     ", err_count );
            $display("**************************** ");
        end
        
        // finish tb
        #(`CYCLE) $finish;
    end
endmodule
