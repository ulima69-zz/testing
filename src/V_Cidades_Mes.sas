%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET NomeRelatorio=;
%LET NomePasta=;

*/%IniciarProcessoMysql(Processo=&NomeRelatorio., Responsavel=Vanessa, XML=&NomeXML.);/*


/*#################################################################################################################*/
/*##### B I B L I O T E C A S #####*/

LIBNAME CITY "/dados/infor/producao/Ourocard_cidades";
LIBNAME FAT "/dados/infor/producao/Ourocard_cidades/Faturas";


LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2VIP 		DB2 DATABASE=BDB2P04 		SCHEMA=DB2VIP 	AUTHDOMAIN=DB2SGCEN;
LIBNAME DB2CDE 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2CDE 	database=BDB2P04;
LIBNAME DB2ATB 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ATB 	database=BDB2P04;
LIBNAME DB2MCI 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2MCI 	database=BDB2P04;
LIBNAME DB2DWH 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2DWH 	database=BDB2P04;
LIBNAME DB2REN 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2REN	database=BDB2P04;
LIBNAME DB2REL 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2REL	database=BDB2P04;



LIBNAME REN ORACLE USER=sas_gecen PASSWORD=Gecen77 PATH="sas_dirco" SCHEMA="ren";




LIBNAME APP "/dados/infor/producao/ind_uso_cn_virt";
LIBNAME HOUSE "/dados/infor/producao/cielo/direcionador";
/*REN não utilizar o da Digov*/


libname gfi clear;
libname coc clear;
libname deb clear;
libname igs clear;
libname rdo clear;
libname opr clear;
libname bic clear;


libname enj 	"/dados/infor/producao/&NomePasta";

LIBNAME DB2MCI 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI database=BDB2P04;
LIBNAME DB2VIP 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2VIP database=BDB2P04;


LIBNAME CIELO '/dados/infor/producao/cielo/mobilizador2016/dados_entrada';




/*CONTROLE DE DATAS*/

DATA _NULL_;
	DATA_INICIO = '01Jan2017'd;
	DATA_FIM = '30Dec2018'd;
	DATA_REFERENCIA = diaUtilAnterior(TODAY());
	D1 = diaUtilAnterior(TODAY());
	D2 = diaUtilAnterior(D1);
	D3 = diaUtilAnterior(D2);
	MES_ATU = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));
	MES_ANT = Put(INTNX('month',primeiroDiaUtilMes(D1),-1), yymmn6.) ;
	MES_G = Put(DATA_REFERENCIA, MONTH.) ;
	ANOMES = IFN((D1 <= DATA_FIM), Put(D1, yymmn6.), Put(DATA_FIM, yymmn6.));
	DT_INICIO_SQL="'"||put(DATA_INICIO, YYMMDDD10.)||"'";
	DT_D1_SQL="'"||put(D1, YYMMDDD10.)||"'";
	DT_1DIA_MES_SQL="'"||put(primeiroDiaUtilMes(D1), YYMMDDD10.)||"'";
	DT_ANOMES_SQL=primeiroDiaUtilMes(D1);
	PRIMEIRO_DIA_MES_SQL="'"||put(primeiroDiaMes(DATA_REFERENCIA), YYMMDDD10.)||"'";
	DT_FIXA_SQL="'"||put(MDY(01,01,2017), YYMMDDD10.)||"'";
	ANO_FIXO_SQL="'"||put(MDY(01,01,2018), YYMMDDD10.)||"'";

	CALL SYMPUT('DATA_HOJE',COMPRESS(TODAY(),' '));
	CALL SYMPUT('DT_1DIA_MES',COMPRESS(primeiroDiaUtilMes(D1),' '));
	CALL SYMPUT('DATA_INICIO',COMPRESS(DATA_INICIO,' '));
	CALL SYMPUT('DATA_FIM',COMPRESS(DATA_FIM,' '));
	CALL SYMPUT('D1',COMPRESS(D1,' '));
	CALL SYMPUT('D2',COMPRESS(D2,' '));
	CALL SYMPUT('D3',COMPRESS(D3,' '));
	CALL SYMPUT('MES_ATU',COMPRESS(MES_ATU,' '));
	CALL SYMPUT('MES_ANT',COMPRESS(MES_ANT,' '));
	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));
	CALL SYMPUT('RF',COMPRESS(ANOMES,' '));
	CALL SYMPUT('DT_ARQUIVO',put(DATA_REFERENCIA, DDMMYY10.));
	CALL SYMPUT('DT_ARQUIVO_SQL',put(DATA_REFERENCIA, YYMMDDD10.));
	CALL SYMPUT('DT_INICIO_SQL', COMPRESS(DT_INICIO_SQL,' '));
	CALL SYMPUT('DT_1DIA_MES_SQL', COMPRESS(DT_1DIA_MES_SQL,' '));
	CALL SYMPUT('DT_D1_SQL', COMPRESS(DT_D1_SQL,' '));
	CALL SYMPUT('DT_ANOMES_SQL', COMPRESS(DT_ANOMES_SQL,' '));
	CALL SYMPUT('MES_G', COMPRESS(MES_G,' '));
	CALL SYMPUT('PRIMEIRO_DIA_MES_SQL', COMPRESS(PRIMEIRO_DIA_MES_SQL,' '));
	CALL SYMPUT('DT_FIXA_SQL', COMPRESS(DT_FIXA_SQL,' '));
	CALL SYMPUT('ANO_FIXO_SQL', COMPRESS(ANO_FIXO_SQL,' '));
	CALL SYMPUT('LAST_DAY', put(DATA_REFERENCIA, DDMMYY10.));
RUN;

%PUT &DT_FIXA_SQL.;


x cd /;
x cd /dados/infor/producao/Ourocard_cidades;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/

/* (40,225,242,293,913,1070,1075,1087,1119,1448,1449,1654,1758,2242,2416,2449,2614,2771,3843,4100,4176,4187,4481,8267) */
/*(40,242,293,913,1070,1087,1119,1448,1449,1654,1758,2242,2416,2449,2614,2771,4100,4176,4187,4481,4490,8267)*/



 /* CURRENT DATE - (DAY(CURRENT DATE)) DAYS; */

/**/
/*proc sql;*/
/*	connect to db2 (authdomain=db2sgcen database=bdb2p04);*/
/*	create table TESTE_DATA_DB2 as*/
/*		select 	*/
/*			**/
/*		from connection to db2(*/
/*			SELECT*/
/*				(CURRENT DATE - (DAY(CURRENT DATE) - 1) DAYS) AS PRIMEIRO,*/
/*				((CURRENT DATE + 1 MONTH) - (DAY(CURRENT DATE + 1 MONTH)) DAYS) AS ULTIMO*/
/*			FROM*/
/*				SYSIBM.SYSDUMMY1*/
/*						);*/
/*	disconnect from db2;*/
/*quit;*/
/**/
/**/
/*BETWEEN (CURRENT DATE - (DAY(CURRENT DATE) - 1) DAYS) AND ((CURRENT DATE + 1 MONTH) - (DAY(CURRENT DATE + 1 MONTH)) DAYS)*/




proc sql;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	create table FLUXO_PAGCRD as
		select 	
			CD_CLI,
			9 AS PRD,
			MDLD,
			NR_CT_CRT,
			DT_UTIL_VNCT_FAT,
			PAGAMENTO
		from connection to db2(
			SELECT t3.CD_CLI,
				t3.CD_MDLD_CRT  AS MDLD,
				t3.NR_CT_CRT,
				t2.DT_UTIL_VNCT_FAT,
				SUM(t5.VL_SDO_FAT_CT_CRT) AS PAGAMENTO
			FROM DB2VIP.FAT_CT_CRT t4
				INNER JOIN DB2VIP.CT_CRT t3 ON (t4.NR_CTR_OPR_CT_CRT = t3.NR_CT_CRT)
				INNER JOIN DB2VIP.CLDR_FATM t2 ON (t4.CD_CLDR_FATM = t2.CD_CLDR_FATM)
				INNER JOIN DB2VIP.SDO_FAT_CT_CRT t5 ON  (t4.NR_SEQL_FAT_CT_CRT = t5.NR_SEQL_FAT_CT_CRT)
					WHERE 
						t5.CD_TIP_SDO = 107
						AND t2.DT_UTIL_VNCT_FAT BETWEEN (CURRENT DATE - (DAY(CURRENT DATE) - 1) DAYS) AND ((CURRENT DATE + 1 MONTH) - (DAY(CURRENT DATE + 1 MONTH)) DAYS)
					GROUP BY t3.CD_CLI,
						t3.CD_MDLD_CRT,
						t3.NR_CT_CRT,
						t2.DT_UTIL_VNCT_FAT
					ORDER BY CD_CLI;
						);
	disconnect from db2;
quit;




%macro encarteiramento;

	proc sql;
		create table base_mci as
			select distinct cd_cli
				from FLUXO_PAGCRD
					order by 1;
		create index cd_cli on base_mci(cd_cli);
	quit;

	proc sql;
		create table encarteiramento as
			select put(cd_prf_depe, z4.) as prefdep,
				ifn(cd_tip_ctra in (10 16 50 56 57 59 60), nr_seql_ctra, 7002) as carteira,
				ifn(cd_tip_ctra in (10 16 50 56 57 59 60), cd_tip_ctra, 700) as tp_cart,
				e.cd_cli
			from comum.pai_rel_&ANOMES e
				inner join base_mci c on (e.cd_cli = c.cd_cli)
				inner join igr.igrrede_&ANOMES d on (put(cd_prf_depe, z4.)=d.prefdep)
					where e.cd_tip_ctra in (10 16 50 15 56 57 59 60 20 17 18 19 70) and codsitdep in ('2' '4') and tipodep in ('09' '01')
						order by 4, 1, 2, 3;
	quit;

	data contas_enc(keep = cd_cli);
		set encarteiramento;
	run;

	proc sort data = contas_enc nodupkey;
		by cd_cli;
	run;

	proc sql noprint;
		select count(*) into: q
			from (select cd_cli
			from encarteiramento
				group by 1
					having count(*)>1);
	quit;

	%put &q;

	%if &q>0 %then
		%do;

			data duplicados(drop=carteira tp_cart);
				set encarteiramento(obs=0);
			run;

			proc sql;
				create table aux_d as
					select cd_cli
						from encarteiramento
							group by 1
								having count(*)>1;
			quit;

			data aux_d(drop=seq);
				set aux_d;
				seq+1;
				grupo=ceil(seq/5957);
			run;

			proc sql noprint;
				select max(grupo) into: q
					from aux_d;
			quit;

			%do i=1 %to &q;

				proc sql noprint;
					select cd_cli into: var separated by ', '
						from aux_d
							where grupo=&i;
				quit;

				proc sql;
					connect to db2 (authdomain=db2sgcen database=bdb2p04);
					insert into duplicados
						select put(cod_pref_agen, z4.), cod
							from connection to db2
								(select cod, cod_pref_agen
									from db2mci.cliente
										where cod in(&var)
											order by cod;);
					disconnect from db2;
				quit;

				proc sql;
					create table fim_dup as
						select a.*, carteira, tp_cart
							from duplicados a
								inner join encarteiramento b on(a.cd_cli=b.cd_cli and a.prefdep=b.prefdep)
									order by 2;
					delete from duplicados;
				quit;

				data encarteiramento;
					set encarteiramento(where=(cd_cli not in(&var.))) fim_dup;
					by cd_cli;
				run;

				proc delete data=fim_dup aux_d;
				run;

			%end;
		%end;

	proc sql noprint;
		select count(*) into: q
			from (select distinct a.cd_cli
			from contas_enc a
				left join encarteiramento b on(a.cd_cli=b.cd_cli)
					where b.cd_cli is missing);
	quit;

	%Put &Q;

	%if &q>0 %then
		%do;

			data perdidos;
				set encarteiramento(obs=0);
			run;

			proc sql;
				create table aux_p as
					select distinct a.cd_cli
						from contas_enc a
							left join encarteiramento b on(a.cd_cli=b.cd_cli)
								where b.cd_cli is missing;
			quit;

			data aux_p(drop=seq);
				set aux_p;
				seq+1;
				grupo=ceil(seq/5957);
			run;

			proc sql noprint;
				select max(grupo) into: q
					from aux_p;
			quit;

			%do i=1 %to &q;

				proc sql noprint;
					select cd_cli format 9. into: var separated by ', '
						from aux_p
							where grupo=&i;
				quit;

				%let filtro=b.tipodep in('013' '015' '035') and sb='00';

				proc sql;
					connect to db2 (authdomain=db2sgcen database=bdb2p04);
					insert into perdidos
						select put(cod_pref_agen, z4.) as prefdep, 
							700 as tp_cart,
							7002 as carteira, 
							cod as cd_cli
						from connection to db2
							(select cod, cod_pref_agen
								from db2mci.cliente
									where cod in(&var)
										order by cod;) a
											inner join igr.dependencias b on(a.cod_pref_agen=input(b.prefdep, 4.))
												where &filtro;
					disconnect from db2;
				quit;

			%end;

			proc sort data=perdidos;
				by cd_cli;
			run;

			data encarteiramento;
				set encarteiramento perdidos;
				by cd_cli;
			run;

			proc delete data=aux_p perdidos;
			run;

		%end;
%mend;

%encarteiramento;


PROC SQL;
	CREATE TABLE FAT.FATURA_CRTCRED_&ANOMES. AS 
		SELECT 
			INPUT(T2.PREFDEP,4.) AS PREFDEP,
			T2.CARTEIRA,
			T2.TP_CART,
			t1.CD_CLI, 
			t1.DT_UTIL_VNCT_FAT, 
			t1.PAGAMENTO,
			2018 AS ANO,
			&MES_G. AS MES
		FROM WORK.FLUXO_PAGCRD t1
			INNER JOIN ENCARTEIRAMENTO T2 ON (T1.CD_CLI=T2.CD_CLI);
QUIT;

PROC SQL;
	DELETE FROM CITY.FATURA_2018 WHERE MES=&MES_G.;
RUN;

DATA CITY.FATURA_2018;
	SET CITY.FATURA_2018 FAT.fatura_crtcred_&anomes;
RUN;


DATA CRT_CRED_FATURAMENTO;
SET CITY.FATURA_2017 CITY.FATURA_2018;
RUN;


PROC SQL;
   CREATE TABLE FATURA_ATUAL AS 
   SELECT DISTINCT t1.PREFDEP, 
          t1.CARTEIRA, 
          /* SUM_of_PAGAMENTO */
            (SUM(t1.PAGAMENTO)) FORMAT=17.2 AS FATURA
      FROM CRT_CRED_FATURAMENTO t1
      GROUP BY 1,2
ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE FATURA_AGOSTO AS 
   SELECT DISTINCT t1.PREFDEP, 
          t1.CARTEIRA, 
          /* SUM_of_PAGAMENTO */
            (SUM(t1.PAGAMENTO)) FORMAT=17.2 AS FATURA_AGOSTO
      FROM CRT_CRED_FATURAMENTO t1
	  WHERE ANO=2017 AND MES IN (1 2 3 4 5 6 7 8)
      GROUP BY 1,2
	  ORDER BY 1,2
               ;
QUIT;


DATA FATURAMENTO_CRTCRED;
SET FATURA_ATUAL FATURA_AGOSTO;
RUN;




PROC SQL;
connect to db2 (authdomain=db2sgcen database=bdb2p04);
	CREATE TABLE PLST_PORT AS 
		select 
		*
	from connection to db2
	(
			SELECT 
			t1.CD_CLI_PORT AS CD_CLI, 
			t1.NR_PLST, 
			t1.CD_PRF_DEPE_DST, 
			t1.NR_CT_CRT, 
			t1.DT_EMS_PLST, 
			t1.DT_ATVC_PLST, 
			t1.DT_CNCT_PLST, 
			t1.DT_VLD_PLST, 
			t1.NM_CLI_PLST, 
			t1.CD_TIP_RST_CRT_CRD 

		FROM DB2VIP.PLST_PORT t1
		WHERE DT_VLD_PLST BETWEEN (CURRENT DATE - (DAY(CURRENT DATE) - 1) DAYS) AND ((CURRENT DATE + 1 MONTH) - (DAY(CURRENT DATE + 1 MONTH)) DAYS)
	order by 1
);
	disconnect from db2;;
QUIT;




PROC SQL;
	CREATE TABLE POSSE_CARTAO_&anomes AS 
		SELECT 
			T2.CD_PRF_DEPE AS PREFDEP,
			T2.NR_SEQL_CTRA AS CARTEIRA,
			COUNT(DISTINCT t1.CD_CLI) AS POSSE_CRT
		FROM WORK.PLST_PORT t1
			INNER JOIN COMUM.ENCARTEIRAMENTO_CONEXAO_&anomes t2 ON (t1.CD_CLI = t2.CD_CLI)
				where DT_VLD_PLST>'01JAN2017'D
					GROUP BY 1,2
ORDER BY 1;
QUIT;


PROC SQL;
	CREATE TABLE FUNCAO_ATIVA_&anomes AS 
		SELECT 
			T2.CD_PRF_DEPE AS PREFDEP,
			T2.NR_SEQL_CTRA AS CARTEIRA,
			COUNT(DISTINCT t1.CD_CLI) AS ATIVO_CRT
		FROM WORK.PLST_PORT t1
			INNER JOIN COMUM.ENCARTEIRAMENTO_CONEXAO_&anomes t2 ON (t1.CD_CLI = t2.CD_CLI)
				where  DT_VLD_PLST>'01JAN2017'D AND CD_TIP_RST_CRT_CRD NOT IN (0,50,58,103,125,135,155,214)
					GROUP BY 1,2
ORDER BY 1;
QUIT;

data city.posse_cartao;
set city.posse_cartao_2018 POSSE_CARTAO_&anomes;
run;


DATA POSSE_CRT;
SET CITY.POSSE_CARTAO CITY.POSSE_CARTAO_AGOSTO;
RUN;



data city.funcao_ativa;
set city.funcao_ativa_2018 funcao_ativa_&anomes;
run;



PROC SQL;
   CREATE TABLE FUNCAO_AGOSTO AS 
   SELECT
   PREFDEP,
          t1.CARTEIRA, 
          t1.ATIVO_CRT AS ATIVA_CRT_AGOSTO
      FROM CITY.FUNCAO_ATIVA_AGOSTO t1;
QUIT;



DATA FUNCAO_CRT;
SET CITY.FUNCAO_ATIVA FUNCAO_AGOSTO;
RUN;




/*******************************************************************/
/************************************************************CARTÕES PERSONALIZADOS**/
/*******************************************************************/



PROC SQL;
   CREATE TABLE WORK.ELO_EMISS_JUN AS
   SELECT t1.NR_PLST,
          t1.NM_CLI_PLST,
          t1.NR_CT_CRT,
          t1.NR_SEQL_TITD_PORT,
          t1.CD_CLI_PORT,
          t1.DT_EMS_PLST,
          t1.DT_ATVC_PLST,
          t1.DT_CNCT_PLST,
          t1.CD_MDLD_EMS_PLST,
          t1.CD_SUB_MDLD_PLST,
          t1.CD_TIP_CRT,
          t1.CD_PRF_DEPE_DST,
		  t2.nr_seql_ctra
      FROM DB2VIP.PLST_PORT t1
	  INNER JOIN COMUM.PAI_REL_&anomes t2 ON (t1.CD_CLI_PORT = t2.CD_CLI and cd_prf_depe_dst=cd_prf_depe)
    WHERE t1.DT_EMS_PLST >= '1jan2017'd /* BETWEEN '1Jan2017'd AND '31Oct2017'd */
		AND t1.CD_TIP_CRT IN (398,399,400,401,402,403,404,419,420,421,422,423,432,459,697,698,699,700,701,702,764,767,768,769,770) 
        ;
		quit;


PROC SQL;
   CREATE TABLE EMISS_JUN AS 
   SELECT DISTINCT t1.CD_PRF_DEPE_DST, 
          t1.nr_seql_ctra, 
          /* COUNT_of_DT_EMS_PLST */
            (COUNT(t1.DT_EMS_PLST)) AS EMS_PLST_ATUAL
      FROM WORK.ELO_EMISS_JUN t1
      GROUP BY t1.CD_PRF_DEPE_DST,
               t1.nr_seql_ctra;
QUIT;



PROC SQL;
   CREATE TABLE ATIVA_JUN AS 
   SELECT DISTINCT t1.CD_PRF_DEPE_DST, 
          t1.nr_seql_ctra, 
          /* COUNT_of_DT_ATVC_PLST */
            (COUNT(t1.DT_ATVC_PLST)) AS ATVC_PLST_ATUAL
      FROM WORK.ELO_EMISS_JUN t1
      GROUP BY t1.CD_PRF_DEPE_DST,
               t1.nr_seql_ctra;
QUIT;

PROC SQL;
   CREATE TABLE WORK.ELO_EMISS_AUG AS 
   SELECT t1.NR_PLST, 
          t1.NM_CLI_PLST, 
          t1.NR_CT_CRT, 
          t1.NR_SEQL_TITD_PORT, 
          t1.CD_CLI_PORT, 
          t1.DT_EMS_PLST, 
          t1.DT_ATVC_PLST, 
          t1.DT_CNCT_PLST, 
          t1.CD_MDLD_EMS_PLST, 
          t1.CD_SUB_MDLD_PLST, 
          t1.CD_TIP_CRT, 
          t1.CD_PRF_DEPE_DST,
		  t1.nr_seql_ctra
      FROM WORK.ELO_EMISS_JUN t1
      WHERE t1.DT_EMS_PLST BETWEEN '1Jan2017'd AND '31Aug2017'd;
QUIT;



PROC SQL;
   CREATE TABLE WORK.EMISS_AUG AS 
   SELECT DISTINCT t1.CD_PRF_DEPE_DST, 
   			T1.nr_seql_ctra,
          /* COUNT_of_DT_EMS_PLST */
            (COUNT(t1.DT_EMS_PLST)) AS EMS_PLST
      FROM WORK.ELO_EMISS_AUG t1
      GROUP BY t1.CD_PRF_DEPE_DST,
nr_seql_ctra;
QUIT;


PROC SQL;
   CREATE TABLE ATIVA_AUG AS 
   SELECT DISTINCT t1.CD_PRF_DEPE_DST, 
          t1.nr_seql_ctra, 
          /* COUNT_of_DT_ATVC_PLST */
            (COUNT(t1.DT_ATVC_PLST)) AS ATVC_PLST
      FROM WORK.ELO_EMISS_AUG t1
      GROUP BY t1.CD_PRF_DEPE_DST,
               t1.nr_seql_ctra;
QUIT;




Data PERSONALIZADO;
merge EMISS_AUG EMISS_JUN ATIVA_AUG ATIVA_JUN ;
BY CD_PRF_DEPE_DST nr_seql_ctra;
RUN;
PROC SORT DATA=PERSONALIZADO NODUPKEY; BY _ALL_; RUN;
%ZerarMissingTabela(PERSONALIZADO);


PROC SQL;
   CREATE TABLE CARTAO_CIDADES AS 
   SELECT t1.CD_PRF_DEPE_DST AS PREFDEP, 
          t1.nr_seql_ctra AS CARTEIRA, 
          t1.EMS_PLST, 
          t1.EMS_PLST_ATUAL, 
          t1.ATVC_PLST, 
          t1.ATVC_PLST_ATUAL
      FROM WORK.PERSONALIZADO t1;
QUIT;





/*******************************************************************/
/************************************************************CIELO**/
/*******************************************************************/
libname CONECTE	"/dados/infor/producao/conectados";





		  
PROC SQL;
   CREATE TABLE QNT_CIELO AS 
   SELECT t1.PrefDep, 
          t1.Carteira, 
          t1.estoque_agosto as cielo_aug
      FROM CITY.DOMICILIO_CIELO_201708 t1
	 
group by 1,2;
QUIT;



PROC SQL;
   CREATE TABLE QNT_CIELO1 AS 
   SELECT t1.PrefDep, 
          t1.Carteira, 
          t1.estoque_atual as cielo_atual
      FROM CITY.DOMICILIO_CIELO_201712 t1

group by 1,2;
QUIT;



/*********************************************************/
/***************************************FATURAMENTO CIELO*/
/*********************************************************/


PROC SQL;
	DELETE FROM CITY.FATURAMENTO_CIELO WHERE MES=&ANOMES.;
RUN;

DATA CITY.FATURAMENTO_CIELO;
SET CITY.FATURAMENTO_CIELO_2017 CITY.FATURAMENTO_CIELO_2018 CIELO.FAT_ENC_&ANOMES;
RUN;


PROC SQL;
   CREATE TABLE FATURAMENTO_CIELO_AGOSTO AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.Carteira, 
          /* SUM_of_Valor */
            (SUM(t1.Valor)) FORMAT=17.2 AS CIELO_AGOSTO
      FROM CITY.FATURAMENTO_CIELO_AGOSTO t1
	  WHERE PREFDEP NE .
      GROUP BY t1.PrefDep,
               t1.Carteira;
QUIT;



PROC SQL;
   CREATE TABLE FATURAMENTO_CIELO AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.Carteira, 
          SUM(Valor)format 19.2 as CIELO
      FROM CITY.FATURAMENTO_CIELO t1
	  WHERE PREFDEP NE .
GROUP BY 1,2;
QUIT;




PROC SQL;
   CREATE TABLE QNT_APP_AUG AS 
   SELECT  
          t1.prefdep, 
          t1.cart AS CARTEIRA,  
          sum(t1.usu_mobile) as usu_mob_aug
      FROM APP.MCI_MOBILE_201708 t1
      group by 1,2
;
QUIT;



PROC SQL;
   CREATE TABLE QNT_APP_ATUAL AS 
   SELECT  
          t1.prefdep, 
          t1.cart AS CARTEIRA, 
          sum(t1.usu_mobile) as usu_mobile
      FROM APP.MCI_MOBILE_&anomes t1
	  group by 1,2
;
QUIT;


DATA JUNTA_TUDO ;
SET FATURAMENTO_CRTCRED POSSE_CRT FUNCAO_CRT CARTAO_CIDADES QNT_CIELO QNT_CIELO1 FATURAMENTO_CIELO_AGOSTO FATURAMENTO_CIELO QNT_APP_AUG QNT_APP_ATUAL;
RUN;



PROC SQL;
   CREATE TABLE CIDADES_CARTEIRA AS 
   SELECT t1.PREFDEP, 
          t1.CARTEIRA,
          (SUM(t1.FATURA)) FORMAT=17.2 AS FATURA, 
			(SUM(t1.FATURA_AGOSTO)) FORMAT=17.2 AS FATURA_AGOSTO, 
			(SUM(t1.POSSE_CRT)) AS POSSE_CRT, 
			(SUM(t1.POSSE_CRT_AGOSTO)) AS POSSE_CRT_AGOSTO, 
			(SUM(t1.ATIVO_CRT)) AS ATIVO_CRT, 
			(SUM(t1.ATIVA_CRT_AGOSTO)) AS ATIVA_CRT_AGOSTO, 
			(SUM(t1.EMS_PLST)) AS EMS_PLST, 
			(SUM(t1.EMS_PLST_ATUAL)) AS EMS_PLST_ATUAL, 
			(SUM(t1.ATVC_PLST)) AS ATVC_PLST, 
			(SUM(t1.ATVC_PLST_ATUAL)) AS ATVC_PLST_ATUAL, 
			(SUM(t1.cielo_aug)) FORMAT=BEST3. AS cielo_aug,
			(SUM(t1.cielo_atual)) FORMAT=BEST4. AS Cielo_atual, 
			(SUM(t1.CIELO_AGOSTO)) FORMAT=17.2 AS CIELO_AGOSTO,
			(SUM(t1.CIELO)) FORMAT=19.2 AS CIELO, 
			(SUM(t1.usu_mob_aug)) AS usu_mob_aug, 
			(SUM(t1.usu_mobile)) AS usu_mobile
      FROM WORK.JUNTA_TUDO t1
	  INNER JOIN IGR.IGRREDE B ON (t1.PREFDEP=INPUT(B.PREFDEP,4.))
	WHERE PREFSUPREG NE "0000" AND CODSITDEP IN ('2', '4') and tipodep in ('09' '01')
GROUP BY 1,2
ORDER BY 1,2;
QUIT;

PROC SQL;
	CREATE TABLE WORK.CIDADES_PREFIXO AS 
		SELECT  
			prefdep,
			0 AS carteira, 
		 (SUM(t1.FATURA)) FORMAT=17.2 AS FATURA, 
            (SUM(t1.FATURA_AGOSTO)) FORMAT=17.2 AS FATURA_AGOSTO, 
            (SUM(t1.POSSE_CRT)) AS POSSE_CRT, 
            (SUM(t1.POSSE_CRT_AGOSTO)) AS POSSE_CRT_AGOSTO, 
            (SUM(t1.ATIVO_CRT)) AS ATIVO_CRT, 
			(SUM(t1.ATIVA_CRT_AGOSTO)) AS ATIVA_CRT_AGOSTO, 
            (SUM(t1.EMS_PLST)) AS EMS_PLST, 
            (SUM(t1.EMS_PLST_ATUAL)) AS EMS_PLST_ATUAL, 
            (SUM(t1.ATVC_PLST)) AS ATVC_PLST, 
            (SUM(t1.ATVC_PLST_ATUAL)) AS ATVC_PLST_ATUAL, 
            (SUM(t1.cielo_aug)) FORMAT=BEST3. AS cielo_aug,
            (SUM(t1.cielo_atual)) FORMAT=BEST4. AS Cielo_atual, 
            (SUM(t1.CIELO_AGOSTO)) FORMAT=17.2 AS CIELO_AGOSTO,
            (SUM(t1.CIELO)) FORMAT=19.2 AS CIELO, 
            (SUM(t1.usu_mob_aug)) AS Usu_mob_aug, 
            (SUM(t1.usu_mobile)) AS usu_mobile
		FROM WORK.CIDADES_CARTEIRA t1
		WHERE PREFDEP NE .
			GROUP BY 1,2
				ORDER BY 1, 2;
QUIT;



PROC SQL;
   CREATE TABLE CIDADES_SUPREG AS 
   SELECT DISTINCT INPUT(PREFSUPREG,4.) AS PREFDEP, 
          0 AS carteira, 
            (SUM(t1.FATURA)) FORMAT=17.2 AS FATURA, 
            (SUM(t1.FATURA_AGOSTO)) FORMAT=17.2 AS FATURA_AGOSTO, 
            (SUM(t1.POSSE_CRT)) AS POSSE_CRT, 
            (SUM(t1.POSSE_CRT_AGOSTO)) AS POSSE_CRT_AGOSTO, 
            (SUM(t1.ATIVO_CRT)) AS ATIVO_CRT, 
			(SUM(t1.ATIVA_CRT_AGOSTO)) AS ATIVA_CRT_AGOSTO, 
            (SUM(t1.EMS_PLST)) AS EMS_PLST, 
            (SUM(t1.EMS_PLST_ATUAL)) AS EMS_PLST_ATUAL, 
            (SUM(t1.ATVC_PLST)) AS ATVC_PLST, 
            (SUM(t1.ATVC_PLST_ATUAL)) AS ATVC_PLST_ATUAL, 
            (SUM(t1.cielo_aug)) FORMAT=BEST3. AS cielo_aug,
            (SUM(t1.cielo_atual)) FORMAT=BEST4. AS Cielo_atual, 
            (SUM(t1.CIELO_AGOSTO)) FORMAT=17.2 AS CIELO_AGOSTO,
            (SUM(t1.CIELO)) FORMAT=19.2 AS CIELO, 
            (SUM(t1.usu_mob_aug)) AS Usu_mob_aug, 
            (SUM(t1.usu_mobile)) AS usu_mobile
      FROM WORK.CIDADES_CARTEIRA t1
	   INNER JOIN IGR.IGRREDE B ON (t1.PREFDEP=INPUT(B.PREFDEP,4.))
	WHERE PREFSUPREG NE "0000" AND CODSITDEP IN ('2', '4')
      GROUP BY 1,2
	  ORDER BY 1, 2;
QUIT;
    


PROC SQL;
   CREATE TABLE CIDADES_SUPEST AS 
   SELECT DISTINCT INPUT(PREFSUPEST,4.) AS PREFDEP, 
          0 AS carteira, 
             (SUM(t1.FATURA)) FORMAT=17.2 AS FATURA, 
            (SUM(t1.FATURA_AGOSTO)) FORMAT=17.2 AS FATURA_AGOSTO, 
            (SUM(t1.POSSE_CRT)) AS POSSE_CRT, 
            (SUM(t1.POSSE_CRT_AGOSTO)) AS POSSE_CRT_AGOSTO, 
            (SUM(t1.ATIVO_CRT)) AS ATIVO_CRT, 
			(SUM(t1.ATIVA_CRT_AGOSTO)) AS ATIVA_CRT_AGOSTO, 
            (SUM(t1.EMS_PLST)) AS EMS_PLST, 
            (SUM(t1.EMS_PLST_ATUAL)) AS EMS_PLST_ATUAL, 
            (SUM(t1.ATVC_PLST)) AS ATVC_PLST, 
            (SUM(t1.ATVC_PLST_ATUAL)) AS ATVC_PLST_ATUAL, 
            (SUM(t1.cielo_aug)) FORMAT=BEST3. AS cielo_aug,
            (SUM(t1.cielo_atual)) FORMAT=BEST4. AS Cielo_atual, 
            (SUM(t1.CIELO_AGOSTO)) FORMAT=17.2 AS CIELO_AGOSTO,
            (SUM(t1.CIELO)) FORMAT=19.2 AS CIELO, 
            (SUM(t1.usu_mob_aug)) AS Usu_mob_aug, 
            (SUM(t1.usu_mobile)) AS usu_mobile
      FROM WORK.CIDADES_CARTEIRA t1
	   INNER JOIN IGR.IGRREDE B ON (t1.PREFDEP=INPUT(B.PREFDEP,4.))
	WHERE PREFSUPEST NE "0000" AND CODSITDEP IN ('2', '4')
      GROUP BY 1,2
	  ORDER BY 1, 2;
QUIT;


PROC SQL;
   CREATE TABLE CIDADES_PREFUEN AS 
   SELECT DISTINCT INPUT(PREFUEN,4.) AS PREFDEP, 
          0 AS carteira, 
            (SUM(t1.FATURA)) FORMAT=17.2 AS FATURA, 
            (SUM(t1.FATURA_AGOSTO)) FORMAT=17.2 AS FATURA_AGOSTO, 
            (SUM(t1.POSSE_CRT)) AS POSSE_CRT, 
            (SUM(t1.POSSE_CRT_AGOSTO)) AS POSSE_CRT_AGOSTO, 
            (SUM(t1.ATIVO_CRT)) AS ATIVO_CRT, 
			(SUM(t1.ATIVA_CRT_AGOSTO)) AS ATIVA_CRT_AGOSTO, 
            (SUM(t1.EMS_PLST)) AS EMS_PLST, 
            (SUM(t1.EMS_PLST_ATUAL)) AS EMS_PLST_ATUAL, 
            (SUM(t1.ATVC_PLST)) AS ATVC_PLST, 
            (SUM(t1.ATVC_PLST_ATUAL)) AS ATVC_PLST_ATUAL, 
            (SUM(t1.cielo_aug)) FORMAT=BEST3. AS cielo_aug,
            (SUM(t1.cielo_atual)) FORMAT=BEST4. AS Cielo_atual, 
            (SUM(t1.CIELO_AGOSTO)) FORMAT=17.2 AS CIELO_AGOSTO,
            (SUM(t1.CIELO)) FORMAT=19.2 AS CIELO, 
            (SUM(t1.usu_mob_aug)) AS Usu_mob_aug, 
            (SUM(t1.usu_mobile)) AS usu_mobile
      FROM WORK.CIDADES_CARTEIRA t1
	   INNER JOIN IGR.IGRREDE B ON (t1.PREFDEP=INPUT(B.PREFDEP,4.))
	WHERE PREFUEN NE '0000' AND CODSITDEP IN ('2', '4')
      GROUP BY 1,2
	  ORDER BY 1, 2;
QUIT;



PROC SQL;
   CREATE TABLE CIDADES_VIVAP AS 
   SELECT DISTINCT 8166 AS PREFDEP, 
          0 AS carteira, 
            (SUM(t1.FATURA)) FORMAT=17.2 AS FATURA, 
            (SUM(t1.FATURA_AGOSTO)) FORMAT=17.2 AS FATURA_AGOSTO, 
            (SUM(t1.POSSE_CRT)) AS POSSE_CRT, 
            (SUM(t1.POSSE_CRT_AGOSTO)) AS POSSE_CRT_AGOSTO, 
            (SUM(t1.ATIVO_CRT)) AS ATIVO_CRT,
            (SUM(t1.ATIVA_CRT_AGOSTO)) AS ATIVA_CRT_AGOSTO,  
            (SUM(t1.EMS_PLST)) AS EMS_PLST, 
            (SUM(t1.EMS_PLST_ATUAL)) AS EMS_PLST_ATUAL, 
            (SUM(t1.ATVC_PLST)) AS ATVC_PLST, 
            (SUM(t1.ATVC_PLST_ATUAL)) AS ATVC_PLST_ATUAL, 
            (SUM(t1.cielo_aug)) FORMAT=BEST3. AS cielo_aug, 
            (SUM(t1.Cielo_atual)) FORMAT=BEST4. AS Cielo_atual,
            (SUM(t1.CIELO_AGOSTO)) FORMAT=17.2 AS CIELO_AGOSTO,
            (SUM(t1.CIELO)) FORMAT=19.2 AS CIELO, 
            (SUM(t1.Usu_mob_aug)) AS Usu_mob_aug, 
            (SUM(t1.usu_mobile)) AS usu_mobile
      FROM WORK.CIDADES_PREFUEN t1
      GROUP BY 1,2;
QUIT;



DATA CIDADES;
SET CIDADES_CARTEIRA CIDADES_PREFIXO CIDADES_SUPREG CIDADES_SUPEST CIDADES_PREFUEN CIDADES_VIVAP;
;
RUN;



PROC SQL;
	CREATE TABLE MUNICIPIOS AS 
		SELECT t1.PREFDEP, 
			1 AS MN
		FROM WORK.CIDADES_PREFIXO t1
			WHERE t1.prefdep IN (40,242,293,913,1070,1087,1119,1448,1449,1654,1758,2242,2416,2449,2614,2771,4100,4176,4187,4481,4490,8267)
			group by 1
	;
QUIT;





PROC SQL;
   CREATE TABLE WORK.MUNB AS 
   SELECT t1.PREFDEP, 
          t1.carteira, 
          t1.FATURA AS FAT_CRT_ATUAL, 
          t1.FATURA_AGOSTO AS FAT_201708, 
          t1.POSSE_CRT AS CARTAO_POSSE, 
          t1.POSSE_CRT_AGOSTO AS CRT_POSSE_AUG, 
          t1.ATIVO_CRT AS CARTAO_ATIVO, 
		  t1.ATIVA_CRT_AGOSTO as CRT_ATIVO_AUG,
          t1.EMS_PLST, 
          t1.EMS_PLST_ATUAL, 
          t1.ATVC_PLST, 
          t1.ATVC_PLST_ATUAL, 
          t1.cielo_aug AS CIELO_AGOSTO, 
          t1.cielo_atual, 
          t1.CIELO_AGOSTO as FAT_CIELO_AUG, 
          t1.CIELO as FAT_CIELO_ATUAL, 
          t1.usu_mob_aug, 
          t1.usu_mobile, 
          t1.cielo_atual, 
          t1.usu_mob_aug, 
	      t2.MN 
      FROM WORK.CIDADES t1
      LEFT JOIN MUNICIPIOS t2 on (t1.prefdep=t2.prefdep)
GROUP BY 1,2;
QUIT;
%ZerarMissingTabela(MUNB);


PROC SQL;
   CREATE TABLE WORK.MUN_DIGITAL AS 
   SELECT DISTINCT 
&d1. FORMAT=DateMysql. as POSICAO,
t1.PREFDEP, 
          t1.carteira, 
          t1.CRT_POSSE_AUG, 
          t1.CARTAO_POSSE, 
          t1.CRT_ATIVO_AUG, 
          t1.CARTAO_ATIVO, 
          t1.FAT_201708, 
          t1.FAT_CRT_ATUAL, 
          t1.cielo_agosto format 19., 
          t1.Cielo_atual format 19., 
          t1.FAT_CIELO_AUG, 
          t1.FAT_CIELO_ATUAL, 
          t1.usu_mob_aug, 
          t1.usu_mobile, 
          t1.EMS_PLST, 
          t1.EMS_PLST_ATUAL, 
          t1.ATVC_PLST, 
          t1.ATVC_PLST_ATUAL, 
          t1.MN
      FROM WORK.MUNB t1;
QUIT;

%ZerarMissingTabela(MUN_DIGITAL);




%LET Usuario=f9457977;
%LET Keypass=E84Y8EDTS404X598UMI7TP5CLLRWX4CJV;
/*relatorio - 96*/
/*rotina 49*/
PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('MUN_DIGITAL', 'cidades');
QUIT;
%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);






x cd /;
x cd /dados/infor/producao/Ourocard_cidades;
x cd /dados/infor/producao/dependencias;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/


/*************************************************/;
/* TRECHO DE CÓDIGO INCLUÍDO PELO FF */;

%include "/dados/gestao/rotinas/_macros/macros_uteis.sas";
 
%processCheckOut(
    uor_resp = 341556
    ,funci_resp = &sysuserid
    /*,tipo = Indicador
    ,sistema = Indicador
    ,rotina = I0123 Indicador de Alguma Coisa*/
    ,mailto= 'F8369937' 'F2986408' 'F6794004' 'F7176219' 'F8176496' 'F9457977' 'F9631159'
);
