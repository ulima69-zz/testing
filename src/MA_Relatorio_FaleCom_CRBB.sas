/*********************************************************************
 ROTINA: RELATÓRIO FALE COM
 AUTOR.: F6794004 - MARCIO VINICIUS DE ALMEIDA

 VERSÃO: VRS001 - 27/02/2019 - F6794004 (MARCIO) - Implementação   

**********************************************************************/

%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';
%Let Mes=0;
/************************************************/
LIBNAME LOCAL "/dados/infor/producao/relatorio_fale_com";
LIBNAME REL   "/dados/gecen/interno/bases/rel";
LIBNAME REL   "/dados/gecen/interno/bases/cdc";
LIBNAME RELFOTOS   "/dados/gecen/interno/bases/rel/fotos";
LIBNAME MIV DB2 DATABASE=BDB2P04 SCHEMA=DB2MIV AUTHDOMAIN=DB2SVARC;
LIBNAME LOCAL "/dados/infor/producao/relatorio_fale_com";
%CONECTARDB2(MIV);
%CONECTARDB2(REL);
%CONECTARDB2(PRD);
%CONECTARDB2(GAT);

			%diasUteis(%sysfunc(today()), 5);
			%GLOBAL DiaUtil_D0 DiaUtil_D1;

			data arq;
				format 
					anomes yymmn6.
					mesano z6.
					DiaUtil_D1 date9.
					DiaUtil_D2 date9.
					inicio_sem date9.
					fim_sem date9.
					D_mais_2 date9.
					mes z2.
					ano 4.;
				anomes = &diautil_d1;
				mesano = INPUT(PUT(&diautil_d1, mmyyn6.),6.);
				DiaUtil_D1 = &diautil_d1;
				DiaUtil_D2 = &diautil_d1;
				inicio_sem = '1jul2018'd;
				fim_sem = '31dec2018'd;
				D_mais_2 = &DiaUtil_D0 + 2;
				mes = month(&diautil_d1);
				ano = year(&diautil_d1);
				CALL SYMPUT('D_mais_2',COMPRESS(D_mais_2,' '));
			run;

			%put &D_mais_2;
			%put &DiaUtil_D0;

			proc sql;
				select anomes, DiaUtil_D1, DiaUtil_D2, inicio_sem, fim_sem, D_mais_2, mes, ano, mesano

				into :anomes, :DiaUtil_D1, :DiaUtil_D2, :inicio_sem, :fim_sem, :D_mais_2, :mes, :ano, :mesano
					from arq;
			quit;

			%put &anomes &mesano &DiaUtil_D1 &DiaUtil_D2 &inicio_sem &fim_sem &ano &mes &mesano;

DATA _NULL_;

/*D1_PRI = '01MAR2019'd;*/
D1_PRI=primeiroDiaUtilMes(DiaUtilAnterior(Today()));
CALL SYMPUT('D1_PRI',"'"||Put(D1_PRI, yymmdd10.)||"'");

DATAINICIAL=primeiroDiaMes(DiaUtilAnterior(Today()));
CALL SYMPUT('DATAINICIAL',"'"||Put(DATAINICIAL, DATE9.)||"'");

DATAFINAL=ultimoDiaMes(DiaUtilAnterior(Today()));
CALL SYMPUT('DATAFINAL',"'"||Put(DATAFINAL, DATE9.)||"'");

/*D1 = '29MAR2019'd;*/
D1 = diaUtilAnterior(TODAY());
CALL SYMPUT('D1',COMPRESS(D1,' '));

DT_PSC = diaUtilAnterior(TODAY());
CALL SYMPUT('DT_PSC',"'"||Put(D1, yymmdd10.)||"'");

CALL SYMPUT('DT_PSC_2',"'"||Put(A, DATE9.)||"'");

ANO_ATUAL = 2019;
CALL SYMPUT('ANO_ATUAL',COMPRESS(ANO_ATUAL,' '));

/*MES_POSICAO = 03;*/
MES_POSICAO = Put(MONTH (D1), Z2.);
CALL SYMPUT('MES_POSICAO', COMPRESS(MES_POSICAO,' '));

/*ANOMES = 201903;*/
ANOMES = Put(D1, yymmn6.);
CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));

/*MESANO = 032019;*/
MESANO = Put(D1, mmyyn6.);
CALL SYMPUT('MESANO',COMPRESS(MESANO,' '));


/*FAZENDO AS VARIAVEIS DO MES ANTERIOR*/
/*FAZENDO AS VARIAVEIS DO MES ANTERIOR*/


D1_PRI_MM_ANT = primeiroDiaUtilMes(intnx('MONTH',D1,-1));
CALL SYMPUT('D1_PRI_MM_ANT',"'"||Put(D1_PRI_MM_ANT, yymmdd10.)||"'");

D1_MM_ANT = ultimoDiaUtilMes(intnx('MONTH',D1,-1));
CALL SYMPUT('D1_MM_ANT',"'"||Put(D1_MM_ANT, yymmdd10.)||"'");

MES_POSICAO_ANT = Put(MONTH (D1_MM_ANT), Z2.);
CALL SYMPUT('MES_POSICAO_ANT', COMPRESS(MES_POSICAO_ANT,' '));

ANOMES_ANT = Put(D1_MM_ANT, yymmn6.);
CALL SYMPUT('ANOMES_ANT',COMPRESS(ANOMES_ANT,' '));

MESANO_ANT = Put(D1_MM_ANT, mmyyn6.);
CALL SYMPUT('MESANO_ANT',COMPRESS(MESANO_ANT,' '));
	
RUN;

%Put &D1_PRI &D1 &DT_PSC &DT_PSC_2  &ANO_ATUAL &MES_POSICAO &ANOMES &MESANO &D1_PRI_MM_ANT &D1_MM_ANT &MES_POSICAO_ANT &ANOMES_ANT &MESANO_ANT, &DATAINICIAL &DATAFINAL;


/* 
   RECUPERAR MCIS PUBLICO ALVO - Todos os clientes PF com Duplo Encarteiramento 
   PREFIXO..: 9940 - CRBB São José dos Pinhais
   Carteiras: Todas Carteiras PF
*/

/* Trazer clientes com duplo encarteiramento - prefixos primários, diferentes de 9940*/
PROC SQL;
	 CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
		CREATE TABLE CLIENTES_PRF_PRMR AS 
		SELECT * FROM CONNECTION TO DB2
		  (SELECT DISTINCT 
                  t1.CD_CLI, 
                  t1.CD_PRF_DEPE AS CD_PRF_PRMR, 
		          t1.NR_SEQL_CTRA, 
		          t1.DT_INCL_CLI_CTRA, 
		          t1.IN_INCL_AUTC, 
		          t1.CD_CLI_VLCD, 
		          t1.IN_VLCD_CLI, 
		          t1.CD_MTV_INCL, 
		          t1.DT_VLDC, 
		          t1.CD_PAB, 
		          t1.DT_CRSD, 
		          t1.DT_ULT_ALT_CTGR, 
		          t1.QT_INCC_EXCL, 
		          t1.QT_INCC_TRNS
			 FROM DB2REL.CLI_CTRA T1
			      INNER JOIN DB2MCI.CLIENTE T2 ON (T1.CD_CLI = T2.COD)
			WHERE T2.COD_TIPO = 1
			  AND t1.CD_PRF_DEPE <> 9940
			  AND CD_CLI IN (SELECT DISTINCT CD_CLI FROM DB2REL.CLI_CTRA WHERE CD_PRF_DEPE = 9940)
          );
	 DISCONNECT FROM DB2;
QUIT;

/* Trazer clientes com duplo encarteiramento - prefixos secundários, somente 9940*/
PROC SQL;
	 CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
		CREATE TABLE CLIENTES_PRF_SCDR AS 
		SELECT * FROM CONNECTION TO DB2
		  (SELECT DISTINCT 
                  t1.CD_CLI, 
                  t1.CD_PRF_DEPE AS CD_PRF_SCDR, 
		          t1.NR_SEQL_CTRA, 
		          t1.DT_INCL_CLI_CTRA, 
		          t1.IN_INCL_AUTC, 
		          t1.CD_CLI_VLCD, 
		          t1.IN_VLCD_CLI, 
		          t1.CD_MTV_INCL, 
		          t1.DT_VLDC, 
		          t1.CD_PAB, 
		          t1.DT_CRSD, 
		          t1.DT_ULT_ALT_CTGR, 
		          t1.QT_INCC_EXCL, 
		          t1.QT_INCC_TRNS
			 FROM DB2REL.CLI_CTRA T1
			INNER JOIN DB2MCI.CLIENTE T2 ON (T1.CD_CLI = T2.COD)
			WHERE T1.CD_PRF_DEPE = 9940 
			  AND T2.COD_TIPO = 1
			  AND CD_CLI IN (SELECT DISTINCT CD_CLI FROM DB2REL.CLI_CTRA WHERE CD_PRF_DEPE <> 9940)
          );
	 DISCONNECT FROM DB2;
QUIT;

/* Gerar tabela de clientes Público Alvo */
PROC SQL;
   CREATE TABLE CLIENTES_ALVO AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.CD_PRF_SCDR AS PRF_SCDR, 
          t1.NR_SEQL_CTRA AS CTRA_SCDR, 
          t2.CD_PRF_PRMR AS PRF_PRMR, 
          t2.NR_SEQL_CTRA AS CTRA_PRMR, 
          t2.CD_PAB
      FROM CLIENTES_PRF_SCDR t1
           INNER JOIN CLIENTES_PRF_PRMR t2 ON (t1.CD_CLI = t2.CD_CLI)
	  WHERE t1.NR_SEQL_CTRA IN ( 1, 2, 3, 13) 
      ORDER BY t1.CD_CLI, 
            t1.CD_PRF_SCDR, 
            t1.NR_SEQL_CTRA;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TTL_CLI_CTRA AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          /* COUNT_DISTINCT_of_CD_CLI */
            (COUNT(DISTINCT(t1.CD_CLI))) AS COUNT_DISTINCT_of_CD_CLI
      FROM WORK.CLIENTES_ALVO t1
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR;
QUIT;

/* 
**********   RELATÓRIO TRANSACIONAL   **********
**********   RELATÓRIO TRANSACIONAL   **********
**********   RELATÓRIO TRANSACIONAL   **********
**********   RELATÓRIO TRANSACIONAL   **********
**********   RELATÓRIO TRANSACIONAL   **********
**********   RELATÓRIO TRANSACIONAL   **********/

/* Recupera atendimentos realizados no dia útil anterior */
PROC SQL;
 CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
	CREATE TABLE TBL_TOTAL_ATDT AS 
	SELECT * FROM CONNECTION TO DB2 
   		( SELECT DISTINCT 
          		 t1.CD_CLI_MSG_EXPS,
                 t1.NR_PTL_ATDT_CLI,  
				 DATE(t1.TS_ABTR_PTL) AS DT_ABTR_PTL,
         		 t1.NR_SEQL_DBT, 
          	  	 t1.TS_ABTR_PTL, 
          	 	 t1.TS_ECR_PTL, 
          	 	 t1.CD_TIP_ECR_PTL, 
                 t1.CD_USU_ECR, 
          		 t1.IN_PTL_OGM_RPRT
      		FROM DB2MIV.PTL_DBT_MSG_EXPS t1
      	   WHERE DATE(t1.TS_ABTR_PTL) = &Dt_PSC.
		   ORDER BY 1, 2
        );
  DISCONNECT FROM DB2;
QUIT;

/*Pega todos os protocolos Abertos */
PROC SQL;
   CREATE TABLE TBL_PTL_ABTR_CLI AS 
   SELECT t1.CD_CLI_MSG_EXPS AS CD_CLI,
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.NR_PTL_ATDT_CLI
     FROM TBL_TOTAL_ATDT t1
     WHERE t1.TS_ECR_PTL IS NULL 
    ORDER BY t1.CD_CLI_MSG_EXPS;
QUIT;

/* Tabela com Protocolos Encerrados */
PROC SQL;
   CREATE TABLE TBL_PTL_ECR_CLI AS 
   SELECT t1.CD_CLI_MSG_EXPS AS CD_CLI,
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.NR_PTL_ATDT_CLI
      FROM TBL_TOTAL_ATDT t1
	  WHERE t1.TS_ECR_PTL IS NOT NULL 
      ORDER BY t1.CD_CLI_MSG_EXPS;
QUIT;

/*Junta protocolos todos os protocolos*/
DATA TOTAL_PROTOCOLOS;
 SET TBL_PTL_ABTR_CLI TBL_PTL_ECR_CLI;
RUN;


/*Junta para Relatório Detalhado- Todos os Protocolos */
PROC SQL;
   CREATE TABLE REL_TRNL_FALECOM_1 AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR,
          t2.TS_ABTR_PTL, 
          t2.TS_ECR_PTL,  
		  t2.NR_PTL_ATDT_CLI
    FROM  WORK.CLIENTES_ALVO t1
    LEFT JOIN  TOTAL_PROTOCOLOS t2 ON (t1.CD_CLI = t2.CD_CLI)
   ORDER BY  1, 6, 4, 5;
QUIT;

/*Junta para Relatório Detalhado- Todos os Protocolos  - Indicadores de Protocolos Abertos e Encerrrados Para Sumarização - CLIENTES */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_2 AS 
   SELECT t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL,
		  TIMEPART(t1.TS_ABTR_PTL) FORMAT TIME. AS HORA_INI, 
		  TIMEPART(t1.TS_ECR_PTL) FORMAT TIME. AS HORA_FIM, 
          t1.NR_PTL_ATDT_CLI, 
          /* IND_PTL_ABTR */
          (CASE WHEN t1.NR_PTL_ATDT_CLI IS MISSING THEN 0 
                WHEN t1.NR_PTL_ATDT_CLI IS NOT MISSING THEN 1 
           END) AS IND_PTL_ABTR, 
          /* IND_PTL_ENCR */
          (CASE WHEN t1.NR_PTL_ATDT_CLI IS NOT MISSING  AND t1.TS_ECR_PTL IS NOT MISSING THEN 1 
                ELSE 0 
           END) AS IND_PTL_ENCR
      FROM WORK.REL_TRNL_FALECOM_1 t1;
QUIT;

/* Clientes com Interação Registrada na Tabela DB2MIV.TX_MSG_EXPS */
PROC SQL;
 CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
	CREATE TABLE TBL_INTERACOES AS 
	SELECT * FROM CONNECTION TO DB2 
   		( SELECT  t1.CD_CLI_MSG_EXPS, 
		          t1.NR_SEQL_DBT, 
		          t1.TS_CRIC_MSG, 
				  DATE(t1.TS_CRIC_MSG) AS DATA_INRO, 
		          HOUR(t1.TS_CRIC_MSG) AS HORA_INRO,
				  TIME(t1.TS_CRIC_MSG) AS HORA_MIN, 
		          t1.CD_USU_RSP_EST_MSG AS RESPONSAVEL, 
		          t1.CD_SNLC_MSG, 
		          t1.CD_EST_MSG, 
		          t1.DT_LET_MSG, 
		          t1.HR_LET_MSG, 
		          t1.TX_MSG, 
		          t1.CD_ITCE_CNL_ATDT, 
		          t1.CD_EQPO_AUTD, 
		          t1.CD_EST_AUTZ_TRAN
		      FROM DB2MIV.TX_MSG_EXPS t1
			  INNER JOIN DB2MIV.DBT_ELET_MSG_EXPS t2 ON (t2.CD_CLI_MSG_EXPS = t1.CD_CLI_MSG_EXPS and t2.NR_SEQL_DBT = t1.NR_SEQL_DBT)
      	   WHERE DATE(t1.TS_CRIC_MSG) = &dt_psc.
		   ORDER BY 1, 2
        );
  DISCONNECT FROM DB2;
QUIT;


PROC STDIZE DATA=TBL_INTERACOES OUT=TBL_INTERACOES REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;

/**/
/*data exemplo_espacos;*/
/*    campo_A = "Finalizado Atendimento Nr.      663693041222 por  MARINALDO RISSI";*/
/*    exemplo_trim = trim(campo_A);*/
/*    exemplo_compress = compress(campo_A);*/
/*run;*/

PROC SQL;
   CREATE TABLE WORK.PROTOCOLOS_INICIAL AS 
   SELECT DISTINCT t1.CD_CLI_MSG_EXPS, 
          t1.data_inro, 
          t1.hora_inro,
          t1.HORA_MIN,
          t1.RESPONSAVEL,
          /* protocolo */
            (INPUT(SUBSTR(compress(t1.TX_MSG),23, 12.),14.)) AS protocolo, 
          t1.TX_MSG, 
          /* matricula */
            (SUBSTR(t1.TX_MSG, 51,30.)) AS matricula
      FROM WORK.TBL_INTERACOES t1
      WHERE t1.CD_SNLC_MSG = 200
     order by 1, 2, 3, 4;
QUIT;

PROC SQL;
   CREATE TABLE WORK.PROTOCOLOS_FINAL AS 
   SELECT DISTINCT t1.CD_CLI_MSG_EXPS, 
          t1.data_inro, 
          t1.hora_inro,
          t1.HORA_MIN, 
		  t1.RESPONSAVEL,
          /* protocolo */
            (INPUT(SUBSTR(compress(t1.TX_MSG),25, 12.),14.)) AS protocolo, 
          t1.TX_MSG, 
          /* matricula */
            (SUBSTR(t1.TX_MSG, 51,30.)) AS matricula
      FROM WORK.TBL_INTERACOES t1
      WHERE t1.CD_SNLC_MSG = 201
     order by 1, 2, 3, 4;
QUIT;


/* Total de Interações do Cliente por Dia */
PROC SQL;
   CREATE TABLE TBL_IND_INRO_CLI_0 AS 
   SELECT t1.CD_CLI_MSG_EXPS AS CD_CLI,
		  t1.DATA_INRO, 
		  t1.HORA_INRO,
		  t1.HORA_MIN, 
          t1.RESPONSAVEL,
          (COUNT(t1.CD_CLI_MSG_EXPS)) AS IN_INRO_CLI
     FROM TBL_INTERACOES t1
    WHERE t1.TX_MSG NOT CONTAINS 'Mensagem automática do sistema' 
      AND t1.TX_MSG NOT CONTAINS 'Bem-vindo ao Atendimento Digital BB'
      AND t1.RESPONSAVEL IS MISSING
	  AND t1.RESPONSAVEL NOT IN ('SISTEMA', 'F0000000')
 GROUP BY 1, 2, 3, 4
 order by 1, 2, 3, 4;
QUIT;

PROC SQL;
   CREATE TABLE TBL_IND_INRO_CLI_PTL_1 AS 
   SELECT t1.CD_CLI, 
          t1.DATA_INRO, 
          t1.HORA_INRO, 
          t1.HORA_MIN, 
          t1.IN_INRO_CLI,
          t1.RESPONSAVEL, 
          t2.protocolo
      FROM WORK.TBL_IND_INRO_CLI_0 t1
           LEFT JOIN WORK.PROTOCOLOS_INICIAL t2 ON (t1.DATA_INRO = t2.DATA_INRO) AND (t1.CD_CLI = t2.CD_CLI_MSG_EXPS) 
          AND (t1.HORA_INRO = t2.HORA_INRO) AND (t1.HORA_MIN = t2.HORA_MIN)
    order by 1, 2, 3, 4;
QUIT;


/* Replicar Protocolo em Cada Horário nas Interções do Cliente */
data WORK.TBL_IND_INRO_CLI_PTL;
	set work.TBL_IND_INRO_CLI_PTL_1;
	retain protocolo_ant;
	if not missing(protocolo) then
		protocolo_ant = protocolo;
	else
		protocolo = protocolo_ant;
	format protocolo: commax25.;
	drop protocolo_ant;
run;

/* Interações do Cliente por Hora*/
PROC SQL;
   CREATE TABLE WORK.INRO_CLI_HORA AS 
   SELECT t1.CD_CLI,
          t1.protocolo, 
          t1.DATA_INRO, 
          t1.HORA_INRO,
          t1.HORA_MIN, 
          /* INRO_CLI_HORA */
            (SUM(t1.IN_INRO_CLI)) AS INRO_CLI_HORA
      FROM WORK.TBL_IND_INRO_CLI_PTL t1
	  where t1.CD_CLI > 0 
      GROUP BY t1.CD_CLI,
               t1.DATA_INRO,
               t1.HORA_INRO
     order by 1, 2, 5 ;
QUIT;

/* Interações do Cliente por Protocolo */
PROC SQL;
   CREATE TABLE WORK.INRO_CLI_PTL AS 
   SELECT t1.CD_CLI, 
          t1.protocolo,
          /* INRO_CLI_PTL */
            (SUM(t1.IN_INRO_CLI)) AS INRO_CLI_PTL
      FROM WORK.TBL_IND_INRO_CLI_PTL t1
      GROUP BY t1.CD_CLI,
               t1.protocolo
     order by 1, 2, 3;
QUIT;


/*Junta para Relatório Detalhado- Total de Interações dos Clientes por Protocolo */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_3 AS 
   SELECT t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.HORA_INI, 
          t1.HORA_FIM, 
          t1.NR_PTL_ATDT_CLI, 
          t1.IND_PTL_ABTR, 
          t1.IND_PTL_ENCR, 
          COALESCE(t2.INRO_CLI_PTL, 0) AS INRO_CLI_PTL
      FROM WORK.REL_TRNL_FALECOM_2 t1
           LEFT JOIN WORK.INRO_CLI_PTL t2 ON (t1.CD_CLI = t2.CD_CLI) AND (t1.NR_PTL_ATDT_CLI = t2.protocolo);
QUIT;

/* Tempo entre a primeira e a última interação do cliente no protocolo */
PROC SQL;
   CREATE TABLE WORK.TEMPO_INRO_CLI AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.DATA_INRO, 
          t1.HORA_INRO,
          t1.RESPONSAVEL,  
          t1.protocolo, 
          /* MIN_of_HORA_MIN */
            (MIN(t1.HORA_MIN)) FORMAT=TIME8. AS HORA_MIN, 
          /* MAX_of_HORA_MIN */
            (MAX(t1.HORA_MIN)) FORMAT=TIME8. AS HORA_MAX, 
          /* SUM_of_IN_INRO_CLI */
            (SUM(t1.IN_INRO_CLI)) AS QTD_INRO_CLI, 
          /* TEMPO_INRO_CLI */
            ((MAX(t1.HORA_MIN)) - (MIN(t1.HORA_MIN))) FORMAT=TIME8. AS TEMPO_INRO_CLI
      FROM WORK.TBL_IND_INRO_CLI_PTL t1
      GROUP BY t1.CD_CLI,
               t1.DATA_INRO,
               t1.HORA_INRO,
               t1.protocolo;
QUIT;

/* Junta para Relatório Detalhado- Total de Extensão da Interação do Cliente */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_4 AS 
   SELECT t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.HORA_INI, 
          t1.HORA_FIM, 
          t1.NR_PTL_ATDT_CLI, 
          t1.IND_PTL_ABTR, 
          t1.IND_PTL_ENCR, 
          t1.INRO_CLI_PTL, 
          COALESCE(t2.TEMPO_INRO_CLI,0) FORMAT TIME. AS TMP_EXTD_CLI
      FROM WORK.REL_TRNL_FALECOM_3 t1
           LEFT JOIN WORK.TEMPO_INRO_CLI t2 ON (t1.CD_CLI = t2.CD_CLI) AND (t1.NR_PTL_ATDT_CLI = t2.protocolo);
QUIT;


/* Total de Interações do Cliente e Banco por Dia */
PROC SQL;
   CREATE TABLE TBL_IND_INRO_BB_0 AS 
   SELECT t1.CD_CLI_MSG_EXPS AS CD_CLI,
		  t1.DATA_INRO, 
		  t1.HORA_INRO,
		  t1.HORA_MIN,
          t1.responsavel, 
          (COUNT(t1.CD_CLI_MSG_EXPS)) AS IN_INRO_BB
     FROM TBL_INTERACOES t1
    WHERE t1.TX_MSG NOT CONTAINS 'Mensagem automática do sistema' 
      AND t1.TX_MSG NOT CONTAINS 'Bem-vindo ao Atendimento Digital BB'
      AND (t1.responsavel CONTAINS 'F' or  t1.RESPONSAVEL IS MISSING)
      AND t1.responsavel NOT IN ('F0000000', 'SISTEMA')
 GROUP BY 1, 2, 3, 4
 order by 1, 2, 3, 4;
QUIT;


PROC SQL;
   CREATE TABLE TBL_IND_INRO_BB_PTL_1 AS 
   SELECT t1.CD_CLI, 
          t1.DATA_INRO, 
          t1.HORA_INRO, 
          t1.HORA_MIN, 
          t1.IN_INRO_BB, 
		  ifc(t1.responsavel is missing, 'CLIENTE', t1.responsavel) as responsavel,
          t2.protocolo
      FROM WORK.TBL_IND_INRO_BB_0 t1
           LEFT JOIN WORK.PROTOCOLOS_INICIAL t2 ON (t1.DATA_INRO = t2.DATA_INRO) AND (t1.CD_CLI = t2.CD_CLI_MSG_EXPS) 
          AND (t1.HORA_INRO = t2.HORA_INRO) AND (t1.HORA_MIN = t2.HORA_MIN)
	 order by 1, 2, 3, 4;
QUIT;


/* Replicar Protocolo em Cada Horário nas Interções do Banco */
data WORK.TBL_IND_INRO_BB_PTL;
	set TBL_IND_INRO_BB_PTL_1;
	retain protocolo_ant;
	if not missing(protocolo) then
		protocolo_ant = protocolo;
	else
		protocolo = protocolo_ant;
	format protocolo: commax25.;
	drop protocolo_ant;
run;

PROC SORT DATA=TBL_IND_INRO_BB_PTL OUT=TBL_IND_INRO_BB_PTL;
   BY PROTOCOLO CD_CLI DATA_INRO HORA_INRO HORA_MIN;
RUN;

/* Criar Sequencial de Interações Entre BB e Cliente */
data TBL_IND_INRO_BB_PTL_SEQL;
	set TBL_IND_INRO_BB_PTL;
	by protocolo;

	if first.protocolo then
		SeqN=1;
	else SeqN + 1;
run;

/* Total de Interações do BB por Protocolo */
PROC SQL;
   CREATE TABLE WORK.TTL_INRO_BB_PTL AS 
   SELECT t1.CD_CLI, 
          t1.protocolo, 
          /* COUNT_of_protocolo */
            (COUNT(t1.protocolo)) AS INRO_BB_PTL
      FROM WORK.TBL_IND_INRO_BB_PTL_SEQL t1
      WHERE t1.responsavel NOT = 'CLIENTE'
      GROUP BY t1.CD_CLI,
               t1.protocolo;
QUIT;

/* Quantidade de Interações do BB por Hora*/
PROC SQL;
   CREATE TABLE WORK.INRO_BB_HORA AS 
   SELECT t1.CD_CLI,
          t1.protocolo, 
          t1.DATA_INRO, 
          t1.HORA_INRO,
          t1.HORA_MIN, 
          /* INRO_CLI_HORA */
            (SUM(t1.IN_INRO_BB)) AS INRO_BB_HORA
      FROM WORK.TBL_IND_INRO_BB_PTL_SEQL t1
	  WHERE t1.responsavel NOT = 'CLIENTE'
	    and t1.CD_CLI > 0
      GROUP BY t1.CD_CLI,
               t1.DATA_INRO,
               t1.HORA_INRO
     order by 1, 2, 5 ;
QUIT;


/* Junta para Relatório Detalhado- Total de Interações do BB por Protocolo */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_5 AS 
   SELECT t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.HORA_INI, 
          t1.HORA_FIM, 
          t1.NR_PTL_ATDT_CLI, 
          t1.IND_PTL_ABTR, 
          t1.IND_PTL_ENCR, 
          t1.INRO_CLI_PTL, 
		  t1.TMP_EXTD_CLI,
          COALESCE(t2.INRO_BB_PTL,0) AS INRO_BB_PTL
      FROM WORK.REL_TRNL_FALECOM_4 t1
           LEFT JOIN WORK.TTL_INRO_BB_PTL t2 ON (t1.CD_CLI = t2.CD_CLI) AND (t1.NR_PTL_ATDT_CLI = t2.protocolo);
QUIT;


/* Tempo entre a primeira e a última interação do BB no protocolo independentemente de quem iniciou o diálogo */
PROC SQL;
   CREATE TABLE WORK.TEMPO_INRO_CLI_BB AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.DATA_INRO, 
/*          t1.HORA_INRO,*/
/*          t1.RESPONSAVEL,  */
          t1.protocolo, 
          /* MIN_of_HORA_MIN */
            (MIN(t1.HORA_MIN)) FORMAT=TIME8. AS HORA_MIN, 
          /* MAX_of_HORA_MIN */
            (MAX(t1.HORA_MIN)) FORMAT=TIME8. AS HORA_MAX, 
          /* SUM_of_IN_INRO_BB */
            (SUM(t1.IN_INRO_BB)) AS QTD_INRO_BB, 
          /* TEMPO_INRO_CLI */
            ((MAX(t1.HORA_MIN)) - (MIN(t1.HORA_MIN))) FORMAT=TIME8. AS TEMPO_INRO_BB
      FROM WORK.TBL_IND_INRO_BB_PTL_SEQL t1
	  WHERE t1.RESPONSAVEL <> 'CLIENTE'
      GROUP BY t1.CD_CLI,
               t1.DATA_INRO,
               t1.protocolo;
QUIT;


/* Junta para Relatório Detalhado- Total de Extensão da Interação do BB*/
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_6 AS 
   SELECT distinct t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.HORA_INI, 
          t1.HORA_FIM, 
          t1.NR_PTL_ATDT_CLI, 
          t1.IND_PTL_ABTR, 
          t1.IND_PTL_ENCR, 
          t1.INRO_CLI_PTL, 
		  t1.TMP_EXTD_CLI,
		  t1.INRO_BB_PTL,
          COALESCE(t2.TEMPO_INRO_BB,0) format time. AS TMP_EXTD_BB
      FROM WORK.REL_TRNL_FALECOM_5 t1
           LEFT JOIN WORK.TEMPO_INRO_CLI_BB t2 ON (t1.CD_CLI = t2.CD_CLI) AND (t1.NR_PTL_ATDT_CLI = t2.protocolo);
QUIT;

/* TEMPO DE RESPOSTA - INÍCIO - CONFORME PROCESSAMENTO DO HENRIQUE */

/* Clientes com Interação Registrada na Tabela DB2MIV.TX_MSG_EXPS para */
PROC SQL;
 CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
	CREATE TABLE TBL_TX_MSG_EXPS_0 AS 
	SELECT * FROM CONNECTION TO DB2 
   		( 
   SELECT DISTINCT t1.CD_CLI_MSG_EXPS AS mci, 
          /* data */
            (date(t1.TS_CRIC_MSG)) AS data, 
          /* hora */
            (time(t1.TS_CRIC_MSG)) AS hora, 
          t1.TS_CRIC_MSG AS timestamp, 
          t1.CD_USU_RSP_EST_MSG AS responsavel, 
          t1.DT_LET_MSG AS data_leitr, 
          t1.HR_LET_MSG AS hora_leitr, 
          t1.CD_EST_MSG, 
          t1.CD_SNLC_MSG, 
          t1.TX_MSG
      FROM DB2MIV.TX_MSG_EXPS t1
      WHERE DATE(t1.TS_CRIC_MSG) = &dt_psc.
      ORDER BY t1.CD_CLI_MSG_EXPS
        );
  DISCONNECT FROM DB2;
QUIT;

/*Tempo de Resposta - INICIO DO PROCESSAMENTO;*/
PROC SQL;
   CREATE TABLE WORK.TBL_TX_MSG_EXPS AS 
   SELECT DISTINCT t1.mci, 
          /* data */
            t1.data FORMAT=ddmmyy10. LABEL="data" AS data, 
          /* hora */
            t1.hora FORMAT=time8. LABEL="hora" AS hora, 
          t1.timestamp, 
          t1.responsavel, 
          t1.data_leitr FORMAT=ddmmyy10. AS data_leitr, 
          t1.hora_leitr, 
          t1.CD_EST_MSG, 
          t1.CD_SNLC_MSG, 
          t1.TX_MSG, 
          /* protocolo */
            (INPUT(SUBSTR(t1.TX_MSG, 29, 14.),14.)) AS protocolo
       FROM TBL_TX_MSG_EXPS_0 t1
      ORDER BY t1.mci;
QUIT;


PROC SQL;
   CREATE TABLE WORK.MENSAGEM_CLIENTE AS 
   SELECT t1.mci, 
          t1.data, 
          t1.hora, 
          t1.timestamp, 
          t1.responsavel, 
          t1.data_leitr, 
          t1.hora_leitr, 
          t1.CD_EST_MSG, 
          t1.CD_SNLC_MSG, 
          t1.TX_MSG, 
          t1.protocolo
      FROM WORK.TBL_TX_MSG_EXPS t1
      WHERE t1.TX_MSG NOT CONTAINS 'Mensagem automática do sistema' 
	    AND t1.TX_MSG NOT CONTAINS 'Bem-vindo ao Atendimento Digital BB'
        AND t1.responsavel IS MISSING;
QUIT;

PROC SQL;
   CREATE TABLE WORK.MENSAGEM_BB AS 
   SELECT DISTINCT t1.mci, 
          t1.responsavel, 
          /* data */
            (MIN(t1.data)) FORMAT=DDMMYY10. AS data, 
          /* hora */
            (MIN(t1.hora)) FORMAT=TOD8. AS hora
      FROM WORK.TBL_TX_MSG_EXPS t1
      WHERE t1.TX_MSG NOT CONTAINS 'Mensagem automática do sistema' 
	    AND t1.TX_MSG NOT CONTAINS 'Bem-vindo ao Atendimento Digital BB'
        AND t1.responsavel CONTAINS 'F' 
        AND t1.responsavel NOT IN ('F0000000', 'SISTEMA')
      GROUP BY t1.mci,
               t1.responsavel
      ORDER BY t1.mci;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TBL_TX_MSG_EXPS_1 AS 
   SELECT DISTINCT t1.mci, 
          t1.data, 
          t1.hora, 
          t1.protocolo, 
          /* matricula */
            (SUBSTR(t1.TX_MSG, 48,8.)) AS matricula, 
          t1.TX_MSG, 
          /* dia_semana */
            (WEEKDAY(t1.data)) AS dia_semana
      FROM WORK.TBL_TX_MSG_EXPS t1
      WHERE t1.CD_SNLC_MSG = 200
      ORDER BY t1.data;
QUIT;

PROC SQL;
   CREATE TABLE WORK.PROTOC_FINAL AS 
   SELECT DISTINCT t1.mci, 
          t1.data, 
          t1.hora, 
          /* protocolo */
            (INPUT(SUBSTR(t1.TX_MSG,33, 13.),14.)) AS protocolo, 
          t1.TX_MSG, 
          /* matricula */
            (SUBSTR(t1.TX_MSG, 51,30.)) AS matricula
      FROM WORK.TBL_TX_MSG_EXPS t1
      WHERE t1.CD_SNLC_MSG = 201;
QUIT;

PROC SQL;
   CREATE TABLE WORK.INTERACAO_BB AS 
   SELECT DISTINCT t2.mci, 
          t2.data, 
          /* hora */
            (ifn(t2.hora > '18:0:0't, ., t2.hora)) FORMAT=time8. AS hora
      FROM WORK.TBL_TX_MSG_EXPS t2
           LEFT JOIN LOCAL.feriados_nacionais t1 ON (t2.data = t1.Data)
      WHERE t1.Data IS MISSING AND ( t2.responsavel CONTAINS 'F' AND t2.responsavel NOT = 'F0000000' ) AND ( 
           t2.CD_SNLC_MSG IN 
           (
           0,
           1
           ) 
        AND t2.TX_MSG NOT CONTAINS 'Mensagem automática do sistema' 
        AND t2.TX_MSG NOT CONTAINS 'Bem-vindo ao Atendimento Digital BB')
        AND t2.hora > '0:0:0't;
QUIT;

PROC SQL;
   CREATE TABLE WORK.BASE_FALE AS 
   SELECT DISTINCT t1.mci, 
          t1.protocolo, 
          t1.matricula, 
          t2.matricula AS matricula_fechamento, 
          t1.data AS data_abertura, 
          t1.hora AS hora_abertura, 
          t2.data AS data_fechamento, 
          t2.hora AS hora_fechamento
      FROM WORK.TBL_TX_MSG_EXPS_1 t1
           LEFT JOIN WORK.PROTOC_FINAL t2 ON (t1.mci = t2.mci) AND (t1.protocolo = t2.protocolo)
      WHERE t1.dia_semana BETWEEN 2 AND 6;
QUIT;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_MENSAGEM_CLIENTE AS 
   SELECT DISTINCT t1.mci, 
          /* data */
            (MIN(t1.data)) FORMAT=DDMMYY10. AS data, 
          /* hora */
            (MIN(t1.hora)) FORMAT=TOD8. AS hora, 
          t2.protocolo AS protocolo
      FROM WORK.MENSAGEM_CLIENTE t1
           LEFT JOIN WORK.BASE_FALE t2 ON (t1.mci = t2.MCI)
      WHERE t1.data BETWEEN t2.data_abertura AND t2.data_fechamento AND t1.hora BETWEEN t2.hora_abertura AND 
           t2.hora_fechamento
      GROUP BY t1.mci,
               t2.protocolo;
QUIT;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_MENSAGEM_BB AS 
   SELECT DISTINCT t1.mci, 
          t1.responsavel, 
          t1.data, 
          t1.hora, 
          t2.protocolo, 
          t2.matricula, 
          t2.matricula_fechamento, 
          t2.data_abertura, 
          t2.hora_abertura, 
          t2.data_fechamento, 
          t2.hora_fechamento
      FROM WORK.MENSAGEM_BB t1
           INNER JOIN WORK.BASE_FALE t2 ON (t1.mci = t2.MCI)
      ORDER BY t1.mci,
               t1.data,
               t2.data_abertura;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TEMPO_APOS_PROTOCOLO_MCI AS 
   SELECT DISTINCT t1.mci, 
          t1.data, 
          t1.hora, 
          t2.data AS data_BB, 
          t2.hora AS hora_BB, 
          t1.protocolo
      FROM WORK.QUERY_FOR_MENSAGEM_CLIENTE t1, WORK.QUERY_FOR_MENSAGEM_BB t2
      WHERE (t1.mci = t2.mci AND t1.protocolo = t2.protocolo);
QUIT;

PROC SQL;
   CREATE TABLE WORK.TBL_MENSAGEM_CLIENTE_1 AS 
   SELECT DISTINCT t1.mci, 
          t1.data, 
          t1.hora, 
          t1.protocolo, 
          t2.data AS data_bb, 
          t2.hora AS hora_bb
      FROM WORK.QUERY_FOR_MENSAGEM_CLIENTE t1
           LEFT JOIN WORK.INTERACAO_BB t2 ON (t1.mci = t2.mci) AND (t1.data = t2.data)
      order by t1.mci, t1.protocolo, t1.data, t1.hora
            ;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TBL_TEMPO_RESPOSTA AS 
   SELECT DISTINCT t1.mci, 
          t1.protocolo, 
          t1.data, 
          t1.hora, 
          t1.data_bb, 
          /* hora_bb */
            (MIN(t1.hora_bb)) FORMAT=TIME8. AS hora_bb, 
          /* tempo_resposta */
            (t1.hora_bb - t1.hora) FORMAT=TOD8. AS tempo_resposta
      FROM WORK.TBL_MENSAGEM_CLIENTE_1 t1
      WHERE t1.data = t1.data_bb AND t1.hora_bb >= t1.hora
      GROUP BY t1.mci,
               t1.protocolo,
               t1.data,
               t1.hora,
               t1.data_bb,
               (CALCULATED tempo_resposta)
      ORDER BY t1.mci, t1.protocolo, t1.data, t1.hora, tempo_resposta asc;
QUIT;


/* Tabela Tempo de Resposta Final */
PROC SORT DATA=TBL_TEMPO_RESPOSTA 
	OUT=TBL_TEMPO_RESPOSTA_FIRST NODUPKEY;
	BY mci protocolo data hora data_bb;
RUN;

data dias_uteis_fale;
    set BASE_FALE;
    dif_dia_util_COM_FECHAMENTO = intck('weekday', data_abertura,data_fechamento);
	dif_dia_util_SEM_FECHAMENTO = intck('weekday', data_abertura,TODAY());
   run;

/* Junta para Relatório Detalhado- Tempo da Primeira Resposta */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_7 AS 
   SELECT distinct t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.HORA_INI, 
          t1.HORA_FIM, 
          t1.NR_PTL_ATDT_CLI, 
          t1.IND_PTL_ABTR, 
          t1.IND_PTL_ENCR, 
          t1.INRO_CLI_PTL, 
		  t1.TMP_EXTD_CLI,
		  t1.INRO_BB_PTL,
          t1.TMP_EXTD_BB,
		  t2.TEMPO_RESPOSTA format time. AS TMP_PRM_RSPT
      FROM WORK.REL_TRNL_FALECOM_6 t1
           LEFT JOIN WORK.TBL_TEMPO_RESPOSTA_FIRST t2 ON (t1.CD_CLI = t2.mci AND t1.NR_PTL_ATDT_CLI = t2.protocolo);
QUIT;


/*Retirada de senha GAT (mesmo dia do atendimento);*/
PROC SQL;

   CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
   CREATE TABLE GAT_PRESENCIAL AS

   SELECT DISTINCT
    
      NR_SLCT_ATDT,
	  CD_CLI,
	  CD_SNH_ATDT,
	  TS_INC_EPR,
	  TS_INC_ATDT,
      CD_EST_PTL_ATDT,
	  DT_HST_PTL_ATDT,
	  CD_UOR_SLCT

   FROM CONNECTION TO DB2
      (SELECT DISTINCT

      t1.NR_SLCT_ATDT,
	  t2.CD_CLI,
	  t2.CD_SNH_ATDT,
	  t1.TS_INC_EPR,
	  t1.TS_INC_ATDT,
	  t1.CD_EST_PTL_ATDT,
	  t1.DT_HST_PTL_ATDT,
	  t1.CD_UOR_SLCT

      FROM DB2GAT.HST_PTL_ATDT t1
	  INNER JOIN DB2GAT.HST_SLCT_ATDT t2 ON (t1.CD_UOR_SLCT = t2.CD_UOR_SLCT AND t1.NR_SLCT_ATDT = t2.NR_SLCT_ATDT AND t1.DT_HST_PTL_ATDT = t2.DT_HST_SLCT_ATDT)

	  WHERE t1.DT_HST_PTL_ATDT = &DT_PSC.
        AND t2.CD_CLI IS NOT NULL);

   DISCONNECT FROM DB2;

QUIT;

PROC SQL;
   CREATE TABLE IND_GAT_PRESENCIAL AS 
   SELECT t1.CD_CLI,
          t1.DT_HST_PTL_ATDT,
		  t1.CD_SNH_ATDT,
          /* IND_GAT */
            (COUNT(DISTINCT(t1.CD_CLI))) AS IND_GAT
      FROM GAT_PRESENCIAL t1
      GROUP BY t1.CD_CLI;
QUIT;

/*Junta para Relatório - Retirada de Senha Gat no Dia do Atendimento */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_8 AS 
   SELECT distinct t1.CD_CLI, 
          t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.TS_ABTR_PTL, 
          t1.TS_ECR_PTL, 
          t1.HORA_INI, 
          t1.HORA_FIM,
          (t1.HORA_FIM - t1.HORA_INI) FORMAT TIME. AS TMP_PTL,  
          t1.NR_PTL_ATDT_CLI, 
          t1.IND_PTL_ABTR, 
          t1.IND_PTL_ENCR, 
          t1.INRO_CLI_PTL, 
		  t1.TMP_EXTD_CLI,
		  t1.INRO_BB_PTL,
          t1.TMP_EXTD_BB,
		  t1.TMP_PRM_RSPT,
		  COALESCE (t2.IND_GAT, 0) AS IND_GAT,
		  t2.CD_SNH_ATDT AS SENHA
      FROM WORK.REL_TRNL_FALECOM_7 t1
           LEFT JOIN WORK.IND_GAT_PRESENCIAL t2 ON (t1.CD_CLI = t2.CD_CLI);
QUIT;


/* TABELA DE DETALHAMENTO FINAL - CLIENTES/PROTOCOLOS */
PROC SQL;
   CREATE TABLE WORK.REL_TRNL_FALECOM_9 AS 
   SELECT distinct t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
		  t1.CD_CLI, 
		  t1.NR_PTL_ATDT_CLI format commax25. AS PROTOCOLO, 
/*          t1.TS_ABTR_PTL, */
/*          t1.TS_ECR_PTL, */
          t1.HORA_INI, 
          t1.HORA_FIM,
		  t1.TMP_PTL,
		  IFC(t1.IND_PTL_ABTR = 1, 'Sim', 'Não') as PTL_ABTR, 
		  IFC(t1.IND_PTL_ENCR = 1, 'Sim', 'Não') as PTL_ENCR,
          t1.IND_PTL_ABTR,
		  t1.IND_PTL_ENCR,
          t1.INRO_CLI_PTL, 
		  t1.TMP_EXTD_CLI,
		  t1.INRO_BB_PTL,
          t1.TMP_EXTD_BB,
		  t1.TMP_PRM_RSPT,
		  t1.IND_GAT,
		  t1.SENHA
      FROM WORK.REL_TRNL_FALECOM_8 t1;
QUIT;

PROC STDIZE DATA=REL_TRNL_FALECOM_9 OUT=REL_DETALHE_PTL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;

/* MONTAR RELATORIO */
/* MONTAR RELATORIO */
/* MONTAR RELATORIO */
/* MONTAR RELATORIO */
/* MONTAR RELATORIO */


/* Qdt. Clientes por Carteira */
PROC SQL;
   CREATE TABLE QTD_CLI_CTRA AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          /* COUNT_DISTINCT_of_CD_CLI */
          (COUNT(DISTINCT(t1.CD_CLI))) AS QTD_CLI
      FROM WORK.REL_DETALHE_PTL t1
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR;
QUIT;


/* Qdt. Clientes atendidos por Carteira */
PROC SQL;
   CREATE TABLE QTD_CLI_ATDS AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          /* COUNT_DISTINCT_of_CD_CLI */
          (COUNT(DISTINCT(t1.CD_CLI))) AS QTD_CLI_ATDS
      FROM WORK.REL_DETALHE_PTL t1
	  WHERE IND_PTL_ABTR <> 0
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR;
QUIT;


/* Quantidade de Atendimentos (MCIs atendidos no dia, mesmo que sem protocolos finalizados);*/

/*****SUMARIZANDO A HIERARQUIA******/
/*****SUMARIZANDO A HIERARQUIA******/
/*****SUMARIZANDO A HIERARQUIA******/
/*****SUMARIZANDO A HIERARQUIA******/

PROC SQL;
   CREATE TABLE WORK.REL_SINTETICO_ATDT_PTL_CTRAS AS 
   SELECT distinct t1.PRF_SCDR AS PREFIXO, 
          t1.CTRA_SCDR AS CARTEIRA, 
		  t2.QTD_CLI,
		  t3.QTD_CLI_ATDS,
          (SUM(t1.IND_PTL_ABTR)) AS QTD_PTL_ABTR, 
          (SUM(t1.IND_PTL_ENCR)) AS QTD_PTL_ECR,
		  (AVG(t1.TMP_PTL)) FORMAT TIME. AS TMP_MED_PTL, 
		  (SUM(t1.INRO_CLI_PTL)) AS INRO_CLI_PTL,
		  (SUM(t1.INRO_BB_PTL))  AS INRO_BB_PTL,  
          (AVG(t1.TMP_EXTD_CLI))  FORMAT TIME. AS TMP_MED_EXTD_CLI,
          (AVG(t1.TMP_EXTD_BB))  FORMAT TIME. AS TMP_MED_EXTD_BB,
          (AVG(t1.TMP_PRM_RSPT)) FORMAT TIME. AS AVG_MED_PRM_RPST, 
		  (SUM(t1.IND_GAT)) AS TTL_ATDT_GAT
      FROM WORK.REL_DETALHE_PTL t1
	  LEFT JOIN QTD_CLI_CTRA t2 ON (t1.PRF_SCDR = t2.PRF_SCDR AND t1.CTRA_SCDR = t2.CTRA_SCDR)
	  LEFT JOIN QTD_CLI_ATDS t3 ON (t1.PRF_SCDR = t3.PRF_SCDR AND t1.CTRA_SCDR = t3.CTRA_SCDR)
      WHERE t1.IND_PTL_ABTR <> 0
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR
      ORDER BY t1.PRF_SCDR,
               t1.CTRA_SCDR;
QUIT;

PROC SQL;
   CREATE TABLE WORK.PREFIXO_9940_TOTAL AS 
   SELECT t1.PREFIXO,
          0 AS CARTEIRA, 
            (SUM(t1.QTD_CLI)) AS QTD_CLI,
		    (SUM(t1.QTD_CLI_ATDS)) AS QTD_CLI_ATDS, 
            (SUM(t1.QTD_PTL_ABTR)) AS QTD_PTL_ABTR, 
            (SUM(t1.QTD_PTL_ECR)) AS QTD_PTL_ECR, 
            (AVG(t1.TMP_MED_PTL)) FORMAT=TIME. AS TMP_MED_PTL, 
            (SUM(t1.INRO_CLI_PTL)) AS INRO_CLI_PTL, 
            (SUM(t1.INRO_BB_PTL)) AS INRO_BB_PTL, 
            (AVG(t1.TMP_MED_EXTD_CLI)) FORMAT=TIME. AS TMP_MED_EXTD_CLI, 
            (AVG(t1.TMP_MED_EXTD_BB)) FORMAT=TIME. AS TMP_MED_EXTD_BB, 
            (AVG(t1.AVG_MED_PRM_RPST)) FORMAT=TIME. AS AVG_MED_PRM_RPST, 
            (SUM(t1.TTL_ATDT_GAT)) AS TTL_ATDT_GAT
      FROM WORK.REL_SINTETICO_ATDT_PTL_CTRAS t1
      GROUP BY t1.PREFIXO;
QUIT;


PROC SQL;
   CREATE TABLE WORK.REL_DETALHE_PTL AS 
   SELECT distinct t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
		  t1.CD_CLI, 
		  t1.PROTOCOLO, 
          t1.HORA_INI, 
          t1.HORA_FIM,
		  t1.TMP_PTL,
		  t1.PTL_ABTR, 
		  t1.PTL_ENCR,
          t1.INRO_CLI_PTL, 
		  t1.TMP_EXTD_CLI,
		  t1.INRO_BB_PTL,
          t1.TMP_EXTD_BB,
		  t1.TMP_PRM_RSPT,
		  t1.IND_GAT,
		  t1.SENHA
      FROM WORK.REL_DETALHE_PTL t1
   where t1.PTL_ABTR = 'Sim';
QUIT;

DATA REL_SINTETICO_ATDT_PTL;
 SET PREFIXO_9940_TOTAL 
     REL_SINTETICO_ATDT_PTL_CTRAS;
RUN;


data REL_SINTETICO_ATDT_PTL;
format POSICAO yymmdd10.;
set REL_SINTETICO_ATDT_PTL;
POSICAO = diaUtilAnterior(TODAY());
run;


/*ENVIANDO PARA O RELATORIO - 0706 Fale Com CRBB 9940 - Visão Protocolos */

/*Rel   */

%LET Usuario=f6794004;
%LET Keypass=relatorio-protocolos-fale-com-crbb-9940-uvBprQSxI0QoCFmGO9gLD24TH23IODTNOMcUjfYbdCre02ZfM5;
%LET Rotina=relatorio-fale-com-crbb-9940-ptl;
%ProcessoIniciar();


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('REL_SINTETICO_ATDT_PTL', 'relatorio-protocolos-fale-com-crbb-9940');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('REL_DETALHE_PTL', 'detalhe');
   ;
QUIT;

%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);

PROC SQL;
   CREATE TABLE WORK.TABELA_RELATORIO_INRO AS 
   SELECT t2.PRF_SCDR, 
          t2.CTRA_SCDR,
          t1.DATA_INRO, 
          t1.HORA_INRO,
          t1.HORA_MIN,  
          t1.CD_CLI,
		  t1.protocolo,
		  t1.SeqN,
		  t1.responsavel,  
          t1.IN_INRO_BB
      FROM WORK.TBL_IND_INRO_BB_PTL_SEQL t1
	  inner join CLIENTES_ALVO t2 ON (t1.cd_cli = t2.cd_cli)
      WHERE t1.CD_CLI > 0
     ORDER BY t1.protocolo, t1.CD_CLI, t1.SeqN ;
QUIT;

PROC SQL;
   CREATE TABLE WORK.MCIS_ATENDIDOS AS 
   SELECT DISTINCT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.CD_CLI
      FROM WORK.TABELA_RELATORIO_INRO t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CLIENTES_NAO_ATENDIDOS AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR,
          t1.CD_CLI
      FROM WORK.CLIENTES_ALVO  t1
	  LEFT join MCIS_ATENDIDOS t2 ON (t1.cd_cli = t2.cd_cli)
      WHERE t2.cd_cli IS MISSING
     ORDER BY 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.QTD_CLIENTES_NAO_ATENDIDOS AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
		  99 AS HORA_TIPO,
/*		  'N/A' AS HORA,*/
          /* QTD_CLI */
          (COUNT(DISTINCT(t1.CD_CLI))) AS QTD_CLI_INRO_HORA,
          0 AS QTD_CLI_PTL_INRO_HORA, 
          0 AS QTD_INRO_HORA, 
          0 AS QTD_FUN_INRO_HORA, 
          0 AS QTD_PTL_INRO_HORA, 
          0 AS QTD_INRO_BB_HORA
      FROM WORK.CLIENTES_NAO_ATENDIDOS t1
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR;
QUIT;

PROC SQL;
   CREATE TABLE WORK.INRO_HORA_CLI AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR,
          t1.DATA_INRO, 
          t1.HORA_INRO, 
          /* QTD_CLI_INRO_HORA */
            (COUNT(DISTINCT(t1.CD_CLI))) AS QTD_CLI_INRO_HORA, 
          /* QTD_PTL_INRO_HORA */
            (COUNT(DISTINCT(t1.protocolo))) AS QTD_PTL_INRO_HORA, 
          /* QTD_INRO_HORA */
            (SUM(t1.IN_INRO_BB)) AS QTD_INRO_HORA
      FROM WORK.TABELA_RELATORIO_INRO t1
      WHERE t1.responsavel = 'CLIENTE'
      GROUP BY t1.PRF_SCDR, 
               t1.CTRA_SCDR,
               t1.DATA_INRO,
               t1.HORA_INRO;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TTL_INRO_CLI_HORA AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.DATA_INRO,
          100 AS HORA_INRO,
          /* QTD_CLI_INRO_HORA */
            (SUM(t1.QTD_CLI_INRO_HORA)) AS QTD_CLI_INRO_HORA, 
          /* QTD_PTL_INRO_HORA */
            (SUM(t1.QTD_PTL_INRO_HORA)) AS QTD_PTL_INRO_HORA, 
          /* QTD_INRO_HORA */
            (SUM(t1.QTD_INRO_HORA)) AS QTD_INRO_HORA
      FROM WORK.INRO_HORA_CLI t1
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR,
               t1.DATA_INRO;
QUIT;

DATA INRO_HORA_CLI_CTRA;
 SET INRO_HORA_CLI TTL_INRO_CLI_HORA;
RUN;

PROC SORT DATA=INRO_HORA_CLI_CTRA OUT=INRO_HORA_CLI_CTRA;
 BY PRF_SCDR CTRA_SCDR DATA_INRO HORA_INRO;
RUN;


PROC SQL;
   CREATE TABLE WORK.INRO_HORA_BB AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR,
          t1.DATA_INRO, 
          t1.HORA_INRO, 
          /* QTD_CLI_INRO_HORA */
            (COUNT(DISTINCT(t1.responsavel))) AS QTD_FUN_INRO_HORA, 
          /* QTD_PTL_INRO_HORA */
            (COUNT(DISTINCT(t1.protocolo))) AS QTD_PTL_INRO_HORA, 
          /* QTD_INRO_HORA */
            (SUM(t1.IN_INRO_BB)) AS QTD_INRO_HORA
      FROM WORK.TABELA_RELATORIO_INRO t1
      WHERE t1.responsavel <> 'CLIENTE'
      GROUP BY t1.PRF_SCDR, 
               t1.CTRA_SCDR,
               t1.DATA_INRO,
               t1.HORA_INRO;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TTL_INRO_HORA_BB AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.DATA_INRO,
          100 AS HORA_INRO,
          /* QTD_CLI_INRO_HORA */
            (SUM(t1.QTD_FUN_INRO_HORA)) AS QTD_FUN_INRO_HORA, 
          /* QTD_PTL_INRO_HORA */
            (SUM(t1.QTD_PTL_INRO_HORA)) AS QTD_PTL_INRO_HORA, 
          /* QTD_INRO_HORA */
            (SUM(t1.QTD_INRO_HORA)) AS QTD_INRO_HORA
      FROM WORK.INRO_HORA_BB t1
      GROUP BY t1.PRF_SCDR,
               t1.CTRA_SCDR,
               t1.DATA_INRO;
QUIT;


DATA INRO_HORA_BB_CTRA;
 SET INRO_HORA_BB TTL_INRO_HORA_BB;
RUN;

PROC SORT DATA=INRO_HORA_BB_CTRA OUT=INRO_HORA_BB_CTRA;
 BY PRF_SCDR CTRA_SCDR DATA_INRO HORA_INRO;
RUN;

PROC SQL;
   CREATE TABLE PREFIXO_CTRA AS 
   SELECT DISTINCT t1.PRF_SCDR, 
          t1.CTRA_SCDR
      FROM WORK.TABELA_RELATORIO_INRO t1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.PREFIXO_CTRA_HORA AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t2.ID, 
          t2.HORA
      FROM WORK.PREFIXO_CTRA t1,LOCAL.DOMINIO_HORA t2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SINTETICO_REL_POR_HORA AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.ID AS HORA_TIPO, 
/*        t1.HORA, */
          t2.QTD_CLI_INRO_HORA, 
          t2.QTD_PTL_INRO_HORA AS QTD_CLI_PTL_INRO_HORA, 
          t2.QTD_INRO_HORA, 
          t3.QTD_FUN_INRO_HORA, 
          t3.QTD_PTL_INRO_HORA, 
          t3.QTD_INRO_HORA AS QTD_INRO_BB_HORA
      FROM WORK.PREFIXO_CTRA_HORA t1
           LEFT JOIN WORK.INRO_HORA_CLI_CTRA t2 ON (t1.PRF_SCDR = t2.PRF_SCDR) AND (t1.CTRA_SCDR = t2.CTRA_SCDR) AND 
          (t1.ID = t2.HORA_INRO)
           LEFT JOIN WORK.INRO_HORA_BB_CTRA t3 ON (t1.PRF_SCDR = t3.PRF_SCDR) AND (t1.CTRA_SCDR = t3.CTRA_SCDR) AND 
          (t1.ID = t3.HORA_INRO)
    where t1.ID <> 99 ;		  
QUIT;







DATA SINTETICO_REL_POR_HORA_FINAL;
   SET  SINTETICO_REL_POR_HORA QTD_CLIENTES_NAO_ATENDIDOS;
RUN; 

PROC STDIZE DATA=SINTETICO_REL_POR_HORA_FINAL OUT=SINTETICO_REL_POR_HORA_FINAL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;

PROC SORT DATA=SINTETICO_REL_POR_HORA_FINAL OUT=SINTETICO_REL_FALECOM_FINAL;
 BY PRF_SCDR CTRA_SCDR HORA_TIPO;
RUN;

PROC SQL;
   CREATE TABLE WORK.SUMARIZAR_CTRA_0 AS 
   SELECT t1.PRF_SCDR, 
          0 AS CTRA_SCDR, 
          t1.HORA_TIPO, 
          /* QTD_CLI_INRO_HORA */
            (SUM(t1.QTD_CLI_INRO_HORA)) AS QTD_CLI_INRO_HORA, 
          /* QTD_CLI_PTL_INRO_HORA */
            (SUM(t1.QTD_CLI_PTL_INRO_HORA)) AS QTD_CLI_PTL_INRO_HORA, 
          /* QTD_INRO_HORA */
            (SUM(t1.QTD_INRO_HORA)) AS QTD_INRO_HORA, 
          /* QTD_FUN_INRO_HORA */
            (SUM(t1.QTD_FUN_INRO_HORA)) AS QTD_FUN_INRO_HORA, 
          /* QTD_PTL_INRO_HORA */
            (SUM(t1.QTD_PTL_INRO_HORA)) AS QTD_PTL_INRO_HORA, 
          /* QTD_INRO_BB_HORA */
            (SUM(t1.QTD_INRO_BB_HORA)) AS QTD_INRO_BB_HORA
      FROM WORK.SINTETICO_REL_FALECOM_FINAL t1
      WHERE t1.HORA_TIPO = 100
      GROUP BY t1.PRF_SCDR,
               t1.HORA_TIPO;
QUIT;

DATA SINTETICO_REL_POR_HORA_FINAL;
   SET  SINTETICO_REL_FALECOM_FINAL SUMARIZAR_CTRA_0;
RUN;

PROC STDIZE DATA=SINTETICO_REL_POR_HORA_FINAL OUT=SINTETICO_REL_POR_HORA_FINAL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;

PROC SORT DATA=SINTETICO_REL_POR_HORA_FINAL OUT=SINTETICO_REL_FALECOM_FINAL;
 BY PRF_SCDR CTRA_SCDR HORA_TIPO;
RUN;


data SINTETICO_REL_FALECOM_FINAL;
format POSICAO yymmdd10.;
set SINTETICO_REL_FALECOM_FINAL;
POSICAO = diaUtilAnterior(TODAY());
run;

PROC SQL;
   CREATE TABLE WORK.REL_DET_FINAL AS 
   SELECT t1.PRF_SCDR, 
          t1.CTRA_SCDR, 
          t1.CD_CLI, 
          t1.protocolo AS PROTOCOLO, 
          t1.DATA_INRO FORMAT=DDMMYY10. AS DATA_INRO, 
          t2.HORA, 
          t1.HORA_MIN AS HHMMSS, 
          t1.SeqN AS SEQL_MSG, 
          t1.responsavel AS RESPONSAVEL, 
          t1.IN_INRO_BB AS QTD_INRO
      FROM WORK.TABELA_RELATORIO_INRO t1
           LEFT JOIN LOCAL.DOMINIO_HORA t2 ON (t1.HORA_INRO = t2.ID)
      ORDER BY t1.protocolo,
               t1.SeqN;
QUIT;

PROC SQL;
   CREATE TABLE DOMINIO_HORA AS 
   SELECT DISTINCT t1.ID, 
          t1.HORA FORMAT=$UTF8XE15. AS HORA
      FROM LOCAL.DOMINIO_HORA t1;
QUIT;

/*ENVIANDO PARA O RELATORIO - FALE COM VISÃO POR HORA*/

%LET Usuario=f6794004;
%LET Keypass=relatorio-falecom-crbb-9940-3Tjyyt4Qsex4ZAlFdQ0t3OZHqTQ9AP7y6zVpdnpJ4o9zarZurz;
%LET Rotina=relatorio-falecom-crbb-9940;
%ProcessoIniciar();


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL_2;
	CREATE TABLE TABELAS_EXPORTAR_REL_2 (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL_2 VALUES('SINTETICO_REL_FALECOM_FINAL', 'relatorio-falecom-crbb-9940');
	INSERT INTO TABELAS_EXPORTAR_REL_2 VALUES('REL_DET_FINAL', 'detalhe');
	INSERT INTO TABELAS_EXPORTAR_REL_2 VALUES('DOMINIO_HORA', 'hora');

   ;
QUIT;


/**/
%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL_2);


/*PROCESSO DE  CHECK-OUT*/
 
%processCheckOut(
    uor_resp = 341556
    ,funci_resp = 'F6794004'
    ,tipo = Indicador
    ,sistema = Indicador
    ,rotina = Novos Clientes PJ (180)
    ,mailto= &EmailsCheckOut.
);




/*	- Contratação de CDC Líquido - CDC Empréstimo (PRD 52 Todas as Modalidades) */



/* 
**********   RELATÓRIO NEGOCIAL   **********
**********   RELATÓRIO NEGOCIAL   **********
**********   RELATÓRIO NEGOCIAL   **********
**********   RELATÓRIO NEGOCIAL   **********
**********   RELATÓRIO NEGOCIAL   **********
**********   RELATÓRIO NEGOCIAL   **********

	- Contratação de CDC Líquido - CDC Empréstimo (PRD 52 Todas as Modalidades) - CANAL DE CONTRATACAO CRBB SISBB/PLATAFORMA somente funcis alocados no 9940 - */
/**/
/*PROC SQL;*/
/*   CREATE TABLE CDC_CONTRATACAO_PRD52_2019 AS */
/*   SELECT t1.**/
/*      FROM CDC.CDC_CONTRATACAO_CDC t1*/
/*      WHERE t1.DT_FRMZ_CTR_CDC >= '1Jan2019'd AND t1.CD_PRD_LNCD = 52;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE PBCO_ALVO_CDC AS */
/*   SELECT t1.CD_CLI, */
/*          t1.CD_PRF_SCDR, */
/*          t1.NR_SEQL_CTRA_SCDR, */
/*          t1.CD_PRF_PRMR, */
/*          t1.NR_SEQL_CTRA_PRMR, */
/*          t1.CD_PAB, */
/*          COALESCE(t2.CD_PRF_DEPE_RSP, 0) AS CD_PRF_DEPE_RSP, */
/*          COALESCE(t2.NR_CTR_OPR, 0) AS NR_CTR_OPR,*/
/*          COALESCE(t2.CD_PRD_LNCD, 0) AS CD_PRD_LNCD, */
/*          COALESCE(t2.CD_MDLD_PRD_LNCD, 0) AS CD_MDLD_PRD_LNCD, */
/*          COALESCE(t2.CD_LNCD, 0) AS CD_LNCD, */
/*          COALESCE(t2.CD_EST_ATU_CTR, 0) AS CD_EST_ATU_CTR, */
/*          t2.DT_FRMZ_CTR_CDC, */
/*          t2.DT_LIB_CRD_CTR, */
/*          t2.DT_VNCT_PCL, */
/*          t2.DT_EST_ATU_CTR, */
/*          t2.DT_FIM_CTR_CDC, */
/*          COALESCE(t2.VL_TTL_FNCD_CTR, 0) AS VL_TTL_FNCD_CTR, */
/*          COALESCE(t2.VL_IOF_FNCD_CTR, 0) AS VL_IOF_FNCD_CTR, */
/*          COALESCE(t2.VLR_TOT_DESEMBOLSO, 0) AS VLR_TOT_DESEMBOLSO, */
/*          COALESCE(t2.VL_INC_PCL_CTR, 0) AS VL_INC_PCL_CTR, */
/*          COALESCE(t2.VL_SDO_DVDR, 0) AS VL_SDO_DVDR, */
/*          COALESCE(t2.QT_PCL_CTR, 0) AS QT_PCL_CTR, */
/*          COALESCE(t2.PC_JUR_CTR, 0) AS PC_JUR_CTR, */
/*          COALESCE(t2.NR_CTR_CVN, 0) AS NR_CTR_CVN, */
/*          t2.SG_SIS_OGM_CTR, */
/*          COALESCE(t2.CD_PRF_DEPE, 0) AS CD_PRF_DEPE, */
/*          COALESCE(t2.NR_MTC_LOG, 0) AS NR_MTC_LOG, */
/*          COALESCE(t2.CD_TIP_CNL_CTR, 0) AS CD_TIP_CNL_CTR, */
/*          COALESCE(t2.vlr_renovado, 0) AS VLR_RENOVADO, */
/*          COALESCE(t2.vlr_troco, 0) AS VLR_TROCO,*/
/*	      /* VL_LIQD_CDC */*/
/*          (CASE WHEN  VLR_TROCO = 0 THEN VLR_TOT_DESEMBOLSO */
/*             ELSE VLR_TROCO*/
/*           END) AS VL_LIQD_CDC*/
/*      FROM CLIENTES_ALVO t1*/
/*           LEFT JOIN CDC_CONTRATACAO_PRD52_2019 t2 ON (t1.CD_CLI = t2.CD_CLI);*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	 CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);*/
/*		CREATE TABLE PRD_MDLD AS */
/*		SELECT * FROM CONNECTION TO DB2*/
/*		   (SELECT DISTINCT */
/*                 t1.CD_PRD, */
/*		         t1.CD_MDLD, */
/*		         t1.NM_MDLD, */
/*		         t1.CD_EST_MDLD*/
/*		      FROM DB2PRD.MDLD_PRD t1*/
/*		     WHERE t1.CD_PRD = 52 */
/*               AND t1.CD_EST_MDLD = 'A');*/
/*	 DISCONNECT FROM DB2;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*   CREATE TABLE PBCO_ALVO_CDC_LIQD AS */
/*   SELECT DISTINCT t1.CD_CLI, */
/*          t1.CD_PRF_SCDR, */
/*          t1.NR_SEQL_CTRA_SCDR, */
/*          t1.CD_PRF_PRMR, */
/*          t1.NR_SEQL_CTRA_PRMR, */
/*          t1.CD_PAB, */
/*          t1.CD_PRF_DEPE_RSP, */
/*          t1.NR_CTR_OPR, */
/*          t1.CD_PRD_LNCD,*/
/*		 (CASE WHEN t1.CD_PRD_LNCD <> 0 */
/*             THEN 'CDC EMPRÉSTIMO'*/
/*             ELSE ''*/
/*          END) AS NM_PRD,*/
/*          t1.CD_MDLD_PRD_LNCD,*/
/*          t2.NM_MDLD, */
/*          t1.DT_FRMZ_CTR_CDC, */
/*          t1.DT_LIB_CRD_CTR, */
/*          t1.DT_FIM_CTR_CDC, */
/*          t1.CD_PRF_DEPE AS CD_PRF_DEPE_ATDT, */
/*          t1.SG_SIS_OGM_CTR, */
/*          t1.CD_TIP_CNL_CTR, */
/*          t1.VL_LIQD_CDC*/
/*      FROM PBCO_ALVO_CDC t1*/
/*          LEFT JOIN PRD_MDLD t2 */
/*            ON (t1.CD_PRD_LNCD = t2.CD_PRD AND t1.CD_MDLD_PRD_LNCD = t2.CD_MDLD);*/
/*QUIT;*/
/**/
/**/
/*/*    - Contratação de Seguridade  - Ourocap, Vida, Patrimônio, Auto e Brasilprev*/*/
/**/
/*/*	- Cancelamento de Seguridade - Ourocap, Vida, Patrimônio, Auto e Brasilprev*/*/
/**/
/*/*	- Contratação ou Upgrade de Pacote de Serviços*/*/
/**/
/*/*	- Contratação de Combo Digital*/*/
/**/
/*/*	- Cancelamento de Pacote de Serviços*/*/
