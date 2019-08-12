

%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME FONTE "/dados/infor/producao/validador_conexao/bases";


DATA _NULL_;
    D1 = '30apr2019'd;
    CALL SYMPUT('D1',COMPRESS(D1,' '));
    CALL SYMPUTX('ANO_ATUAL',YEAR(D1));
    CALL SYMPUTX('MES_POSICAO', MONTH(D1));
    CALL SYMPUTX('ANOMES',PUT(D1,YYMMN6.));    
    CALL SYMPUTX('MESANO',PUT(D1,MMYYN6.));
RUN;


%Put &MES_POSICAO &ANO_ATUAL &D1 &ANOMES &MESANO;


/**********************************/
/**********************************/
/**********************************/
/**********************************/


PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO_110_COMP AS SELECT 
   
   t1.CD_IN_MBZ as ind,
   t1.CD_CPNT_IN_MBZ AS COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.CD_UOR_CTRA AS UOR,
   INPUT(t2.PREFDEP, d4.) AS PREFDEP,
   t1.NR_SEQL_CTRA AS CTRA,
   t1.VL_RLZD_CPNT_IN AS VLR_RLZ,
   0 as VLR_ORC, 
   0 as VLR_ATG,
   &D1. FORMAT YYMMDD10. AS POSICAO       
   
   FROM FONTE.vl_aprd_cpnt_mbz_d190507 t1
   INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_UOR_CTRA = INPUT(t2.UOR, d9.)
   WHERE CD_IN_MBZ = 110 AND AA_APRC = 2019 AND MM_APRC = 04 
   ORDER BY PREFDEP
   ; 

QUIT;


PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO_110_IND AS SELECT 
   
   t1.CD_IN_MBZ as ind,
   0 AS COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.CD_UOR_CTRA AS UOR,
   INPUT(t2.PREFDEP, d4.) AS PREFDEP,
   t1.NR_SEQL_CTRA AS CTRA,
   t1.VL_RLZD_IN_MBZ AS VLR_RLZ,
   0 as VLR_ORC, 
   0 as VLR_ATG,
   &D1. FORMAT YYMMDD10. AS POSICAO       
   
   FROM FONTE.vl_aprd_in_mbz_mm_d190507 t1
   INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_UOR_CTRA = INPUT(t2.UOR, d9.)
   WHERE CD_IN_MBZ = 110 AND AA_APRC = 2019 AND MM_APRC = 04
   ORDER BY PREFDEP
   ; 

QUIT;


DATA PARA_BASE_CONEXAO_110;
SET PARA_BASE_CONEXAO_110_COMP PARA_BASE_CONEXAO_110_IND;
BY PREFDEP;
RUN;


%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO_110);
%ExportarCNX_IND(IND=110, MMAAAA=&MESANO, ORC=0, RLZ=1); 
%ExportarCNX_COMP(IND=110, MMAAAA=&MESANO, ORC=0, RLZ=1);


/**********************************/
/**********************************/
/**********************************/
/**********************************/


PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO_178_COMP AS SELECT 
   
   t1.CD_IN_MBZ as ind,
   t1.CD_CPNT_IN_MBZ AS COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.CD_UOR_CTRA AS UOR,
   INPUT(t2.PREFDEP, d4.) AS PREFDEP,
   t1.NR_SEQL_CTRA AS CTRA,
   t1.VL_RLZD_CPNT_IN AS VLR_RLZ,
   0 as VLR_ORC, 
   0 as VLR_ATG,
   &D1. FORMAT YYMMDD10. AS POSICAO       
   
   FROM FONTE.vl_aprd_cpnt_mbz_d190503 t1
   INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_UOR_CTRA = INPUT(t2.UOR, d9.)
   WHERE CD_IN_MBZ = 178 AND AA_APRC = 2019 AND MM_APRC = 04
   ORDER BY PREFDEP
   ; 

QUIT;


PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO_178_IND AS SELECT 
   
   t1.CD_IN_MBZ as ind,
   0 AS COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.CD_UOR_CTRA AS UOR,
   INPUT(t2.PREFDEP, d4.) AS PREFDEP,
   t1.NR_SEQL_CTRA AS CTRA,
   t1.VL_RLZD_IN_MBZ AS VLR_RLZ,
   0 as VLR_ORC, 
   0 as VLR_ATG,
   &D1. FORMAT YYMMDD10. AS POSICAO       
   
   FROM FONTE.vl_aprd_in_mbz_mm_d190503 t1
   INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_UOR_CTRA = INPUT(t2.UOR, d9.)
   WHERE CD_IN_MBZ = 178 AND AA_APRC = 2019 AND MM_APRC = 04
   ORDER BY PREFDEP
   ; 

QUIT;


DATA PARA_BASE_CONEXAO_178;
SET PARA_BASE_CONEXAO_178_COMP PARA_BASE_CONEXAO_178_IND;
BY PREFDEP;
RUN;


%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO_178);
%ExportarCNX_IND(IND=178, MMAAAA=&MESANO, ORC=0, RLZ=1); 
%ExportarCNX_COMP(IND=178, MMAAAA=&MESANO, ORC=0, RLZ=1);
 
 
/**********************************/
/**********************************/
/**********************************/
/**********************************/


PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO_188_COMP AS SELECT 
   
   t1.CD_IN_MBZ as ind,
   t1.CD_CPNT_IN_MBZ AS COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.CD_UOR_CTRA AS UOR,
   INPUT(t2.PREFDEP, d4.) AS PREFDEP,
   t1.NR_SEQL_CTRA AS CTRA,
   t1.VL_RLZD_CPNT_IN AS VLR_RLZ,
   0 as VLR_ORC, 
   0 as VLR_ATG,
   &D1. FORMAT YYMMDD10. AS POSICAO       
   
   FROM FONTE.vl_aprd_cpnt_mbz_d190508 t1
   INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_UOR_CTRA = INPUT(t2.UOR, d9.)
   WHERE CD_IN_MBZ = 188 AND AA_APRC = 2019 AND MM_APRC = 04
   ORDER BY PREFDEP
   ; 

QUIT;


PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO_188_IND AS SELECT 
   
   t1.CD_IN_MBZ as ind,
   0 AS COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.CD_UOR_CTRA AS UOR,
   INPUT(t2.PREFDEP, d4.) AS PREFDEP,
   t1.NR_SEQL_CTRA AS CTRA,
   t1.VL_RLZD_IN_MBZ AS VLR_RLZ,
   0 as VLR_ORC, 
   0 as VLR_ATG,
   &D1. FORMAT YYMMDD10. AS POSICAO       
   
   FROM FONTE.vl_aprd_in_mbz_mm_d190508 t1
   INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_UOR_CTRA = INPUT(t2.UOR, d9.)
   WHERE CD_IN_MBZ = 188 AND AA_APRC = 2019 AND MM_APRC = 04
   ORDER BY PREFDEP
   ; 

QUIT;


DATA PARA_BASE_CONEXAO_188;
SET PARA_BASE_CONEXAO_188_COMP PARA_BASE_CONEXAO_188_IND;
BY PREFDEP;
RUN;



%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO_188);
%ExportarCNX_IND(IND=188, MMAAAA=&MESANO, ORC=0, RLZ=1); 
%ExportarCNX_COMP(IND=188, MMAAAA=&MESANO, ORC=0, RLZ=1);
 
 
/**********************************/
/**********************************/
/**********************************/
/**********************************/
x cd /dados/infor/producao/cobranca_qualificada_19;

 x chmod 2777 *;
