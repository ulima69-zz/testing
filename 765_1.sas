* sas:run@sasanalitico;

Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';


*libname encart '/dados/gecen/interno/bases/rel/fotos'; 				
libname orcmci '/dados/externo/DIGOV/GECEN/indicadores'; 
*libname rlzmci '/dados/externo/DIVAR/METAS/conexao/19S2/rlzd_analitico';

libname rlzinfor'/dados/divar/gerexresultad/gerinfor/interno/765_dj_trabalhista_gov';


*LIBNAME DB2ATB DB2 DATABASE=bdb2p04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SDRED;

*LIBNAME deps postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='dependencias';
*LIBNAME rel postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='rel';





* buscando o orcado e seu encarteiramento ;
proc sql;
create table mci as 
select
CD_PRF_DEPE
,NR_SEQL_CTRA
,CD_CLI
,VL_ORC
,VLR_RLZD
,ATG
,anomes
from rlzinfor.rlz_vertical c
;
quit;









* Indicador 2019.1 - 243 2019.2 - 266 ;
proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table dados_mbz as 
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
	and a.cd_in_mbz = CASE when (month(current_date)) <= 6 then 243 else 266 end;
) a;
quit;




* usado para buscar a data do conexao;
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';

proc sql;
create table conx_pos as 
select md_dm1 as posicao from datas.mapa_datas where md_data_ref = today();
quit;



proc sql;
create table final as 
select * from conx_pos cross join dados_mbz;
quit;



proc sql;
create table anomes as
select distinct
 case when a.mm in (10,11,12) then cats(a.aaaa, a.mm)       else cats(a.aaaa, '0' , a.mm)  end as id        /* horrivel preciso corrigir */
,case when a.mm in (10,11,12) then cats(a.aaaa, '-' , a.mm) else cats(a.aaaa, '-0' , a.mm) end as descricao /* horrivel preciso corrigir */
from orcmci.ORC_DIRECIONADOR_DJ_TRAB_22019 a
where a.aaaa = year(date());
quit;





%LET Keypass=dj-trabalhista-wG56uFdARMtcEUDDQgmN9En112beGFXzkvY6pyuQ4kUnmfFL5d;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
    INSERT INTO EXPTROTINAS VALUES('work.final', 'dj-trabalhista');
    INSERT INTO EXPTROTINAS VALUES('work.mci', 'clientes');
    INSERT INTO EXPTROTINAS VALUES('work.anomes', 'anomes');
	/*INSERT INTO EXPTROTINAS VALUES('work.aaaamm', 'aaaamm');*/
QUIT;

%ProcessoCarregarEncerrar(EXPTROTINAS);
