
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


%Macro Encarteiramento;

	proc sql;
		create table encarteiramento as
			select put(cd_prf_depe, z4.) as prefdep,
				nr_seql_ctra_ATB as carteira,
				e.cd_cli
			from comum.pai_rel_&AnoMes e
				inner join base_mci a on(e.cd_cli=a.cd_cli)
					where cd_prf_depe not in(4777 8008 9940)
						order by 3;
	quit;

	proc sql noprint;
		select count(*) into: q
			from (select cd_cli
			from encarteiramento
				group by 1
					having count(*)>1);
	quit;

	%put &q;

	%IF &Q>0 %THEN
		%DO;

			DATA DUPLICADOS(DROP=CARTEIRA);
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

			%DO I=1 %TO &Q;

				PROC SQL NOPRINT;
					SELECT CD_CLI INTO: Var Separated By ', '
						FROM AUX_D
							WHERE Grupo=&I;
				QUIT;

				PROC SQL;
					CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
					INSERT INTO DUPLICADOS
						SELECT Put(COD_PREF_AGEN, Z4.), COD
							FROM CONNECTION TO DB2
								(SELECT COD, COD_PREF_AGEN
									FROM DB2MCI.CLIENTE
										WHERE COD IN(&Var)
											ORDER BY COD;);
					DISCONNECT FROM DB2;
				QUIT;

				PROC SQL;
					CREATE TABLE FIM_DUP AS
						SELECT A.*, carteira
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

	PROC DELETE DATA=FIM_DUP AUX_D;
	RUN;

	PROC SQL NOPRINT;
		SELECT COUNT(*) INTO: Q
			FROM (SELECT DISTINCT A.CD_CLI
			FROM base_mci A
				LEFT JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI)
					WHERE B.CD_CLI Is Missing);
	QUIT;

	%IF &Q>0 %THEN
		%DO;

			DATA PERDIDOS;
				SET ENCARTEIRAMENTO(Obs=0);
			RUN;

			PROC SQL;
				CREATE TABLE AUX_P AS
					SELECT DISTINCT A.CD_CLI
						FROM base_mci A
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

			%DO I=1 %TO &Q;

				/*				PROC SQL;*/
				/*					DROP TABLE DB2SGCEN.APAGAR_180205;*/
				/*					CREATE TABLE DB2SGCEN.APAGAR_180205 AS*/
				/*						SELECT DISTINCT CD_CLI FORMAT Z9.*/
				/*							FROM AUX_P;*/
				/*				QUIT;*/
				PROC SQL NOPRINT;
					SELECT CD_CLI Format 9. INTO: Var Separated By ', '
						FROM AUX_P
							WHERE Grupo=&I;
				QUIT;

				%LET Filtro=B.TipoDep In('013' '015' '035') AND SB='00';

				PROC SQL;
					CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
					INSERT INTO PERDIDOS
						SELECT Put(COD_PREF_AGEN, Z4.) AS PrefDep, 
							7002 AS Carteira,
							COD AS CD_CLI
						FROM CONNECTION TO DB2
							(SELECT COD, 
								COD_PREF_AGEN
							FROM DB2MCI.CLIENTE A 
								/*								INNER JOIN DB2SGCEN.APAGAR_180205 B ON(A.COD=B.CD_CLI)*/
							WHERE COD IN(&Var)
								ORDER BY COD;) A
									INNER JOIN IGR.DEPENDENCIAS B ON(A.COD_PREF_AGEN=Input(B.PrefDep, 4.))
										WHERE &Filtro;
					DISCONNECT FROM DB2;

					/*					DROP TABLE DB2SGCEN.APAGAR_180205;*/
				QUIT;

			%END;

			PROC SORT DATA=PERDIDOS NODUPKEY;
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
          t1.DT_PRCT AS DT_LCTO_RAO,
          /*put(t1.DT_LCTO_RAO,yymmn6.) as ANOMES_LCTO,*/ 
		  put(t1.DT_PRCT,yymmn6.) as ANOMES,
 
          t1.VL_LCTO_RAO FORMAT=COMMAX19.2 AS VALOR
      
      FROM DIRAO.BASE_DIRAO_RAO_P_DIRCO_NOVA t1

      WHERE t1.CD_CNL_CTRC NOT IN 
           (
           1,
		   11,
           1008
           ) AND (put(t1.DT_LCTO_RAO,yymmn6.)) IN ('201904' '201905') AND (calculated ANOMES)= "&ANOMES"
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


	data base_mci(keep = cd_cli);
				set Base_CLI;

			run;

			proc sort data = base_mci nodupkey;
				by cd_cli;
			run;

			%Encarteiramento;

			
PROC SQL;
   CREATE TABLE Valor_fim AS 
   SELECT t1.prefdep, 
          t1.carteira, 
          sum(t2.Valor) as valor
      FROM ENCARTEIRAMENTO t1
           INNER JOIN BASE_CLI t2 ON (t1.CD_CLI = t2.CD_CLI) group by 1,2;
QUIT;


PROC SQL;
	CREATE TABLE BBM AS
		SELECT 
			"20001530464"||REPEAT(" ",45)||PrefDep||Put(Carteira, Z5.)||"&AnoMes"||"0001+"||Put(Coalesce(Valor,0)*100, Z13.)||"F7176219"||Put("&DiaUtil_D1"d, ddmmyy10.)||"N" AS T
		FROM Valor_fim
		
			;
QUIT;


%let EB=BNRA&MES;


/*%GerarBBM(BBM, /dados/infor/transfer/enviar/, &EB);*/


PROC SQL;
   CREATE TABLE CPA.VALOR_FIM AS 
   SELECT       t1.CD_CLI, 
                t1.DT_PRCT,
                t1.DT_LCTO_RAO,
		        t1.VL_LCTO_RAO FORMAT=COMMAX19.2 AS VALOR

   FROM dirao.BASE_DIRAO_RAO_P_DIRCO_NOVA t1
   WHERE t1.CD_CNL_CTRC NOT IN 
           (
           1,
		   11,
           1008
           )
   ;
QUIT;

/*

PROC SQL;
   CREATE TABLE CPA.VALOR_FIM_ANTIGO AS 
   SELECT       t1.CD_CLI, 
                t1.DT_LCTO,
		        t1.VL_LCTO FORMAT=COMMAX19.2 AS VALOR

   FROM dirao.base_dirao_rao_p_dirco t1
   WHERE t1.CD_CNL_CTRC NOT IN 
           (
           1,
		   1008
           )
   ;
QUIT;

*/

x cd /dados/infor/producao/bonus_dirco_1s19 ;
x cd /dados/dirao/publico ;
x chmod 2777 *;




