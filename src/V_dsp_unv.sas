/*%include '/dados/infor/suporte/FuncoesInfor.sas';	*/
/**/
/*CONTROLE DE DATAS*/*/
/*DATA _NULL_;*/
/*	DATA_INICIO = '01Jan2017'd;*/
/*	DATA_FIM = '30Dec2018'd;*/
/*	DATA_REFERENCIA = diaUtilAnterior(TODAY());*/
/*	D1 = diaUtilAnterior(TODAY());*/
/*	D2 = diaUtilAnterior(D1);*/
/*	D3 = diaUtilAnterior(D2);*/
/*	MES_ATU = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));*/
/*	MES_ANT = Put(INTNX('month',primeiroDiaUtilMes(D1),-1), yymmn6.);*/
/*	MES_G = Put(DATA_REFERENCIA, MONTH.);*/
/*	ANOMES = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));*/
/*	DT_INICIO_SQL="'"||put(DATA_INICIO, YYMMDDD10.)||"'";*/
/*	DT_D1_SQL="'"||put(D1, YYMMDDD10.)||"'";*/
/*	DT_1DIA_MES_SQL="'"||put(primeiroDiaUtilMes(D1), YYMMDDD10.)||"'";*/
/*	DT_ANOMES_SQL=primeiroDiaUtilMes(D1);*/
/*	PRIMEIRO_DIA_MES_SQL="'"||put(primeiroDiaMes(DATA_REFERENCIA), YYMMDDD10.)||"'";*/
/*	MMAAAA=PUT(D1,mmyyn6.);*/
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
/*	CALL SYMPUT('MMAAAA', COMPRESS(MMAAAA,' '));*/
/*RUN;*/
/**/
/*LIBNAME ADE '/dados/infor/producao/Aderencia';*/
/**/
/*x cd /;*/
/*x cd /dados/infor/producao/saa;*/
/*x chmod -R 2777 *; /*ALTERAR PERMISÕES*/*/
/*x chown f9457977 -R ./; /*FIXA O FUNCI*/*/
/*x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/*/
/**/
/**/
/*%LET SELECT="SELECT * FROM tb_dspb_pto where periodo>201808;";*/
/*%ImportSelect(Select=&SELECT., TabelaSaidaSAS=tb_dsp, Acesso=%AcessoMySqlUOPTerminais(terminais));*/
/**/
/*%LET SELECT="SELECT * FROM jrdt_pso;";*/
/*%ImportSelect(Select=&SELECT., TabelaSaidaSAS=PSO, Acesso=%AcessoMySqlUOPCNX(sinergia));*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE DISPONIBILIDADE_TAA AS */
/*   SELECT  */
/*          dt_mta, */
/*          t1.PERIODO,*/
/*          t2.CD_UOR_AG,  */
/*		  IFN(T2.CD_PRF_AG IS MISSING, T1.CD_PRF, T2.CD_PRF_AG) AS PREFDEP, */
/*          IFN (T2.CD_SBDD_AG IS MISSING,T1.CD_SBDD, T2.CD_SBDD_AG) AS CD_SUB, */
/*		  T2.NM_UOR_RED_AG,*/
/*          t1.CD_PRF, */
/*          t1.CD_SBDD, */
/*		  T2.NM_UOR_RED,*/
/*          t1.QTDE_TRML_NTERC, */
/*          t1.QTDE_TRML_TERC, */
/*          t1.VLR_DSPB_NTERC, */
/*          t1.VLR_DSPB_TERC, */
/*          t1.VLR_DSPB, */
/*          t1.VLR_DSPB_AJSD*/
/*      FROM WORK.TB_DSP t1*/
/*LEFT JOIN PSO T2 ON (T1.CD_PRF=T2.CD_PRF AND T1.CD_SBDD=T2.CD_SBDD)*/
/*WHERE periodo=&anomes. and dt_mta=&d1. ;*/
/*QUIT;*/
/**/
/**/
/* */
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_00 AS */
/*		SELECT DISTINCT */
/*			T1.DT_MTA, */
/*			t1.PREFDEP, */
/*			t1.CD_SUB, */
/*			t1.QTDE_TRML_NTERC, */
/*			t1.QTDE_TRML_TERC, */
/*			t1.VLR_DSPB_NTERC, */
/*			t1.VLR_DSPB_TERC, */
/*			t1.VLR_DSPB,*/
/*			t1.VLR_DSPB_AJSD*/
/*		FROM WORK.DISPONIBILIDADE_TAA t1*/
/*	;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_01 AS */
/*		SELECT t1.DT_MTA,*/
/*			t1.PREFDEP,*/
/*			count(prefdep) as qtd_dep,*/
/*			SUM(VLR_DSPB_AJSD) AS VLR_DSPB_AJSD*/
/*		FROM WORK.DSP_00 t1*/
/*			GROUP BY 1,2;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE DSP_DIARIO_&anomes AS */
/*   SELECT t1.dt_mta,*/
/*          t1.PREFDEP, */
/*          (VLR_DSPB_AJSD/QTD_DEP) AS VLR_RLZD*/
/*      FROM WORK.DSP_01 t1*/
/*      INNER JOIN ADE.PUBLICO_PREFIXO_&anomes T2 ON (T1.PREFDEP=T2.PREFIXO AND T1.DT_MTA=T2.POSICAO);*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	DELETE FROM ADE.DSP_DIARIO_&anomes WHERE DT_MTA = &d1.;*/
/*RUN;*/
/**/
/*PROC APPEND OUT=ADE.DSP_DIARIO_&anomes*/
/*	BASE=ADE.DSP_DIARIO_&anomes*/
/*	DATA=WORK.DSP_DIARIO_&anomes;*/
/*RUN;*/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE RLZD_01 AS */
/*   SELECT */
/*MAX(DT_MTA) FORMAT DDMMYY10. AS POSICAO,*/
/*t1.PREFDEP, */
/*           COUNT_of_DT_MTA */*/
/*            (COUNT(t1.DT_MTA)) AS QTD_DIAS, */
/*          SUM(VLR_RLZD) AS VLR_RLZD*/
/*      FROM ADE.DSP_DIARIO_&anomes t1*/
/*      GROUP BY t1.PREFDEP;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE RLZD_02 AS */
/*   SELECT */
/*MAX(POSICAO) FORMAT DDMMYY10. AS POSICAO,*/
/*t1.PREFDEP, */
/*           90 AS VLR_ORC,*/
/*          (t1.VLR_RLZD/QTD_DIAS) AS VLR_RLZD*/
/*      FROM WORK.RLZD_01 t1;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SUPREG AS */
/*		SELECT POSICAO, */
/*			INPUT(PREFSUPREG,4.) AS PREFDEP,*/
/*			SUM(VLR_ORC) AS VLR_ORC,*/
/*			SUM(VLR_RLZD) AS VLR_RLZD*/
/*		FROM WORK.RLZD_02 t1*/
/*			INNER JOIN IGR.IGRREDE B ON (T1.PREFDEP=INPUT(B.PREFDEP,4.))*/
/*				WHERE PREFSUPREG NE "0000" AND CODSITDEP = '2'*/
/*					GROUP BY 1,2*/
/*	;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SUPEST AS */
/*		SELECT POSICAO,*/
/*			INPUT(PREFSUPEST,4.) AS PREFDEP,*/
/*			SUM(VLR_ORC) AS VLR_ORC,*/
/*			SUM(VLR_RLZD) AS VLR_RLZD*/
/*		FROM WORK.RLZD_02 t1*/
/*			INNER JOIN IGR.IGRREDE B ON (T1.PREFDEP=INPUT(B.PREFDEP,4.))*/
/*				WHERE PREFSUPEST NE "0000" AND CODSITDEP = '2'*/
/*					GROUP BY 1,2*/
/*	;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE PREFUEN AS */
/*		SELECT POSICAO,*/
/*			INPUT(PREFUEN,4.) AS PREFDEP, */
/*			SUM(VLR_ORC) AS VLR_ORC,*/
/*			SUM(VLR_RLZD) AS VLR_RLZD*/
/*		FROM WORK.RLZD_02 t1*/
/*			INNER JOIN IGR.IGRREDE B ON (T1.PREFDEP=INPUT(B.PREFDEP,4.))*/
/*				WHERE PREFUEN NE "0000"*/
/*					GROUP BY 1,2*/
/*	;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE VIVAP AS */
/*		SELECT  POSICAO,*/
/*			8166 AS PREFDEP, */
/*			SUM(VLR_ORC) AS VLR_ORC,*/
/*			SUM(VLR_RLZD) AS VLR_RLZD*/
/*		FROM WORK.PREFUEN t1*/
/*			GROUP BY 1,2;*/
/*QUIT;*/
/**/
/*DATA JUNTA_PREFIXOS;*/
/*	SET RLZD_02 SUPREG SUPEST PREFUEN VIVAP;*/
/*RUN;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_02 AS */
/*		SELECT  POSICAO, */
/*			t1.PREFDEP, */
/*			t1.VLR_ORC, */
/*			t1.VLR_RLZD,*/
/*		(case */
/*			WHEN (vlr_rlzd/vlr_orc)*100 > 100 THEN 100*/
/*			ELSE (VLR_RLZD/VLR_ORC)*100 */
/*		END)*/
/*	AS PC_ATINGIMENTO*/
/*		FROM WORK.JUNTA_PREFIXOS t1*/
/*			GROUP BY 2,3,4,5;*/
/*QUIT;*/
/*LIBNAME ADE '/dados/infor/producao/Aderencia';*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE WORK.REL_01 AS */
/*		SELECT POSICAO  as posicao, */
/*			t1.PREFDEP, */
/*			t1.VLR_ORC, */
/*			t1.VLR_RLZD AS VLR_RLZ, */
/*			t1.PC_ATINGIMENTO*/
/*		FROM WORK.DSP_02 t1*/
/*;*/
/*QUIT;*/
/**/
/*data REGUA_DSP;*/
/*	infile DATALINES dsd missover;*/
/*	input Inferior Superior Pontos;*/
/*	format Inferior Superior 32.4;*/
/*	CARDS;*/
/*98.00,	100.00,	225*/
/*96.00,	97.99,	210*/
/*95.00,	95.99,	195*/
/*94.00,	94.99,	180*/
/*92.00,	93.99,	165*/
/*90.00,	91.99,	150*/
/*86.00,	89.99,	135*/
/*84.00,	85.99,	120*/
/*82.00,	83.99,	105*/
/*80.00,	81.99,	90*/
/*78.00,	79.99,	75*/
/*75.00,	77.99,	60*/
/*70.00,	74.99,	45*/
/*65.00,	69.99,	30*/
/*60.00,	64.99,	15*/
/*0.00,	59.99,	0*/
/*;*/
/*run;*/
/*LIBNAME TRAN '/dados/infor/producao/saa';*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE  TRAN.DSP_SAA_&anomes AS */
/*		SELECT t1.POSICAO, */
/*			T1.PREFDEP,*/
/*           0 AS UOR, */
/*			t1.vlr_orc FORMAT 20.2,*/
/*			t1.VLR_RLZ FORMAT 20.2,*/
/*			PC_ATINGIMENTO  FORMAT 20.2 as pc_atgt_dsp,*/
/*			IFN(VLR_ORC=.,525,T2.PONTOS) AS PONTOS_DSP*/
/*		FROM WORK.REL_01 t1*/
/*			LEFT JOIN REGUA_DSP T2 ON (PC_ATINGIMENTO BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*				GROUP BY 1,2,3;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/**/
/*x cd /;*/
/*x cd /dados/infor/producao/saa;*/
/*x cd /dados/infor/producao/Aderencia;*/
/*x chmod -R 2777 *; /*ALTERAR PERMISÕES*/*/
/*x chown f9457977 -R ./; /*FIXA O FUNCI*/*/
/*x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/*/
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
