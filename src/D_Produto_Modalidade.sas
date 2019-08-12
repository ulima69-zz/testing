%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET Keypass=produto-modalidade-ff5436f2-ebbd-4f27-a4b7-586c5b31a55a;
%ProcessoIniciar();


LIBNAME DB2PRD 		db2 AUTHDOMAIN=DB2SGCEN schema=DB2PRD	database=BDB2P04;


PROC SQL;
	CREATE TABLE WORK.PRODUTO AS 
		SELECT 
			TODAY() FORMAT=DateMysql. AS POSICAO, 
			t1.CD_PRD, 
			t1.NM_PRD,
			t1.CD_EST_PRD
		FROM DB2PRD.PRD t1
;QUIT;


PROC SQL;
	CREATE TABLE WORK.MODALIDADE AS 
		SELECT 
			TODAY() FORMAT=DateMysql. AS POSICAO,
			t1.CD_PRD, 
			t1.CD_MDLD, 
			t1.NM_MDLD,
			t1.CD_EST_MDLD
		FROM DB2PRD.MDLD_PRD t1
;QUIT;

PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('PRODUTO', 'produto-modalidade');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('MODALIDADE', 'modalidade');
QUIT;

%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL);

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
