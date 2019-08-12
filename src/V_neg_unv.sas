/*%include '/dados/infor/suporte/FuncoesInfor.sas';*/
/**/
/**/
/*DATA _NULL_;*/
/*	DATA_INICIO = '01Jan2017'd;*/
/*	DATA_FIM = '30Dec2018'd;*/
/*	DATA_REFERENCIA = diaUtilAnterior(TODAY());*/
/*/*	DATA_REFERENCIA = diaUtilAnterior(MDY(10,01,2018));*/*/
/*	D1 = DATA_REFERENCIA;*/
/*	D2 = diaUtilAnterior(D1);*/
/*	D3 = diaUtilAnterior(D2);*/
/*	MES_ATU = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));*/
/*	MES_ANT = Put(INTNX('month',primeiroDiaUtilMes(D1),-1), yymmn6.) ;*/
/*	MES_G = Put(DATA_REFERENCIA, MONTH.) ;*/
/*	ANOMES = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));*/
/*	DT_INICIO_SQL="'"||put(DATA_INICIO, YYMMDDD10.)||"'";*/
/*	DT_D1_SQL="'"||put(D1, YYMMDDD10.)||"'";*/
/*	DT_1DIA_MES_SQL="'"||put(primeiroDiaUtilMes(D1), YYMMDDD10.)||"'";*/
/*	DT_ANOMES_SQL=primeiroDiaUtilMes(D1);*/
/*	PRIMEIRO_DIA_MES_SQL="'"||put(primeiroDiaMes(DATA_REFERENCIA), YYMMDDD10.)||"'";*/
/*	DT_FIXA_SQL="'"||put(MDY(01,01,2017), YYMMDDD10.)||"'";*/
/*	ANO_FIXO_SQL="'"||put(MDY(01,01,2018), YYMMDDD10.)||"'";*/
/*		ULTIMO_DIA_MES_SQL="'"||put(ultimoDiaMes(DATA_REFERENCIA), YYMMDDD10.)||"'";*/
/*			MES_ATUAL = Put(INTNX('month',primeiroDiaUtilMes(D1),0),DATE9. ) ;*/
/**/
/*	CALL SYMPUT('DATA_HOJE',COMPRESS(TODAY(),' '));*/
/*	CALL SYMPUT('DT_1DIA_MES',COMPRESS(primeiroDiaUtilMes(D1),' '));*/
/*	CALL SYMPUT('DATA_INICIO',COMPRESS(DATA_INICIO,' '));*/
/*	CALL SYMPUT('DATA_FIM',COMPRESS(DATA_FIM,' '));*/
/*	CALL SYMPUT('D1',COMPRESS(D1,' '));*/
/*	CALL SYMPUT('D2',COMPRESS(D2,' '));*/
/*	CALL SYMPUT('D3',COMPRESS(D3,' '));*/
/*	CALL SYMPUT('MES_ATU',COMPRESS(MES_ATU,' '));*/
/*	CALL SYMPUT('MES_ANT',COMPRESS(MES_ANT,' '));*/
/*	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));*/
/*	CALL SYMPUT('RF',COMPRESS(ANOMES,' '));*/
/*	CALL SYMPUT('DT_ARQUIVO',put(DATA_REFERENCIA, DDMMYY10.));*/
/*	CALL SYMPUT('DT_ARQUIVO_SQL',put(DATA_REFERENCIA, YYMMDDD10.));*/
/*	CALL SYMPUT('DT_INICIO_SQL', COMPRESS(DT_INICIO_SQL,' '));*/
/*	CALL SYMPUT('DT_1DIA_MES_SQL', COMPRESS(DT_1DIA_MES_SQL,' '));*/
/*	CALL SYMPUT('DT_D1_SQL', COMPRESS(DT_D1_SQL,' '));*/
/*	CALL SYMPUT('DT_ANOMES_SQL', COMPRESS(DT_ANOMES_SQL,' '));*/
/*	CALL SYMPUT('MES_G', COMPRESS(MES_G,' '));*/
/*	CALL SYMPUT('PRIMEIRO_DIA_MES_SQL', COMPRESS(PRIMEIRO_DIA_MES_SQL,' '));*/
/*	CALL SYMPUT('DT_FIXA_SQL', COMPRESS(DT_FIXA_SQL,' '));*/
/*	CALL SYMPUT('ANO_FIXO_SQL', COMPRESS(ANO_FIXO_SQL,' '));*/
/*		CALL SYMPUT('ULTIMO_DIA_MES_SQL', COMPRESS(ULTIMO_DIA_MES_SQL,' '));*/
/*	CALL SYMPUT('MES_ATUAL',COMPRESS(MES_ATUAL,' '));*/
/*;*/
/*RUN;*/
/**/
/*LIBNAME DB2SGCEN db2 AUTHDOMAIN=DB2SGCEN schema=DB2SGCEN database=BDB2P04;*/
/**/
/*LIBNAME DB2PRD DB2 DATABASE=BDB2P04 SCHEMA=DB2PRD AUTHDOMAIN='DB2SGCEN' ; */
/**/
/**/
/**/
/*/**/*/
/*/*DB2RST_CLC_RSTD_GRNL ou DB2DWH_VS_CLC_RSTD_GRNL*/*/
/**/
/**/
/**/
/*x cd /;*/
/*x cd /dados/infor/producao/saa;*/
/*x cd /dados/infor/producao/TCX_UNV;*/
/*x chmod -R 2777 *; /*ALTERAR PERMISÕES*/*/
/*x chown f9457977 -R ./; /*FIXA O FUNCI*/*/
/*x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/*/
/**/
/*LIBNAME RIV '/dados/infor/producao/receita_interna';*/
/*LIBNAME ADE '/dados/infor/producao/Aderencia';*/
/*LIBNAME SEG '/dados/dirco/publico/Gecen';*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.PUBLICO_RIV AS */
/*   SELECT t1.NR_UNCO_CTR_OPR, */
/*          t1.NR_CTR_OPR, */
/*          t1.NR_SCTR_OPR, */
/*          t1.CD_USU, */
/*          t1.SG_SIS_RSP, */
/*          t1.CD_CLI, */
/*          t1.CD_PRF_RSTD, */
/*          t1.CD_PRF_VCLD_TRAN, */
/*          t1.CD_PRF_CTRA_CLI, */
/*          t1.CD_IPMC_ITCE_CNL, */
/*          t1.CD_PRD, */
/*          t1.CD_MDLD, */
/*          t1.CD_CPNT_RSTD, */
/*          t1.VL_CPNT_RSTD, */
/*          t1.VL_CPNT_RSTD_TODOS, */
/*          t1.VL_ULT_SDO, */
/*          t1.DT_APRC FORMAT DATE9., */
/*          t1.DT_FRMZ_SCTR*/
/*      FROM RIV.VS_CLC_RSTD_GRNL t1*/
/*	  INNER JOIN IGR.IGRREDE T2 ON (T1.CD_PRF_RSTD=INPUT(T2.PREFDEP,4.))*/
/*WHERE (dt_aprc BETWEEN '01JAN2018'D AND '31DEC2018'D) and cd_cpnt_rstd=174 AND CD_IPMC_ITCE_CNL=10 AND T2.TIPODEP IN ('09' '01') AND T2.CODSITDEP='2'*/
/**/
/*;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE PUBLICO_MES AS */
/*   SELECT */
/*t1.NR_UNCO_CTR_OPR, */
/*          t1.NR_CTR_OPR, */
/*          t1.NR_SCTR_OPR, */
/*          t1.CD_USU, */
/*          t1.SG_SIS_RSP, */
/*          t1.CD_CLI, */
/*          t1.CD_PRF_RSTD, */
/*          t1.CD_PRF_VCLD_TRAN, */
/*          t1.CD_PRF_CTRA_CLI, */
/*          t1.CD_IPMC_ITCE_CNL, */
/*          t1.CD_PRD, */
/*          t1.CD_MDLD, */
/*          t1.CD_CPNT_RSTD, */
/*          t1.VL_CPNT_RSTD, */
/*          t1.VL_CPNT_RSTD_TODOS, */
/*          t1.VL_ULT_SDO, */
/*          t1.DT_APRC, */
/*          t1.DT_FRMZ_SCTR*/
/*      FROM WORK.PUBLICO_RIV t1*/
/* WHERE  t1.CD_IPMC_ITCE_CNL=10 and DT_APRC >=(INTNX('month',primeiroDiaUtilMes(&D1.),0)) and DT_FRMZ_SCTR not between '01jul2018'd and '31oct2018'd;*/
/*;QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SEGURIDADE_RIV AS */
/*		SELECT */
/*			t1.CD_PRF_CTRA_CLI, */
/*			t1.CD_ITCE_CNL AS CD_IPMC_ITCE_CNL, */
/*			t1.CD_PRF_RSTD, */
/*			t1.CD_CPNT_RSTD, */
/*			t1.VLR_CPNT_RSTD AS VL_CPNT_RSTD_TODOS,*/
/*			t1.DT_APRC, */
/*			t1.CD_PRD, */
/*			t1.CD_MDLD, */
/*			t1.CD_CLI, */
/*			t1.NR_UNCO_CTR_OPR, */
/*             VL_CTR AS VL_ULT_SDO*/
/*		FROM SEG.RV_&ANOMES t1*/
/*WHERE DT_APRC >=(INTNX('month',primeiroDiaUtilMes(&D1.),0)) AND CD_ITCE_CNL=10;*/
/*QUIT;*/
/**/
/**/
/*LIBNAME TRAN '/dados/infor/producao/saa';*/
/*LIBNAME TCX '/dados/infor/producao/TCX_UNV';*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SEGURIDADE AS*/
/*		SELECT DISTINCT*/
/*			t1.CD_PRF_RSTD, */
/*			SUM(VL_CPNT_RSTD_TODOS) AS VL_M_SAA*/
/*		FROM WORK.SEGURIDADE_RIV t1*/
/*GROUP BY 1*/
/*ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/*/**/*/
/*/**/*/
/*/*PROC SQL;*/*/
/*/*   CREATE TABLE WORK.RIV_TOTAL AS */*/
/*/*   SELECT DISTINCT t1.CD_PRF_RSTD, */*/
/*/*          /* SUM_of_VL_CPNT_RSTD */*/*/
/*/*            (SUM(t1.VL_CPNT_RSTD)) AS VL_TOTAL*/*/
/*/*      FROM WORK.PUBLICO_RIV t1*/*/
/*/*	  where DT_APRC<'31MAR2018'D */*/
/*/*      GROUP BY 1*/*/
/*/*ORDER BY 1;*/*/
/*/*QUIT;*/*/
/*/**/*/
/*/**/*/
/*/**/*/
/*/**/*/
/*/*PROC SQL;*/*/
/*/*   CREATE TABLE WORK.RIV_ATUAL AS */*/
/*/*   SELECT DISTINCT t1.CD_PRF_RSTD, */*/
/*/*          /* SUM_of_VL_CPNT_RSTD */*/*/
/*/*            (SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_ATUAL*/*/
/*/*      FROM WORK.PUBLICO_RIV t1*/*/
/*/*	  WHERE DT_APRC between '01mar2018'd and '31mar2018'd*/*/
/*/*      GROUP BY 1*/*/
/*/*ORDER BY 1;*/*/
/*/*QUIT;*/
/**/
/*LIBNAME ORC '/dados/externo/UNV/canais';*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.RIV_AC_SAA AS */
/*   SELECT DISTINCT t1.CD_PRF_RSTD, */
/*          /* SUM_of_VL_CPNT_RSTD */*/
/*            sum(t1.VL_CPNT_RSTD_TODOS) FORMAT=19.2 AS VL_AC_SAA*/
/*      FROM WORK.PUBLICO_RIV t1*/
/*where t1.CD_IPMC_ITCE_CNL=10 */
/*      GROUP BY 1*/
/*ORDER BY 1;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE WORK.RIV_M_SAA AS */
/*		SELECT DISTINCT t1.CD_PRF_RSTD, */
/*			/* SUM_of_VL_CPNT_RSTD */*/
/*	(SUM(t1.VL_CPNT_RSTD_TODOS)) FORMAT=19.2 AS VL_M_SAA */
/*FROM WORK.PUBLICO_MES t1 */
/*	GROUP BY 1*/
/*;QUIT;*/
/**/
/*DATA RIV_M_SAA;*/
/*SET SEGURIDADE RIV_M_SAA;*/
/*RUN;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.RIV_M_SAA AS */
/*   SELECT DISTINCT t1.CD_PRF_RSTD, */
/*          /* SUM_of_VL_M_SAA */*/
/*            (SUM(t1.VL_M_SAA)) FORMAT=19.2 AS VL_M_SAA*/
/*      FROM WORK.RIV_M_SAA t1*/
/*      GROUP BY t1.CD_PRF_RSTD;*/
/*QUIT;*/
/**/
/**/
/*data tran.junta_riv_&anomes;*/
/*merge RIV_AC_SAA RIV_M_SAA;*/
/*by cd_prf_rstd;*/
/*run;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE RIV AS */
/*   SELECT */
/*t1.CD_PRF_RSTD as PREFDEP, */
/*          t1.VL_AC_SAA, */
/*          t1.VL_M_SAA,*/
/*          t2.orc as ORC_SAA*/
/*      FROM TRAN.JUNTA_RIV_&anomes t1*/
/*	     INNER JOIN TRAN.negocios_saa_meta_2s2018r T2 ON (T1.CD_PRF_RSTD=T2.prefdep)*/
/*		 INNER JOIN IGR.IGRREDE_&anomes T3 ON (T1.CD_PRF_RSTD=INPUT(t3.PREFDEP,4.))*/
/*		 where t2.anomes=&anomes and t2.orc>0 AND T3.TIPODEP IN ('09' '01') AND CODSITDEP IN ('2' '4')*/
/*		 ORDER BY 1*/
/*;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE RESULTADO_SUPREG AS */
/*SELECT DISTINCT INPUT(PREFSUPREG,4.) AS PREFDEP,*/
/*sum(VL_AC_SAA) as VL_AC_SAA, */
/*sum(VL_M_SAA) as VL_M_SAA,*/
/*sum(orc_saa) as orc_saa*/
/*FROM WORK.RIV t1*/
/*INNER JOIN IGR.IGRREDE B ON (T1.PREFDEP=INPUT(B.PREFDEP,4.))*/
/*WHERE PREFSUPREG NE "0000"*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE RESULTADO_SUPEST AS */
/*SELECT DISTINCT INPUT(PREFSUPEST,4.) AS PREFDEP,*/
/*sum(VL_AC_SAA) as VL_AC_SAA, */
/*sum(VL_M_SAA) as VL_M_SAA,*/
/*sum(orc_saa) as orc_saa*/
/*FROM WORK.RIV t1*/
/*INNER JOIN IGR.IGRREDE B ON (T1.PREFDEP=INPUT(B.PREFDEP,4.))*/
/*WHERE PREFSUPEST NE "0000"*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE RESULTADO_PREFUEN AS */
/*   SELECT DISTINCT INPUT(PREFUEN,4.) AS PREFDEP, */
/*sum(VL_AC_SAA) as VL_AC_SAA, */
/*sum(VL_M_SAA) as VL_M_SAA,*/
/*sum(orc_saa) as orc_saa*/
/*FROM WORK.RIV t1*/
/*INNER JOIN IGR.IGRREDE B ON (T1.PREFDEP=INPUT(B.PREFDEP,4.))*/
/*WHERE PREFUEN NE "0000"*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE WORK.RESULTADO_VIVAP AS */
/*SELECT 8166 AS PREFDEP, */
/*(SUM(t1.VL_AC_SAA)) AS VL_AC_SAA, */
/*(SUM(t1.VL_M_SAA)) AS VL_M_SAA,*/
/*sum(orc_saa) as orc_saa*/
/*FROM WORK.RESULTADO_PREFUEN t1*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/*DATA JUNTA_SAA;*/
/*SET RIV RESULTADO_SUPREG RESULTADO_SUPEST RESULTADO_PREFUEN RESULTADO_VIVAP;*/
/*RUN;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE RIV_01 AS */
/*   SELECT */
/*&d1. FORMAT DDMMYY10. AS POSICAO,*/
/*t1.PREFDEP, */
/*          t1.VL_AC_SAA, */
/*          t1.VL_M_SAA,*/
/*		  t1.orc_saa*/
/*      FROM WORK.JUNTA_SAA t1*/
/*;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE RIV_02 AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.VL_AC_SAA,*/
/*          t1.ORC_SAA, */
/*          t1.VL_M_SAA*/
/*      FROM WORK.RIV_01 t1*/
/*    */
/*;QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE riv_03 AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.VL_AC_SAA, */
/*          t1.ORC_SAA, */
/*          t1.VL_M_SAA, */
/*          (VL_M_SAA/ORC_saa)*100 AS PCT_ATG_RIV*/
/*      FROM WORK.RIV_02 t1;*/
/*QUIT;*/
/**/
/*/*REGUA ALTERADA EM 27/07/2018 CFE EMAIL CONEXAO SAA -*/*/
/*/*MATRICULA F8366515*/*/
/**/
/**/
/**/
/*data REGUA_RIV;*/
/*infile DATALINES dsd missover;*/
/*input Inferior Superior Pontos;*/
/*format Inferior Superior 32.4;*/
/*CARDS;*/
/*125.00,	9999.99, 525*/
/*120.00,	124.99,	490*/
/*118.00,	119.99,	455*/
/*115.00,	117.99,	420*/
/*112.00,	114.99,	385*/
/*100.00,	111.99,	350*/
/*90.00,	99.99,	315*/
/*80.00,	89.99,	280*/
/*70.00, 	79.99,	245*/
/*60.00,	69.99,	210*/
/*50.00,	59.99,	175*/
/*40.00,	49.99,	140*/
/*30.00,	39.99,	105*/
/*20.00,	29.99,	70*/
/*10.00,	19.99,	35*/
/*0.00,	9.99,	0*/
/*;*/
/*run;*/
/**/
/**/
/*/**/*/
/*/**/*/
/*/**/*/
/*/*data REGUA_RIV;*/*/
/*/*infile DATALINES dsd missover;*/*/
/*/*input Inferior Superior Pontos;*/*/
/*/*format Inferior Superior 32.4;*/*/
/*/*CARDS;*/*/
/*/*110.00,	9999.00,	1500*/*/
/*/*109.00,	109.99,	1400*/*/
/*/*108.00,	108.99,	1300*/*/
/*/*107.00,	107.99,	1200*/*/
/*/*105.00,	106.99,	1100*/*/
/*/*100.00,	104.99,	1000*/*/
/*/*90.00,	99.99,	900*/*/
/*/*80.00,	89.99,	800*/*/
/*/*70.00, 	79.99,	700*/*/
/*/*60.00,	69.99,	600*/*/
/*/*50.00,	59.99,	500*/*/
/*/*40.00,	49.99,	400*/*/
/*/*30.00,	39.99,	300*/*/
/*/*20.00,	29.99,	200*/*/
/*/*10.00,	19.99,	100*/*/
/*/*0.00,	0.9999,	0*/*/
/*/*;*/*/
/*/*run;*/*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE RIV_04 AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.VL_AC_SAA, */
/*          t1.ORC_SAA, */
/*          t1.VL_M_SAA, */
/*          t1.PCT_ATG_RIV,*/
/*		  ifn(orc_saa is missing or orc_saa=0,525,T2.PONTOS) as PONTOS_RIV*/
/*      FROM WORK.RIV_03 t1*/
/*LEFT JOIN REGUA_RIV T2 ON (T1.PCT_ATG_RIV BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*WHERE ORC_SAA>0*/
/*GROUP BY 1,2;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE riv_saa AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.VL_AC_SAA format 19.2, */
/*          t1.ORC_SAA format 19.2, */
/*          t1.VL_M_SAA format 19.2, */
/*          t1.PCT_ATG_RIV, */
/*          t1.PONTOS_RIV*/
/*      FROM WORK.RIV_04 t1;*/
/*QUIT;*/
/**/
/*DATA SEGURIDADE_DETALHE;*/
/*SET SEG.RV_201810 SEG.RV_201811 SEG.RV_201812;*/
/*RUN;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE SEGURIDADE_RIV_detalhe AS */
/*   SELECT t1.CD_PRF_CTRA_CLI, */
/*			t1.CD_ITCE_CNL AS CD_IPMC_ITCE_CNL, */
/*			t1.CD_PRF_RSTD, */
/*			t1.CD_CPNT_RSTD, */
/*			t1.VLR_CPNT_RSTD AS VL_CPNT_RSTD_TODOS,*/
/*			t1.DT_APRC, */
/*			t1.CD_PRD, */
/*			t1.CD_MDLD, */
/*			t1.CD_CLI, */
/*			t1.NR_UNCO_CTR_OPR, */
/*             VL_CTR AS VL_ULT_SDO*/
/*      FROM WORK.SEGURIDADE_DETALHE t1*/
/*WHERE CD_ITCE_CNL=10;*/
/*QUIT;*/
/**/
/*DATA PUBLICO_RIV_REP;*/
/*SET ADE.PUBLICO_RIV_7DEZ18;*/
/*WHERE DT_APRC BETWEEN '01JUL2018'D AND '30NOV2018'D; */
/*RUN;*/
/**/
/**/
/*DATA DETALHE_II;*/
/*SET PUBLICO_RIV_REP SEGURIDADE_RIV_detalhe PUBLICO_MES;*/
/*RUN;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE TRAN.detalhe AS */
/*   SELECT */
/*&d1. FORMAT DDMMYY10. AS POSICAO,*/
/* t1.CD_PRF_RSTD as PREFDEP,*/
/*t1.NR_UNCO_CTR_OPR, */
/*          t1.NR_CTR_OPR, */
/*          t1.NR_SCTR_OPR, */
/*          t1.CD_CLI, */
/*          t1.CD_IPMC_ITCE_CNL, */
/*          t1.CD_PRD, */
/*          t1.CD_MDLD, */
/*		  t2.NM_MDLD,*/
/*          t1.CD_CPNT_RSTD, */
/*          t1.VL_CPNT_RSTD_TODOS, */
/*          t1.VL_ULT_SDO, */
/*          t1.DT_APRC, */
/*          t1.DT_FRMZ_SCTR*/
/*      FROM WORK.DETALHE_II t1*/
/*	  inner join DB2PRD.MDLD_PRD t2 on (t1.cd_prd=t2.cd_prd AND T1.CD_MDLD=T2.CD_MDLD)*/
/**/
/*WHERE DT_APRC>='01JUL2018'D;*/
/*QUIT;*/
/**/
/*DATA DETALHA;*/
/*set tran.detalhe;*/
/*run;*/
/*/**/*/
/*/**/*/
/*/*/* RELATÓRIO 279 */*/*/
/*/**/*/
/*/*%LET Usuario=f9457977;*/*/
/*/*%LET Keypass=lamRISgRPpy1CdCCeDuq5Q3T9jzvPFvOclCGIUHIhLe79v7wNY;*/*/
/*/*PROC SQL;*/*/
/*/*DROP TABLE TABELAS_EXPORTAR_REL;*/*/
/*/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/*/
/*/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('riv_saa', 'riv-unv');*/*/
/*/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('detalha', 'detalhe');*/*/
/*/*QUIT;*/*/
/*/*%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);	  */*/
/*/**/*/
/**/
/*x cd /;*/
/*x cd /dados/infor/producao/saa;*/
/*x cd /dados/infor/producao/Aderencia;*/
/*x cd /dados/infor/producao/TCX_UNV;*/
/*x chmod -R 2777 *; /*ALTERAR PERMISÕES*/*/
/*x chown f9457977 -R ./; /*FIXA O FUNCI*/*/
/*x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/*/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE tran.neg_saa_&anomes AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.VL_AC_SAA, */
/*          t1.ORC_SAA, */
/*          t1.VL_M_SAA, */
/*          t1.PCT_ATG_RIV, */
/*          t1.PONTOS_RIV*/
/*      FROM WORK.RIV_SAA t1;*/
/*QUIT;*/
/**/
/**/

/*************************************************/;
/* TRECHO DE CÓDIGO INCLUÍDO PELO FF */;

%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";
 
%processCheckOut(
    uor_resp = 341556
    ,funci_resp = &sysuserid
    /*,tipo = Indicador
    ,sistema = Indicador
    ,rotina = I0123 Indicador de Alguma Coisa*/
    ,mailto= 'F8369937' 'F2986408' 'F6794004' 'F7176219' 'F8176496' 'F9457977' 'F9631159'
);
