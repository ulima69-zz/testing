%include '/dados/infor/suporte/FuncoesInfor.sas';	
%diasUteis(%sysfunc(today()), 1);
%GLOBAL DiaUtil_D1;


%include '/dados/infor/suporte/FuncoesInfor.sas';	

/*libnames*/
Options
	Compress = no
	Reuse    = Yes
	PageNo   =   1
	PageSize =  55
	LineSize = 110;
LIBNAME RUT "/dados/infor/producao/RotinasUteis";
LIBNAME PCLD_old "/dados/infor/producao/pcld_vp";
LIBNAME old_1602 "/dados/infor/producao/pcld_vp/201602";
LIBNAME dicre "/dados/dicre/publico";
libname EC "/dados/infor/producao/indic_eficiencia_cobranca/dados_saida";
libname icred "/dados/infor/producao/inad_15_90";
libname mci "/dados/gecen/interno/bases/mci";
libname ind_e 	"/dados/infor/producao/indic_eficiencia_cobranca/dados_entrada";
libname ind_s 	"/dados/infor/producao/indic_eficiencia_cobranca/dados_saida";
libname gcn "/dados/externo/GECEN";
libname b_dados "/dados/publica/b_dados";
libname aux ORACLE USER=sas_gecen PASSWORD=Gecen77 PATH="sas_dirco" SCHEMA="atb_sinergia";


LIBNAME PCLD_VP "/dados/infor/producao/pcld_vp/201701";
%conectardb2(ARC, AUTHDOMAIN = DB2SGCEN);
%ConectarDB2 (REL);
%ConectarDB2 (BIC, AUTHDOMAIN = DB2SGCEN);
%conectardb2(atb);
%conectardb2(VARRC); 
%conectardb2(mci); 
%conectardb2(RAO, AUTHDOMAIN = DB2SGCEN);
%conectardb2(PGT, AUTHDOMAIN = DB2SGCEN);
%conectardb2(SGCEN, AUTHDOMAIN = DB2SGCEN);


PROC SQL;
   CREATE TABLE Max_data AS 
   SELECT DISTINCT 
                     (MAX(t1.DT_CCL_CTB)) FORMAT=DATE9. AS MaxData,
					 time() as agora
      FROM DB2ARC.CMPS_PVS_DRIA t1;
QUIT;

data _null_; set PCLD_VP.Max_data_cred; call symput('Dataant',MaxData);run;
data _null_; set Max_data; call symput('Dataatual_1',MaxData);run;
data _null_; set Max_data; call symput('Dataatual',"'"||put (MaxData, FINDFDD10.)||"'");run;
data _null_; set Max_data; call symput('Dataatu',put (MaxData, DATE9.));run;
data _null_; set Max_data; call symput('rotina',"'"||put (MaxData, yymmdd10.)||"'");run;
%put &rotina;
%put &Dataatual;
%put &Dataatual;
%put &Dataatual_1;
%put &Dataant;


proc sql;
create table dias_venc as 
select case when weekday(maxdata)=2 then '15, 16, 17'
else '15' end as dias_venc
from pcld_vp.max_data_cred;
quit;

data _null_; set dias_venc; call symput('dias_venc',dias_venc);run;
%put &dias_venc;


data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatual_1',MaxData);run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatual',"'"||put (MaxData, FINDFDD10.)||"'");run;
data _null_; set PCLD_VP.Max_data_cred; call symput('Dataatu',put (MaxData, DATE9.));run;
data _null_; set PCLD_VP.Max_data_cred; call symput('rotina',"'"||put (MaxData, yymmdd10.)||"'");run;
%put &rotina;
%put &Dataatual;
data _null_; call symput('contato',"'"||put (&DiaUtil_D1-30, FINDFDD10.)||':00:00:00'||"'");run;
%put &contato;

data datas;
	format agora $14.
		dt_arquivo date9.
		anomes yymmn6.;
	agora=put(today(), ddmmyy6.)||"_"||compress(put(compress(put(time(),time5.),":"),$5.));
	dt_arquivo=%lowcase(today());
	anomes=&Dataatual_1;
run;

proc sql noprint;
	select distinct agora into: agora separated by ', '
	from datas;

	select distinct dt_arquivo into: dt_arquivo separated by ', '
	from datas;

	
quit;

PROC SQL NOPRINT;
select distinct anomes into: anomes separated by ', '
	from datas;
quit;

%GLOBAL dt_arquivo AnoMes;

%put &AnoMes;



%ls(/dados/infor/producao/inad_15_90, out=work.mci_pj_tbl);

data work.out_ls0;
    set work.mci_pj_tbl;
    where pasta eq './' and substr(arquivo,1,9) in ('icred_enc');
    tabela = scan(arquivo,1,'.');
    dt_ref = input(scan(tabela,-1,'_'),yymmn6.);
    format dt_ref yymmn6.;
run;

proc sql noprint;
    select data_arquivo into: tabela0
        from work.out_ls0
            where arquivo = 'icred_enc.sas7bndx';
quit;
%put &tabela0;
PROC SQL;
   CREATE TABLE teste_100_maiores AS 
   SELECT t1.data_arquivo, 
          t1.hora_arquivo
      FROM WORK.OUT_LS0 t1
where arquivo = 'icred_enc.sas7bdat';
QUIT;

data _null_; set icred.teste_100_maiores; call symput('teste_ant',hora_arquivo);run;
data _null_; set teste_100_maiores; call symput('teste_atu',hora_arquivo);run;
%put &teste_ant;
%put &teste_atu;


%macro testa_tabela;
	%if &teste_ant ne &teste_atu %then
		%do;

/*
%macro sendEmail;
	options emailsys=smtp emailhost= 'smtp.bb.com.br' emailport=25;
	filename newEmail email;

	data _null_;
		file newEmail
		from = "prmunhoz@bb.com.br"
		to = ("prmunhoz@bb.com.br")
		subject = "Início 100 maiores" 
		;
		set max_data; x='INÍCIO '||PUT(TODAY(), DDMMYY10.); y='POSIÇÃO';
		put Y maxdata X agora;
	run;

%mend sendEmail;%sendEmail;
*/


PROC SQL;
   CREATE TABLE icred.teste_100_maiores AS 
   SELECT t1.data_arquivo, 
          t1.hora_arquivo
      FROM WORK.OUT_LS0 t1
where arquivo = 'icred_enc.sas7bdat';
QUIT;





/*
proc sql;
create table exclui_gov as
select t1.*
from ICRED.ICRED_ENC t1
left join mci.clientes_gov t2 on (t1.cd_cli=t2.cd_cli)
where t2.cd_cli=.
and NR_UNCO_CTR_OPR ne '00000000000000000'
ORDER BY PREFDEP;
run;*/

PROC SQL;
   CREATE TABLE WORK.AG AS 
   SELECT distinct 
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
            (SUM(t1.VL_DSP_PVS_CRD)) AS SUM_of_VL_DSP_PVS_CRD, 
            (SUM(t1.VL_BASE_CLC_PVS)) FORMAT=29.2 AS SUM_of_VL_TRND_PRJZ
      FROM ICRED.ICRED_ENC t1
	  where t1.NR_UNCO_CTR_OPR ne '00000000000000000' and INAD90 <> 0
      GROUP BY 1, 2, 3
      order by 3;
QUIT;

PROC SQL;
   CREATE TABLE WORK.AG AS 
   SELECT distinct t2.Prefdir, t2.PrefSuper, t2.PrefGerev,
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          SUM_of_VL_DSP_PVS_CRD, 
          SUM_of_VL_TRND_PRJZ
      FROM AG t1
	  	left join mci.clientes_gov t3 on (t1.cd_cli=t3.cd_cli)
           INNER JOIN igr.AUXILIAR_RELATORIOS t2 ON (t1.Prefdep = t2.PrefDep)
		   where t2.PrefGerev ne '0000'
		   and t3.cd_cli=.
      ORDER BY t2.PrefDEP,
               SUM_of_VL_TRND_PRJZ desc;
QUIT;


data AG_maiores;
set AG ;
by prefDEP;
if first.prefdep then seq_AG=0;
seq_AG+1;
IF seq_AG<=100;
run;

proc sort data=ag out=gerev nodupkey;
by prefgerev descending SUM_of_VL_TRND_PRJZ;
run;

/*PROC SQL;
   CREATE TABLE WORK.gerev AS 
   SELECT 
          t2.PrefGerev, 
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
            (SUM(t1.VL_DSP_PVS_CRD)) AS SUM_of_VL_DSP_PVS_CRD, 
            (SUM(t1.VL_TRND_PRJZ)) FORMAT=29.2 AS SUM_of_VL_TRND_PRJZ
      FROM exclui_gov t1
           INNER JOIN igr.AUXILIAR_RELATORIOS t2 ON (t1.Prefdep = t2.PrefDep)
		   where t2.PrefGerev ne '0000'
      GROUP BY t2.PrefGerev,
               t1.Prefdep,
               t1.cart,
               t1.CD_CLI
      ORDER BY t2.PrefGerev,
               SUM_of_VL_TRND_PRJZ;
QUIT;*/

data gerev_maiores;
set gerev ;
by prefgerev;
if first.prefgerev then seq_gerev=0;
seq_gerev+1;
IF seq_gerev<=100;
run;

proc sort data=ag out=super nodupkey;
by prefsuper descending SUM_of_VL_TRND_PRJZ;
run;

/*PROC SQL;
   CREATE TABLE WORK.super AS 
   SELECT t2.PrefSuper, 
          
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
  
            (SUM(t1.VL_DSP_PVS_CRD)) AS SUM_of_VL_DSP_PVS_CRD, 
  
            (SUM(t1.VL_TRND_PRJZ)) FORMAT=29.2 AS SUM_of_VL_TRND_PRJZ
      FROM exclui_gov t1
           INNER JOIN igr.AUXILIAR_RELATORIOS t2 ON (t1.Prefdep = t2.PrefDep)
		   where t2.PrefGerev ne '0000'
      GROUP BY t2.PrefSuper,
               
               t1.Prefdep,
               t1.cart,
               t1.CD_CLI
      ORDER BY t2.PrefSuper,
               SUM_of_VL_TRND_PRJZ;
QUIT;*/

data super_maiores;
set super ;
by prefSUPER;
if first.PrefSuper then seq_super=0;
seq_super+1;
if seq_super<=100;
run;

proc sort data=ag out=dir;
by prefdir descending SUM_of_VL_TRND_PRJZ;
run;

/*PROC SQL;
   CREATE TABLE WORK.dir AS 
   SELECT t2.Prefdir, 
          
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
            (SUM(t1.VL_DSP_PVS_CRD)) AS SUM_of_VL_DSP_PVS_CRD, 
            (SUM(t1.VL_TRND_PRJZ)) FORMAT=29.2 AS SUM_of_VL_TRND_PRJZ
      FROM exclui_gov t1
           INNER JOIN igr.AUXILIAR_RELATORIOS t2 ON (t1.Prefdep = t2.PrefDep)
		   where t2.PrefGerev ne '0000'
      GROUP BY t2.Prefdir,
               
               t1.Prefdep,
               t1.cart,
               t1.CD_CLI
      ORDER BY t2.Prefdir,
               SUM_of_VL_TRND_PRJZ;
QUIT;*/

data dir_maiores;
set dir ;
by prefdir;
if first.Prefdir then seq_dir=0;
seq_dir+1;
if seq_dir<=100;
run;

PROC SQL;
CREATE TABLE MCIS AS 
SELECT PREFDEP, CD_CLI
FROM AG_MAIORES
UNION
SELECT PREFDEP, CD_CLI
FROM GEREV_MAIORES
UNION
SELECT PREFDEP, CD_CLI
FROM SUPER_MAIORES
UNION
SELECT PREFDEP, CD_CLI
FROM DIR_MAIORES
order by 2, 1;
create index cd_cli on mcis(cd_cli);	
QUIT;



proc sql;
create table ICRED.OPR_MAIORES as
select distinct t1.*
from ICRED.ICRED_ENC t1
inner join mcis t2 on (t1.cd_cli=t2.cd_cli and T1.PREFDEP=T2.PREFDEP)
where t1.cd_cli ne 0;
run;

PROC SQL;
   CREATE TABLE unicos AS 
   SELECT DISTINCT t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI
      FROM ICRED.OPR_MAIORES t1;
QUIT;

PROC SQL;
   CREATE TABLE duplicados AS 
   SELECT distinct t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          /* COUNT_of_CD_CLI */
            (COUNT(t1.CD_CLI)) AS COUNT_of_CD_CLI
      FROM unicos t1
      GROUP BY t1.CD_CLI
	  having COUNT_of_CD_CLI>1
      ORDER BY COUNT_of_CD_CLI DESC,
               t1.CD_CLI;
QUIT;

PROC SQL;
   CREATE TABLE simples AS 
   SELECT distinct t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          /* COUNT_of_CD_CLI */
            (COUNT(t1.CD_CLI)) AS COUNT_of_CD_CLI
      FROM unicos t1
      GROUP BY t1.CD_CLI
	  having COUNT_of_CD_CLI=1
      ORDER BY COUNT_of_CD_CLI DESC,
               t1.CD_CLI;
QUIT;

PROC SQL;
	DROP TABLE DB2SGCEN.MCI_100;
	CREATE TABLE DB2SGCEN.MCI_100 AS
		SELECT DISTINCT CD_CLI FORMAT Z9.
			FROM DUPLICADOS;
QUIT;


PROC SQL;CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
   CREATE TABLE WORK.mci_cart AS select * FROM CONNECTION TO DB2(
   SELECT DISTINCT t2.COD, 
          t2.COD_PREF_AGEN
      FROM DB2SGCEN.MCI_100 t1
           INNER JOIN DB2MCI.CLIENTE t2 ON (t1.CD_CLI = t2.COD))
order by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.mci_cart AS
   SELECT DISTINCT t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          t1.COUNT_of_CD_CLI, 
          put (t2.COD_PREF_AGEN, z4.) as COD_PREF_AGEN
      FROM WORK.DUPLICADOS t1
           INNER JOIN mci_cart t2 ON (t1.CD_CLI = t2.COD)
order by 3;
QUIT;



PROC SQL;
   CREATE TABLE WORK.MCI_CART_s_dup AS 
   SELECT distinct t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          t1.COUNT_of_CD_CLI, 
          t1.COD_PREF_AGEN
      FROM WORK.MCI_CART t1
where Prefdep=COD_PREF_AGEN;
QUIT;

proc sql;
create table cart_s_dup as 
select prefdep, cart, cd_cli
from simples
union
select prefdep, cart, cd_cli
from MCI_CART_s_dup;
quit;

PROC SQL;
   CREATE TABLE ICRED.OPR_MAIORES AS 
   SELECT t2.Prefdep, 
          t2.cart, 
          t1.DT_MVTC, 
          t1.CD_CLI, 
          t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.NR_EPRD_FNCD, 
          t1.NR_SCTR_OPR, 
          t1.CD_PRF_DEPE, 
          t1.NR_CTR_OPR, 
          t1.CD_RSCO_ATBD, 
          t1.IN_RBC_CRD_VCD, 
          t1.CD_MTDL_RSCO_OPR, 
          t1.NR_RADC_CGC, 
          t1.CD_GR_EPRL, 
          t1.SG_SIS_OGM_OPR, 
          t1.NR_DD_VCD_OPR, 
          t1.NR_DD_VNCT_OPR, 
          t1.CD_RSCO_ATBD_PRJ, 
          t1.DT_ALT_RSCO_OPR, 
          t1.DT_CTR_OPR, 
          t1.CD_EST_ESPL_CTR, 
          t1.VL_BASE_CLC_PVS, 
          t1.VL_CLCD_PVS, 
          t1.VL_DSP_PVS_CRD, 
          t1.VL_TRND_PRJZ, 
          t1.CLI_ZERADO, 
          t1.INAD15, 
          t1.INAD60, 
          t1.INAD90
      FROM ICRED.OPR_MAIORES t1
           inner JOIN WORK.CART_S_DUP t2 ON (t1.CD_CLI = t2.CD_CLI);
QUIT;

PROC SQL;
   CREATE TABLE WORK.OPR_MAIORES AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          ifn (t1.CD_EST_ESPL_CTR=0,t1.NR_DD_VCD_OPR,0) as NR_DD_VCD_OPR,
          t1.VL_BASE_CLC_PVS as saldo_opr, 
          t3.VL_ATR_SCTR as vlr_atrs, 
          t1.CD_RSCO_ATBD, 
          t1.CD_RSCO_ATBD_PRJ, 
          t1.DT_ALT_RSCO_OPR, 
		  ifn(t4.NR_UNCO_CTR_OPR='',0,1) as ec,
          t1.VL_DSP_PVS_CRD as fluxo_pcld, 
          t1.VL_TRND_PRJZ*-1 as fluxo_prj
      FROM ICRED.OPR_MAIORES t1
           INNER JOIN igr.AUXILIAR_RELATORIOS t2 ON (t1.Prefdep = t2.PrefDep)
           LEFT JOIN ICRED.VLR_ATRS t3 ON (t1.NR_UNCO_CTR_OPR = t3.NR_UNCO_CTR_OPR) AND (t1.NR_EPRD_FNCD = 
          t3.NR_EPRD_FNCD) AND (t1.NR_SCTR_OPR = t3.NR_SCTR_OPR)
           LEFT JOIN IND_S.BASE_FECHADA_201611 t4 ON (t1.Prefdep = t4.Prefdep) AND (t1.NR_UNCO_CTR_OPR = 
          t4.NR_UNCO_CTR_OPR);
QUIT;

PROC SQL;
   CREATE TABLE WORK.OPR_MAIORES_1 AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          max (t1.NR_DD_VCD_OPR) as NR_DD_VCD_OPR, 
          sum (t1.saldo_opr) as saldo_opr, 
          sum (t1.vlr_atrs) as vlr_atrs, 
          max (t1.CD_RSCO_ATBD) as CD_RSCO_ATBD, 
          max (t1.CD_RSCO_ATBD_PRJ) as CD_RSCO_ATBD_PRJ, 
          min (t1.DT_ALT_RSCO_OPR) as DT_ALT_RSCO_OPR, 
		  max (ifn (NR_DD_VCD_OPR>90,1,0)) as inad90,
		  max (ifn (NR_DD_VCD_OPR>14,1,0)) as inad15,
		  max (t1.ec) as ec,
          sum (t1.fluxo_pcld) as fluxo_pcld, 
          sum (t1.fluxo_prj) as fluxo_prj
      FROM WORK.OPR_MAIORES t1
	  where NR_UNCO_CTR_OPR ne '00000000000000000'
group by 1;
QUIT;


PROC SQL;
   CREATE TABLE icred.OPR_MAIORES_2 AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
		  ifn (t2.cd_cli=.,1,2) as pilar,
          t1.Prefdep, 
          t4.PrefGerev, 
          t3.PrefSuper, 
		  t5.Prefdir, 
          t1.cart, 
          t1.CD_CLI, 
          NR_DD_VCD_OPR, 
          saldo_opr, 
          vlr_atrs, 
          t1.CD_RSCO_ATBD, 
          t1.CD_RSCO_ATBD_PRJ, 
          t1.DT_ALT_RSCO_OPR format yymmdd10., 
		  inad90,
		  inad15,
		  t1.ec,
          fluxo_pcld, 
          fluxo_prj
      FROM WORK.OPR_MAIORES_1 t1
	  left join mci.clientes_pj t2 on (t1.cd_cli=t2.cd_cli)
	  left join super_maiores t3 on (t1.cd_cli=t3.cd_cli)
	  left join gerev_maiores t4 on (t1.cd_cli=t4.cd_cli)
	  left join dir_maiores t5 on (t1.cd_cli=t5.cd_cli)
group by 1;
QUIT;


PROC SQL;
   CREATE TABLE ICRED.OPR_MAIORES_2 AS 
   SELECT distinct t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.pilar, 
          t1.Prefdep, 
          ifc (t1.PrefGerev='','',t2.PrefGerev) as PrefGerev, 
          ifc (t1.PrefSuper='','',t2.PrefSuper) as PrefSuper, 
          ifc (t1.PrefDir='','',t2.PrefDir) as PrefDir, 
          t1.cart, 
          t1.CD_CLI, 
          t1.NR_DD_VCD_OPR, 
          t1.saldo_opr, 
          t1.vlr_atrs, 
          t1.CD_RSCO_ATBD, 
          t1.CD_RSCO_ATBD_PRJ, 
          t1.DT_ALT_RSCO_OPR, 
          t1.inad15, 
          t1.inad90, 
          t1.ec, 
          t1.fluxo_pcld, 
          t1.fluxo_prj
      FROM ICRED.OPR_MAIORES_2 t1
           INNER JOIN igr.AUXILIAR_RELATORIOS t2 ON (t1.Prefdep = t2.PrefDep);
QUIT;


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
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414)
	  )
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
		and ((t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 42)
		or (t1.CD_ASNT_INRO = 6 AND t1.CD_SUB_ASNT_INRO = 54)
		or (t1.CD_ASNT_INRO = 1 AND t1.CD_SUB_ASNT_INRO = 60))
	  
	  and (t1.CD_RSTD_INRO in (1, 5, 10, 11, 12, 13, 14) and t1.CD_SUB_RSTD_INRO in (109, 110, 136, 138, 139, 140, 141, 142, 1201, 1202, 1203, 
		3, 4, 5, 6, 7, 12, 13, 14, 1301, 1302, 1303, 1304, 1305, 1306, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414)
	  )
group by 1;
QUIT;




proc sql;
create table max_1 as 
select distinct mci,
max (timestamp_contato) format datetime25.6 as timestamp_contato
from WORK.QUERY_FOR_INRO_CLI
group by 1;
quit;



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
          t1.impacto15, 
          t1.inad15, 
          t1.impacto90, 
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
           LEFT JOIN WORK.PAG_AG t3 ON (t1.CD_CLI = t3.NR_DOC_BNFC_MCI)
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

proc sql;
create table CLI_MAIORES_NOVO_REL as 
select "&Dataatu"D format yymmdd10. as posicao,
 t1.CD_CLI, 
          input (t1.Prefdep, 4.) as Prefdep,
          ifn (input (t1.PrefGerev, 4.)=.,0,input (t1.PrefGerev, 4.)) as PrefGerev,
          ifn (input (t1.PrefSuper, 4.)=.,0,input (t1.PrefSuper, 4.)) as PrefSuper,
		  0 as gecor,
          ifn (input (t1.PrefDir, 4.)=.,0,input (t1.PrefDir, 4.)) as prefdir,
          coalesce(t1.cart, 7002),
          t1.pilar, 
          t1.NR_DD_VCD_OPR, 
          coalesce(t1.saldo_opr,0)format 19.2,
          coalesce(t1.vlr_atrs, 0)format 19.2,
          coalesce(t1.fluxo_pcld, 0)format 19.2,
          coalesce(t1.fluxo_prj, 0)format 19.2,
          t1.inad90, 
          coalesce(t1.impacto15, 0)format 19.2,
          t1.inad15, 
          coalesce(t1.impacto90, 0)format 19.2,
          0 as ec, 
          coalesce(t1.impactoec, 0)format 19.2,
          t1.data_contato, 
          t1.qtd_opr, 
          t1.COD_SUB_RESULTADO_DESCRICAO, 
		  '' as obs,
          t1.DT_OGNL_PGTO, 
          ifn (t1.VL_PGTO=.,0,t1.VL_PGTO) format 19.2 as VL_PGTO, 
          ifn (input(t1.TETO_MAX_DESC_PEC, 10.)=.,0,input(t1.TETO_MAX_DESC_PEC, 10.)) as TETO_MAX_DESC_PEC
 from CLI_MAIORES_2 t1;
quit;



proc sql;
create table OPR_MAIORES_NOVO_REL as 
select "&Dataatu"D format yymmdd10. as posicao,
t1.NR_UNCO_CTR_OPR, 
          t1.CD_PRD, 
          t1.CD_MDLD, 
          t1.pilar, 
		  t1.CD_CLI, 
          input(t1.Prefdep, 4.) as Prefdep,
          ifn (input(t1.PrefGerev, 4.)=.,0,input(t1.PrefGerev, 4.)) as PrefGerev,
          ifn (input(t1.PrefSuper, 4.)=.,0,input(t1.PrefSuper, 4.)) as PrefSuper,
          ifn (input(t1.PrefDir, 4.)=.,0,input(t1.PrefDir, 4.)) as PrefDir,
          coalesce(t1.cart, 7002),
          t1.NR_DD_VCD_OPR, 
          coalesce(t1.saldo_opr, 0)format 19.2,
          coalesce(t1.vlr_atrs, 0)format 19.2,
          t1.CD_RSCO_ATBD, 
          t1.CD_RSCO_ATBD_PRJ, 
          t1.DT_ALT_RSCO_OPR, 
          t1.inad15, 
          t1.inad90, 
          0 as ec, 
          coalesce(t1.fluxo_pcld, 0)format 19.2,
          coalesce(t1.fluxo_prj, 0)format 19.2,
		  0 as acp
from icred.OPR_MAIORES_2 t1;
quit;


%LET Usuario=f8176496;
%LET Keypass=adimplencia-100-maiores-icred90-dIC1XO70P42l1VATXcfV0ebWTW9EvjpSRc6LsYwcMyxjnpFpFF;

PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('CLI_MAIORES_NOVO_REL', 'adimplencia-100-maiores-icred90');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('OPR_MAIORES_NOVO_REL', 'operacoes');
QUIT;

%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);




PROC SQL;
   CREATE TABLE WORK.cliente_rel AS 
   SELECT t1.prefdir, t1.prefsuper, t1.prefgerev, t1.Prefdep, 
          t1.cart, 
          t1.CD_CLI, 
		  ifn (data_contato=.,0,1) as ctt,
          ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Alta') 
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('acionado')
or t1.COD_SUB_RESULTADO_DESCRICAO contains ( 'Formalização')
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('formalização' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Promessa') 
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('estudo' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Estudo' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('efetuado' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('RAO' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('PCLD' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Renegociado'), 1,0) as expc_alta,
ifn (t1.COD_SUB_RESULTADO_DESCRICAO contains ('Baixa')
or t1.COD_SUB_RESULTADO_DESCRICAO contains ( 'Ajuizamento')
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Capacidade' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Carência') 
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Evadido' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Falecido' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Fraude' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Liminar' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Prazo' )
or t1.COD_SUB_RESULTADO_DESCRICAO contains ('Recuperação'), 1,0) as expc_baixa,
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
;
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
/*
%macro sendEmail;
	options emailsys=smtp emailhost= 'smtp.bb.com.br' emailport=25;
	filename newEmail email;

	data _null_;
		file newEmail
		from = "prmunhoz@bb.com.br"
		to = ("prmunhoz@bb.com.br")
		subject = "Fim 100 maiores" 
		;
		set max_data;x='FIM '||PUT(TIME(), E8601TM8.);
		put X;
	run;

%mend sendEmail;%sendEmail;
*/
x cd /;
x cd /dados/infor/producao/pcld_vp/201701;
x chmod 777 *; /*ALTERAR PERMISÕES*/

x cd /;
x cd /dados/infor/producao/pcld_vp/201602;
x chmod 777 *; /*ALTERAR PERMISÕES*/

x cd /;
x cd /dados/infor/producao/pcld_vp;
x chmod 777 *; /*ALTERAR PERMISÕES*/

x cd /;
x cd /dados/infor/producao/inad_15_90;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x cd /;
x cd /dados/infor/producao/inad_15_90/201701;
x chmod 777 *; /*ALTERAR PERMISÕES*/


%end;

%mend;

%testa_tabela;

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
