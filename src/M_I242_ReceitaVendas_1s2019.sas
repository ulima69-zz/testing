
%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME DB2PRD DB2 DATABASE=BDB2P04 SCHEMA=DB2PRD  AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2MCI DB2 DATABASE=BDB2P04 SCHEMA=DB2MCI  AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2RST DB2 DATABASE=BDB2P04 SCHEMA=DB2RST  AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2DTM DB2 DATABASE=BDB2P04 SCHEMA=DB2DTM  AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2REL DB2 DATABASE=BDB2P04 SCHEMA=DB2REL  AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2ARH DB2 DATABASE=BDB2P04 SCHEMA=DB2ARH  AUTHDOMAIN='DB2SGCEN';

LIBNAME REC '/dados/infor/producao/Receita_Vendas';
LIBNAME DIRCO '/dados/dirco/publico/Gecen';
LIBNAME RIV '/dados/infor/producao/receita_interna';
LIBNAME CTUSU '/dados/infor/producao/Hst_Carteiras_II';

x cd /dados/infor/producao/Receita_Vendas;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/


PROC SQL;
   CREATE TABLE WORK.DIAS_UTEIS AS 
   SELECT t1.DT_TMP
      FROM DB2DTM.DIM_TMP_DT t1
      WHERE t1.IN_DD_UTIL = 'S' AND t1.DT_TMP < TODAY()
      ORDER BY t1.DT_TMP DESC;
QUIT;


DATA WORK.DIAS_UTEIS;
SET WORK.DIAS_UTEIS;
ORDEM = _N_;
RUN;


proc sql noprint;
   select DT_TMP format date9.
      into :data
      from WORK.DIAS_UTEIS
      where ORDEM = 3;
QUIT;


%put Referência GPF: &data;


data _null_;
if (month("&data"d)) < 10 then 
		do;
			nome = cat(year("&data"d),"0",month("&data"d));
			call symput("nome", nome);
		end;
	else
		do;
			nome = cat(year("&data"d),month("&data"d));
			call symput("nome", nome);
		end;

	 mmaaaa=PUT("&data"d,mmyyn6.);
     CALL SYMPUT('mmaaaa', COMPRESS(mmaaaa,' '));
run;


%put Nome do arquivo: &nome &MMAAAA &DATA;


/*************************************************************************************************************************/
/*************************************************************************************************************************/
/**************************************** RECEITA DE VENDAS - INDICADOR 242 **********************************************/
/*************************************************************************************************************************/
/*************************************************************************************************************************/


PROC SQL;
   CREATE TABLE RV_1 AS 
   SELECT DISTINCT 

          t1.CD_PRF_RSTD, 
          t1.CD_CLI, 
          t1.CD_IPMC_ITCE_CNL, 
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.VL_CPNT_RSTD, 
          t1.VL_ULT_SDO, 
          t1.DT_APRC,
          t1.CD_USU
		  
      FROM DB2RST.CLC_RSTD_GRNL t1
      WHERE CD_CLI NE 0 AND t1.DT_APRC >= '01jan2019'D AND t1.CD_CPNT_RSTD = 174 AND CD_PRF_RSTD NE 9903
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE RV_2 AS 
   SELECT DISTINCT 

          t1.CD_PRF_RSTD, 
          t1.CD_CLI, 
          t1.CD_IPMC_ITCE_CNL, 
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.VL_CPNT_RSTD, 
          t1.VL_ULT_SDO, 
          t1.DT_APRC,
          Input(COMPRESS(t1.CD_USU, 'F'), 9.) AS USUARIO

      FROM RV_1 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
	DROP TABLE DB2SGCEN.REC_VND_190429;
	CREATE TABLE DB2SGCEN.REC_VND_190429 AS
		SELECT DISTINCT DT_APRC Format yymmdd10., USUARIO Format Z9.
			FROM RV_2
				WHERE COALESCE(USUARIO,0) NE 0;
QUIT;


PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
	CREATE TABLE CMSS_LCZC AS
		SELECT *
			FROM CONNECTION TO DB2

				(SELECT A.USUARIO, 
                 DT_APRC, 
                 CD_TIP_CMSS_FUC AS CMSS, 
                 CD_PRF_DEPE_LCZC AS LCZC

					FROM REC_VND_190429 A
						LEFT JOIN DB2ARH.HST_CMSS_FUC_FUN B ON(A.USUARIO=B.CD_MTC_FUN AND A.DT_APRC BETWEEN B.DT_INC_CMSS_FUN AND B.DT_FIM_CMSS_FUN)
						LEFT JOIN DB2ARH.HST_LCZC_FUN C ON(A.USUARIO=C.CD_MTC_FUN AND A.DT_APRC BETWEEN C.DT_INC_LCZC_FUN AND C.DT_FIM_LCZC_FUN));
	DROP TABLE DB2SGCEN.REC_VND_190429;
QUIT;


PROC SQL;
   CREATE TABLE CMSS_LCZC_1 AS 
   SELECT DISTINCT 

          t1.USUARIO FORMAT 7. AS USUARIO, 
          t1.DT_APRC FORMAT yymmdd10. AS DT_APRC, 
          t1.CMSS, 
          t1.LCZC
 
      FROM CMSS_LCZC t1
      WHERE LCZC IS NOT MISSING AND t1.CMSS IS NOT MISSING
      ORDER BY 1,2;
QUIT;



/************************/
/************************/
/************************/
/***********MARCO********/

PROC SQL;

   CREATE TABLE CARTEIRAS_MAR_1 AS 
      SELECT DISTINCT 

          t1.CD_TIP_CTRA AS TC
		            
      FROM COMUM.PAI_REL_201903 t1
	  WHERE nr_seql_ctra_atb <> 7002 AND t1.CD_TIP_CTRA IS NOT MISSING
      ORDER BY 1;

QUIT;


PROC SQL NOPRINT;
	SELECT '('||COMPRESS('TC='||Put(TC, 3.))||')' INTO :VRV3 SEPARATED BY ' OR '
	FROM CARTEIRAS_MAR_1;
QUIT;


%PUT &VRV3;


PROC SQL;
   CREATE TABLE CARTEIRAS_MAR_2 AS 
   SELECT DISTINCT
   
   t1.PREFDEP,
   IFC(&VRV3., t1.CARTEIRA, '7002') AS CARTEIRA,
   t1.MATRICULA,
   t1.POSICAO,
   t1.TC   
 
      FROM CTUSU.captura_primaria_201901 t1
	  WHERE MONTH(t1.POSICAO) = 03
	  ORDER BY 1,2,3,4;
QUIT;


/************************/
/************************/
/************************/
/********ABRIL***********/

PROC SQL;

   CREATE TABLE CARTEIRAS_ABR_1 AS 
      SELECT DISTINCT 

          t1.CD_TIP_CTRA AS TC
		            
      FROM COMUM.PAI_REL_201904 t1
	  WHERE nr_seql_ctra_atb <> 7002 AND t1.CD_TIP_CTRA IS NOT MISSING
      ORDER BY 1;

QUIT;


PROC SQL NOPRINT;
	SELECT '('||COMPRESS('TC='||Put(TC, 3.))||')' INTO :VRV4 SEPARATED BY ' OR '
	FROM CARTEIRAS_ABR_1;
QUIT;


%PUT &VRV4;


PROC SQL;
   CREATE TABLE CARTEIRAS_ABR_2 AS 
   SELECT DISTINCT
   
   t1.PREFDEP,
   IFC(&VRV4., t1.CARTEIRA, '7002') AS CARTEIRA,
   t1.MATRICULA,
   t1.POSICAO,
   t1.TC 
 
      FROM CTUSU.captura_primaria_201901 t1
	  WHERE MONTH(t1.POSICAO) = 04
	  ORDER BY 1,2,3,4;
QUIT;


/************************/
/************************/
/************************/
/*********MAIO***********/

PROC SQL;

   CREATE TABLE CARTEIRAS_MAI_1 AS 
      SELECT DISTINCT 

          t1.CD_TIP_CTRA AS TC
		            
      FROM COMUM.PAI_REL_201905 t1
	  WHERE nr_seql_ctra_atb <> 7002 AND t1.CD_TIP_CTRA IS NOT MISSING
      ORDER BY 1;

QUIT;


PROC SQL NOPRINT;
	SELECT '('||COMPRESS('TC='||Put(TC, 3.))||')' INTO :VRV5 SEPARATED BY ' OR '
	FROM CARTEIRAS_MAI_1;
QUIT;


%PUT &VRV5;


PROC SQL;
   CREATE TABLE CARTEIRAS_MAI_2 AS 
   SELECT DISTINCT
   
   t1.PREFDEP,
   IFC(&VRV5., t1.CARTEIRA, '7002') AS CARTEIRA,
   t1.MATRICULA,
   t1.POSICAO,
   t1.TC   
 
      FROM CTUSU.captura_primaria_201901 t1
	  WHERE MONTH(t1.POSICAO) = 05
	  ORDER BY 1,2,3,4;
QUIT;


/************************/
/************************/
/************************/
/**JUNTANDO OS MESES*****/

PROC SQL;

CREATE TABLE SEMESTRE AS   
   SELECT * FROM CARTEIRAS_MAR_2
   OUTER UNION CORR
   SELECT * FROM CARTEIRAS_ABR_2
   OUTER UNION CORR
   SELECT * FROM CARTEIRAS_MAI_2
   ;

Quit;


PROC SQL;
   CREATE TABLE SEMESTRE AS 
   SELECT DISTINCT
   
   t1.PREFDEP,
   t1.CARTEIRA,
   t1.MATRICULA FORMAT 7. AS MATRICULA,
   t1.POSICAO FORMAT yymmdd10. AS POSICAO,
   t1.TC   
 
      FROM SEMESTRE t1
	  ORDER BY 1,2,3,4,5;
QUIT;


PROC SQL;
   CREATE TABLE CMSS_LCZC_2 AS 
   SELECT DISTINCT 

          t1.USUARIO, 
          t1.DT_APRC, 
          t1.CMSS,
          /*t1.LCZC,*/		  
		  t2.PREFDEP AS CD_PRF_DEPE,
          t2.CARTEIRA AS NR_SEQL_CTRA
 
      FROM CMSS_LCZC_1 t1
	  INNER JOIN SEMESTRE t2 ON t1.USUARIO = t2.MATRICULA and t1.DT_APRC = t2.POSICAO
	  WHERE TC IN (67 68)
      ORDER BY 1,2;
QUIT;


PROC SQL;
   CREATE TABLE CMSS_LCZC_3 AS 
   SELECT DISTINCT 

          t1.USUARIO, 
          t1.DT_APRC, 
          t1.CMSS, 
		  t1.CD_PRF_DEPE,
          MAX(t1.NR_SEQL_CTRA) AS NR_SEQL_CTRA		  
 
      FROM CMSS_LCZC_2 t1
	  GROUP BY 1, 2, 3
      ORDER BY 1
      ;
QUIT;


PROC SQL;
   CREATE TABLE RV_3 AS 
   SELECT DISTINCT 	  

		  t1.CD_PRF_RSTD, 
          t1.CD_CLI, 
          t1.CD_IPMC_ITCE_CNL, 
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.VL_CPNT_RSTD, 
          t1.VL_ULT_SDO, 
          t1.DT_APRC,
          t1.USUARIO,
		  t2.CMSS,
		  t2.CD_PRF_DEPE,
          t2.NR_SEQL_CTRA

      FROM RV_2 t1
	  LEFT JOIN CMSS_LCZC_3 t2 ON t1.USUARIO = t2.USUARIO AND t1.DT_APRC = t2.DT_APRC
      ;
QUIT;


/*********************************************/
/*********************************************/
/*********************************************/
/*********************************************/


PROC SQL;
   CREATE TABLE WORK.BASE_MCI AS 
   SELECT DISTINCT t1.CD_CLI
      FROM RV_3 t1
WHERE CD_CLI NE 0;
QUIT;


%Macro Encarteiramento;

	PROC SQL;
		LIBNAME ENC "/dados/infor/producao/tbls_comuns";
		CREATE TABLE ENCARTEIRAMENTO AS
			SELECT Put(CD_PRF_DEPE, Z4.) AS PrefDep,
				nr_seql_ctra_atb as carteira,
				case when nr_seql_ctra_atb = 7002 then 700 else cd_tip_ctra end as tc,
				E.CD_CLI
			FROM COMUM.PAI_REL_&NOME E
				INNER JOIN BASE_MCI A ON(E.CD_CLI=A.CD_CLI)
					ORDER BY 4;
	QUIT;

	PROC SQL NOPRINT;
		SELECT COUNT(*) INTO: Q
			FROM (SELECT CD_CLI
			FROM ENCARTEIRAMENTO
				GROUP BY 1
					HAVING COUNT(*)>1);
	QUIT;

	%Put &Q;

	%IF &Q>0 %THEN
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

				PROC DELETE DATA=FIM_DUP AUX_D;
				RUN;

			%END;
		%END;

	PROC SQL NOPRINT;
		SELECT COUNT(*) INTO: Q
			FROM (SELECT DISTINCT A.CD_CLI
			FROM BASE_MCI A
				LEFT JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI)
					WHERE B.CD_CLI Is Missing);
	QUIT;

	%Put &Q;

	%IF &Q>0 %THEN
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

			%DO I=1 %TO &Q;

				PROC SQL NOPRINT;
					SELECT CD_CLI Format 9. INTO: Var Separated By ', '
						FROM AUX_P
							WHERE Grupo=&I;
				QUIT;

				%LET Filtro=B.TipoDep In('013' '015' '035') AND SB='00';

				PROC SQL;
					CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
					INSERT INTO PERDIDOS
						SELECT Put(COD_PREF_AGEN, Z4.) AS PrefDep, 7002 AS Carteira,
							700 AS TC, COD AS CD_CLI
						FROM CONNECTION TO DB2
							(SELECT COD, COD_PREF_AGEN, 
								7002 AS CARTEIRA, 700 AS TC
							FROM DB2MCI.CLIENTE
								WHERE COD IN(&Var)
									ORDER BY COD;) A
										INNER JOIN IGR.DEPENDENCIAS B ON(A.COD_PREF_AGEN=Input(B.PrefDep, 4.))
											WHERE &Filtro;
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

			PROC DELETE DATA=AUX_P PERDIDOS DUPLICADOS;
			RUN;

			PROC SQL;
				DELETE FROM ENCARTEIRAMENTO
					WHERE PrefDep Not In(SELECT DISTINCT PrefDep
						FROM IGR.IGRREDE_&NOME
							WHERE TipoDep In('01' '09') AND PrefDep NE '4777');
			QUIT;

		%END;
%Mend;


%Encarteiramento;


PROC SQL;
	CREATE TABLE RECEITA_PRD AS 
		SELECT        

			T3.PREFDEP,
			T3.CARTEIRA,
			t1.CD_PRF_RSTD, /*rlz no prefixo*/
			t1.CD_CLI, 
			t1.CD_IPMC_ITCE_CNL, 
			t1.CD_MDLD, 
			t1.CD_PRD,
			T2.NM_MDLD,
			t2.CD_CTRG_PRD, 
		(CASE 
			WHEN t2.CD_CTRG_PRD=1 THEN 'CAPTACAO'
			WHEN t2.CD_CTRG_PRD=2 THEN 'APLICACAO/CREDITO'
			WHEN t2.CD_CTRG_PRD=3 THEN 'SERVICOS' 
		END)
	AS CATEGORIA,
		t1.VL_CPNT_RSTD, 
		t1.VL_ULT_SDO, 
		t1.DT_APRC,
		t1.USUARIO,
		t1.CMSS,
		t1.CD_PRF_DEPE,
        t1.NR_SEQL_CTRA

	FROM WORK.rv_3 t1
		INNER JOIN DB2PRD.MDLD_PRD T2 ON (T1.CD_PRD=T2.CD_PRD AND T1.CD_MDLD=T2.CD_MDLD)
		INNER JOIN ENCARTEIRAMENTO T3 ON (T1.CD_CLI=T3.CD_CLI)
			WHERE T1.CD_CLI NE 0 and t1.CD_IPMC_ITCE_CNL IN (1,3,4,55,10,12,14,20,67)
				ORDER BY 2;
QUIT;


PROC SQL;
	CREATE TABLE RECEITA_PRD_1 AS 
		SELECT       

		IFN(t1.CD_PRF_DEPE IS NOT MISSING AND t1.NR_SEQL_CTRA IS NOT MISSING, INPUT(t1.CD_PRF_DEPE, 4.), INPUT(t1.PrefDep, 4.)) AS PREFDEP,
		IFN(t1.CD_PRF_DEPE IS NOT MISSING AND t1.NR_SEQL_CTRA IS NOT MISSING, INPUT(t1.NR_SEQL_CTRA, 5.), t1.CARTEIRA) AS CARTEIRA,
				
			INPUT(t1.PrefDep, 4.) AS PREFDEP_ORIGINAL,
			t1.CARTEIRA AS CARTEIRA_ORIGINAL,

			t1.CD_PRF_RSTD, 
			t1.CD_CLI, 
			t1.CD_IPMC_ITCE_CNL, 
			t1.CD_MDLD, 
			t1.CD_PRD,
			t1.NM_MDLD,
			t1.CD_CTRG_PRD, 

		t1.CATEGORIA,
		t1.VL_CPNT_RSTD, 
		t1.VL_ULT_SDO, 
		t1.DT_APRC,
		t1.USUARIO,
		t1.CMSS,
		t1.CD_PRF_DEPE,
        t1.NR_SEQL_CTRA

	FROM RECEITA_PRD t1;
QUIT;


%BuscarPrefixosIndicador(IND=242, MMAAAA=&MMAAAA, NIVEL_CTRA=1, SO_AG_PAA=0);


PROC SQL;
	CREATE TABLE RECEITA_GERAL AS 
		SELECT       

		t1.*

	FROM RECEITA_PRD_1 t1
    INNER JOIN PREFIXOS_IND_000000242 T2 ON t1.PREFDEP=t2.PREFDEP AND T1.CARTEIRA=T2.CTRA;

QUIT;


PROC SQL;
   CREATE TABLE RV_CLIENTE AS 
   SELECT DISTINCT 

            t1.PrefDep, 
			t1.Carteira AS CTRA, 
			t1.CD_CLI, 

			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO

      FROM RECEITA_GERAL t1	 
      GROUP BY 1,2,3;

QUIT;


PROC SQL;
   CREATE TABLE RV_CARTEIRA AS 
   SELECT DISTINCT 

            t1.PrefDep, 
			t1.Carteira AS CTRA,

			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO

      FROM RECEITA_GERAL t1	 
      GROUP BY 1,2;

QUIT;


/*****************************/
/*****************************/
/*****************************/
/*****************************/


/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COLS_SUM;
	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COLS_SUM VALUES ('VL_CPNT_RSTD', 'SUM', 'VL_CPNT_RSTD');
	INSERT INTO COLS_SUM VALUES ('VL_ULT_SDO', 'SUM', 'VL_ULT_SDO');
QUIT;
%SumarizadorCNX(TblSASValores=RV_CARTEIRA, TblSASColunas=COLS_SUM, NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL_RV, AAAAMM=&NOME.);


%BuscarPrefixosIndicador(IND=000000242, MMAAAA=&MMAAAA, NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarOrcado(IND=000000242, MMAAAA=&MMAAAA);
%BuscarComponentesIndicador(000000242);


PROC SQL;
	CREATE TABLE RESULTADO_RV AS 
		SELECT 
			"&data"d  AS POSICAO,
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			T2.VLR_ORC,
			t1.VL_CPNT_RSTD as VLR_RLZ,
			t1.VL_ULT_SDO
		FROM WORK.FINAL_RV t1
			right JOIN ORCADOS_000000242 t2 on (t1.prefdep=t2.prefdep AND T1.UOR=T2.UOR AND T1.CTRA=T2.CTRA)
				INNER JOIN PREFIXOS_IND_000000242 T3 ON (T1.PREFDEP=T3.PREFDEP AND T1.CTRA=T3.CTRA);
QUIT;



PROC SQL;
	CREATE TABLE CNX_RV AS 
		SELECT DISTINCT 
			242 AS IND, 
			0 AS COMP,
			0 AS COMP_PAI,
			0 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VLR_RLZ AS VLR_RLZ,
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_RV t1, WORK.ORCADOS_000000242 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
;QUIT;


PROC SQL;
	CREATE TABLE RV_COMP AS 
		SELECT DISTINCT 
			242 AS IND, 
			1 AS COMP,
			0 AS COMP_PAI,
			1 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VLR_RLZ AS VLR_RLZ, 
			. AS VLR_ORC,
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_RV t1 , WORK.ORCADOS_000000242 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0
;
QUIT;

/*%BaseIndicadorCNX(TabelaSAS=CNX_RV);*/
/*%BaseIndicadorCNX(TabelaSAS=RV_COMP);*/

/*%ExportarCNX_IND(IND=000000242, MMAAAA=&MMAAAA);*/


PROC SQL;
	CREATE TABLE BASE_CLI_RV AS 
		SELECT 
	000000242 AS IND, /*CODIGO INDICADOR*/
	0 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/
	input(T2.UOR,9.) as UOR, 
	t1.PREFDEP,
	CTRA,
    T1.CD_CLI AS CLI, 
    input(PUT(POSICAO, mmyyn6.),6.) as mmaaaa,
	VL_CPNT_RSTD AS VLR
	FROM WORK.RV_CLIENTE t1
		INNER JOIN IGR.DEPENDENCIAS_&NOME. T2 ON (T1.PREFDEP=input(t2.PREFDEP, 4.))
			WHERE T2.SB='00' AND T2.STATUS= 'A';
QUIT;



/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CLI_RV);*/
/*%ExportarCNX_CLI(IND=000000242,  MMAAAA=&MMAAAA);*/



x cd /dados/infor/producao/Receita_Vendas;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/



/*FIM*/

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
