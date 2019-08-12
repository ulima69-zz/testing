/*#################################################################################################################*/
/************** INICIAR PROCESSO ****************/
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';
%LET Keypass=carteiras-a5f93337-7003-469a-a29c-319ada9dd782;
%ProcessoIniciar();
/************************************************/



LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;


/*CONTROLE DE DATAS*/
DATA _NULL_;
	DT_REF = diaUtilAnterior(TODAY());
/*	DT_REF = diaUtilAnterior(MDY(02,01,2018));*/

	DT_ANT = ultimoDiaMes(intnx('month',primeiroDiaMes(DT_REF),-1));

	AAAAMM = Put(DT_REF, yymmn6.);
	AAAAMM_ANT = Put(DT_ANT, yymmn6.);

	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('AAAAMM_ANT',COMPRESS(AAAAMM_ANT,' '));
RUN; 

%put &AAAAMM.;
%put &AAAAMM_ANT.;



PROC SQL;
	CREATE TABLE WORK.CARTEIRAS_TODAS AS 
		SELECT DISTINCT 
			t1.CD_PRF_DEPE AS PREFIXO,
			t1.NR_SEQL_CTRA AS CTRA,
			t1.CD_TIP_CTRA AS TP_CTRA,
			t1.IN_FRMC_CTRA AS ST_CTRA,
			IFN(t1.NR_MTC_ADM_CTRA=0, ., t1.NR_MTC_ADM_CTRA) AS ADM_CTRA,
			IFN(INPUT(t1.NM_OTR_RSP, 7.)=0, ., INPUT(t1.NM_OTR_RSP, 7.)) AS CO_RESP_CTRA,
			IFN(t1.NR_MTC_ADM_NEG=0, ., t1.NR_MTC_ADM_NEG) AS ASSIS_CTR
		FROM DB2REL.CTRA_CLI t1
;QUIT;


PROC SQL;
	CREATE TABLE WORK.CARTEIRAS_TODAS AS 
		SELECT 
			t1.PREFIXO, 
			t1.CTRA, 
			t1.TP_CTRA, 
			t1.ST_CTRA,
 			IFC(t1.ADM_CTRA=., '', 'F'||COMPRESS(PUT(t1.ADM_CTRA,Z7.))) AS ADM_CTRA,
			IFC(t1.CO_RESP_CTRA=., '', 'F'||COMPRESS(PUT(t1.CO_RESP_CTRA,Z7.))) AS CO_RESP_CTRA,
			IFC(t1.ASSIS_CTR=., '', 'F'||COMPRESS(PUT(t1.ASSIS_CTR,Z7.))) AS ASSIS_CTR
		FROM WORK.CARTEIRAS_TODAS t1
		ORDER BY 1,2,3
;QUIT;


/*ADICIONAR AS CARTEIRAS 7002*/
PROC SQL;
	CREATE TABLE WORK.CART_7002 AS 
		SELECT DISTINCT 
			t1.PREFIXO,
			7002 AS CTRA,
			700 AS TP_CTRA,
			'G' AS ST_CTRA,
			7002 AS CTRA_ATB
		FROM WORK.CARTEIRAS_TODAS t1
		ORDER BY 1,2,3
;QUIT;


DATA CARTEIRAS_TODAS;
	MERGE CARTEIRAS_TODAS CART_7002;
	BY PREFIXO CTRA TP_CTRA;
RUN;



PROC SQL;
	CREATE TABLE WORK.CARTEIRAS_PAI_REL AS 
		SELECT DISTINCT 
			t1.CD_PRF_DEPE AS PREFIXO, 
			t1.NR_SEQL_CTRA AS CTRA,
			t1.CD_TIP_CTRA AS TP_CTRA, 
			t1.NR_SEQL_CTRA_ATB AS CTRA_ATB
		FROM COMUM.PAI_REL_&AAAAMM. t1
		WHERE t1.CD_PRF_DEPE IS NOT MISSING
		ORDER BY 1,2,3
;QUIT;


DATA CARTEIRAS;
	MERGE CARTEIRAS_TODAS CARTEIRAS_PAI_REL;
	BY PREFIXO CTRA TP_CTRA;
RUN;


PROC SQL;
	CREATE TABLE WORK.CARTEIRAS AS 
		SELECT
			TODAY() FORMAT=DateMysql. AS POSICAO, 
			t1.PREFIXO, 
			t1.CTRA, 
			t1.TP_CTRA,
			t1.CTRA_ATB, 
			t1.ST_CTRA, 
			t1.ADM_CTRA, 
			t1.CO_RESP_CTRA, 
			t1.ASSIS_CTR
		FROM WORK.CARTEIRAS t1
;QUIT;

PROC SQL;
	CREATE TABLE TIP_CTRA AS 
		SELECT 
			TODAY() FORMAT=DateMysql. AS POSICAO,
			t1.CD_TIP_CTRA, 
			t1.NM_TIP_CTRA
		FROM DB2REL.TIP_CTRA t1
;QUIT;





/*#################################################################################################################*/
/*#################################################################################################################*/
/*EXPORTAR REL*/
/*#################################################################################################################*/

/*TABELA AUXILIAR DE TABELAS DE CARGA E ROTINAS DO SISTEMA REL*/
PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('CARTEIRAS', 'carteiras');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('TIP_CTRA', 'tipo-carteira');
QUIT;


%LET Dev=0;
%LET Keypass=carteiras-a5f93337-7003-469a-a29c-319ada9dd782;
%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);

/**/
/*%LET Dev=1;*/
/*%LET Keypass=carteiras-d49f4b78-a083-4bd1-9ec5-58056dbe441b;*/
/*%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);*/


/*#################################################################################################################*/
/*#################################################################################################################*/











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
