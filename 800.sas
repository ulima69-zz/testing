* sas:run@sasanalitico;

/*
======================================================
CONEXÃO HORIZONTAL SETOR PÚBLICO versao 2
======================================================
- pegar acumulados postgres
-- incluir pegar placar
-- left com consultoria

- pegar mensais postgres
-- atg-mc sumarizar pro níveis superiores

*/

Options
	nonotes
	nosource;

%include '/dados/infor/suporte/FuncoesInfor.sas';


proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table rel as 
select 
	*
from connection to postgres (
with 
avl_datas as (
  select 
    max(posicao) posicao 
    ,(substring(max(posicao)::text from 0 for 5) || substring(max(posicao)::text from 6 for 2))::int as anomes
  from conexao.modulo_avaliacao_indicadores
)
,d1 as (
  select md_dm1 as posicao from datas.mapa_datas where md_data_ref = current_date
)
,mob_datas as (
  select 
    posicao 
    ,extract(month from (select posicao from d1)::date) as mes
    ,extract(year from  (select posicao from d1)::date) as ano
  from  public.posicao 
  where id = 'CON_MOB_DB2'
)
,atg_mc as (
select 
  cd_prf_ctra
  ,nr_seql_ctra
  ,qt_pto_in_mbz
  ,qt_pto_in_mbz_acm
  ,qt_peso_aprd
  ,vl_acm_meta_in
  ,vl_acm_rlzd_in
  ,pc_atgt_acm_in_mbz
  ,VL_META_IN_MBZ
  ,VL_RLZD_IN_MBZ
  ,PC_ATGT_IN_MBZ
from conexao_mobilizacao.indicadores_mensal a
  where  a.cd_in_mbz = 277
  and a.aa_aprc = (select ano from mob_datas)
  and a.mm_aprc = (select mes from mob_datas)
  and a.posicao = (select posicao from mob_datas)
union all
select 
b.superior as cd_prf_ctra
,-1 as nr_seql_ctra
,sum(qt_pto_in_mbz) as qt_pto_in_mbz
,sum(qt_pto_in_mbz_acm) as qt_pto_in_mbz_acm
,sum(qt_peso_aprd) as qt_peso_aprd
,sum(vl_acm_meta_in) as vl_acm_meta_in
,sum(vl_acm_rlzd_in) as vl_acm_rlzd_in
,(sum(vl_acm_rlzd_in)/nullif(sum(vl_acm_meta_in), 0))*100 as pc_atgt_acm_in_mbz
,sum(VL_META_IN_MBZ) as VL_META_IN_MBZ
,sum(VL_RLZD_IN_MBZ) as VL_RLZD_IN_MBZ
,(sum(VL_RLZD_IN_MBZ)/nullif(sum(VL_META_IN_MBZ), 0))*100 as PC_ATGT_IN_MBZ
from conexao_mobilizacao.indicadores_mensal a
left join dependencias.hierarquia b on a.cd_prf_ctra = b.agencia and a.nr_seql_ctra = -1
  where  a.cd_in_mbz = 277
  and a.aa_aprc = (select ano from mob_datas)
  and a.mm_aprc = (select mes from mob_datas)
  and a.posicao = (select posicao from mob_datas)
  and b.superior <> b.agencia
group by 1,2
)
,acumulado as (
select 
  dep.prefixo 
  ,case when dep.carteira = -1 then 0 else dep.carteira end as carteira 

  /* margem de contribução sem risco */
  ,mg.orcado as mg_orc
  ,mg.realizado as mg_rlz
  ,mg.atingimento as mg_atg

  /* desmbolso credito governo */
  ,dcg.orcado as dcg_orc
  ,dcg.realizado as dcg_rlz
  ,dcg.atingimento as dcg_atg

  /* depesas administrativas */
  ,dadm.orcado as dadm_orc
  ,dadm.realizado as dadm_rlz
  ,dadm.atingimento as dadm_atg

  /* mgg */
  ,mgg.orcado as mgg_orc
  ,mgg.realizado as mgg_rlz
  ,mgg.atingimento as mgg_atg

  /* rentabilidade cartoes governo */
  ,rcg.vl_acm_meta_in     as rcg_orc
  ,rcg.vl_acm_rlzd_in     as rcg_rlz
  ,rcg.pc_atgt_acm_in_mbz as rcg_atg
  ,rcg.qt_pto_in_mbz_acm*(rcg.qt_peso_aprd/100) as rcg_ptp

  /* rpps */
  ,rpps.vl_acm_meta_in     as rpps_orc
  ,rpps.vl_acm_rlzd_in     as rpps_rlz
  ,rpps.pc_atgt_acm_in_mbz as rpps_atg
  ,rpps.qt_pto_in_mbz_acm*(rpps.qt_peso_aprd/100) as rpps_ptp

  /* fundos setor publico*/
  ,fsp.vl_acm_meta_in     as fsp_orc
  ,fsp.vl_acm_rlzd_in     as fsp_rlz
  ,fsp.pc_atgt_acm_in_mbz as fsp_atg
  ,fsp.qt_pto_in_mbz_acm*(fsp.qt_peso_aprd/100) as fsp_ptp

  /* tarifas */
  ,tar.vl_acm_meta_in     as tar_orc
  ,tar.vl_acm_rlzd_in     as tar_rlz
  ,tar.pc_atgt_acm_in_mbz as tar_atg
  ,tar.qt_pto_in_mbz_acm*(tar.qt_peso_aprd/100) as tar_ptp

  /*Modulo*/
  ,modulo.qt_pto_plcr /* placar mob */
  ,modulo.qt_pto_med_plcr  /* placar mob med */

  /*Placar Avaliação*/
  ,placar.pontos as placar /* placar avaliacao */
from (
  select distinct
    cd_prf_ctra as prefixo, 
    nr_seql_ctra as carteira 
  FROM conexao_mobilizacao.indicadores_mensal a
  where posicao = (select posicao from mob_datas)
    and cd_in_mbz in (121,123,184,185,186,187,202,266,276,277,279)
    and aa_aprc = (select ano from mob_datas)
    and mm_aprc = (select mes from mob_datas)
) dep

/* Rentabilidade de Fundos Setor Público */
left join conexao_mobilizacao.indicadores_mensal 		fsp
  on fsp.cd_in_mbz = 185
  and fsp.cd_prf_ctra = dep.prefixo
  and fsp.nr_seql_ctra = dep.carteira
  and fsp.aa_aprc = (select ano from mob_datas)
  and fsp.mm_aprc = (select mes from mob_datas)
  and fsp.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					fsp_r
  on fsp.cd_rgua_in_mbz = fsp_r.cd_rgua_in_mbz
  and fsp_r.nr_fxa_rgua_in_mbz = fsp.qt_pto_in_mbz
  and fsp_r.posicao = (select posicao from mob_datas)

/* Rentabilidade de Fundos RPPS */
left join conexao_mobilizacao.indicadores_mensal 		rpps
  on rpps.cd_in_mbz = 186
  and rpps.cd_prf_ctra = dep.prefixo
  and rpps.nr_seql_ctra = dep.carteira
  and rpps.aa_aprc = (select ano from mob_datas)
  and rpps.mm_aprc = (select mes from mob_datas)
  and rpps.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					rpps_r
  on rpps.cd_rgua_in_mbz = rpps_r.cd_rgua_in_mbz
  and rpps_r.nr_fxa_rgua_in_mbz = rpps.qt_pto_in_mbz
  and rpps_r.posicao = (select posicao from mob_datas)

  /* Rentabilidade de cartões governo */
left join conexao_mobilizacao.indicadores_mensal 		rcg
  on rcg.cd_in_mbz = 187
  and rcg.cd_prf_ctra = dep.prefixo
  and rcg.nr_seql_ctra = dep.carteira
  and rcg.aa_aprc = (select ano from mob_datas)
  and rcg.mm_aprc = (select mes from mob_datas)
  and rcg.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					rcg_r
  on rcg.cd_rgua_in_mbz = rcg_r.cd_rgua_in_mbz
  and rcg_r.nr_fxa_rgua_in_mbz = rcg.qt_pto_in_mbz
  and rcg_r.posicao = (select posicao from mob_datas)

/* tarifas priorizadas governo */
left join conexao_mobilizacao.indicadores_mensal 		tar
  on tar.cd_in_mbz = 202
  and tar.cd_prf_ctra = dep.prefixo
  and tar.nr_seql_ctra = dep.carteira
  and tar.aa_aprc = (select ano from mob_datas)
  and tar.mm_aprc = (select mes from mob_datas)
  and tar.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					tar_r
  on tar.cd_rgua_in_mbz = tar_r.cd_rgua_in_mbz
  and tar_r.nr_fxa_rgua_in_mbz = tar.qt_pto_in_mbz
  and tar_r.posicao = (select posicao from mob_datas)

left join conexao_mobilizacao.placar modulo
  on modulo.posicao = (select posicao from mob_datas)
  and modulo.aa_aprc = (select ano from mob_datas)
  and modulo.mm_aprc = (select mes from mob_datas)
  and modulo.cd_prf_ctra = dep.prefixo
  and modulo.nr_seql_ctra = dep.carteira

/*Placar*/
 left join conexao.placar_avaliacao placar
  on placar.prefixo = dep.prefixo
  and placar.carteira = dep.carteira
  and placar.ano = (select ano from mob_datas)
  and placar.mes = (select mes from mob_datas)

  /* Margem de Contribuição sem Risco */
left join conexao.modulo_avaliacao_indicadores mg
on mg.prefixo = dep.prefixo
  and mg.carteira = dep.carteira
  and mg.indicador in (12120,12119,12121,12187)
  and mg.anomes = (select anomes from avl_datas)
  and mg.posicao = (select posicao from avl_datas)  

  /* desemb credito governo */
left join conexao.modulo_avaliacao_indicadores dcg
  on dcg.prefixo = dep.prefixo
  and dcg.carteira = dep.carteira
  and dcg.indicador in (12208,12207)
  and dcg.anomes = (select anomes from avl_datas)
  and dcg.posicao = (select posicao from avl_datas)  

  /* despesas administrativas */
left join conexao.modulo_avaliacao_indicadores dadm
  on dadm.prefixo = dep.prefixo
  and dadm.carteira = dep.carteira
  and dadm.indicador in (12122,12125)
  and dadm.anomes = (select anomes from avl_datas)
  and dadm.posicao = (select posicao from avl_datas)
  /* mgg */

left join conexao.modulo_avaliacao_indicadores mgg
  on mgg.prefixo = dep.prefixo
  and mgg.carteira = dep.carteira
  and mgg.indicador in (12112,12110,12117,12116)
  and mgg.anomes = (select anomes from avl_datas)
  and mgg.posicao = (select posicao from avl_datas)
)
, mensal as (
select 
  dep.prefixo 
  ,case when dep.carteira = -1 then 0 else dep.carteira end as carteira 

  /* carteiras atingindo mc */
  ,cmsr.VL_META_IN_MBZ as cmsr_orc
  ,cmsr.VL_RLZD_IN_MBZ as cmsr_rlz
  ,cmsr.PC_ATGT_IN_MBZ as cmsr_atg
  ,cmsr.qt_pto_in_mbz*(cmsr.qt_peso_aprd/100) as cmsr_ptp

  /* desconcentra mais */
  ,descom.VL_META_IN_MBZ as des_m_orc
  ,descom.VL_RLZD_IN_MBZ as des_m_rlz
  ,descom.PC_ATGT_IN_MBZ as des_m_atg
  ,descom.qt_pto_in_mbz*(descom.qt_peso_aprd/100) as descom_ptp

  /* dj trabalhista */
  ,djt.VL_META_IN_MBZ as djt_orc
  ,djt.VL_RLZD_IN_MBZ as djt_rlz
  ,djt.PC_ATGT_IN_MBZ as djt_atg
  ,djt.qt_pto_in_mbz*(djt.qt_peso_aprd/100) as djt_ptp

  /* docmicilio educação */
  ,ded.VL_META_IN_MBZ as ded_orc
  ,ded.VL_RLZD_IN_MBZ as ded_rlz
  ,ded.PC_ATGT_IN_MBZ as ded_atg 
  ,ded.qt_pto_in_mbz*(ded.qt_peso_aprd/100) as ded_ptp

  /* domicilio bancario saude */
  ,dbs.VL_META_IN_MBZ as dbs_orc
  ,dbs.VL_RLZD_IN_MBZ as dbs_rlz
  ,dbs.PC_ATGT_IN_MBZ as dbs_atg
  ,dbs.qt_pto_in_mbz*(dbs.qt_peso_aprd/100) as dbs_ptp

  /* gac */
  ,gac.orcado as gac_orc
  ,gac.realizado as gac_rlz
  ,gac.atingimento as gac_atg

  /* utilizacao de canais digitais */
  ,ucd.VL_META_IN_MBZ as ucd_orc
  ,ucd.VL_RLZD_IN_MBZ as ucd_rlz
  ,ucd.PC_ATGT_IN_MBZ as ucd_atg
  ,ucd.qt_pto_in_mbz*(ucd.qt_peso_aprd/100) as ucd_ptp

  /* clientes atingindo mc */
  ,atg_mc.VL_META_IN_MBZ as cmc_orc
  ,atg_mc.VL_RLZD_IN_MBZ as cmc_rlz
  ,atg_mc.PC_ATGT_IN_MBZ as cmc_atg
  ,0 as cmc_ptp
from (
  select distinct
    cd_prf_ctra as prefixo, 
    nr_seql_ctra as carteira 
  FROM conexao_mobilizacao.indicadores_mensal a
  where posicao = (select posicao from mob_datas)
    and cd_in_mbz in (121,123,184,185,186,187,202,266,276,277,279)
    and aa_aprc = (select ano from mob_datas)
    and mm_aprc = (select mes from mob_datas)
) dep
/* carteiras ating mc sem risco */
left join conexao_mobilizacao.indicadores_mensal 		cmsr
  on cmsr.cd_in_mbz = 279 
  and cmsr.cd_prf_ctra = dep.prefixo
  and cmsr.nr_seql_ctra = dep.carteira
  and cmsr.aa_aprc = (select ano from mob_datas)
  and cmsr.mm_aprc = (select mes from mob_datas)
  and cmsr.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					cmsr_r
  on cmsr.cd_rgua_in_mbz = cmsr_r.cd_rgua_in_mbz
  and cmsr_r.nr_fxa_rgua_in_mbz = cmsr.qt_pto_in_mbz
  and cmsr_r.posicao = (select posicao from mob_datas)

  /* desconcentra mais */
left join conexao_mobilizacao.indicadores_mensal 		descom
  on descom.cd_in_mbz = 276 
  and descom.cd_prf_ctra = dep.prefixo
  and descom.nr_seql_ctra = dep.carteira
  and descom.aa_aprc = (select ano from mob_datas)
  and descom.mm_aprc = (select mes from mob_datas)
  and descom.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					descom_r
  on descom.cd_rgua_in_mbz = descom_r.cd_rgua_in_mbz
  and descom_r.nr_fxa_rgua_in_mbz = descom.qt_pto_in_mbz
  and descom_r.posicao = (select posicao from mob_datas)

/* dj trabalhista */
left join conexao_mobilizacao.indicadores_mensal 		djt
  on djt.cd_in_mbz = 266 
  and djt.cd_prf_ctra = dep.prefixo
  and djt.nr_seql_ctra = dep.carteira
  and djt.aa_aprc = (select ano from mob_datas)
  and djt.mm_aprc = (select mes from mob_datas)
  and djt.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					djt_r
  on djt.cd_rgua_in_mbz = djt_r.cd_rgua_in_mbz
  and djt_r.nr_fxa_rgua_in_mbz = djt.qt_pto_in_mbz
  and djt_r.posicao = (select posicao from mob_datas)

/* domicilio educacao */
left join conexao_mobilizacao.indicadores_mensal 		ded
  on ded.cd_in_mbz = 184
  and ded.cd_prf_ctra = dep.prefixo
  and ded.nr_seql_ctra = dep.carteira
  and ded.aa_aprc = (select ano from mob_datas)
  and ded.mm_aprc = (select mes from mob_datas)
  and ded.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					ded_r
  on ded.cd_rgua_in_mbz = ded_r.cd_rgua_in_mbz
  and ded_r.nr_fxa_rgua_in_mbz = ded.qt_pto_in_mbz
  and ded_r.posicao = (select posicao from mob_datas)

  /* Domicílio Bancario Saude */
left join conexao_mobilizacao.indicadores_mensal 		dbs
  on dbs.cd_in_mbz = 123
  and dbs.cd_prf_ctra = dep.prefixo
  and dbs.nr_seql_ctra = dep.carteira
  and dbs.aa_aprc = (select ano from mob_datas)
  and dbs.mm_aprc = (select mes from mob_datas)
  and dbs.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					dbs_r
  on dbs.cd_rgua_in_mbz = dbs_r.cd_rgua_in_mbz
  and dbs_r.nr_fxa_rgua_in_mbz = dbs.qt_pto_in_mbz
  and dbs_r.posicao = (select posicao from mob_datas)

  /* gac */
left join conexao.modulo_avaliacao_indicadores 			gac
  on gac.prefixo = dep.prefixo
  and gac.carteira = dep.carteira
  and gac.indicador in (12154,12159,12158)
  and gac.anomes = (select anomes from avl_datas)
  and gac.posicao = (select posicao from avl_datas)

  /* Utilização de Canais Digitais */
left join conexao_mobilizacao.indicadores_mensal 		ucd
  on ucd.cd_in_mbz = 121
  and ucd.cd_prf_ctra = dep.prefixo
  and ucd.nr_seql_ctra = dep.carteira
  and ucd.aa_aprc = (select ano from mob_datas)
  and ucd.mm_aprc = (select mes from mob_datas)
  and ucd.posicao = (select posicao from mob_datas)
left join conexao_mobilizacao.reguas 					ucd_r
  on ucd.cd_rgua_in_mbz = ucd_r.cd_rgua_in_mbz
  and ucd_r.nr_fxa_rgua_in_mbz = ucd.qt_pto_in_mbz
  and ucd_r.posicao = (select posicao from mob_datas)

  /* % Clientes Atingindo MC - 2 Semestre */
left join 												atg_mc
  on  atg_mc.cd_prf_ctra = dep.prefixo
  and atg_mc.nr_seql_ctra = dep.carteira
/*left join conexao_mobilizacao.reguas 					atg_mc_r
  on atg_mc.cd_rgua_in_mbz = atg_mc_r.cd_rgua_in_mbz
  and atg_mc_r.vl_fxa_supr >= 99999
  and atg_mc_r.posicao = (select posicao from mob_datas)*/
)
select 
  a.prefixo 
  ,a.carteira 

  ,placar
  ,qt_pto_plcr
  ,qt_pto_med_plcr

  ,mg_orc
  ,mg_rlz
  ,mg_atg

  ,dcg_orc
  ,dcg_rlz
  ,dcg_atg

  ,dadm_orc
  ,dadm_rlz
  ,dadm_atg

  ,mgg_orc
  ,mgg_rlz
  ,mgg_atg

  ,rcg_orc
  ,rcg_rlz
  ,rcg_atg

  ,rpps_orc
  ,rpps_rlz
  ,rpps_atg

  ,fsp_orc
  ,fsp_rlz
  ,fsp_atg

  ,tar_orc
  ,tar_rlz
  ,tar_atg

  ,cmsr_orc
  ,cmsr_rlz
  ,cmsr_atg

  ,des_m_orc
  ,des_m_rlz
  ,des_m_atg

  ,djt_orc
  ,djt_rlz
  ,djt_atg

  ,ded_orc
  ,ded_rlz
  ,ded_atg

  ,dbs_orc
  ,dbs_rlz
  ,dbs_atg

  ,gac_orc
  ,gac_rlz
  ,gac_atg

  ,ucd_orc
  ,ucd_rlz
  ,ucd_atg

  ,cmc_orc
  ,cmc_rlz
  ,cmc_atg

  ,rpps_ptp
  ,fsp_ptp
  ,rcg_ptp
  ,tar_ptp
  ,cmsr_ptp
  ,djt_ptp
  ,ded_ptp
  ,dbs_ptp
  ,ucd_ptp
  ,cmc_ptp
from acumulado a
left join mensal b on b.prefixo = a.prefixo and a.carteira = b.carteira;
) a;
quit;


/* Componente Consultoria 
- só existe por carteira, não é necessário.
*/
proc sql;
connect to db2 (DATABASE=bdb2p04 AUTHDOMAIN=DB2SDRED);
create table consultoria_cpnt as 
select * from connection to db2 (
	SELECT
		b.CD_DEPE_UOR   as prefixo
		,a.NR_SEQL_CTRA as carteira
		,a.VL_META_CPNT as csl_orc
		,a.VL_RLZD      as csl_rlz
		,a.PC_ATGT_CPNT as csl_atg
	FROM DB2ATB.VL_APRD_CPNT_CTRA a
	LEFT JOIN DB2UOR.UOR b ON b.CD_UOR = a.CD_UOR_CTRA
	WHERE 
		CD_CPNT_MOD_AVLC = 35222 
	and MM_VL_APRD_CPNT = month(CURRENT_DATE) 
	and AA_VL_APRD_CPNT  = year(CURRENT_DATE);
) a;
quit;


/* busco a hierarquia no postgres para sumarizar o passo anterior */
/*proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table work.hierarquia as 
select 
	*
from connection to postgres (
	select * 
	from dependencias.hierarquia;
) a;
quit;*/


/* sumarizando o componente de consultoria para agencia, gerev, super */
proc sql;
/*create table consultoria as 
select * from consultoria_cpnt
union all
select
	superior       as prefixo
	,0             as carteira
	,sum(csl_orc)  as csl_orc
	,sum(csl_rlz)  as csl_rlz
	,0             as csl_atg
from consultoria_cpnt a
left join hierarquia b on a.prefixo = b.agencia
group by 1, 2;
quit;*/


/* juntando os dados do 620 com o componente de consultoria */
proc sql;
create table rel_consultoria as 
select
  *
from rel a
left join consultoria_cpnt b on a.prefixo = b.prefixo and a.carteira = b.carteira;
quit;


/* pegando a posicao do conexao que eh d-1 */
proc sql;
connect to postgres (server='172.17.145.191' port=5432 user=postgres password=My3G55_191 db=infor);
create table rel_posicao as 
select 
	*
from connection to postgres (
	select md_dm1 as posicao from datas.mapa_datas where md_data_ref = current_date;
) a;
quit;


proc sql;
create table final as
select * from rel_posicao
cross join rel_consultoria;
quit;






%LET Keypass=gov-conexao-horizontal-2019-2-H2NG44jNLk9RXShIhNNSQBzEVFDspjetcdmbln0kqSxyWk3a6h;
PROC SQL;
  CREATE TABLE EXPTROTINAS (TABELA_SAS CHAR(100), ROTINA CHAR(100));
  INSERT INTO EXPTROTINAS VALUES('work.final', 'gov-conexao-horizontal-2019-2');
QUIT;


%ProcessoCarregarEncerrar(EXPTROTINAS);

