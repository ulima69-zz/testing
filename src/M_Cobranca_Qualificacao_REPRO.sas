

%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME CBR '/dados/gecen/interno/bases/cbr';
LIBNAME BCN '/dados/gecen/interno/bases/bcn';
LIBNAME AUX_1 "/dados/infor/producao/cobranca_qualificada_19";


DATA _NULL_;

D1 = diaUtilAnterior(TODAY());
CALL SYMPUT('D1',COMPRESS(D1,' '));

ANO_ATUAL = 2019;
CALL SYMPUT('ANO_ATUAL',COMPRESS(ANO_ATUAL,' '));

/*MES_POSICAO = 01*/
MES_POSICAO = Put(MONTH (diaUtilAnterior(TODAY())), Z2.);
CALL SYMPUT('MES_POSICAO', COMPRESS(MES_POSICAO,' '));

/*ANOMES = 201901*/
ANOMES = Put(D1, yymmn6.);
CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));

/*MESANO = 012019*/
MESANO = Put(D1, mmyyn6.);
CALL SYMPUT('MESANO',COMPRESS(MESANO,' '));

RUN;


%Put &MES_POSICAO &ANO_ATUAL &D1 &ANOMES &MESANO;


/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/

/*%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";*/

options mlogic symbolgen mprint;

%hps;

%let syscc = 0;

%ConectarDB2(CBR,authdomain=DB2SGCEN);
%ConectarDB2(SGCEN,authdomain=DB2SGCEN);


%macro montar_view;

	data _null_;
		set cbr.conv_tip_evt_tarf end=last;
		call symputx ('operador'||left(_n_), operador);
		call symputx ('nr_ctra_cbr'||left(_n_), nr_ctra_cbr);
		call symputx ('cd_tip_gr_itc_cbr'||left(_n_), cd_tip_gr_itc_cbr);
		call symputx ('cd_fma_entd_itc'||left(_n_), cd_fma_entd_itc);
		call symputx ('cd_tip_evt_tarf'||left(_n_), cd_tip_evt_tarf);
		if last then call symputx ('count',_n_);
	;run;

	proc sql;
		drop table db2sgcen.gcen_ettc_gr_itc_cli_2;

		connect to db2 (authdomain=db2sgcen database=bdb2p04);
		execute (
			create view gcen_ettc_gr_itc_cli_2 as
			select 
				date(to_date(varchar_format(t1.aa_per_mvt_tit, '0000')||varchar_format(t1.mm_per_mvt_tit, '00')||varchar_format(t1.dd_per_mvt_tit, '00'), 'yyyy mm dd')) as dt_per_mvt_tit,
				t4.cd_prd,
				t4.cd_mdld,
				t2.cd_cli,
				t2.cd_prf_depe,
				t2.nr_cc,
				t1.nr_opr_cli_cbr, 
				t1.nr_ctra_cbr, 
				t1.nr_vrc_ctra_cbr,
				case
					%do i = 1 %to &count;
					when t1.nr_ctra_cbr &&operador&i in (&&nr_ctra_cbr&i) and t1.cd_tip_gr_itc_cbr in (&&cd_tip_gr_itc_cbr&i) and t1.cd_fma_entd_itc in (&&cd_fma_entd_itc&i) then &&cd_tip_evt_tarf&i
					%end;
				end as cd_tip_evt_tarf,
				case when t3.cd_fnld_ctra_cbr in (30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) then t3.cd_fnld_ctra_cbr else 0 end as cd_tip_sgm_cbr,				
				t1.qt_tit_gr_itc,
				t1.vl_ttl_tit_gr_itc
			from 
				db2cbr.ettc_gr_itc_cli as t1
				inner join db2cbr.ctr_cli_cbr t2 on (t1.nr_opr_cli_cbr = t2.nr_opr_cli_cbr)
				inner join db2cbr.ctr_srvc_cbr t3 on (t1.nr_opr_cli_cbr = t3.nr_opr_cli_cbr and t1.nr_ctra_cbr = t3.nr_ctra_cbr and t1.nr_vrc_ctra_cbr = t3.nr_vrc_ctra_cbr)
				inner join db2opr.ctr_opr t4 on (t3.nr_ctr_opr = t4.nr_unco_ctr_opr)
			where

			 aa_per_mvt_tit = 2019 

             /*aa_per_mvt_tit >= year(current date - 7 days) and mm_per_mvt_tit >= month(current date - 7 days) and dd_per_mvt_tit >= day(current date - 7 days)*/

             and cd_tip_per_mvt_tit = 'D' and t1.nr_ctra_cbr > 0 and t1.nr_vrc_ctra_cbr > 0

		) by db2;
		disconnect from db2;
	quit;
%mend;

%montar_view;

proc sql;
	connect to db2(authdomain=db2sgcen database=bdb2p04);
	create table work.tbl_0001 as select * from connection to db2 (
	select	
		a.dt_per_mvt_tit, a.cd_prd, a.cd_mdld, a.cd_cli, a.cd_prf_depe, a.nr_cc, a.nr_opr_cli_cbr, a.nr_ctra_cbr, a.nr_vrc_ctra_cbr,
		a.cd_tip_evt_tarf, a.cd_tip_sgm_cbr, a.qt_tit_gr_itc, a.vl_ttl_tit_gr_itc, a.pc_tarf_evt_cbr, a.vl_tarf_evt_cbr,
		case 
			when a.cd_tip_sgm_cbr in (30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) or a.in_flz_tarf_atv = 'N' then a.vl_tarf_evt_cbr 
			else round((a.pc_tarf_evt_cbr / 100) * a.vl_tarf_evt_cbr, 2) 
		end as vl_tarf_flex,
		case 
			when a.cd_tip_sgm_cbr in (30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) or a.in_flz_tarf_atv = 'N' then round(a.qt_tit_gr_itc * a.vl_tarf_evt_cbr, 2)
			else round(((a.pc_tarf_evt_cbr / 100) * a.vl_tarf_evt_cbr) * a.qt_tit_gr_itc, 2)
		end as vl_ttl_tarf_flex,
		round(qt_tit_gr_itc * vl_tarf_evt_cbr, 2) as vl_ttl_tarf_cheia
	from (
		select 
			t1.*,
			t2.dt_inc_vgc_tarf,
			t2.dt_fim_vgc_tarf,
			t2.dt_incl_flz,
			t2.hr_incl_flz,
			case when t2.pc_tarf_evt_cbr is null then 100 else t2.pc_tarf_evt_cbr end as pc_tarf_evt_cbr,
			case when t2.in_flz_tarf_atv is null then 'N' else t2.in_flz_tarf_atv end as in_flz_tarf_atv,
			t3.vl_tarf_evt_cbr,
			row_number() over(
				partition by t1.dt_per_mvt_tit, t1.nr_opr_cli_cbr, t1.nr_ctra_cbr, t1.nr_vrc_ctra_cbr, t1.cd_tip_evt_tarf 
				order by t2.in_flz_tarf_atv desc, t2.dt_incl_flz desc, t2.hr_incl_flz desc
			) as posicao
		from 
			(
				select dt_per_mvt_tit, cd_prd, cd_mdld, cd_cli, cd_prf_depe, nr_cc, nr_opr_cli_cbr, nr_ctra_cbr, nr_vrc_ctra_cbr, cd_tip_evt_tarf, cd_tip_sgm_cbr, 
					sum(qt_tit_gr_itc) as qt_tit_gr_itc, sum(vl_ttl_tit_gr_itc) as vl_ttl_tit_gr_itc
				from db2sgcen.gcen_ettc_gr_itc_cli_2 as t1
				group by dt_per_mvt_tit, cd_prd, cd_mdld, cd_cli, cd_prf_depe, nr_cc, nr_opr_cli_cbr,  nr_ctra_cbr,  nr_vrc_ctra_cbr, cd_tip_evt_tarf, cd_tip_sgm_cbr
			) t1
			left join db2cbr.flz_tarf_srvc_cbr t2
				on (t1.nr_opr_cli_cbr = t2.nr_opr_cli_cbr and t1.nr_ctra_cbr = t2.nr_ctra_cbr and t1.nr_vrc_ctra_cbr = t2.nr_vrc_ctra_cbr and t1.cd_tip_evt_tarf = t2.cd_tip_evt_tarf
					and t2.dt_inc_vgc_tarf <= t1.dt_per_mvt_tit and t1.dt_per_mvt_tit <= t2.dt_fim_vgc_tarf and t2.dt_incl_flz <= t1.dt_per_mvt_tit)
			left join db2cbr.tarf_evt_cbr t3 
				on (t1.cd_tip_evt_tarf = t3.cd_tip_evt_tarf and t1.cd_tip_sgm_cbr = t3.cd_tip_sgm_cbr)
		) as a
		where
			a.posicao = 1
		order by
			a.dt_per_mvt_tit, a.cd_prd, a.cd_mdld, a.cd_cli
	); 
	disconnect from db2;
quit;


PROC SQL;

   CREATE TABLE TAB_CBR_1 AS 

   SELECT DISTINCT

   CD_CLI,
   QT_TIT_GR_ITC,
   CD_PRD,
   DT_PER_MVT_TIT,
   CD_TIP_EVT_TARF    

          FROM work.tbl_0001 t1

		  WHERE CD_PRD = 14 AND MONTH(DT_PER_MVT_TIT) = &MES_POSICAO. AND YEAR(DT_PER_MVT_TIT) = &ANO_ATUAL. AND CD_TIP_EVT_TARF IN (1, 2, 19)
 
   ORDER BY 1;

QUIT;


/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/
/***********************************************/


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_1 AS 
   SELECT 
      
      CD_CLI,
	  QT_TIT_GR_ITC 

      /*FROM CBR.TIT_CBR_LQDD_CLI*/
	  FROM TAB_CBR_1

	  WHERE CD_PRD = 14 AND MONTH(DT_PER_MVT_TIT) = &MES_POSICAO. AND YEAR(DT_PER_MVT_TIT) = &ANO_ATUAL. AND CD_TIP_EVT_TARF IN (1, 2, 19)
	  
      ORDER BY 1,2;
QUIT;


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_2 AS 
   SELECT 
      
      CD_CLI,
	  SUM(QT_TIT_GR_ITC) AS QTDE

      FROM CBR_QUALIFICACAO_1
      GROUP BY 1
      ORDER BY 1;

QUIT;


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_3 AS 
   SELECT 

      MCI,
	  VLR_FATURAMENTO
      
      FROM BCN.BCN_PJ 
      ORDER BY 1;

QUIT;


/*SEG PARA REPRO BCN*/
/*SEG PARA REPRO BCN*/
/*SEG PARA REPRO BCN*/
/*SEG PARA REPRO BCN*/


PROC SQL;

   CREATE TABLE AUX_1.BCN_SEG_&ANOMES. AS 
   SELECT  DISTINCT 

           t1.MCI,
           t1.VLR_FATURAMENTO 

   FROM BCN.BCN_PJ t1;

QUIT;


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_4_ANT AS 
   SELECT DISTINCT
      
      t1.CD_CLI AS MCI_1,
      t2.MCI AS MCI_2,
	  t1.QTDE,
      t2.VLR_FATURAMENTO AS FATURAMENTO

      FROM CBR_QUALIFICACAO_2 t1
	  FULL JOIN CBR_QUALIFICACAO_3 t2 ON t1.CD_CLI = t2.MCI
	  	  
      ORDER BY 1;
QUIT;


PROC STDIZE DATA=CBR_QUALIFICACAO_4_ANT OUT=CBR_QUALIFICACAO_4_ANT REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_4 AS 
   SELECT DISTINCT
      
      IFN(t1.MCI_1 <> 0, t1.MCI_1, MCI_2) AS MCI,
      t1.QTDE,
      t1.FATURAMENTO

      FROM CBR_QUALIFICACAO_4_ANT t1
	  	  	  
      ORDER BY 1;
QUIT;


/*ENCARTEIRANDO*/

PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_5 AS 
      SELECT DISTINCT 

          t2.CD_PRF_DEPE AS PREFIXO, 
          t2.NR_SEQL_CTRA AS CARTEIRA,
          t1.MCI,
	      t1.QTDE,
          t1.FATURAMENTO          
		            
      FROM CBR_QUALIFICACAO_4 t1
      INNER JOIN COMUM.PAI_REL_&ANOMES. t2 ON (t1.MCI = t2.CD_CLI)
      WHERE t1.FATURAMENTO <> 0 AND t1.QTDE <> 0;

QUIT;


PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_6 AS 
      SELECT DISTINCT 

          t1.PREFIXO, 
          t1.CARTEIRA,
          t1.MCI,
	      t1.QTDE,
          t1.FATURAMENTO           
		            
      FROM CBR_QUALIFICACAO_5 t1
      WHERE 
      (t1.FATURAMENTO < 120000 AND t1.QTDE >= 6)
      OR(t1.FATURAMENTO >= 120000 AND t1.FATURAMENTO < 250000 AND t1.QTDE >= 8) 
	  OR(t1.FATURAMENTO >= 250000 AND t1.FATURAMENTO < 500000 AND t1.QTDE >= 10)
	  OR(t1.FATURAMENTO >= 500000 AND t1.FATURAMENTO < 750000 AND t1.QTDE >= 14)
	  OR(t1.FATURAMENTO >= 750000 AND t1.FATURAMENTO < 1000000 AND t1.QTDE >= 16)
	  OR(t1.FATURAMENTO >= 1000000 AND t1.FATURAMENTO < 2500000 AND t1.QTDE >= 23)
	  OR(t1.FATURAMENTO >= 2500000 AND t1.FATURAMENTO < 5000000 AND t1.QTDE >= 40)
	  OR(t1.FATURAMENTO >= 5000000 AND t1.FATURAMENTO < 25000000 AND t1.QTDE >= 59)
	  OR(t1.FATURAMENTO >= 25000000 AND t1.QTDE >= 121);

QUIT;


/*TABELA CLIENTES*/

PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_CLIENTES AS 
      SELECT DISTINCT 

          t1.PREFIXO AS PREFDEP, 
          t1.CARTEIRA AS CTRA,
          t1.MCI,
		  t1.QTDE,
		  t1.FATURAMENTO,
          1 AS TOTAL 
		            
      FROM CBR_QUALIFICACAO_6 t1;

QUIT;


/*VENDO OS PREFIXOS QUE ESTÃO NO ACORDO*/


%BuscarPrefixosIndicador(IND=118, MMAAAA=&MESANO., NIVEL_CTRA=1, SO_AG_PAA=0);


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_CLIENTES_1 AS 
   SELECT t1.PREFDEP, t1.CTRA, t2.UOR, t1.MCI, t1.TOTAL, t1.QTDE, t1.FATURAMENTO
   FROM CBR_QUALIFICACAO_CLIENTES t1
   INNER JOIN PREFIXOS_IND_000000118 t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA
   ORDER BY 2, 3;
QUIT;


/*TABELA GERAL*/


PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_GERAL AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
		  COUNT(t1.MCI) AS TOTAL, 
          SUM(t1.QTDE) AS QTDE,
		  SUM(t1.FATURAMENTO) AS FATURAMENTO
		            
      FROM CBR_QUALIFICACAO_CLIENTES_1 t1
      GROUP BY 1, 2;

QUIT;


/*TRAZENDO O TOTAL DE CLIENTES*/
/*TRAZENDO O TOTAL DE CLIENTES*/
/*TRAZENDO O TOTAL DE CLIENTES*/
/*TRAZENDO O TOTAL DE CLIENTES*/


PROC SQL;

   CREATE TABLE TOTAL_DE_CLIENTES AS 
      SELECT DISTINCT 

          t1.CD_PRF_DEPE AS PREFIXO, 
          t1.NR_SEQL_CTRA AS CARTEIRA,
          t1.CD_CLI AS MCI
		            
   FROM COMUM.PAI_REL_&ANOMES. t1
   ;

QUIT;


PROC STDIZE DATA=TOTAL_DE_CLIENTES OUT=TOTAL_DE_CLIENTES REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;

   CREATE TABLE TOTAL_DE_CLIENTES_15 AS 
      SELECT DISTINCT 

          t1.PREFIXO AS PREFDEP, 
          t1.CARTEIRA AS CTRA,
          t1.MCI    
		            
   FROM TOTAL_DE_CLIENTES t1
   WHERE t1.PREFIXO <> 0 AND t1.CARTEIRA <> 0 AND t1.MCI <> 0
   GROUP BY 1, 2;

QUIT;


PROC SQL;

   CREATE TABLE TOTAL_DE_CLIENTES_1 AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
          COUNT(t1.MCI) AS TOT_CLI    
		            
   FROM TOTAL_DE_CLIENTES_15 t1   
   GROUP BY 1, 2;

QUIT;


PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_GERAL_1 AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
		  t1.TOTAL,
		  t1.QTDE,
		  t1.FATURAMENTO,
          t2.TOT_CLI          
		            
      FROM CBR_QUALIFICACAO_GERAL t1
      INNER JOIN TOTAL_DE_CLIENTES_1 t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA;

QUIT;


/*SUMARIZANDO*/


PROC SQL;
DROP TABLE COLUNAS_SUMARIZAR;
CREATE TABLE COLUNAS_SUMARIZAR (Coluna CHAR(50), Tipo CHAR(10));
INSERT INTO COLUNAS_SUMARIZAR VALUES ('TOTAL', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('QTDE', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('FATURAMENTO', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('TOT_CLI', 'SUM');

QUIT;


/*FUNCAO DE SUMARIZACAO*/ 

%SumarizadorCNX( TblSASValores=CBR_QUALIFICACAO_GERAL_1,  TblSASColunas=COLUNAS_SUMARIZAR,  NivelCTRA=1,  PAA_PARA_AGENCIA=1,  TblSaida=CBR_QUALIFICACAO_GERAL_1, AAAAMM=&ANOMES.); 
 

PROC STDIZE DATA=CBR_QUALIFICACAO_GERAL_1 OUT=CBR_QUALIFICACAO_GERAL_1 REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_GERAL_2 AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
		  t1.UOR,
		  t1.TOTAL as TOT_DIR,
		  (t1.TOTAL / t1.TOT_CLI)*100 AS TOTAL FORMAT 32.2,
		  t1.QTDE
		            
      FROM CBR_QUALIFICACAO_GERAL_1 t1;

QUIT;


PROC SQL;

   CREATE TABLE CBR_QUALIFICACAO_GERAL_3 AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
		  t1.UOR,
		  t1.TOT_DIR,
		  t1.TOTAL,
          t1.QTDE 
		            
      FROM CBR_QUALIFICACAO_GERAL_2 t1
      GROUP BY 1, 2;

QUIT;


%BuscarPrefixosIndicador(IND=118, MMAAAA=&MESANO., NIVEL_CTRA=1, SO_AG_PAA=0);


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_GERAL_4 AS 
   SELECT t1.PREFDEP, t1.CTRA, t2.UOR, t1.TOTAL, t1.TOT_DIR, t1.QTDE
   FROM CBR_QUALIFICACAO_GERAL_3 t1
   INNER JOIN PREFIXOS_IND_000000118 t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA
   ORDER BY 2, 3;
QUIT;


PROC SQL;
   CREATE TABLE CBR_QUALIFICACAO_GERAL_5 AS 
   SELECT t1.PREFDEP, t1.CTRA, t1.UOR, t1.TOTAL, t1.QTDE
   FROM CBR_QUALIFICACAO_GERAL_4 t1
   ORDER BY 2, 3;
QUIT;


/*ENVIANDO PARA O CONEXÃO*/
/*ENVIANDO PARA O CONEXÃO*/
/*ENVIANDO PARA O CONEXÃO*/
/*ENVIANDO PARA O CONEXÃO*/


PROC SQL;
    CREATE TABLE WORK.PARA_BASE_CONEXAO_COMP AS
        SELECT
            118 as ind, /*CODIGO INDICADOR 180 */
            1 as COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/
            0 as COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/
            1 as ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/
            UOR,
            PREFDEP,
            CTRA,            
            TOTAL as VLR_RLZ, /*VALOR REALIZADO*/
            0 as VLR_ORC, /*VALOR ORÇADO*/
			0 as VLR_ATG, /*VALOR ATINGIMENTO, por padrão 0, enviar somente se o atingimento tiver regra de cálculo*/  
			&D1.  FORMAT YYMMDD10. AS POSICAO /*DATA DO VALOR LEVANTADO*/
        FROM CBR_QUALIFICACAO_GERAL_5
ORDER BY PREFDEP;
QUIT;


PROC SQL;
    CREATE TABLE WORK.PARA_BASE_CONEXAO_IND AS
        SELECT
            118 as ind, /*CODIGO INDICADOR*/
            0 as COMP, /*CODIGO COMPONENTE, SE NÃO FOR COMPONENTE USAR 0*/
            0 as COMP_PAI, /*CODIGO COMPONENTE PAI, SE NÃO FOR COMPONENTE USAR 0*/
            0 as ORD_EXI, /*ORDEM EXIBIÇÃO, SE NÃO FOR COMPONENTE USAR 0*/
            UOR,
            PREFDEP,
            CTRA,            
            TOTAL as VLR_RLZ, /*VALOR REALIZADO*/
            0 as VLR_ORC, /*VALOR ORÇADO*/
			0 as VLR_ATG, /*VALOR ATINGIMENTO, por padrão 0, enviar somente se o atingimento tiver regra de cálculo*/  
			&D1.  FORMAT YYMMDD10. AS POSICAO /*DATA DO VALOR LEVANTADO*/
        FROM CBR_QUALIFICACAO_GERAL_5
ORDER BY PREFDEP;
QUIT;


DATA PARA_BASE_CONEXAO;
SET PARA_BASE_CONEXAO_IND PARA_BASE_CONEXAO_COMP;
BY PREFDEP;
RUN;


PROC SQL;
    CREATE TABLE WORK.BASE_CONEXAO_CLI AS
        SELECT
            118 as IND,
            1 as COMP,
            t1.PREFDEP,
            UOR,
            CTRA,
            MCI as CLI,
            &MESANO as MMAAAA,
            TOTAL as VLR
        FROM CBR_QUALIFICACAO_CLIENTES_1 t1 ;
QUIT;


%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO);
%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CONEXAO_CLI);
/*%ExpCNX_IND_CMPS(118, 2019, MESES=&MES_POSICAO, ORC=0, RLZ=1);*/
%ExportarCNX_CLI(IND=118, MMAAAA=&MESANO);
%ExportarCNX_IND(IND=118, MMAAAA=&MESANO, ORC=0, RLZ=1); /*arquivo indicador*/
%ExportarCNX_COMP(IND=118, MMAAAA=&MESANO, ORC=0, RLZ=1); /*arquivo componentes*/


/*******************************************/
/*******************************************/
/*******************************************/
/*******************************************/
/*****************RELATORIO*****************/
/*******************************************/
/*******************************************/
/*******************************************/
/*******************************************/


/*TABELA GERAL TODOS*/

%BuscarPrefixosIndicador(IND=118, MMAAAA=&MESANO., NIVEL_CTRA=1, SO_AG_PAA=0);


PROC SQL;

   CREATE TABLE RELATORIO_TODOS AS 
      SELECT DISTINCT 

          t1.PREFIXO AS PREFDEP, 
          t1.CARTEIRA AS CTRA,
          t1.MCI,
	      t1.QTDE,
          t1.FATURAMENTO           
		            
      FROM CBR_QUALIFICACAO_5 t1
      INNER JOIN PREFIXOS_IND_000000118 t2 ON t1.PREFIXO = t2.PREFDEP AND t1.CARTEIRA = t2.CTRA;

QUIT;


PROC SQL;

   CREATE TABLE RELATORIO_TODOS_1 AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
		  SUM(t1.QTDE) AS QTDE_NQ,
          SUM(t1.FATURAMENTO) AS FAT_NQ,
          COUNT(t1.MCI) AS TOTAL_NQ 
		            
      FROM RELATORIO_TODOS t1
      GROUP BY 1,2;

QUIT;


/*********************************/


PROC SQL;

   CREATE TABLE RELATORIO_QUALIFICADO AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,          
          t1.QTDE,
		  t1.TOTAL,
          t1.FATURAMENTO AS FAT,
          t1.TOT_CLI                             
		            
      FROM CBR_QUALIFICACAO_GERAL_1 t1;
      
QUIT;


PROC SQL;

   CREATE TABLE RELATORIO_FINAL_ANT AS 
      SELECT DISTINCT 
         t1.PREFDEP, 
         t1.CTRA,
		 t1.QTDE_NQ,
         t1.FAT_NQ,
         t1.TOTAL_NQ,
		 t2.QTDE,		 
         t2.FAT,         
         t2.TOTAL,
		 t2.TOT_CLI
		            
      FROM RELATORIO_TODOS_1 t1
	  LEFT JOIN RELATORIO_QUALIFICADO t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA
      GROUP BY 1,2;       
      
QUIT;


PROC SQL;

   CREATE TABLE RELATORIO_FINAL AS 
      SELECT DISTINCT 
         t1.PREFDEP, 
         t1.CTRA,
		 (t1.QTDE_NQ - t2.QTDE) AS QTDE_NQ,
         (t1.FAT_NQ - t2.FAT) AS FAT_NQ,
         (t1.TOTAL_NQ - t2.TOTAL) AS TOTAL_NQ,
		 t2.QTDE,		 
         t2.FAT,         
         t2.TOTAL,
		 t2.TOT_CLI
		            
      FROM RELATORIO_FINAL_ANT t1
	  LEFT JOIN RELATORIO_QUALIFICADO t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA
      GROUP BY 1,2;       
      
QUIT;


PROC STDIZE DATA=RELATORIO_FINAL OUT=RELATORIO_FINAL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


/*SUMARIZANDO*/


PROC SQL;
DROP TABLE COLUNAS_SUMARIZAR;
CREATE TABLE COLUNAS_SUMARIZAR (Coluna CHAR(50), Tipo CHAR(10));
INSERT INTO COLUNAS_SUMARIZAR VALUES ('QTDE_NQ', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('FAT_NQ', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('TOTAL_NQ', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('QTDE', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('FAT', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('TOTAL', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('TOT_CLI', 'SUM');


QUIT;


/*FUNCAO DE SUMARIZACAO*/ 

%SumarizadorCNX( TblSASValores=RELATORIO_FINAL,  TblSASColunas=COLUNAS_SUMARIZAR,  NivelCTRA=1,  PAA_PARA_AGENCIA=1,  TblSaida=RELATORIO_FINAL, AAAAMM=&ANOMES.); 
 

PROC STDIZE DATA=RELATORIO_FINAL OUT=RELATORIO_FINAL REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


%BuscarPrefixosIndicador(IND=118, MMAAAA=&MESANO., NIVEL_CTRA=0, SO_AG_PAA=0);


PROC SQL;

   CREATE TABLE RELATORIO_FINAL_1 AS 
      SELECT DISTINCT 

         t1.PREFDEP, 
         t1.CTRA,
		 t1.QTDE_NQ FORMAT 32.2,
         t1.FAT_NQ FORMAT 32.2,
         t1.TOTAL_NQ FORMAT 32.2,
		 t1.QTDE FORMAT 32.2,
         t1.FAT FORMAT 32.2,
		 t1.TOTAL FORMAT 32.2,
         t1.TOT_CLI FORMAT 32.2           
		            
      FROM RELATORIO_FINAL t1
	  /*INNER JOIN PREFIXOS_IND_000000118 t2 ON t1.PREFDEP = t2.PREFDEP*/

      ;

QUIT;


data RELATORIO_FINAL_1;
format posicao yymmdd10.;
set RELATORIO_FINAL_1;
POSICAO = &D1;
run;


/*TABELA CLIENTES TODOS*/
/*TABELA CLIENTES TODOS*/
/*TABELA CLIENTES TODOS*/
/*TABELA CLIENTES TODOS*/


PROC SQL;

   CREATE TABLE RELATORIO_TODOS_CLIENTES AS 
      SELECT DISTINCT 

          t1.PREFDEP, 
          t1.CTRA,
          t1.MCI,
		  t1.QTDE AS QTDE_NQ,
		  t1.FATURAMENTO AS FAT_NQ          
		            
      FROM RELATORIO_TODOS t1;

QUIT;


/**/

PROC SQL;

   CREATE TABLE RELATORIO_QUALIFICADO_CLIENTES AS 
    
    SELECT t1.PREFDEP, 
           t1.CTRA, 
           t1.MCI, 
           t1.QTDE, 
           t1.FATURAMENTO AS FAT

    FROM CBR_QUALIFICACAO_CLIENTES_1 t1;

QUIT;


PROC SQL;

   CREATE TABLE RELATORIO_FINAL_CLIENTES_ANT AS 
      SELECT DISTINCT 
         t1.PREFDEP, 
         t1.CTRA,
		 t1.MCI FORMAT 32.2,
		 t1.QTDE_NQ FORMAT 32.2,
         t1.FAT_NQ FORMAT 32.2,
		 t2.QTDE FORMAT 32.2,
         t2.FAT FORMAT 32.2                          
		            
      FROM RELATORIO_TODOS_CLIENTES t1
	  LEFT JOIN RELATORIO_QUALIFICADO_CLIENTES t2 ON t1.PREFDEP = t2.PREFDEP AND t1.CTRA = t2.CTRA AND t1.MCI = t2.MCI
      GROUP BY 1,2,3;       
      
QUIT;


PROC STDIZE DATA=RELATORIO_FINAL_CLIENTES_ANT OUT=RELATORIO_FINAL_CLIENTES_ANT REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;

   CREATE TABLE RELATORIO_FINAL_CLIENTES AS 
      SELECT DISTINCT 
         t1.PREFDEP, 
         t1.CTRA,
		 t1.MCI,
		 (t1.QTDE_NQ - t1.QTDE) AS QTDE_NQ,
         (t1.FAT_NQ - t1.FAT) AS FAT_NQ,
		 t1.QTDE,
         t1.FAT                          
		            
      FROM RELATORIO_FINAL_CLIENTES_ANT t1
	  GROUP BY 1,2,3;       
      
QUIT;



/*RELATORIO*/
/*RELATORIO*/
/*RELATORIO*/
/*RELATORIO*/
/*550*/


%LET Usuario=f7176219;
%LET Keypass=cobranca-qualificada-2019-JN1ZuV16j1BwU0fSfESAiQLIPZUJRxOdDtnf7pIrHAhwirl3kb;
%LET Rotina=cobranca-qualificada-2019;
%ProcessoIniciar();


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('RELATORIO_FINAL_1', 'cobranca-qualificada-2019');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('RELATORIO_FINAL_CLIENTES', 'detalhe');
   ;
QUIT;


%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);

 x cd /dados/gecen/interno/bases/cbr;
 x cd /dados/gecen/interno/bases/bcn;
 x cd /dados/infor/producao/cobranca_qualificada_19;

 x chmod 2777 *;
