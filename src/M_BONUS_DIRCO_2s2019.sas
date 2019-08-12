
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME ATB DB2 DATABASE=BDB2P04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SGCEN;

Libname DIRAO "/dados/dirao/publico";

LIBNAME CPA "/dados/infor/producao/bonus_dirco_1s19";

%diasUteis(%sysfunc(today()), 5);
			%GLOBAL DiaUtil_D0 DiaUtil_D1;


			data arq;
				format 
					anomes yymmn6.
					mesano z6.
					DiaUtil_D1 date9.
					mes z2.
					ano 4.;
				anomes = &diaUtil_d1;
				mesano = INPUT(PUT(&diaUtil_d1, mmyyn6.),6.);
				DiaUtil_D1 = &diaUtil_d1;
				mes = month(&diaUtil_d1);
				ano = year(&diaUtil_d1);
			run;

			%put &D_mais_2;
			%put &DiaUtil_D0;

			proc sql;
				select anomes, DiaUtil_D1,   mes, ano, mesano

				into :anomes, :DiaUtil_D1, :mes, :ano, :mesano
					from arq;
			quit;

			%put &anomes &mesano &DiaUtil_D1 &ano &mes;


DATA _NULL_;
D1=DiaUtilAnterior(Today());
CALL SYMPUT('D1',D1);
run;

 
PROC SQL;
   CREATE TABLE Base_CLI_ANT AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.DT_LCTO_RAO,
          put(t1.DT_LCTO_RAO,yymmn6.) as ANOMES,        
          t1.VL_LCTO_RAO FORMAT=COMMAX19.2 AS VALOR
      
      FROM DIRAO.BASE_DIRAO_RAO_P_DIRCO_NOVA t1

      WHERE t1.CD_CNL_CTRC NOT IN 
           (
           1,
		   11,
           1008
           ) and (calculated ANOMES)="&ANOMES"
      ;
QUIT;


PROC SQL;
   CREATE TABLE Base_CLI_ANT_2 AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.DT_LCTO_RAO,
          put(t1.DT_PRCT,yymmn6.) as ANOMES,        
          t1.VL_LCTO_RAO FORMAT=COMMAX19.2 AS VALOR
      
      FROM DIRAO.BASE_DIRAO_RAO_P_DIRCO_NOVA t1

      WHERE t1.CD_CNL_CTRC NOT IN 
           (
           1,
		   11,
           1008
           ) AND put(t1.DT_LCTO_RAO,yymmn6.)="201907" AND put(t1.DT_PRCT,yymmn6.)="&ANOMES" /*AND t1.DT_PRCT > '02AUG2019'd*/
		   
      ;
QUIT;


PROC SQL;

CREATE TABLE BASE_JUNTOS AS

   SELECT * FROM Base_CLI_ANT
   OUTER UNION CORR 
   SELECT * FROM Base_CLI_ANT_2
       
   ;

Quit;


PROC SQL;
   CREATE TABLE Base_CLI AS 
   SELECT t1.CD_CLI, 
          t1.ANOMES, 
       
            SUM(VALOR) AS VALOR
      
      FROM BASE_JUNTOS t1
      
      GROUP BY 1,2;

QUIT;


PROC SQL;
	CREATE TABLE WORK.BASE_MCI AS 

       SELECT DISTINCT t1.CD_CLI
			
    FROM BASE_CLI t1
	WHERE t1.CD_CLI IS NOT MISSING
	ORDER BY 1

;QUIT;


%EncarteirarCNX(tabela_cli=BASE_MCI, tabela_saida=encarteiramento, aaaamm=&AnoMes., so_ag_paa=1);

			
PROC SQL;
   CREATE TABLE Valor_fim AS 
   SELECT t1.PREFDEP_ATB AS PREFDEP,
          t1.CTRA_ATB AS CARTEIRA,
           
          sum(t2.Valor) as valor
      FROM ENCARTEIRAMENTO t1
           INNER JOIN BASE_CLI t2 ON (t1.CD_CLI = t2.CD_CLI) group by 1,2;
QUIT;


PROC SQL;
	CREATE TABLE BBM AS
		SELECT 
			"20001530464"||REPEAT(" ",45)||Put(PREFDEP, Z4.)||Put(Carteira, Z5.)||"&AnoMes"||"0001+"||Put(Coalesce(Valor,0)*100, Z13.)||"F7176219"||Put("&DiaUtil_D1"d, ddmmyy10.)||"N" AS T
		FROM Valor_fim
		
			;
QUIT;


%let EB=BNRA&MES;

%GerarBBM(BBM, /dados/infor/transfer/enviar/, &EB);


PROC SQL;
   CREATE TABLE CPA.VALOR_FIM_&ANOMES. AS 
   SELECT       t1.CD_CLI, 
                t1.DT_PRCT,
                t1.DT_LCTO_RAO,
		        t1.VL_LCTO_RAO FORMAT 32.2 AS VALOR

   FROM dirao.BASE_DIRAO_RAO_P_DIRCO_NOVA t1
   WHERE t1.CD_CNL_CTRC NOT IN 
           (
           1,
		   11,
           1008
           ) and month(t1.DT_PRCT) = &mes. and year(t1.DT_PRCT) = &ano.     
   ;
QUIT;


x cd /dados/infor/producao/bonus_dirco_1s19 ;
x cd /dados/dirao/publico ;
x chmod 2777 *;




