
%include '/dados/infor/suporte/FuncoesInfor.sas';

/*CONTROLE DE DATAS*/

DATA _NULL_;
    
	DATA_INICIO = '01Jul2017'd;
	DATA_FIM = '31Dec2020'd;
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
	DT_FIXA_SQL="'"||put(MDY(08,29,2017), YYMMDDD10.)||"'";

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
RUN;

LIBNAME ARH DB2 DATABASE=BDB2P04 SCHEMA=DB2ARH AUTHDOMAIN=DB2SGCEN;
LIBNAME DB2SGCEN DB2 DATABASE=BDB2P04 SCHEMA=DB2SGCEN AUTHDOMAIN=DB2SGCEN;


x cd /;
x cd /dados/infor/producao/Aderencia;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/


LIBNAME ADE '/dados/infor/producao/Aderencia';
LIBNAME ADES '/dados/infor/conexao/apuracao/000000265/bases/';



DATA WORK.ARH_215;
    DT_POSICAO = &d1.;
    FORMAT DT_POSICAO DDMMYYS10.;
    SET DB2SGCEN.ARH215_CADASTRO_BASICO;
    /* RENAME 'CD-UOR-PSC-FUN'n = CD_UOR_PSC_FUN; */
RUN;



%MACRO ExcluirRegistros(nome_tabela, dt_posicao);
    %IF %SYSFUNC(exist(&nome_tabela., data)) %THEN %DO;
        PROC SQL;
            DELETE FROM
                &nome_tabela.
            WHERE
                DT_POSICAO = &dt_posicao.;
        RUN;
    %END;
%MEND ExcluirRegistros;

%ExcluirRegistros(ADE.ARH215_CADASTRO_BASICO_&anomes, &D1.);

PROC APPEND BASE=ADE.ARH215_CADASTRO_BASICO_&anomes DATA=WORK.ARH_215;
RUN;

DATA ADES.ARH215_CADASTRO_BASICO_&anomes;
SET ADE.ARH215_CADASTRO_BASICO_&anomes;
RUN;


x cd /;
x cd /dados/infor/producao/Aderencia;
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
