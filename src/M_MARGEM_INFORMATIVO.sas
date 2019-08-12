
%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME MRG "/dados/infor/producao/margem_informativo";


DATA _NULL_;

D1 = diaUtilAnterior(TODAY());
CALL SYMPUT('D1',COMPRESS(D1,' '));

ANO_ATUAL = 2019;
CALL SYMPUT('ANO_ATUAL',COMPRESS(ANO_ATUAL,' '));

MES_POSICAO = Put(MONTH (diaUtilAnterior(TODAY())), Z2.);
CALL SYMPUT('MES_POSICAO', COMPRESS(MES_POSICAO,' '));

ANOMES = Put(D1, yymmn6.);
CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));

ANOMESDIA = Put(D1, yymmddn8.);
CALL SYMPUT('ANOMESDIA',COMPRESS(ANOMESDIA,' '));

MESANO = Put(D1, mmyyn6.);
CALL SYMPUT('MESANO',COMPRESS(MESANO,' '));

RUN;


%Put &MES_POSICAO &ANO_ATUAL &D1 &ANOMES &ANOMESDIA &MESANO;


/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/

PROC SQL;

   CREATE TABLE PARA_BASE_CONEXAO AS SELECT 

   t1.IND,
   t1.COMP,
   0 as COMP_PAI,
   0 as ORD_EXI,
   t1.UOR,
   t1.PREFDEP,   
   t1.CTRA,
   t1.VLR FORMAT 32.2 AS VLR_RLZ,
   0 as VLR_ORC,
   0 as VLR_ATG,
   &D1.  FORMAT YYMMDD10. AS POSICAO

   /*t1.MMAAAA*/       

   FROM MRG.VLR_&ANOMESDIA. t1
		  
   ORDER BY PREFDEP;

QUIT;


%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO);
%ExportarCNX_IND(IND=245, MMAAAA=&MESANO, ORC=0, RLZ=1); /*arquivo indicador*/
%ExportarCNX_COMP(IND=245, MMAAAA=&MESANO, ORC=0, RLZ=1); /*arquivo componentes*/

 
 x cd /dados/infor/producao/margem_informativo;
 x chmod 2777 *;
