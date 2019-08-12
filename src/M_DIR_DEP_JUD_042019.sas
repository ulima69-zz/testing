
/*#################################################################################################################*/


/************** INICIAR PROCESSO ****************/
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';
%LET Indicador = 243;
%LET Keypass = ;
%LET Relatorio = ;
%ProcessoIniciar();
/************************************************/


/*##################################################################################################################*/


/*##### B I B L I O T E C A S #####*/

LIBNAME LOCAL 		"/dados/infor/producao/IndicadoresGoverno/bases";

LIBNAME DIGOV 		"/dados/externo/DIGOV/GECEN/indicadores";
LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2MCI 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI 	database=BDB2P04;
LIBNAME DB2RDO 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2RDO 	database=BDB2P04;
LIBNAME DB2DJO 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2DJO 	database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;


/*###################################################################################################################*/


/*##### V A R I A V E I S   E   C O N S T A N T E S  #####*/


DATA _NULL_;


  /*D1 = diaUtilAnterior(MDY(02,01,2019));*/
    D1 = diaUtilAnterior(TODAY());
	ANOMES = Put(D1, yymmn6.);
	MES = Put(D1, MONTH.);
	MESANO = Put(D1, yymmn6.);


	CALL SYMPUT('D1',COMPRESS(D1,' '));
  	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));
	CALL SYMPUT('MES',COMPRESS(MES,' '));
	CALL SYMPUT('MESANO',COMPRESS(MESANO,' '));		


RUN; 


%PUT &D1. &ANOMES. &MES. &MESANO. &Indicador.;


/*###################################################################################################################*/


/*##### T A B E L A S #####*/


/*****************/


PROC SQL;
	CREATE TABLE WORK.TRABALHISTAS_SALDO AS 
		SELECT 
			t1.NR_DEPZ, 

			SUM(((t1.VL_SDO_CPTL + t1.VL_CM_SMT + t1.VL_CM_SMT_ANT) - t1.VL_CM_RCPR) + ((t1.VL_JUR_SMT + t1.VL_JUR_SMT_ANT)- t1.VL_JUR_RCPR)) AS VLR

		FROM DB2RDO.DEPZ_OURO t1
		WHERE 
				t1.CD_PRD = 196 
			AND t1.CD_MDLD = 6 
			AND t1.VL_SDO_CPTL NOT = 0

			AND DT_DEPZ <= &D1.

	   GROUP BY t1.NR_DEPZ
	   ORDER BY t1.NR_DEPZ
;QUIT;


PROC SQL;
	CREATE TABLE WORK.TRAB_DADOS AS 
		SELECT 

			t1.NR_DEPZ, 
			t1.VLR, 
			t2.UF_JSTC, 
			t2.CD_CMR, 
			t2.CD_TRN, 
			t2.CD_ORG_TRN

		FROM WORK.TRABALHISTAS_SALDO t1
		LEFT JOIN DB2RDO.PRC_DEPZ_JDCL t2 ON (t1.NR_DEPZ = t2.NR_DEPZ);
QUIT;


PROC SQL;
	CREATE TABLE WORK.TRAB_DADOS2 AS 
		SELECT DISTINCT 

			t1.NR_DEPZ,
            t1.VLR, 
			t1.UF_JSTC, 
			t1.CD_CMR, 
			t1.CD_TRN, 
			t1.CD_ORG_TRN, 
			t4.NM_TRN_JSTC, 
			t3.NM_ORG_JSTC, 
			t3.CD_CLI_ORG_JSTC, 
			t2.NM_CMR_JSTC

		FROM WORK.TRAB_DADOS t1
		LEFT JOIN DB2DJO.ORG_JSTC t3 ON (t1.CD_ORG_TRN = t3.CD_ORG_JSTC AND t1.CD_CMR = t3.CD_CMR_JSTC AND t1.CD_TRN = t3.CD_TRN_JSTC)
		INNER JOIN DB2DJO.CMR_JSTC t2 ON (t1.CD_CMR = t2.CD_CMR_JSTC)
		INNER JOIN DB2DJO.TRN_JSTC t4 ON (t1.CD_TRN = t4.CD_TRN_JSTC)		
;QUIT;


PROC SQL;
	CREATE TABLE WORK.SUM_DADOS AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.NM_TRN_JSTC, 
			t1.CD_CMR, 
			IFC(t1.NM_CMR_JSTC = "AçU", "ASSU", t1.NM_CMR_JSTC) AS NM_CMR_JSTC, 
			t1.CD_ORG_TRN, 
			t1.NM_ORG_JSTC, 
			t1.CD_CLI_ORG_JSTC, 
			SUM(t1.VLR) AS VLR

		FROM WORK.TRAB_DADOS2 t1
		GROUP BY 1,2,3,4,5,6,7,8
;QUIT;


PROC SQL;
	CREATE TABLE WORK.DADOS_MUN AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.NM_TRN_JSTC, 
			t1.CD_CMR, 
			t1.NM_CMR_JSTC, 
			t1.CD_ORG_TRN, 
			t1.NM_ORG_JSTC, 
			t1.CD_CLI_ORG_JSTC, 
            t1.VLR, 
			t2.UF, 
			t2.NM_MUN, 
			INPUT(t2.MCI_REPRES_MUN_BB, 9.) FORMAT=9. AS MCI_MUN, 
			t2.MCI_REPRES_MUN_BB, 
			t2.CAPITAL

		FROM WORK.SUM_DADOS t1
		LEFT JOIN DIGOV.AUX_CAP_DJT_C_ACENTOS t2 ON (t1.UF_JSTC = t2.UF AND t1.NM_CMR_JSTC = t2.NM_MUN)
;QUIT;


DATA AUX_CAP_DJT_C_ACENTOS;
	SET DIGOV.AUX_CAP_DJT_C_ACENTOS;
RUN; 


PROC SQL;
	CREATE TABLE WORK.COM_MCI AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.NM_TRN_JSTC, 
			t1.CD_CMR, 
			t1.NM_CMR_JSTC, 
			t1.CD_ORG_TRN, 
			t1.NM_ORG_JSTC, 
			t1.CD_CLI_ORG_JSTC, 
			t1.VLR, 
			t1.UF, 
			t1.NM_MUN, 
			t1.MCI_MUN, 
			t1.MCI_REPRES_MUN_BB, 
			t1.CAPITAL

		FROM WORK.DADOS_MUN t1
		WHERE t1.MCI_REPRES_MUN_BB NOT IS MISSING
;QUIT;


PROC SQL;
	CREATE TABLE WORK.SEM_MCI AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.NM_TRN_JSTC, 
			t1.CD_CMR, 
			t1.NM_CMR_JSTC, 
			t1.CD_ORG_TRN, 
			t1.NM_ORG_JSTC, 
			t1.CD_CLI_ORG_JSTC, 
			t1.VLR, 
			t1.UF, 
			t1.NM_MUN, 
			t1.MCI_MUN, 
			t1.MCI_REPRES_MUN_BB, 
			t1.CAPITAL

		FROM WORK.DADOS_MUN t1
		WHERE t1.MCI_REPRES_MUN_BB IS MISSING
;QUIT;


PROC SQL;
	CREATE TABLE WORK.AJUSTE_SEM_MCI AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.NM_TRN_JSTC, 
			t1.CD_CMR, 
			t1.NM_CMR_JSTC, 
			t1.CD_ORG_TRN, 
			t1.NM_ORG_JSTC, 
			t1.CD_CLI_ORG_JSTC, 
			t1.VLR, 
			t2.UF, 
			t2.NM_MUN, 
			INPUT(t2.MCI_REPRES_MUN_BB, 9.) AS MCI_MUN, 
			t2.MCI_REPRES_MUN_BB, 
			t2.CAPITAL

		FROM WORK.SEM_MCI t1
		LEFT JOIN DIGOV.AUX_CAP_DJT_S_ACENTOS t2 ON (t1.UF_JSTC = t2.UF AND t1.NM_CMR_JSTC = t2.NM_MUN)
		WHERE t2.MCI_REPRES_MUN_BB NOT IS MISSING

;QUIT;


DATA APPEND_TABLE_0000;
	SET COM_MCI	AJUSTE_SEM_MCI;
RUN;


/*ENCARTEIRANDO*/
/*ENCARTEIRANDO*/


PROC SQL;
	CREATE TABLE WORK.MCI_REALIZADO_ENCART AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.NM_TRN_JSTC, 
			t1.CD_CMR, 
			t1.NM_CMR_JSTC, 
			t1.CD_ORG_TRN, 
			t1.NM_ORG_JSTC, 
			t1.CD_CLI_ORG_JSTC, 
			t1.VLR, 
			t1.UF, 
			t1.NM_MUN, 
			t1.MCI_MUN, 
			t1.MCI_REPRES_MUN_BB, 
			t1.CAPITAL, 

			t2.CD_PRF_DEPE, 
            t2.NR_SEQL_CTRA_ATB AS NR_SEQL_CTRA,             
			t2.CD_TIP_CTRA

		FROM WORK.APPEND_TABLE_0000 t1
		LEFT JOIN COMUM.PAI_REL_&ANOMES. t2 ON (t1.MCI_MUN = t2.CD_CLI)
				
		WHERE t2.CD_TIP_CTRA NOT = 440

;QUIT;


/***************/
/***************/


PROC SQL;
	CREATE TABLE WORK.CLI_CTRA_JUD AS 
		SELECT 

			t1.CD_CLI, 
			t1.CD_PRF_DEPE, 
			t1.NR_SEQL_CTRA, 
			t2.CD_TIP_CTRA
		FROM DB2REL.CLI_CTRA t1
		INNER JOIN DB2REL.CTRA_CLI t2 ON (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE AND t1.NR_SEQL_CTRA = t2.NR_SEQL_CTRA)
		LEFT JOIN DB2MCI.PESSOA_JURIDICA t3 ON (t1.CD_CLI = t3.F_CLIENTE_COD)

		WHERE 

			t2.CD_TIP_CTRA=405 AND
			((FIND(t3.NOM_FANT, "PLANO")=0 AND
			FIND(t3.NOM_FANT, "SAUDE")=0 AND
			FIND(t3.NOM_FANT, "SUPERIOR")=0)) AND
			((FIND(t3.NOM_FANT, "TRABALHO")<>0 OR
			FIND(t3.NOM_FANT, "TRT")<>0))
;QUIT;


PROC SQL;
	CREATE TABLE WORK.AJUSTE_CAPITAIS AS 
		SELECT 

			t1.UF_JSTC, 
			t1.CD_TRN, 
			t1.CD_CMR, 
			t1.CD_ORG_TRN, 
			t1.CD_CLI_ORG_JSTC, 
			t1.VLR,
			t1.UF, 
			t1.MCI_REPRES_MUN_BB, 

			(CASE
				WHEN t1.CAPITAL = "CAPITAL" AND t2.CD_PRF_DEPE IS NOT MISSING THEN t2.CD_CLI
				WHEN t1.CAPITAL = "CAPITAL" AND t2.CD_PRF_DEPE IS MISSING THEN t1.MCI_MUN
				WHEN t1.CAPITAL IS MISSING THEN t1.MCI_MUN
				ELSE 0
			END) AS MCI,
 
			t1.CAPITAL, 

			t1.CD_PRF_DEPE, 

			(CASE
				WHEN t1.CAPITAL = "CAPITAL" AND  t2.CD_PRF_DEPE IS NOT MISSING THEN t2.NR_SEQL_CTRA
				WHEN t1.CAPITAL = "CAPITAL" AND t2.CD_PRF_DEPE IS MISSING THEN t1.NR_SEQL_CTRA
				WHEN t1.CAPITAL IS MISSING THEN t1.NR_SEQL_CTRA
				ELSE 0
			END) AS NR_SEQL_CTRA, 

			(CASE
				WHEN t1.CAPITAL = "CAPITAL" AND t2.CD_PRF_DEPE IS NOT MISSING THEN t2.CD_TIP_CTRA
				WHEN t1.CAPITAL = "CAPITAL" AND t2.CD_PRF_DEPE IS MISSING THEN t1.CD_TIP_CTRA
				WHEN t1.CAPITAL IS MISSING THEN t1.CD_TIP_CTRA
				ELSE 0
				END) AS CD_TIP_CTRA

		FROM WORK.MCI_REALIZADO_ENCART t1
		LEFT JOIN WORK.CLI_CTRA_JUD t2 ON (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE)
;QUIT;


PROC SQL;
	CREATE TABLE WORK.REALIZADO AS 
		SELECT 

			t1.MCI_REPRES_MUN_BB, 
			t1.MCI, 
			t1.NM_MUN, 
			t1.UF, 
			t1.CAPITAL, 
			t1.INDICADOR, 
			t1.SALDO_INIC, 
			t1.M1, 
			t1.M2, 
			t1.M3, 
			t1.M4, 
			t1.M5, 
			t1.M6, 
			t2.CD_PRF_DEPE, 
			IFN(t2.CD_TIP_CTRA IN (410 420), 7002, t2.NR_SEQL_CTRA) AS NR_SEQL_CTRA,
			t2.CD_TIP_CTRA, 
			(SUM(t2.VLR)) AS VLR_RLZD 

		FROM DIGOV.META_DIRECIONADOR_CAP_DJT_12019 t1
		LEFT JOIN WORK.AJUSTE_CAPITAIS t2 ON (t1.MCI = t2.MCI)		
		GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
;QUIT;


PROC SQL;
	CREATE TABLE WORK.REALIZADO_1 AS 
		SELECT

           t1.MCI,
		   t1.CD_PRF_DEPE AS PREFDEP,
		   t1.NR_SEQL_CTRA AS CTRA,
		   t1.M&MES. AS VL_ORC,			
           t1.VLR_RLZD

		FROM WORK.REALIZADO t1	
        WHERE t1.CD_PRF_DEPE IS NOT MISSING AND t1.NR_SEQL_CTRA IS NOT MISSING	
		ORDER BY 1, 2, 3
		
;QUIT;

%BuscarPrefixosIndicador(IND=243, MMAAAA=&MESANO., NIVEL_CTRA=1, SO_AG_PAA=1);

PROC SQL;
	CREATE TABLE WORK.DEP_JUD_FINAL AS 
		SELECT DISTINCT

		   t1.PREFDEP,
		   t1.CTRA,
		   SUM(t1.VL_ORC) FORMAT 32.2 AS VL_ORC,			
           SUM(t1.VLR_RLZD) FORMAT 32.2 AS VL_RLZD

		FROM WORK.REALIZADO_1 t1
    INNER JOIN PREFIXOS_IND_000000180 t2 ON t1.PREFDEP = t2.PREFDEP AND t2.CTRA = t2.CTRA	
		GROUP BY 1, 2
		ORDER BY 1, 2
		
;QUIT;


/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/


PROC SQL;
	DROP TABLE ColunasSumarizador;
	CREATE TABLE ColunasSumarizador (Coluna CHAR(50), Tipo CHAR(10) );
		/*COLUNAS PARA SUMARIZACAO*/
		INSERT INTO ColunasSumarizador VALUES ('VL_ORC', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('VL_RLZD', 'SUM');

QUIT;


%SumarizadorCNX(TblSASValores=DEP_JUD_FINAL, TblSASColunas=ColunasSumarizador,  NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=DEP_JUD_FINAL_SUM, AAAAMM=&ANOMES.);


PROC SQL;
	CREATE TABLE WORK.TABELA_FINAL AS 
		SELECT DISTINCT

		   t1.PREFDEP,
		   t1.UOR,
		   t1.CTRA,
		   t1.VL_ORC,			
           t1.VL_RLZD

		FROM DEP_JUD_FINAL_SUM t1		
		ORDER BY 1, 2
		
;QUIT;



/*#################################################################################################################*/
/*##### CRIAÇÃO DE ORÇADO #########################################################################################*/


/*REMOVER OS HISTORIOS DO ORÇAMENTO DO ANO MES DE REFERENCIA DO PROCESSAMENTO*/

LIBNAME LIBORC 		"/dados/gecen/interno/cnx_orc/&AAAA./&Indicador.";

DATA LIBORC.IND_ORC_HST_&Indicador.;
	SET LIBORC.IND_ORC_HST_&Indicador.;
	WHERE MMAAAA <> &MESANO.; 
RUN;


PROC SQL;
    CREATE TABLE WORK.ORCADO AS
        SELECT
            &Indicador. AS ind,
            0 AS comp,
            t1.uor,
            t1.prefdep,
            t1.ctra,
            t1.VL_ORC as vlr,
			input(Put(&D1. , mmyyn6.),6.) as mmaaaa
        FROM WORK.TABELA_FINAL t1;
QUIT;


/*FUNÇÃO CRIAR ATUALIZAR ORÇADO*/
%BASE_IND_ORC(TabelaSAS=ORCADO);


/*#################################################################################################################*/
/*#################################################################################################################*/


/**ENVIANDO PARA O CONEXÃO**/
/**ENVIANDO PARA O CONEXÃO**/
/**ENVIANDO PARA O CONEXÃO**/
/**ENVIANDO PARA O CONEXÃO**/


PROC SQL;
	CREATE TABLE WORK.BASE_CNX AS 
		SELECT 
			&Indicador. AS IND,
			0 AS COMP,
			0 AS COMP_PAI,
			0 AS ORD_EXI,
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA,
			t1.VL_RLZ AS VLR_RLZ,
			t1.VL_ORC AS VLR_ORC,
			0 AS VLR_ATG,
			&D1. FORMAT=DateMysql. AS POSICAO 
		FROM WORK.FINAL t1;
QUIT;

DATA BASE_CNX_COMP_1;
	SET BASE_CNX;
	COMP=1;
RUN;

DATA BASE_CNX;
	SET BASE_CNX BASE_CNX_COMP_1;
RUN;

PROC SORT DATA=BASE_CNX; BY IND COMP COMP_PAI ORD_EXI UOR CTRA; QUIT;

/*%BaseIndicadorCNX(TabelaSAS=BASE_CNX);
%ExportarCNX_IND(IND=&Indicador., MMAAAA=&MESANO., ORC=0, RLZ=1);
%ExportarCNX_COMP(IND=&Indicador., MMAAAA=&MESANO., ORC=0, RLZ=1);*/


PROC SQL;
	CREATE TABLE WORK.BASE_CNX_CLI AS 
		SELECT
			&Indicador. AS IND,
			1 AS COMP, 
			t1.PREFDEP, 
			input(t2.UOR,9.) as UOR,
			t1.CTRA AS CTRA, 
			t1.MCI AS CLI,
			INPUT(PUT(&D1., mmyyn6.),6.) AS MMAAAA, 
			t1.VL_RLZ AS VLR
		FROM WORK.REALIZADO_1 t1
		LEFT JOIN IGR.IGRREDE_&MESANO. t2 ON(t1.PREFDEP=input(t2.PREFDEP,4.))
;QUIT;


/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CNX_CLI);
%ExportarCNX_CLI(IND=&Indicador., MMAAAA=&MESANO.);*/

/**************************************/

x cd /dados/infor/producao/IndicadoresGoverno/bases ;
x cd /dados/externo/DIGOV/GECEN/indicadores ;

x chmod 2777 *;

