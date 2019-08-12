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
%LET NM_INDICADOR=Investimentos - Saldo Total (Leve);
%LET NR_INDICADOR=000000283;
%LET MT_DEMANDANTE=;
%LET NM_DEMANDANTE=;	
%LET MT_AUTOR=F9631159;
%LET NM_AUTOR=DUTRA;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=07:00;
/* ---------------------------------------------------------------------------------------------------------------------------*/

/* CONCEITO ------------------------------------------------------------------------------------------------------------------

Refere-se ao SALDO da carteira de investimentos, contemplando os seguintes produtos: Captação (Depósito a Prazo, Poupança, 
Poupex, LCI, LCA, COE), Fundos de Investimento, Tesouro Direto, Mercado de Capitais (Ações, CRA, CRI, Debêntures, FII, 
FDIC e Ouro) e Previdência.

/*############################################################################################################################*/

/*############################################################################################################################*/
/*# CKECKIN ##################################################################################################################*/
%indCheckIn();
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/

DATA _NULL_;
/*	DT_D0 = MDY(07,02,2019);*/
	DT_D0 = TODAY();
	DT_D1 = diaUtilAnterior(DT_D0);
	DT_D2 = diaUtilAnterior(DT_D1);
	DT_D3 = diaUtilAnterior(DT_D2);
	PDU1 = primeiroDiaUtilMes(DT_D0);
	PDU2 = diaUtilPosterior(PDU1);
	PDU3 = diaUtilPosterior(PDU2);
	PrimeirosUteis = IFN((TODAY() >= PDU1 AND TODAY() <= PDU3), 1, 0); 
	AAAAMM = Put(DT_D3, yymmn6.);
	MMAAAA = Put(DT_D3, mmyyn6.);
	MMAAAA_PDU1 = Put(PDU1, mmyyn6.);
	MM = Put(DT_D3, MONTH.);
	S = PUT(semestre(DT_D3), Z1.);
	AAAA = Put(DT_D3, YEAR.);
	INC_MES=primeiroDiaMes(DT_D3);
	INC_MES_SQL="'"||PUT(INC_MES, YYMMDDD10.)||"'";
	DT_D3_SQL="'"||PUT(DT_D3, YYMMDDD10.)||"'";

	CALL SYMPUT('AASS',COMPRESS(PUT(DT_D3, YEAR2.),' ')||'S'||COMPRESS(S,' '));
	CALL SYMPUT('DT_D3',COMPRESS(DT_D3,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));
	CALL SYMPUT('MM',COMPRESS(MM,' '));
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('DT_D3_SQL',COMPRESS(DT_D3_SQL,' '));
	CALL SYMPUT('INC_MES_SQL',COMPRESS(INC_MES_SQL,' '));
	CALL SYMPUT('PrimeirosUteis',COMPRESS(PrimeirosUteis,' '));
	CALL SYMPUT('PDU1',COMPRESS(PDU1,' '));
	CALL SYMPUT('MMAAAA_PDU1',COMPRESS(MMAAAA_PDU1,' '));
RUN;

%PUT &AASS.;

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
LIBNAME LOCAL "/dados/infor/producao/Investimentos/&AASS./";
LIBNAME EXT_ANLT "/dados/externo/DIVAR/METAS/conexao/&AASS./rlzd_analitico";
LIBNAME CNX_RLZD "/dados/infor/conexao/&AAAA./&NR_INDICADOR/";

/*# BIBLIOTECAS - ############################################################################################################*/
/*############################################################################################################################*/

%BuscarComponentesIndicador(IND=&NR_INDICADOR.);

/*DE/PARA DE PRODUTOS E COMPONENTES*/

DATA PRD_INVT;
	SET LOCAL.PRD_INVT;
	WHERE COMP NOT IN (27 29 30 32 34 35 36) AND CLI_TIPO=1;
RUN;


PROC SQL;
	CREATE TABLE WORK.PRD_INVT AS 
		SELECT 
			t1.PRD, 
			t1.MDLD, 
			t3.NM_MDLD,
			t1.CLI_TIPO,
			t1.COMP,
			t2.COMP_PAI, 
			t2.ORD_EXI, 
			upcase(t2.NM_COMP) AS NM_COMP,
			t1.LEGADO
		FROM WORK.PRD_INVT t1
		LEFT JOIN WORK.IND_COMP_&NR_INDICADOR. t2 ON (t1.COMP=t2.COMP)
		LEFT JOIN DB2PRD.MDLD_PRD t3 ON (t1.PRD=t3.CD_PRD AND t1.MDLD=t3.CD_MDLD)
		ORDER BY 1,2,4
;QUIT;


/*SUMARIZAR POR PRODUTO COMPONENTE*/

/*ATENÇÃO! A tabela LOCAL.INVT_PRD_* é processada pelo programa sas APRC_IND_COMUM_INVT.sas */

%PUT &AAAAMM. &AAAA. &MM.;

%BuscarPrefixosIndicador(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., NIVEL_CTRA=1, SO_AG_PAA=0);

PROC SQL;
	CREATE TABLE INVT_PRD AS 
		SELECT
 			t1.AAAA,
			t1.MM,
			t3.AC,
			t2.COMP,
			t1.CD_CLI, 
			t1.CLI_TIPO,
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA,
			t1.PRD, 
			t1.MDLD,        
			SUM(t1.VL_SDO) AS VL_SDO
		FROM LOCAL.INVT_PRD_&AAAAMM. t1
		INNER JOIN WORK.PRD_INVT t2 ON (t1.PRD=t2.PRD AND t1.MDLD=t2.MDLD AND t1.CLI_TIPO=t2.CLI_TIPO)
		INNER JOIN WORK.PREFIXOS_IND_&NR_INDICADOR. t3 ON (t1.PREFDEP=t3.PREFDEP AND t1.CTRA=t3.CTRA)
		WHERE 
				t1.AAAA=&AAAA. 
			AND t1.MM=&MM. 
			AND t2.COMP IS NOT MISSING
			AND t3.PESO > 0
		GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;QUIT;


/*REMOVER POUPANÇA DE ACORDOS DE CARTEIRAS 1000 1040 1080 2082 */
PROC SQL;
	CREATE TABLE WORK.INVT_PRD AS 
		SELECT *
		FROM WORK.INVT_PRD t1
		WHERE NOT (t1.AC IN (1000 1040 1080 2082) AND ((t1.PRD=3 AND t1.MDLD IN (1, 5)) OR (t1.PRD=644 AND t1.MDLD IN (1, 2))))
;QUIT;



/*############################################################################################################################*/
/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS #################################*/

LIBNAME EXT_ANLT "/dados/externo/DIVAR/METAS/conexao/&AASS./rlzd_analitico";

DATA EXT_ANLT.anlt_&NR_INDICADOR._&AAAAMM.;
	SET INVT_PRD;
RUN;

%commandShell("chmod 777 /dados/externo/DIVAR/METAS/conexao/&AASS./rlzd_analitico/anlt_&NR_INDICADOR._&AAAAMM.*");

/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS - FIM ###########################*/
/*############################################################################################################################*/


/*SUMARIZAR PRODUTOS POR COMPONENTE*/
PROC SQL;
	CREATE TABLE WORK.INVT_CLI_NVL_3 AS 
		SELECT 
			t1.AAAA,
			t1.MM,
			t1.CD_CLI,
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.COMP, 
			SUM(t1.VL_SDO) FORMAT=32.2 AS VL_SDO
		FROM WORK.INVT_PRD t1
		GROUP BY 1,2,3,4,5,6,7
;QUIT;

/*SUMARIZAR COMPONENTE EM SEU NIVEL INTERMEDIÁRIO*/
PROC SQL;
	CREATE TABLE WORK.INVT_CLI_NVL_2 AS 
		SELECT
			t1.AAAA,
			t1.MM, 
			t1.CD_CLI, 
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA, 
			t2.COMP_PAI AS COMP, 
			SUM(t1.VL_SDO) FORMAT=32.2 AS VL_SDO
		FROM WORK.INVT_CLI_NVL_3 t1
		LEFT JOIN WORK.IND_COMP_&NR_INDICADOR. t2 ON (t1.COMP=t2.COMP)
		WHERE t2.COMP_PAI IN (26, 27)
		GROUP BY 1,2,3,4,5,6,7
;QUIT;

/*SUMARIZAR NO NÍVEL DO INDICADOR (COMP 0)*/
PROC SQL;
	CREATE TABLE WORK.INVT_CLI_NVL_1 AS 
		SELECT 
			t1.AAAA,
			t1.MM,
			t1.CD_CLI,
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			0 AS COMP, 
			SUM(t1.VL_SDO) FORMAT=32.2 AS VL_SDO
		FROM WORK.INVT_PRD t1
		GROUP BY 1,2,3,4,5,6,7
;QUIT;

/*JUNÇÃO DE TODAS AS SUMARIZAÇÕES DE COMPONENTES*/
DATA INVT_CLI;
	SET INVT_CLI_NVL_1 INVT_CLI_NVL_2 INVT_CLI_NVL_3;
RUN;

PROC SORT DATA=INVT_CLI NODUPKEY; BY _ALL_; QUIT;


/*############################################################################################################################*/
/*# SUMARIZAÇÃO ##############################################################################################################*/

/*SUMARIZAÇÃO POR CARTEIRA*/
PROC SQL;
	CREATE TABLE WORK.INVT_CTRA AS 
		SELECT 
			t1.AAAA,
			t1.MM,
			t1.PREFDEP, 
			t1.CTRA, 
			t1.COMP, 
			SUM(t1.VL_SDO) FORMAT=32.2 AS VLR_RLZ
		FROM WORK.INVT_CLI t1
		GROUP BY 1,2,3,4,5
;QUIT;

/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COL_SUM;
	CREATE TABLE COL_SUM (Coluna CHAR(50), Tipo CHAR(10) );
		/*COLUNAS PARA SUMARIZACAO*/
		INSERT INTO COL_SUM VALUES ('VLR_RLZ', 'SUM');
QUIT;

%SumarizadorCNX(TblSASValores=INVT_CTRA, TblSASColunas=COL_SUM,  NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=INVT_FINAL, AAAAMM=&AAAAMM.);


PROC SQL;
	CREATE TABLE WORK.INVT_FINAL AS 
		SELECT 
			t1.AAAA,
			t1.MM,
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.COMP, 
			t1.VLR_RLZ
		FROM WORK.INVT_FINAL t1
		ORDER BY 1,2,4,5,6
;QUIT;

/*# SUMARIZAÇÃO - FIM ########################################################################################################*/
/*############################################################################################################################*/





/*############################################################################################################################*/
/*# CONEXÃO ##################################################################################################################*/

PROC SQL;
	CREATE TABLE WORK.BASE_CNX AS 
		SELECT 
			t2.IND,
			t1.COMP,
			t2.COMP_PAI,
			t2.ORD_EXI,
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA,
			t1.VLR_RLZ, 
			0 AS VLR_ORC,
			0 AS VLR_ATG,
			&DT_D3. FORMAT=YYMMDDD10. AS POSICAO 
		FROM WORK.INVT_FINAL t1
		LEFT JOIN WORK.IND_COMP_&NR_INDICADOR. t2 ON (t1.COMP=t2.COMP)
		ORDER BY 1,2,3,4,5,7
;QUIT;

PROC SQL;
	CREATE TABLE WORK.BASE_CNX_CLI AS 
		SELECT
			&NR_INDICADOR. AS IND,
			t1.COMP, 
			t1.PREFDEP, 
			t1.UOR,
			t1.CTRA, 
			t1.CD_CLI AS CLI,
			INPUT(PUT(&DT_D3., mmyyn6.),6.) AS MMAAAA, 
			t1.VL_SDO AS VLR
		FROM WORK.INVT_CLI t1
		WHERE t1.COMP NOT IN (0, 26, 27)
		ORDER BY 3, 5, 2, 6
;QUIT;

%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CNX_CLI);
%BaseIndicadorCNX(TabelaSAS=BASE_CNX);

%ExportarCNX_CLI(IND=&NR_INDICADOR., MMAAAA=&MMAAAA.);
%ExportarCNX_IND(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., ORC=0, RLZ=1);
%ExportarCNX_COMP(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., ORC=0, RLZ=1);

/*# CONEXÃO - FIM ############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CKECKOUT #################################################################################################################*/
%indCheckOut();
/*############################################################################################################################*/
