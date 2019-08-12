
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

%LET Tx_Fon=6062;

%CONECTARDB2(MIV);
%CONECTARDB2(REL);

LIBNAME unc_ata "/dados/externo/UNC/ATA";
LIBNAME unc_gat "/dados/externo/UNC/GAT/TELEFONE";
LIBNAME AUX_TP "/dados/infor/producao/Tempo_Resposta_PF_PJ";


DATA _NULL_;
	
D1 = diaUtilAnterior(TODAY());
CALL SYMPUT('D1',COMPRESS(D1,' '));

ANOMES = Put(D1, yymmn6.);
CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));

MMAAAA=PUT(D1,mmyyn6.);
CALL SYMPUT('MMAAAA', COMPRESS(MMAAAA,' '));

RUN;


/**************************************************/
/**************************************************/
/***********************ACORDO*********************/
/**************************************************/
/**************************************************/

LIBNAME DB2ATB DB2 DATABASE=BDB2P04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SGCEN;


PROC SQL;
CREATE TABLE ACORDO_CARTEIRA AS 
SELECT DISTINCT cd_uor_ctra AS UOR, nr_seql_ctra as CTRA
FROM DB2ATB.vl_aprd_in_ctra
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and  cd_in_mod_avlc = 11956;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_CARTEIRA_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_CARTEIRA t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;


PROC SQL;
CREATE TABLE ACORDO_PREFIXO AS 
SELECT DISTINCT cd_uor AS UOR, 0 as CTRA
FROM DB2ATB.vl_aprd_in_uor
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and cd_In_mod_avlc = 11955;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_PREFIXO_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_PREFIXO t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;


PROC SQL;

CREATE TABLE ACORDO AS
 
   SELECT * FROM ACORDO_CARTEIRA_1
   OUTER UNION CORR
   SELECT * FROM ACORDO_PREFIXO_1;

Quit;


PROC SQL;
CREATE TABLE ACORDO_1 AS 
SELECT DISTINCT PREFIXO, t1.CTRA, t1.UOR
FROM ACORDO t1
order by 1,2;
QUIT;


/*#############*/
/*PROCESSAMENTO*/
/*#############*/

/*TROCANDO A TABELA DE DEPENDENCIAS*/

PROC SQL;
   CREATE TABLE WORK.nova_dependencias AS SELECT 
   INPUT(t1.PrefDep, d4.) as prefixo, 
   INPUT(t1.TipoDep, d3.) as tipo_dependencia,
   INPUT(t1.UOR, d9.) as cod_UOR,
   INPUT(t1.PREFSUPREG, d4.) as gerev,
   INPUT(t1.PREFSUPEST, d4.) as super,
   INPUT(t1.PREFUEN, d4.) as diretoria_jurisdicionante, 
   8592 as divar,
   8166 as vice_presidencia,
   t1.CD_GR_DEPE_FXO as cod_agrupamento_fixo
   FROM IGR.IGRREDE_&ANOMES. t1
   inner join ACORDO_PREFIXO_1 t2 on INPUT(t1.PrefDep, d4.) = t2.prefixo
   ORDER BY 1; 
QUIT;


PROC STDIZE OUT=WORK.nova_dependencias REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;

   CREATE TABLE WORK.CARTEIRAS AS SELECT
          distinct t1.cd_cli,

          t1.CD_PRF_DEPE AS PREFIXO, 
          t1.NR_SEQL_CTRA_ATB AS CARTEIRA, 
          t1.CD_TIP_CTRA AS TIPO_CARTEIRA,
		  t2.cod_UOR AS UOR, 
          t2.tipo_dependencia,
		  t2.cod_agrupamento_fixo,
		  t2.super as SUPER,
		  t2.gerev AS GEREV,
          t2.diretoria_jurisdicionante AS DIRETORIA,
		  divar,
          vice_presidencia
      FROM WORK.nova_dependencias t2
           INNER JOIN COMUM.PAI_REL_&ANOMES. t1 ON (t2.prefixo = t1.CD_PRF_DEPE)
		   INNER JOIN ACORDO_CARTEIRA_1 t3 ON t1.CD_PRF_DEPE = t3.PREFIXO AND  t1.NR_SEQL_CTRA_ATB = t3.CTRA
      /*t2.tipo_dependencia IN (13, 15, 35) */ WHERE t1.NR_SEQL_CTRA_ATB > 5000 /*t1.CD_TIP_CTRA IN (303, 315, 321, 322, 328)*/;
QUIT;


PROC STDIZE OUT=WORK.CARTEIRAS REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;

   CREATE TABLE WORK.CARTEIRAS AS SELECT
          
          distinct t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.TIPO_CARTEIRA,
		  count( t1.cd_cli) AS QTD_CLIENTES,
          t1.UOR, 
          t1.tipo_dependencia,
		  t1.cod_agrupamento_fixo,
		  t1.SUPER,
		  t1.GEREV,
          t1.DIRETORIA,
		  divar,
          vice_presidencia

      FROM WORK.CARTEIRAS t1	  
	  WHERE t1.CARTEIRA IS NOT MISSING AND t1.CARTEIRA <> 0
	  group by 1, 2
      ;

QUIT;


/*#############*/
/*PROCESSAMENTO*/
/*#############*/

PROC SQL;
   CREATE TABLE WORK.DEPENDENCIAS_DEPE AS 
   SELECT t1.prefixo, 
          t1.cod_UOR AS UOR,
		  t1.super,
		  t1.GEREV,
		  t1.diretoria_jurisdicionante,
		  t1.divar,
          t1.vice_presidencia
      FROM WORK.nova_dependencias t1
      /* WHERE t1.cod_agrupamento_fixo IN(877, 872, 908, 610, 613, 616) 
			AND t1.tipo_dependencia IN (13, 15, 35)
			AND t1.PREFIXO NOT IN (7058, 5812)*/;
QUIT;


PROC SQL;
   CREATE TABLE WORK.GEREVS AS 
   SELECT DISTINCT gerev AS prefixo, 
          input(t2.UOR, 9.) AS UOR
      FROM WORK.nova_dependencias t1
      LEFT JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.gerev = input(t2.PREFDEP, 4.)
      /*WHERE t1.gerev NOT = 3903*/; 
QUIT;


PROC SQL;
   CREATE TABLE WORK.SUPERINTENDENCIAS AS 
   SELECT DISTINCT super AS prefixo, 
          input(t2.UOR, 9.) AS UOR
      FROM WORK.nova_dependencias t1
      LEFT JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.super = input(t2.PREFDEP, 4.)
      /*WHERE t1.super NOT IN (8481, 9300, 9009) AND t1.cod_agrupamento_fixo IN(877, 872, 908, 610, 613, 616) AND t2.UOR IS NOT MISSING*/; 
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIRETORIAS AS 
   SELECT DISTINCT diretoria_jurisdicionante AS prefixo, 
          input(t2.UOR, 9.) AS UOR
      FROM WORK.nova_dependencias t1
      LEFT JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.diretoria_jurisdicionante = input(t2.PREFDEP, 4.)
      /*WHERE t1.cod_agrupamento_fixo IN(877, 872, 908, 610, 613, 616)*/; 
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIVAR AS 
   SELECT DISTINCT DIVAR AS prefixo, 
          input(t2.UOR, 9.) AS UOR
      FROM WORK.nova_dependencias t1
      LEFT JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.DIVAR = input(t2.PREFDEP, 4.)
      /*WHERE t1.cod_agrupamento_fixo IN(877, 872, 908, 610, 613, 616)*/; 
QUIT;


PROC SQL;
   CREATE TABLE WORK.VPS AS 
   SELECT DISTINCT vice_presidencia AS prefixo, 
          input(t2.UOR, 9.) AS UOR
      FROM WORK.nova_dependencias t1
      LEFT JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.vice_presidencia = input(t2.PREFDEP, 4.)
      /*WHERE t1.cod_agrupamento_fixo IN(877, 872, 908, 610, 613, 616)*/; 
QUIT;


PROC SQL;
CREATE TABLE WORK.DEPENDENCIAS AS 
SELECT * FROM WORK.DEPENDENCIAS_DEPE
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIAS
 OUTER UNION CORR 
SELECT * FROM WORK.SUPERINTENDENCIAS
 OUTER UNION CORR 
 SELECT * FROM WORK.DIVAR
 OUTER UNION CORR 
SELECT * FROM WORK.GEREVS
 OUTER UNION CORR 
SELECT * FROM WORK.VPS;
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
SELECT * FROM WORK.CARTEIRAS_COMP;
Quit;


/*#####################*/
/*FALE COM - QUANTIDADE*/
/*#####################*/

/*PROCESSAMENTO DEMORADO*/

PROC SQL;

   CREATE TABLE AUX_TP.CTRA_CLI_FC AS 
      SELECT DISTINCT 

          t3.CD_PRF_DEPE AS PREFIXO, 
          t3.NR_SEQL_CTRA_ATB AS CARTEIRA,
		  t3.CD_CLI
          
      FROM DB2MIV.TX_MSG_EXPS t1
      INNER JOIN DB2MIV.DBT_ELET_MSG_EXPS t2 ON (t2.CD_CLI_MSG_EXPS = t1.CD_CLI_MSG_EXPS and t2.NR_SEQL_DBT = t1.NR_SEQL_DBT) 
      INNER JOIN COMUM.PAI_REL_&ANOMES. t3 ON (t2.CD_CLI_PJ = t3.CD_CLI)
	  
      WHERE DATEPART(t1.TS_CRIC_MSG) >= MDY(MONTH(&D1.),1,YEAR(&D1.)) AND DATEPART(t1.TS_CRIC_MSG) <= &D1. and t2.CD_TIP_DBT = 3 
      AND t1.CD_USU_RSP_EST_MSG IS NULL;

QUIT;


PROC SQL;

	CREATE TABLE WORK.CTRA_CLI_FC AS 
	SELECT *
    
	FROM AUX_TP.CTRA_CLI_FC t1
    INNER JOIN ACORDO_CARTEIRA_1 t2 ON t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA  = t2.CTRA
    ;

QUIT;


PROC SQL;
	CREATE TABLE WORK.CTRA_QTD_CLI_FC AS 
	SELECT t1.PREFIXO,
		   t1.CARTEIRA,
		   COUNT(*) AS QTD_CLI_USO_FC
	FROM WORK.CTRA_CLI_FC t1
	GROUP BY t1.PREFIXO, t1.CARTEIRA;
QUIT;


PROC SQL;
	CREATE TABLE WORK.CTRA_FC AS 
	SELECT DISTINCT t1.PREFIXO,
		   t1.CARTEIRA,
		   t1.GEREV,
		   t1.SUPER,
		   t1.DIRETORIA,
		   t1.DIVAR,
		   t1.vice_presidencia,
		   t1.QTD_CLIENTES,
		   t2.QTD_CLI_USO_FC
	FROM WORK.CARTEIRAS t1
	INNER JOIN WORK.CTRA_QTD_CLI_FC t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	/*WHERE t1.cod_agrupamento_fixo IN (877, 872, 908, 610, 613, 616)*/;	
QUIT;


PROC STDIZE DATA=WORK.CTRA_FC OUT=WORK.CTRA_FC REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
	CREATE TABLE WORK.DEPE_FC AS 
	SELECT DISTINCT t1.PREFIXO,
		   (0) AS CARTEIRA, 
		   SUM(t1.QTD_CLIENTES) AS QTD_CLIENTES,
		   SUM(t1.QTD_CLI_USO_FC) AS QTD_CLI_USO_FC
		   
	FROM WORK.CTRA_FC t1
	GROUP BY t1.PREFIXO;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.GEREV_FC AS 
	SELECT DISTINCT t1.GEREV AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_CLIENTES) AS QTD_CLIENTES,
		   SUM(t1.QTD_CLI_USO_FC) AS QTD_CLI_USO_FC
	FROM WORK.CTRA_FC t1
	GROUP BY t1.GEREV;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.SUPER_FC AS 
	SELECT DISTINCT t1.SUPER AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_CLIENTES) AS QTD_CLIENTES,
		   SUM(t1.QTD_CLI_USO_FC) AS QTD_CLI_USO_FC
	FROM WORK.CTRA_FC t1
	GROUP BY t1.SUPER;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.DIRETORIA_FC AS 
	SELECT DISTINCT t1.DIRETORIA AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_CLIENTES) AS QTD_CLIENTES,
		   SUM(t1.QTD_CLI_USO_FC) AS QTD_CLI_USO_FC
	FROM WORK.CTRA_FC t1
	GROUP BY t1.DIRETORIA;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.DIVAR_FC AS 
	SELECT DISTINCT t1.DIVAR AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_CLIENTES) AS QTD_CLIENTES,
		   SUM(t1.QTD_CLI_USO_FC) AS QTD_CLI_USO_FC
	FROM WORK.CTRA_FC t1
	GROUP BY t1.DIVAR;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.VIVAP_FC AS 
	SELECT DISTINCT (8166) AS PREFIXO,
		   (0) AS CARTEIRA,
		   SUM(t1.QTD_CLIENTES) AS QTD_CLIENTES,
		   SUM(t1.QTD_CLI_USO_FC) AS QTD_CLI_USO_FC
	FROM WORK.CTRA_FC t1;	
QUIT;


PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_FC AS 
SELECT * FROM WORK.CTRA_FC
 OUTER UNION CORR 
SELECT * FROM WORK.DEPE_FC
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_FC
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_FC
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_FC
 OUTER UNION CORR 
SELECT * FROM WORK.DIVAR_FC
OUTER UNION CORR 
SELECT * FROM WORK.VIVAP_FC;
Quit;


/*###########################*/
/*FALE COM - TEMPO DE RETORNO*/
/*###########################*/


PROC SQL;
   CREATE TABLE AUX_TP.QUERY_FOR_TX_MSG_EXPS AS 
   SELECT DISTINCT t2.CD_CLI_PJ AS mci, 
          (datepart(t1.TS_CRIC_MSG)) FORMAT=ddmmyy10. LABEL="data" AS data, 
          (timepart(t1.TS_CRIC_MSG)) FORMAT=time8. LABEL="hora" AS hora, 
          t1.TS_CRIC_MSG AS timestamp, 
          t1.CD_USU_RSP_EST_MSG AS responsavel, 
          t1.DT_LET_MSG FORMAT=ddmmyy10. AS data_leitr, 
          t1.HR_LET_MSG AS hora_leitr, 
          t1.CD_SNLC_MSG, 
          t1.TX_MSG,
		  t3.CD_PRF_DEPE AS PREFIXO,
		  t3.NR_SEQL_CTRA_ATB AS CARTEIRA
      FROM DB2MIV.TX_MSG_EXPS t1
	  INNER JOIN DB2MIV.DBT_ELET_MSG_EXPS t2 ON (t2.CD_CLI_MSG_EXPS = t1.CD_CLI_MSG_EXPS and t2.NR_SEQL_DBT = t1.NR_SEQL_DBT) 
	  INNER JOIN COMUM.PAI_REL_&ANOMES. t3 ON (t2.CD_CLI_PJ = t3.CD_CLI)
      WHERE DATEPART(t1.TS_CRIC_MSG) >= MDY(MONTH(&D1.),1,YEAR(&D1.)) AND  DATEPART(t1.TS_CRIC_MSG) <= &D1. AND t2.CD_TIP_DBT = 3
      ORDER BY t2.CD_CLI_PJ;
QUIT;


PROC SQL;

	CREATE TABLE WORK.QUERY_FOR_TX_MSG_EXPS AS 
	SELECT *
	FROM AUX_TP.QUERY_FOR_TX_MSG_EXPS t1
    INNER JOIN ACORDO_CARTEIRA_1 t2 ON t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA  = t2.CTRA;

QUIT;


PROC SQL;
   CREATE TABLE WORK.INTERACAO_CLIENTE AS 
   SELECT DISTINCT t2.PREFIXO, t2.CARTEIRA, t2.mci, 
          t2.data, 
          (MIN(t2.hora)) FORMAT=TIME8. AS hora_cliente, 
          t2.responsavel
      FROM WORK.QUERY_FOR_TX_MSG_EXPS t2
      WHERE t2.responsavel IS NULL
      GROUP BY t2.mci,
               t2.data,
               t2.responsavel;
QUIT;


PROC SQL;
   CREATE TABLE WORK.INTERACAO_BB AS 
   SELECT DISTINCT t2.PREFIXO, t2.CARTEIRA, t2.mci, 
          t2.data, 
          t2.hora
      FROM WORK.QUERY_FOR_TX_MSG_EXPS t2
      WHERE t2.responsavel IS NOT NULL;
QUIT;



PROC SQL;
   CREATE TABLE WORK.FALE_COM AS 
   SELECT DISTINCT t1.PREFIXO, t1.CARTEIRA, t1.mci, 
          t1.data, 
          t1.hora_cliente, 
          t2.hora LABEL='' AS hora_BB, 
          t1.responsavel, 

          (IFN(t2.hora IS MISSING, ('17:0:0't - t1.hora_cliente), 
           IFN(t2.hora LT t1.hora_cliente, ('17:0:0't - t1.hora_cliente), (t2.hora - t1.hora_cliente)))) FORMAT=TIME8. LABEL="tempo_start_2" AS tempo_start, 

          (WEEKDAY(t1.data)) AS dia_semana
      FROM WORK.INTERACAO_CLIENTE t1
      LEFT JOIN WORK.INTERACAO_BB t2 ON (t1.mci = t2.mci) AND (t1.data = t2.data)
      WHERE t1.hora_cliente BETWEEN '9:0:0't AND '17:0:0't AND WEEKDAY(t1.data) IN(2, 3, 4, 5, 6);
QUIT;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_FALE_COM_001E AS 
   SELECT DISTINCT t1.PREFIXO, t1.CARTEIRA, t1.mci, 
          t1.data, 
          t1.hora_cliente, 
          t1.responsavel, 
          (MIN(t1.tempo_start)) FORMAT=TIME8. AS tempo_start, 
          t1.dia_semana
      FROM WORK.FALE_COM t1
      GROUP BY t1.mci,
               t1.data,
               t1.hora_cliente,
               t1.responsavel,
               t1.dia_semana;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CLI_TR_FC AS 
   SELECT DISTINCT t1.PREFIXO, t1.CARTEIRA, t1.mci, 
          t1.data, 
          t1.hora_cliente, 
          t1.responsavel, 
          t1.tempo_start, 
          (IFC(t1.dia_semana EQ 2, "Segunda", IFC(t1.dia_semana eq 3, "Terça", IFC(t1.dia_semana eq 
            4, "Quarta", IFC(t1.dia_semana eq 5, "Quinta", IFC(t1.dia_semana eq 6, "Sexta", "Fim de Semana"
            )))))) AS dia
      FROM WORK.QUERY_FOR_FALE_COM_001E t1, WORK.FALE_COM t2
      WHERE (t1.mci = t2.mci AND t1.data = t2.data AND t1.tempo_start = t2.tempo_start AND t1.hora_cliente = 
           t2.hora_cliente) AND t1.dia_semana IN 
           (
           2,
           3,
           4,
           5,
           6
           )
      ORDER BY t1.hora_cliente;
QUIT;


PROC SQL;
	CREATE TABLE WORK.CTRA_TR_FC_MCI AS 
	SELECT DISTINCT t1.PREFIXO,
		   t1.CARTEIRA,
		   t1.GEREV,
		   t1.SUPER,
		   t1.DIRETORIA,
		   t1.DIVAR,
		   t2.tempo_start AS TEMPO_RETORNO
	FROM WORK.CARTEIRAS t1
	LEFT JOIN WORK.CLI_TR_FC t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
    WHERE t2.tempo_start IS NOT MISSING;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.CTRA_TR_FC AS 
	SELECT DISTINCT t1.PREFIXO,
		   t1.CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1
	GROUP BY t1.PREFIXO, t1.CARTEIRA;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.DEPE_TR_FC AS 
	SELECT DISTINCT t1.PREFIXO,
		   (0) AS CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1
	GROUP BY t1.PREFIXO;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.GEREV_TR_FC AS 
	SELECT DISTINCT t1.GEREV AS PREFIXO,
		   (0) AS CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1
	GROUP BY t1.GEREV;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.SUPER_TR_FC AS 
	SELECT DISTINCT t1.SUPER AS PREFIXO,
		   (0) AS CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1
	GROUP BY t1.SUPER;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.DIRETORIA_TR_FC AS 
	SELECT DISTINCT t1.DIRETORIA AS PREFIXO,
		   (0) AS CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1
	GROUP BY t1.DIRETORIA;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.DIVAR_TR_FC AS 
	SELECT DISTINCT t1.DIVAR AS PREFIXO,
		   (0) AS CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1
	GROUP BY t1.DIVAR;	
QUIT;


PROC SQL;
	CREATE TABLE WORK.VIVAP_TR_FC AS 
	SELECT DISTINCT (8166) AS PREFIXO,
		   (0) AS CARTEIRA,
		   AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
	FROM WORK.CTRA_TR_FC_MCI t1;	
QUIT;


PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_TR_FC AS 
SELECT * FROM WORK.CTRA_TR_FC
 OUTER UNION CORR 
SELECT * FROM WORK.DEPE_TR_FC
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_TR_FC
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_TR_FC
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_TR_FC
OUTER UNION CORR 
SELECT * FROM WORK.DIVAR_TR_FC
 OUTER UNION CORR 
SELECT * FROM WORK.VIVAP_TR_FC;
Quit;


/*###*/
/*ATA*/
/*###*/


PROC SQL;
   CREATE TABLE WORK.UNC_TB_ATA AS 
   SELECT t1.idGenesys, 
          t1.URA, 
          t1.ANI, 
          t1.DNIS, 
          t1.DataChamada, 
          t1.HoraChamada, 
          t1.Agencia, 
          t1.Conta, 
          INPUT(t1.MCI, 9.) AS MCI, 
          t1.Duracao, 
          t1.Transferida, 
          t1.Servico, 
          t1.Opcoes, 
          t1.Transacoes, 
          t1.Vazio
      FROM UNC_ATA.relatorio_detalhado_&MMAAAA. t1
      where t1.DataChamada<=&D1.; 
QUIT;


PROC SQL;
	CREATE TABLE WORK.MCI_CTRA AS 
	SELECT t1.CD_PRF_DEPE AS PREFIXO,
		   t1.NR_SEQL_CTRA_ATB AS CARTEIRA,
		   t2.CD_TIP_CTRA AS TIPO_CARTEIRA,
		   t1.CD_CLI AS MCI
	FROM COMUM.PAI_REL_&ANOMES. t1
	INNER JOIN DB2REL.CTRA_CLI t2 ON (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE AND t1.NR_SEQL_CTRA_ATB = t2.NR_SEQL_CTRA)
	/*WHERE t2.CD_TIP_CTRA IN (303, 315, 321, 322, 328)*/;
QUIT;


PROC SQL;
   CREATE TABLE WORK.UNC_TB_GAT AS 
   SELECT t2.PREFIXO,
		  t2.CARTEIRA, 
          t1.subordinada, 
          t1.protocoloAtend, 
          t1.clienteEncarteirado, 
          t1.mci, 
          t1.chaveAdmAtend, 
          t1.tipoCarteira, 
          t1.chaveAtendente, 
          t1.prefixoAtendente, 
          t1.statusAtend, 
          t1.tipoPessoaNaoCli, 
          t1.dataSolicitacaoAtend, 
          t1.horaSolicitacaoAtend, 
          t1.dataInicioAtend, 
          t1.horaInicioAtend, 
          t1.dataFimAtend, 
          t1.horaFimAtend,
		  diasUteisEntreDatas(t1.dataSolicitacaoAtend, t1.dataFimAtend) AS qtd_dias_uteis,
          t1.dataUltimaAnotacao, 
          t1.horaUltimaAnotacao, 
          t1.horaAberturaAgencia, 
          t1.horaFechamentoAgencia
      FROM UNC_GAT.tel&ANOMES. t1
	  INNER JOIN WORK.MCI_CTRA t2 ON (t1.MCI = t2.MCI)
	  WHERE t1.statusAtend = 40	AND t1.horaSolicitacaoAtend BETWEEN "9:0:0"t AND "17:0:0"t AND t1.dataFimAtend<=&D1.;
QUIT;


PROC SQL;
   CREATE TABLE WORK.MCI_GAT AS 
   SELECT t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.MCI,
   		  t1.dataSolicitacaoAtend, 
          t1.horaSolicitacaoAtend, 
          t1.dataInicioAtend, 
          t1.horaInicioAtend, 
          t1.dataFimAtend, 
          t1.horaFimAtend,
   		  IFN(t1.qtd_dias_uteis = 1 AND (t1.horaInicioAtend - t1.horaSolicitacaoAtend) <= "0:05:0"t, 1, 0, 0) AS ATD_IMEDIATO,
		  (
			IFN(t1.qtd_dias_uteis > 2, (t1.qtd_dias_uteis - 2)* "10:0:0"t, 0, 0) +
			IFN(t1.qtd_dias_uteis >= 2, ("17:0:0"t - t1.horaSolicitacaoAtend) + (t1.horaInicioAtend - "9:0:0"t), 0, 0) +
			IFN(t1.qtd_dias_uteis = 1, t1.horaInicioAtend - t1.horaSolicitacaoAtend, 0, 0)
		  ) FORMAT=TIME8. AS TEMPO_RETORNO_GAT,
		  t1.qtd_dias_uteis
      FROM WORK.UNC_TB_GAT t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CTRA_GAT_BASE AS 
   SELECT t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.GEREV,
		  t1.SUPER,
		  t1.DIRETORIA,
		  t1.DIVAR,
		  COUNT(t2.MCI) AS QTD_CHAMADAS,
		  SUM(t2.ATD_IMEDIATO) AS QTD_CHAMADAS_IMED,
		  AVG(t2.TEMPO_RETORNO_GAT) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CARTEIRAS t1
	  LEFT JOIN WORK.MCI_GAT t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	  WHERE t2.TEMPO_RETORNO_GAT IS NOT MISSING
	  GROUP BY t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.GEREV,
		  t1.SUPER,
		  t1.DIRETORIA,
          t1.DIVAR;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CTRA_GAT AS 
   SELECT t1.PREFIXO,
		  t1.CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1
	  GROUP BY t1.PREFIXO,
		  t1.CARTEIRA;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DEPE_GAT AS 
   SELECT t1.PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1
	  GROUP BY t1.PREFIXO;
QUIT;


PROC SQL;
   CREATE TABLE WORK.GEREV_GAT AS 
   SELECT t1.GEREV AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1
	  GROUP BY t1.GEREV;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SUPER_GAT AS 
   SELECT t1.SUPER AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1
	  GROUP BY t1.SUPER;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIRETORIA_GAT AS 
   SELECT t1.DIRETORIA AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1
	  GROUP BY t1.DIRETORIA;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIVAR_GAT AS 
   SELECT t1.DIVAR AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1
	  GROUP BY t1.DIVAR;
QUIT;


PROC SQL;
   CREATE TABLE WORK.VP_GAT AS 
   SELECT (8166) AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_IMED) AS QTD_CHAMADAS_IMED,
		  AVG(t1.TEMPO_RETORNO) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CTRA_GAT_BASE t1;
QUIT;


PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_GAT AS 
SELECT * FROM WORK.CTRA_GAT
 OUTER UNION CORR 
SELECT * FROM WORK.DEPE_GAT
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_GAT
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_GAT
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_GAT
OUTER UNION CORR 
SELECT * FROM WORK.DIVAR_GAT
 OUTER UNION CORR 
SELECT * FROM WORK.VP_GAT;
Quit;


/* ATA QTD ATENDIMENTOS */


PROC SQL;
   CREATE TABLE WORK.ATA_DEPENDENCIAS AS 
   SELECT t1.prefixo AS prefdep, 
          t1.cod_UOR AS uor
      FROM WORK.nova_dependencias t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.todos_0 AS
   SELECT t1.idGenesys,
          t1.URA,
          t1.ANI,
          t1.DNIS,
          t1.DataChamada,
          t1.HoraChamada,
          index(opcoes,"Carteira do cliente") as a,
          index(opcoes,"Agencia Informada") as b,
          index(opcoes,"Conta Informada") as c,
          compress(substr(opcoes,calculated a+21,4),': , ','A') as d,
          substr(opcoes,calculated b+19,4) as e,
          INPUT (compress(substr(opcoes,calculated c+17,9),': , ','A'), 9.) as f,
          t1.Agencia,
          t1.Conta,
          ifn (t1.MCI in ('', '0'), .,input(mci, 9.)) as mci,
          t1.Duracao,
          t1.Transferida,
          t1.Servico,
          t1.Opcoes,
          ifc (substr(t1.Opcoes,1,17)='Agencia Informada' and substr(t1.Opcoes,21,8)='Invalida',put (input(t1.Agencia, 5.), z5.),put (input(substr(t1.Opcoes,20,5), 5.), z5.)) as ag,
          t1.Transacoes,
          t1.Vazio,
          ifn (calculated ag ne '    .' and calculated ag ne agencia, input (agencia, 6.),.)  as uor
      FROM UNC_ATA.relatorio_detalhado_&MMAAAA. t1
      WHERE t1.DNIS = 2009 
and t1.Servico in ("s_telefone,agenciagerenciado,estilo_digital_unv,", "s_anp,atendimentoPF,exclusivo,*", "s_telefone,agencianaogerenciado,pj,*","s_telefone,atendimentopj,pj,*","s_telefone,pj,governo,*","s_telefone,pj,pj,*","s_telefone,agenciagerenciado,*,*","s_telefone,agenciagerenciado, ,*","s_telefone,agenciagerenciado,estilo_digital,*")
and t1.Transferida = 't' AND t1.DataChamada<=&D1.;
QUIT;


PROC SQL;
   CREATE TABLE WORK.todos AS
   SELECT t1.idGenesys,
          t1.URA,
          t1.ANI,
          t1.DNIS,
          t1.DataChamada,
          t1.HoraChamada,
          put (input (ifc (t1.Agencia='', t1.e,t1.Agencia), 4.),z4.) as Agencia,
          ifc (t1.Conta='',put (t1.f, z15.),t1.Conta) as Conta,
          t1.mci,
          t1.Duracao,
          t1.Transferida,
          t1.Servico,
          t1.Opcoes,
          t1.ag,
          t1.Transacoes,
          t1.Vazio,
          t1.uor,
          input (t1.d, 4.) as prefdep
      FROM todos_0 t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.TODOS_1 AS
   SELECT t1.idGenesys,
          t1.URA,
          t1.ANI,
          t1.DNIS,
          t1.DataChamada,
          t1.HoraChamada,
          t1.Agencia,
          t1.Conta,
          t1.MCI,
          t1.Duracao,
          t1.Transferida,
          t1.Servico,
          t1.Opcoes,
          t1.ag,
          t1.Transacoes,
          t1.Vazio,
          t1.uor,
          CASE  WHEN t1.prefdep<>. THEN put(t1.prefdep, z4.)
            	WHEN t1.prefdep = . THEN PUT(t2.PREFDEP, z4.)
          		WHEN t1.servico IN ('s_telefone,agencianaogerenciado,*,*', 's_telefone,agencianaoidentificado,*,*', 's_telefone,agencianaogerenciado,pj,*') THEN '9940'
          		ELSE substr(t1.Agencia,1,4)
          END AS prefdep,
          ifn (t1.prefdep<>.,1,0) as marca
      FROM WORK.TODOS t1
      LEFT JOIN work.ata_dependencias t2 ON (t1.uor = t2.UOR);
QUIT;


PROC SQL;
   CREATE TABLE WORK.cabb AS
   SELECT t1.idGenesys,
          t1.URA,
          t1.ANI,
          t1.DNIS,
          t1.DataChamada,
          t1.HoraChamada,
          t1.Agencia,
          t1.Conta,
          t1.MCI,
          t1.Duracao,
          t1.Transferida,
          t1.Servico,
          t1.Opcoes,
          t1.Transacoes,
          t1.Vazio
      FROM UNC_ATA.RELATORIO_DETALHADO_&MMAAAA. t1
      WHERE t1.DNIS = 2028 AND t1.DataChamada<=&D1.;
QUIT;


PROC SQL;
   CREATE TABLE WORK.ATA_CHAMADAS_FINAL AS
   SELECT DISTINCT t1.idGenesys,
          t1.URA,
          t1.ANI,
          t1.DNIS,
          t1.DataChamada,
          t1.HoraChamada,
          t1.Agencia,
          t1.Conta,
          t1.MCI,
          t1.Duracao,
          t1.Transferida,
          t1.Servico,
          t1.Opcoes,
          t1.Transacoes,
          t1.Vazio,
          ifc (input (t1.prefdep, 4.)=.,(substr(t1.Opcoes,20,4)),t1.prefdep) as prefdep,
          ifn (t2.idGenesys ne '' and t2.ANI ne '' and t2.DataChamada ne .,1,0) as transbordada,
          t1.marca,
		  t3.PREFIXO,
		  t3.CARTEIRA
      FROM WORK.TODOS_1 t1
        LEFT JOIN WORK.CABB t2 ON (t1.idGenesys = t2.idGenesys AND t1.ANI = t2.ANI AND t1.DataChamada = t2.DataChamada)
		LEFT JOIN WORK.MCI_CTRA t3 ON (t1.MCI = t3.MCI)
	  WHERE t1.prefdep ne '';
QUIT;


PROC SQL;
   CREATE TABLE WORK.CTRA_ATA_BASE AS 
   SELECT t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.GEREV,
		  t1.SUPER,
		  t1.DIRETORIA,
		  t1.DIVAR,
		  COUNT(t2.MCI) AS QTD_CHAMADAS,
		  SUM(t2.transbordada) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CARTEIRAS t1
	  LEFT JOIN WORK.ATA_CHAMADAS_FINAL t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	  GROUP BY t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.GEREV,
		  t1.SUPER,
		  t1.DIRETORIA,
          t1.DIVAR;
QUIT;


PROC STDIZE DATA=WORK.CTRA_ATA_BASE OUT=WORK.CTRA_ATA_BASE REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CTRA_ATA AS 
   SELECT t1.PREFIXO,
		  t1.CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1
	  GROUP BY t1.PREFIXO,
		  t1.CARTEIRA;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DEPE_ATA AS 
   SELECT t1.PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1
	  GROUP BY t1.PREFIXO;
QUIT;


PROC SQL;
   CREATE TABLE WORK.GEREV_ATA AS 
   SELECT t1.GEREV AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1
	  GROUP BY t1.GEREV;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SUPER_ATA AS 
   SELECT t1.SUPER AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1
	  GROUP BY t1.SUPER;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIRETORIA_ATA AS 
   SELECT t1.DIRETORIA AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1
	  GROUP BY t1.DIRETORIA;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIVAR_ATA AS 
   SELECT t1.DIVAR AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1
	  GROUP BY t1.DIVAR;
QUIT;


PROC SQL;
   CREATE TABLE WORK.VP_ATA AS 
   SELECT (8166) AS PREFIXO,
		  (0) AS CARTEIRA,
		  SUM(t1.QTD_CHAMADAS) AS QTD_CHAMADAS,
		  SUM(t1.QTD_CHAMADAS_N_ATENDIDAS) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CTRA_ATA_BASE t1;
QUIT;


PROC SQL;
CREATE TABLE WORK.DEPE_CTRA_ATA AS 
SELECT * FROM WORK.CTRA_ATA
 OUTER UNION CORR 
SELECT * FROM WORK.DEPE_ATA
 OUTER UNION CORR 
SELECT * FROM WORK.GEREV_ATA
 OUTER UNION CORR 
SELECT * FROM WORK.SUPER_ATA
 OUTER UNION CORR 
SELECT * FROM WORK.DIRETORIA_ATA
 OUTER UNION CORR 
SELECT * FROM WORK.DIVAR_ATA
OUTER UNION CORR 
SELECT * FROM WORK.VP_ATA;
Quit;


/*###############*/
/*CONSOLIDADO_CNX*/
/*###############*/


PROC SQL;
	CREATE TABLE WORK.CONSOLIDADO_1_CONEXAO AS 
	SELECT DISTINCT &D1. FORMAT=DateMysql. AS POSICAO,
		   t1.PREFIXO,
		   t1.CARTEIRA,
		   (t3.QTD_CLIENTES) AS FC_CLI_OBJ,
		   (t3.QTD_CLI_USO_FC) AS FC_CLI_RLZ,
		   ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) AS FC_UTILIZACAO,
		   ( IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 2.5, 0, 0, 0) +
		   	 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 2.5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 5.0, 5.0, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 7.5, 10, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 7.5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 10, 15, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 10 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 11, 20, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 11, 25, 0, 0)
		   ) AS FC_UTILIZACAO_PTS,
		   (t4.TEMPO_RETORNO) AS FC_TR,
		   ( IFN(t4.TEMPO_RETORNO >= "2:0:0"t, 0, 0, 0) +
		   	 IFN(t4.TEMPO_RETORNO < "2:0:0"t AND t4.TEMPO_RETORNO >= "1:45:0"t, 5, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:45:0"t AND t4.TEMPO_RETORNO >= "1:30:0"t, 10, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:30:0"t AND t4.TEMPO_RETORNO >= "1:15:0"t, 15, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:15:0"t AND t4.TEMPO_RETORNO >= "1:0:0"t, 20, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:0:0"t, 25, 0, 0)
		   ) AS FC_TR_PTS,
		   (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) AS ATA_ATDT_IMED,
		   ( IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 60, 0, 0, 0) +
		   	 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 60 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 70, 5, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 70 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 80, 10, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 80 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 85, 15, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 85 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 90, 20, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 90 , 25, 0, 0)
		   ) AS ATA_ATDT_IMED_PTS,
		   (t5.TEMPO_RETORNO) AS ATA_TR,
		   ( IFN(t5.TEMPO_RETORNO >= "2:0:0"t, 0, 0, 0) +
		   	 IFN(t5.TEMPO_RETORNO < "2:0:0"t AND t5.TEMPO_RETORNO >= "1:45:0"t, 5, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:45:0"t AND t5.TEMPO_RETORNO >= "1:30:0"t, 10, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:30:0"t AND t5.TEMPO_RETORNO >= "1:15:0"t, 15, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:15:0"t AND t5.TEMPO_RETORNO >= "1:0:0"t, 20, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:0:0"t, 25, 0, 0)
		   ) AS ATA_TR_PTS
	FROM WORK.DEPE_CTRA t1
	LEFT JOIN WORK.DEPE_CTRA_FC t3 ON (t1.PREFIXO = t3.PREFIXO AND t1.CARTEIRA = t3.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_TR_FC t4 ON (t1.PREFIXO = t4.PREFIXO AND t1.CARTEIRA = t4.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_GAT t5 ON (t1.PREFIXO = t5.PREFIXO AND t1.CARTEIRA = t5.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_ATA t6 ON (t1.PREFIXO = t6.PREFIXO AND t1.CARTEIRA = t6.CARTEIRA)
    group by 1,2;
QUIT;


PROC SQL;
   CREATE TABLE CONEXAO_PONDERACAO_1 AS 
   SELECT 

          t1.POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.FC_CLI_OBJ, 
          t1.FC_CLI_RLZ, 

          t1.FC_UTILIZACAO, 
          IFN(t1.FC_UTILIZACAO IS NOT MISSING, 1, 0) AS AUX_FC_UTILIZACAO,
		  IFN(t1.FC_UTILIZACAO IS NOT MISSING, t1.FC_UTILIZACAO_PTS, 0) AS FC_UTILIZACAO_PTS,
  
          t1.FC_TR, 
          IFN(t1.FC_TR IS NOT MISSING, 1, 0) AS AUX_FC_TR,
		  IFN(t1.FC_TR IS NOT MISSING, t1.FC_TR_PTS, 0) AS FC_TR_PTS,
		  
          t1.ATA_ATDT_IMED,           
		  IFN(t1.ATA_ATDT_IMED IS NOT MISSING, 1, 0) AS AUX_ATA_ATDT_IMED,
		  IFN(t1.ATA_ATDT_IMED IS NOT MISSING, t1.ATA_ATDT_IMED_PTS, 0) AS ATA_ATDT_IMED_PTS,
		  
          t1.ATA_TR,           
		  IFN(t1.ATA_TR IS NOT MISSING, 1, 0) AS AUX_ATA_TR,
		  IFN(t1.ATA_TR IS NOT MISSING, t1.ATA_TR_PTS, 0) AS ATA_TR_PTS
		  		  
      FROM CONSOLIDADO_1_CONEXAO t1
      WHERE PREFIXO <> 0;

QUIT;


PROC SQL;
   CREATE TABLE CONEXAO_PONDERACAO_2 AS 
   SELECT 

          t1.POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.FC_CLI_OBJ, 
          t1.FC_CLI_RLZ, 

          t1.FC_UTILIZACAO, 
          t1.FC_UTILIZACAO_PTS,
  
          t1.FC_TR, 
          t1.FC_TR_PTS,
		  
          t1.ATA_ATDT_IMED,           
		  t1.ATA_ATDT_IMED_PTS,
		  
          t1.ATA_TR,           
		  t1.ATA_TR_PTS,
		  (AUX_FC_UTILIZACAO + AUX_FC_TR + AUX_ATA_ATDT_IMED + AUX_ATA_TR) AS AUX

		  		  
      FROM CONEXAO_PONDERACAO_1 t1
      ;

QUIT;


PROC SQL;
   CREATE TABLE CONSOLIDADO_CONEXAO AS 
   SELECT 

          t1.POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.FC_CLI_OBJ, 
          t1.FC_CLI_RLZ, 

          t1.FC_UTILIZACAO, 
          IFN(t1.FC_UTILIZACAO IS NOT MISSING, (t1.FC_UTILIZACAO_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS FC_UTILIZACAO_PTS,
  
          t1.FC_TR, 
		  IFN(t1.FC_TR IS NOT MISSING, (t1.FC_TR_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS FC_TR_PTS,
          		  
          t1.ATA_ATDT_IMED,
          IFN(t1.ATA_ATDT_IMED IS NOT MISSING, (t1.ATA_ATDT_IMED_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS ATA_ATDT_IMED_PTS, 
		  		  
          t1.ATA_TR,
          IFN(t1.ATA_TR IS NOT MISSING, (t1.ATA_TR_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS ATA_TR_PTS,
		  t1.AUX,

          (IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 80 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 99.99, 1000, 0, 0) 
          + IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 100, 1500, 0, 0))  AS PTS_CONEXAO 
          		  		  
      FROM CONEXAO_PONDERACAO_2 t1
      ;

QUIT;


/*WORK.CONSOLIDADO_CNX*/


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_CNX AS 
SELECT POSICAO, PREFIXO as PREFDEP, CARTEIRA, &ANOMES. AS ANOMES, INPUT(t2.TD_SINERGIA, d4.) AS TipDepCnx,

IFN(t1.AUX = 0, 0, fc_utilizacao_pts + fc_tr_pts + ata_atdt_imed_pts + ata_tr_pts) AS REALIZADO FORMAT 17.2

FROM CONSOLIDADO_CONEXAO t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON PREFIXO = INPUT(t2.PREFDEP, d4.);
QUIT;


data WORK.CONSOLIDADO_CNX;
format POSICAO yymmdd10.;
set WORK.CONSOLIDADO_CNX;
POSICAO = &D1;
run;


PROC STDIZE DATA=WORK.CONSOLIDADO_CNX OUT=WORK.CONSOLIDADO_CNX REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;

CREATE TABLE CONSOLIDADO_CNX_ULT AS SELECT  

t1.POSICAO, t1.PREFDEP, IFN(t1.Carteira = 0 AND t1.TipDepCnx = 2, 7002, t1.Carteira) AS Carteira, t1.ANOMES, 
IFN(CALCULATED Carteira = 0, t1.TipDepCnx, 1) AS TipDepCnx, t1.REALIZADO

FROM  WORK.CONSOLIDADO_CNX t1;
QUIT;


/*PARA O CONEXÃO*/
/*PARA O CONEXÃO*/
/*PARA O CONEXÃO*/
/*PARA O CONEXÃO*/

/*SUBINDO PARA O CONEXAO*/ 


PROC SQL;
    CREATE TABLE CONEXAO AS
        SELECT
            '2000153'
            ||"&Tx_Fon"
            ||REPEAT(' ',45)
            ||COMPRESS(PUT(t1.PrefDep,Z4.))
            ||COMPRESS(PUT(t1.Carteira,Z5.))
            ||"&ANOMES"
            ||put(t1.TipDepCnx,z4.)
            ||'+'
            ||PUT(ABS(t1.REALIZADO)*100,z13.)
            ||'F7176219'
            ||COMPRESS(PUT(Today(), ddmmyy10.))
            ||'N' AS L
        FROM WORK.CONSOLIDADO_CNX_ULT t1       
;QUIT;


%GerarBBM(TabelaSAS=CONEXAO, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=M6062);


/*SUBINDO PARA O CONEXAO - FIM*/

x chmod 2777 *;


/********************************************/
/********************************************/
/********************************************/
/********************************************/
/********************************************/


/*###############*/
/*CONSOLIDADO_rel*/
/*###############*/


PROC SQL;
	CREATE TABLE WORK.CONSOLIDADO_1 AS 
	SELECT DISTINCT &D1. FORMAT=DateMysql. AS POSICAO,
		   t1.PREFIXO,
		   t1.CARTEIRA,
		   (t3.QTD_CLIENTES) AS FC_CLI_OBJ,
		   (t3.QTD_CLI_USO_FC) AS FC_CLI_RLZ,
		   ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) AS FC_UTILIZACAO,

		   ( IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 2.5, 0, 0, 0) +
		   	 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 2.5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 5.0, 5.0, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 7.5, 10, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 7.5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 10, 15, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 10 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 11, 20, 0, 0) +
			 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 11, 25, 0, 0)
		   ) AS FC_UTILIZACAO_PTS,

		   (t4.TEMPO_RETORNO) AS FC_TR,
		   ( IFN(t4.TEMPO_RETORNO >= "2:0:0"t, 0, 0, 0) +
		   	 IFN(t4.TEMPO_RETORNO < "2:0:0"t AND t4.TEMPO_RETORNO >= "1:45:0"t, 5, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:45:0"t AND t4.TEMPO_RETORNO >= "1:30:0"t, 10, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:30:0"t AND t4.TEMPO_RETORNO >= "1:15:0"t, 15, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:15:0"t AND t4.TEMPO_RETORNO >= "1:0:0"t, 20, 0, 0) +
			 IFN(t4.TEMPO_RETORNO < "1:0:0"t, 25, 0, 0)
		   ) AS FC_TR_PTS,
		   (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) AS ATA_ATDT_IMED,
		   ( IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 60, 0, 0, 0) +
		   	 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 60 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 70, 5, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 70 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 80, 10, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 80 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 85, 15, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 85 AND (((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) <= 90, 20, 0, 0) +
			 IFN((((t6.QTD_CHAMADAS - t6.QTD_CHAMADAS_N_ATENDIDAS) / t6.QTD_CHAMADAS)*100) > 90 , 25, 0, 0)
		   ) AS ATA_ATDT_IMED_PTS,
		   (t5.TEMPO_RETORNO) AS ATA_TR,
		   ( IFN(t5.TEMPO_RETORNO >= "2:0:0"t, 0, 0, 0) +
		   	 IFN(t5.TEMPO_RETORNO < "2:0:0"t AND t5.TEMPO_RETORNO >= "1:45:0"t, 5, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:45:0"t AND t5.TEMPO_RETORNO >= "1:30:0"t, 10, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:30:0"t AND t5.TEMPO_RETORNO >= "1:15:0"t, 15, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:15:0"t AND t5.TEMPO_RETORNO >= "1:0:0"t, 20, 0, 0) +
			 IFN(t5.TEMPO_RETORNO < "1:0:0"t, 25, 0, 0)
		   ) AS ATA_TR_PTS
	FROM WORK.DEPE_CTRA t1
	LEFT JOIN WORK.DEPE_CTRA_FC t3 ON (t1.PREFIXO = t3.PREFIXO AND t1.CARTEIRA = t3.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_TR_FC t4 ON (t1.PREFIXO = t4.PREFIXO AND t1.CARTEIRA = t4.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_GAT t5 ON (t1.PREFIXO = t5.PREFIXO AND t1.CARTEIRA = t5.CARTEIRA)
	LEFT JOIN WORK.DEPE_CTRA_ATA t6 ON (t1.PREFIXO = t6.PREFIXO AND t1.CARTEIRA = t6.CARTEIRA);
QUIT;



PROC SQL;
   CREATE TABLE CONEXAO_PONDERACAO_1_REL AS 
   SELECT 

          t1.POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.FC_CLI_OBJ, 
          t1.FC_CLI_RLZ, 

          t1.FC_UTILIZACAO, 
          IFN(t1.FC_UTILIZACAO IS NOT MISSING, 1, 0) AS AUX_FC_UTILIZACAO,
		  IFN(t1.FC_UTILIZACAO IS NOT MISSING, t1.FC_UTILIZACAO_PTS, 0) AS FC_UTILIZACAO_PTS,
  
          t1.FC_TR, 
          IFN(t1.FC_TR IS NOT MISSING, 1, 0) AS AUX_FC_TR,
		  IFN(t1.FC_TR IS NOT MISSING, t1.FC_TR_PTS, 0) AS FC_TR_PTS,
		  
          t1.ATA_ATDT_IMED,           
		  IFN(t1.ATA_ATDT_IMED IS NOT MISSING, 1, 0) AS AUX_ATA_ATDT_IMED,
		  IFN(t1.ATA_ATDT_IMED IS NOT MISSING, t1.ATA_ATDT_IMED_PTS, 0) AS ATA_ATDT_IMED_PTS,
		  
          t1.ATA_TR,           
		  IFN(t1.ATA_TR IS NOT MISSING, 1, 0) AS AUX_ATA_TR,
		  IFN(t1.ATA_TR IS NOT MISSING, t1.ATA_TR_PTS, 0) AS ATA_TR_PTS
		  		  
      FROM CONSOLIDADO_1 t1
      WHERE PREFIXO <> 0;

QUIT;


PROC SQL;
   CREATE TABLE CONEXAO_PONDERACAO_2_REL AS 
   SELECT 

          t1.POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.FC_CLI_OBJ, 
          t1.FC_CLI_RLZ, 

          t1.FC_UTILIZACAO, 
          t1.FC_UTILIZACAO_PTS,
  
          t1.FC_TR, 
          t1.FC_TR_PTS,
		  
          t1.ATA_ATDT_IMED,           
		  t1.ATA_ATDT_IMED_PTS,
		  
          t1.ATA_TR,           
		  t1.ATA_TR_PTS,
		  (AUX_FC_UTILIZACAO + AUX_FC_TR + AUX_ATA_ATDT_IMED + AUX_ATA_TR) AS AUX

		  		  
      FROM CONEXAO_PONDERACAO_1_REL t1
      ;

QUIT;


PROC SQL;
   CREATE TABLE CONSOLIDADO AS 
   SELECT 

          t1.POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.FC_CLI_OBJ, 
          t1.FC_CLI_RLZ, 

          t1.FC_UTILIZACAO, 
          IFN(t1.FC_UTILIZACAO IS NOT MISSING, (t1.FC_UTILIZACAO_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS FC_UTILIZACAO_PTS,
  
          t1.FC_TR, 
		  IFN(t1.FC_TR IS NOT MISSING, (t1.FC_TR_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS FC_TR_PTS,
          		  
          t1.ATA_ATDT_IMED,
          IFN(t1.ATA_ATDT_IMED IS NOT MISSING, (t1.ATA_ATDT_IMED_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS ATA_ATDT_IMED_PTS, 
		  		  
          t1.ATA_TR,
          IFN(t1.ATA_TR IS NOT MISSING, (t1.ATA_TR_PTS*4)/t1.AUX, 0) FORMAT 32.2 AS ATA_TR_PTS,
		  t1.AUX,

          		  	
			(IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 80 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 99.99, 1000, 0, 0) 
          + IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 100, 1500, 0, 0))  AS PTS_CONEXAO
     
          		  		  
      FROM CONEXAO_PONDERACAO_2_REL t1
      ;

QUIT;


/***/
/***/


PROC STDIZE OUT=WORK.CONSOLIDADO REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


DATA CONSOLIDADO;
SET CONSOLIDADO;
ORCADO = 80;
RUN;


/*PARA O RELATÓRIO*/


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_REL AS 
SELECT POSICAO, prefixo as PREFDEP, CARTEIRA as CTRA, FC_CLI_OBJ, FC_CLI_RLZ, FC_UTILIZACAO_PTS, FC_TR, FC_TR_PTS, ATA_ATDT_IMED, ATA_ATDT_IMED_PTS, 
ATA_TR, ATA_TR_PTS, ORCADO, IFN(t1.AUX = 0, 0, fc_utilizacao_pts + fc_tr_pts + ata_atdt_imed_pts + ata_tr_pts) AS REALIZADO FORMAT 17.2
FROM  WORK.CONSOLIDADO T1;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_REL AS 
SELECT POSICAO, PREFDEP, CTRA, FC_CLI_OBJ, FC_CLI_RLZ, FC_UTILIZACAO_PTS, FC_TR, FC_TR_PTS, ATA_ATDT_IMED, ATA_ATDT_IMED_PTS, 
ATA_TR, ATA_TR_PTS, ORCADO, REALIZADO, (REALIZADO/ORCADO)*100 as POR_ATG
FROM  WORK.CONSOLIDADO_REL;
QUIT;


data WORK.CONSOLIDADO_REL;
format POSICAO yymmdd10.;
set WORK.CONSOLIDADO_REL;
POSICAO = &D1;
run;


PROC STDIZE OUT=WORK.CONSOLIDADO_REL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


/*Relatório 420 - Piloto*/
/************** INICIAR PROCESSO ***************/
%LET Usuario=f7176219;
%LET Keypass=p91WlbrVLhMS6nD0xuBvsJeuRhaYv7SthinqocltJxnO3k1ppr;
%LET Rotina=rel-tempo-resposta-unv;
%ProcessoIniciar();
/***********************************************/

/*Relatório 420 - Piloto*/
/*#################################################################################################################*/


/*TABELA AUXILIAR DE TABELAS DE CARGA E ROTINAS DO SISTEMA REL*/
PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('WORK.CONSOLIDADO_REL', 'rel-tempo-resposta-unv');
QUIT;


%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);


x chmod 2777 *;
