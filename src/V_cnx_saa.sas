/**/
/*%include '/dados/infor/suporte/FuncoesInfor.sas';*/
/**/
/**/
/*DATA _NULL_;*/
/*	DATA_INICIO = '01Jan2017'd;*/
/*	DATA_FIM = '30Dec2018'd;*/
/*	DATA_REFERENCIA = diaUtilAnterior(TODAY()-1);*/
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
/*	 MMAAAA=PUT(D1,mmyyn6.);*/
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
/*	CALL SYMPUT('MMAAAA', COMPRESS(MMAAAA,' '));*/
/*RUN;*/
/**/
/*LIBNAME DB2ARH		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ARH database=BDB2P04;*/
/*LIBNAME DB2DTM		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2DTM database=BDB2P04;*/
/*LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2SGCEN database=BDB2P04;*/
/*LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2SGCEN database=BDB2P04;*/
/*LIBNAME DB2ATB 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ATB database=BDB2P04;*/
/*LIBNAME DB2RST 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2RST database=BDB2P04;*/
/**/
/**/
/**/
/*x cd /;*/
/*x cd /dados/infor/producao/Aderencia;*/
/*x cd /dados/infor/producao/TCX_UNV;*/
/*x cd /dados/infor/producao/saa;*/
/*x chmod -R 2777 *; /*ALTERAR PERMISÕES*/*/
/*x chown f9457977 -R ./; /*FIXA O FUNCI*/*/
/*x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/*/
/**/
/**/
/**/
/**/
/*										/*******************/*/
/*										/*******************/*/
/*										/**** Aderencia ****/*/
/*										/*******************/*/
/*										/*******************/*/
/**/
/**/
/*LIBNAME ADE '/dados/infor/producao/Aderencia';*/
/**/
/*LIBNAME DET_SUP '/dados/externo/UNV/canais';*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE REL_ADE_01 AS */
/*		SELECT */
/*			t1.PREFIXO AS PREFDEP,*/
/*			COUNT(DISTINCT(t1.POSICAO)) AS QT_DIAS,*/
/*			SUM(t1.PONTUACAO_MAX_SUPERV_DIA) FORMAT=5. AS PONTUACAO_MAX_SUPERV_DIA, */
/*			SUM(t1.PTOS_SUPERV_IND_UOR) FORMAT=5. AS PTOS_SUPERV_IND_UOR, */
/*			SUM(t1.PTOS_SUPERV_IND_GAT) FORMAT=5. AS PTOS_SUPERV_IND_GAT, */
/*			SUM(t1.PTOS_SUPERV_IND_BIC) FORMAT=5. AS PTOS_SUPERV_IND_BIC, */
/*			SUM(t1.PONTUACAO_TOTAL_SUPERV_DIA) FORMAT=5. AS PONTUACAO_TOTAL_SUPERV_MES, */
/*			SUM(t1.PONTUACAO_MAX_ESCRIT_DIA) FORMAT=5. AS PONTUACAO_MAX_ESCRIT_MES, */
/*			SUM(t1.PTOS_ESCRIT_IND_UOR) FORMAT=5. AS PTOS_ESCRIT_IND_UOR,*/
/*			SUM(t1.PTOS_ESCRIT_IND_GAT) FORMAT=5. AS PTOS_ESCRIT_IND_GAT, */
/*			SUM(t1.PTOS_ESCRIT_IND_BIC) FORMAT=5. AS PTOS_ESCRIT_IND_BIC, */
/*			SUM(t1.PONTUACAO_TOTAL_ESCRIT_DIA) FORMAT=5. AS PONTUACAO_TOTAL_ESCRIT_MES, */
/*			SUM(t1.PONTUACAO_OBTIDA_AGENCIA) AS PONTUACAO_OBTIDA_AGENCIA, */
/*			SUM(t1.PONTUACAO_MAXIMA_REGRA) AS PONTUACAO_MAXIMA_REGRA */
/*		FROM ADE.REL_AGENCIAS_DIA_201812 t1*/
/*			WHERE DESCARTAR=0 AND t1.PONTUACAO_OBTIDA_AGENCIA <> 0*/
/*				GROUP BY*/
/*					t1.PREFIXO;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE RESULTADO_SUPREG AS */
/*SELECT DISTINCT */
/*INPUT(PREFSUPREG,4.) AS PREFDEP,*/
/*          MAX(QT_DIAS), */
/*          sum(PONTUACAO_MAX_SUPERV_DIA) AS PONTUACAO_MAX_SUPERV_DIA, */
/*          sum(PTOS_SUPERV_IND_UOR) AS PTOS_SUPERV_IND_UOR, */
/*          sum(PTOS_SUPERV_IND_GAT) AS PTOS_SUPERV_IND_GAT, */
/*          sum(PTOS_SUPERV_IND_BIC) AS PTOS_SUPERV_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_SUPERV_MES) AS PONTUACAO_TOTAL_SUPERV_MES, */
/*          sum(PONTUACAO_MAX_ESCRIT_MES) AS PONTUACAO_MAX_ESCRIT_MES, */
/*          sum(PTOS_ESCRIT_IND_UOR) AS PTOS_ESCRIT_IND_UOR, */
/*          sum(PTOS_ESCRIT_IND_GAT) AS PTOS_ESCRIT_IND_GAT, */
/*          sum(PTOS_ESCRIT_IND_BIC) AS PTOS_ESCRIT_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_ESCRIT_MES) AS PONTUACAO_TOTAL_ESCRIT_MES, */
/*          sum(PONTUACAO_OBTIDA_AGENCIA) AS PONTUACAO_OBTIDA_AGENCIA, */
/*          sum(PONTUACAO_MAXIMA_REGRA ) AS PONTUACAO_MAXIMA_REGRA*/
/*FROM WORK.REL_ADE_01 t1*/
/*INNER JOIN IGR.IGRREDE B ON (T1.prefdep=INPUT(B.PREFDEP,4.))*/
/*WHERE PREFSUPREG NE "0000" AND CODSITDEP='2'*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE RESULTADO_SUPEST AS */
/*SELECT DISTINCT */
/**/
/*INPUT(PREFSUPEST,4.) AS PREFDEP,*/
/*          MAX(QT_DIAS), */
/*          sum(PONTUACAO_MAX_SUPERV_DIA) AS PONTUACAO_MAX_SUPERV_DIA, */
/*          sum(PTOS_SUPERV_IND_UOR) AS PTOS_SUPERV_IND_UOR, */
/*          sum(PTOS_SUPERV_IND_GAT) AS PTOS_SUPERV_IND_GAT, */
/*          sum(PTOS_SUPERV_IND_BIC) AS PTOS_SUPERV_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_SUPERV_MES) AS PONTUACAO_TOTAL_SUPERV_MES, */
/*          sum(PONTUACAO_MAX_ESCRIT_MES) AS PONTUACAO_MAX_ESCRIT_MES, */
/*          sum(PTOS_ESCRIT_IND_UOR) AS PTOS_ESCRIT_IND_UOR, */
/*          sum(PTOS_ESCRIT_IND_GAT) AS PTOS_ESCRIT_IND_GAT, */
/*          sum(PTOS_ESCRIT_IND_BIC) AS PTOS_ESCRIT_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_ESCRIT_MES) AS PONTUACAO_TOTAL_ESCRIT_MES, */
/*          sum(PONTUACAO_OBTIDA_AGENCIA) AS PONTUACAO_OBTIDA_AGENCIA, */
/*          sum(PONTUACAO_MAXIMA_REGRA ) AS PONTUACAO_MAXIMA_REGRA*/
/*FROM WORK.REL_ADE_01 t1*/
/*INNER JOIN IGR.IGRREDE B ON (T1.prefdep=INPUT(B.PREFDEP,4.))*/
/*WHERE PREFSUPEST NE "0000" AND CODSITDEP='2'*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE RESULTADO_PREFUEN AS */
/*   SELECT DISTINCT */
/*  */
/*INPUT(PREFUEN,4.) AS PREFDEP, */
/* MAX(QT_DIAS), */
/*          sum(PONTUACAO_MAX_SUPERV_DIA) AS PONTUACAO_MAX_SUPERV_DIA, */
/*          sum(PTOS_SUPERV_IND_UOR) AS PTOS_SUPERV_IND_UOR, */
/*          sum(PTOS_SUPERV_IND_GAT) AS PTOS_SUPERV_IND_GAT, */
/*          sum(PTOS_SUPERV_IND_BIC) AS PTOS_SUPERV_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_SUPERV_MES) AS PONTUACAO_TOTAL_SUPERV_MES, */
/*          sum(PONTUACAO_MAX_ESCRIT_MES) AS PONTUACAO_MAX_ESCRIT_MES, */
/*          sum(PTOS_ESCRIT_IND_UOR) AS PTOS_ESCRIT_IND_UOR, */
/*          sum(PTOS_ESCRIT_IND_GAT) AS PTOS_ESCRIT_IND_GAT, */
/*          sum(PTOS_ESCRIT_IND_BIC) AS PTOS_ESCRIT_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_ESCRIT_MES) AS PONTUACAO_TOTAL_ESCRIT_MES, */
/*          sum(PONTUACAO_OBTIDA_AGENCIA) AS PONTUACAO_OBTIDA_AGENCIA, */
/*          sum(PONTUACAO_MAXIMA_REGRA ) AS PONTUACAO_MAXIMA_REGRA*/
/*FROM WORK.REL_ADE_01 t1*/
/*INNER JOIN IGR.IGRREDE B ON (T1.prefdep=INPUT(B.PREFDEP,4.))*/
/*WHERE PREFUEN NE "0000" AND CODSITDEP='2'*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.VIVAP AS */
/*   SELECT 8166 AS PREFDEP, */
/* MAX(_TEMG001), */
/*          sum(PONTUACAO_MAX_SUPERV_DIA) AS PONTUACAO_MAX_SUPERV_DIA, */
/*          sum(PTOS_SUPERV_IND_UOR) AS PTOS_SUPERV_IND_UOR, */
/*          sum(PTOS_SUPERV_IND_GAT) AS PTOS_SUPERV_IND_GAT, */
/*          sum(PTOS_SUPERV_IND_BIC) AS PTOS_SUPERV_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_SUPERV_MES) AS PONTUACAO_TOTAL_SUPERV_MES, */
/*          sum(PONTUACAO_MAX_ESCRIT_MES) AS PONTUACAO_MAX_ESCRIT_MES, */
/*          sum(PTOS_ESCRIT_IND_UOR) AS PTOS_ESCRIT_IND_UOR, */
/*          sum(PTOS_ESCRIT_IND_GAT) AS PTOS_ESCRIT_IND_GAT, */
/*          sum(PTOS_ESCRIT_IND_BIC) AS PTOS_ESCRIT_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_ESCRIT_MES) AS PONTUACAO_TOTAL_ESCRIT_MES, */
/*          sum(PONTUACAO_OBTIDA_AGENCIA) AS PONTUACAO_OBTIDA_AGENCIA, */
/*          sum(PONTUACAO_MAXIMA_REGRA ) AS PONTUACAO_MAXIMA_REGRA*/
/*      FROM WORK.RESULTADO_PREFUEN t1*/
/*GROUP BY 1;*/
/*QUIT;*/
/**/
/**/
/*/*AQUI*/*/
/**/
/**/
/*data sumarizado;*/
/*set REL_ADE_01 RESULTADO_SUPREG RESULTADO_SUPEST RESULTADO_PREFUEN VIVAP;*/
/*run;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.REL_ADE_SUM AS */
/*   SELECT */
/*t1.prefdep, */
/*          t1.QT_DIAS, */
/*          sum(PONTUACAO_MAX_SUPERV_DIA) as PONTUACAO_MAX_SUPERV_DIA, */
/*          sum(PTOS_SUPERV_IND_UOR) as PTOS_SUPERV_IND_UOR, */
/*          sum(PTOS_SUPERV_IND_GAT) as PTOS_SUPERV_IND_GAT, */
/*          sum(PTOS_SUPERV_IND_BIC) as PTOS_SUPERV_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_SUPERV_MES) as PONTUACAO_TOTAL_SUPERV_MES, */
/*          sum(PONTUACAO_MAX_ESCRIT_MES) as PONTUACAO_MAX_ESCRIT_MES, */
/*          sum(PTOS_ESCRIT_IND_UOR) as  PTOS_ESCRIT_IND_UOR, */
/*          sum(PTOS_ESCRIT_IND_GAT) as PTOS_ESCRIT_IND_GAT, */
/*          sum(PTOS_ESCRIT_IND_BIC) as PTOS_ESCRIT_IND_BIC, */
/*          sum(PONTUACAO_TOTAL_ESCRIT_MES) as PONTUACAO_TOTAL_ESCRIT_MES, */
/*          sum(PONTUACAO_OBTIDA_AGENCIA) as PONTUACAO_OBTIDA_AGENCIA, */
/*          sum(PONTUACAO_MAXIMA_REGRA) as PONTUACAO_MAXIMA_REGRA*/
/*      FROM WORK.SUMARIZADO t1*/
/*group by 1,2;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE REL_ADE_02 AS */
/*   SELECT t1.prefdep, */
/*          t1.QT_DIAS, */
/*          t1.PONTUACAO_MAX_SUPERV_DIA, */
/*          t1.PTOS_SUPERV_IND_UOR, */
/*          t1.PTOS_SUPERV_IND_GAT, */
/*          t1.PTOS_SUPERV_IND_BIC, */
/*          t1.PONTUACAO_TOTAL_SUPERV_MES, */
/*          t1.PONTUACAO_MAX_ESCRIT_MES, */
/*          t1.PTOS_ESCRIT_IND_UOR, */
/*          t1.PTOS_ESCRIT_IND_GAT, */
/*          t1.PTOS_ESCRIT_IND_BIC, */
/*          t1.PONTUACAO_TOTAL_ESCRIT_MES, */
/*          t1.PONTUACAO_OBTIDA_AGENCIA, */
/*          t1.PONTUACAO_MAXIMA_REGRA,*/
/*		  (PONTUACAO_OBTIDA_AGENCIA/PONTUACAO_MAXIMA_REGRA)*100 as PERC_ATING_AGENCIA*/
/*      FROM WORK.REL_ADE_SUM t1;*/
/*QUIT;*/
/*	  */
/**/
/*data REGUA_ADERENCIA;*/
/*infile DATALINES dsd missover;*/
/*input Inferior Superior Pontos;*/
/*format Inferior Superior 32.4;*/
/*CARDS;*/
/*95.00,	100.00,	525*/
/*92.00,	94.99,	490*/
/*89.00,	91.99,	455*/
/*86.00,	88.99,	420*/
/*83.00,	85.99,	385*/
/*80.00,	82.99,	350*/
/*75.00,	79.99,	315*/
/*70.00,	74.99,	280*/
/*65.00,	69.99,	245*/
/*60.00,	64.99,	210*/
/*55.00,	59.99,	175*/
/*50.00,	54.99,	140*/
/*45.00,	49.99,	105*/
/*40.00,	44.99,	70*/
/*30.00,	39.99,	35*/
/*0.00,	29.99,	0*/
/*;*/
/*run;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE ADERENCIA AS */
/*   SELECT  '31dec2018'd  FORMAT=DateMysql. AS POSICAO, */
/*          t1.prefdep, */
/*          t1.QT_DIAS, */
/*          t1.PONTUACAO_MAX_SUPERV_DIA as PONTUACAO_MAX_superv,*/
/*          t1.PTOS_SUPERV_IND_UOR, */
/*          t1.PTOS_SUPERV_IND_GAT, */
/*          t1.PTOS_SUPERV_IND_BIC, */
/*          t1.PONTUACAO_TOTAL_SUPERV_MES as PONTUACAO_TOTAL_SUPERV, */
/*          t1.PONTUACAO_MAX_ESCRIT_MES, */
/*          t1.PTOS_ESCRIT_IND_UOR, */
/*          t1.PTOS_ESCRIT_IND_GAT, */
/*          t1.PTOS_ESCRIT_IND_BIC, */
/*          t1.PONTUACAO_TOTAL_ESCRIT_MES, */
/*          t1.PONTUACAO_OBTIDA_AGENCIA, */
/*          t1.PONTUACAO_MAXIMA_REGRA, */
/*          t1.PERC_ATING_AGENCIA,*/
/*		  T2.PONTOS AS PONTOS_ADE*/
/*      FROM WORK.REL_ADE_02 t1*/
/*INNER JOIN REGUA_ADERENCIA T2 ON (PERC_ATING_AGENCIA BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*GROUP BY 1,2,3,4,5;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE ADE_RENCIA AS */
/*   SELECT t1.POSICAO, */
/*          t1.prefdep, */
/*          QT_DIAS, */
/*          SUM(PONTUACAO_MAX_superv) AS PONTUACAO_MAX_superv, */
/*          SUM(PTOS_SUPERV_IND_UOR) AS PTOS_SUPERV_IND_UOR, */
/*          SUM(PTOS_SUPERV_IND_GAT) AS PTOS_SUPERV_IND_GAT, */
/*          SUM(PTOS_SUPERV_IND_BIC) AS PTOS_SUPERV_IND_BIC, */
/*          SUM(PONTUACAO_TOTAL_SUPERV) AS PONTUACAO_TOTAL_SUPERV, */
/*          SUM(PONTUACAO_MAX_ESCRIT_MES) AS PONTUACAO_MAX_ESCRIT_MES, */
/*          SUM(PTOS_ESCRIT_IND_UOR) AS PTOS_ESCRIT_IND_UOR, */
/*          SUM(PTOS_ESCRIT_IND_GAT) AS PTOS_ESCRIT_IND_GAT, */
/*          SUM(PTOS_ESCRIT_IND_BIC) AS PTOS_ESCRIT_IND_BIC, */
/*          SUM(PONTUACAO_TOTAL_ESCRIT_MES) AS PONTUACAO_TOTAL_ESCRIT_MES, */
/*          SUM(PONTUACAO_OBTIDA_AGENCIA) AS PONTUACAO_OBTIDA_AGENCIA, */
/*          SUM(PONTUACAO_MAXIMA_REGRA) AS PONTUACAO_MAXIMA_REGRA, */
/*          SUM(PERC_ATING_AGENCIA) AS  PERC_ATING_AGENCIA,*/
/*          SUM(PONTOS_ADE) AS PONTOS_ADE*/
/*      FROM WORK.ADERENCIA t1*/
/*GROUP BY 1,2,3;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE Atendimento AS */
/*		SELECT DISTINCT */
/*			'31dec2018'd  format ddmmyy10. as posicao,*/
/*			t1.PREFIXO, */
/*			t1.posicao AS DATA, */
/*			t1.LOTAC_MIN_SUPERV_SAA, */
/*			t1.LOTAC_MIN_ESCRIT_SAA, */
/*			t1.LOTAC_MIN_FUNCIS_SAA, */
/*			t1.REGRA_CALCULO_CONEXAO, */
/*			t1.QTDE_FUNCIS_LCLZ_PREF, */
/*			t1.QTDE_FUNCIS_AUSENTES_TOTAL, */
/*			round(PERC_AUSENCIAS_TOTAL*100,.01) as PERC_AUSENCIAS_TOTAL, */
/*			t1.IND_GAT_ORCADO_ADC, /**/*/
/*	t1.QT_TRAN_AGENCIA, */
/*	t1.QT_FUNCIS_RLZ_TRAN, */
/*	t1.MEDIA_TRAN_POR_FUNCI format 20.2 , */
/*	t1.QTDE_SUPERV_LCLZ_PREF, */
/*	t1.QTDE_SUPERV_TRABALHOU, */
/*	t1.QTDE_SUPERV_SAA_TRABALHOU, */
/**/
/*	t1.PTOS_SUPERV_IND_UOR, */
/*	t1.PTOS_SUPERV_IND_GAT, */
/*	t1.PTOS_SUPERV_IND_BIC, */
/*	t1.PONTUACAO_TOTAL_SUPERV_DIA, */
/*	t1.PONTUACAO_MAX_SUPERV_DIA, */
/*	t1.QTDE_ESCRIT_LCLZ_PREF, */
/*	t1.QTDE_ESCRIT_TRABALHOU, */
/*	t1.QTDE_ESCRIT_SAA_TRABALHOU, */
/**/
/*	t1.PTOS_ESCRIT_IND_UOR, */
/*	t1.PTOS_ESCRIT_IND_GAT, */
/*	t1.PTOS_ESCRIT_IND_BIC, */
/*	t1.PONTUACAO_TOTAL_ESCRIT_DIA, */
/*	t1.PONTUACAO_MAX_ESCRIT_DIA, /**/*/
/*	t1.PONTUACAO_OBTIDA_AGENCIA, */
/*	t1.PONTUACAO_MAXIMA_REGRA, */
/*	round(PERC_ATING_AGENCIA*100,.01) as PERC_ATING_AGENCIA, */
/*	t1.DESCARTAR_AUSENCIAS_TOTAL, */
/*	t1.DESCARTAR_AUSENCIA_SUPERVISOR, */
/*	t1.DESCARTAR_SEM_FUNCI_PREV_TRAB,*/
/*	t1.DESCARTAR,*/
/*	(CASE */
/*		WHEN DESCARTAR_SEM_FUNCI_PREV_TRAB=1 	THEN 'Não houve atendimento'*/
/*		WHEN DESCARTAR_AUSENCIAS_TOTAL=1 		THEN 'Ausências maior que 30%'*/
/*		/*		*/
/*		WHEN DESCARTAR_AUSENCIA_SUPERVISOR=1 	THEN 'Superv. de Atendimento ausente'*/*/
/*	end)*/
/*	as Observacao*/
/*		FROM ADE.REL_AGENCIAS_DIA_201812 t1*/
/*        where t1.PONTUACAO_OBTIDA_AGENCIA <> 0;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE detalha_funci AS */
/*   SELECT */
/*'31dec2018'd  FORMAT DDMMYY10. AS POSICAO,*/
/* t1.PREFIXO as prefdep, */
/* posicao as data,*/
/*         'F'||PUT(MATRICULA_215,Z7.) AS MATRICULA,*/
/*          t1.CD_TIP_CMSS_FUC, */
/*          t1.NM_TIP_CMSS_FUC, */
/*          t1.REGISTROU_PONTO, */
/*          t1.FUNCI_AUSENTE, */
/*          t1.EFETUADO_CALCULO_FUNCI, */
/*          t1.FUNCI_SUPERVISOR, */
/*          t1.FUNCI_ESCRITURARIO, */
/*          t1.FUNCI_ALOCADO_SAA, */
/*          t1.IND_UOR_ATINGIU, */
/*          t1.IND_UOR_PTOS, */
/*          t1.IND_GAT_TMP_ORCADO, */
/*          t1.IND_GAT_TMP_OBSERVADO, */
/*          t1.IND_GAT_QTDE_ORCADO, */
/*          t1.IND_GAT_QTDE_OBSERVADO, */
/*          t1.IND_GAT_ATINGIU, */
/*          t1.IND_GAT_PTOS, */
/*          t1.MEDIA_TRAN_POR_FUNCI, */
/*          t1.QT_TRAN_FUN, */
/*          round(IND_BIC_OBSERVADO*100,.01) as IND_BIC_OBSERVADO, */
/*          round(IND_BIC_ORCADO*100,.01) as IND_BIC_ORCADO, */
/*          t1.IND_BIC_ATINGIU, */
/*          t1.IND_BIC_PTOS, */
/*          t1.PONTUACAO_OBTIDA_FUNCI, */
/*          t1.PONTUACAO_MAXIMA_FUNCI, */
/*          round(PERC_ATING_FUNCI*100,.01) as PERC_ATING_FUNCI,*/
/*		  		       t1.DESCARTAR */
/*      FROM  ADE.BASE_FINAL_FUNCI_201812 t1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/**/
/**/
/*										/*******************/*/
/*										/*******************/*/
/*										/****	TCX  	****/*/
/*										/*******************/*/
/*										/*******************/*/
/*	*/
/*LIBNAME TCX '/dados/infor/producao/TCX_UNV';*/
/**/
/*DATA TCX_COMP;*/
/*SET TCX.TCX_SAA_201812;*/
/*RUN;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE TCX_COMP_01 AS */
/*   SELECT t1.posicao,*/
/*          t1.PREFDEP, */
/*          t1.VLR_ORC, */
/*          ifn(vlr_orc=0,150,VLR_RLZ) as VLR_RLZ, */
/*          t1.pc_atg_tcx, */
/*          IFN(VLR_ORC=0,150,PONTOS_TCX) AS PONTOS_TCX*/
/*      FROM TCX.TCX_SAA_201812 t1*/
/*LEFT JOIN work.rel_ade_01 t2 on (t1.prefdep=t2.prefdep)*/
/*GROUP BY 1;*/
/*QUIT;*/
/*PROC SORT DATA=TCX_COMP NODUPKEY; BY _ALL_; RUN;*/
/**/
/**/
/*										/*******************/*/
/*										/*******************/*/
/*										/****  NEGÓCIOS	****/*/
/*										/*******************/*/
/*										/*******************/*/
/*									*/
/*LIBNAME TRAN '/dados/infor/producao/saa';*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE NEGOCIOS AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.VL_AC_SAA, */
/*          t1.ORC_SAA, */
/*          ifn(orc_saa=0, 350, VL_M_SAA) as VL_M_SAA, */
/*          t1.PCT_ATG_RIV, */
/*          IFN(ORC_SAA=0,350,PONTOS_RIV) AS PONTOS_RIV*/
/*      FROM TRAN.NEG_SAA_201812 t1*/
/*LEFT JOIN work.rel_ade_01 t2 on (t1.prefdep=t2.prefdep)*/
/*group by 1,2;*/
/*;*/
/*QUIT;*/
/**/
/**/
/*										/*******************/*/
/*										/*******************/*/
/*										/****	DSP  	****/*/
/*										/*******************/*/
/*										/*******************/*/
/**/
/*		*/
/*LIBNAME TRAN '/dados/infor/producao/saa';*/
/*LIBNAME TCX '/dados/infor/producao/TCX_UNV';*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE DSP_COMP_01 AS */
/*   SELECT t1.POSICAO, */
/*          T2.PREFDEP, */
/*          UOR, */
/*          VLR_ORC AS ORC_DSP, */
/*          ifn(vlr_orc=0,150,VLR_RLZ)  AS RLZ_DSP, */
/*          pc_atgt_dsp, */
/*          IFN(VLR_ORC=0,150,PONTOS_DSP) AS PONTOS_DSP*/
/*      FROM TRAN.DSP_SAA_201812 t1*/
/*LEFT JOIN work.rel_ade_01 t2 on (t1.prefdep=t2.prefdep)*/
/*WHERE T2.PREFDEP NE .*/
/*GROUP BY 1,2,3;*/
/**/
/*;*/
/*QUIT;*/
/*%ZerarMissingTabela(DSP_COMP_01)*/
/**/
/**/
/**/
/**/
/**/
/**/
/**/
/**/
/*										/*******************/*/
/*										/****  JUNTA TUDO****/*/
/*										/*******************/*/
/*									*/
/**/
/*DATA IND_COMP;*/
/*MERGE ADE_RENCIA NEGOCIOS TCX_COMP DSP_COMP_01 ;*/
/*BY PREFDEP;*/
/*RUN ;*/
/*PROC SORT DATA=IND_COMP NODUPKEY; BY _ALL_; RUN;*/
/*%ZerarMissingTabela(IND_COMP)*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE PREFDEP_ORC AS */
/*		SELECT DISTINCT */
/*			'31dec2018'd  FORMAT DDMMYY10. AS  POSICAO,  */
/*			t1.prefdep, */
/*			t1.PERC_ATING_AGENCIA AS ADE_RLZD, */
/*			t1.PONTOS_ADE, */
/*			ifn(ORC_SAA=0,150,PCT_ATG_RIV) as NEG_RLZD, */
/*			ifn(orc_saa=0,150,PONTOS_RIV) AS PONTOS_NEG, */
/*			t1.PC_ATG_TCX AS TCX_RLZD,*/
/*			IFN(VLR_ORC=0,150,PONTOS_TCX) AS PONTOS_TCX, */
/*			t1.pc_atgt_dsp AS DSP_RLZD, */
/*			IFN(ORC_DSP=0,150,PONTOS_DSP) AS PONTOS_DSP*/
/*		FROM WORK.IND_COMP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			INNER JOIN work.rel_ade_01 t3 on (t1.prefdep=t3.prefdep)*/
/*				WHERE TIPODEP IN ('09' '01') AND CODSITDEP='2' AND T1.PREFDEP NE 0*/
/*					ORDER BY 2*/
/*					*/
/*	;*/
/*QUIT;*/
/*%ZerarMissingTabela(PREFDEP_orc)*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE PREFDEP AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.ADE_RLZD, */
/*          t1.PONTOS_ADE, */
/*          t1.NEG_RLZD, */
/*          t1.PONTOS_NEG, */
/*          t1.TCX_RLZD, */
/*          t1.PONTOS_TCX, */
/*          t1.DSP_RLZD, */
/*          t1.PONTOS_DSP, */
/*          (PONTOS_ADE+PONTOS_NEG+PONTOS_TCX+PONTOS_DSP) AS PONTOS_TOTAL*/
/*      FROM WORK.PREFDEP_ORC t1;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE PREFDEP AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.ADE_RLZD, */
/*          t1.PONTOS_ADE, */
/*          t1.NEG_RLZD, */
/*          t1.PONTOS_NEG, */
/*          t1.TCX_RLZD, */
/*          t1.PONTOS_TCX, */
/*          t1.DSP_RLZD, */
/*          t1.PONTOS_DSP,*/
/*		  (PONTOS_ADE+PONTOS_NEG+PONTOS_TCX+PONTOS_DSP) AS PONTOS_TOTAL*/
/*      FROM WORK.PREFDEP t1*/
/*ORDER BY 2;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SORT DATA=PREFDEP NODUPKEY; BY _ALL_; RUN;*/
/**/
/**/
/*%BuscarPrefixosAcordo(AC=2019, MMAAAA=122018, NIVEL_CTRA=0);*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.ACORDO_EXPANSAO AS */
/*   SELECT t1.AC, */
/*          t1.PREFDEP, */
/*          t1.UOR*/
/*      FROM WORK.PREFIXOS_AC t1;*/
/*QUIT;*/
/*%BuscarPrefixosAcordo(AC=2021, MMAAAA=122018, NIVEL_CTRA=0);*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.ACORDO_EXPANSAO_II AS */
/*   SELECT t1.AC, */
/*          t1.PREFDEP, */
/*          t1.UOR*/
/*      FROM WORK.PREFIXOS_AC t1;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE ACORDO_EXPANSAO AS */
/*		SELECT */
/*			**/
/*		FROM ACORDO_EXPANSAO*/
/*			UNION */
/*		SELECT */
/*			**/
/*		FROM ACORDO_EXPANSAO_II*/
/*	;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE RESULTADO_PREFIXOS AS */
/*		SELECT t1.POSICAO, */
/*			t1.PREFDEP, */
/*			350 as ADE_ORC, */
/*			t1.PONTOS_ADE, */
/*			350 as NEG_ORC,*/
/*			t1.PONTOS_NEG, */
/*			150 as TCX_ORC, */
/*			t1.PONTOS_TCX, */
/*			150 as DSP_ORC,*/
/*			t1.PONTOS_DSP, */
/*			1000 as pontos_orc, */
/*			t1.PONTOS_TOTAL*/
/*		FROM WORK.PREFDEP t1*/
/*		INNER JOIN IGR.IGRREDE T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*		LEFT JOIN ACORDO_EXPANSAO T4 ON (T1.PREFDEP=T4.PREFDEP)*/
/*		WHERE T4.AC NOT IN (2019 2021)*/
/*	;*/
/*QUIT;*/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 25/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/*%BuscarOrcado(IND=136, MMAAAA=122018);*/
/**/
/*/*CONFORME EMAIL 29/10 VINICIUS */*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE ORCADO_NOV AS */
/*   SELECT t1.IND, */
/*          t1.comp, */
/*          t1.uor, */
/*          t1.PREFDEP, */
/*          t1.CTRA, */
/*          t1.vlr_orc*0.35 AS ADE_ORC, */
/*		  t1.vlr_orc*0.35 AS NEG_ORC, */
/*		  t1.vlr_orc*0.15 AS TCX_ORC, */
/*		  t1.vlr_orc*0.15 AS DSP_ORC, */
/*          t1.vlr_mjd*/
/*      FROM WORK.ORCADOS t1*/
/*WHERE UOR NE . AND CTRA NE .;*/
/*QUIT;*/
/*%ZerarMissingTabela(ORCADO_NOV)*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE RESULTADO_DIRED AS */
/*		SELECT t1.POSICAO, */
/*			t1.PREFDEP, */
/*			ifn(t3.ADE_ORC IS MISSING,245, T3.ADE_ORC) AS ADE_ORC, */
/*			t1.PONTOS_ADE, */
/*			IFN(T3.NEG_ORC IS MISSING,350, T3.NEG_ORC) AS NEG_ORC,*/
/*			t1.PONTOS_NEG, */
/*			IFN(t3.TCX_ORC IS MISSING,150, T3.TCX_ORC) AS TCX_ORC,*/
/*			t1.PONTOS_TCX, */
/*			IFN(t3.DSP_ORC IS MISSING,150, T3.DSP_ORC) AS DSP_ORC,*/
/*			t1.PONTOS_DSP, */
/*            (ifn(t3.ADE_ORC IS MISSING,245, T3.ADE_ORC)+ IFN(T3.NEG_ORC IS MISSING,350, T3.NEG_ORC) + IFN(t3.TCX_ORC IS MISSING,150, T3.TCX_ORC) +IFN(t3.DSP_ORC IS MISSING,150, T3.DSP_ORC))*/
/*  AS PONTOS_ORC,*/
/*			t1.PONTOS_TOTAL*/
/*		FROM WORK.PREFDEP t1*/
/*		INNER JOIN IGR.IGRREDE T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*		INNER JOIN ACORDO_EXPANSAO T4 ON (T1.PREFDEP=T4.PREFDEP)*/
/*		LEFT JOIN ORCADO_NOV T3 ON (T1.PREFDEP=T3.PREFDEP)*/
/*		WHERE PREFSUPEST IN ('8515' '8508')*/
/*	;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE RESULTADO AS */
/*	SELECT * */
/*	FROM RESULTADO_PREFIXOS*/
/*	UNION */
/*	SELECT **/
/*	FROM RESULTADO_DIRED;*/
/*	QUIT;*/
/**/
/**/
/*/******************************************************************************************************************************************/*/
/**/
/**/
/*/*INDICADOR SAA - SUPER E GEREV */ */
/*/*EMAIL F8366515 - 27/07/2018 - CONEXAO SAA - METAS SUPER E GEREV*/
/**/
/*/******************************************************************************************************************************************/*/
/**/
/**/
/**/
/*/*NEG*/*/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PREFIXOS_GEREV AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_NEG*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PONTOS_GEREV AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_NEG) AS CONTA_PONTOS_NEG*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_NEG>=350 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PONTOS_GEREV_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_NEG) AS CONTA_PONTOS_NEG*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPREG,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_NEG>=T3.NEG_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PREFIXOS_SUPER AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_NEG*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PONTOS_SUPER AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_NEG) AS CONTA_PONTOS_NEG*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_NEG>=350*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/**/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PONTOS_SUPER_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_NEG) AS CONTA_PONTOS_NEG*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPEST,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_NEG>=T3.NEG_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PREFIXOS_UE AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_NEG*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NEG_PONTOS_UE AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_neg) AS CONTA_PONTOS_NEG*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0 AND PONTOS_neg>=350*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*DATA NIVEL_NEG;*/
/*	MERGE NEG_PREFIXOS_GEREV NEG_PONTOS_GEREV NEG_PONTOS_GEREV_NOVO_PADRAO NEG_PREFIXOS_SUPER NEG_PONTOS_SUPER NEG_PREFIXOS_UE NEG_PONTOS_UE NEG_PONTOS_SUPER_NOVO_PADRAO;*/
/*	BY PREFIXO;*/
/*RUN;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NIVEL_01_NEG AS */
/*		SELECT  */
/*			t1.PREFIXO, */
/*			t1.TT_PREFDEP_NEG, */
/*			t1.CONTA_PONTOS_NEG,*/
/*			(CONTA_PONTOS_NEG/TT_PREFDEP_NEG)*100 AS PC_ATGT_SUPER_NEG*/
/*		FROM WORK.NIVEL_NEG t1;*/
/*QUIT;*/
/**/
/**/
/*data REGUA_SUPER_NEG;*/
/*	infile DATALINES dsd missover;*/
/*	input Inferior Superior Pontos;*/
/*	format Inferior Superior 32.4;*/
/*	CARDS;*/
/*98.00,	100.00,	1500*/
/*94.00,	97.99,	1400*/
/*89.00,	93.99,	1300*/
/*85.00,	88.99,	1200*/
/*83.00,	84.99,	1100*/
/*80.00,	82.99,	1000*/
/*75.00,	79.99,	900*/
/*70.00,	74.99,	800*/
/*65.00,	69.99,	700*/
/*60.00,	64.99,	600*/
/*55.00,	59.99,	500*/
/*50.00,	54.99,	400*/
/*45.00,	49.99,	300*/
/*40.00,	44.99,	200*/
/*35.00,	39.99,	100*/
/*0.00,	34.99,	0*/
/*;*/
/*run;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NIVEL_02_NEG AS */
/*		SELECT */
/*			t1.PREFIXO AS PREFDEP, */
/*			t1.TT_PREFDEP_NEG AS NEG_ORC, */
/*			t1.CONTA_PONTOS_NEG AS NEG_RLZD,*/
/*			(T2.PONTOS*0.35) AS PONTOS_NEG*/
/*		FROM WORK.NIVEL_01_NEG t1*/
/*			INNER JOIN REGUA_SUPER_NEG T2 ON (PC_ATGT_SUPER_NEG BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*order by 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*/*DSP*/*/
/*/*SUPER E GEREV */*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PREFIXOS_GEREV AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_DSP*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PONTOS_GEREV AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_DSP) AS CONTA_PONTOS_DSP*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_DSP>=150 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PONTOS_GEREV_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_DSP) AS CONTA_PONTOS_DSP*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPREG,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_DSP>=T3.DSP_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PREFIXOS_SUPER AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_DSP*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PONTOS_SUPER AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_DSP) AS CONTA_PONTOS_DSP*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_DSP>=150 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PONTOS_SUPER_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_DSP) AS CONTA_PONTOS_DSP*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPEST,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_DSP>=T3.DSP_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PREFIXOS_UE AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_DSP*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DSP_PONTOS_UE AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_DSP) AS CONTA_PONTOS_DSP*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0 AND PONTOS_DSP>=150*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*DATA NIVEL_DSP;*/
/*	MERGE DSP_PREFIXOS_GEREV DSP_PONTOS_GEREV DSP_PONTOS_GEREV_NOVO_PADRAO DSP_PREFIXOS_SUPER DSP_PONTOS_SUPER DSP_PONTOS_SUPER_NOVO_PADRAO DSP_PREFIXOS_UE DSP_PONTOS_UE;*/
/*	BY PREFIXO;*/
/*RUN;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE NIVEL_01_DSP AS */
/*   SELECT */
/*          t1.PREFIXO, */
/*          t1.TT_PREFDEP_DSP, */
/*          t1.CONTA_PONTOS_DSP,*/
/*		  (CONTA_PONTOS_DSP/TT_PREFDEP_DSP)*100 AS PC_ATGT_SUPER_DSP*/
/*      FROM WORK.NIVEL_DSP t1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*data REGUA_SUPER_DSP;*/
/*infile DATALINES dsd missover;*/
/*input Inferior Superior Pontos;*/
/*format Inferior Superior 32.4;*/
/*CARDS;*/
/*98.00,	100.00,	1500*/
/*94.00,	97.99,	1400*/
/*89.00,	93.99,	1300*/
/*85.00,	88.99,	1200*/
/*83.00,	84.99,	1100*/
/*80.00,	82.99,	1000*/
/*75.00,	79.99,	900*/
/*70.00,	74.99,	800*/
/*65.00,	69.99,	700*/
/*60.00,	64.99,	600*/
/*55.00,	59.99,	500*/
/*50.00,	54.99,	400*/
/*45.00,	49.99,	300*/
/*40.00,	44.99,	200*/
/*35.00,	39.99,	100*/
/*0.00,	34.99,	0*/
/*;*/
/*run;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NIVEL_02_DSP AS */
/*		SELECT */
/*			t1.PREFIXO AS PREFDEP, */
/*			t1.TT_PREFDEP_DSP AS DSP_ORC, */
/*			t1.CONTA_PONTOS_DSP AS DSP_RLZD, */
/*	(T2.PONTOS*0.15) AS PONTOS_DSP*/
/*		FROM WORK.NIVEL_01_DSP t1*/
/*			INNER JOIN REGUA_SUPER_DSP T2 ON (PC_ATGT_SUPER_DSP BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*			order by 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/**/
/*/*TCX*/*/
/*/*SUPER E GEREV */*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PREFIXOS_GEREV AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_TCX*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PONTOS_GEREV AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_TCX) AS CONTA_PONTOS_TCX*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_TCX>=150 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PONTOS_GEREV_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_TCX) AS CONTA_PONTOS_TCX*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPREG,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_TCX>=T3.TCX_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PREFIXOS_SUPER AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_TCX*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PONTOS_SUPER AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_TCX) AS CONTA_PONTOS_TCX*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_TCX>=150 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PONTOS_SUPER_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_TCX) AS CONTA_PONTOS_TCX*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPEST,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_TCX>=T3.TCX_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PREFIXOS_UE AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_TCX*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE TCX_PONTOS_UE AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_TCX) AS CONTA_PONTOS_TCX*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0 AND PONTOS_TCX>=150*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*DATA NIVEL_TCX;*/
/*	MERGE TCX_PREFIXOS_GEREV TCX_PONTOS_GEREV TCX_PONTOS_GEREV_NOVO_PADRAO TCX_PREFIXOS_SUPER TCX_PONTOS_SUPER TCX_PONTOS_SUPER_NOVO_PADRAO TCX_PREFIXOS_UE TCX_PONTOS_UE;*/
/*	BY PREFIXO;*/
/*RUN;*/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE NIVEL_1_TCX AS */
/*   SELECT */
/*          t1.PREFIXO, */
/*          t1.TT_PREFDEP_TCX, */
/*          t1.CONTA_PONTOS_TCX,*/
/*(CONTA_PONTOS_TCX/TT_PREFDEP_TCX)*100 AS PC_ATGT_SUPER_TCX*/
/*      FROM WORK.NIVEL_TCX t1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/**/
/*data REGUA_SUPER_TCX;*/
/*infile DATALINES dsd missover;*/
/*input Inferior Superior Pontos;*/
/*format Inferior Superior 32.4;*/
/*CARDS;*/
/*98.00,	100.00,	1500*/
/*94.00,	97.99,	1400*/
/*89.00,	93.99,	1300*/
/*85.00,	88.99,	1200*/
/*83.00,	84.99,	1100*/
/*80.00,	82.99,	1000*/
/*75.00,	79.99,	900*/
/*70.00,	74.99,	800*/
/*65.00,	69.99,	700*/
/*60.00,	64.99,	600*/
/*55.00,	59.99,	500*/
/*50.00,	54.99,	400*/
/*45.00,	49.99,	300*/
/*40.00,	44.99,	200*/
/*35.00,	39.99,	100*/
/*0.00,	34.99,	0*/
/*;*/
/*run;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE NIVEL_02_TCX AS */
/*   SELECT  */
/*          t1.PREFIXO AS PREFDEP, */
/*          t1.TT_PREFDEP_TCX AS TCX_ORC, */
/*          t1.CONTA_PONTOS_TCX AS TCX_RLZD, */
/*		  (T2.PONTOS*0.15) AS PONTOS_TCX*/
/*      FROM WORK.NIVEL_1_TCX t1*/
/*INNER JOIN REGUA_SUPER_TCX T2 ON (PC_ATGT_SUPER_TCX BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*GROUP BY 1*/
/*order by 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*/*ADERENCIA*/*/
/*/*SUPER E GEREV */*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE GEREV_PREFIXOS AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_ADE*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE GEREV_PONTOS AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_ADE) AS CONTA_PONTOS_ADE*/
/*		FROM WORK.PREFDEP  t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_ADE>=350 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE ADE_PONTOS_GEREV_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPREG,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_ADE) AS CONTA_PONTOS_ADE*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPREG,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPREG,4.) NE 0 AND PONTOS_ADE>=T3.ADE_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SUPER_PREFIXOS AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_ADE*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SUPER_PONTOS AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_ADE) AS CONTA_PONTOS_ADE*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_ADE>=350 AND PREFSUPEST NOT IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*/*********************************************************************************************/*/
/*/*CONFORME EMAIL RECEBIDO DIA 28/09 F9540874 Vinícius Dired - Orçamento SAA - Novo Padrão (UNV)*/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE ADE_PONTOS_SUPER_NOVO_PADRAO AS */
/*		SELECT */
/*			INPUT(PREFSUPEST,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_ADE) AS CONTA_PONTOS_ADE*/
/*		FROM WORK.RESULTADO t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN ORCADO_NOV T3 ON (INPUT(T2.PREFSUPEST,4.)=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFSUPEST,4.) NE 0 AND PONTOS_ADE>=T3.ADE_ORC AND PREFSUPEST IN ('8515' '8508')*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/*/************************************************************************************************/*/
/**/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DIR_PREFIXOS AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PREFDEP) AS TT_PREFDEP_ADE*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DIR_PONTOS AS */
/*		SELECT */
/*			INPUT(PREFUEN,4.) AS PREFIXO, */
/*			COUNT(T1.PONTOS_ADE) AS CONTA_PONTOS_ADE*/
/*		FROM WORK.PREFDEP t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*				WHERE CODSITDEP='2' AND INPUT(PREFUEN,4.) NE 0 AND PONTOS_ADE>=350*/
/*					GROUP BY 1*/
/*						ORDER BY 1;*/
/*QUIT;*/
/**/
/**/
/*DATA NIVEL_SUPERIOR;*/
/*	MERGE GEREV_PREFIXOS GEREV_PONTOS  ADE_PONTOS_GEREV_NOVO_PADRAO SUPER_PREFIXOS SUPER_PONTOS ADE_PONTOS_SUPER_NOVO_PADRAO DIR_PREFIXOS DIR_PONTOS;*/
/*	BY PREFIXO;*/
/*RUN;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE NIVEL_01 AS */
/*		SELECT  */
/*			t1.PREFIXO, */
/*			t1.TT_PREFDEP_ADE, */
/*			t1.CONTA_PONTOS_ADE,*/
/*			(CONTA_PONTOS_ADE/TT_PREFDEP_ADE)*100 AS PC_ATGT_NIVELS_ADE*/
/*		FROM WORK.NIVEL_SUPERIOR t1;*/
/*QUIT;*/
/*%ZerarMissingTabela(NIVEL_01)*/
/**/
/**/
/**/
/**/
/*data REGUA_SUPER_ADERENCIA;*/
/*infile DATALINES dsd missover;*/
/*input Inferior Superior Pontos;*/
/*format Inferior Superior 32.4;*/
/*CARDS;*/
/*98.00,	100.00,	1500*/
/*94.00,	97.99,	1400*/
/*89.00,	93.99,	1300*/
/*85.00,	88.99,	1200*/
/*83.00,	84.99,	1100*/
/*80.00,	82.99,	1000*/
/*75.00,	79.99,	900*/
/*70.00,	74.99,	800*/
/*65.00,	69.99,	700*/
/*60.00,	64.99,	600*/
/*55.00,	59.99,	500*/
/*50.00,	54.99,	400*/
/*45.00,	49.99,	300*/
/*40.00,	44.99,	200*/
/*35.00,	39.99,	100*/
/*0.00,	34.99,	0*/
/*;*/
/*run;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE NIVEL_02_ADE AS */
/*   SELECT */
/*          t1.PREFIXO as PREFDEP, */
/*          t1.TT_PREFDEP_ADE AS ADE_ORC, */
/*          t1.CONTA_PONTOS_ADE AS ADE_RLZD, */
/*		  (T2.PONTOS)*0.35 AS PONTOS_ADE*/
/*      FROM WORK.NIVEL_01 t1*/
/*LEFT JOIN REGUA_SUPER_ADERENCIA T2 ON (PC_ATGT_NIVELS_ADE BETWEEN T2.INFERIOR AND T2.SUPERIOR)*/
/*order by 1*/
/*;*/
/*QUIT;*/
/**/
/**/
/**/
/*DATA JUNTA_DIR;*/
/*MERGE NIVEL_02_ADE NIVEL_02_NEG NIVEL_02_TCX NIVEL_02_DSP;*/
/*BY PREFDEP;*/
/*RUN;*/
/*%ZerarMissingTabela(JUNTA_DIR)*/
/**/
/**/
/**/
/**/
/**/
/**/
/*/*ACORDOS SUPER GEREV - DIRED E DISUD - VAREJO EXPANSÃO*/*/
/**/
/*%BuscarPrefixosAcordo (AC=2008, MMAAAA=122018, NIVEL_CTRA=0);*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE SUPERS AS */
/*   SELECT DISTINCT*/
/*          t1.PREFDEP, */
/*		  T1.AC*/
/*      FROM WORK.PREFIXOS_AC t1*/
/*WHERE AC=2008;*/
/*QUIT;*/
/**/
/*%BuscarPrefixosAcordo(AC=2009, MMAAAA=122018, NIVEL_CTRA=0);*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.GEREV_DF AS */
/*   SELECT DISTINCT*/
/*          t1.PREFDEP,*/
/*		  T1.AC*/
/*      FROM WORK.PREFIXOS_AC t1*/
/*	  WHERE AC=2009;*/
/*QUIT;*/
/**/
/*%BuscarPrefixosAcordo(AC=2013, MMAAAA=122018, NIVEL_CTRA=0);*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.GEREV_SP AS */
/*   SELECT t1.PREFDEP,*/
/*    T1.AC*/
/*      FROM WORK.PREFIXOS_AC t1*/
/*WHERE AC=2013;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE DIR_EXPANSAO AS */
/*		SELECT */
/*			**/
/*		FROM SUPERS*/
/*			UNION */
/*		SELECT */
/*			**/
/*		FROM GEREV_DF*/
/*			UNION*/
/*		SELECT */
/*			**/
/*		FROM GEREV_SP*/
/*		group by 1*/
/*	;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE JUNTA_DIR_00 AS */
/*		SELECT */
/*			t1.PREFDEP, */
/*			350 as ADE_ORC, */
/*			t1.PONTOS_ADE, */
/*			350 AS NEG_ORC,*/
/*			PONTOS_NEG, */
/*			150 AS TCX_ORC,*/
/*			PONTOS_TCX, */
/*			150 AS DSP_ORC,*/
/*			PONTOS_DSP,*/
/*			1000 as pontos_orc, */
/*			(pontos_ade+pontos_neg+pontos_tcx+pontos_dsp) as PONTOS_TOTAL*/
/*		FROM WORK.JUNTA_DIR t1*/
/*			INNER JOIN IGR.IGRREDE_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			LEFT JOIN DIR_EXPANSAO T3 ON (T1.PREFDEP=T3.PREFDEP)*/
/*				WHERE CODSITDEP='2' AND AC NOT IN (2008 2009 2013)*/
/*				group by 1*/
/*				ORDER BY 1*/
/*	;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE JUNTA_DIR_01 AS */
/*		SELECT DISTINCT*/
/*			t1.PREFDEP, */
/*			t2.ADE_ORC,*/
/*			t1.PONTOS_ADE, */
/*			t2.NEG_ORC,*/
/*			PONTOS_NEG, */
/*			T2.TCX_ORC,*/
/*			PONTOS_TCX, */
/*			T2.DSP_ORC,*/
/*			PONTOS_DSP, */
/*			(T2.ADE_ORC+T2.NEG_ORC+T2.TCX_ORC+T2.DSP_ORC) AS PONTOS_ORC,*/
/*			(pontos_ade+pontos_neg+pontos_tcx+pontos_dsp) as PONTOS_TOTAL*/
/*		FROM WORK.JUNTA_DIR t1*/
/*		    INNER JOIN ORCADO_NOV T2 ON (T1.PREFDEP=T2.PREFDEP)*/
/*			INNER JOIN DIR_EXPANSAO T3 ON (T1.PREFDEP=T3.PREFDEP)*/
/*			GROUP BY 1*/
/*			ORDER BY 1*/
/*        ;*/
/*QUIT;*/
/**/
/*DATA JUNTA_PREFDEP;*/
/*MERGE RESULTADO JUNTA_DIR_00 JUNTA_DIR_01;*/
/*BY PREFDEP;*/
/*RUN;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.RELATORIO AS */
/*   SELECT '31dec2018'd  FORMAT DDMMYY10. AS POSICAO,*/
/*          t1.PREFDEP, */
/*          t1.ADE_ORC, */
/*          t1.PONTOS_ADE, */
/*          t1.NEG_ORC, */
/*          t1.PONTOS_NEG, */
/*          t1.TCX_ORC, */
/*          t1.PONTOS_TCX, */
/*          t1.DSP_ORC, */
/*          t1.PONTOS_DSP, */
/*          t1.pontos_orc, */
/*          t1.PONTOS_TOTAL*/
/*      FROM WORK.JUNTA_PREFDEP t1;*/
/*	  QUIT;*/
/*/**/*/
/*/**/*/
/*/*data ADE.RELATORIO_201812;*/*/
/*/*SET RELATORIO;*/*/
/*/*RUN;*/*/
/**/
/**/
/**/
/**/
/**/
/**/
/**/
/**/
/*/*														CONEXÃO DIRED E DISUD							*/*/
/**/
/**/
/**/
/**/
/*/*	  ACORDOS EXPANSAO */*/
/**/
/*	 DATA JUNTA_ACORDO;*/
/*	SET ACORDO_EXPANSAO DIR_EXPANSAO;*/
/*RUN;*/
/**/
/**/
/*%BuscarOrcado(IND=98, MMAAAA=122018);*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.DADOS_PARA_CONEXAO AS */
/*   SELECT t1.POSICAO, */
/*          98 AS IND,*/
/*          t1.PREFDEP, */
/*          t1.ADE_ORC, */
/*          t1.PONTOS_ADE, */
/*          t1.NEG_ORC, */
/*          t1.PONTOS_NEG, */
/*          t1.TCX_ORC, */
/*          t1.PONTOS_TCX, */
/*          t1.DSP_ORC, */
/*          t1.PONTOS_DSP, */
/*          t1.pontos_orc, */
/*          t1.PONTOS_TOTAL*/
/*      FROM WORK.RELATORIO t1*/
/*inner join igr.igrrede t2 on (t1.prefdep=input(t2.prefdep, 4.))*/
/*LEFT JOIN JUNTA_ACORDO T3 ON (t1.prefdep=t3.prefdep)*/
/*where t3.ac not in (2019 2021 2013 2009 2008) AND T2.PREFUEN NE '9500'*/
/*; QUIT;*/
/**/
/**/
/*%ZerarMissingTabela(DADOS_PARA_CONEXAO)*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE PARA_BASE_CONEXAO AS */
/*		SELECT */
/*			000000098 AS IND, /*CODIGO INDICADOR*/*/
/*	0 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_TOTAL AS VLR_RLZ,*/
/*	pontos_orc AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.ORCADO AS */
/*   SELECT t1.ind,*/
/*            t1.comp,*/
/*            t1.uor,*/
/*            t1.prefdep,*/
/*            t1.ctra,*/
/*            VLR_ORC AS vlr,*/
/*          	input(PUT(POSICAO, mmyyn6.),6.)  as mmaaaa*/
/*      FROM WORK.PARA_BASE_CONEXAO t1*/
/*WHERE IND=98;*/
/*QUIT;*/
/*%BASE_IND_ORC(TabelaSAS=ORCADO);*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_ADE AS */
/*		SELECT */
/*			000000098 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	1 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	1 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_ADE AS VLR_RLZ,*/
/*	ADE_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_NEG AS */
/*		SELECT */
/*			000000098 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	2 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	2 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_NEG AS VLR_RLZ,*/
/*	NEG_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_TCX AS */
/*		SELECT */
/*			000000098 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	3 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	3 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_TCX AS VLR_RLZ,*/
/*	TCX_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_DSP AS */
/*		SELECT */
/*			000000098 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	4 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	4 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_DSP AS VLR_RLZ,*/
/*	DSP_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/**/
/*%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_ADE);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_NEG);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_TCX);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_DSP);*/
/**/
/**/
/**/
/*%ExportarCNX_IND(IND=000000098, MMAAAA=122018);*/
/*%ExportarCNX_COMP(IND=000000098, MMAAAA=122018);*/
/**/
/**/
/**/
/**/
/**/
/*/*														CONEXÃO UNV	E SUPER 8515 E 8508	- VAREJO EXPANSAO							*/*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.DADOS_PARA_CONEXAO_UNV AS */
/*   SELECT t1.POSICAO, */
/*          t1.PREFDEP, */
/*          t1.ADE_ORC, */
/*          t1.PONTOS_ADE, */
/*          t1.NEG_ORC, */
/*          t1.PONTOS_NEG, */
/*          t1.TCX_ORC, */
/*          t1.PONTOS_TCX, */
/*          t1.DSP_ORC, */
/*          t1.PONTOS_DSP,*/
/*          t1.pontos_orc, */
/*          ifn(T1.ade_orc=0,0,T1.PONTOS_TOTAL) as PONTOS_TOTAL*/
/*      FROM WORK.RELATORIO t1*/
/*inner join igr.igrrede t2 on (t1.prefdep=input(t2.prefdep, 4.))*/
/*LEFT JOIN DADOS_PARA_CONEXAO T3 ON (T1.PREFDEP=T3.PREFDEP)*/
/*where T2.PREFUEN IN ('9500' '8592' '8477') AND t2.PREFSUPEST IN ('8515' '8508' '9800') AND T3.IND NE 98*/
/*;*/
/*; QUIT;*/
/**/
/*%ZerarMissingTabela(DADOS_PARA_CONEXAO_UNV)*/
/**/
/*%BuscarOrcado(IND=136, MMAAAA=122018);*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.DADOS_PARA_CONEXAO_UNV AS */
/*   SELECT '31dec2018'd  FORMAT DDMMYY10. AS POSICAO,*/
/*          t2.PREFDEP, */
/*          t1.ADE_ORC, */
/*          t1.PONTOS_ADE, */
/*          t1.NEG_ORC, */
/*          t1.PONTOS_NEG, */
/*          t1.TCX_ORC, */
/*          t1.PONTOS_TCX, */
/*          t1.DSP_ORC, */
/*          t1.PONTOS_DSP,*/
/*          t2.vlr_orc, */
/*          ifn( pontos_total=., 0, pontos_orc) as pontos_orc, */
/*          t1.PONTOS_TOTAL*/
/*      FROM WORK.DADOS_PARA_CONEXAO_UNV t1*/
/*right join ORCADOS t2 on (t1.prefdep=t2.prefdep);*/
/*QUIT;*/
/*%ZerarMissingTabela(DADOS_PARA_CONEXAO_UNV)*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE PARA_BASE_CONEXAO_UNV AS */
/*		SELECT */
/*			000000136 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	0 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_total FORMAT 19.2 AS VLR_RLZ,*/
/*	pontos_orc as vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO_UNV t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.ORCADO_UNV AS */
/*   SELECT t1.ind,*/
/*            t1.comp,*/
/*            t1.uor,*/
/*            t1.prefdep,*/
/*            t1.ctra,*/
/*            t1.vlr_orc AS vlr,*/
/*          	input(PUT(POSICAO, mmyyn6.),6.)  as mmaaaa*/
/*      FROM WORK.PARA_BASE_CONEXAO_UNV t1*/
/*WHERE IND=136;*/
/*QUIT;*/
/*%BASE_IND_ORC(TabelaSAS=ORCADO_UNV);*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_ADE_UNV AS */
/*		SELECT */
/*			000000136 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	1 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	1 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_ADE AS VLR_RLZ,*/
/*	ADE_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO_UNV t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_NEG_UNV AS */
/*		SELECT */
/*			000000136 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	2 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	2 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_neg AS VLR_RLZ,*/
/*	NEG_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO_UNV t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_TCX_UNV AS */
/*		SELECT */
/*			000000136 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	3 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	3 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_TCX AS VLR_RLZ,*/
/*	TCX_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO_UNV t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE BASE_CONEXAO_DSP_UNV AS */
/*		SELECT */
/*			000000136 AS IND, /*CODIGO INDICADOR*/*/
/**/
/*	4 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 AS COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	4 AS ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	INPUT(t2.uor, 9.) AS UOR, */
/*	T1.PREFDEP,*/
/*	0 as ctra, */
/*	PONTOS_DSP AS VLR_RLZ,*/
/*	DSP_ORC AS vlr_orc,*/
/*	0 AS VLR_ATG,*/
/*	t1.POSICAO FORMAT=mmyyn6. as POSICAO */
/*	FROM WORK.DADOS_PARA_CONEXAO_UNV t1*/
/*		INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))*/
/*			WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/**/
/*%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO_UNV);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_ADE_UNV);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_NEG_UNV);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_TCX_UNV);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO_DSP_UNV);*/
/**/
/**/
/**/
/*%ExportarCNX_IND(IND=000000136, MMAAAA=122018);*/
/*%ExportarCNX_COMP(IND=000000136, MMAAAA=122018);*/
/**/
/**/
/**/
/**/
/**/
/*/*MEDIA*/*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE VL_APRD_IN_MBZ_MM AS */
/*   SELECT t1.CD_UOR_CTRA, */
/*          t1.NR_SEQL_CTRA, */
/*          t1.AA_APRC, */
/*          t1.MM_APRC, */
/*          t1.VL_META_IN_MBZ, */
/*          t1.VL_RLZD_IN_MBZ, */
/*          t1.PC_ATGT_IN_MBZ, */
/*          t1.QT_PTO_IN_MBZ, */
/*          t1.QT_PTO_IN_MBZ_MED*/
/*      FROM DB2ATB.VL_APRD_IN_MBZ_MM t1*/
/*      WHERE AA_APRC=2018 AND MM_APRC>=7 AND t1.CD_IN_MBZ IN (136,98);*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*	CREATE TABLE SAA_DETALHA_PONTOS AS */
/*		SELECT DISTINCT */
/*			INPUT(T2.PREFDEP,4.) AS PREFDEP,*/
/*			t1.MM_APRC, */
/*			t1.VL_META_IN_MBZ, */
/*			t1.VL_RLZD_IN_MBZ, */
/*			t1.PC_ATGT_IN_MBZ, */
/*			t1.QT_PTO_IN_MBZ, */
/*			t1.QT_PTO_IN_MBZ_MED*/
/*		FROM WORK.VL_APRD_IN_MBZ_MM t1*/
/*			INNER JOIN IGR.DEPENDENCIAS_201812 T2 ON (T1.CD_UOR_CTRA=INPUT(t2.uor, 9.))*/
/*				WHERE T2.SB='00' AND T2.STATUS= 'A';*/
/*QUIT;*/
/**/
/**/
/**/
/**/
/**/
/*/* RELATÓRIO 00257 */*/
/**/
/*%LET Usuario=f9457977;*/
/*%LET Keypass=SIWsl7V2YNui8lNOxiTTE02GzQaCJqh52B75c9OTk8RQjTUSeD;*/
/*%LET Rotina=cnx-saa-unv;*/
/**/
/*PROC SQL;*/
/*DROP TABLE TABELAS_EXPORTAR_REL;*/
/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('relatorio', 'cnx-saa-unv');*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('saa_detalha_pontos', 'pontos-saa');*/
/*QUIT;*/
/**/
/*%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL); */
/**/
/**/
/**/
/*/* RELATÓRIO 00321 */*/
/**/
/*%LET Usuario=f9457977;*/
/*%LET Keypass=ym4XcQLCtvCHn36NgpQ4Cd8ojT3EwzJQ8ROdBdNu2LEup3FOu0;*/
/*%LET Rotina=aderencia-2s2018;*/
/**/
/*PROC SQL;*/
/*DROP TABLE TABELAS_EXPORTAR_REL;*/
/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('ade_rencia', 'aderencia-2s2018');*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('atendimento', 'detalhar-prefixo');*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('detalha_funci', 'detalhar-funcionarios');*/
/*QUIT;*/
/**/
/*%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);*/
/**/
/**/
/**/
/**/
/**/
/**/
/*/* RELATÓRIO 279 */*/
/**/
/*%LET Usuario=f9457977;*/
/*%LET Keypass=lamRISgRPpy1CdCCeDuq5Q3T9jzvPFvOclCGIUHIhLe79v7wNY;*/
/*%LET Rotina=riv-unv;*/
/**/
/**/
/*DATA DETALHA;*/
/*set tran.detalhe;*/
/*run;*/
/**/
/**/
/*data RIV_SAA;*/
/*set tran.neg_saa_201812;*/
/*run;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*DROP TABLE TABELAS_EXPORTAR_REL;*/
/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('riv_saa', 'riv-unv');*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('detalha', 'detalhe');*/
/*QUIT;*/
/**/
/**/
/*%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);  */
/**/
/**/
/**/
/*/*ADICIONANDO DETALHE POR SUPER*/*/
/**/
/**/
/*PROC SQL;*/
/**/
/*CREATE TABLE WORK.PREF_SUPER AS SELECT*/
/*DISTINCT input(PrefDep, 4.) AS PrefDep, PrefSuper*/
/*FROM COMUM.DEPENDENCIAS*/
/*WHERE SB = '00'*/
/*order by PrefDep;*/
/**/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/**/
/*create table DETALHA_2 AS SELECT **/
/*FROM DETALHA*/
/*order by PrefDep;*/
/*run;*/
/**/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/**/
/*CREATE TABLE work.DETALHE_SUPER_279 AS SELECT **/
/*FROM DETALHA_2 t1*/
/*LEFT JOIN WORK.PREF_SUPER t2 ON t1.PrefDep = t2.PrefDep*/
/*group by t1.prefdep;*/
/**/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/**/
/*CREATE TABLE DET_SUP.DETALHE_SUPER_279 AS SELECT **/
/*FROM work.DETALHE_SUPER_279;*/
/**/
/*QUIT;*/
/**/
/**/
/*/*FIM-FIM-FIM-FIM-FIM-FIM-FIM-FIM*/*/
/**/
/**/
/**/
/**/
/* /*Relatório 274  9h*/*/
/**/
/*%LET Usuario=f9457977;*/
/*%LET Keypass=8eb9yuYZoPVUp1fY8pd4gjXU6DvZ8BgErm6GouHeRnxknMV0Ww;*/
/*%LET Rotina=tcx-unv;*/
/**/
/*DATA TCX_SAA;*/
/*SET tcx.TCX_TT_201812;*/
/*RUN;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*DROP TABLE TABELAS_EXPORTAR_REL;*/
/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('tcx_saa', 'tcx-unv');*/
/*QUIT;*/
/**/
/*%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);*/
/**/
/**/
/**/
/**/
/**/
/**/
/*/*Relatório 275  9h*/*/
/**/
/*%LET Usuario=f9457977;*/
/*%LET Keypass=67zLPZQTxCxj22lEwFK9FFYd6kCidvIcLLIiWKzpc3XKOPWLJN;*/
/*%LET Rotina=dsp-unv;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE RESULTADO_FINAL AS */
/*		SELECT t1.posicao, */
/*			t1.PREFDEP, */
/*			t1.UOR, */
/*			t1.VLR_ORC, */
/*			t1.VLR_RLZ, */
/*			t1.pc_atgt_dsp, */
/*			t1.PONTOS_DSP*/
/*		FROM tran.DSP_SAA_201812 t1;*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*DROP TABLE TABELAS_EXPORTAR_REL;*/
/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('resultado_final', 'dsp-unv');*/
/*QUIT;*/
/**/
/*%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);*/
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
