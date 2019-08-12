

%include '/dados/infor/suporte/FuncoesInfor.sas';
%IniciarProcessoMysql(Tarifas de Cobran�a, Ernani);
LIBNAME CBR "/dados/infor/producao/tarifas_cobranca";
%LET Indicador=67;
%LET Mes=0;

DATA _NULL_;
	IF &Mes=0 THEN
		CALL SYMPUT('D1',DiaUtilAnterior(Today()));
	ELSE
		DO;
			AA=Floor(&Mes/100);
			MM=&Mes-(AA*100);
			DD=DiaUtilAnterior(IntNx('month',MDY(MM,1,AA),1));
			CALL SYMPUT('D1',DD);
		END;
RUN;

%Put &D1;

DATA _NULL_;
	CALL SYMPUT('AnoMes',Put(&D1, yymmn6.));
	CALL SYMPUT('MesAno',Put(&D1, mmyyn6.));
	CALL SYMPUT('Ini',"'"||Put(IntNx('month',&D1,0), yymmdd10.)||"'");
	CALL SYMPUT('Fim',"'"||Put(&D1, yymmdd10.)||"'");
RUN;

%Put &AnoMes &MesAno &Ini &Fim;

%Macro Direcionador;
	%IF &AnoMes>=201807 %THEN
		%DO;
			%LIBCONEXAO(67);
			%LIBCONEXAO(133);

			%IF &AnoMes<201810 %THEN
				%DO;

					DATA ICNX133.INDICADOR_000000133;
						SET ICNX067.INDICADOR_000000067;
						IND=133;
					RUN;

					DATA OCNX133.IND_ORC_000000133;
						SET OCNX067.IND_ORC_000000067;
						IND=133;
					RUN;

					DATA _NULL_;
						CALL SYMPUT('A',EXIST("ICNX067.CLI_IND_000000067_DT&MesAno"));
					RUN;

					%PUT &A;

					%IF &A %THEN
						%DO;

							DATA ICNX133.CLI_IND_000000133_DT&MesAno;
								SET ICNX067.CLI_IND_000000067_DT&MesAno;
								IND=133;
							RUN;

							%ExportarCNX_CLI(133, &MesAno);
						%END;

					%ExportarCNX_COMP(133, &MesAno);
					%ExportarCNX_IND(133, &MesAno, ORC=1, RLZ=1);
				%END;
			%ELSE
				%DO;
					%ApuraDirecionador(Indicador=67, Direcionador=133, CPNT_IND=0, D1=&D1, MULT=1.1, ForcarMeta=0);

					%IF &AnoMes=201811 %THEN
						%ApuraDirecionador(Indicador=67, Direcionador=158, CPNT_IND=0, D1=&D1, MULT=1, ForcarMeta=0, EnviaMeta=0);
				%END;
		%END;
%Mend;

PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
	CREATE TABLE TRF_CBR AS
		SELECT CD_CLI, DT_EFTC_CBR_TARF Format ddmmyy10. AS DT_CBR, Sum(VLR_TRF) AS VLR_TRF
			FROM CONNECTION TO DB2
				(SELECT CD_CLI_VCLD_CT_OGM AS CD_CLI, DT_EFTC_CBR_TARF,
					VL_OPR_CBR_TARF AS VLR_TRF
				FROM DB2TFA.CBR_TARF_REC A
					INNER JOIN DB2MCI.CLIENTE B ON(A.CD_CLI_VCLD_CT_OGM=B.COD)
						WHERE CD_PRD_CBR_TARF=14 AND DT_EFTC_CBR_TARF BETWEEN &Ini AND &Fim
							AND COD_TIPO=2)
						WHERE VLR_TRF NE 0 AND CD_CLI NE 0
							GROUP BY 1, 2;
	DISCONNECT FROM DB2;
QUIT;

DATA CBR.TRF_CBR_TOTAL_&AnoMes;
	SET TRF_CBR;
RUN;

PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	CREATE TABLE CLIENTES_GOV_EXCLUSAO AS
		SELECT COD AS CD_CLI
			FROM CONNECTION TO DB2
				(SELECT COD 
					FROM DB2MCI.CLIENTE
						WHERE COD_MERC = 3
							ORDER BY COD);
	DISCONNECT FROM DB2;
QUIT;

DATA _NULL_;
	IF &AnoMes>=201810 THEN
		CALL SYMPUT('TBL','CLIENTES_GOV_EXCLUSAO(OBS=0)');
	ELSE CALL SYMPUT('TBL','CLIENTES_GOV_EXCLUSAO');
RUN;

%PUT &TBL;

DATA CLIENTES_GOV_EXCLUSAO;
	SET &TBL;
RUN;

PROC SQL;
	CREATE TABLE RESUMO_TRF_CLIENTE AS
		SELECT A.CD_CLI, Sum(VLR_TRF) AS VLR_TRF
			FROM CBR.TRF_CBR_TOTAL_&AnoMes A
				LEFT JOIN CLIENTES_GOV_EXCLUSAO B ON(A.CD_CLI=B.CD_CLI)
					WHERE B.CD_CLI Is Missing
						GROUP BY 1;
	CREATE INDEX CD_CLI ON RESUMO_TRF_CLIENTE(CD_CLI);
QUIT;

%BuscarOrcado(&Indicador, &MesAno);

DATA ORCADOS(KEEP=PREFDEP CTRA VLR_ORC);
	SET ORCADOS(WHERE=(CTRA NE 0 AND VLR_ORC>0 AND COMP=0));
RUN;

PROC SQL;
	CREATE TABLE ACRD AS
		SELECT DISTINCT Prefixo AS PrefDep, CTRA, 1 AS ACRD
			FROM CNX18.ACORDO_IND_PRF_CTRA_PESO 
				WHERE IND=&Indicador AND MMAAAA=&MesAno
					ORDER BY 1, 2;
QUIT;

PROC SORT DATA=ORCADOS NODUPKEY;
	BY PrefDep CTRA;
RUN;

DATA ORCADOS(WHERE=(VLR_ORC NE .) DROP=ACRD);
	MERGE ORCADOS ACRD;
	BY PrefDep CTRA;
	ACRD=COALESCE(ACRD,0);

	IF ACRD NE 0;
RUN;

%Macro Encarteiramento;

	PROC SQL;
		CREATE TABLE ENCARTEIRAMENTO AS
			SELECT CD_PRF_DEPE AS PrefDep, NR_SEQL_CTRA AS Carteira, 
				CD_TIP_CTRA AS TC, E.CD_CLI
			FROM COMUM.PAI_REL_PJ_&AnoMes E
				INNER JOIN RESUMO_TRF_CLIENTE A ON(E.CD_CLI=A.CD_CLI)
					ORDER BY 4;
	QUIT;

	PROC SQL NOPRINT;
		SELECT COUNT(*) INTO: X
			FROM (SELECT CD_CLI
			FROM ENCARTEIRAMENTO
				GROUP BY 1
					HAVING COUNT(*)>1);
	QUIT;

	%Put &X;

	%IF &X>0 %THEN
		%DO;

			DATA DUPLICADOS(DROP=CARTEIRA TC);
				SET ENCARTEIRAMENTO(Obs=0);
			RUN;

			PROC SQL;
				CREATE TABLE AUX_D AS
					SELECT CD_CLI
						FROM ENCARTEIRAMENTO
							GROUP BY 1
								HAVING COUNT(*)>1;
			QUIT;

			DATA AUX_D(DROP=Seq);
				SET AUX_D;
				Seq+1;
				Grupo=CEIL(Seq/5957);
			RUN;

			PROC SQL NOPRINT;
				SELECT MAX(Grupo) INTO: Q
					FROM AUX_D;
			QUIT;

			%PUT &Q;

			%DO I=1 %TO &Q;

				PROC SQL NOPRINT;
					SELECT CD_CLI INTO: Var Separated By ', '
						FROM AUX_D
							WHERE Grupo=&I;
				QUIT;

				PROC SQL;
					CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
					INSERT INTO DUPLICADOS
						SELECT COD_PREF_AGEN, COD
							FROM CONNECTION TO DB2
								(SELECT COD, COD_PREF_AGEN
									FROM DB2MCI.CLIENTE
										WHERE COD IN(&Var)
											ORDER BY COD;);
					DISCONNECT FROM DB2;
				QUIT;

				PROC SQL;
					CREATE TABLE FIM_DUP AS
						SELECT A.*, CARTEIRA, TC
							FROM DUPLICADOS A
								INNER JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI AND A.PrefDep=B.PrefDep)
									ORDER BY 2;
					DELETE FROM DUPLICADOS;
				QUIT;

				DATA ENCARTEIRAMENTO;
					SET ENCARTEIRAMENTO(WHERE=(CD_CLI NOT IN(&Var.))) FIM_DUP;
					BY CD_CLI;
				RUN;

			%END;
		%END;

	PROC DELETE DATA=FIM_DUP AUX_D DUPLICADOS;
	RUN;

	PROC SQL NOPRINT;
		SELECT COUNT(*) INTO: X
			FROM (SELECT DISTINCT A.CD_CLI
			FROM RESUMO_TRF_CLIENTE A
				LEFT JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI)
					WHERE B.CD_CLI Is Missing);
	QUIT;

	%Put &X;

	%IF &X>0 %THEN
		%DO;

			DATA PERDIDOS;
				SET ENCARTEIRAMENTO(Obs=0);
			RUN;

			PROC SQL;
				CREATE TABLE AUX_P AS
					SELECT DISTINCT A.CD_CLI
						FROM RESUMO_TRF_CLIENTE A
							LEFT JOIN ENCARTEIRAMENTO B ON(A.CD_CLI=B.CD_CLI)
								WHERE B.CD_CLI Is Missing;
			QUIT;

			DATA AUX_P(DROP=Seq);
				SET AUX_P;
				Seq+1;
				Grupo=CEIL(Seq/5957);
			RUN;

			PROC SQL NOPRINT;
				SELECT MAX(Grupo) INTO: Q
					FROM AUX_P;
			QUIT;

			%Put &Q;

			%DO I=1 %TO &Q;

				PROC SQL NOPRINT;
					SELECT CD_CLI Format 9. INTO: Var Separated By ', '
						FROM AUX_P
							WHERE Grupo=&I;
				QUIT;

				PROC SQL;
					CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
					INSERT INTO PERDIDOS
						SELECT COD_PREF_AGEN, 7002, 700, COD
							FROM CONNECTION TO DB2
								(SELECT COD, COD_PREF_AGEN, 
									7002 AS CARTEIRA, 700 AS TC
								FROM DB2MCI.CLIENTE
									WHERE COD IN(&Var)
										ORDER BY COD;);
					DISCONNECT FROM DB2;
				QUIT;

			%END;

			PROC SORT DATA=PERDIDOS;
				BY CD_CLI;
			RUN;

			DATA ENCARTEIRAMENTO;
				SET ENCARTEIRAMENTO PERDIDOS;
				BY CD_CLI;
			RUN;

			PROC DELETE DATA=AUX_P PERDIDOS;
			RUN;

		%END;
%Mend;

%Encarteiramento;

DATA AUX_META/VIEW=AUX_META;
	SET ORCADOS(KEEP=PrefDep CTRA VLR_ORC WHERE=(VLR_ORC>0 AND CTRA NE 0));
RUN;

PROC SQL;
	CREATE TABLE RSM_CLI_ENC AS
		SELECT A.PrefDep,
			IFN(TC IN(303 315 321 322 328), Carteira, 7002) AS Carteira,
			IFN(TC IN(303 315 321 322 328), TC, 700) AS TC,
			A.CD_CLI, VLR_TRF, TipoDep, Input(PrefAgenc, 4.) AS Agencia
		FROM ENCARTEIRAMENTO A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.) AND B.TipoDep In('01' '09') AND B.PrefDep NE '4777')
			INNER JOIN RESUMO_TRF_CLIENTE C ON(A.CD_CLI=C.CD_CLI)
			INNER JOIN AUX_META D ON(A.PrefDep=D.PrefDep AND IFN(A.TC IN(303 315 321 322 328), A.Carteira, 7002)=D.CTRA)
				ORDER BY 1, 2, 4;
	DROP VIEW AUX_META;
QUIT;

PROC SQL;
	CREATE TABLE CRT AS
		SELECT PrefDep, Carteira, TipoDep, Agencia, SUM(VLR_TRF) AS VLR_TRF
			FROM RSM_CLI_ENC
				GROUP BY 1, 2, 3, 4;
QUIT;

PROC SQL;
	CREATE TABLE ORC_AJ AS
		SELECT A.*, TipoDep, Input(PrefAgenc, 4.) AS Agencia
			FROM ORCADOS A
				INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.))
					ORDER BY 1, 2;
QUIT;

DATA CRT;
	MERGE CRT(RENAME=(VLR_TRF=VLR_RLZ)) ORC_AJ(RENAME=(CTRA=Carteira));
	BY PrefDep Carteira;
	VLR_RLZ=COALESCE(VLR_RLZ,0);
RUN;

PROC SQL;
	CREATE TABLE PAA AS
		SELECT PrefDep, SUM(VLR_RLZ) AS VLR_RLZ, SUM(VLR_ORC) AS VLR_ORC, 0 AS Carteira
			FROM CRT
				WHERE TipoDep='01'
					GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE AGC AS
		SELECT IFN(TipoDep='01', Agencia, PrefDep) AS PrefDep, SUM(VLR_RLZ) AS VLR_RLZ, Sum(VLR_ORC) AS VLR_ORC,
			0 AS Carteira
		FROM CRT
			GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE GRV AS
		SELECT Input(PrefSupReg, 4.) AS PrefDep, SUM(VLR_RLZ) AS VLR_RLZ, Sum(VLR_ORC) AS VLR_ORC,
			0 AS Carteira
		FROM AGC A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.))
				GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE SUP AS
		SELECT Input(PrefSupEst, 4.) AS PrefDep, SUM(VLR_RLZ) AS VLR_RLZ, Sum(VLR_ORC) AS VLR_ORC,
			0 AS Carteira
		FROM AGC A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.))
				GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE DIR AS
		SELECT Input(PrefUEN, 4.) AS PrefDep, SUM(VLR_RLZ) AS VLR_RLZ, Sum(VLR_ORC) AS VLR_ORC,
			0 AS Carteira
		FROM AGC A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.))
				GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE VIP AS
		SELECT 8166 AS PrefDep, SUM(VLR_RLZ) AS VLR_RLZ, Sum(VLR_ORC) AS VLR_ORC,
			0 AS Carteira
		FROM AGC A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.));
QUIT;

DATA RESUMO_INDICADOR(WHERE=(PrefDep NE 0));
	SET CRT(DROP=TipoDep Agencia) AGC GRV SUP DIR VIP PAA;
	Format VLR_RLZ 19.2;
	BY _ALL_;
	Carteira=Coalesce(Carteira,0);
RUN;

DATA CBR.RSM_CLI_&AnoMes;
	SET RSM_CLI_ENC(DROP=TipoDep Agencia);
RUN;

PROC SQL;
	CREATE TABLE CLIENTES AS
		SELECT &Indicador AS IND,
			1 AS COMP, A.PREFDEP, Input(UOR, 9.) AS UOR,
			Carteira AS CTRA, CD_CLI AS CLI,
			&MesAno AS MMAAAA, VLR_TRF AS VLR
		FROM RSM_CLI_ENC A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.))
				ORDER BY 6, 2;
QUIT;

%BaseIndicadorCNX_CLI(CLIENTES);

PROC SQL;
	CREATE TABLE INDICADOR AS
		SELECT &Indicador AS IND, 0 AS COMP, 0 AS COMP_PAI, 0 AS ORD_EXI, INPUT(B.UOR, 9.) AS UOR,
			A.PrefDep, Carteira AS CTRA, VLR_RLZ, VLR_ORC, 
			0 AS VLR_ATG, &D1 Format yymmdd10. AS POSICAO 
		FROM RESUMO_INDICADOR A
			INNER JOIN IGR.IGRREDE_&AnoMes B ON(A.PrefDep=Input(B.PrefDep, 4.))
				ORDER BY 6, 7;
QUIT;

DATA CPNT;
	SET INDICADOR INDICADOR(DROP=COMP ORD_EXI VLR_ORC);
	COMP=COALESCE(COMP,1);
	ORD_EXI=COALESCE(ORD_EXI,1);
	VLR_ORC=COALESCE(VLR_ORC,0);
	BY PrefDep CTRA;
RUN;

PROC SQL;
	CREATE TABLE TBLRPT AS
		SELECT &D1 Format yymmdd10. AS Posicao, PrefDep AS Prefixo, CTRA AS Carteira,
			VLR_RLZ, VLR_ORC, IFN(VLR_ORC=0,0,(VLR_RLZ/VLR_ORC))*100 AS ATG
		FROM INDICADOR
			ORDER BY 2, 3;
QUIT;

%LET Usuario=f2986408;
%LET Keypass=G8o0oRM7BKAiSlC97Cc8ZrP63kYhd5tIQFQLtOqcgxp88fVijJ;

PROC SQL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('TBLRPT', 'tarifa-cobranca');
QUIT;

%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);
%BaseIndicadorCNX(TabelaSAS=CPNT);
%ExportarCNX_CLI(&Indicador, &MesAno);
%ExportarCNX_COMP(&Indicador, &MesAno);
%ExportarCNX_IND(&Indicador, &MesAno);
%Direcionador;
x cd /dados/infor/producao/tarifas_cobranca;
x chmod 2777 *;

%EncerrarProcessoMysql(Tarifas de Cobran�a);