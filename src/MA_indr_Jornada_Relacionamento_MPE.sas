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

############################################################################################################################

O indicador irá apurar a quantidade de clientes da carteira que possuem Margem de Contribuição Gerencial observada igual ou
superior ao Custo de Habilitação, definido em função da FBA do cliente e encarteiramento.

/*############################################################################################################################*/
%include '/dados/infor/suporte/FuncoesInfor.sas';
/*############################################################################################################################*/
/* DADOS ---------------------------------------------------------------------------------------------------------------------*/

%LET NM_INDICADOR=JORNADA RELACIONAMENTO MPE;
%LET NR_INDICADOR=000000294;
%LET MT_DEMANDANTE=F3190234;
%LET NM_DEMANDANTE=FELIPE MARTINS / F2189255 - CRIS VEIGA;
%LET MT_AUTOR=F6794004;
%LET NM_AUTOR=MARCIO V ALMEIDA;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=07:45;
%LET ANOMES=0;

/* ---------------------------------------------------------------------------------------------------------------------------*/
/*############################################################################################################################*/
/*############################################################################################################################*/
/*# CKECKIN ##################################################################################################################*/
%indCheckIn();

/*############################################################################################################################*/
/*############################################################################################################################*/
/*# BIBLIOTECAS - ############################################################################################################*/


LIBNAME REL 		"/DADOS/GECEN/INTERNO/BASES/REL/FOTOS";
LIBNAME DB2SGCEN 	DB2 AUTHDOMAIN=DB2SGCEN SCHEMA=DB2SGCEN DATABASE=BDB2P04;
LIBNAME DB2MCI 		DB2 AUTHDOMAIN=DB2SGCEN SCHEMA=DB2MCI 	DATABASE=BDB2P04;
LIBNAME DB2PRD 		DB2 AUTHDOMAIN=DB2SGCEN SCHEMA=DB2PRD 	DATABASE=BDB2P04;
LIBNAME DB2ATB 		DB2 AUTHDOMAIN=DB2SGCEN SCHEMA=DB2ATB 	DATABASE=BDB2P04;
LIBNAME GESTAOPJ "/DADOS/UNV/INTVAR/DIVDINGEST/INTERNO/GESTAOPJ";
LIBNAME AUXILIAR "/DADOS/PUBLICA/B_AUXILIAR/";
LIBNAME GECEN "/DADOS/EXTERNO/GECEN";
LIBNAME PSOVD POSTGRES SERVER='172.17.71.80' DATABASE='POSTGRES' PORT='5432' USER='UNV' PASSWORD='UNV9500' SCHEMA='OVD';

%conectardb2(REL);
%conectardb2(MIV);
%conectardb2(MCI);
%conectardb2(ATB);
%conectardb2(PRD);


/*# BIBLIOTECAS - ############################################################################################################*/
/*############################################################################################################################*/
/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/
DATA _NULL_;
	IF &AnoMes=0 THEN
		D0=Today();
	ELSE
		DO;
			AA=Floor(&AnoMes/100);
			MM=&AnoMes-(AA*100);
			D0=IntNx('month',MDY(MM,1,AA),1);
		END;

	D1=SetDiaUtilAnterior(Smallest(1,D0,Today()),1);
	CALL SYMPUT('D1',D1);
	CALL SYMPUT('AnoMes',Put(D1, yymmn6.));
	CALL SYMPUT('MesAno',Put(D1, mmyyn6.));
	CALL SYMPUT('Ini',"'"||Put(IntNx('month',D1,0), yymmdd10.)||"'");
	CALL SYMPUT('Fim',"'"||Put(D1, yymmdd10.)||"'");
	CALL SYMPUT('Ano',Year(D1));
	CALL SYMPUT('Mes',Month(D1));
RUN;

%Put &D1 &AnoMes &MesAno &Ini &Fim &Ano &Mes;

/*# VARIÁVEIS - ##############################################################################################################*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# CARTEIRAS DO ESCOPO - #####################################################################################################*


/*CARTEIRAS - DEP. ATIVAS - (303, 321, 315, 323, 339, 328 - 322 - 304 e 382) */


PROC SQL;
	CREATE TABLE WORK.CARTEIRAS AS 
		SELECT t1.CD_PRF_DEPE AS PREFIXO, 
			t1.NR_SEQL_CTRA AS CARTEIRA, 
			t1.CD_TIP_CTRA AS TIPO_CARTEIRA,
			t1.NR_MTC_ADM_CTRA AS MTR_GERENTE,
			t1.QT_CLI_CTRA AS QTD_CLIENTES,
			t2.cod_UOR AS UOR, 
			t2.tipo_dependencia,
			t2.cod_agrupamento_fixo,
			t2.super as SUPER,
			t2.gerev AS GEREV,
			t2.diretoria_jurisdicionante AS DIRETORIA
		FROM AUXILIAR.dependencias_completa t2
			INNER JOIN REL.CTRA_CLI t1 ON (t2.prefixo = t1.CD_PRF_DEPE)
				WHERE t2.tipo_dependencia IN /*13 Ag. varejo; 15 PAA; 35 Ag. Estilo*/
	                                        ( 13, 15, 35 )
                  AND t2.status_dependencia = 'A' 
                  AND t1.CD_TIP_CTRA IN ( 303, 315, 321, 322, 328 );
QUIT;

/*############################################################################################################################*/
/*# CARTEIRAS DO FIM - #####################################################################################################*







/*############################################################################################################################*/
/*# CLIENTES DO ESCOPO - #####################################################################################################*/
%BuscarPrefixosIndicador(IND=&nr_indicador., MMAAAA=&MesAno., NIVEL_CTRA=1, SO_AG_PAA=0);

/*# CLIENTES DO ESCOPO - #####################################################################################################*/
%LIBCONEXAO(222);

DATA _NULL_;
	TBL_CLI =  COMPRESS("ICNX222.CLI_IND_000000222_DT"||PUT(&MesAno,Z6.));
	CALL SYMPUT("TBL_CLI",TBL_CLI);
RUN;

%PUT &TBL_CLI;

DATA CLIENTES;
	SET &TBL_CLI (WHERE=(COMP IN(5, 6)));
	IND=&NR_INDICADOR;

	IF COMP = 5 THEN
		COMP=1;
	ELSE COMP=2;
RUN;

PROC SQL;
	CREATE TABLE CLIENTES_DIRECIONADOR AS
		SELECT A.* 
			FROM CLIENTES A 
				INNER JOIN PREFIXOS_IND B ON (A.PREFDEP = B.PREFDEP AND A.CTRA = B.CTRA);
QUIT;

/*############################################################################################################################*/
/*# SUMARIZAR ################################################################################################################*/
PROC SQL;
	CREATE TABLE WORK.SUM_CTRA AS 
		SELECT 
			t1.PREFDEP, 
			t1.CTRA,
			t1.COMP,
			t1.VLR
		FROM WORK.CLIENTES_DIRECIONADOR t1
	;
QUIT;

/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COL_SUM;
	CREATE TABLE COL_SUM (Coluna CHAR(50), Tipo CHAR(10) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COL_SUM VALUES ('VLR', 'SUM');
QUIT;

%SumarizadorCNX(TblSASValores=SUM_CTRA, TblSASColunas=COL_SUM,  NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=SUMARIZADA, AAAAMM=&AnoMes.);

PROC SQL;
	CREATE TABLE WORK.SUMARIZADA AS 
		SELECT 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.TP_CTRA, 
			t1.COMP,
			t1.VLR
		FROM WORK.SUMARIZADA t1;
QUIT;

/*# SUMARIZAR - FIM ##########################################################################################################*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# CONEXÃO ##################################################################################################################*/
PROC SQL;
	CREATE TABLE WORK.BASE_CONEXAO_CLI AS 
		SELECT
			&NR_INDICADOR. AS IND,
			t1.COMP, 
			t1.PREFDEP AS PREFDEP, 
			t1.UOR,
			t1.CTRA, 
			t1.CLI,
			t1.MMAAAA, 
			t1.VLR
		FROM WORK.CLIENTES_DIRECIONADOR t1
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.BASE_CONEXAO AS 
		SELECT 
			&NR_INDICADOR. AS IND,
			t1.COMP,
			0 AS COMP_PAI,
			0 AS ORD_EXI,
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA,
			t1.VLR AS VLR_RLZ,
			0 AS VLR_ORC,
			0 AS VLR_ATG,
			TODAY() AS POSICAO FORMAT=YYMMDDD10. 
		FROM WORK.SUMARIZADA t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.BASE_CONEXAO_COMP0 AS 
		SELECT 
			&NR_INDICADOR. AS IND,
			0 AS COMP,
			0 AS COMP_PAI,
			0 AS ORD_EXI,
			t1.UOR,
			t1.PREFDEP, 
			t1.CTRA,
			t1.VLR AS VLR_RLZ,
			0 AS VLR_ORC,
			0 AS VLR_ATG,
			TODAY() AS POSICAO FORMAT=YYMMDDD10. 
		FROM WORK.SUMARIZADA t1;
QUIT;

DATA BASE_CONEXAO;
	SET BASE_CONEXAO BASE_CONEXAO_COMP0;
RUN;

PROC SORT DATA=BASE_CONEXAO;
	BY IND COMP COMP_PAI ORD_EXI UOR CTRA;
QUIT;

%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CONEXAO_CLI);
%BaseIndicadorCNX(TabelaSAS=BASE_CONEXAO);
%ExportarCNX_CLI(IND=&NR_INDICADOR., MMAAAA=&MesAno.);
%ExportarCNX_IND(IND=&NR_INDICADOR., MMAAAA=&MesAno., ORC=0, RLZ=1);
%ExportarCNX_COMP(IND=&NR_INDICADOR., MMAAAA=&MesAno., ORC=0, RLZ=1);

/*# CONEXÃO - FIM ############################################################################################################*/
/*############################################################################################################################*/
/*############################################################################################################################*/
/*# CKECKOUT #################################################################################################################*/
%indCheckOut();

/*############################################################################################################################*/





/* A PARTIR DAQUI COPIAR  */


/*#################################################################################################################*/

/*PROCESSAMENTOS*/
/*#################################################################################################################*/


/*CARTEIRAS - DEP. ATIVAS - (303, 315, 321, 322, 328)*/
PROC SQL;
   CREATE TABLE WORK.CARTEIRAS AS 
   SELECT t1.CD_PRF_DEPE AS PREFIXO, 
          t1.NR_SEQL_CTRA AS CARTEIRA, 
          t1.CD_TIP_CTRA AS TIPO_CARTEIRA,
		  t1.NR_MTC_ADM_CTRA AS MTR_GERENTE,
		  t1.QT_CLI_CTRA AS QTD_CLIENTES,
          t2.cod_UOR AS UOR, 
          t2.tipo_dependencia,
		  t2.cod_agrupamento_fixo,
		  t2.super as SUPER,
		  t2.gerev AS GEREV,
          t2.diretoria_jurisdicionante AS DIRETORIA
      FROM AUXILIAR.dependencias_completa t2
           INNER JOIN REL.CTRA_CLI t1 ON (t2.prefixo = t1.CD_PRF_DEPE)
      WHERE t2.tipo_dependencia IN /*13 Ag. varejo; 15 PAA; 35 Ag. Estilo*/ 
           (
           13,
           15,
           35
           ) AND t2.status_dependencia = 'A' AND t1.CD_TIP_CTRA IN 
           (
           303,
           315,
           321,
           322,
           328
           );
QUIT;


/*DEPENDÊNCIAS*/
PROC SQL;
   CREATE TABLE WORK.DEPENDENCIAS_DEPE AS 
   SELECT t1.prefixo, 
          t1.cod_UOR,
		  t1.super,
		  t1.GEREV,
		  t1.diretoria_jurisdicionante
      FROM AUXILIAR.DEPENDENCIAS_COMPLETA t1
      WHERE t1.status_dependencia = 'A' AND t1.cod_agrupamento_fixo IN(877, 872, 908, 610) 
			AND t1.data_inauguracao NOT = '31Dec9999'd AND t1.tipo_dependencia IN /*REMOVE DEPENDENCIAS NÃO INAUGURADAS*/
           (
           13,
           15,
           35
           );
QUIT;

/*SUPERINTENDÊNCIAS*/
PROC SQL;
   CREATE TABLE WORK.SUPERINTENDENCIAS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM AUXILIAR.DEPENDENCIAS_COMPLETA t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia = 4 AND t1.vice_presidencia = 8166 AND t1.pilar = 
           1 ) AND t1.prefixo NOT = 8481 AND t1.prefixo NOT = 9300; /*8481 SUPER GOVERNO SP*/
QUIT;

/*GEREVS*/
PROC SQL;
   CREATE TABLE WORK.GEREVS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM AUXILIAR.DEPENDENCIAS_COMPLETA t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia = 3 AND t1.vice_presidencia = 8166 
            AND t1.prefixo IN (SELECT DISTINCT gerev FROM CARTEIRAS)
			AND t1.prefixo NOT = 3903); /*3903 GEREV A. RENDA NORTE*/
QUIT;

/*DIRETORIAS*/
PROC SQL;
   CREATE TABLE WORK.DIRETORIAS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM AUXILIAR.DEPENDENCIAS_COMPLETA t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia IN (2) AND t1.prefixo IN (8477, 8592, 9500));
QUIT;
/*VICE PRESIDENCIA*/
PROC SQL;
   CREATE TABLE WORK.VPS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM AUXILIAR.DEPENDENCIAS_COMPLETA t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia IN (23) AND t1.prefixo IN (8166));
QUIT;

PROC SQL;
CREATE TABLE WORK.DEPENDENCIAS AS 
SELECT * FROM WORK.DEPENDENCIAS_DEPE
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIAS
 OUTER UNION CORR 
SELECT * FROM WORK.SUPERINTENDENCIAS
 OUTER UNION CORR 
SELECT * FROM WORK.GEREVS
 OUTER UNION CORR 
SELECT * FROM WORK.VPS
;
Quit;

PROC SQL;
	CREATE TABLE WORK.CARTEIRAS_COMP AS 
		SELECT DISTINCT t1.PREFIXO,
			   t1.CARTEIRA
		FROM WORK.CARTEIRAS t1;
QUIT;


PROC SQL;
	CREATE TABLE WORK.DEPE_COMP AS 
		SELECT DISTINCT t1.PREFIXO,
			   (0) AS CARTEIRA
		FROM WORK.DEPENDENCIAS t1;
QUIT;


PROC SQL;
CREATE TABLE WORK.DEPE_CTRA AS 
SELECT * FROM WORK.DEPE_COMP
 OUTER UNION CORR 
SELECT * FROM WORK.CARTEIRAS_COMP
;
Quit;

/*AÇÃO 4TRI (NVL COMPONENTE)*/
/*Meta - % Atg - Nec. Diária*/

/*
######################
# HEADER / VARIÁVEIS #
######################
*/

/*Calcula a quantidade de dias úteis até o fim doa mês*/
DATA _NULL_;
	QNT_DIAS_UTEIS_PASSADO= diasUteisEntreDatas(primeiroDiaMes(TODAY()), TODAY()) - 1;
    QNT_DIAS_UTEIS=diasUteisEntreDatas(TODAY(), ultimoDiaMes(TODAY())) - 1;
	QNT_DIAS_UTEIS_MES=diasUteisEntreDatas(primeiroDiaMes(TODAY()), ultimoDiaMes(TODAY()));
	DIA_UTIL_ANTERIOR = DAY(TODAY()) - 1;
    CALL SYMPUT('QNT_DIAS_UTEIS',COMPRESS(QNT_DIAS_UTEIS,' '));
	CALL SYMPUT('QNT_DIAS_UTEIS_PASSADO',COMPRESS(QNT_DIAS_UTEIS_PASSADO,' '));
	CALL SYMPUT('QNT_DIAS_UTEIS_MES',COMPRESS(QNT_DIAS_UTEIS_MES,' '));
	CALL SYMPUT('DATA_HOJE',COMPRESS(TODAY(),' '));
	CALL SYMPUT('DATA_PERSONALIZADA',COMPRESS(MDY( 11, 30, 2017 ) ,' ')); /*MDY( month, day, year ) */
	CALL SYMPUT('DIA_UTIL_ANTERIOR',COMPRESS(DIA_UTIL_ANTERIOR,' '));
	/*CALL SYMPUT('NEC_DIARIA',COMPRESS(((100 / &qnt_dias_uteis_mes) * (&qnt_dias_uteis_passado + 1)),' '));*/
	CALL SYMPUT('NEC_DIARIA',COMPRESS(((100 / QNT_DIAS_UTEIS_MES) * (QNT_DIAS_UTEIS_PASSADO + 1)),' '));
RUN;
%LET dia_referencia = &DIA_UTIL_ANTERIOR;


/*#################################################################################################################*/
/*#################################################################################################################*/



/*###########################*/
/*         IQO               */
/*###########################*/
PROC SQL;
   CREATE TABLE WORK.DEPENDENCIAS_IQO AS 
   SELECT t1.agencia AS PREFIXO, 
          /* QTD_DEVOLVIDOS */
            (SUM(IFN(t1.DEVOLVIDO = 0, 1, 0, 0))) AS QTD_ACEITOS, 
          /* QTD_TOTAL */
            (COUNT(t1.DEVOLVIDO)) AS QTD_TOTAL
      FROM GESTAOPJ.IQO t1
      GROUP BY t1.agencia;
QUIT;

PROC SQL;
	CREATE TABLE WORK.DEPENDENCIAS_IQO_QTD AS 
	SELECT t1.PREFIXO,
		   t1.GEREV,
		   t1.SUPER,
		   t1.DIRETORIA_JURISDICIONANTE AS DIRETORIA,
		   t2.QTD_ACEITOS,
		   t2.QTD_TOTAL
	FROM WORK.DEPENDENCIAS_DEPE t1
	LEFT JOIN WORK.DEPENDENCIAS_IQO t2 ON (t1.PREFIXO = t2.PREFIXO);
QUIT;

PROC SQL;
	CREATE TABLE WORK.DEPE_IQO AS 
	SELECT t1.PREFIXO,
		   (0) AS CARTEIRA,
		   t1.QTD_ACEITOS,
		   t1.QTD_TOTAL
	FROM WORK.DEPENDENCIAS_IQO_QTD t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.GEREV_IQO AS 
	SELECT t1.GEREV AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_ACEITOS) AS QTD_ACEITOS,
		   SUM(t1.QTD_TOTAL) AS QTD_TOTAL
	FROM WORK.DEPENDENCIAS_IQO_QTD t1
	GROUP BY t1.GEREV;
QUIT;

PROC SQL;
	CREATE TABLE WORK.SUPER_IQO AS 
	SELECT t1.SUPER AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_ACEITOS) AS QTD_ACEITOS,
		   SUM(t1.QTD_TOTAL) AS QTD_TOTAL
	FROM WORK.DEPENDENCIAS_IQO_QTD t1
	GROUP BY t1.SUPER;
QUIT;

PROC SQL;
	CREATE TABLE WORK.DIRETORIA_IQO AS 
	SELECT t1.DIRETORIA AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_ACEITOS) AS QTD_ACEITOS,
		   SUM(t1.QTD_TOTAL) AS QTD_TOTAL
	FROM WORK.DEPENDENCIAS_IQO_QTD t1
	GROUP BY t1.DIRETORIA;
QUIT;


PROC SQL;
	CREATE TABLE WORK.VIVAP_IQO AS 
	SELECT (8166) AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_ACEITOS) AS QTD_ACEITOS,
		   SUM(t1.QTD_TOTAL) AS QTD_TOTAL
	FROM WORK.DEPENDENCIAS_IQO_QTD t1;
QUIT;

PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_IQO AS 
/*SELECT * FROM WORK.CTRA_TR_FC
 OUTER UNION CORR */
SELECT * FROM WORK.DEPE_IQO
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_IQO
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_IQO
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_IQO
 OUTER UNION CORR 
SELECT * FROM WORK.VIVAP_IQO
;
Quit;

/*###########################*/
/*         IQO               */
/*###########################*/

/*###########################*/
/*         IQP               */
/*###########################*/
PROC SQL;
   CREATE TABLE WORK.CARTEIRAS_IQP AS 
   SELECT t1.PREFIXO,
   		  t1.CARTEIRA,
		  t2.GEREV,
		  t2.SUPER,
		  t2.DIRETORIA,
          t1.QTD_PROCESSOS,
          t1.QTD_DILIGENCIAS
      FROM GESTAOPJ.DEPE_CTRA_IQP t1
	  LEFT JOIN WORK.CARTEIRAS t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA);
QUIT;

PROC SQL;
	CREATE TABLE WORK.DEPE_IQP AS 
	SELECT t1.PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_PROCESSOS) AS QTD_PROCESSOS,
		   SUM(t1.QTD_DILIGENCIAS) AS QTD_DILIGENCIAS
	FROM WORK.CARTEIRAS_IQP t1
	GROUP BY t1.PREFIXO;
QUIT;

PROC SQL;
	CREATE TABLE WORK.GEREV_IQP AS 
	SELECT t1.GEREV AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_PROCESSOS) AS QTD_PROCESSOS,
		   SUM(t1.QTD_DILIGENCIAS) AS QTD_DILIGENCIAS
	FROM WORK.CARTEIRAS_IQP t1
	GROUP BY t1.GEREV;
QUIT;

PROC SQL;
	CREATE TABLE WORK.SUPER_IQP AS 
	SELECT t1.SUPER AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_PROCESSOS) AS QTD_PROCESSOS,
		   SUM(t1.QTD_DILIGENCIAS) AS QTD_DILIGENCIAS
	FROM WORK.CARTEIRAS_IQP t1
	GROUP BY t1.SUPER;
QUIT;

PROC SQL;
	CREATE TABLE WORK.DIRETORIA_IQP AS 
	SELECT t1.DIRETORIA AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_PROCESSOS) AS QTD_PROCESSOS,
		   SUM(t1.QTD_DILIGENCIAS) AS QTD_DILIGENCIAS
	FROM WORK.CARTEIRAS_IQP t1
	GROUP BY t1.DIRETORIA;
QUIT;

PROC SQL;
	CREATE TABLE WORK.VIVAP_IQP AS 
	SELECT (8166) AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_PROCESSOS) AS QTD_PROCESSOS,
		   SUM(t1.QTD_DILIGENCIAS) AS QTD_DILIGENCIAS
	FROM WORK.CARTEIRAS_IQP t1;
QUIT;

PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_IQP AS 
SELECT * FROM WORK.CARTEIRAS_IQP
 OUTER UNION CORR
SELECT * FROM WORK.DEPE_IQP
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_IQP
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_IQP
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_IQP
 OUTER UNION CORR 
SELECT * FROM WORK.VIVAP_IQP
;
Quit;

/*###########################*/
/*         IQP               */
/*###########################*/

/*###########################*/
/*         OCORRENCIAS       */
/*###########################*/

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_CLI_CTRA AS 
   SELECT t1.CD_CLI AS MCI, 
          t1.CD_PRF_DEPE AS PREFIXO, 
          t1.NR_SEQL_CTRA AS CARTEIRA
      FROM REL.CLI_CTRA t1
	INNER JOIN REL.CTRA_CLI t2 ON (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE AND t1.NR_SEQL_CTRA = t2.NR_SEQL_CTRA)
	WHERE t2.CD_TIP_CTRA IN (303, 315, 321, 322, 328);
QUIT;

PROC SQL;
   CREATE TABLE WORK.CLI_CTRA_OCORRENCIA AS 
   SELECT t1.cd_cli, 
          t1.origem, 
          t1.procedencia, 
          t1.ts_solucao, 
          t2.PREFIXO, 
          t2.CARTEIRA
      FROM PSOVD.OCORRENCIAS_SOLUCIONADAS t1
      INNER JOIN WORK.QUERY_FOR_CLI_CTRA t2 ON (t1.cd_cli = t2.MCI AND t1.CD_DEPE_RSP_FATO = t2.PREFIXO)
	  WHERE MONTH(t1.TS_SOLUCAO) = MONTH(TODAY()) AND YEAR(t1.TS_SOLUCAO) = YEAR(TODAY());
QUIT;

PROC SQL;
   CREATE TABLE WORK.CARTEIRAS_OCORRENCIAS AS 
   SELECT t1.PREFIXO,
   		  t1.CARTEIRA,
		  SUM(IFN(t1.ORIGEM = "SAC", 1, 0, 0)) AS QTD_SAC,
		  SUM(IFN(t1.ORIGEM = "OUVIDORIA" AND t1.PROCEDENCIA = "procedente", 1, 0, 0)) AS QTD_OVD,
		  SUM(IFN(t1.ORIGEM = "BACEN" AND t1.PROCEDENCIA = "procedente", 1, 0, 0)) AS QTD_BACEN,
		  t2.GEREV,
		  t2.SUPER,
		  t2.DIRETORIA
      FROM WORK.CLI_CTRA_OCORRENCIA t1
	  LEFT JOIN WORK.CARTEIRAS t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	  WHERE MONTH(t1.TS_SOLUCAO) = MONTH(TODAY()) AND YEAR(t1.TS_SOLUCAO) = YEAR(TODAY()) AND t2.GEREV IS NOT NULL
	  GROUP BY t1.PREFIXO, t1.CARTEIRA;
QUIT;

PROC SQL;
	CREATE TABLE WORK.DEPE_OCORRENCIAS AS 
	SELECT t1.PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_SAC) AS QTD_SAC,
		   SUM(t1.QTD_OVD) AS QTD_OVD,
		   SUM(t1.QTD_BACEN) AS QTD_BACEN
	FROM WORK.CARTEIRAS_OCORRENCIAS t1
	GROUP BY t1.PREFIXO;
QUIT;

PROC SQL;
	CREATE TABLE WORK.GEREV_OCORRENCIAS AS 
	SELECT t1.GEREV AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_SAC) AS QTD_SAC,
		   SUM(t1.QTD_OVD) AS QTD_OVD,
		   SUM(t1.QTD_BACEN) AS QTD_BACEN
	FROM WORK.CARTEIRAS_OCORRENCIAS t1
	GROUP BY t1.GEREV;
QUIT;

PROC SQL;
	CREATE TABLE WORK.SUPER_OCORRENCIAS AS 
	SELECT t1.SUPER AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_SAC) AS QTD_SAC,
		   SUM(t1.QTD_OVD) AS QTD_OVD,
		   SUM(t1.QTD_BACEN) AS QTD_BACEN
	FROM WORK.CARTEIRAS_OCORRENCIAS t1
	GROUP BY t1.SUPER;
QUIT;

PROC SQL;
	CREATE TABLE WORK.DIRETORIA_OCORRENCIAS AS 
	SELECT t1.DIRETORIA AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_SAC) AS QTD_SAC,
		   SUM(t1.QTD_OVD) AS QTD_OVD,
		   SUM(t1.QTD_BACEN) AS QTD_BACEN
	FROM WORK.CARTEIRAS_OCORRENCIAS t1
	GROUP BY t1.DIRETORIA;
QUIT;

PROC SQL;
	CREATE TABLE WORK.VIVAP_OCORRENCIAS AS 
	SELECT (8166) AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_SAC) AS QTD_SAC,
		   SUM(t1.QTD_OVD) AS QTD_OVD,
		   SUM(t1.QTD_BACEN) AS QTD_BACEN
	FROM WORK.CARTEIRAS_OCORRENCIAS t1;
QUIT;

PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_OCORRENCIAS AS 
SELECT * FROM WORK.CARTEIRAS_OCORRENCIAS
 OUTER UNION CORR
SELECT * FROM WORK.DEPE_OCORRENCIAS
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_OCORRENCIAS
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_OCORRENCIAS
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_OCORRENCIAS
 OUTER UNION CORR 
SELECT * FROM WORK.VIVAP_OCORRENCIAS
;
Quit;

/*###########################*/
/*         OCORRENCIAS       */
/*###########################*/


/*#############################*/
/*CONSOLIDADO*/
/*#############################*/
PROC SQL;
	CREATE TABLE WORK.CONSOLIDADO AS 
	SELECT DISTINCT &DATA_HOJE. FORMAT=DateMysql. AS POSICAO,
		   t1.PREFIXO,
		   t1.CARTEIRA,
		   (.) AS IQO_ORC,
		   ((t5.QTD_ACEITOS / t5.QTD_TOTAL)*100) AS IQO_RLZD,
		   (.) AS IQP_ORC,
		   (((t6.QTD_PROCESSOS - t6.QTD_DILIGENCIAS) / t6.QTD_PROCESSOS)*100) AS IQP_RLZD,
		   t7.QTD_SAC,
		   t7.QTD_OVD,
		   t7.QTD_BACEN
	FROM WORK.DEPE_CTRA t1
	LEFT JOIN WORK.DEPE_CTRA_IQO t5 ON (t1.PREFIXO = t5.PREFIXO AND t1.CARTEIRA = t5.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_IQP t6 ON (t1.PREFIXO = t6.PREFIXO AND t1.CARTEIRA = t6.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_OCORRENCIAS t7 ON (t1.PREFIXO = t7.PREFIXO AND t1.CARTEIRA = t7.CARTEIRA);
		
QUIT;

/*#############################*/
/*CONSOLIDADO*/
/*#############################*/





/*#################################################################################################################*/
/*#################################################################################################################*/
/*EXPORTAR REL*/
/*#################################################################################################################*/


/*TABELA AUXILIAR DE TABELAS DE CARGA E ROTINAS DO SISTEMA REL*/
PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
		/*TABELAS PARA EXPORTAÇÃO > VALUES('TABELA_SAS', 'ROTINA') > INICIAR PELA PRINCIPAL*/
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('WORK.CONSOLIDADO', 'painel-experiencia-mpe');
QUIT;


%ExportarDadosREL(TABELAS_EXPORTAR_REL);

/*#################################################################################################################*/
/*#################################################################################################################*/


