/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: segunda-feira, 24 de dezembro de 2018     TIME: 10:50:53
PROJECT: Projeto-Indicadores-Atendimento V9
PROJECT PATH: G:\Interna\1.Gestão da Rede\1.BI - Relatórios\8.P0_Indicadores_Atendimento\Projeto-Indicadores-Atendimento V9.egp
---------------------------------------- */

/* Library assignment for SASApp_ANL06.DWH */
Libname DWH DB2 'BDB2P04' ;
/* Library assignment for SASApp_ANL06.ARH */
Libname ARH DB2 'BDB2P04' ;
/* Library assignment for SASApp_ANL06.GAT */
Libname GAT DB2 'BDB2P04' ;

/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* Build where clauses from stored process parameters */
%macro _eg_WhereParam( COLUMN, PARM, OPERATOR, TYPE=S, MATCHALL=_ALL_VALUES_, MATCHALL_CLAUSE=1, MAX= , IS_EXPLICIT=0, MATCH_CASE=1);

  %local q1 q2 sq1 sq2;
  %local isEmpty;
  %local isEqual isNotEqual;
  %local isIn isNotIn;
  %local isString;
  %local isBetween;

  %let isEqual = ("%QUPCASE(&OPERATOR)" = "EQ" OR "&OPERATOR" = "=");
  %let isNotEqual = ("%QUPCASE(&OPERATOR)" = "NE" OR "&OPERATOR" = "<>");
  %let isIn = ("%QUPCASE(&OPERATOR)" = "IN");
  %let isNotIn = ("%QUPCASE(&OPERATOR)" = "NOT IN");
  %let isString = (%QUPCASE(&TYPE) eq S or %QUPCASE(&TYPE) eq STRING );
  %if &isString %then
  %do;
	%if "&MATCH_CASE" eq "0" %then %do;
		%let COLUMN = %str(UPPER%(&COLUMN%));
	%end;
	%let q1=%str(%");
	%let q2=%str(%");
	%let sq1=%str(%'); 
	%let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq D or %QUPCASE(&TYPE) eq DATE %then 
  %do;
    %let q1=%str(%");
    %let q2=%str(%"d);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq T or %QUPCASE(&TYPE) eq TIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"t);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq DT or %QUPCASE(&TYPE) eq DATETIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"dt);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else
  %do;
    %let q1=;
    %let q2=;
	%let sq1=;
    %let sq2=;
  %end;
  
  %if "&PARM" = "" %then %let PARM=&COLUMN;

  %let isBetween = ("%QUPCASE(&OPERATOR)"="BETWEEN" or "%QUPCASE(&OPERATOR)"="NOT BETWEEN");

  %if "&MAX" = "" %then %do;
    %let MAX = &parm._MAX;
    %if &isBetween %then %let PARM = &parm._MIN;
  %end;

  %if not %symexist(&PARM) or (&isBetween and not %symexist(&MAX)) %then %do;
    %if &IS_EXPLICIT=0 %then %do;
		not &MATCHALL_CLAUSE
	%end;
	%else %do;
	    not 1=1
	%end;
  %end;
  %else %if "%qupcase(&&&PARM)" = "%qupcase(&MATCHALL)" %then %do;
    %if &IS_EXPLICIT=0 %then %do;
	    &MATCHALL_CLAUSE
	%end;
	%else %do;
	    1=1
	%end;	
  %end;
  %else %if (not %symexist(&PARM._count)) or &isBetween %then %do;
    %let isEmpty = ("&&&PARM" = "");
    %if (&isEqual AND &isEmpty AND &isString) %then
       &COLUMN is null;
    %else %if (&isNotEqual AND &isEmpty AND &isString) %then
       &COLUMN is not null;
    %else %do;
	   %if &IS_EXPLICIT=0 %then %do;
           &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2)
			%end;
			%else %do;
				%unquote(&q1)&&&PARM%unquote(&q2)
			%end;
	   %end;
	   %else %do;
	       &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2))
			%end;
	   %end;
       %if &isBetween %then 
          AND %unquote(&q1)&&&MAX%unquote(&q2);
    %end;
  %end;
  %else 
  %do;
	%local emptyList;
  	%let emptyList = %symexist(&PARM._count);
  	%if &emptyList %then %let emptyList = &&&PARM._count = 0;
	%if (&emptyList) %then
	%do;
		%if (&isNotin) %then
		   1;
		%else
			0;
	%end;
	%else %if (&&&PARM._count = 1) %then 
    %do;
      %let isEmpty = ("&&&PARM" = "");
      %if (&isIn AND &isEmpty AND &isString) %then
        &COLUMN is null;
      %else %if (&isNotin AND &isEmpty AND &isString) %then
        &COLUMN is not null;
      %else %do;
	    %if &IS_EXPLICIT=0 %then %do;
			%if "&MATCH_CASE" eq "0" %then %do;
				&COLUMN &OPERATOR (%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2))
			%end;
			%else %do;
				&COLUMN &OPERATOR (%unquote(&q1)&&&PARM%unquote(&q2))
			%end;
	    %end;
		%else %do;
		    &COLUMN &OPERATOR (
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2)))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2)))
			%end;
		%end;
	  %end;
    %end;
    %else 
    %do;
       %local addIsNull addIsNotNull addComma;
       %let addIsNull = %eval(0);
       %let addIsNotNull = %eval(0);
       %let addComma = %eval(0);
       (&COLUMN &OPERATOR ( 
       %do i=1 %to &&&PARM._count; 
          %let isEmpty = ("&&&PARM&i" = "");
          %if (&isString AND &isEmpty AND (&isIn OR &isNotIn)) %then
          %do;
             %if (&isIn) %then %let addIsNull = 1;
             %else %let addIsNotNull = 1;
          %end;
          %else
          %do;		     
            %if &addComma %then %do;,%end;
			%if &IS_EXPLICIT=0 %then %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(&q1)%QUPCASE(&&&PARM&i)%unquote(&q2)
				%end;
				%else %do;
					%unquote(&q1)&&&PARM&i%unquote(&q2)
				%end;
			%end;
			%else %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM&i)%unquote(%nrstr(&sq2))
				%end;
				%else %do;
					%unquote(%nrstr(&sq1))&&&PARM&i%unquote(%nrstr(&sq2))
				%end; 
			%end;
            %let addComma = %eval(1);
          %end;
       %end;) 
       %if &addIsNull %then OR &COLUMN is null;
       %else %if &addIsNotNull %then AND &COLUMN is not null;
       %do;)
       %end;
    %end;
  %end;
%mend _eg_WhereParam;


/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HtmlBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome7.1/SASEnterpriseGuide/7.1/Styles/HtmlBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: Program   */

GOPTIONS ACCESSIBLE;
LIBNAME ATB DB2 DATABASE=BDB2P04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SUNV1;
LIBNAME REL DB2 DATABASE=BDB2P04 SCHEMA=DB2REL AUTHDOMAIN=DB2SUNV1;
LIBNAME BIC DB2 DATABASE=BDB2P04 SCHEMA=DB2BIC AUTHDOMAIN=DB2SUNV1;
LIBNAME GAT DB2 DATABASE=BDB2P04 SCHEMA=DB2GAT AUTHDOMAIN=DB2SUNV1;
LIBNAME MST DB2 DATABASE=BDB2P04 SCHEMA=DB2MST AUTHDOMAIN=DB2SUNV1;
LIBNAME MCI DB2 DATABASE=BDB2P04 SCHEMA=DB2MCI AUTHDOMAIN=DB2SUNV1;
LIBNAME DEB DB2 DATABASE=BDB2P04 SCHEMA=DB2DEB AUTHDOMAIN=DB2SUNV1;
LIBNAME CPB DB2 DATABASE=BDB2P04 SCHEMA=DB2CPB AUTHDOMAIN=DB2SUNV1;
LIBNAME ARH DB2 DATABASE=BDB2P04 SCHEMA=DB2ARH AUTHDOMAIN=DB2SUNV1;
LIBNAME RST DB2 DATABASE=BDB2P04 SCHEMA=DB2RST AUTHDOMAIN=DB2SUNV1;
LIBNAME OPR DB2 DATABASE=BDB2P04 SCHEMA=DB2OPR AUTHDOMAIN=DB2SUNV1;
LIBNAME DWH DB2 DATABASE=BDB2P04 SCHEMA=DB2DWH AUTHDOMAIN=DB2SVARC;
LIBNAME CAF DB2 DATABASE=BDB2P04 SCHEMA=DB2CAF AUTHDOMAIN=DB2SUNV1;
LIBNAME painel "/dados/externo" ; 
LIBNAME gecen "/dados/externo/GECEN";




GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: REGRA CFG GAT   */
LIBNAME TMP00004 "/dados/unc/infor/mestre";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.REGRA_FILA_GAT);

PROC SQL;
   CREATE TABLE WORK.REGRA_FILA_GAT AS 
   SELECT DISTINCT t2.CD_PREF_UOR AS prefixo, 
          t1.TX_FMT_CFG_AG AS regra, 
          t1.QT_MNTO_MAX_EPR AS tempo_max_neg, 
          t1.IN_CFG_TRML AS tipo_dia, 
          t1.DT_REF AS data_atend
      FROM DWH.PRM_CFG_AG t1
           INNER JOIN TMP00004.mestre_uor t2 ON (t1.CD_DEPE = t2.CD_UOR)
      WHERE t2.CD_SB_UOR = 0 AND t2.CD_EST_UOR = 2 AND t2.CD_PREF_DIRETORIA IN 
           (
           9500,
           8477,
           8592
           ) AND t1.CD_TIP_CFG = 112;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: FUNCI_EXIST   */
LIBNAME TMP00005 "/dados/externo/UNV/canais";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QTD_FUNCI);

PROC SQL;
   CREATE TABLE WORK.QTD_FUNCI AS 
   SELECT DISTINCT t1.LOCALIZACAO_215 AS PREFIXO, 
          /* QTD_FUNCI */
            (COUNT(DISTINCT(t1.MATRICULA_215))) AS QTD_FUNCI
      FROM ARH.ARH215_CADASTRO_BASICO t1
           INNER JOIN TMP00005.funcoes_ro_nome t2 ON (t1.FUNCAO_LOCALIZACAO_215 = t2.FUNCAO_LOTACAO)
      WHERE t1.SITUACAO_215 IN 
           (
           100,
           506,
           510,
           415
           ) AND t1.CD_UOR_LCZC = t1.'CD-UOR-PSC-FUN'n AND t2.FUNCAO_NOME NOT = 'GER GERAL UN'
      GROUP BY t1.LOCALIZACAO_215;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TEMPO_ESPERA   */
%LET _CLIENTTASKLABEL='TEMPO_ESPERA';
%LET _CLIENTPROCESSFLOWNAME='Relatório 170';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\8.P0_Indicadores_Atendimento\Projeto-Indicadores-Atendimento V9.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='Projeto-Indicadores-Atendimento V9.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TEMPO_ESPERA);

PROC SQL;
   CREATE TABLE WORK.TEMPO_ESPERA AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          t1.DT_ATDT, 
          t1.TX_UTZD_SNH_ATDT, 
          t4.tempo_max_neg LABEL='', 
          /* TEMPO_ESPERA */
            (MAX((t1.HR_INC_ATDT-t1.HR_CHGD_AG))) LABEL="TEMPO_ESPERA" AS TEMPO_ESPERA
      FROM GAT.ATDT t1
           LEFT JOIN WORK.REGRA_FILA_GAT t4 ON (t1.CD_PRF_DEPE = t4.prefixo) AND (t1.DT_ATDT = t4.data_atend)
           LEFT JOIN WORK.QTD_FUNCI t2 ON (t1.CD_PRF_DEPE = t2.PREFIXO)
      WHERE t1.CD_TIP_LCL_ATDT = 1 AND t1.DT_ATDT >= MDY(CASE WHEN WEEKDAY (TODAY()-1) = 1 THEN MONTH(TODAY()-3) ELSE 
           MONTH(TODAY()-1) END,01,2018) AND t1.CD_EST_ATDT NOT IN 
           (
           10,
           20
           )
      GROUP BY t1.CD_PRF_DEPE,
               t1.DT_ATDT,
               t1.TX_UTZD_SNH_ATDT,
               t4.tempo_max_neg;
QUIT;

GOPTIONS NOACCESSIBLE;




%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: QRY_TBL_BASE_ATDT   */
%LET _CLIENTTASKLABEL='QRY_TBL_BASE_ATDT';
%LET _CLIENTPROCESSFLOWNAME='Relatório 170';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\8.P0_Indicadores_Atendimento\Projeto-Indicadores-Atendimento V9.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='Projeto-Indicadores-Atendimento V9.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TBL_BASE_ATDT);

PROC SQL;
   CREATE TABLE WORK.TBL_BASE_ATDT AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          t1.DT_ATDT, 
          t1.NR_ATDT, 
          t1.CD_TIP_ATDT, 
          t1.CD_TIP_PSS, 
          t1.CD_CLI, 
          t1.CD_TIP_CTRA, 
          t1.CD_CRIT_SGM, 
          t1.CD_MTV_PRIO, 
          t1.CD_SGM_CLI, 
          t1.NR_MTC_ADM_CTRA, 
          t1.CD_CHV_ATD, 
          t1.HR_CHGD_AG, 
          t1.HR_INC_ATDT, 
          t1.HR_FIM_ATDT, 
          t1.HR_ATDT_ABDD, 
          t1.CD_EST_ATDT, 
          t1.CD_AG_CC, 
          t1.CD_CC_CLI, 
          t1.CD_TIP_LCL_ATDT, 
          t1.CD_DEPE, 
          t1.QT_DFMT_ATDT, 
          t1.HR_DFMT_ATDT, 
          t1.HR_TRNS_OTR_FILA, 
          t1.NR_PTL_ATDT, 
          t1.NR_ORD_DEPE_SBDD, 
          t1.TX_UTZD_SNH_ATDT, 
          t1.QT_HH_DFRT_BSB, 
          t3.tempo_max_neg, 
          t4.tipo_dia LABEL='', 
          t3.TEMPO_ESPERA FORMAT=IS8601TM8. AS TEMPO_ESPERA, 
          /* TEMPO_ATDT */
            (CASE WHEN t1.CD_EST_ATDT = 40 AND t1.HR_INC_ATDT <> '0:0:0't THEN t1.HR_FIM_ATDT-t1.HR_INC_ATDT 
            ELSE 0
            END) FORMAT=IS8601TM8. LABEL="TEMPO_ATDT" AS TEMPO_ATDT, 
          t2.QTD_FUNCI
      FROM GAT.ATDT t1
           LEFT JOIN WORK.REGRA_FILA_GAT t4 ON (t1.CD_PRF_DEPE = t4.prefixo) AND (t1.DT_ATDT = t4.data_atend)
           LEFT JOIN WORK.QTD_FUNCI t2 ON (t1.CD_PRF_DEPE = t2.PREFIXO)
           INNER JOIN WORK.TEMPO_ESPERA t3 ON (t1.CD_PRF_DEPE = t3.CD_PRF_DEPE) AND (t1.DT_ATDT = t3.DT_ATDT) AND 
          (t1.TX_UTZD_SNH_ATDT = t3.TX_UTZD_SNH_ATDT)
      WHERE t1.CD_TIP_LCL_ATDT = 1 AND t1.DT_ATDT >= MDY(CASE WHEN WEEKDAY (TODAY()-1) = 1 THEN MONTH(TODAY()-3) ELSE 
           MONTH(TODAY()-1) END,01,2018) AND t1.CD_EST_ATDT NOT IN 
           (
           10,
           20
           );
QUIT;

GOPTIONS NOACCESSIBLE;





%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: QRY_BASE_ATDT   */

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.BASE_RELATORIO);

PROC SQL;
   CREATE TABLE WORK.BASE_RELATORIO AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          t1.DT_ATDT, 
          t1.TX_UTZD_SNH_ATDT, 
          t1.CD_TIP_ATDT, 
          /* CD_EST_ATDT */
            (MAX(t1.CD_EST_ATDT)) FORMAT=6. AS CD_EST_ATDT, 
          t1.TEMPO_ESPERA, 
          t1.tempo_max_neg, 
          t1.QTD_FUNCI
      FROM WORK.TBL_BASE_ATDT t1
      WHERE t1.TEMPO_ESPERA > '0:0:0't
      GROUP BY t1.CD_PRF_DEPE,
               t1.DT_ATDT,
               t1.TX_UTZD_SNH_ATDT,
               t1.CD_TIP_ATDT,
               t1.TEMPO_ESPERA,
               t1.tempo_max_neg,
               t1.QTD_FUNCI;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: RELATORIO   */

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_RELATORIO);

PROC SQL;
   CREATE TABLE WORK.TABELA_RELATORIO AS 
   SELECT t1.CD_PRF_DEPE AS PREFIXO, 
          /* QTD_SNH */
            (COUNT(t1.TX_UTZD_SNH_ATDT)) AS QTD_SNH, 
          /* TOTAL_SNH_ATDT */
            (SUM (CASE WHEN t1.CD_EST_ATDT = 40 THEN 1 ELSE 0 END)) AS TOTAL_SNH_ATDT, 
          /* NS */
            (((SUM (CASE WHEN t1.CD_EST_ATDT = 40 THEN 1 ELSE 0 END))/(COUNT(t1.TX_UTZD_SNH_ATDT)))*100) AS NS, 
          /* QTD_SNH_ABDN */
            (SUM (CASE WHEN t1.CD_EST_ATDT = 30 THEN 1 ELSE 0 END)) AS QTD_SNH_ABDN, 
          /* TAB */
            (((SUM (CASE WHEN t1.CD_EST_ATDT = 30 THEN 1 ELSE 0 END))/(COUNT(t1.TX_UTZD_SNH_ATDT)))*100) AS TAB, 
          /* QTD_ATDT_IN_PRZ */
            (SUM (CASE WHEN t1.TEMPO_ESPERA < (t1.tempo_max_neg)*60 AND t1.CD_EST_ATDT = 40 AND t1.TEMPO_ESPERA > 0 
            THEN 1 ELSE 0 END)) AS QTD_ATDT_IN_PRZ, 
          /* TAP */
            (((SUM (CASE WHEN t1.TEMPO_ESPERA < (t1.tempo_max_neg)*60 AND t1.CD_EST_ATDT = 40 AND t1.TEMPO_ESPERA > 0 
            THEN 1 ELSE 0 END))/(SUM (CASE WHEN t1.CD_EST_ATDT = 40 THEN 1 ELSE 0 END)))*100) AS TAP, 
          /* TOTAL_SNH_MOBILE */
            (SUM (CASE WHEN t1.CD_TIP_ATDT = 4 THEN 1 ELSE 0 END)) AS TOTAL_SNH_MOBILE, 
          /* ATF */
            ((SUM (CASE WHEN t1.CD_EST_ATDT = 40 THEN 1 ELSE 0 END))/t1.QTD_FUNCI) AS ATF, 
          t1.QTD_FUNCI
      FROM WORK.BASE_RELATORIO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.QTD_FUNCI;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: QRY_BASE_TME_ATDT   */
%LET _CLIENTTASKLABEL='QRY_BASE_TME_ATDT';
%LET _CLIENTPROCESSFLOWNAME='Relatório 170';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\8.P0_Indicadores_Atendimento\Projeto-Indicadores-Atendimento V9.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='Projeto-Indicadores-Atendimento V9.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.BASE_TME_ATDT);

PROC SQL;
   CREATE TABLE WORK.BASE_TME_ATDT AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          t1.DT_ATDT, 
          t1.TX_UTZD_SNH_ATDT, 
          t1.TEMPO_ESPERA
      FROM WORK.TBL_BASE_ATDT t1
      WHERE t1.TEMPO_ESPERA > '0:0:0't;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: QRY_TME_ATDT   */

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TME_ATDT);

PROC SQL;
   CREATE TABLE WORK.TME_ATDT AS 
   SELECT DISTINCT t1.CD_PRF_DEPE, 
          /* TME */
            (AVG(t1.TEMPO_ESPERA)) FORMAT=IS8601TM8. LABEL="TME" AS TME
      FROM WORK.BASE_TME_ATDT t1
      WHERE t1.TEMPO_ESPERA > '0:0:0't
      GROUP BY t1.CD_PRF_DEPE;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: QRY_TMA_ATDT   */

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TMA_ATDT);

PROC SQL;
   CREATE TABLE WORK.TMA_ATDT AS 
   SELECT t1.CD_PRF_DEPE, 
          /* TMA */
            (AVG(t1.TEMPO_ATDT)) FORMAT=IS8601TM8. LABEL="TMA" AS TMA
      FROM WORK.TBL_BASE_ATDT t1
      WHERE t1.CD_EST_ATDT = 40 AND t1.TEMPO_ESPERA > '0:0:0't AND t1.HR_INC_ATDT NOT = '0:0:0't
      GROUP BY t1.CD_PRF_DEPE;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TABELA FINAL   */
LIBNAME TMP00004 "/dados/unc/infor/mestre";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL_AG);

PROC SQL;
   CREATE TABLE WORK.TABELA_FINAL_AG AS 
   SELECT DISTINCT /* POSICAO */
                     (CASE
                     WHEN WEEKDAY (TODAY()-1) = 1 THEN TODAY()-3
                     ELSE TODAY()-1
                     END) FORMAT=IS8601DA10. AS POSICAO, 
          t1.CD_PREF_UOR AS PREFIXO, 
          /* CARTEIRA */
            (0) AS CARTEIRA, 
          t2.QTD_SNH AS SNH_TOTAL, 
          t2.TOTAL_SNH_ATDT, 
          t2.NS, 
          t2.QTD_SNH_ABDN, 
          t2.TAB, 
          t4.TME, 
          t3.TMA, 
          t2.QTD_ATDT_IN_PRZ, 
          t2.TAP, 
          t2.QTD_FUNCI, 
          t2.ATF, 
          t2.TOTAL_SNH_MOBILE
      FROM TMP00004.mestre_uor t1
           LEFT JOIN WORK.TABELA_RELATORIO t2 ON (t1.CD_PREF_UOR = t2.PREFIXO)
           LEFT JOIN WORK.TMA_ATDT t3 ON (t1.CD_PREF_UOR = t3.CD_PRF_DEPE)
           LEFT JOIN WORK.TME_ATDT t4 ON (t1.CD_PREF_UOR = t4.CD_PRF_DEPE)
      WHERE t1.CD_SB_UOR = 0 AND t1.CD_PREF_DIRETORIA IN 
           (
           9500,
           8592,
           8477
           ) AND t1.CD_PREF_UOR NOT = 0 AND t1.TP_DEP_ANT_AG IN 
           (
           13,
           15,
           35
           ) AND t1.CD_EST_UOR = 2 AND t1.NM_UOR_RDZ NOT CONTAINS 'ESC.' AND t1.NM_UOR_RDZ NOT CONTAINS 'ESCR.' AND 
           t1.NM_UOR_RDZ NOT CONTAINS 'ESCRITORIO' AND t1.NM_UOR_RDZ NOT CONTAINS 'EXCLUSIVO' AND t1.NM_UOR_RDZ NOT 
           CONTAINS 'S.PUBLICO' AND t2.QTD_SNH NOT = .;
QUIT;

GOPTIONS NOACCESSIBLE;





%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Query SUPER   */
LIBNAME TMP00004 "/dados/unc/infor/mestre";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL_SUPER);

PROC SQL;
   CREATE TABLE WORK.TABELA_FINAL_SUPER(label="WORK.TABELA_FINAL_SUPER") AS 
   SELECT DISTINCT t1.POSICAO, 
          t2.CD_PREF_SUPER AS PREFIXO, 
          t1.CARTEIRA, 
          /* SNH_TOTAL */
            (SUM(t1.SNH_TOTAL)) AS SNH_TOTAL, 
          /* TOTAL_SNH_ATDT */
            (SUM(t1.TOTAL_SNH_ATDT)) AS TOTAL_SNH_ATDT, 
          /* NS */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.SNH_TOTAL))*100) AS NS, 
          /* QTD_SNH_ABDN */
            (SUM(t1.QTD_SNH_ABDN)) AS QTD_SNH_ABDN, 
          /* TAB */
            ((SUM(t1.QTD_SNH_ABDN))/(SUM(t1.SNH_TOTAL))*100) AS TAB, 
          /* TME */
            (AVG(t1.TME)) FORMAT=IS8601TM8. AS TME, 
          /* TMA */
            (AVG(t1.TMA)) FORMAT=IS8601TM8. AS TMA, 
          /* QTD_ATDT_IN_PRZ */
            (SUM(t1.QTD_ATDT_IN_PRZ)) AS QTD_ATDT_IN_PRZ, 
          /* TAP */
            ((SUM(t1.QTD_ATDT_IN_PRZ))/(SUM(t1.SNH_TOTAL))*100) AS TAP, 
          /* QTD_FUNCI */
            (SUM(t1.QTD_FUNCI)) AS QTD_FUNCI, 
          /* ATF */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.QTD_FUNCI))) FORMAT=BESTX15. AS ATF, 
          /* TOTAL_SNH_MOBILE */
            (SUM(t1.TOTAL_SNH_MOBILE)) AS TOTAL_SNH_MOBILE
      FROM WORK.TABELA_FINAL_AG t1
           INNER JOIN TMP00004.mestre_uor t2 ON (t1.PREFIXO = t2.CD_PREF_UOR)
      WHERE t2.CD_PREF_SUPER NOT = 0 AND t2.CD_SB_UOR = 0 AND t2.CD_PREF_DIRETORIA IN 
           (
           9500,
           8592,
           8477
           ) AND t1.SNH_TOTAL NOT = .
      GROUP BY t1.POSICAO,
               t2.CD_PREF_SUPER,
               t1.CARTEIRA;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Query GEREV   */
LIBNAME TMP00004 "/dados/unc/infor/mestre";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL_GEREV);

PROC SQL;
   CREATE TABLE WORK.TABELA_FINAL_GEREV(label="WORK.TABELA_FINAL_GEREV") AS 
   SELECT DISTINCT t1.POSICAO, 
          t2.CD_PREF_GEREV AS PREFIXO, 
          t1.CARTEIRA, 
          /* SNH_TOTAL */
            (SUM(t1.SNH_TOTAL)) AS SNH_TOTAL, 
          /* TOTAL_SNH_ATDT */
            (SUM(t1.TOTAL_SNH_ATDT)) AS TOTAL_SNH_ATDT, 
          /* NS */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.SNH_TOTAL))*100) AS NS, 
          /* QTD_SNH_ABDN */
            (SUM(t1.QTD_SNH_ABDN)) AS QTD_SNH_ABDN, 
          /* TAB */
            ((SUM(t1.QTD_SNH_ABDN))/(SUM(t1.SNH_TOTAL))*100) AS TAB, 
          /* TME */
            (AVG(t1.TME)) FORMAT=IS8601TM8. AS TME, 
          /* TMA */
            (AVG(t1.TMA)) FORMAT=IS8601TM8. AS TMA, 
          /* QTD_ATDT_IN_PRZ */
            (SUM(t1.QTD_ATDT_IN_PRZ)) AS QTD_ATDT_IN_PRZ, 
          /* TAP */
            ((SUM(t1.QTD_ATDT_IN_PRZ))/(SUM(t1.SNH_TOTAL))*100) AS TAP, 
          /* QTD_FUNCI */
            (SUM(t1.QTD_FUNCI)) AS QTD_FUNCI, 
          /* ATF */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.QTD_FUNCI))) FORMAT=BESTX15. AS ATF, 
          /* TOTAL_SNH_MOBILE */
            (SUM(t1.TOTAL_SNH_MOBILE)) AS TOTAL_SNH_MOBILE
      FROM WORK.TABELA_FINAL_AG t1
           INNER JOIN TMP00004.mestre_uor t2 ON (t1.PREFIXO = t2.CD_PREF_UOR)
      WHERE t2.CD_SB_UOR = 0 AND t2.CD_PREF_DIRETORIA IN 
           (
           9500,
           8592,
           8477
           ) AND t2.CD_PREF_GEREV NOT = 0 AND t2.CD_PREF_GEREV NOT = .
      GROUP BY t1.POSICAO,
               t2.CD_PREF_GEREV,
               t1.CARTEIRA;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Query DIRETORIA   */
LIBNAME TMP00004 "/dados/unc/infor/mestre";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL_DIRETORIA);

PROC SQL;
   CREATE TABLE WORK.TABELA_FINAL_DIRETORIA(label="WORK.TABELA_FINAL_SUPER") AS 
   SELECT DISTINCT t1.POSICAO, 
          t2.CD_PREF_DIRETORIA AS PREFIXO, 
          t1.CARTEIRA, 
          /* SNH_TOTAL */
            (SUM(t1.SNH_TOTAL)) AS SNH_TOTAL, 
          /* TOTAL_SNH_ATDT */
            (SUM(t1.TOTAL_SNH_ATDT)) AS TOTAL_SNH_ATDT, 
          /* NS */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.SNH_TOTAL))*100) AS NS, 
          /* QTD_SNH_ABDN */
            (SUM(t1.QTD_SNH_ABDN)) AS QTD_SNH_ABDN, 
          /* TAB */
            ((SUM(t1.QTD_SNH_ABDN))/(SUM(t1.SNH_TOTAL))*100) AS TAB, 
          /* TME */
            (AVG(t1.TME)) FORMAT=IS8601TM8. AS TME, 
          /* TMA */
            (AVG(t1.TMA)) FORMAT=IS8601TM8. AS TMA, 
          /* QTD_ATDT_IN_PRZ */
            (SUM(t1.QTD_ATDT_IN_PRZ)) AS QTD_ATDT_IN_PRZ, 
          /* TAP */
            ((SUM(t1.QTD_ATDT_IN_PRZ))/(SUM(t1.SNH_TOTAL))*100) AS TAP, 
          /* QTD_FUNCI */
            (SUM(t1.QTD_FUNCI)) AS QTD_FUNCI, 
          /* ATF */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.QTD_FUNCI))) FORMAT=BESTX15. AS ATF, 
          /* TOTAL_SNH_MOBILE */
            (SUM(t1.TOTAL_SNH_MOBILE)) AS TOTAL_SNH_MOBILE
      FROM WORK.TABELA_FINAL_AG t1
           INNER JOIN TMP00004.mestre_uor t2 ON (t1.PREFIXO = t2.CD_PREF_UOR)
      WHERE t2.CD_SB_UOR = 0 AND t2.CD_PREF_DIRETORIA IN 
           (
           9500,
           8592,
           8477
           )
      GROUP BY t1.POSICAO,
               t2.CD_PREF_DIRETORIA,
               t1.CARTEIRA;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Query VIVAR   */
LIBNAME TMP00004 "/dados/unc/infor/mestre";



GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL_VIVAR);

PROC SQL;
   CREATE TABLE WORK.TABELA_FINAL_VIVAR(label="WORK.TABELA_FINAL_SUPER") AS 
   SELECT DISTINCT t1.POSICAO, 
          /* PREFIXO */
            (8166) AS PREFIXO, 
          t1.CARTEIRA, 
          /* SNH_TOTAL */
            (SUM(t1.SNH_TOTAL)) AS SNH_TOTAL, 
          /* TOTAL_SNH_ATDT */
            (SUM(t1.TOTAL_SNH_ATDT)) AS TOTAL_SNH_ATDT, 
          /* NS */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.SNH_TOTAL))*100) AS NS, 
          /* QTD_SNH_ABDN */
            (SUM(t1.QTD_SNH_ABDN)) AS QTD_SNH_ABDN, 
          /* TAB */
            ((SUM(t1.QTD_SNH_ABDN))/(SUM(t1.SNH_TOTAL))*100) AS TAB, 
          /* TME */
            (AVG(t1.TME)) FORMAT=IS8601TM8. AS TME, 
          /* TMA */
            (AVG(t1.TMA)) FORMAT=IS8601TM8. AS TMA, 
          /* QTD_ATDT_IN_PRZ */
            (SUM(t1.QTD_ATDT_IN_PRZ)) AS QTD_ATDT_IN_PRZ, 
          /* TAP */
            ((SUM(t1.QTD_ATDT_IN_PRZ))/(SUM(t1.SNH_TOTAL))*100) AS TAP, 
          /* QTD_FUNCI */
            (SUM(t1.QTD_FUNCI)) AS QTD_FUNCI, 
          /* ATF */
            ((SUM(t1.TOTAL_SNH_ATDT))/(SUM(t1.QTD_FUNCI))) FORMAT=BESTX15. AS ATF, 
          /* TOTAL_SNH_MOBILE */
            (SUM(t1.TOTAL_SNH_MOBILE)) AS TOTAL_SNH_MOBILE
      FROM WORK.TABELA_FINAL_AG t1
           INNER JOIN TMP00004.mestre_uor t2 ON (t1.PREFIXO = t2.CD_PREF_UOR)
      WHERE t2.CD_SB_UOR = 0 AND t2.CD_PREF_DIRETORIA IN 
           (
           9500,
           8592,
           8477
           )
      GROUP BY t1.POSICAO,
               (CALCULATED PREFIXO),
               t1.CARTEIRA;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Append Table   */

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL);
PROC SQL;
CREATE TABLE WORK.TABELA_FINAL AS 
SELECT * FROM WORK.TABELA_FINAL_AG
 OUTER UNION CORR 
SELECT * FROM WORK.TABELA_FINAL_GEREV
 OUTER UNION CORR 
SELECT * FROM WORK.TABELA_FINAL_SUPER
 OUTER UNION CORR 
SELECT * FROM WORK.TABELA_FINAL_DIRETORIA
 OUTER UNION CORR 
SELECT * FROM WORK.TABELA_FINAL_VIVAR
;
Quit;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TABELA DETALHE   */

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ATDT_DETALHE);

PROC SQL;
   CREATE TABLE WORK.ATDT_DETALHE AS 
   SELECT /* POSICAO */
            (CASE
            WHEN WEEKDAY (TODAY()-1) = 1 THEN TODAY()-3
            ELSE TODAY()-1
            END) FORMAT=IS8601DA10. AS POSICAO, 
          t1.CD_PRF_DEPE AS PREFIXO, 
          /* carteira */
            (7002) AS carteira, 
          t1.DT_ATDT AS DT_ATDT, 
          t1.CD_CHV_ATD, 
          t1.TX_UTZD_SNH_ATDT AS SENHA, 
          t1.TEMPO_ESPERA, 
          t1.tempo_max_neg, 
          t1.tipo_dia, 
          /* SITUACAO */
            (CASE
            WHEN t1.TEMPO_ESPERA > 0 AND t1.TEMPO_ESPERA < t1.tempo_max_neg*60 AND t1.CD_EST_ATDT = 40 THEN 
            "Dentro do Prazo"
            WHEN t1.TEMPO_ESPERA > t1.tempo_max_neg*60 AND t1.CD_EST_ATDT = 40 THEN "Fora do Prazo"
            ELSE ""
            END) AS SITUACAO, 
          t1.TEMPO_ATDT, 
          /* STATUS_ATDT */
            (CASE
            WHEN t1.CD_EST_ATDT = 40 THEN "Atendida"
            WHEN t1.CD_EST_ATDT = 30 THEN "Abandonada"
            WHEN t1.CD_EST_ATDT = 15 THEN "Remanejada"
            WHEN t1.CD_EST_ATDT = 10 THEN "Aguardando"
            WHEN t1.CD_EST_ATDT = 11 THEN "Check-in não realizado"
            WHEN t1.CD_EST_ATDT = 20 THEN "Aguardando"
            ELSE "Outros"
            END) AS STATUS_ATDT, 
          t1.CD_CLI AS MCI
      FROM WORK.TBL_BASE_ATDT t1
      WHERE t1.DT_ATDT >= MDY(CASE WHEN WEEKDAY (TODAY()-1) = 1 THEN MONTH(TODAY()-3) ELSE MONTH(TODAY()-1) END,01,2018) 
           AND t1.CD_TIP_LCL_ATDT = 1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: gera-relatorio   */

GOPTIONS ACCESSIBLE;
/*HEADER PROCESSOS*/
/*PACOTE DE FUNÇÕES BASE*/
%include '/dados/externo/UNV/canais/intranet/FuncoesBase.sas';

%LET Usuario=F9570458;
%LET Keypass=indicadores-atendimento-20a3ba8d-ee66-4028-b20e-c9b0f2d92f7f;
/*%PUT &Keypass;*/


/*#################################################################################################################*/

/*PROCESSAMENTOS*/
/*#################################################################################################################*/

data relatorio;
set WORK.TABELA_FINAL;
run;

data detalhe;
set WORK.ATDT_DETALHE;
run;


/*#################################################################################################################*/
/*#################################################################################################################*/

/*170*/

/*#################################################################################################################*/
/*#################################################################################################################*/
/*EXPORTAR REL*/
/*#################################################################################################################*/

/*TABELA AUXILIAR DE TABELAS DE CARGA E ROTINAS DO SISTEMA REL*/
PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
		/*TABELAS PARA EXPORTAÇÃO > VALUES('TABELA_SAS', 'ROTINA') > INICIAR PELA PRINCIPAL*/
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('relatorio', 'indicadores-atendimento');
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('detalhe', 'atendimentos');

QUIT;


%ExportarDadosREL(TABELAS_EXPORTAR_REL);

/*#################################################################################################################*/
/*#################################################################################################################*/


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
