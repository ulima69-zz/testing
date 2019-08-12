%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET NomeRelatorio=ATB_RSA;
%LET NomePasta=;

/* DEMANDANTE DIREO - HUMBERTO/GABRIEL */

LIBNAME PEGADA "/dados/infor/producao/Pegada_Ecologica";
LIBNAME RADAR "/dados/infor/producao/Radar";
LIBNAME DB2ITR      db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ITR 	database=BDB2P04;  
LIBNAME DB2ATB      db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ATB 	database=BDB2P04;  
LIBNAME DB2ARH      db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ARH 	database=BDB2P04;  
LIBNAME DB2GTD      db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2GTD 	database=BDB2P04;  
LIBNAME DB2MCI      db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2MCI 	database=BDB2P04;  




DATA _NULL_;
    
	DATA_INICIO = '01JAN2018'd;
	DATA_FIM = '31DEC2019'd;
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
 


/********************************************************/
														/*Cultura Rsa Empresarial*/
/*******************************************************/


/**/
/**/
/*DATA CORP;*/
/*SET IGR.DEPENDENCIAS_&anomes;*/
/*WHERE SB = '00' AND tipodep = '013' and tipoGeral='092' and status='A' AND NIVEL IN ('0','9');*/
/*RUN;*/
/**/
/**/
/**/
/*DATA GECEX;*/
/*SET IGR.DEPENDENCIAS_&anomes;*/
/*WHERE SB = '00' AND NOMEdep CONTAINS 'GECEX' AND STATUS='A';*/
/*RUN;*/
/**/
/**/
/**/
/*DATA PREFIXOS;*/
/*SET IGR.DEPENDENCIAS_&anomes;*/
/*WHERE SB = '00' AND tipodep IN('001','002','003','004','009','014','022','025','031','032','034','036','037','052','058','060','062','064', '063' '078','079','081','090') and tipoGeral IN ('090','091', '092','093') and status='A'*/
/*;RUN;*/
/**/
/**/
/**/
/*DATA OUTRAS;*/
/*SET IGR.DEPENDENCIAS_&anomes;*/
/*WHERE SB = SB = '00' AND PREFDEP = ('9517');*/
/*RUN;*/
/**/
/**/
/**/
/*DATA ATB_RSA_DEPE;*/
/*SET CORP GECEX PREFIXOS OUTRAS;*/
/*WHERE PREFDEP NOT IN ('9500','8166','8592','8477');*/
/*RUN;*/
/*PROC SORT DATA=ATB_RSA_DEPE NODUPKEY; BY _ALL_; RUN;*/
/**/


LIBNAME ADE '/dados/infor/producao/Aderencia';
LIBNAME RAD '/dados/infor/producao/Radar/';



x cd /;
x cd /dados/infor/producao/Aderencia/;
x cd /dados/infor/producao/Radar/;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/


PROC SQL;
	CREATE TABLE funci AS 
		SELECT 
			t1.MATRICULA_215, 
			t1.dep_lotacao_215 as CD_DEPE_LCLZ,
			t1.nome_215 as nm_fun,
			situacao_215,
			codigo_mci_215
		FROM ADE.ARH215_CADASTRO_BASICO_&anomes t1
			where dt_posicao=&d1. and  situacao_215 not in (150,3003,590,600,601,603,604,610,800,802,803,804,805,809,810,817,818,819,820,821,822,823,824,825,826,827,828,830,831,834,835,850,852,990);
QUIT;

PROC SQL;
   CREATE TABLE CURSOS_DIPES AS 
   SELECT 
          MAX(DT_FIM_CSO) FORMAT=DateMysql. AS POSICAO,
		  t2.CD_DEPE_LCLZ,
          t2.MATRICULA_215 AS MATRICULA,
          t2.nm_fun, 
          t1.CD_CSO AS CD_CURSO, 
          t1.DT_FIM_CSO AS DT_CONCLUSAO
      FROM DB2GTD.CSO_PSS_ITSE_SIS t1
INNER JOIN FUNCI T2 ON (T1.CD_PSS=T2.CODIGO_MCI_215)
WHERE CD_CSO IN (6828 6606 6605 1540) and t2.matricula_215 ne .
;
QUIT;



PROC SQL;
   CREATE TABLE RADAR.CURSOS AS 
   SELECT t1.POSICAO, 
          t2.CD_DEPE_LCLZ, 
          t2.MATRICULA_215 AS MATRICULA, 
          t2.nm_fun, 
		  T2.situacao_215,
          t1.CD_CURSO, 
          t1.DT_CONCLUSAO
      FROM CURSOS_DIPES t1
RIGHT JOIN FUNCI T2 ON (T1.MATRICULA=T2.MATRICULA_215 AND T1.CD_DEPE_LCLZ=T2.CD_DEPE_LCLZ AND T1.NM_FUN=T2.NM_FUN)
WHERE T2.CD_DEPE_LCLZ NE 0 ;
QUIT;



PROC SQL;
	CREATE TABLE CURSOS_1540 AS 
		SELECT DISTINCT
			POSICAO,
			CD_DEPE_LCLZ,
			Matricula,
			nm_fun, 
			ifn(Cd_curso=1540,1,0) as Curso_1540
		FROM RADAR.CURSOS
			WHERE Cd_curso = 1540
		      order by 2,3
	;
QUIT;

PROC SQL;
	CREATE TABLE CURSOS_6605 AS 
		SELECT DISTINCT
			POSICAO,
			CD_DEPE_LCLZ,
			Matricula, 
			nm_fun,
			ifn(Cd_curso=6605,1,0) as Curso_6605
		FROM RADAR.CURSOS
			WHERE Cd_curso = 6605
order by 2,3
	;
QUIT;
PROC SQL;
	CREATE TABLE CURSOS_6606 AS 
		SELECT DISTINCT
			POSICAO,
			CD_DEPE_LCLZ,
			Matricula,
			nm_fun, 
			ifn(Cd_curso=6606,1,0) as Curso_6606
		FROM RADAR.CURSOS
			WHERE Cd_curso = 6606 
				order by 2,3
	;
QUIT;

PROC SQL;
	CREATE TABLE CURSOS_6828 AS 
		SELECT DISTINCT 
			POSICAO,
			CD_DEPE_LCLZ,
			Matricula,
			nm_fun,
			ifn(Cd_curso=6828,1,0) as Curso_6828
		FROM RADAR.CURSOS
			WHERE Cd_curso = 6828
				order by 2,3
	;
QUIT;

DATA CURSOS_RSA;
	MERGE CURSOS_1540 CURSOS_6605 CURSOS_6606 CURSOS_6828;
	BY POSICAO CD_DEPE_LCLZ MATRICULA NM_FUN;
RUN;

PROC SORT DATA=CURSOS_RSA NODUPKEY;
	BY _ALL_;
RUN;
%ZerarMissingTabela(CURSOS_RSA)


PROC SQL;
	CREATE TABLE CURSOS_RSA_RLZD AS 
		SELECT DISTINCT 
            max(t2.posicao) format ddmmyy10. as posicao,
			t1.CD_DEPE_LCLZ as prefdep, 
			t1.MATRICULA, 
			t1.nm_fun,
			t2.Curso_1540,
			t2.Curso_6605, 
			t2.Curso_6606, 
			t2.Curso_6828,
		    4 as Meta,
		(Curso_1540+Curso_6605+Curso_6606+Curso_6828) as Qtd_realizado
		FROM RADAR.CURSOS t1
			LEFT JOIN CURSOS_RSA t2 ON (T1.MATRICULA=T2.MATRICULA AND T1.CD_DEPE_LCLZ=T2.CD_DEPE_LCLZ AND T1.NM_FUN=T2.NM_FUN)
;
QUIT;
%ZerarMissingTabela(CURSOS_RSA_RLZD)



PROC SQL;
CREATE TABLE RADAR.DETALHE_CURSOS AS 
	SELECT 
		posicao,
		t1.prefdep, 
		T1.Matricula,
		T1.NM_FUN AS NOME, 
		t1.Curso_1540, 
		t1.Curso_6605, 
		t1.Curso_6606, 
		t1.Curso_6828,
		T1.Meta,
		T1.Qtd_realizado,
		(qTD_REALIZADO/META)*100 FORMAT 20.2 AS PERC_REALIZADO
	FROM WORK.CURSOS_RSA_RLZD t1
;QUIT;


PROC SQL;
   CREATE TABLE WORK.DETALHE_UE AS 
   SELECT DISTINCT 
          input(t2.PrefDir,4.) as prefdep, 
          input(t2.PrefSuper,4.) as prefsuper, 
          input(t2.PrefSureg,4.) as prefsureg,
          t1.prefdep as agencia, 
          t1.MATRICULA, 
          t1.NOME, 
          t1.Curso_1540, 
          t1.Curso_6605, 
          t1.Curso_6606, 
          t1.Curso_6828, 
          t1.Qtd_realizado
      FROM RADAR.DETALHE_CURSOS t1
     inner join IGR.DEPENDENCIAS_&ANOMES T2 ON (T1.PREFDEP=INPUT(T2.PREFDEP,4.))
where sb='00' and status = 'A';
QUIT;


PROC SQL;
	CREATE TABLE CURSOS_RSA_DEPE AS 
		SELECT posicao, 
		    PREFDEP,
			SUM(T1.META) AS META_DEPE,
			SUM(t1.Qtd_realizado) AS QTD_RLZD_DEPE
		FROM RADAR.DETALHE_CURSOS t1
			GROUP BY 1,2;
QUIT;

PROC SQL;
	CREATE TABLE CURSOS_RSA_DEPE_RLZD AS 
		SELECT 
			posicao,
			t1.prefdep, 
			T1.META_DEPE AS QTD_META,
			T1.QTD_RLZD_DEPE,
			80 AS PERC_ORCADO,
			(QTD_RLZD_DEPE/META_DEPE)*100 FORMAT 20.2 AS PERC_RLZD_RSA
		FROM WORK.CURSOS_RSA_DEPE t1
			GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE CURSOS_DEPE AS 
		SELECT DISTINCT 
			posicao,
			t1.prefdep, 
			t1.QTD_META, 
			t1.QTD_RLZD_DEPE, 
			t1.PERC_ORCADO, 
			t1.PERC_RLZD_RSA,
			(PERC_ORCADO-PERC_RLZD_RSA) format 20.2 AS PC_FALTA_ATING
		FROM WORK.CURSOS_RSA_DEPE_RLZD t1
			/* left JOIN ATB_RSA_DEPE t2 ON T1.PREFDEP=INPUT(T2.PREFDEP,4.)*/
	GROUP BY 1;
QUIT;

PROC SQL;
	CREATE TABLE RSA_FINAL AS 
		SELECT
			posicao,
			t1.prefdep, 
			t1.QTD_META, 
			t1.QTD_RLZD_DEPE, 
			t1.PERC_ORCADO, 
			t1.PERC_RLZD_RSA, 
			t1.PC_FALTA_ATING
		FROM WORK.CURSOS_DEPE t1;
QUIT;
%ZerarMissingTabela(RSA_FINAL)

/*relatório 141*/



%LET Usuario=f9457977;
%LET Keypass=GDwBk0Q8oqtNu8EE625jiFKtUlRmND6fSvvpDpZ1CtdPLgyFuy;
PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('RSA_FINAL', 'atb-rsa');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('RADAR.DETALHE_CURSOS', 'funcionario');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('DETALHE_UE', 'detalhe-diretoria');

QUIT;
%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);	  





x cd /;
x cd /dados/infor/producao/Aderencia/;
x cd /dados/infor/producao/Radar/;
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
