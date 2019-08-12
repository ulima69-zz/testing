
%include '/dados/infor/suporte/FuncoesInfor.sas';

libname PROP '/dados/externo/propensao_dimpe';


DATA _NULL_;
	   
    D1=DiaUtilAnterior(Today());
	CALL SYMPUT('D1',D1);
	CALL SYMPUT('AnoMes',Put(D1, yymmn6.));
	CALL SYMPUT('LMT',"'"||Put(D1, yymmdd10.)||"'");

    DT_IN=primeiroDiaUtilMes(DiaUtilAnterior(Today()));
	CALL SYMPUT('DT_IN',"'"||Put(DT_IN, yymmdd10.)||"'");

    DT_FIM=DiaUtilAnterior(Today());
	CALL SYMPUT('DT_FIM',"'"||Put(DT_FIM, yymmdd10.)||"'");

	MES_POSICAO = Put(MONTH (diaUtilAnterior(TODAY())), Z2.);
    CALL SYMPUT('MES_POSICAO', COMPRESS(MES_POSICAO,' '));

	DATA_BASE = '31Dec2100'd;
	CALL SYMPUT('DATA_BASE',COMPRESS(DATA_BASE,' '));

RUN;


%Put &D1 &AnoMes &LMT  &DT_IN &DT_FIM  &MES_POSICAO &DATA_BASE;


PROC SQL;
	CREATE TABLE WORK.ESTAGIO_1 AS
		SELECT 
		t1.pref_agencia as PREFDEP,
        t1.nr_carteira as CTRA,
		/*t2.CD_PRF_DEPE AS PREF,*/ 
        /*t2.NR_SEQL_CTRA AS CART,*/ 
        t1.mci,
        t1.fidelizar_atual,
        t1.diversificar_atual,
        t1.rentabilizar_atual,
        t1.habilitar_atual,
        t1.recuperar_atual,
        t1.mes_atual,
        t1.fidelizar_anterior,
        t1.diversificar_anterior,
        t1.rentabilizar_anterior,
        t1.habilitar_anterior,
        t1.recuperar_anterior,
        t1.mes_anterior,
        t1.evolucao,
        t1.involucao,
        t1.posse_prd_fidelizadores,
        t1.vlr_mce,
        t1.vlr_mch,
        t1.vlr_mco,
        t1.ind_evasao,
        t1.ind_inad,
        t1.nm_estagio_atual
		/*t2.CD_TIP_CTRA*/
    FROM PROP.base_estagio_relatorio_gecem t1
	LEFT JOIN COMUM.PAI_REL_&ANOMES. t2 ON t1.mci = t2.cd_cli
		ORDER BY 1,2;
QUIT;


PROC STDIZE DATA=WORK.ESTAGIO_1 OUT=WORK.ESTAGIO_1 REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
	CREATE TABLE WORK.ESTAGIO_2 AS
		SELECT *
    FROM WORK.ESTAGIO_1 
	    WHERE PrefDep <> 0 AND CTRA <> 0 AND mci <> 0
		ORDER BY 1,2;
QUIT;


PROC SQL;
	CREATE TABLE WORK.ESTAGIO_3 AS
		SELECT 
		PrefDep,
        CTRA,
        SUM(fidelizar_atual) AS fidelizar_atual,
        SUM(diversificar_atual) AS diversificar_atual,
        SUM(rentabilizar_atual) AS rentabilizar_atual,
        SUM(habilitar_atual) AS habilitar_atual,
        SUM(recuperar_atual) AS recuperar_atual,
        SUM(fidelizar_anterior) AS fidelizar_anterior,
        SUM(diversificar_anterior) AS diversificar_anterior,
        SUM(rentabilizar_anterior) AS rentabilizar_anterior,
        SUM(habilitar_anterior) AS habilitar_anterior,
        SUM(recuperar_anterior) AS recuperar_anterior,
        SUM(evolucao) AS evolucao,
        SUM(involucao) AS involucao,
        SUM(posse_prd_fidelizadores) AS posse_prd_fidelizadores,
        SUM(vlr_mce) AS vlr_mce,
        SUM(vlr_mch) AS vlr_mch,
        SUM(vlr_mco) AS vlr_mco,
        SUM(ind_evasao) AS ind_evasao,
        SUM(ind_inad) AS ind_inad,
        count(mci) as total_clientes
    FROM WORK.ESTAGIO_2
	    GROUP BY 1,2
		ORDER BY 1,2;
QUIT;


data WORK.ESTAGIO_4;
format posicao yymmdd10.;
set WORK.ESTAGIO_3;
posicao = &D1;
run;


/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/

PROC SQL;
DROP TABLE COLUNAS_SUMARIZAR;
CREATE TABLE COLUNAS_SUMARIZAR (Coluna CHAR(50), Tipo CHAR(10));
INSERT INTO COLUNAS_SUMARIZAR VALUES ('fidelizar_atual', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('diversificar_atual', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('rentabilizar_atual', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('habilitar_atual', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('recuperar_atual', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('fidelizar_anterior', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('diversificar_anterior', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('rentabilizar_anterior', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('habilitar_anterior', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('recuperar_anterior', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('evolucao', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('involucao', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('posse_prd_fidelizadores', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('vlr_mce', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('vlr_mch', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('vlr_mco', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('ind_evasao', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('ind_inad', 'SUM');
INSERT INTO COLUNAS_SUMARIZAR VALUES ('total_clientes', 'SUM');

QUIT;


/*FUNCAO DE SUMARIZACAO*/ 
%SumarizadorCNX( TblSASValores=WORK.ESTAGIO_4,  TblSASColunas=COLUNAS_SUMARIZAR,  NivelCTRA=1,  PAA_PARA_AGENCIA=0,  TblSaida=WORK.ESTAGIO_5, AAAAMM=&ANOMES.); 


PROC SQL;
	CREATE TABLE WORK.ESTAGIO_6 AS
		SELECT 
		posicao,
		PrefDep as prefixo,
        CTRA as carteira,
        fidelizar_atual/total_clientes*100 as fidelizar_atual,
        diversificar_atual/total_clientes*100 as diversificar_atual,
        rentabilizar_atual/total_clientes*100 as rentabilizar_atual,
        habilitar_atual/total_clientes*100 as habilitar_atual,
        recuperar_atual/total_clientes*100 as recuperar_atual,
        fidelizar_anterior/total_clientes*100 as fidelizar_anterior,
        diversificar_anterior/total_clientes*100 as diversificar_anterior,
        rentabilizar_anterior/total_clientes*100 as rentabilizar_anterior,
        habilitar_anterior/total_clientes*100 as habilitar_anterior,
        recuperar_anterior/total_clientes*100 as recuperar_anterior,
        evolucao/total_clientes*100 as evolucao,
        involucao/total_clientes*100 as involucao,
		total_clientes, 
        (evolucao - involucao)/total_clientes*100 as liquido
    FROM WORK.ESTAGIO_5
	    ORDER BY 1,2;
QUIT;


/*detalhe*/

PROC SQL;
	CREATE TABLE WORK.ESTAGIO_7 AS
		SELECT 
		pref_agencia as prefixo,
        nr_carteira as carteira,
        mci format = 9.,        
        nm_prd_fidelizadores,
        vlr_mce format = 32.2,
        vlr_mch format = 32.2,
        vlr_mco format = 32.2,
        ind_evasao format = 32.2,
        ind_inad format = 32.2,
        nm_estagio_atual,
		cod_grupo_relac format = 32.2,
		vlr_mco_201906 format = 32.2,
        dt_ultima_visita FORMAT ddmmyy10. as dt_ultima_visita,
        dt_ultimo_contato FORMAT ddmmyy10. as dt_ultimo_contato

    FROM PROP.base_estagio_relatorio_gecem 
		ORDER BY 1,2;
QUIT;


PROC STDIZE DATA=WORK.ESTAGIO_7 OUT=WORK.ESTAGIO_7 REPONLY MISSING=0;
	VAR _NUMERIC_;
QUIT;


PROC SQL;
	CREATE TABLE WORK.ESTAGIO_8 AS
		SELECT *
    FROM WORK.ESTAGIO_7 
	    WHERE prefixo <> 0 AND carteira <> 0 AND mci <> 0
		ORDER BY 1,2;
QUIT;


PROC SQL;
	CREATE TABLE WORK.ESTAGIO_9 AS
		SELECT 
		prefixo,
        carteira,
        mci,        
        nm_prd_fidelizadores,
		/*IFC(posse_prd_fidelizadores = 1, "S", "N") as posse_prd_fidelizadores,*/
        vlr_mce,
        vlr_mch,
        vlr_mco,
        IFC(ind_evasao = 1, "S", "N") as ind_evasao,
		IFC(ind_inad = 1, "S", "N") as ind_inad,
        nm_estagio_atual,
		cod_grupo_relac,
		vlr_mco_201906,
        dt_ultima_visita,
        dt_ultimo_contato
    FROM WORK.ESTAGIO_8 
		ORDER BY 1,2;
QUIT;


DATA '/dados/infor/producao/credito_pj_publicos/estagio_9';
SET ESTAGIO_9(KEEP=MCI VLR_MCO);
RUN;


/*Rel 508*/


%LET Usuario=f7176219;
%LET Keypass=estagio-relac-mpe-xCHr7sTNgI6QL655r0FZgtXya5JmDguVKB12A66AifHHfCYlFn;
%LET Rotina=estagio-relac-mpe;
%ProcessoIniciar();


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('ESTAGIO_6', 'estagio-relac-mpe');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('ESTAGIO_9', 'detalhes');
   ;
QUIT;


%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);


x cd /dados/externo/propensao_dimpe ;
x chmod 2777 *;


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
