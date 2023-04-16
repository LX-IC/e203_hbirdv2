/*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */

//=====================================================================
//
// Designer   : LZB
//
// Description:
//  The Module to realize a simple NICE core
//
// ====================================================================
`include "e203_defines.v"

`ifdef E203_HAS_NICE//{
module e203_subsys_nice_core (
    // System	
    input                         nice_clk             ,
    input                         nice_rst_n	          ,
    output                        nice_active	      ,
    output                        nice_mem_holdup	  ,
//    output                        nice_rsp_err_irq	  ,
    // Control cmd_req
    input                         nice_req_valid       ,
    output                        nice_req_ready       ,
    input  [`E203_XLEN-1:0]       nice_req_inst        ,
    input  [`E203_XLEN-1:0]       nice_req_rs1         ,
    input  [`E203_XLEN-1:0]       nice_req_rs2         ,
    // Control cmd_rsp	
    output                        nice_rsp_valid       ,
    input                         nice_rsp_ready       ,
    output [`E203_XLEN-1:0]       nice_rsp_rdat        ,//д���ݵ��Ĵ���
    output                        nice_rsp_err    	  ,
    // Memory lsu_req	
    output                        nice_icb_cmd_valid   ,
    input                         nice_icb_cmd_ready   ,
    output [`E203_ADDR_SIZE-1:0]  nice_icb_cmd_addr    ,
    output                        nice_icb_cmd_read    ,
    output [`E203_XLEN-1:0]       nice_icb_cmd_wdata   ,//д���ݵ��ڴ�
//    output [`E203_XLEN_MW-1:0]     nice_icb_cmd_wmask   ,  // 
    output [1:0]                  nice_icb_cmd_size    ,
    // Memory lsu_rsp	
    input                         nice_icb_rsp_valid   ,
    output                        nice_icb_rsp_ready   ,
    input  [`E203_XLEN-1:0]       nice_icb_rsp_rdata   ,
    input                         nice_icb_rsp_err	

);

   localparam ROWBUF_DP = 4;
   localparam ROWBUF_IDX_W = 2;
   localparam ROW_IDX_W = 2;
   localparam COL_IDX_W = 4;
   localparam PIPE_NUM = 3;


// here we only use custom3: 
// CUSTOM0 = 7'h0b, R type
// CUSTOM1 = 7'h2b, R tpye
// CUSTOM2 = 7'h5b, R type
// CUSTOM3 = 7'h7b, R type

// RISC-V format  
//	.insn r  0x33,  0,  0, a0, a1, a2       0:  00c58533[ 	]+add [ 	]+a0,a1,a2
//	.insn i  0x13,  0, a0, a1, 13           4:  00d58513[ 	]+addi[ 	]+a0,a1,13
//	.insn i  0x67,  0, a0, 10(a1)           8:  00a58567[ 	]+jalr[ 	]+a0,10 (a1)
//	.insn s   0x3,  0, a0, 4(a1)            c:  00458503[ 	]+lb  [ 	]+a0,4(a1)
//	.insn sb 0x63,  0, a0, a1, target       10: feb508e3[ 	]+beq [ 	]+a0,a1,0 target
//	.insn sb 0x23,  0, a0, 4(a1)            14: 00a58223[ 	]+sb  [ 	]+a0,4(a1)
//	.insn u  0x37, a0, 0xfff                18: 00fff537[ 	]+lui [ 	]+a0,0xfff
//	.insn uj 0x6f, a0, target               1c: fe5ff56f[ 	]+jal [ 	]+a0,0 target
//	.insn ci 0x1, 0x0, a0, 4                20: 0511    [ 	]+addi[ 	]+a0,a0,4
//	.insn cr 0x2, 0x8, a0, a1               22: 852e    [ 	]+mv  [ 	]+a0,a1
//	.insn ciw 0x0, 0x0, a1, 1               24: 002c    [ 	]+addi[ 	]+a1,sp,8
//	.insn cb 0x1, 0x6, a1, target           26: dde9    [ 	]+beqz[ 	]+a1,0 target
//	.insn cj 0x1, 0x5, target               28: bfe1    [ 	]+j   [ 	]+0 targe

   ////////////////////////////////////////////////////////////
   // decode
   ////////////////////////////////////////////////////////////
   wire [6:0] opcode      = {7{nice_req_valid}} & nice_req_inst[6:0];//��ȡopcode
   wire [2:0] rv32_func3  = {3{nice_req_valid}} & nice_req_inst[14:12];//��ȡfunc3
   wire [6:0] rv32_func7  = {7{nice_req_valid}} & nice_req_inst[31:25];//��ȡfunc7

//   wire opcode_custom0 = (opcode == 7'b0001011); 
//   wire opcode_custom1 = (opcode == 7'b0101011); 
//   wire opcode_custom2 = (opcode == 7'b1011011); 
   wire opcode_custom3 = (opcode == 7'b1111011); //ƥ��opcodeȷ��Ϊcustom3�Զ���ָ��

   wire rv32_func3_000 = (rv32_func3 == 3'b000); //ƥ��func3
   wire rv32_func3_001 = (rv32_func3 == 3'b001); 
   wire rv32_func3_010 = (rv32_func3 == 3'b010); 
   wire rv32_func3_011 = (rv32_func3 == 3'b011); 
   wire rv32_func3_100 = (rv32_func3 == 3'b100); 
   wire rv32_func3_101 = (rv32_func3 == 3'b101); 
   wire rv32_func3_110 = (rv32_func3 == 3'b110); 
   wire rv32_func3_111 = (rv32_func3 == 3'b111); 

   wire rv32_func7_0000000 = (rv32_func7 == 7'b0000000); //ƥ��func7
   wire rv32_func7_0000001 = (rv32_func7 == 7'b0000001); 
   wire rv32_func7_0000010 = (rv32_func7 == 7'b0000010); 
   wire rv32_func7_0000011 = (rv32_func7 == 7'b0000011); 
   wire rv32_func7_0000100 = (rv32_func7 == 7'b0000100); 
   wire rv32_func7_0000101 = (rv32_func7 == 7'b0000101); 
   wire rv32_func7_0000110 = (rv32_func7 == 7'b0000110); 
   wire rv32_func7_0000111 = (rv32_func7 == 7'b0000111); 

   ////////////////////////////////////////////////////////////
   // custom3:
   // Supported format: only R type here
   // Supported instr:
   //  1. custom3 lbuf: load data(in memory) to row_buf
   //     lbuf (a1)
   //     .insn r opcode, func3, func7, rd, rs1, rs2    
   //  2. custom3 sbuf: store data(in row_buf) to memory
   //     sbuf (a1)
   //     .insn r opcode, func3, func7, rd, rs1, rs2    
   //  3. custom3 acc rowsum: load data from memory(@a1), accumulate row datas and write back 
   //     rowsum rd, a1, x0
   //     .insn r opcode, func3, func7, rd, rs1, rs2    
   ////////////////////////////////////////////////////////////
   wire custom3_lbuf     = opcode_custom3 & rv32_func3_010 & rv32_func7_0000001; //�ж��Ƿ���custom3_lbufָ��
   wire custom3_sbuf     = opcode_custom3 & rv32_func3_010 & rv32_func7_0000010; 
   wire custom3_rowsum   = opcode_custom3 & rv32_func3_110 & rv32_func7_0000110; 

   ////////////////////////////////////////////////////////////
   //  multi-cyc op 
   ////////////////////////////////////////////////////////////
   wire custom_multi_cyc_op = custom3_lbuf | custom3_sbuf | custom3_rowsum;//�ж��Ƿ���Э������ָ��
   // need access memory
   wire custom_mem_op = custom3_lbuf | custom3_sbuf | custom3_rowsum;//�ж��Ƿ���Ҫ�����ڴ�
 
   ////////////////////////////////////////////////////////////
   // NICE FSM 
   ////////////////////////////////////////////////////////////
   parameter NICE_FSM_WIDTH = 2; //D���������ز�����DW��
   parameter IDLE     = 2'd0; //IDLE״̬
   parameter LBUF     = 2'd1; //LBUF״̬
   parameter SBUF     = 2'd2; //SBUF״̬
   parameter ROWSUM   = 2'd3; //ROWSUM״̬

   wire [NICE_FSM_WIDTH-1:0] state_r; //D�����������״̬����ǰ״̬��
   wire [NICE_FSM_WIDTH-1:0] nxt_state; //D������������״̬����һ״̬��
   wire [NICE_FSM_WIDTH-1:0] state_idle_nxt; //IDLE״̬����һ״̬
   wire [NICE_FSM_WIDTH-1:0] state_lbuf_nxt; //LBUF״̬����һ״̬
   wire [NICE_FSM_WIDTH-1:0] state_sbuf_nxt; //SBUF״̬����һ״̬
   wire [NICE_FSM_WIDTH-1:0] state_rowsum_nxt; //ROWSUM״̬����һ״̬

   wire nice_req_hsked;//��cpu���ֳɹ����ѽ���ָ��
   wire nice_rsp_hsked;//��cpu���ֳɹ����ѷ��ͽ��
   wire nice_icb_rsp_hsked;//��memory���ֳɹ����ѽ��շ���
   wire illgel_instr = ~(custom_multi_cyc_op);//0��������Э������ָ�� 1�������Э������ָ��

   wire state_idle_exit_ena; //�˳�IDLE״̬ʹ���ź�
   wire state_lbuf_exit_ena; //�˳�LBUF״̬ʹ���ź�
   wire state_sbuf_exit_ena; //�˳�SBUF״̬ʹ���ź�
   wire state_rowsum_exit_ena; //�˳�ROWSUM״̬ʹ���ź�
   wire state_ena; //D��������״̬ʹ������

   wire state_is_idle     = (state_r == IDLE); //��ǰ״̬��IDLE״̬
   wire state_is_lbuf     = (state_r == LBUF); //��ǰ״̬��LBUF״̬
   wire state_is_sbuf     = (state_r == SBUF); //��ǰ״̬��SBUF״̬
   wire state_is_rowsum   = (state_r == ROWSUM); //��ǰ״̬��ROWSUM״̬

  //�����ǰ״̬��IDLE״̬����cpu���ֳɹ����ѽ���ָ���Э������ָ���ʹ���˳�IDLE״̬ʹ���ź�
   assign state_idle_exit_ena = state_is_idle & nice_req_hsked & ~illgel_instr; 
  //IDLE״̬����һ״̬��LBUF��SBUF��ROWSUM
   assign state_idle_nxt =  custom3_lbuf    ? LBUF   : 
                            custom3_sbuf    ? SBUF   :
                            custom3_rowsum  ? ROWSUM :
			    IDLE;

   wire lbuf_icb_rsp_hsked_last; //LBUFָ����������ź�
  //�����ǰ״̬��LBUF״̬��LBUFָ����������ź�Ϊ1,��ʹ���˳�LBUF״̬ʹ���ź�
   assign state_lbuf_exit_ena = state_is_lbuf & lbuf_icb_rsp_hsked_last; 
  //LBUF״̬����һ״̬��IDLE״̬
   assign state_lbuf_nxt = IDLE;

   wire sbuf_icb_rsp_hsked_last; //SBUFָ����������ź�
  //�����ǰ״̬��SBUF״̬��SBUFָ����������ź�Ϊ1,��ʹ���˳�SBUF״̬ʹ���ź�
   assign state_sbuf_exit_ena = state_is_sbuf & sbuf_icb_rsp_hsked_last; 
  //SBUF״̬����һ״̬��IDLE״̬
   assign state_sbuf_nxt = IDLE;

   wire rowsum_done; //ROWSUMָ����������ź�
  //�����ǰ״̬��ROWSUM״̬��ROWSUMָ����������ź�Ϊ1,��ʹ���˳�ROWSUM״̬ʹ���ź�
   assign state_rowsum_exit_ena = state_is_rowsum & rowsum_done; 
  //ROWSUM״̬����һ״̬��IDLE״̬
   assign state_rowsum_nxt = IDLE;

  //D������������״̬����һ״̬�����˳���ָ���Լ��˳�ָ��ָ������һ״̬ȷ��
   assign nxt_state =   ({NICE_FSM_WIDTH{state_idle_exit_ena   }} & state_idle_nxt   )
                      | ({NICE_FSM_WIDTH{state_lbuf_exit_ena   }} & state_lbuf_nxt   ) 
                      | ({NICE_FSM_WIDTH{state_sbuf_exit_ena   }} & state_sbuf_nxt   ) 
                      | ({NICE_FSM_WIDTH{state_rowsum_exit_ena }} & state_rowsum_nxt ) 
                      ;
  //D��������״̬ʹ���������Ƿ���ָ���˳�ʹ��
   assign state_ena =   state_idle_exit_ena | state_lbuf_exit_ena 
                      | state_sbuf_exit_ena | state_rowsum_exit_ena;
  //����D�����������ز���DW����ʼ��״̬ΪIDLE����state_enaΪ1ʱ����һ�ģ�nxt_state��ֵ��state_r���͵�ƽ��λ��sirv_gnrl_dffs.v��
   sirv_gnrl_dfflr #(NICE_FSM_WIDTH)   state_dfflr (state_ena, nxt_state, state_r, nice_clk, nice_rst_n);

   ////////////////////////////////////////////////////////////
   // instr EXU
   ////////////////////////////////////////////////////////////
   wire [ROW_IDX_W-1:0]  clonum = 2'b10;  // fixed clonum ������2
   //wire [COL_IDX_W-1:0]  rownum;

   //////////// 1. custom3_lbuf
   wire [ROWBUF_IDX_W-1:0] lbuf_cnt_r; //D�������������ǰ����ֵ
   wire [ROWBUF_IDX_W-1:0] lbuf_cnt_nxt; //D��������������һ����ֵ
   wire lbuf_cnt_clr;//����
   wire lbuf_cnt_incr;//����
   wire lbuf_cnt_ena;//D���������������ʹ��
   wire lbuf_cnt_last;//�Ƶ����һ����
   wire lbuf_icb_rsp_hsked;//IBUF״̬����memory���ֳɹ����ѽ��շ����ź�
   wire nice_rsp_valid_lbuf;//IBUF״̬�ķ���cpu�����ź�
   wire nice_icb_cmd_valid_lbuf;//IBUF״̬�Ķ�дmemory�����ź�

  //LBUF״̬�£���memory���ֳɹ����ѽ��շ�����ʹ��IBUF״̬����memory���ֳɹ����ѽ��շ����ź�
   assign lbuf_icb_rsp_hsked = state_is_lbuf & nice_icb_rsp_hsked;
  //�Ƶ����һ������IBUF״̬����memory���ֳɹ����ѽ��շ�����ʹ��LBUFָ����������źţ�last, wait lbuf_cnt_last
   assign lbuf_icb_rsp_hsked_last = lbuf_icb_rsp_hsked & lbuf_cnt_last;
  //D�������������ǰ����ֵ=2,��Ƶ����һ����
   assign lbuf_cnt_last = (lbuf_cnt_r == clonum);
  //��cpu���ֳɹ�������ָ�ָ����custom3_lbuf��������,first
   assign lbuf_cnt_clr = custom3_lbuf & nice_req_hsked;
  //IBUF״̬����memory���ֳɹ����ѽ��շ�������δ�Ƶ����һ��������һֱ����
   assign lbuf_cnt_incr = lbuf_icb_rsp_hsked & ~lbuf_cnt_last;
  //D���������������ʹ���������źźͼ����ź�ȷ��
   assign lbuf_cnt_ena = lbuf_cnt_clr | lbuf_cnt_incr;
  //D��������������һ����ֵ�������źźͼ����ź�ȷ��
   assign lbuf_cnt_nxt =   ({ROWBUF_IDX_W{lbuf_cnt_clr }} & {ROWBUF_IDX_W{1'b0}})
                         | ({ROWBUF_IDX_W{lbuf_cnt_incr}} & (lbuf_cnt_r + 1'b1) )
                         ;
  //����D�����������ز���DW����ʼ����Ϊ0����lbuf_cnt_enaΪ1ʱ����һ�ģ�lbuf_cnt_nxt��ֵ��lbuf_cnt_r���͵�ƽ��λ��sirv_gnrl_dffs.v��
   sirv_gnrl_dfflr #(ROWBUF_IDX_W)   lbuf_cnt_dfflr (lbuf_cnt_ena, lbuf_cnt_nxt, lbuf_cnt_r, nice_clk, nice_rst_n);

   // nice_rsp_valid wait for nice_icb_rsp_valid in LBUF
  //LBUF״̬�£���memory���ֳɹ����ѽ��շ������ҼƵ����һ��������ʹ��IBUF״̬�ķ���cpu�����ź�,last, wait lbuf_cnt_last
   assign nice_rsp_valid_lbuf = state_is_lbuf & lbuf_cnt_last & nice_icb_rsp_valid;

   // nice_icb_cmd_valid sets when lbuf_cnt_r is not full in LBUF
  //LBUF״̬�£�D�������������ǰ����ֵС�����ֵ����ʹ��IBUF״̬�Ķ�дmemory�����ź�,first
   assign nice_icb_cmd_valid_lbuf = (state_is_lbuf & (lbuf_cnt_r < clonum));

   //////////// 2. custom3_sbuf
   wire [ROWBUF_IDX_W-1:0] sbuf_cnt_r; //D�������������ǰ����ֵ
   wire [ROWBUF_IDX_W-1:0] sbuf_cnt_nxt; //D��������������һ����ֵ
   wire sbuf_cnt_clr;//����
   wire sbuf_cnt_incr;//����
   wire sbuf_cnt_ena;//D���������������ʹ��
   wire sbuf_cnt_last;//�Ƶ����һ����
   wire sbuf_icb_cmd_hsked;//SBUF״̬����memory���ֳɹ����ѷ��Ͷ�д��ַ�������ź�
   wire sbuf_icb_rsp_hsked;//SBUF״̬����memory���ֳɹ����ѽ��շ����ź�
   wire nice_rsp_valid_sbuf;//SBUF״̬�ķ���cpu�����ź�
   wire nice_icb_cmd_valid_sbuf;//SBUF״̬�Ķ�дmemory�����ź�
   wire nice_icb_cmd_hsked;//��memory���ֳɹ����ѷ��Ͷ�д��ַ������
  
  //SBUF״̬�£���memory���ֳɹ����ѷ��Ͷ�д��ַ�����ݣ���ʹ��SBUF״̬����memory���ֳɹ����ѷ��Ͷ�д��ַ�������źţ�second����һ������������
   assign sbuf_icb_cmd_hsked = (state_is_sbuf | (state_is_idle & custom3_sbuf)) & nice_icb_cmd_hsked;
  //SBUF״̬�£���memory���ֳɹ����ѽ��շ�����ʹ��SBUF״̬����memory���ֳɹ����ѽ��շ����źţ�third���ڶ������������� 
   assign sbuf_icb_rsp_hsked = state_is_sbuf & nice_icb_rsp_hsked;
  //�Ƶ����һ������SBUF״̬����memory���ֳɹ����ѽ��շ�����ʹ��SBUFָ����������ź�, last, wait sbuf_cnt_last
   assign sbuf_icb_rsp_hsked_last = sbuf_icb_rsp_hsked & sbuf_cnt_last;
  //D�������������ǰ����ֵ=2,��Ƶ����һ����
   assign sbuf_cnt_last = (sbuf_cnt_r == clonum);
   //assign sbuf_cnt_clr = custom3_sbuf & nice_req_hsked;
  //SBUFָ����������������㣬last, wait sbuf_cnt_last
   assign sbuf_cnt_clr = sbuf_icb_rsp_hsked_last;
  //SBUF״̬����memory���ֳɹ����ѽ��շ�������δ�Ƶ����һ��������һֱ����
   assign sbuf_cnt_incr = sbuf_icb_rsp_hsked & ~sbuf_cnt_last;
  //D���������������ʹ���������źźͼ����ź�ȷ��
   assign sbuf_cnt_ena = sbuf_cnt_clr | sbuf_cnt_incr;
  //D��������������һ����ֵ�������źźͼ����ź�ȷ��
   assign sbuf_cnt_nxt =   ({ROWBUF_IDX_W{sbuf_cnt_clr }} & {ROWBUF_IDX_W{1'b0}})
                         | ({ROWBUF_IDX_W{sbuf_cnt_incr}} & (sbuf_cnt_r + 1'b1) )
                         ;
  //����D�����������ز���DW����ʼ����Ϊ0����sbuf_cnt_enaΪ1ʱ����һ�ģ�sbuf_cnt_nxt��ֵ��sbuf_cnt_r���͵�ƽ��λ��sirv_gnrl_dffs.v��
   sirv_gnrl_dfflr #(ROWBUF_IDX_W)   sbuf_cnt_dfflr (sbuf_cnt_ena, sbuf_cnt_nxt, sbuf_cnt_r, nice_clk, nice_rst_n);

   // nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
  //SBUF״̬�£���memory���ֳɹ����ѽ��շ������ҼƵ����һ��������ʹ��SBUF״̬�ķ���cpu�����ź�,last, wait sbuf_cnt_last
   assign nice_rsp_valid_sbuf = state_is_sbuf & sbuf_cnt_last & nice_icb_rsp_valid;

   wire [ROWBUF_IDX_W-1:0] sbuf_cmd_cnt_r; //D�������������ǰ����ֵ
   wire [ROWBUF_IDX_W-1:0] sbuf_cmd_cnt_nxt; //D��������������һ����ֵ
   wire sbuf_cmd_cnt_clr;//����
   wire sbuf_cmd_cnt_incr;//����
   wire sbuf_cmd_cnt_ena;//D���������������ʹ��
   wire sbuf_cmd_cnt_last;//�Ƶ����һ����

  //D�������������ǰ����ֵ=2,��Ƶ����һ����
   assign sbuf_cmd_cnt_last = (sbuf_cmd_cnt_r == clonum);
  //SBUFָ����������������㣬last, wait sbuf_cnt_last
   assign sbuf_cmd_cnt_clr = sbuf_icb_rsp_hsked_last;
  //SBUF״̬����memory���ֳɹ����ѷ��Ͷ�д��ַ�������źţ���δ�Ƶ����һ��������һֱ����
   assign sbuf_cmd_cnt_incr = sbuf_icb_cmd_hsked & ~sbuf_cmd_cnt_last;
  //D���������������ʹ���������źźͼ����ź�ȷ��
   assign sbuf_cmd_cnt_ena = sbuf_cmd_cnt_clr | sbuf_cmd_cnt_incr;
  //D��������������һ����ֵ�������źźͼ����ź�ȷ��
   assign sbuf_cmd_cnt_nxt =   ({ROWBUF_IDX_W{sbuf_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}})
                             | ({ROWBUF_IDX_W{sbuf_cmd_cnt_incr}} & (sbuf_cmd_cnt_r + 1'b1) )
                             ;
  //����D�����������ز���DW����ʼ����Ϊ0����sbuf_cmd_cnt_enaΪ1ʱ����һ�ģ�sbuf_cmd_cnt_nxt��ֵ��sbuf_cmd_cnt_r���͵�ƽ��λ��sirv_gnrl_dffs.v��
   sirv_gnrl_dfflr #(ROWBUF_IDX_W)   sbuf_cmd_cnt_dfflr (sbuf_cmd_cnt_ena, sbuf_cmd_cnt_nxt, sbuf_cmd_cnt_r, nice_clk, nice_rst_n);

   // nice_icb_cmd_valid sets when sbuf_cmd_cnt_r is not full in SBUF
  //SBUF״̬�£�D�������������ǰ����ֵsbuf_cmd_cnt_rС�ڵ������ֵ��sbuf_cnt_r���������ֵ����ʹ��SBUF״̬�Ķ�дmemory�����ź�,first��also last, wait sbuf_cnt_last
   assign nice_icb_cmd_valid_sbuf = (state_is_sbuf & (sbuf_cmd_cnt_r <= clonum) & (sbuf_cnt_r != clonum));


   //////////// 3. custom3_rowsum
   // rowbuf counter ��ǰ��һ�������Կ�����ROWSUM״̬�µĵ�һ��������
   wire [ROWBUF_IDX_W-1:0] rowbuf_cnt_r; //D�������������ǰ����ֵ
   wire [ROWBUF_IDX_W-1:0] rowbuf_cnt_nxt; //D��������������һ����ֵ
   wire rowbuf_cnt_clr;//����
   wire rowbuf_cnt_incr;//����
   wire rowbuf_cnt_ena;//D���������������ʹ��
   wire rowbuf_cnt_last;//�Ƶ����һ����
   wire rowbuf_icb_rsp_hsked;//ROWSUM״̬����memory���ֳɹ����ѽ��շ����ź�
   wire rowbuf_rsp_hsked;//ROWSUM״̬����cpu���ֳɹ����ѷ��ͽ���ź�
   wire nice_rsp_valid_rowsum;//ROWSUM״̬�µķ���cpu�����ź�

  //ROWSUM״̬�µķ���cpu����cpu���շ�������ʹ��ROWSUM״̬����cpu���ֳɹ����ѷ��ͽ���źţ�last
   assign rowbuf_rsp_hsked = nice_rsp_valid_rowsum & nice_rsp_ready;
  //ROWSUM״̬�£���memory���ֳɹ����ѽ��շ�����ʹ��ROWSUM״̬����memory���ֳɹ����ѽ��շ����ź�
   assign rowbuf_icb_rsp_hsked = state_is_rowsum & nice_icb_rsp_hsked;
  //D�������������ǰ����ֵ=2,��Ƶ����һ����
   assign rowbuf_cnt_last = (rowbuf_cnt_r == clonum);
  //�Ƶ����һ��������ROWSUM״̬����memory���ֳɹ����ѽ��շ����źţ�������
   assign rowbuf_cnt_clr = rowbuf_icb_rsp_hsked & rowbuf_cnt_last;
  //ROWSUM״̬����memory���ֳɹ����ѽ��շ����źţ���δ�Ƶ����һ��������һֱ����
   assign rowbuf_cnt_incr = rowbuf_icb_rsp_hsked & ~rowbuf_cnt_last;
  //D���������������ʹ���������źźͼ����ź�ȷ��
   assign rowbuf_cnt_ena = rowbuf_cnt_clr | rowbuf_cnt_incr;
  //D��������������һ����ֵ�������źźͼ����ź�ȷ��
   assign rowbuf_cnt_nxt =   ({ROWBUF_IDX_W{rowbuf_cnt_clr }} & {ROWBUF_IDX_W{1'b0}})
                           | ({ROWBUF_IDX_W{rowbuf_cnt_incr}} & (rowbuf_cnt_r + 1'b1))
                           ;
   //assign nice_icb_cmd_valid_rowbuf =   (state_is_idle & custom3_rowsum)
   //                                  | (state_is_rowsum & (rowbuf_cnt_r <= clonum) & (clonum != 0))
   //                                  ;
  //����2,ʹ��rowbuf_cnt_ena����һ�ģ�rowbuf_cnt_nxt��ֵ��rowbuf_cnt_r
   sirv_gnrl_dfflr #(ROWBUF_IDX_W)   rowbuf_cnt_dfflr (rowbuf_cnt_ena, rowbuf_cnt_nxt, rowbuf_cnt_r, nice_clk, nice_rst_n);

   // recieve data buffer, to make sure rowsum ops come from registers 
   wire rcv_data_buf_ena;
   wire rcv_data_buf_set;//ROWSUM״̬��memory�����뷴�������ź�
   wire rcv_data_buf_clr;//ROWSUM״̬��cpu�����뷴�������ź�
   wire rcv_data_buf_valid;
   wire [`E203_XLEN-1:0] rcv_data_buf; //��memory���صĲ�����
   wire [ROWBUF_IDX_W-1:0] rcv_data_buf_idx; 
   wire [ROWBUF_IDX_W-1:0] rcv_data_buf_idx_nxt; 

   assign rcv_data_buf_set = rowbuf_icb_rsp_hsked;
   assign rcv_data_buf_clr = rowbuf_rsp_hsked;
   assign rcv_data_buf_ena = rcv_data_buf_clr | rcv_data_buf_set;
  //ROWSUM״̬��memory�����뷴��������cpu�����뷴��δ��������rcv_data_buf_idx_nxt����rowbuf_cnt_r
   assign rcv_data_buf_idx_nxt =   ({ROWBUF_IDX_W{rcv_data_buf_clr}} & {ROWBUF_IDX_W{1'b0}})
                                 | ({ROWBUF_IDX_W{rcv_data_buf_set}} & rowbuf_cnt_r        );
  //����1,ʹ��1,��һ�ģ�rcv_data_buf_ena��ֵ��rcv_data_buf_valid
   sirv_gnrl_dfflr #(1)   rcv_data_buf_valid_dfflr (1'b1, rcv_data_buf_ena, rcv_data_buf_valid, nice_clk, nice_rst_n);
  //����32,ʹ��rcv_data_buf_ena����һ�ģ�nice_icb_rsp_rdata��ֵ��rcv_data_buf
   sirv_gnrl_dfflr #(`E203_XLEN)   rcv_data_buf_dfflr (rcv_data_buf_ena, nice_icb_rsp_rdata, rcv_data_buf, nice_clk, nice_rst_n);
  //����2,ʹ��rcv_data_buf_ena����һ�ģ�rcv_data_buf_idx_nxt��ֵ��rcv_data_buf_idx
   sirv_gnrl_dfflr #(ROWBUF_IDX_W)   rowbuf_cnt_d_dfflr (rcv_data_buf_ena, rcv_data_buf_idx_nxt, rcv_data_buf_idx, nice_clk, nice_rst_n);

   // rowsum accumulator 
   wire [`E203_XLEN-1:0] rowsum_acc_r;//��ǰ������
   wire [`E203_XLEN-1:0] rowsum_acc_nxt;//��һ������
   wire [`E203_XLEN-1:0] rowsum_acc_adder;//��������
   wire rowsum_acc_ena;
   wire rowsum_acc_set;//��һ��������״̬ʹ��
   wire rowsum_acc_flg;//�ǵ�һ��������״̬ʹ��
   wire nice_icb_cmd_valid_rowsum;
   wire [`E203_XLEN-1:0] rowsum_res;//�������ܺ�

   assign rowsum_acc_set = rcv_data_buf_valid & (rcv_data_buf_idx == {ROWBUF_IDX_W{1'b0}});
   assign rowsum_acc_flg = rcv_data_buf_valid & (rcv_data_buf_idx != {ROWBUF_IDX_W{1'b0}});
  //����memory���صĲ������뵱ǰ���������
   assign rowsum_acc_adder = rcv_data_buf + rowsum_acc_r;
   assign rowsum_acc_ena = rowsum_acc_set | rowsum_acc_flg;
  //����ǵ�һ������������rowsum_acc_nxt���ڴ�memory���صĲ����������������Ŀǰ�Ĳ�������
   assign rowsum_acc_nxt =   ({`E203_XLEN{rowsum_acc_set}} & rcv_data_buf)
                           | ({`E203_XLEN{rowsum_acc_flg}} & rowsum_acc_adder)
                           ;
  //����32,ʹ��rowsum_acc_ena����һ�ģ�rowsum_acc_nxt��ֵ��rowsum_acc_r
   sirv_gnrl_dfflr #(`E203_XLEN)   rowsum_acc_dfflr (rowsum_acc_ena, rowsum_acc_nxt, rowsum_acc_r, nice_clk, nice_rst_n);

   assign rowsum_done = state_is_rowsum & nice_rsp_hsked;//ROWSUMָ���������
   assign rowsum_res  = rowsum_acc_r;//�������ܺ�

   // rowsum finishes when the last acc data is added to rowsum_acc_r  
  //�����꣬nice_rsp_valid_rowsum��׼��������cpu
   assign nice_rsp_valid_rowsum = state_is_rowsum & (rcv_data_buf_idx == clonum) & ~rowsum_acc_flg;

   // nice_icb_cmd_valid sets when rcv_data_buf_idx is not full in LBUF
  //��û���ڴ�ȡ������nice_icb_cmd_valid_rowsumһֱ��
   assign nice_icb_cmd_valid_rowsum = state_is_rowsum & (rcv_data_buf_idx < clonum) & ~rowsum_acc_flg;

   //////////// rowbuf //lbuf��rowsumдrowbuf��sbuf��rowbuf��rowsumд��rowbuf�����м�����Ľ��
   // rowbuf access list:
   //  1. lbuf will write to rowbuf, write data comes from memory, data length is defined by clonum 
   //  2. sbuf will read from rowbuf, and store it to memory, data length is defined by clonum 
   //  3. rowsum will accumulate data, and store to rowbuf, data length is defined by clonum 
   wire [`E203_XLEN-1:0] rowbuf_r [ROWBUF_DP-1:0];//16��32λ��Ķ�����[31:0][3:0]
   wire [`E203_XLEN-1:0] rowbuf_wdat [ROWBUF_DP-1:0];//16��32λ���д����
   wire [ROWBUF_DP-1:0]  rowbuf_we;//4λ�������,D��������ʹ���ź�
   wire [ROWBUF_IDX_W-1:0] rowbuf_idx_mux; //2λ�������
   wire [`E203_XLEN-1:0] rowbuf_wdat_mux; //32λ�������
   wire rowbuf_wr_mux; 
   //wire [ROWBUF_IDX_W-1:0] sbuf_idx; 
   
   // lbuf write to rowbuf
   wire [ROWBUF_IDX_W-1:0] lbuf_idx = lbuf_cnt_r; //д��rowbuf�����
   wire lbuf_wr = lbuf_icb_rsp_hsked; //ʹ��lbufдrowbuf�ź�
   wire [`E203_XLEN-1:0] lbuf_wdata = nice_icb_rsp_rdata;

   // rowsum write to rowbuf(column accumulated data)
   wire [ROWBUF_IDX_W-1:0] rowsum_idx = rcv_data_buf_idx; //д��rowbuf�����
   wire rowsum_wr = rcv_data_buf_valid; //ʹ��rowsumдrowbuf�ź�
   wire [`E203_XLEN-1:0] rowsum_wdata = rowbuf_r[rowsum_idx] + rcv_data_buf;//�м����㣬ÿ��Ԫ�ط�����D����������

   // rowbuf write mux
  //ѡ��д�������
   assign rowbuf_wdat_mux =   ({`E203_XLEN{lbuf_wr  }} & lbuf_wdata  )
                            | ({`E203_XLEN{rowsum_wr}} & rowsum_wdata)
                            ;
  //ѡ��д���ָ���ź�
   assign rowbuf_wr_mux   =  lbuf_wr | rowsum_wr;
  //ѡ��д��rowbuf�����
   assign rowbuf_idx_mux  =   ({ROWBUF_IDX_W{lbuf_wr  }} & lbuf_idx  )
                            | ({ROWBUF_IDX_W{rowsum_wr}} & rowsum_idx)
                            ;  

   // rowbuf inst //ʵ����4��D��������Ϊrowbuf
   genvar i;
   generate 
     for (i=0; i<ROWBUF_DP; i=i+1) begin:gen_rowbuf
       //ȷ��д�����ź�ʹ���ź�
       assign rowbuf_we[i] =   (rowbuf_wr_mux & (rowbuf_idx_mux == i[ROWBUF_IDX_W-1:0]))
                             ;
       //ȷ��д�������
       assign rowbuf_wdat[i] =   ({`E203_XLEN{rowbuf_we[i]}} & rowbuf_wdat_mux   )
                               ;
       //���ɴ���������������д�룬����32,ʹ��rowbuf_we[i]����һ�ģ�rowbuf_wdat[i]��ֵ��rowbuf_r[i]
       sirv_gnrl_dfflr #(`E203_XLEN) rowbuf_dfflr (rowbuf_we[i], rowbuf_wdat[i], rowbuf_r[i], nice_clk, nice_rst_n);
     end
   endgenerate

   //////////// mem aacess addr management
   wire [`E203_XLEN-1:0] maddr_acc_r; 
   assign nice_icb_cmd_hsked = nice_icb_cmd_valid & nice_icb_cmd_ready; //��memory���ֳɹ����ѷ��Ͷ�д��ַ������
   // custom3_lbuf 
   //wire [`E203_XLEN-1:0] lbuf_maddr    = state_is_idle ? nice_req_rs1 : maddr_acc_r ; 
  //LBUF״̬�£�����memoryʹ���ź�
   wire lbuf_maddr_ena    =   (state_is_idle & custom3_lbuf & nice_icb_cmd_hsked)
                            | (state_is_lbuf & nice_icb_cmd_hsked)
                            ;

   // custom3_sbuf 
   //wire [`E203_XLEN-1:0] sbuf_maddr    = state_is_idle ? nice_req_rs1 : maddr_acc_r ; 
  //SBUF״̬�£�����memoryʹ���ź�
   wire sbuf_maddr_ena    =   (state_is_idle & custom3_sbuf & nice_icb_cmd_hsked)
                            | (state_is_sbuf & nice_icb_cmd_hsked)
                            ;

   // custom3_rowsum
   //wire [`E203_XLEN-1:0] rowsum_maddr  = state_is_idle ? nice_req_rs1 : maddr_acc_r ; 
  //ROWSUM״̬�£�����memoryʹ���ź�
   wire rowsum_maddr_ena  =   (state_is_idle & custom3_rowsum & nice_icb_cmd_hsked)
                            | (state_is_rowsum & nice_icb_cmd_hsked)
                            ;

   // maddr acc 
   //wire  maddr_incr = lbuf_maddr_ena | sbuf_maddr_ena | rowsum_maddr_ena | rbuf_maddr_ena;
   wire  maddr_ena = lbuf_maddr_ena | sbuf_maddr_ena | rowsum_maddr_ena;
   wire  maddr_ena_idle = maddr_ena & state_is_idle;//��״̬ΪIDLEʱ��ȡ����һ���ڴ��ַ������ָ���ȡ���ڴ��ַ
  //nice_req_rs1�Ǵ�ָ���ȡ���ڴ��ַ��֮���memoryÿȡһ�������ڴ��ַҪ��4,��Ϊÿһ������32λ��32/8=4
   wire [`E203_XLEN-1:0] maddr_acc_op1 = maddr_ena_idle ? nice_req_rs1 : maddr_acc_r; // not reused
   wire [`E203_XLEN-1:0] maddr_acc_op2 = maddr_ena_idle ? `E203_XLEN'h4 : `E203_XLEN'h4; 

   wire [`E203_XLEN-1:0] maddr_acc_next = maddr_acc_op1 + maddr_acc_op2;
   wire  maddr_acc_ena = maddr_ena;
  //����32,ʹ��maddr_acc_ena����һ�ģ�maddr_acc_next��ֵ��maddr_acc_r
   sirv_gnrl_dfflr #(`E203_XLEN)   maddr_acc_dfflr (maddr_acc_ena, maddr_acc_next, maddr_acc_r, nice_clk, nice_rst_n);

   ////////////////////////////////////////////////////////////
   // Control cmd_req
   ////////////////////////////////////////////////////////////
   assign nice_req_hsked = nice_req_valid & nice_req_ready;
   assign nice_req_ready = state_is_idle & (custom_mem_op ? nice_icb_cmd_ready : 1'b1);

   ////////////////////////////////////////////////////////////
   // Control cmd_rsp
   ////////////////////////////////////////////////////////////
   assign nice_rsp_hsked = nice_rsp_valid & nice_rsp_ready; 
   assign nice_icb_rsp_hsked = nice_icb_rsp_valid & nice_icb_rsp_ready;
   assign nice_rsp_valid = nice_rsp_valid_rowsum | nice_rsp_valid_sbuf | nice_rsp_valid_lbuf;
   assign nice_rsp_rdat  = {`E203_XLEN{state_is_rowsum}} & rowsum_res;

   // memory access bus error
   //assign nice_rsp_err_irq  =   (nice_icb_rsp_hsked & nice_icb_rsp_err)
   //                          | (nice_req_hsked & illgel_instr)
   //                          ; 
   assign nice_rsp_err   =   (nice_icb_rsp_hsked & nice_icb_rsp_err);//��memory���ֳɹ�������memory���յķ�����Ϊ��cpu�ķ���

   ////////////////////////////////////////////////////////////
   // Memory lsu
   ////////////////////////////////////////////////////////////
   // memory access list:
   //  1. In IDLE, custom_mem_op will access memory(lbuf/sbuf/rowsum)
   //  2. In LBUF, it will read from memory as long as lbuf_cnt_r is not full
   //  3. In SBUF, it will write to memory as long as sbuf_cnt_r is not full
   //  3. In ROWSUM, it will read from memory as long as rowsum_cnt_r is not full
   //assign nice_icb_rsp_ready = state_is_ldst_rsp & nice_rsp_ready; 
   // rsp always ready
   assign nice_icb_rsp_ready = 1'b1; //ʱ��׼������memory����
   wire [ROWBUF_IDX_W-1:0] sbuf_idx = sbuf_cmd_cnt_r; 
  //ʹ��memory�����ź�
   assign nice_icb_cmd_valid =   (state_is_idle & nice_req_valid & custom_mem_op)
                              | nice_icb_cmd_valid_lbuf
                              | nice_icb_cmd_valid_sbuf
                              | nice_icb_cmd_valid_rowsum
                              ;
  //��״̬idle��������Ч��Ϊ�Ĵ���1������Ϊmaddr_acc_r
   assign nice_icb_cmd_addr  = (state_is_idle & custom_mem_op) ? nice_req_rs1 :
                              maddr_acc_r;
  //��״̬idle��Ϊlbuf��rowsumzָ�Ϊ1��Ϊsbufָ�Ϊ0��������Ϊsbuf״̬Ϊ0������Ϊ1��0Ϊд��1Ϊ��
   assign nice_icb_cmd_read  = (state_is_idle & custom_mem_op) ? (custom3_lbuf | custom3_rowsum) : 
                              state_is_sbuf ? 1'b0 : 
                              1'b1;
  //��״̬idle��sbufָ���subf״̬��Ϊrowbuf_r[sbuf_idx]������Ϊ0
   assign nice_icb_cmd_wdata = (state_is_idle & custom3_sbuf) ? rowbuf_r[sbuf_idx] :
                              state_is_sbuf ? rowbuf_r[sbuf_idx] : 
                              `E203_XLEN'b0; 

   //assign nice_icb_cmd_wmask = {`sirv_XLEN_MW{custom3_sbuf}} & 4'b1111;
   assign nice_icb_cmd_size  = 2'b10;//2: ����4�ֽ�32λ����
   assign nice_mem_holdup    =  state_is_lbuf | state_is_sbuf | state_is_rowsum; //��ռ�ڴ��ź�

   ////////////////////////////////////////////////////////////
   // nice_active
   ////////////////////////////////////////////////////////////
   assign nice_active = state_is_idle ? nice_req_valid : 1'b1;//nice�Ƿ��ڹ���

endmodule
`endif//}


