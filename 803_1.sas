* sas:run@sasanalitico;

Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';


*libname encart '/dados/gecen/interno/bases/rel/fotos'; 				
libname orcmci '/dados/externo/DIGOV/GECEN/indicadores'; 
*libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';
libname rlzinfor'/dados/divar/gerexresultad/gerinfor/interno/803_mc_sem_risco';
*LIBNAME DB2ATB DB2 DATABASE=bdb2p04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SDRED;
*LIBNAME deps postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='dependencias';
*LIBNAME rel postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='rel';

%let mes = 8;


proc sql;
create table clientes as 
select
	prefixo
	,carteira
	,cd_cli
	,orc format=best20.5
	,rlz
	,atg
	,anomes
	,prefixo_rlz
from rlzinfor.r803_aprc_20192
where prefixo is not null;
quit;




* buscando os dados por carteira ;
* este indicador é acumulado. entao para ter o orcado, realizado mensal, subtraio do mes corrente o anterior;
proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table dados_carteira_src as 
select * from connection to db2 (
	WITH 
	info AS ( SELECT month(CURRENT_date) AS mes, 12120 AS indicador FROM DB2ATB.VL_APRD_IN_UOR a LIMIT 1)
	, ant AS (
		SELECT
			 a.CD_UOR_CTRA     as prefixo
			,a.NR_SEQL_CTRA   as carteira
			,a.VL_META_IN     AS orc
			,a.VL_RLZD_IN     AS rlz
			,a.PC_ATGT_IN     AS atg
		FROM DB2ATB.VL_APRD_IN_CTRA a
		where
				a.MM_VL_APRD_IN = (SELECT CASE WHEN mes IN (1 , 7) THEN mes ELSE (mes-1) end FROM info)
			and a.AA_VL_APRD_IN = YEAR(CURRENT_DATE)
			AND a.CD_IN_MOD_AVLC = (SELECT indicador FROM info)
	)
	, atu AS (
		SELECT
			 a.CD_UOR_CTRA     as prefixo
			,a.NR_SEQL_CTRA   as carteira
			,a.VL_META_IN     AS orc
			,a.VL_RLZD_IN     AS rlz
			,a.PC_ATGT_IN     AS atg
		FROM DB2ATB.VL_APRD_IN_CTRA a
		where
				a.MM_VL_APRD_IN = (SELECT mes FROM info)
			and a.AA_VL_APRD_IN = YEAR(CURRENT_DATE)
			AND a.CD_IN_MOD_AVLC = (SELECT indicador FROM info)
	)
	SELECT
			c.CD_DEPE_UOR	as prefixo
			,a.carteira
			,a.orc  AS orc_au
			,a.rlz	AS rlz_au
			,a.atg	AS atg_au
			,b.orc	AS orc_ant
			,b.rlz	AS rlz_ant
			,b.atg	AS atg_ant
		FROM atu a
		left JOIN ant b ON a.prefixo = b.prefixo AND a.carteira = b.carteira 
		LEFT JOIN DB2UOR.UOR c ON c.CD_UOR = a.prefixo;
) a;
quit;





proc sql;
create table dados_carteira_src as 
select 
	prefixo
	,carteira
	,(orc_atu-orc_ant) 							as orc
	,(rlz_atu-rlz_ant)							as rlz
	,(rlz_atu-rlz_ant)/(orc_atu-orc_ant)*100 	as atg
	,orc_atu as orc_acm							as orc_acm
	,rlz_atu as rlz_acm							as rlz_acm
	,atg_atu as atg_acm							as atg_acm
from dados_carteira_src;
quit;









* buscando os dados por agencia, regional e super ;
* este indicador é acumulado. entao para ter o orcado, realizado mensal, subtraio do mes corrente o anterior;
proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table dados_prefixo_src as 
select * from connection to db2 (
	WITH 
	info AS ( SELECT month(CURRENT_date) AS mes FROM DB2ATB.VL_APRD_IN_UOR a LIMIT 1)
	, ant AS (
		SELECT
			 a.CD_UOR 		AS prefixo
			,a.VL_META_IN 	AS orc
			,a.VL_RLZD_IN 	AS rlz
			,a.PC_ATGT_IN 	AS atg		
		FROM DB2ATB.VL_APRD_IN_UOR a		  
		where
				a.MM_VL_APRD_IN = (SELECT CASE WHEN mes IN (1 , 7) THEN mes ELSE (mes-1) end FROM info)  
			and a.AA_VL_APRD_IN = YEAR(CURRENT_DATE)
			AND a.CD_IN_MOD_AVLC IN (12119 , 12121 , 12187)
	)
	, atu AS (
		SELECT
			 a.CD_UOR 		AS prefixo		 
			,a.VL_META_IN 	AS orc
			,a.VL_RLZD_IN 	AS rlz
			,a.PC_ATGT_IN 	AS atg
		FROM DB2ATB.VL_APRD_IN_UOR a  
		where
				a.MM_VL_APRD_IN = (SELECT mes FROM info)  
			and a.AA_VL_APRD_IN = YEAR(CURRENT_DATE)
			AND a.CD_IN_MOD_AVLC IN (12119 , 12121 , 12187)
	)
	SELECT
		a.prefixo
		,c.CD_DEPE_UOR
		,a.orc AS orc_atu
		,a.rlz AS rlz_atu
		,a.atg AS atg_atu
		,b.orc AS orc_ant
		,b.rlz AS rlz_ant
		,b.atg AS atg_ant
	FROM atu a
	LEFT JOIN ant b ON a.prefixo = b.prefixo
	LEFT JOIN DB2UOR.UOR c ON c.CD_UOR = a.prefixo 
	;
) a;
quit;



proc sql;
create table dados_prefixo as 
select
	 CD_DEPE_UOR 								as prefixo
	,0 											as carteira
	,(orc_atu-orc_ant) 							as orc
	,(rlz_atu-rlz_ant)							as rlz
	,(rlz_atu-rlz_ant)/(orc_atu-orc_ant)*100 	as atg
	,orc_atu as orc_acm							as orc_acm
	,rlz_atu as rlz_acm							as rlz_acm
	,atg_atu as atg_acm							as atg_acm
from dados_prefixo_src;
quit;





proc sql;
create table dados as 
select * FROM dados_carteira
union all 
select * from dados_prefixo;
quit;


proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table conx_pos as 
select * from connection to postgres (
	select /*'2019-07-31'::date*/ md_dm2 as posicao from datas.mapa_datas where md_data_ref = current_date /*limit 1*/;
) a ;
quit;

* usado para buscar a data do conexao;
* LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';
/*
proc sql;
create table conx_pos as 
select md_dm2 as posicao from datas.mapa_datas where md_data_ref = today();
quit;
*/


proc sql;
create table final_posicao as 
select * from conx_pos cross join dados;
quit;



proc sql;
create table anomes as
select distinct
 case when a.mm in (10,11,12) then cats(a.aaaa, a.mm)       else cats(a.aaaa, '0' , a.mm)  end as id        /* horrivel preciso corrigir */
,case when a.mm in (10,11,12) then cats(a.aaaa, '-' , a.mm) else cats(a.aaaa, '-0' , a.mm) end as descricao /* horrivel preciso corrigir */
from orcmci.ORC_MCI_MC_22019 a
where a.aaaa = year(date());
quit;





%LET Keypass=mc-sem-risco-governo-2019-2-632IdZAJPOaWzD3PaCcaIj1tFfqomFGYEW98qox48yaBgxJ6Hh;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
    INSERT INTO EXPTROTINAS VALUES('work.final_posicao', 'mc-sem-risco-governo-2019-2');
    INSERT INTO EXPTROTINAS VALUES('work.clientes', 'clientes');
    INSERT INTO EXPTROTINAS VALUES('work.anomes', 'anomes');
	/*INSERT INTO EXPTROTINAS VALUES('work.aaaamm', 'aaaamm');*/
QUIT;

%ProcessoCarregarEncerrar(EXPTROTINAS);
