* sas:run@sasanalitico;

Options	nonotes	nosource;


/************************************************************************************
Saida: tabela com a apuracao por MCI por mes

A tabela de apuracao tem: 
- orcado fornecido pela digov
- encarteiramento do realizado gecen, caso nao exista da atomizacao
- realizado do realizado gecen
*************************************************************************************/


libname orcmci '/dados/externo/DIGOV/GECEN/indicadores';                                      * fonte do orcado por mci ;
libname encart '/dados/gecen/interno/bases/rel/fotos'; 				                          * fonte do encarteiramento, caso nao exista no realizado;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';                      * fonte do realizado;
libname rlzinfor'/dados/divar/gerexresultad/gerinfor/interno/803_mc_sem_risco';


%let rlz201907 = "rlz_201907";


* O realizado esta vindo por produto entao sumarizo para ter por cliente ;
* cria tabela no work com a sumarizacao ;
%macro sum_rlz(tabela_in, tabela_out);
proc sql;
create table &tabela_out as
select
	a.CD_CLI
	,a.PREFDEP
	,a.CTRA
	,sum(a.VL_MGCT_SEM_RSCO) as rlz
from rlzmci.&tabela_in a
group by 
	a.CD_CLI
	,a.PREFDEP
	,a.CTRA;
quit;
%mend sum_rlz;


* junta o orcado e realizado;
* caso o nao exista prefixo para o mci no realizado, entao pego prefixo do orcado ;
%macro aprc(tabela_orc, tabela_encart, tabela_rlz, tabela_out, mes, ano);
	proc sql;
		create table &tabela_out. as
			select
				a.CD_CLI
				,case 
					when b.PREFDEP is null and b.CTRA is null then c.CD_PRF_DEPE 
					else b.PREFDEP 
				end as prefixo
				,case 
					when b.PREFDEP is null and b.CTRA is null then c.NR_SEQL_CTRA_ATB 
					else b.CTRA 
				end as carteira
				,a.VL_ORC				as orc
				,b.rlz 					as rlz
				,(b.rlz/a.VL_ORC)*100 	as atg
				,a.MM
				,a.AAAA
				,case when a.mm > 10 then cats(a.aaaa, a.mm) else cats(a.aaaa, '0' , a.mm)  end as anomes
				,case 
					when b.PREFDEP is null and b.CTRA is null then 0 
					else 1 
				end as prefixo_rlz				
			from &tabela_orc. a
			left join &tabela_encart. c on a.cd_cli = c.cd_cli
			left join &tabela_rlz. b on a.cd_cli = b.cd_cli
			where 
				a.mm = &mes. 
			and a.aaaa = &ano.
			;
 quit;
%mend aprc;


%let mes1=1;

%put %eval(&mes1+1);

* apurando julho ;
%sum_rlz(anlt_000000276_201907,rlz_201907);
%aprc(tabela_orc=orcmci.orc_mci_mc_22019, tabela_encart=encart.rel_atom_201907, tabela_rlz=rlz_201907, tabela_out=aprc_201907, mes=7, ano=2019);




* apurando agosto ;
%sum_rlz(anlt_000000276_201908,rlz_201908);
%aprc(tabela_orc=orcmci.orc_mci_mc_22019, tabela_encart=encart.rel_atom_201908, tabela_rlz=rlz_201908, tabela_out=aprc_201908, mes=8, ano=2019);





proc sql;
create table aprc_201909 as
select
	a.CD_CLI
	, case when b.PREFDEP is null and b.CTRA is null then c.CD_PRF_DEPE else b.PREFDEP end as prefixo
	, case when b.PREFDEP is null and b.CTRA is null then c.NR_SEQL_CTRA_ATB else b.CTRA end as carteira
	,a.VL_ORC	as orc
	,0 			as rlz
	,0			as atg
	,a.MM
	,a.AAAA
	,case 
		when a.mm > 10 then cats(a.aaaa, a.mm) 
		else cats(a.aaaa, '0' , a.mm)  
	end as anomes
	,case 
		when b.PREFDEP is null and b.CTRA is null then 0 
		else 1 
	end as prefixo as prefixo_rlz
from orcmci.orc_mci_mc_22019 a
left join encart.rel_atom_201908 c on a.cd_cli = c.cd_cli
left join rlzmci.anlt_000000276_201908 b on a.cd_cli = b.cd_cli
where 
	a.mm = 9 
and a.aaaa = 2019;
quit;



* LIBNAME PGLIB postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='margem_gerencial';
proc sql;
create table rlzinfor.r803_aprc_20192 as
select * from aprc_201907
union all
select * from aprc_201908
union all
select * from aprc_201909;
quit;


