* sas:run@sasanalitico;

* rentabilidade fundos rpps - 186;

Options
	nonotes
	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';


* Para buscar o orçado e realizado por MCI;
libname mcicart '/dados/gecen/interno/bases/rel/fotos'; 					* encarteiramento usado;
libname orcmci '/dados/externo/DIGOV/GECEN/indicadores'; 					* orçado usado;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';	* realizado usado;


* usado para buscar a data do conexao;
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';


/*
=================================
Buscando a posicao do conexao
=================================
*/
proc sql;
create table work.mapa as 
select 'posicao' as chave, md_dm1 as valor from datas.mapa_datas where md_data_ref = today();
quit;


/*
================================================
Orçado e Realizado por MCI
================================================
*/

* Buscando o orcado e o encarteiramento para o primeiro trimestre de 2019;
proc sql;
create table orcmci_526 as
select
a.cd_cli
,a.vl_orc format 12.2
,b.cd_prf_depe
,b.nr_seql_ctra
,a.aaaa
,a.mm
,cats(a.aaaa, '0' , a.mm) as anomes_tipo /* horrivel preciso corrigir */
from orcmci.ORC_FUNDOS_STPB_CLI_22019 a
left join mcicart.rel_atom_201907 b on a.cd_cli = b.cd_cli
where a.aaaa = year(date()) and mm in (7,8,9);
quit;


* adicionando o realizado na tabela anterior ;
proc sql;
create table aprc_mci as
select
a.cd_prf_depe as prefixo
,a.nr_seql_ctra as carteira
,a.cd_cli as mci
,a.vl_orc as orc
,b.rlz as rlz
,a.aaaa
,a.mm
,a.anomes_tipo
from orcmci_526 a
left join rlzmci.anlt_000000185_201907 b on a.cd_cli = b.cd_cli;
quit;


* putz melhorar isso pra exportar ;
proc sql;
create table aprc_mci_final as
select
prefixo
,carteira
,mci
,orc
,rlz
,anomes_tipo
from aprc_mci;
quit;

/*
==================================================================
Contabilizando clientes por carteira
==================================================================
*/
proc sql;
create table count_mci_carteira as
select
prefixo
,carteira
,anomes_tipo
,aaaa
,mm
,count(mci) as cli_qtd
,sum(case when missing(rlz) then 0 else 1 end) as cli_qtd_atg
from aprc_mci
group by 1, 2, 3, 4, 5;
quit;


* contabilizando o total por agencia;
proc sql;
create table count_mci_agencia as
select
prefixo
,0 as carteira
,anomes_tipo
,aaaa
,mm
,sum(cli_qtd) as cli_qtd
,sum(cli_qtd_atg) as cli_qtd_atg
from count_mci_carteira
group by 1, 2, 3, 4, 5;
quit;



* contabilizando os prefixos superiores;
proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table hierarquia as 
select 
	*
from connection to postgres (select * from dependencias.hierarquia) a;
quit;


proc sql;
create table count_mci_dep as
select 
b.superior as prefixo
,0 as carteira
,a.aaaa
,a.mm
,sum(cli_qtd) as cli_qtd
,sum(cli_qtd_atg) as cli_qtd_atg
from count_mci_agencia a
left join hierarquia b on b.agencia = a.prefixo
where  b.superior <> a.prefixo
group by 1 , 2 , 3 , 4;
quit;


* junatando todos;
proc sql;
create table count_mci as 

select
prefixo
,carteira
,aaaa as aa_aprc
,mm as mm_aprc
,cli_qtd
,cli_qtd_atg
from count_mci_carteira

union all

select 
prefixo
,carteira
,aaaa as aa_aprc
,mm as mm_aprc
,cli_qtd
,cli_qtd_atg
from count_mci_agencia

union all 

select
prefixo
,carteira
,aaaa as aa_aprc
,mm as mm_aprc
,cli_qtd
,cli_qtd_atg
from count_mci_dep;
quit;


/*
================================================
Orçado e Realizado por Carteira e Agencia
================================================
*/
proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table dados_dep as 
select * from connection to db2 (
	SELECT
		b.CD_DEPE_UOR
		,a.NR_SEQL_CTRA
		,a.VL_META_IN_MBZ
		,a.VL_RLZD_IN_MBZ
		,a.PC_ATGT_IN_MBZ
		,a.VL_ACM_META_IN
		,a.VL_ACM_RLZD_IN
		,a.PC_ATGT_ACM_IN_MBZ
		,a.aa_aprc
		,a.mm_aprc
	FROM DB2ATB.VL_APRD_IN_MBZ_MM a
	LEFT JOIN DB2UOR.UOR b ON a.CD_UOR_CTRA = b.CD_UOR
	WHERE 
		cd_in_mbz = 185 
		and aa_aprc = year(CURRENT_DATE) 
		and mm_aprc = month(CURRENT_DATE);
) a;
quit;




* sumarizando por dependencia os elegiveis e que atingiram o realizado ;
proc sql;
create table aprc_dep as
select 
	(select valor from mapa where chave = 'posicao') as posicao
	,CD_DEPE_UOR
	,NR_SEQL_CTRA
	,VL_META_IN_MBZ
	,VL_RLZD_IN_MBZ
	,PC_ATGT_IN_MBZ
	,VL_ACM_META_IN
	,VL_ACM_RLZD_IN
	,PC_ATGT_ACM_IN_MBZ
	,cli_qtd
	,cli_qtd_atg
from dados_dep a
left join count_mci b on a.CD_DEPE_UOR = b.prefixo and a.NR_SEQL_CTRA = b.carteira and a.aa_aprc = b.aa_aprc and a.mm_aprc = b.mm_aprc
where 
	a.aa_aprc = b.aa_aprc 
and a.mm_aprc = b.mm_aprc;
quit;


proc sql;
create table anomes as
select distinct
cats(a.aaaa, '0' , a.mm) as id /* horrivel preciso corrigir */
,cats(a.aaaa, '-0' , a.mm) as descricao /* horrivel preciso corrigir */
from orcmci.ORC_FUNDOS_STPB_CLI_22019 a
where a.aaaa = year(date()) and mm in (7,8,9);
quit;


%LET Keypass=rentabilidade-de-fundos-setor-publico-2019-2-8lSR6PJOQ7HRoomoHLKEYjXewMhAfWPNDlRgp4SJXAD3KljhDy;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
  INSERT INTO EXPTROTINAS VALUES('work.aprc_dep', 'rentabilidade-de-fundos-setor-publico-2019-2');
  INSERT INTO EXPTROTINAS VALUES('work.aprc_mci_final', 'clientes');
  INSERT INTO EXPTROTINAS VALUES('work.anomes', 'anomes');
QUIT;


%ProcessoCarregarEncerrar(EXPTROTINAS);

