module ALU #(
   parameter CMD_WIDTH = 4, //minimum width should be 4
   parameter WIDTH = 8 //minimum width should be 4
)(
   input  wire clk,rst,mode,ce,cin,
   input  wire [1:0] inp_valid,
   input  wire [CMD_WIDTH-1:0] cmd,
   input  wire [WIDTH-1:0] op_a,op_b,
   output reg signed [2*WIDTH-1:0] res,
   output reg err,oflow,cout,g,l,e 
);
    // Internal registers and wires
    wire clk_new;
    reg start,done;
    reg [WIDTH-1:0] temp_a, temp_b;
    reg [CMD_WIDTH-1:0] prev_cmd;
    
    //gated clk
    assign clk_new = clk & ce;
    
    // Sequential logic for ALU operations
    always @(posedge clk_new or posedge rst) begin
        //reset condition
        if (rst) begin
            res <= 0;
            err <= 0;
            oflow <= 0;
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
            oflow <= 0;
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
                            cout <= (op_a + op_b) > {WIDTH{1'b1}};
                        end
                    end
                    1: begin // Subtraction
                        if(inp_valid==2'b11) begin
                            res <= op_a - op_b;
                            oflow <= (op_a < op_b);
                        end
                    end
                    2: begin // Addition with carry
                        if(inp_valid==2'b11) begin
                            res <= op_a + op_b + cin;
                            cout <= (op_a + op_b + cin) > {WIDTH{1'b1}};
                        end
                    end
                    3: begin // Subtraction with borrow
                        if(inp_valid==2'b11) begin
                            res <= op_a - op_b - cin;
                            oflow <= (op_a < (op_b + cin));
                        end
                    end
                    4: begin // Increment A
                        if(inp_valid[0]) begin
                            res <= op_a + 1'b1;
                            cout <= (op_a + 1'b1) > {WIDTH{1'b1}};
                        end
                    end
                    5: begin // Decrement A
                        if(inp_valid[0]) begin
                            res <= op_a - 1'b1;
                            oflow <= (op_a == 0);
                        end
                    end
                    6: begin // Increment B
                        if(inp_valid[1]) begin
                            res <= op_b + 1'b1;
                            cout <= (op_b + 1'b1) > {WIDTH{1'b1}};
                        end
                    end
                    7: begin // Decrement B
                        if(inp_valid[1]) begin
                            res <= op_b - 1'b1;
                            oflow <= (op_b == 0);
                        end
                    end
                    8: begin // Comparison
                        if(inp_valid==2'b11) begin
                            if (op_a>op_b) g<=1;
                            else if (op_a<op_b) l<=1;
                            else e<=1;
                        end
                    end
                    9: begin // Multiplication with increment
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
                    10: begin // Multiplication with shift
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
                    11: begin // Signed addition
                        if (inp_valid==2'b11) begin
                            res <= $signed(op_a) + $signed(op_b);
                            {g,l,e} <= ($signed(op_a) == $signed(op_b)) ? 3'b001 : ($signed(op_a) > $signed(op_b)) ? 3'b100 : 3'b010; 
                        end
                    end
                    12: begin // Signed subtraction
                        if (inp_valid==2'b11) begin
                            res <= $signed(op_a) - $signed(op_b);
                            {g,l,e} <= ($signed(op_a) == $signed(op_b)) ? 3'b001 : ($signed(op_a) > $signed(op_b)) ? 3'b100 : 3'b010; 
                        end
                    end
               endcase 
            end
            else begin
                case (cmd)
                    0: begin // AND
                        if(inp_valid==2'b11) res <= op_a & op_b;
                    end
                    1: begin // NAND
                        if(inp_valid==2'b11) res <= ~(op_a & op_b);
                    end
                    2: begin // OR
                        if(inp_valid==2'b11) res <= op_a | op_b;
                    end
                    3: begin // NOR
                        if(inp_valid==2'b11) res <= ~(op_a | op_b);
                    end
                    4: begin // XOR
                        if(inp_valid==2'b11) res <= op_a ^ op_b;
                    end
                    5: begin // XNOR
                        if(inp_valid==2'b11) res <= ~(op_a ^ op_b);
                    end
                    6: begin // NOT A
                        if(inp_valid[0]) res <= ~op_a;
                    end
                    7: begin // NOT B
                        if(inp_valid[1]) res <= ~op_b;
                    end
                    8: begin // Right Shift A
                        if(inp_valid[0]) res[WIDTH-1:0] <= op_a >> 1;
                    end
                    9: begin // Left Shift A
                        if(inp_valid[0]) res[WIDTH-1:0] <= op_a << 1;
                    end
                    10: begin // Right Shift B
                        if(inp_valid[1]) res[WIDTH-1:0] <= op_b >> 1;
                    end
                    11: begin // Left Shift B
                        if(inp_valid[1]) res[WIDTH-1:0] <= op_b << 1;
                    end
                    12: begin // Rotate Left A, B times
                        if (inp_valid==2'b11) begin
                            res[WIDTH-1:0] <= op_a << op_b[$clog2(WIDTH)-1:0]|op_a >> (WIDTH - op_b[$clog2(WIDTH)-1:0]);
                            if (|op_b[WIDTH-1:$clog2(WIDTH)+1]) begin
                                err <= 1;
                            end
                        end
                    end
                    13: begin // Rotate Right A, B times
                        if(inp_valid==2'b11) begin
                            res[WIDTH-1:0] <= op_a >> op_b[$clog2(WIDTH)-1:0]|op_a << (WIDTH - op_b[$clog2(WIDTH)-1:0]);
                            if (|op_b[WIDTH-1:$clog2(WIDTH)+1]) begin
                                err <= 1;
                            end
                        end
                    end
                endcase
            end
        end
    end

    // Combinational logic for overflow detection
    always @( *) begin
        if(mode && (cmd == 11||cmd == 12)) begin
            oflow <= (op_a[WIDTH-1] == op_b[WIDTH-1]) && (res[WIDTH-1] != op_a[WIDTH-1]); 
        end
        else
            oflow <= 0;
    end
    
endmodule //ALU


