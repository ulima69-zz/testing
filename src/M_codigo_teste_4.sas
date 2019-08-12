
/*novembro*/

%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

/*HEADER*/

%LET Tx_Fon=6062;

%CONECTARDB2(MIV);
%CONECTARDB2(REL);

/*LIBNAME REL DB2 DATABASE=BDB2P04 SCHEMA=DB2REL AUTHDOMAIN=DB2SGCEN;
LIBNAME MIV DB2 DATABASE=BDB2P04 SCHEMA=DB2MIV AUTHDOMAIN=DB2SGCEN;*/

LIBNAME ATB DB2 DATABASE=BDB2P04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SGCEN;


libname unc_ata "/dados/externo/UNC/ATA";
libname unc_gat "/dados/externo/UNC/GAT/TELEFONE";
libname auxiliar '/dados/infor/producao/tempo_resposta';


DATA _NULL_;
	DATA_INICIO = '01Jan2017'd;
	DATA_FIM = '30Dec2018'd;
    DATA_HOJE = TODAY();
	D1 = diaUtilAnterior(TODAY());
	D2 = diaUtilAnterior(D1);
	D3 = diaUtilAnterior(D2);
	MES_ATU = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));
	MES_ANT = Put(INTNX('month',primeiroDiaUtilMes(D1),-1), yymmn6.) ;
	MES_G = Put(DATA_REFERENCIA, MONTH.);
	ANOMES = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));
	DT_INICIO_SQL="'"||put(DATA_INICIO, YYMMDDD10.)||"'";
	DT_D1_SQL="'"||put(D1, YYMMDDD10.)||"'";
	DT_1DIA_MES_SQL="'"||put(primeiroDiaUtilMes(D1), YYMMDDD10.)||"'";
	DT_ANOMES_SQL=primeiroDiaUtilMes(D1);
	PRIMEIRO_DIA_MES_SQL="'"||put(primeiroDiaMes(DATA_REFERENCIA), YYMMDDD10.)||"'";
    MMAAAA=PUT(D1,mmyyn6.);
	MES_G_2 = Put(MONTH (DATA_REFERENCIA), Z2.);
	AAAAMM=PUT(D1,yymmn6.);

    QNT_DIAS_UTEIS_PASSADO= diasUteisEntreDatas(primeiroDiaMes(TODAY()), TODAY()) - 1;
    QNT_DIAS_UTEIS_MES=diasUteisEntreDatas(primeiroDiaMes(TODAY()), ultimoDiaMes(TODAY()));
	DIA_UTIL_ANTERIOR = DAY(TODAY()) - 1;

	CALL SYMPUT('DATA_INICIO',COMPRESS(DATA_INICIO,' '));
	CALL SYMPUT('DATA_FIM',COMPRESS(DATA_FIM,' '));
	CALL SYMPUT('DATA_HOJE',COMPRESS(TODAY(),' '));
	CALL SYMPUT('D1',COMPRESS(D1,' '));
	CALL SYMPUT('D2',COMPRESS(D2,' '));
	CALL SYMPUT('D3',COMPRESS(D3,' '));
	CALL SYMPUT('MES_ATU',COMPRESS(MES_ATU,' '));
	CALL SYMPUT('MES_ANT',COMPRESS(MES_ANT,' '));
    CALL SYMPUT('MES_G', COMPRESS(MES_G,' '));
	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));
	CALL SYMPUT('DT_INICIO_SQL', COMPRESS(DT_INICIO_SQL,' '));
	CALL SYMPUT('DT_D1_SQL', COMPRESS(DT_D1_SQL,' '));
	CALL SYMPUT('DT_1DIA_MES_SQL', COMPRESS(DT_1DIA_MES_SQL,' '));
	CALL SYMPUT('DT_ANOMES_SQL', COMPRESS(DT_ANOMES_SQL,' '));
	CALL SYMPUT('PRIMEIRO_DIA_MES_SQL', COMPRESS(PRIMEIRO_DIA_MES_SQL,' '));
	CALL SYMPUT('MMAAAA', COMPRESS(MMAAAA,' '));
    CALL SYMPUT('MES_G_2', COMPRESS(MES_G_2,' '));
	CALL SYMPUT('AAAAMM', COMPRESS(AAAAMM,' '));

	CALL SYMPUT('QNT_DIAS_UTEIS_PASSADO',COMPRESS(QNT_DIAS_UTEIS_PASSADO,' '));
	CALL SYMPUT('QNT_DIAS_UTEIS_MES',COMPRESS(QNT_DIAS_UTEIS_MES,' '));
	CALL SYMPUT('DIA_UTIL_ANTERIOR',COMPRESS(DIA_UTIL_ANTERIOR,' '));

RUN;


/*HEADER FIM*/


/*Variaveis*/


%LET dia_referencia = &DIA_UTIL_ANTERIOR;
%PUT &dia_referencia;


/*#############*/
/*PROCESSAMENTO*/
/*#############*/


PROC SQL;
   CREATE TABLE WORK.nova_dependencias AS SELECT 
   INPUT(PrefDep, d4.) as prefixo, 
   INPUT(SB, d2.) as cod_subordinada,
   INPUT(TipoDep, d3.) as tipo_dependencia,
   Status as status_dependencia,
   Inauguracao as data_inauguracao,  
   INPUT(UOR, d9.) as cod_UOR,
   INPUT(PrefSureg, d4.) as gerev,
   INPUT(PrefSuper, d4.) as super,
   INPUT(PrefDir, d4.) as diretoria_jurisdicionante, 
   INPUT(PrefVice, d4.) as vice_presidencia,
   INPUT(GrupoFixo, d4.) as cod_agrupamento_fixo
   FROM IGR.DEPENDENCIAS_201811
   where SB = "00"; 
QUIT;


PROC SQL;
   CREATE TABLE WORK.CARTEIRAS AS SELECT
          distinct t1.cd_cli,

          t1.CD_PRF_DEPE AS PREFIXO, 
          t1.NR_SEQL_CTRA AS CARTEIRA, 
          t1.CD_TIP_CTRA AS TIPO_CARTEIRA,
		  /*t1.NR_MTC_ADM_CTRA AS MTR_GERENTE,*/
		  /*t1.QT_CLI_CTRA AS QTD_CLIENTES,*/
          t2.cod_UOR AS UOR, 
          t2.tipo_dependencia,
		  t2.cod_agrupamento_fixo,
		  t2.super as SUPER,
		  t2.gerev AS GEREV,
          t2.diretoria_jurisdicionante AS DIRETORIA
      FROM WORK.nova_dependencias t2
           INNER JOIN COMUM.PAI_REL_PJ_201811 t1 ON (t2.prefixo = t1.CD_PRF_DEPE)
      WHERE t2.tipo_dependencia IN  
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


PROC STDIZE OUT=WORK.CARTEIRAS REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;



PROC SQL;

   CREATE TABLE WORK.CARTEIRAS AS SELECT
          
          distinct t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.TIPO_CARTEIRA,
		  /*t1.NR_MTC_ADM_CTRA AS MTR_GERENTE,*/
		  count( t1.cd_cli) AS QTD_CLIENTES,
          t1.UOR, 
          t1.tipo_dependencia,
		  t1.cod_agrupamento_fixo,
		  t1.SUPER,
		  t1.GEREV,
          t1.DIRETORIA

      FROM WORK.CARTEIRAS t1
      group by 1, 2;

QUIT;


PROC SQL;
   CREATE TABLE WORK.DEPENDENCIAS_DEPE AS 
   SELECT t1.prefixo, 
          t1.cod_UOR,
		  t1.super,
		  t1.GEREV,
		  t1.diretoria_jurisdicionante
      FROM WORK.nova_dependencias t1
      WHERE t1.status_dependencia = 'A' AND t1.cod_agrupamento_fixo IN(877, 872, 908, 610, 613, 616) 
			AND t1.data_inauguracao NOT = '31Dec9999'd AND t1.tipo_dependencia IN (13, 15, 35)
			AND t1.PREFIXO NOT IN (7058, 5812);
QUIT;


PROC SQL;
   CREATE TABLE WORK.SUPERINTENDENCIAS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM WORK.nova_dependencias t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia = 4 AND t1.vice_presidencia = 8166)
		AND t1.prefixo NOT IN (8481, 9300, 9009); 
QUIT;


PROC SQL;
   CREATE TABLE WORK.GEREVS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM WORK.nova_dependencias t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia = 3 AND t1.vice_presidencia = 8166 
            AND t1.prefixo IN (SELECT DISTINCT gerev FROM CARTEIRAS)
			AND t1.prefixo NOT = 3903); 
QUIT;


PROC SQL;
   CREATE TABLE WORK.DIRETORIAS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM WORK.nova_dependencias t1
      WHERE (t1.status_dependencia = 'A' AND t1.tipo_dependencia IN (2) AND t1.prefixo IN (8477, 8592, 9500));
QUIT;


PROC SQL;
   CREATE TABLE WORK.VPS AS 
   SELECT t1.prefixo, 
          t1.cod_UOR
      FROM WORK.nova_dependencias t1
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


PROC SQL;
   CREATE TABLE WORK.CTRA_CLI_FC AS 
   SELECT DISTINCT t2.CD_PRF_DEPE AS PREFIXO, 
          t2.NR_SEQL_CTRA AS CARTEIRA,
		  t2.CD_CLI
      FROM DB2MIV.TX_MSG_EXPS_PJ t1
           INNER JOIN COMUM.PAI_REL_PJ_201811 t2 ON (t1.CD_CLI_MSG_EXPS = t2.CD_CLI)
      WHERE DATEPART(t1.TS_CRIC_MSG) >= MDY(11,1,2018) AND t1.NR_MTC_RPRT_CTRA = 0 
AND DATEPART(t1.TS_CRIC_MSG) <= '30NOV2018'd;
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
		   t1.QTD_CLIENTES,
		   t2.QTD_CLI_USO_FC
	FROM WORK.CARTEIRAS t1
	LEFT JOIN WORK.CTRA_QTD_CLI_FC t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	WHERE t1.cod_agrupamento_fixo IN (877, 872, 908, 610, 613, 616);	
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
SELECT * FROM WORK.VIVAP_FC;
Quit;


/*###########################*/
/*FALE COM - TEMPO DE RETORNO*/
/*###########################*/


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_TX_MSG_EXPS AS 
   SELECT DISTINCT t1.CD_CLI_MSG_EXPS AS mci, 
          (datepart(t1.TS_CRIC_MSG)) FORMAT=ddmmyy10. LABEL="data" AS data, 
          (timepart(t1.TS_CRIC_MSG)) FORMAT=time8. LABEL="hora" AS hora, 
          t1.TS_CRIC_MSG AS timestamp, 
          t1.NR_MTC_RPRT_CTRA AS responsavel, 
          t1.DT_LET_MSG FORMAT=ddmmyy10. AS data_leitr, 
          t1.HR_LET_MSG AS hora_leitr, 
          t1.CD_SNLC_MSG, 
          t1.TX_MSG,
		  t2.CD_PRF_DEPE AS PREFIXO,
		  t2.NR_SEQL_CTRA AS CARTEIRA
      FROM DB2MIV.TX_MSG_EXPS_PJ t1
	  INNER JOIN COMUM.PAI_REL_PJ_201811 t2 ON (t1.CD_CLI_MSG_EXPS = t2.CD_CLI)
	  WHERE DATEPART(t1.TS_CRIC_MSG) >= MDY(11,1,2018) AND  DATEPART(t1.TS_CRIC_MSG) <= '30NOV2018'd
      ORDER BY t1.CD_CLI_MSG_EXPS;
QUIT;


PROC SQL;
   CREATE TABLE WORK.INTERACAO_CLIENTE AS 
   SELECT DISTINCT t2.PREFIXO, t2.CARTEIRA, t2.mci, 
          t2.data, 
          (MIN(t2.hora)) FORMAT=TIME8. AS hora_cliente, 
          t2.responsavel
      FROM WORK.QUERY_FOR_TX_MSG_EXPS t2
      WHERE t2.responsavel = 0
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
      WHERE t2.responsavel NOT = 0;
QUIT;


PROC SQL;
   CREATE TABLE WORK.FALE_COM_1 AS 
   SELECT DISTINCT t1.PREFIXO, t1.CARTEIRA, t1.mci, 
          t1.data, 
          t1.hora_cliente, 
          t2.hora LABEL='' AS hora_BB, 
          t1.responsavel, 
          (IFN(t2.hora IS MISSING, ('18:0:0't - t1.hora_cliente), IFN(t2.hora LT t1.hora_cliente, ('18:0:0't - 
            t1.hora_cliente), (t2.hora - t1.hora_cliente)))) FORMAT=TIME8. LABEL="tempo_start_2" AS tempo_start, 
          (WEEKDAY(t1.data)) AS dia_semana,
		  day(t1.data) as dia_mes,
		  t3.uf,

		  IFN((t3.UF = "SP" and day(t1.data) = 20 and t1.PREFIXO in (37, 79, 171, 199, 290, 306, 320, 348, 511, 943, 1510, 1791, 2502, 2513, 
          3062, 3369, 3568, 6615, 7652, 9794, 9796))
          ,1,IFN((t3.UF = "DF" and day(t1.data) = 30),1,0)) as indicador


      FROM WORK.INTERACAO_CLIENTE t1
      LEFT JOIN WORK.INTERACAO_BB t2 ON (t1.mci = t2.mci) AND (t1.data = t2.data)
	  left join IGR.DEPENDENCIAS_201811 t3 on (t1.prefixo = INPUT(t3.PrefDep, d4.))
      WHERE t1.hora_cliente BETWEEN '8:0:0't AND '18:0:0't AND WEEKDAY(t1.data) IN(2, 3, 4, 5, 6);
QUIT;


PROC SQL;
   CREATE TABLE WORK.FALE_COM AS 
   SELECT DISTINCT t1.PREFIXO, t1.CARTEIRA, t1.mci, 
          t1.data, 
          t1.hora_cliente, 
          t1.hora_BB, 
          t1.responsavel, 
          t1.dia_semana,
		  t1.dia_mes,
		  t1.tempo_start
	  FROM  WORK.FALE_COM_1 t1
      WHERE indicador = 0;
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
		   t2.tempo_start AS TEMPO_RETORNO
	FROM WORK.CARTEIRAS t1
	LEFT JOIN WORK.CLI_TR_FC t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA);	
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
SELECT * FROM WORK.VIVAP_TR_FC;
Quit;


/*###*/
/*ATA*/
/*###*/


%ls(dados/externo/UNC/ATA, out=work.teste);


data work.out_ls(drop=aa mm);
    set work.teste;
    where pasta eq './' and substr(arquivo,1,19) in ('relatorio_detalhado');
    TABELA_ATA = scan(arquivo,1,'.');
    aa=substr((scan(TABELA_ATA,-1,'_')),3,4);
    mm=substr((scan(TABELA_ATA,-1,'_')),1,2);
    dt_ref = input(compress(aa||mm), 6.);
run;


proc sql noprint;
    select TABELA_ATA into: TABELA_ATA
    from work.out_ls
    order by dt_ref desc;
quit;


%put &TABELA_ATA;


%ls(/dados/externo/UNC/GAT/TELEFONE, out=work.teste1);


data work.out_ls1;
    set work.teste1;
    where pasta eq './' and substr(arquivo,1,3) in ('tel');
    TABELA_GAT = scan(arquivo,1,'.');
    dt_ref1 = input(scan(TABELA_GAT,-1,'l'),6.);
run;


proc sql ;
    select TABELA_GAT into: TABELA_GAT
    from work.out_ls1
    where dt_ref1 = (select max(dt_ref1) from work.out_ls1)     ;
quit;


%put &TABELA_GAT;


/*##voltar aqui#*/

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
      FROM UNC_ATA.relatorio_detalhado_112018 t1
      where t1.DataChamada<='30NOV2018'd; 
QUIT;


PROC SQL;
	CREATE TABLE WORK.MCI_CTRA AS 
	SELECT t1.CD_PRF_DEPE AS PREFIXO,
		   t1.NR_SEQL_CTRA AS CARTEIRA,
		   t2.CD_TIP_CTRA AS TIPO_CARTEIRA,
		   t1.CD_CLI AS MCI
	FROM COMUM.PAI_REL_PJ_201811 t1
	INNER JOIN DB2REL.CTRA_CLI t2 ON (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE AND t1.NR_SEQL_CTRA = t2.NR_SEQL_CTRA)
	WHERE t2.CD_TIP_CTRA IN (303, 315, 321, 322, 328);
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
      FROM UNC_GAT.tel201811 t1
	  INNER JOIN WORK.MCI_CTRA t2 ON (t1.MCI = t2.MCI)
	  WHERE t1.statusAtend = 40	AND t1.horaSolicitacaoAtend BETWEEN "8:0:0"t AND "18:0:0"t AND t1.dataFimAtend<='30NOV2018'd;
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
   		  IFN(t1.qtd_dias_uteis = 1 AND (t1.horaInicioAtend - t1.horaSolicitacaoAtend) <= "0:5:0"t, 1, 0, 0) AS ATD_IMEDIATO,
		  (
			IFN(t1.qtd_dias_uteis > 2, (t1.qtd_dias_uteis - 2)* "10:0:0"t, 0, 0) +
			IFN(t1.qtd_dias_uteis >= 2, ("18:0:0"t - t1.horaSolicitacaoAtend) + (t1.horaInicioAtend - "8:0:0"t), 0, 0) +
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
		  COUNT(t2.MCI) AS QTD_CHAMADAS,
		  SUM(t2.ATD_IMEDIATO) AS QTD_CHAMADAS_IMED,
		  AVG(t2.TEMPO_RETORNO_GAT) FORMAT=TIME8. AS TEMPO_RETORNO
      FROM WORK.CARTEIRAS t1
	  LEFT JOIN WORK.MCI_GAT t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	  GROUP BY t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.GEREV,
		  t1.SUPER,
		  t1.DIRETORIA;
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
SELECT * FROM WORK.VP_GAT;
Quit;


/* ATA QTD ATENDIMENTOS */


PROC SQL;
   CREATE TABLE WORK.ATA_DEPENDENCIAS AS 
   SELECT t1.prefixo AS prefdep, 
          t1.cod_subordinada AS sb, 
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
      FROM UNC_ATA.relatorio_detalhado_112018 t1
      WHERE t1.DNIS = 2009 
and t1.Servico in ("s_telefone,agenciagerenciado,estilo_digital_unv,", "s_anp,atendimentoPF,exclusivo,*", "s_telefone,agencianaogerenciado,pj,*","s_telefone,atendimentopj,pj,*","s_telefone,pj,governo,*","s_telefone,pj,pj,*","s_telefone,agenciagerenciado,*,*","s_telefone,agenciagerenciado, ,*","s_telefone,agenciagerenciado,estilo_digital,*")
and t1.Transferida = 't' AND t1.DataChamada<='30NOV2018'd;
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
            	WHEN t1.prefdep = . AND t2.SB = 0 THEN PUT(t2.PREFDEP, z4.)
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
      FROM UNC_ATA.RELATORIO_DETALHADO_112018 t1
      WHERE t1.DNIS = 2028 AND t1.DataChamada<='30NOV2018'd;
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
		  COUNT(t2.MCI) AS QTD_CHAMADAS,
		  SUM(t2.transbordada) AS QTD_CHAMADAS_N_ATENDIDAS
      FROM WORK.CARTEIRAS t1
	  LEFT JOIN WORK.ATA_CHAMADAS_FINAL t2 ON (t1.PREFIXO = t2.PREFIXO AND t1.CARTEIRA = t2.CARTEIRA)
	  GROUP BY t1.PREFIXO,
		  t1.CARTEIRA,
		  t1.GEREV,
		  t1.SUPER,
		  t1.DIRETORIA;
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
SELECT * FROM WORK.VP_ATA;
Quit;



/*###############*/
/*CONSOLIDADO_CNX*/
/*###############*/


PROC SQL;
	CREATE TABLE WORK.CONSOLIDADO_1_CONEXAO AS 
	SELECT DISTINCT '30NOV2018'd FORMAT=DateMysql. AS POSICAO,
		   t1.PREFIXO,
		   t1.CARTEIRA,
		   (t3.QTD_CLIENTES) AS FC_CLI_OBJ,
		   (t3.QTD_CLI_USO_FC) AS FC_CLI_RLZ,
		   ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) AS FC_UTILIZACAO,
		   ( IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 2.5, 0, 0, 0) +
		   	 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 2.5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 5, 5, 0, 0) +
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
   CREATE TABLE WORK.CONSOLIDADO_CONEXAO AS 
   SELECT t1.POSICAO, 
          t1.prefixo, 
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
		  (
		  	IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) > 0 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 5.99, 50, 0, 0) + 
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 6 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 10.99, 115, 0, 0) +
		    IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 11 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 15.99, 180, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 16 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 20.99, 245, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 21 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 25.99, 310, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 26 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 30.99, 375, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 31 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 35.99, 440, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 36 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 40.99, 505, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 41 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 45.99, 570, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 46 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 50.99, 635, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 51 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 55.99, 700, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 56 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 60.99, 765, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 61 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 65.99, 830, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 66 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 70.99, 895, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 71 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 75.99, 960, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 76 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 80.99, 1000, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 81 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 85.99, 1125, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 86 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 90.99, 1250, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 91 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 95.99, 1375, 0, 0) +
		    IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 96, 1500, 0, 0)
		  ) AS PTS_CONEXAO
      FROM WORK.CONSOLIDADO_1_CONEXAO t1;
QUIT;


/*WORK.CONSOLIDADO_CNX*/


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_CNX AS SELECT *
FROM WORK.CONSOLIDADO_CONEXAO t1
WHERE t1.CARTEIRA <> 0;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_CNX AS 
SELECT POSICAO, prefixo as PREFDEP, CARTEIRA as CTRA, fc_utilizacao_pts, fc_tr_pts, ata_atdt_imed_pts, ata_tr_pts
FROM WORK.CONSOLIDADO_CNX;
QUIT;


PROC STDIZE DATA=WORK.CONSOLIDADO_CNX OUT=WORK.CONSOLIDADO_CNX REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
DROP TABLE COLUNAS_SUMARIZAR;
CREATE TABLE COLUNAS_SUMARIZAR (Coluna CHAR(50), Tipo CHAR(10));
INSERT INTO COLUNAS_SUMARIZAR VALUES ('fc_utilizacao_pts', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('fc_tr_pts', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('ata_atdt_imed_pts', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('ata_tr_pts', 'SUM');
QUIT;


/*FUNCAO DE SUMARIZACAO*/ 

%SumarizadorCNX( TblSASValores=CONSOLIDADO_CNX,  TblSASColunas=COLUNAS_SUMARIZAR,  NivelCTRA=1,  PAA_PARA_AGENCIA=0,  TblSaida=CONSOLIDADO_CNX, AAAAMM=201811); 
 

PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_CNX AS 
SELECT POSICAO, PREFDEP, CTRA as Carteira, 201811 AS ANOMES, TP_CNX_AVL as TipDepCnx
FROM  WORK.CONSOLIDADO_CNX;
QUIT;


/*TRAZENDO O REALIZADO*/ 
PROC SQL;
CREATE TABLE WORK.REALIZADO_CNX AS SELECT prefixo as PREFDEP, carteira, (fc_utilizacao_pts + fc_tr_pts + ata_atdt_imed_pts + ata_tr_pts) AS REALIZADO FORMAT 17.2
FROM WORK.CONSOLIDADO_CONEXAO;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_CNX AS 
SELECT t1.POSICAO, t1.PREFDEP, t1.Carteira, t1.ANOMES, t1.TipDepCnx, t2.REALIZADO
FROM WORK.REALIZADO_CNX t2 
LEFT JOIN WORK.CONSOLIDADO_CNX t1
ON t1.PREFDEP=t2.PREFDEP and t1.Carteira=t2.Carteira;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_CNX AS SELECT  t1.POSICAO, t1.PREFDEP, t1.Carteira, t1.ANOMES, t1.TipDepCnx, t1.REALIZADO
FROM  WORK.CONSOLIDADO_CNX t1
INNER JOIN IGR.IGRREDE_201811 t2
ON t1.PREFDEP = INPUT(t2.PrefDep, d4.)
WHERE t2.TipoDep Not in ('99','39') and t2.CodSitDep = "2";

/*and t2.PrefUEN = '9500'*/

QUIT;


data WORK.CONSOLIDADO_CNX;
format posicao yymmdd10.;
set WORK.CONSOLIDADO_CNX;
POSICAO = '30NOV2018'd;
run;


PROC STDIZE DATA=WORK.CONSOLIDADO_CNX OUT=WORK.CONSOLIDADO_CNX REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
CREATE TABLE auxiliar.CONSOLIDADO_CNX AS 
SELECT *
FROM  WORK.CONSOLIDADO_CNX;
QUIT;



/*ANALISE DE COMPARAÇÃO*/
/**************************/
/**************************/
/**************************/


PROC SQL;
CREATE TABLE COMPARACAO_1 AS 
SELECT PREFDEP, carteira AS CTRA, REALIZADO
FROM CONSOLIDADO_CNX;
QUIT;


PROC SQL;
CREATE TABLE COMPARACAO_2 AS 
SELECT cd_uor, 0 as CTRA, vl_rlzd_in as REALIZADO_ATUAL
FROM ATB.vl_aprd_in_uor
where aa_vl_aprd_in = 2018 and mm_vl_aprd_in = 11 and cd_In_mod_avlc = 11785;
QUIT;


PROC SQL;
CREATE TABLE COMPARACAO_3 AS 
SELECT cd_uor_ctra AS cd_uor, nr_seql_ctra as CTRA, vl_rlzd_in as REALIZADO_ATUAL
FROM ATB.vl_aprd_in_ctra
where aa_vl_aprd_in = 2018 and mm_vl_aprd_in = 11 and  cd_in_mod_avlc = 11788;
QUIT;


PROC SQL;
CREATE TABLE COMPARACAO_4 AS SELECT *
FROM COMPARACAO_2
UNION SELECT *
FROM COMPARACAO_3;
QUIT;


PROC SQL;
CREATE TABLE COMPARACAO_5 AS 
SELECT INPUT(UOR, d9.) as cd_uor, INPUT(PrefDep, d4.) as prefdep
FROM comum.dependencias
where sb="00";
QUIT;


PROC SQL;
CREATE TABLE COMPARACAO_6 AS 
SELECT *
FROM COMPARACAO_4 t1
LEFT JOIN COMPARACAO_5 t2 ON t1.cd_uor = t2.cd_uor;
QUIT;


PROC SQL;
CREATE TABLE COMPARACAO_7 AS 
SELECT t1.PREFDEP AS PREFDEP, t1.CTRA, t1.REALIZADO_ATUAL, t2.REALIZADO as REALIZADO_REPRO, (t2.REALIZADO - t1.REALIZADO_ATUAL) AS DIFERENCA
FROM COMPARACAO_6 t1
LEFT JOIN COMPARACAO_1 t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA;
QUIT;


PROC STDIZE DATA=COMPARACAO_7 OUT=COMPARACAO_7 REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


/**Novo Conexao**/
/**Novo Conexao**/
/**Novo Conexao**/
/**Novo Conexao**/


PROC SQL;
CREATE TABLE WORK.NOVO_CONSOLIDADO_CNX AS 
SELECT 

t1.*,
t2.REALIZADO_ATUAL

FROM  WORK.CONSOLIDADO_CNX t1 
LEFT JOIN COMPARACAO_7 t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CARTEIRA = t2.CTRA;
QUIT;


PROC STDIZE DATA=NOVO_CONSOLIDADO_CNX OUT=NOVO_CONSOLIDADO_CNX REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
CREATE TABLE WORK.NOVO_CONSOLIDADO_CNX_1 AS 
SELECT 

t1.POSICAO,
t1.PREFDEP,
t1.CARTEIRA,
t1.ANOMES,
t1.TipDepCnx,
/*t1.REALIZADO,*/
/*t1.REALIZADO_ATUAL,*/

IFN(REALIZADO_ATUAL >= REALIZADO, REALIZADO_ATUAL, REALIZADO) AS REALIZADO

FROM  WORK.NOVO_CONSOLIDADO_CNX t1;
QUIT;



/*PREFIXOS*/

PROC SQL;
CREATE TABLE ANALISE_PREFIXO AS 
SELECT *
FROM COMPARACAO_7 t1
WHERE CTRA = 0;
QUIT;


PROC SQL;
CREATE TABLE ANALISE_PREFIXO_FINAL AS 
SELECT 

PREFDEP,
CTRA,
REALIZADO_ATUAL,
REALIZADO_REPRO,
DIFERENCA,
IFN(DIFERENCA > 0,1,0) AS INDICADOR1,
IFN(DIFERENCA < 0,1,0) AS INDICADOR2,
IFN(DIFERENCA = 0,1,0) AS INDICADOR3

FROM ANALISE_PREFIXO;

QUIT;


PROC SQL;
CREATE TABLE ANALISE_PREFIXO_FINAL_2 AS 
SELECT 

PREFDEP,
CTRA,
REALIZADO_ATUAL,
REALIZADO_REPRO,
DIFERENCA,
SUM(INDICADOR1) AS MAIOR,
SUM(INDICADOR2) AS MENOR,
SUM(INDICADOR3) AS IGUAL

FROM ANALISE_PREFIXO_FINAL;

QUIT;



/*CARTEIRAS*/


PROC SQL;
CREATE TABLE ANALISE_CARTEIRAS AS 
SELECT *
FROM COMPARACAO_7 t1
WHERE CTRA <>0;
QUIT;


PROC SQL;
CREATE TABLE ANALISE_CARTEIRAS_FINAL AS 
SELECT 

PREFDEP,
CTRA,
REALIZADO_ATUAL,
REALIZADO_REPRO,
DIFERENCA,
IFN(DIFERENCA > 0,1,0) AS INDICADOR1,
IFN(DIFERENCA < 0,1,0) AS INDICADOR2,
IFN(DIFERENCA = 0,1,0) AS INDICADOR3

FROM ANALISE_CARTEIRAS;

QUIT;


PROC SQL;
CREATE TABLE ANALISE_CARTEIRAS_FINAL_2 AS 
SELECT 

PREFDEP,
CTRA,
REALIZADO_ATUAL,
REALIZADO_REPRO,
DIFERENCA,
SUM(INDICADOR1) AS MAIOR,
SUM(INDICADOR2) AS MENOR,
SUM(INDICADOR3) AS IGUAL

FROM ANALISE_CARTEIRAS_FINAL;

QUIT;



/**************************/
/**************************/
/**************************/
/**************************/


PROC SQL;
CREATE TABLE auxiliar.NOVO_CONSOLIDADO_CNX_1_11 AS 
SELECT *
FROM  WORK.NOVO_CONSOLIDADO_CNX_1;
QUIT;


/*SUBINDO PARA O CONEXAO*/ 


PROC SQL;
    CREATE TABLE CONEXAO AS
        SELECT
            '2000153'
            ||"&Tx_Fon"
            ||REPEAT(' ',45)
            ||COMPRESS(PUT(t1.PrefDep,Z4.))
            ||COMPRESS(PUT(t1.Carteira,Z5.))
            ||"201811"
            ||put(t1.TipDepCnx,z4.)
            ||'+'
            ||PUT(ABS(t1.REALIZADO)*100,z13.)
            ||'F7176219'
            ||COMPRESS(PUT('30NOV2018'd, ddmmyy10.))
            ||'N' AS L
        FROM WORK.NOVO_CONSOLIDADO_CNX_1 t1       
;QUIT;


%GerarBBM(TabelaSAS=CONEXAO, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=M1162);


/*SUBINDO PARA O CONEXAO - FIM*/


x chmod 2777 *;


/*###############*/
/*CONSOLIDADO_rel*/
/*###############*/


PROC SQL;
	CREATE TABLE WORK.CONSOLIDADO_1 AS 
	SELECT DISTINCT '30NOV2018'd FORMAT=DateMysql. AS POSICAO,
		   t1.PREFIXO,
		   t1.CARTEIRA,
		   (t3.QTD_CLIENTES) AS FC_CLI_OBJ,
		   (t3.QTD_CLI_USO_FC) AS FC_CLI_RLZ,
		   ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) AS FC_UTILIZACAO,
		   ( IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 2.5, 0, 0, 0) +
		   	 IFN(((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) > 2.5 AND ((t3.QTD_CLI_USO_FC / t3.QTD_CLIENTES)*100) <= 5, 5, 0, 0) +
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
   CREATE TABLE WORK.CONSOLIDADO AS 
   SELECT t1.POSICAO, 
          t1.prefixo, 
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
		  (
		  	IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) > 0 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 5.99, 50, 0, 0) + 
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 6 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 10.99, 115, 0, 0) +
		    IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 11 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 15.99, 180, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 16 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 20.99, 245, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 21 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 25.99, 310, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 26 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 30.99, 375, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 31 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 35.99, 440, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 36 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 40.99, 505, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 41 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 45.99, 570, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 46 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 50.99, 635, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 51 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 55.99, 700, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 56 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 60.99, 765, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 61 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 65.99, 830, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 66 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 70.99, 895, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 71 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 75.99, 960, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 76 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 80.99, 1000, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 81 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 85.99, 1125, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 86 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 90.99, 1250, 0, 0) +
			IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 91 AND ((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) <= 95.99, 1375, 0, 0) +
		    IFN(((t1.FC_UTILIZACAO_PTS + t1.FC_TR_PTS + t1.ATA_ATDT_IMED_PTS + t1.ATA_TR_PTS)/0.8) >= 96, 1500, 0, 0)
		  ) AS PTS_CONEXAO
      FROM WORK.CONSOLIDADO_1 t1;
QUIT;


DATA CONSOLIDADO;
SET CONSOLIDADO;
ORCADO = 80;
RUN;


/*PARA O RELATÓRIO*/

PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_REL AS 
SELECT POSICAO, prefixo as PREFDEP, CARTEIRA as CTRA, FC_CLI_OBJ, FC_CLI_RLZ, FC_UTILIZACAO_PTS, FC_TR, FC_TR_PTS, ATA_ATDT_IMED, ATA_ATDT_IMED_PTS, 
ATA_TR, ATA_TR_PTS, ORCADO, (fc_utilizacao_pts + fc_tr_pts + ata_atdt_imed_pts + ata_tr_pts) as REALIZADO
FROM  WORK.CONSOLIDADO;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_REL AS 
SELECT t1.POSICAO, t1.PREFDEP, t1.CTRA, t1.FC_CLI_OBJ, t1.FC_CLI_RLZ, t1.FC_UTILIZACAO_PTS, t1.FC_TR, t1.FC_TR_PTS, t1.ATA_ATDT_IMED, t1.ATA_ATDT_IMED_PTS, 
t1.ATA_TR, t1.ATA_TR_PTS, t1.ORCADO, /*t1.REALIZADO, t2.REALIZADO as NOVO_REALIZADO,*/ IFN(t2.REALIZADO >= t1.REALIZADO, t2.REALIZADO, t1.REALIZADO) AS REALIZADO
FROM  WORK.CONSOLIDADO_REL t1
LEFT JOIN NOVO_CONSOLIDADO_CNX_1 t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CARTEIRA;;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_REL AS 
SELECT POSICAO, PREFDEP, CTRA, FC_CLI_OBJ, FC_CLI_RLZ, FC_UTILIZACAO_PTS, FC_TR, FC_TR_PTS, ATA_ATDT_IMED, ATA_ATDT_IMED_PTS, 
ATA_TR, ATA_TR_PTS, ORCADO, REALIZADO, (REALIZADO/ORCADO)*100 as POR_ATG
FROM  WORK.CONSOLIDADO_REL;
QUIT;


PROC SQL;
CREATE TABLE WORK.CONSOLIDADO_REL AS 
SELECT POSICAO, PREFDEP, CTRA, FC_CLI_OBJ, FC_CLI_RLZ, FC_UTILIZACAO_PTS, FC_TR, FC_TR_PTS, ATA_ATDT_IMED, ATA_ATDT_IMED_PTS, 
ATA_TR, ATA_TR_PTS, ORCADO, REALIZADO, (REALIZADO/ORCADO)*100 as POR_ATG
FROM  WORK.CONSOLIDADO_REL
WHERE PREFDEP <> 9007 AND PREFDEP <> 9008;
QUIT;


data WORK.CONSOLIDADO_REL;
format POSICAO yymmdd10.;
set WORK.CONSOLIDADO_REL;
POSICAO = '30NOV2018'd;
run;



PROC SQL;
CREATE TABLE auxiliar.CONSOLIDADO_REL_11 AS 
SELECT *
FROM  WORK.CONSOLIDADO_REL;
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

