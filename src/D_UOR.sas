%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET Keypass=dependencias-vinculos-historico-8eb5dd19-7069-4a20-b066-f749c88b6940;
%ProcessoIniciar();

LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2UOR 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2UOR 	database=BDB2P04;


PROC SQL;
	CREATE TABLE WORK.VCL_UOR AS 
		SELECT 
			TODAY() FORMAT=DateMysql. AS POSICAO,
			t1.CD_UOR_VCLD, 
			t1.CD_UOR_VCLR, 
			t1.CD_TIP_VCL
		FROM DB2UOR.VCL_UOR t1
;QUIT;


PROC SQL;
	CREATE TABLE WORK.CTGR_TIP_VCL AS 
		SELECT 
			TODAY() FORMAT=DateMysql. AS POSICAO,
			t1.CD_CTGR_TIP_VCL, 
			t1.NM_CTGR_TIP_VCL
		FROM DB2UOR.CTGR_TIP_VCL t1;
QUIT;


PROC SQL;
	CREATE TABLE WORK.TIP_VLC AS 
		SELECT 
			TODAY() FORMAT=DateMysql. AS POSICAO,
			t1.CD_TIP_VCL, 
			t1.CD_NTZ_TIP_VCL, 
			t1.CD_CTGR_TIP_VCL, 
			t1.CD_IOR, 
			t1.NM_TIP_VCL, 
			t1.TX_DCR_TIP_VCL
		FROM DB2UOR.TIP_VCL t1;
QUIT;


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('VCL_UOR', 'dependencias-vinculos-historico');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('CTGR_TIP_VCL', 'dependencias-vinculos-categorias-historico');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('TIP_VLC', 'dependencias-vinculos-tipos-historico');
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
