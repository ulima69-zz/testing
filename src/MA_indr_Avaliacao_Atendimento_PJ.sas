/* Indicador Avaliação do Atendimento PJ */

/* CHECKIN */

/* BIBLIOTECAS + METADADOS (VARIÁVEIS) */

/* BIBLIOTECAS + METADADOS (VARIÁVEIS) */

%include '/dados/infor/suporte/FuncoesInfor.sas';
LIBNAME RELFOTOS "/dados/gecen/interno/bases/rel/fotos";
LIBNAME PDG "/dados/infor/producao/Hst_Carteiras_II";
%LET AnoMes=201905;
%LET Tx_Fon=5144;
%CONECTARDB2(BIC);
%CONECTARDB2(REL);
%CONECTARDB2(ATB);

DATA _NULL_;
	IF &AnoMes=0 THEN
		D0=Today();
	ELSE
		DO;
			AA=Floor(&AnoMes/100);
			MM=&AnoMes-(AA*100);
			D0=IntNx('month',MDY(MM,1,AA),1);
		END;

	D1=DiaUtilAnterior(Smallest(1,D0,Today()));
	CALL SYMPUT('D1',D1);
	CALL SYMPUT('AnoMes',Put(D1, yymmn6.));
	CALL SYMPUT('MesAno',Put(D1, mmyyn6.));
	CALL SYMPUT('Ini',"'"||Put(IntNx('month',D1,0), yymmdd10.)||"'");
	CALL SYMPUT('Fim',"'"||Put(D1, yymmdd10.)||"'");
RUN;
%Put &D1 &AnoMes &MesAno &Ini &Fim;


/************************************************/
/*******************ACORDO***********************/
/*******************ACORDO***********************/
/************************************************/


PROC SQL;
CREATE TABLE ACORDO_CARTEIRA AS 
SELECT DISTINCT cd_uor_ctra AS UOR, nr_seql_ctra as CTRA
FROM DB2ATB.vl_aprd_in_ctra
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and  cd_in_mod_avlc = 12097;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_CARTEIRA_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_CARTEIRA t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;


PROC SQL;
CREATE TABLE ACORDO_PREFIXO AS 
SELECT DISTINCT cd_uor AS UOR, 0 as CTRA
FROM DB2ATB.vl_aprd_in_uor
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and cd_In_mod_avlc = 12096;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_PREFIXO_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_PREFIXO t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;


PROC SQL;
CREATE TABLE ACORDO_GEREV AS 
SELECT DISTINCT cd_uor AS UOR, 0 as CTRA
FROM DB2ATB.vl_aprd_in_uor
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and cd_In_mod_avlc = 12010;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_GEREV_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_GEREV t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;


PROC SQL;
CREATE TABLE ACORDO_SUPER AS 
SELECT DISTINCT cd_uor AS UOR, 0 as CTRA
FROM DB2ATB.vl_aprd_in_uor
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and cd_In_mod_avlc = 12099;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_SUPER_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_SUPER t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;



PROC SQL;
CREATE TABLE ACORDO_GRUPO AS 
SELECT DISTINCT cd_uor AS UOR, 0 as CTRA
FROM DB2ATB.vl_aprd_in_uor
where aa_vl_aprd_in = 2019 and mm_vl_aprd_in = MONTH(&D1.) and cd_In_mod_avlc = 12098;
QUIT;


PROC SQL;
CREATE TABLE ACORDO_GRUPO_1 AS 
SELECT DISTINCT t1.UOR, CTRA, input(t2.PREFDEP, 4.) AS PREFIXO
FROM ACORDO_GRUPO t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.UOR = input(t2.UOR, 9.);
QUIT;



PROC SQL;

CREATE TABLE ACORDO_PREF_CTRA AS
 
   SELECT * FROM ACORDO_CARTEIRA_1
   OUTER UNION CORR
   SELECT * FROM ACORDO_PREFIXO_1;

Quit;


PROC SQL;
CREATE TABLE ACORDOS AS 
SELECT DISTINCT PREFIXO, t1.CTRA, t1.UOR
FROM ACORDO_PREF_CTRA t1
order by 1,2;
QUIT;

DATA IGR(KEEP=Prefixo Gerev Super Diretoria VP AGC TD CD_UOR);
	SET IGR.IGRREDE_&AnoMes;
	CD_UOR=Input(UOR, 9.);
	Prefixo=Input(PrefDep, 4.);
	Gerev=Input(PrefSupReg, 4.);
	Super=Input(PrefSupESt, 4.);
	Diretoria=Input(PrefUEN, 4.);
	VP=8166;

	IF TipoDep='01' THEN
		AGC=Input(PrefAgenc, 4.);
	ELSE AGC=Prefixo;
	TD=Input(TipoDep, 2.);
RUN;


/* CONSULTA ORIGINAL - Consulta base da BIC */
PROC SQL;
   CREATE TABLE CONSULTA_BIC AS 
   SELECT t1.CD_CLI AS CD_CLI_RESPONDENTE, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_PRF_DEPE_CLI AS CD_PRF_DEPE_RESPONDENTE, 
          t1.CD_TIP_PSS, 
          t1.VL_INRO_CLI, 
          t1.CD_IDFC_TRML_CPTH, 
          t1.DT_INCL_REG_INRO, 
          t2.CD_CLI AS CD_CLI_PJ, 
          t2.TS_INRO_CLI, 
          t2.CD_TRAN_INRO_SIS, 
          t2.CD_RSTD_INRO AS CD_RSTD_INRO1, 
          t2.CD_SUB_RSTD_INRO AS CD_SUB_RSTD_INRO1, 
          t2.CD_PRF_DEPE_CLI AS CD_PRF_DEPE_PJ, 
          t2.CD_DEPE_RSP_ATDT, 
          t2.CD_TIP_PSS AS CD_TIP_PSS1, 
          t2.CD_ASNT_INRO, 
          t2.CD_SUB_ASNT_INRO, 
          t3.CD_USU_RSP_ATDT
      FROM DB2BIC.AUX_INRO_CLI_ATU t1
           LEFT JOIN (DB2BIC.AUX_INRO_CLI_ATU t2
           LEFT JOIN DB2BIC.INRO_HMNO_CLI t3 ON (t2.TS_INRO_CLI = t3.TS_INRO_CLI)) ON (t1.CD_IDFC_TRML_CPTH = t2.CD_IDFC_TRML_CPTH)
      WHERE t1.CD_RSTD_INRO = 1005 AND t2.CD_TRAN_INRO_SIS IN 
           (
           'REL11',
           'GATN',
           'GATNPJ',
           'REL04',
           'MIV10016'
           ) AND t2.CD_TIP_PSS = 2
     order by 4, 1;
QUIT;

/* Junta dados da tabel REL_APRC_&ANOMES à Base Inicial */
PROC SQL;
   CREATE TABLE BASE_BIC_REL_MES AS 
   SELECT t1.CD_CLI_RESPONDENTE, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_PRF_DEPE_RESPONDENTE, 
          t1.CD_TIP_PSS, 
          t1.VL_INRO_CLI, 
          t1.CD_IDFC_TRML_CPTH, 
          t1.DT_INCL_REG_INRO FORMAT yymmdd10. as DT_INCL_REG_INRO, 
          t1.CD_CLI_PJ, 
          t1.TS_INRO_CLI,
		  DATEPART(T1.TS_INRO_CLI) FORMAT yymmdd10. AS DATE_TS_INRO_CLI,
          t1.CD_TRAN_INRO_SIS, 
          t1.CD_RSTD_INRO1, 
          t1.CD_SUB_RSTD_INRO1, 
          t1.CD_PRF_DEPE_PJ, 
          t1.CD_DEPE_RSP_ATDT, 
          t1.CD_TIP_PSS1, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO, 
          t1.CD_USU_RSP_ATDT, 
		  INPUT(SUBSTR(t1.CD_USU_RSP_ATDT, 2, 7),7.) AS CHAVE_FUNCI,
          t2.DT_INCL_CLI_CTRA, 
          t2.CD_TIP_CTRA, 
          t2.NR_SEQL_CTRA_ATB, 
          t2.CD_PRF_DEPE, 
          t2.CD_PRF_ADMC_RGNL, 
          t2.CD_PRF_SPCA, 
          t2.CD_PRF_DRTA, 
          t2.CD_PRF_VICE_PRSA
      FROM CONSULTA_BIC t1
           LEFT JOIN RELFOTOS.rel_aprc_&AnoMes t2 ON (t1.CD_CLI_RESPONDENTE = t2.CD_CLI)
      where t1.VL_INRO_CLI <> 0;
QUIT;

/* Histórico de Gerentes das Carteiras */
PROC SQL;
	CREATE TABLE GERENTES_&AnoMes AS
		SELECT DISTINCT Posicao, Input(PrefDep, 4.) AS PrefDep,
			IFN(B.NR_SEQL_CTRA IS MISSING,7002,Input(Carteira, 5.)) AS Carteira,
			IFN(B.NR_SEQL_CTRA IS MISSING,700,TC) AS TC, Matricula
		FROM PDG.CAPTURA_PRIMARIA_201901 A
			LEFT JOIN COMUM.CTRA_VALIDA_&AnoMes B ON(Input(A.Prefdep,4.)=B.CD_PRF_DEPE AND Input(A.Carteira,5.)=B.NR_SEQL_CTRA)
				WHERE Posicao>='1apr2019'd;
QUIT;

/* Consultar Assistentes Vinculados à Carteiras */
PROC SQL;
   CREATE TABLE WORK.ASST_VCLD_CTRA_TTL AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.NR_SEQL_CTRA, 
          t1.CD_TIP_CTRA, 
          t1.NR_MTC_ADM_NEG, 
          /* TTL_CTRA_VCLD */
          (COUNT(t1.NR_MTC_ADM_NEG)) AS TTL_CTRA_VCLD
      FROM DB2REL.CTRA_CLI t1
      WHERE t1.NR_MTC_ADM_NEG NOT = 0
      GROUP BY t1.NR_MTC_ADM_NEG;
QUIT;

PROC SQL;
   CREATE TABLE ASST_VCLD_CTRA_UNCA AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.NR_SEQL_CTRA, 
          t1.CD_TIP_CTRA, 
          t1.NR_MTC_ADM_NEG as ASSISTENTE,
          t1.TTL_CTRA_VCLD
      FROM ASST_VCLD_CTRA_TTL  t1
      WHERE t1.TTL_CTRA_VCLD = 1;
QUIT;

PROC SQL;
   CREATE TABLE ASST_VCLD_VARIAS_CTRAS AS 
   SELECT distinct t1.CD_PRF_DEPE, 
          t1.NR_MTC_ADM_NEG as ASSISTENTE,
          t1.TTL_CTRA_VCLD
      FROM ASST_VCLD_CTRA_TTL  t1
      WHERE t1.TTL_CTRA_VCLD > 1;
QUIT;


/* Junta dados do Prefixo e Ctra do Funcionario GERENTE à BASE_BIC_REL_MES  - CONTA PARA A CARTEIRA DO ATENDIMENTO */
PROC SQL;
   CREATE TABLE BASE_COM_GERENTES AS 
   SELECT t1.CD_CLI_RESPONDENTE, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_PRF_DEPE_RESPONDENTE, 
          t1.CD_TIP_PSS, 
          t1.VL_INRO_CLI, 
          t1.CD_IDFC_TRML_CPTH, 
          t1.DT_INCL_REG_INRO, 
          t1.CD_CLI_PJ, 
          t1.TS_INRO_CLI,
          t1.DATE_TS_INRO_CLI,
          t1.CD_TRAN_INRO_SIS, 
          t1.CD_RSTD_INRO1, 
          t1.CD_SUB_RSTD_INRO1, 
          t1.CD_PRF_DEPE_PJ, 
          t1.CD_DEPE_RSP_ATDT, 
          t1.CD_TIP_PSS1, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO, 
          t1.CD_USU_RSP_ATDT, 
          t1.CHAVE_FUNCI, 
		  t2.Matricula,
          t2.PrefDep AS CD_PRF_FUNCI, 
          t2.Carteira AS NR_CTRA_FUNCI,
          t2.TC, 
          t1.DT_INCL_CLI_CTRA, 
          t1.CD_TIP_CTRA, 
          t1.NR_SEQL_CTRA_ATB, 
          t1.CD_PRF_DEPE, 
          t1.CD_PRF_ADMC_RGNL, 
          t1.CD_PRF_SPCA, 
          t1.CD_PRF_DRTA, 
          t1.CD_PRF_VICE_PRSA
      FROM WORK.BASE_BIC_REL_MES t1
           LEFT JOIN GERENTES_&AnoMes t2 ON t1.CHAVE_FUNCI = t2.Matricula AND t1.DATE_TS_INRO_CLI = t2.Posicao
      WHERE t2.Matricula IS NOT MISSING;
QUIT;

/* Junta dados do Prefixo e Ctra do Funcionario ASSISTENTE VINCULADO A CARTEIRA UNICA à BASE_COM_GERENTES  - CONTA PARA A CARTEIRA DO ATENDIMENTO */
PROC SQL;
   CREATE TABLE BASE_COM_ASSISTENTES_1 AS 
   SELECT t1.CD_CLI_RESPONDENTE, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_PRF_DEPE_RESPONDENTE, 
          t1.CD_TIP_PSS, 
          t1.VL_INRO_CLI, 
          t1.CD_IDFC_TRML_CPTH, 
          t1.DT_INCL_REG_INRO, 
          t1.CD_CLI_PJ, 
          t1.TS_INRO_CLI,
          t1.DATE_TS_INRO_CLI,
          t1.CD_TRAN_INRO_SIS, 
          t1.CD_RSTD_INRO1, 
          t1.CD_SUB_RSTD_INRO1, 
          t1.CD_PRF_DEPE_PJ, 
          t1.CD_DEPE_RSP_ATDT, 
          t1.CD_TIP_PSS1, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO, 
          t1.CD_USU_RSP_ATDT, 
          t1.CHAVE_FUNCI, 
		  t2.assistente AS Matricula,
          t2.CD_PRF_DEPE AS CD_PRF_FUNCI, 
          t2.NR_SEQL_CTRA AS NR_CTRA_FUNCI,
          t2.CD_TIP_CTRA AS TC, 
          t1.DT_INCL_CLI_CTRA, 
          t1.CD_TIP_CTRA, 
          t1.NR_SEQL_CTRA_ATB, 
          t1.CD_PRF_DEPE, 
          t1.CD_PRF_ADMC_RGNL, 
          t1.CD_PRF_SPCA, 
          t1.CD_PRF_DRTA, 
          t1.CD_PRF_VICE_PRSA
      FROM WORK.BASE_BIC_REL_MES t1
		   LEFT JOIN ASST_VCLD_CTRA_UNCA t2 ON (t1.CHAVE_FUNCI = t2.assistente)
     WHERE t2.assistente NOT IS MISSING;
QUIT;

/* Junta dados do Prefixo e Ctra do Funcionario ASSISTENTE VINCULADO A MAIS DE UMA CARTEIRA à BASE_COM_ASSISTENTES_1  - CONTA PARA A DEPENDENCIA DO ATENDIMENTO */
PROC SQL;
   CREATE TABLE BASE_COM_ASSISTENTES_2 AS 
   SELECT t1.CD_CLI_RESPONDENTE, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_PRF_DEPE_RESPONDENTE, 
          t1.CD_TIP_PSS, 
          t1.VL_INRO_CLI, 
          t1.CD_IDFC_TRML_CPTH, 
          t1.DT_INCL_REG_INRO, 
          t1.CD_CLI_PJ, 
          t1.TS_INRO_CLI,
          t1.DATE_TS_INRO_CLI,
          t1.CD_TRAN_INRO_SIS, 
          t1.CD_RSTD_INRO1, 
          t1.CD_SUB_RSTD_INRO1, 
          t1.CD_PRF_DEPE_PJ, 
          t1.CD_DEPE_RSP_ATDT, 
          t1.CD_TIP_PSS1, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO, 
          t1.CD_USU_RSP_ATDT, 
          t1.CHAVE_FUNCI, 
		  t2.assistente AS Matricula,
          t2.CD_PRF_DEPE AS CD_PRF_FUNCI, 
          0 AS NR_CTRA_FUNCI,
          0 AS TC, 
          t1.DT_INCL_CLI_CTRA, 
          t1.CD_TIP_CTRA, 
          t1.NR_SEQL_CTRA_ATB, 
          t1.CD_PRF_DEPE, 
          t1.CD_PRF_ADMC_RGNL, 
          t1.CD_PRF_SPCA, 
          t1.CD_PRF_DRTA, 
          t1.CD_PRF_VICE_PRSA
      FROM WORK.BASE_BIC_REL_MES t1
		   LEFT JOIN ASST_VCLD_VARIAS_CTRAS t2 ON (t1.CHAVE_FUNCI = t2.assistente)
     WHERE t2.assistente NOT IS MISSING;;
QUIT;

DATA BASE_GERAL;
SET BASE_COM_GERENTES BASE_COM_ASSISTENTES_1 BASE_COM_ASSISTENTES_2;
RUN;

/* Limpa base e calcula Peso das Notas */
PROC SQL;
   CREATE TABLE AVLC_NOTA_PESO AS 
   SELECT t1.CD_PRF_VICE_PRSA, 
          t1.CD_PRF_DRTA, 
          t1.CD_PRF_SPCA, 
          t1.CD_PRF_DEPE, 
          t1.CD_PRF_ADMC_RGNL, 
          t1.CD_PRF_DEPE_RESPONDENTE AS DEPE_REL_CLI,
		  t1.NR_SEQL_CTRA_ATB, 
          t1.CD_DEPE_RSP_ATDT, 
          t1.CD_USU_RSP_ATDT, 
          COALESCE(t1.NR_CTRA_FUNCI,0) AS NR_CTRA_FUNCI,
          t1.CHAVE_FUNCI,
          t1.CD_CLI_RESPONDENTE AS MCI, 
          t1.VL_INRO_CLI AS NOTA, 
          /* PESO */
            (CASE WHEN t1.VL_INRO_CLI = 1 THEN 4
                      WHEN t1.VL_INRO_CLI = 2 THEN 4
                      WHEN t1.VL_INRO_CLI = 3 THEN 3
                      WHEN t1.VL_INRO_CLI = 4 THEN 4
                      ELSE 2
            END
            ) AS PESO, 
          t1.DT_INCL_REG_INRO,
		  t1.DATE_TS_INRO_CLI,
          t1.TS_INRO_CLI,
		  (t1.DT_INCL_REG_INRO - t1.DATE_TS_INRO_CLI) as PRAZO_RESPOSTA
      FROM WORK.BASE_GERAL t1
	  WHERE CALCULATED PRAZO_RESPOSTA <= 4
      ORDER BY t1.CD_DEPE_RSP_ATDT,
               t1.NR_SEQL_CTRA_ATB,
               t1.CD_USU_RSP_ATDT;
QUIT;

/* Calcular o total de Avaliações por Nota e Peso - Dependencias e Carteiras */
PROC SQL;
   CREATE TABLE WORK.TTL_AVLC_NOTA_PESO_CTRAS AS 
   SELECT t1.CD_DEPE_RSP_ATDT,
          t1.NR_CTRA_FUNCI, 
          t1.NOTA, 
          t1.PESO, 
          /* TTL_AVLC */
            (COUNT(t1.MCI)) AS QT_AVLC
      FROM WORK.AVLC_NOTA_PESO t1
	  WHERE t1.NR_CTRA_FUNCI <> 0
      GROUP BY t1.CD_DEPE_RSP_ATDT,
               t1.NR_CTRA_FUNCI, 
               t1.NOTA,
               t1.PESO
      ORDER BY t1.CD_DEPE_RSP_ATDT,
               t1.NR_CTRA_FUNCI,
               t1.NOTA,
               t1.PESO,
               QT_AVLC;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TTL_AVLC_NOTA_PESO_DEPES AS 
   SELECT t1.CD_DEPE_RSP_ATDT, 
          0 AS NR_CTRA_FUNCI,
          t1.NOTA, 
          t1.PESO, 
          /* TTL_AVLC */
            (COUNT(t1.MCI)) AS QT_AVLC
      FROM WORK.AVLC_NOTA_PESO t1
      GROUP BY t1.CD_DEPE_RSP_ATDT,
               t1.NOTA,
               t1.PESO
      ORDER BY t1.CD_DEPE_RSP_ATDT,
               t1.NOTA,
               t1.PESO,
               QT_AVLC;
QUIT;

DATA TTL_AVLC_NOTA_PESO;
 SET TTL_AVLC_NOTA_PESO_DEPES TTL_AVLC_NOTA_PESO_CTRAS;
RUN;

PROC SORT DATA=TTL_AVLC_NOTA_PESO;
     BY CD_DEPE_RSP_ATDT NR_CTRA_FUNCI;
RUN;

/* Seperar Carteiras Avaliáveis - com 10 ou mais avaliações - Dependencias e Carteiras */
PROC SQL;
   CREATE TABLE WORK.TTL_AVALIACOES_CTRAS AS 
   SELECT t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI, 
          /* SUM_of_QT_AVLC */
            (SUM(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.TTL_AVLC_NOTA_PESO t1
	  WHERE t1.NR_CTRA_FUNCI <> 0
      GROUP BY t1.CD_DEPE_RSP_ATDT,
               t1.NR_CTRA_FUNCI;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CTRAS_AVALIAVEIS AS 
   SELECT t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI, 
          t1.QT_AVLC
      FROM WORK.TTL_AVALIACOES_CTRAS t1
	WHERE t1.QT_AVLC >= 10;
QUIT;

PROC SQL;
   CREATE TABLE WORK.TTL_AVALIACOES_DEPES AS 
   SELECT t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI, 
          /* SUM_of_QT_AVLC */
            (SUM(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.TTL_AVLC_NOTA_PESO t1
	  WHERE t1.NR_CTRA_FUNCI = 0
      GROUP BY t1.CD_DEPE_RSP_ATDT,
               t1.NR_CTRA_FUNCI;
QUIT;

PROC SQL;
   CREATE TABLE WORK.DEPES_AVALIAVEIS AS 
   SELECT t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI, 
          t1.QT_AVLC
      FROM WORK.TTL_AVALIACOES_DEPES t1
	WHERE t1.QT_AVLC >= 10;
QUIT;


DATA DEPES_CTRA_AVALIAVEIS;
 SET DEPES_AVALIAVEIS CTRAS_AVALIAVEIS;
RUN;

PROC SORT DATA=DEPES_CTRA_AVALIAVEIS;
     BY CD_DEPE_RSP_ATDT NR_CTRA_FUNCI;
RUN;

/* Dependências e Carteiras com Mais de 10 avaliações */
PROC SQL;
   CREATE TABLE AVLC_NOTA_PESO_GERAL AS 
   SELECT t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI, 
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC
      FROM WORK.TTL_AVLC_NOTA_PESO t1
	  INNER JOIN DEPES_CTRA_AVALIAVEIS t2 
              ON (t1.CD_DEPE_RSP_ATDT = t2.CD_DEPE_RSP_ATDT AND t1.NR_CTRA_FUNCI = t2.NR_CTRA_FUNCI)
		  WHERE t1.QT_AVLC >= 10
      ORDER BY t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI, 
          t1.NOTA;
QUIT;

/* TRATA CARTEIRAS */

PROC SQL;
   CREATE TABLE AVLC_NOTA_PESO_GERAL_1 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI,  
          t1.NOTA, 
          t1.PESO, 
          (sum(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.AVLC_NOTA_PESO_GERAL t1
	  where t1.NR_CTRA_FUNCI <> 0
	    and t1.qt_avlc >= 10
      GROUP BY t1.CD_DEPE_RSP_ATDT,
               t1.NR_CTRA_FUNCI,
			   t1.NOTA
      ORDER BY 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE AVLC_NOTA_PESO_GERAL_2 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC,
          (t1.QT_AVLC * t1.PESO *  t1.NOTA) as QPN,
		  (t1.QT_AVLC * t1.PESO) AS QP
      FROM WORK.AVLC_NOTA_PESO_GERAL_1 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_NOTA_PESO_GERAL_3 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          t1.NR_CTRA_FUNCI,  
          SUM(QPN) AS QPN,
		  SUM(QP) AS QP,
          SUM(QPN)/ SUM(QP) FORMAT 32.2 AS NOTA_AVLC
      FROM AVLC_NOTA_PESO_GERAL_2 t1
	  GROUP BY 1, 2
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE RLZD_NOTAS_CTRA AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT AS PREFDEP,
          t1.NR_CTRA_FUNCI AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          ((t1.NOTA_AVLC - 1) * 25) FORMAT 32.2 AS RLZD_NOTAS
      FROM AVLC_NOTA_PESO_GERAL_3 t1
	  GROUP BY 1, 2
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE CRT AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          1 AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_CTRA T1
	  INNER JOIN ACORDO_CARTEIRA_1 t2 ON (T1.PREFDEP = t2.PREFIXO AND T1.CTRA = T2.CTRA)
      ORDER BY 1, 2;
QUIT;



/* TRATA PREFIXOS E PAA */


/**/
PROC SQL;

   CREATE TABLE AVLC_PJ_PAA_PREF AS SELECT DISTINCT
          input(t2.PREFAGENC, 4.) AS CD_DEPE_RSP_ATDT,	 
/*          input(t2.PREFDEP, 4.) AS PAA_ATDT,*/
          t1.NR_CTRA_FUNCI,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC AS QT_AVLC_PAA    	  
    FROM AVLC_NOTA_PESO_GERAL t1
	INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_DEPE_RSP_ATDT = input(t2.PREFDEP, 4.)
	WHERE input(t2.PREFAGENC, 4.) <> 0
    ORDER BY 1;

QUIT;

DATA AVLC_PJ_TOTAL;
	MERGE AVLC_PJ_PAA_PREF AVLC_NOTA_PESO_GERAL;
	BY CD_DEPE_RSP_ATDT NR_CTRA_FUNCI NOTA PESO;
RUN;

PROC STDIZE DATA=AVLC_PJ_TOTAL OUT=AVLC_PJ_TOTAL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;

PROC SQL;

   CREATE TABLE NOTAS_PREF_MAIS_PAA AS
    SELECT DISTINCT
          t1.CD_DEPE_RSP_ATDT,	 
          t1.NR_CTRA_FUNCI, 
          t1.NOTA, 
          t1.PESO, 
          (t1.QT_AVLC + t1.QT_AVLC_PAA) AS QT_AVLC    	  
    FROM AVLC_PJ_TOTAL t1
    ORDER BY 1, 2, 3;

QUIT;


PROC SQL;
   CREATE TABLE NOTAS_PREF_MAIS_PAA_2 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,   
          t1.NOTA, 
          t1.PESO, 
          (sum(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.NOTAS_PREF_MAIS_PAA t1
	 WHERE t1.qt_avlc >= 10
      GROUP BY t1.CD_DEPE_RSP_ATDT,
			   t1.NOTA
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE NOTAS_PREF_MAIS_PAA_3 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC,
          (t1.QT_AVLC * t1.PESO *  t1.NOTA) as QPN,
		  (t1.QT_AVLC * t1.PESO) AS QP
      FROM WORK.NOTAS_PREF_MAIS_PAA_2 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE NOTAS_PREF_MAIS_PAA_4 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          SUM(QPN) AS QPN,
		  SUM(QP) AS QP,
          SUM(QPN)/ SUM(QP) FORMAT 32.2 AS NOTA_AVLC
      FROM WORK.NOTAS_PREF_MAIS_PAA_3 t1
	  GROUP BY 1
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE RLZD_NOTAS_DEPE AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT AS PREFDEP,
          0 AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          ((t1.NOTA_AVLC - 1) * 25) FORMAT 32.2 AS RLZD_NOTAS
      FROM WORK.NOTAS_PREF_MAIS_PAA_4 t1
	  GROUP BY 1, 2
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE DEPE AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          INPUT(t2.TD_SINERGIA, d4.) AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_DEPE T1
       INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.PREFDEP = INPUT(t2.PREFDEP, d4.)
	   INNER JOIN ACORDO_PREFIXO_1 t3 ON (T1.PREFDEP = T3.PREFIXO)
      ORDER BY 1, 2;
QUIT;


/* BLOCO DE CALCULO PARA AS HIERARQUIAS SUPERIORES A AGENCIA */
/* BLOCO DE CALCULO PARA AS HIERARQUIAS SUPERIORES A AGENCIA */
/* BLOCO DE CALCULO PARA AS HIERARQUIAS SUPERIORES A AGENCIA */

PROC SQL;

   CREATE TABLE AVLC_PJ_HIER AS SELECT DISTINCT

      t1.CD_DEPE_RSP_ATDT,
      t1.NR_CTRA_FUNCI,  
      t1.NOTA, 
      t1.PESO, 
      t1.QT_AVLC,	  
      INPUT(t2.PREFSUPREG, 4.) AS GEREV,
	  INPUT(t2.PREFSUPEST, 4.) AS SUPER,
	  INPUT(t2.PREFUEN, 4.) AS DIR,
	  8592 AS NOVADIR,
	  8166 AS VICE
	  
    FROM AVLC_NOTA_PESO_GERAL t1
    INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.CD_DEPE_RSP_ATDT = input(t2.PREFDEP, 4.)
	GROUP BY 1;

QUIT;


/* GEREV */

PROC SQL;
   CREATE TABLE AVLC_PJ_GEREV_1 AS SELECT DISTINCT
      t1.GEREV AS CD_DEPE_RSP_ATDT,
      t1.NOTA, 
      t1.PESO, 
      t1.QT_AVLC  
    FROM AVLC_PJ_HIER t1;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_GEREV_2 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,   
          t1.NOTA, 
          t1.PESO, 
          (sum(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.AVLC_PJ_GEREV_1 t1
      GROUP BY t1.CD_DEPE_RSP_ATDT,
			   t1.NOTA
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_GEREV_3 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC,
          (t1.QT_AVLC * t1.PESO *  t1.NOTA) as QPN,
		  (t1.QT_AVLC * t1.PESO) AS QP
      FROM WORK.AVLC_PJ_GEREV_2 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_GEREV_4 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          SUM(QPN) AS QPN,
		  SUM(QP) AS QP,
          SUM(QPN)/ SUM(QP) FORMAT 32.2 AS NOTA_AVLC
      FROM WORK.AVLC_PJ_GEREV_3 t1
	  GROUP BY 1
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE RLZD_NOTAS_GEREV AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT AS PREFDEP,
          0 AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          ((t1.NOTA_AVLC - 1) * 25) FORMAT 32.2 AS RLZD_NOTAS
      FROM WORK.AVLC_PJ_GEREV_4 t1
	  GROUP BY 1, 2
      ORDER BY 1;
QUIT;

PROC SQL;
   CREATE TABLE GEREV AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          INPUT(t2.TD_SINERGIA, d4.) AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_GEREV T1
       INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.PREFDEP = INPUT(t2.PREFDEP, d4.)
	   INNER JOIN ACORDO_GEREV_1 t3 ON (T1.PREFDEP = T3.PREFIXO)
      ORDER BY 1, 2;
QUIT;


/* SUPER */

PROC SQL;
   CREATE TABLE AVLC_PJ_SUPER_1 AS SELECT DISTINCT
      t1.SUPER AS CD_DEPE_RSP_ATDT,
      t1.NOTA, 
      t1.PESO, 
      t1.QT_AVLC  
    FROM AVLC_PJ_HIER t1;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_SUPER_2 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,   
          t1.NOTA, 
          t1.PESO, 
          (sum(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.AVLC_PJ_SUPER_1 t1
      GROUP BY t1.CD_DEPE_RSP_ATDT,
			   t1.NOTA
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_SUPER_3 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC,
          (t1.QT_AVLC * t1.PESO *  t1.NOTA) as QPN,
		  (t1.QT_AVLC * t1.PESO) AS QP
      FROM WORK.AVLC_PJ_SUPER_2 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_SUPER_4 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          SUM(QPN) AS QPN,
		  SUM(QP) AS QP,
          SUM(QPN)/ SUM(QP) FORMAT 32.2 AS NOTA_AVLC
      FROM WORK.AVLC_PJ_SUPER_3 t1
	  GROUP BY 1
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE RLZD_NOTAS_SUPER AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT AS PREFDEP,
          0 AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          ((t1.NOTA_AVLC - 1) * 25) FORMAT 32.2 AS RLZD_NOTAS
      FROM WORK.AVLC_PJ_SUPER_4 t1
	  GROUP BY 1, 2
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE SUPER AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          INPUT(t2.TD_SINERGIA, d4.) AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_SUPER T1
       INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.PREFDEP = INPUT(t2.PREFDEP, d4.)
	   	   INNER JOIN ACORDO_SUPER_1 t3 ON (T1.PREFDEP = T3.PREFIXO)
      ORDER BY 1, 2;
QUIT;


/* UNIDADES */


PROC SQL;
   CREATE TABLE AVLC_PJ_DIR_1 AS SELECT DISTINCT
      t1.DIR AS CD_DEPE_RSP_ATDT,
      t1.NOTA, 
      t1.PESO, 
      t1.QT_AVLC  
    FROM AVLC_PJ_HIER t1;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_DIR_2 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,   
          t1.NOTA, 
          t1.PESO, 
          (sum(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.AVLC_PJ_DIR_1 t1
      GROUP BY t1.CD_DEPE_RSP_ATDT,
			   t1.NOTA
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_DIR_3 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC,
          (t1.QT_AVLC * t1.PESO *  t1.NOTA) as QPN,
		  (t1.QT_AVLC * t1.PESO) AS QP
      FROM WORK.AVLC_PJ_DIR_2 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_DIR_4 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          SUM(QPN) AS QPN,
		  SUM(QP) AS QP,
          SUM(QPN)/ SUM(QP) FORMAT 32.2 AS NOTA_AVLC
      FROM WORK.AVLC_PJ_DIR_3 t1
	  GROUP BY 1
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE RLZD_NOTAS_DIR AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT AS PREFDEP,
          0 AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          ((t1.NOTA_AVLC - 1) * 25) FORMAT 32.2 AS RLZD_NOTAS
      FROM WORK.AVLC_PJ_DIR_4 t1
	  GROUP BY 1, 2
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE UND AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          INPUT(t2.TD_SINERGIA, d4.) AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_DIR T1
       INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.PREFDEP = INPUT(t2.PREFDEP, d4.)
      ORDER BY 1, 2;
QUIT;


/* DIVAR  */

PROC SQL;
   CREATE TABLE AVLC_PJ_NOVADIR_1 AS SELECT DISTINCT
      t1.NOVADIR AS CD_DEPE_RSP_ATDT,
      t1.NOTA, 
      t1.PESO, 
      t1.QT_AVLC  
    FROM AVLC_PJ_HIER t1;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_NOVADIR_2 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,   
          t1.NOTA, 
          t1.PESO, 
          (sum(t1.QT_AVLC)) AS QT_AVLC
      FROM WORK.AVLC_PJ_NOVADIR_1 t1
      GROUP BY t1.CD_DEPE_RSP_ATDT,
			   t1.NOTA
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_NOVADIR_3 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT,  
          t1.NOTA, 
          t1.PESO, 
          t1.QT_AVLC,
          (t1.QT_AVLC * t1.PESO *  t1.NOTA) as QPN,
		  (t1.QT_AVLC * t1.PESO) AS QP
      FROM WORK.AVLC_PJ_NOVADIR_2 t1
      ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE AVLC_PJ_NOVADIR_4 AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT, 
          SUM(QPN) AS QPN,
		  SUM(QP) AS QP,
          SUM(QPN)/ SUM(QP) FORMAT 32.2 AS NOTA_AVLC
      FROM WORK.AVLC_PJ_NOVADIR_3 t1
	  GROUP BY 1
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE RLZD_NOTAS_NOVADIR AS 
   SELECT distinct t1.CD_DEPE_RSP_ATDT AS PREFDEP,
          0 AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          ((t1.NOTA_AVLC - 1) * 25) FORMAT 32.2 AS RLZD_NOTAS
      FROM WORK.AVLC_PJ_NOVADIR_4 t1
	  GROUP BY 1, 2
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE DIR AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          INPUT(t2.TD_SINERGIA, d4.) AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_NOVADIR T1
       INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.PREFDEP = INPUT(t2.PREFDEP, d4.)
      ORDER BY 1, 2;
QUIT;


/* VICE */

PROC SQL;
   CREATE TABLE RLZD_NOTAS_VICE AS 
   SELECT distinct 8166 AS PREFDEP,
          0 AS CTRA,
          t1.QPN,
		  t1.QP,
          t1.NOTA_AVLC,
          t1.RLZD_NOTAS
      FROM WORK.RLZD_NOTAS_NOVADIR t1
	  GROUP BY 1, 2
      ORDER BY 1;
QUIT;


PROC SQL;
   CREATE TABLE VICE AS 
   SELECT T1.PREFDEP,
          T1.CTRA AS CARTEIRA,
          INPUT(t2.TD_SINERGIA, d4.) AS  TIPDEPCNX,
          T1.RLZD_NOTAS
      FROM RLZD_NOTAS_VICE T1
       INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON t1.PREFDEP = INPUT(t2.PREFDEP, d4.)
      ORDER BY 1, 2;
QUIT;
/*FINAL DO BLOCO DE CALCULO PARA AS HIERARQUIAS SUPERIORES A AGENCIA */

/***JUNTANDO HIERARIQUIAS ***/


PROC SQL;

CREATE TABLE NOTAS_AVCL_PJ_FINAL AS
 
   SELECT * FROM CRT
   OUTER UNION CORR
   SELECT * FROM DEPE
   OUTER UNION CORR
   SELECT * FROM GEREV
   OUTER UNION CORR
   SELECT * FROM SUPER
   OUTER UNION CORR
   SELECT * FROM UND
   OUTER UNION CORR
   SELECT * FROM DIR
   OUTER UNION CORR
   SELECT * FROM VICE
   ORDER BY 1, 2;

Quit;

/*ENVIANDO PARA O CONEXÃO*/

PROC SQL;
    CREATE TABLE CONEXAO AS
        SELECT
            '2000153'
            ||"&Tx_Fon"
            ||REPEAT(' ',45)
            ||COMPRESS(PUT(t1.PrefDep,Z4.))
            ||COMPRESS(PUT(t1.Carteira,Z5.))
            ||"&ANOMES"
            ||put(t1.TipDepCnx,z4.)
            ||'+'
            ||PUT(ABS(t1.RLZD_NOTAS)*100,z13.)
            ||'F6794004'
            ||COMPRESS(PUT(Today(), ddmmyy10.))
            ||'N' AS L
        FROM NOTAS_AVCL_PJ_FINAL t1       
;QUIT;


/*%GerarBBM(TabelaSAS=CONEXAO, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=M5144);*/




