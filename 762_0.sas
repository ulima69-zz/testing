* sas:run@sasanalitico;




/*
Em que pé que tá??

Adicionar a visão de mci: contabilizar os clientes que 3 ou mais produtos em MGCT_OPR_PJTD

*/


Options	nonotes	nosource;


*;

LIBNAME PGLIB postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='margem_gerencial';
* buscando o realizado projetado;
proc sql;
* drop table PGLIB.r803_rlz_201907;

connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SGCEN);
EXECUTE (SET CURRENT QUERY ACCELERATION ENABLE) BY DB2;
create table PGLIB.r803_rlz_201908 as 
select * from connection to db2 (
	with datas as( 
		select day(DATA_ANT_1) as dia from DB2MIS.IADD_MAPA_DT where DATA_REF = current_date
	)
	SELECT
		CD_CLI
		,CD_PRD 
		,CD_MDLD
		,CD_DEPE
		,sum(VL_MGCT_SEM_RSCO) as VL_MGCT_SEM_RSCO
	FROM DB2REN.MGCT_OPR_PJTD a		
	WHERE 
		a.AA_APRC = year(current_date)
		and a.MM_APRC = 8
		and a.DD_APRC = (select dia from datas)
		and a.CD_DEPE in (select prefixo from DB2I0469.AGENCIAS_GOVERNO)
		and cd_cli in (select cd_cli from DB2I0469.R803_PUBLICO_ALVO where mm_aprc = 8 and aa_aprc = 2019)
		group by CD_CLI
		,CD_PRD 
		,CD_MDLD
		,CD_DEPE;
;
) a;
quit;
*;


* crio tabela com orcado e realizado verticalizado por mes ;


libname orcmci '/dados/externo/DIGOV/GECEN/indicadores';                                      * fonte do orcado por mci ;
libname encart '/dados/gecen/interno/bases/rel/fotos'; 				                          * fonte do encarteiramento ;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';                      * fonte do realizado;
libname rlzinfor'/dados/divar/gerexresultad/gerinfor/interno/762_desconcentra_mais';


*orcado = prd_desc_mais_22019;

*anlt_000000276_201907;


proc sql;
select 
* 
from ;
quit;




LIBNAME db2ren DB2 DATABASE=bdb2p04 SCHEMA=DB2I0469 AUTHDOMAIN=DB2SDRED;
proc sql;
insert into DB2I0469.PUBLICO_ALVO
select 
	mci, 762, 0, 0, 0, '', ''
INSERT INTO DB2I0469.PUBLICO_ALVO (IDENTIFICADOR1, IDENTIFICADOR2, TIPO_PUBLICO, NUMERAL1, NUMERAL2, TEXTO, POSICAO) VALUES(0, 0, 0, 0, 0, '', '');

quit;



*p_alvo_desc_mais_22019;

LIBNAME db2ren DB2 DATABASE=bdb2p04 SCHEMA=db2ren AUTHDOMAIN=DB2SGCEN;

proc sql outobs=100;
select * from db2ren.MGCT_OPR_PJTD where cd_cli = 514605393 and aa_aprc = 2019 and mm_aprc = 8 and dd_aprc = 1;
quit;


proc sql inobs=100;
select * from orcmci.P_ALVO_DESC_MAIS_22019;
quit;




* descobrir como fazer isso dinamico ;
proc sql;
create table aprc_vertical_201907 as
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
from orcmci.p_alvo_desc_mais_22019 a
left join encart.rel_atom_201907           b on a.cd_cli = b.cd_cli
left join rlzmci.anlt_000000276_201907     c on a.cd_cli = c.mci
where a.mm = 7 and a.aaaa = 2019
;
quit;





proc sql;
create table aprc_vertical_201908 as
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