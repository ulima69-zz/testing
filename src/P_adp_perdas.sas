%include '/dados/infor/suporte/FuncoesInfor.sas';	
%diasUteis(%sysfunc(today()), 1);
%GLOBAL DiaUtil_D1;

/*libnames*/
Options
	Compress = no
	Reuse    = Yes
	PageNo   =   1
	PageSize =  55
	LineSize = 110;

%conectardb2(atb);
%conectardb2(OPR);
libname EC "/dados/infor/producao/indic_eficiencia_cobranca/dados_saida";
libname icred "/dados/infor/producao/inad_15_90";
LIBNAME PCLD_VP "/dados/infor/producao/pcld_vp";
LIBNAME PCLD_N "/dados/infor/producao/pcld_vp/201602";
libname mci "/dados/gecen/interno/bases/mci";
LIBNAME DB2ARC db2 AUTHDOMAIN=DB2SGCEN schema=DB2ARC database=BDB2P04;
libname ind_e 	"/dados/infor/producao/indic_eficiencia_cobranca/dados_entrada";
libname ind_s 	"/dados/infor/producao/indic_eficiencia_cobranca/dados_saida";
LIBNAME DB2VARRC DB2 DATABASE=BDB2P04 AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2PGT db2 AUTHDOMAIN=DB2SGCEN schema=DB2PGT database=BDB2P04;
LIBNAME DB2RAO db2 AUTHDOMAIN=DB2SGCEN schema=DB2RAO database=BDB2P04;
libname dicre "/dados/dicre/publico";
libname dirao "/dados/dirao/publico";
libname gcn "/dados/externo/GECEN";
libname b_dados "/dados/publica/b_dados";



data datas;
	format agora $14.
		dt_arquivo date9.
		anomes yymmn6.;
	agora=put(today(), ddmmyy6.)||"_"||compress(put(compress(put(time(),time5.),":"),$5.));
	dt_arquivo=%lowcase(today());
	anomes=&DiaUtil_D1;
run;

proc sql noprint;
	select distinct agora into: agora separated by ', '
	from datas;

	select distinct dt_arquivo into: dt_arquivo separated by ', '
	from datas;

	select distinct anomes into: anomes separated by ', '
	from datas;
quit;
%GLOBAL dt_arquivo AnoMes;

data _null_; set PCLD_VP.Max_data_cred; call symput('Dataant',put (MaxData, DATE9.));run;

PROC SQL;
   CREATE TABLE PCLD_VP.Max_data_cred AS 
   SELECT DISTINCT 
                     (MAX(t1.DT_CCL_CTB)) FORMAT=FINDFDD10. AS MaxData
      FROM DB2ARC.CMPS_PVS_DRIA t1;
QUIT;

data PCLD_VP.Max_data_cred_&Dataant; set PCLD_VP.Max_data_cred; run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatual_1',MaxData);run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatual',"'"||put (MaxData, FINDFDD10.)||"'");run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatu',put (MaxData, DATE9.));run;
data _null_; set PCLD_VP.Max_data_cred; call symput('rotina',"'"||put (MaxData, yymmdd10.)||"'");run;
%put &rotina;
%put &Dataatual;


PROC SQL;
    CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
    CREATE TABLE PERDAS_ESTOQUE AS
    SELECT *
    FROM CONNECTION TO DB2
        (  
         SELECT DISTINCT
         DIGITS(X.NR_UNCO_CTR_OPR) AS NR_UNCO_CTR_OPR, 
		 E.CD_TIP_CPF_CGC AS CD_TIP_PSS,
        E.CD_PSS_CTR_OPR AS CD_CLI,
        B.CD_PRF_DEPE_CDU AS MAIOR_DEPE_RAO,
		X.DT_TRNS_PRJZ,
         SUM(X.VL_TRND_PRJZ) AS  VL_TRND_PRJZ
         FROM DB2OPR.SDO_SCTR_OPR AS X
        LEFT JOIN DB2OPR.SCTR_OPR AS A ON (X.NR_UNCO_CTR_OPR = A.NR_UNCO_CTR_OPR AND X.NR_EPRD_FNCD = A.NR_EPRD_FNCD AND X.NR_SCTR_OPR = A.NR_SCTR_OPR)
        LEFT JOIN DB2OPR.CTR_OPR AS B ON (X.NR_UNCO_CTR_OPR = B.NR_UNCO_CTR_OPR)
        LEFT JOIN DB2OPR.PRTC_PSS_CTR_OPR E ON (X.NR_UNCO_CTR_OPR = E.NR_UNCO_CTR_OPR)
         WHERE (X.DT_TRNS_PRJZ > current date - 5 years) AND
        E.NR_SEQL_PRTC = 1
        GROUP BY X.NR_UNCO_CTR_OPR, E.CD_TIP_CPF_CGC, E.CD_PSS_CTR_OPR, B.CD_PRF_DEPE_CDU, X.DT_TRNS_PRJZ
        ORDER BY 1);
    DISCONNECT FROM DB2;
	CREATE INDEX NR_UNCO_CTR_OPR ON PERDAS_ESTOQUE(NR_UNCO_CTR_OPR);
QUIT;

PROC sql;
create table icred.LST_QLF_GECEN_PEC_Pda as 
select * 
from dirao.LST_QLF_GECEN_PEC_Pda
order by NR_UNCO_CTR_OPR;
create index NR_UNCO_CTR_OPR on icred.LST_QLF_GECEN_PEC_Pda(NR_UNCO_CTR_OPR);
quit;

PROC SQL;
CREATE TABLE OPR_UNICO AS 
SELECT NR_UNCO_CTR_OPR FROM icred.LST_QLF_GECEN_PEC_Pda
UNION
SELECT NR_UNCO_CTR_OPR FROM PERDAS_ESTOQUE;
CREATE INDEX NR_UNCO_CTR_OPR ON OPR_UNICO(NR_UNCO_CTR_OPR);
RUN;

PROC SQL;
   CREATE TABLE WORK.LST_QLF_GECEN_PEC_Pda AS 
   SELECT t2.NR_UNCO_CTR_OPR, 
          IFN (t3.MAIOR_DEPE_RAO=., T2.MAIOR_DEPE_RAO, T3.MAIOR_DEPE_RAO) AS MAIOR_DEPE_RAO,
          IFN (t3.CD_PSS_CLI_OPR=., T2.CD_CLI, T3.CD_PSS_CLI_OPR) AS CD_PSS_CLI_OPR,
          IFN (t3.CD_TIP_PSS=., T2.CD_TIP_PSS,T3.CD_TIP_PSS) AS CD_TIP_PSS,
          t3.IN_BOLETAVEL, 
          t3.IN_FGO, 
          t3.PEC_CLIENTE, 
          t3.IN_FALECIDO, 
          IFN (t3.SALDO=.,T2.VL_TRND_PRJZ,T3.SALDO) AS SALDO, 
          DT_TRNS_PRJZ AS DT_PDA_POS_2010, 
          t3.IN_AJUIZ, 
          t3.DT_EST_AJUIZ
		  
      FROM WORK.PERDAS_ESTOQUE t2 
           LEFT JOIN ICRED.LST_QLF_GECEN_PEC_Pda t3 ON (t2.NR_UNCO_CTR_OPR = t3.NR_UNCO_CTR_OPR)
ORDER BY 3;
CREATE INDEX CD_PSS_CLI_OPR ON LST_QLF_GECEN_PEC_Pda(CD_PSS_CLI_OPR);
QUIT;


proc sql;
	create table icred.perdas_enc as 
		select 
			ifc(t2.cd_cli=., PUT(t1.MAIOR_DEPE_RAO,Z4.),put (t2.CD_PRF_DEPE, z4.)) as Prefdep, 
			ifN(t2.cd_tip_ctra NOT in (10,16,25,40,41,42,43,44,45,46,47,48,49,50,54,55,56,57,60,190,200,210,303,315,400,405,406,407,430,500,550,321,322,323,324,328) OR t2.cd_tip_ctra=.,7002, t2.nr_seql_ctra) as cart,
			T1.*
		from LST_QLF_GECEN_PEC_Pda t1
			left join comum.pai_rel_&anomes t2 on (t1.CD_PSS_CLI_OPR = t2.cd_cli)
			ORDER BY T1.CD_PSS_CLI_OPR	;
quit;

LIBNAME DB2BIC db2 AUTHDOMAIN=DB2SGCEN schema=DB2BIC database=BDB2P04;

PROC SQL;
   CREATE TABLE WORK.SUB_RSTD_INRO AS 
   SELECT t1.CD_RSTD_INRO AS cod_resultado, 
          t1.CD_SUB_RSTD_INRO AS cod_sub_resultado, 
          t1.TX_SUB_RSTD_INRO AS COD_SUB_RESULTADO_DESCRIcao, 
          t1.DT_INC_VGC, 
          t1.DT_FIM_VGC
      FROM DB2BIC.SUB_RSTD_INRO t1;
QUIT;

PROC SQL;
   CREATE TABLE QUERY_FOR_INRO_CLI AS 
   SELECT t1.CD_CLI as mci, 
          t1.TS_INRO_CLI format datetime25.6 as timestamp_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO
      FROM DB2BIC.AUX_INRO_CLI_ATU t1
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-30
		and t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  or t1.CD_RSTD_INRO = 2)
	  group by 1
	  union
	  SELECT t1.CD_CLI as mci, 
          t1.TS_INRO_CLI format datetime25.6 as timestamp_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO
      FROM DB2BIC.AUX_INRO_CLI_Ant t1
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-30
		and t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  or t1.CD_RSTD_INRO = 2)
group by 1
;
QUIT;

proc sql;
create table max as 
select distinct mci,
max (timestamp_contato) format datetime25.6 as timestamp_contato
from WORK.QUERY_FOR_INRO_CLI
group by 1;
quit;

proc sql;
create table contatos_unicos as 
select distinct t1.mci,
 datepart (t1.timestamp_contato) format yymmdd10. as data_contato,
          t2.CD_RSTD_INRO, 
          t2.CD_SUB_RSTD_INRO, 
          t2.CD_ASNT_INRO, 
          t2.CD_SUB_ASNT_INRO
from max t1
inner join QUERY_FOR_INRO_CLI t2 on (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
where (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
group by 1, 2;
quit;



PROC SQL;
   CREATE TABLE WORK.contatos AS 
   SELECT t1.mci, 
          t1.data_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t2.COD_SUB_RESULTADO_DESCRIcao
      FROM WORK.contatos_unicos t1, WORK.SUB_RSTD_INRO t2
      WHERE (t1.CD_RSTD_INRO = t2.cod_resultado AND t1.CD_SUB_RSTD_INRO = t2.cod_sub_resultado);
QUIT;

PROC SQL;
   CREATE TABLE icred.adp_operacoes_perdas AS 
   SELECT NR_UNCO_CTR_OPR,
		  t1.CD_PSS_CLI_OPR as MCI, 
          t1.Prefdep,  
		  '' as gerev,
		  '' as super,
          t1.cart, 
		  ifn (IN_BOLETAVEL='S',1,0) as IN_BOLETAVEL,
		  IFN (IN_FGO='S',1,0) AS IN_FGO,
		  IFN (IN_FALECIDO='S',1,0) AS IN_FALECIDO,
          t1.saldo format 19.2 as VLR_PERDAS, 
		  '' as contato,
		  '' as ctt,
		  t1.PEC_CLIENTE as Teto_max_desc_PEC/*,
		  ifn (t2.mci=.,0,1) as seguro_pendente*/,
		  DT_PDA_POS_2010
      FROM ICRED.PERDAS_ENC t1

/*left join icred.prestamista_pendente t3 on (t1.CD_PSS_CLI_OPR=t3.mci)*/;
QUIT;






PROC SQL;
   CREATE TABLE icred.cli_perdas_ctt AS 
   SELECT DISTINCT t1.MCI, 
          t1.Prefdep, 
		  '' as gerev,
		  '' as super,
          t1.cart, 
          SUM (t1.VLR_PERDAS) AS VLR_PERDAS, 
          t2.data_contato, 
          t2.COD_SUB_RESULTADO_DESCRIcao, 
          MAX (t1.Teto_max_desc_PEC) AS Teto_max_desc_PEC
      FROM ICRED.ADP_OPERACOES_PERDAS t1
	  left join contatos t2 on (t1.MCI=t2.mci)
GROUP BY 2, 3, 1;
QUIT;

proc sql;
create table cli_perdas_ctt as 
select t1.mci,
t1.prefdep,
t5.prefgerev,
t1.cart,
t1.vlr_perdas,
t1.data_contato,
t1.COD_SUB_RESULTADO_DESCRIcao,
t1.Teto_max_desc_PEC
from icred.cli_perdas_ctt t1
inner join igr.auxiliar_relatorios t5 on (t1.prefdep=t5.prefdep)
order by t5.prefgerev, t1.vlr_perdas desc;
quit;

data cli_perdas_ctt_1;
set cli_perdas_ctt (where= (prefdep ne '4777'));
by prefgerev;
if first.prefgerev then seq_gerev=0;
seq_gerev+1;
if seq_gerev>1000 then prefgerev='';

run;


proc sql;
create table cli_perdas_ctt_2 as 
select t1.mci,
t1.prefdep,
t1.prefgerev,
t5.prefsuper,
t1.cart,
t1.vlr_perdas,
t1.data_contato,
t1.COD_SUB_RESULTADO_DESCRIcao,
t1.Teto_max_desc_PEC
from cli_perdas_ctt_1 t1
inner join igr.auxiliar_relatorios t5 on (t1.prefdep=t5.prefdep)
order by t5.prefsuper, t1.vlr_perdas desc;
quit;

data cli_perdas_ctt_3 (drop=seq_super  seq_gerev);
set cli_perdas_ctt_2 (where= (prefdep ne '4777'));
by prefsuper;
if first.prefsuper then seq_super=0;
seq_super+1;
if seq_super>1000 then prefsuper='';

run;

proc sql;
	create table cli_perdas_ctt_4 as 
		select distinct  t1.*,
			. as liberacao
		from cli_perdas_ctt_3 t1
			/*left join icred.BASE_FGTS_LIEBRACAO t2 on (t1.mci=t2.mci)*/
	ORDER BY T1.MCI;
	CREATE INDEX MCI ON cli_perdas_ctt_4(MCI);
quit;

PROC SQL;
	CREATE TABLE SALDOS AS 
		SELECT DISTINCT A.mci, 
			A.saldo_d2, 
			A.saldo_investimento
		FROM BCN.BCN_PF A INNER JOIN cli_perdas_ctt_4 B ON (A.MCI=B.MCI)
			UNION
		SELECT DISTINCT C.mci, 
			C.saldo_d2, 
			C.saldo_investimento
		FROM BCN.BCN_PJ C INNER JOIN cli_perdas_ctt_4 D ON (C.MCI=D.MCI);		
	CREATE INDEX MCI ON SALDOS(MCI);
QUIT;

PROC SQL;
	create table pag_ag as 
		SELECT t1.DT_OGNL_PGTO,
			t1.VL_PGTO,
			t1.NR_DOC_BNFC_MCI
		FROM DB2PGT.MVT_PGTO t1
			WHERE t1.DT_OGNL_PGTO BETWEEN &DiaUtil_D0 AND &DiaUtil_D0+15
				and NR_DOC_BNFC_MCI not in (., 0)
				and CD_EST_PGTO='PEN'
				AND CD_PRD=127;
QUIT;

PROC SQL;
	CREATE TABLE WORK.pag_ag_acl AS 
		SELECT today() format date9. as DT_OGNL_PGTO,
			t1.potencial as VL_PGTO,
			t1.mci as NR_DOC_BNFC_MCI		  
		FROM ICRED.POTENCIAL_ACL t1
			union 
		select t2.DT_OGNL_PGTO,
			t2.VL_PGTO,
			t2.NR_DOC_BNFC_MCI
		from pag_ag t2;
QUIT;

PROC SQL;
	CREATE TABLE WORK.PAG_AG_ACL AS 
		SELECT t1.NR_DOC_BNFC_MCI, 
			(MIN(t1.DT_OGNL_PGTO)) FORMAT=DATE9. AS DT_OGNL_PGTO, 
			(SUM(t1.VL_PGTO)) AS VL_PGTO
		FROM WORK.PAG_AG_ACL t1
			GROUP BY t1.NR_DOC_BNFC_MCI;
QUIT;

PROC SQL;
	CREATE TABLE LISTA_QUALIF_GECEN_20160729 AS 
		SELECT t1.CD_CLI, 
			put (t1.CD_PRF_DEPE_CTRA, z4.) as prefdep,
			t1.NR_SEQL_CTRA as cart, 
			t1.CD_TIP_CTRA, 
			t1.PROB_REC, 
			t1.IND_INCOBRAVEL, 
			t1.TAXA_PE, 
			t1.VL_INAD_ATU, 
			t1.FLUXO_PCLD_PRJ, 
			t1.ORDEM,
			max (t1.TETO_DESC_PEC_ESP) as TETO_MAX_DESC_PEC
		FROM DICRE.LISTA_QUALIF_GECEN t1
			group by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CLI_PERDAS_CTT_5 AS 
   SELECT t1.*, 
          t2.saldo_d2, 
          t2.saldo_investimento, 
          t3.VL_PGTO,
		  t4.TETO_MAX_DESC_PEC as pec_especial
      FROM WORK.CLI_PERDAS_CTT_4 t1
           LEFT JOIN WORK.SALDOS t2 ON (t1.MCI = t2.mci)
           LEFT JOIN WORK.PAG_AG_ACL t3 ON (t1.MCI = t3.NR_DOC_BNFC_MCI)
			LEFT JOIN WORK.LISTA_QUALIF_GECEN_20160729 t4 ON (t1.MCI = t4.cd_cli);
QUIT;

PROC SQL;
   CREATE TABLE GCN.cli_perdas_ctt AS 
   SELECT t1.MCI, 
          t1.Prefdep, 
          t1.cart, 
          t1.VLR_PERDAS
      FROM WORK.CLI_PERDAS_CTT_4 t1;
QUIT;


PROC SQL;
   CREATE TABLE adp_operacoes_perdas AS 
   SELECT distinct NR_UNCO_CTR_OPR,
		  t1.MCI, 
          t1.Prefdep,  
		  t2.prefgerev,
		  t2.prefsuper,
          t1.cart, 
		  t1.IN_BOLETAVEL,
		  t1.IN_FGO,
		  t1.IN_FALECIDO,
          t1.VLR_PERDAS, 
		  '' as contato,
		  '' as ctt,
		  t1.Teto_max_desc_PEC,
		  . as gecor,
		  DT_PDA_POS_2010 format yymmdd10.
      FROM ICRED.adp_operacoes_perdas t1
		left join cli_perdas_ctt_3 t2 on (t1.mci=t2.mci)
;
QUIT;


proc export
	data=CLI_PERDAS_CTT_5
	outfile="/dados/infor/producao/inad_15_90/cli_perdas_ctt.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_cliente_perdas";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/cli_perdas_ctt.txt' into table adp_cliente_perdas fields terminated by ';' lines terminated by '\n'";

x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_cliente_perdas(&rotina);";


%put &rotina;

proc export
	data=adp_operacoes_perdas
	outfile="/dados/infor/producao/inad_15_90/adp_operacoes_perdas.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_operacoes_perdas";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/adp_operacoes_perdas.txt' into table adp_operacoes_perdas fields terminated by ';' lines terminated by '\n'";

x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_operacoes_perdas();";




PROC SQL;
   CREATE TABLE WORK.cli_novo_rel AS 
   SELECT t1.MCI, 
          coalesce(input(t1.Prefdep, 4.),0),
          coalesce(input(t1.PrefGerev, 4.),0),
          coalesce(input(t1.PrefSuper, 4.),0),
          coalesce(t1.cart, 7002),
          coalesce(t1.VLR_PERDAS, 0),
          t1.data_contato, 
          t1.COD_SUB_RESULTADO_DESCRIcao, 
          t1.Teto_max_desc_PEC, 
          t1.liberacao, 
          coalesce(t1.saldo_d2, 0),
          coalesce(t1.saldo_investimento, 0),
          coalesce(t1.VL_PGTO, 0),
          t1.pec_especial
      FROM WORK.CLI_PERDAS_CTT_5 t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.opr_novo_rel AS 
   SELECT t1.NR_UNCO_CTR_OPR, 
          t1.MCI, 
          coalesce(input(t1.Prefdep, 4.),0),
          coalesce(input(t1.PrefGerev, 4.),0),
          coalesce(input(t1.PrefSuper, 4.),0),
          coalesce(t1.cart, 7002),
          t1.IN_BOLETAVEL, 
          t1.IN_FGO, 
          t1.IN_FALECIDO, 
          coalesce(t1.VLR_PERDAS, 0),
          t1.contato, 
          t1.ctt, 
          t1.Teto_max_desc_PEC, 
          coalesce(t1.gecor,0),
          t1.DT_PDA_POS_2010
      FROM WORK.ADP_OPERACOES_PERDAS t1;
QUIT;

x cd /;
x cd /dados/infor/producao/inad_15_90;
x chmod 777 *; /*ALTERAR PERMIS?S*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/

x cd /;
x cd /dados/infor/producao/inad_15_90/201701;
x chmod 777 *; /*ALTERAR PERMIS?S*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/

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
