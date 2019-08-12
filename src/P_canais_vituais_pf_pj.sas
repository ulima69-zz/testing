%include '/dados/infor/suporte/FuncoesInfor.sas';	
%diasUteis(%sysfunc(today()), 5);
/*  %let diautil_d1 = '29mar2018'd; */

%let ind = 000000028;
%put &ind;

data datas;
	format agora $14.
		dt_arquivo date9.
		anomes yymmn6.
		Mesano mmyyn6.;
		Mesano = &diaUtil_d1;
	agora=put(&diautil_d0, ddmmyy6.)||"_"||compress(put(compress(put(time(),time5.),":"),$5.));
	dt_arquivo=%lowcase(&diautil_d1);
	anomes=&diautil_d1;
	txtfont = put(&diaUtil_d1, DANDFMN3.)||'3154';
	txtorc = put(&diaUtil_d1, DANDFMN3.)||'3153';
	mes=month(&diautil_d1);
run;

proc sql noprint;
	select distinct agora into: agora separated by ', '
	from work.datas;
	select distinct dt_arquivo into: dt_arquivo separated by ', '
	from work.datas;
	select distinct anomes into: anomes separated by ', '
	from work.datas;
	select distinct txtfont into: txtfont separated by ', '
    from work.datas;
	select distinct txtorc into: txtorc separated by ', '
    from work.datas;
	select distinct Mesano into: Mesano separated by ', '
    from work.datas;
	select distinct Mes into: Mes separated by ', '
    from work.datas;
quit;
%put &mes;

Options
	Compress = no
	Reuse    = Yes
	PageNo   =   1
	PageSize =  55
	LineSize = 110;

/*libnames*/ 
libname ind "/dados/infor/producao/ind_uso_cn_virt";
libname bic_di "/dados/publica/b_dados2/";
libname bic_p  "/dados/publica/b_dados2/bic";
LIBNAME PUB "/dados/externo/restrito";
LIBNAME GCN "/dados/externo/DIVAR/METAS";
libname ind_28 "/dados/infor/conexao/2018/&ind";

/*libname geinf oracle user=sas_direc password=direc8008 path="dirco1" schema="ren"; /*ren diaria*/
libname deb clear;
libname bcs clear;
libname bic clear;
libname cdc clear;
libname coc clear;
libname cop_bas clear;
libname ext clear;

libname rdo clear;

%CONECTARDB2(BIC);
libname aux ORACLE USER=sas_gecen PASSWORD=Gecen77 PATH="sas_dirco" SCHEMA="atb_sinergia";

/*%BuscarOrcado(IND=&ind, MMAAAA=&mesano);

PROC SQL;
   CREATE TABLE WORK.ORCADOS AS 
   SELECT t1.ind, 
          t1.comp, 
          t1.prefdep, 
          t1.uor, 
          t1.ctra, 
          t1.mmaaaa, 
          t1.vlr_orc as valor
      FROM WORK.ORCADOS t1;
QUIT;
*/
proc sql;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	CREATE TABLE aux_cd_tip as 
		SELECT * FROM CONNECTION TO DB2
		(select 
			a.cd_cli, 
			a.cd_tip_cnl,
			a.cd_tran_inro_sis,
			a.ts_inro_cli,
			a.VL_INRO_CLI
		from db2bic.aux_inro_cli_atu a
			inner join db2bic.tran_inro_cli b on (a.cd_tran_inro_sis = b.cd_tran_inro_sis)
				where b.in_ntz_fncr_opr = 'S' 
					and b.in_inic_acao_bco = 'N'
					and a.cd_tip_cnl in (12, 15, 19, 20, 21, 23, 24, 25, 26));
quit;








data bcn_pf; 
set COMUM.pai_rel_&anomes (where=(CD_TIP_CTRA in (10, 16, 50, 15, 17, 18, 19, 20, 55, 70, 56, 57, 60)));
run;

proc sort data=bcn_pf;
	by cd_cli CD_TIP_CTRA;
run;


proc sql;
	create table net_mob as
		select put (a.CD_PRF_DEPE, z4.) as prefdep,
			a.cd_cli,
			ifn(a.CD_TIP_CTRA in (10 16 50 56 57 60), a.CD_TIP_CTRA, 700) as tp_cart,
			ifn(a.CD_TIP_CTRA in (10 16 50 56 57 60), a.NR_SEQL_CTRA, 7002) as cart,
			b.cd_tran_inro_sis as cd_tran_sis,
			ifn (b.cd_tip_cnl in(12 23 25) and month(datepart(TS_INRO_CLI))=month(&diautil_d1), 1, 0) as web,
			ifn (b.cd_tip_cnl in(20 19 24) and month(datepart(TS_INRO_CLI))=month(&diautil_d1), 1, 0) as mobile,
			datepart (ts_inro_cli) FORMAT ddmmyy10. as data
		from bcn_pf a
			left join aux_cd_tip b on(a.cd_cli=b.cd_cli)
				order by 1, 2, 3;
quit;

data ind.net_mob_2_revisado;
	set net_mob;
run;

proc sql;
	create table qtde_total1 as 
		select distinct 
			prefdep, 
			cart,
			tp_cart,
			cd_cli,
			MAX(ifn(web = 1, 1, 0)) as qtde_cli_web,
			MAX(ifn(mobile = 1, 1, 0)) as qtde_cli_mob,
			MAX(ifn(mobile = 1 or web = 1, 1, 0)) as qtde_cli_mob_web,
			MAX(ifn(web = 0 and mobile = 0, 1, 0)) as qtde_cli_nao
		from ind.net_mob_2_revisado
GROUP BY 1, 2, 3, 4;
quit;

proc sql;
	create table qtde_total as 
		select DISTINCT
			prefdep, 
			cart,			
			tp_cart,
			(COUNT (DISTINCT cd_cli)) as total_cli, 
			(SUM(qtde_cli_web)) as qtde_cli_web, 
			(SUM(qtde_cli_mob)) as qtde_cli_mob, 
			(SUM(qtde_cli_mob_web)) as qtde_cli_mob_web, 
			(SUM( qtde_cli_nao)) as qtde_cli_nao
		from qtde_total1
			group by 1,2;
quit;

proc sql;
	create table apoio as
		select distinct 
			prefdep, cart, tp_cart
		from qtde_total;
quit;

/*

PROC SQL;
   CREATE TABLE WORK.cart_orc AS 
   SELECT t1.PrefDep, 
          t1.ctra as cart,
		  t1.valor
      FROM ORCADOS t1
      WHERE t1.ctra NOT = 0;
QUIT;
*/

proc sql;
	create table ind.qtdes_new_&anomes as 
		select distinct 
			t1.prefdep, 
			t1.cart,
			t2.qtde_cli_web, 
			t2.qtde_cli_mob, 
			t2.qtde_cli_nao,
			t2.total_cli,
			t2.qtde_cli_mob_web as qtd_uso,
			0 as valor,
			(t2.qtde_cli_mob_web / t2.total_cli) * 100 as percent,
			1 as qtd_cart
	from apoio t1 
		left join qtde_total t2 on (t1.prefdep = t2.prefdep and t1.cart=t2.cart and t1.tp_cart=t2.tp_cart)	
		/*left join cart_orc t3 on (t1.prefdep = put (t3.prefdep,z4.) and t1.cart=t3.cart)*/
			group by 1,2
;
quit;

%ZERARMISSINGTABELA (ind.qtdes_new_&ANOMES);

PROC SQL;
   CREATE TABLE pub.carteiras_canais_virtuais_&anomes AS 
   SELECT t1.prefdep, 
          t1.cart, 
          t1.qtde_cli_web, 
          t1.qtde_cli_mob, 
          t1.qtde_cli_nao, 
          t1.total_cli, 
          t1.qtd_uso, 
          t1.percent, 
          0 as orcado
      FROM IND.QTDES_NEW_&anomes t1/*, ORCADOS t2
      WHERE (t1.cart = t2.ctra AND t1.prefdep = put (t2.PrefDep,z4.))*/;
QUIT;


proc sql;
	create table fim_ag as 
		select distinct 
			f.prefdep as prefdep, 
			0 as cart,
			sum(f.qtde_cli_web) format 19.0 as qtde_cli_web,
			sum(f.qtde_cli_mob) format 19.0 as qtde_cli_mob,
			sum(f.qtde_cli_nao) format 19.0 as qtde_cli_nao,
			sum(f.total_cli) format 19.0 as total_cli,
			sum(f.qtd_uso) format 19.0 as qtd_uso,
			sum (f.valor) as valor,
		    CALCULATED QTD_USO/CALCULATED TOTAL_CLI*100 format 19.2 AS PERCENT,
			sum (f.qtd_cart) as qtd_cart
		from ind.qtdes_new_&anomes f 
		inner join IGR.auxiliar_relatorios a on (f.prefdep=a.prefdep)
		/*inner join cart_orc t3 on (f.prefdep = put (t3.prefdep,z4.) and f.cart=t3.cart)*/
					where f.prefdep ne "4777" 		
				group by 1,2;
quit;


proc sql;
	create table fim_grv as
		select 
			prefgerev as prefdep,
			0 as cart,
			sum (a.qtde_cli_web) as qtde_cli_web,
			sum (a.qtde_cli_mob) as qtde_cli_mob,
			sum (a.qtde_cli_nao) as qtde_cli_nao,
			sum (a.total_cli) as total_cli,
			sum (a.qtd_uso) as qtd_uso,
			sum (a.valor) as valor,
		   CALCULATED QTD_USO/CALCULATED TOTAL_CLI*100 AS PERCENT,
			sum (qtd_cart) as qtd_cart
		from fim_ag a
			inner join IGR.auxiliar_relatorios q on(a.prefdep=q.prefdep)
				where prefgerev ne "0000"
					group by 1
						order by 1;
quit;

proc sql;
	create table fim_super as
		select
			prefsuper as prefdep,
			0 as cart,
			sum (a.qtde_cli_web) as qtde_cli_web,
			sum (a.qtde_cli_mob) as qtde_cli_mob,
			sum (a.qtde_cli_nao) as qtde_cli_nao,
			sum (a.total_cli) as total_cli,
			sum (a.qtd_uso) as qtd_uso,
			sum (a.valor) as valor,
		   CALCULATED QTD_USO/CALCULATED TOTAL_CLI*100 AS PERCENT,
			sum (qtd_cart) as qtd_cart
		from fim_grv a
			inner join IGR.auxiliar_relatorios q on(a.prefdep=q.prefdep)
				group by 1
					order by 1;
quit;

proc sql;
	create table fim_uen as
		select 
			prefdir as prefdep, 
			0 as cart,
			sum (a.qtde_cli_web) as qtde_cli_web,
			sum (a.qtde_cli_mob) as qtde_cli_mob,
			sum (a.qtde_cli_nao) as qtde_cli_nao,
			sum (a.total_cli) as total_cli,
			sum (a.qtd_uso) as qtd_uso,
			sum (a.valor) as valor,
		   CALCULATED QTD_USO/CALCULATED TOTAL_CLI*100 AS PERCENT,
			sum (qtd_cart) as qtd_cart
		from fim_super a
			inner join IGR.auxiliar_relatorios q on(a.prefdep=q.prefdep)
				group by 1
					order by 1;
quit;

proc sql;
	create table fim_vivar as
		select 
			prefvice as prefdep, 
			0 as cart,
			sum (a.qtde_cli_web) as qtde_cli_web,
			sum (a.qtde_cli_mob) as qtde_cli_mob,
			sum (a.qtde_cli_nao) as qtde_cli_nao,
			sum (a.total_cli) as total_cli,
			sum (a.qtd_uso) as qtd_uso,
			sum (a.valor) as valor,
		   CALCULATED QTD_USO/CALCULATED TOTAL_CLI*100 AS PERCENT,
			sum (qtd_cart) as qtd_cart
		from fim_uen a
			inner join IGR.auxiliar_relatorios q on(a.prefdep=q.prefdep)
				group by 1
					order by 1;
quit;

data base_rpt;
	set ind.qtdes_new_&ANOMES fim_ag fim_grv fim_super fim_uen fim_vivar;
	by prefdep;
	where qtde_cli_web+qtde_cli_mob+qtde_cli_nao+total_cli ne 0;
run;

%ZERARMISSINGTABELA (base_rpt);

data base_rpt_fim (drop= ts estilo governo codsitdep acordoreduzido);

	merge IGR.auxiliar_relatorios base_rpt;
	
	by prefdep;
run;

data base_rpt_fim1 (drop=prefagenc);
	set base_rpt_fim;

	if tipodep='01' then
		prefpai=prefagenc;

	if cart ne 0 then
		do;
			prefpai=prefdep;
			tipodep='89';
			niveldep='0';
		end;
	;
run;
%ZERARMISSINGTABELA (work.base_rpt_fim1);

data _null_; call symput('posicao',"'"||put ((&diautil_d1), yymmdd10.)||"'");run;
%put &posicao;

PROC SQL;
   CREATE TABLE BASE_RPT_FIM2 AS 
   SELECT distinct &diautil_d1 format yymmdd10. as posicao,
          input (t1.PrefDep, 4.) as prefdep,          
          t1.cart, 
          t1.qtde_cli_web, 
          t1.qtde_cli_mob, 
          t1.qtde_cli_nao, 
          t1.total_cli, 
          t1.qtd_uso, 
		  t1.valor,
		  0 as orc_qtd,
          t1.percent,
		  t1.percent/t1.valor*100 as pct_atg_conexao,
		  qtd_cart
      FROM WORK.BASE_RPT_FIM1 t1
	  /*where t1.valor not in (., 0)*/
order by 2;
QUIT;
%zerarmissingtabela (work.BASE_RPT_FIM2);

DATA GCN.CANAIS_PF_&ANOMES;
SET ind.BASE_RPT_FIM2;
BY PREFDEP;

RUN;



x /dados/infor/producao/ind_uso_cn_virt;
x chmod 777 *;

x /dados/infor/producao/ind_uso_cn_virt;
x chmod 777 *.txt;
x /dados/infor/producao/ind_uso_cn_virt/dados_saida;
x chmod 777 *;

x cd /dados/infor/producao/ind_uso_cn_virt/dados_saida;
x chmod 777 *.txt; 



/****************ANALITICO********************************/
/****************ANALITICO********************************/
/****************ANALITICO********************************/
/****************ANALITICO********************************/


DATA BASE_ANALITICO;
SET NET_MOB;
RUN;



PROC SORT DATA=BASE_ANALITICO OUT=BASE_ANALITICO1 NODUPKEY; BY cd_cli DATA; RUN;

PROC SQL;
   CREATE TABLE CLIENTES AS 
   SELECT t1.cd_cli as mci
      FROM WORK.BASE_ANALITICO1 t1;
QUIT;

DATA WEB MOB NAO LIXO;
SET BASE_ANALITICO1;
IF WEB=1 or MOBILE=1 THEN OUTPUT WEB;
IF MOBILE=0 AND WEB=0 THEN OUTPUT NAO;
ELSE OUTPUT LIXO;
RUN;

DATA WEB; 
SET WEB;
BY cd_cli;

	IF Last.cd_cli THEN
		Seq=0;
	Seq+1;
	
RUN;


DATA NAO; 
SET NAO;
BY cd_cli;

	IF Last.cd_cli THEN
		Seq=0;
	Seq+1;
	
RUN;


DATA WEB1; 
SET WEB(WHERE= (Seq = 1));
DROP SEQ;

RUN;


DATA NAO1; 
SET NAO(WHERE= (Seq = 1));
DROP SEQ;

RUN;

DATA BASE_ANALITICO2;
SET WEB1 NAO1;
RUN;

PROC SORT DATA=BASE_ANALITICO2 OUT=BASE_ANALITICO3; BY cd_cli; RUN;

PROC SQL;
   CREATE TABLE BASE_ANALITICO_4_&anomes AS 
   SELECT &diautil_d1 format yymmdd10. as posicao,
		  input (t1.PREFDEP, 4.) as prefdep,
   		  t1.CART, 
          t1.cd_cli, 
          t1.TP_CART,           
          t1.WEB, 
          t1.MOBILE, 
          t1.DATA format yymmdd10.
      FROM BASE_ANALITICO3 t1
;
QUIT;

data pub.canais_virtuais_&anomes;
set BASE_ANALITICO_4_&anomes;
run;

%LET Usuario=f8176496;
%LET Keypass=pafO93AETmfcB1tZjxYSJYp6yFaONU8JkvSKGevdVs7T0FkykM;

PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('BASE_RPT_FIM2', 'canais-virtuais-pf');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('BASE_ANALITICO_4_&anomes', 'detalha-clientes');
QUIT;

%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);


/*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*/               /*|\    |  ||||| \    /  |||||*/                /*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*/               /*|  \  |  |   |  \  /   |   |*/                /*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*/               /*|    \|  |||||   \/    |||||*/                /*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*/



/*PROC SQL;*/
/*	CREATE TABLE WORK.PARA_BASE_CONEXAO_IND AS*/
/*		SELECT*/
/*			&IND as ind, /*CODIGO INDICADOR*/*/
/**/
/*	0 as COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 as COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 as ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	input (UOR,9.) as uor,*/
/*	t1.PREFDEP,*/
/*	cart as CTRA,            */
/*	percent as VLR_RLZ, /*VALOR REALIZADO*/*/
/*	valor as VLR_ORC, /*VALOR ORÇADO*/*/
/**/
/*	0 as VLR_ATG, /*VALOR ATINGIMENTO, por padrão 0, enviar somente se o atingimento tiver regra de cálculo*/*/
/*	t1.posicao /*DATA DO VALOR LEVANTADO*/*/
/*	FROM BASE_RPT_FIM2 t1*/
/*		inner join igr.dependencias t2 on (put(t1.prefdep, z4.)=t2.prefdep)*/
/*			where t2.sb='00' and t1.cart <>0 and valor not in (., 0)*/
/*				order by t1.prefdep;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE WORK.PARA_BASE_CONEXAO_COMP AS*/
/*		SELECT*/
/*			&IND as ind, /*CODIGO INDICADOR*/*/
/**/
/*	1 as COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 as COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	1 as ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	input (UOR,9.) as uor,*/
/*	t1.PREFDEP,*/
/*	cart as CTRA,            */
/*	percent as VLR_RLZ, /*VALOR REALIZADO*/*/
/*	valor as VLR_ORC, /*VALOR ORÇADO*/*/
/**/
/*	0 as VLR_ATG, /*VALOR ATINGIMENTO, por padrão 0, enviar somente se o atingimento tiver regra de cálculo*/*/
/*	t1.posicao /*DATA DO VALOR LEVANTADO*/*/
/*	FROM BASE_RPT_FIM2 t1*/
/*		inner join igr.dependencias t2 on (put(t1.prefdep, z4.)=t2.prefdep)*/
/*			where t2.sb='00' and t1.cart <>0 and valor not in (., 0)*/
/*				order by t1.prefdep;*/
/*QUIT;*/
/**/
/*DATA PARA_BASE_CONEXAO;*/
/*SET PARA_BASE_CONEXAO_COMP PARA_BASE_CONEXAO_IND;*/
/*BY PREFDEP;*/
/*RUN;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE WORK.BASE_CONEXAO_CLI AS*/
/*		SELECT*/
/*			&IND as IND,*/
/*			1 as COMP,*/
/*			t1.PREFDEP,*/
/*			input (UOR, 10.) as UOR,*/
/*			cart as CTRA,*/
/*			cd_cli as CLI,*/
/*			&MESANO as MMAAAA,*/
/*			1 as VLR*/
/*		FROM BASE_ANALITICO_4_&anomes t1*/
/*			inner join igr.dependencias t2 on (put (t1.prefdep, z4.)=t2.prefdep)*/
/*				where t2.sb='00'*/
/*					and t1.MOBILE+t1.web > 0;*/
/*QUIT;*/
/**/
/*%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO);*/
/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CONEXAO_CLI);*/
/*%ExpCNX_IND_CMPS(&IND, 2018, MESES=&mes, ORC=0, RLZ=1);*/
/*%ExportarCNX_CLI(IND=&ind, MMAAAA=&MESANO);*/






x /dados/infor/producao/ind_uso_cn_virt;
x chmod 777 *;

x /dados/infor/producao/ind_uso_cn_virt;
x chmod 777 *.txt;
x /dados/infor/producao/ind_uso_cn_virt/dados_saida;
x chmod 777 *;

x cd /dados/infor/producao/ind_uso_cn_virt/dados_saida;
x chmod 777 *.txt; 




/**************************MPE********************************/
/**************************MPE********************************/
/**************************MPE********************************/
/**************************MPE********************************/
/**************************MPE********************************/


%let ind = 000000062;
%put &ind;

/*%BuscarOrcado(IND=&ind, MMAAAA=&mesano);

PROC SQL;
   CREATE TABLE WORK.ORCADOS AS 
   SELECT t1.ind, 
          t1.comp, 
          t1.prefdep, 
          t1.uor, 
          t1.ctra, 
          t1.mmaaaa, 
          t1.vlr_orc as valor
      FROM WORK.ORCADOS t1;
QUIT;
*/
PROC SQL;
   CREATE TABLE ind.orc_mpe_&anomes AS 
   SELECT distinct t1.TX_FON ,put (t1.CD_PRF, z4.) as prefdep, put(cd_uor, z9.) as uor,
          t1.CRTA as cart, 
          t1.VL as valor, 
          t1.ANOMES
      FROM AUX.VW_FON_153 t1
where t1.ANOMES=&anomes
and t1.TX_FON='3153'
and t1.cd_uor ne .
and TTL=1
order by 2, 3;
QUIT;

PROC SQL;
   CREATE TABLE ind.orc_mpe_&anomes AS 
   SELECT distinct t1.TX_FON, 
          t1.uor, 
          t1.cart, 
          t1.valor, 
          t1.ANOMES, 
          t2.PrefDep
      FROM ind.orc_mpe_&anomes t1
           INNER JOIN IGR.DEPENDENCIAS t2 ON (t1.uor = t2.UOR);
QUIT;


proc sql; 
    CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
    CREATE TABLE PGT00007 as 
	         SELECT * FROM CONNECTION TO DB2

		(select 
			a.cd_cli, 
			a.cd_tip_cnl,
			a.cd_tran_inro_sis,
			a.ts_inro_cli
		from db2bic.aux_inro_cli_atu a
				where a.cd_tran_inro_sis='PGT00007'
);
 
quit;


PROC SQL;
   CREATE TABLE IND.AUX_CD_TIP_2 AS 
   SELECT distinct t1.CD_CLI, 
          t1.CD_TIP_CNL, 
          t1.CD_TRAN_INRO_SIS, 
          t1.TS_INRO_CLI,
		  t1.VL_INRO_CLI
      FROM AUX_CD_TIP t1 INNER JOIN IND.TRANSACOES_CANAIS_PJ_201701 t2 ON (t1.CD_TRAN_INRO_SIS = t2.CD_TRAN_INRO_SIS)
      ;
QUIT;

proc sql;
create table IND.AUX_CD_TIP_2 as 
select * from IND.AUX_CD_TIP_2
union
select * from PGT00007;
quit;


PROC SQL;
   CREATE TABLE WORK.ENCARTEIRADOS_MPE AS 
   SELECT t1.CD_CLI, 
          put (t1.CD_PRF_DEPE,z4.) as prefdep, 
          ifn (t1.CD_TIP_CTRA not in (303, 315, 321, 322, 323, 324, 328, 337) or t1.CD_TIP_CTRA=.,700,t1.CD_TIP_CTRA) as tp_cart, 
          ifn (t1.CD_TIP_CTRA not in (303, 315, 321, 322, 323, 324, 328, 337) or t1.CD_TIP_CTRA=.,7002,t1.NR_SEQL_CTRA) as cart
      FROM COMUM.pai_rel_pj_&ANOMES t1
      where CD_TIP_CTRA in (303, 304, 315, 321, 322, 324, 328, 337, 382)
  ;
QUIT;

PROC SQL;
   CREATE TABLE WORK.exclui_pbco AS 
   SELECT DISTINCT t1.mci
      FROM BCN.BCN_PJ t1
      WHERE t1.situ_conta_corrente_ttld_1 NOT = 1 OR t1.situacao_funcionamento NOT = 2;
QUIT;

proc sql;
create table ENCARTEIRADOS_MPE as
select t1.* ,
ifn (t2.mci=.,1,0) as pbco_alvo
from ENCARTEIRADOS_MPE t1
left join exclui_pbco t2 on (t1.cd_cli=t2.mci);
quit;


PROC SQL;
	CREATE TABLE NET_MOB_MPE AS
		SELECT 	A.PREFDEP, A.CD_CLI, A.TP_CART,
			A.CART,
			B.CD_TRAN_INRO_SIS AS CD_TRAN_SIS,
			IFN (B.CD_TIP_CNL IN(12, 15, 23, 25, 26) and pbco_alvo=1 and month(datepart(TS_INRO_CLI))=month(&diautil_d1), 1, 0) AS WEB,
			IFN (B.CD_TIP_CNL IN(19, 21, 24) and pbco_alvo=1 and month(datepart(TS_INRO_CLI))=month(&diautil_d1), 1, 0) AS MOBILE,
			datepart (TS_INRO_CLI) FORMAT ddmmyy10. AS DATA,
			a.pbco_alvo
		FROM ENCARTEIRADOS_MPE A
			LEFT JOIN IND.AUX_CD_TIP_2 B ON(A.CD_CLI=B.CD_CLI)
			
				ORDER BY 1, 2, 3;
QUIT;


PROC SQL;
	CREATE TABLE QTDE_WEB_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			COUNT (DISTINCT t1.CD_CLI) AS QTDE_CLI_WEB
		FROM WORK.NET_MOB_MPE t1
			WHERE t1.WEB = 1
				GROUP BY 1, 2, 3;
QUIT;

PROC SQL;
	CREATE TABLE QTDE_MOB_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			COUNT(DISTINCT t1.CD_CLI) AS QTDE_CLI_MOB
		FROM WORK.NET_MOB_MPE t1
			WHERE t1.MOBILE = 1
				GROUP BY 1, 2, 3;
QUIT;

PROC SQL;
	CREATE TABLE QTDE_MOB_WEB_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			COUNT(DISTINCT t1.CD_CLI) AS QTDE_CLI_MOB_WEB
		FROM WORK.NET_MOB_MPE t1
			WHERE t1.MOBILE = 1 OR T1.WEB=1
				GROUP BY 1, 2, 3;
QUIT;

PROC SQL;
	CREATE TABLE QTDE_NAO_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			COUNT(DISTINCT t1.CD_CLI) AS QTDE_CLI_NAO
		FROM WORK.NET_MOB_MPE t1
			WHERE t1.MOBILE =0 AND t1.WEB =0
				GROUP BY 1, 2, 3;
QUIT;

PROC SQL;
	CREATE TABLE QTDE_TOTAL_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			COUNT(DISTINCT t1.CD_CLI) AS TOTAL_CLI
		FROM WORK.NET_MOB_MPE t1
			GROUP BY 1, 2, 3;
QUIT;

PROC SQL;
	CREATE TABLE PBCO_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			t1.CD_CLI,
			PBCO_ALVO
		FROM WORK.NET_MOB_MPE t1
			;
QUIT;

PROC SQL;
	CREATE TABLE QTDE_PBCO_ALVO_MPE AS 
		SELECT DISTINCT t1.PREFDEP, T1.TP_CART,
			t1.CART, 
			SUM(t1.PBCO_ALVO) AS PBCO_ALVO
		FROM PBCO_MPE t1
			GROUP BY 1, 2, 3;
QUIT;






PROC SQL;
	CREATE TABLE ind.QTDES_MPE_&anomes AS 
		SELECT DISTINCT t1.PREFDEP, t1.TP_CART,
			t1.CART, 
			t2.QTDE_CLI_WEB, 
			t3.QTDE_CLI_MOB, 
			t4.QTDE_CLI_NAO,
			t1.TOTAL_CLI,
			t7.QTDE_CLI_MOB_WEB AS QTD_USO,
			t7.QTDE_CLI_MOB_WEB/T6.PBCO_ALVO*100 AS PERCENT,
			T6.PBCO_ALVO,
			0 as orc,
			0 as orc_qtd
	FROM WORK.QTDE_TOTAL_MPE t1 
		LEFT JOIN WORK.QTDE_WEB_MPE t2 ON (t1.PREFDEP = t2.PREFDEP) AND (T1.CART=T2.CART) AND (T1.TP_CART=T2.TP_CART)
		LEFT JOIN WORK.QTDE_MOB_MPE t3 ON (t1.PREFDEP = t3.PREFDEP) AND (T1.CART=T3.CART) AND (T1.TP_CART=T3.TP_CART)
		LEFT JOIN WORK.QTDE_NAO_MPE t4 ON (t1.PREFDEP = t4.PREFDEP) AND (T1.CART=T4.CART) AND (T1.TP_CART=T4.TP_CART)
	LEFT JOIN WORK.QTDE_PBCO_ALVO_MPE t6 ON (t1.PREFDEP = t6.PREFDEP) AND (T1.CART=T6.CART) AND (T1.TP_CART=T6.TP_CART)	
	LEFT JOIN WORK.QTDE_MOB_WEB_MPE t7 ON (t1.PREFDEP = t7.PREFDEP) AND (T1.CART=T7.CART) AND (T1.TP_CART=T7.TP_CART)
	/*left join orcados t5 on (t1.PREFDEP = put (t5.PREFDEP,z4.)) AND (T1.CART = T5.ctra)*/;
QUIT;
%ZERARMISSINGTABELA (ind.QTDES_MPE_&anomes);

DATA PUB.QTDES_MPE_&anomes;
SET IND.QTDES_MPE_&anomes;
RUN;

PROC SQL;
	CREATE TABLE FIM_AG_MPE AS 
		SELECT DISTINCT ifc (a.tipodep='01',a.PrefAgenc,f.prefdep) as prefdep,  0 as CART,
			SUM (F.QTDE_CLI_WEB) AS QTDE_CLI_WEB,
			SUM (F.QTDE_CLI_MOB) AS QTDE_CLI_MOB,
			SUM (F.QTDE_CLI_NAO) AS QTDE_CLI_NAO,
	       SUM (F.TOTAL_CLI) AS TOTAL_CLI,
		   SUM (F.QTD_USO) AS QTD_USO,		   
		   SUM (PBCO_ALVO) AS PBCO_ALVO,
		   calculated QTD_USO/calculated PBCO_ALVO*100 as percent,
		   sum (orc_qtd) as orc_qtd,
		   calculated orc_qtd/calculated PBCO_ALVO*100 as orc
		FROM ind.QTDES_MPE_&anomes F 
		inner join IGR.auxiliar_relatorios a on (f.prefdep=a.prefdep)
				WHERE F.PREFDEP Not in ("4777" "9940") /*and orc not in (., 0)*/
						
GROUP BY 1;
QUIT;


PROC SQL;
	CREATE TABLE FIM_GRV_MPE AS
		SELECT PrefGEREV AS PrefDep, 0 AS CART,
			SUM (F.QTDE_CLI_WEB) AS QTDE_CLI_WEB,
			SUM (F.QTDE_CLI_MOB) AS QTDE_CLI_MOB,
			SUM (F.QTDE_CLI_NAO) AS QTDE_CLI_NAO,
	       SUM (F.TOTAL_CLI) AS TOTAL_CLI,
		   SUM (F.QTD_USO) AS QTD_USO,		   
		   SUM (PBCO_ALVO) AS PBCO_ALVO,
		   calculated QTD_USO/calculated PBCO_ALVO*100 as percent,
		   sum (orc_qtd) as orc_qtd,
		   calculated orc_qtd/calculated PBCO_ALVO*100 as orc
		FROM FIM_AG_MPE f
			INNER JOIN IGR.AUXILIAR_RELATORIOS a ON(A.PrefDep=f.PrefDep)
				WHERE PrefGEREV NE "0000"
					GROUP BY 1
						ORDER BY 1;
QUIT;


PROC SQL;
	CREATE TABLE FIM_SUPER_MPE AS
		SELECT PrefSupER AS PrefDep, 0 AS CART,
			SUM (F.QTDE_CLI_WEB) AS QTDE_CLI_WEB,
			SUM (F.QTDE_CLI_MOB) AS QTDE_CLI_MOB,
			SUM (F.QTDE_CLI_NAO) AS QTDE_CLI_NAO,
	       SUM (F.TOTAL_CLI) AS TOTAL_CLI,
		   SUM (F.QTD_USO) AS QTD_USO,		   
		   SUM (PBCO_ALVO) AS PBCO_ALVO,
		   calculated QTD_USO/calculated PBCO_ALVO*100 as percent,
		   sum (orc_qtd) as orc_qtd,
		   calculated orc_qtd/calculated PBCO_ALVO*100 as orc
		FROM FIM_AG_MPE f
			INNER JOIN IGR.AUXILIAR_RELATORIOS a ON(A.PrefDep=f.PrefDep)
					GROUP BY 1
						ORDER BY 1;
QUIT;


PROC SQL;
	CREATE TABLE FIM_UEN_MPE AS
		SELECT PrefDIR AS PrefDep, 0 AS CART,
			SUM (F.QTDE_CLI_WEB) AS QTDE_CLI_WEB,
			SUM (F.QTDE_CLI_MOB) AS QTDE_CLI_MOB,
			SUM (F.QTDE_CLI_NAO) AS QTDE_CLI_NAO,
	       SUM (F.TOTAL_CLI) AS TOTAL_CLI,
		   SUM (F.QTD_USO) AS QTD_USO,		   
		   SUM (PBCO_ALVO) AS PBCO_ALVO,
		   calculated QTD_USO/calculated PBCO_ALVO*100 as percent,
		   sum (orc_qtd) as orc_qtd,
		   calculated orc_qtd/calculated PBCO_ALVO*100 as orc
		FROM FIM_AG_MPE f
			INNER JOIN IGR.AUXILIAR_RELATORIOS a ON(A.PrefDep=f.PrefDep)
					GROUP BY 1
						ORDER BY 1;
QUIT;



PROC SQL;
	CREATE TABLE FIM_VIVAR_MPE AS
		SELECT PREFVICE AS PrefDep, 0 AS CART,
			SUM (F.QTDE_CLI_WEB) AS QTDE_CLI_WEB,
			SUM (F.QTDE_CLI_MOB) AS QTDE_CLI_MOB,
			SUM (F.QTDE_CLI_NAO) AS QTDE_CLI_NAO,
	       SUM (F.TOTAL_CLI) AS TOTAL_CLI,
		   SUM (F.QTD_USO) AS QTD_USO,		   
		   SUM (PBCO_ALVO) AS PBCO_ALVO,
		   calculated QTD_USO/calculated PBCO_ALVO*100 as percent,
		   sum (orc_qtd) as orc_qtd,
		   calculated orc_qtd/calculated PBCO_ALVO*100 as orc
		FROM FIM_UEN_MPE f
			INNER JOIN IGR.AUXILIAR_RELATORIOS a ON(A.PrefDep=f.PrefDep)
					GROUP BY 1
						ORDER BY 1;
QUIT;

DATA BASE_mpe (drop= percent_cart qtd tp_cart);
SET ind.QTDES_MPE_&anomes FIM_AG_MPE FIM_GRV_MPE FIM_SUPER_MPE FIM_UEN_MPE FIM_VIVAR_MPE;
BY PREFDEP;
WHERE QTDE_CLI_WEB+QTDE_CLI_MOB+QTDE_CLI_NAO+TOTAL_CLI NOT IN (., 0);
if prefdep ne '9940' /*and orc <> .*/;
RUN;

%ZERARMISSINGTABELA (WORK.BASE_MPE);


DATA BASE_1_mpe (drop= ts estilo governo codsitdep acordoreduzido);
	MERGE IGR.AUXILIAR_RELATORIOS BASE_MPE;
		;

	BY PrefDep;
RUN;

%ZERARMISSINGTABELA (WORK.BASE_1_mpe);

DATA BASE_RPT_FIM_mpe (drop=prefagenc);
	SET BASE_1_mpe;

	IF CART NE 0 THEN
		DO;	
			PrefPai=Prefdep;
			TipoDep='89';
			NivelDep='0';
		END;
			WHERE QTDE_CLI_WEB+QTDE_CLI_MOB+QTDE_CLI_NAO+TOTAL_CLI NOT IN (., 0);

RUN;
%ZERARMISSINGTABELA (WORK.BASE_RPT_FIM_mpe);

PROC SQL;
   CREATE TABLE ind.BASE_RPT_FIM_MPE_1 AS 
   SELECT &diautil_d1 format yymmdd10. as posicao,
t1.PrefPai, 
          t1.PrefVice, 
          t1.PrefDir, 
          t1.PrefSuper, 
          t1.PrefGerev, 
          t1.PrefRede, 
          t1.NivelDep, 
          t1.TipoDep, 
          input (t1.PrefDep, 4.) as prefdep,
          t1.NomeDep, 
          t1.EN, 
          t1.cart, 
          t1.QTDE_CLI_WEB, 
          t1.QTDE_CLI_MOB, 
          t1.QTDE_CLI_NAO, 
          t1.TOTAL_CLI, 
          t1.QTD_USO, 
		  t1.orc as valor,
		  T1.ORC_QTD,
          t1.PERCENT,
		  t1.percent/t1.orc*100 as percent_atg,
		  T1.PBCO_ALVO
      FROM WORK.BASE_RPT_FIM_MPE t1
inner join igr.auxiliar_relatorios t4 on (t1.prefdep = t4.prefdep)
			where codsitdep = '2';
QUIT;

PROC SQL;
   CREATE TABLE BASE_RPT_FIM_MPE_9940 AS 
   SELECT &diautil_d1 format yymmdd10. as posicao,
t1.PrefPai, 
          t1.PrefVice, 
          t1.PrefDir, 
          t1.PrefSuper, 
          t1.PrefGerev, 
          t1.PrefRede, 
          t1.NivelDep, 
          t1.TipoDep, 
          input (t1.PrefDep, 4.) as prefdep,
          t1.NomeDep, 
          t1.EN, 
          t1.cart, 
          t1.QTDE_CLI_WEB, 
          t1.QTDE_CLI_MOB, 
          t1.QTDE_CLI_NAO, 
          t1.TOTAL_CLI, 
          t1.QTD_USO, 
		  0 as valor,
		  0 AS ORC_QTD,
          t1.PERCENT,
		  0 as percent_atg,
		  T1.PBCO_ALVO
      FROM WORK.BASE_RPT_FIM_MPE t1
      WHERE (t1.PrefDep = '9940');
QUIT;

data BASE_RPT_FIM_MPE_1 (drop=prefpai prefvice prefdir prefsuper prefgerev prefrede niveldep tipodep nomedep mvto en);
set ind.BASE_RPT_FIM_MPE_1 BASE_RPT_FIM_MPE_9940;
run;

DATA GCN.CANAIS_PJ_&ANOMES;
SET ind.BASE_RPT_FIM_MPE_1;

RUN;








/*analitico*/
/*analitico*/
/*analitico*/
/*analitico*/

DATA BASE_ANALITICO_MPE;
SET NET_MOB_MPE;
RUN;



PROC SORT DATA=BASE_ANALITICO_MPE OUT=BASE_ANALITICO_MPE1 NODUPKEY; BY CD_CLI DATA; RUN;

PROC SQL;
   CREATE TABLE CLIENTES AS 
   SELECT t1.CD_CLI
      FROM WORK.BASE_ANALITICO_MPE1 t1;
QUIT;

DATA WEB_MPE MOB_MPE NAO_MPE LIXO_MPE;
SET BASE_ANALITICO_MPE1;
IF WEB=1 THEN OUTPUT WEB_MPE;
IF MOBILE=1 THEN OUTPUT MOB_MPE;
IF MOBILE=0 AND WEB=0 THEN OUTPUT NAO_MPE;
ELSE OUTPUT LIXO_MPE;
RUN;

DATA WEB_MPE; 
SET WEB_MPE;
BY CD_CLI;

	IF Last.CD_CLI THEN
		Seq=0;
	Seq+1;
	
RUN;

DATA MOB_MPE; 
SET MOB_MPE;
BY CD_CLI;

	IF Last.CD_CLI THEN
		Seq=0;
	Seq+1;
	
RUN;

DATA NAO_MPE; 
SET NAO_MPE;
BY CD_CLI;

	IF Last.CD_CLI THEN
		Seq=0;
	Seq+1;
	
RUN;


DATA WEB_MPE1; 
SET WEB_MPE(WHERE= (Seq = 1));
DROP SEQ;

RUN;

DATA MOB_MPE1; 
SET MOB_MPE(WHERE= (Seq = 1));
DROP SEQ;

RUN;

DATA NAO_MPE1; 
SET NAO_MPE(WHERE= (Seq = 1));
DROP SEQ;

RUN;

DATA BASE_ANALITICO_MPE2;
SET WEB_MPE1 MOB_MPE1 NAO_MPE1;
RUN;

PROC SORT DATA=BASE_ANALITICO_MPE2 OUT=BASE_ANALITICO_MPE3; BY CD_CLI; RUN;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_BASE_ANALITICO_MPE3 AS 
   SELECT t1.PrefDep, 
             t1.CART, 
          t1.CD_CLI, 
          IFN (SUM (t1.WEB)>1,1,SUM (t1.WEB)) AS WEB,
IFN (SUM (t1.MOBILE)>1,1,SUM (t1.MOBILE)) AS MOBILE ,
          
            (MAX(t1.DATA)) FORMAT=DDMMYY10. AS DATA
      FROM WORK.BASE_ANALITICO_MPE3 t1
GROUP BY 1,2,3 ;
QUIT;


PROC SQL;
   CREATE TABLE BASE_ANALITICO_4_MPE AS 
   SELECT distinct &diautil_d1 format yymmdd10. as posicao,
input(t1.PREFDEP, 4.) as prefdep,
t1.CART, 
          t1.CD_CLI, 
          t1.WEB, 
          t1.MOBILE, 
		  ifn (t1.MOBILE=1 or t1.web=1, 1, 0) AS uso, 
          t1.DATA format yymmdd10. AS DATA_formatada,
		  pbco_alvo
      FROM WORK.QUERY_FOR_BASE_ANALITICO_MPE3 t1
left join BASE_ANALITICO_MPE t2 on (t1.cd_cli=t2.cd_cli)
inner join igr.auxiliar_relatorios t4 on (t1.prefdep = t4.prefdep)
			where tipodep in ('01', '09') and codsitdep = '2';
QUIT;

data pub.canais_mpe_&anomes;
set BASE_ANALITICO_4_MPE;
run;


%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET Usuario=f8176496;
%LET Keypass=6BNV6H1MLV7JFXP52343IB6KSJGDT2ND3;

PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('BASE_RPT_FIM_MPE_1', 'pj-uso-canais-virtuais-20172');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('BASE_ANALITICO_4_MPE', 'clientes');
QUIT;

%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);






/*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*/               /*|\    |  ||||| \    /  |||||*/                /*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*/               /*|  \  |  |   |  \  /   |   |*/                /*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*/               /*|    \|  |||||   \/    |||||*/                /*NOVO CONEXÃO 2018*/
/*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*//*NOVO CONEXÃO 2018*/



%put &ind;

/*PROC SQL;*/
/*	CREATE TABLE WORK.PARA_BASE_CONEXAO_IND AS*/
/*		SELECT*/
/*			&IND as ind, /*CODIGO INDICADOR*/*/
/**/
/*	0 as COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 as COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 as ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	input (UOR,9.) as uor,*/
/*	t1.PREFDEP,*/
/*	cart as CTRA,            */
/*	percent as VLR_RLZ, /*VALOR REALIZADO*/*/
/*	valor as VLR_ORC, /*VALOR ORÇADO*/*/
/**/
/*	0 as VLR_ATG, /*VALOR ATINGIMENTO, por padrão 0, enviar somente se o atingimento tiver regra de cálculo*/*/
/*	t1.posicao /*DATA DO VALOR LEVANTADO*/*/
/*	FROM ind.BASE_RPT_FIM_mpe_1 t1*/
/*		inner join igr.dependencias t2 on (put(t1.prefdep, z4.)=t2.prefdep)*/
/*			where t2.sb='00' and t1.cart <>0*/
/*				order by t1.prefdep;*/
/*QUIT;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE WORK.PARA_BASE_CONEXAO_COMP AS*/
/*		SELECT*/
/*			&IND as ind, /*CODIGO INDICADOR*/*/
/**/
/*	1 as COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	0 as COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	1 as ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/*/
/*	input (UOR,9.) as uor,*/
/*	t1.PREFDEP,*/
/*	cart as CTRA,            */
/*	percent as VLR_RLZ, /*VALOR REALIZADO*/*/
/*	valor as VLR_ORC, /*VALOR ORÇADO*/*/
/**/
/*	0 as VLR_ATG, /*VALOR ATINGIMENTO, por padrão 0, enviar somente se o atingimento tiver regra de cálculo*/*/
/*	t1.posicao /*DATA DO VALOR LEVANTADO*/*/
/*	FROM ind.BASE_RPT_FIM_mpe_1 t1*/
/*		inner join igr.dependencias t2 on (put(t1.prefdep, z4.)=t2.prefdep)*/
/*			where t2.sb='00' and t1.cart <>0*/
/*				order by t1.prefdep;*/
/*QUIT;*/
/**/
/*DATA PARA_BASE_CONEXAO;*/
/*SET PARA_BASE_CONEXAO_IND PARA_BASE_CONEXAO_COMP;*/
/*BY PREFDEP;*/
/*RUN;*/
/**/
/*PROC SQL;*/
/*	CREATE TABLE WORK.BASE_CONEXAO_CLI AS*/
/*		SELECT*/
/*			&IND as IND,*/
/*			1 as COMP,*/
/*			t1.PREFDEP,*/
/*			input (UOR, 10.) as UOR,*/
/*			cart as CTRA,*/
/*			cd_cli as CLI,*/
/*			&MESANO as MMAAAA,*/
/*			uso as VLR*/
/*		FROM WORK.BASE_ANALITICO_4_MPE t1*/
/*			inner join igr.dependencias t2 on (put(t1.prefdep, z4.)=t2.prefdep)*/
/*				where t2.sb='00'*/
/*					and pbco_alvo = 1*/
/*					and uso = 1;*/
/*QUIT;*/
/**/
/*%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO);*/
/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CONEXAO_CLI);*/
/*%ExportarCNX_CLI(IND=&ind, MMAAAA=&MESANO);*/
/*%ExpCNX_IND_CMPS(&IND, 2018, MESES=&mes, ORC=0, RLZ=1);*/



x cd /;
x cd /dados/infor/producao/ind_uso_cn_virt/dados_saida;
x chmod 777 *; /*ALTERAR PERMISÕES*/

x cd /;
x cd /dados/infor/producao/ind_uso_cn_virt;
x chmod 777 *; /*ALTERAR PERMISÕES*/
x cd /;
x cd /dados/externo/restrito;
x chmod 775 *; /*ALTERAR PERMISÕES*/

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
