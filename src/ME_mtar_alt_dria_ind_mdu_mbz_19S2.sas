/***************************************************************************************************
 * ROTINA.....: VERIFICAÇÃO DE ALTERAÇÕES DE ORÇADO E REALIZADO NO CONEXÃO                         *
 * MÓDULO.....: MOBILIZAÇÃO                                                                        *
 * AUTOR......: MARCIO VINICIUS DE ALMEIDA                                                         *
 * OBJETIVO...: Gerar tabela com evidência de alteração de orçamento e                             *
 *              realizado dos indicadores do Conexão 2019.                                         *
 * DATA.......: 01/01/2019.                                                                        *
 ***************************************************************************************************
 * VRS001 - 01/01/2019 - F6794004 (MARCIO) - Implementação.                                        *
 * VRS002 - 08/02/2019 - F6794004 (MARCIO) - Ajuste da parametrização de                           *
 *                       datas para apuração dos dados a partir de Janeiro/19.                     *
 **************************************************************************************************/

/***************************************************************************************************
 * ÍNDICE DE SEÇÕES                                                                                *  
 ***************************************************************************************************
 * 000000 - SEÇÃO CONECTAR E PREPARAÇÃO DE PROCESSAMENTO.                                          *
 * 100000 - SEÇÃO DE CONSULTAS AOS DADOS LEGADOS.                                                  *
 * 200000 - SEÇÃO DE APLICAÇÃO DE FILTROS SISTÊMICOS.                                              *
 * 300000 - SEÇÃO CRIAR TABELAS COM O ORÇAMENTO E REALIZADO DO SEMESTRE - VISÃO DEPE. E CTRA.      *
 * 400000 - SEÇÃO COMPARAR POSIÇÃO ATUAL COM A POSIÇÃO ANTERIOR - VISÃO DEPE. E VISÃO CTRA.        *
 *                                                                                                 *
/*+================================================================================================+
*/
/*+================================================================================================+
  | 000000 - SEÇÃO CONECTAR E PREPARAÇÃO DE PROCESSAMENTO                                                                         
  +================================================================================================+*/
%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";
%conectardb2(atb);
%conectardb2(ARH);
%conectardb2(MST);

libname db2rel 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL 	database=BDB2P04;
libname avlc_grl     "/dados/infor/conexao/2018";
/*libname cnx_bkp     "/dados/infor/conexao/2018/bkp";*/
libname pg_ind 		postgres server="172.16.15.104" port=5432 user="gecen_processamento" password='procgecen17' database="portal" schema="indicadores";
libname infcnx18 "/dados/infor/conexao/2018";
libname infcnx19 "/dados/infor/conexao/2019/acordos";
libname igr "/dados/infor/producao/dependencias";
libname relfotos "/dados/prep/rel/fotos";
libname cnx "/dados/gecen/interno/mbz_avlc_cnx";
libname spot "/dados/gestao/rotinas/_spotfire/";
libname mst oracle user=sas_gecen password=Gecen77 path="sas_dirco" schema="mst";
/*libname post postgres server="172.16.15.103" port=5432 user="gecen_processamento" password='procgecen17' database="portal" schema="indicadores";*/
LIBNAME POST POSTGRES server="172.16.15.103" port=5432 user="gecen_processamento" password='procgecen17' database="portal" schema="acordos";


/******************************************************************************************************************************************************
 DIRETÓRIOS DE APURACAO DO ORCADO E REALIZADO DOS MODULOS CONEXÃO E MOBILIZAÇÃO
******************************************************************************************************************************************************/
libname mbz_grl  "/dados/gecen/interno/mbz_avlc_cnx/mobilizacao/2019S1/geral/";
libname mbz_orc  "/dados/gecen/interno/mbz_avlc_cnx/mobilizacao/2019S1/orcado/";
libname mbz_rlzd "/dados/gecen/interno/mbz_avlc_cnx/mobilizacao/2019S1/realizado/";
libname local    "/dados/gecen/interno/mbz_avlc_cnx/mobilizacao/";

/******************************************************************************************************************************************************
 CONTROLE DE DATAS
******************************************************************************************************************************************************/
DATA _NULL_;
	DATA_REF = TODAY();         /* <------ Comentar aqui caso seja parametrizada uma data especificada que não hoje.*/
/* 	DATA_REF = MDY(01,05,2019); /* <------ Informar aqui a data para processamento ou manter comentado. */
	AAMMDD = PUT(TODAY(), YYMMDD7.);
	DT_SAS = PUT(DATA_REF, 32.);
	DT_SASf = PUT(DATA_REF, yymmdd10.);
	MMAAAA = PUT(DATA_REF, MMYYN6.);
	AAAAMM = PUT(DATA_REF, YYMMN6.);
	AAAA = PUT(DATA_REF, YEAR.);
	MM = PUT(INPUT(PUT(DATA_REF, MONTH.), 2.),Z2.);
	IF MM >= 7 THEN;
	   PRMO_MM = 7;
    IF MM <= 6 THEN;
	   PRMO_MM = 1;
    
	CALL SYMPUT('DT_SAS',COMPRESS(DT_SAS,' '));
	CALL SYMPUT('DT_SASf',COMPRESS(DT_SASf,' '));
	CALL SYMPUT('AAMMDD',COMPRESS(AAMMDD,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('AAAAMM_LIMIT',COMPRESS(AAAAMM_LIMIT,' '));
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('MM',COMPRESS(MM,' '));
	CALL SYMPUT('PRMO_MM',COMPRESS(PRMO_MM,' '));
RUN;

%LET DT_PRCT_ATU = &AAMMDD;
%LET DT_AA_ATU = &AAAA;
%LET DT_MM_ATU = &MM;
%LET DT_MMAAAA = &MMAAAA;
%LET MM_INC_SMT = &PRMO_MM;

%PUT &MM_INC_SMT - &DT_PRCT_ATU - &DT_MM_ATU - &DT_MMAAAA - &DT_AA_ATU &DT_SASf;


/* VERIFICAR EXISTÊNCIA DE TABELAS PARA A DATA DE PROCESSAMENTO EXECUTAR DELEÇÃO CASO EXISTAM */

%macro deletarTabelas;
%if %sysfunc(exist(MBZ_GRL.A_REL_ANA_MDU_MBZ_CTRA_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE MBZ_GRL.A_REL_ANA_MDU_MBZ_CTRA_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(MBZ_ORC.REL_DIF_ORC_MDU_MBZ_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE MBZ_ORC.REL_DIF_ORC_MDU_MBZ_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(MBZ_RLZD.REL_DIF_RLZD_MDU_MBZ_&AAMMDD)) %then
	%do;
		PROC SQL;
			DROP TABLE MBZ_RLZD.REL_DIF_RLZD_MDU_MBZ_&AAMMDD;
		Quit;
	%end;
%if %sysfunc(exist(MBZ_ORC.SINTETICO_ORC)) %then
	%do;
		PROC SQL;
			DROP TABLE MBZ_ORC.SINTETICO_ORC;
		Quit;
	%end;
%if %sysfunc(exist(MBZ_RLZD.SINTETICO_RLZD)) %then
	%do;
		PROC SQL;
			DROP TABLE MBZ_RLZD.SINTETICO_RLZD;
		Quit;
	%end;
%mend; %deletarTabelas;

/*+-----------------------------------------------------------------------------------------------+ 
  | 000999 - SEÇÃO CONECTAR E PREPARAÇÃO DE PROCESSAMENTO    - FIM                                                                        
  +-----------------------------------------------------------------------------------------------*/


/*+-----------------------------------------------------------------------------------------------+ 
  | 100000 - SEÇÃO DE CONSULTAS AOS DADOS LEGADOS                                                                         
  +-----------------------------------------------------------------------------------------------*/

/*	DADOS DAS TABELAS DO CONEXÃO MOBILIZAÇÃO-DB2 */
/*	PARTIÇÃO VALIDA DO DB2*/
proc sql noprint; select distinct ifn(in_est_pcd="N",2,1) into :part from db2atb.ctl_prct_pcd t1 where t1.nm_pcd = 'MOBILIZA'; quit;
%PUT &PART;
%LET PART=1;
PROC SQL;
	CREATE TABLE VL_APRD_IN_MBZ_MAX AS 
	SELECT 
		t1.CD_IN_MBZ, 
		t1.CD_UOR_CTRA, 
		t1.NR_SEQL_CTRA, 
		t1.AA_APRC, 
		t1.MM_APRC, 
		(MAX(t1.DT_PSC)) AS MAX_DT_PSC
	FROM DB2ATB.VL_APRD_IN_MBZ_MM t1
	WHERE
			t1.AA_APRC=&AAAA. 
/*		AND t1.MM_APRC=&MM.*/
		AND t1.NR_PTC=&PART.
	GROUP BY 1,2,3,4,5;
QUIT;

/*ORÇADO, REALIZADO E PONTOS DO CONEXÃO*/
PROC SQL;
	CREATE TABLE ORC_RLZ_PTO_MBZ AS 
		SELECT
			t3.prefixo AS PREFDEP, 
			t1.NR_SEQL_CTRA AS CTRA, 
			t1.CD_UOR_CTRA AS UOR,
			t1.CD_IN_MBZ AS IND,
			INPUT(PUT(t1.MM_APRC,Z2.)||PUT(t1.AA_APRC,Z4.),6.) AS MMAAAA,
			t1.VL_META_IN_MBZ FORMAT=32.5 INFORMAT=32.5 AS ORC_MBZ, 
			t1.VL_RLZD_IN_MBZ FORMAT=32.5 INFORMAT=32.5 AS RLZ_MBZ,
			(t1.VL_RLZD_IN_MBZ/t1.VL_META_IN_MBZ)*100 FORMAT=32.5 INFORMAT=32.5 AS ATG_MBZ
		FROM DB2ATB.VL_APRD_IN_MBZ_MM t1
		INNER JOIN VL_APRD_IN_MBZ_MAX t2 ON (t1.CD_IN_MBZ=t2.CD_IN_MBZ AND t1.CD_UOR_CTRA=t2.CD_UOR_CTRA AND t1.NR_SEQL_CTRA=t2.NR_SEQL_CTRA AND t1.AA_APRC=t2.AA_APRC AND t1.MM_APRC=t2.MM_APRC AND t1.DT_PSC=t2.MAX_DT_PSC)
		INNER JOIN IGR.DEPENDENCIAS_NOVO_REL t3 ON (t1.CD_UOR_CTRA=t3.uor)
		WHERE
			t1.AA_APRC=&AAAA. 
/*			AND t1.MM_APRC=&MM.*/
			AND t1.NR_PTC=&PART.
		ORDER BY 1,2,4,5
;QUIT;


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

/*DADOS DAS TABELAS DO CONEXÃO MOBILIZAÇÃO-DB2 - FIM XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX*/

/***************************************************************************************************
 TRAZER NOME DA DEPENDENCIA PARA DA VIEW MST606.
/**************************************************************************************************/
PROC SQL;
   CREATE TABLE VW_MST606 AS 
   SELECT DISTINCT t1.CD_UOR, 
          t1.CD_PRF, 
          t1.NM_DEPE
      FROM MST.VW_MST606 t1
      WHERE t1.MM = &DT_MM_ATU
      ORDER BY t1.CD_PRF;
QUIT;

PROC SQL;
   CREATE TABLE DEPENDENCIAS_FORMATADAS AS 
   SELECT (INPUT(t1.UOR, 10.))      AS UOR,
          (INPUT(t1.PrefDep, 4.))   AS PREF_DEP, 
          (IFN(t1.DV='X',0,(INPUT(t1.DV, 1.)))) AS DV,
          (INPUT(t1.SB, 2.))        AS SB,
          (INPUT(t1.PrefVice, 4.))  AS PRF_VICE_PRSA,
          (INPUT(t1.PrefDir, 4.))   AS PRF_DRTRA,
          (INPUT(t1.PrefSuper, 4.)) AS PRF_SPCA,
          (INPUT(t1.PrefSureg, 4.)) AS PRF_SUP_RGNL,
          (INPUT(t1.PrefDep, 4.))   AS PRF_DEPE,
           t1.NomeDep               AS NM_DEPE,              
           t1.Criacao               AS DT_CRIC, 
           t1.Posicao               AS DT_PSC, 
           t1.Encerramento          AS DT_ECR
      FROM IGR.DEPENDENCIAS t1
      WHERE t1.SB = '00' 
        AND t1.PrefDir = '8592'  
        AND t1.UOR <> '18525'
        AND t1.Encerramento = '31Dec9999'd;
QUIT;

/*+-----------------------------------------------------------------------------------------------+ 
  | 100999 - SEÇÃO DE CONSULTAS AOS DADOS LEGADOS - FIM                                                                      
  +-----------------------------------------------------------------------------------------------*/

/*+-----------------------------------------------------------------------------------------------+ 
  | 200000 - SEÇÃO DE APLICAÇÃO DE FILTROS SISTÊMICOS                                                                          
  +-----------------------------------------------------------------------------------------------*/
/***************************************************************************************************
 TRAZER ACORDOS VALIDOS DA TABELA ACORDO_IND_PRF_CTRA_PESO.
/**************************************************************************************************/
PROC SQL;
	CREATE TABLE ACORDOS_VALIDOS AS 
		SELECT DISTINCT 
			t1.ind AS CD_IN_MBZ, 
			t2.NM_IN_MBZ, 
			t1.ac, 
			t1.MMAAAA, 
			t1.prefdep as prefixo, 
			t3.NM_DEPE, 
			t1.ctra, 
			t1.tp_ctra, 
			t1.peso_ant, 
			t1.peso_ajus
		from infcnx19.AC_IND_PRF_CTRA_PESO_2019_1 t1, DB2ATB.IN_MBZ t2, VW_MST606 t3
		WHERE (t1.ind = t2.CD_IN_MBZ AND t1.prefdep = t3.CD_PRF AND t1.uor = t3.CD_UOR)
/*		FROM INFCNX19.ACORDO_IND_PRF_CTRA_PESO t1, DB2ATB.IN_MBZ t2, VW_MST606 t3
			WHERE (t1.ind = t2.CD_IN_MBZ AND t1.prefixo = t3.CD_PRF AND t1.uor = t3.CD_UOR)*/;
QUIT;

/***************************************************************************************************
 CRUZAR ACORDOS COM OS VALORES DO CONEXÃO.
/**************************************************************************************************/
PROC SQL;
   CREATE TABLE VL_ORC_RLZD_AC_MBZ AS 
   SELECT DISTINCT 
			t2.CD_IN_MBZ, 
          t2.NM_IN_MBZ, 
          t2.ac, 
          t2.MMAAAA, 
          t2.prefixo, 
          t2.NM_DEPE, 
          t2.ctra, 
          t2.tp_ctra, 
          t2.peso_ant, 
          t2.peso_ajus, 
          t1.ORC_MBZ, 
          t1.RLZ_MBZ
      FROM ACORDOS_VALIDOS t2
           LEFT JOIN ORC_RLZ_PTO_MBZ t1 
                  ON  (t2.CD_IN_MBZ = t1.IND) 
                  AND (t2.prefixo = t1.PREFDEP) 
                  AND (t2.ctra = t1.CTRA) 
                  AND (t2.MMAAAA = t1.MMAAAA)
/*		  INNER JOIN DEPENDENCIAS_FORMATADAS t3*/
/*                  ON (t2.prefixo = t3.PRF_DEPE)*/
      WHERE t2.MMAAAA >= 012019;*/;
QUIT;


/*+-----------------------------------------------------------------------------------------------+ 
  | 200999 - SEÇÃO DE APLICAÇÃO DE FILTROS SISTÊMICOS - FIM                                                                        
  +-----------------------------------------------------------------------------------------------*/

/*+-----------------------------------------------------------------------------------------------+ 
  | 300000 - SEÇÃO CRIAR TABELAS DE ORÇAMENTO/REALIZADO DO SEMESTRE - VISÃO DEPE/VISÃO CTRA                                                                        
  +-----------------------------------------------------------------------------------------------*/

/************************************************************************************************************************
	GERAR MARCAÇÃO DE DEPÊNDNCIAS COM E SEM VALORES DE ORÇAMENTO E REALZIADO APURADOS 
	- VISÃO POR DEPE E CTRA
/***********************************************************************************************************************/
PROC SQL;
   CREATE TABLE VL_ORC_RLZD_AC_MBZ_FLAG AS 
   select distinct 
          t1.cd_in_mbz, 
          t1.nm_in_mbz, 
          t1.ac, 
          t1.mmaaaa, 
          t1.prefixo, 
          t1.nm_depe, 
          t1.ctra, 
          t1.tp_ctra, 
          t1.peso_ant, 
          t1.peso_ajus, 
          t1.orc_mbz, 
          t1.rlz_mbz, 
          /* flag_meta */
            ((ifn(t1.orc_mbz, 1, 0))) as flag_meta, 
          /* com_meta */
            ((ifc(t1.orc_mbz, 'SIM', 'NAO'))) as com_meta, 
          /* flag_rlzd */
            ((ifn(t1.rlz_mbz, 1, 0))) as flag_rlzd, 
          /* com_rlzd */
            ((ifc(t1.rlz_mbz, 'SIM', 'NAO'))) as com_rlzd
      from vl_orc_rlzd_ac_mbz t1;
QUIT;

/************************************************************************************************************************
  ORGANIZAR OS DADOS POR MES/ANO, PREFIXO, CARTEIRA, ACORDO E INDICADOR;
/***********************************************************************************************************************/
PROC SORT DATA=VL_ORC_RLZD_AC_MBZ_FLAG
	OUT=A_REL_ANA_MDU_MBZ_CTRA_&AAMMDD(LABEL="Sorted A_REL_ANA_MDU_MBZ_CTRA_&AAMMDD")
	;
	BY MMAAAA PREFIXO CTRA AC CD_IN_MBZ ;
RUN;
PROC SQL;
CREATE TABLE MBZ_GRL.A_REL_ANA_MDU_MBZ_CTRA_&AAMMDD AS 
SELECT DISTINCT * 
  FROM A_REL_ANA_MDU_MBZ_CTRA_&AAMMDD
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

		%ls(/dados/gecen/interno/mbz_avlc_cnx/mobilizacao/2019S1/geral/);

		proc sort data=out_ls (where = (arquivo contains "a_rel_ana_mdu_mbz_ctra_" and scan(arquivo,-1,'.') eq 'sas7bdat'));
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

	%if not %sysfunc(exist(local.hst_monitor_mbz)) %then %do;
		data local.hst_monitor_mbz;
			length dt_foto_mbz_base dt_foto_mbz_compare 8 _info_ $200 _type_ $32 cod_ind _vlr_ 8;
			format dt_foto_mbz_base dt_foto_mbz_compare ddmmyy10.;
			delete;
		;run;
	%end;

	/* REALIZAR A ORDENAÇÃO (POR: (MES/ANO, PREFIXO, CARTEIRA, ACORDO E INDICADOR))DAS TABELAS PARA COMPARAÇÃO */
	proc sort data=mbz_grl.a_rel_ana_mdu_mbz_ctra_&base
		out=mbz_grl.a_rel_ana_mdu_mbz_ctra_&base(label="sorted mbz_grl.a_rel_ana_mdu_mbz_ctra_&base")
		;
		by mmaaaa prefixo ctra ac cd_in_mbz;
	run;
	proc sort data=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare
		out=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare(label="sorted mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare")
		;
		by mmaaaa prefixo ctra ac cd_in_mbz;
	run;
	proc sort data=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2
		out=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2(label="sorted mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2")
		;
		by mmaaaa prefixo ctra ac cd_in_mbz;
	run;
	proc sort data=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3
		out=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3(label="sorted mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3")
		;
		by mmaaaa prefixo ctra ac cd_in_mbz;
	run;
	proc sort data=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4
		out=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4(label="sorted mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4")
		;
		by mmaaaa prefixo ctra ac cd_in_mbz;
	run;


	/* COMPARAR ORÇAMENTO NAS TABELAS DOS ULTIMOS 5 DIAS */
	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&base compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare
		criterion=0.00001
		method=relative
		out=out_compare_orc_1
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var orc_mbz;
	run;

	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2
		criterion=0.00001
		method=relative
		out=out_compare_orc_2
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var orc_mbz;
	run;

	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2 compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3
		criterion=0.00001
		method=relative
		out=out_compare_orc_3
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var orc_mbz;
	run;

	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3 compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4
		criterion=0.00001
		method=relative
		out=out_compare_orc_4
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var orc_mbz;
	run;

	/* CRIAR TABELA ÚNICA (out_compare_orc) FAZENDO O UNION (APPEND) DAS TABELAS OUT_COMPARE_ORC_nº */
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

	/* COMPARAR REALIZADO NAS TABELAS DOS ULTIMOS 5 DIAS */
	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&base compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_1
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var rlz_mbz;
	run;

	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_2
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var rlz_mbz;
	run;

	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2 compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_3
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var rlz_mbz;
	run;

	proc compare base=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3 compare=mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4
		criterion=0.00001
		method=relative
		out=out_compare_rlzd_4
		nomissing outbase outcomp outdif outnoequal noprint;
		id mmaaaa prefixo ctra ac cd_in_mbz;
		var rlz_mbz;
	run;

	/* CRIAR TABELA ÚNICA (out_compare_rlzd) FAZENDO O UNION (APPEND) DAS TABELAS OUT_COMPARE_RLZD_nº */
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

	/* SEPARAR DADOS DA TABELA ÚNICA DE ORÇAMENTO POR TIPO DE REGISTRO - 'BASE', 'COMPARE' E 'DIF' */
	proc sql;
	   create table out_orc_base as 
	   select 
			  t1._type_, 
	          t1._obs_, 
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
			  t1.orc_mbz
	      from out_compare_orc t1
	      where t1._type_ = 'BASE';
	quit;

	%let dsid=%sysfunc(open(out_orc_base));
	%let nobs_orc_base=%sysfunc(attrn(&dsid,nobs));
	%let dsid=%sysfunc(close(&dsid));

	proc sql;
	   create table out_orc_compare as 
	   select 
			  t1._type_, 
	          t1._obs_, 
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
			  t1.orc_mbz
	      from out_compare_orc t1
	      where t1._type_ = 'COMPARE';
	quit;

	proc sql;
	   create table out_orc_dif as 
	   select 
			  t1._type_, 
	          t1._obs_, 
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
			  t1.orc_mbz
	      from out_compare_orc t1
	      where t1._type_ = 'DIF';
	quit;

/* SEPARAR DADOS DA TABELA ÚNICA DE REALIZADO POR TIPO DE REGISTRO - 'BASE', 'COMPARE' E 'DIF' */
	proc sql;
	   create table out_rlzd_base as 
	   select 
			  t1._type_, 
	          t1._obs_, 
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
			  t1.rlz_mbz
	      from out_compare_rlzd t1
	      where t1._type_ = 'BASE';
	quit;

	%let dsid=%sysfunc(open(out_rlzd_base));
	%let nobs_rlzd_base=%sysfunc(attrn(&dsid,nobs));
	%let dsid=%sysfunc(close(&dsid));

	proc sql;
	   create table out_rlzd_compare as 
	   select 
			  t1._type_, 
	          t1._obs_, 
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
			  t1.rlz_mbz
	      from out_compare_rlzd t1
	      where t1._type_ = 'COMPARE';
	quit;

	proc sql;
	   create table out_rlzd_dif as 
	   select 
			  t1._type_, 
	          t1._obs_,
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
			  t1.rlz_mbz
	      from out_compare_rlzd t1
	      where t1._type_ = 'DIF';
	quit;

/* FORMATAR TABELA DE ORÇADO PARA O LEYOUT DO RELATORIO */
	proc sql;
	   create table compare_orc_final as 
	   select distinct 
			  t1._type_, 
	          t1._obs_,
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
	          t6.orc_mbz as 'a_vl_meta_d_4'n, 
	          t5.orc_mbz as 'b_vl_meta_d_3'n, 
	          t4.orc_mbz as 'c_vl_meta_d_2'n, 
	          t3.orc_mbz as 'd_vl_meta_d_1'n, 
	          t2.orc_mbz as 'e_vl_meta_d'n, 
	          (coalesce((t2.orc_mbz / t3.orc_mbz) - 1, 0)) format=percentn12.3 as pc_dif,
	          t1.orc_mbz as 'vl_dif_e_d'n 
	      from out_orc_dif t1
	           left join out_orc_base t2 
			   		  on (t1.mmaaaa = t2.mmaaaa)
					 and (t1.prefixo = t2.prefixo)
					 and (t1.ctra = t2.ctra)
					 and (t1.cd_in_mbz = t2.cd_in_mbz)
					 and (t1.ac = t2.ac)
	           left join out_orc_compare t3 
			   		  on (t1.mmaaaa = t3.mmaaaa)
					 and (t1.prefixo = t3.prefixo)
					 and (t1.ctra = t3.ctra)
					 and (t1.cd_in_mbz = t3.cd_in_mbz)
					 and (t1.ac = t3.ac)
	           left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2 t4
			   		  on (t1.mmaaaa = t4.mmaaaa)
					 and (t1.prefixo = t4.prefixo)
					 and (t1.ctra = t4.ctra)
					 and (t1.cd_in_mbz = t4.cd_in_mbz)
					 and (t1.ac = t4.ac)
			   left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3 t5 
			   		  on (t1.mmaaaa = t5.mmaaaa)
					 and (t1.prefixo = t5.prefixo)
					 and (t1.ctra = t5.ctra)
					 and (t1.cd_in_mbz = t5.cd_in_mbz)
					 and (t1.ac = t5.ac)
	           left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4 t6 
			   		  on (t1.mmaaaa = t6.mmaaaa)
					 and (t1.prefixo = t6.prefixo)
					 and (t1.ctra = t6.ctra)
					 and (t1.cd_in_mbz = t6.cd_in_mbz)
					 and (t1.ac = t6.ac)
		;
	quit;

/* FORMATAR TABELA DE REALIZADO PARA O LEYOUT DO RELATORIO */
	proc sql;
	   create table compare_rlzd_final as 
	   select distinct 
			  t1._type_, 
	          t1._obs_, 
			  t1.mmaaaa,
			  t1.prefixo,
			  t1.ctra,
			  t1.cd_in_mbz,
			  t1.ac,
	          t6.rlz_mbz as 'a_vl_rlzd_d_4'n,
	          t5.rlz_mbz as 'b_vl_rlzd_d_3'n, 
	          t4.rlz_mbz as 'c_vl_rlzd_d_2'n, 
	          t3.rlz_mbz as 'd_vl_rlzd_d_1'n, 
	          t2.rlz_mbz as 'e_vl_rlzd_d'n, 
	          (coalesce((t2.rlz_mbz / t3.rlz_mbz) - 1, 0)) format=percentn12.3 as pc_dif,
	          t1.rlz_mbz as 'vl_dif_e_d'n 
	      from out_rlzd_dif t1
	           left join out_rlzd_base t2 
			   		  on (t1.mmaaaa = t2.mmaaaa)
					 and (t1.prefixo = t2.prefixo)
					 and (t1.ctra = t2.ctra)
					 and (t1.cd_in_mbz = t2.cd_in_mbz)
					 and (t1.ac = t2.ac)
	           left join out_rlzd_compare t3 
			   		  on (t1.mmaaaa = t3.mmaaaa)
					 and (t1.prefixo = t3.prefixo)
					 and (t1.ctra = t3.ctra)
					 and (t1.cd_in_mbz = t3.cd_in_mbz)
					 and (t1.ac = t3.ac)
	           left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d2 t4
			   		  on (t1.mmaaaa = t4.mmaaaa)
					 and (t1.prefixo = t4.prefixo)
					 and (t1.ctra = t4.ctra)
					 and (t1.cd_in_mbz = t4.cd_in_mbz)
					 and (t1.ac = t4.ac)
			   left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d3 t5 
			   		  on (t1.mmaaaa = t5.mmaaaa)
					 and (t1.prefixo = t5.prefixo)
					 and (t1.ctra = t5.ctra)
					 and (t1.cd_in_mbz = t5.cd_in_mbz)
					 and (t1.ac = t5.ac)
	           left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&compare_d4 t6 
			   		  on (t1.mmaaaa = t6.mmaaaa)
					 and (t1.prefixo = t6.prefixo)
					 and (t1.ctra = t6.ctra)
					 and (t1.cd_in_mbz = t6.cd_in_mbz)
					 and (t1.ac = t6.ac)
		;
	quit;

	/* ACIONAR %MACRO PARA GERAR TABELAS FINAIS PARA RELATÓRIO E SPOTFIRE  */
		%GerarTabelasRelatoriosFinais;

	quit;
%mend;


	/*PARAMETRIZAR %MACRO GERAR TABELAS PARA RELATÓRIOS FINAIS */
%macro GerarTabelasRelatoriosFinais;

	proc sql;
	   create table mbz_rlzd.rel_dif_rlzd_mdu_mbz_&aammdd as 
	   select distinct 

			  t1.cd_in_mbz, 
	          t2.nm_in_mbz, 
	          t1.ac,
              t1.mmaaaa,
			  t1.prefixo, 
	          t2.nm_depe, 
	          t1.ctra, 
	          t2.com_meta, 
	          t1.'a_vl_rlzd_d_4'n, 
	          t1.'b_vl_rlzd_d_3'n, 
	          t1.'c_vl_rlzd_d_2'n, 
	          t1.'d_vl_rlzd_d_1'n, 
	          t1.'e_vl_rlzd_d'n, 
	          t1.pc_dif, 
	          /* vl_dif */
	            (t1.'vl_dif_e_d'n * (-1)) format=commax35.2 as vl_dif
	      from compare_rlzd_final t1
	           left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&aammdd t2 
						on (t1.mmaaaa = t2.mmaaaa)
					 and (t1.prefixo = t2.prefixo)
					 and (t1.ctra = t2.ctra)
					 and (t1.cd_in_mbz = t2.cd_in_mbz)
					 and (t1.ac = t2.ac);
    quit;

	proc sql;
		create table spot.rel_dif_rlzd_mdu_mbz as
		select * from mbz_rlzd.rel_dif_rlzd_mdu_mbz_&aammdd;
	quit;

	proc sql;
	   create table mbz_rlzd.sintetico_rlzd as 
	   select t1.cd_in_mbz, 
	          t1.nm_in_mbz, 
	          t1.mmaaaa, 
	          /* total_ctras_impactadas */
	          (count(t1.prefixo * 10000 +  t1.ctra)) as total_ctras_impactadas
	      from mbz_rlzd.rel_dif_rlzd_mdu_mbz_&aammdd t1
	      where t1.mmaaaa <= &mmaaaa
	      group by t1.cd_in_mbz,
	               t1.nm_in_mbz,
	               t1.mmaaaa
	      order by t1.mmaaaa,
	               t1.cd_in_mbz,
	               total_ctras_impactadas;
	quit;

	proc sql;
	   create table mbz_orc.rel_dif_orc_mdu_mbz_&aammdd as 
	   select distinct 
			  t1.cd_in_mbz, 
	          t2.nm_in_mbz, 
	          t1.ac,
			  t1.mmaaaa,
			  t1.prefixo, 
	          t2.nm_depe, 
	          t1.ctra, 
	          t2.com_meta, 
	          t1.'a_vl_meta_d_4'n, 
	          t1.'b_vl_meta_d_3'n, 
	          t1.'c_vl_meta_d_2'n, 
	          t1.'d_vl_meta_d_1'n, 
	          t1.'e_vl_meta_d'n, 
	          t1.pc_dif, 
	          /* vl_dif */
	            (t1.'vl_dif_e_d'n * (-1)) format=commax35.2 as vl_dif
	      from compare_orc_final t1
	           left join mbz_grl.a_rel_ana_mdu_mbz_ctra_&aammdd t2 
						on (t1.mmaaaa = t2.mmaaaa)
					 and (t1.prefixo = t2.prefixo)
					 and (t1.ctra = t2.ctra)
					 and (t1.cd_in_mbz = t2.cd_in_mbz)
					 and (t1.ac = t2.ac);
    quit;

	proc sql;
		create table spot.rel_dif_orc_mdu_mbz as
		select * from mbz_orc.rel_dif_orc_mdu_mbz_&aammdd;
	quit;

	proc sql;
	   create table mbz_orc.sintetico_orc as 
	   select t1.cd_in_mbz, 
	          t1.nm_in_mbz, 
	          t1.mmaaaa, 
	          /* total_ctras_impactadas */
	            (count(t1.prefixo * 10000 +  t1.ctra)) as total_ctras_impactadas
	      from mbz_orc.rel_dif_orc_mdu_mbz_&aammdd t1
	      where t1.mmaaaa <= &mmaaaa
	      group by t1.cd_in_mbz,
	               t1.nm_in_mbz,
	               t1.mmaaaa
	      order by t1.mmaaaa,
	               t1.cd_in_mbz,
	               total_ctras_impactadas;
	quit;

%mend;
%relacionarTabelasParaComparar;
/*+-----------------------------------------------------------------------------------------------+ 
  | 400999 - SEÇÃO COMPARAR POSIÇÃO ATUAL COM A POSIÇÃO ANTERIOR - FIM                                                                        
  +-----------------------------------------------------------------------------------------------*/


/*+-----------------------------------------------------------------------------------------------+ 
  | 999999 - REGISTRAR PERMISSÕES                                                                     
  +-----------------------------------------------------------------------------------------------*/


x cd /dados/gecen/interno/mbz_avlc_cnx/mobilizacao/geral;
x chmod 2777 *;

x cd /dados/gecen/interno/mbz_avlc_cnx/mobilizacao/orcado;
x chmod 2777 *;

x cd /dados/gecen/interno/mbz_avlc_cnx/mobilizacao/realizado;
x chmod 2777 *;

x cd /dados/gecen/interno/mbz_avlc_cnx;
x chmod 2777 *;

x cd /dados/gestao/rotinas/_spotfire/;
x chmod 2777 *;

/*+-----------------------------------------------------------------------------------------------+ 
  | 999999 - REGISTRAR PERMISSÕES  - FIM                                                                   
  +-----------------------------------------------------------------------------------------------+*/
