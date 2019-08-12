* sas:run@sasanalitico;

Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';

* Para buscar o orÃ§ado e realizado por MCI;
libname mcicart '/dados/gecen/interno/bases/rel/fotos'; 					* encarteiramento usado no orçado;
libname orcmci '/dados/externo/DIGOV/GECEN/indicadores'; 					* orÃ§ado usado;

libname rlzcart '/dados/externo/DIVAR/METAS/conexao/rel';					* encarteiramento usado no realizado;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';	* realizado usado;


* usado para buscar a data do conexao;
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';


proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table mapa as 
select
*
from connection to postgres (
	select posicao, extract(month from posicao)::int as mes from public.posicao where id = 'CON_MOB_DB2'; 
) a;
quit;


* START = BUSCANDO QUAL MES SERA USADO PARA O NOME DO ARQUIVO;
* pega mes corrente com dois digitos;
%macro mes_str();
   %let mes_corrente = %sysfunc(date(),month2.);
   %if &mes_corrente < 10 %then %sysfunc(cat(0, &mes_corrente)) ;
   %else &mes_corrente;
%mend mes_str;
%let messtr = %mes_str();
%put &messtr;

* busca o mes usado na posicao do conexao ;
proc sql noprint;
select mes
into :mes
from mapa;
quit;

%let mespos=;
data _null_;
  if "&mes" < 10  then call symput('mespos',cat(0, &mes));

  if "&mes" >= 10 then call symput('mespos',&mes);
run;

%put &mespos;


* seja existir arquivo para o mes atual usa, caso contrario usa o do mes da posicao ;
%macro checkfile(mes_corrente, mes_ant);
%if %sysfunc(fileexist("/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico/anlt_000000121_2019&mes_corrente")) %then &mes_corrente;  
%else &mes_ant;
%mend checkfile;

%let mes_usado = %checkfile(&messtr, &mespos);
%put "Resultado : &mes_usado";
* END = BUSCANDO QUAL MES SERA USADO PARA O NOME DO ARQUIVO;




* buscando todos os MCIs disponiveis no orcado e no realizado ;
proc sql;
create table mcis as
select distinct cd_cli, aaaa, mm from orcmci.ORC_RENTAB_CARTAO_22019
union 
select distinct cd_cli, aaaa, mm from rlzmci.anlt_000000187_2019&mes_usado;
quit;


* OrÃ§ado e Realizado por MCI;
* Buscando o orcado e o encarteiramento para o segundo semestre de 2019;
proc sql;
create table orcmci_538 as
select
z.cd_cli 			  as mci
,a.vl_orc format 12.2 as orc
,c.vl_mgct 			  as rlz
,b.cd_prf_depe		  as orc_prefixo
,b.nr_seql_ctra       as orc_carteira
,c.prefdep            as rlz_prefixo
,c.ctra               as rlz_carteira
,a.aaaa 			  as orc_aaaa
,a.mm 				  as orc_mm
,c.aaaa 			  as rlz_aaaa
,c.mm 			      as rlz_mm
,case 
	when a.vl_orc is not missing and a.mm in (10,11,12) then cats(a.aaaa, a.mm) 
    when a.vl_orc is not missing and a.mm not in (10,11,12) then cats(a.aaaa, '0' , a.mm) 
	when a.vl_orc is missing     and c.mm in (10,11,12) then cats(c.aaaa, c.mm) 
    when a.vl_orc is missing     and c.mm not in (10,11,12) then cats(c.aaaa, '0' , c.mm) 
	else ''
 end as anomes_tipo /* horrivel melhorar TODO */
from mcis z
left join mcicart.rel_atom_2019&mes_usado b on z.cd_cli = b.cd_cli /* busca o encarteiramento */
left join orcmci.ORC_RENTAB_CARTAO_22019 a on a.cd_cli = z.cd_cli and a.aaaa = z.aaaa and a.mm = z.mm	/* busca orcado */
left join rlzmci.anlt_000000187_2019&mes_usado c on z.cd_cli = c.cd_cli and z.aaaa = c.aaaa and z.mm = c.mm; /* busca realizado */
quit;


* ajustando o anomes para os mci ;
proc sql;
create table aprc_mci as
select
orc_prefixo   as prefixo
,orc_carteira as carteira
,mci
,orc
,rlz
,case when orc is missing then rlz_aaaa else orc_aaaa end as aaaa
,case when orc is missing then rlz_mm else orc_mm end as mm
,anomes_tipo 
from orcmci_538 a;
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

* Contabilizando clientes por carteira por ano mes pelo prefixo de orcamento;
proc sql;
create table count_mci_carteira as
select
prefixo
,carteira
,anomes_tipo
,aaaa
,mm
,count(mci) as cli_qtd
,sum(case when rlz is missing then 0 else 1 end) as cli_qtd_atg
from aprc_mci
group by 1, 2, 3, 4, 5;
quit;


* contabilizando o total por agencia por ano mes;
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



* contabilizando os o total de clientes para os prefixos superiores;
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


* junatando o sumarizados por carteira, agencia, gerev e super;
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


* busca orçado e realizado do conexão ;
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
		cd_in_mbz = 187
		and aa_aprc = year(CURRENT_DATE) 
		and mm_aprc = month(CURRENT_DATE);
) a;
quit;




* sumarizando por dependencia os elegiveis e que atingiram o realizado ;
proc sql;
create table aprc_dep as
select 
	(select posicao from mapa) as posicao
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
 case when a.mm in (10,11,12) then cats(a.aaaa, a.mm)       else cats(a.aaaa, '0' , a.mm)  end as id        /* horrivel preciso corrigir */
,case when a.mm in (10,11,12) then cats(a.aaaa, '-' , a.mm) else cats(a.aaaa, '-0' , a.mm) end as descricao /* horrivel preciso corrigir */
from orcmci.ORC_RENTAB_CARTAO_22019 a
where a.aaaa = year(date());
quit;


%LET Keypass=rentabilidade-cartoes-governo-zUBiTUHZ2oInEYwfRNf4I2pH098BZucwewLiKoVol8VPSD6cjf;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
  INSERT INTO EXPTROTINAS VALUES('work.aprc_dep', 'rentabilidade-cartoes-governo');
  INSERT INTO EXPTROTINAS VALUES('work.aprc_mci_final', 'clientes');
  INSERT INTO EXPTROTINAS VALUES('work.anomes', 'anomes');
QUIT;


%ProcessoCarregarEncerrar(EXPTROTINAS);

