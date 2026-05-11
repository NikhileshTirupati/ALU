module ALU #(
   parameter CMD_WIDTH = 4, //minimum width should be 4
   parameter WIDTH = 8 //minimum width should be 4
)(
   input  wire clk,rst,mode,ce,cin,
   input  wire [1:0] inp_valid,
   input  wire [CMD_WIDTH-1:0] cmd,
   input  wire [WIDTH-1:0] op_a,op_b,
   output reg signed [2*WIDTH-1:0] result,
   output reg erro,Oflow,Cout,G,L,E 
);
    // Internal registers and wires
    wire clk_new;
    reg start,done;
    reg [WIDTH-1:0] temp_a, temp_b;
    reg [CMD_WIDTH-1:0] prev_cmd;
    reg [2*WIDTH-1:0] res;
    reg err,oflow,cout,g,l,e,of;
    
    //gated clk
    assign clk_new = clk & ce;
    
    always@(posedge clk_new or posedge rst) begin
        if(rst) begin
            result<=0;
            erro <= 0;
            Oflow <= 0;
            Cout <= 0;
            G <= 0;
            L <= 0;
            E <= 0;
        end
        else begin
            result<=res;
            erro<=err;
            Oflow<=of;
            Cout<=cout;
            G<=g;
            L<=l;
            E<=e;
        end
    end
    
    // Sequential logic for ALU operations
    always @(posedge clk_new or posedge rst) begin
        //reset condition
       if (rst) begin
            res <= 0;
            err <= 0;
            of <= 0;
            cout <= 0;
            g <= 0;
            l <= 0;
            e <= 0;
            start <= 1;
            done <= 0;
            prev_cmd <= 14;
        end
        // Main ALU operations
        else begin
            // Default values for outputs
            err <= 0;
            of <= 0;
            cout <= 0;
            g <= 0;
            l <= 0;
            e <= 0;

            prev_cmd <= cmd; // Update previous command
            // Start new operation for multiplication if command changes
            if(cmd != prev_cmd) begin
                start = 1; 
                done = 0; 
            end 

            // ALU operations based on mode and command
            if(mode) begin
               case(cmd)
                    0: begin // Addition
                        if(inp_valid==2'b11) begin
                            res <= op_a + op_b;
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    1: begin // Subtraction
                        if(inp_valid==2'b11) begin
                            res <= op_a - op_b;
                            of <= (op_a < op_b);
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    2: begin // Addition with carry
                        if(inp_valid==2'b11) begin
                            res <= op_a + op_b + cin;
                        end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    3: begin // Subtraction with borrow
                        if(inp_valid==2'b11) begin
                            res <= op_a - op_b - cin;
                            of <= (op_a < (op_b + cin));
                        end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    4: begin // Increment A
                        if(inp_valid[0]) begin
                            res <= op_a + 1'b1;
                        end
                        else
                            err <= 1; // Set error if input A is not valid
                    end
                    5: begin // Decrement A
                        if(inp_valid[0]) begin
                            res <= op_a - 1'b1;
                        end
                        else err <= 1; // Set error if input A is not valid
                    end
                    6: begin // Increment B
                        if(inp_valid[1]) begin
                            res <= op_b + 1'b1;
                        end
                        else err <= 1; // Set error if input B is not valid
                    end
                    7: begin // Decrement B
                        if(inp_valid[1]) begin
                            res <= op_b - 1'b1;
                        end
                        else err <= 1; // Set error if input B is not valid
                    end
                    8: begin // Comparison
                        if(inp_valid==2'b11) begin
                            if (op_a>op_b) g<=1;
                            else if (op_a<op_b) l<=1;
                            else e<=1;
                        end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    9: begin // Multiplication with increment
                        if(inp_valid==2'b11) begin
                            if(start) begin
                                temp_a <= op_a + 1'b1;
                                temp_b <= op_b + 1'b1;
                                start <= 0;
                                done <= 1;
                            end
                            if(done) begin
                                res <= temp_a * temp_b;
                                done <= 0;
                                start <= 1;
                            end
                            end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    10: begin // Multiplication with shift
                        if (inp_valid==2'b11) begin
                            if(start) begin
                                temp_a <= op_a << 1;
                                temp_b <= op_b;
                                start <= 0;
                                done <= 1;
                            end
                            if(done) begin
                                res <= temp_a * temp_b;
                                done <= 0;
                                start <= 1;
                            end
                        end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    11: begin // Signed addition
                        if (inp_valid==2'b11) begin
                            res <= $signed(op_a) + $signed(op_b);
                            {g,l,e} <= ($signed(op_a) == $signed(op_b)) ? 3'b001 : ($signed(op_a) > $signed(op_b)) ? 3'b100 : 3'b010; 
                        end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    12: begin // Signed subtraction
                        if (inp_valid==2'b11) begin
                            res <= $signed(op_a) - $signed(op_b);
                            {g,l,e} <= ($signed(op_a) == $signed(op_b)) ? 3'b001 : ($signed(op_a) > $signed(op_b)) ? 3'b100 : 3'b010; 
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
               endcase 
            end
            else begin
                case (cmd)
                    0: begin // AND
                        if(inp_valid==2'b11) begin
                            res <= op_a & op_b;
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else err <= 1; // Set error if inputs are not valid
                    end
                    1: begin // NAND
                        if(inp_valid==2'b11)begin
                            res <= ~(op_a & op_b);
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end 
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    2: begin // OR
                        if(inp_valid==2'b11) begin
                            res <= op_a | op_b;
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end 
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    3: begin // NOR
                        if(inp_valid==2'b11) begin 
                            res <= ~(op_a | op_b);
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    4: begin // XOR
                        if(inp_valid==2'b11) begin
                            res <= op_a ^ op_b;
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    5: begin // XNOR
                        if(inp_valid==2'b11) begin
                            res <= ~(op_a ^ op_b);
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    6: begin // NOT A
                        if(inp_valid[0]) begin
                            res <= ~op_a;
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if input A is not valid
                    end
                    7: begin // NOT B
                        if(inp_valid[1]) begin
                            res <= ~op_b;
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if input B is not valid  
                    end
                    8: begin // Right Shift A
                        if(inp_valid[0]) begin 
                            res[WIDTH-1:0] <= op_a >> 1
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if input A is not valid
                    end
                    9: begin // Left Shift A
                        if(inp_valid[0]) begin
                            res[WIDTH-1:0] <= op_a << 1;
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if input A is not valid
                    end
                    10: begin // Right Shift B
                      if(inp_valid[1]) begin
                        res[WIDTH-1:0] <= op_b >> 1;
                        res[2*WIDTH-1:WIDTH] <= 0;
                      end
                        else
                            err <= 1; // Set error if input B is not valid
                    end
                    11: begin // Left Shift B
                      if(inp_valid[1]) begin
                            res[WIDTH-1:0] <= op_b << 1;
                            res[2*WIDTH-1:WIDTH] <= 0;
                      end
                        else
                            err <= 1; // Set error if input B is not valid
                    end
                    12: begin // Rotate Left A, B times
                        if (inp_valid==2'b11) begin
                            res[WIDTH-1:0] <= op_a << op_b[$clog2(WIDTH)-1:0]|op_a >> (WIDTH - op_b[$clog2(WIDTH)-1:0]);
                            if (|op_b[WIDTH-1:$clog2(WIDTH)+1]) begin
                                err <= 1;
                            end
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                    13: begin // Rotate Right A, B times
                        if(inp_valid==2'b11) begin
                            res[WIDTH-1:0] <= op_a >> op_b[$clog2(WIDTH)-1:0]|op_a << (WIDTH - op_b[$clog2(WIDTH)-1:0]);
                            if (|op_b[WIDTH-1:$clog2(WIDTH)+1]) begin
                                err <= 1;
                            end
                            res[2*WIDTH-1:WIDTH] <= 0;
                        end
                        else
                            err <= 1; // Set error if inputs are not valid
                    end
                endcase
            end
        end
    end

    // Combinational logic for overflow detection
    always @( *) begin
        if(mode && (cmd == 11)) begin
            of = (op_a[WIDTH-1] == op_b[WIDTH-1]) && (res[WIDTH-1] != op_a[WIDTH-1]); 
        end
        else if(mode && (cmd == 12)) begin
            of = (op_a[WIDTH-1] != op_b[WIDTH-1]) && (res[WIDTH-1] != op_a[WIDTH-1]);
        end
            
        if(mode && (cmd == 0 || cmd ==2)) cout = res[WIDTH];
    end
    
endmodule //ALU


