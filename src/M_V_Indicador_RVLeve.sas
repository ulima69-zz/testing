%include '/dados/infor/suporte/FuncoesInfor.sas';
LIBNAME DB2PRD DB2 DATABASE=BDB2P04 SCHEMA=DB2PRD  AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2MCI DB2 DATABASE=BDB2P04 SCHEMA=DB2MCI  AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2RST DB2 DATABASE=BDB2P04 SCHEMA=DB2RST  AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2DTM DB2 DATABASE=BDB2P04 SCHEMA=DB2DTM  AUTHDOMAIN='DB2SGCEN';


LIBNAME REC '/dados/infor/producao/Receita_Vendas';

LIBNAME RIV '/dados/infor/producao/receita_interna';


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




/**/
/*VISÃO: ACUMULADA */
/*NIVEL: MCI/CARTEIRA*/
/**/
/*CANAL - */
/*1 3 4 10 55 AND 7648*/



PROC SQL;
   CREATE TABLE RECEITA_VENDAS AS 
   SELECT DISTINCT t1.CD_PRF_RSTD, 
          t1.CD_CLI, 
          t1.CD_IPMC_ITCE_CNL, 
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.VL_CPNT_RSTD, 
          t1.VL_ULT_SDO, 
          t1.DT_APRC
      FROM DB2RST.CLC_RSTD_GRNL t1
      WHERE CD_CLI NE 0 AND t1.DT_APRC >= '01jan2019'D AND t1.CD_CPNT_RSTD = 174 AND CD_PRF_RSTD NE 9903 ;
QUIT;


PROC SQL;
   CREATE TABLE WORK.BASE_MCI AS 
   SELECT DISTINCT t1.CD_CLI
      FROM WORK.RECEITA_VENDAS t1
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
		t1.DT_APRC
	FROM WORK.RECEITA_VENDAS t1
		INNER JOIN DB2PRD.MDLD_PRD T2 ON (T1.CD_PRD=T2.CD_PRD AND T1.CD_MDLD=T2.CD_MDLD)
		INNER JOIN ENCARTEIRAMENTO T3 ON (T1.CD_CLI=T3.CD_CLI)
			WHERE T1.CD_CLI NE 0
				ORDER BY 2;
QUIT;



PROC SQL;
   CREATE TABLE REC.RECEITA_GERAL_&NOME AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.Carteira, 
          t1.CD_CLI,
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.NM_MDLD, 
          t1.CD_CTRG_PRD, 
          t1.CATEGORIA, 
            (SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
            (SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO, 
          t1.DT_APRC
      FROM WORK.RECEITA_PRD t1
	  WHERE  t1.CD_IPMC_ITCE_CNL IN (1,3,4,55,10,12,14,20,67)
      GROUP BY 1,2,3,4,5,6,7,8,11
              ;
QUIT;


/*************************************************************************************************************************/
/*************************************************************************************************************************/
/**************************************** RECEITA DE VENDAS - CAPTACAO ***************************************************/
/*************************************************************************************************************************/
/*************************************************************************************************************************/

%BuscarPrefixosIndicador(IND=172, MMAAAA=&MMAAAA, NIVEL_CTRA=1, SO_AG_PAA=0);


PROC SQL;
	CREATE TABLE CAPTACAO_CLIENTE AS 
		SELECT DISTINCT 
			t1.PrefDep, 
			t1.Carteira, 
			t1.CD_CLI, 
			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO
		FROM REC.RECEITA_GERAL_&NOME t1
		INNER JOIN PREFIXOS_IND_000000172 T2 ON (INPUT(T1.PREFDEP,4.)=T2.PREFDEP AND T1.CARTEIRA=T2.CTRA)
			WHERE CD_CTRG_PRD = 1 
				GROUP BY 1, 2, 3;
QUIT;


PROC SQL;
	CREATE TABLE CAPTACAO_CARTEIRA AS 
		SELECT DISTINCT 
			INPUT(t1.PrefDep, 4.) AS PREFDEP,
			t1.Carteira AS CTRA,
			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO
		FROM REC.RECEITA_GERAL_&NOME t1
		INNER JOIN PREFIXOS_IND_000000172 T2 ON (INPUT(T1.PREFDEP,4.)=T2.PREFDEP AND T1.CARTEIRA=T2.CTRA)
			WHERE CD_CTRG_PRD = 1 
				GROUP BY 1, 2;
QUIT;



/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COLS_SUM;
	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COLS_SUM VALUES ('VL_CPNT_RSTD', 'SUM', 'VL_CPNT_RSTD');
	INSERT INTO COLS_SUM VALUES ('VL_ULT_SDO', 'SUM', 'VL_ULT_SDO');
QUIT;
%SumarizadorCNX(TblSASValores=CAPTACAO_CARTEIRA, TblSASColunas=COLS_SUM, NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL_CAPTACAO, AAAAMM=&NOME.);


%BuscarPrefixosIndicador(IND=000000172, MMAAAA=&MMAAAA, NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarOrcado(IND=000000172, MMAAAA=&MMAAAA);
%BuscarComponentesIndicador(000000172);


PROC SQL;
	CREATE TABLE RESULTADO_CAPTACAO AS 
		SELECT 
			"&data"d  FORMAT DDMMYY10. AS POSICAO,
			t1.UOR, 
			t2.PREFDEP, 
			t1.CTRA, 
			T2.VLR_ORC,
			t1.VL_CPNT_RSTD as VLR_RLZ,
			t1.VL_ULT_SDO
		FROM WORK.FINAL_CAPTACAO t1
			right JOIN ORCADOS_000000172 t2 on (t1.prefdep=t2.prefdep AND T1.UOR=T2.UOR AND T1.CTRA=T2.CTRA)
				INNER JOIN PREFIXOS_IND_000000172 T3 ON (T2.PREFDEP=T3.PREFDEP AND T2.CTRA=T3.CTRA)
ORDER BY 2,3;
QUIT;



PROC SQL;
	CREATE TABLE CNX_CAPTACAO AS 
		SELECT DISTINCT 
			t2.IND, 
			t2.COMP,
			0 AS COMP_PAI,
			0 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VLR_RLZ AS VLR_RLZ, 
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_CAPTACAO t1, WORK.ORCADOS_000000172 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
QUIT;


PROC SQL;
	CREATE TABLE CAPTACAO_COMP AS 
		SELECT DISTINCT 
			t2.IND, 
			1 AS COMP,
			0 AS COMP_PAI,
			1 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VLR_RLZ AS VLR_RLZ, 
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_CAPTACAO t1, WORK.ORCADOS_000000172 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
QUIT;

%BaseIndicadorCNX(TabelaSAS=CNX_CAPTACAO);
%BaseIndicadorCNX(TabelaSAS=CAPTACAO_COMP);

%ExportarCNX_IND(IND=000000172, MMAAAA=&MMAAAA);


PROC SQL;
	CREATE TABLE BASE_CLI_CAPTACAO AS 
		SELECT 
	000000172 AS IND, /*CODIGO INDICADOR*/
	0 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/
	input(T2.UOR,9.) as UOR, 
	INPUT(T1.PREFDEP, 4.) AS PREFDEP,
	CARTEIRA AS CTRA,
    T1.CD_CLI AS CLI, 
    input(PUT(POSICAO, mmyyn6.),6.) as mmaaaa,
	VL_CPNT_RSTD AS VLR
	FROM WORK.CAPTACAO_CLIENTE t1
		INNER JOIN IGR.DEPENDENCIAS_&NOME. T2 ON (T1.PREFDEP=T2.PREFDEP)
			WHERE T2.SB='00' AND T2.STATUS= 'A';
QUIT;



%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CLI_CAPTACAO);
%ExportarCNX_CLI(IND=000000172,  MMAAAA=&MMAAAA);



/*************************************************************************************************************************/
/*************************************************************************************************************************/
/**************************************** RECEITA DE VENDAS - SERVICOS ***************************************************/
/*************************************************************************************************************************/
/*************************************************************************************************************************/



%BuscarPrefixosIndicador(IND=173, MMAAAA=&MMAAAA, NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarOrcado(IND=173, MMAAAA=&MMAAAA);
%BuscarComponentesIndicador(173);


PROC SQL;
	CREATE TABLE SERVICOS_CLIENTES AS 
		SELECT DISTINCT 
			t1.PrefDep, 
			t1.Carteira, 
			t1.CD_CLI, 
			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO
		FROM REC.RECEITA_GERAL_&NOME t1
		INNER JOIN PREFIXOS_IND_000000173 T2 ON (INPUT(T1.PREFDEP,4.)=T2.PREFDEP AND CARTEIRA=CTRA)
			WHERE CD_CTRG_PRD = 3 
				GROUP BY 1, 2, 3;
QUIT;




PROC SQL;
	CREATE TABLE SERVICOS_CARTEIRA AS 
		SELECT DISTINCT 
			INPUT(t1.PrefDep, 4.) AS PREFDEP,
			t1.Carteira AS CTRA,
			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO
		FROM WORK.SERVICOS_CLIENTES t1
		INNER JOIN PREFIXOS_IND_000000173 T2 ON (INPUT(T1.PREFDEP,4.)=T2.PREFDEP AND T1.CARTEIRA=T2.CTRA) 
				GROUP BY 1, 2;
QUIT;

/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COLS_SUM;
	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COLS_SUM VALUES ('VL_CPNT_RSTD', 'SUM', 'VL_CPNT_RSTD');
	INSERT INTO COLS_SUM VALUES ('VL_ULT_SDO', 'SUM', 'VL_ULT_SDO');
QUIT;
%SumarizadorCNX(TblSASValores=SERVICOS_CARTEIRA, TblSASColunas=COLS_SUM, NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL_SERVICOS, AAAAMM=&NOME.);

PROC SQL;
	CREATE TABLE RESULTADO_SERVICOS AS 
		SELECT 
			"&data"d AS POSICAO,
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA,
			t1.VL_CPNT_RSTD, 
			t1.VL_ULT_SDO
		FROM WORK.FINAL_SERVICOS t1
			right JOIN ORCADOS_000000173 t2 on (t1.prefdep=t2.prefdep AND T1.UOR=T2.UOR AND T1.CTRA=T2.CTRA)
				INNER JOIN PREFIXOS_IND_000000173 T3 ON (T2.PREFDEP=T3.PREFDEP AND T2.CTRA=T3.CTRA);;
QUIT;




PROC SQL;
	CREATE TABLE CNX_SERVICOS AS 
		SELECT DISTINCT 
			t2.IND, 
			0 AS comp,
			0 AS COMP_PAI,
			0 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VL_CPNT_RSTD AS VLR_RLZ, 
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_SERVICOS t1, WORK.ORCADOS_000000173 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
QUIT;




PROC SQL;
	CREATE TABLE SERVICOS_COMP AS 
		SELECT DISTINCT 
			t2.IND, 
			1 AS comp,
			0 AS COMP_PAI,
			1 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VL_CPNT_RSTD AS VLR_RLZ, 
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_SERVICOS t1, WORK.ORCADOS_000000173 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
QUIT;

%BaseIndicadorCNX(TabelaSAS=CNX_SERVICOS);
%BaseIndicadorCNX(TabelaSAS=SERVICOS_COMP);
%ExportarCNX_IND(IND=000000173, MMAAAA=&MMAAAA);



PROC SQL;
	CREATE TABLE BASE_CLI_SERVICOS AS 
		SELECT 
	000000173 AS IND, /*CODIGO INDICADOR*/
	0 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/
	input(T2.UOR,9.) as UOR, 
	INPUT(T1.PREFDEP, 4.) AS PREFDEP,
	CARTEIRA AS CTRA,
    T1.CD_CLI AS CLI, 
    input(PUT(POSICAO, mmyyn6.),6.) as mmaaaa,
	VL_CPNT_RSTD AS VLR
	FROM WORK.SERVICOS_CLIENTES t1
		INNER JOIN IGR.DEPENDENCIAS_&NOME. T2 ON (T1.PREFDEP=T2.PREFDEP)
			WHERE T2.SB='00' AND T2.STATUS= 'A';
QUIT;

%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CLI_SERVICOS);

%ExportarCNX_CLI(IND=000000173,  MMAAAA=&MMAAAA);





/*************************************************************************************************************************/
/*************************************************************************************************************************/
/**************************************** RECEITA DE VENDAS - CREDITO  ***************************************************/
/*************************************************************************************************************************/
/*************************************************************************************************************************/







%BuscarPrefixosIndicador(IND=174, MMAAAA=&MMAAAA, NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarOrcado(IND=174, MMAAAA=&MMAAAA);
%BuscarComponentesIndicador(174);




PROC SQL;
	CREATE TABLE CREDITO_CLIENTES AS 
		SELECT DISTINCT 
			t1.PrefDep, 
			t1.Carteira, 
			t1.CD_CLI, 
			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO
		FROM REC.RECEITA_GERAL_&NOME t1
		INNER JOIN PREFIXOS_IND_000000174 T2 ON (INPUT(T1.PREFDEP,4.)=T2.PREFDEP AND CARTEIRA=CTRA)
			WHERE CD_CTRG_PRD = 2 
				GROUP BY 1, 2, 3;
QUIT;



PROC SQL;
	CREATE TABLE CREDITO_CARTEIRA AS 
		SELECT DISTINCT 
			INPUT(t1.PrefDep, 4.) AS PREFDEP,
			t1.Carteira AS CTRA,
			(SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
			(SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO
		FROM WORK.CREDITO_CLIENTES t1
		INNER JOIN PREFIXOS_IND_000000174 T2 ON (INPUT(T1.PREFDEP,4.)=T2.PREFDEP AND T1.CARTEIRA=T2.CTRA)
				GROUP BY 1, 2;
QUIT;



/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COLS_SUM;
	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COLS_SUM VALUES ('VL_CPNT_RSTD', 'SUM', 'VL_CPNT_RSTD');
	INSERT INTO COLS_SUM VALUES ('VL_ULT_SDO', 'SUM', 'VL_ULT_SDO');
QUIT;
%SumarizadorCNX(TblSASValores=CREDITO_CARTEIRA, TblSASColunas=COLS_SUM, NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL_CAPTACAO, AAAAMM=&NOME.);


PROC SQL;
	CREATE TABLE RESULTADO_CREDITO AS 
		SELECT 
			"&data"d AS POSICAO,
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VL_CPNT_RSTD, 
			t1.VL_ULT_SDO
		FROM WORK.FINAL_CAPTACAO t1
	right JOIN ORCADOS_000000174 t2 on (t1.prefdep=t2.prefdep AND T1.UOR=T2.UOR AND T1.CTRA=T2.CTRA)
				INNER JOIN PREFIXOS_IND_000000174 T3 ON (T2.PREFDEP=T3.PREFDEP AND T2.CTRA=T3.CTRA);
QUIT;


PROC SQL;
	CREATE TABLE CNX_CREDITO AS 
		SELECT DISTINCT 
			t2.IND, 
			0 AS comp,
			0 AS COMP_PAI,
			0 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VL_CPNT_RSTD AS VLR_RLZ, 
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_CREDITO t1, WORK.ORCADOS_000000174 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
QUIT;

PROC SQL;
	CREATE TABLE CREDITO_COMP AS 
		SELECT DISTINCT 
			t2.IND, 
			1 AS comp,
			0 AS COMP_PAI,
			1 AS ORD_EXI, 
			t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.VL_CPNT_RSTD AS VLR_RLZ, 
			t2.VLR_ORC FORMAT=19.2,
			0 AS VLR_ATG,
			t1.POSICAO FORMAT=mmyyn6. as POSICAO 
		FROM WORK.RESULTADO_CREDITO t1, WORK.ORCADOS_000000174 t2
			WHERE (t1.UOR = t2.UOR AND t1.PREFDEP = t2.PrefDep AND t1.CTRA = t2.CTRA) AND t2.comp = 0;
QUIT;

%BaseIndicadorCNX(TabelaSAS=CNX_CREDITO);
%BaseIndicadorCNX(TabelaSAS=CREDITO_COMP);

%ExportarCNX_IND(IND=000000174, MMAAAA=&MMAAAA);



PROC SQL;
	CREATE TABLE BASE_CLI_CREDITO AS 
		SELECT 
	000000174 AS IND, /*CODIGO INDICADOR*/
	0 AS COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/
	input(T2.UOR,9.) as UOR, 
	INPUT(T1.PREFDEP, 4.) AS PREFDEP,
	CARTEIRA AS CTRA,
    T1.CD_CLI AS CLI, 
    input(PUT(POSICAO, mmyyn6.),6.) as mmaaaa,
	VL_CPNT_RSTD AS VLR
	FROM WORK.CREDITO_CLIENTES t1
		INNER JOIN IGR.DEPENDENCIAS_&NOME. T2 ON (T1.PREFDEP=T2.PREFDEP)
			WHERE T2.SB='00' AND T2.STATUS= 'A';
QUIT;

%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CLI_CREDITO);
%ExportarCNX_CLI(IND=000000174,  MMAAAA=&MMAAAA);






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
