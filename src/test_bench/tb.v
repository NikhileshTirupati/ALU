`timescale 1ns/1ps

module tb;
  parameter DATA_WIDTH = 8;
  parameter CMD_WIDTH  = 4;

  reg clk;
  reg rst;

  reg [DATA_WIDTH-1:0] opa;
  reg [DATA_WIDTH-1:0] opb;
  reg                  cin;
  reg                  ce;
  reg                  mode;       // 1 = Arithmetic, 0 = Logical
  reg [1:0]            inp_valid;  // 11=both, 01=A, 10=B, 00=none
  reg [CMD_WIDTH-1:0]  cmd;

  wire [2*DATA_WIDTH-1:0] res;
  wire                  oflow;
  wire                  cout;
  wire                  g;
  wire                  l;
  wire                  e;
  wire                  err;

    ALU#(CMD_WIDTH, DATA_WIDTH) dut (
    .clk       (clk),
    .rst       (rst),
    .ce        (ce),
    .inp_valid (inp_valid),
    .mode      (mode),
    .cmd       (cmd),
    .op_a       (opa),
    .op_b       (opb),
    .cin       (cin),
    .result       (res),
    .Oflow     (oflow),
    .Cout      (cout),
    .G         (g),
    .L         (l),
    .E         (e),
    .erro       (err)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer i;
  parameter [CMD_WIDTH-1:0]
    CMD_ADD          = 4'd0,
    CMD_SUB          = 4'd1,
    CMD_ADD_CIN      = 4'd2,
    CMD_SUB_CIN      = 4'd3,
    CMD_INC_A        = 4'd4,
    CMD_DEC_A        = 4'd5,
    CMD_INC_B        = 4'd6,
    CMD_DEC_B        = 4'd7,
    CMD_CMP          = 4'd8,
    CMD_INC_BOTH_MUL = 4'd9,
    CMD_SHL_A_MUL    = 4'd10,
    CMD_SIGNED_ADD   = 4'd11,
    CMD_SIGNED_SUB   = 4'd12;

  parameter [CMD_WIDTH-1:0]
    CMD_AND     = 4'd0,
    CMD_NAND    = 4'd1,
    CMD_OR      = 4'd2,
    CMD_NOR     = 4'd3,
    CMD_XOR     = 4'd4,
    CMD_XNOR    = 4'd5,
    CMD_NOT_A   = 4'd6,
    CMD_NOT_B   = 4'd7,
    CMD_SHR1_A  = 4'd8,
    CMD_SHL1_A  = 4'd9,
    CMD_SHR1_B  = 4'd10,
    CMD_SHL1_B  = 4'd11,
    CMD_ROL_A_B = 4'd12,
    CMD_ROR_A_B = 4'd13;

  function [DATA_WIDTH-1:0] rol;
    input [DATA_WIDTH-1:0] val;
    input integer          amt;
    integer n;
    begin
      n   = amt % DATA_WIDTH;
      rol = (val << n) | (val >> (DATA_WIDTH - n));
    end
  endfunction

  function [DATA_WIDTH-1:0] ror_f;
    input [DATA_WIDTH-1:0] val;
    input integer          amt;
    integer n;
    begin
      n     = amt % DATA_WIDTH;
      ror_f = (val >> n) | (val << (DATA_WIDTH - n));
    end
  endfunction

  task drive_and_check_1cyc;
    input [DATA_WIDTH-1:0] a;
    input [DATA_WIDTH-1:0] b;
    input                  c_in;
    input                  i_mode;
    input [1:0]            valid;
    input [CMD_WIDTH-1:0]  i_cmd;
    input [2*DATA_WIDTH-1:0] exp_res;
    input                  exp_cout;
    input                  exp_oflow;
    input                  exp_g;
    input                  exp_l;
    input                  exp_e;
    input                  exp_err;
    input [127:0]          test_name;
    begin
      opa       = a;
      opb       = b;
      cin       = c_in;
      mode      = i_mode;
      inp_valid = valid;
      cmd       = i_cmd;
      ce        = 1'b1;

      @(posedge clk);
      @(posedge clk); #1;

      if (res !== exp_res) begin
        $display("[FAIL] %0s : RES    got=%0h exp=%0h", test_name, res, exp_res);
      end else begin
        $display("[PASS] %0s : RES=%0h", test_name, res);
      end
      if (cout !== exp_cout) begin
        $display("[FAIL] %0s : COUT   got=%0b exp=%0b", test_name, cout, exp_cout);
      end
      if (oflow !== exp_oflow) begin
        $display("[FAIL] %0s : OFLOW  got=%0b exp=%0b", test_name, oflow, exp_oflow);
      end
      if (g !== exp_g) begin
        $display("[FAIL] %0s : G      got=%0b exp=%0b", test_name, g, exp_g);
      end
      if (l !== exp_l) begin
        $display("[FAIL] %0s : L      got=%0b exp=%0b", test_name, l, exp_l);
      end
      if (e !== exp_e) begin
        $display("[FAIL] %0s : E      got=%0b exp=%0b", test_name, e, exp_e);
      end
      if (err !== exp_err) begin
        $display("[FAIL] %0s : ERR    got=%0b exp=%0b", test_name, err, exp_err);
      end
    end
  endtask
  
  // For compare
  task drive_and_check_1cyc_cmp;
    input [DATA_WIDTH-1:0] a;
    input [DATA_WIDTH-1:0] b;
    input                  c_in;
    input                  i_mode;
    input [1:0]            valid;
    input [CMD_WIDTH-1:0]  i_cmd;
    input                  exp_g;
    input                  exp_l;
    input                  exp_e;
    input                  exp_err;
    input [127:0]          test_name;
    begin
      opa       = a;
      opb       = b;
      cin       = c_in;
      mode      = i_mode;
      inp_valid = valid;
      cmd       = i_cmd;
      ce        = 1'b1;

      @(posedge clk);
      @(posedge clk); #1;
      if (g !== exp_g) begin
        $display("[FAIL] %0s : G      got=%0b exp=%0b", test_name, g, exp_g);
      end
      if (l !== exp_l) begin
        $display("[FAIL] %0s : L      got=%0b exp=%0b", test_name, l, exp_l);
      end
      if (e !== exp_e) begin
        $display("[FAIL] %0s : E      got=%0b exp=%0b", test_name, e, exp_e);
      end
      if (err !== exp_err) begin
        $display("[FAIL] %0s : ERR    got=%0b exp=%0b", test_name, err, exp_err);
      end
    end
  endtask

  task drive_and_check_2cyc;
    input [DATA_WIDTH-1:0] a;
    input [DATA_WIDTH-1:0] b;
    input                  c_in;
    input                  i_mode;
    input [1:0]            valid;
    input [CMD_WIDTH-1:0]  i_cmd;
    input [2*DATA_WIDTH-1:0] exp_res;
    input                  exp_err;
    input [127:0]          test_name;
    begin
      opa       = a;
      opb       = b;
      cin       = c_in;
      mode      = i_mode;
      inp_valid = valid;
      cmd       = i_cmd;
      ce        = 1'b1;

      @(posedge clk);
      @(posedge clk);
      @(posedge clk); #1;

      if (res !== exp_res) begin
        $display("[FAIL] %0s : RES got=%0h exp=%0h", test_name, res, exp_res);
      end else begin
        $display("[PASS] %0s : RES=%0h", test_name, res);
      end
      if (exp_err != err) begin
        $display("[FAIL] %0s : ERR got=%0b exp=%0b", test_name, err, exp_err);
      end
    end
  endtask
  
  task drive_and_check_2cyc_discard;
    input [DATA_WIDTH-1:0] a;
    input [DATA_WIDTH-1:0] b;
    input                  c_in;
    input                  i_mode;
    input [1:0]            valid;
    input [CMD_WIDTH-1:0]  i_cmd;
    input [CMD_WIDTH-1:0]  i_cmd_2;
    input [2*DATA_WIDTH-1:0] exp_res;
    input                  exp_err;
    input [127:0]          test_name;
    begin
      @(posedge clk); #1;
      opa       = a;
      opb       = b;
      cin       = c_in;
      mode      = i_mode;
      inp_valid = valid;
      cmd       = i_cmd;
      ce        = 1'b1;

      opa       = a;
      opb       = b;
      cin       = c_in;
      mode      = i_mode;
      inp_valid = valid;
      cmd       = i_cmd_2;
      ce        = 1'b1;
      @(posedge clk); 
      @(posedge clk);
      @(posedge clk);#1;

      if (res !== exp_res) begin
        $display("[FAIL] %0s : RES got=%0h exp=%0h", test_name, res, exp_res);
      end else begin
        $display("[PASS] %0s : RES=%0h", test_name, res);
      end
      if (exp_err != err) begin
        $display("[FAIL] %0s : ERR got=%0b exp=%0b", test_name, err, exp_err);
      end
    end
  endtask

  

  task do_reset;
    begin
      rst       = 1'b1;
      ce        = 1'b0;
      opa       = {DATA_WIDTH{1'b0}};
      opb       = {DATA_WIDTH{1'b0}};
      cin       = 1'b0;
      mode      = 1'b0;
      inp_valid = 2'b00;
      cmd       = {CMD_WIDTH{1'b0}};
      repeat(3) @(posedge clk);
      #1 rst = 1'b0;
      @(posedge clk);
    end
  endtask

  reg [2*DATA_WIDTH-1:0] captured_res;

  initial begin

    do_reset;

    // 1. ARITHMETIC TESTS (MODE = 1)
    $display("\n--- Arithmetic Operations (MODE=1) ---");

    drive_and_check_1cyc(8'h06, 8'h01, 0, 1, 2'b11, CMD_ADD,
                         8'h07, 0, 0, 0, 0, 0, 0, "FID: 9");

    drive_and_check_1cyc(8'hFF, 8'h01, 0, 1, 2'b11, CMD_ADD,
                         16'h100, 1, 0, 0, 0, 0, 0, "FID: 10");
   
    drive_and_check_1cyc(8'h06, 8'h01, 0, 1, 2'b01, CMD_ADD,
                         16'h100, 0, 0, 0, 0, 0, 1, "FID: 11");

    drive_and_check_1cyc(8'h05, 8'h03, 0, 1, 2'b11, CMD_SUB,
                         8'h02, 0, 0, 0, 0, 0, 0, "FID: 12");

    drive_and_check_1cyc(8'h03, 8'h05, 0, 1, 2'b11, CMD_SUB,
                         16'hFFFE, 0, 1, 0, 0, 0, 0, "FID: 13");
    
    drive_and_check_1cyc(8'h05, 8'h03, 0, 1, 2'b01, CMD_SUB,
                         16'hFFFE, 0, 0, 0, 0, 0, 1, "FID: 14");

    drive_and_check_1cyc(8'h03, 8'h02, 1, 1, 2'b11, CMD_ADD_CIN,
                         8'h06, 0, 0, 0, 0, 0, 0, "FID: 15");
    
    drive_and_check_1cyc(8'hFF, 8'h00, 1, 1, 2'b11, CMD_ADD_CIN,
                         16'h100, 1, 0, 0, 0, 0, 0, "FID: 16");
    
    drive_and_check_1cyc(8'h03, 8'h02, 1, 1, 2'b01, CMD_ADD_CIN,
                         16'h100, 0, 0, 0, 0, 0, 1, "FID: 17");

    drive_and_check_1cyc(8'h0A, 8'h03, 1, 1, 2'b11, CMD_SUB_CIN,
                         8'h06, 0, 0, 0, 0, 0, 0, "FID: 18");
    
    drive_and_check_1cyc(8'h00, 8'h00, 1, 1, 2'b11, CMD_SUB_CIN,
                         16'hFFFF, 0, 1, 0, 0, 0, 0, "FID: 19");
    
    drive_and_check_1cyc(8'h0A, 8'h03, 1, 1, 2'b01, CMD_SUB_CIN,
                         16'hFFFF, 0, 0, 0, 0, 0, 1, "FID: 20");

    drive_and_check_1cyc(8'h05, 8'h00, 0, 1, 2'b01, CMD_INC_A,
                         8'h06, 0, 0, 0, 0, 0, 0, "FID: 21");
    
    drive_and_check_1cyc(8'hFF, 8'h00, 0, 1, 2'b01, CMD_INC_A,
                         16'h100, 0, 0, 0, 0, 0, 0, "FID: 22");
    
    drive_and_check_1cyc(8'h05, 8'h00, 0, 1, 2'b10, CMD_INC_A,
                         16'h100, 0, 0, 0, 0, 0, 1, "FID: 23");

    drive_and_check_1cyc(8'h05, 8'h00, 0, 1, 2'b01, CMD_DEC_A,
                         8'h04, 0, 0, 0, 0, 0, 0, "FID: 24");
    
    drive_and_check_1cyc(8'h04, 8'h00, 0, 1, 2'b10, CMD_DEC_A,
                         8'h04, 0, 0, 0, 0, 0, 1, "FID: 25");
    
    drive_and_check_1cyc(8'h00, 8'h00, 0, 1, 2'b01, CMD_DEC_A,
                         16'hFFFF, 0, 0, 0, 0, 0, 0, "FID: 26");

    drive_and_check_1cyc(8'h00, 8'h07, 0, 1, 2'b10, CMD_INC_B,
                         8'h08, 0, 0, 0, 0, 0, 0, "FID: 27");
    
    drive_and_check_1cyc(8'h00, 8'h06, 0, 1, 2'b01, CMD_INC_B,
                         8'h08, 0, 0, 0, 0, 0, 1, "FID: 28");
    
    drive_and_check_1cyc(8'h00, 8'hFF, 0, 1, 2'b10, CMD_INC_B,
                         16'h100, 0, 0, 0, 0, 0, 0, "FID: 29");

    drive_and_check_1cyc(8'h00, 8'h07, 0, 1, 2'b10, CMD_DEC_B,
                         8'h06, 0, 0, 0, 0, 0, 0, "FID: 30");
    
    drive_and_check_1cyc(8'h00, 8'h06, 0, 1, 2'b01, CMD_DEC_B,
                         8'h06, 0, 0, 0, 0, 0, 1, "FID: 31");
    
    drive_and_check_1cyc(8'h00, 8'h00, 0, 1, 2'b10, CMD_DEC_B,
                         16'hFFFF, 0, 0, 0, 0, 0, 0, "FID: 32");

    drive_and_check_1cyc_cmp(8'h05, 8'h05, 0, 1, 2'b11, CMD_CMP,
                         0, 0, 1, 0, "FID: 33");

    drive_and_check_1cyc_cmp(8'h03, 8'h05, 0, 1, 2'b11, CMD_CMP,
                         0, 1, 0, 0, "FID: 34");

    drive_and_check_1cyc_cmp(8'h05, 8'h03, 0, 1, 2'b11, CMD_CMP,
                         1, 0, 0, 0, "FID: 35");
    
    drive_and_check_1cyc_cmp(8'h05, 8'h03, 0, 1, 2'b10, CMD_CMP,
                         0, 0, 0, 1, "FID: 36");



    // Multiply - 2-cycle latency
    drive_and_check_2cyc(8'h03, 8'h04, 0, 1, 2'b11, CMD_INC_BOTH_MUL,
                         8'h14, 0, "FID: 37");
    
    drive_and_check_2cyc(8'h01, 8'h04, 0, 1, 2'b11, CMD_INC_BOTH_MUL,
                         8'h0A, 0, "FID: 38");
    
    drive_and_check_2cyc_discard(8'h01, 8'h04, 0, 1, 2'b11, CMD_INC_BOTH_MUL, CMD_ADD,
                         8'h05, 0, "FID: 39");
    
    drive_and_check_2cyc_discard(8'h01, 8'h04, 0, 1, 2'b11, CMD_INC_BOTH_MUL, CMD_SHL_A_MUL,
                         8'h08, 0, "FID: 40");
    
    drive_and_check_1cyc(8'h03, 8'h04, 0, 1, 2'b10, CMD_INC_BOTH_MUL,
                         8'h08, 0, 0, 0, 0, 0, 1, "FID: 41");

    drive_and_check_2cyc(8'h03, 8'h04, 0, 1, 2'b11, CMD_SHL_A_MUL,
                         8'h18, 0, "FID: 42");
    
    drive_and_check_2cyc(8'h01, 8'h02, 0, 1, 2'b11, CMD_SHL_A_MUL,
                         8'h04, 0, "FID: 43");
    
    drive_and_check_2cyc_discard(8'h01, 8'h04, 0, 1, 2'b11, CMD_SHL_A_MUL, CMD_ADD,
                         8'h05, 0, "FID: 44");
    
    drive_and_check_2cyc_discard(8'h01, 8'h04, 0, 1, 2'b11, CMD_SHL_A_MUL, CMD_INC_BOTH_MUL,
                         8'h0A, 0, "FID: 45");
    
    drive_and_check_1cyc(8'h03, 8'h04, 0, 1, 2'b10, CMD_SHL_A_MUL,
                         8'h0A, 0, 0, 0, 0, 0, 1, "FID: 46");

    drive_and_check_1cyc(8'h0F, 8'h01, 0, 1, 2'b11, CMD_SIGNED_ADD,
                         8'h10, 0, 0, 1, 0, 0, 0, "FID: 47");

    drive_and_check_1cyc(8'h7F, 8'h01, 0, 1, 2'b11, CMD_SIGNED_ADD,
                         8'h80, 0, 1, 1, 0, 0, 0, "FID: 48");
    
    drive_and_check_1cyc(8'h0F, 8'h01, 0, 1, 2'b01, CMD_SIGNED_ADD,
                         8'h80, 0, 0, 0, 0, 0, 1, "FID: 49");

    drive_and_check_1cyc(8'h32, 8'h14, 0, 1, 2'b11, CMD_SIGNED_SUB,
                         8'h1E, 0, 0, 1, 0, 0, 0, "FID: 50");

    drive_and_check_1cyc(8'h80, 8'h01, 0, 1, 2'b11, CMD_SIGNED_SUB,
                         16'hFF7F, 0, 1, 0, 1, 0, 0, "FID: 51");
    
    drive_and_check_1cyc(8'h32, 8'h14, 0, 1, 2'b10, CMD_SIGNED_SUB,
                         16'hFF7F, 0, 0, 1, 0, 0, 1, "FID: 52");

    //------------------------------------------------------------------------
    // 2. LOGICAL TESTS (MODE = 0)
    //------------------------------------------------------------------------
    $display("\n--- Logical Operations (MODE=0) ---");

    drive_and_check_1cyc(8'hAA, 8'h0F, 0, 0, 2'b11, CMD_AND,
                         8'h0A, 0, 0, 0, 0, 0, 0, "FID: 53");
    
    drive_and_check_1cyc(8'hA0, 8'h0F, 0, 0, 2'b10, CMD_AND,
                         8'h0A, 0, 0, 0, 0, 0, 1, "FID: 54");

    drive_and_check_1cyc(8'hAA, 8'h0F, 0, 0, 2'b11, CMD_NAND,
                         8'hF5, 0, 0, 0, 0, 0, 0, "FID: 55");
    
    drive_and_check_1cyc(8'h0A, 8'h0F, 0, 0, 2'b10, CMD_NAND,
                         8'hF5, 0, 0, 0, 0, 0, 1, "FID: 56");

    drive_and_check_1cyc(8'hA0, 8'h0F, 0, 0, 2'b11, CMD_OR,
                         8'hAF, 0, 0, 0, 0, 0, 0, "FID: 57");
    
    drive_and_check_1cyc(8'hA0, 8'h3F, 0, 0, 2'b10, CMD_OR,
                         8'hAF, 0, 0, 0, 0, 0, 1, "FID: 58");

    drive_and_check_1cyc(8'hA0, 8'h0F, 0, 0, 2'b11, CMD_NOR,
                         8'h50, 0, 0, 0, 0, 0, 0, "FID: 59");
    
    drive_and_check_1cyc(8'hA0, 8'h1F, 0, 0, 2'b10, CMD_NOR,
                         8'h50, 0, 0, 0, 0, 0, 1, "FID: 60");

    drive_and_check_1cyc(8'hFF, 8'h0F, 0, 0, 2'b11, CMD_XOR,
                         8'hF0, 0, 0, 0, 0, 0, 0, "FID: 61");
    
    drive_and_check_1cyc(8'hFF, 8'h1F, 0, 0, 2'b10, CMD_XOR,
                         8'hF0, 0, 0, 0, 0, 0, 1, "FID: 62");

    drive_and_check_1cyc(8'hFF, 8'h0F, 0, 0, 2'b11, CMD_XNOR,
                         8'h0F, 0, 0, 0, 0, 0, 0, "FID: 63");
    
    drive_and_check_1cyc(8'hFF, 8'h1F, 0, 0, 2'b10, CMD_XNOR,
                         8'h0F, 0, 0, 0, 0, 0, 1, "FID: 64");

    drive_and_check_1cyc(8'hAA, 8'h00, 0, 0, 2'b01, CMD_NOT_A,
                         8'h55, 0, 0, 0, 0, 0, 0, "FID: 65");
    
    drive_and_check_1cyc(8'hA1, 8'h00, 0, 0, 2'b10, CMD_NOT_A,
                         8'h55, 0, 0, 0, 0, 0, 1, "FID: 66");

    drive_and_check_1cyc(8'h00, 8'h55, 0, 0, 2'b10, CMD_NOT_B,
                         8'hAA, 0, 0, 0, 0, 0, 0, "FID: 67");
    
    drive_and_check_1cyc(8'h00, 8'h15, 0, 0, 2'b01, CMD_NOT_B,
                         8'hAA, 0, 0, 0, 0, 0, 1, "FID: 68");

    drive_and_check_1cyc(8'hAA, 8'h00, 0, 0, 2'b01, CMD_SHR1_A,
                         8'h55, 0, 0, 0, 0, 0, 0, "FID: 69");
    
    drive_and_check_1cyc(8'hA2, 8'h00, 0, 0, 2'b10, CMD_SHR1_A,
                         8'h55, 0, 0, 0, 0, 0, 1, "FID: 70");

    drive_and_check_1cyc(8'h55, 8'h00, 0, 0, 2'b01, CMD_SHL1_A,
                         8'hAA, 0, 0, 0, 0, 0, 0, "FID: 71");
    
    drive_and_check_1cyc(8'h55, 8'h00, 0, 0, 2'b10, CMD_SHL1_A,
                         8'hAA, 0, 0, 0, 0, 0, 1, "FID: 72");

    drive_and_check_1cyc(8'h00, 8'hF0, 0, 0, 2'b10, CMD_SHR1_B,
                         8'h78, 0, 0, 0, 0, 0, 0, "FID: 73");
    
    drive_and_check_1cyc(8'h00, 8'hF1, 0, 0, 2'b01, CMD_SHR1_B,
                         8'h78, 0, 0, 0, 0, 0, 1, "FID: 74");

    drive_and_check_1cyc(8'h00, 8'h0F, 0, 0, 2'b10, CMD_SHL1_B,
                         8'h1E, 0, 0, 0, 0, 0, 0, "FID: 75");
    
    drive_and_check_1cyc(8'h00, 8'h1F, 0, 0, 2'b01, CMD_SHL1_B,
                         8'h1E, 0, 0, 0, 0, 0, 1, "FID: 76");

    drive_and_check_1cyc(8'hB4, 8'h02, 0, 0, 2'b11, CMD_ROL_A_B,
                         rol(8'hB4, 2), 0, 0, 0, 0, 0, 0, "FID: 77");

    drive_and_check_1cyc(8'h01, 8'h0F, 0, 0, 2'b11, CMD_ROL_A_B,
                         rol(8'h01, 7), 0, 0, 0, 0, 0, 0, "FID: 78");

    drive_and_check_1cyc(8'hAB, 8'h12, 0, 0, 2'b11, CMD_ROL_A_B,
                         rol(8'hAB, 2), 0, 0, 0, 0, 0, 1, "FID: 79");
    
    drive_and_check_1cyc(8'h01, 8'h0F, 0, 0, 2'b10, CMD_ROL_A_B,
                         rol(8'hAB, 2), 0, 0, 0, 0, 0, 1, "FID: 80");

    drive_and_check_1cyc(8'hB4, 8'h03, 0, 0, 2'b11, CMD_ROR_A_B,
                         ror_f(8'hB4, 3), 0, 0, 0, 0, 0, 0, "FID: 81");

    drive_and_check_1cyc(8'hB4, 8'h0F, 0, 0, 2'b11, CMD_ROR_A_B,
                         ror_f(8'hB4, 7), 0, 0, 0, 0, 0, 0, "FID: 82");
    
    drive_and_check_1cyc(8'hB4, 8'h22, 0, 0, 2'b11, CMD_ROR_A_B,
                         ror_f(8'hB4, 2), 0, 0, 0, 0, 0, 1, "FID: 83");

    drive_and_check_1cyc(8'h80, 8'h01, 0, 0, 2'b10, CMD_ROR_A_B,
                         ror_f(8'hB4, 2), 0, 0, 0, 0, 0, 1, "FID: 84");

    //CE Test
    @(posedge clk); #1;
    opa = 8'h0A; opb = 8'h05; cin = 0; mode = 1;
    inp_valid = 2'b11; cmd = CMD_ADD; ce = 1;
    @(posedge clk); #1;
    captured_res = res;

    @(posedge clk); #1;
    ce  = 0;
    opa = 8'hFF; opb = 8'hFF;
    @(posedge clk); #1;
    if (res !== captured_res) begin
      $display("[FAIL] FID: 4,5 CE=0: output changed (got=%0h, was=%0h)", res, captured_res);
    end else begin
      $display("[PASS] FID: 4,5 CE=0: output held correctly at %0h", captured_res);
    end

    //Reset Test
    @(posedge clk); #1;
    rst = 1'b1;
    @(posedge clk); #1;
    if (res !== {DATA_WIDTH{1'b0}} || oflow !== 0 || cout !== 0 ||
        g !== 0 || l !== 0 || e !== 0) begin
      $display("[FAIL] FID: 2 RST: outputs not cleared (res=%0h oflow=%0b cout=%0b g=%0b l=%0b e=%0b)",
               res, oflow, cout, g, l, e);
    end else begin
      $display("[PASS] FID: 2 RST: all outputs cleared correctly");
    end
    #1 rst = 1'b0;
    @(posedge clk);

    //Inp_valid test
    drive_and_check_1cyc(8'hAA, 8'hXX, 0, 0, 2'b01, CMD_NOT_A,
                         8'h55, 0, 0, 0, 0, 0, 0, "NOT_A inp_valid=01");

    drive_and_check_1cyc(8'hXX, 8'h55, 0, 0, 2'b10, CMD_NOT_B,
                         8'hAA, 0, 0, 0, 0, 0, 0, "NOT_B inp_valid=10");
    
    for(i=0; i<14; i=i+1) begin
      drive_and_check_1cyc(8'hFF, 8'hFF, 0, 0, 2'b00, i,
                           8'hAA, 0, 0, 0, 0, 0, 1, "FID: 8");
    end
  end

endmodule

