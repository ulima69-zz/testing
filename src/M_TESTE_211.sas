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
%LET NM_INDICADOR=Desembolso Governo;
%LET NR_INDICADOR=000000211;
%LET MT_DEMANDANTE=;
%LET NM_DEMANDANTE=;	
%LET MT_AUTOR=F9631159;
%LET NM_AUTOR=DUTRA;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=07:00;
/* ---------------------------------------------------------------------------------------------------------------------------*/

/* CONCEITO ------------------------------------------------------------------------------------------------------------------

Valor do desembolso de operações de crédito com a administração direta dos Estados, DF e Municípios, com autarquias e com 
empresas estatais não dependentes (públicas e sociedades de economia mista). <br>Considerando as especificidades do cliente 
Governo, a meta será acionada sempre que houver Desembolso no período avaliativo.

Carteiras Avaliadas: Governo, Judiciário, PNG, PNA e Grupo das Agências Setor Público, Judiciário e Governo

/* ---------------------------------------------------------------------------------------------------------------------------*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# CKECKIN ##################################################################################################################*/
%indCheckIn();
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# BIBLIOTECAS - ############################################################################################################*/

LIBNAME REN   		"/dados/infor/producao/IndicadoresGoverno/bases/MGCT_OPR";
LIBNAME LOCAL 		"/dados/infor/producao/IndicadoresGoverno/bases";
LIBNAME DIGOV 		"/dados/externo/DIGOV/GECEN/indicadores";
LIBNAME REL_EXT 	"/dados/gecen/interno/bases/rel/fotos";
LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2MCI 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI 	database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;
LIBNAME DB2COP 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2COP 	database=BDB2P04;
LIBNAME DB2PRD 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2PRD 	database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;

/*# BIBLIOTECAS - ############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/

DATA _NULL_;
	DT_D1 = diaUtilAnterior(TODAY());
	/*	DT_D1 = diaUtilAnterior(MDY(03,01,2018));*/
	AAAAMM = Put(DT_D1, yymmn6.);
	MMAAAA = Put(DT_D1, mmyyn6.);
	MM = Put(DT_D1, MONTH.);
	AAAA = Put(DT_D1, YEAR.);
	S = PUT(semestre(DT_D1), Z1.);
	DT_INC_MM_ATU=primeiroDiaMes(DT_D1);
	DT_FIM_MM_ATU=ultimoDiaMes(DT_D1);

	CALL SYMPUT('AASS',COMPRESS(PUT(DT_D1, YEAR2.),' ')||'S'||COMPRESS(semestre(DT_D1),' '));
	CALL SYMPUT('DT_D1',COMPRESS(DT_D1,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));
	CALL SYMPUT('MM',COMPRESS(MM,' '));
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('S',COMPRESS(S,' '));
	CALL SYMPUT('DT_INC_MM_ATU',COMPRESS(DT_INC_MM_ATU,' '));
	CALL SYMPUT('DT_FIM_MM_ATU',COMPRESS(DT_FIM_MM_ATU,' '));
	CALL SYMPUT('DT_INC_MM_ATU_SQL',"'"||PUT(DT_INC_MM_ATU, yymmdd10.)||"'");
	CALL SYMPUT('DT_FIM_MM_ATU_SQL',"'"||PUT(DT_FIM_MM_ATU, yymmdd10.)||"'");
RUN;

%PUT &MM.;

/*# VARIÁVEIS - ##############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# PRODUTOS DO ESCOPO - #####################################################################################################*/

%BuscarComponentesIndicador(IND=&NR_INDICADOR.);

PROC SQL;
	CREATE TABLE WORK.LST_PRD AS 
		SELECT 
			t1.IND,
			t1.AAAA, 
			t1.MM, 
			t1.CD_PRD, 
			t1.CD_MDLD, 
			upcase(t3.NM_MDLD) AS NM_MDLD,
			t1.CLI_TIP, 
			t1.COMP,
			upcase(t2.NM_COMP) AS NM_COMP
		FROM LOCAL.LST_PRD_IND_GOV_&AAAA.S&S. t1
		LEFT JOIN DB2PRD.MDLD_PRD t3 ON (t1.CD_PRD=t3.CD_PRD AND t1.CD_MDLD=t3.CD_MDLD)
		LEFT JOIN WORK.IND_COMP_&NR_INDICADOR. t2 ON (t1.COMP=t2.COMP)
		WHERE t1.IND=&NR_INDICADOR. AND t1.AAAA=&AAAA. AND t1.MM=&MM.
		ORDER BY 1,2,3,4,5
;QUIT;

/*# PRODUTOS DO ESCOPO - FIM #################################################################################################*/
/*############################################################################################################################*/



/*############################################################################################################################*/
/*# CLIENTES DO ESCOPO - #####################################################################################################*/

/*%BuscarPrefixosIndicador(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., NIVEL_CTRA=1, SO_AG_PAA=0);*/

PROC SQL;
	CREATE TABLE WORK.CLI_GOV_ANT AS
		SELECT DISTINCT
			t1.CD_CLI,
			INPUT(i1.UOR, 9.) AS UOR,
			t1.CD_PRF_DEPE AS PREFDEP, 
			IFN(t1.CD_TIP_CTRA IN (410, 420), 7002, t1.NR_SEQL_CTRA_ATB) AS CTRA,
			IFN(t1.CD_TIP_CTRA IN (410, 420), 700, t1.CD_TIP_CTRA) AS TP_CTRA, 
			&AAAA. AS AAAA,
			&MM. AS MM
		FROM REL_EXT.REL_APRC_&AAAAMM. t1
/*		INNER JOIN WORK.PREFIXOS_IND_&NR_INDICADOR. t3 ON (t1.CD_PRF_DEPE=t3.PREFDEP AND t1.NR_SEQL_CTRA_ATB=t3.CTRA AND t3.PESO>0)*/
		INNER JOIN IGR.IGRREDE_&AAAAMM. i1 ON (t1.CD_PRF_DEPE=INPUT(i1.PREFDEP,4.))
		WHERE t1.CD_TIP_CTRA IN (400, 405, 406, 410, 420) 

		UNION

		SELECT DISTINCT
			t1.CD_CLI,
			INPUT(i1.UOR, 9.) AS UOR,
			t1.CD_PRF_DEPE AS PREFDEP, 
			IFN(t1.CD_TIP_CTRA IN (410, 420), 7002, t1.NR_SEQL_CTRA_ATB) AS CTRA,
			IFN(t1.CD_TIP_CTRA IN (410, 420), 700, t1.CD_TIP_CTRA) AS TP_CTRA, 
			&AAAA. AS AAAA,
			&MM. AS MM
		FROM REL_EXT.REL_APRC_DUPL_&AAAAMM. t1
/*		INNER JOIN WORK.PREFIXOS_IND_&NR_INDICADOR. t3 ON (t1.CD_PRF_DEPE=t3.PREFDEP AND t1.NR_SEQL_CTRA_ATB=t3.CTRA AND t3.PESO>0)*/
		INNER JOIN IGR.IGRREDE_&AAAAMM. i1 ON (t1.CD_PRF_DEPE=INPUT(i1.PREFDEP,4.))
		WHERE t1.CD_TIP_CTRA IN (440)
;QUIT;


PROC SQL;
	CREATE TABLE WORK.CLI_GOV AS 
		SELECT

			t1.CD_CLI,
			t1.UOR,
            IFN(t1.TP_CTRA = 440 AND t2.CD_PRF_DEPE_VCLD IS NOT MISSING AND t2.NR_SEQL_CTRA_VCLD IS NOT MISSING, t2.CD_PRF_DEPE_VCLD, t1.PREFDEP) AS PREFDEP,
            IFN(t1.TP_CTRA = 440 AND t2.CD_PRF_DEPE_VCLD IS NOT MISSING AND t2.NR_SEQL_CTRA_VCLD IS NOT MISSING, t2.NR_SEQL_CTRA_VCLD, t1.CTRA) AS CTRA,
			 
			t1.TP_CTRA,
			t1.AAAA, 
			t1.MM,
			t2.CD_PRF_DEPE_VCLD AS PREFDEP_VCLD,
            t2.NR_SEQL_CTRA_VCLD AS CTRA_VCLD

		FROM WORK.CLI_GOV_ANT t1	
        LEFT JOIN DB2REL.CTRA_CLI_ASSR_GOV t2 ON t1.PREFDEP = t2.CD_PRF_DEPE AND t1.CTRA = t2.NR_SEQL_CTRA
		
		ORDER BY 1,2,3,4
;QUIT;



/*# CLIENTES DO ESCOPO - FIM #################################################################################################*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# DESEMBOLSOS DB2COP - #####################################################################################################*/
%PUT ANO: &AAAA. - Data Inicio: &DT_INC_MM_ATU_SQL. - Data final:&DT_FIM_MM_ATU_SQL.;

PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	DROP TABLE DB2SGCEN.PRD_GOV_DSBS_TEMP;
	CREATE TABLE DB2SGCEN.PRD_GOV_DSBS_TEMP AS 
		SELECT DISTINCT
			t1.CD_PRD FORMAT=4. AS COD_PROD, 
			t1.CD_MDLD FORMAT=4. AS COD_MDLD_PROD
		FROM WORK.LST_PRD t1;

	CREATE TABLE COP_DSB AS
		SELECT *
			FROM CONNECTION TO DB2(
				SELECT
					YEAR(t1.DATA) AS AAAA,
					MONTH(t1.DATA) AS MM,
					t3.COD AS CD_CLI, 
					t1.DATA AS DT_DSB, 
					(t1.VLRLANC*-1) AS VLR_DSB 
				FROM DB2COP.TCOP527 t1 
				INNER JOIN DB2COP.TCOP522 t2 ON (t1.AGENCIA = t2.AGENCIA AND t1.CONTRATO = t2.CONTRATO)
				INNER JOIN DB2MCI.CLIENTE t3 ON (t2.CIC= t3.COD_CPF_CGC)
				INNER JOIN DB2SGCEN.PRD_GOV_DSBS_TEMP t0 ON (t1.COD_PROD = t0.COD_PROD AND t1.COD_MDLD_PROD = t0.COD_MDLD_PROD)
				WHERE 
					t1.HIST IN (235, 610)
					AND t2.CPFCGC = 2
					AND t1.DATA BETWEEN &DT_INC_MM_ATU_SQL. AND &DT_FIM_MM_ATU_SQL.

				UNION ALL

				SELECT
					YEAR(t1.DTA_DBTO) AS AAAA,
					MONTH(t1.DTA_DBTO) AS MM, 
					t2.CD_CLI_OPR AS CD_CLI,
					t1.DTA_DBTO AS DT_DSB, 
					t1.VLR_DBTO AS VLR_DSB
				FROM DB2COP.TCOP132 t1
				INNER JOIN DB2COP.CLI_OPR t2 ON (t1.NRO_OPER = t2.NR_OPR)
				WHERE 
					t1.COD_LNCR = 612 
					AND t1.SEQ_VLOR_DBTO = 1 
					AND t1.COD_TIPO_EVNT_DBTO = 17 
					AND t1.DTA_CANC IS NULL 
					AND t1.DTA_DBTO BETWEEN &DT_INC_MM_ATU_SQL. AND &DT_FIM_MM_ATU_SQL.
					;)
				ORDER BY 1;
	DISCONNECT FROM DB2;
	DROP TABLE DB2SGCEN.PRD_GOV_DSBS_TEMP;
QUIT;

/*# DESEMBOLSOS DB2COP - FIM #################################################################################################*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# TABELAS ANALITICAS - #####################################################################################################*/
PROC SQL;
	CREATE TABLE WORK.ANLT_DSB AS 
		SELECT
			t1.AAAA, 
			t1.MM, 
			t1.CD_CLI, 
			t2.UOR, 
			t2.PREFDEP, 
			t2.CTRA, 
			t2.TP_CTRA, 
			t1.DT_DSB, 
			t1.VLR_DSB
		FROM WORK.COP_DSB t1
		INNER JOIN WORK.CLI_GOV t2 ON (t1.CD_CLI=t2.CD_CLI AND t1.AAAA=t2.AAAA AND t1.MM=t2.MM)
;QUIT;

PROC SQL;
	CREATE TABLE WORK.ANLT_CLI AS 
		SELECT
			t1.AAAA, 
			t1.MM,
			t1.CD_CLI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.TP_CTRA,  
			SUM(t1.VLR_DSB) FORMAT=32.2 AS RLZ,
			SUM(t1.VLR_DSB) FORMAT=32.2 AS ORC
		FROM WORK.ANLT_DSB t1
		GROUP BY 1,2,3,4,5,6,7
;QUIT;

/*TIRANDO a 440*/

PROC SQL;
	CREATE TABLE WORK.ANLT_CLI_S440 AS 
		SELECT
			t1.AAAA, 
			t1.MM,
			t1.CD_CLI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.TP_CTRA,  
			SUM(t1.VLR_DSB) FORMAT=32.2 AS RLZ,
			SUM(t1.VLR_DSB) FORMAT=32.2 AS ORC
		FROM WORK.ANLT_DSB t1
		WHERE t1.TP_CTRA <> 440
		GROUP BY 1,2,3,4,5,6,7
;QUIT;


/*# TABELAS ANALITICAS - FIM #################################################################################################*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS #################################*/
LIBNAME EXT_ANLT "/dados/externo/DIVAR/METAS/conexao/&AASS./rlzd_analitico";

DATA EXT_ANLT.anlt_&NR_INDICADOR._&AAAAMM.;
	SET ANLT_DSB;
RUN;

%commandShell("chmod 777 /dados/externo/DIVAR/METAS/conexao/&AASS./rlzd_analitico/anlt_&NR_INDICADOR._&AAAAMM.*");

/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS - FIM ###########################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# SUMARIZAR ################################################################################################################*/

PROC SQL;
	CREATE TABLE WORK.SUM_CTRA AS 
		SELECT 
			t1.AAAA, 
			t1.MM, 
			t1.PREFDEP, 
			t1.CTRA, 
			SUM(t1.RLZ) FORMAT=32.2 AS VLR_RLZ, 
			SUM(t1.ORC) FORMAT=32.2 AS VLR_ORC
		FROM WORK.ANLT_CLI t1
		GROUP BY 1,2,3,4;
QUIT;


DATA SUM_CTRA;
SET SUM_CTRA;
CTRA_RLZ=IFN(VLR_RLZ>0, 1, 0);
RUN;


/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/

PROC SQL;
	DROP TABLE COL_SUM;
	CREATE TABLE COL_SUM (Coluna CHAR(50), Tipo CHAR(10) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COL_SUM VALUES ('VLR_RLZ', 'SUM');
	INSERT INTO COL_SUM VALUES ('VLR_ORC', 'SUM');
	INSERT INTO COL_SUM VALUES ('CTRA_RLZ', 'SUM');
QUIT;


%SumarizadorCNX(TblSASValores=SUM_CTRA, TblSASColunas=COL_SUM,  NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL, AAAAMM=&AAAAMM.);


/*****************************************************************/
/*****************************************************************/
/*****************************************************************/
/*****************************************************************/

PROC SQL;
	CREATE TABLE WORK.SUM_CTRA_S440 AS 
		SELECT 
			t1.AAAA, 
			t1.MM, 
			t1.PREFDEP, 
			t1.CTRA, 
			SUM(t1.RLZ) FORMAT=32.2 AS VLR_RLZ, 
			SUM(t1.ORC) FORMAT=32.2 AS VLR_ORC
		FROM WORK.ANLT_CLI_S440 t1
		GROUP BY 1,2,3,4;
QUIT;


DATA SUM_CTRA_S440;
SET SUM_CTRA_S440;
CTRA_RLZ=IFN(VLR_RLZ>0, 1, 0);
RUN;


/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/

PROC SQL;
	DROP TABLE COL_SUM;
	CREATE TABLE COL_SUM (Coluna CHAR(50), Tipo CHAR(10) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COL_SUM VALUES ('VLR_RLZ', 'SUM');
	INSERT INTO COL_SUM VALUES ('VLR_ORC', 'SUM');
	INSERT INTO COL_SUM VALUES ('CTRA_RLZ', 'SUM');
QUIT;


%SumarizadorCNX(TblSASValores=SUM_CTRA_S440, TblSASColunas=COL_SUM,  NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL_S440, AAAAMM=&AAAAMM.);


/*# SUMARIZAR - FIM ##########################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CRIAR ORÇADO #############################################################################################################*/

/*REMOVER OS HISTORIOS DO ORÇAMENTO DO ANO MES DE REFERENCIA DO PROCESSAMENTO*/

/*
LIBNAME LIBORC 		"/dados/gecen/interno/cnx_orc/&AAAA./&NR_INDICADOR.";

DATA LIBORC.IND_ORC_HST_&NR_INDICADOR.;
	SET LIBORC.IND_ORC_HST_&NR_INDICADOR.;
	WHERE MMAAAA <> &MMAAAA.;
RUN;

PROC SQL;
	CREATE TABLE WORK.ORCADO AS
		SELECT
			&NR_INDICADOR. AS ind,
			0 AS comp,
			t1.uor,
			t1.prefdep,
			t1.ctra,
			t1.VLR_ORC as vlr,
			input(Put(&DT_D1. , mmyyn6.),6.) as mmaaaa
		FROM WORK.FINAL t1;
QUIT;

/*FUNÇÃO CRIAR ATUALIZAR ORÇADO*/
/*%BASE_IND_ORC(TabelaSAS=ORCADO);*/

/*# CRIAR ORÇADO - FIM #######################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CONEXÃO ##################################################################################################################*/


/*CONEXÃO MOBILIZAÇÃO*/
/*
PROC SQL;
	CREATE TABLE WORK.BASE_CNX_CLI AS 
		SELECT
			&NR_INDICADOR. AS IND,
			1 AS COMP, 
			t1.PREFDEP, 
			t1.UOR,
			t1.CTRA AS CTRA, 
			t1.CD_CLI AS CLI,
			INPUT(PUT(&DT_D1., mmyyn6.),6.) AS MMAAAA, 
			t1.RLZ AS VLR
		FROM WORK.ANLT_CLI t1
;QUIT;

PROC SQL;
	CREATE TABLE WORK.BASE_CNX AS 
		SELECT 
			&NR_INDICADOR. AS IND,
			0 AS COMP,
			0 AS COMP_PAI,
			0 AS ORD_EXI,
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA,
			t1.VLR_RLZ,
			. AS VLR_ORC,
			. AS VLR_ATG,
			&DT_D1. FORMAT=YYMMDD10. AS POSICAO 
		FROM WORK.FINAL t1;
QUIT;

DATA BASE_CNX_COMP_1;SET BASE_CNX;COMP=1;RUN;
DATA BASE_CNX; SET BASE_CNX BASE_CNX_COMP_1; RUN;
PROC SORT DATA=BASE_CNX; BY IND COMP COMP_PAI ORD_EXI UOR CTRA; QUIT;

/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CNX_CLI);*/
/*%BaseIndicadorCNX(TabelaSAS=BASE_CNX);*/
/**/
/*%ExportarCNX_CLI(IND=&NR_INDICADOR., MMAAAA=&MMAAAA.);*/
/*%ExportarCNX_IND(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., ORC=1, RLZ=1);*/
/*%ExportarCNX_COMP(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., ORC=1, RLZ=1);*/




/*CONEXÃO AVALIAÇÃO*/

/*
Carteira 5175 ORC 5176 RLZ (Valor), enviar orçado e realizado
Prefixos 5178 RLZ (Quantidade), enviar somente realizado
*/

%PUT &MM.;

PROC SQL;
	CREATE TABLE CNX_AVL_CTRA_ORC AS
		SELECT 
			'2000153'
			||'5175'
			||REPEAT(' ',45)
			||COMPRESS(PUT(PREFDEP,Z4.))
			||COMPRESS(PUT(CTRA,Z5.))
			||"&AAAAMM"
			||COMPRESS(PUT(TP_CNX_AVL,Z4.))
			||'+'
			||put(ABS(VLR_ORC)*100,z13.)
			||'F9631159'
			||COMPRESS(PUT(&DT_D1, ddmmyy10.))
			||'N' AS L
		FROM FINAL
		WHERE CTRA<>0
;QUIT;

%GerarBBM(TabelaSAS=CNX_AVL_CTRA_ORC, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=G5175&MM.);

PROC SQL;
	CREATE TABLE CNX_AVL_CTRA_RLZ AS
		SELECT 
			'2000153'
			||'5176'
			||REPEAT(' ',45)
			||COMPRESS(PUT(PREFDEP,Z4.))
			||COMPRESS(PUT(CTRA,Z5.))
			||"&AAAAMM"
			||COMPRESS(PUT(TP_CNX_AVL,Z4.))
			||'+'
			||put(ABS(VLR_RLZ)*100,z13.)
			||'F9631159'
			||COMPRESS(PUT(&DT_D1, ddmmyy10.))
			||'N' AS L
		FROM FINAL
		WHERE CTRA<>0
;QUIT;

%GerarBBM(TabelaSAS=CNX_AVL_CTRA_RLZ, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=G5176&MM.);


PROC SQL;
	CREATE TABLE CNX_AVL_PREF_RLZ AS
		SELECT 
			'2000153'
			||'5178'
			||REPEAT(' ',45)
			||COMPRESS(PUT(PREFDEP,Z4.))
			||COMPRESS(PUT(CTRA,Z5.))
			||"&AAAAMM"
			||COMPRESS(PUT(TP_CNX_AVL,Z4.))
			||'+'
			||put(ABS(CTRA_RLZ)*100,z13.)
			||'F9631159'
			||COMPRESS(PUT(&DT_D1, ddmmyy10.))
			||'N' AS L
		FROM FINAL_S440
		WHERE CTRA=0
;QUIT;

%GerarBBM(TabelaSAS=CNX_AVL_PREF_RLZ, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=G5178&MM.);

/*# CONEXÃO - FIM ############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CKECKOUT #################################################################################################################*/
%indCheckOut();
/*############################################################################################################################*/
