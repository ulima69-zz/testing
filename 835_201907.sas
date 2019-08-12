* sas:run@sasanalitico;

*Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';

libname mcicart '/dados/gecen/interno/bases/rel/fotos'; 					* encarteiramento usado;
libname orcmci '/dados/externo/DIGOV/GECEN/indicadores'; 					* orÃ§ado usado;
libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';	* realizado usado;

* usado para buscar a data do conexao;
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';

/*proc sql;
create table mapa as 
select md_dm1 as posicao from datas.mapa_datas where md_data_ref = today();
quit;*/

*%let a1=;
*%let a2=;


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










proc sql;
create table mcis as 
select  distinct mci from orcmci.P_ALVO_CANAIS_DIGITAIS_22019;
quit;

/*
proc sql;
select count(*) from mcis;
quit;
*/

proc sql;
create table mci_visao as 
select
b.cd_prf_depe
,b.NR_SEQL_CTRA_ATB as NR_SEQL_CTRA
,mci
,RLZ_ASP
,RLZ_MOB
,PC_RLZ_ASP*100
,PC_RLZ_MOB*100
,RLZ
from mcis a
left join mcicart.rel_atom_2019&mes_usado b on a.mci = b.cd_cli
left join rlzmci.anlt_000000121_2019&mes_usado c on c.cd_cli = a.mci;
quit;



* sumarizando por carteira mcis por carteira;
/*proc sql;
create table mcis_sum_carteira as
select 
cd_prf_depe
,NR_SEQL_CTRA
,count(mci) as qtd_mci
,sum(RLZ_ASP) as RLZ_ASP
,sum(RLZ_MOB) as RLZ_MOB
from mci_visao a
group by 1,2;
quit;


proc sql;
create table mcis_sum_prefixo as
select
cd_prf_depe
,0 as NR_SEQL_CTRA
,sum(qtd_mci) as qtd_mci
,sum(RLZ_ASP) as RLZ_ASP
,sum(RLZ_MOB) as RLZ_MOB
from mcis_sum_carteira a;
quit;
*/


* buscando os valores para carteiras;
proc sql;
	connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
	create table carteiras as 
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
		FROM DB2ATB.VL_APRD_IN_MBZ_MM a
		LEFT JOIN DB2UOR.UOR b ON a.CD_UOR_CTRA = b.CD_UOR
		WHERE 
			cd_in_mbz = 121
			AND AA_APRC = year(CURRENT_DATE)
			AND MM_APRC = month(CURRENT_DATE);
	) a;
quit;


/*
proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table hierarquia as 
select 
	*
from connection to postgres (select * from dependencias.hierarquia) a;
quit;



proc sql;
create table dependencia_sum as
select 
b.superior as CD_DEPE_UOR
,0 as NR_SEQL_CTRA
,sum(VL_META_IN_MBZ) as VL_META_IN_MBZ
,sum(VL_RLZD_IN_MBZ) as VL_RLZD_IN_MBZ
,sum(VL_RLZD_IN_MBZ)/sum(VL_META_IN_MBZ) as PC_ATGT_IN_MBZ
,sum(VL_ACM_META_IN) as VL_ACM_META_IN
,sum(VL_ACM_RLZD_IN) as VL_ACM_RLZD_IN
,sum(VL_ACM_RLZD_IN)/sum(VL_ACM_META_IN) as PC_ATGT_ACM_IN_MBZ
from carteiras a
left join hierarquia b on b.agencia = a.CD_DEPE_UOR
where  b.superior <> a.CD_DEPE_UOR
group by 1 , 2;
quit;



proc sql;
create table dependencia_visao as
select * from carteiras
union all
select * from dependencia_sum;
quit;*/

proc sql;
create table final as 
select * from mapa cross join carteiras;
quit;


%LET Keypass=digov-utilizacao-de-canais-digitais-2019-2-e7tLW385IAy2wBJ2twGKh76l418y3IMOrCpPWsTgRUnPrfeWl8;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
  INSERT INTO EXPTROTINAS VALUES('work.final', 'digov-utilizacao-de-canais-digitais-2019-2');
  INSERT INTO EXPTROTINAS VALUES('work.mci_visao', 'clientes');
QUIT;


%ProcessoCarregarEncerrar(EXPTROTINAS);

