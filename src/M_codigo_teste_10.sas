
%include '/dados/infor/suporte/FuncoesInfor.sas';
%IniciarProcessoMySQL(Direcionador Cobrança - Julho/2019 - 291, Ernani);
LIBNAME CBR '/dados/infor/producao/cobranca';

%Libconexao19(291);
%LET AnoMes=201907;

/*(11) 4298-7355*/
DATA _NULL_;
	IF &AnoMes=0 THEN
		D0=Today();
	ELSE
		DO;
			AA=Floor(&AnoMes/100);
			MM=&AnoMes-(AA*100);
			D0=IntNx('month',MDY(MM,1,AA),1);
		END;

	D1=DiaUtilAnterior(Smallest(1,D0,Today()));
	CALL SYMPUT('D1',D1);
	CALL SYMPUT('AnoMes',Put(D1, yymmn6.));
	CALL SYMPUT('MesAno',Put(D1, mmyyn6.));
RUN;

%Put &D1 &AnoMes &MesAno;

%BuscarPrefixosIndicador(IND=291, MMAAAA=&MesAno, NIVEL_CTRA=1, SO_AG_PAA=0);

PROC SQL NOPRINT;
	SELECT DISTINCT CD_TIP_CTRA INTO :LTC Separated By ' '
		FROM COMUM.CTRA_VALIDA_&AnoMes(WHERE=(CD_TIP_CTRA NE 0)) A
			INNER JOIN PREFIXOS_IND_000000291 B ON(A.CD_PRF_DEPE=B.PREFDEP AND A.NR_SEQL_CTRA=B.CTRA);
QUIT;

%PUT &LTC;

PROC SQL;
	CREATE TABLE BASE_CLIENTES AS
		SELECT *, 
			IFN(CD_TIP_CTRA=328,30,IFN(CD_TIP_CTRA IN(303 321 322),150,100)) AS Meta_Cli
		FROM COMUM.PAI_REL_PJ_&AnoMes
			WHERE CD_TIP_CTRA IN(&LTC)
				ORDER BY CD_CLI;
QUIT;

PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	CREATE TABLE CNV_COBR AS
		SELECT NR_OPR_CLI_CBR AS NR_OPR, CD_CLI, DT_INCL_CTR Format ddmmyy10. AS DT_INCL
			FROM CONNECTION TO DB2
				(SELECT NR_OPR_CLI_CBR, CD_CLI, DT_INCL_CTR
					FROM DB2CBR.CTR_CLI_CBR
						WHERE CD_CLI<>0)
						WHERE DT_INCL_CTR<=SMALLEST(1,&D1,MDY(6,30,2019));
	DISCONNECT FROM DB2;
QUIT;

DATA RESUMO_REMESSA(DROP=TTL_ACM VLR_ACM);
	MERGE CBR.RESUMO_RMSS_2018 CBR.RESUMO_RMSS_2019;
	BY CD_CLI NR_OPR DT_INCL;
RUN;

PROC STDIZE OUT=RESUMO_REMESSA REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;

PROC CONTENTS NOPRINT DATA=RESUMO_REMESSA OUT=LIXO(KEEP=NAME);
RUN;

PROC SQL NOPRINT;
	SELECT DISTINCT NAME INTO :CPT Separated By '+'
		FROM LIXO
			WHERE NAME CONTAINS 'TTL_2019';
QUIT;

%PUT &CPT;

PROC SQL NOPRINT;
	SELECT DISTINCT NAME INTO :CPV Separated By '+'
		FROM LIXO
			WHERE NAME CONTAINS 'VLR_2019';
QUIT;

%PUT &CPV;

PROC SQL;
	CREATE TABLE VLR_MCI AS
		SELECT A.CD_CLI, SUM(&CPT) AS TTL_ACM,
			SUM(&CPV) AS VLR_ACM
		FROM CNV_COBR A
			INNER JOIN RESUMO_REMESSA B ON(A.NR_OPR=B.NR_OPR)
				GROUP BY 1
					HAVING CALCULATED TTL_ACM NE 0;
QUIT;

DATA BASE_CLIENTES(WHERE=(Publico_Alvo=1));
	MERGE BASE_CLIENTES(IN=A) VLR_MCI(OBS=0 KEEP=CD_CLI TTL_ACM);
	BY CD_CLI;
	TTL_ACM=COALESCE(TTL_ACM,0);
	Publico_Alvo=(TTL_ACM=0);

	IF A;
RUN;

LIBNAME CBR '/dados/gecen/interno/bases/cbr';

%macro montar_view;

	data _null_;
		set cbr.conv_tip_evt_tarf end=last;
		call symputx ('operador'||left(_n_), operador);
		call symputx ('nr_ctra_cbr'||left(_n_), nr_ctra_cbr);
		call symputx ('cd_tip_gr_itc_cbr'||left(_n_), cd_tip_gr_itc_cbr);
		call symputx ('cd_fma_entd_itc'||left(_n_), cd_fma_entd_itc);
		call symputx ('cd_tip_evt_tarf'||left(_n_), cd_tip_evt_tarf);

		if last then
			call symputx ('count',_n_);
		;
	run;

	proc sql;
		drop table db2sgcen.drc_291_190702;
		connect to db2 (authdomain=db2sgcen database=bdb2p04);
		execute (
			create view drc_291_190702 as
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
		end 
		as cd_tip_evt_tarf,
			case 
				when t3.cd_fnld_ctra_cbr in (30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) then t3.cd_fnld_ctra_cbr 
				else 0 
			end 
			as cd_tip_sgm_cbr,               
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
	create table tbl_0001 as select * from connection to db2 (
		select   
			a.dt_per_mvt_tit, a.cd_prd, a.cd_mdld, a.cd_cli, a.cd_prf_depe, a.nr_cc, a.nr_opr_cli_cbr, a.nr_ctra_cbr, a.nr_vrc_ctra_cbr,
			a.cd_tip_evt_tarf, a.cd_tip_sgm_cbr, a.qt_tit_gr_itc, a.vl_ttl_tit_gr_itc, a.pc_tarf_evt_cbr, a.vl_tarf_evt_cbr,
		case
			when a.cd_tip_sgm_cbr in (30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) or a.in_flz_tarf_atv = 'N' then a.vl_tarf_evt_cbr
			else round((a.pc_tarf_evt_cbr / 100) * a.vl_tarf_evt_cbr, 2)
		end 
	as vl_tarf_flex,
		case
			when a.cd_tip_sgm_cbr in (30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40) or a.in_flz_tarf_atv = 'N' then round(a.qt_tit_gr_itc * a.vl_tarf_evt_cbr, 2)
			else round(((a.pc_tarf_evt_cbr / 100) * a.vl_tarf_evt_cbr) * a.qt_tit_gr_itc, 2)
		end 
	as vl_ttl_tarf_flex,
		round(qt_tit_gr_itc * vl_tarf_evt_cbr, 2) as vl_ttl_tarf_cheia
	from (
		select
			t1.*,
			t2.dt_inc_vgc_tarf,
			t2.dt_fim_vgc_tarf,
			t2.dt_incl_flz,
			t2.hr_incl_flz,
		case 
			when t2.pc_tarf_evt_cbr is null then 100 
			else t2.pc_tarf_evt_cbr 
		end 
	as pc_tarf_evt_cbr,
		case 
			when t2.in_flz_tarf_atv is null then 'N' 
			else t2.in_flz_tarf_atv 
		end 
	as in_flz_tarf_atv,
		t3.vl_tarf_evt_cbr,
		row_number() over(
		partition by t1.dt_per_mvt_tit, t1.nr_opr_cli_cbr, t1.nr_ctra_cbr, t1.nr_vrc_ctra_cbr, t1.cd_tip_evt_tarf
	order by t2.in_flz_tarf_atv desc, t2.dt_incl_flz desc, t2.hr_incl_flz desc
		) as posicao
	from
		(
	select dt_per_mvt_tit, cd_prd, cd_mdld, cd_cli, cd_prf_depe, nr_cc, nr_opr_cli_cbr, nr_ctra_cbr, nr_vrc_ctra_cbr, cd_tip_evt_tarf, cd_tip_sgm_cbr,
		sum(qt_tit_gr_itc) as qt_tit_gr_itc, sum(vl_ttl_tit_gr_itc) as vl_ttl_tit_gr_itc
	from db2sgcen.drc_291_190702 as t1
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
		FROM tbl_0001 t1
			WHERE CD_PRD = 14 AND MONTH(DT_PER_MVT_TIT) = MONTH(&D1) AND YEAR(DT_PER_MVT_TIT) = YEAR(&D1) AND CD_TIP_EVT_TARF IN (1, 2, 19)
				ORDER BY 1;
	drop table db2sgcen.drc_291_190702;
QUIT;

/*PROC SQL;*/
/*	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);*/
/*	EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;*/
/*	CREATE TABLE RMSS_COBR AS*/
/*		SELECT CD_TIP_PER_MVT_TIT, CD_TIP_PER_MVT_TIT, AA_PER_MVT_TIT, MM_PER_MVT_TIT, DD_PER_MVT_TIT,*/
/*			NR_OPR, SUM(QT_TIT) AS QTD_TTL, SUM(VALOR) AS VALOR,*/
/*			(AA_PER_MVT_TIT*1000)+MM_PER_MVT_TIT AS AnoMes*/
/*		FROM CONNECTION TO DB2*/
/*			(SELECT A.NR_OPR_CLI_CBR AS NR_OPR, VL_TTL_TIT_GR_ITC AS VALOR, QT_TIT_GR_ITC AS QT_TIT,*/
/*				CD_TIP_PER_MVT_TIT, AA_PER_MVT_TIT, MM_PER_MVT_TIT, DD_PER_MVT_TIT*/
/*			FROM DB2CBR.ETTC_GR_ITC_CLI A*/
/*				WHERE CD_TIP_GR_ITC_CBR=1 */
/*					AND CD_FMA_ENTD_ITC IN (5, 23, 25, 54) */
/*					AND NR_CTRA_CBR IN (11, 17, 31, 51)*/
/*					AND ((AA_PER_MVT_TIT*100)+MM_PER_MVT_TIT)=&AnoMes)*/
/*				GROUP BY 1, 2, 3, 4, 5, 6;*/
/*	DISCONNECT FROM DB2;*/
/*QUIT;*/
/*DATA RMSS_COBR(WHERE=(DT_VRF<=MDY(7,31,2019)));*/
/*	SET RMSS_COBR;*/
/*	Format DT_VRF ddmmyy10.;*/
/*	DT_VRF=MDY(MM_PER_MVT_TIT,DD_PER_MVT_TIT,AA_PER_MVT_TIT);*/
/*RUN;*/
/**/
/*PROC SORT DATA=RMSS_COBR(KEEP=AnoMes AA_PER_MVT_TIT MM_PER_MVT_TIT CD_TIP_PER_MVT_TIT) OUT=TESTE NODUPKEY;*/
/*	BY AnoMes CD_TIP_PER_MVT_TIT;*/
/*RUN;*/
/**/
/*DATA TESTE(DROP=Seq);*/
/*	SET TESTE;*/
/*	BY AnoMes;*/
/**/
/*	IF FIRST.AnoMes THEN*/
/*		Seq=0;*/
/*	Seq+1;*/
/**/
/*	IF Seq>1 THEN*/
/*		DELETE;*/
/*RUN;*/
/*PROC  SQL;*/
/*	CREATE TABLE RMSS_FIM AS*/
/*		SELECT A.**/
/*			FROM RMSS_COBR(DROP=AnoMes) A*/
/*				INNER JOIN TESTE B ON(A.AA_PER_MVT_TIT=B.AA_PER_MVT_TIT AND A.MM_PER_MVT_TIT=B.MM_PER_MVT_TIT AND A.CD_TIP_PER_MVT_TIT=B.CD_TIP_PER_MVT_TIT);*/
/*QUIT;*/
/*PROC SQL;*/
/*	CREATE TABLE RMSS_MCI_CNV AS*/
/*		SELECT CD_PRF_DEPE, NR_SEQL_CTRA, CD_TIP_CTRA, B.CD_CLI, DT_INCL, A.NR_OPR, (AA_PER_MVT_TIT*100)+MM_PER_MVT_TIT AS AnoMes,*/
/*			Meta_Cli, SUM(QTD_TTL) AS QTD_TTL, SUM(VALOR) AS VALOR*/
/*	FROM RMSS_FIM A*/
/*		INNER JOIN CNV_COBR B ON(A.NR_OPR=B.NR_OPR)*/
/*		INNER JOIN BASE_CLIENTES C ON(B.CD_CLI=C.CD_CLI AND C.Publico_Alvo=1)*/
/*			GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;*/
/*QUIT;*/

PROC SQL;
	CREATE TABLE RMSS_MCI_CNV AS
		SELECT CD_PRF_DEPE, NR_SEQL_CTRA, CD_TIP_CTRA, A.CD_CLI, Input(Put(DT_PER_MVT_TIT, yymmn6.), 6.) AS AnoMes,
			Meta_Cli, SUM(QT_TIT_GR_ITC) AS QTD_TTL
		FROM TAB_CBR_1 A
			INNER JOIN BASE_CLIENTES C ON(A.CD_CLI=C.CD_CLI)
				GROUP BY 1, 2, 3, 4, 5, 6;
QUIT;

PROC SQL;
	CREATE TABLE AUX_ATG AS
		SELECT CD_CLI, SUM(QTD_TTL) AS QTD_TTL
	FROM RMSS_MCI_CNV
		GROUP BY CD_CLI, Meta_Cli;
QUIT;

DATA _NULL_;
	CALL SYMPUT('FLT_INI',IntNx('month',&D1,0,'b'));
RUN;

PROC SQL;
	CREATE TABLE MARCA_ATG AS
		SELECT A.*, B.QTD_TTL/*, DT_INCL>=&FLT_INI AS Novo*/
	FROM RMSS_MCI_CNV A
		INNER JOIN AUX_ATG B ON(A.CD_CLI=B.CD_CLI);
QUIT;

DATA IGR(KEEP=Prefixo Gerev Super Diretoria VP AGC TD CD_UOR);
	SET IGR.IGRREDE_&AnoMes;
	CD_UOR=Input(UOR, 9.);
	Prefixo=Input(PrefDep, 4.);
	Gerev=Input(PrefSupReg, 4.);
	Super=Input(PrefSupESt, 4.);
	Diretoria=Input(PrefUEN, 4.);
	VP=8166;

	IF TipoDep='01' THEN
		AGC=Input(PrefAgenc, 4.);
	ELSE AGC=Prefixo;
	TD=Input(TipoDep, 2.);
RUN;

PROC SQL;
	CREATE TABLE BASE_CONEXAO_CLI AS
		SELECT 291 AS IND, 1 AS COMP,
			CD_PRF_DEPE AS PrefDep,
			CD_UOR AS UOR,
			NR_SEQL_CTRA AS CTRA, CD_CLI AS CLI,
			&MesAno AS MMAAAA,
			SUM(QTD_TTL) AS VLR
		FROM MARCA_ATG A
			INNER JOIN IGR B ON(A.CD_PRF_DEPE=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(A.CD_PRF_DEPE=C.PREFDEP AND A.NR_SEQL_CTRA=C.CTRA)
				GROUP BY 3, 4, 5, 6;
QUIT;

/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CONEXAO_CLI);*/
%BuscarOrcado(291, &MesAno);

PROC SQL;
	CREATE TABLE CRT AS
		SELECT 291 AS IND, 0 AS COMP, 0 AS COMP_PAI, 0 AS ORD_EXI, CD_UOR AS UOR,
			CD_PRF_DEPE AS PrefDep, NR_SEQL_CTRA AS CTRA, Sum(QTD_TTL) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG,
			&D1 Format yymmdd10. AS Posicao
		FROM MARCA_ATG A
			INNER JOIN IGR B ON(A.CD_PRF_DEPE=B.Prefixo)
				GROUP BY 6, 7, 5, Meta_Cli;
QUIT;

PROC SQL;
	CREATE TABLE AUX_CRT AS
		SELECT A.*, VLR_MJD, Ceil(Smallest(1,VLR_MJD*1.2,A.VLR)) AS NOVO_VALOR
			FROM CRT A
				INNER JOIN ORCADOS_000000291 B ON(A.PrefDep=B.PrefDep AND A.CTRA=B.CTRA);
QUIT;

DATA PREFIXOS_IND_000000291(WHERE=(CTRA=0));
	SET PREFIXOS_IND_000000291;
RUN;

PROC SQL;
	CREATE TABLE PAA AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, A.UOR,
			A.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(A.PrefDep=C.PrefDep)
				WHERE TD=1
					GROUP BY 6, 2, 1, 3, 4, 5, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.AGC=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE AGC AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.Gerev=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE GRV AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.Super=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE SUP AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.Diretoria=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE DIR AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.VP=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE VIP AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000291 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

DATA PARA_BASE_CONEXAO;
	SET CRT PAA AGC GRV SUP DIR VIP;
RUN;

PROC SORT DATA=PARA_BASE_CONEXAO;
	BY PREFDEP CTRA COMP;
RUN;

DATA INDICADOR(RENAME=(VLR=VLR_RLZ));
	SET PARA_BASE_CONEXAO;
	BY PREFDEP CTRA COMP;
RUN;

/*%BaseIndicadorCNX(TabelaSAS=INDICADOR);
%ExportarCNX_IND(IND=291, MMAAAA=&mesano, ORC=0, RLZ=1);
%ExportarCNX_COMP(IND=291, MMAAAA=&mesano, ORC=0, RLZ=1);
%ExportarCNX_CLI(IND=291, MMAAAA=&MesAno);*/
%EncerrarProcessoMySQL(Direcionador Cobrança - Julho/2019 - 291);
/*INDICADOR 273*/
%IniciarProcessoMySQL(Indicador Cobrança - 273, Ernani);
%BuscarPrefixosIndicador(IND=273, MMAAAA=&MesAno, NIVEL_CTRA=1, SO_AG_PAA=0);
%BuscarOrcado(273, &MesAno);

PROC SQL;
	CREATE TABLE BASE_CONEXAO_CLI AS
		SELECT 273 AS IND, 15 AS COMP,
			CD_PRF_DEPE AS PrefDep,
			CD_UOR AS UOR,
			NR_SEQL_CTRA AS CTRA, CD_CLI AS CLI,
			&MesAno AS MMAAAA,
			SUM(QTD_TTL) AS VLR
		FROM MARCA_ATG A
			INNER JOIN IGR B ON(A.CD_PRF_DEPE=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(A.CD_PRF_DEPE=C.PREFDEP AND A.NR_SEQL_CTRA=C.CTRA)
				GROUP BY 3, 4, 5, 6;
QUIT;

/*%BaseIndicadorCNX_CLI(TabelaSAS=BASE_CONEXAO_CLI);*/

PROC SQL;
	CREATE TABLE CRT AS
		SELECT 273 AS IND, 0 AS COMP, 0 AS COMP_PAI, 0 AS ORD_EXI, CD_UOR AS UOR,
			CD_PRF_DEPE AS PrefDep, NR_SEQL_CTRA AS CTRA, Sum(QTD_TTL) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG,
			&D1 Format yymmdd10. AS Posicao
		FROM MARCA_ATG A
			INNER JOIN IGR B ON(A.CD_PRF_DEPE=B.Prefixo)
				GROUP BY 6, 7, 5, Meta_Cli;
QUIT;

PROC SQL;
	CREATE TABLE AUX_CRT AS
		SELECT A.*, VLR_MJD, Ceil(Smallest(1,VLR_MJD*1.1,A.VLR)) AS NOVO_VALOR
			FROM CRT A
				INNER JOIN ORCADOS_000000273 B ON(A.PrefDep=B.PrefDep AND A.CTRA=B.CTRA);
QUIT;

DATA PREFIXOS_IND_000000273(WHERE=(CTRA=0));
	SET PREFIXOS_IND_000000273;
RUN;

PROC SQL;
	CREATE TABLE PAA AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, A.UOR,
			A.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(A.PrefDep=C.PrefDep)
				WHERE TD=1
					GROUP BY 6, 2, 1, 3, 4, 5, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.AGC=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE AGC AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.Gerev=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE GRV AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.Super=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE SUP AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.Diretoria=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE DIR AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

PROC SQL;
	CREATE VIEW AUX_IGR AS
		SELECT A.*, B.CD_UOR AS UOR, B.Prefixo AS PrefDep
			FROM IGR A
				INNER JOIN IGR B ON(A.VP=B.Prefixo)
					WHERE A.TD IN(1 9)
						ORDER BY 10;
QUIT;

PROC SQL;
	CREATE TABLE VIP AS
		SELECT A.IND, COMP, COMP_PAI, ORD_EXI, B.UOR,
			B.PrefDep, Posicao,
			0 AS CTRA, Sum(NOVO_VALOR) AS VLR, 0 AS VLR_ORC, 0 AS VLR_ATG
		FROM AUX_CRT A
			INNER JOIN AUX_IGR B ON(A.PrefDep=B.Prefixo)
			INNER JOIN PREFIXOS_IND_000000273 C ON(B.PrefDep=C.PrefDep)
				GROUP BY 6, 2, 3, 4, 5, 1, 7;
QUIT;

DATA PARA_BASE_CONEXAO;
	SET CRT PAA AGC GRV SUP DIR VIP;
RUN;

PROC SORT DATA=PARA_BASE_CONEXAO;
	BY PREFDEP CTRA COMP;
RUN;

DATA INDICADOR(RENAME=(VLR=VLR_RLZ));
	SET PARA_BASE_CONEXAO;
	BY PREFDEP CTRA COMP;
RUN;

/*%BaseIndicadorCNX(TabelaSAS=INDICADOR);
%ExportarCNX_IND(IND=273, MMAAAA=&mesano, ORC=0, RLZ=1);
%ExportarCNX_COMP(IND=273, MMAAAA=&mesano, ORC=0, RLZ=1);
%ExportarCNX_CLI(IND=273, MMAAAA=&MesAno);*/
%EncerrarProcessoMySQL(Indicador Cobrança - 273);
x cd /dados/infor/producao/auxiliar;
x chmod 2777 *;

/*************************************************/;
/* TRECHO DE CÓDIGO INCLUÍDO PELO FF */;
%processCheckOut(
	uor_resp = 341556
	,funci_resp = &sysuserid
	/*,tipo = Indicador
	,sistema = Indicador
	,rotina = I0123 Indicador de Alguma Coisa*/
	,mailto= 'F8369937' 'F2986408' 'F6794004' 'F7176219' 'F8176496' 'F9457977' 'F9631159'
	);
