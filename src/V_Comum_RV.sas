
%include '/dados/infor/suporte/FuncoesInfor.sas';
LIBNAME DB2PRD DB2 DATABASE=BDB2P04 SCHEMA=DB2PRD  AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2MCI DB2 DATABASE=BDB2P04 SCHEMA=DB2MCI  AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2RST DB2 DATABASE=BDB2P04 SCHEMA=DB2RST  AUTHDOMAIN='DB2SGCEN' ;
LIBNAME DB2DTM DB2 DATABASE=BDB2P04 SCHEMA=DB2DTM  AUTHDOMAIN='DB2SGCEN';




LIBNAME REC '/dados/infor/producao/Receita_Vendas';

LIBNAME RIV '/dados/infor/producao/receita_interna';

LIBNAME SEG '/dados/dirco/publico/Gecen';



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
/*VISÃO: ACUMALADA */
/*NIVEL: MCI/CARTEIRA*/
/**/
/*CANAL - */
/*1 3 4 10 55 AND 7648*/


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_CLC_RSTD_GRNL AS 
   SELECT DISTINCT t1.CD_ITCE_CNL_ATDT, 
          t1.CD_IPMC_ITCE
      FROM DB2RST.CLC_RSTD_GRNL t1;
QUIT;

PROC SQL;
	CREATE TABLE RECEITA_VENDAS AS 
		SELECT DISTINCT 
			t1.CD_PRF_RSTD, 
			t1.CD_CLI, 
			t1.CD_ITCE_CNL_ATDT as CD_IPMC_ITCE_CNL ,
			t1.CD_IPMC_ITCE, 
			t1.CD_MDLD, 
			t1.CD_PRD, 
			t1.VL_CPNT_RSTD, 
			t1.VL_ULT_SDO, 
			t1.DT_APRC,
			t1.DT_FRMZ_SCTR,
			t1.DT_FRMZ_CTR,
			t1.CD_USU
		FROM DB2RST.CLC_RSTD_GRNL t1
			WHERE CD_CLI NE 0 AND t1.DT_APRC BETWEEN '01jan2019'D AND "&DATA"D AND t1.CD_CPNT_RSTD = 174 AND CD_PRF_RSTD NE 9903 
				ORDER BY 1,2;
QUIT;


PROC SQL;
	CREATE TABLE SEGUROS AS 
		SELECT 
			t1.CD_PRF_RSTD, 
			t1.CD_CLI, 
			t1.CD_ITCE_CNL AS CD_IPMC_ITCE_CNL, 
			t1.CD_PRD, 
			t1.CD_MDLD,
			t1.VLR_CPNT_RSTD AS VL_CPNT_RSTD, 
			t1.VL_CTR AS VL_ULT_SDO,
			t1.DT_APRC,
			t1.CD_USU
		FROM seg.rv_acum_2019s2 t1
		WHERE DT_APRC BETWEEN '01JAN2019'D AND "&DATA"D AND t1.CD_CPNT_RSTD = 174 AND CD_PRF_RSTD NE 9903
		ORDER BY 1,2
	;
QUIT;

DATA RECEITA_TOTAL;
SET RECEITA_VENDAS SEGUROS;
WHERE CD_IPMC_ITCE_CNL IN (1,3,4,55,10,12,14,20,67);
RUN;



PROC SQL;
   CREATE TABLE date AS 
   SELECT
          t1.CD_PRF_RSTD, 
          t1.CD_CLI, 
          t1.CD_IPMC_ITCE_CNL, 
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.VL_CPNT_RSTD, 
          t1.VL_ULT_SDO, 
          t1.DT_APRC,
		  t1.DT_FRMZ_CTR,
		  (case WHEN DT_FRMZ_CTR IS NOT MISSING THEN DT_FRMZ_CTR ELSE DT_APRC END) FORMAT DDMMYY10.
		  AS DATA,
		  t1.CD_USU
      FROM WORK.RECEITA_TOTAL t1
	  ;
QUIT;


PROC SQL;
	CREATE TABLE RECEITA_MCI AS 
		SELECT 
			t1.CD_PRF_RSTD, 
			t1.CD_CLI, 
			t1.CD_IPMC_ITCE_CNL, 
			t1.CD_PRD, 
			t1.CD_MDLD,
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
		t1.DATA, 
		t1.CD_USU
	FROM DATE t1
		INNER JOIN DB2PRD.MDLD_PRD T2 ON (T1.CD_PRD=T2.CD_PRD AND T1.CD_MDLD=T2.CD_MDLD)
;QUIT;



DATA ENCARTEIRAMENTO_CNX (KEEP=CD_CLI NR_SEQL_CTRA_ATB CD_PRF_DEPE CD_PRF_ADMC_RGNL CD_PRF_SPCA CD_PRF_DRTA CD_PRF_VICE_PRSA);
SET COMUM.ENCARTEIRAMENTO_CONEXAO_&NOME;
RUN;


PROC SQL;
	CREATE TABLE REC.RV_LEVE_&NOME AS 
		SELECT 
	T3.CD_PRF_DEPE,
	T3.NR_SEQL_CTRA_ATB,
	t1.CD_PRF_RSTD, /*rlz no prefixo*/
	t1.CD_CLI, 
	t1.CD_IPMC_ITCE_CNL, 
	t1.CD_MDLD, 
	t1.CD_PRD,
	T1.NM_MDLD,
	t1.CD_CTRG_PRD,
	t1.CATEGORIA,
	t1.VL_CPNT_RSTD, 
	t1.VL_ULT_SDO, 
	t1.DT_APRC,
	t1.DATA, 
	t1.CD_USU
	FROM WORK.RECEITA_MCI t1
		INNER JOIN DB2PRD.MDLD_PRD T2 ON (T1.CD_PRD=T2.CD_PRD AND T1.CD_MDLD=T2.CD_MDLD)
		INNER JOIN ENCARTEIRAMENTO_CNX T3 ON (T1.CD_CLI=T3.CD_CLI)
			WHERE T1.CD_CLI NE 0 and t3.cd_prf_depe is not missing
				ORDER BY 2;
QUIT;


PROC SQL;
   CREATE TABLE RECEITA_LOJA AS 
   SELECT DISTINCT 
        *
      FROM REC.RV_LEVE_&NOME t1
	  WHERE  t1.CD_IPMC_ITCE_CNL IN (1,3,4,55) AND CD_PRF_RSTD=CD_PRF_DEPE
      GROUP BY 1,2,3,4,5,6,7,8,11
              ;
QUIT;


PROC SQL;
   CREATE TABLE RECEITA_GERAL AS 
   SELECT DISTINCT 
          *
      FROM REC.RV_LEVE_&NOME t1
	  WHERE  t1.CD_IPMC_ITCE_CNL IN (10,12,14,20,67)
      GROUP BY 1,2,3,4,5,6,7,8,11
              ;
QUIT;

DATA RECEITA_LEVE_GERAL_;
SET RECEITA_GERAL RECEITA_LOJA;
RUN;


PROC SQL;
   CREATE TABLE REC.DETALHE_MCI_&NOME AS 
   SELECT DISTINCT 
          t1.CD_PRF_DEPE AS PREFDEP, 
          t1.NR_SEQL_CTRA_ATB AS CARTEIRA, 
          t1.CD_CLI,
          t1.CD_MDLD, 
          t1.CD_PRD, 
          t1.NM_MDLD, 
          t1.CD_CTRG_PRD, 
          t1.CATEGORIA, 
            (SUM(t1.VL_CPNT_RSTD)) FORMAT=19.2 AS VL_CPNT_RSTD, 
            (SUM(t1.VL_ULT_SDO)) FORMAT=19.2 AS VL_ULT_SDO, 
          t1.DT_APRC
      FROM RECEITA_LEVE_GERAL_ t1
      GROUP BY 1,2,3,4,5,6,7,8,11
              ;
QUIT;





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
