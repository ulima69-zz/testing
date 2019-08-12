
%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME CHQ '/dados/infor/producao/Adesao_Cheques/';
LIBNAME DB2REL 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2REL database=BDB2P04;
LIBNAME DB2ANC 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2ANC database=BDB2P04;




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
    MMAAAA=PUT(D1,mmyyn6.);

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
	CALL SYMPUT('MMAAAA', COMPRESS(MMAAAA,' '));
RUN;

LIBNAME PROV '/dados/infor/producao/clientes_proventistas/';
/**/
/*DATA WORK.AptosChequeEspecial;*/
/*    LENGTH*/
/*        F1               $ 15 ;*/
/*    FORMAT*/
/*        F1               $CHAR15. ;*/
/*    INFORMAT*/
/*        F1               $CHAR15. ;*/
/*    INFILE '/saswork/infor/work/SAS_workF1E302E401E0_ppa1sas00036/#LN00019'*/
/*        LRECL=15*/
/*        ENCODING="LATIN1"*/
/*        TERMSTR=CRLF*/
/*        DLM='7F'x*/
/*        MISSOVER*/
/*        DSD ;*/
/*    INPUT*/
/*        F1               : $CHAR15. ;*/
/*RUN;*/
/**/




PROC SQL;
   CREATE TABLE chq.BASE AS 
   SELECT 
/*          t1.f1,*/
          index(f1,'1') as a ,
          input(substr(f1,calculated a+1,9),9.) as MCI
      FROM WORK.pbco t1
;
QUIT;


PROC SQL;
   CREATE TABLE BASE AS 
   SELECT t1.MCI
      FROM CHQ.BASE t1;
QUIT;



/**/
/*BASE ERNANI PROVENTISTAS*/

/*DESCRIÇÃO CPNT  5=LOB VAI, 4=LOB VEM*/

PROC SQL;
   CREATE TABLE CLIENTES  AS 
   SELECT 
          T2.MCI, 
          t1.DTA_CRED, 
          t1.Descricao, 
          t1.CPNT
      FROM PROV.DETALHE_&anomes. t1
	  RIGHT JOIN BASE T2 ON (T1.MCI=T2.MCI)
	  WHERE T2.MCI IS NOT MISSING 
;
QUIT;

	/*--- RESTRIÇÃO E SITUAÇÃO DO LIMITE DE CREDITO ---*/
proc sql;
	create table restricao_limite as 
		select distinct 
			t1.mci, 
			t2.situacao_cadastral,
			t2.cd_est_lmcr as situacao_limite_credito,  
			ifn(t2.max_peso_anot_cadl>t2.max_peso_anot_cadl_repl,t2.max_peso_anot_cadl,t2.max_peso_anot_cadl_repl) as restricao_cadastral  
		from CLIENTES t1
			inner join comum.bcn_pf t2 on (t1.mci = t2.mci)
				order by 1;
quit;

PROC SQL;
	CREATE TABLE restricao_limite_00 AS 
		SELECT t1.MCI, 
/*		    t1.situacao_cadastral,*/
			ifn(t1.situacao_limite_credito=10,1,0) as possui_limite_credito,
			ifn(t1.restricao_cadastral = 4,1,0) as possui_restr_cadastral
		FROM WORK.RESTRICAO_LIMITE t1;
QUIT;
	

DATA JUNTA;
MERGE CLIENTES RESTRICAO_LIMITE_00;
BY MCI;
RUN;

/**/
/*DB2ANC.LMCR_CLI*/
/*Tipos de Situacoes de Limite de Credito vindo da tabela DB2ANC.LMCR_CLI. Sao eles: 00 Em Estudo 10 Vigente 20 Cancelado 25 Cancelado Dados Pendent 30 Canc. a partir vigente 40 Vencido 50 Impedido 60 Indeferido 70 Em transferencia 80 Suspenso*/

/*PROC SQL;CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);*/
/*   CREATE TABLE WORK.QUERY_FOR_LMCR_CLI AS select **/
/*						FROM CONNECTION TO DB2(*/
/*   SELECT t1.CD_CLI, */
/*          t1.TS_ACLT_SLC, */
/*          t1.NR_SEQL_SLCT, */
/*          t1.NR_SEQL_PECS_NVL, */
/*          t1.CD_EST_LMCR, */
/*          t1.CD_TIP_PSS, */
/*          t1.CD_CPF_CGC, */
/*          t1.DT_VNCT_LIM, */
/*          t1.VL_LMCR_APVD, */
/*          t1.VL_LMCR_UTZD, */
/*          t1.VL_PSTC_MAX_APVD, */
/*          t1.VL_PSTC_MAX_UTZD, */
/*          t1.VL_TTL_REC_LIM_CRD, */
/*          t1.VL_TTL_CDD_LIM_CRD, */
/*          t1.VL_SDO_MRG_LMCR, */
/*          t1.CD_MTDL_ANL_CRD, */
/*          t1.CD_PRF_DEPE_CAD, */
/*          t1.CD_RSCO_CRD_CLI, */
/*          t1.DT_APVC_LIM, */
/*          t1.TS_ULT_ATL*/
/*      FROM DB2ANC.LMCR_CLI t1);*/
/*QUIT;*/


        libname bcs "/dados/bcs";
           
            %ls(/dados/bcs, out=limpf);

            data out_ls1;
                set limpf;
                where pasta eq './' and substr(arquivo,1,10) in ('limpf_slim');
                tabela = scan(arquivo,1,'.');
                dt_ref = input(scan(tabela,-1,'_'),ddmmyy8.);
                format dt_ref ddmmyyn6.;
            run;

            proc sql noprint;
                select tabela into :limpf_slim
                    from out_ls1
                        where dt_ref = (select max(dt_ref) from out_ls1);
            quit;

            %put &limpf_slim;



PROC SQL;
   CREATE TABLE CLIENTES_D AS 
   SELECT t1.MCI AS CD_CLI, 
          t1.DTA_CRED, 
          t1.Descricao, 
          t1.CPNT, 
          t1.possui_limite_credito, 
          t1.possui_restr_cadastral,
		  t2.VL_SLIM_DSPN,
		  (CASE 
          WHEN T3.CD_EST_LMCR=00 THEN 'Em estudo'
		  WHEN T3.CD_EST_LMCR=10 THEN 'Vigente'
		  WHEN T3.CD_EST_LMCR=20 THEN 'Cancelado'
		  WHEN T3.CD_EST_LMCR=25 THEN 'Cancelado - dados pendentes'
		  WHEN T3.CD_EST_LMCR=30 THEN 'Cancelado - a partir vigente'
		  WHEN T3.CD_EST_LMCR=40 THEN 'Vencido'
		  WHEN T3.CD_EST_LMCR=50 THEN 'Impedido'
		  WHEN T3.CD_EST_LMCR=60 THEN 'Indeferido'
		  WHEN T3.CD_EST_LMCR=70 THEN 'Em transferência'
		  WHEN T3.CD_EST_LMCR=78 THEN 'Suspenso'
          END)
           as est_lmcr
      FROM WORK.JUNTA t1
      LEFT JOIN BCS.&limpf_slim t2 on (T1.MCI=T2.CD_CLI)
	  LEFT JOIN DB2ANC.LMCR_CLI t3 on (t1.MCI=T3.CD_CLI)
      WHERE T2.CD_SLIM_CRD=15 AND T2.CD_MTDL_ANL_CRD=51 AND T2.CD_TIP_PSS=1 ;
QUIT;

%macro encarteiramento;

	proc sql;
		create table base_mci as
			select distinct cd_cli
				from CLIENTES_D
					order by 1;
		create index cd_cli on base_mci(cd_cli);
	quit;

	proc sql;
		create table encarteiramento as
			select put(e.cd_prf_depe, z4.) as prefdep,
				ifn(cd_tip_ctra in (10 16 50 56 57 59 60), e.nr_seql_ctra, 7002) as carteira,
				ifn(cd_tip_ctra in (10 16 50 56 57 59 60), cd_tip_ctra, 700) as tp_cart,
				e.cd_cli
			from db2rel.cli_ctra e
			inner join db2rel.ctra_cli f on (e.cd_prf_depe=f.cd_prf_depe and e.nr_seql_ctra=f.nr_seql_ctra)
				inner join base_mci c on (e.cd_cli = c.cd_cli)
				inner join igr.igrrede_&ANOMES d on (put(e.cd_prf_depe, z4.)=d.prefdep)
					where f.cd_tip_ctra in (10 16 50 15 56 57 59 60 20 17 18 19 70) and codsitdep in ('2' '4') and tipodep in ('09' '01')
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


LIBNAME DB2MCI 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2MCI database=BDB2P04;
LIBNAME DB2BIC 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2BIC database=BDB2P04;
LIBNAME DB2PRD 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2PRD database=BDB2P04;

/*CONTATOS BIC*/

%Macro Contatos;

	DATA _NULL_;
		SET CHQ.BIC;
		CALL SYMPUT('Executa',DT NE Today());
	RUN;

	%Put &Executa;

	%IF &Executa=1 %THEN
		%DO;

			PROC SQL;
				CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
				EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
				CREATE TABLE CONTATOS_ACM_I AS 
					SELECT *
						FROM CONNECTION TO DB2
							(SELECT D.CD_CLI, DATE(D.TS_INRO_CLI) AS DT_CTT, TX_RSTD_INRO, TX_SUB_RSTD_INRO, CD_USU_RSP_ATDT, F.CD_PRD
								FROM DB2BIC.INRO_HMNO_CLI D
									INNER JOIN (SELECT A.CD_CLI, MIN(TS_INRO_CLI) AS MD
										FROM DB2BIC.INRO_HMNO_CLI A
											INNER JOIN DB2MCI.CLIENTE C ON(A.CD_CLI=C.COD)
												WHERE DATE(TS_INRO_CLI)>='2018-08-01' AND A.CD_FMA_CTT = 2 
													AND (CD_ASNT_INRO=6 AND CD_SUB_ASNT_INRO=20) AND C.COD_TIPO=1
												GROUP BY A.CD_CLI) E ON(D.CD_CLI=E.CD_CLI AND D.TS_INRO_CLI=E.MD)
													INNER JOIN DB2BIC.AUX_INRO_CLI_ATU F ON(D.CD_CLI=F.CD_CLI AND D.TS_INRO_CLI=F.TS_INRO_CLI)
													INNER JOIN DB2BIC.SUB_RSTD_INRO G ON(F.CD_RSTD_INRO=G.CD_RSTD_INRO AND F.CD_SUB_RSTD_INRO=G.CD_SUB_RSTD_INRO)
													INNER JOIN DB2BIC.RSTD_INRO H ON(F.CD_RSTD_INRO=H.CD_RSTD_INRO));
			QUIT;

			PROC SQL;
				CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
				EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
				CREATE TABLE CONTATOS_ACM_X AS 
					SELECT *
						FROM CONNECTION TO DB2
							(SELECT D.CD_CLI, DATE(D.TS_INRO_CLI) AS DT_CTT, TX_RSTD_INRO, TX_SUB_RSTD_INRO, CD_USU_RSP_ATDT, F.CD_PRD
								FROM DB2BIC.INRO_HMNO_CLI D
									INNER JOIN (SELECT A.CD_CLI, MIN(TS_INRO_CLI) AS MD
										FROM DB2BIC.INRO_HMNO_CLI A
											INNER JOIN DB2MCI.CLIENTE C ON(A.CD_CLI=C.COD)
												WHERE DATE(TS_INRO_CLI)>='2018-08-01' AND A.CD_FMA_CTT = 2
													AND (CD_ASNT_INRO=6 AND CD_SUB_ASNT_INRO=20)  AND C.COD_TIPO=1
												GROUP BY A.CD_CLI) E ON(D.CD_CLI=E.CD_CLI AND D.TS_INRO_CLI=E.MD)
													INNER JOIN DB2BIC.AUX_INRO_CLI_ANT F ON(D.CD_CLI=F.CD_CLI AND D.TS_INRO_CLI=F.TS_INRO_CLI)
													INNER JOIN DB2BIC.SUB_RSTD_INRO G ON(F.CD_RSTD_INRO=G.CD_RSTD_INRO AND F.CD_SUB_RSTD_INRO=G.CD_SUB_RSTD_INRO)
													INNER JOIN DB2BIC.RSTD_INRO H ON(F.CD_RSTD_INRO=H.CD_RSTD_INRO));
			QUIT;

			DATA CHQ.BIC;
				DT=Today();
			RUN;

		%END;

	PROC SQL;
		CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
		EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
		CREATE TABLE CONTATOS_ACM_II AS 
			SELECT *
				FROM CONNECTION TO DB2
					(SELECT D.CD_CLI, DATE(D.TS_INRO_CLI) AS DT_CTT, TX_RSTD_INRO, TX_SUB_RSTD_INRO, CD_USU_RSP_ATDT, F.CD_PRD
						FROM DB2BIC.INRO_HMNO_CLI D
							INNER JOIN (SELECT A.CD_CLI, MIN(TS_INRO_CLI) AS MD
								FROM DB2BIC.INRO_HMNO_CLI A
									INNER JOIN DB2MCI.CLIENTE C ON(A.CD_CLI=C.COD)
										WHERE DATE(TS_INRO_CLI)>='2018-08-01' AND A.CD_FMA_CTT = 2
											AND (CD_ASNT_INRO=6 AND CD_SUB_ASNT_INRO=20) AND C.COD_TIPO=1
										GROUP BY A.CD_CLI) E ON(D.CD_CLI=E.CD_CLI AND D.TS_INRO_CLI=E.MD)
											INNER JOIN DB2BIC.INRO_CLI F ON(D.CD_CLI=F.CD_CLI AND D.TS_INRO_CLI=F.TS_INRO_CLI)
											INNER JOIN DB2BIC.SUB_RSTD_INRO G ON(F.CD_RSTD_INRO=G.CD_RSTD_INRO AND F.CD_SUB_RSTD_INRO=G.CD_SUB_RSTD_INRO)
											INNER JOIN DB2BIC.RSTD_INRO H ON(F.CD_RSTD_INRO=H.CD_RSTD_INRO));
	QUIT;

	%IF &Executa=1 %THEN
		%DO;

			PROC SQL;
				CREATE TABLE CONTATOS_ACM_III AS
					SELECT *
						FROM CONTATOS_ACM_I
							UNION
						SELECT *
							FROM CONTATOS_ACM_II
								UNION
							SELECT *
								FROM CONTATOS_ACM_X;
			QUIT;

		%END;
	%ELSE
		%DO;

			DATA CONTATOS_ACM_III;
				SET CONTATOS_ACM_II
;
			RUN;

		%END;
%Mend;

%Contatos;

PROC SQL;
	CREATE TABLE CONTATOS_ACM AS
		SELECT A.*
			FROM CONTATOS_ACM_III A
				INNER JOIN (SELECT CD_CLI, MAX(DT_CTT) AS DT
					FROM CONTATOS_ACM_III
						WHERE CD_PRD=8
							GROUP BY 1) B ON(A.CD_CLI=B.CD_CLI AND A.DT_CTT=B.DT)
								ORDER BY 1;
QUIT;

DATA CONTATOS_ACM(WHERE=(DT_CTT>=MDY(8,01,2018)));
	SET CHQ.CONTATOS_201808 CONTATOS_ACM;
WHERE CD_PRD = 8;
RUN;

PROC SORT DATA=CONTATOS_ACM OUT=CHQ.CONTATOS_18 NODUPKEY;
	BY _ALL_;
RUN;

PROC SQL;
	CREATE TABLE CONTATOS AS
		SELECT A.CD_CLI, A.DT_CTT, A.TX_RSTD_INRO, A.TX_SUB_RSTD_INRO, A.CD_USU_RSP_ATDT,A.CD_PRD
			FROM CHQ.CONTATOS_18 A
				INNER JOIN (SELECT CD_CLI, MAX(DT_CTT) AS MAX_D
					FROM CHQ.CONTATOS_18
						GROUP BY 1) B ON(A.CD_CLI=B.CD_CLI AND A.DT_CTT=B.MAX_D)
							ORDER BY 1;
QUIT;


LIBNAME DB2ATB	db2 AUTHDOMAIN=DB2SGCEN schema=DB2ATB database=BDB2P04;


PROC SQL;
	CREATE TABLE ENCARTEIRADOS AS 
		SELECT DISTINCT
		TODAY() FORMAT DDMMYY10. AS POSICAO,
			t2.prefdep,
			t2.carteira,
			t1.CD_CLI, 
			t1.DTA_CRED, 
			t1.Descricao, 
			t1.CPNT, 
			t1.possui_limite_credito, 
			t1.possui_restr_cadastral,
			t3.dt_ctt,
			t3.TX_RSTD_INRO,
			t3.TX_SUB_RSTD_INRO,
			t3.CD_USU_RSP_ATDT,
			IFN(CPNT>0,1,0) AS POSSUI_PROVENTOS,
			t1.est_lmcr,
			t1.VL_SLIM_DSPN format best12.2 as VL_SLIM_DSPN
		FROM WORK.CLIENTES_D t1
			inner join encarteiramento t2 on (t1.cd_cli=t2.cd_cli)
				left join contatos t3 on (t1.cd_cli=t3.cd_cli)
				group by 1,2,3,4

	;
QUIT;



PROC SQL;
   CREATE TABLE CARTEIRA AS 
   SELECT DISTINCT 
input(t1.prefdep, 4.) as prefdep,
          t1.carteira as CTRA, 
            (COUNT(distinct t1.CD_CLI)) AS QTD_CLIENTES, 
            (SUM(t1.POSSUI_PROVENTOS)) AS QTD_PROVENTISTAS,
            (SUM(t1.possui_limite_credito)) AS QTD_POSSUI_LIMITE,
            (SUM(t1.possui_restr_cadastral)) AS QTD_POSSUI_RESTRICAO,
			(COUNT(t1.dt_ctt)) AS CONTATOS,
			(SUM(t1.vl_slim_dspn))  AS vl_slim_dspn
      FROM WORK.ENCARTEIRADOS t1  
/*      INNER JOIN IGR.IGRREDE T2 ON (T1.PREFDEP=T2.PREFDEP)*/
/*	  WHERE TIPODEP IN ('09' '01') AND CODSITDEP IN ('2' '4')*/
      GROUP BY 1,2;
QUIT;


/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
	DROP TABLE COLS_SUM;
	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );
	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COLS_SUM VALUES ('QTD_CLIENTES', 'SUM', 'QTD_CLIENTES');
	INSERT INTO COLS_SUM VALUES ('QTD_PROVENTISTAS', 'SUM', 'QTD_PROVENTISTAS');
	INSERT INTO COLS_SUM VALUES ('QTD_POSSUI_LIMITE', 'SUM', 'QTD_POSSUI_LIMITE');
	INSERT INTO COLS_SUM VALUES ('QTD_POSSUI_RESTRICAO', 'SUM', 'QTD_POSSUI_RESTRICAO');
		INSERT INTO COLS_SUM VALUES ('CONTATOS', 'SUM', 'CONTATOS');
	INSERT INTO COLS_SUM VALUES ('vl_slim_dspn', 'SUM', 'vl_slim_dspn');
QUIT;
%SumarizadorCNX(TblSASValores=CARTEIRA, TblSASColunas=COLS_SUM, NivelCTRA=1, PAA_PARA_AGENCIA=0, TblSaida=FINAL_DEPE, AAAAMM=&ANOMES.);


PROC SQL;
	CREATE TABLE WORK.CONEXAO_CHEQUE AS 
		SELECT DISTINCT 
			INPUT(T2.PREFDEP,4.) AS PREFDEP,
			t1.CD_UOR_CTRA, 
			t1.NR_SEQL_CTRA, 
			t1.VL_META_IN_MBZ, 
			t1.VL_RLZD_IN_MBZ, 
			t1.PC_ATGT_IN_MBZ
		FROM DB2ATB.VL_APRD_IN_MBZ_MM t1
			INNER JOIN IGR.IGRREDE_&ANOMES T2 ON (T1.CD_UOR_CTRA=INPUT(T2.UOR,9.))
				WHERE t1.CD_IN_MBZ = 115 AND t1.AA_APRC = 2018 AND t1.MM_APRC = 10;
QUIT;

PROC SQL;
	CREATE TABLE final_depe AS 
		SELECT DISTINCT 
			today()-1 FORMAT DDMMYY10. AS POSICAO,
			t1.prefdep, 
			t1.CTRA as CARTEIRA, 
			QTD_CLIENTES format 19.0, 
			QTD_PROVENTISTAS format 19.0,
			QTD_POSSUI_LIMITE format 19.0,
			QTD_POSSUI_RESTRICAO format 19.0,
			CONTATOS format 19.0,
			vl_slim_dspn,
			t2.VL_META_IN_MBZ, 
			t2.VL_RLZD_IN_MBZ, 
			t2.PC_ATGT_IN_MBZ
		FROM WORK.final_depe t1  
		LEFT JOIN CONEXAO_CHEQUE T2 ON (T1.PREFDEP=T2.PREFDEP AND T1.CTRA=T2.NR_SEQL_CTRA)
	GROUP BY 1,2,3;
QUIT;




/*relatório 369*/



%LET Usuario=f9457977;
%LET Keypass=Qos4f6B06723Jny8rZC720C4ao6t87mPVp8RtvvRAyZNiOPb40;
PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('final_depe', 'oferta-chq');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('encarteirados', 'clientes');
QUIT;
%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);

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
