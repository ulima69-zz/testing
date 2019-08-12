* sas:run@sasanalitico;

/*
Clientes que atingiram MC
Indicador: 277
*/

Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';

libname orcmci '/dados/externo/DIGOV/GECEN/indicadores';
*LIBNAME DB2ATB DB2 DATABASE=bdb2p04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SDRED;
*LIBNAME deps postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='dependencias';
*LIBNAME rel postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='rel';



proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table clientes as 
select * from connection to postgres (
	select 
	prefixo
	, carteira
	, mci
	, orc
	, rlz
	, atg
	, anomes 
	from margem_gerencial.aprc_mci_mc_2019s2;
) a;
quit;




proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table carteiras as 
select * from connection to db2 (
	SELECT
		b.cd_depe_uor as prefixo
		,a.nr_seql_ctra as carteira
		,a.vl_meta_in_mbz as orc
		,a.vl_rlzd_in_mbz as rlz
		,a.pc_atgt_in_mbz as atg
	FROM DB2ATB.VL_APRD_IN_MBZ_MM a
	left join DB2UOR.uor b on a.cd_uor_ctra = b.cd_uor
	WHERE 
		a.AA_aprc = year(current_date) 
	and a.MM_aprc = month(current_date)
	and a.cd_in_mbz = 277
) a;
quit;




proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table hierarquia as 
select * from connection to postgres (
	select * 
	from dependencias.hierarquia;
) a;
quit;


proc sql;
create table dados_hierarquia as
select * from carteiras
union all
select
	superior       										as prefixo
	,0              									as carteira
	,sum(coalesce(orc, 0))								as orc
	,sum(coalesce(rlz, 0))								as rlz
	,(sum(coalesce(rlz,0))/sum(coalesce(orc,0)))*100	as atg
from carteiras a
left join hierarquia b on a.prefixo = b.agencia and carteira = 0
where b.superior <> b.agencia
group by 1, 2;
quit;




* usado para buscar a data do conexao;
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';

proc sql;
create table conx_pos as 
select md_dm1 as posicao from datas.mapa_datas where md_data_ref = today();
quit;





proc sql;
create table final as 
select * from conx_pos cross join dados_hierarquia;
quit;



proc sql;
create table anomes as
select distinct
 case when a.mm in (10,11,12) then cats(a.aaaa, a.mm)       else cats(a.aaaa, '0' , a.mm)  end as id        /* horrivel preciso corrigir */
,case when a.mm in (10,11,12) then cats(a.aaaa, '-' , a.mm) else cats(a.aaaa, '-0' , a.mm) end as descricao /* horrivel preciso corrigir */
from orcmci.orc_mci_mc_22019 a
where a.aaaa = year(date());
quit;


/*proc sql;
create table detalhe as 
select distinct ind from orcmci.meta_mci_encart_22019 order by ind asc;
quit;*/

/*
proc sql;
create table dep as
SELECT 
	prefixos.dbh_prefixo as prefixo, 
	carts.c_num_carteira as carteira
FROM 		deps.dependencias prefixos
INNER JOIN 	deps.carteiras carts ON carts.c_prefixo = prefixos.dbh_prefixo
LEFT JOIN 	rel.tipo_carteira tipcart on tipcart.id = carts.c_tipo_carteira
WHERE
	prefixos.dbh_tipo_dep IN(13,65,15,35,34,17) 
and prefixos.dbh_diretoria  in (9220, 9270, 8477, 9500, 8592);
quit;
*/

/*
proc sql;
select
a.preixo
,a.carteira
,b.vl_meta_in_mbz
,b.vl_rlzd_in_mbz
,b.pc_atgt_in_mbz
,b.dt_psc
from 		dep a
left join 	dados_mbz b on a.prefixo = b.cd_depe_uor and a.carteira = b.nr_seql_ctra
quit;
*/








%LET Keypass=gov-clientes-atg-mc-20192-Camj2pI4q0U21XZTGCFP7soAwaQ0y7OqWf1Hf00AlnwkOXrmiR;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
    INSERT INTO EXPTROTINAS VALUES('work.final', 'gov-clientes-atg-mc-20192');
    INSERT INTO EXPTROTINAS VALUES('work.clientes', 'clientes');
    INSERT INTO EXPTROTINAS VALUES('work.anomes', 'anomes');
QUIT;

%ProcessoCarregarEncerrar(EXPTROTINAS);
