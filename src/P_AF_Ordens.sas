%include '/dados/infor/suporte/FuncoesInfor.sas';
%diasUteis(%sysfunc(today()), 5);

%GLOBAL DiaUtil_D1;

DATA ARQ;
FORMAT AGORA $14.;
AGORA=put(&diaUtil_d0, ddmmyy6.)||"_"||compress(put(compress(put(time(),time5.),":"),$5.));
RUN;


proc sql noprint;
	create table work.datas as 
	select agora
	from arq;

	select distinct agora into: agora separated by ', '
	from work.arq;

quit;

%put &agora;
%conectardb2 (csh, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (cop, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (mci, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (acp, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (arc, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (OPR, AUTHDOMAIN=DB2SGCEN);



/*libnames*/ 
LIBNAME CER 	"/dados/gecen/interno/bases/cer" filelockwait=600 access=readonly;
LIBNAME REL 	"/dados/gecen/interno/bases/rel" filelockwait=600 access=readonly;
LIBNAME MCI		"/dados/gecen/interno/bases/mci" filelockwait=600 access=readonly;
LIBNAME AF		"/dados/infor/producao/AF";
LIBNAME BCS		"/dados/bcs";
LIBNAME RUT "/dados/infor/producao/RotinasUteis";

PROC SQL;
   CREATE TABLE WORK.dia_mais3 AS 
   SELECT t1.DataMovimento
      FROM RUT.TBL_DATAS_PROCESSAMENTO t1
      WHERE t1.D_menos_3 = today() AND t1.Dia_Util = 'S';
QUIT;
DATA _NULL_;
	SET dia_mais3;
	CALL SYMPUT('dia_mais3',"'"||Put(DataMovimento, FINDFDD10.)||"'");
RUN;
%put &dia_mais3;


%conectardb2 (cop, AUTHDOMAIN=DB2SGCEN);

PROC SQL;connect to db2 (authdomain=db2SGCEN database=bdb2p04); 
CREATE TABLE AF.SALDO_AF AS select * from connection to db2
                (SELECT
	SUM(t1.VL_SDO_PRD_MDLD) - (
		SELECT
			SUM(VL_SDO_CTR_OPR)
		FROM
			DB2ARC.CLC_RSCO_OPR
		WHERE
			CD_RSCO_ATBD = 'P' AND
			VL_SDO_CTR_OPR > 0 AND
			CD_PRD = 367 AND
			CD_MDLD = 1
	)  AS SALDO
FROM
	DB2OPR.SDO_CLI_PRD_AUX AS t1
WHERE
	t1.CD_PRD = 367 AND
	t1.CD_MDLD = 1);
QUIT;

%conectardb2 (cop, AUTHDOMAIN=DB2SGCEN);



/**/
/*PROC SQL;*/
/*CREATE TABLE AF.SALDO_AF AS*/
/*SELECT*/
/*    t1.CD_PRD,*/
/*    t1.CD_MDLD,*/
/*    t1.CD_PRF_DEPE AS AGENCIA,*/
/*    t1.NR_CTR_OPR AS CONTRATO,*/
/*    t1.CD_CLI AS MCI,*/
/*    t1.VL_SDO_CTR_OPR AS SALDO,*/
/*    t1.CD_RSCO_ATBD AS RISCO_OPERACAO,*/
/*    t1.NR_DD_VCD_OPR*/
/*FROM DB2ARC.CLC_RSCO_OPR t1*/
/*WHERE t1.CD_RSCO_ATBD <> 'P' AND*/
/*(t1.CD_PRD = 367 AND (t1.CD_MDLD IN (1)));*/
/**/
/*QUIT;*/

/**/
/*FILIAL MATRIZ*/

PROC SQL;connect to db2 (authdomain=db2SGCEN database=bdb2p04); 
   CREATE TABLE AF.FILIAL_MATRIZ AS  select * from connection to db2
   (SELECT t1.F_CLIENTE_COD,
          t1.F_PJURMTRZ_CLIENTE
      FROM DB2MCI.PESSOA_JURIDICA t1
      WHERE t1.IND_FILI = 'S' AND t1.F_PJURMTRZ_CLIENTE <> 0);
QUIT;





PROC SQL;
   CREATE TABLE AF.Convenios_AF AS
   (SELECT t1.PRF_DEPE_CNDU_OPER,
          t1.NRO_OPER,
          t1.DTA_FORM,
          t1.DTA_VENC,
          t1.VLR_OPER,
          t1.COD_CLTE,
          t1.NOM_CLTE,
          t1.SALDO,
          t1.MARGEM1 AS Margem_AF,
          t2.CD_RSCO_CRD_CLI AS CD_RSCO_CRD,
          t2.vl_sdo_MRG AS VL_LMCR_DSPN,
          t2.DT_VNCT_LIM
      FROM (SELECT t1.PRF_DEPE_CNDU_OPER,
          t1.NRO_OPER,
          t1.DTA_FORM,
          t1.DTA_VENC,
          t1.VLR_OPER,
          t1.COD_CLTE,
          t1.NOM_CLTE,
          t2.SALDO,
          /* Margem1 */
            (t1.VLR_OPER-(CASE
               WHEN  t2.SALDO is null THEN 0
               ELSE  t2.SALDO
            END)) FORMAT=19.2 AS Margem1
      FROM (SELECT t1.PRF_DEPE_CNDU_OPER,
          t1.NRO_OPER,
          t1.DTA_FORM,
          t1.DTA_VENC,
          t1.VLR_OPER,
          t1.COD_SITU_OPER,
          t2.COD_CLTE,
          t2.NOM_CLTE
      FROM DB2COP.TCOP100 t1
           INNER JOIN DB2COP.TCOP147 t2 ON (t1.NRO_PROP = t2.NRO_PROP)
      WHERE t1.COD_LNCR = 516 AND (t1.COD_SITU_OPER = 1 or t1.COD_SITU_OPER = 2 or t1.COD_SITU_OPER = 4)) t1
           LEFT JOIN (SELECT t1.CD_PRF_DEPE_CDU,
          t1.NR_CTR_OPR,
          t1.DT_FRMZ,
          t1.DT_VNCT,
          t1.VL_OPR,
          /* SUM_of_VL_SDO_SCTR */
            (SUM(t2.VL_SDO_SCTR)) FORMAT=19.2 AS SALDO
      FROM DB2OPR.CTR_OPR t1
           INNER JOIN DB2OPR.SDO_SCTR_OPR t2 ON (t1.NR_UNCO_CTR_OPR = t2.NR_UNCO_CTR_OPR)
      WHERE t1.CD_PRD = 367
      GROUP BY t1.CD_PRF_DEPE_CDU,
               t1.NR_CTR_OPR,
               t1.DT_FRMZ,
               t1.DT_VNCT,
               t1.VL_OPR) t2 ON (t1.NRO_OPER = t2.NR_CTR_OPR)) t1
           INNER JOIN BCS.TAB_LIMITE (PW="LIMPJ") t2 ON (t1.COD_CLTE = t2.CD_CLI)


     UNION


     SELECT t1.PRF_DEPE_CNDU_OPER,
          t1.NRO_OPER,
          t1.DTA_FORM,
          t1.DTA_VENC,
          t1.VLR_OPER,
          t1.COD_CLTE,
          t1.NOM_CLTE,
          t1.SALDO,
          t1.MARGEM1 AS Margem_AF,
          t2.CD_RSCO_CRD_CLI AS CD_RSCO_CRD,
          t2.vl_sdo_MRG AS VL_LMCR_DSPN,
          t2.DT_VNCT_LIM
      FROM (SELECT t1.PRF_DEPE_CNDU_OPER,
          t1.NRO_OPER,
          t1.DTA_FORM,
          t1.DTA_VENC,
          t1.VLR_OPER,
          t1.COD_CLTE,
          t1.NOM_CLTE,
          t2.SALDO,
          /* Margem1 */
            (t1.VLR_OPER-(CASE
               WHEN  t2.SALDO is null THEN 0
               ELSE  t2.SALDO
            END)) FORMAT=19.2 AS Margem1
      FROM (SELECT t1.PRF_DEPE_CNDU_OPER,
          t1.NRO_OPER,
          t1.DTA_FORM,
          t1.DTA_VENC,
          t1.VLR_OPER,
          t1.COD_SITU_OPER,
          t2.COD_CLTE,
          t2.NOM_CLTE
      FROM DB2COP.TCOP100 t1
           INNER JOIN DB2COP.TCOP147 t2 ON (t1.NRO_PROP = t2.NRO_PROP)
      WHERE t1.COD_LNCR = 516 AND (t1.COD_SITU_OPER = 1 OR t1.COD_SITU_OPER = 2 or t1.COD_SITU_OPER = 4)) t1
           LEFT JOIN (SELECT t1.CD_PRF_DEPE_CDU,
          t1.NR_CTR_OPR,
          t1.DT_FRMZ,
          t1.DT_VNCT,
          t1.VL_OPR,
          /* SUM_of_VL_SDO_SCTR */
            (SUM(t2.VL_SDO_SCTR)) FORMAT=19.2 AS SALDO
      FROM DB2OPR.CTR_OPR t1
           INNER JOIN DB2OPR.SDO_SCTR_OPR t2 ON (t1.NR_UNCO_CTR_OPR = t2.NR_UNCO_CTR_OPR)
      WHERE t1.CD_PRD = 367
      GROUP BY t1.CD_PRF_DEPE_CDU,
               t1.NR_CTR_OPR,
               t1.DT_FRMZ,
               t1.DT_VNCT,
               t1.VL_OPR) t2 ON (t1.NRO_OPER = t2.NR_CTR_OPR))t1, AF.FILIAL_MATRIZ t3, BCS.TAB_LIMITE (PW="LIMPJ") t2
      WHERE (t1.COD_CLTE = t3.F_CLIENTE_COD AND t3.F_PJURMTRZ_CLIENTE = t2.CD_CLI));
QUIT;

/**/
/*Taxas*/




PROC SQL;
   CREATE TABLE AF.NR_SEQL_TAXA AS
   SELECT DISTINCT t1.COD_CLTE,
          t1.NOM_CLTE,
          t3.NR_CTR_PCT_CPRD,
          t3.NR_SEQL_TAXA
      FROM AF.CONVENIOS_AF t1, DB2CSH.PCT_NEG t2, DB2CSH.TAXA_ORD_CPR t3
      WHERE (t1.COD_CLTE = t2.CD_CLI_PCT AND t2.NR_CTR_PCT_NEG = t3.NR_CTR_PCT_CPRD);
QUIT;


/**/
/*Fornecedores Autorizados*/
PROC SQL;
   CREATE TABLE AF.CADASTRO_FORNEC_AUTORIZADO_PJ AS
   SELECT DISTINCT t1.ANCORA,
          t1.MCI_FORNECEDOR,
          t1.NOME_FORNECEDOR,
          t1.CD_TIP_PCT,
          t1.CD_EST_CDVL,
          t1.IN_AUTZ_ATCC
      FROM (SELECT B.CD_CLI_PCT AS ANCORA , C.CD_CLI_PCT AS MCI_FORNECEDOR , C.NM_FANT_PCT AS NOME_FORNECEDOR, A.CD_TIP_PCT, A.CD_EST_CDVL, A.IN_AUTZ_ATCC
FROM DB2CSH.CDVL_PCT_NEG A,
     DB2CSH.PCT_NEG      B,
     DB2CSH.PCT_NEG      C INNER JOIN DB2MCI.CLIENTE t2 ON (c.CD_CLI_PCT = t2.COD)
where A.CD_TIP_PCT   = 1  
and   A.CD_EST_CDVL  = 1  
and   A.IN_AUTZ_ATCC = 'S'
and   C.CD_CLI_PCT <> 0
AND   A.NR_CTR_PCT_CPRD = B.NR_CTR_PCT_NEG
AND   A.NR_CTR_PCT_CDVL = C.NR_CTR_PCT_NEG
and   t2.COD_TIPO = 2) t1
           INNER JOIN AF.CONVENIOS_AF t2 ON (t1.ANCORA = t2.COD_CLTE);
QUIT;


/**/
/*Ordens de Compra Agendadas*/


proc sql;connect to db2 (authdomain=db2SGCEN database=bdb2p04);
	create table af.ordens_de_compra_agendadas as select * from connection to db2(
		select t2.cd_cli_pct as mci_ancora,
			t2.nm_fant_pct as nome_ancora,
			t4.cd_cli_pct as mci_fornecedor,
			t4.nm_fant_pct as nome_fonecedor,
			t1.cd_est_ord_cpr as situacao,
			t1.nr_ord_cpr,
			t1.vl_ord_cpr,
			t1.dt_vnct_ord_cpr,
			t1.nr_seql_taxa,
			t3.nr_bco_pgto,
			t3.cd_prf_ag_pgto,
			t3.dv_ag_pgto,
			t3.nr_ct_pgto,
			t3.dv_ct_pgto
		from db2csh.ord_cpr t1, db2csh.pct_neg t2, db2csh.rcb_pgto t3, db2csh.pct_neg t4, db2csh.dado_atcc_pct_neg t5
			where (t1.nr_ctr_pct_cprd = t2.nr_ctr_pct_neg 
				and t1.nr_ord_cpr = t3.nr_ord_cpr 
				and t1.nr_ctr_pct_cdvl = t4.nr_ctr_pct_neg) 
				and (t1.cd_est_ord_cpr in (3) 
				and t1.cd_chv_rsp_incl in ('SISTEMA', 'CSH240','VIA240', 'VIA240S' ))  
				and t4.cd_cli_pct <> 0 
				and t1.dt_vnct_ord_cpr >= &dia_mais3
				and t5.nr_ctr_pct_neg = t2.nr_ctr_pct_neg
				and t5.in_autz_atcc_pdro = 'S');
quit;

proc sql;connect to db2 (authdomain=db2SGCEN database=bdb2p04);
	create table af.ordens_de_compra_agendadas_cassi as select * from connection to db2(
		select t2.cd_cli_pct as mci_ancora,
			t2.nm_fant_pct as nome_ancora,
			t4.cd_cli_pct as mci_fornecedor,
			t4.nm_fant_pct as nome_fonecedor,
			t1.cd_est_ord_cpr as situacao,
			t1.nr_ord_cpr,
			t1.vl_ord_cpr,
			t1.dt_vnct_ord_cpr,
			t1.nr_seql_taxa,
			t3.nr_bco_pgto,
			t3.cd_prf_ag_pgto,
			t3.dv_ag_pgto,
			t3.nr_ct_pgto,
			t3.dv_ct_pgto
		from db2csh.ord_cpr t1, db2csh.pct_neg t2, db2csh.rcb_pgto t3, db2csh.pct_neg t4, db2csh.dado_atcc_pct_neg t5
			where (t1.nr_ctr_pct_cprd = t2.nr_ctr_pct_neg 
				and t1.nr_ord_cpr = t3.nr_ord_cpr 
				and t1.nr_ctr_pct_cdvl = t4.nr_ctr_pct_neg) 
				and (t1.cd_est_ord_cpr in (1) 
				and t1.cd_chv_rsp_incl in ('SISTEMA', 'CSH240','VIA240', 'VIA240S' ))  
				and t4.cd_cli_pct <> 0 
				and t1.dt_vnct_ord_cpr >= &dia_mais3
				and t5.nr_ctr_pct_neg = t2.nr_ctr_pct_neg
				and t5.in_autz_atcc_pdro = 'S'
				and t2.cd_cli_pct=903587815);
quit;

proc sql;
create table af.ordens_de_compra_agendadas_total as 
select a.*
from af.ordens_de_compra_agendadas a
union 
select b.*
from af.ordens_de_compra_agendadas_cassi b;
quit;



/*, 'CSH240' and CD_CHV_RSP_INCL CONTAINS "240")*/
/*proc sql;
create table lixo as
select distinct CD_CHV_RSP_INCL
from DB2CSH.ORD_CPR
where CD_CHV_RSP_INCL CONTAINS "240";
quit;
*/


/*Poderes*/

PROC SQL;
    CREATE TABLE    AF.lista AS
    SELECT DISTINCT ANCORA AS CD_CLI
    ,                1 AS TIPO
    FROM            AF.CADASTRO_FORNEC_AUTORIZADO_PJ
    UNION
    SELECT DISTINCT MCI_FORNECEDOR AS CD_CLI
    ,                2 AS TIPO
    FROM            AF.CADASTRO_FORNEC_AUTORIZADO_PJ
    ;

    CREATE TABLE    AF.lista2 AS
    SELECT             CD_CLI
    ,                SUM(TIPO) AS SUM_TIPO
    FROM             AF.LISTA
    GROUP BY        CD_CLI
    ;
QUIT;

PROC SQL;   
    CREATE TABLE AF.OTMZ_DICOR_PODER AS
    SELECT DISTINCT    CD_CLI FORMAT BEST32.
    FROM             AF.LISTA2
    ;
QUIT;

PROC SQL;
CREATE TABLE AF.OTMZ_DICOR_DOCUMENTO_PODER as
                select        a.*
                from        DB2MCI.DOCUMENTO_PODER a
                inner join    AF.OTMZ_DICOR_PODER b
                on            a.F_CLIENTE_COD = b.cd_cli
                where        a.DTA_VENC >= "01AUG2015"D
                or            a.DTA_VENC IS NULL
ORDER BY        F_CLIENTE_COD, COD_SEQL, COD_TIPO;
quit;

PROC SQL;
  
                CREATE TABLE AF.OTMZ_DICOR_PODER_OUTORGADO as
                select        a.*
                from        DB2MCI.PODER_OUTORGADO a
                inner join    AF.OTMZ_DICOR_DOCUMENTO_PODER b
                on            A.F_DCTOPODR_CLIENTE = B.F_CLIENTE_COD
                AND            A.F_DCTOPODR_CODSEQL = B.COD_SEQL
                WHERE        F_PODER_COD IN (45 148)

    ORDER BY        F_DCTOPODR_CLIENTE
    ,                F_DCTOPODR_CODSEQL
    ,                F_PODER_COD
    ;
    
QUIT;


proc sql;
	create table af.otmz_dicor_representante as
		select distinct 
			a.*
			from db2mci.representante a
				inner join    af.otmz_dicor_poder_outorgado b
					on            a.f_dctopodr_cliente = b.f_dctopodr_cliente
					and            a.f_poder_cod = b.f_poder_cod
					and           (a.dta_baix_otga_repr > "01aug2015"d
					or   a.dta_baix_otga_repr is null)

				order by        f_dctopodr_cliente
					,                f_dctopodr_codseql
					,                f_poder_cod
	;
quit;

proc sql;
	create table af.otmz_dicor_representante_nome as
		select distinct        b.*, a.nome as nome
			from        mci.clientes_pf a
				inner join    af.otmz_dicor_representante b
					on            (a.cd_cli = b.f_cliente_otgdo)
				order by        f_dctopodr_cliente
					,                f_dctopodr_codseql
					,                f_poder_cod
	;
quit;


%conectardb2 (mci, AUTHDOMAIN=DB2SGCEN);


/*RESTRIÇÕES FORNECEDORES AUTORIZADOS - FLEXIBILIZADOS PARA CRÉDITO NO BB*/

proc sql;
	connect to db2 (authdomain=db2SVARC database=bdb2p04);
	create table restr_anot as  select DISTINCT * from connection to db2(
		select DISTINCT CD_PSS_RLCD_IOR AS CD_CLI,
			t2.CD_TIP_ANOT AS CD_TIP_ANOT_CADL,
			T2.QT_PESO_ANOT,
			T2.VL_ANOT_CADL
		from (SELECT CD_PSS_RLCD_IOR, NR_CTRE_SRF, CD_TIP_ANOT, VL_ANOT_CADL, CD_PESO_ANOT AS QT_PESO_ANOT FROM DB2ACP.ANOT_PSS_CFMD_BCRO  WHERE CD_PESO_ANOT IN (3, 4)
			AND CD_TIP_ANOT IN (210, 195, 216, 217, 272, 82, 227, 126, 215, 277, 125, 153, 174, 270, 3, 271, 295, 165, 215, 277, 125, 153, 174, 270,
			3, 271, 295, 165, 246, 175, 128, 88, 65, 173, 85, 64, 68, 36, 304, 269, 275, 248, 39, 232, 233, 207, 224, 274, 230,    181, 10, 167, 211, 58,
			303, 120, 66, 121, 83, 279, 234) AND CD_PSS_RLCD_IOR IS NOT NULL) T2)
ORDER BY 1;
CREATE INDEX CD_CLI ON RESTR_ANOT(CD_CLI);
quit;

PROC SQL;
    CREATE TABLE AF.RESTR_CRED_BB_FORNEC_AUTOR_PJ AS
    SELECT DISTINCT
        T1.MCI_FORNECEDOR,
        T1.NOME_FORNECEDOR,
        T2.CD_TIP_ANOT_CADL,
        /*T2.TX_RDZ_TIP_ANOT,
        T2.QT_OBJ,*/
        T2.QT_PESO_ANOT,
        T2.VL_ANOT_CADL
    FROM (
            SELECT DISTINCT
                T1.ANCORA,
                T1.MCI_FORNECEDOR,
                T1.NOME_FORNECEDOR,
                T1.CD_TIP_PCT,
                T1.CD_EST_CDVL,
                T1.IN_AUTZ_ATCC
            FROM (
                    SELECT
                        B.CD_CLI_PCT AS ANCORA ,
                        C.CD_CLI_PCT AS MCI_FORNECEDOR ,
                        C.NM_FANT_PCT AS NOME_FORNECEDOR,
                        A.CD_TIP_PCT,
                        A.CD_EST_CDVL,
                        A.IN_AUTZ_ATCC
                    FROM
                        DB2CSH.CDVL_PCT_NEG A,
                        DB2CSH.PCT_NEG      B,
                        DB2CSH.PCT_NEG      C,
                        DB2MCI.CLIENTE      D
                    WHERE
                            A.CD_TIP_PCT   = 1
                        AND   A.CD_EST_CDVL  = 1
                        AND   A.IN_AUTZ_ATCC = 'S'
                        AND   C.CD_CLI_PCT <> 0
                        AND   A.NR_CTR_PCT_CPRD = B.NR_CTR_PCT_NEG
                        AND   A.NR_CTR_PCT_CDVL = C.NR_CTR_PCT_NEG
                        AND   C.CD_CLI_PCT = D.COD
                        AND   D.COD_TIPO = 2
                ) T1
                INNER JOIN AF.CONVENIOS_AF T2 ON (T1.ANCORA = T2.COD_CLTE)
        ) T1
        LEFT JOIN (
                select * FROM restr_anot
            ) T2 ON (T1.MCI_FORNECEDOR = T2.CD_CLI)
    ;
QUIT;


PROC SQL;
    CREATE TABLE AF.RESTRICOES_IMPED_FORNEC_AUTOR_PJ AS
        SELECT DISTINCT
            T1.MCI_FORNECEDOR,
            T1.NOME_FORNECEDOR,
            T2.CD_TIP_ANOT_CADL,
            /*T2.TX_RDZ_TIP_ANOT,
            T2.QT_OBJ,*/
            T2.QT_PESO_ANOT,
            T2.VL_ANOT_CADL
        FROM (
            SELECT DISTINCT
                T1.ANCORA,
                T1.MCI_FORNECEDOR,
                T1.NOME_FORNECEDOR,
                T1.CD_TIP_PCT,
                T1.CD_EST_CDVL,
                T1.IN_AUTZ_ATCC
            FROM (
                SELECT
                    B.CD_CLI_PCT AS ANCORA ,
                    C.CD_CLI_PCT AS MCI_FORNECEDOR ,
                    C.NM_FANT_PCT AS NOME_FORNECEDOR,
                    A.CD_TIP_PCT,
                    A.CD_EST_CDVL,
                    A.IN_AUTZ_ATCC
                FROM DB2CSH.CDVL_PCT_NEG A,
                    DB2CSH.PCT_NEG      B,
                    DB2CSH.PCT_NEG      C,
                    DB2MCI.CLIENTE      D
                WHERE A.CD_TIP_PCT   = 1
                    AND   A.CD_EST_CDVL  = 1
                    AND   A.IN_AUTZ_ATCC = 'S'
                    AND   C.CD_CLI_PCT <> 0
                    AND   A.NR_CTR_PCT_CPRD = B.NR_CTR_PCT_NEG
                    AND   A.NR_CTR_PCT_CDVL = C.NR_CTR_PCT_NEG
                    AND   C.CD_CLI_PCT = D.COD
                    AND   D.COD_TIPO = 2
            ) T1
            INNER JOIN AF.CONVENIOS_AF T2 ON (T1.ANCORA = T2.COD_CLTE)
        ) T1
            LEFT JOIN (select * FROM restr_anot) T2 ON (T1.MCI_FORNECEDOR = T2.CD_CLI)
           
        ;
QUIT;






PROC SQL;
   CREATE TABLE AF.Convenio_AB AS 
   SELECT t2.MCI_ANCORA, 
          t2.NOME_ANCORA, 
          t2.MCI_FORNECEDOR, 
          t2.NOME_FONECEDOR, 
          t2.SITUACAO, 
          t2.NR_ORD_CPR, 
          t2.VL_ORD_CPR, 
          t2.DT_VNCT_ORD_CPR, 
          t2.NR_SEQL_TAXA, 
          t2.NR_BCO_PGTO, 
          t2.CD_PRF_AG_PGTO, 
          t2.DV_AG_PGTO, 
          t2.NR_CT_PGTO, 
          t2.DV_CT_PGTO
      FROM AF.CONVENIOS_AF t1
           INNER JOIN AF.ordens_de_compra_agendadas_total t2 ON (t1.COD_CLTE = t2.MCI_ANCORA)
      WHERE t1.CD_RSCO_CRD IN ('A','B') and (t2.mci_ancora NOT IN (100122685, 603378064, 205343430/*, 903587815*/));
QUIT;

proc sql;
	create table af.ordens_finais as 
		select t1.mci_ancora, 
			t1.nome_ancora, 
			t1.mci_fornecedor, 
			t1.nome_fonecedor, 
			t1.situacao, 
			t1.nr_ord_cpr, 
			t1.vl_ord_cpr, 
			t1.dt_vnct_ord_cpr, 
			t1.nr_seql_taxa, 
			t1.nr_bco_pgto, 
			t1.cd_prf_ag_pgto, 
			t1.dv_ag_pgto, 
			t1.nr_ct_pgto, 
			t1.dv_ct_pgto
		from af.convenio_ab t1
			left join af.restricoes_imped_fornec_autor_pj t2 on (t1.mci_fornecedor = t2.mci_fornecedor)
				where t2.cd_tip_anot_cadl is missing
					order by 3;
quit;

proc sql;
	create table af.ordens_finais_encarteirados as 
		select 
			ifc(t2.cd_prf_depe = ., "4777", put(t2.cd_prf_depe, z4.)) as prefdep, 
			ifn(t2.nr_seql_ctra = ., 9999, t2.nr_seql_ctra) as cart, 
			t1.mci_ancora, 
			t1.nome_ancora, 
			t1.mci_fornecedor, 
			t1.nome_fonecedor, 
			t1.situacao, 
			t1.nr_ord_cpr, 
			t1.vl_ord_cpr, 
			t1.dt_vnct_ord_cpr, 
			t1.nr_seql_taxa, 
			t1.nr_bco_pgto, 
			t1.cd_prf_ag_pgto, 
			t1.dv_ag_pgto, 
			t1.nr_ct_pgto, 
			t1.dv_ct_pgto,
			&diautil_d0 format yymmdd10. as mvto
		from af.ordens_finais t1		
			left join rel.rel t2 on (t1.mci_fornecedor = t2.cd_cli) where t2.cd_tIp_ctra not in (321, 322, 323, 328) and t2.cd_prf_depe ne 9940;
quit;

proc sql;
	create table af.ordens_finais_encarteirados as 
		select 
			IFC (t1.prefdep IN ('   .' '0000' '4777'),PUT (T2.pref_agen_cdto, Z4.),t1.prefdep) AS PREFDEP,
          IFN (t1.cart=.,7002,t1.cart) AS CART,
			t1.mci_ancora, 
			t1.nome_ancora, 
			t1.mci_fornecedor, 
			t1.nome_fonecedor, 
			t1.situacao, 
			t1.nr_ord_cpr, 
			t1.vl_ord_cpr, 
			t1.dt_vnct_ord_cpr, 
			t1.nr_seql_taxa, 
			t1.nr_bco_pgto, 
			t1.cd_prf_ag_pgto, 
			t1.dv_ag_pgto, 
			t1.nr_ct_pgto, 
			t1.dv_ct_pgto,
			t1.mvto
		from af.ordens_finais_encarteirados t1		
			left join bcn.bcn_pj t2 on (t1.mci_fornecedor = t2.mci);
quit;

/*evitar duplicação no caso de reprocessamento*/
data temp; 
set af.ordens_finais_enc_hst(where=(mvto < &diautil_d0));
run;

proc sql;
	insert into temp
		(prefdep, 
		cart, 
		mci_ancora, 
		nome_ancora, 
		mci_fornecedor, 
		nome_fonecedor, 
		situacao, 
		nr_ord_cpr, 
		vl_ord_cpr, 
		dt_vnct_ord_cpr, 
		nr_seql_taxa, 
		nr_bco_pgto, 
		cd_prf_ag_pgto, 
		dv_ag_pgto, 
		nr_ct_pgto, 
		dv_ct_pgto,
		mvto)
	select 
		prefdep, 
		cart, 
		mci_ancora, 
		nome_ancora, 
		mci_fornecedor, 
		nome_fonecedor, 
		situacao, 
		nr_ord_cpr, 
		vl_ord_cpr, 
		dt_vnct_ord_cpr, 
		nr_seql_taxa, 
		nr_bco_pgto, 
		cd_prf_ag_pgto, 
		dv_ag_pgto, 
		nr_ct_pgto, 
		dv_ct_pgto,
		mvto
	from af.ordens_finais_encarteirados;
quit;

data af.ordens_finais_enc_hst; set temp; run;

/*criar tabela com as ordens sem duplicação - mantendo sempre somente a primeira de cada mci_fornecedor*/
data hst;
	set af.ordens_finais_encarteirados;
run;

proc sort data=hst nodupkey;
	by _all_;
run;

/*
data af.ordens_unicas_enc_hst;
	set af.ordens_finais_enc_hst;
	if mvto = "21sep2015"d;
run;

proc sort data=af.ordens_unicas_enc_hst nodupkey;
	by _all_;
run;

data af.ordens_finais_enc_hst; set hst_16 hst_17 hst_18; run;*/
/*
2015-09-16	859
2015-09-17	955
2015-09-18	865*/

proc sql;
	create table work.hst_temp1 as 
		select 
			mci_ancora, 
			mci_fornecedor, 
			nr_ord_cpr, 
			min(dt_vnct_ord_cpr) format=date9. as dt_vnct_ord_cpr
		from af.ordens_unicas_enc_hst
			group by 1,2,3;
quit;

proc sql;
	create table work.hst_temp2 as 
		select 
			mci_ancora, 
			mci_fornecedor, 
			nr_ord_cpr, 
			min(dt_vnct_ord_cpr) format=date9. as dt_vnct_ord_cpr
		from work.hst
			group by 1,2,3;
quit;

proc sql;
	create table work.novos as 
		select b.mci_ancora, 
			b.mci_fornecedor, 
			b.nr_ord_cpr, 
			b.dt_vnct_ord_cpr
		from work.hst_temp1 a
			right join work.hst_temp2 b on (a.mci_ancora = b.mci_ancora 
						and a.mci_fornecedor = b.mci_fornecedor 
						and a.nr_ord_cpr = b.nr_ord_cpr 
						and a.dt_vnct_ord_cpr = b.dt_vnct_ord_cpr)
			where 	a.mci_ancora is missing 
				and a.mci_fornecedor is missing 
				and a.nr_ord_cpr is missing 
				and a.dt_vnct_ord_cpr is missing;
quit;

proc sql;
	create table work.adiciona_novos as 
		select a.*
		from work.hst a, 
			work.novos b
			where (	a.mci_ancora = b.mci_ancora 
				and a.mci_fornecedor = b.mci_fornecedor 
				and a.nr_ord_cpr = b.nr_ord_cpr 
				and a.dt_vnct_ord_cpr = b.dt_vnct_ord_cpr);
quit;

data af;
	set af.ordens_unicas_enc_hst;
run;

proc sql;
	create table af.ordens_unicas_enc_hst as 
		select * 
			from af
				outer union corr 
					select * from work.adiciona_novos;
quit;

proc sort data=af.ordens_unicas_enc_hst nodupkey; by _all_; run;
/*criar tabela com as ordens sem duplicação */

PROC SQL;
   CREATE TABLE AF.ORDENS_FINAIS_ENCARTEIRADOS_DIR AS 
   SELECT t2.PrefUEN, 
          t1.PrefDep, 
          t1.CART, 
          t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR, 
          t1.SITUACAO, 
          t1.NR_ORD_CPR, 
          t1.VL_ORD_CPR, 
          t1.DT_VNCT_ORD_CPR, 
          t1.NR_SEQL_TAXA, 
          t1.NR_BCO_PGTO, 
          t1.CD_PRF_AG_PGTO, 
          t1.DV_AG_PGTO, 
          t1.NR_CT_PGTO, 
          t1.DV_CT_PGTO
      FROM AF.ORDENS_FINAIS_ENCARTEIRADOS t1
           LEFT JOIN COMUM.igrrede t2 ON (t1.PrefDep = t2.PrefDep);
QUIT;

PROC SQL;
   CREATE TABLE AF.MCI_BCN AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
		  t2.tipo_carteira,
          t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR, 
          t2.vlr_faturamento, 
          t2.CD_EST_LMCR AS situacao_limite_credito,
		  t2.MAX_PESO_ANOT_CADL AS restricao_cadastral,
		  T2.CNPJ
      FROM AF.ORDENS_FINAIS_ENCARTEIRADOS t1
           LEFT JOIN BCN.bcn_pj t2 ON (t1.MCI_FORNECEDOR = t2.mci);
QUIT;


PROC SQL;
   CREATE TABLE AF.MCI_LIMITES AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
          t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR,  
          (T2.slim_disp_1 + T2.slim_disp_151 + T2.slim_disp_158 + T2.slim_disp_166 + T2.slim_disp_17 + T2.slim_disp_196 + T2.slim_disp_197 + T2.slim_disp_198 + T2.slim_disp_2 + T2.slim_disp_20 + T2.slim_disp_201 + T2.slim_disp_203 + T2.slim_disp_205 + T2.slim_disp_206 + T2.slim_disp_207 + T2.slim_disp_208 + T2.slim_disp_209 + T2.slim_disp_25 + T2.slim_disp_26 + T2.slim_disp_3 + T2.slim_disp_37 + T2.slim_disp_44 + T2.slim_disp_5 + T2.slim_disp_6 + T2.slim_disp_7 + T2.slim_disp_78)
		  AS LIM_APROV, 
          (T2.vlr_utlz_acl + T2.vlr_utlz_agronegocios + T2.vlr_utlz_bndes_capital_giro + T2.vlr_utlz_cartao_bndes + T2.vlr_utlz_comercio_exterior + T2.vlr_utlz_credito_empresa + T2.vlr_utlz_demais_capital_giro + T2.vlr_utlz_demais_investimentos + T2.vlr_utlz_demais_recebiveis + T2.vlr_utlz_desconto_cheques + T2.vlr_utlz_desconto_titulos + T2.vlr_utlz_fco_empresarial + T2.vlr_utlz_finame + T2.vlr_utlz_giro_cartoes + T2.vlr_utlz_giro_empresa_flex + T2.vlr_utlz_giro_mix_pasep + T2.vlr_utlz_giro_rapido + T2.vlr_utlz_giro_recebiveis + T2.vlr_utlz_proger_urbano)
		  AS LIM_UTIL, 
            (CALCULATED LIM_APROV - CALCULATED LIM_UTIL) AS Lim_disp
      FROM AF.ordens_finais_encarteirados t1
           LEFT JOIN BCN.BCN_PJ t2 ON (t1.MCI_FORNECEDOR = t2.MCI);
QUIT;

/*risco do cliente*/
%conectardb2 (ANC, AUTHDOMAIN=DB2SGCEN);

proc sql;
	create table mcis as
		select distinct mci_fornecedor
			from af.ordens_finais_encarteirados
	order by 1;
quit;

proc sql;
	create table af.risco_cliente_local as 
		select distinct t1.cd_cli as mci_fornecedor, 
			t1.dt_vnct_lim as dt_vnct_lim, 
			t1.cd_rsco_crd_cli,
			t1.ts_ult_atl
		from db2anc.lmcr_cli_cfmd_bcro t1
			inner join work.mcis t2 on (t1.cd_cli = t2.mci_fornecedor);
quit;

proc sql;
	create table risco_cliente_max as 
		select distinct t1.mci_fornecedor, 
			(max(t1.dt_vnct_lim)) format=date9. as dt_vnct_lim,
			(max(t1.ts_ult_atl)) format=date9. as ts_ult_atl 
		from af.risco_cliente_local t1 group by 1;
quit;

proc sql;
	create table af.risco_cliente as 
		select t1.mci_fornecedor, 
			t1.dt_vnct_lim, 
			t2.cd_rsco_crd_cli
		from work.risco_cliente_max t1, af.risco_cliente_local t2
			where (t1.mci_fornecedor = t2.mci_fornecedor and t1.ts_ult_atl = t2.ts_ult_atl);
quit;

/*
proc sql;
CREATE TABLE AF.risco_cliente AS 
   SELECT DISTINCT t1.CD_CLI as MCI_FORNECEDOR, 
          t1.CD_RSCO_CRD_CLI 
         FROM af.risco_cliente_local t1
INNER JOIN DB2ANC.LMCR_CLI_CFMD_BCRO t2 ON ((t2.CD_CLI = t1.MCI_FORNECEDOR) and ((t2.DT_VNCT_LIM = t1.DT_VNCT_LIM))) group by 1;
quit;*/


/*cer - endividamento*/
%ls(/dados/gecen/interno/bases/cer, out=work.cer_tbl);
data work.out_ls2;
	set work.cer_tbl;
	where pasta eq './' and substr(arquivo,1,15) in ('endividados_sfn');

	tabela = scan(arquivo,1,'.');

	dt_ref = input(scan(tabela,-1,'_'),yymmn6.);

	format dt_ref yymmn6.;
run;

proc sql noprint;
	select tabela into: tabela2
	from work.out_ls2
	where dt_ref = (select max(dt_ref) from work.out_ls2) 	;
quit;

proc sql;
create table posicao_scr as
   select max(dt_ref) format=mmyyn6. as posicao_scr 
      from out_ls2;
quit;

%put &tabela2;

proc sql;
	create table endividados_sfn as 
		select 
			b.mci_fornecedor as cd_cli, 
			cd_tip_vnct, 
			sum(vl_sfn) as vl_sfn, 
			sum(vl_bb) as vl_bb, 
			sum(vl_fora_bb) as vl_fora_bb
		from mcis b
		left join cer.&tabela2 a on (b.mci_fornecedor = a.cd_cli)
	group by 1,2;
quit;

proc sql;
	create table extrato_scr as 
		select 
			cd_cli, 
		/* 4. Fluxo de Vencimentos*/
			ifn(cd_tip_vnct = 110, vl_bb, 0) as vencer_14_30_bb,
			ifn(cd_tip_vnct = 110, vl_sfn, 0) as vencer_14_30_sfn,
			ifn(cd_tip_vnct = 110, vl_fora_bb, 0) as vencer_14_30_fora,
			ifn(cd_tip_vnct = 120, vl_bb, 0) as vencer_31_60_bb,
			ifn(cd_tip_vnct = 120, vl_sfn, 0) as vencer_31_60_sfn,
			ifn(cd_tip_vnct = 120, vl_fora_bb, 0) as vencer_31_60_fora,
			ifn(cd_tip_vnct = 130, vl_bb, 0) as vencer_61_90_bb,
			ifn(cd_tip_vnct = 130, vl_sfn, 0) as vencer_61_90_sfn,
			ifn(cd_tip_vnct = 130, vl_fora_bb, 0) as vencer_61_90_fora,
			ifn(cd_tip_vnct = 140, vl_bb, 0) as vencer_91_180_bb,
			ifn(cd_tip_vnct = 140, vl_sfn, 0) as vencer_91_180_sfn,
			ifn(cd_tip_vnct = 140, vl_fora_bb, 0) as vencer_91_180_fora,
			ifn(cd_tip_vnct = 150, vl_bb, 0) as vencer_181_360_bb,
			ifn(cd_tip_vnct = 150, vl_sfn, 0) as vencer_181_360_sfn,
			ifn(cd_tip_vnct = 150, vl_fora_bb, 0) as vencer_181_360_fora,
			ifn(cd_tip_vnct = 160, vl_bb, 0) as vencer_ac_361_bb,
			ifn(cd_tip_vnct = 160, vl_sfn, 0) as vencer_ac_361_sfn,
			ifn(cd_tip_vnct = 160, vl_fora_bb, 0) as vencer_ac_361_fora,
		/*vencidos*/
			ifn(cd_tip_vnct = 210, vl_bb, 0) as vencido_15_30_bb,
			ifn(cd_tip_vnct = 210, vl_sfn, 0) as vencido_15_30_sfn,
			ifn(cd_tip_vnct = 210, vl_fora_bb, 0) as vencido_15_30_fora,
			ifn(cd_tip_vnct = 220, vl_bb, 0) as vencido_31_60_bb,
			ifn(cd_tip_vnct = 220, vl_sfn, 0) as vencido_31_60_sfn,
			ifn(cd_tip_vnct = 220, vl_fora_bb, 0) as vencido_31_60_fora,
			ifn(cd_tip_vnct = 230, vl_bb, 0) as vencido_61_90_bb,
			ifn(cd_tip_vnct = 230, vl_sfn, 0) as vencido_61_90_sfn,
			ifn(cd_tip_vnct = 230, vl_fora_bb, 0) as vencido_61_90_fora,

			ifn(cd_tip_vnct in (240 245 250), vl_bb, 0) as vencido_91_180_bb,
			ifn(cd_tip_vnct in (240 245 250), vl_sfn, 0) as vencido_91_180_sfn,
			ifn(cd_tip_vnct in (240 245 250), vl_fora_bb, 0) as vencido_91_180_fora,
			
			ifn(cd_tip_vnct in (255 260 270), vl_bb, 0) as vencido_181_360_bb,
			ifn(cd_tip_vnct in (255 260 270), vl_sfn, 0) as vencido_181_360_sfn,
			ifn(cd_tip_vnct in (255 260 270), vl_fora_bb, 0) as vencido_181_360_fora,

			ifn(cd_tip_vnct in (280 290), vl_bb, 0) as vencido_ac_361_bb,
			ifn(cd_tip_vnct in (280 290), vl_sfn, 0) as vencido_ac_361_sfn,
			ifn(cd_tip_vnct in (280 290), vl_fora_bb, 0) as vencido_ac_361_fora,
		/*Prejuizo*/
			ifn(cd_tip_vnct = 310, vl_bb, 0) as prej_baix_ate_12m_bb,
			ifn(cd_tip_vnct = 310, vl_sfn, 0) as prej_baix_ate_12m_sfn,
			ifn(cd_tip_vnct = 310, vl_fora_bb, 0) as prej_baix_ate_12m_fora,

			ifn(cd_tip_vnct = 320, vl_bb, 0) as prej_baix_aci_12m_bb,
			ifn(cd_tip_vnct = 320, vl_sfn, 0) as prej_baix_aci_12m_sfn,
			ifn(cd_tip_vnct = 320, vl_fora_bb, 0) as prej_baix_aci_12m_fora			
	from endividados_sfn;
quit;

proc sql;
	create table extrato_scr_1 as 
		select distinct 
			cd_cli, 
			(sum(vencer_14_30_bb)) as vencer_14_30_bb, 
			(sum(vencer_14_30_sfn)) as vencer_14_30_sfn, 
			(sum(vencer_14_30_fora)) as vencer_14_30_fora, 
			(sum(vencer_31_60_bb)) as vencer_31_60_bb, 
			(sum(vencer_31_60_sfn)) as vencer_31_60_sfn, 
			(sum(vencer_31_60_fora)) as vencer_31_60_fora, 
			(sum(vencer_61_90_bb)) as vencer_61_90_bb, 
			(sum(vencer_61_90_sfn)) as vencer_61_90_sfn, 
			(sum(vencer_61_90_fora)) as vencer_61_90_fora, 
			(sum(vencer_91_180_bb)) as vencer_91_180_bb, 
			(sum(vencer_91_180_sfn)) as vencer_91_180_sfn, 
			(sum(vencer_91_180_fora)) as vencer_91_180_fora, 
			(sum(vencer_181_360_bb)) as vencer_181_360_bb, 
			(sum(vencer_181_360_sfn)) as vencer_181_360_sfn, 
			(sum(vencer_181_360_fora)) as vencer_181_360_fora, 
			(sum(vencer_ac_361_bb)) as vencer_ac_361_bb, 
			(sum(vencer_ac_361_sfn)) as vencer_ac_361_sfn, 
			(sum(vencer_ac_361_fora)) as vencer_ac_361_fora, 
			(sum(vencido_15_30_bb)) as vencido_15_30_bb, 
			(sum(vencido_15_30_sfn)) as vencido_15_30_sfn, 
			(sum(vencido_15_30_fora)) as vencido_15_30_fora, 
			(sum(vencido_31_60_bb)) as vencido_31_60_bb, 
			(sum(vencido_31_60_sfn)) as vencido_31_60_sfn, 
			(sum(vencido_31_60_fora)) as vencido_31_60_fora, 
			(sum(vencido_61_90_bb)) as vencido_61_90_bb, 
			(sum(vencido_61_90_sfn)) as vencido_61_90_sfn, 
			(sum(vencido_61_90_fora)) as vencido_61_90_fora, 
			(sum(vencido_91_180_bb)) as vencido_91_180_bb, 
			(sum(vencido_91_180_sfn)) as vencido_91_180_sfn, 
			(sum(vencido_91_180_fora)) as vencido_91_180_fora, 
			(sum(vencido_181_360_bb)) as vencido_181_360_bb, 
			(sum(vencido_181_360_sfn)) as vencido_181_360_sfn, 
			(sum(vencido_181_360_fora)) as vencido_181_360_fora, 
			(sum(vencido_ac_361_bb)) as vencido_ac_361_bb, 
			(sum(vencido_ac_361_sfn)) as vencido_ac_361_sfn, 
			(sum(vencido_ac_361_fora)) as vencido_ac_361_fora, 
			(sum(prej_baix_ate_12m_bb)) as prej_baix_ate_12m_bb, 
			(sum(prej_baix_ate_12m_sfn)) as prej_baix_ate_12m_sfn, 
			(sum(prej_baix_ate_12m_fora)) as prej_baix_ate_12m_fora, 
			(sum(prej_baix_aci_12m_bb)) as prej_baix_aci_12m_bb, 
			(sum(prej_baix_aci_12m_sfn)) as prej_baix_aci_12m_sfn, 
			(sum(prej_baix_aci_12m_fora)) as prej_baix_aci_12m_fora,

			sum(prej_baix_ate_12m_sfn + prej_baix_aci_12m_sfn) as prej_baix_sfn,

			sum(prej_baix_ate_12m_bb + prej_baix_aci_12m_bb) as prej_baix_bb,

			sum(prej_baix_ate_12m_fora + prej_baix_aci_12m_fora) as prej_baix_fora,
			sum(vencer_14_30_sfn + vencer_31_60_sfn + vencer_61_90_sfn + vencer_91_180_sfn +
				vencer_181_360_sfn + vencer_ac_361_sfn) as cred_vencer_sfn,

			sum(vencer_14_30_bb + vencer_31_60_bb + vencer_61_90_bb + vencer_91_180_bb + 
				vencer_181_360_bb + vencer_ac_361_bb) as cred_vencer_bb,

			(calculated cred_vencer_sfn) - (calculated cred_vencer_bb) as vencer_fora,

			sum(vencido_15_30_bb + vencido_15_30_fora + vencido_31_60_bb + vencido_31_60_fora + 
				vencido_61_90_bb + vencido_61_90_fora + vencido_91_180_bb + vencido_91_180_fora + 
				vencido_181_360_bb + vencido_181_360_fora + vencido_ac_361_bb + vencido_ac_361_fora) as cred_vencidos_sfn,
			
			sum(vencido_15_30_bb + vencido_31_60_bb + vencido_61_90_bb + vencido_91_180_bb + 
				vencido_181_360_bb + vencido_ac_361_bb ) as cred_vencidos_bb,
		
			(calculated cred_vencidos_sfn) - (calculated cred_vencidos_bb) as vencidos_fora

		from work.extrato_scr 
			group by 1;
quit;

data af.endividamento_scr(keep= cd_cli cred_vencer_sfn cred_vencer_bb vencer_fora cred_vencidos_sfn cred_vencidos_bb vencidos_fora);
set extrato_scr_1;
		if 	cred_vencer_sfn	< 0	then 	cred_vencer_sfn	=0;
		if 	cred_vencer_bb	< 0	then 	cred_vencer_bb	=0;
		if 	vencer_fora	< 0	then 	vencer_fora	=0;
		if 	cred_vencidos_sfn	< 0	then 	cred_vencidos_sfn	=0;
		if 	cred_vencidos_bb	< 0	then 	cred_vencidos_bb	=0;
		if 	vencidos_fora	< 0	then 	vencidos_fora	=0;
run;

/*Inad 15*/
proc sql;
    connect to db2 (authdomain=db2sgcen database=bdb2p04); 
        create table af.inad_15 as
            select *
            from connection to db2
                (select	distinct			
                t3.cd_pss_ctr_opr as mci,
				t3.nr_unco_ctr_opr,
				t3.nr_ctr_opr,
				t3.cd_prd,
				t3.cd_mdld,
				t1.VL_SDO_CTR_OPR
                  from 	db2opr.prtc_pss_ctr_opr t3, 
						db2arc.clc_rsco_opr t1, 
						db2opr.sctr_opr t2
                where ((t1.nr_unco_ctr_opr = t2.nr_unco_ctr_opr and t1.nr_unco_ctr_opr = t3.nr_unco_ctr_opr)
                and t1.nr_dd_vcd_opr >= 15
                and t2.cd_est_espl_ctr not in (30))               
				) order by  mci;
     disconnect from db2;
quit;

proc sql;
   create table af.inad_15_ctr as 
   select distinct 
		t1.mci_fornecedor, 
          sum(t2.VL_SDO_CTR_OPR) as vl_sdo_ctr_opr
      from work.mcis t1
           left join af.inad_15 t2 on (t1.mci_fornecedor = t2.mci)
		group by 1;
quit;


proc sql;
	create table af.ordens_valores_encart99 as 
		select distinct
			prefdep,
			t1.mci_fornecedor,
			t1.NR_ORD_CPR,
            t1.vl_ord_cpr as valorantecip
		from af.ordens_finais_encarteirados t1
			group by 1,2,3;
quit;
proc sql;
	create table af.ordens_valores_encart as 
		select 
			prefdep,
			t1.mci_fornecedor,
            sum(t1.valorantecip) as valorantecip
		from af.ordens_valores_encart99 t1
			group by 1,2;
quit;

proc sql;
	create table af_final as 
		select distinct 
			t1.prefdep, 
			t1.cart, 
			t2.tipo_carteira,
			t1.mci_fornecedor,
			. as mci_ancora,
			t2.cnpj,
			2 as tipo, 
			t1.nome_fonecedor, 
			t2.vlr_faturamento format best20.2, 
			t4.cred_vencer_sfn, 
			t4.cred_vencer_bb, 
			t4.cred_vencidos_sfn,
			ifn(t4.cred_vencidos_sfn>0,1,0) as venc_sfn,
			t4.cred_vencidos_bb,
			ifn(t4.cred_vencidos_bb>0,1,0) as venc_bb, 
			t2.situacao_limite_credito, 
			t5.cd_rsco_crd_cli, 
			t3.lim_aprov, 
			t3.lim_util, 
			t3.lim_disp, 
			t2.restricao_cadastral, 
			t6.vl_sdo_ctr_opr as valorinad,
			ifn((t6.vl_sdo_ctr_opr)>0,1,0) as possui_inad15,
			ifc((t2.situacao_limite_credito=2)and(t4.cred_vencidos_sfn=0) and(t6.vl_sdo_ctr_opr=0) and (t2.restricao_cadastral=0),"perfil 1", 
				ifc((t2.situacao_limite_credito<>2)and(t4.cred_vencidos_sfn=0) and(t6.vl_sdo_ctr_opr=0) and (t2.restricao_cadastral=0),"perfil 2", 
					ifc((t4.cred_vencidos_sfn=0) and(t6.vl_sdo_ctr_opr>0),"perfil 3","perfil 4"))) as perfil,
			t7.valorantecip
		from af.ordens_finais_encarteirados t1 
	left join af.mci_bcn t2 on (t1.mci_fornecedor = t2.mci_fornecedor) 
	left join af.mci_limites t3 on (t1.mci_fornecedor = t3.mci_fornecedor) 
	left join af.endividamento_scr t4 on (t1.mci_fornecedor = t4.cd_cli) 
	left join af.risco_cliente t5 on (t1.mci_fornecedor = t5.mci_fornecedor) 
	left join af.inad_15_ctr t6 on (t1.mci_fornecedor = t6.mci_fornecedor) 
	left join af.ordens_valores_encart t7  on (t1.mci_fornecedor = t7.mci_fornecedor and t1.prefdep = t7.prefdep) 
	where input(t1.prefdep, 4.) <> . ;
quit;


proc sql;
	create table pref_4777 as 
		select  
			&diautil_d1 format yymmdd10. as mvto,
			t1.prefdep,
			"sem prefixo" as nomedep, 
			count(t1.mci_fornecedor) as qtde_fornecedores, 
			sum(t1.valorantecip) as valorantecipado
		from work.af_final t1
			where t1.prefdep = '4777'
				group by 1,2;
quit;

proc sql;
	create table verificacao_diaria as 
		select 
			&DiaUtil_D1 format yymmdd10. as mvto,
			t3.prefdep, 
			t3.nomedep, 
			count(t1.mci_fornecedor) as qtde_fornecedores, 
			sum(t1.valorantecip) format=commax19.2 as valorantecipado
		from af.af_final t1, 
			comum.dependencias t2, 
			comum.dependencias t3
		where (t1.prefdep = t2.prefdep and t2.prefdir = t3.prefdep) and (t2.sb = '00' and t3.sb = '00')
			group by t3.prefdep, t3.nomedep;
quit;

data historico_diario;
set af.historico_diario; 
run;

data af.historico_diario;
set verificacao_diaria pref_4777; run;

proc sql;
	create table af.af_final as 
		select distinct 
			t1.*,
			&diautil_d1 format yymmdd10. as mvto
		from af_final t1
			inner join bcn.bcn_pj t2 on (t1.mci_fornecedor = t2.mci)
				where prefdep <> "4777";
libname bcn clear;
quit;

proc export data=AF.af_final
	outfile="/dados/infor/producao/AF/AF_rel_adiant_fornec.txt"
	dbms=dlm
	replace;
	putnames=no;
	delimiter=';';
run;

/*
proc sql;
	insert into af.ordens_finais_enc_hst
		(t1.PrefDep, 
          t1.CART, 
          t1.tipo_carteira, 
          t1.MCI_FORNECEDOR, 
          t1.mci_ancora, 
          t1.cnpj, 
          t1.tipo, 
          t1.NOME_FONECEDOR, 
          t1.vlr_faturamento, 
          t1.cred_vencer_sfn, 
          t1.cred_vencer_bb, 
          t1.cred_vencidos_sfn, 
          t1.venc_sfn, 
          t1.cred_vencidos_bb, 
          t1.venc_bb, 
          t1.situacao_limite_credito, 
          t1.CD_RSCO_CRD_CLI, 
          t1.LIM_APROV, 
          t1.LIM_UTIL, 
          t1.Lim_disp, 
          t1.restricao_cadastral, 
          t1.valorinad, 
          t1.possui_inad15, 
          t1.perfil, 
          t1.valorantecip)
	select 
		prefdep, 
		cart, 
		mci_ancora, 
		nome_ancora, 
		mci_fornecedor, 
		nome_fonecedor, 
		situacao, 
		nr_ord_cpr, 
		vl_ord_cpr, 
		dt_vnct_ord_cpr, 
		nr_seql_taxa, 
		nr_bco_pgto, 
		cd_prf_ag_pgto, 
		dv_ag_pgto, 
		nr_ct_pgto, 
		dv_ct_pgto,
		mvto
	from af.ORDENS_FINAIS_ENCARTEIRADOS;
quit;*/

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="truncate rel_adiantamento_fornecedor" ;
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/AF/AF_rel_adiant_fornec.txt' INTO TABLE rel_adiantamento_fornecedor FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'" 2>teste.txt;

proc sql;
	create table af.detalhamento_ordens as 
		select distinct
			t2.mci_fornecedor, 
			t1.nro_oper, 
			t2.mci_ancora, 
			t2.nome_ancora,
			t2.nr_ord_cpr,
			"x" as risco, 
			T2.DT_VNCT_ORD_CPR format yymmdd10. as DATA, 
			t2.vl_ord_cpr as valor
		from af.ordens_finais_encarteirados t2
			left join af.convenios_af t1 on (t2.mci_ancora = t1.cod_clte)
		order by 1,2,3,4,5;
quit;

proc export data=AF.DETALHAMENTO_ORDENS
	outfile="/dados/infor/producao/AF/AF_DetalhaOrdens.txt"
	dbms=dlm
	replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="truncate rel_adiantamento_fornecedor_ordem" ;
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/AF/AF_DetalhaOrdens.txt' INTO TABLE rel_adiantamento_fornecedor_ordem FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";

x cd /dados/infor/utilitarios;
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="call rel_adiantamento_fornecedor";

x cd /dados/infor/producao/AF;
x chmod 2777 *;

x cd /dados/infor/producao/AF/Dados_saida;
x chmod 2777 *;





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
