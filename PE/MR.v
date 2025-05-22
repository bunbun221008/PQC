 

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