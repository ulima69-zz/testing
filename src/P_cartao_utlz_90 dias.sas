%LET NomePasta=desembolsopj;
			%LET NomeRelatorio=Cartão em Uso;
			%LET Indicador=000000114;
			%let comp1 = 1; /*possui CARTÃO*/
			%let inicio_sem = 1jul2018;
			%let fim_sem =	31dec2018;

			%libconexao(114);

			/*#################################################################################################################*/
			/*##### B I B L I O T E C A S #####*/
			LIBNAME DB2DEB	db2 AUTHDOMAIN=DB2SGCEN schema=DB2DEB database=BDB2P04;
			libname bcs clear;
			libname baux clear;
			libname bcn clear;
			libname cdc clear;
			libname cop clear;
			libname opr clear;
			libname pub clear;
			libname rot clear;
			libname sinergia clear;
			libname gfi clear;
			libname coc clear;
			libname deb clear;
			libname igs clear;
			libname rdo clear;
			libname bic clear;
			libname opr 	"/dados/gecen/interno/bases/opr" filelockwait=600 access=readonly;
			LIBNAME PAI 	"/dados/publica/b_dados";
			libname anc 	"/dados/gecen/interno/bases/anc" filelockwait=600 access=readonly;
			libname mci 	"/dados/gecen/interno/bases/mci" filelockwait=600 access=readonly;
			libname cer 	"/dados/prep/bases/cer" filelockwait=600 access=readonly;
			LIBNAME CON		"/dados/infor/conexao/2018/&Indicador";
			libname acomp 	"/dados/infor/ATB/conexao_2018_acompanhamentos";
			libname mci 	"/dados/gecen/interno/bases/mci" filelockwait=600 access=readonly;
			libname dimep 	"/dados/infor/producao/Dimep/cartoes_em_uso";
			libname xxx 	"/dados/infor/desenvolvimento/wagner/cartoes";

/*			%diasUteis(%sysfunc(mdy(10,1,2018)), 5);*/
			%diasUteis(%sysfunc(today()), 5);

			data arq;
				format 
					anomes yymmn6.
					mesano 6.
					DiaUtil_D1 date9.
					DiaUtil_D2 date9.
					inicio_sem date9.
					fim_sem date9.
					mes z2.
					ano 4.;
				anomes = &DiaUtil_D1;
				mesano = INPUT(PUT(&DiaUtil_D1, mmyyn6.),6.);
				DiaUtil_D1 = &DiaUtil_D1;
				DiaUtil_D2 = &DiaUtil_D2;
				inicio_sem = "&inicio_sem"d;
				fim_sem = "&fim_sem"d;
				mes = month(&DiaUtil_D1);
				ano = year(&DiaUtil_D1);
				menos_90 = &DiaUtil_D1 -90;
			run;

			proc sql;
				select anomes, DiaUtil_D1, DiaUtil_D2, inicio_sem, fim_sem, mes, ano, mesano, menos_90
					into :anomes, :DiaUtil_D1, :DiaUtil_D2, :inicio_sem, :fim_sem, :mes, :ano, :mesano, :menos_90
						from arq;
			quit;

			%put &anomes - &DiaUtil_D1 - &DiaUtil_D2 - &inicio_sem - &fim_sem - &ano - &mes - &mesano;

			%conectardb2(vip);

			data _null_;
				call symput('inicio',"'"||put(&menos_90, yymmdd10.)||"'");
				call symput('ref',"'"||put(intnx('month', "&diautil_d1"d, 0), yymmdd10.)||"'");
			run;

/*			%let ref =30sep2018;*/
/*			%let inicio=1sep2018;*/
			%put &ref &inicio;

			proc sql;
				connect to db2 (authdomain=db2sgcen database=bdb2p04);
				create table compras_saques as 
					select * from connection to db2
					(select 
						t2.cd_cli, 
						t2.cd_mdld_crt,
						max(DT_MVT_CT_CRT) as data_utlz,
						sum(t1.vl_mvt_ct_crt) as valor
					from db2vip.mvt_ct_crt t1,
						db2vip.fat_ct_crt t4, 
						db2vip.ct_crt t2, 
						db2vip.ettc_item t3, 
						db2vip.tip_tran t5
					where (t1.nr_seql_fat_ct_crt = t4.nr_seql_fat_ct_crt 
						and t4.nr_ctr_opr_ct_crt = t2.nr_ct_crt 
						and t3.cd_item_ettc = t5.cd_item_ettc 
						and t1.cd_tip_tran = t5.cd_tran) 
						and t1.DT_MVT_CT_CRT >= &inicio 
						and t1.DT_MVT_CT_CRT < &ref 
/*						and t1.dt_incl_sis >= '2018-08-01' and t1.dt_incl_sis <= '2018-08-31'*/
						and t3.cd_item_ettc in (27, 28, 29, 31, 32, 33)
					group by t2.cd_cli, t2.cd_mdld_crt);
				disconnect from db2;
			quit;

			proc sql;
				connect to db2 (authdomain=db2sgcen database=bdb2p04);
				create table pgto_cts as 
					select * from connection to db2
					(select distinct 
						t2.cd_cli, 	
						t2.cd_mdld_crt,
						max(dt_pgto_ct) as data_utlz,
						sum(t1.vl_pgto_rlzd) as valor
					from db2vip.pgto_ct_pcl_unco t1
						inner join db2vip.ct_crt t2 on (t1.nr_ct_crt = t2.nr_ct_crt)
							where dt_pgto_ct >= &inicio  and dt_pgto_ct < &ref
/*							where dt_pgto_ct >= '2018-08-01'  and dt_pgto_ct <= '2018-08-31' */
								group by t2.cd_cli, t2.cd_mdld_crt);
				disconnect from db2;
			quit;

			proc sql;
				connect to db2 (authdomain=db2sgcen database=bdb2p04);
				create table cpr_pcld as 
					select * from connection to db2
					(select 
						t2.cd_cli, 
						t2.cd_mdld_crt,
						max(t1.DT_CPR) as data_utlz,
						sum(t1.vl_cpr_real) as valor 
					from db2vip.cpr_pcld t1 
						inner join db2vip.ct_crt t2 on (t1.nr_ct_crt = t2.nr_ct_crt) 
							where t1.DT_CPR >= &inicio
								and t1.DT_CPR < &ref
								and t1.tip_tran in ( '01', '02', '51', '52', '53' ) 
							group by t2.cd_cli, t2.cd_mdld_crt);
				disconnect from db2;
			quit;

			proc sql;
				create table tran as 
					select * from compras_saques
						outer union corr 
							select * from pgto_cts
								outer union corr 
									select * from cpr_pcld;
			quit;

			proc sql;
				create table base_qtde_cartoes_&anomes as 
					select distinct 
						cd_cli, 
						cd_mdld_crt, 	
						sum(valor) as valor
					from tran 
						group by 1,2
							order by 1,2;
			quit;

			proc sql;
				create table dimep.utlz_90_dias as 
					select 
						cd_cli, 
						count(distinct cd_cli) as qtde,
						sum(valor) as valor
					from base_qtde_cartoes_&anomes 
						where cd_mdld_crt in (1 4 5 6 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 25 26 27 28 29 36 37 
							46 47 48 49 50 51 53 55 59 63 64 65 72 74 76 78 80 83 85 87 90 92 93 94 98 
							102 109 111 116 117 118 119 127 129 131 133 135 137 153 154 157 158 163 169 
							171 179 181 183 204 205 206 207 149 165 167 168 178 192 193 194 195 202 203)
						group by 1
							having valor >=100;
			quit;
