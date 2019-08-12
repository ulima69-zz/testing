%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET Keypass=encarteiramento-7cb689e6-c8f3-42eb-b0bd-ceabdb9a2085;
%ProcessoIniciar();


LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;
LIBNAME DB2MCI 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI 	database=BDB2P04;


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
	CREATE TABLE WORK.ENCARTEIRAMENTO AS 
		SELECT DISTINCT 
			TODAY() FORMAT=DateMysql. AS POSICAO,
			t1.CD_CLI,
			t1.CD_PRF_DEPE AS PREFDEP, 
			t1.NR_SEQL_CTRA AS CD_CTRA,
			t1.CD_TIP_CTRA,
			TODAY() FORMAT=DateMysql. AS VALIDADE
		FROM COMUM.PAI_REL_&AAAAMM. t1
		WHERE t1.CD_PRF_DEPE IS NOT MISSING
		ORDER BY 2,3,4
;QUIT;


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('ENCARTEIRAMENTO', 'encarteiramento');
QUIT;

%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);

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
