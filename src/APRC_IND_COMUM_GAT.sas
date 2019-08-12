/*#################################################################################################################*/
/************** INICIAR PROCESSO ****************/
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';
/************************************************/


/*#################################################################################################################*/
/*##### B I B L I O T E C A S #####*/
LIBNAME DB2GAT 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2GAT database=BDB2P04;
LIBNAME DB2DEB 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2DEB database=BDB2P04;
LIBNAME DB2UOR 	db2 AUTHDOMAIN=DB2SGCEN schema=DB2UOR database=BDB2P04;
LIBNAME GAT		'/dados/infor/bases/gat';


/*
DEFINE SE O PROCESSAMENTO SERÁ INTEGRAL DO MES, OU POR APPEND:
PROC_MM=1 >>> INTEGRAL
PROC_MM=0 >>> APPEND
*/

%LET PROC_MM=0;


/*CONTROLE DE DATAS*/
DATA _NULL_;
	DT_D1 = diaUtilAnterior(TODAY());
/*	DT_D1 = diaUtilAnterior(MDY(04,01,2019));*/
	DT_HJ=TODAY();
	DT_INC_MM=primeiroDiaMes(DT_D1);
	DT_FIM_MM=ultimoDiaMes(DT_D1);
	DT_D5=setDiaUtilAnterior(DT_D1, 5);
	AAAAMM = PUT(DT_D1, yymmn6.);
	AAAAMM_HJ = PUT(DT_HJ, yymmn6.);
	MMAAAA = PUT(DT_D1, mmyyn6.);
	PROC_MM=IFN(MONTH(DT_D5) NE MONTH(DT_D1), 1, &PROC_MM.);
	DT_INC=IFN(PROC_MM=1, DT_INC_MM, DT_D5);
	DT_FIM=IFN(PROC_MM=1, IFN(DT_FIM_MM>=DT_HJ, DT_D1, DT_FIM_MM), DT_D1);

	CALL SYMPUT('PROC_MM',COMPRESS(PROC_MM,' '));
	CALL SYMPUT('DT_HJ',COMPRESS(DT_HJ,' '));
	CALL SYMPUT('DT_D1',COMPRESS(DT_D1,' '));
	CALL SYMPUT('DT_INC_MM',COMPRESS(DT_INC_MM,' '));
	CALL SYMPUT('DT_INC',COMPRESS(DT_INC,' '));
	CALL SYMPUT('DT_FIM',COMPRESS(DT_FIM,' '));
	CALL SYMPUT('AAAAMM',COMPRESS(AAAAMM,' '));
	CALL SYMPUT('AAAAMM_HJ',COMPRESS(AAAAMM_HJ,' '));
	CALL SYMPUT('MMAAAA',COMPRESS(MMAAAA,' '));

	CALL SYMPUT('DT_HJ_SQL',"'"||PUT(DT_HJ, yymmdd10.)||"'");
	CALL SYMPUT('DT_INC_MM_SQL',"'"||PUT(DT_INC_MM, yymmdd10.)||"'");
	CALL SYMPUT('DT_D1_SQL',"'"||PUT(DT_D1, yymmdd10.)||"'");
	CALL SYMPUT('DT_INC_SQL',"'"||PUT(DT_INC, yymmdd10.)||"'");
	CALL SYMPUT('DT_FIM_SQL',"'"||PUT(DT_FIM, yymmdd10.)||"'");
RUN; 

%PUT AnoMes: &AAAAMM. Inicio Mes: &DT_INC_MM_SQL. Hoje: &DT_HJ_SQL. D1: &DT_D1_SQL.;

%PUT Dt inicio: &DT_INC_SQL. Dt fim: &DT_FIM_SQL.;


/*GUARDAR TABELA DE TIP_FILA_ATDT POR NÃO POSSUIR HISTÓRICO*/
%MACRO GERAR_COPIA_TIP_FILA_ATDT();
	%IF &AAAAMM. = &AAAAMM_HJ. %THEN %DO;
		DATA GAT.TIP_FILA_ATDT_&AAAAMM.;
			SET DB2GAT.TIP_FILA_ATDT;
		RUN;
	%END;
%MEND GERAR_COPIA_TIP_FILA_ATDT; %GERAR_COPIA_TIP_FILA_ATDT();


PROC SQL;
    CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=DB23P41);
    EXECUTE (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
    CREATE TABLE ATDT_GAT_&AAAAMM. AS
        SELECT DISTINCT *
        FROM CONNECTION TO DB2 (
            SELECT
                T1.CD_UOR_SLCT AS UOR_SLCT,
                CASE WHEN T2.CD_UOR_RLZC_ATDT = 0 THEN NULL ELSE T2.CD_UOR_RLZC_ATDT END AS UOR_RLZC_ATDT,
                T4.CD_DEPE_VCLD AS UOR_VCLD,
                CASE WHEN T4.CD_DEPE_VCLD IS NULL THEN NULL ELSE T4.NR_SEQL_CTRA END AS CTRA_VCLD,
                T2.CD_CHV_ATD AS CHV_ATD_ATDT,
                CONCAT('F', RIGHT(DIGITS(T4.NR_MTC_ADM_ATDT), 7)) AS CHV_ADM_ATDT,
                T1.CD_SNH_ATDT,
                T1.NR_SLCT_ATDT,
                T2.NR_PTL_ATDT,
                T3.NR_SEQL_FILA_ATDT,
                T1.CD_TIP_ATDT,
				T2.CD_TIP_ESP_ATDT,
				T1.CD_TIP_OGM_SLCT,
                T2.CD_EST_PTL_ATDT,	
                T1.DT_HST_SLCT_ATDT AS DT_SLCT_ATDT,
                TIME(T2.TS_INC_EPR) AS HR_INC_EPR,
                TIME(T2.TS_CHGD_DEPE) AS HR_CHGD_DEPE,
                TIME(T2.TS_INC_ATDT) AS HR_INC_ATDT,
                TIME(T2.TS_FIM_ATDT) AS HR_FIM_ATDT,
                T2.QT_HH_DFRT_BSB,
                COALESCE(T1.CD_CLI, C2.COD) AS CD_CLI,
                COALESCE(T1.NR_ISCR_SRF, C1.COD_CPF_CGC) AS NR_ISCR_SRF,
                COALESCE(C1.COD_TIPO, C2.COD_TIPO) AS CD_TIP_PSS,
                COALESCE(C1.COD_PREF_AGEN, C2.COD_PREF_AGEN) AS PREF_CLI_CDST,
				T1.CD_TIP_CTRA
            FROM DB2GAT.HST_SLCT_ATDT T1
            INNER JOIN DB2GAT.HST_PTL_ATDT T2 ON (T1.DT_HST_SLCT_ATDT = T2.DT_HST_PTL_ATDT AND T1.CD_UOR_SLCT=T2.CD_UOR_SLCT AND T1.NR_SLCT_ATDT=T2.NR_SLCT_ATDT)
            LEFT JOIN DB2GAT.HST_PTL_TIP_UND T3 ON (T1.DT_HST_SLCT_ATDT=T3.DT_HST_TIP_UND_PTL AND T1.CD_UOR_SLCT=T3.CD_UOR_SLCT AND T1.NR_SLCT_ATDT=T3.NR_SLCT_ATDT AND T2.NR_PTL_ATDT=T3.NR_PTL_ATDT)
            LEFT JOIN DB2GAT.TIP_FILA_ATDT T4 ON (T3.CD_UOR_SLCT=T4.CD_DEPE AND T3.NR_SEQL_FILA_ATDT=T4.NR_SEQL_FILA_ATDT)

			LEFT JOIN DB2MCI.CLIENTE C1 ON (T1.CD_CLI = C1.COD AND T1.CD_CLI > 0 AND C1.COD > 0)
            LEFT JOIN DB2MCI.CLIENTE C2 ON (T1.NR_ISCR_SRF = C2.COD_CPF_CGC AND T1.NR_ISCR_SRF > 0 AND C2.COD_CPF_CGC > 0)

            WHERE
					(T1.DT_HST_SLCT_ATDT >= &DT_INC_SQL. AND T1.DT_HST_SLCT_ATDT <= &DT_FIM_SQL.)
                AND (T2.DT_HST_PTL_ATDT >= &DT_INC_SQL. AND T2.DT_HST_PTL_ATDT <= &DT_FIM_SQL.) 
            );
    DISCONNECT FROM DB2;
QUIT;



/*AJUSTE DA TABELA TIP FILA EM CASO DE REPROCESSAMENTO*/
PROC SQL;
	CREATE TABLE ATDT_GAT_&AAAAMM. AS 
		SELECT 
			t1.UOR_SLCT, 
			t1.UOR_RLZC_ATDT, 
			t2.CD_DEPE_VCLD AS UOR_VCLD,
			CASE WHEN t2.CD_DEPE_VCLD IS MISSING THEN . ELSE t2.NR_SEQL_CTRA END AS CTRA_VCLD,
			t1.CHV_ATD_ATDT,
			IFC(t2.NR_MTC_ADM_ATDT IS MISSING, '', 'F'||PUT(t2.NR_MTC_ADM_ATDT, Z7.)) AS CHV_ADM_ATDT, 
			t1.CD_SNH_ATDT, 
			t1.NR_SLCT_ATDT, 
			t1.NR_PTL_ATDT, 
			t1.NR_SEQL_FILA_ATDT, 
			t1.CD_TIP_ATDT, 
			t1.CD_TIP_ESP_ATDT,
			t1.CD_TIP_OGM_SLCT,
			t1.CD_EST_PTL_ATDT, 
			t1.DT_SLCT_ATDT, 
			t1.HR_INC_EPR, 
			t1.HR_CHGD_DEPE, 
			t1.HR_INC_ATDT, 
			t1.HR_FIM_ATDT, 
			t1.QT_HH_DFRT_BSB, 
			t1.CD_CLI, 
			t1.NR_ISCR_SRF, 
			t1.CD_TIP_PSS, 
			t1.PREF_CLI_CDST,
			t1.CD_TIP_CTRA
		FROM WORK.ATDT_GAT_&AAAAMM. t1
		LEFT JOIN GAT.TIP_FILA_ATDT_&AAAAMM. t2 ON (t1.UOR_SLCT=t2.CD_DEPE AND t1.NR_SEQL_FILA_ATDT=t2.NR_SEQL_FILA_ATDT)
;QUIT;




/*ADD PREFIXOS DOS UOR*/
PROC SQL;
	CREATE TABLE ATDT_GAT_&AAAAMM.  AS 
		SELECT 
			t1.UOR_SLCT,
			INPUT(u1.PrefDep, 4.) AS PREF_SLCT,  
			t1.UOR_RLZC_ATDT,
			INPUT(u2.PrefDep, 4.) AS PREF_RLZC_ATDT, 
			t1.UOR_VCLD, 
			INPUT(u3.PrefDep, 4.) AS PREF_VCLD, 
			t1.CTRA_VCLD, 
			t1.CHV_ATD_ATDT, 
			t1.CHV_ADM_ATDT, 
			t1.CD_SNH_ATDT, 
			t1.NR_SLCT_ATDT, 
			t1.NR_PTL_ATDT, 
			t1.NR_SEQL_FILA_ATDT, 
			t1.CD_TIP_ATDT,
			t1.CD_TIP_ESP_ATDT,
			t1.CD_TIP_OGM_SLCT, 
			t1.CD_EST_PTL_ATDT, 
			t1.DT_SLCT_ATDT FORMAT=YYMMDDD10., 
			t1.HR_INC_EPR, 
			t1.HR_CHGD_DEPE, 
			t1.HR_INC_ATDT, 
			t1.HR_FIM_ATDT, 
			t1.QT_HH_DFRT_BSB, 
			t1.CD_CLI, 
			t1.NR_ISCR_SRF, 
			t1.CD_TIP_PSS, 
			t1.PREF_CLI_CDST,
			t1.CD_TIP_CTRA
		FROM WORK.ATDT_GAT_&AAAAMM. t1
		LEFT JOIN IGR.DEPENDENCIAS_&AAAAMM. u1 ON (INPUT(u1.UOR, 9.)=t1.UOR_SLCT)
		LEFT JOIN IGR.DEPENDENCIAS_&AAAAMM. u2 ON (INPUT(u2.UOR, 9.)=t1.UOR_RLZC_ATDT)
		LEFT JOIN IGR.DEPENDENCIAS_&AAAAMM. u3 ON (INPUT(u3.UOR, 9.)=t1.UOR_VCLD)
;QUIT;

/*
DEPEDENCIA DE ATENDIMENTO PELA ORDEM:
SE TEM UOR_VCLD TEM ATENDIMETNO DE PLATAFORMA, MANTEM O ATENDIMENTO NESTA DEPENDENCIA;
SE NÃO TEM ATENDIMETNO DE PLATAFORMA E TEM UOR_RLZC_ATDT, TEM ATENDIMENTO REALIZADO, MANTEM O ATENDIMENTO NESTA DEPENDENCIA;
SE NÃO TEM ATENDIMETNO DE PLATAFORMA NEM ATENDIMENTO REALIZADO, MANTEM O ATENDIMENTO DE SOLICITAÇÃO;

CARTEIRAS PLATAFORMA MANTEM, OS DEMAIS FICAM NA 7002 DA DEPENDENCIA DO ATENDIMENTO DEFINIDO;
*/

PROC SQL;
	CREATE TABLE WORK.ATDT_GAT_&AAAAMM. AS 
		SELECT 
			COALESCE(t1.UOR_VCLD, t1.UOR_RLZC_ATDT, t1.UOR_SLCT) AS UOR_ATDT,
			COALESCE(t1.PREF_VCLD, t1.PREF_RLZC_ATDT, t1.PREF_SLCT) AS PREF_ATDT,
			COALESCE(t1.CTRA_VCLD, 7002) AS CTRA_ATDT,
			t1.UOR_SLCT LABEL='UOR solicitação atendimento',
			t1.PREF_SLCT LABEL='Prefixo solicitação atendimento', 
			t1.UOR_RLZC_ATDT LABEL='UOR realização atendimento',
			t1.PREF_RLZC_ATDT LABEL='Prefixo realização atendimento',  
			t1.UOR_VCLD LABEL='UOR plataforma vinculada', 
			t1.PREF_VCLD LABEL='Prefixo plataforma vinculada',  
			t1.CTRA_VCLD LABEL='Carteira plataforma vinculada', 
			t1.CHV_ATD_ATDT LABEL='Chave atendente',
			t1.CHV_ADM_ATDT LABEL='Chave gerente da fila', 
			t1.CD_SNH_ATDT LABEL='Nr da senha emitida para o cliente',
			t1.NR_SLCT_ATDT LABEL='Nr solicitação atendimento, único na dependência',
			t1.NR_PTL_ATDT LABEL='Nr solicitação na plataforma de atendimento', 
			t1.NR_SEQL_FILA_ATDT LABEL='Nr da fila de atendimento', 
			t1.CD_TIP_ATDT LABEL='Tipo atendimento solicitado: 1-Presencial, 2-Remoto',
			t1.CD_TIP_OGM_SLCT LABEL='Tipo origem da solicitação: 1-Terminal de senhas, 4-CABB, 5-URA', 
			t1.CD_TIP_ESP_ATDT LABEL='Tipo de espaço de atendimento: 1-Negocial, 2-Caixa',
			t1.CD_EST_PTL_ATDT LABEL='Estado do protocolo',  
			t1.DT_SLCT_ATDT LABEL='Data atendimento',  
			t1.HR_INC_EPR LABEL='Hora emissão da senha', 
			t1.HR_CHGD_DEPE LABEL='Hora chegada na dependência',  
			t1.HR_INC_ATDT LABEL='Hora início do atendimento', 
			t1.HR_FIM_ATDT LABEL='Hora fim do atendimento', 
			t1.QT_HH_DFRT_BSB LABEL='Diferença horas local para BSB',  
			t1.CD_CLI LABEL='Código cliente', 
			t1.NR_ISCR_SRF LABEL='Nr CPF ou CNPJ', 
			t1.CD_TIP_PSS LABEL='Tipo pessoa: 1-PF, 2-PJ',
			t1.PREF_CLI_CDST LABEL='Prefixo cadastro cliente',
			t1.CD_TIP_CTRA LABEL='Tipo carteira cliente'
		FROM WORK.ATDT_GAT_&AAAAMM. t1;
QUIT;


/*
DEFINE SE O PROCESSAMENTO SERÁ INTEGRAL DO MES, OU POR APPEND:
PROC_MM=1 >>> INTEGRAL
PROC_MM=0 >>> APPEND
*/
%PUT &PROC_MM.;

%MACRO APPEND_DATA();

	%IF &PROC_MM.=1 %THEN %DO;

		DATA GAT.ATDT_GAT_&AAAAMM.;
			SET WORK.ATDT_GAT_&AAAAMM.;
		RUN;


	%END;

	%ELSE %DO;

		/*REMOVER DADOS PARA ATUALIZAR*/
		DATA GAT.ATDT_GAT_&AAAAMM.;
			SET GAT.ATDT_GAT_&AAAAMM.;
			WHERE DT_SLCT_ATDT NOT BETWEEN &DT_INC. AND &DT_FIM.;
		RUN;

		/*APPENDA A TABELA*/
		DATA GAT.ATDT_GAT_&AAAAMM.;
			SET GAT.ATDT_GAT_&AAAAMM. WORK.ATDT_GAT_&AAAAMM.;
		RUN;

	%END;
%MEND APPEND_DATA; %APPEND_DATA();


%commandShell("chmod 777 /dados/infor/bases/gat/*");



/*#################################################################################################################*/
/*#################################################################################################################*/
/*CkeckOut do processamento*/
/*#################################################################################################################*/

%processCheckOut(uor_resp = 464341, tipo = Processo Comum, sistema = Conexão, rotina = GAT - BASES, mailto= &EmailsCheckOut.);


/*#################################################################################################################*/
/*#################################################################################################################*/