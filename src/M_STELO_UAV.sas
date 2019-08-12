
/*#################################################################################################################*/

%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME SEG_10 "/dados/infor/producao/REPRO_1S_DIGOV";
LIBNAME BS_MGCT "/dados/infor/producao/IndicadoresGoverno/bases/MGCT_OPR";
LIBNAME CNX_1 "/dados/infor/conexao/2019/000000015";
LIBNAME CNX_2 "/dados/infor/conexao/2019/000000141";
LIBNAME CNX_3 "/dados/infor/conexao/2019/000000187";
LIBNAME CNX_4 "/dados/infor/conexao/2019/000000202";
LIBNAME CNX_5 "/dados/infor/conexao/2019/000000186";
LIBNAME CNX_6 "/dados/infor/conexao/2019/000000049";
LIBNAME CNX_7 "/dados/infor/conexao/2019/000000185";

/*# V A R I A V E I S   E   C O N S T A N T E S  #*/

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

%PUT &D1. &ANOMES. &MES. &MESANO.;


/*###################################################################################################################*/

/*	
PROC SQL;

   CREATE TABLE SEG_10.MGCT_OPR_FCHD_1s2019 AS
 
   SELECT *
		  		  
   FROM BS_MGCT.MGCT_OPR_FCHD_1s2019 t1
   ;

QUIT;
*/

/*******************************************/
/*******************************************/

PROC SQL;

   CREATE TABLE TESTE AS
 
   SELECT SUM(VL_MGCT) AS TOTAL
		  		  
   FROM BS_MGCT.MGCT_OPR_FCHD_1s2019 t1
   ;

QUIT;


/*CONEXAO*/
/*CONEXAO*/
/*CONEXAO*/
/*CONEXAO*/

/*
D_IND_GOV_CESTA_MINIMA
D_IND_GOV_MC
D_IND_GOV_RTBLD_CARTAO
D_IND_GOV_TARIFAS_PRIORIZADAS
D_IND_GOV_FUNDOS
D_IND_GOV_MC_PERC_CTRA
*/


/*********************/
/*********************/
/*********************/
/********PRIMEIRO*****/

/*
PROC SQL;

   CREATE TABLE SEG_10.indicador_000000015 AS
 
   SELECT *
		  		  
   FROM CNX_1.indicador_000000015 t1
   ;

QUIT;


PROC SQL;

   CREATE TABLE SEG_10.cli_ind_000000015_dt062019 AS
 
   SELECT *
		  		  
   FROM CNX_1.cli_ind_000000015_dt062019 t1
   ;

QUIT;
*/


PROC SQL;

   CREATE TABLE TESTE_RLZ AS
 
   SELECT *
		  		  
   FROM SEG_10.indicador_000000015 t1
   ;

QUIT;

PROC SQL;

   CREATE TABLE TESTE_MCI AS
 
   SELECT *
		  		  
   FROM SEG_10.cli_ind_000000015_dt062019 t1
   ;

QUIT;




/*********************/
/*********************/
/*********************/
/******SEGUNDO********/

/*
PROC SQL;

   CREATE TABLE SEG_10.indicador_000000141 AS
 
   SELECT *
		  		  
   FROM CNX_2.indicador_000000141 t1
   ;

QUIT;


PROC SQL;

   CREATE TABLE SEG_10.cli_ind_000000141_dt062019 AS
 
   SELECT *
		  		  
   FROM CNX_2.cli_ind_000000141_dt062019 t1
   ;

QUIT;


/*********************/
/*********************/
/*********************/
/*********TERCEIRO****/
/*
PROC SQL;

   CREATE TABLE SEG_10.indicador_000000187 AS
 
   SELECT *
		  		  
   FROM CNX_3.indicador_000000187 t1
   ;

QUIT;


PROC SQL;

   CREATE TABLE SEG_10.cli_ind_000000187_dt062019 AS
 
   SELECT *
		  		  
   FROM CNX_3.cli_ind_000000187_dt062019 t1
   ;

QUIT;


/*********************/
/*********************/
/*********************/
/*******QUARTO********/
/*
PROC SQL;

   CREATE TABLE SEG_10.indicador_000000202 AS
 
   SELECT *
		  		  
   FROM CNX_4.indicador_000000202 t1
   ;

QUIT;


PROC SQL;

   CREATE TABLE SEG_10.cli_ind_000000202_dt062019 AS
 
   SELECT *
		  		  
   FROM CNX_4.cli_ind_000000202_dt062019 t1
   ;

QUIT;


/*********************/
/*********************/
/*********************/
/******QUINTO*******/
/*
PROC SQL;

   CREATE TABLE SEG_10.indicador_000000186 AS
 
   SELECT *
		  		  
   FROM CNX_5.indicador_000000186 t1
   ;

QUIT;


PROC SQL;

   CREATE TABLE SEG_10.cli_ind_000000186_dt062019 AS
 
   SELECT *
		  		  
   FROM CNX_5.cli_ind_000000186_dt062019 t1
   ;

QUIT;


/*********************/
/*********************/
/*********************/
/******SEXTO**********/
/*
PROC SQL;

   CREATE TABLE SEG_10.indicador_000000049 AS
 
   SELECT *
		  		  
   FROM CNX_6.indicador_000000049 t1
   ;

QUIT;


/*********************/
/*********************/
/*********************/
/******SETIMO*******/


PROC SQL;

   CREATE TABLE SEG_10.indicador_000000185 AS
 
   SELECT *
		  		  
   FROM CNX_7.indicador_000000185 t1
   ;

QUIT;


PROC SQL;

   CREATE TABLE SEG_10.cli_ind_000000185_dt062019 AS
 
   SELECT *
		  		  
   FROM CNX_7.cli_ind_000000185_dt062019 t1
   ;

QUIT;


/*********************/
/*********************/
/*********************/
/*********************/


x cd /dados/infor/producao/REPRO_1S_DIGOV ;
x cd /dados/infor/producao/IndicadoresGoverno/bases/MGCT_OPR ;
x cd /dados/infor/conexao/2019/000000015 ;
x cd /dados/infor/conexao/2019/000000141 ;
x cd /dados/infor/conexao/2019/000000187 ;
x cd /dados/infor/conexao/2019/000000202 ;
x cd /dados/infor/conexao/2019/000000186 ;
x cd /dados/infor/conexao/2019/000000049 ;
x chmod 2777 *;


/********************************************/
/*******************************************/
