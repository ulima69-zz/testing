 %include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2SGCEN database=BDB2P04;

LIBNAME BCN "/dados/gecen/interno/bases/bcn";


x cd /dados/infor/utilitarios;
x ./mysql --batch -h svispo02157.sp.intrabb.bb.com.br -u proc_ernani sis_gecen -parnesto --execute="select distinct mci from pfr_empresa where not isnull(mci) order by 1" > '/dados/infor/producao/franquias/prf_mci.txt';

DATA PRF_CNPJ;
    INFILE '/dados/infor/producao/franquias/prf_mci.txt'
        LRECL=836
        FIRSTOBS=2
        ENCODING="LATIN1"
        dlm="09"x
        TERMSTR=LF
        TRUNCOVER;
    LENGTH
        cd_cli 8;
    FORMAT
        cd_cli BEST9.;
    INFORMAT
        cd_cli BEST9.;
    INPUT
        cd_cli : ?? BEST9.;
RUN;




PROC SQL;
   CREATE TABLE CONTA_CORRENTE AS 
   SELECT DISTINCT t1.CD_CLI, 
          /* MAX_of_DT_FIM_PRTC */
            (MAX(t1.DT_FIM_PRTC)) FORMAT=DDMMYY10. AS DT_SIT_CONTA
      FROM OPR.CONTA_CORRENTE t1
	  INNER JOIN PRF_CNPJ T2 ON (T1.CD_CLI=T2.CD_CLI)
      GROUP BY t1.CD_CLI;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CONTA_CORRENTE_01 AS 
   SELECT DISTINCT t1.CD_CLI,
		   t2.DT_SIT_CONTA,
		   T1.CD_MDLD
      FROM OPR.CONTA_CORRENTE t1
INNER JOIN CONTA_CORRENTE T2 ON (T1.CD_CLI=T2.CD_CLI AND T1.DT_FIM_PRTC=T2.DT_SIT_CONTA)
GROUP BY 1,2;
QUIT;





proc format;
	VALUE SIT 1='ATIVA' 2='ENCERRADA/LIQUIDADA' 3="TRANSFERIDA" 5="CONTA SEM MOVIMENTO" 6="BLOQUEADA" 0="NÃO INFORMADO" 
	;

PROC SQL;
    CREATE TABLE MCI_SIT AS
        SELECT B.CNPJ, B.MCI, situ_conta_corrente_ttld_1 FORMAT SIT.
            FROM PRF_CNPJ A
                LEFT JOIN BCN.BCN_PJ B ON(A.CD_CLI=B.MCI)
order by 1;
QUIT;



PROC SQL;
   CREATE TABLE MCI_MDLD AS 
   SELECT t1.cnpj, 
          t1.mci,
		  IFN(CD_MDLD=27, situ_conta_corrente_ttld_1=0, situ_conta_corrente_ttld_1) AS situ_conta_corrente_ttld_1,
          t1.situ_conta_corrente_ttld_1
      FROM WORK.MCI_SIT t1
LEFT JOIN CONTA_CORRENTE_01 T2 ON (T1.MCI=T2.CD_CLI);
QUIT;


PROC SQL;
    CREATE TABLE MCI_CC AS
        SELECT CNPJ, situ_conta_corrente_ttld_1 FORMAT SIT.
            FROM MCI_MDLD
		WHERE CNPJ <>.
                
order by 1;
QUIT;


DATA _NULL_;
CALL SYMPUT('CAMINHO',&SASWORKLOCATION);
RUN;

%PUT &CAMINHO;

PROC EXPORT DATA=MCI_CC( where=(cnpj ne 0)) OUTFILE="&CAMINHO.TXTRpt.txt" DBMS=DLM REPLACE;
    PUTNAMES=NO;
    DELIMITER=';';
RUN;

x cd /dados/infor/utilitarios;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_ernani upd_gecen -parnesto --execute="load data local infile '&CAMINHO.TXTRpt.txt' into table pfr_atualizacao_conta fields terminated by ';' lines terminated by '\n'";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_ernani upd_gecen -parnesto --execute="call pfr_atualizacao_conta()";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_ernani upd_gecen -parnesto --execute="truncate table pfr_atualizacao_conta";

/*************************************************/;
/* TRECHO DE CÓDIGO INCLUÍDO PELO FF */;

%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";
 
%processCheckOut(
    uor_resp = 341556
    ,funci_resp = 'F9457977'
    /*,tipo = Indicador
    ,sistema = Indicador
    ,rotina = I0123 Indicador de Alguma Coisa*/
    ,mailto= &EmailsCheckOut.
);
