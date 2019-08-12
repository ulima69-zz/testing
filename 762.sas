* sas:run@sasanalitico;

Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';


libname mcicart '/dados/gecen/interno/bases/rel/fotos'; 	* DIGOV quer que use esse encarteiramento ;
libname orcmci  '/dados/externo/DIGOV/GECEN/indicadores'; 	* O orçado por MCI vem dessa fonte;
LIBNAME deps postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='dependencias';
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';
LIBNAME rel postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='rel';



proc sql inobs=1000;
select * from orcmci.p_alvo_desc_mais_22019;
quit;

libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';	* realizado usado;


/* tabela desconcentra mais orcado vindo do db2 */
proc sql;
create table work.mapa as 
select 'posicao' as chave, md_dm1 as valor from datas.mapa_datas where md_data_ref = today();
quit;


/*
proc sql outobs=100;
select * from orcmci.PRD_DESC_MAIS_22019;
quit;

proc sql;
create table mcis as
select distinct cd_cli, aaaa, mm from orcmci.PRD_DESC_MAIS_22019
union 
select distinct cd_cli, aaaa, mm from rlzmci.anlt_000000187_2019&mes_usado;
quit;
*/

proc sql  outobs=100;
select * from rlzmci.anlt_000000276_201908;
quit;





* === Buscando orçado para carteiras e agências, gerevs e supers;
proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table orc as 
select 
	(select valor from mapa where chave = 'posicao') as posicao
	,cd_depe_uor 	as prefixo
	,nr_seql_ctra 	as carteira
	,vl_meta_in_mbz as vl_orcd
	,vl_rlzd_in_mbz as vl_rlzd
	,vl_acm_meta_in as vl_orcd_acum
	,vl_acm_rlzd_in as vl_rlzd_acum
	,0 				as qnt_cli
	,0 				as qnt_cli_enc
	,0 				as qnt_cli_rlz
	,0 				as qnt_cli_orc
	,0 				as orc
	,0 				as rlz
	,pc_atgt_in_mbz as atg
from connection to db2 (
	SELECT
		a.dt_psc
		,b.cd_depe_uor
		,a.nr_seql_ctra
		,a.vl_meta_in_mbz
		,a.vl_acm_meta_in
		,a.vl_rlzd_in_mbz
		,a.vl_acm_rlzd_in
		,a.pc_atgt_in_mbz
		,a.pc_atgt_acm_in_mbz
	FROM DB2ATB.VL_APRD_IN_MBZ_MM a
	left join DB2UOR.uor b on a.cd_uor_ctra = b.cd_uor
	WHERE 
		a.AA_aprc = year(current_date) 
	and a.MM_aprc = month(current_date)
	and a.cd_in_mbz = 276;
) a;
quit;




proc sql;
CREATE TABLE WORK.desc_mais AS
SELECT 
	today()        as posicao, 
	dbh_prefixo    as prefixo, 
	0 as carteira, 
	0 as vl_orcd, 
	0 as vl_rlzd, 
	0 as vl_orcd_acum, 
	0 as vl_rlzd_acum, 
	0 as qnt_cli, 
	0 as qnt_cli_enc, 
	0 as qnt_cli_rlz, 
	0 as qnt_cli_orc, 
	0 as orc, 
	0 as rlz, 
	0 as atg 
FROM deps.dependencias dependencias
WHERE dependencias.dbh_diretoria IN (9220, 9270)
GROUP BY 1, 2, 3;
quit;

PROC SQL;
create table WORK.desc_mais_cli as
SELECT 
	dep.prefixo  as prefixo, 
	dep.carteira as carteira, 
	0 as mci, 
	0 as vl_orcd, 
	0 as vl_rlzd, 
	0 as vl_orcd_acum, 
	0 as vl_rlzd_acum, 
	0 as cli_vld, 
	0 as cli_rlz, 
	201907 as aaaamm_tipo 
FROM
(
  SELECT * FROM (SELECT prefixos.dbh_prefixo as prefixo, carts.c_num_carteira as carteira
                 FROM deps.dependencias prefixos
                 INNER JOIN deps.carteiras carts ON carts.c_prefixo = prefixos.dbh_prefixo
                 LEFT JOIN rel.tipo_carteira tipcart on tipcart.id = carts.c_tipo_carteira
                 WHERE
                   prefixos.dbh_tipo_dep IN(13,65,15,35,34,17) and prefixos.dbh_diretoria  in (9220, 9270, 8477, 9500, 8592 )
                 ) d
) dep;
quit;

proc sql;
create table WORK.desc_mais_prod as
SELECT 
dep.prefixo  as prefixo, 
dep.carteira as carteira, 
0 as mci, 
0 as cd_prd, 
0 as cd_mdld, 
0 as vlr_mg_rlz, 
201907 as aaaamm_tipo 
FROM
(
  SELECT * FROM (SELECT prefixos.dbh_prefixo as prefixo, carts.c_num_carteira as carteira
                 FROM deps.dependencias prefixos
                 INNER JOIN deps.carteiras carts ON carts.c_prefixo = prefixos.dbh_prefixo
                 LEFT JOIN rel.tipo_carteira tipcart on tipcart.id = carts.c_tipo_carteira
                 WHERE
                   prefixos.dbh_tipo_dep IN(13,65,15,35,34,17) and prefixos.dbh_diretoria  in (9220, 9270, 8477, 9500, 8592 )
                 ) d
) dep;
QUIT;

/* melhorar isso usar o comando data */
proc sql;
create table work.aaaamm as
select 
201906 as id
, '06-2019' as descricao
from deps.carteiras
union all 
select 
201907 as id
, '07-2019' as descricao
from deps.carteiras
;
quit;

%LET Keypass=desconcentra-mais-BlLPN7Zcuqla6HQBSI9kyWCpoFvLiWGW8t0XAURyk1Fe7BVQry;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
    INSERT INTO EXPTROTINAS VALUES('work.orc', 'desconcentra-mais');
    INSERT INTO EXPTROTINAS VALUES('work.desc_mais_cli', 'clientes');
    INSERT INTO EXPTROTINAS VALUES('work.desc_mais_prod', 'produtos');
	INSERT INTO EXPTROTINAS VALUES('work.aaaamm', 'aaaamm');
QUIT;

%ProcessoCarregarEncerrar(EXPTROTINAS);