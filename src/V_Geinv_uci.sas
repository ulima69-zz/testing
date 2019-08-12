
%include '/dados/infor/suporte/FuncoesInfor.sas';


DATA _NULL_;
	DATA_INICIO = '01Jan2017'd;
	DATA_FIM = '30Dec2018'd;
	DATA_REFERENCIA = diaUtilAnterior(TODAY());
	D1 = diaUtilAnterior(TODAY());
	D2 = diaUtilAnterior(D1);
	D3 = diaUtilAnterior(D2);
	MES_ATU = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));
	MES_ANT = Put(INTNX('month',primeiroDiaUtilMes(D1),-1), yymmn6.) ;
	MES_G = Put(DATA_REFERENCIA, MONTH.) ;
	ANOMES = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));
	DT_INICIO_SQL="'"||put(DATA_INICIO, YYMMDDD10.)||"'";
	DT_D1_SQL="'"||put(D1, YYMMDDD10.)||"'";
	DT_1DIA_MES_SQL="'"||put(primeiroDiaUtilMes(D1), YYMMDDD10.)||"'";
	DT_ANOMES_SQL=primeiroDiaUtilMes(D1);
	PRIMEIRO_DIA_MES_SQL="'"||put(primeiroDiaMes(DATA_REFERENCIA), YYMMDDD10.)||"'";
	DT_FIXA_SQL="'"||put(MDY(01,01,2017), YYMMDDD10.)||"'";
	ANO_FIXO_SQL="'"||put(MDY(01,01,2018), YYMMDDD10.)||"'";

	CALL SYMPUT('DATA_HOJE',COMPRESS(TODAY(),' '));
	CALL SYMPUT('DT_1DIA_MES',COMPRESS(primeiroDiaUtilMes(D1),' '));
	CALL SYMPUT('DATA_INICIO',COMPRESS(DATA_INICIO,' '));
	CALL SYMPUT('DATA_FIM',COMPRESS(DATA_FIM,' '));
	CALL SYMPUT('D1',COMPRESS(D1,' '));
	CALL SYMPUT('D2',COMPRESS(D2,' '));
	CALL SYMPUT('D3',COMPRESS(D3,' '));
	CALL SYMPUT('MES_ATU',COMPRESS(MES_ATU,' '));
	CALL SYMPUT('MES_ANT',COMPRESS(MES_ANT,' '));
	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));
	CALL SYMPUT('RF',COMPRESS(ANOMES,' '));
	CALL SYMPUT('DT_ARQUIVO',put(DATA_REFERENCIA, DDMMYY10.));
	CALL SYMPUT('DT_ARQUIVO_SQL',put(DATA_REFERENCIA, YYMMDDD10.));
	CALL SYMPUT('DT_INICIO_SQL', COMPRESS(DT_INICIO_SQL,' '));
	CALL SYMPUT('DT_1DIA_MES_SQL', COMPRESS(DT_1DIA_MES_SQL,' '));
	CALL SYMPUT('DT_D1_SQL', COMPRESS(DT_D1_SQL,' '));
	CALL SYMPUT('DT_ANOMES_SQL', COMPRESS(DT_ANOMES_SQL,' '));
	CALL SYMPUT('MES_G', COMPRESS(MES_G,' '));
	CALL SYMPUT('PRIMEIRO_DIA_MES_SQL', COMPRESS(PRIMEIRO_DIA_MES_SQL,' '));
	CALL SYMPUT('DT_FIXA_SQL', COMPRESS(DT_FIXA_SQL,' '));
	CALL SYMPUT('ANO_FIXO_SQL', COMPRESS(ANO_FIXO_SQL,' '));
RUN;


LIBNAME DB2RCA DB2 DATABASE=BDB2P04 SCHEMA=DB2RCA AUTHDOMAIN='DB2SGCEN' ; 
LIBNAME DB2REL DB2 DATABASE=BDB2P04 SCHEMA=DB2REL AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2MCI DB2 DATABASE=BDB2P04 SCHEMA=DB2MCI AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2PRD DB2 DATABASE=BDB2P04 SCHEMA=DB2PRD AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2RDO DB2 DATABASE=BDB2P04 SCHEMA=DB2RDO AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2BIC DB2 DATABASE=BDB2P04 SCHEMA=DB2BIC AUTHDOMAIN='DB2SGCEN' ; 
LIBNAME DB2ARH DB2 DATABASE=BDB2P04 SCHEMA=DB2ARH AUTHDOMAIN='DB2SGCEN' ; 
LIBNAME DB2ITR db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ITR 	database=BDB2P04;  






LIBNAME GEINV "/dados/infor/producao/Geinv";
LIBNAME PUBLICA "/dados/publica/b_dados"; 
/*LIBNAME DWH "/dados/uci/restrito/infor/dwh";*/

/*PÚBLICO*/
/**/





%Macro Encarteiramento;

    PROC SQL;
        CREATE TABLE ENCARTEIRAMENTO AS
            SELECT Put(CD_PRF_DEPE, Z4.) AS PrefDep,
                NR_SEQL_CTRA_atb as carteira,
                case when NR_SEQL_CTRA_atb = 7002 then 700 else CD_TIP_CTRA end as tc,
                E.CD_CLI
            FROM COMUM.PAI_REL_&anomes E
                INNER JOIN BASE_MCI A ON(E.CD_CLI=A.CD_CLI)
         
                    ORDER BY 4;
    QUIT;

    PROC SQL NOPRINT;
        SELECT COUNT(*) INTO: X
            FROM (SELECT CD_CLI
            FROM ENCARTEIRAMENTO
                GROUP BY 1
                    HAVING COUNT(*)>1);
    QUIT;

    %Put &X;

    %IF &X>0 %THEN
        %DO;

            DATA DUPLICADOS(DROP=CARTEIRA TC);
                SET ENCARTEIRAMENTO(Obs=0);
            RUN;

            PROC SQL;
                CREATE TABLE AUX_D AS
                    SELECT CD_CLI
                        FROM ENCARTEIRAMENTO
                            GROUP BY 1
                                HAVING COUNT(*)>1;
            QUIT;

            DATA AUX_D(DROP=Seq);
                SET AUX_D;
                Seq+1;
                Grupo=CEIL(Seq/5957);
            RUN;

            PROC SQL NOPRINT;
                SELECT MAX(Grupo) INTO: Q
                    FROM AUX_D;
            QUIT;

            %PUT &Q;

            %DO I=1 %TO &Q;

                PROC SQL NOPRINT;
                    SELECT CD_CLI INTO: Var Separated By ', '
                        FROM AUX_D
                            WHERE Grupo=&I;
                QUIT;

                PROC SQL;
                    CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
                    INSERT INTO DUPLICADOS
                        SELECT COD_PREF_AGEN, COD
                            FROM CONNECTION TO DB2
                                (SELECT COD, COD_PREF_AGEN
                                    FROM DB2MCI.CLIENTE
                                        WHERE COD IN(&Var)
                                            ORDER BY COD;);
                    DISCONNECT FROM DB2;
                QUIT;

                PROC SQL;
                    CREATE TABLE FIM_DUP AS
                        SELECT A.*, CARTEIRA, TC
                            FROM DUPLICADOS A
                                INNER JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI AND A.PrefDep=B.PrefDep)
                                    ORDER BY 2;
                    DELETE FROM DUPLICADOS;
                QUIT;

                DATA ENCARTEIRAMENTO;
                    SET ENCARTEIRAMENTO(WHERE=(CD_CLI NOT IN(&Var.))) FIM_DUP;
                    BY CD_CLI;
                RUN;

            %END;
        %END;

    PROC DELETE DATA=FIM_DUP AUX_D DUPLICADOS;
    RUN;

    PROC SQL NOPRINT;
        SELECT COUNT(*) INTO: X
            FROM (SELECT DISTINCT A.CD_CLI
            FROM BASE_MCI A
                LEFT JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI)
                    WHERE B.CD_CLI Is Missing);
    QUIT;

    %Put &X;

    %IF &X>0 %THEN
        %DO;

            DATA PERDIDOS;
                SET ENCARTEIRAMENTO(Obs=0);
            RUN;

            PROC SQL;
                CREATE TABLE AUX_P AS
                    SELECT DISTINCT A.CD_CLI
                        FROM BASE_MCI A
                            LEFT JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI)
                                WHERE B.CD_CLI Is Missing;
            QUIT;

            DATA AUX_P(DROP=Seq);
                SET AUX_P;
                Seq+1;
                Grupo=CEIL(Seq/5957);
            RUN;

            PROC SQL NOPRINT;
                SELECT MAX(Grupo) INTO: Q
                    FROM AUX_P;
            QUIT;

            %Put &Q;

            %DO I=1 %TO &Q;

                PROC SQL NOPRINT;
                    SELECT CD_CLI Format 9. INTO: Var Separated By ', '
                        FROM AUX_P
                            WHERE Grupo=&I;
                QUIT;

                PROC SQL;
                    CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
                    INSERT INTO PERDIDOS
                        SELECT COD_PREF_AGEN, 7002, 700, COD
                            FROM CONNECTION TO DB2
                                (SELECT COD, COD_PREF_AGEN,
                                    7002 AS CARTEIRA, 700 AS TC
                                FROM DB2MCI.CLIENTE
                                    WHERE COD IN(&Var)
                                        ORDER BY COD;);
                    DISCONNECT FROM DB2;
                QUIT;

            %END;

            PROC SORT DATA=PERDIDOS;
                BY CD_CLI;
            RUN;

            DATA ENCARTEIRAMENTO;
                SET ENCARTEIRAMENTO PERDIDOS;
                BY CD_CLI;
            RUN;

            PROC DELETE DATA=AUX_P PERDIDOS;
            RUN;

        %END;
%Mend;




/**/
/**/
/**/
/**/
/*PROC SQL;*/
/*	connect to db2 (authdomain=db2sgcen database=bdb2p04);*/
/*   CREATE TABLE WORK.OCUPACAO AS */
/*   SELECT DISTINCT */
/*		  F_PESSFISI_CLIENTE, */
/*          COD,*/
/*		  TXT_MASC*/
/*from connection to db2(	*/
/*select distinct	*/
/*         t1.F_PESSFISI_CLIENTE, */
/*          t1.COD,*/
/*		  t3.TXT_MASC*/
/*      FROM DB2MCI.OCUPACAO t1*/
/*	  INNER JOIN DB2REL.CLI_CTRA T2 ON (t1.F_PESSFISI_CLIENTE=T2.CD_CLI)*/
/*	  INNER JOIN DB2MCI.TAB_OCUPACAO t3 on (t1.cod=t3.cod)*/
/*	  */
/*WHERE t1.IND_OCUP_PRIN = 'S'*/
/**/
/*	);*/
/*	disconnect from db2*/
/**/
/*;*/
/*QUIT;*/
/**/
/**/


/*******************************************************************************/
/*******************************************************Saldo em Investimentos*/

%_eg_conditional_dropds(WORK.QUERY_FOR_QSTN_CLI);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QSTN_CLI AS 
   SELECT t1.CD_CLI, 
          t1.CD_PRFL, 
          t1.CD_TIP_PRFL, 
          t1.TS_INCL_QSTN_CLI, 
          t1.DT_CNCT_QSTN_CLI, 
          t1.DT_VNCT_QSTN_CLI, 
          t1.CD_EST_QSTN_CLI, 
          /* ESTADO */
            (case
            when t1.CD_EST_QSTN_CLI = 1 then "Pendente de liberacao"
            when t1.CD_EST_QSTN_CLI = 2 then "Vigente"
            when t1.CD_EST_QSTN_CLI = 3 then "A Vencer"
            when t1.CD_EST_QSTN_CLI = 4 then "Expirado"
            when t1.CD_EST_QSTN_CLI = 5 then "Substituido"
            when t1.CD_EST_QSTN_CLI = 6 then "Substituido pendente"
            end) AS ESTADO
      FROM DB2RCA.QSTN_CLI t1
		  INNER JOIN GEINV.base T2 ON (T1.cd_cli=T2.mci)
		  GROUP BY 1
		  ORDER BY 1;
QUIT;
PROC SORT DATA=QUERY_FOR_QSTN_CLI NODUPKEY; BY _ALL_; RUN;
/* --- End of code for "Query Builder". --- */

/* --- Start of code for "MAX". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_QSTN_CLI_0001);


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QSTN_CLI_0001(label="QUERY_FOR_QSTN_CLI") AS 
   SELECT t1.CD_CLI, 
          /* MAX_of_TS_INCL_QSTN_CLI */
            (MAX(t1.TS_INCL_QSTN_CLI)) FORMAT=DATETIME25.6 AS MAX_of_TS_INCL_QSTN_CLI
      FROM WORK.QUERY_FOR_QSTN_CLI t1
	    GROUP BY 1
		  ORDER BY 1;
QUIT;
/* --- End of code for "MAX". --- */

/* --- Start of code for "DADOS". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_QSTN_CLI_0002);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QSTN_CLI_0002(label="QUERY_FOR_QSTN_CLI") AS 
   SELECT t2.CD_CLI, 
          t2.CD_PRFL, 
          t2.CD_TIP_PRFL, 
          t2.TS_INCL_QSTN_CLI, 
          t2.DT_CNCT_QSTN_CLI, 
          t2.DT_VNCT_QSTN_CLI, 
          t2.CD_EST_QSTN_CLI, 
          t2.ESTADO
      FROM WORK.QUERY_FOR_QSTN_CLI_0001 t1
           LEFT JOIN WORK.QUERY_FOR_QSTN_CLI t2 ON (t1.CD_CLI = t2.CD_CLI) AND (t1.MAX_of_TS_INCL_QSTN_CLI = 
          t2.TS_INCL_QSTN_CLI)
		    GROUP BY 1
		  ORDER BY 1
 ;
QUIT;
/* --- End of code for "DADOS". --- */

/* --- Start of code for "Query Builder3". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_QSTN_CLI_0000);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QSTN_CLI_0000 AS 
   SELECT t1.CD_CLI, 
          t1.CD_PRFL, 
          t1.CD_TIP_PRFL, 
          t2.TX_DCR_PRFL, 
          t1.ESTADO AS API
      FROM WORK.QUERY_FOR_QSTN_CLI_0002 t1
           LEFT JOIN DB2RCA.PRFL t2 ON (t1.CD_PRFL = t2.CD_PRFL) AND (t1.CD_TIP_PRFL = t2.CD_TIP_PRFL)
	      ORDER BY t1.CD_CLI;
QUIT;
/* --- End of code for "Query Builder3". --- */

/* --- Start of code for "Query Builder1". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_PRD_INVS_CLI);


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_PRD_INVS_CLI AS 
   SELECT t1.CD_CLI, 
          t1.CD_PRD_ATI, 
          t1.CD_MDLD_ATI, 
          t1.TX_SUB_MDLD_ATI, 
          t1.DT_VRF_PRD_INVS, 
          t1.VL_SDO_PRD_INVS, 
          t1.SG_SIS_DTTR_INF, 
          t1.VL_DIAR_APL
      FROM DB2RCA.PRD_INVS_CLI t1
	  INNER JOIN GEINV.base T2 ON (T1.cd_cli=T2.mci)
      WHERE t1.VL_SDO_PRD_INVS > 0 
	  group by 1
      ORDER BY t1.CD_CLI;
QUIT;
PROC SORT DATA=QUERY_FOR_PRD_INVS_CLI NODUPKEY; BY _ALL_; RUN;
/* --- End of code for "Query Builder1". --- */


/* --- Start of code for "Query Builder21". --- */
%_eg_conditional_dropds(WORK.QUERY1);

PROC SQL;
   CREATE TABLE WORK.QUERY1 AS 
   SELECT t1.CD_CLI, 
          t1.CD_PRD_ATI, 
          t1.CD_MDLD_ATI, 
          t1.DT_VRF_PRD_INVS, 
          t1.VL_SDO_PRD_INVS, 
          t1.SG_SIS_DTTR_INF, 
          t1.VL_DIAR_APL
      FROM WORK.QUERY_FOR_PRD_INVS_CLI t1
           LEFT JOIN DB2PRD.MDLD_PRD t2 ON (t1.CD_PRD_ATI = t2.CD_PRD) AND (t1.CD_MDLD_ATI = t2.CD_MDLD)
		   GROUP BY 1,2,3
      ORDER BY t1.CD_CLI,
               t1.CD_PRD_ATI,
               t1.CD_MDLD_ATI;
QUIT;
/* --- End of code for "Query Builder21". --- */


/* --- Start of code for "RCA_SALDO". --- */



PROC SQL;
   CREATE TABLE RCA_API_SALDO AS 
   SELECT t1.CD_CLI,
          (CASE WHEN t1.SG_SIS_DTTR_INF = "BPR" THEN "PREVIDENCIA"
/*				WHEN t1.SG_SIS_DTTR_INF = "CAC" THEN "LETRAS DE CREDITO"*/
	            WHEN t1.SG_SIS_DTTR_INF = "CPR" THEN "POUPANCA"
				when t1.SG_SIS_DTTR_INF = "CAC" and t1.CD_MDLD_ATI = 19 then "LCA" 
                when t1.SG_SIS_DTTR_INF = "CAC" and t1.CD_MDLD_ATI = 17 then "LCI" 
	            WHEN t1.SG_SIS_DTTR_INF = "GFI" THEN "FUNDOS DE INVESTIMENTO"
	            WHEN t1.SG_SIS_DTTR_INF = "RDO" THEN "DEPOSITO A PRAZO"
				WHEN t1.SG_SIS_DTTR_INF = "TDR" THEN "TESOURO DIRETO"
				ELSE "OUTROS" END) AS ORIGEM,
          t1.CD_PRD_ATI, 
          t1.CD_MDLD_ATI,
          t1.DT_VRF_PRD_INVS, 
          t1.VL_SDO_PRD_INVS, 
          t1.SG_SIS_DTTR_INF, 
          t1.VL_DIAR_APL, 
          t2.CD_PRFL, 
          t2.CD_TIP_PRFL, 
          (CASE WHEN t2.API IS MISSING THEN "INEXISTENTE" ELSE t2.API END) AS API, 
          (CASE WHEN t2.CD_PRFL = 0 THEN "NAO RESPONDIDO"
				WHEN t2.CD_PRFL = 1 THEN "Conservador"
	            WHEN t2.CD_PRFL = 2 THEN "Moderado"
	            WHEN t2.CD_PRFL = 3 THEN "Arrojado"
	            WHEN t2.CD_PRFL = 4 THEN "Agressivo"
            	ELSE "SEM PERFIL" END) AS TX_DCR_PRFL
      FROM WORK.QUERY1 t1
           LEFT JOIN WORK.QUERY_FOR_QSTN_CLI_0000 t2 ON (t1.CD_CLI = t2.CD_CLI)
		   WHERE t1.VL_SDO_PRD_INVS > 0 
		   GROUP BY 1
 ;
QUIT;


/* --- End of code for "RCA_SALDO". --- */

/* --- Start of code for "RCA_ENQ". --- */

PROC SQL;
   CREATE TABLE RCA_API_ENQUADRAMENTO AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.CD_PRFL, 
          t1.TX_DCR_PRFL, 
          t1.CD_TIP_PRFL, 
          /* TX_DCR_TIP_PRFL */
            (CASE WHEN t4.TX_DCR_TIP_PRFL IS MISSING THEN "SEM PERFIL" ELSE t4.TX_DCR_TIP_PRFL END) AS TX_DCR_TIP_PRFL, 
          t1.API, 
          t2.CD_CLS_PRD_CRS, 
          /* TX_DCR_CLS_PRD */
            (CASE WHEN t3.TX_DCR_CLS_PRD IS MISSING THEN "SEM PERFIL" ELSE t3.TX_DCR_CLS_PRD END) AS TX_DCR_CLS_PRD, 
          t2.PC_CMPS_CLS_PRD, 
          /* IN_ENQ_CLS */
            (CASE WHEN t2.IN_ENQ_CLS IS MISSING THEN "SEM PERFIL VIGENTE" ELSE t2.IN_ENQ_CLS END) AS IN_ENQ_CLS
      FROM RCA_API_SALDO t1
           LEFT JOIN DB2RCA.CLI_ENQD_CLS t2 ON (t1.CD_CLI = t2.CD_CLI)
           LEFT JOIN DB2RCA.TIP_PRFL t4 ON (t1.CD_TIP_PRFL = t4.CD_TIP_PRFL)
           LEFT JOIN DB2RCA.CLS_PRD_INVS t3 ON (t2.CD_TIP_PRFL = t3.CD_TIP_PRFL) AND (t2.CD_CLS_PRD_CRS = t3.CD_CLS_PRD)
		   group by 1
      ORDER BY t1.CD_CLI;
QUIT;


/* --- End of code for "RCA_ENQ". --- */
/**/
/**/
/*PROC SQL; CREATE TABLE IDADE AS */
/*SELECT DISTINCT t1.COD AS CD_CLI, */
/*(INTCK('YEAR',t1.DTA_NASC_CSNT,TODAY())) AS IDADE */
/*FROM DB2MCI.CLIENTE t1 */
/* INNER JOIN GEINV.base T2 ON (T1.cd_cli=T2.mci)GROUP BY 1*/
/*ORDER BY 1; */
/*QUIT;*/
/**/



PROC SQL;
CREATE TABLE POUPANCA AS 
	SELECT *, 
		t1.VL_SDO_PRD_INVS AS VL_POUPANCA
	FROM WORK.RCA_API_SALDO t1
	WHERE ORIGEM = "POUPANCA";
QUIT;


PROC SQL;
CREATE TABLE CDB AS 
SELECT *, 
t1.VL_SDO_PRD_INVS AS VL_CDB
FROM WORK.RCA_API_SALDO t1
WHERE ORIGEM = "DEPOSITO A PRAZO";
QUIT;



PROC SQL;
CREATE TABLE LCA_LCI AS 
	SELECT *, 
		t1.VL_SDO_PRD_INVS AS VL_LCA_LCI
	FROM WORK.RCA_API_SALDO t1
	WHERE ORIGEM IN ("LCA","LCI");
QUIT;



PROC SQL;
CREATE TABLE FUNDOS AS 
	SELECT *, 
		t1.VL_SDO_PRD_INVS AS VL_FUNDOS
	FROM WORK.RCA_API_SALDO t1
	WHERE  ORIGEM = "FUNDOS DE INVESTIMENTO";
QUIT;


PROC SQL;
CREATE TABLE PREVIDENCIA AS 
	SELECT *, 
		t1.VL_SDO_PRD_INVS AS VL_PREVIDENCIA
	FROM WORK.RCA_API_SALDO t1
	WHERE  ORIGEM = "PREVIDENCIA";
QUIT;


PROC SQL;
CREATE TABLE TESOURO AS 
	SELECT *, 
		t1.VL_SDO_PRD_INVS AS VL_TESOURO
	FROM WORK.RCA_API_SALDO t1
	WHERE  ORIGEM = "TESOURO DIRETO";
QUIT;


PROC SQL;
CREATE TABLE DEMAIS AS 
	SELECT *, 
		t1.VL_SDO_PRD_INVS AS VL_OUTROS
	FROM WORK.RCA_API_SALDO t1
	WHERE  ORIGEM IN ("LETRAS DE CREDITO","OUTROS");
QUIT;


DATA INVESTIMENTOS;
SET POUPANCA CDB LCA_LCI FUNDOS PREVIDENCIA TESOURO DEMAIS;
RUN;
PROC SORT DATA=INVESTIMENTOS NODUPKEY; BY _ALL_; RUN;

PROC SQL;
CREATE TABLE INVESTIMENTOS_JUNTA AS 
	SELECT DISTINCT 
		t2.cd_prf_depe,
		t2.nr_seql_ctra,
		t1.CD_CLI, 
		t1.API, 
		t1.TX_DCR_PRFL, 
		(SUM(t1.VL_POUPANCA)) FORMAT=19.2 AS VL_POUPANCA, 
		(SUM(t1.VL_CDB)) FORMAT=19.2 AS VL_CDB, 
		(SUM(t1.VL_LCA_LCI)) FORMAT=19.2 AS LCA_LCI, 
		(SUM(t1.VL_FUNDOS)) FORMAT=19.2 AS FUNDOS, 
		(SUM(t1.VL_PREVIDENCIA)) FORMAT=19.2 AS VL_PREVIDENCIA, 
		(SUM(t1.VL_TESOURO)) FORMAT=19.2 AS TESOURO, 
		(SUM(t1.VL_OUTROS)) FORMAT=19.2 AS OUTROS
	FROM WORK.INVESTIMENTOS t1
	INNER JOIN COMUM.PAI_REL_&ANOMES T2 ON (T1.CD_CLI=T2.CD_CLI)
GROUP BY 1 ,2 ,3,4,5 ;
QUIT;




PROC SQL;
   CREATE TABLE CONTATOS AS 
   SELECT DISTINCT t1.CD_CLI, 
          /* MAX_of_DT_INCL_REG_INRO */
            (MAX(t1.DT_INCL_REG_INRO)) FORMAT=DATE9. AS DT_INCL_REG_INRO
      FROM DB2BIC.AUX_INRO_CLI_ATU t1
	  INNER JOIN GEINV.base T2 ON (T1.cd_cli=T2.mci)
/*	  LEFT JOIN DB2BIC.AUX_INRO_CLI_ANT T3 ON (T1.CD_CLI AND T3.CD_CLI)*/
	  
	   WHERE t1.CD_TIP_CNL = 55 AND t1.CD_PRD = 352 AND t1.CD_TRAN_INRO_SIS = 'REL02'
      GROUP BY t1.CD_CLI;
QUIT;


PROC SQL;
   CREATE TABLE CONTATOS_ANT AS 
   SELECT DISTINCT t1.CD_CLI, 
          /* MAX_of_DT_INCL_REG_INRO */
            (MAX(t1.DT_INCL_REG_INRO)) FORMAT=DATE9. AS DT_INCL_REG_INRO
      FROM DB2BIC.AUX_INRO_CLI_ANT t1
	  INNER JOIN GEINV.base T2 ON (T1.cd_cli=T2.mci)	  
	   WHERE t1.CD_TIP_CNL = 55 AND t1.CD_PRD = 352 AND t1.CD_TRAN_INRO_SIS = 'REL02'
      GROUP BY t1.CD_CLI;
QUIT;



DATA CONTATOS_TODOS;
SET CONTATOS CONTATOS_ANT;
RUN;



PROC SQL;
   CREATE TABLE CONTATOS_02 AS 
   SELECT DISTINCT t1.CD_CLI, 
          MAX(t1.DT_INCL_REG_INRO) FORMAT DDMMYY10. AS CONTACTADO
      FROM WORK.CONTATOS_TODOS t1
GROUP BY 1;
QUIT;


PROC SQL;
   CREATE TABLE CONTATOS_03 AS 
   SELECT t1.CD_CLI, 
          1 AS CONTACTADO
      FROM WORK.CONTATOS_02 t1;
QUIT;


PROC SQL;
CREATE TABLE nivel_mci AS 
	SELECT 
		t1.CD_CLI, 
		(CASE WHEN t1.API IS MISSING THEN "Nao" ELSE t1.API END) AS API_VIGENTE,
		(CASE WHEN t1.TX_DCR_PRFL IS MISSING THEN "Sem perfil" else t1.TX_DCR_PRFL end) AS PERFIL_INVESTIDOR,
		t1.VL_POUPANCA, 
		t1.VL_CDB, 
		t1.LCA_LCI, 
		t1.FUNDOS, 
		t1.VL_PREVIDENCIA, 
		t1.TESOURO, 
		t1.OUTROS
		FROM WORK.INVESTIMENTOS_JUNTA t1
	GROUP BY 1
;
QUIT;
PROC SORT DATA=nivel_mci NODUPKEY; BY _ALL_; RUN;






PROC SQL;
CREATE TABLE geinv.geinv_uci_cli AS 
	SELECT 
		t1.CD_CLI, 
		t1.API_VIGENTE, 
		t1.PERFIL_INVESTIDOR,
		T2.ADERENTE,  
		t1.VL_POUPANCA, 
		t1.VL_CDB, 
		t1.LCA_LCI, 
		t1.FUNDOS, 
		t1.VL_PREVIDENCIA, 
		t1.TESOURO, 
		t1.OUTROS,
		t2.RFV, 
		t2.RISCO
	FROM WORK.NIVEL_MCI t1
	LEFT JOIN GEINV.base T2 ON (T1.CD_CLI=T2.mci)
group by 1
;QUIT;
PROC SORT DATA=geinv.geinv_uci_cli NODUPKEY; BY _ALL_; RUN;
%ZerarMissingTabela(geinv.geinv_uci_cli)




PROC SQL;
CREATE TABLE clientes AS 
	SELECT 
	
		t1.CD_CLI, 
		t1.API_VIGENTE, 
		t1.PERFIL_INVESTIDOR, 
		t1.ADERENTE, 
		t1.VL_POUPANCA, 
		t1.VL_CDB, 
		t1.LCA_LCI, 
		t1.FUNDOS, 
		t1.VL_PREVIDENCIA, 
		t1.TESOURO, 
		t1.OUTROS, 
		t1.RFV, 
		t1.RISCO
		FROM GEINV.GEINV_UCI_CLI t1
;
QUIT;

PROC SORT DATA=clientes NODUPKEY; BY _ALL_; RUN;


proc sql;
	CREATE TABLE BASE_MCI AS
	SELECT DISTINCT CD_CLI FROM CLIENTES ORDER BY 1;
	CREATE INDEX CD_CLI ON BASE_MCI (CD_CLI); 
QUIT;

%ENCARTEIRAMENTO;


DATA CLIENTES;
MERGE ENCARTEIRAMENTO (IN=A) CLIENTES;
BY CD_CLI;
IF A;
RUN;

PROC SQL;
CREATE TABLE DEPENDENCIAS AS
SELECT INPUT(PREFDEP,4.) AS PREFDEP FROM IGR.IGRREDE_&ANOMES WHERE TIPODEP IN ('01','09') ORDER BY 1;
QUIT;

PROC SORT DATA=CLIENTES; BY PREFDEP; RUN;



DATA CLIENTES (WHERE=(CD_CLI NE .));
MERGE DEPENDENCIAS (IN=A) CLIENTES;
BY PREFDEP;
IF A;
IF TC NOT IN(10 16 50 56 57 59 60) THEN DO;
CARTEIRA=7002; TC=700; END;
RUN;
%ZerarMissingTabela(CLIENTES)




DATA PUBLICO_MCI;
SET DB2REL.CLI_CTRA;
WHERE CD_PRF_DEPE in (9777);
RUN;



DATA PUBLICO_CTRA;
SET DB2REL.CTRA_CLI;
WHERE CD_PRF_DEPE in (9777);
RUN;



PROC SQL;
	CREATE TABLE PUBLICO_UCI AS 
		SELECT 
		t1.CD_CLI, 
		t1.CD_PRF_DEPE, 
		t1.NR_SEQL_CTRA,
		T2.CD_TIP_CTRA,
		T2.NR_MTC_ADM_CTRA 
		FROM WORK.PUBLICO_MCI t1
	INNER JOIN PUBLICO_CTRA T2 ON (T1.CD_PRF_DEPE=T2.CD_PRF_DEPE AND T1.NR_SEQL_CTRA=T2.NR_SEQL_CTRA);
QUIT;



PROC SQL;
   CREATE TABLE GERENTES AS 
   SELECT 
          t1.CD_CLI AS MCI,
t1.PREFDEP, 

          t1.Carteira as CARTEIRA_RELACIONAMENTO, 
		  T2.CD_PRF_DEPE,
		   T2.NR_SEQL_CTRA AS CARTEIRA_INVESTIMENTO,
		   "F"||PUT(T2.NR_MTC_ADM_CTRA,Z7.) AS ESPECIALISTA_CHAVE, 
 
          t1.API_VIGENTE AS VIGENCIA_API, 
          t1.PERFIL_INVESTIDOR AS PERFIL_INVERTIDOR, 
          t1.ADERENTE, 
		  (VL_POUPANCA+VL_CDB+LCA_LCI+FUNDOS+VL_PREVIDENCIA+TESOURO+OUTROS) AS TOTAL_APLICACOES,
          t1.VL_POUPANCA as total_poupanca, 
          t1.VL_CDB as total_cdb, 
          t1.LCA_LCI AS TOTAL_LC, 
          t1.FUNDOS AS TOTAL_FUNDOS, 
          t1.VL_PREVIDENCIA AS TOTAL_PREVIDENCIA, 
          t1.TESOURO AS TOTAL_TESOURO, 
          t1.OUTROS AS TOTAL_OUTROS,
		  t1.RFV, 
          t1.RISCO 
      FROM WORK.CLIENTES t1
	  INNER JOIN PUBLICO_UCI T2 ON (T1.CD_CLI=T2.CD_CLI)
;QUIT;




PROC SQL;
   CREATE TABLE CLIENTES AS 
   SELECT
today() FORMAT DDMMYY10. AS POSICAO,
 
t1.MCI, 
          t1.PREFDEP as PREFIXO, 
          t1.CARTEIRA_RELACIONAMENTO, 
          t1.CARTEIRA_INVESTIMENTO, 
		  "F"||PUT(T2.NR_MTC_ADM_CTRA,Z7.) AS GERENTE_CHAVE,
          t1.ESPECIALISTA_CHAVE,
		  T3.CONTACTADO AS CONTATADO,
		  t1.RFV, 
          t1.RISCO,
          t1.VIGENCIA_API, 
          t1.PERFIL_INVERTIDOR, 
          t1.ADERENTE,
		   t1.TOTAL_APLICACOES,
          t1.TOTAL_POUPANCA, 
          t1.TOTAL_CDB,
          t1.TOTAL_LC, 
          t1.TOTAL_FUNDOS, 
          t1.TOTAL_PREVIDENCIA, 
          t1.TOTAL_TESOURO, 
          t1.TOTAL_OUTROS
      FROM WORK.GERENTES t1
INNER JOIN db2rel.ctra_cli T2 ON (T1.PREFDEP=T2.CD_PRF_DEPE AND T1.CARTEIRA_RELACIONAMENTO=T2.NR_SEQL_CTRA)
LEFT JOIN CONTATOS_03 T3 ON (T1.MCI=T3.CD_CLI)
;QUIT;
%ZerarMissingTabela(CLIENTES)



PROC SQL;
   CREATE TABLE SUMARIZAR_CARTEIRA AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          t1.CARTEIRA_INVESTIMENTO, 
          t1.ESPECIALISTA_CHAVE,
            (COUNT(t1.MCI)) AS TOTAL_CLIENTES, 
            (SUM(t1.TOTAL_APLICACOES)) AS TOTAL_APLICACOES, 
            (SUM(t1.TOTAL_POUPANCA)) FORMAT=19.2 AS TOTAL_POUPANCA,
            (SUM(t1.TOTAL_CDB)) FORMAT=19.2 AS TOTAL_CDB, 
            (SUM(t1.TOTAL_LC)) FORMAT=19.2 AS TOTAL_LC, 
            (SUM(t1.TOTAL_FUNDOS)) FORMAT=19.2 AS TOTAL_FUNDOS,
            (SUM(t1.TOTAL_PREVIDENCIA)) FORMAT=19.2 AS TOTAL_PREVIDENCIA, 
            (SUM(t1.TOTAL_TESOURO)) FORMAT=19.2 AS TOTAL_TESOURO, 
            (SUM(t1.TOTAL_OUTROS)) FORMAT=19.2 AS TOTAL_OUTROS
      FROM WORK.GERENTES t1
      GROUP BY 1,2,3;
QUIT;


PROC SQL;
   CREATE TABLE SUMARIZAR_DEPE AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          0 AS CARTEIRA_INVESTIMENTO, 
          "" AS ESPECIALISTA_CHAVE, 
            (COUNT(t1.MCI)) AS TOTAL_CLIENTES, 
            (SUM(t1.TOTAL_APLICACOES)) AS TOTAL_APLICACOES, 
            (SUM(t1.TOTAL_POUPANCA)) FORMAT=19.2 AS TOTAL_POUPANCA,
            (SUM(t1.TOTAL_CDB)) FORMAT=19.2 AS TOTAL_CDB, 
            (SUM(t1.TOTAL_LC)) FORMAT=19.2 AS TOTAL_LC, 
            (SUM(t1.TOTAL_FUNDOS)) FORMAT=19.2 AS TOTAL_FUNDOS,
            (SUM(t1.TOTAL_PREVIDENCIA)) FORMAT=19.2 AS TOTAL_PREVIDENCIA, 
            (SUM(t1.TOTAL_TESOURO)) FORMAT=19.2 AS TOTAL_TESOURO, 
            (SUM(t1.TOTAL_OUTROS)) FORMAT=19.2 AS TOTAL_OUTROS
      FROM WORK.GERENTES t1
      GROUP BY 1,2,3;
QUIT;



DATA JUNTA_PREFIXO;
SET SUMARIZAR_CARTEIRA SUMARIZAR_DEPE;
RUN;



PROC SQL;
   CREATE TABLE FINAL AS 
   SELECT 

today() FORMAT DDMMYY10. AS POSICAO,
t1.CD_PRF_DEPE AS PREFDEP, 
          t1.CARTEIRA_INVESTIMENTO AS CARTEIRA, 
          t1.ESPECIALISTA_CHAVE, 
          t1.TOTAL_CLIENTES, 
          t1.TOTAL_POUPANCA, 
          t1.TOTAL_CDB, 
          t1.TOTAL_LC, 
          t1.TOTAL_FUNDOS, 
          t1.TOTAL_PREVIDENCIA, 
          t1.TOTAL_TESOURO, 
          t1.TOTAL_OUTROS
      FROM WORK.JUNTA_PREFIXO t1
where CARTEIRA_INVESTIMENTO ne 0;
QUIT;


/*ROTINA 298*/

%LET Keypass=painel-geinv-4f383b23-46a4-46d3-8ef8-252194693c91;
PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('final', 'painel-geinv');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('clientes', 'clientes');
QUIT;
%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);


/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.FUN AS */
/*   SELECT DISTINCT INPUT(SUBSTR(t1.CD_USU,2,8), 7.) AS CD_USU,*/
/*          t1.NM_FUN, */
/*          t1.CD_CTGR_FUN, */
/*          t1.CD_CMSS_FUN, */
/*          t2.CD_REF_ORGC_PRFL, */
/*          t2.NM_CRG, */
/*          t1.TX_CMSS_FUN, */
/*          t1.CD_DEPE_LCLZ, */
/*          t1.DT_NSC, */
/*          t1.NM_RDZ_FUN, */
/*          t1.CD_CLI, */
/*          t1.CD_EST, */
/*          t1.NM_EST, */
/*          t1.NR_CPF*/
/*      FROM DB2ITR.FUN t1*/
/*           INNER JOIN DB2ITR.USU t2 ON (t1.CD_USU = t2.CD_USU)*/
/*WHERE t1.CD_CTGR_FUN='F';*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.QUERY_FOR_ESPECIALISTA_0001 AS */
/*   SELECT t1.ESPECIALISTA, */
/*          t2.cd_usu*/
/*      FROM WORK.QUERY_FOR_ESPECIALISTA t1*/
/*inner join DB2ITR.USU t2 on (t1.gerente_matricula=INPUT(SUBSTR(t2.cd_usu,2,8),7.));*/
/*QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*CREATE TABLE Especialista_mci AS */
/*	SELECT */
/*TODAY() format yymmdd10. as posicao,*/
/* t1.PREFDEP,*/
/*		t1.ESPECIALISTA fomat 2., */
/*		"" AS nm_especialista,*/
/*		T1.PREFDIR,*/
/*		T1.PREFSUPER,*/
/*		T1.PREFSUREG,*/
/*		t1.prefdep as dep,*/
/*		t1.carteira,*/
/*		t1.GERENTE_MATRICULA Format 10., */
/*		ifc(T3.NM_FUN="", "CARTEIRA SEM GERENTE",T3.NM_FUN) AS NM_FUN,*/
/*		t1.CD_CLI, */
/*		t2.contactado,*/
/*			t1.RFV, */
/*		t1.RISCO,*/
/*		t1.API_VIGENTE, */
/*		t1.PERFIL_INVESTIDOR, */
/*		t1.ADERENTE, */
/*		t1.VL_POUPANCA, */
/*		t1.VL_CDB, */
/*		t1.LCA_LCI, */
/*		t1.FUNDOS, */
/*		t1.VL_PREVIDENCIA, */
/*		t1.TESOURO, */
/*		t1.OUTROS,*/
/*(vl_poupanca+VL_CDB+LCA_LCI+FUNDOS+VL_PREVIDENCIA+TESOURO+OUTROS) AS SOMA */
/*		FROM CLIENTES t1*/
/*		LEFT JOIN CONTATOS_02 T2 ON (t1.CD_CLI=t2.CD_CLI)*/
/*		left join fun t3 on (T1.GERENTE_MATRICULA=T3.CD_USU)*/
/*	*/
/*ORDER BY 2,7,8,11*/
/*	;	QUIT;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE ESPECIALISTA_DEPE AS */
/*   SELECT DISTINCT */
/*t1.PREFDEP,*/
/*t1.ESPECIALISTA, */
/*"" as nm_especialista,*/
/*            (SUM(t1.VL_POUPANCA)) FORMAT=19.2 AS VL_POUPANCA, */
/*            (SUM(t1.VL_CDB)) FORMAT=19.2 AS VL_CDB, */
/*            (SUM(t1.LCA_LCI)) FORMAT=19.2 AS LCA_LCI,*/
/*            (SUM(t1.FUNDOS)) FORMAT=19.2 AS FUNDOS, */
/*            (SUM(t1.VL_PREVIDENCIA)) FORMAT=19.2 AS VL_PREVIDENCIA,*/
/*            (SUM(t1.TESOURO)) FORMAT=19.2 AS TESOURO, */
/*            (SUM(t1.OUTROS)) FORMAT=19.2 AS OUTROS,*/
/*			(SUM(SOMA)) AS SOMA*/
/*      FROM WORK.ESPECIALISTA_MCI t1*/
/*      GROUP BY 1,2;*/
/*QUIT;*/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE ESPECIALISTA_DEPE_01 AS */
/*   SELECT DISTINCT*/
/*9777 AS PREFDEP,*/
/*0 AS ESPECIALISTA, */
/*"" as nm_especialista,*/
/*            (SUM(t1.VL_POUPANCA)) FORMAT=19.2 AS VL_POUPANCA, */
/*            (SUM(t1.VL_CDB)) FORMAT=19.2 AS VL_CDB, */
/*            (SUM(t1.LCA_LCI)) FORMAT=19.2 AS LCA_LCI,*/
/*            (SUM(t1.FUNDOS)) FORMAT=19.2 AS FUNDOS, */
/*            (SUM(t1.VL_PREVIDENCIA)) FORMAT=19.2 AS VL_PREVIDENCIA,*/
/*            (SUM(t1.TESOURO)) FORMAT=19.2 AS TESOURO, */
/*            (SUM(t1.OUTROS)) FORMAT=19.2 AS OUTROS,*/
/*			(SUM(SOMA)) AS SOMA*/
/*      FROM WORK.ESPECIALISTA_DEPE t1*/
/*      GROUP BY 1,2;*/
/*QUIT;*/
/**/
/*DATA ESP_DEPE;*/
/*SET ESPECIALISTA_DEPE ESPECIALISTA_DEPE_01;*/
/*RUN;*/
/**/
/**/
/**/
/*PROC SQL;*/
/*   CREATE TABLE ESP_DEPE_01 AS */
/*   SELECT */
/*	TODAY() format yymmdd10. as posicao,	*/
/*t1.PREFDEP, */
/*          t1.ESPECIALISTA, */
/*		  */
/*          t1.VL_POUPANCA, */
/*          t1.VL_CDB, */
/*          t1.LCA_LCI, */
/*          t1.FUNDOS, */
/*          t1.VL_PREVIDENCIA, */
/*          t1.TESOURO, */
/*          t1.OUTROS, */
/*          t1.SOMA,*/
/*		  nm_especialista*/
/*      FROM WORK.ESP_DEPE t1*/
/*GROUP BY 1,2,3 ;*/
/*QUIT;*/
/**/
/**/
/*data cod_grupo ;*/
/*infile DATALINES dsd missover;*/
/*input Especialista 2.*/
/*      nm_esp $38.;*/
/*CARDS;*/
/*0 TOTAL*/
/*1	ALAN KARDEC DA SILVA SALOMON*/
/*2	AMANDA BITTENCOURT DE OLIVEIRA*/
/*3	ANDERSON NUNES DE MELO*/
/*4	ANDERSON VENANCIO DE CARVALHO*/
/*5	ANDRE HIROSHI SAITO FISCHER MORI*/
/*6	AUREO ANTONIO DUARTE*/
/*7	CAIO CEZAR PAGANINI*/
/*8	CAMILA MONTSERRAT ALVAREZ DIAS*/
/*9	CASSIANA APARECIDA FERREIRA DE A*/
/*10	DANIEL RICARDO DE ARAUJO*/
/*11	DIOGENES MONTEIRO DE FIGUEIREDO*/
/*12	DIOGO DINARTE DO SOUTO*/
/*13	EDUARDO CARR DE OLIVEIRA CAMPOS*/
/*14	EDUARDO DA CRUZ*/
/*15	EDUARDO LOPES DE OLIVEIRA FILHO*/
/*16	FABIO DE MELLO MATOS*/
/*17	FLAVIO MINORU TANAKA*/
/*18	FRANCIELLE SILVA*/
/*19	GILMAR VASCONCELOS VILARIM*/
/*20	GUILHERME SILVA BRENNAND*/
/*21	HECTOR SEGATO FRIAS MORALES*/
/*22	JEZIEL MONTEIRO DOURADO*/
/*23	JONATAN FREIRE CARDOSO OLIVEIRA*/
/*24	LILIANE VIEIRA MARTINS*/
/*25	LIVIA PAULA FERREIRA E SILVA*/
/*26	LUIZ EDUARDO KOZAK MICHELON*/
/*27	LUIZ FELIPE ASP DE QUEIROZ*/
/*28	MANOEL ANTUNES PERASI*/
/*29	MARCELO YUKIO USHIDA*/
/*30	NAYANNE WELTER DOS SANTOS*/
/*31	PEDRO HENRIQUE LOMNITZER*/
/*32	RAFAEL PELISSARI NEGREIROS*/
/*33	RENATO PEREIRA REGGIANI*/
/*34	SAMARINA HOPKA HERRERIAS CARDOSO*/
/*35	SAMIA MEDEIROS ANDION*/
/*36	SEBASTIAO RIBEIRO DE LIMA*/
/*37	SEILACIR RODRIGUES*/
/*38	STEPHANE BRITO DE OLIVEIRA FACO*/
/*39	THIAGO CORREA SOARES DE SANTANA*/
/*40	VANESSA ANDRADE DE CASTRO*/
/*41	VINICIUS SECON*/
/*99 SEM ESPECIALISTA99*/
/*;*/
/*run;*/
/**/
/**/
/*proc sql;*/
/*	create table Especialista as */
/*		select  */
/*			TODAY() format yymmdd10. as posicao,	*/
/*			Especialista, */
/*			nm_esp*/
/*		from cod_grupo;*/
/*quit;*/
/**/
/**/
/**/
/**/
/*%LET Usuario=f9457977;*/
/*%LET Keypass=iRk8OjNFj7s0yqmsKMcTRXTKO2IbpkDUzrBq3A8BnYRktWt0Y1;*/
/*PROC SQL;*/
/*DROP TABLE TABELAS_EXPORTAR_REL;*/
/*CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('esp_depe_01', 'uop-rel');*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('especialista', 'especialista');*/
/*INSERT INTO TABELAS_EXPORTAR_REL VALUES('especialista_mci', 'clientes');*/
/**/
/*QUIT;*/
/*%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);*/

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
