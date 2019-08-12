* sas:run@sasanalitico;

Options	nonotes	nosource;


* crio tabela com apuracao verticalizado por mes ;
* TODO os meses anteiores deveriam ser rodados apenas no dia 15 mes corrente ;


libname orcmci '/dados/externo/DIGOV/GECEN/indicadores';                                      * fonte do orcado por mci ;
libname encart '/dados/gecen/interno/bases/rel/fotos'; 				                          * fonte do encarteiramento ;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';                      * fonte do realizado;
*libname rlzinfor'/dados/divar/gerexresultad/gerinfor/interno/799_clientes_atg_mc';



* pegando apuracao para julho ;
proc sql;
create table rlz_201907 as 
select
b.CD_PRF_DEPE as prefixo
,b.NR_SEQL_CTRA_ATB as carteira
,a.cd_cli as mci
,a.vl_orc as orc
,c.mg_rlz as rlz
,((c.mg_rlz/a.vl_orc))*100 as atg
,a.MM
,a.AAAA
,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
from orcmci.orc_mci_mc_22019 a
left join encart.rel_atom_201907 b on a.cd_cli = b.cd_cli
left join rlzmci.anlt_000000277_201907 c on a.cd_cli = c.cd_cli
where a.mm = 7 and a.aaaa = 2019;
quit;



* pegando apuracao para agosto ;
proc sql;
create table rlz_201908 as 
select
b.CD_PRF_DEPE as prefixo
,b.NR_SEQL_CTRA_ATB as carteira
,a.cd_cli as mci
,a.vl_orc as orc
,c.mg_rlz as rlz
,((c.mg_rlz/a.vl_orc))*100 as atg
,a.MM
,a.AAAA
,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
from orcmci.orc_mci_mc_22019 a
left join encart.rel_atom_201908 b on a.cd_cli = b.cd_cli
left join rlzmci.anlt_000000277_201908 c on a.cd_cli = c.cd_cli
where a.mm = 8 and a.aaaa = 2019;
quit;





* pegando apuracao para setembro ;
* TODO na virada do mes substituir prefixo e carteira pelo arquivo do mes e adicionar o join do realizado ;
proc sql;
create table rlz_201909 as 
select
b.CD_PRF_DEPE as prefixo
,b.NR_SEQL_CTRA_ATB as carteira
,a.cd_cli as mci
,a.vl_orc as orc
,0 as rlz
,0 as atg
,a.MM
,a.AAAA
,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
from orcmci.orc_mci_mc_22019 a
left join encart.rel_atom_201908 b on a.cd_cli = b.cd_cli
/*left join rlzmci.anlt_000000277_201909 c on a.cd_cli = c.cd_cli*/
where a.mm = 9 and a.aaaa = 2019;
quit;



LIBNAME PGLIB postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='margem_gerencial';
proc sql;
drop table PGLIB.aprc_mci_mc_2019S2;
create table PGLIB.aprc_mci_mc_2019S2 as
select * from rlz_201907
union all 
select * from rlz_201908
union all
select * from rlz_201909;
quit;



