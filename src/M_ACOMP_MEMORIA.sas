

%include '/dados/infor/suporte/FuncoesInfor.sas';


libname MEM '/dados/infor/producao/MEM_SAS';


/***********************/
/***********************/


/*LEITURA QUOTAS GECEN*/


DATA WORK.QUOTAS_GECEN;
    LENGTH
        F1               $ 11
        F2               $ 12
        F3               $ 1 ;
    FORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFILE '/dados/gecen/quotas.txt'
        LRECL=25
        ENCODING="LATIN1"
        TERMSTR=LF
        DLM=':'
        MISSOVER
        DSD ;
    INPUT
        F1               : $CHAR11.
        F2               : $CHAR12.
        F3               : $CHAR1. ;
RUN;


data WORK.QUOTAS_GECEN_1(keep = F2 i);
set WORK.QUOTAS_GECEN;
i+1;
run;


data WORK.QUOTAS_GECEN_2;
set WORK.QUOTAS_GECEN_1;
where i in(4 5);
run;


data WORK.QUOTAS_GECEN_3;
set WORK.QUOTAS_GECEN_2;
format F2 32.;
VALOR = Input(tranwrd(F2, " GB", ""), 32.);
run;


data WORK.QUOTAS_GECEN_TOTAL (KEEP = VALOR);
set WORK.QUOTAS_GECEN_3;
where i in(5);
run;


data WORK.QUOTAS_GECEN_TOTAL_1;
set WORK.QUOTAS_GECEN_TOTAL;
i+1;
run;


data WORK.QUOTAS_GECEN_USADO (KEEP = VALOR);
set WORK.QUOTAS_GECEN_3;
where i in(4);
run;


data WORK.QUOTAS_GECEN_USADO_1;
set WORK.QUOTAS_GECEN_USADO;
i+1;
run;


PROC SQL;
CREATE TABLE WORK.QUOTAS_GECEN_FINAL AS SELECT t1.VALOR AS VL_TOTAL, t2.VALOR AS VL_USADO
FROM WORK.QUOTAS_GECEN_TOTAL_1 t1
LEFT JOIN WORK.QUOTAS_GECEN_USADO_1 t2 ON t1.i = t2.i;
QUIT;


data WORK.QUOTAS_GECEN_FINAL;
format TS_LEITURA IS8601DT19.;
set WORK.QUOTAS_GECEN_FINAL;
TS_LEITURA = datetime();
run;


data WORK.QUOTAS_GECEN_FINAL;
format FILESYSTEM $ 20.;
set WORK.QUOTAS_GECEN_FINAL;
FILESYSTEM = "/dados/gecen";
run;


PROC SQL;
CREATE TABLE WORK.QUOTAS_CONSOLIDADO AS SELECT *
FROM WORK.QUOTAS_GECEN_FINAL;
QUIT;


/*Fazendo a Carga*/


DATA _NULL_;
	SET WORK.QUOTAS_GECEN_FINAL;
	FILE '/dados/infor/producao/MEM_SAS/QUOTAS_GECEN_FINAL.txt';
	PUT FILESYSTEM '; ' TS_LEITURA '; ' VL_TOTAL '; ' VL_USADO '; ' TS_LEITURA;
RUN;


LIBNAME RUT;
x cd /dados/infor/utilitarios;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u spot_gecem spotfire -pJINOPOFA --execute="LOAD DATA LOCAL INFILE '/dados/infor/producao/MEM_SAS/QUOTAS_GECEN_FINAL.txt' 
IGNORE INTO TABLE utilizacao_fs_sas FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n';";


/***********************/
/***********************/


/*LEITURA QUOTAS GESTAO*/


DATA WORK.QUOTAS_GESTAO;
    LENGTH
        F1               $ 11
        F2               $ 12
        F3               $ 1 ;
    FORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFILE '/dados/gestao/quotas.txt'
        LRECL=25
        ENCODING="LATIN1"
        TERMSTR=LF
        DLM=':'
        MISSOVER
        DSD ;
    INPUT
        F1               : $CHAR11.
        F2               : $CHAR12.
        F3               : $CHAR1. ;
RUN;


data WORK.QUOTAS_GESTAO_1(keep = F2 i);
set WORK.QUOTAS_GESTAO;
i+1;
run;


data WORK.QUOTAS_GESTAO_2;
set WORK.QUOTAS_GESTAO_1;
where i in(4 5);
run;


data WORK.QUOTAS_GESTAO_3;
set WORK.QUOTAS_GESTAO_2;
format F2 32.;
VALOR = Input(tranwrd(F2, " GB", ""), 32.);
run;


data WORK.QUOTAS_GESTAO_TOTAL (KEEP = VALOR);
set WORK.QUOTAS_GESTAO_3;
where i in(5);
run;


data WORK.QUOTAS_GESTAO_TOTAL_1;
set WORK.QUOTAS_GESTAO_TOTAL;
i+1;
run;


data WORK.QUOTAS_GESTAO_USADO (KEEP = VALOR);
set WORK.QUOTAS_GESTAO_3;
where i in(4);
run;


data WORK.QUOTAS_GESTAO_USADO_1;
set WORK.QUOTAS_GESTAO_USADO;
i+1;
run;


PROC SQL;
CREATE TABLE WORK.QUOTAS_GESTAO_FINAL AS SELECT t1.VALOR AS VL_TOTAL, t2.VALOR AS VL_USADO
FROM WORK.QUOTAS_GESTAO_TOTAL_1 t1
LEFT JOIN WORK.QUOTAS_GESTAO_USADO_1 t2 ON t1.i = t2.i;
QUIT;


data WORK.QUOTAS_GESTAO_FINAL;
format TS_LEITURA IS8601DT19.;
set WORK.QUOTAS_GESTAO_FINAL;
TS_LEITURA = datetime();
run;


data WORK.QUOTAS_GESTAO_FINAL;
format FILESYSTEM $ 20.;
set WORK.QUOTAS_GESTAO_FINAL;
FILESYSTEM = "/dados/gestao";
run;


PROC SQL;
INSERT INTO WORK.QUOTAS_CONSOLIDADO SELECT *
FROM WORK.QUOTAS_GESTAO_FINAL t1;
QUIT;


/*Fazendo a Carga*/


DATA _NULL_;
	SET WORK.QUOTAS_GESTAO_FINAL;
	FILE '/dados/infor/producao/MEM_SAS/QUOTAS_GESTAO_FINAL.txt';
	PUT FILESYSTEM '; ' TS_LEITURA '; ' VL_TOTAL '; ' VL_USADO '; ' TS_LEITURA;
RUN;


LIBNAME RUT;
x cd /dados/infor/utilitarios;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u spot_gecem spotfire -pJINOPOFA --execute="LOAD DATA LOCAL INFILE '/dados/infor/producao/MEM_SAS/QUOTAS_GESTAO_FINAL.txt' 
IGNORE INTO TABLE utilizacao_fs_sas FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n';";


/***********************/
/***********************/


/*LEITURA QUOTAS ORCAMENTO*/


DATA WORK.QUOTAS_ORCAMENTO;
    LENGTH
        F1               $ 11
        F2               $ 12
        F3               $ 1 ;
    FORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFILE '/dados/orcamento/quotas.txt'
        LRECL=25
        ENCODING="LATIN1"
        TERMSTR=LF
        DLM=':'
        MISSOVER
        DSD ;
    INPUT
        F1               : $CHAR11.
        F2               : $CHAR12.
        F3               : $CHAR1. ;
RUN;


data WORK.QUOTAS_ORCAMENTO_1(keep = F2 i);
set WORK.QUOTAS_ORCAMENTO;
i+1;
run;


data WORK.QUOTAS_ORCAMENTO_2;
set WORK.QUOTAS_ORCAMENTO_1;
where i in(4 5);
run;


data WORK.QUOTAS_ORCAMENTO_3;
set WORK.QUOTAS_ORCAMENTO_2;
format F2 32.;
VALOR = Input(tranwrd(F2, " GB", ""), 32.);
run;


data WORK.QUOTAS_ORCAMENTO_TOTAL (KEEP = VALOR);
set WORK.QUOTAS_ORCAMENTO_3;
where i in(5);
run;


data WORK.QUOTAS_ORCAMENTO_TOTAL_1;
set WORK.QUOTAS_ORCAMENTO_TOTAL;
i+1;
run;


data WORK.QUOTAS_ORCAMENTO_USADO (KEEP = VALOR);
set WORK.QUOTAS_ORCAMENTO_3;
where i in(4);
run;


data WORK.QUOTAS_ORCAMENTO_USADO_1;
set WORK.QUOTAS_ORCAMENTO_USADO;
i+1;
run;


PROC SQL;
CREATE TABLE WORK.QUOTAS_ORCAMENTO_FINAL AS SELECT t1.VALOR AS VL_TOTAL, t2.VALOR AS VL_USADO
FROM WORK.QUOTAS_ORCAMENTO_TOTAL_1 t1
LEFT JOIN WORK.QUOTAS_ORCAMENTO_USADO_1 t2 ON t1.i = t2.i;
QUIT;


data WORK.QUOTAS_ORCAMENTO_FINAL;
format TS_LEITURA IS8601DT19.;
set WORK.QUOTAS_ORCAMENTO_FINAL;
TS_LEITURA = datetime();
run;


data WORK.QUOTAS_ORCAMENTO_FINAL;
format FILESYSTEM $ 20.;
set WORK.QUOTAS_ORCAMENTO_FINAL;
FILESYSTEM = "/dados/orcamento";
run;


PROC SQL;
INSERT INTO WORK.QUOTAS_CONSOLIDADO SELECT *
FROM WORK.QUOTAS_ORCAMENTO_FINAL t1;
QUIT;


/*Fazendo a Carga*/

DATA _NULL_;
	SET WORK.QUOTAS_ORCAMENTO_FINAL;
	FILE '/dados/infor/producao/MEM_SAS/QUOTAS_ORCAMENTO_FINAL.txt';
	PUT FILESYSTEM '; ' TS_LEITURA '; ' VL_TOTAL '; ' VL_USADO '; ' TS_LEITURA;
RUN;


LIBNAME RUT;
x cd /dados/infor/utilitarios;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u spot_gecem spotfire -pJINOPOFA --execute="LOAD DATA LOCAL INFILE '/dados/infor/producao/MEM_SAS/QUOTAS_ORCAMENTO_FINAL.txt' 
IGNORE INTO TABLE utilizacao_fs_sas FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n';";


/***********************/
/***********************/


/*LEITURA QUOTAS INFOR*/


DATA WORK.QUOTAS_INFOR;
    LENGTH
        F1               $ 11
        F2               $ 12
        F3               $ 1 ;
    FORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFORMAT
        F1               $CHAR11.
        F2               $CHAR12.
        F3               $CHAR1. ;
    INFILE '/dados/infor/quotas.txt'
        LRECL=25
        ENCODING="LATIN1"
        TERMSTR=LF
        DLM=':'
        MISSOVER
        DSD ;
    INPUT
        F1               : $CHAR11.
        F2               : $CHAR12.
        F3               : $CHAR1. ;
RUN;


data WORK.QUOTAS_INFOR_1(keep = F2 i);
set WORK.QUOTAS_INFOR;
i+1;
run;


data WORK.QUOTAS_INFOR_2;
set WORK.QUOTAS_INFOR_1;
where i in(4 5);
run;


data WORK.QUOTAS_INFOR_3;
set WORK.QUOTAS_INFOR_2;
format F2 32.;
VALOR = Input(tranwrd(F2, " GB", ""), 32.);
run;


data WORK.QUOTAS_INFOR_TOTAL (KEEP = VALOR);
set WORK.QUOTAS_INFOR_3;
where i in(5);
run;


data WORK.QUOTAS_INFOR_TOTAL_1;
set WORK.QUOTAS_INFOR_TOTAL;
i+1;
run;


data WORK.QUOTAS_INFOR_USADO (KEEP = VALOR);
set WORK.QUOTAS_INFOR_3;
where i in(4);
run;


data WORK.QUOTAS_INFOR_USADO_1;
set WORK.QUOTAS_INFOR_USADO;
i+1;
run;


PROC SQL;
CREATE TABLE WORK.QUOTAS_INFOR_FINAL AS SELECT t1.VALOR AS VL_TOTAL, t2.VALOR AS VL_USADO
FROM WORK.QUOTAS_INFOR_TOTAL_1 t1
LEFT JOIN WORK.QUOTAS_INFOR_USADO_1 t2 ON t1.i = t2.i;
QUIT;


data WORK.QUOTAS_INFOR_FINAL;
format TS_LEITURA IS8601DT19.;
set WORK.QUOTAS_INFOR_FINAL;
TS_LEITURA = datetime();
run;


data WORK.QUOTAS_INFOR_FINAL;
format FILESYSTEM $ 20.;
set WORK.QUOTAS_INFOR_FINAL;
FILESYSTEM = "/dados/infor";
run;


PROC SQL;
INSERT INTO WORK.QUOTAS_CONSOLIDADO SELECT *
FROM WORK.QUOTAS_INFOR_FINAL ;
QUIT;


/*Fazendo a Carga*/


DATA _NULL_;
	SET WORK.QUOTAS_INFOR_FINAL;
	FILE '/dados/infor/producao/MEM_SAS/QUOTAS_INFOR_FINAL.txt';
	PUT FILESYSTEM '; ' TS_LEITURA '; ' VL_TOTAL '; ' VL_USADO '; ' TS_LEITURA;
RUN;


LIBNAME RUT;
x cd /dados/infor/utilitarios;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u spot_gecem spotfire -pJINOPOFA --execute="LOAD DATA LOCAL INFILE '/dados/infor/producao/MEM_SAS/QUOTAS_INFOR_FINAL.txt' 
IGNORE INTO TABLE utilizacao_fs_sas FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n';";


/***********************/
/***********************/


x cd /dados/infor/producao/MEM_SAS;
x chmod 2777 *;



