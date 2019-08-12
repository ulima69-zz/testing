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
libname EC "/dados/infor/producao/indic_eficiencia_cobranca/dados_saida";
libname icred "/dados/infor/producao/inad_15_90";
LIBNAME PCLD_VP "/dados/infor/producao/pcld_vp/201701";
LIBNAME PCLD_N "/dados/infor/producao/pcld_vp/201602";
libname mci "/dados/gecen/interno/bases/mci";
LIBNAME DB2ARC db2 AUTHDOMAIN=DB2SGCEN schema=DB2ARC database=BDB2P04;
LIBNAME DB2MCI db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI database=BDB2P04;
libname ind_e 	"/dados/infor/producao/indic_eficiencia_cobranca/dados_entrada";
libname ind_s 	"/dados/infor/producao/indic_eficiencia_cobranca/dados_saida";
LIBNAME DB2VARRC DB2 DATABASE=BDB2P04 AUTHDOMAIN='DB2SGCEN';
LIBNAME DB2PGT db2 AUTHDOMAIN=DB2SGCEN schema=DB2PGT database=BDB2P04;
LIBNAME DB2RAO db2 AUTHDOMAIN=DB2SGCEN schema=DB2RAO database=BDB2P04;
libname dicre "/dados/dicre/publico";
libname gcn "/dados/externo/GECEN";
libname b_dados "/dados/publica/b_dados";
libname agro "/dados/externo/GECEN/Agro/";



data datas;
	format agora $14.
		dt_arquivo date9.
		anomes yymmn6.;
	agora=put(today(), ddmmyy6.)||"_"||compress(put(compress(put(time(),time5.),":"),$5.));
	dt_arquivo=%lowcase(today());
	anomes=today();
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

/*data _null_; set PCLD_VP.Max_data_cred; call symput('Dataant',put (MaxData, DATE9.));run;

PROC SQL;
   CREATE TABLE PCLD_VP.Max_data_cred AS 
   SELECT DISTINCT 
                     (MAX(t1.DT_CCL_CTB)) FORMAT=FINDFDD10. AS MaxData
      FROM DB2ARC.CMPS_PVS_DRIA t1;
QUIT;*/


data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatual_1',MaxData);run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatual',"'"||put (MaxData, FINDFDD10.)||"'");run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatu',put (MaxData, DATE9.));run;
data _null_; set PCLD_VP.Max_data_cred; call symput('rotina',"'"||put (MaxData, yymmdd10.)||"'");run;
%put &rotina;
%put &Dataatual;

%ls(/dados/externo/GECEN/Agro, out=work.teste);

data work.out_ls;
    set work.teste;
    where pasta eq './' and substr(arquivo,1,26) in ('dirag_20180227_inad90_1t18');

    tabela = scan(arquivo,1,'.');
    dt_ref = scan(tabela,-1,'_');
run;

proc sql noprint;
    select tabela into: tabela
    from work.out_ls
    order by dt_ref desc;
quit;

%put &tabela;



PROC SQL;
   CREATE TABLE CLI AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
          t1.cart, 
          t1.pilar, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.VL_ATR_SCTR, 
          t1.vl_dsp_pvs_crd, 
          t1.fluxo_prj, 
          t1.opr_inad90, 
		  IFN (opr_inad90=1,t1.saldo_opr,0) AS VLR_INAD90,
          t1.opr_inad15, 
		  IFN (opr_inad15=1,t1.saldo_opr,0) AS VLR_INAD15,
          t1.ec, 
		  IFN (ec=1,t1.saldo_opr,0) AS VLR_ec,
          t1.ordem,
		  T1.NR_UNCO_CTR_OPR
      FROM ICRED.ICRED_INAD_EC_PRIORI_FLUXO t1;
QUIT;
LIBNAME DB2BIC db2 AUTHDOMAIN=DB2SGCEN schema=DB2BIC database=BDB2P04;

PROC SQL;
   CREATE TABLE WORK.SUB_RSTD_INRO AS 
   SELECT t1.CD_RSTD_INRO AS cod_resultado, 
          t1.CD_SUB_RSTD_INRO AS cod_sub_resultado, 
          t1.TX_SUB_RSTD_INRO AS COD_SUB_RESULTADO_DESCRICAO, 
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
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-15
		and t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  or t1.CD_RSTD_INRO = 2)
group by 1;
QUIT;


PROC SQL;
   CREATE TABLE QUERY_FOR_INRO_CLI_1 AS 
   SELECT t1.CD_CLI as mci, 
          t1.TS_INRO_CLI format datetime25.6 as timestamp_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO
      FROM DB2BIC.AUX_INRO_CLI_Ant t1
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-15
		and t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  or t1.CD_RSTD_INRO = 2)
group by 1;
QUIT;

proc sql;
create table todos as 
select t1.* from 
QUERY_FOR_INRO_CLI_1 t1
union 
select t2.*
from QUERY_FOR_INRO_CLI t2;
quit;

proc sql;
create table max_1 as 
select distinct mci,
max (timestamp_contato) format datetime25.6 as timestamp_contato
from WORK.todos
group by 1;
quit;

proc sql;
create table contatos_unicos_1 as 
select distinct t1.mci,
 datepart (t1.timestamp_contato) format yymmdd10. as data_contato,
          t2.CD_RSTD_INRO, 
          t2.CD_SUB_RSTD_INRO, 
          t2.CD_ASNT_INRO, 
          t2.CD_SUB_ASNT_INRO
from max_1 t1
inner join todos t2 on (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
where (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
group by 1, 2;
quit;



PROC SQL;
   CREATE TABLE WORK.contatos AS 
   SELECT t1.mci, 
          t1.data_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t2.COD_SUB_RESULTADO_DESCRICAO
      FROM WORK.contatos_unicos_1 t1, WORK.SUB_RSTD_INRO t2
      WHERE (t1.CD_RSTD_INRO = t2.cod_resultado AND t1.CD_SUB_RSTD_INRO = t2.cod_sub_resultado);
QUIT;


PROC SQL;
	create table pag_ag as 
		SELECT t1.DT_OGNL_PGTO,
			t1.VL_PGTO,
			t1.NR_DOC_BNFC_MCI
		FROM DB2PGT.MVT_PGTO t1
			WHERE t1.DT_OGNL_PGTO BETWEEN &DiaUtil_D0+1 AND &DiaUtil_D0+15
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
          compress (t1.PROB_REC, '1 2 3 4 5 6 7 8 9 0 -') as prob_rec,
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
   CREATE TABLE pec AS 
   SELECT t1.CD_CLI, 
          max (t1.TETO_MAX_DESC_PEC) as TETO_MAX_DESC_PEC
      FROM LISTA_QUALIF_GECEN_20160729 t1
group by 1;
QUIT;

PROC SQL;
   CREATE TABLE sum_cli AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
          t1.cart, 
          t1.pilar, 
          max (t1.NR_DD_VCD_OPR) as NR_DD_VCD_OPR, 
          sum (t1.saldo_opr) as saldo_opr, 
          sum (t1.VL_ATR_SCTR) as VL_ATR_SCTR, 
          sum (t1.vl_dsp_pvs_crd) as vl_dsp_pvs_crd, 
          sum (t1.fluxo_prj) as fluxo_prj, 
          max (t1.opr_inad90) as opr_inad90, 
          sum (t1.VLR_INAD90) as VLR_INAD90, 
          max (t1.opr_inad15) as opr_inad15, 
          sum (t1.VLR_INAD15) as VLR_INAD15, 
          max (t1.ec) as ec, 
          sum (t1.VLR_ec) as VLR_ec, 
          t1.ordem,
		  count (distinct t1.NR_UNCO_CTR_OPR) as qtd_opr
      FROM WORK.CLI t1 
group by 2, 3, 1;
QUIT;



PROC SQL;
   CREATE TABLE icred.sum_cli AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
		  t5.prefgerev,
          t1.cart, 
          t1.pilar, 
          NR_DD_VCD_OPR, 
          saldo_opr, 
          VL_ATR_SCTR, 
          vl_dsp_pvs_crd, 
          fluxo_prj, 
          opr_inad90, 
          VLR_INAD90, 
          opr_inad15, 
          VLR_INAD15, 
          ec, 
          VLR_ec, 
          t1.ordem, 
          t2.data_contato, 
          qtd_opr,
		  T2.COD_SUB_RESULTADO_DESCRICAO,
		  t3.DT_OGNL_PGTO format yymmdd10.,
			t3.VL_PGTO,
			t4.TETO_MAX_DESC_PEC
      FROM WORK.sum_CLI t1 left join contatos t2 on (t1.cd_cli=t2.mci)
	  left join pag_ag_acl t3 on (t1.cd_cli=t3.NR_DOC_BNFC_MCI)
	  left join pec t4 on (t1.cd_cli=t4.cd_cli)
	  inner join igr.auxiliar_relatorios t5 on (t1.prefdep=t5.prefdep)

order by prefgerev, VLR_INAD15 desc;
QUIT;


data sum_cli_1;
set icred.sum_cli (where= (prefdep ne '4777'));
by prefgerev;
if first.prefgerev then seq_gerev=0;
seq_gerev+1;
if seq_gerev>1000 then prefgerev='';

run;

PROC SQL;
   CREATE TABLE sum_cli_2 AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
		  t1.prefgerev,
		  t5.prefsuper,
          t1.cart, 
          t1.pilar, 
          NR_DD_VCD_OPR, 
          saldo_opr, 
          VL_ATR_SCTR, 
          vl_dsp_pvs_crd, 
          fluxo_prj*-1 as fluxo_prj, 
          opr_inad90, 
          VLR_INAD90, 
          opr_inad15, 
          VLR_INAD15, 
          ec, 
          VLR_ec, 
          t1.ordem, 
          t1.data_contato, 
          qtd_opr,
		  T1.COD_SUB_RESULTADO_DESCRICAO,
		  t1.DT_OGNL_PGTO format yymmdd10.,
			t1.VL_PGTO,
			t1.TETO_MAX_DESC_PEC
      FROM sum_cli_1 t1
	  inner join igr.auxiliar_relatorios t5 on (t1.prefdep=t5.prefdep)

order by prefsuper, VLR_INAD15 desc;
QUIT;


data sum_cli_3 (DROP=seq_super) ;
set sum_cli_2 (where= (prefdep ne '4777'));
by prefsuper;
if first.prefsuper then seq_super=0;
seq_super+1;
if seq_super>1000 then prefsuper='';

run;

PROC SQL;
   CREATE TABLE WORK.saldo_total_cliente AS 
   SELECT distinct t1.CD_CLI, 
            (SUM(t1.VL_BASE_CLC_PVS)) AS saldo_total_cliente
      FROM pcld_vp.diaria_nova t1
      GROUP BY t1.CD_CLI;
QUIT;

PROC SQL;
	CREATE TABLE WORK.sum_cli_4 AS 
		SELECT distinct t1.CD_CLI, 
			t1.Prefdep, 
			t1.PrefGerev, 
			t1.PrefSuper, 
			t1.cart, 
			t1.pilar, 
			t1.NR_DD_VCD_OPR, 
			t1.saldo_opr, 
			t1.VL_ATR_SCTR, 
			t1.vl_dsp_pvs_crd, 
			t1.fluxo_prj, 
			t1.opr_inad90, 
			t1.VLR_INAD90, 
			t1.opr_inad15, 
			t1.VLR_INAD15, 
			t1.ec, 
			t1.VLR_ec, 
			t1.ordem, 
			t1.data_contato, 
			t1.qtd_opr, 
			t1.COD_SUB_RESULTADO_DESCRICAO, 
			t1.DT_OGNL_PGTO, 
			t1.VL_PGTO, 
			t1.TETO_MAX_DESC_PEC,
			t2.saldo_total_cliente,
			'' as gecor,
			. as liberacao,
		case when t4.prob_rec ='MÉDIA' then t4.prob_rec
			when t4.prob_rec ='ALTA' then t4.prob_rec
			when t4.prob_rec ='MÉDIACRÍTICA' then t4.prob_rec 
			ELSE '' END as arrasto
		FROM WORK.SUM_CLI_3 t1
			left join saldo_total_cliente t2 on (t1.cd_cli=t2.cd_cli)
			/*left join icred.BASE_FGTS_LIEBRACAO t3 on (t1.cd_cli=t3.mci)*/
			left join LISTA_QUALIF_GECEN_20160729 t4 on (t1.cd_cli=t4.cd_cli)
				WHERE T1.CD_CLI NE 0;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SUM_CLI_41 AS 
   SELECT t1.CD_CLI, 
          t1.Prefdep, 
          t1.PrefGerev, 
          t1.PrefSuper, 
          t1.cart, 
          t1.pilar, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.VL_ATR_SCTR, 
          t1.vl_dsp_pvs_crd, 
          t1.fluxo_prj, 
          t1.opr_inad90, 
          t1.VLR_INAD90, 
          t1.opr_inad15, 
          t1.VLR_INAD15, 
          t1.ec, 
          t1.VLR_ec, 
          t1.ordem, 
          t1.data_contato, 
          t1.qtd_opr, 
          t1.COD_SUB_RESULTADO_DESCRICAO, 
          t1.DT_OGNL_PGTO, 
          t1.VL_PGTO, 
          t1.TETO_MAX_DESC_PEC, 
          t1.saldo_total_cliente, 
          t1.gecor, 
          t1.liberacao, 
          t1.arrasto, 
          /* COUNT_of_CD_CLI */
            (COUNT(t1.CD_CLI)) AS COUNT_of_CD_CLI
      FROM WORK.SUM_CLI_4 t1
      GROUP BY t1.CD_CLI
	  having COUNT_of_CD_CLI=1
order by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SUM_CLI_42 AS 
   SELECT t1.CD_CLI, 
          t1.Prefdep, 
          t1.PrefGerev, 
          t1.PrefSuper, 
          t1.cart, 
          t1.pilar, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.VL_ATR_SCTR, 
          t1.vl_dsp_pvs_crd, 
          t1.fluxo_prj, 
          t1.opr_inad90, 
          t1.VLR_INAD90, 
          t1.opr_inad15, 
          t1.VLR_INAD15, 
          t1.ec, 
          t1.VLR_ec, 
          t1.ordem, 
          t1.data_contato, 
          t1.qtd_opr, 
          t1.COD_SUB_RESULTADO_DESCRICAO, 
          t1.DT_OGNL_PGTO, 
          t1.VL_PGTO, 
          t1.TETO_MAX_DESC_PEC, 
          t1.saldo_total_cliente, 
          t1.gecor, 
          t1.liberacao, 
          t1.arrasto, 
          /* COUNT_of_CD_CLI */
            (COUNT(t1.CD_CLI)) AS COUNT_of_CD_CLI
      FROM WORK.SUM_CLI_4 t1
      GROUP BY t1.CD_CLI
	  having COUNT_of_CD_CLI=2
order by COUNT_of_CD_CLI desc, cd_cli;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SUM_CLI_44 AS 
   SELECT t1.CD_CLI, 
          t1.Prefdep, 
          t1.PrefGerev, 
          t1.PrefSuper, 
          t1.cart, 
          t1.pilar, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.VL_ATR_SCTR, 
          t1.vl_dsp_pvs_crd, 
          t1.fluxo_prj, 
          t1.opr_inad90, 
          t1.VLR_INAD90, 
          t1.opr_inad15, 
          t1.VLR_INAD15, 
          t1.ec, 
          t1.VLR_ec, 
          t1.ordem, 
          t1.data_contato, 
          t1.qtd_opr, 
          t1.COD_SUB_RESULTADO_DESCRICAO, 
          t1.DT_OGNL_PGTO, 
          t1.VL_PGTO, 
          t1.TETO_MAX_DESC_PEC, 
          t1.saldo_total_cliente, 
          t1.gecor, 
          t1.liberacao, 
          t1.arrasto, 
          t1.COUNT_of_CD_CLI
      FROM WORK.SUM_CLI_42 t1, DB2MCI.CLIENTE t2
      WHERE (t1.CD_CLI = t2.COD AND t1.Prefdep = PUT (t2.COD_PREF_AGEN, Z4.))
order by 1;
QUIT;

DATA SUM_CLI_45 (drop=COUNT_of_CD_CLI);
SET SUM_CLI_44 SUM_CLI_41;
by CD_CLI;
RUN;

proc sql;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	create table seguro_protegido as SELECT * FROM CONNECTION TO DB2(
		select distinct cd_cli as cd_cli, 
		    digits (b.NR_CTR_SIS_OPR) as NR_UNCO_CTR_OPR,
			t1.NR_CTR_OPR,
			t1.VL_CPNT_CTR,
			T1.DT_LQDC_CPNT_CTR
		from db2cdc.CPNT_CTR_CDC t1 
			inner join db2cdc.CTR_CDC B ON (t1.NR_CTR_OPR=B.NR_CTR_OPR)
				where t1.CD_TIP_CPNT_CTR = 51 and DT_LQDC_CPNT_CTR > current date
				order by 1, 2);
quit;

PROC SQL;
   CREATE TABLE WORK.SEGURO_PROTEGIDO AS 
   SELECT t1.CD_CLI, 
          t1.NR_UNCO_CTR_OPR, 
          t1.NR_CTR_OPR, 
          t1.VL_CPNT_CTR
      FROM WORK.SEGURO_PROTEGIDO t1
           INNER JOIN MCI.FALECIDOS t2 ON (t1.CD_CLI = t2.cd_cli);
QUIT;

PROC SQL;
   CREATE TABLE WORK.mci_SEGURO_PROTEGIDO AS 
   SELECT distinct t1.CD_CLI
      FROM WORK.SEGURO_PROTEGIDO t1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SUM_CLI_46 AS 
   SELECT distinct t1.*,
   			'' as bonus_sp,
   		  ifn (t2.cd_cli=.,0,1) as credito_protegido
      FROM WORK.SUM_CLI_45 t1
           left JOIN mci_SEGURO_PROTEGIDO t2 ON (t1.CD_CLI = t2.cd_cli);
QUIT;


proc export
	data=sum_cli_46
	outfile="/dados/infor/producao/inad_15_90/base_clientes.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_15dias_cliente";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/base_clientes.txt' into table adp_15dias_cliente fields terminated by ';' lines terminated by '\n'";

x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_15dias_cliente(&rotina);";



%put &tabela;

PROC SQL;
   CREATE TABLE ICRED_INAD_EC_PRIORI_FLUXO AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.pilar, 
          t1.Prefdep, 
          t2.PrefGerev, 
          t2.PrefSuper, 
          t1.cart, 
          t1.CD_CLI, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.VL_ATR_SCTR, 
          t1.CD_RSCO_ATBD,
          t1.CD_RSCO_ATBD_PRJ,
          t1.DT_ALT_RSCO_OPR format yymmdd10., 
          t1.opr_inad90, 
          t1.opr_inad15, 
          t1.ec, 
          /*t1.ordem, */
          t1.vl_dsp_pvs_crd, 
          t1.fluxo_prj,
		  t1.gecor,
		  /*ifn (t3.NR_UNCO_CTR_OPR='',0,1)*/0 as arrasto,
		  /*ifn (t4.NR_UNCO_CTR_OPR='',0,1)*/0 as credito_protegido,
		  /*case when in_sudene = 'SUDENE' then 'Sudene'
		  when in_sudene <> 'SUDENE' and in_bovino contains 'BOVINO' then 'Bovinocultura'
		  when t5.NR_UNCO_CTR_OPR <> '' and in_sudene <> 'SUDENE' and in_bovino not contains 'BOVINO' then 'IN-13'
		  ELSE '' END*/'' AS MEDIDA_APL,
		  /*CASE WHEN indicativo_atnc = 'Gerag' THEN 'Gerag'
		  WHEN t5.NR_UNCO_CTR_OPR <> '' and indicativo_atnc <> 'Gerag' and t1.gecor = . THEN 'Agência'
		  WHEN t5.NR_UNCO_CTR_OPR <> '' and indicativo_atnc <> 'Gerag' and t1.gecor <> . THEN 'Gecor'
		  ELSE '' end*/'' as canal_abdg
      FROM ICRED.ICRED_INAD_EC_PRIORI_FLUXO t1
           INNER JOIN WORK.SUM_CLI_45 t2 ON (t1.CD_CLI = t2.CD_CLI)
/*left join icred.CAUSADORAS_ARRASTO_RENEG t3 on (t1.cd_cli=t3.cd_cli and t1.NR_UNCO_CTR_OPR=t3.NR_UNCO_CTR_OPR)*/
left join seguro_protegido t4 on (t1.CD_CLI=t4.CD_CLI and t1.NR_UNCO_CTR_OPR=t4.NR_UNCO_CTR_OPR)
/*left join agro.&tabela t5 on (t1.CD_CLI=t5.CD_CLI and t1.NR_UNCO_CTR_OPR=t5.NR_UNCO_CTR_OPR)*/
;
QUIT;

proc export
	data=icred_inad_ec_priori_fluxo
	outfile="/dados/infor/producao/inad_15_90/base_rpt_fim_sinergia_jr.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;




x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_15dias_operacao";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/base_rpt_fim_sinergia_jr.txt' into table adp_15dias_operacao fields terminated by ';' lines terminated by '\n'";


x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_15dias_operacao(&rotina);";



PROC SQL;
   CREATE TABLE renovacao_pj_14dias AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR,
   NR_EPRD_FNCD,
   NR_SCTR_OPR,
			t1.cd_prd,
			t1.cd_mdld,
			t1.Prefdep, 
			t1.cart, 
			t1.CD_CLI,
			t1.NR_DD_VCD_OPR, 
          t1.VL_BASE_CLC_PVS, 
          t1.CD_RSCO_ATBD, 
		  t1.vl_dsp_pvs_crd,
          t1.VL_TRND_PRJZ
     FROM ICRED.ICRED_PJ_FULL t1
WHERE t1.NR_DD_VCD_OPR BETWEEN 1 AND 14
and VL_BASE_CLC_PVS ne 0
and CD_EST_ESPL_CTR=0
group by 1, 2, 3, 4, 5, 6;
QUIT;

PROC SQL;
   CREATE TABLE WORK.sum_VLR_ATRS AS 
   SELECT t1.NR_UNCO_CTR_OPR, 
          sum (t1.VL_ATR_SCTR) as VL_ATR_SCTR
      FROM icred.VLR_ATRS t1
	  inner join renovacao_pj_14dias t2 on (t1.NR_UNCO_CTR_OPR=t2.NR_UNCO_CTR_OPR and  t1.NR_EPRD_FNCD=t2.NR_EPRD_FNCD and t1.NR_SCTR_OPR=t2.NR_SCTR_OPR)
group by 1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.sum_VLR_ATRS AS 
   SELECT t1.NR_UNCO_CTR_OPR, 
          sum (t1.VL_ATR_SCTR) as VL_ATR_SCTR
      FROM icred.VLR_ATRS t1
group by 1;
QUIT;

PROC SQL;
   CREATE TABLE renovacao_pj_14dias_opr AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR,
			t1.cd_prd,
			t1.cd_mdld,
			t1.Prefdep, 
			t1.cart, 
			t1.CD_CLI,
			max (t1.NR_DD_VCD_OPR) as NR_DD_VCD_OPR, 
          sum (t1.VL_BASE_CLC_PVS) as saldo_opr,           
          t1.CD_RSCO_ATBD, 
		  sum (t1.vl_dsp_pvs_crd) as vl_dsp_pvs_crd,
          sum (t1.VL_TRND_PRJZ) as fluxo_prj
      FROM renovacao_pj_14dias t1
      


WHERE t1.NR_DD_VCD_OPR BETWEEN 1 AND 14
and VL_BASE_CLC_PVS ne 0
group by 1, 2, 3, 4, 5, 6;
QUIT;

PROC SQL;
   CREATE TABLE icred.renovacao_pj_14dias AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR,
			t1.cd_prd,
			t1.cd_mdld,
			t1.Prefdep, 
			t1.cart, 
			t1.CD_CLI,
			t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          ifn (t3.VL_ATR_SCTR in (., 0) or t3.VL_ATR_SCTR>t1.saldo_opr ,t1.saldo_opr, t3.VL_ATR_SCTR) as VL_ATR_SCTR, 
          t1.CD_RSCO_ATBD, 
		  t1.vl_dsp_pvs_crd,
          t1.fluxo_prj
      FROM renovacao_pj_14dias_opr t1
      
left join sum_VLR_ATRS t3 ON (t1.NR_UNCO_CTR_OPR = t3.NR_UNCO_CTR_OPR)

WHERE t1.NR_DD_VCD_OPR BETWEEN 1 AND 14
;
QUIT;

PROC SQL;
   CREATE TABLE sum_cli_pj14 AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
		  t3.prefgerev,
          t1.cart,
          max (t1.NR_DD_VCD_OPR) as NR_DD_VCD_OPR_NOVO, 
          sum (t1.saldo_opr) as saldo_opr, 
          sum (t1.VL_ATR_SCTR) as VL_ATR_SCTR, 
          sum (t1.vl_dsp_pvs_crd) as vl_dsp_pvs_crd, 
          sum (t1.fluxo_prj) as fluxo_prj, 
          count (distinct t1.NR_UNCO_CTR_OPR) as qtd_opr
      FROM icred.renovacao_pj_14dias t1 
	  inner join igr.auxiliar_relatorios t3 on (t1.prefdep=t3.prefdep)
group by 2, 4, 1
order by prefgerev, saldo_opr desc;
QUIT;

PROC SQL;
   CREATE TABLE icred.sum_cli_pj14 AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
		  t1.prefgerev,
          t1.cart,
          NR_DD_VCD_OPR_NOVO, 
          saldo_opr, 
          VL_ATR_SCTR, 
          vl_dsp_pvs_crd, 
          fluxo_prj, 
          qtd_opr,
		  t2.data_contato format yymmdd10.,
		  T2.COD_SUB_RESULTADO_DESCRICAO
      FROM sum_cli_pj14 t1 left join contatos t2 on (t1.cd_cli=t2.mci)
	  

order by prefgerev, saldo_opr desc;
QUIT;

data sum_cli_pj14_1;
set icred.sum_cli_pj14 (where= (prefdep ne '4777'));
by prefgerev;
if first.prefgerev then seq_gerev=0;
seq_gerev+1;
if seq_gerev>1000 then prefgerev='';

run;

PROC SQL;
   CREATE TABLE sum_cli_pj14_2 AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
		  t1.prefgerev,
		  t3.prefsuper,
          t1.cart,
          NR_DD_VCD_OPR_NOVO, 
          saldo_opr, 
          VL_ATR_SCTR, 
          vl_dsp_pvs_crd, 
          fluxo_prj, 
          qtd_opr,
		  t1.data_contato,
		  T1.COD_SUB_RESULTADO_DESCRICAO
      FROM sum_cli_pj14_1 t1
	  inner join igr.auxiliar_relatorios t3 on (t1.prefdep=t3.prefdep)

order by prefsuper, saldo_opr desc;
QUIT;

data sum_cli_pj14_3;
set sum_cli_pj14_2 (where= (prefdep ne '4777'));
by prefsuper;
if first.prefsuper then seq_super=0;
seq_super+1;
if seq_super>1000 then prefsuper='';

run;

PROC SQL;
   CREATE TABLE sum_cli_pj14_4 AS 
   SELECT distinct t1.CD_CLI, 
          t1.Prefdep, 
		  t1.prefgerev,
		  t1.prefsuper,
          t1.cart,
          NR_DD_VCD_OPR_NOVO, 
          saldo_opr, 
          VL_ATR_SCTR, 
          vl_dsp_pvs_crd, 
          fluxo_prj, 
          qtd_opr,
		  t1.data_contato,
		  T1.COD_SUB_RESULTADO_DESCRICAO,
		  t3.saldo_total_cliente,
		  t2.VL_PGTO
      FROM sum_cli_pj14_3 t1
	  left join pag_ag_acl t2 on (t1.cd_cli=t2.NR_DOC_BNFC_MCI)
	  left join saldo_total_cliente t3 on (t1.cd_cli=t3.cd_cli)
;
QUIT;

/*data sum_cli_pj14_4 (drop= seq_super seq_gerev);
set sum_cli_pj14_3;
run;*/


PROC SQL;
   CREATE TABLE WORK.RENOVACAO_PJ_14DIAS AS 
   SELECT t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.Prefdep, 
		  t2.PrefGerev, 
          t2.PrefSuper, 
          t1.cart, 
          t1.CD_CLI, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.VL_ATR_SCTR, 
          t1.CD_RSCO_ATBD, 
          t1.vl_dsp_pvs_crd, 
          t1.fluxo_prj
      FROM ICRED.RENOVACAO_PJ_14DIAS t1
 inner join sum_cli_pj14_4 t2 on (t1.cd_cli=t2.cd_cli);
QUIT;


proc export
	data=renovacao_pj_14dias
	outfile="/dados/infor/producao/inad_15_90/renovacao_pj_14dias.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;




x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_operacoes_pj";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/renovacao_pj_14dias.txt' into table adp_operacoes_pj fields terminated by ';' lines terminated by '\n'";


x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_operacoes_pj(&rotina);";



proc export
	data=sum_cli_pj14_4
	outfile="/dados/infor/producao/inad_15_90/sum_cli_pj14.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;




x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_cliente_pj";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/sum_cli_pj14.txt' into table adp_cliente_pj fields terminated by ';' lines terminated by '\n'";


x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_cliente_pj(&rotina);";



/*******relatorio icred15/90**********/
/*******relatorio icred15/90**********/
/*******relatorio icred15/90**********/
/*******relatorio icred15/90**********/
/*******relatorio icred15/90**********/


PROC SQL;
   CREATE TABLE WORK.cliente_rel AS 
   SELECT t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
		  t1.pilar,
		  ifn (data_contato=.,0,1) as ctt,
		  t1.opr_inad90,
          ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Alta'), 1,0) as expc_alta,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Baixa'), 1,0) as expc_baixa,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Regularizado'), 1,0) as regularizado,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Sem'), 1,0) as sem_presp,
ifn ((calculated expc_alta+calculated expc_baixa+calculated regularizado+calculated sem_presp=0) and calculated ctt ne 0,1,0) as outros,
saldo_opr,
ifn (calculated expc_alta=1,saldo_opr,0) as vlr_expc_alta,
ifn (calculated expc_baixa=1,saldo_opr,0) as vlr_expc_baixa,
ifn (calculated regularizado=1,saldo_opr,0) as vlr_regularizado,
ifn (calculated sem_presp=1,saldo_opr,0) as vlr_sem_presp,
ifn (calculated outros=1,saldo_opr,0) as vlr_outros
      FROM ICRED.SUM_CLI t1
where /*data_contato ne .
and*/ t1.opr_inad15=1
order by 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_cart_pf AS 
   SELECT t1.Prefdep, 
          t1.cart, 
		  t1.pilar,
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.opr_inad90) as opr_inad90, 
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.CLIENTE_REL t1
	  where t1.pilar=1
group by 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_cart_pj AS 
   SELECT t1.Prefdep, 
          t1.cart, 
		  t1.pilar,
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.opr_inad90) as opr_inad90, 
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.CLIENTE_REL t1
	  where t1.pilar=2
group by 1, 2, 3;
QUIT;

proc sql;
create table carts as
select prefdep, cart
from fim_cart_pj
union
select prefdep, cart
from fim_cart_pf;
quit;

proc sql;
	create table fim_cart_tt as 
		select t0.prefdep,
			t0.cart,
			ifn (t1.qtd_cli=.,0,t1.qtd_cli)+ifn (t2.qtd_cli=.,0,t2.qtd_cli) as qtd_cli, 
			t1.qtd_cli as qtd_cli_pf,
			t1.ctt, 
			t1.expc_alta, 
			t1.expc_baixa, 
			t1.outros, 
			t1.regularizado, 
			t1.sem_presp, 
			t1.saldo_opr, 
			t1.vlr_expc_alta, 
			t1.vlr_expc_baixa, 
			t1.vlr_regularizado, 
			t1.vlr_sem_presp, 
			t1.vlr_outros,
			t2.qtd_cli as qtd_cli_pj,
			t2.ctt as ctt_pj, 
			t2.expc_alta as expc_alta_pj, 
			t2.expc_baixa as expc_baixa_pj, 
			t2.outros as outros_pj, 
			t2.regularizado as regularizado_pj, 
			t2.sem_presp as sem_presp_pj, 
			t2.saldo_opr as saldo_opr_pj, 
			t2.vlr_expc_alta as vlr_expc_alta_pj, 
			t2.vlr_expc_baixa as vlr_expc_baixa_pj, 
			t2.vlr_regularizado as vlr_regularizado_pj, 
			t2.vlr_sem_presp as vlr_sem_presp_pj, 
			t2.vlr_outros as vlr_outros_pj
		from carts t0
			left join fim_cart_pf t1 on (t0.prefdep=t1.prefdep and t0.cart=t1.cart)
			left join fim_cart_pj t2 on (t0.prefdep=t2.prefdep and t0.cart=t2.cart);
quit;
%zerarmissingtabela (work.fim_cart_tt);

PROC SQL;
   CREATE TABLE WORK.fim_ag AS 
   SELECT t1.Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_cart_tt t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_grv AS 
   SELECT prefgerev as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE WORK.fim_sup AS 
   SELECT prefsuper as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_uen AS 
   SELECT prefdir as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_vp AS 
   SELECT prefvice as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


data base;
	set fim_cart_tt fim_ag fim_grv fim_sup fim_uen fim_vp;
	by prefdep;
	percent_ctt=(ctt+ctt_pj)/qtd_cli*100;
	percent_ctt_pf=(ctt)/qtd_cli_pf*100;
	percent_ctt_pj=(ctt_pj)/qtd_cli_pj*100;
	ctt_tt=(ctt+ctt_pj);
run;


data base_1 (drop= ts estilo governo codsitdep acordoreduzido en PrefAgenc uor);
	merge igr.AUXILIAR_RELATORIOS base;
	by prefdep;

	if qtd_cli ne .;
run;


data base_rpt_fim;
	set base_1;

	if cart ne 0 then
		do;
			prefpai=prefdep;
			tipodep='89';
			NivelDep='0';
		end;
run;
%zerarmissingtabela (work.base_rpt_fim);

PROC EXPORT 
DATA=base_rpt_fim OUTFILE="/dados/infor/producao/inad_15_90/contatos_icred15.txt" 
	DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate contatos_icred15";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/inad_15_90/contatos_icred15.txt' INTO TABLE contatos_icred15 FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="update posicoes set posicao = if(Weekday(date(now())) = 0 ,date(date(now())-3),date(date(now())-1)) where xml = 'contatos_icred15'";







/*******relatorio pj 1-14*******/
/*******relatorio pj 1-14*******/
/*******relatorio pj 1-14*******/
/*******relatorio pj 1-14*******/
/*******relatorio pj 1-14*******/


PROC SQL;
   CREATE TABLE WORK.cliente_rel_pj14 AS 
   SELECT t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI,
		  ifn(data_contato=.,0,1) as ctt,
          ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Alta'), 1,0) as expc_alta,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Baixa'), 1,0) as expc_baixa,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Regularizado'), 1,0) as regularizado,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Sem'), 1,0) as sem_presp,
ifn ((calculated expc_alta+calculated expc_baixa+calculated regularizado+calculated sem_presp=0) and calculated ctt ne 0,1,0) as outros,
saldo_opr,
ifn (calculated expc_alta=1,saldo_opr,0) as vlr_expc_alta,
ifn (calculated expc_baixa=1,saldo_opr,0) as vlr_expc_baixa,
ifn (calculated regularizado=1,saldo_opr,0) as vlr_regularizado,
ifn (calculated sem_presp=1,saldo_opr,0) as vlr_sem_presp,
ifn (calculated outros=1,saldo_opr,0) as vlr_outros
      FROM ICRED.SUM_CLI_pj14 t1
/*where data_contato ne .*/

order by 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_cart_pj14 AS 
   SELECT t1.Prefdep, 
          t1.cart, 
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.CLIENTE_REL_pj14 t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_ag_pj14 AS 
   SELECT t1.Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_cart_pj14 t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_grv_pj14 AS 
   SELECT prefgerev as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pj14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE WORK.fim_sup_pj14 AS 
   SELECT prefsuper as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pj14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_uen_pj14 AS 
   SELECT prefdir as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pj14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_vp_pj14 AS 
   SELECT prefvice as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pj14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


data base_pj14;
	set fim_cart_pj14 fim_ag_pj14 fim_grv_pj14 fim_sup_pj14 fim_uen_pj14 fim_vp_pj14;
	by prefdep;
	percent_ctt=ctt/qtd_cli*100;
run;


data base_1_pj14 (drop= ts estilo governo codsitdep acordoreduzido en PrefAgenc uor);
	merge igr.AUXILIAR_RELATORIOS base_pj14;
	by prefdep;

	if qtd_cli ne .;
run;


data base_rpt_fim_pj14;
	set base_1_pj14;

	if cart ne 0 then
		do;
			prefpai=prefdep;
			tipodep='89';
			NivelDep='0';
		end;
run;


PROC EXPORT 
DATA=base_rpt_fim_pj14 OUTFILE="/dados/infor/producao/inad_15_90/contatos_pj14.txt" 
	DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate contatos_pj14";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/inad_15_90/contatos_pj14.txt' INTO TABLE contatos_pj14 FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="update posicoes set posicao = if(Weekday(date(now())) = 0 ,date(date(now())-3),date(date(now())-1)) where xml = 'contatos_pj14'";




/************CONTATOS PF 4-14*******************/
/************CONTATOS PF 4-14*******************/
/************CONTATOS PF 4-14*******************/
/************CONTATOS PF 4-14*******************/
/************CONTATOS PF 4-14*******************/
libname inad_e 	"/dados/infor/producao/Inad4_14/dados_entrada";

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
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-15
		and t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  or t1.CD_RSTD_INRO = 2)
group by 1;
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
   CREATE TABLE QUERY_FOR_INRO_CLI_1 AS 
   SELECT t1.CD_CLI as mci, 
          t1.TS_INRO_CLI format datetime25.6 as timestamp_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO
      FROM DB2BIC.AUX_INRO_CLI_Ant t1
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-15
		and t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  or t1.CD_RSTD_INRO = 2)
group by 1;
QUIT;

proc sql;
create table max_1 as 
select distinct mci,
max (timestamp_contato) format datetime25.6 as timestamp_contato
from WORK.QUERY_FOR_INRO_CLI_1
group by 1;
quit;

proc sql;
create table contatos_unicos_1 as 
select distinct t1.mci,
 datepart (t1.timestamp_contato) format yymmdd10. as data_contato,
          t2.CD_RSTD_INRO, 
          t2.CD_SUB_RSTD_INRO, 
          t2.CD_ASNT_INRO, 
          t2.CD_SUB_ASNT_INRO
from max_1 t1
inner join QUERY_FOR_INRO_CLI_1 t2 on (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
where (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
group by 1, 2;
quit;

proc sql;
create table todos as 
select t1.* from 
contatos_unicos t1
union 
select t2.*
from contatos_unicos_1 t2;
quit;


PROC SQL;
   CREATE TABLE WORK.contatos AS 
   SELECT t1.mci, 
          t1.data_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t2.COD_SUB_RESULTADO_DESCRIcao
      FROM WORK.todos t1, WORK.SUB_RSTD_INRO t2
      WHERE (t1.CD_RSTD_INRO = t2.cod_resultado AND t1.CD_SUB_RSTD_INRO = t2.cod_sub_resultado);
QUIT;


PROC SQL;
   CREATE TABLE WORK.ICRED_4_14_cli AS 
   SELECT t1.CD_CLI, 
          t1.Prefdep, 
          t1.cart, 
          count (distinct t1.NR_UNCO_CTR_OPR) as qtd_opr, 
          sum (t1.VL_ATR_SCTR) as VL_ATR_SCTR, 
          sum (t1.VL_DSP_PVS_CRD) as VL_DSP_PVS_CRD, 
          sum (t1.VL_BASE_CLC_PVS) as VL_BASE_CLC_PVS, 
          max (t1.NR_DD_VCD_OPR) as NR_DD_VCD_OPR, 
          min (t1.primeiro_atraso) format yymmdd10. as primeiro_atraso
      FROM INAD_E.ICRED_4_14_PF_VLR_ATRS t1
group by 2, 3, 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.ICRED_4_14_CLI_fim AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.Prefdep, 
          t1.cart, 
          t1.qtd_opr, 
          t1.VL_ATR_SCTR, 
          t1.VL_DSP_PVS_CRD, 
          t1.VL_BASE_CLC_PVS, 
          t1.NR_DD_VCD_OPR, 
          t1.primeiro_atraso, 
          t2.aplicacao, 
          t3.proventista, 
          t3.mais_de_uma_conta
      FROM WORK.ICRED_4_14_CLI t1
           LEFT JOIN INAD_E.MCI_INVEST_FINAL t2 ON (t1.CD_CLI = t2.mci)
           LEFT JOIN INAD_E.CADASTRO t3 ON (t1.CD_CLI = t3.mci);
QUIT;
%zerarmissingtabela (work.ICRED_4_14_CLI_fim);

PROC SQL;
   CREATE TABLE WORK.saldo_total_cliente AS 
   SELECT distinct t1.CD_CLI, 
            (SUM(t1.VL_BASE_CLC_PVS)) AS saldo_total_cliente
      FROM ICRED.ICRED_ENC t1
      GROUP BY t1.CD_CLI;
QUIT;

PROC SQL;
   CREATE TABLE WORK.ICRED_4_14_CLI_FIM_ctt AS 
   SELECT t1.CD_CLI, 
          t1.Prefdep, 
          t1.cart, 
          t1.qtd_opr, 
          t1.VL_ATR_SCTR, 
          t1.VL_DSP_PVS_CRD, 
          t1.VL_BASE_CLC_PVS, 
          t1.NR_DD_VCD_OPR, 
          t1.primeiro_atraso, 
          t1.aplicacao, 
          t1.proventista, 
          t1.mais_de_uma_conta, 
          t2.data_contato, 
          t2.COD_SUB_RESULTADO_DESCRIcao,
		  t4.saldo_total_cliente
      FROM WORK.ICRED_4_14_CLI_FIM t1
           LEFT JOIN WORK.CONTATOS t2 ON (t1.CD_CLI = t2.mci)
		   left join (select mci from bcn.bcn_gov union select mci from bcn.bcn_pj) t3 on (t1.cd_cli=t3.mci)
		   left join saldo_total_cliente t4 on (t1.cd_cli=t4.cd_cli)
where t1.cart <5000 or t1.cart >7000 and t3.mci is missing;
QUIT;

proc sql;
	create table ICRED_4_14_CLI_FIM_ctt_1 as 
		select t1.CD_CLI, 
			t1.Prefdep, 
			t2.prefgerev,
			t1.cart, 
			t1.qtd_opr, 
			t1.VL_ATR_SCTR, 
			t1.VL_DSP_PVS_CRD, 
			t1.VL_BASE_CLC_PVS, 
			t1.NR_DD_VCD_OPR, 
			t1.primeiro_atraso, 
			t1.aplicacao, 
			t1.proventista, 
			t1.mais_de_uma_conta, 
			t1.data_contato, 
			t1.COD_SUB_RESULTADO_DESCRIcao, 
			t1.saldo_total_cliente
		from ICRED_4_14_CLI_FIM_ctt t1 
			inner join igr.auxiliar_relatorios t2 on (t1.prefdep=t2.prefdep)
				order by t2.prefgerev, t1.VL_BASE_CLC_PVS desc;
quit;


data ICRED_4_14_CLI_FIM_ctt_2;
set ICRED_4_14_CLI_FIM_ctt_1 (where= (prefdep ne '4777'));
by prefgerev;
if first.prefgerev then seq_gerev=0;
seq_gerev+1;
if seq_gerev>1000 then prefgerev='';

run;

proc sql;
	create table ICRED_4_14_CLI_FIM_ctt_3 as 
		select t1.CD_CLI, 
			t1.Prefdep, 
			t1.prefgerev,
			t2.prefsuper,
			t1.cart, 
			t1.qtd_opr, 
			t1.VL_ATR_SCTR, 
			t1.VL_DSP_PVS_CRD, 
			t1.VL_BASE_CLC_PVS, 
			t1.NR_DD_VCD_OPR, 
			t1.primeiro_atraso, 
			t1.aplicacao, 
			t1.proventista, 
			t1.mais_de_uma_conta, 
			t1.data_contato, 
			t1.COD_SUB_RESULTADO_DESCRIcao, 
			t1.saldo_total_cliente
		from ICRED_4_14_CLI_FIM_ctt_2 t1 
			inner join igr.auxiliar_relatorios t2 on (t1.prefdep=t2.prefdep)
				order by t2.prefsuper, t1.VL_BASE_CLC_PVS desc;
quit;

data ICRED_4_14_CLI_FIM_ctt_4 (drop=seq_super seq_gerev);
set ICRED_4_14_CLI_FIM_ctt_3 (where= (prefdep ne '4777'));
by prefsuper;
if first.prefsuper then seq_super=0;
seq_super+1;
if seq_super>1000 then prefsuper='';

run;

proc sql;
create table ICRED_4_14_CLI_FIM_ctt_5 as 
select distinct t1.*,
. as liberacao
from ICRED_4_14_CLI_FIM_ctt_4 t1
/*left join icred.BASE_FGTS_LIEBRACAO t2 on (t1.cd_cli=t2.mci)*/;
quit;


proc export 
	data=ICRED_4_14_CLI_FIM_ctt_5 
	outfile="/dados/infor/producao/Inad4_14/dados_saida/Inad_4_14.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="truncate adp_414_cliente" ;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="load data low_priority local infile '/dados/infor/producao/Inad4_14/dados_saida/Inad_4_14.txt' into table adp_414_cliente fields terminated by ';' lines terminated by '\n'";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_wagner upd_gecen -pwagner --execute="call adp_414_cliente(&rotina)" ;


PROC SQL;
   CREATE TABLE WORK.cliente_rel_pf14 AS 
   SELECT t1.prefdep as Prefdep, 
          t1.cart as cart, 
          t1.cd_cli as CD_CLI,
          ifn(data_contato=.,0,1) as ctt,
          ifn (t1.COD_SUB_RESULTADO_DESCRIcao contains ('Alta'), 1,0) as expc_alta,
ifn (t1.COD_SUB_RESULTADO_DESCRIcao contains ('Baixa'), 1,0) as expc_baixa,
ifn (t1.COD_SUB_RESULTADO_DESCRIcao contains ('Regularizado'), 1,0) as regularizado,
ifn (t1.COD_SUB_RESULTADO_DESCRIcao contains ('Sem'), 1,0) as sem_presp,
ifn ((calculated expc_alta+calculated expc_baixa+calculated regularizado+calculated sem_presp=0) and calculated ctt ne 0,1,0) as outros,
VL_BASE_CLC_PVS as saldo_total,
ifn (calculated expc_alta=1,saldo_total,0) as vlr_expc_alta,
ifn (calculated expc_baixa=1,saldo_total,0) as vlr_expc_baixa,
ifn (calculated regularizado=1,saldo_total,0) as vlr_regularizado,
ifn (calculated sem_presp=1,saldo_total,0) as vlr_sem_presp,
ifn (calculated outros=1,saldo_total,0) as vlr_outros
      FROM ICRED_4_14_CLI_FIM_ctt t1


order by 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_cart_pf14 AS 
   SELECT t1.prefdep,
          t1.cart, 
          count (distinct t1.CD_CLI) as qtd_cli, 
          sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_total) as saldo_total,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.CLIENTE_REL_pf14 t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_ag_pf14 AS 
   SELECT t1.Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
          sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_total) as saldo_total,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_cart_pf14 t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_grv_pf14 AS 
   SELECT prefgerev as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
          sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_total) as saldo_total,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pf14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE WORK.fim_sup_pf14 AS 
   SELECT prefsuper as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
          sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_total) as saldo_total,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pf14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_uen_pf14 AS 
   SELECT prefdir as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
          sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_total) as saldo_total,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pf14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_vp_pf14 AS 
   SELECT prefvice as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
          sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_total) as saldo_total,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_ag_pf14 t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


data base_pf14;
	set fim_cart_pf14 fim_ag_pf14 fim_grv_pf14 fim_sup_pf14 fim_uen_pf14 fim_vp_pf14;
	by prefdep;
	percent_ctt=ctt/qtd_cli*100;
run;


data base_1_pf14 (drop= ts estilo governo codsitdep acordoreduzido en PrefAgenc uor);
	merge igr.AUXILIAR_RELATORIOS base_pf14;
	by prefdep;

	if qtd_cli ne .;
run;


data base_rpt_fim_pf14;
	set base_1_pf14;

	if cart ne 0 then
		do;
			prefpai=prefdep;
			tipodep='89';
			NivelDep='0';
		end;
run;


PROC EXPORT 
DATA=base_rpt_fim_pf14 OUTFILE="/dados/infor/producao/inad_15_90/contatos_pf14.txt" 
	DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate contatos_pf14";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/inad_15_90/contatos_pf14.txt' INTO TABLE contatos_pf14 FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="update posicoes set posicao = if(Weekday(date(now())) = 0 ,date(date(now())-3),date(date(now())-1)) where xml = 'contatos_pf14'";




/********100 Maiores********/
/********100 Maiores********/
/********100 Maiores********/
/********100 Maiores********/
/********100 Maiores********/


PROC SQL;
   CREATE TABLE WORK.cli_MAIORES AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.Prefdep, 
          t1.PrefGerev, 
          t1.PrefSuper, 
		  t1.Prefdir,
          t1.cart, 
          t1.pilar, 
          NR_DD_VCD_OPR, 
          saldo_opr, 
          vlr_atrs, 
          fluxo_pcld, 
          fluxo_prj, 
          t1.inad90, 
		  ifn (inad90=1,saldo_opr,0) as impacto90,
          t1.inad15, 
		  ifn (inad15=1,saldo_opr,0) as impacto15,
          t1.ec, 
		  ifn (ec=1,saldo_opr,0) as impactoec,
          t1.NR_UNCO_CTR_OPR
      FROM icred.OPR_MAIORES_2 t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.cli_MAIORES_1 AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.Prefdep, 
          t1.PrefGerev, 
          t1.PrefSuper, 
		  t1.Prefdir,
          t1.cart, 
          t1.pilar, 
          max (t1.NR_DD_VCD_OPR) as NR_DD_VCD_OPR, 
          sum (t1.saldo_opr) as saldo_opr, 
          sum (t1.vlr_atrs) as vlr_atrs, 
          sum (t1.fluxo_pcld) as fluxo_pcld, 
          sum (t1.fluxo_prj) as fluxo_prj, 
          max(t1.inad90) as inad90, 
		  sum (impacto90) as impacto90,
          max (t1.inad15) as inad15, 
		  sum (impacto15) as impacto15,
          sum (t1.ec) as ec, 
		  sum (impactoec) as impactoec,
          count (distinct t1.NR_UNCO_CTR_OPR) as qtd_opr
      FROM WORK.cli_MAIORES t1
group by 5, 4, 3, 2, 6, 1;
QUIT;




/*****CONTATOS********/
/*****CONTATOS********/
/*****CONTATOS********/
/*****CONTATOS********/

LIBNAME DB2BIC db2 AUTHDOMAIN=DB2SGCEN schema=DB2BIC database=BDB2P04;

PROC SQL;
   CREATE TABLE WORK.SUB_RSTD_INRO AS 
   SELECT t1.CD_RSTD_INRO AS cod_resultado, 
          t1.CD_SUB_RSTD_INRO AS cod_sub_resultado, 
          t1.TX_SUB_RSTD_INRO AS COD_SUB_RESULTADO_DESCRICAO, 
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
		and ((t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42)
		or (t1.CD_ASNT_INRO = 6 AND t1.CD_SUB_ASNT_INRO = 54)
		or (t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 60))
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  )
group by 1;
QUIT;


PROC SQL;
   CREATE TABLE QUERY_FOR_INRO_CLI_1 AS 
   SELECT t1.CD_CLI as mci, 
          t1.TS_INRO_CLI format datetime25.6 as timestamp_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO
      FROM DB2BIC.AUX_INRO_CLI_Ant t1
		WHERE datepart (TS_INRO_CLI) > &DiaUtil_D0-30
		and ((t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42)
		or (t1.CD_ASNT_INRO = 6 AND t1.CD_SUB_ASNT_INRO = 54))
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415)
	  )
group by 1;
QUIT;


proc sql;
create table todos as 
select t1.* from 
QUERY_FOR_INRO_CLI_1 t1
union 
select t2.*
from QUERY_FOR_INRO_CLI t2;
quit;

proc sql;
create table max_1 as 
select distinct mci,
max (timestamp_contato) format datetime25.6 as timestamp_contato
from WORK.todos
group by 1;
quit;

LIBNAME DB2SGCEN DB2 AUTHDOMAIN=DB2SGCEN schema=DB2SGCEN database=BDB2P04;

PROC SQL;
    DROP TABLE DB2SGCEN.P_contatos_unicos_1 ;

    CREATE TABLE    DB2SGCEN.P_contatos_unicos_1     AS
    SELECT            t1.MCI FORMAT=9., 
          MIN (t1.timestamp_contato) FORMAT=datetime25.6 AS timestamp_contato
    FROM            max_1 T1
    ;
QUIT;

PROC SQL;CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
   CREATE TABLE WORK.INRO_HMNO_CLI AS SELECT * FROM CONNECTION TO DB2(
   SELECT t1.CD_CLI, 
          t1.TS_INRO_CLI, 
          t1.CD_ASNT_INRO, 
          t1.CD_SUB_ASNT_INRO, 
          t1.CD_USU_RSP_ATDT, 
          t1.TX_OBS_ATDT_CLI, 
          t1.CD_FMA_CTT
      FROM DB2BIC.INRO_HMNO_CLI t1
	  INNER JOIN DB2SGCEN.P_contatos_unicos_1 T2 ON (T1.CD_CLI=T2.MCI)
where t1.TS_INRO_CLI>=T2.timestamp_contato);
DROP TABLE DB2SGCEN.P_contatos_unicos_1 ;
QUIT;

proc sql;
create table contatos_unicos_1 as 
select distinct t1.mci,
 datepart (t1.timestamp_contato) format yymmdd10. as data_contato,
          t2.CD_RSTD_INRO, 
          t2.CD_SUB_RSTD_INRO, 
          t2.CD_ASNT_INRO, 
          t2.CD_SUB_ASNT_INRO
from max_1 t1
inner join todos t2 on (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
where (t1.mci=t2.mci and t1.timestamp_contato=t2.timestamp_contato)
group by 1, 2;
quit;





PROC SQL;
   CREATE TABLE WORK.contatos AS 
   SELECT t1.mci, 
          t1.data_contato, 
          t1.CD_RSTD_INRO, 
          t1.CD_SUB_RSTD_INRO, 
          t2.COD_SUB_RESULTADO_DESCRICAO
      FROM WORK.contatos_unicos_1 t1, WORK.SUB_RSTD_INRO t2
      WHERE (t1.CD_RSTD_INRO = t2.cod_resultado AND t1.CD_SUB_RSTD_INRO = t2.cod_sub_resultado);
QUIT;

PROC SQL;
   CREATE TABLE WORK.observacao AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.TS_INRO_CLI format E8601DT19., 
          t1.TX_OBS_ATDT_CLI
      FROM WORK.INRO_HMNO_CLI t1
           INNER JOIN WORK.MAX_1 t2 ON (t1.CD_CLI = t2.mci AND t1.TS_INRO_CLI=T2.timestamp_contato);
QUIT;

/*proc export
	data=observacao
	outfile="/dados/infor/producao/inad_15_90/adp_maiores_pcld_prj_observacao.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_maiores_pcld_prj_observacao";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/adp_maiores_pcld_prj_observacao.txt' into table adp_maiores_pcld_prj_observacao fields terminated by ';' lines terminated by '\n'";
*/


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
   CREATE TABLE pec AS 
   SELECT t1.CD_CLI, 
          max (t1.TETO_MAX_DESC_PEC) as TETO_MAX_DESC_PEC
      FROM LISTA_QUALIF_GECEN_20160729 t1
group by 1;
QUIT;

PROC SQL;
	create table pag_ag_ as 
		SELECT t1.DT_OGNL_PGTO,
			t1.VL_PGTO,
			t1.NR_DOC_BNFC_MCI
		FROM DB2PGT.MVT_PGTO t1
			WHERE t1.DT_OGNL_PGTO BETWEEN &DiaUtil_D0+1 AND &DiaUtil_D0+15
				and NR_DOC_BNFC_MCI not in (., 0)
				and CD_EST_PGTO='PEN'	
				AND CD_PRD=127;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CLI_MAIORES_2 AS 
   SELECT DISTINCT t1.CD_CLI, 
          t1.Prefdep, 
          t1.PrefGerev, 
          t1.PrefSuper, 
		  t1.Prefdir,
          t1.cart, 
          t1.pilar, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.vlr_atrs, 
          t1.fluxo_pcld, 
          t1.fluxo_prj, 
          t1.inad90, 
          t1.impacto90, 
          t1.inad15, 
          t1.impacto15, 
          t1.ec, 
          t1.impactoec, 
          t2.data_contato format yymmdd10., 
          t1.qtd_opr, 
          t2.COD_SUB_RESULTADO_DESCRICAO, 
          min(t3.DT_OGNL_PGTO) format yymmdd10. as DT_OGNL_PGTO, 
          sum (t3.VL_PGTO) as VL_PGTO, 
          t4.TETO_MAX_DESC_PEC,
		  t5.TX_OBS_ATDT_CLI
      FROM WORK.CLI_MAIORES_1 t1
           LEFT JOIN WORK.PEC t4 ON (t1.CD_CLI = t4.CD_CLI)
           LEFT JOIN WORK.CONTATOS t2 ON (t1.CD_CLI = t2.mci)
           LEFT JOIN WORK.PAG_AG_ t3 ON (t1.CD_CLI = t3.NR_DOC_BNFC_MCI)
		   LEFT JOIN WORK.observacao t5 ON (t1.CD_CLI = t5.cd_cli)
group by 1;
QUIT;

proc export
	data=CLI_MAIORES_2
	outfile="/dados/infor/producao/inad_15_90/adp_maiores_pcld_prj_cliente.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_maiores_pcld_prj_cliente";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/adp_maiores_pcld_prj_cliente.txt' into table adp_maiores_pcld_prj_cliente fields terminated by ';' lines terminated by '\n'";



proc export
	data=icred.OPR_MAIORES_2
	outfile="/dados/infor/producao/inad_15_90/adp_maiores_pcld_prj_opr.txt" dbms=dlm replace;
	putnames=no;
	delimiter=';';
run;

x cd /dados/infor/utilitarios; 
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="truncate adp_maiores_pcld_prj_opr";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/inad_15_90/adp_maiores_pcld_prj_opr.txt' into table adp_maiores_pcld_prj_opr fields terminated by ';' lines terminated by '\n'";



x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_maiores_pcld_prj_opr(&rotina);";

x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_maiores_pcld_prj_cliente(&rotina);";

x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo upd_gecen -p33262308 --execute="call adp_maiores_pcld_prj_observacao();";



PROC SQL;
   CREATE TABLE WORK.cliente_rel AS 
   SELECT t1.prefdir, t1.prefsuper, t1.prefgerev, t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
		  ifn (data_contato=.,0,1) as ctt,
          ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Alta'), 1,0) as expc_alta,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Baixa'), 1,0) as expc_baixa,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Regularizado'), 1,0) as regularizado,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Sem'), 1,0) as sem_presp,
ifn ((calculated expc_alta+calculated expc_baixa+calculated regularizado+calculated sem_presp=0) and calculated ctt ne 0,1,0) as outros,
fluxo_prj,
ifn (calculated expc_alta=1,fluxo_prj,0) as vlr_expc_alta,
ifn (calculated expc_baixa=1,fluxo_prj,0) as vlr_expc_baixa,
ifn (calculated regularizado=1,fluxo_prj,0) as vlr_regularizado,
ifn (calculated sem_presp=1,fluxo_prj,0) as vlr_sem_presp,
ifn (calculated outros=1,fluxo_prj,0) as vlr_outros
      FROM CLI_MAIORES_2 t1

order by prefdep, fluxo_prj desc;
QUIT;


PROC SQL;
   CREATE TABLE WORK.fim_ag AS 
   SELECT t1.Prefdep,
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.fluxo_prj) as fluxo_prj,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.cliente_rel t1
group by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_grv AS 
   SELECT t1.Prefgerev as prefdep,
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.fluxo_prj) as fluxo_prj,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.cliente_rel t1
	  where Prefgerev ne ''
group by 1;
QUIT;

data WORK.fim_grv;
set WORK.fim_grv;
if qtd_cli>90;
run;

PROC SQL;
   CREATE TABLE WORK.fim_sup AS 
   SELECT t2.Prefsuper as prefdep,
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.fluxo_prj) as fluxo_prj,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_grv t1
	  inner join igr.auxiliar_relatorios t2 on (t1.prefdep=t2.prefdep)
group by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_dir AS 
   SELECT t2.Prefdir as prefdep,
          sum (qtd_cli) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.fluxo_prj) as fluxo_prj,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.fim_sup t1
	  inner join igr.auxiliar_relatorios t2 on (t1.prefdep=t2.prefdep)
	  where t2.Prefdir ne ''
group by 1;
QUIT;

data base;
set fim_ag fim_grv fim_sup fim_dir;
by prefdep;
percent=ctt/qtd_cli*100;
run;

data base_1 (DROP= TS Estilo Governo AcordoReduzido CodSitDep en PrefAgenc uor);
merge igr.auxiliar_relatorios base;
by prefdep;
IF QTD_CLI >=90;
run;

PROC EXPORT 
DATA=base_1 OUTFILE="/dados/infor/producao/inad_15_90/contatos_100_maiores.txt" 
	DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate contatos_100_maiores";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/inad_15_90/contatos_100_maiores.txt' INTO TABLE contatos_100_maiores FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="update posicoes set posicao = if(Weekday(date(now())) = 0 ,date(date(now())-3),date(date(now())-1)) where xml = 'contatos_100_maiores'";




/*contatos icred90*/

PROC SQL;
   CREATE TABLE WORK.cliente_rel AS 
   SELECT t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
		  t1.pilar,
		  ifn (data_contato=.,0,1) as ctt,
		  t1.opr_inad90,
          ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Alta'), 1,0) as expc_alta,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Baixa'), 1,0) as expc_baixa,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Regularizado'), 1,0) as regularizado,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Sem'), 1,0) as sem_presp,
ifn ((calculated expc_alta+calculated expc_baixa+calculated regularizado+calculated sem_presp=0) and calculated ctt ne 0,1,0) as outros,
saldo_opr,
ifn (calculated expc_alta=1,saldo_opr,0) as vlr_expc_alta,
ifn (calculated expc_baixa=1,saldo_opr,0) as vlr_expc_baixa,
ifn (calculated regularizado=1,saldo_opr,0) as vlr_regularizado,
ifn (calculated sem_presp=1,saldo_opr,0) as vlr_sem_presp,
ifn (calculated outros=1,saldo_opr,0) as vlr_outros
      FROM ICRED.SUM_CLI t1
where /*data_contato ne .
and*/ opr_inad90=1
order by 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_cart_pf AS 
   SELECT t1.Prefdep, 
          t1.cart, 
		  t1.pilar,
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.opr_inad90) as opr_inad90, 
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.CLIENTE_REL t1
	  where t1.pilar=1
group by 1, 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_cart_pj AS 
   SELECT t1.Prefdep, 
          t1.cart, 
		  t1.pilar,
          count (distinct t1.CD_CLI) as qtd_cli, 
		  sum (ctt) as ctt,
          sum (t1.opr_inad90) as opr_inad90, 
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros
      FROM WORK.CLIENTE_REL t1
	  where t1.pilar=2
group by 1, 2, 3;
QUIT;

proc sql;
create table carts as
select prefdep, cart
from fim_cart_pj
union
select prefdep, cart
from fim_cart_pf;
quit;

proc sql;
	create table fim_cart_tt as 
		select t0.prefdep,
			t0.cart,
			ifn (t1.qtd_cli=.,0,t1.qtd_cli)+ifn (t2.qtd_cli=.,0,t2.qtd_cli) as qtd_cli, 
			t1.qtd_cli as qtd_cli_pf,
			t1.ctt, 
			t1.expc_alta, 
			t1.expc_baixa, 
			t1.outros, 
			t1.regularizado, 
			t1.sem_presp, 
			t1.saldo_opr, 
			t1.vlr_expc_alta, 
			t1.vlr_expc_baixa, 
			t1.vlr_regularizado, 
			t1.vlr_sem_presp, 
			t1.vlr_outros,
			t2.qtd_cli as qtd_cli_pj,
			t2.ctt as ctt_pj, 
			t2.expc_alta as expc_alta_pj, 
			t2.expc_baixa as expc_baixa_pj, 
			t2.outros as outros_pj, 
			t2.regularizado as regularizado_pj, 
			t2.sem_presp as sem_presp_pj, 
			t2.saldo_opr as saldo_opr_pj, 
			t2.vlr_expc_alta as vlr_expc_alta_pj, 
			t2.vlr_expc_baixa as vlr_expc_baixa_pj, 
			t2.vlr_regularizado as vlr_regularizado_pj, 
			t2.vlr_sem_presp as vlr_sem_presp_pj, 
			t2.vlr_outros as vlr_outros_pj
		from carts t0
			left join fim_cart_pf t1 on (t0.prefdep=t1.prefdep and t0.cart=t1.cart)
			left join fim_cart_pj t2 on (t0.prefdep=t2.prefdep and t0.cart=t2.cart);
quit;
%zerarmissingtabela (work.fim_cart_tt);

PROC SQL;
   CREATE TABLE WORK.fim_ag AS 
   SELECT t1.Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_cart_tt t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_grv AS 
   SELECT prefgerev as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE WORK.fim_sup AS 
   SELECT prefsuper as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_uen AS 
   SELECT prefdir as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_vp AS 
   SELECT prefvice as Prefdep, 
          0 as cart, 
          sum (qtd_cli) as qtd_cli, 
		  sum (qtd_cli_pf) as qtd_cli_pf, 
		  sum (ctt) as ctt,
          sum (t1.expc_alta) as expc_alta, 
          sum (t1.expc_baixa) as expc_baixa, 
          sum (t1.outros) as outros,
          sum (t1.regularizado) as regularizado, 
          sum (t1.sem_presp) as sem_presp,
		  sum (t1.saldo_opr) as saldo_opr,
		  sum (t1.vlr_expc_alta) as vlr_expc_alta,
		  sum (t1.vlr_expc_baixa) as vlr_expc_baixa,
		  sum (t1.vlr_regularizado) as vlr_regularizado,
		  sum (t1.vlr_sem_presp) as vlr_sem_presp,
		  sum (t1.vlr_outros) as vlr_outros,
		  sum (qtd_cli_pj) as qtd_cli_pj, 
		  sum (ctt_pj) as ctt_pj,
          sum (t1.expc_alta_pj) as expc_alta_pj, 
          sum (t1.expc_baixa_pj) as expc_baixa_pj, 
          sum (t1.outros_pj) as outros_pj,
          sum (t1.regularizado_pj) as regularizado_pj, 
          sum (t1.sem_presp_pj) as sem_presp_pj,
		  sum (t1.saldo_opr_pj) as saldo_opr_pj,
		  sum (t1.vlr_expc_alta_pj) as vlr_expc_alta_pj,
		  sum (t1.vlr_expc_baixa_pj) as vlr_expc_baixa_pj,
		  sum (t1.vlr_regularizado_pj) as vlr_regularizado_pj,
		  sum (t1.vlr_sem_presp_pj) as vlr_sem_presp_pj,
		  sum (t1.vlr_outros_pj) as vlr_outros_pj
      FROM WORK.fim_ag t1 inner join igr.AUXILIAR_RELATORIOS t2 on (t1.prefdep=t2.prefdep)
	  where prefgerev ne '0000'
group by 1, 2;
QUIT;


data base;
	set fim_cart_tt fim_ag fim_grv fim_sup fim_uen fim_vp;
	by prefdep;
	percent_ctt=(ctt+ctt_pj)/qtd_cli*100;
	percent_ctt_pf=(ctt)/qtd_cli_pf*100;
	percent_ctt_pj=(ctt_pj)/qtd_cli_pj*100;
	ctt_tt=(ctt+ctt_pj);
run;

PROC SQL;
   CREATE TABLE WORK.base_rpt_fim AS 
   SELECT &DiaUtil_D1 format yymmdd10. as posicao,
		  input (t1.Prefdep, 4.) as prefdep,
		  cart,
          t1.qtd_cli, 
          t1.qtd_cli_pf, 
          t1.expc_alta, 
          t1.expc_baixa, 
          t1.outros, 
          t1.regularizado, 
          t1.sem_presp, 
          t1.saldo_opr, 
          t1.vlr_expc_alta, 
          t1.vlr_expc_baixa, 
          t1.vlr_regularizado, 
          t1.vlr_sem_presp, 
          t1.vlr_outros, 
          t1.qtd_cli_pj, 
          t1.ctt_pj, 
          t1.expc_alta_pj, 
          t1.expc_baixa_pj, 
          t1.outros_pj, 
          t1.regularizado_pj, 
          t1.sem_presp_pj, 
          t1.saldo_opr_pj, 
          t1.vlr_expc_alta_pj, 
          t1.vlr_expc_baixa_pj, 
          t1.vlr_regularizado_pj, 
          t1.vlr_sem_presp_pj, 
          t1.vlr_outros_pj, 
          t1.percent_ctt, 
          t1.percent_ctt_pf, 
          t1.percent_ctt_pj, 
          t1.ctt_tt, 
          t1.ctt
      FROM WORK.BASE t1
where qtd_cli ne .;
QUIT;


%zerarmissingtabela (work.base_rpt_fim);

%LET Keypass=6bkNeaR0aqvFsphD6DkdKXpstJB1S7kS2OrZm3m1SFzVuAXr6g;
%LET Rotina=contatos-icred90;
%LET Usuario=f8176496;

%ProcessoIniciar();

		/*rotina-366*/
PROC SQL;
			DROP TABLE TABELAS_EXPORTAR_REL;
			CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
			INSERT INTO TABELAS_EXPORTAR_REL VALUES('base_rpt_fim', 'contatos-icred90');
QUIT;

%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);







x cd /;
x cd /dados/infor/producao/pcld_vp/201701;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/


x cd /;
x cd /dados/infor/producao/pcld_vp/201602;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/

x cd /;
x cd /dados/infor/producao/pcld_vp;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/

x cd /;
x cd /dados/infor/producao/inad_15_90;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/

x cd /;
x cd /dados/infor/producao/inad_15_90/201701;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x chown f8176496:GSASBPA -R ./; /*FIXA O FUNCI DO E GRUPO*/

x cd /;
x cd /dados/infor/producao/indic_eficiencia_cobranca/dados_saida;
x chmod 777 *; /*ALTERAR PERMISÕES*/
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
