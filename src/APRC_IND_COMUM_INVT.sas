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
%LET NM_INDICADOR=Investimentos Comum;
%LET NR_INDICADOR=;
%LET MT_DEMANDANTE=;
%LET NM_DEMANDANTE=;	
%LET MT_AUTOR=F9631159;
%LET NM_AUTOR=DUTRA;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=05:30;
/* ---------------------------------------------------------------------------------------------------------------------------*/

/* CONCEITO ------------------------------------------------------------------------------------------------------------------

PROCESSAMENTO DE TABELAS COMUNS DE INVESTIMENTOS.

/* ---------------------------------------------------------------------------------------------------------------------------*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CKECKIN ##################################################################################################################*/

%processCheckIn(uor_resp = 464341, tipo = Processo Comum, sistema = Conexão, rotina = Investimentos Comum);

/*############################################################################################################################*/



/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/

DATA _NULL_;
/*	DT_D0 = MDY(05,06,2019);*/
	DT_D0 = TODAY();
	DT_D1 = diaUtilAnterior(DT_D0);
	DT_D2 = diaUtilAnterior(DT_D1);
	DT_D3 = diaUtilAnterior(DT_D2);
	AAAAMM = Put(DT_D3, yymmn6.);
	MMAAAA = Put(DT_D3, mmyyn6.);
	MM = Put(DT_D3, MONTH.);
	S = PUT(semestre(DT_D3), Z1.);
	AAAA = Put(DT_D3, YEAR.);
	DT_INC_MES=primeiroDiaMes(DT_D3);
	DT_INC_MES_SQL="'"||PUT(DT_INC_MES, YYMMDDD10.)||"'";
	DT_D3_SQL="'"||PUT(DT_D3, YYMMDDD10.)||"'";
	WEEKEND=IFN(weekday(TODAY()) IN (1,7), 1, 0);
	AAMMDD=Put(DT_D0, yymmdd7.);

	CALL SYMPUT('AASS',COMPRESS(PUT(DT_D3, YEAR2.),' ')||'S'||COMPRESS(S,' '));
	CALL SYMPUT('DT_D3',COMPRESS(DT_D3,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));
	CALL SYMPUT('MM',COMPRESS(MM,' '));
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('DT_D3_SQL',COMPRESS(DT_D3_SQL,' '));
	CALL SYMPUT('DT_INC_MES',COMPRESS(DT_INC_MES,' '));
	CALL SYMPUT('DT_INC_MES_SQL',COMPRESS(DT_INC_MES_SQL,' '));
	CALL SYMPUT('WEEKEND',COMPRESS(WEEKEND,' '));
	CALL SYMPUT('AAMMDD',COMPRESS(AAMMDD,' '));
RUN; 

%LET syscc=0;
%LET IDAA=EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;

%PUT  &AASS.;

/*# VARIÁVEIS - ##############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# BIBLIOTECAS - ############################################################################################################*/

LIBNAME DB2GPF db2 AUTHDOMAIN=DB2SGCEN schema=DB2GPF database=BDB2P04;
LIBNAME DB2DEB db2 AUTHDOMAIN=DB2SGCEN schema=DB2DEB database=BDB2P04;
LIBNAME DB2RCA db2 AUTHDOMAIN=DB2SGCEN schema=DB2RCA database=BDB2P04;
LIBNAME DB2GFI db2 AUTHDOMAIN=DB2SGCEN schema=DB2GFI database=BDB2P04;
LIBNAME DB2BPR db2 AUTHDOMAIN=DB2SGCEN schema=DB2BPR database=BDB2P04;
LIBNAME DB2PRD db2 AUTHDOMAIN=DB2SGCEN schema=DB2PRD database=BDB2P04;
LIBNAME DB2MCI db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI database=BDB2P04;
LIBNAME DB2DTM db2 AUTHDOMAIN=DB2SGCEN schema=DB2DTM database=BDB2P04;
LIBNAME GPF "/dados/gecen/interno/bases/gpf" filelockwait=600 access=readonly;
LIBNAME LOCAL "/dados/infor/producao/Investimentos/&AASS./";


/*# BIBLIOTECAS - ############################################################################################################*/
/*############################################################################################################################*/



/*LEGADO GPF ####################################################################################################*/
/*
AÇÕES, TESOURO DIRETO, TÍTULOS, OURO, CUSTÓDIA

CD_PRD	NM_PRD
24		CUSTODIA
114		COMPROMISSADAS TOMADAS
161		COMERCIALIZACAO DE OURO
364		COMPROMISSADAS TOMADAS REGIST NO CETIP
378		TITULOS PUBLICOS
673		COMPRA/VENDA DE ACOES
*/
/*
DATA CTRA_ATI (KEEP=CD_CTRA CD_CLI_CTRT);
	SET DB2GPF.CTRA_ATI;
	WHERE CD_TIP_CTRA = 1;
RUN;

DATA RCBT_ARQ (KEEP=CD_IDFR_ARQ NR_SEQL_RMS CD_EST_RMS_REC DT_REF_RMS_ARQ);
	SET DB2GPF.RCBT_ARQ;
	WHERE CD_EST_RMS_REC = 1;
RUN;

DATA ATI_FNCO_PRTF_INVS (KEEP=CD_ATI_FNCO CD_PRD_INVS_FNCO CD_MDLD_INVS_FNCO);
	SET DB2GPF.ATI_FNCO_PRTF_INVS;
RUN;

DATA TIP_MVT_ATI (KEEP=CD_TIP_MVT_ATI TX_MVT_ATI);
	SET DB2GPF.TIP_MVT_ATI;
RUN;

/* #################################################################################################################################
DB2GPF.CNSO_PSC_DRIA_ATI

Entidade:
Consolidação da Posição Diária de Ativos das Carteiras dos Clientes 

Descrição:
Trata-se da Consolidação das Posições dos Ativos das Carteiras dos Clientes. É a consolidação das informações que serão 
apresentadas ao gestor de forma consolidada para a tomada de Decisão. Fazer essa consolidação em tempo de execução seria um 
processo muito moroso, dessa forma foi necessário criar uma tabela de Consolidação para apresentar essa visão consolidada do Cliente.
*/

/*
DATA CNSO_PSC_DRIA_ATI (KEEP=CD_CLI_OPR_ATI CD_IDFR_ARQ CD_CTRA NR_SEQL_RMS DT_PSC_CTRA VL_FNCO_ATI_DSPN CD_ATI_FNCO);
	SET DB2GPF.CNSO_PSC_DRIA_ATI;
	WHERE DT_PSC_CTRA=&DT_D3.;
RUN;
*/
/*
PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	&IDAA.;
	CREATE TABLE CNSO_PSC_DRIA_ATI AS 
		SELECT * 
		FROM CONNECTION TO DB2(
			SELECT CD_CLI_OPR_ATI, CD_IDFR_ARQ, CD_CTRA, NR_SEQL_RMS, DT_PSC_CTRA, VL_FNCO_ATI_DSPN, CD_ATI_FNCO 
			FROM DB2GPF.CNSO_PSC_DRIA_ATI
			WHERE DT_PSC_CTRA=&DT_D3_SQL.
		);
QUIT;


%PUT &syscc;


%MACRO HABILITAR_IDAA_SE_DER_ERRO;

	%if &syscc > 6 %then %do;

		%LET IDAA=EXECUTE (SET CURRENT QUERY ACCELERATION ENABLE) BY DB2;

		PROC SQL;
			CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
			&IDAA.;
			CREATE TABLE CNSO_PSC_DRIA_ATI AS 
				SELECT * 
				FROM CONNECTION TO DB2(
					SELECT CD_CLI_OPR_ATI, CD_IDFR_ARQ, CD_CTRA, NR_SEQL_RMS, DT_PSC_CTRA, VL_FNCO_ATI_DSPN, CD_ATI_FNCO 
					FROM DB2GPF.CNSO_PSC_DRIA_ATI
					WHERE DT_PSC_CTRA=&DT_D3_SQL.
				);
		QUIT;

	%end;
 
%MEND; %HABILITAR_IDAA_SE_DER_ERRO;



/* ################################################################################################################################# */






/*LEGADO GFI ####################################################################################################*/
/*
FUNDOS DE INVESTIMENTOS

CD_PRD	NM_PRD
352		FUNDOS DE INVESTIMENTOS
955/40	PREVIDENCIA ABERTA	

!! REMOVIDO A MODALIDADE 90
*/

%PUT &DT_INC_MES_SQL.;

PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	&IDAA.;
	CREATE TABLE GFI AS 
		SELECT *
		FROM CONNECTION TO DB2(
			SELECT
				t2.DEB307_COD_BDC AS CD_CLI, 
				t3.CD_PRD AS PRD, 
				t3.CD_MDLD AS MDLD,
				t1.DT_REF AS DT,
				SUM(t1.VL_SDO) AS VL_SDO
			FROM DB2GFI.SDO_TTL t1
			LEFT JOIN DB2GFI.FNDO_INVS t3 ON (t1.CD_FNDO = t3.CD_FNDO)
			INNER JOIN DB2DEB.TDEB307 t2 ON (t2.DEB307_AGENCIA=t1.CD_PRF_DEPE AND t2.DEB307_CONTA=t1.NR_CT)
			WHERE 
					t1.DT_REF BETWEEN &DT_INC_MES_SQL. AND &DT_D3_SQL.
				AND t2.DEB307_COD_BDC > 0
				AND NOT (t3.CD_PRD=352 AND t3.CD_MDLD=90)
			GROUP BY
				t2.DEB307_COD_BDC, 
				t3.CD_PRD, 
				t3.CD_MDLD,
				t1.DT_REF
			HAVING SUM(t1.VL_SDO) <> 0
		);
	DISCONNECT FROM DB2;
QUIT;

/*LEGADO GFI - FIM ################################################################################################*/









/*LEGADO RCA ####################################################################################################*/

/*
Entidade: Produtos de Investimentos dos Clientes
Nome Abreviado: DB2RCA.PRD_INVS_CLI  
Esta tabela possui os dados de cada produto de investimento para todos os clientes enquadrados

A coluna de data disponível na tabela não tem referência com a posição do saldo, a tabela é em DT_D0 (online)

CD_PRD	NM_PRD
1		DEPOSITO A PRAZO
3		POUPANCA
354		EMISSAO DE TITULOS
352		(MDLD=90 > REFERENTE A PREVIDENCIA 955/101, FILTRO SG_SIS_DTTR_INF = 'BPR')
!! REMOVIDO A MODALIDADE 90
489		CERTIFICADO DE OPERACOES ESTRUTURADAS
644		POUPANCA - POUPEX
955		PREVIDENCIA ABERTA
*/


PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	&IDAA.;
	CREATE TABLE RCA AS 
		SELECT *
		FROM CONNECTION TO DB2(
			SELECT 
				t1.CD_CLI,
				t1.CD_PRD_ATI AS PRD, 
				t1.CD_MDLD_ATI AS MDLD,
				DATE(&DT_INC_MES_SQL.) AS DT,
				SUM(t1.VL_SDO_PRD_INVS) AS VL_SDO
			FROM DB2RCA.PRD_INVS_CLI t1
			WHERE 
				(
					(t1.CD_PRD_ATI = 1   AND t1.CD_MDLD_ATI IN (12, 30, 31, 39, 50, 57)) OR
					(t1.CD_PRD_ATI = 3   AND t1.CD_MDLD_ATI IN (1, 5))               	 OR
					(t1.CD_PRD_ATI = 354 AND t1.CD_MDLD_ATI IN (17, 19))             	 OR
					(t1.CD_PRD_ATI = 489 AND t1.CD_MDLD_ATI IN (1))					 	 OR
					(t1.CD_PRD_ATI = 644 AND t1.CD_MDLD_ATI IN (1, 2))               	 OR
					(t1.CD_PRD_ATI = 955 AND t1.CD_MDLD_ATI NOT IN (40))			 	 OR
					(t1.SG_SIS_DTTR_INF = 'BPR')
				) 
			GROUP BY 
				t1.CD_CLI,
				t1.CD_PRD_ATI,
				t1.CD_MDLD_ATI
		)
	;DISCONNECT FROM DB2;
QUIT;


/*LEGADO RCA - FIM ################################################################################################*/


DATA LOCAL.GFI;
	SET GFI;
RUN;

DATA LOCAL.RCA;
	SET RCA;
RUN;

DATA GPF;
	SET GPF.GPF_SDO_DSPN;
RUN;


/*JUNÇÃO DOS LEGADOS*/
DATA INVT;
	SET 
		WORK.GPF 
		WORK.GFI 
		WORK.RCA
;RUN;

PROC SORT DATA=INVT NODUPKEY; BY CD_CLI PRD MDLD DT VL_SDO; RUN;


%EncarteirarCNX(TABELA_CLI=INVT, TABELA_SAIDA=ENCARTEIRADOS, AAAAMM=&AAAAMM., SO_AG_PAA=1);


PROC SQL;
	CREATE TABLE WORK.ENCARTEIRADOS AS 
		SELECT 
			t1.CD_CLI, 
			t1.CD_TIP_PSS AS CLI_TIPO, 
			t1.UOR_ATB AS UOR,  
			t1.PREFDEP_ATB AS PREFDEP,  
			t1.CTRA_ATB AS CTRA,  
			t1.TP_CTRA_ATB AS TP_CTRA 
		FROM WORK.ENCARTEIRADOS t1
		WHERE t1.COD_MERC NOT IN (3, 4)
;QUIT;



%put &syscc;
%put &sysProcessMode;
%PUT &AAAAMM.;

%MACRO GRAVAR_SEM_ERRO;

	%if &syscc > 6 %then %do;

		%if "&sysProcessMode" = "SAS Batch Mode" AND &WEEKEND.=0 AND %sysfunc(time(),time2.) < 12 %then %do;
			x at now + 10 minutes /dados/infor/_scripts/sh/APRC_IND_COMUM_INVT.sh;
		%end;

	%end;
	%else %do;

		PROC SQL;
			CREATE TABLE LOCAL.INVT_PRD_FT&AAMMDD.p AS 
				SELECT
					YEAR(t1.DT) AS AAAA, 
					MONTH(t1.DT) AS MM,
					t2.CD_CLI, 
					t2.CLI_TIPO,
					t2.UOR,
					t2.PREFDEP, 
					t2.CTRA,
					t1.PRD, 
					t1.MDLD,       
					SUM(t1.VL_SDO) AS VL_SDO
				FROM INVT t1
				INNER JOIN ENCARTEIRADOS t2 ON (t1.CD_CLI=t2.CD_CLI)
				GROUP BY 1,2,3,4,5,6,7,8,9
				HAVING SUM(t1.VL_SDO) > 0
		;QUIT;

		%commandShell("chmod 777 /dados/infor/producao/Investimentos/&AASS./*");
		%commandShell("ln -sf /dados/infor/producao/Investimentos/&AASS./invt_prd_ft&aammdd.p.sas7bdat /dados/infor/producao/Investimentos/&AASS./invt_prd_&aaaamm..sas7bdat");
	%end;
 
%MEND; %GRAVAR_SEM_ERRO;


/*############################################################################################################################*/
/*# CKECKOUT #################################################################################################################*/

%processCheckOut(uor_resp = 464341, tipo = Processo Comum, sistema = Conexão, rotina = Investimentos Comum, mailto= &EmailsCheckOut.);

/*############################################################################################################################*/




