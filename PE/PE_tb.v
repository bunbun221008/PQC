`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

module MR_tb;
    // port declaration for design-under-test
    reg        Clk;
    reg        mode; // 0: Kyber, 1: Dilithium
    reg [45:0] d;
    wire [23:0] MR_output;
 
    // instantiate the design-under-test
    MR mr(
        .clk    (Clk),
        .mode   (mode),
        .d      (d),
        .MR_output (MR_output)
    );

    // waveform dump
    initial begin
        $fsdbDumpfile("MR.fsdb");
        $fsdbDumpvars(0,MR_tb,"+mda");

    end
    
    // clock generation
    always#(`HCYCLE) Clk = ~Clk;
    
    // test pattern
    parameter D0 = 46'd66666661;
    parameter D1 = 46'd8193;
    parameter D2 = 46'd3316429;
    parameter D3 = 46'd12943;
    

    parameter K0 = 25'd17702923;
    

    
    // simulation
    integer err_count;
    reg [50:0] i;
    initial begin
        // initialization
        Clk = 1'b1;
        err_count = 0;
        
        // 4-bit x 4-bit unsigned multiplication
        $display( "Montgomery reduction for Dilithium" );
        
        
        #(`CYCLE*0.2)
        $display( "1: Input=%2d", D0 );
        d = D0; mode = 1'b1; // Dilithium mode
        #(`CYCLE*0.8)
        
        #(`CYCLE*1.2)
        if( ((MR_output*8191) % 46'd8380417) == (D0 % 46'd8380417) ) // 8372232 = 2 ^ -23 mod 8380417
            $display( "    .... passed. design(%2d) == expected(%2d)" , MR_output, (((D0 % 46'd8380417) * 8372232) % 46'd8380417) );
        else begin 
            err_count = err_count+1;
            $display( "    .... failed, design(%2d) != expected(%2d)", MR_output, (((D0 % 46'd8380417) * 8372232) % 46'd8380417) );
        end

        #(`CYCLE*0.8)


        
        
        
        #(`CYCLE*0.2)
        for (i = 0; i<0 ; i=i+1) begin
            #(`CYCLE*0.8)
            #(`CYCLE*0.2)
            // $display( "1: Input=%2d", i );
            d = i; mode = 1'b1; // Dilithium mode
            #(`CYCLE*0.8)
            
            #(`CYCLE*1.2)
            if( ((MR_output*8191) % 46'd8380417) == (i % 46'd8380417) ) begin
            end
            else begin 
                err_count = err_count+1;
                $display( "    .... failed, design(%2d) != expected(%2d)", MR_output, (((i % 46'd8380417) * 8372232) % 46'd8380417) );
            end
            if(i%100000 == 0) begin
                $display( "i = %2d", i );
            end
        end

        #(`CYCLE*0.8)


        
        
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
