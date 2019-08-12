%include '/dados/infor/suporte/FuncoesInfor.sas';

%LET NomeRelatorio=Cartão em Uso;
			%LET Indicador=000000114;
			%let comp1 = 1; /*possui CARTÃO*/
			%let inicio_sem = 1jul2018;
			%let fim_sem =	31dec2018;

			%libconexao(114);

			/*#################################################################################################################*/
			/*##### B I B L I O T E C A S #####*/
			%conectardb2(vip);
			%conectardb2(deb);
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
			libname CQPF 	"/dados/infor/desenvolvimento/qualificacao_clientes_pf";
		    LIBNAME DB2ATB	db2 AUTHDOMAIN=DB2SGCEN schema=DB2ATB database=BDB2P04;

%diasUteis(%sysfunc(TODAY()), 5);

data arq;
format dia date9.;
    dia = (intnx('month',&diautil_d1, 0, 'begin'));
    roda= ifn (day(&diautil_d1)<= 20,1,0);
	D1 = diaUtilAnterior(dia);
run;

proc sql;
    select distinct dia into: dia separated by ', '
    from work.arq;
    select distinct roda into: roda separated by ', '
    from work.arq;
	select distinct D1 into: D1 separated by ', '
    from work.arq;
quit;

%macro roda;
	%if &roda = 1 %then
		%do;

			%let diautil_d1 = &d1; 

				data arq;
				format 
					anomes yymmn6.
					anomes_a yymmn6.
					anomes_a1 yymmn6.
					anomes_a2 yymmn6.
					mesano 6.
					DiaUtil_D1 date9.
					DiaUtil_D2 date9.
					inicio_sem date9.
					fim_sem date9.
					mes z2.
					ano 4.
                    mes_a z2.;
				anomes = &DiaUtil_D1;
				anomes_a = intnx('month', &diautil_d1, -1);
				anomes_a1 = intnx('month', &diautil_d1, -2);
				anomes_a2 = intnx('month', &diautil_d1, -3);
				mesano = INPUT(PUT(&DiaUtil_D1, mmyyn6.),6.);
				DiaUtil_D1 = &DiaUtil_D1;
				DiaUtil_D2 = &DiaUtil_D2;
				inicio_sem = "&inicio_sem"d;
				fim_sem = "&fim_sem"d;
				mes = month(&DiaUtil_D1);
				mes_a = (month(&DiaUtil_D1)-1);
				ano = year(&DiaUtil_D1);
				mes_fat = ifc (mes = 5,'&mes, &mes_a','&mes');

			run;

			proc sql;
				select anomes, anomes_a, anomes_a1, anomes_a2, DiaUtil_D1, DiaUtil_D2, inicio_sem, fim_sem, mes, ano, mesano, mes_a, mes_fat
					into :anomes, :anomes_a, :anomes_a1, :anomes_a2, :DiaUtil_D1, :DiaUtil_D2, :inicio_sem, :fim_sem, :mes, :ano, :mesano, :mes_a, :mes_fat
						from arq;
			quit;

				%put &anomes - &DiaUtil_D1 - &DiaUtil_D2 - &inicio_sem - &fim_sem - &ano - &mes - &mesano - &mes_a;

				%conectardb2(vip);

				data _null_;
					call symput('fim',"'"||put((intnx('month',"&diautil_d1"d, 0, 'end')), yymmdd10.)||"'");
					call symput('inicio',"'"||put("&diautil_d1"d - 90, yymmdd10.)||"'");
				run;

	/*			%let ref = '2019-01-11';
				%let inicio=1sep2018;*/
				%put &fim &inicio;

			

			proc sql;
	create table tran as 
		select * from dimep.TRAN_&anomes_a2
			outer union corr 
				select * from dimep.TRAN_&anomes_a1
					outer union corr 
						select * from dimep.TRAN_&anomes_a
							outer union corr 
								select * from dimep.TRAN_&anomes;
quit;

			proc sql;
				create table base_qtde_cartoes_&anomes as 
					select distinct 
						cd_cli, 
						cd_mdld_crt, 	
						data_utlz,
						sum(valor) as valor
					from tran 
						group by 1, 2, 3
							order by 1, 2;
			quit;

			/*consulta para detalhamento*/
			proc sql;
				create table tran_limp_mdld_d as 
					select 
						cd_cli, 
						cd_mdld_crt,
						data_utlz,
						sum(ifn (cd_mdld_crt in (1 4 5 6 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 25 26 27 28 29 36 37 
							46 47 48 49 50 51 53 55 59 63 64 65 72 74 76 78 80 83 85 87 90 92 93 94 98 
							102 109 111 116 117 118 119 127 129 131 133 135 137 153 154 157 158 163 169 
							171 179 181 183 204 205 206 207 149 165 167 168 178 192 193 194 195 202 203),valor,0)) as valor,
							sum(ifn (cd_mdld_crt not in (1 4 5 6 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 25 26 27 28 29 36 37 
							46 47 48 49 50 51 53 55 59 63 64 65 72 74 76 78 80 83 85 87 90 92 93 94 98 
							102 109 111 116 117 118 119 127 129 131 133 135 137 153 154 157 158 163 169 
							171 179 181 183 204 205 206 207 149 165 167 168 178 192 193 194 195 202 203),valor,0)) as outros
					from base_qtde_cartoes_&anomes 
						
						group by 1, 2, 3;
			quit;

			

			proc sql;
				create table cartoes_em_uso_&anomes as 
					select distinct 
						"&DiaUtil_D1"d format yymmdd10. as posicao,			
						b.cd_prf_depe as prefdep, 
						b.nr_seql_ctra_atb as ctra, 
						b.cd_tip_ctra as tp_cart, 
						a.cd_cli,
						a.cd_mdld_crt,
						a.data_utlz,
						a.valor,
						a.outros
					from tran_limp_mdld_d a
						left join comum.pai_rel_&anomes b on (a.cd_cli = b.cd_cli)
							inner join igr.igrrede_&anomes c on (b.cd_prf_depe = input(c.prefdep, 4.))								
									where tipodep in ('01' '09') and codsitdep in ('2' '4')
										order by 5,2,3,4;
			quit;

			proc sql;
				create table cartoes_100_&anomes as 
					select distinct 
						"&DiaUtil_D1"d format yymmdd10. as posicao,			
						prefdep, 
						ctra, 
						tp_cart, 
						cd_cli,
						sum (valor) as valor
					from cartoes_em_uso_&anomes
					group by 1, 2, 3, 4, 5
										order by 5,2,3,4;
			quit;


			
PROC SQL;
   CREATE TABLE WORK.PRD AS 
   SELECT distinct 
          t1.CD_MDLD,
          case 
		  when t1.NM_MDLD contains ('ELO') then 'ELO'
		  when t1.NM_MDLD contains ('VISA') then 'VISA'
		  when t1.NM_MDLD not contains ('VISA') or t1.NM_MDLD not contains ('ELO') then 'DEMAIS'
end as NM_MDLD
      FROM BAUX.PRD t1
      WHERE t1.CD_EST_MDLD = 'A' and t1.CD_PRD=  9;
QUIT;

DATA dimep.cartoes_em_uso_&anomes;
	SET cartoes_100_&anomes;
RUN;

libname ext_g "/dados/externo/GECEN";

DATA ext_g.cartoes_em_uso_&anomes;
	SET dimep.cartoes_em_uso_&anomes;
RUN;

LIBNAME EXTERNO "/dados/externo/CQPF";

DATA EXTERNO.cartoes_em_uso_&anomes;
	SET dimep.cartoes_em_uso_&anomes;
RUN;

/*conexão*/
%PUT &Indicador;
%put &anomes;
%libconexao(114);

proc sql;
	create table clientes_cartao as
		select distinct 
			&indicador as ind,
			&comp1 as comp,
			a.prefdep,
			input(b.uor,9.) as uor,
			ctra,
			cd_cli as cli,
			input(put("&diautil_d1"d, mmyyn6.),6.) as mmaaaa,
			1 as vlr
		from cartoes_100_&anomes a
			inner join igr.igrrede_&anomes b on (a.prefdep = input(b.prefdep, 4.))
			where valor >=100
				group by 1,2,3,4,5,6,7
					having vlr > 0;
quit;



/*componente -  componente 1 - */
proc sql;
	create table para_sumarizar_&comp1 as
		select distinct 			
			"&DiaUtil_D1"d format yymmdd10. as posicao,
			coalesce(b.uor, a.uor) as uor,
			coalesce(b.PREFDEP, a.PREFDEP) as PREFDEP,
			coalesce(b.CTRA, a.CTRA) as CTRA,			
			sum(coalesce(a.vlr, 0)) as vlr_rlz,
			coalesce(b.vlr, 0) AS VLR_ORC
		from clientes_cartao a
			full join (select * from OCNX114.IND_ORC_&Indicador where mmaaaa = &mesano and ctra <> 0) b on (a.uor = b.uor and a.ctra = b.ctra)
			group by 1,2,3,4;
quit;

/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE ColunasSumarizadorag&comp1;
	CREATE TABLE ColunasSumarizadorag&comp1 (Coluna CHAR(50), Tipo CHAR(10));

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO ColunasSumarizadorag&comp1 VALUES ('VLR_RLZ', 'SUM');
	INSERT INTO ColunasSumarizadorag&comp1 VALUES ('VLR_ORC', 'SUM');
QUIT;

%SumarizadorCNX(TblSASValores=para_sumarizar_&comp1, TblSASColunas=ColunasSumarizadorag&comp1,  NivelCTRA=1, PAA_PARA_AGENCIA=1, TblSaida=FINAL_pf_&comp1, AAAAMM=&anomes);

PROC SQL;
	CREATE TABLE PARA_BASE_CONEXAO_COMP AS
		SELECT distinct 
			&Indicador AS IND, 
			1 AS COMP, 
			1 AS COMP_PAI, 
			1 AS ORD_EXI, 
			UOR,
			PREFDEP,
			CTRA,
			VLR_RLZ, 
			VLR_ORC, 
			0 AS VLR_ATG, 
			POSICAO 
		FROM FINAL_pf_&comp1
			group by 1,2,3,4,5,6,7;
QUIT;


PROC SQL;
	CREATE TABLE PARA_BASE_CONEXAO_IND AS
		SELECT distinct 
			&Indicador AS IND, 
			0 as COMP, 
			0 AS COMP_PAI, 
			0 as ORD_EXI,
			a.uor,
			a.PREFDEP,
			a.CTRA,
			VLR_RLZ, 
			VLR_ORC, 
			0 AS VLR_ATG, 
			posicao 
		FROM FINAL_pf_&comp1 A
			group by 1,2,3,4,5,6,7;
QUIT;

DATA PARA_BASE_CONEXAO;
SET PARA_BASE_CONEXAO_IND PARA_BASE_CONEXAO_COMP;
RUN;


%BaseIndicadorCNX_CLI(TabelaSAS=clientes_cartao);
%BaseIndicadorCNX(TabelaSAS=PARA_BASE_CONEXAO);
%ExportarCNX_CLI (IND=&Indicador, MMAAAA=&mesano);
%ExportarCNX_IND(&Indicador, &mesano, ORC=0, RLZ=1);
%ExportarCNX_COMP(&Indicador, &mesano, ORC=0, RLZ=1);









%end;

%mend;

%roda;
