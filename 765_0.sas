* sas:run@sasanalitico;

Options	nonotes	nosource;


* crio tabela com orcado e realizado verticalizado por mes ;


libname orcmci '/dados/externo/DIGOV/GECEN/indicadores';                                      * fonte do orcado por mci ;
libname encart '/dados/gecen/interno/bases/rel/fotos'; 				                          * fonte do encarteiramento ;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';                      * fonte do realizado;
libname rlzinfor'/dados/divar/gerexresultad/gerinfor/interno/765_dj_trabalhista_gov';



* descobrir como fazer isso dinamico ;
proc sql;
create table rlz_vertical_201907 as
select
b.CD_PRF_DEPE
,b.NR_SEQL_CTRA_ATB as NR_SEQL_CTRA
,a.CD_CLI
,VL_ORC
,VLR_RLZD
,(VLR_RLZD/VL_ORC)*100 as ATG
,a.MM
,a.AAAA
,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
from orcmci.ORC_DIRECIONADOR_DJ_TRAB_22019 a
left join encart.rel_atom_201907           b on a.cd_cli = b.cd_cli
left join rlzmci.anlt_000000266_201907     c on a.cd_cli = c.mci
where a.mm = 7 and a.aaaa = 2019
;
quit;





proc sql;
create table rlz_vertical_201908 as
select
b.CD_PRF_DEPE
,b.NR_SEQL_CTRA_ATB as NR_SEQL_CTRA
,a.CD_CLI
,VL_ORC
,VLR_RLZD
,(VLR_RLZD/VL_ORC)*100 as ATG
,a.MM
,a.AAAA
,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
from orcmci.ORC_DIRECIONADOR_DJ_TRAB_22019 a
left join encart.rel_atom_201908           b on a.cd_cli = b.cd_cli
left join rlzmci.anlt_000000266_201908     c on a.cd_cli = c.mci
where a.mm = 8 and a.aaaa = 2019
;
quit;





* se eu lancar o mes futuro que encarteiramento eu irei usar? ;
/*proc sql;
create table rlz_vertical_201908 as
select
b.CD_PRF_DEPE
,b.NR_SEQL_CTRA_ATB as NR_SEQL_CTRA
,a.CD_CLI
,VL_ORC
,VLR_RLZD
,(VLR_RLZD/VL_ORC)*100 as ATG
,a.MM
,a.AAAA
,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
from orcmci.ORC_DIRECIONADOR_DJ_TRAB_22019 a
left join encart.rel_atom_201908           b on a.cd_cli = b.cd_cli
left join rlzmci.anlt_000000266_201908     c on a.cd_cli = c.mci
where a.mm = 8 and a.aaaa = 2019
;
quit;*/




proc sql;
create table rlzinfor.rlz_vertical as 
select * from rlz_vertical_201907
union all
select * from rlz_vertical_201908;
quit;




/*
proc sql;
create table orc_vertical_201909
select * from rlzmci.anlt_000000266_20190;
quit;


proc sql;
create table orc_vertical_201910
select * from rlzmci.anlt_000000266_20190;
quit;


proc sql;
create table orc_vertical_201911
select * from rlzmci.anlt_000000266_20190;
quit;


proc sql;
create table orc_vertical_201912
select * from rlzmci.anlt_000000266_20190;
quit;

*/