/*#############################################################################################################################
#####      PROGRAMA DE CÓDIGO SAS DE PROCESSAMENTO DE INDICADOR DE INDUÇÃO DA REDE DE NEGÓCIOS DO BANCO DO BRASIL       #######
###############################################################################################################################

VIVAR - Vice-Presidência de Distribuição de Varejo
DIVAR - Diretoria Comercial Varejo
GEREX METAS - Gerencia Executiva da Central de Metas de Varejo 
Gerência de Avaliação e Soluções

Os metadados e dados desde programa são confidenciais (#CONFIDENCIAL) com informações de infraestrutura estratégica, 
dados cadastrais e financeiros de clientes, oriundos de informações dos legados e bases do Banco do Brasil.

!!! ESTE PROGRAMA NÃO PODE SER ALTERADO, DIVULGADO OU DISTRIBUÍDO SEM A EXPRESSA AUTORIZAÇÃO DA GEREX METAS.

!!! É EXPRESSAMENTE PROIBIDA A DIVULGAÇÃO EXTERNA AO BANCO, DO PROGRAMA OU DOS DADOS POR ELE GERADOS.

/*############################################################################################################################*/
/*############################################################################################################################*/

/* PACOTE DE FUNÇÕES BASE ----------------------------------------------------------------------------------------------------*/
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';
/* ---------------------------------------------------------------------------------------------------------------------------*/

/* DADOS ---------------------------------------------------------------------------------------------------------------------*/
%LET NM_INDICADOR=Governo Comum;
%LET NR_INDICADOR=;
%LET MT_DEMANDANTE=;
%LET NM_DEMANDANTE=;	
%LET MT_AUTOR=F9631159;
%LET NM_AUTOR=DUTRA;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=;
/* ---------------------------------------------------------------------------------------------------------------------------*/

/* CONCEITO ------------------------------------------------------------------------------------------------------------------

PROCESSAMENTO DE TABELAS COMUNS DO DB2REN, PARA INDICADORES GOVERNO.

/* ---------------------------------------------------------------------------------------------------------------------------*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CKECKIN ##################################################################################################################*/

%processCheckIn(uor_resp = 464341, tipo = Processo Comum, sistema = Conexão, rotina = Governo Comum);

/*############################################################################################################################*/



/*############################################################################################################################*/
/*# BIBLIOTECAS - ############################################################################################################*/

LIBNAME BS_MGCT 	"/dados/infor/producao/IndicadoresGoverno/bases/MGCT_OPR";
LIBNAME BS_RAIZ 	"/dados/infor/producao/IndicadoresGoverno/bases/";
LIBNAME REL_EXT 	"/dados/gecen/interno/bases/rel/fotos";
LIBNAME DB2REN 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REN 	database=BDB2P04;
LIBNAME DB2MCI 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI 	database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;

/*# BIBLIOTECAS - ############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/

DATA _NULL_;
	DT_D1 = diaUtilAnterior(TODAY());
/*	DT_D1 = diaUtilAnterior(MDY(04,01,2019));*/
	AAAAMM = Put(DT_D1, yymmn6.);
	MMAAAA = Put(DT_D1, mmyyn6.);
	MM = PUT(DT_D1, MONTH.);
	AAAA = PUT(DT_D1, YEAR.);
	DT_MM_ANT = intnx('month',DT_D1,-1);
	AAAAMM_ANT = PUT(DT_MM_ANT, yymmn6.);
	MMAAAA_ANT = PUT(DT_MM_ANT, mmyyn6.);
	MM_ANT = PUT(DT_MM_ANT, MONTH.);
	AAAA_ANT = PUT(DT_MM_ANT, YEAR.);
	S = PUT(semestre(DT_D1), Z1.);
	MM_I=IFN(S=1,1,7);
	MM_F=IFN(S=1,6,12);

	CALL SYMPUT('DATA_HOJE',COMPRESS(TODAY(),' '));
	CALL SYMPUT('DT_D1',COMPRESS(DT_D1,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));
	CALL SYMPUT('MM',COMPRESS(MM,' '));
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('AAAAMM_ANT',COMPRESS(AAAAMM_ANT,' '));
	CALL SYMPUT('MMAAAA_ANT',COMPRESS(MMAAAA_ANT,' '));
	CALL SYMPUT('MM_ANT',COMPRESS(MM_ANT,' '));
	CALL SYMPUT('AAAA_ANT',COMPRESS(AAAA_ANT,' '));
	CALL SYMPUT('S',COMPRESS(S,' '));
	CALL SYMPUT('MM_I',COMPRESS(MM_I,' '));
	CALL SYMPUT('MM_F',COMPRESS(MM_F,' '));
RUN; 

%PUT &MMAAAA.;

/*# VARIÁVEIS - ##############################################################################################################*/
/*############################################################################################################################*/



/*#################################################################################################################*/
/*#################################################################################################################*/

/*CONGELAR TABELAS DE NATUREZA JURIDICA*/

PROC SQL;
	CREATE TABLE BS_RAIZ.CLI_GOV_NTZ_JRD_&AAAAMM. AS 
		SELECT 
			t1.CD_CLI, 
			t2.COD_NATU_JURI AS CD_NTZ_JRD, 
			&AAAA. AS AAAA, 
			&MM. AS MM
		FROM BS_RAIZ.CLI_GOV_NTZ_JRD_&AAAAMM_ANT. t1
		LEFT JOIN DB2MCI.PESSOA_JURIDICA t2 ON (t1.CD_CLI=t2.F_CLIENTE_COD)
		WHERE t2.COD_NATU_JURI IN (1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,23,24,25,33,34,36,37,38,54)
;QUIT;
/*TABELA DE HISTORICO DE NATUREZA JURIDICA: DB2MCI.HST_PJ*/

/*#################################################################################################################*/
/*#################################################################################################################*/



/*TODOS OS CLIENTES ENCARTEIRADOS GOVERNO*/
/*#################################################################################################################*/
/*#################################################################################################################*/

%MACRO CLI_SEMESTRE();
	DATA _NULL_;
		CALL SYMPUT('MM_I_MC',COMPRESS(IFN(&S.=1,1,7),' '));
		CALL SYMPUT('MM_F_MC',COMPRESS(MONTH(TODAY()),' '));
	RUN; 

	LIBNAME REL_EXT 	"/dados/gecen/interno/bases/rel/fotos";

	%LET TABELAS=;
	%LET TABELAS_DROP=;
	%DO i=&MM_I_MC. %TO &MM_F_MC.;

		DATA _NULL_;
			AAAAMM_MACRO= put(MDY(&i.,01,&AAAA.), yymmn6.);
			CALL SYMPUT('AAAAMM_MACRO',COMPRESS(AAAAMM_MACRO,' '));
		RUN;

		DATA CLI_&i. (KEEP=CD_CLI TP_CTRA); 
			SET REL_EXT.REL_APRC_&AAAAMM_MACRO.;
			WHERE CD_TIP_CTRA IN (400, 405, 406, 407, 410, 420);
			TP_CTRA=CD_TIP_CTRA;
		RUN;

		DATA CLI_&i._440 (KEEP=CD_CLI TP_CTRA); 
			SET REL_EXT.REL_APRC_DUPL_&AAAAMM_MACRO.;
			WHERE CD_TIP_CTRA IN (440);
			TP_CTRA=CD_TIP_CTRA;
		RUN;

		DATA CLI_&i.;
			SET CLI_&i. CLI_&i._440;
		RUN;

		%LET TABELAS = &TABELAS. CLI_&i;
		%LET TABELAS_DROP = &TABELAS_DROP. CLI_&i CLI_&i._440;
		%PUT &TABELAS.;
	%END;
	DATA BS_RAIZ.CLIENTES_GOV; SET &TABELAS.; RUN;
	PROC SORT DATA=BS_RAIZ.CLIENTES_GOV NODUPKEY; BY CD_CLI TP_CTRA; QUIT;

	PROC DELETE DATA=&TABELAS_DROP.; RUN;

	%commandShell("chmod 777 /dados/infor/producao/IndicadoresGoverno/bases/*");
%MEND CLI_SEMESTRE;

%CLI_SEMESTRE();


PROC SQL;
	DROP TABLE DB2SGCEN.GOV_CLI_TMP;
	CREATE TABLE DB2SGCEN.GOV_CLI_TMP AS 
		SELECT DISTINCT
			t1.CD_CLI FORMAT=9. AS CD_CLI
		FROM BS_RAIZ.CLIENTES_GOV t1 
		ORDER BY t1.CD_CLI;
QUIT;

/*#################################################################################################################*/
/*#################################################################################################################*/



/*REN PROJETADA*/
/*#################################################################################################################*/
/*#################################################################################################################*/

PROC SQL;
	CREATE TABLE WORK.MAX_DT AS 
		SELECT DISTINCT 
			MAX(MDY(t1.MM_APRC, t1.DD_APRC, t1.AA_APRC)) AS DT_APRC
		FROM DB2REN.MGCT_OPR_PJTD t1
		WHERE t1.CD_CLI = 504788788	AND t1.MM_APRC=&MM. AND t1.AA_APRC=&AAAA.
		ORDER BY 1;
QUIT;

DATA _NULL_;
	SET MAX_DT;
	AA_APRC = YEAR(DT_APRC);
	MM_APRC = MONTH(DT_APRC);
	DD_APRC = DAY(DT_APRC);

	CALL SYMPUT('AA_APRC',COMPRESS(AA_APRC,' '));
	CALL SYMPUT('MM_APRC',COMPRESS(MM_APRC,' '));
	CALL SYMPUT('DD_APRC',COMPRESS(DD_APRC,' '));
RUN; 

%PUT ANO: &AA_APRC. - MES: &MM_APRC. - DIA: &DD_APRC. - ANOMES: &AAAAMM.;


PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;

	CREATE TABLE WORK.MGCT_OPR_PJTD_&AAAAMM. AS 
		SELECT 
			AA_APRC, 
			MM_APRC, 
			DD_APRC, 
			CD_CLI, 
			CD_PRD, 
			CD_MDLD, 
			NR_OPR,
			INPUT(NR_UNCO_CTR_OPR,17.) FORMAT=17. INFORMAT=17. AS NR_UNCO_CTR_OPR,
			CD_DEPE_CC_VCLD,
			NR_CC_VCLD,
			RAZAO_CC_VCLD,
			VL_MGCT_SEM_RSCO, 
			VL_MGCT, 
			VL_MSD, 
			VL_TARF_REC 
		FROM CONNECTION TO DB2(
			SELECT DISTINCT 
				t1.AA_APRC, 
				t1.MM_APRC, 
				t1.DD_APRC, 
				t1.CD_CLI, 
				t1.CD_PRD, 
				t1.CD_MDLD, 
				t1.NR_OPR,
				DIGITS(t1.NR_UNCO_CTR_OPR) AS NR_UNCO_CTR_OPR,
				CASE WHEN t2.CD_DEPE_CC_VCLD=0 THEN NULL ELSE t2.CD_DEPE_CC_VCLD END AS CD_DEPE_CC_VCLD,
				CASE WHEN t2.NR_CC_VCLD=0 THEN NULL ELSE t2.NR_CC_VCLD END AS NR_CC_VCLD,
				t3.DEB307_RAZAO AS RAZAO_CC_VCLD,
				t1.VL_MGCT_SEM_RSCO, 
				t1.VL_MGCT, 
				t1.VL_MSD, 
				t1.VL_TARF_REC 
			FROM DB2REN.MGCT_OPR_PJTD t1
			LEFT JOIN DB2OPR.PRTC_PSS_CTR_OPR t2 ON (t1.NR_UNCO_CTR_OPR=t2.NR_UNCO_CTR_OPR)
			LEFT JOIN DB2DEB.TDEB307 t3 ON (t2.CD_DEPE_CC_VCLD = t3.DEB307_AGENCIA AND t2.NR_CC_VCLD = t3.DEB307_CONTA)
			WHERE 
					t1.AA_APRC = &AA_APRC. 
				AND t1.MM_APRC = &MM_APRC. 
				AND t1.DD_APRC = &DD_APRC.
				AND t1.CD_CLI IN (SELECT CD_CLI FROM DB2SGCEN.GOV_CLI_TMP)
			ORDER BY t1.CD_CLI
		);
QUIT;

DATA WORK.MGCT_OPR_PJTD_&AAAAMM.;
	SET WORK.MGCT_OPR_PJTD_&AAAAMM.;
	NR_OPR=IFN(NR_OPR=0, ., NR_OPR);
	NR_UNCO_CTR_OPR=IFN(NR_UNCO_CTR_OPR=0, ., NR_UNCO_CTR_OPR);
RUN;


/*#################################################################################################################*/
/*#################################################################################################################*/




/*REN FECHADA*/
/*#################################################################################################################*/
/*#################################################################################################################*/

PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;

	CREATE TABLE WORK.MGCT_OPR_FCHD_&S.S&AAAA. AS 
		SELECT 
			AA_APRC, 
			MM_APRC, 
			CD_CLI, 
			CD_PRD, 
			CD_MDLD, 
			NR_OPR,
			INPUT(NR_UNCO_CTR_OPR,17.) FORMAT=17. INFORMAT=17. AS NR_UNCO_CTR_OPR,
			CD_DEPE_CC_VCLD,
			NR_CC_VCLD,
			RAZAO_CC_VCLD,
			VL_MGCT_SEM_RSCO, 
			VL_MGCT, 
			VL_MSD, 
			VL_TARF_REC
		FROM CONNECTION TO DB2(
			SELECT DISTINCT
				t1.AA_APRC, 
				t1.MM_APRC, 
				t1.CD_CLI, 
				t1.CD_PRD, 
				t1.CD_MDLD, 
				t1.NR_OPR,
				DIGITS(t1.NR_UNCO_CTR_OPR) AS NR_UNCO_CTR_OPR,
				CASE WHEN t2.CD_DEPE_CC_VCLD=0 THEN NULL ELSE t2.CD_DEPE_CC_VCLD END AS CD_DEPE_CC_VCLD,
				CASE WHEN t2.NR_CC_VCLD=0 THEN NULL ELSE t2.NR_CC_VCLD END AS NR_CC_VCLD,
				t3.DEB307_RAZAO AS RAZAO_CC_VCLD,
				t1.VL_MGCT_SEM_RSCO, 
				t1.VL_MGCT, 
				t1.VL_MSD, 
				t1.VL_TARF_REC 
			FROM DB2REN.MGCT_OPR t1
			LEFT JOIN DB2OPR.PRTC_PSS_CTR_OPR t2 ON (t1.NR_UNCO_CTR_OPR=t2.NR_UNCO_CTR_OPR)
			LEFT JOIN DB2DEB.TDEB307 t3 ON (t2.CD_DEPE_CC_VCLD = t3.DEB307_AGENCIA AND t2.NR_CC_VCLD = t3.DEB307_CONTA)
			WHERE 
					t1.AA_APRC = &AAAA.
				AND t1.MM_APRC >= &MM_I.
				AND t1.MM_APRC <= &MM_F.
				AND t1.CD_CLI IN (SELECT CD_CLI FROM DB2SGCEN.GOV_CLI_TMP)
			ORDER BY t1.CD_CLI
		);
QUIT;


DATA WORK.MGCT_OPR_FCHD_&S.S&AAAA.;
	SET WORK.MGCT_OPR_FCHD_&S.S&AAAA.;
	NR_OPR=IFN(NR_OPR=0, ., NR_OPR);
	NR_UNCO_CTR_OPR=IFN(NR_UNCO_CTR_OPR=0, ., NR_UNCO_CTR_OPR);
RUN;

/*#################################################################################################################*/
/*#################################################################################################################*/


PROC SQL;
	DROP TABLE DB2SGCEN.GOV_CLI_TMP;
QUIT;



%MACRO GRAVAR_SEM_ERRO;

	%if &syscc > 6 %then %do;

		%if "&sysProcessMode" = "SAS Batch Mode" AND %sysfunc(time(),time2.) < 12 %then %do;
			x at now + 10 minutes /dados/infor/_scripts/sh/APRC_IND_COMUM_GOV.sh;
		%end;

	%end;
	%else %do;

		DATA BS_MGCT.MGCT_OPR_FCHD_&S.S&AAAA.;
			SET WORK.MGCT_OPR_FCHD_&S.S&AAAA.;
		RUN;

		DATA BS_MGCT.MGCT_OPR_PJTD_&AAAAMM.;
			SET WORK.MGCT_OPR_PJTD_&AAAAMM.;
		RUN;

	%end;
 
%MEND; %GRAVAR_SEM_ERRO;





/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/
/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/
/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/
/* PROCESSAMENTO COMUM DE FUNDOS GOVERNO */
/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/

/*############################################################################################################################*/
/*# CLIENTES DO ESCOPO - #####################################################################################################*/

/*CLIENTES MARGEM FECHADA E PROJETADA PARA O PRODUTO DE FUNDOS(352)*/
PROC SQL;
	CREATE TABLE WORK.CLI_MGCT_PRD_352 AS 
		SELECT DISTINCT t1.CD_CLI
		FROM BS_MGCT.MGCT_OPR_FCHD_&S.S&AAAA. t1
		WHERE t1.CD_PRD = 352

		UNION 

		SELECT DISTINCT t1.CD_CLI
		FROM BS_MGCT.MGCT_OPR_PJTD_&AAAAMM. t1
		WHERE t1.AA_APRC = &AAAA. AND t1.CD_PRD = 352
;QUIT;

PROC SORT DATA=CLI_MGCT_PRD_352 NODUPKEY; BY CD_CLI; QUIT;


/*IDENTIFICAR CONTAS POR TITULO RAZAO*/
PROC SQL;
	DROP TABLE DB2SGCEN.IND_FND_CLI_TMP;
	CREATE TABLE DB2SGCEN.IND_FND_CLI_TMP AS 
		SELECT DISTINCT t1.CD_CLI FORMAT=9. AS CD_CLI
		FROM WORK.CLI_MGCT_PRD_352 t1;

	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
	CREATE TABLE CC_FNDO_DEB AS
		SELECT DISTINCT *	
		FROM CONNECTION TO DB2 (
			SELECT
				DEB307_COD_BDC AS CD_CLI, 
				DEB307_AGENCIA, 
				DEB307_CONTA, 
				(CASE  
					WHEN DEB307_RAZAO IN (315019201, 315019202, 313019200, 312619200, 314019200) THEN 1
					ELSE 0
				END) AS TP_CC_RPPS
			FROM DB2DEB.TDEB307
			WHERE DEB307_COD_BDC IN (SELECT CD_CLI FROM DB2SGCEN.IND_FND_CLI_TMP)
		);
	DISCONNECT FROM DB2;
	DROP TABLE DB2SGCEN.IND_FND_CLI_TMP;
;QUIT;


/*QUANTIDADE DE CONTAS POR CLIENTE*/
PROC SQL;
	CREATE TABLE WORK.CC_FNDO AS 
		SELECT DISTINCT 
			t1.CD_CLI, 
			t1.TP_CC_RPPS, 
			COUNT(t1.DEB307_CONTA) AS QNT_CC
		FROM WORK.CC_FNDO_DEB t1
		GROUP BY 1,2
;QUIT;

/*QUANTIDADE DE CONTAS POR TIPO POR CLIENTE*/
PROC SQL;
   CREATE TABLE WORK.CC_FNDO AS 
   SELECT DISTINCT 
		t1.CD_CLI,
		SUM(IFN(t1.TP_CC_RPPS=0, t1.QNT_CC, 0)) AS QNT_CC_GOVN,
		SUM(IFN(t1.TP_CC_RPPS=1, t1.QNT_CC, 0)) AS QNT_CC_RPPS,
		SUM(t1.QNT_CC) AS QNT_CC_TOTL
      FROM WORK.CC_FNDO t1
      GROUP BY 1;
QUIT;

/*ADD PERCENTUAL DE TIPOS DE CONTA POR CLIENTE*/
PROC SQL;
	CREATE TABLE WORK.CLI_FNDO_TP AS 
		SELECT 
			t1.CD_CLI, 
			t1.QNT_CC_GOVN, 
			t1.QNT_CC_RPPS, 
			t1.QNT_CC_TOTL, 
			(t1.QNT_CC_GOVN/t1.QNT_CC_TOTL)*100 FORMAT=32.2 AS PC_QNT_CC_GOVN, 
			(t1.QNT_CC_RPPS/t1.QNT_CC_TOTL)*100 FORMAT=32.2 AS PC_QNT_CC_RPPS
		FROM WORK.CC_FNDO t1
		ORDER BY 1
;QUIT;


PROC SQL;
	CREATE TABLE WORK.CLI_FNDO AS 
		SELECT DISTINCT
			t1.CD_CLI
		FROM WORK.CLI_FNDO_TP t1
		ORDER BY 1
;QUIT;

/*BUSCAR PREFIXOS COM ACORDO*/
%BuscarPrefixosIndicador(IND=185, MMAAAA=&MMAAAA., NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarPrefixosIndicador(IND=186, MMAAAA=&MMAAAA., NIVEL_CTRA=1, SO_AG_PAA=0);

DATA PREFIXOS_IND (KEEP=PREFDEP CTRA);SET PREFIXOS_IND_000000185 PREFIXOS_IND_000000186; RUN;
PROC SORT DATA=PREFIXOS_IND NODUPKEY; BY PREFDEP CTRA; RUN;

PROC SQL;
	CREATE TABLE CLI_GOV_ATU AS
		SELECT DISTINCT
			t1.CD_CLI,
			INPUT(i1.UOR, 9.) AS UOR,
			t1.CD_PRF_DEPE AS PREFDEP, 
          	IFN(t1.CD_TIP_CTRA IN (410, 420), 7002, t1.NR_SEQL_CTRA_ATB) AS CTRA,
			IFN(t1.CD_TIP_CTRA IN (410, 420), 700, t1.CD_TIP_CTRA) AS TP_CTRA, 
			&AAAA. AS AAAA,
			&MM. AS MM
		FROM REL_EXT.REL_APRC_&AAAAMM. t1
		INNER JOIN WORK.CLI_FNDO t2 ON (t1.CD_CLI=t2.CD_CLI)
		INNER JOIN WORK.PREFIXOS_IND t3 ON (t1.CD_PRF_DEPE=t3.PREFDEP AND t1.NR_SEQL_CTRA_ATB=t3.CTRA)
		INNER JOIN IGR.IGRREDE_&AAAAMM. i1 ON (t1.CD_PRF_DEPE=INPUT(i1.PREFDEP,4.))
		WHERE t1.CD_TIP_CTRA IN (400, 405, 406, 410, 420)
;QUIT;


%BuscarPrefixosIndicador(IND=185, MMAAAA=&MMAAAA_ANT., NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarPrefixosIndicador(IND=186, MMAAAA=&MMAAAA_ANT., NIVEL_CTRA=1, SO_AG_PAA=0);

DATA PREFIXOS_IND (KEEP=PREFDEP CTRA);SET PREFIXOS_IND_000000185 PREFIXOS_IND_000000186; RUN;
PROC SORT DATA=PREFIXOS_IND NODUPKEY; BY PREFDEP CTRA; RUN;


PROC SQL;
	CREATE TABLE CLI_GOV_ANT AS
		SELECT DISTINCT
			t1.CD_CLI,
			INPUT(i1.UOR, 9.) AS UOR,
			t1.CD_PRF_DEPE AS PREFDEP, 
          	IFN(t1.CD_TIP_CTRA IN (410, 420), 7002, t1.NR_SEQL_CTRA_ATB) AS CTRA,
			IFN(t1.CD_TIP_CTRA IN (410, 420), 700, t1.CD_TIP_CTRA) AS TP_CTRA,
			&AAAA_ANT. AS AAAA,
			&MM_ANT. AS MM
		FROM REL_EXT.REL_APRC_&AAAAMM_ANT. t1
		INNER JOIN WORK.CLI_FNDO t2 ON (t1.CD_CLI=t2.CD_CLI)
		INNER JOIN WORK.PREFIXOS_IND t3 ON (t1.CD_PRF_DEPE=t3.PREFDEP AND t1.NR_SEQL_CTRA_ATB=t3.CTRA)
		INNER JOIN IGR.IGRREDE_&AAAAMM_ANT. i1 ON (t1.CD_PRF_DEPE=INPUT(i1.PREFDEP,4.))
		WHERE t1.CD_TIP_CTRA IN (400, 405, 406, 410, 420)
;QUIT;

DATA CLI_GOV;
	SET CLI_GOV_ATU CLI_GOV_ANT;
	WHERE CTRA IS NOT MISSING AND AAAA=&AAAA. AND MM BETWEEN IFN(&S.=1, 1, 7) AND IFN(&S.=1, 6, 12);
RUN;

PROC SORT DATA=CLI_GOV;  BY CD_CLI MM; QUIT;


/*# CLIENTES DO ESCOPO - FIM #################################################################################################*/
/*############################################################################################################################*/




/*############################################################################################################################*/
/*# PRODUTOS DB2REN - ########################################################################################################*/

PROC SQL;
	CREATE TABLE MGCT_FCHD AS
		SELECT
			t1.CD_CLI, 
			t2.UOR,
			t2.PREFDEP,
			t2.CTRA,
			t2.TP_CTRA, 
			t1.CD_PRD,
			t1.CD_MDLD,
			t1.NR_UNCO_CTR_OPR,
			t1.NR_OPR,
			t1.CD_DEPE_CC_VCLD,
			t1.NR_CC_VCLD,
			t1.RAZAO_CC_VCLD,
			t1.MM_APRC, 
			t1.AA_APRC, 
			SUM(t1.VL_MGCT) AS VL_MGCT
		FROM BS_MGCT.MGCT_OPR_FCHD_&S.S&AAAA. t1
		INNER JOIN WORK.CLI_GOV t2 ON (t1.CD_CLI=t2.CD_CLI AND t1.AA_APRC=t2.AAAA AND t1.MM_APRC=t2.MM)
		WHERE 
				t1.MM_APRC IN ( &MM_ANT., &MM. )  
			AND t1.AA_APRC = &AAAA.
			AND t1.CD_PRD = 352
		GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;QUIT;

PROC SORT DATA=MGCT_FCHD; BY CD_CLI MM_APRC AA_APRC CD_PRD CD_MDLD NR_UNCO_CTR_OPR; QUIT;

PROC SQL;
	CREATE TABLE WORK.MGCT_PJTD AS 
		SELECT 
			t1.CD_CLI, 
			t2.UOR,
			t2.PREFDEP,
			t2.CTRA,
			t2.TP_CTRA, 
			t1.CD_PRD,
			t1.CD_MDLD,
			t1.NR_UNCO_CTR_OPR,
			t1.NR_OPR,
			t1.CD_DEPE_CC_VCLD,
			t1.NR_CC_VCLD,
			t1.RAZAO_CC_VCLD,
			t1.MM_APRC, 
			t1.AA_APRC, 
			SUM(t1.VL_MGCT) AS VL_MGCT
		FROM BS_MGCT.MGCT_OPR_PJTD_&AAAAMM. t1
		INNER JOIN WORK.CLI_GOV t2 ON (t1.CD_CLI=t2.CD_CLI AND t1.AA_APRC=t2.AAAA AND t1.MM_APRC=t2.MM)
		WHERE 
				t1.AA_APRC=&AAAA. 
			AND t1.MM_APRC>=&MM. 
			AND t1.CD_PRD = 352
		GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

		UNION ALL

		SELECT 
			t1.CD_CLI, 
			t2.UOR,
			t2.PREFDEP,
			t2.CTRA,
			t2.TP_CTRA, 
			t1.CD_PRD,
			t1.CD_MDLD,
			t1.NR_UNCO_CTR_OPR,
			t1.NR_OPR,
			t1.CD_DEPE_CC_VCLD,
			t1.NR_CC_VCLD,
			t1.RAZAO_CC_VCLD,
			t1.MM_APRC, 
			t1.AA_APRC, 
			SUM(t1.VL_MGCT) AS VL_MGCT
		FROM BS_MGCT.MGCT_OPR_PJTD_&AAAAMM_ANT. t1
		INNER JOIN WORK.CLI_GOV t2 ON (t1.CD_CLI=t2.CD_CLI AND t1.AA_APRC=t2.AAAA AND t1.MM_APRC=t2.MM)
		WHERE 
				t1.AA_APRC=&AAAA. 
			AND t1.MM_APRC=&MM_ANT. 
			AND t1.CD_PRD = 352
		GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;QUIT;

PROC SORT DATA=MGCT_PJTD NODUPKEY; BY CD_CLI MM_APRC AA_APRC CD_PRD CD_MDLD NR_UNCO_CTR_OPR; QUIT;


/*MANTEM SOMENTE OS REGISTROS QUE NÃO EXISTIREM NA MARGEM FECHADA*/
/*PROC SQL;*/
/*	CREATE TABLE WORK.MGCT_PJTD AS */
/*		SELECT **/
/*		FROM WORK.MGCT_PJTD t1*/
/*		LEFT JOIN WORK.MGCT_FCHD t2 ON (t1.CD_CLI=t2.CD_CLI AND t1.MM_APRC=t2.MM_APRC AND t1.AA_APRC=t2.AA_APRC AND t1.CD_PRD=t2.CD_PRD AND t1.CD_MDLD=t2.CD_MDLD AND t1.NR_UNCO_CTR_OPR=t2.NR_UNCO_CTR_OPR)*/
/*		WHERE t2.CD_CLI IS MISSING*/
/*;QUIT;*/


/*MANTER SOMENTE OS DADOS PROJETADOS DE MESES QUE NÃO CONTEM FECHADA*/
PROC SQL NOPRINT; SELECT DISTINCT MM_APRC INTO: MESES_MGCT_FCHD SEPARATED BY ', ' FROM MGCT_FCHD; QUIT;
%LET MESES_MGCT_FCHD=0, &MESES_MGCT_FCHD.;
%PUT &MESES_MGCT_FCHD.;
DATA MGCT_PJTD; SET MGCT_PJTD; WHERE MM_APRC NOT IN (&MESES_MGCT_FCHD.); RUN;


/*JUNÇÃO MARGENS FECHADA E PROJETADA*/
DATA MGCT;
	SET MGCT_FCHD MGCT_PJTD;
	WHERE AA_APRC=&AAAA. AND MM_APRC BETWEEN IFN(&S.=1, 1, 7) AND IFN(&S.=1, 6, 12);
RUN;

PROC SORT DATA=MGCT; BY CD_CLI MM_APRC AA_APRC CD_PRD CD_MDLD NR_UNCO_CTR_OPR; QUIT;


/*# PRODUTOS DB2REN - FIM ####################################################################################################*/
/*############################################################################################################################*/



PROC SQL;
	CREATE TABLE WORK.MGCT AS 
		SELECT 
			t1.CD_CLI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.TP_CTRA, 
			t1.CD_PRD, 
			t1.CD_MDLD, 
			t1.NR_UNCO_CTR_OPR, 
			t1.NR_OPR, 
			t1.CD_DEPE_CC_VCLD, 
			t1.NR_CC_VCLD, 
			t1.RAZAO_CC_VCLD, 
			t1.AA_APRC AS AAAA,
			t1.MM_APRC AS MM, 
			t1.VL_MGCT
		FROM WORK.MGCT t1;
QUIT;


PROC SQL;
	CREATE TABLE WORK.MGCT_ENCT_RPPS AS 
		SELECT 
			t1.*,
			t2.QNT_CC_GOVN, 
			t2.QNT_CC_RPPS, 
			t2.QNT_CC_TOTL, 
			t2.PC_QNT_CC_GOVN, 
			t2.PC_QNT_CC_RPPS
		FROM WORK.MGCT t1
		INNER JOIN WORK.CLI_FNDO_TP t2 ON (t1.CD_CLI=t2.CD_CLI)
;QUIT;

PROC SQL;
	CREATE TABLE WORK.MGCT_ENCT_RPPS AS 
		SELECT 
			t1.*,
			(CASE  
               WHEN t1.RAZAO_CC_VCLD IS NOT MISSING AND t1.RAZAO_CC_VCLD 		IN (315019201, 315019202, 313019200, 312619200, 314019200)   THEN 1
               WHEN t1.RAZAO_CC_VCLD IS NOT MISSING AND t1.RAZAO_CC_VCLD NOT 	IN (315019201, 315019202, 313019200, 312619200, 314019200)   THEN 0
               WHEN t1.RAZAO_CC_VCLD IS 	MISSING AND t1.PC_QNT_CC_RPPS = 1 THEN 1
               WHEN t1.RAZAO_CC_VCLD IS 	MISSING AND t1.PC_QNT_CC_GOVN = 1 THEN 0
               WHEN t1.RAZAO_CC_VCLD IS 	MISSING AND t1.CD_MDLD IN (90, 802, 804)	AND t1.QNT_CC_RPPS > 0 THEN 1
               WHEN t1.RAZAO_CC_VCLD IS 	MISSING AND t1.CD_MDLD IN (52, 800)			AND t1.QNT_CC_GOVN > 0 THEN 0    
               ELSE 0
            END) AS RPPS
		FROM WORK.MGCT_ENCT_RPPS t1
;QUIT;


DATA BS_MGCT.MGCT_ENCT_RPPS_&AAAAMM.;
	SET MGCT_ENCT_RPPS;
	WHERE MM=&MM.;
RUN;

DATA BS_MGCT.MGCT_ENCT_RPPS_&AAAAMM_ANT.;
	SET MGCT_ENCT_RPPS;
	WHERE MM=&MM_ANT.;
RUN;

																												

/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/
/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/
/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/
/* FIM PROCESSAMENTO COMUM DOS INDICADORES DE FUNDOS*/
/*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/


%commandShell("chmod 777 /dados/infor/producao/IndicadoresGoverno/bases/*");
%commandShell("chmod 777 /dados/infor/producao/IndicadoresGoverno/bases/MGCT_OPR/*");


/*############################################################################################################################*/
/*# CKECKOUT #################################################################################################################*/

%processCheckOut(uor_resp = 464341, tipo = Processo Comum, sistema = Conexão, rotina = Governo Comum, mailto= &EmailsCheckOut.);

/*############################################################################################################################*/
