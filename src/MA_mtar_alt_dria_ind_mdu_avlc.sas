/*+------------------------------------------------------------------------------------------------+ 
  | SCRIPT..: R182AA - Rotina de Verificação do Módulo Avaliação                                   |
  | AUTOR...: Márcio Vinícius de Almeida                                                           |
  | OBJETIVO: Verificar diariamente alterações no orçamento e realizado de meses anteriores do     |
  |           Módulo Avaliação                                                                     |
  | VERSÃO..: VRS001 - 15/10/2018 - F6794004 (Márcio) - Desenvolvimento                            |
  |                                                                                                |
  +------------------------------------------------------------------------------------------------+ 
*/ 
/*+------------------------------------------------------------------------------------------------+ 
  | ÍNDICE DE SEÇÕES                                                                               |  
  +------------------------------------------------------------------------------------------------+
  | 000000 - SEÇÃO CONECTAR 
  | 100000 - SEÇÃO DE CONSULTAS AOS DADOS LEGADOS
  | 200000 - SEÇÃO DE APLICAÇÃO DE FILTROS SISTÊMICOS 
  | 300000 - SEÇÃO CRIAR TABELAS COM O ORÇAMENTO E REALIZADO DO SEMESTRE - VISÃO DEPE. E VISÃO CTRA.
  | 400000 - SEÇÃO COMPARAR POSIÇÃO ATUAL COM A POSIÇÃO ANTERIOR - VISÃO DEPE. E VISÃO CTRA.
  | /*
/*+-----------------------------------------------------------------------------------------------+ 
  | 000000 - SEÇÃO CONECTAR                                                                         
  +-----------------------------------------------------------------------------------------------*/
%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";
%conectardb2(atb);
%conectardb2(ARH);
%conectardb2(MST);

libname db2rel 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;
libname avlc_grl     "/dados/infor/conexao/2018";
libname cnx_bkp     "/dados/infor/conexao/2018/bkp";
libname pg_ind 		postgres server="172.16.15.104" port=5432 user="gecen_processamento" password='procgecen17' database="portal" schema="indicadores";
libname infcnx18 "/dados/infor/conexao/2018";
libname igr "/dados/infor/producao/dependencias";
libname relfotos "/dados/prep/rel/fotos";
libname cnx "/dados/gecen/interno/mbz_avlc_cnx";
libname spot "/dados/gestao/rotinas/_spotfire/";
libname mst oracle user=sas_gecen password=Gecen77 path="sas_dirco" schema="mst";


/******************************************************************************************************************************************************
 DIRETÓRIOS DE APURACAO DO ORCADO E REALIZADO DOS MODULOS CONEXÃO E MOBILIZAÇÃO
******************************************************************************************************************************************************/
libname avl_grl  "/dados/gecen/interno/mbz_avlc_cnx/avaliacao/geral/";
libname avl_orc  "/dados/gecen/interno/mbz_avlc_cnx/avaliacao/orcado/";
libname avl_rlzd "/dados/gecen/interno/mbz_avlc_cnx/avaliacao/realizado/";
libname local    "/dados/gecen/interno/mbz_avlc_cnx/avaliacao/";

/******************************************************************************************************************************************************
 CONTROLE DE DATAS
******************************************************************************************************************************************************/
DATA _NULL_;
	DATA_REF = TODAY();         /* <------ Comentar aqui caso seja parametrizada uma data especificada que não hoje.*/
/* 	DATA_REF = MDY(10,09,2018); /* <------ Informar aqui a data para processamento ou manter comentado. */;
	AAMMDD = PUT(TODAY(), YYMMDD7.);
	DT_SAS = PUT(DATA_REF, 32.);
	MMAAAA = PUT(DATA_REF, MMYYN6.);
	AAAAMM = PUT(DATA_REF, YYMMN6.);
	AAAA = PUT(DATA_REF, YEAR.);
	MM = PUT(INPUT(PUT(DATA_REF, MONTH.), 2.),Z2.);
	IF MM >= 7 THEN;
	   PRMO_MM = 7;
    IF MM <= 6 THEN;
	   PRMO_MM = 1;
    
	CALL SYMPUT('DT_SAS',COMPRESS(DT_SAS,' '));
	CALL SYMPUT('AAMMDD',COMPRESS(AAMMDD,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
/*	CALL SYMPUT('AAAAMM_LIMIT',COMPRESS(AAAAMM_LIMIT,' '));*/
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('MM',COMPRESS(MM,' '));
	CALL SYMPUT('PRMO_MM',COMPRESS(PRMO_MM,' '));
RUN;

%LET DT_PRCT_ATU = &AAMMDD;
%LET DT_AA_ATU = &AAAA;
%LET DT_MM_ATU = &MM;
%LET DT_MMAAAA = &MMAAAA;
%LET MM_INC_SMT = &PRMO_MM;
%PUT &MM_INC_SMT;
/*+-----------------------------------------------------------------------------------------------+ 
  | 000999 - SEÇÃO CONECTAR - FIM                                                                        
  +-----------------------------------------------------------------------------------------------*/
%macro deletarTabelas;
%if %sysfunc(exist(CNX.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE CNX.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(AVL_GRL.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE AVL_GRL.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(AVL_ORC.REL_DIF_ORC_MDU_AVLC_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE AVL_ORC.REL_DIF_ORC_MDU_AVLC_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(AVL_RLZD.REL_DIF_RLZD_MDU_AVLC_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE AVL_RLZD.REL_DIF_RLZD_MDU_AVLC_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(AVL_ORC.SINTETICO_ORC)) %then
	%do;
		PROC SQL;
			DROP TABLE AVL_ORC.SINTETICO_ORC;
		Quit;
	%end;
%if %sysfunc(exist(AVL_RLZD.SINTETICO_RLZD)) %then
	%do;
		PROC SQL;
			DROP TABLE AVL_RLZD.SINTETICO_RLZD;
		Quit;
	%end;
%mend; %deletarTabelas;

/*+-----------------------------------------------------------------------------------------------+ 
  | 100000 - SEÇÃO DE CONSULTAS AOS DADOS LEGADOS                                                                         
  +-----------------------------------------------------------------------------------------------*/
	PROC SQL; 
	   CREATE TABLE DB2ATB_VL_APRD_IN_UOR AS 
	   SELECT DISTINCT t1.CD_MOD_AVLC, 
	          t1.NR_PTC_MOD_AVLC, 
	          t1.CD_IN_MOD_AVLC, 
	          t2.NM_IN_MOD_AVLC, 
	          t2.NM_RDZ_APSC_IN, 
	          t2.NM_APSC_IN, 
	          t1.MM_VL_APRD_IN, 
	          t1.AA_VL_APRD_IN, 
	          t1.CD_UOR, 
	          t1.CD_TTLZ_MOD_AVLC, 
	          t1.VL_META_IN, 
	          t1.VL_RLZD_ANT, 
	          t1.VL_RLZD_IN, 
	          t1.PC_ATGT_IN, 
	          t1.QT_PTO_IN, 
	          t1.CD_AGPT_PTO_UTZD, 
	          t1.NR_SEQL_FASE_IN, 
	          t1.CD_MOD_FASE_IN, 
	          t1.CD_AGPT_FASE_UTZD, 
	          t1.VL_ATGT_PRX_FASE, 
	          t1.VL_ATGT_FASE_PSZD, 
	          t1.VL_ATGT_ULT_FASE, 
	          t1.VL_ATGT_FASE_ANT, 
	          t1.DT_ATL_VL_IN, 
	          t1.CD_NVL_UOR, 
	          t1.CD_NVL_UOR_RGNL, 
	          t1.CD_UOR_ADMC_RGNL, 
	          t1.CD_NVL_UOR_SPCA, 
	          t1.CD_UOR_SPCA, 
	          t1.CD_UOR_DRTA, 
	          t1.QT_PESO_APRD_IN, 
	          t1.QT_PTO_ACM_UOR, 
	          t1.CD_NTZ_FLZ, 
	          t1.CD_EST_FLZ
	      FROM DB2ATB.VL_APRD_IN_UOR t1
	           INNER JOIN DB2ATB.IN_MOD_AVLC t2 ON (t1.CD_IN_MOD_AVLC = t2.CD_IN_MOD_AVLC)
	      WHERE t1.AA_VL_APRD_IN = &DT_AA_ATU
	        AND t1.MM_VL_APRD_IN >= &MM_INC_SMT;
	QUIT;

	/**********************************************************************************************************************
	 CONSULTAR TABELA COMPLETA DB2ATB.VL_APRD_IN_CTRA PARA CONSULTA DE ORÇADO E REALIZADO NO CONEXÃO EM NÍVEL DE CARTEIRAS.
	/*********************************************************************************************************************/
	PROC SQL;
	   CREATE TABLE DB2ATB_VL_APRD_IN_CTRA AS 
	   SELECT t1.CD_MOD_AVLC, 
	          t1.NR_PTC_MOD_AVLC, 
	          t1.CD_IN_MOD_AVLC, 
	          t1.MM_VL_APRD_IN, 
	          t1.AA_VL_APRD_IN, 
	          t1.CD_UOR_CTRA, 
	          t1.NR_SEQL_CTRA, 
	          t1.VL_META_IN, 
	          t1.VL_RLZD_ANT, 
	          t1.VL_RLZD_IN, 
	          t1.PC_ATGT_IN, 
	          t1.QT_PTO_IN, 
	          t1.CD_AGPT_PTO_UTZD, 
	          t1.NR_SEQL_FASE_IN, 
	          t1.CD_MOD_FASE_IN, 
	          t1.CD_AGPT_FASE_UTZD, 
	          t1.VL_ATGT_PRX_FASE, 
	          t1.VL_ATGT_FASE_PSZD, 
	          t1.VL_ATGT_ULT_FASE, 
	          t1.VL_ATGT_FASE_ANT, 
	          t1.DT_ATL_VL_IN, 
	          t1.CD_NVL_UOR_CTRA, 
	          t1.CD_NVL_UOR_RGNL, 
	          t1.CD_UOR_ADMC_RGNL, 
	          t1.CD_NVL_UOR_SPCA, 
	          t1.CD_UOR_SPCA, 
	          t1.CD_UOR_DRTA, 
	          t1.QT_PESO_APRD_IN, 
	          t1.QT_PTO_ACM_CTRA, 
	          t1.CD_NTZ_FLZ, 
	          t1.CD_EST_FLZ
	      FROM DB2ATB.VL_APRD_IN_CTRA t1
	      WHERE t1.AA_VL_APRD_IN = &DT_AA_ATU
	        AND t1.MM_VL_APRD_IN >= &MM_INC_SMT;
	QUIT;

	/********************************************************************************************
	 CONSULTAR TABELA COMPLETA DB2ATB_MOD_AVLC PARA CONSULTA DE ACORDOS VÁLIDOS.
	/********************************************************************************************/
	PROC SQL;
	   CREATE TABLE DB2ATB_MOD_AVLC AS 
	   SELECT t1.CD_MOD_AVLC, 
	          t1.NR_PTC_MOD_AVLC, 
	          t1.CD_UOR_GST, 
	          t1.NM_MOD_AVLC, 
	          t1.NM_RDZ_APSC_MOD, 
	          t1.NM_APSC_MOD_AVLC, 
	          t1.MM_INC_VLD_MOD, 
	          t1.AA_INC_VLD_MOD, 
	          t1.MM_FIM_VLD_MOD, 
	          t1.AA_FIM_VLD_MOD, 
	          t1.CD_TIP_MOD_AVLC, 
	          t1.CD_TIP_CTRA_CLI, 
	          t1.CD_AGPT_FXA_FASE, 
	          t1.TX_DCR_MOD_AVLC, 
	          t1.DT_ULT_PRCT_MOD, 
	          t1.IN_MOD_AVLC_PRCT, 
	          t1.IN_BLQ_MOD_AVLC, 
	          t1.IN_MOD_REL_REDE, 
	          t1.CD_TIP_REL_REDE
	      FROM DB2ATB.MOD_AVLC t1
	     WHERE t1.MM_INC_VLD_MOD >= &MM_INC_SMT AND t1.AA_INC_VLD_MOD = &DT_AA_ATU
		   AND t1.MM_FIM_VLD_MOD >= &DT_MM_ATU  AND t1.AA_INC_VLD_MOD >= &DT_AA_ATU;
	QUIT;

	/********************************************************************************************
	 CONSULTAR TABELA COMPLETA DB2ATB_IN_MOD_AVLC PARA CONSULTA DE INDICADORES VÁLIDOS.
	/********************************************************************************************/

	PROC SQL;
	   CREATE TABLE DB2ATB_IN_MOD_AVLC AS 
	   SELECT t1.CD_IN_MOD_AVLC, 
	          t1.NM_IN_MOD_AVLC, 
	          t1.NM_RDZ_APSC_IN, 
	          t1.NM_APSC_IN, 
	          t1.MM_INC_VLD_IN, 
	          t1.AA_INC_VLD_IN, 
	          t1.MM_FIM_VLD_IN, 
	          t1.AA_FIM_VLD_IN, 
	          t1.CD_FMT_APSC_VL, 
	          t1.CD_FMLA_PC_ATGT, 
	          t1.IN_SNLC_IN, 
	          t1.IN_APRC_VL_ZERO, 
	          t1.IN_CDEC_PDRO_IN, 
	          t1.QT_CDEC_IN_MOD, 
	          t1.IN_DVS_ZERO_IN, 
	          t1.VL_DVS_ZERO_IN, 
	          t1.TX_DCR_IN_MOD_AVLC, 
	          t1.CD_TIP_PTAC_ACM_IN, 
	          t1.CD_AGPT_FXA_FASE, 
	          t1.CD_FMLA_MTO_MTTO, 
	          t1.CD_UOR_GST_IN
	      FROM DB2ATB.IN_MOD_AVLC t1;
	QUIT;

	/***************************************************************************************************
	 CONSULTAR TABELA DB2ARH.ARH215_CADASTRO_BASICO PARA TRAZER AS DEPEDÊNCIAS E UOR COM FUNCIS LOTADOS.
	/**************************************************************************************************/
	PROC SQL;
	   CREATE TABLE DB2_ARH215_CADASTRO_BASICO AS 
	   SELECT t1.DEP_LOTACAO_215, 
	          t1.CD_UOR_LCZC, 
	          /* QTD_TTL_MATRICULA_215 */
	          (COUNT(t1.MATRICULA_215)) AS QTD_TTL_MATRICULA_215
	      FROM DB2ARH.ARH215_CADASTRO_BASICO t1
	      WHERE t1.DEP_LOTACAO_215 NOT = 0 AND t1.SITUACAO_215 BETWEEN 0 AND 599
	      GROUP BY t1.DEP_LOTACAO_215,
	               t1.CD_UOR_LCZC;
	QUIT;

/*+-----------------------------------------------------------------------------------------------+ 
  | 100999 - SEÇÃO DE CONSULTAS AOS DADOS LEGADOS - FIM                                                                      
  +-----------------------------------------------------------------------------------------------*/

/*+-----------------------------------------------------------------------------------------------+ 
  | 200000 - SEÇÃO DE APLICAÇÃO DE FILTROS SISTÊMICOS                                                                          
  +-----------------------------------------------------------------------------------------------*/
	PROC SQL;
	   CREATE TABLE BASE_VL_APRD_IN_UOR AS 
	   SELECT t2.CD_MOD_AVLC, 
	          t2.NR_PTC_MOD_AVLC, 
	          t2.CD_IN_MOD_AVLC, 
	          t2.NM_IN_MOD_AVLC, 
	          t2.NM_RDZ_APSC_IN, 
	          t2.NM_APSC_IN, 
	          t2.MM_VL_APRD_IN, 
	          t2.AA_VL_APRD_IN, 
	          t2.CD_UOR, 
	          t2.CD_TTLZ_MOD_AVLC, 
	          t2.VL_META_IN, 
	          t2.VL_RLZD_ANT, 
	          t2.VL_RLZD_IN, 
	          t2.PC_ATGT_IN, 
	          t2.QT_PTO_IN, 
	          t2.CD_AGPT_PTO_UTZD, 
	          t2.NR_SEQL_FASE_IN, 
	          t2.CD_MOD_FASE_IN, 
	          t2.CD_AGPT_FASE_UTZD, 
	          t2.VL_ATGT_PRX_FASE, 
	          t2.VL_ATGT_FASE_PSZD, 
	          t2.VL_ATGT_ULT_FASE, 
	          t2.VL_ATGT_FASE_ANT, 
	          t2.DT_ATL_VL_IN, 
	          t2.CD_NVL_UOR, 
	          t2.CD_NVL_UOR_RGNL, 
	          t2.CD_UOR_ADMC_RGNL, 
	          t2.CD_NVL_UOR_SPCA, 
	          t2.CD_UOR_SPCA, 
	          t2.CD_UOR_DRTA, 
	          t2.QT_PESO_APRD_IN, 
	          t2.QT_PTO_ACM_UOR, 
	          t2.CD_NTZ_FLZ, 
	          t2.CD_EST_FLZ
	      FROM DB2ATB_VL_APRD_IN_UOR t2, DB2ATB_MOD_AVLC t1, DB2_ARH215_CADASTRO_BASICO t3
	      WHERE (t2.CD_MOD_AVLC = t1.CD_MOD_AVLC AND t2.CD_UOR = t3.CD_UOR_LCZC);
	QUIT;

	PROC SQL;
	   CREATE TABLE BASE_VL_APRD_IN_CTRA AS 
	   SELECT t2.CD_MOD_AVLC, 
	          t4.NM_IN_MOD_AVLC, 
	          t4.NM_RDZ_APSC_IN, 
	          t4.NM_APSC_IN, 
	          t2.NR_PTC_MOD_AVLC, 
	          t2.CD_IN_MOD_AVLC, 
	          t2.MM_VL_APRD_IN, 
	          t2.AA_VL_APRD_IN, 
	          t2.CD_UOR_CTRA, 
	          t2.NR_SEQL_CTRA, 
	          t2.VL_META_IN, 
	          t2.VL_RLZD_ANT, 
	          t2.VL_RLZD_IN, 
	          t2.PC_ATGT_IN, 
	          t2.QT_PTO_IN, 
	          t2.CD_AGPT_PTO_UTZD, 
	          t2.NR_SEQL_FASE_IN, 
	          t2.CD_MOD_FASE_IN, 
	          t2.CD_AGPT_FASE_UTZD, 
	          t2.VL_ATGT_PRX_FASE, 
	          t2.VL_ATGT_FASE_PSZD, 
	          t2.VL_ATGT_ULT_FASE, 
	          t2.VL_ATGT_FASE_ANT, 
	          t2.DT_ATL_VL_IN, 
	          t2.CD_NVL_UOR_CTRA, 
	          t2.CD_NVL_UOR_RGNL, 
	          t2.CD_UOR_ADMC_RGNL, 
	          t2.CD_NVL_UOR_SPCA, 
	          t2.CD_UOR_SPCA, 
	          t2.CD_UOR_DRTA, 
	          t2.QT_PESO_APRD_IN, 
	          t2.QT_PTO_ACM_CTRA, 
	          t2.CD_NTZ_FLZ, 
	          t2.CD_EST_FLZ
	      FROM DB2ATB_VL_APRD_IN_CTRA t2, DB2ATB_MOD_AVLC t1, DB2_ARH215_CADASTRO_BASICO t3, DB2ATB_IN_MOD_AVLC t4
	      WHERE t2.CD_MOD_AVLC = t1.CD_MOD_AVLC 
		    AND t2.CD_IN_MOD_AVLC = t4.CD_IN_MOD_AVLC
	        AND t2.CD_UOR_CTRA = t3.CD_UOR_LCZC;
	QUIT;
/*+-----------------------------------------------------------------------------------------------+ 
  | 200999 - SEÇÃO DE APLICAÇÃO DE FILTROS SISTÊMICOS - FIM                                                                        
  +-----------------------------------------------------------------------------------------------*/
/*+-----------------------------------------------------------------------------------------------+ 
  | 300000 - SEÇÃO CRIAR TABELAS DE ORÇAMENTO/REALIZADO DO SEMESTRE - VISÃO DEPE/VISÃO CTRA                                                                        
  +-----------------------------------------------------------------------------------------------*/
	/************************************************************************************************************************
	  GERAR MARCAÇÃO DE DEPÊNDNCIAS COM E SEM VALORES DE ORÇAMENTO E REALZIADO APURADOS - VISÃO POR DEPENDÊNCIA
	/***********************************************************************************************************************/
	PROC SQL;
	   CREATE TABLE MDU_AVLC_DEPE AS 
	   SELECT DISTINCT t1.CD_MOD_AVLC, 
	          t1.NM_IN_MOD_AVLC,
	          t1.CD_IN_MOD_AVLC,
	          t1.NM_RDZ_APSC_IN, 
			  t1.NM_APSC_IN, 
	          t1.MM_VL_APRD_IN, 
	          t1.AA_VL_APRD_IN, 
			  t1.CD_UOR AS CD_UOR_CTRA, 
	          t2.CD_PRF, 
	          t2.NM_DEPE, 
	          0 AS NR_SEQL_CTRA,
	          t1.VL_META_IN FORMAT=commax20.2 AS VL_META_IN, 
	          t1.VL_RLZD_ANT FORMAT=commax20.2 AS VL_RLZD_ANT, 
	          t1.VL_RLZD_IN FORMAT=commax20.2 AS VL_RLZD_IN, 
	            IFN(t1.VL_META_IN, 1, 0) AS FLAG_META, 
	            IFC(t1.VL_META_IN, 'SIM', 'NAO') AS COM_META, 
	            IFN(t1.VL_RLZD_IN, 1, 0) AS FLAG_RLZD_IN,
	            IFC(t1.VL_RLZD_IN, 'SIM', 'NAO') AS COM_RLZD_ATU
	      FROM BASE_VL_APRD_IN_UOR t1
	           INNER JOIN MST.VW_MST606 t2 ON (t1.CD_UOR = t2.CD_UOR)
	      WHERE t1.AA_VL_APRD_IN = 2019 AND t2.AA = &DT_AA_ATU AND t2.MM IN (1, 2, 3)
		    AND t1.NM_RDZ_APSC_IN NOT IN 
	           (
	           'Bloco Avaliação-Pts',
	           'Bloco Resultado-Pts',
	           'Pontos Mobilização',
	           'Pontuação Placar',
	           'Valor Zero',
	           'VALOR.ZERO'
	           );
	QUIT;

	/************************************************************************************************************************
	  GERAR MARCAÇÃO DE DEPÊNDNCIAS COM E SEM VALORES DE ORÇAMENTO E REALZIADO APURADOS - VISÃO POR CARTEIRA
	/***********************************************************************************************************************/
	PROC SQL;
	   CREATE TABLE MDU_AVLC_CTRA AS 
	   SELECT DISTINCT t1.CD_MOD_AVLC, 
	          t1.NM_IN_MOD_AVLC,
	          t1.CD_IN_MOD_AVLC,
	          t1.NM_RDZ_APSC_IN, 
	          t1.MM_VL_APRD_IN, 
	          t1.AA_VL_APRD_IN, 
			  t1.CD_UOR_CTRA,
	          t2.CD_PRF, 
	          t2.NM_DEPE, 
	          t1.NR_SEQL_CTRA, 
	          t1.VL_META_IN FORMAT=commax20.2 AS VL_META_IN, 
	          t1.VL_RLZD_ANT FORMAT=commax20.2 AS VL_RLZD_ANT, 
	          t1.VL_RLZD_IN FORMAT=commax20.2 AS VL_RLZD_IN, 
	          IFN(t1.VL_META_IN, 1, 0) AS FLAG_META, 
	          IFC(t1.VL_META_IN, 'SIM', 'NAO') AS COM_META, 
	          IFN(t1.VL_RLZD_IN, 1, 0) AS FLAG_RLZD_IN,
	          IFC(t1.VL_RLZD_IN, 'SIM', 'NAO') AS COM_RLZD_ATU
	      FROM BASE_VL_APRD_IN_CTRA t1
	           INNER JOIN MST.VW_MST606 t2 ON (t1.CD_UOR_CTRA = t2.CD_UOR)
	      WHERE t1.AA_VL_APRD_IN = &DT_AA_ATU AND t2.AA = &DT_AA_ATU AND t2.MM = &DT_MM_ATU
		    AND t1.NM_RDZ_APSC_IN NOT IN 
	           (
	           'Bloco Avaliação-Pts',
	           'Bloco Resultado-Pts',
	           'Pontos Mobilização',
	           'Pontuação Placar',
	           'Valor Zero',
	           'VALOR.ZERO'
	           );
	QUIT;

	/************************************************************************************************************************
	  UNIR TABELAS DA VISÃO POR DECARTEIRA COM A VISÃO POR CARTEIRA E ORGANIZAR OS DADOS POR
	  MM_VL_APRD_IN AA_VL_APRD_IN CD_PRF NR_SEQL_CTRA CD_MOD_AVLC CD_IN_MOD_AVLC;
	/***********************************************************************************************************************/
	PROC SQL;
		CREATE TABLE APPEND_TABELA AS 
			SELECT * FROM MDU_AVLC_CTRA
				OUTER UNION CORR 
					SELECT * FROM MDU_AVLC_DEPE
		;
	Quit;

	PROC SORT DATA=APPEND_TABELA
		OUT=CNX.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD(LABEL="Sorted APPEND_TABELA")
	;
		BY MM_VL_APRD_IN AA_VL_APRD_IN CD_PRF NR_SEQL_CTRA CD_MOD_AVLC CD_IN_MOD_AVLC;
	RUN;

	PROC SQL;
		CREATE TABLE avl_grl.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD AS 
			SELECT * FROM cnx.A_REL_ANA_MDU_AVLC_CTRA_&AAMMDD
		;
	Quit;

/*+-----------------------------------------------------------------------------------------------+ 
  | 300999 - SEÇÃO CRIAR TABELAS DE ORÇAMENTO/REALIZADO DO SEMESTRE - VISÃO DEPE/VISÃO CTRA - FIM                                                                       
  +-----------------------------------------------------------------------------------------------*/

/*+-----------------------------------------------------------------------------------------------+ 
  | 400000 - SEÇÃO COMPARAR POSIÇÃO ATUAL COM A POSIÇÃO ANTERIOR                                                      
  +-----------------------------------------------------------------------------------------------*/
	/*PARAMETRIZAR %MACRO PARA LISTAR TABELAS NECESSÁRIAS À COMPARACAO  */
	%macro relacionarTabelasParaComparar;

		%ls(/dados/gecen/interno/mbz_avlc_cnx/avaliacao/geral);

		proc sort data=out_ls (where = (arquivo contains "a_rel_ana_mdu_avlc_ctra_" and scan(arquivo,-1,'.') eq 'sas7bdat'));
			by descending arquivo;
		run;

		data out_ls;
			set out_ls;
			retain posicao 0;
			posicao + 1;
		run;

		proc sql;
			select substr(scan(scan(arquivo,1,'.') ,-1,'_'),1) as dt into: base from out_ls where posicao = 1;
			select substr(scan(scan(arquivo,1,'.') ,-1,'_'),1) as dt into: compare from out_ls where posicao = 2;
            select substr(scan(scan(arquivo,1,'.') ,-1,'_'),1) as dt into: compare_d2 from out_ls where posicao = 3;
			select substr(scan(scan(arquivo,1,'.') ,-1,'_'),1) as dt into: compare_d3 from out_ls where posicao = 4;
			select substr(scan(scan(arquivo,1,'.') ,-1,'_'),1) as dt into: compare_d4 from out_ls where posicao = 5;
		quit;
	/* ACIONAR %MACRO PARA COMPARACAO DOS DADOS */
		%compararDados(&base, &compare, &compare_d2, &compare_d3, &compare_d4);

	%mend;
	/*PARAMETRIZAR %MACRO PARA COMPARAR DADOS  */
%macro compararDados (base, compare, compare_d2, compare_d3, compare_d4);

	%if not %sysfunc(exist(local.hst_monitor_avlc)) %then %do;
		data local.hst_monitor_avlc;
			length dt_foto_avlc_base dt_foto_avlc_compare 8 _info_ $200 _type_ $32 cod_ind _vlr_ 8;
			format dt_foto_avlc_base dt_foto_avlc_compare ddmmyy10.;
			delete;
		;run;
	%end;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&base compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare
		criterion=0.00001
		method=relative
		out=out_compare_orc_1
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_meta_in;
	run;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d2
		criterion=0.00001
		method=relative
		out=out_compare_orc_2
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_meta_in;
	run;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d2 compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d3
		criterion=0.00001
		method=relative
		out=out_compare_orc_3
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_meta_in;
	run;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d3 compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d4
		criterion=0.00001
		method=relative
		out=out_compare_orc_4
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_meta_in;
	run;

	proc sql;
		create table out_compare_orc as 
			select * from out_compare_orc_1
				outer union corr 
					select * from out_compare_orc_2
						outer union corr 
							select * from out_compare_orc_3
								outer union corr 
									select * from out_compare_orc_4
		;
	quit;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&base compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_1
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_rlzd_in;
	run;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d2
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_2
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_rlzd_in;
	run;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d2 compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d3
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_3
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_rlzd_in;
	run;

	proc compare base=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d3 compare=avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d4
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_4
		nomissing outbase outcomp outdif outnoequal noprint;
		id mm_vl_aprd_in aa_vl_aprd_in cd_prf nr_seql_ctra cd_mod_avlc cd_in_mod_avlc;
		var vl_rlzd_in;
	run;

	proc sql;
		create table out_compare_rlzd as 
			select * from out_compare_rlzd_1
				outer union corr 
					select * from out_compare_rlzd_2
						outer union corr 
							select * from out_compare_rlzd_3
								outer union corr 
									select * from out_compare_rlzd_4
		;
	quit;

	proc sql;
	   create table out_orc_base as 
	   select t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          t1.vl_meta_in
	      from out_compare_orc t1
	      where t1._type_ = 'BASE';
	quit;

	%let dsid=%sysfunc(open(out_orc_base));
	%let nobs_orc_base=%sysfunc(attrn(&dsid,nobs));
	%let dsid=%sysfunc(close(&dsid));

	proc sql;
	   create table out_orc_compare as 
	   select t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          t1.vl_meta_in
	      from out_compare_orc t1
	      where t1._type_ = 'COMPARE';
	quit;

	proc sql;
	   create table out_orc_dif as 
	   select t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          t1.vl_meta_in
	      from out_compare_orc t1
	      where t1._type_ = 'DIF';
	quit;

	proc sql;
	   create table out_rlzd_base as 
	   select t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          t1.vl_rlzd_in
	      from out_compare_rlzd t1
	      where t1._type_ = 'BASE';
	quit;

	%let dsid=%sysfunc(open(out_rlzd_base));
	%let nobs_rlzd_base=%sysfunc(attrn(&dsid,nobs));
	%let dsid=%sysfunc(close(&dsid));

	proc sql;
	   create table out_rlzd_compare as 
	   select t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          t1.vl_rlzd_in
	      from out_compare_rlzd t1
	      where t1._type_ = 'COMPARE';
	quit;

	proc sql;
	   create table out_rlzd_dif as 
	   select t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          t1.vl_rlzd_in
	      from out_compare_rlzd t1
	      where t1._type_ = 'DIF';
	quit;

	proc sql;
	   create table compare_orc_final as 
	   select distinct t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          coalesce(t6.vl_meta_in, 0) as a_vl_meta_d_4, 
	          coalesce(t5.vl_meta_in, 0) as b_vl_meta_d_3, 
	          coalesce(t4.vl_meta_in, 0) as c_vl_meta_d_2, 
	          coalesce(t3.vl_meta_in, 0) as d_vl_meta_d_1, 
	          coalesce(t2.vl_meta_in, 0) as e_vl_meta_d, 
	          (coalesce((t2.vl_meta_in / t3.vl_meta_in) - 1, 0)) format=percentn12.3 as pc_dif,
	          t1.vl_meta_in as 'vl_dif_d_d_1'n 
	      from out_orc_dif t1
	           left join out_orc_base t2 
			          on (t1.mm_vl_aprd_in = t2.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t2.aa_vl_aprd_in) 
					 and (t1.cd_prf = t2.cd_prf) 
					 and (t1.nr_seql_ctra = t2.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t2.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t2.cd_in_mod_avlc)
	           left join out_orc_compare t3 
			          on (t1.mm_vl_aprd_in = t3.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t3.aa_vl_aprd_in) 
					 and (t1.cd_prf = t3.cd_prf) 
					 and (t1.nr_seql_ctra = t3.nr_seql_ctra) 
					 and (t1.cd_mod_avlc =  t3.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t3.cd_in_mod_avlc)
	           left join avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d2 t4
	       		      on (t1.mm_vl_aprd_in = t4.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t4.aa_vl_aprd_in) 
					 and (t1.cd_prf = t4.cd_prf) 
					 and (t1.nr_seql_ctra = t4.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t4.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t4.cd_in_mod_avlc) 
			   left join avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d3 t5 
			          on (t1.mm_vl_aprd_in = t5.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t5.aa_vl_aprd_in) 
					 and (t1.cd_prf = t5.cd_prf) 
					 and (t1.nr_seql_ctra = t5.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t5.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t5.cd_in_mod_avlc)
	           left join avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d4 t6 
			          on (t1.mm_vl_aprd_in = t6.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t6.aa_vl_aprd_in) 
					 and (t1.cd_prf = t6.cd_prf) 
					 and (t1.nr_seql_ctra = t6.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t6.cd_mod_avlc)
					 and (t1.cd_in_mod_avlc = t6.cd_in_mod_avlc)
		;
	quit;

	proc sql;
	   create table compare_rlzd_final as 
	   select distinct 
			t1._type_, 
	          t1._obs_, 
	          t1.mm_vl_aprd_in, 
	          t1.aa_vl_aprd_in, 
	          t1.cd_prf, 
	          t1.nr_seql_ctra, 
	          t1.cd_mod_avlc, 
	          t1.cd_in_mod_avlc, 
	          coalesce(t6.vl_rlzd_in, 0) as 'a_vl_rlzd_d_4'n, 
	          coalesce(t5.vl_rlzd_in, 0) as 'b_vl_rlzd_d_3'n, 
	          coalesce(t4.vl_rlzd_in, 0) as 'c_vl_rlzd_d_2'n, 
	          coalesce(t3.vl_rlzd_in, 0) as 'd_vl_rlzd_d_1'n, 
	          coalesce(t2.vl_rlzd_in, 0) as 'e_vl_rlzd_d'n, 
	          (coalesce((t2.vl_rlzd_in / t3.vl_rlzd_in) - 1, 0)) format=percentn12.3 as pc_dif,
	          t1.vl_rlzd_in as vl_dif_d_d_1
	      from out_rlzd_dif t1
	           left join out_rlzd_base t2 
			          on (t1.mm_vl_aprd_in = t2.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t2.aa_vl_aprd_in) 
					 and (t1.cd_prf = t2.cd_prf) 
					 and (t1.nr_seql_ctra = t2.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t2.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t2.cd_in_mod_avlc)
	           left join out_rlzd_compare t3 
			          on (t1.mm_vl_aprd_in = t3.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t3.aa_vl_aprd_in) 
					 and (t1.cd_prf = t3.cd_prf) 
					 and (t1.nr_seql_ctra = t3.nr_seql_ctra) 
					 and (t1.cd_mod_avlc =  t3.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t3.cd_in_mod_avlc)
	           left join avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d2 t4
	       		      on (t1.mm_vl_aprd_in = t4.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t4.aa_vl_aprd_in) 
					 and (t1.cd_prf = t4.cd_prf) 
					 and (t1.nr_seql_ctra = t4.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t4.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t4.cd_in_mod_avlc) 
			   left join avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d3 t5 
			          on (t1.mm_vl_aprd_in = t5.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t5.aa_vl_aprd_in) 
					 and (t1.cd_prf = t5.cd_prf) 
					 and (t1.nr_seql_ctra = t5.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t5.cd_mod_avlc) 
					 and (t1.cd_in_mod_avlc = t5.cd_in_mod_avlc)
	           left join avl_grl.a_rel_ana_mdu_avlc_ctra_&compare_d4 t6 
			          on (t1.mm_vl_aprd_in = t6.mm_vl_aprd_in) 
					 and (t1.aa_vl_aprd_in = t6.aa_vl_aprd_in) 
					 and (t1.cd_prf = t6.cd_prf) 
					 and (t1.nr_seql_ctra = t6.nr_seql_ctra) 
					 and (t1.cd_mod_avlc = t6.cd_mod_avlc)
					 and (t1.cd_in_mod_avlc = t6.cd_in_mod_avlc)
		;
	quit;

	/* ACIONAR %MACRO PARA GERAR TABELAS FINAIS PARA RELATÓRIO E SPOTFIRE  */
		%GerarTabelasRelatoriosFinais;

	quit;
	%mend;
	/*PARAMETRIZAR %MACRO GERAR TABELAS PARA RELATÓRIOS FINAIS */
	%macro GerarTabelasRelatoriosFinais;

	proc sql;
		create table avl_rlzd.rel_dif_rlzd_mdu_avlc_&aammdd as 
			select distinct t1.cd_mod_avlc, 
				t2.nm_in_mod_avlc, 
				t1.cd_in_mod_avlc, 
				t2.nm_rdz_apsc_in, 
				t1.mm_vl_aprd_in, 
				t1.aa_vl_aprd_in, 
				t1.cd_prf, 
				t2.nm_depe, 
				t1.nr_seql_ctra, 
				t2.com_meta, 
				sum(distinct t1.a_vl_rlzd_d_4) as d_vl_rlzd_d_4, 
				sum(distinct t1.b_vl_rlzd_d_3) as d_vl_rlzd_d_3, 
				sum(distinct t1.c_vl_rlzd_d_2) as d_vl_rlzd_d_2, 
				sum(distinct t1.d_vl_rlzd_d_1) as d_vl_rlzd_d_1, 
				sum(distinct t1.e_vl_rlzd_d) as e_vl_rlzd_d, 
				sum(distinct t1.pc_dif) as pc_dif, 
				t1.vl_dif_d_d_1 * (-1) format=commax35.2 as vl_dif
			from compare_rlzd_final t1
				left join avl_grl.a_rel_ana_mdu_avlc_ctra_&aammdd t2 on (t1.mm_vl_aprd_in = t2.mm_vl_aprd_in) 
					and (t1.aa_vl_aprd_in = t2.aa_vl_aprd_in) 
					and (t1.cd_prf = t2.cd_prf) 
					and (t1.nr_seql_ctra = t2.nr_seql_ctra) 
					and (t1.cd_mod_avlc = t2.cd_mod_avlc) 
					and (t1.cd_in_mod_avlc = t2.cd_in_mod_avlc)
				order by t1.mm_vl_aprd_in, t2.nm_rdz_apsc_in;
	quit;

	proc sql;
	   create table avl_rlzd.sintetico_rlzd as 
	   select t1.cd_in_mod_avlc, 
	          t1.nm_rdz_apsc_in, 
	          t1.mm_vl_aprd_in, 
	          count(t1.cd_prf * 10000 + t1.nr_seql_ctra) as total_ctras_impactadas
	      from avl_rlzd.rel_dif_rlzd_mdu_avlc_&AAMMDD t1
	      where t1.mm_vl_aprd_in < &MM
	      group by t1.cd_in_mod_avlc,
	               t1.nm_rdz_apsc_in,
	               t1.mm_vl_aprd_in
	      order by t1.mm_vl_aprd_in;
	quit;

	proc sql;
		create table spot.rel_dif_rlzd_mdu_avlc as
		select * from avl_rlzd.rel_dif_rlzd_mdu_avlc_&aammdd;
	quit;

	proc sql;
		create table avl_orc.rel_dif_orc_mdu_avlc_&aammdd as 
			select distinct t1.cd_mod_avlc, 
				t2.nm_in_mod_avlc, 
				t1.cd_in_mod_avlc, 
				t2.nm_rdz_apsc_in, 
				t1.mm_vl_aprd_in, 
				t1.aa_vl_aprd_in, 
				t1.cd_prf, 
				t2.nm_depe, 
				t1.nr_seql_ctra, 
				t2.com_meta, 
				sum(distinct t1.a_vl_meta_d_4) as vl_meta_d_4, 
				sum(distinct t1.b_vl_meta_d_3) as vl_meta_d_3, 
				sum(distinct t1.c_vl_meta_d_2) as vl_meta_d_2, 
				sum(distinct t1.d_vl_meta_d_1) as vl_meta_d_1, 
				sum(distinct t1.e_vl_meta_d) as e_vl_meta_d, 
				sum(distinct t1.pc_dif) as pc_dif, 
				vl_dif_d_d_1 * (-1) format=commax35.2 as vl_dif
			from compare_orc_final t1
				left join avl_grl.a_rel_ana_mdu_avlc_ctra_&aammdd t2 on (t1.mm_vl_aprd_in = t2.mm_vl_aprd_in) 
					and (t1.aa_vl_aprd_in = t2.aa_vl_aprd_in) 
					and (t1.cd_prf = t2.cd_prf) 
					and (t1.nr_seql_ctra = t2.nr_seql_ctra) 
					and (t1.cd_mod_avlc = t2.cd_mod_avlc) 
					and (t1.cd_in_mod_avlc = t2.cd_in_mod_avlc)
				group by 1,2,3,4,5,6,7,8,9,10
				order by t1.mm_vl_aprd_in, t2.nm_rdz_apsc_in;
	quit;

	proc sql;
	   create table avl_orc.sintetico_orc as 
	   select t1.cd_in_mod_avlc, 
	          t1.nm_rdz_apsc_in, 
	          t1.mm_vl_aprd_in, 
	          /* total_ctras_impactadas */
	            (count(t1.cd_prf * 10000 + t1.nr_seql_ctra)) as total_ctras_impactadas
	      from avl_orc.rel_dif_orc_mdu_avlc_&AAMMDD t1
	      where t1.mm_vl_aprd_in <= &MM
	      group by t1.cd_in_mod_avlc,
	               t1.nm_rdz_apsc_in,
	               t1.mm_vl_aprd_in
	      order by t1.mm_vl_aprd_in;
	quit;

	proc sql;
		create table spot.rel_dif_orc_mdu_avlc as
		select * from avl_orc.rel_dif_orc_mdu_avlc_&aammdd;
	quit;

	%mend;

%relacionarTabelasParaComparar;
/*+-----------------------------------------------------------------------------------------------+ 
  | 400999 - SEÇÃO COMPARAR POSIÇÃO ATUAL COM A POSIÇÃO ANTERIOR - FIM                                                                        
  +-----------------------------------------------------------------------------------------------*/

/*+-----------------------------------------------------------------------------------------------+ 
  | 999999 - REGISTRAR PERMISSÕES                                                                     
  +-----------------------------------------------------------------------------------------------*/

x cd /dados/gecen/interno/mbz_avlc_cnx/avaliacao/geral;
x chmod 2777 *;

x cd /dados/gecen/interno/mbz_avlc_cnx/avaliacao/orcado;
x chmod 2777 *;

x cd /dados/gecen/interno/mbz_avlc_cnx/avaliacao/realizado;
x chmod 2777 *;

x cd /dados/gecen/interno/mbz_avlc_cnx;
x chmod 2777 *;

x cd /dados/gestao/rotinas/_spotfire/;
x chmod 2777 *;

/*+-----------------------------------------------------------------------------------------------+ 
  | 999999 - REGISTRAR PERMISSÕES  - FIM                                                                   
  +-----------------------------------------------------------------------------------------------*/

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
