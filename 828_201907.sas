* sas:run@sasanalitico;

Options	nonotes	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';

* usado para buscar a data do conexao;
LIBNAME datas postgres SERVER='172.17.145.191' DATABASE='infor' PORT='5432' USER='postgres' PASS='My3G55_191' schema='datas';

proc sql;
create table mapa as 
select 'posicao' as chave, md_dm1 as valor from datas.mapa_datas where md_data_ref = today();
quit;



* buscando os valores para carteiras;
proc sql;
	connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
	create table carteiras as 
		select * from connection to db2 (
		SELECT 
			b.CD_DEPE_UOR
			,NR_SEQL_CTRA
			,VL_META_IN as VL_META_IN_MBZ
			,VL_RLZD_IN as VL_RLZD_IN_MBZ
			,PC_ATGT_IN as PC_ATGT_IN_MBZ
			, 0 as QTD_ORC
			, 0 as QTD_RLZ
			, 0 as ATG_QTD
		FROM db2atb.VL_APRD_IN_CTRA a
		LEFT JOIN DB2UOR.UOR b ON a.CD_UOR_CTRA = b.CD_UOR
			WHERE CD_IN_MOD_AVLC  in ( 12120 , 12119 , 12121 , 12187 )
				and AA_VL_APRD_IN = year(CURRENT_DATE) 
				and MM_VL_APRD_IN in (month(current_date))
				AND NR_SEQL_CTRA NOT IN (0);
				) a;
quit;




* buscando os dados para dependencias ;
proc sql;
	connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
	create table dependencias as 
		select * from connection to db2 (
			WITH dependencias AS (
SELECT
	CD_DEPE_UOR
	,AA_VL_APRD_IN
	,MM_VL_APRD_IN 
	,COUNT(NR_SEQL_CTRA) AS qtd_carteiras 
	,SUM( CASE WHEN VL_META_IN<VL_RLZD_IN THEN 1 ELSE 0 END ) AS qtd_carteiras_atg
FROM db2atb.VL_APRD_IN_CTRA a
LEFT JOIN DB2UOR.UOR b ON a.CD_UOR_CTRA = b.CD_UOR
WHERE
	CD_IN_MOD_AVLC  in ( 12120 , 12119 , 12121 , 12187 )
	AND AA_VL_APRD_IN = YEAR(CURRENT_DATE)
	AND MM_VL_APRD_IN IN (MONTH(CURRENT_DATE))
	AND NR_SEQL_CTRA NOT IN (0)
GROUP BY
	CD_DEPE_UOR,
	AA_VL_APRD_IN,
	MM_VL_APRD_IN 
)
SELECT
CD_DEPE_UOR
, 0 AS NR_SEQL_CTRA
, 0 as VL_META_IN_MBZ
, 0 as VL_RLZD_IN_MBZ
, 0 as PC_ATGT_IN_MBZ
,floor((cast(qtd_carteiras as real) * 0.7)) AS QTD_ORC
,qtd_carteiras_atg AS QTD_RLZ
,( cast(qtd_carteiras_atg AS REAL) /floor((cast(qtd_carteiras as real) * 0.7)) ) * 100  AS ATG_QTD
FROM dependencias;
				) a;
quit;


* buscando os valores para gerevs;
proc sql;
	connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
	create table gerevs as 
		select * from connection to db2 (
		SELECT 
			b.CD_DEPE_UOR
			,NR_SEQL_CTRA
			, 0 as VL_META_IN_MBZ
			, 0 as VL_RLZD_IN_MBZ
			, 0 as PC_ATGT_IN_MBZ
			,VL_META_IN_MBZ as QTD_ORC
			,VL_RLZD_IN_MBZ as QTD_RLZ
			,PC_ATGT_IN_MBZ	as ATG_QTD
		FROM db2atb.VL_APRD_IN_MBZ_MM a
		LEFT JOIN DB2UOR.UOR b ON a.CD_UOR_CTRA = b.CD_UOR
			WHERE cd_in_mbz = 279 
				and aa_aprc = year(CURRENT_DATE) 
				and mm_aprc in (month(current_date));
				) a;
quit;


proc sql;
create table dependencias_todas as
select (select valor from mapa where chave = 'posicao') as posicao, a.* from dependencias a
union
select (select valor from mapa where chave = 'posicao') as posicao, b.* from gerevs b
union
select (select valor from mapa where chave = 'posicao') as posicao, c.* from carteiras c;
quit;



%LET Keypass=digov-carteiras-atg-mc-sem-risco-2019-2-LYZj7ML5AtQvcy21tbjF0E6tDeRRha8nbxwM62E7qkrXVQiLgV;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
  INSERT INTO EXPTROTINAS VALUES('work.dependencias_todas', 'digov-carteiras-atg-mc-sem-risco-2019-2');
QUIT;


%ProcessoCarregarEncerrar(EXPTROTINAS);

