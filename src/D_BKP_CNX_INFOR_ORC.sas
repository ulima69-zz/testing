/*#################################################################################################################*/
/*##### A B E R T U R A #####*/
%include '/dados/infor/suporte/FuncoesInfor.sas';

/*CONTROLE DE DATAS*/
DATA _NULL_;
	AAAA = Put(TODAY(), YEAR.);
	AAAAMMDD = Put(TODAY(), yymmddn8.);
	AAAAMMDD_D14 = Put(intnx('day',TODAY(),-14), yymmddn8.);
	CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
	CALL SYMPUT('AAAAMMDD',COMPRESS(AAAAMMDD,' '));
	CALL SYMPUT('AAAAMMDD_D14',COMPRESS(AAAAMMDD_D14,' '));
RUN; 


LIBNAME CNX_ORC		"/dados/gecen/interno/cnx_orc";
LIBNAME CNX_READ	"/dados/gecen/interno/cnx_orc/read";
LIBNAME CNX_BKP		"/dados/gecen/interno/cnx_orc/bkp";	
LIBNAME CNX_GRL     "/dados/infor/conexao/&AAAA./acordos";
LIBNAME CNX_BKP8    "/dados/infor/conexao/&AAAA./bkp/acordos";


%PUT &AAAAMMDD;
%PUT &AAAAMMDD_D14;



/*BACKUPS DOS ARQUIVOS DE SCRIPTS*/
%MACRO BKP_SCRIPTS();

	/*CONTROLE DE DATAS*/
	DATA _NULL_;
		HH=Put(HOUR(TIME()), 2.);
		CALL SYMPUT('HH',COMPRESS(HH,' '));
	RUN; 

	%put hora: &HH.;

/*	EXECUTAR SOMENTE AS 23 HORAS*/
	%IF &HH=23 %THEN %DO;
		%commandShell("cp -f /dados/infor/_scripts/sas/*.sas /dados/infor/_scripts/sas/BACKUP/");
		%commandShell("chmod 777 /dados/infor/_scripts/sas/BACKUP/*");
	%END;

%MEND BKP_SCRIPTS;
%BKP_SCRIPTS();



/*PERMISSÕES DE ARQUIVOS*/

%commandShell("chmod 777 /dados/infor/conexao/&AAAA./bkp/acordos/*");



/*BACKUPS INDIVIDUAIS DAS TABELAS DE ORÇADOS DE CADA INDICADOR*/
%MACRO BKP_ORC();

	/*CONTROLE DE DATAS*/
	DATA _NULL_;
		AAAA = Put(TODAY(), YEAR.);
		AAAAMMDD = Put(TODAY(), yymmddn8.);
		AAAAMMDD_D7 = Put(intnx('day',TODAY(),-7), yymmddn8.);
		CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
		CALL SYMPUT('AAAAMMDD',COMPRESS(AAAAMMDD,' '));
		CALL SYMPUT('AAAAMMDD_D7',COMPRESS(AAAAMMDD_D7,' '));
	RUN; 

	/*Listar todas as pastas de indicadores, remove a pasta de backup 'bkp'*/
	filename saida pipe "cd /dados/gecen/interno/cnx_orc/&AAAA.; ls -d */";
	data lista_dir (where=(filename not IN ('bkp', 'BKP_G', 'acordos', 'blocos')));
	  infile saida missover pad;
	  input filename $255.;
	  filename=TRANWRD(filename,'/',''); 
	run;

	/*criar variavel com lista de indicadores*/
	PROC SQL NOPRINT; SELECT DISTINCT filename INTO :INDICADORES SEPARATED ' ' FROM lista_dir; QUIT;

	%put &INDICADORES;
	/*----------------------*/

	%LET nLoops=%sysfunc(countw(&INDICADORES));

	%DO i=1 %TO &nLoops;
		%LET IND=%SCAN(&INDICADORES, &i);

	/*	VALIDAR SE DIRETORIO DO INDICADOR EXISTE*/
		%commandShell("if [ -d /dados/gecen/interno/cnx_orc/&AAAA./bkp ]; then echo 1; else echo 0; fi");
		%PUT Existe pasta: &CommandShellOut.;

	/*	SE DIRETORIO NÃO EXISTIR, CRIAR*/
		%IF &CommandShellOut.=0 %THEN %DO;
			%commandShell("mkdir /dados/gecen/interno/cnx_orc/&AAAA./bkp");
			%commandShell("chmod 777 /dados/gecen/interno/cnx_orc/&AAAA./bkp");
			%AGUARDAR(1); 
		%END;

	/*	VALIDAR SE DIRETORIO DO INDICADOR EXISTE*/
		%commandShell("if [ -d /dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND. ]; then echo 1; else echo 0; fi");
		%PUT Existe pasta: &CommandShellOut.;

	/*	SE DIRETORIO NÃO EXISTIR, CRIAR*/
		%IF &CommandShellOut.=0 %THEN %DO;
			%commandShell("mkdir /dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND.");
			%commandShell("chmod 777 /dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND.");
			%AGUARDAR(1); 
		%END;

		LIBNAME CNX_T	"/dados/gecen/interno/cnx_orc/&AAAA./&IND.";
		LIBNAME CNX_B	"/dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND.";
		%LET PATH=/dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND./;

		/*DIARIO*/
		DATA CNX_B.IND_ORC_HST_&IND.;
			SET CNX_T.IND_ORC_HST_&IND.;
		RUN;

		DATA CNX_B.IND_ORC_HST_&IND._&AAAAMMDD.;
			SET CNX_T.IND_ORC_HST_&IND.;
		RUN;

		%commandShell("chmod 777 /dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND./ind_orc_hst_&IND..sas7bdat");
		%commandShell("chmod 777 /dados/gecen/interno/cnx_orc/&AAAA./bkp/&IND./ind_orc_hst_&IND._&AAAAMMDD..sas7bdat");

		/*APAGAR DIARIOS COM MAIS DE 7 DIAS*/
		PROC DELETE DATA=CNX_B.IND_ORC_HST_&IND._&AAAAMMDD_D7.;RUN;

		PROC DELETE DATA=CNX_B.IND_ORC_&IND._&AAAAMMDD_D7.;RUN;

		PROC DELETE DATA=CNX_B.IND_ORC_&IND.;RUN;

		LIBNAME CNX_T CLEAR;
		LIBNAME CNX_B CLEAR;
	%END;
	PROC DELETE DATA=lista_dir; RUN;
%MEND BKP_ORC;
%BKP_ORC();



/*BACKUPS INDIVIDUAIS DAS TABELAS DE REALIZADO DE CADA INDICADOR*/
%MACRO BKP_RLZ();

	/*CONTROLE DE DATAS*/
	DATA _NULL_;
		AAAA = Put(TODAY(), YEAR.);
		AAAAMMDD = Put(TODAY(), yymmddn8.);
		DD_SEM=weekday(TODAY());
		HH=Put(HOUR(TIME()), 2.);

		CALL SYMPUT('AAAA',COMPRESS(AAAA,' '));
		CALL SYMPUT('AAAAMMDD',COMPRESS(AAAAMMDD,' '));
		CALL SYMPUT('DD_SEM',COMPRESS(DD_SEM,' '));
		CALL SYMPUT('HH',COMPRESS(HH,' '));
	RUN; 

	%put hora: &HH.;

/*	EXECUTAR SOMENTE AS 23 HORAS*/
	%IF &HH=23 %THEN %DO;

		/*Listar todas as pastas de indicadores, remove a pasta de backup 'bkp'*/
		filename saida pipe "cd /dados/infor/conexao/&AAAA.; ls -d */";
		data lista_dir (where=(filename not IN ('bkp', 'BKP_G', 'acordos', 'blocos')));
		  infile saida missover pad;
		  input filename $255.;
		  filename=TRANWRD(filename,'/',''); 
		run;

		/*criar variavel com lista de indicadores*/
		PROC SQL NOPRINT; SELECT DISTINCT filename INTO :INDICADORES SEPARATED ' ' FROM lista_dir; QUIT;

		%put &INDICADORES;

		/*----------------------*/

		%LET nLoops=%sysfunc(countw(&INDICADORES));

		%DO i=1 %TO &nLoops;
			%LET IND=%SCAN(&INDICADORES, &i);

		/*	VALIDAR SE DIRETORIO DO INDICADOR EXISTE*/
			%commandShell("if [ -d /dados/infor/conexao/&AAAA./bkp ]; then echo 1; else echo 0; fi");
			%PUT Existe pasta: &CommandShellOut.;

		/*	SE DIRETORIO NÃO EXISTIR, CRIAR*/
			%IF &CommandShellOut.=0 %THEN %DO;
				%commandShell("mkdir /dados/infor/conexao/&AAAA./bkp");
				%commandShell("chmod 777 /dados/infor/conexao/&AAAA./bkp");
				%AGUARDAR(1); 
			%END;

			/*VALIDAR SE DIRETORIO DO INDICADOR EXISTE*/
			%commandShell("if [ -d /dados/infor/conexao/&AAAA./bkp/&IND. ]; then echo 1; else echo 0; fi");
			%PUT Existe pasta: &CommandShellOut.;

			/*SE DIRETORIO NÃO EXISTIR, CRIAR*/
			%IF &CommandShellOut.=0 %THEN %DO;
				%commandShell("mkdir /dados/infor/conexao/&AAAA./bkp/&IND.");
				%commandShell("chmod 777 /dados/infor/conexao/&AAAA./bkp/&IND.");
				%AGUARDAR(1); 
			%END;

			LIBNAME CNX_T	"/dados/infor/conexao/&AAAA./&IND.";
			LIBNAME CNX_B	"/dados/infor/conexao/&AAAA./bkp/&IND.";
			%LET PATH=/dados/infor/conexao/&AAAA./bkp/&IND./;

			/*DIARIO*/
			DATA CNX_B.indicador_&IND.;
				SET CNX_T.indicador_&IND.;
			RUN;
			%commandShell("chmod 777 /dados/infor/conexao/&AAAA./bkp/&IND./indicador_&IND..sas7bdat");

			/*SEMANAL - SOMENTE AOS DOMINGOS*/
			%IF &DD_SEM.=1 %THEN %DO;
				DATA CNX_B.indicador_&IND._&AAAAMMDD.;
					SET CNX_T.indicador_&IND.;
				RUN;
				%commandShell("chmod 777 /dados/infor/conexao/&AAAA./bkp/&IND./indicador_&IND._&AAAAMMDD..sas7bdat");
			%END;

			LIBNAME CNX_T CLEAR;
			LIBNAME CNX_B CLEAR;
		%END;
		PROC DELETE DATA=lista_dir; RUN;
	%END;
%MEND BKP_RLZ;
%BKP_RLZ();


%MACRO REMOVER_ARQ(CAMINHO, DIAS);
  	%PUT CAMINHO VARRER REMOCAO: &CAMINHO.;
	%PUT DIAS PARA REMOCAO: &DIAS.;

	DATA REMOVER_ARQ (drop = _:);
		format DATE EURDFDE9.;
	    _rc = filename("dRef", "&CAMINHO.");
	    _id = dopen("dRef");
	    _n = dnum(_id);
	    do _i = 1 to _n;
	        ARQUIVO = dread(_id, _i);
			NOME = tranwrd(tranwrd(tranwrd(tranwrd(ARQUIVO, 'ATB.', ''), '.TXT', ''), '.tar', ''), '.gz', '');
	            _rc = filename("fRef", "&CAMINHO./" || strip(ARQUIVO));
	            _fid = fopen("fRef");
/*	            size = finfo(_fid, "File Size (bytes)");*/
/*	            dateCreate = finfo(_fid, "Create Time");*/
				DATE=input(substr(finfo(_fid, "Last Modified"),1,9), EURDFDE9.);
	            _rc = fclose(_fid);
	            output;
	    end;
	    _rc = dclose(_id);
	RUN;

	PROC SQL;
		CREATE TABLE WORK.REMOVER_ARQ AS 
		SELECT DISTINCT
			t1.DATE, 
/*			t1.ARQUIVO, */
			t1.NOME
		FROM WORK.REMOVER_ARQ t1
		WHERE t1.DATE <= TODAY()-&DIAS.
	;QUIT;

	%LET ARQS_RM=;
	PROC SQL NOPRINT; SELECT DISTINCT NOME INTO :ARQS_RM SEPARATED ' ' FROM REMOVER_ARQ; QUIT; 
	%PUT ARQUIVOS REMOVER: &ARQS_RM;

	%LET nLoops=%sysfunc(countw(%quote(&ARQS_RM),' '));
	%PUT LOOPS: &nLoops.;

	%IF &nLoops.>0 %THEN %DO;
		%DO i=1 %TO &nLoops;
			%PUT LOOP: &i.; 
			%LET ARQ_RM=ATB.%SCAN(&ARQS_RM, &i).*;
			%PUT REMOVER: rm &CAMINHO.&ARQ_RM.;
			%commandShell("rm &CAMINHO.&ARQ_RM.");
		%END;
	%END;
%MEND REMOVER_ARQ;


%MACRO BKP_TRANSMITIDO();

/*	lista arquivos da pasta transmitido*/
	filename saida pipe 'cd /dados/infor/DITEC_Conexao/transmitido/; ls -a';
	DATA list_files (where=(ARQUIVO not IN ('.', '..', ' ', '.TXT')));
	  infile saida missover pad;
	  input ARQUIVO $255.;
	  FORMAT IND 3.;
	  ARQUIVO=COMPRESS(TRANWRD(ARQUIVO,'/',''),' '); ; 
	  IND=COMPRESS(input(substrn(ARQUIVO,max(1,length(ARQUIVO)-6),3), 3.),' ');
	  TP=substr(ARQUIVO,9,3);
	RUN;

	DATA list_files;
		SET list_files;
		FORMAT IND Z9.;
		IND=PUT(IND, Z9.);
		WHERE TP IN ('IND' 'CMP' 'CLI' 'REC');
	RUN;

	DATA list_files;
		SET list_files;
		PASTA_DESTINO=COMPRESS('/dados/infor/DITEC_Conexao/bkp_transmitido/'||PUT(IND,Z9.)||'/'||TP||'/',' ');
		ORIGEM=COMPRESS('/dados/infor/DITEC_Conexao/transmitido/'||ARQUIVO,' ');
		DESTINO=COMPRESS('/dados/infor/DITEC_Conexao/bkp_transmitido/'||PUT(IND,Z9.)||'/'||TP||'/'||ARQUIVO,' ');
		SEQ=_N_;
	RUN;

	PROC SQL NOPRINT; SELECT COUNT(*) INTO :QNT_ARQUIVOS FROM list_files; QUIT;

	%IF &QNT_ARQUIVOS.>0 %THEN %DO;

/*	    criar variavel com lista de indicadores*/
		PROC SQL NOPRINT; SELECT DISTINCT IND INTO :INDICADORES SEPARATED ' ' FROM list_files; QUIT;

		%put &INDICADORES;

	/*	ARRAY COM INDICE E NUMERO DOS DIRETORIOS*/
		%LET nLoops=%sysfunc(countw(&INDICADORES));

		%DO i=1 %TO &nLoops;
			%LET IND=%SCAN(&INDICADORES, &i);

			/*VALIDAR SE DIRETORIO EXISTE*/
	        %commandShell("if [ -d /dados/infor/DITEC_Conexao/bkp_transmitido/&IND. ]; then echo 1; else echo 0; fi");
	        %PUT Existe pasta &IND.: &CommandShellOut.;

	    	/*SE DIRETORIO NÃO EXISTIR, CRIAR*/
	        %IF &CommandShellOut.=0 %THEN %DO;
	            %commandShell("mkdir /dados/infor/DITEC_Conexao/bkp_transmitido/&IND.");
	            %commandShell("chmod 777 /dados/infor/DITEC_Conexao/bkp_transmitido/&IND.");
	        %END;

			PROC SQL NOPRINT; SELECT DISTINCT TP INTO :TIPOS SEPARATED ' ' FROM list_files WHERE IND=&IND.; QUIT;

			%put TIPOS DE PASTAS A CRIAR: &TIPOS;

			/*ARRAY COM INDICE E NOMES DOS DIRETORIOS*/
			%LET nLoopsTp=%sysfunc(countw(&TIPOS));

			%DO ii=1 %TO &nLoopsTp;
				%LET TP=%SCAN(&TIPOS, &ii);

				/*VALIDAR SE DIRETORIO EXISTE*/
		        %commandShell("if [ -d /dados/infor/DITEC_Conexao/bkp_transmitido/&IND./&TP. ]; then echo 1; else echo 0; fi");
		        %PUT Existe pasta &IND./&TP.: &CommandShellOut.;

				/*SE DIRETORIO NÃO EXISTIR, CRIAR*/
		        %IF &CommandShellOut.=0 %THEN %DO;
					%put PASTA A CRIAR: /dados/infor/DITEC_Conexao/bkp_transmitido/&IND./&TP.;
					%commandShell("mkdir /dados/infor/DITEC_Conexao/bkp_transmitido/&IND./&TP.");
		            %commandShell("chmod 777 /dados/infor/DITEC_Conexao/bkp_transmitido/&IND./&TP.");
		        %END;
			%END;
		%END;


		PROC SQL NOPRINT; SELECT DISTINCT SEQ INTO :SEQUENCIA SEPARATED ' ' FROM list_files; QUIT;
		%LET nLoopsTpInd=%sysfunc(countw(&SEQUENCIA));

		%DO iii=1 %TO &nLoopsTpInd;
			%LET SEQ=%SCAN(&SEQUENCIA, &iii);
			PROC SQL NOPRINT; SELECT DISTINCT PASTA_DESTINO, DESTINO, ORIGEM INTO :PASTA_DESTINO, :DESTINO, :ORIGEM FROM list_files WHERE SEQ=&SEQ.; QUIT;
			%PUT SEQUENCIA: &SEQ.;
			%PUT ORIGEM: &ORIGEM;
			%PUT DESTINO: &DESTINO;
			%PUT PASTA DESTINO: &PASTA_DESTINO;

/*			%REMOVER_ARQ(&PASTA_DESTINO., 31);*/
			%commandShell("mv &ORIGEM. &DESTINO.");			
			%commandShell("chmod 777 &DESTINO.");
			%commandShell("gzip &DESTINO.");
		%END;
    %END;

	PROC DELETE DATA=list_files; RUN;
%MEND BKP_TRANSMITIDO;

%BKP_TRANSMITIDO();





/*#################################################################################################################*/
/*#################################################################################################################*/
/*CkeckOut do processamento*/
/*#################################################################################################################*/

%processCheckOut(
    uor_resp = 341556
    ,funci_resp = 'F9631159'
    ,tipo = Indicador
    ,sistema = Indicador
    ,rotina = BACKUPS
    ,mailto= &EmailsCheckOut.
);
/*#################################################################################################################*/
/*#################################################################################################################*/
