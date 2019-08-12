

%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";

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
		drop table db2sgcen.gcen_ettc_gr_itc_cli;

		connect to db2 (authdomain=db2sgcen database=bdb2p04);
		execute (
			create view gcen_ettc_gr_itc_cli as
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
					aa_per_mvt_tit >= year(current date - 7 days) and mm_per_mvt_tit >= month(current date - 7 days) and dd_per_mvt_tit >= day(current date - 7 days) and cd_tip_per_mvt_tit = 'D'
				and t1.nr_ctra_cbr > 0 and t1.nr_vrc_ctra_cbr > 0
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
				from db2sgcen.gcen_ettc_gr_itc_cli as t1
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














proc sql;
	insert into cbr.tit_cbr_lqdd_cli
	select *
	from work.tbl_0001;
quit;



x cd &path_bases./cbr;
x chmod -R 775 *;
x chgrp -R GSASBQA *;
x chmod 775 *.sas7bndx;
x chgrp GSASBQA *.sas7bndx;



