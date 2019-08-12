/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: segunda-feira, 24 de dezembro de 2018     TIME: 09:19:10
PROJECT: P2_Atende_QTDv3
PROJECT PATH: G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp
---------------------------------------- */

/* Library assignment for SASApp_ANL06.GAT */

%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME GAT DB2 DATABASE=BDB2P04 SCHEMA=DB2GAT AUTHDOMAIN=DB2SGCEN;




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
%LET _CLIENTTASKLABEL='Program';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;

LIBNAME REL DB2 DATABASE=BDB2P04 SCHEMA=DB2REL AUTHDOMAIN=DB2SGCEN;
LIBNAME GAT DB2 DATABASE=BDB2P04 SCHEMA=DB2GAT AUTHDOMAIN=DB2SGCEN;
LIBNAME ARH DB2 DATABASE=BDB2P04 SCHEMA=DB2ARH AUTHDOMAIN=DB2SGCEN;
LIBNAME MST DB2 DATABASE=BDB2P04 SCHEMA=DB2MST AUTHDOMAIN=DB2SGCEN;
LIBNAME ATB DB2 DATABASE=BDB2P04 SCHEMA=DB2ATB AUTHDOMAIN=DB2SGCEN;
LIBNAME BIC DB2 DATABASE=BDB2P04 SCHEMA=DB2BIC AUTHDOMAIN=DB2SGCEN;
LIBNAME MCI DB2 DATABASE=BDB2P04 SCHEMA=DB2MCI AUTHDOMAIN=DB2SGCEN;
LIBNAME DEB DB2 DATABASE=BDB2P04 SCHEMA=DB2DEB AUTHDOMAIN=DB2SGCEN;
LIBNAME CPB DB2 DATABASE=BDB2P04 SCHEMA=DB2CPB AUTHDOMAIN=DB2SGCEN;
LIBNAME RST DB2 DATABASE=BDB2P04 SCHEMA=DB2RST AUTHDOMAIN=DB2SGCEN;

LIBNAME painel "/dados/externo" ;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: BASE_ATDT   */
LIBNAME TMP00003 "/dados/ucp";

LIBNAME TMP00004 "/dados/externo/UNV/canais";


%LET _CLIENTTASKLABEL='BASE_ATDT';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.BASE_ATENDIMENTO);

PROC SQL;
   CREATE TABLE WORK.BASE_ATENDIMENTO AS 
   SELECT DISTINCT t3.PREFIXO AS CD_PRF_DEPE, 
          t3.NOME, 
          t3.NIVEL, 
          t3.MUNICIPIO, 
          t3.UF, 
          t3.GEREV, 
          t3.SUPER, 
          t3.DIRETORIA, 
          t3.TP_DEPENDENCIA, 
          /* UNV_CONTROLE_DEMAIS */
            (Case
            When t1.CD_PRF_DEPE  in (0003, 0009, 0028, 0038, 0756, 0765, 0828, 1183, 1184, 1232, 1243, 1244, 1426, 
            1432, 1433, 1443, 1458, 1518, 1519, 1522, 1534, 1846, 1863, 1869, 1876, 1905, 1969, 2665, 2803, 2823, 2891, 
            2920, 2926, 2946, 2981, 3020, 3024, 3074, 3106, 3160, 3184, 3262, 3273, 3275, 3299, 3312, 3372, 3390, 3510, 
            3511, 3539, 3543, 3663, 3702, 3792, 4015, 4028, 4206, 4221, 4242, 4451, 4464, 5214, 5443, 5550, 6842, 6855, 
            6950, 6954, 8129, 8697) then 1
            When t1.CD_PRF_DEPE  in (20, 367, 661, 1248, 1249, 1414,1594 ,1611 ,1612 ,1638 ,1639 , 1889, 1899, 2307, 
            2375, 2794, 2797, 2806, 2813,2814 ,2817, 2821, 2822, 2869, 2953, 2954, 2972, 2980, 2999, 3015, 3126, 3154, 
            3202, 3240, 3252, 3255, 3334, 3432,3527 , 3529, 3530, 3537, 3649, 3650, 3876, 4288, 4323, 4359, 4445, 4569, 
            4612, 4613, 5446, 5459, 5656, 5675, 5716, 5784, 5789, 5882, 5895, 5972, 5990, 6533, 6841, 6853, 6919, 8110, 
            8112) then 2
            Else 0
            END
            ) LABEL="UNV_CONTROLE_DEMAIS" AS UNV_CONTROLE_DEMAIS, 
          t3.VICE_PRESIDENCIA, 
          t1.CD_CLI, 
          t1.CD_TIP_PSS, 
          t1.CD_TIP_CTRA, 
          t1.CD_CHV_ATD, 
          /* MES */
            (month (t1.DT_ATDT)) LABEL="MES" AS MES, 
          t1.DT_ATDT FORMAT=DDMMYY10. AS DT_ATDT, 
          t1.NR_ATDT, 
          t1.HR_CHGD_AG, 
          t1.HR_INC_ATDT, 
          t1.HR_FIM_ATDT, 
          t1.HR_ATDT_ABDD, 
          t1.CD_EST_ATDT, 
          t1.CD_TIP_LCL_ATDT, 
          /* ABANDONA_ENC_QTD */
            (Case
            When t1.CD_EST_ATDT = 30 AND t4.GERENCIADO = 1 then 1
            Else 0
            END
            ) LABEL="ABANDONA_ENC_QTD" AS ABANDONA_ENC_QTD, 
          /* ABANDONA_ENC_TEMPO */
            (Case
            When t1.CD_EST_ATDT = 30 and (t1.HR_ATDT_ABDD-t1.HR_INC_ATDT) > 0 AND t4.GERENCIADO = 1 then 
            ((t1.HR_ATDT_ABDD-t1.HR_INC_ATDT)/3600)
            Else 0
            END) LABEL="ABANDONA_ENC_TEMPO" AS ABANDONA_ENC_TEMPO, 
          /* ABANDONA_NENC_TEMPO */
            (Case
            When t1.CD_EST_ATDT = 30 and (t1.HR_ATDT_ABDD-t1.HR_INC_ATDT) > 0 AND t4.GERENCIADO = 0 then 
            ((t1.HR_ATDT_ABDD-t1.HR_INC_ATDT)/3600)
            Else 0
            END) LABEL="ABANDONA_NENC_TEMPO" AS ABANDONA_NENC_TEMPO, 
          /* ABANDONA_NENC_QTD */
            (Case
            When t1.CD_EST_ATDT = 30 AND t4.GERENCIADO = 0 then 1
            Else 0
            END
            ) LABEL="ABANDONA_NENC_QTD" AS ABANDONA_NENC_QTD, 
          /* ATENDE_ENC_QTD */
            (Case
            When t1.CD_EST_ATDT = 40 AND t4.GERENCIADO = 1 then 1
            Else 0
            END
            ) LABEL="ATENDE_ENC_QTD" AS ATENDE_ENC_QTD, 
          /* ATENDE_NENC_QTD */
            (Case
            When t1.CD_EST_ATDT = 40 AND t4.GERENCIADO = 0 then 1
            Else 0
            END
            ) LABEL="ATENDE_NENC_QTD" AS ATENDE_NENC_QTD, 
          /* ATENDE_ENC_TEMPO */
            (Case
            When t1.CD_EST_ATDT = 40  and (t1.HR_FIM_ATDT-t1.HR_INC_ATDT ) > 0 AND t4.GERENCIADO = 1 then 
            ((t1.HR_FIM_ATDT-t1.HR_INC_ATDT )/3600)
            Else 0
            END) LABEL="ATENDE_ENC_TEMPO" AS ATENDE_ENC_TEMPO, 
          /* ATENDE_NENC_TEMPO */
            (Case
            When t1.CD_EST_ATDT = 40  and (t1.HR_FIM_ATDT-t1.HR_INC_ATDT ) > 0 AND t4.GERENCIADO = 0 then 
            ((t1.HR_FIM_ATDT-t1.HR_INC_ATDT )/3600)
            Else 0
            END) LABEL="ATENDE_NENC_TEMPO" AS ATENDE_NENC_TEMPO, 
          /* DEMAIS_ENC_ATENDE_QTD */
            (Case
            When t1.CD_EST_ATDT not in (15, 30, 40) AND t4.GERENCIADO = 1 then 1
            Else 0
            END) LABEL="DEMAIS_ENC_ATENDE_QTD" AS DEMAIS_ENC_ATENDE_QTD, 
          /* DEMAIS_NENC_ATENDE_QTD */
            (Case
            When t1.CD_EST_ATDT not in (15, 30, 40) AND t4.GERENCIADO = 0 then 1
            Else 0
            END) LABEL="DEMAIS_NENC_ATENDE_QTD" AS DEMAIS_NENC_ATENDE_QTD, 
          /* ESPERA_ENC_TEMPO */
            (Case
            When (t1.HR_INC_ATDT-t1.HR_CHGD_AG) > 0 AND t4.GERENCIADO = 1 then ((t1.HR_INC_ATDT-t1.HR_CHGD_AG)/3600)
            Else 0
            END) LABEL="ESPERA_ENC_TEMPO" AS ESPERA_ENC_TEMPO, 
          /* ESPERA_NENC_TEMPO */
            (Case
            When (t1.HR_INC_ATDT-t1.HR_CHGD_AG) > 0 AND t4.GERENCIADO = 0 then ((t1.HR_INC_ATDT-t1.HR_CHGD_AG)/3600)
            Else 0
            END) LABEL="ESPERA_NENC_TEMPO" AS ESPERA_NENC_TEMPO, 
          /* REMANEJA_ENC_QTD */
            (Case
            When t1.CD_EST_ATDT = 15 AND t4.GERENCIADO = 1 then 1
            Else 0
            END
            ) LABEL="REMANEJA_ENC_QTD" AS REMANEJA_ENC_QTD, 
          /* REMANEJA_NENC_QTD */
            (Case
            When t1.CD_EST_ATDT = 15 AND t4.GERENCIADO = 0 then 1
            Else 0
            END
            ) LABEL="REMANEJA_NENC_QTD" AS REMANEJA_NENC_QTD, 
          /* REMANEJA_ENC_TEMPO */
            (Case
            When t1.CD_EST_ATDT = 15 and (t1.HR_FIM_ATDT-t1.HR_INC_ATDT) > 0 AND t4.GERENCIADO = 1 then 
            ((t1.HR_FIM_ATDT-t1.HR_INC_ATDT)/3600)
            else 0
            END) LABEL="REMANEJA_ENC_TEMPO" AS REMANEJA_ENC_TEMPO, 
          /* REMANEJA_NENC_TEMPO */
            (Case
            When t1.CD_EST_ATDT = 15 and (t1.HR_FIM_ATDT-t1.HR_INC_ATDT) > 0 AND t4.GERENCIADO = 0 then 
            ((t1.HR_FIM_ATDT-t1.HR_INC_ATDT)/3600)
            else 0
            END) LABEL="REMANEJA_NENC_TEMPO" AS REMANEJA_NENC_TEMPO, 
          t4.GERENCIADO, 
          t4.CARTEIRA, 
          t4.NM_TIP_CTRA, 
          t1.TX_UTZD_SNH_ATDT
      FROM GAT.ATDT t1
           INNER JOIN TMP00003.mestre t3 ON (t1.CD_PRF_DEPE = t3.PREFIXO)
           LEFT JOIN TMP00004.encarteiramento t4 ON (t1.CD_TIP_CTRA = t4.CD_TIP_CTRA)
      WHERE t1.DT_ATDT >= MDY(CASE WHEN TODAY()-1 = 1 THEN MONTH(TODAY()-3) ELSE MONTH(TODAY()-1) END, 01, 2018) AND 
           t1.CD_TIP_LCL_ATDT = 1 AND t3.COD_SUBORDINADA = 0 AND t3.DIRETORIA IN 
           (
           9500,
           8592,
           8477
           );
QUIT;

GOPTIONS NOACCESSIBLE;




%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: DETALHE   */
%LET _CLIENTTASKLABEL='DETALHE';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TBL_DETALHE);

PROC SQL;
   CREATE TABLE WORK.TBL_DETALHE AS 
   SELECT /* POSICAO */
            (CASE
            WHEN WEEKDAY (TODAY()-1) = 1 THEN TODAY()-3
            ELSE TODAY()-1
            END) FORMAT=IS8601DA10. AS POSICAO, 
          t1.CD_PRF_DEPE AS PREFIXO, 
          /* CARTEIRA */
            (7002) AS CARTEIRA, 
          t1.DT_ATDT, 
          t1.TX_UTZD_SNH_ATDT AS SENHA, 
          t1.CD_CLI AS MCI, 
          t1.CD_CHV_ATD AS MATRICULA, 
          t1.NM_TIP_CTRA, 
          t1.CARTEIRA AS GRUPO_CARTEIRA, 
          t1.HR_CHGD_AG, 
          t1.HR_INC_ATDT, 
          t1.HR_FIM_ATDT, 
          t1.HR_ATDT_ABDD, 
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
          t1.CD_EST_ATDT AS CD_EST_ATDT
      FROM WORK.BASE_ATENDIMENTO t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_ENCERRADAS   */
%LET _CLIENTTASKLABEL='SENHAS_ENCERRADAS';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_ENCERRADAS);

PROC SQL;
   CREATE TABLE WORK.SENHAS_ENCERRADAS AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.GEREV, 
          t1.SUPER, 
          t1.DIRETORIA, 
          /* TOTAL_ENCERRA */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))) LABEL="TOTAL_ENCERRA" AS TOTAL_ENCERRA, 
          /* PF_ENC_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PF_ENC_ENCERRA" AS PF_ENC_ENCERRA, 
          /* PF_ENC_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PF_ENC_ENCERRA_PC" AS PF_ENC_ENCERRA_PC, 
          /* PF_NENC_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PF_NENC_ENCERRA" AS PF_NENC_ENCERRA, 
          /* PF_NENC_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PF_NENC_ENCERRA_PC" AS PF_NENC_ENCERRA_PC, 
          /* PJ_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PJ_ENCERRA" AS PJ_ENCERRA, 
          /* PJ_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PJ_ENCERRA_PC" AS PJ_ENCERRA_PC, 
          /* N_ID_ENCERRA */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="N_ID_ENCERRA" AS N_ID_ENCERRA, 
          /* N_ID_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="N_ID_ENCERRA_PC" AS N_ID_ENCERRA_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.GEREV,
               t1.SUPER,
               t1.DIRETORIA;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_TAB   */
%LET _CLIENTTASKLABEL='SENHAS_TAB';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_TAB);

PROC SQL;
   CREATE TABLE WORK.SENHAS_TAB AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.GEREV, 
          t1.SUPER, 
          t1.DIRETORIA, 
          /* PF_ENC_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_ENC_TAB" AS PF_ENC_TAB, 
          /* PF_NENC_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_NENC_TAB" AS PF_NENC_TAB, 
          /* PJ_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))) LABEL="PJ_TAB" AS PJ_TAB, 
          /* N_ID_TAB */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="N_ID_TAB" AS N_ID_TAB
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.GEREV,
               t1.SUPER,
               t1.DIRETORIA;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_NS   */
%LET _CLIENTTASKLABEL='SENHAS_NS';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_NS);

PROC SQL;
   CREATE TABLE WORK.SENHAS_NS AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.GEREV, 
          t1.SUPER, 
          t1.DIRETORIA, 
          /* PF_ENC_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_ENC_NS" AS PF_ENC_NS, 
          /* PF_NENC_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_NENC_NS" AS PF_NENC_NS, 
          /* PJ_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))) LABEL="PJ_NS" AS PJ_NS, 
          /* N_ID_NS */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="N_ID_NS" AS N_ID_NS
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.GEREV,
               t1.SUPER,
               t1.DIRETORIA;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TOTAL_SENHAS   */
%LET _CLIENTTASKLABEL='TOTAL_SENHAS';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TOTAL_SENHAS);

PROC SQL;
   CREATE TABLE WORK.TOTAL_SENHAS AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.GEREV, 
          t1.SUPER, 
          t1.DIRETORIA, 
          /* TOTAL_SENHAS */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="TOTAL_SENHAS" AS TOTAL_SENHAS, 
          /* PF_ENC_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)) LABEL="PF_ENC_TOTAL" AS PF_ENC_TOTAL, 
          /* PF_ENC_TOTAL_PC */
            (100 * (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PF_ENC_TOTAL_PC" AS PF_ENC_TOTAL_PC, 
          /* PF_NENC_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)) LABEL="PF_NENC_TOTAL" AS PF_NENC_TOTAL, 
          /* PF_NENC_TOTAL_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PF_NENC_TOTAL_PC" AS PF_NENC_TOTAL_PC, 
          /* PJ_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END)) LABEL="PJ_TOTAL" AS PJ_TOTAL, 
          /* PJ_TOTAL_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PJ_TOTAL_PC" AS PJ_TOTAL_PC, 
          /* N_ID_TOTAL */
            (SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END)) LABEL="N_ID_TOTAL" AS N_ID_TOTAL, 
          /* N_ID_TOTAL_PC */
            (100 * (SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="N_ID_TOTAL_PC" AS N_ID_TOTAL_PC, 
          /* SNH_ATDT */
            (COUNT(t1.TX_UTZD_SNH_ATDT)) AS SNH_ATDT
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.GEREV,
               t1.SUPER,
               t1.DIRETORIA;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_DEMAIS   */
%LET _CLIENTTASKLABEL='SENHAS_DEMAIS';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_DEMAIS);

PROC SQL;
   CREATE TABLE WORK.SENHAS_DEMAIS AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.GEREV, 
          t1.SUPER, 
          t1.DIRETORIA, 
          /* TOTAL_DEMAIS */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))) LABEL="TOTAL_DEMAIS" AS TOTAL_DEMAIS, 
          /* PF_ENC_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END)) LABEL="PF_ENC_DEMAIS" AS PF_ENC_DEMAIS, 
          /* PF_ENC_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))
            
            ) LABEL="PF_ENC_DEMAIS_PC" AS PF_ENC_DEMAIS_PC, 
          /* PF_NENC_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="PF_NENC_DEMAIS" AS PF_NENC_DEMAIS, 
          /* PF_NENC_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="PF_NENC_DEMAIS_PC" AS PF_NENC_DEMAIS_PC, 
          /* PJ_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="PJ_DEMAIS" AS PJ_DEMAIS, 
          /* PJ_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="PJ_DEMAIS_PC" AS PJ_DEMAIS_PC, 
          /* N_ID_DEMAIS */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="N_ID_DEMAIS" AS N_ID_DEMAIS, 
          /* N_ID_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="N_ID_DEMAIS_PC" AS N_ID_DEMAIS_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.GEREV,
               t1.SUPER,
               t1.DIRETORIA;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_ABANDONA   */
%LET _CLIENTTASKLABEL='SENHAS_ABANDONA';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_ABANDONA);

PROC SQL;
   CREATE TABLE WORK.SENHAS_ABANDONA AS 
   SELECT t1.CD_PRF_DEPE, 
          t1.GEREV, 
          t1.SUPER, 
          t1.DIRETORIA, 
          /* TOTAL_ABANDONA */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))) LABEL="TOTAL_ABANDONA" AS TOTAL_ABANDONA, 
          /* PF_ENC_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PF_ENC_ABANDONA" AS PF_ENC_ABANDONA, 
          /* PF_ENC_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PF_ENC_ABANDONA_PC" AS PF_ENC_ABANDONA_PC, 
          /* PF_NENC_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PF_NENC_ABANDONA" AS PF_NENC_ABANDONA, 
          /* PF_NENC_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PF_NENC_ABANDONA_PC" AS PF_NENC_ABANDONA_PC, 
          /* PJ_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PJ_ABANDONA" AS PJ_ABANDONA, 
          /* PJ_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PJ_ABANDONA_PC" AS PJ_ABANDONA_PC, 
          /* N_ID_ABANDONA */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="N_ID_ABANDONA" AS N_ID_ABANDONA, 
          /* N_ID_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="N_ID_ABANDONA_PC" AS N_ID_ABANDONA_PC, 
          /* AB_Clientes_Remotos */
            (SUM(Case
            When t1.CD_TIP_CTRA=10 OR  t1.CD_TIP_CTRA=56 OR  t1.CD_TIP_CTRA=40  AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            ) AS AB_Clientes_Remotos
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.CD_PRF_DEPE,
               t1.GEREV,
               t1.SUPER,
               t1.DIRETORIA;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: RELATORIO_SENHAS_QTD_AGENCIAS   */
%LET _CLIENTTASKLABEL='RELATORIO_SENHAS_QTD_AGENCIAS';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.RELATORIO_SENHAS_QTD_AGENCIAS);

PROC SQL;
   CREATE TABLE WORK.RELATORIO_SENHAS_QTD_AGENCIAS AS 
   SELECT DISTINCT /* POSICAO */
                     (TODAY()-1) FORMAT=IS8601DA10. AS POSICAO, 
          t1.CD_PRF_DEPE AS PREFIXO, 
          /* CARTEIRA */
            (Case
            when t1.CD_PRF_DEPE <> 0 then 0
            Else 1
            END) LABEL="CARTEIRA" AS CARTEIRA, 
          t1.TOTAL_SENHAS AS TOTAL_SENHAS, 
          /* ENCERRADAS */
            (t2.TOTAL_ENCERRA) LABEL="ENCERRADAS" AS ENCERRADAS, 
          /* ENCERRADAS_PC */
            ((100*(t2.TOTAL_ENCERRA/t1.TOTAL_SENHAS))) LABEL="ENCERRADAS_PC" AS ENCERRADAS_PC, 
          /* ABANDONADAS */
            (t3.TOTAL_ABANDONA) LABEL="ABANDONADAS" AS ABANDONADAS, 
          /* ABANDONADAS_PC */
            ((100*(t3.TOTAL_ABANDONA/t1.TOTAL_SENHAS))) LABEL="ABANDONADAS_PC" AS ABANDONADAS_PC, 
          /* DEMAIS */
            (t4.TOTAL_DEMAIS) LABEL="DEMAIS" AS DEMAIS, 
          /* DEMAIS_PC */
            (100*(t4.TOTAL_DEMAIS/t1.TOTAL_SENHAS)) LABEL="DEMAIS_PC" AS DEMAIS_PC, 
          /* SENHAS_TOTAL */
            (t1.TOTAL_SENHAS) LABEL="SENHAS_TOTAL" AS SENHAS_TOTAL, 
          t1.PF_ENC_TOTAL AS PF_ENC_TOTAL, 
          t1.PF_ENC_TOTAL_PC, 
          t1.PF_NENC_TOTAL AS PF_NENC_TOTAL, 
          t1.PF_NENC_TOTAL_PC, 
          t1.PJ_TOTAL, 
          t1.PJ_TOTAL_PC, 
          t1.N_ID_TOTAL, 
          t1.N_ID_TOTAL_PC, 
          t2.TOTAL_ENCERRA AS TOTAL_ENCERRA, 
          t2.PF_ENC_ENCERRA AS PF_ENC_ENCERRA, 
          t2.PF_ENC_ENCERRA_PC, 
          t2.PF_NENC_ENCERRA AS PF_NENC_ENCERRA, 
          t2.PF_NENC_ENCERRA_PC AS PF_NENC_ENCERRA_PC, 
          t2.PJ_ENCERRA AS PJ_ENCERRA, 
          t2.PJ_ENCERRA_PC AS PJ_ENCERRA_PC, 
          t2.N_ID_ENCERRA AS N_ID_ENCERRA, 
          t2.N_ID_ENCERRA_PC AS N_ID_ENCERRA_PC, 
          t3.TOTAL_ABANDONA AS TOTAL_ABANDONA, 
          t3.PF_ENC_ABANDONA AS PF_ENC_ABANDONA, 
          t3.PF_ENC_ABANDONA_PC AS PF_ENC_ABANDONA_PC, 
          t3.PF_NENC_ABANDONA AS PF_NENC_ABANDONA, 
          t3.PF_NENC_ABANDONA_PC AS PF_NENC_ABANDONA_PC, 
          t3.PJ_ABANDONA AS PJ_ABANDONA, 
          t3.PJ_ABANDONA_PC AS PJ_ABANDONA_PC, 
          t3.N_ID_ABANDONA AS N_ID_ABANDONA, 
          t3.N_ID_ABANDONA_PC AS N_ID_ABANDONA_PC, 
          t4.TOTAL_DEMAIS AS TOTAL_DEMAIS, 
          t4.PF_ENC_DEMAIS AS PF_ENC_DEMAIS, 
          t4.PF_ENC_DEMAIS_PC AS PF_ENC_DEMAIS_PC, 
          t4.PF_NENC_DEMAIS AS PF_NENC_DEMAIS, 
          t4.PF_NENC_DEMAIS_PC AS PF_NENC_DEMAIS_PC, 
          t4.PJ_DEMAIS, 
          t4.PJ_DEMAIS_PC, 
          t4.N_ID_DEMAIS, 
          t4.N_ID_DEMAIS_PC, 
          /* TOTAL_NS */
            (100*(t2.TOTAL_ENCERRA/t1.TOTAL_SENHAS)) LABEL="TOTAL_NS" AS TOTAL_NS, 
          t5.PF_ENC_NS AS PF_ENC_NS, 
          t5.PF_NENC_NS AS PF_NENC_NS, 
          t5.PJ_NS AS PJ_NS, 
          t5.N_ID_NS, 
          /* TOTAL_TAB */
            (100*(t3.TOTAL_ABANDONA/t1.TOTAL_SENHAS)) LABEL="TOTAL_TAB" AS TOTAL_TAB, 
          t6.PF_ENC_TAB AS PF_ENC_TAB, 
          t6.PF_NENC_TAB AS PF_NENC_TAB, 
          t6.PJ_TAB, 
          t6.N_ID_TAB, 
          t3.AB_Clientes_Remotos
      FROM WORK.TOTAL_SENHAS t1, WORK.SENHAS_ENCERRADAS t2, WORK.SENHAS_ABANDONA t3, WORK.SENHAS_DEMAIS t4, 
          WORK.SENHAS_NS t5, WORK.SENHAS_TAB t6, WORK.BASE_ATENDIMENTO t7
      WHERE (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE AND t1.CD_PRF_DEPE = t3.CD_PRF_DEPE AND t1.CD_PRF_DEPE = t4.CD_PRF_DEPE AND 
           t1.CD_PRF_DEPE = t5.CD_PRF_DEPE AND t1.CD_PRF_DEPE = t6.CD_PRF_DEPE AND t1.CD_PRF_DEPE = t7.CD_PRF_DEPE);
QUIT;

GOPTIONS NOACCESSIBLE;








%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_ENCERRADAS_GEREV   */
%LET _CLIENTTASKLABEL='SENHAS_ENCERRADAS_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_ENCERRADAS_GEREV);

PROC SQL;
   CREATE TABLE WORK.SENHAS_ENCERRADAS_GEREV AS 
   SELECT t1.GEREV, 
          /* TOTAL_ENCERRA */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))) LABEL="TOTAL_ENCERRA" AS TOTAL_ENCERRA, 
          /* PF_ENC_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PF_ENC_ENCERRA" AS PF_ENC_ENCERRA, 
          /* PF_ENC_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PF_ENC_ENCERRA_PC" AS PF_ENC_ENCERRA_PC, 
          /* PF_NENC_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PF_NENC_ENCERRA" AS PF_NENC_ENCERRA, 
          /* PF_NENC_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PF_NENC_ENCERRA_PC" AS PF_NENC_ENCERRA_PC, 
          /* PJ_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PJ_ENCERRA" AS PJ_ENCERRA, 
          /* PJ_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PJ_ENCERRA_PC" AS PJ_ENCERRA_PC, 
          /* N_ID_ENCERRA */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="N_ID_ENCERRA" AS N_ID_ENCERRA, 
          /* N_ID_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="N_ID_ENCERRA_PC" AS N_ID_ENCERRA_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.GEREV;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_TAB_GEREV   */
%LET _CLIENTTASKLABEL='SENHAS_TAB_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_TAB_GEREV);

PROC SQL;
   CREATE TABLE WORK.SENHAS_TAB_GEREV AS 
   SELECT t1.GEREV, 
          /* PF_ENC_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_ENC_TAB" AS PF_ENC_TAB, 
          /* PF_NENC_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_NENC_TAB" AS PF_NENC_TAB, 
          /* PJ_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))) LABEL="PJ_TAB" AS PJ_TAB, 
          /* N_ID_TAB */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="N_ID_TAB" AS N_ID_TAB
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.GEREV;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_NS_GEREV   */
%LET _CLIENTTASKLABEL='SENHAS_NS_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_NS_GEREV);

PROC SQL;
   CREATE TABLE WORK.SENHAS_NS_GEREV AS 
   SELECT t1.GEREV, 
          /* PF_ENC_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_ENC_NS" AS PF_ENC_NS, 
          /* PF_NENC_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_NENC_NS" AS PF_NENC_NS, 
          /* PJ_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))) LABEL="PJ_NS" AS PJ_NS, 
          /* N_ID_NS */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="N_ID_NS" AS N_ID_NS
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.GEREV;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TOTAL_SENHAS_GEREV   */
%LET _CLIENTTASKLABEL='TOTAL_SENHAS_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TOTAL_SENHAS_GEREV);

PROC SQL;
   CREATE TABLE WORK.TOTAL_SENHAS_GEREV AS 
   SELECT t1.GEREV, 
          /* TOTAL_SENHAS */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="TOTAL_SENHAS" AS TOTAL_SENHAS, 
          /* PF_ENC_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)) LABEL="PF_ENC_TOTAL" AS PF_ENC_TOTAL, 
          /* PF_ENC_TOTAL_PC */
            (100 * (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PF_ENC_TOTAL_PC" AS PF_ENC_TOTAL_PC, 
          /* PF_NENC_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)) LABEL="PF_NENC_TOTAL" AS PF_NENC_TOTAL, 
          /* PF_NENC_TOTAL_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PF_NENC_TOTAL_PC" AS PF_NENC_TOTAL_PC, 
          /* PJ_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END)) LABEL="PJ_TOTAL" AS PJ_TOTAL, 
          /* PJ_TOTAL_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PJ_TOTAL_PC" AS PJ_TOTAL_PC, 
          /* N_ID_TOTAL */
            (SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END)) LABEL="N_ID_TOTAL" AS N_ID_TOTAL, 
          /* N_ID_TOTAL_PC */
            (100 * (SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="N_ID_TOTAL_PC" AS N_ID_TOTAL_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.GEREV;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_DEMAIS_GEREV   */
%LET _CLIENTTASKLABEL='SENHAS_DEMAIS_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_DEMAIS_GEREV);

PROC SQL;
   CREATE TABLE WORK.SENHAS_DEMAIS_GEREV AS 
   SELECT t1.GEREV, 
          /* TOTAL_DEMAIS */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))) LABEL="TOTAL_DEMAIS" AS TOTAL_DEMAIS, 
          /* PF_ENC_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END)) LABEL="PF_ENC_DEMAIS" AS PF_ENC_DEMAIS, 
          /* PF_ENC_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))
            
            ) LABEL="PF_ENC_DEMAIS_PC" AS PF_ENC_DEMAIS_PC, 
          /* PF_NENC_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="PF_NENC_DEMAIS" AS PF_NENC_DEMAIS, 
          /* PF_NENC_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="PF_NENC_DEMAIS_PC" AS PF_NENC_DEMAIS_PC, 
          /* PJ_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="PJ_DEMAIS" AS PJ_DEMAIS, 
          /* PJ_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="PJ_DEMAIS_PC" AS PJ_DEMAIS_PC, 
          /* N_ID_DEMAIS */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="N_ID_DEMAIS" AS N_ID_DEMAIS, 
          /* N_ID_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="N_ID_DEMAIS_PC" AS N_ID_DEMAIS_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.GEREV;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_ABANDONA_GEREV   */
%LET _CLIENTTASKLABEL='SENHAS_ABANDONA_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_ABANDONA_GEREV);

PROC SQL;
   CREATE TABLE WORK.SENHAS_ABANDONA_GEREV AS 
   SELECT t1.GEREV, 
          /* TOTAL_ABANDONA */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))) LABEL="TOTAL_ABANDONA" AS TOTAL_ABANDONA, 
          /* PF_ENC_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PF_ENC_ABANDONA" AS PF_ENC_ABANDONA, 
          /* PF_ENC_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PF_ENC_ABANDONA_PC" AS PF_ENC_ABANDONA_PC, 
          /* PF_NENC_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PF_NENC_ABANDONA" AS PF_NENC_ABANDONA, 
          /* PF_NENC_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PF_NENC_ABANDONA_PC" AS PF_NENC_ABANDONA_PC, 
          /* PJ_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PJ_ABANDONA" AS PJ_ABANDONA, 
          /* PJ_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PJ_ABANDONA_PC" AS PJ_ABANDONA_PC, 
          /* N_ID_ABANDONA */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="N_ID_ABANDONA" AS N_ID_ABANDONA, 
          /* N_ID_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="N_ID_ABANDONA_PC" AS N_ID_ABANDONA_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.GEREV;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: RELATORIO_SENHAS_QTD_GEREV   */
%LET _CLIENTTASKLABEL='RELATORIO_SENHAS_QTD_GEREV';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.RELATORIO_SENHAS_QTD_GEREV);

PROC SQL;
   CREATE TABLE WORK.RELATORIO_SENHAS_QTD_GEREV AS 
   SELECT t1.GEREV AS PREFIXO, 
          t1.TOTAL_SENHAS, 
          t1.PF_ENC_TOTAL, 
          t1.PF_ENC_TOTAL_PC, 
          t1.PF_NENC_TOTAL, 
          t1.PF_NENC_TOTAL_PC, 
          t1.PJ_TOTAL, 
          t1.PJ_TOTAL_PC, 
          t1.N_ID_TOTAL, 
          t1.N_ID_TOTAL_PC, 
          t2.TOTAL_ABANDONA, 
          t2.PF_ENC_ABANDONA, 
          t2.PF_ENC_ABANDONA_PC, 
          t2.PF_NENC_ABANDONA, 
          t2.PF_NENC_ABANDONA_PC, 
          t2.PJ_ABANDONA, 
          t2.PJ_ABANDONA_PC, 
          t2.N_ID_ABANDONA, 
          t2.N_ID_ABANDONA_PC, 
          t3.TOTAL_DEMAIS, 
          t3.PF_ENC_DEMAIS, 
          t3.PF_ENC_DEMAIS_PC, 
          t3.PF_NENC_DEMAIS, 
          t3.PF_NENC_DEMAIS_PC, 
          t3.PJ_DEMAIS, 
          t3.PJ_DEMAIS_PC, 
          t3.N_ID_DEMAIS, 
          t3.N_ID_DEMAIS_PC, 
          t4.TOTAL_ENCERRA, 
          t4.PF_ENC_ENCERRA, 
          t4.PF_ENC_ENCERRA_PC, 
          t4.PF_NENC_ENCERRA, 
          t4.PF_NENC_ENCERRA_PC, 
          t4.PJ_ENCERRA, 
          t4.PJ_ENCERRA_PC, 
          t4.N_ID_ENCERRA, 
          t4.N_ID_ENCERRA_PC, 
          t5.PF_ENC_NS, 
          t5.PF_NENC_NS, 
          t5.PJ_NS, 
          t5.N_ID_NS, 
          t6.PF_ENC_TAB, 
          t6.PF_NENC_TAB, 
          t6.PJ_TAB, 
          t6.N_ID_TAB, 
          /* CARTEIRA */
            (Case
            when t1.GEREV <> 0 then 0
            Else 1
            END) LABEL="CARTEIRA" AS CARTEIRA, 
          /* TOTAL_NS */
            (100*(t4.TOTAL_ENCERRA/t1.TOTAL_SENHAS)) LABEL="TOTAL_NS" AS TOTAL_NS, 
          /* TOTAL_TAB */
            (100*(t2.TOTAL_ABANDONA/t1.TOTAL_SENHAS)) LABEL="TOTAL_TAB" AS TOTAL_TAB, 
          /* ENCERRADAS */
            (t4.TOTAL_ENCERRA) LABEL="ENCERRADAS" AS ENCERRADAS, 
          /* ENCERRADAS_PC */
            (100*(t4.TOTAL_ENCERRA/t1.TOTAL_SENHAS)) LABEL="ENCERRADAS_PC" AS ENCERRADAS_PC, 
          /* ABANDONADAS */
            (t2.TOTAL_ABANDONA) LABEL="ABANDONADAS" AS ABANDONADAS, 
          /* ABANDONADAS_PC */
            (100*(t2.TOTAL_ABANDONA/t1.TOTAL_SENHAS)) LABEL="ABANDONADAS_PC" AS ABANDONADAS_PC, 
          /* DEMAIS */
            (t3.TOTAL_DEMAIS) LABEL="DEMAIS" AS DEMAIS, 
          /* DEMAIS_PC */
            (100*(t3.TOTAL_DEMAIS/t1.TOTAL_SENHAS)) LABEL="DEMAIS_PC" AS DEMAIS_PC, 
          /* SENHAS_TOTAL */
            (t1.TOTAL_SENHAS) LABEL="SENHAS_TOTAL" AS SENHAS_TOTAL
      FROM WORK.TOTAL_SENHAS_GEREV t1, WORK.SENHAS_ABANDONA_GEREV t2, WORK.SENHAS_DEMAIS_GEREV t3, 
          WORK.SENHAS_ENCERRADAS_GEREV t4, WORK.SENHAS_NS_GEREV t5, WORK.SENHAS_TAB_GEREV t6
      WHERE (t1.GEREV = t2.GEREV AND t1.GEREV = t3.GEREV AND t1.GEREV = t4.GEREV AND t1.GEREV = t5.GEREV AND t1.GEREV = 
           t6.GEREV) AND t1.GEREV > 0;
QUIT;

GOPTIONS NOACCESSIBLE;







%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_ENCERRADAS_SUPER   */
%LET _CLIENTTASKLABEL='SENHAS_ENCERRADAS_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_ENCERRADAS_SUPER);

PROC SQL;
   CREATE TABLE WORK.SENHAS_ENCERRADAS_SUPER AS 
   SELECT t1.SUPER, 
          /* TOTAL_ENCERRA */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))) LABEL="TOTAL_ENCERRA" AS TOTAL_ENCERRA, 
          /* PF_ENC_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PF_ENC_ENCERRA" AS PF_ENC_ENCERRA, 
          /* PF_ENC_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PF_ENC_ENCERRA_PC" AS PF_ENC_ENCERRA_PC, 
          /* PF_NENC_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PF_NENC_ENCERRA" AS PF_NENC_ENCERRA, 
          /* PF_NENC_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PF_NENC_ENCERRA_PC" AS PF_NENC_ENCERRA_PC, 
          /* PJ_ENCERRA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="PJ_ENCERRA" AS PJ_ENCERRA, 
          /* PJ_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="PJ_ENCERRA_PC" AS PJ_ENCERRA_PC, 
          /* N_ID_ENCERRA */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)) LABEL="N_ID_ENCERRA" AS N_ID_ENCERRA, 
          /* N_ID_ENCERRA_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END))))) LABEL="N_ID_ENCERRA_PC" AS N_ID_ENCERRA_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.SUPER;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_TAB_SUPER   */
%LET _CLIENTTASKLABEL='SENHAS_TAB_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_TAB_SUPER);

PROC SQL;
   CREATE TABLE WORK.SENHAS_TAB_SUPER AS 
   SELECT t1.SUPER, 
          /* PF_ENC_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_ENC_TAB" AS PF_ENC_TAB, 
          /* PF_NENC_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_NENC_TAB" AS PF_NENC_TAB, 
          /* PJ_TAB */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))) LABEL="PJ_TAB" AS PJ_TAB, 
          /* N_ID_TAB */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="N_ID_TAB" AS N_ID_TAB
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.SUPER;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_NS_SUPER   */
%LET _CLIENTTASKLABEL='SENHAS_NS_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_NS_SUPER);

PROC SQL;
   CREATE TABLE WORK.SENHAS_NS_SUPER AS 
   SELECT t1.SUPER, 
          /* PF_ENC_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_ENC_NS" AS PF_ENC_NS, 
          /* PF_NENC_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))) LABEL="PF_NENC_NS" AS PF_NENC_NS, 
          /* PJ_NS */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))) LABEL="PJ_NS" AS PJ_NS, 
          /* N_ID_NS */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 40 then 1
            Else 0
            END)
            /
            SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="N_ID_NS" AS N_ID_NS
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.SUPER;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TOTAL_SENHAS_SUPER   */
%LET _CLIENTTASKLABEL='TOTAL_SENHAS_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TOTAL_SENHAS_SUPER);

PROC SQL;
   CREATE TABLE WORK.TOTAL_SENHAS_SUPER AS 
   SELECT t1.SUPER, 
          /* TOTAL_SENHAS */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))) LABEL="TOTAL_SENHAS" AS TOTAL_SENHAS, 
          /* PF_ENC_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)) LABEL="PF_ENC_TOTAL" AS PF_ENC_TOTAL, 
          /* PF_ENC_TOTAL_PC */
            (100 * (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PF_ENC_TOTAL_PC" AS PF_ENC_TOTAL_PC, 
          /* PF_NENC_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)) LABEL="PF_NENC_TOTAL" AS PF_NENC_TOTAL, 
          /* PF_NENC_TOTAL_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PF_NENC_TOTAL_PC" AS PF_NENC_TOTAL_PC, 
          /* PJ_TOTAL */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END)) LABEL="PJ_TOTAL" AS PJ_TOTAL, 
          /* PJ_TOTAL_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="PJ_TOTAL_PC" AS PJ_TOTAL_PC, 
          /* N_ID_TOTAL */
            (SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END)) LABEL="N_ID_TOTAL" AS N_ID_TOTAL, 
          /* N_ID_TOTAL_PC */
            (100 * (SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END)/((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 then 1
            Else 0
            END))))) LABEL="N_ID_TOTAL_PC" AS N_ID_TOTAL_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.SUPER;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_DEMAIS_SUPER   */
%LET _CLIENTTASKLABEL='SENHAS_DEMAIS_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_DEMAIS_SUPER);

PROC SQL;
   CREATE TABLE WORK.SENHAS_DEMAIS_SUPER AS 
   SELECT t1.SUPER, 
          /* TOTAL_DEMAIS */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))) LABEL="TOTAL_DEMAIS" AS TOTAL_DEMAIS, 
          /* PF_ENC_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END)) LABEL="PF_ENC_DEMAIS" AS PF_ENC_DEMAIS, 
          /* PF_ENC_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))
            
            ) LABEL="PF_ENC_DEMAIS_PC" AS PF_ENC_DEMAIS_PC, 
          /* PF_NENC_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="PF_NENC_DEMAIS" AS PF_NENC_DEMAIS, 
          /* PF_NENC_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="PF_NENC_DEMAIS_PC" AS PF_NENC_DEMAIS_PC, 
          /* PJ_DEMAIS */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="PJ_DEMAIS" AS PJ_DEMAIS, 
          /* PJ_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="PJ_DEMAIS_PC" AS PJ_DEMAIS_PC, 
          /* N_ID_DEMAIS */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)) LABEL="N_ID_DEMAIS" AS N_ID_DEMAIS, 
          /* N_ID_DEMAIS_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40)  then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT NOT IN (30, 40) then 1
            Else 0
            END))))) LABEL="N_ID_DEMAIS_PC" AS N_ID_DEMAIS_PC
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.SUPER;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: SENHAS_ABANDONA_SUPER   */
%LET _CLIENTTASKLABEL='SENHAS_ABANDONA_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.SENHAS_ABANDONA_SUPER);

PROC SQL;
   CREATE TABLE WORK.SENHAS_ABANDONA_SUPER AS 
   SELECT t1.SUPER, 
          /* TOTAL_ABANDONA */
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))) LABEL="TOTAL_ABANDONA" AS TOTAL_ABANDONA, 
          /* PF_ENC_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PF_ENC_ABANDONA" AS PF_ENC_ABANDONA, 
          /* PF_ENC_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PF_ENC_ABANDONA_PC" AS PF_ENC_ABANDONA_PC, 
          /* PF_NENC_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PF_NENC_ABANDONA" AS PF_NENC_ABANDONA, 
          /* PF_NENC_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PF_NENC_ABANDONA_PC" AS PF_NENC_ABANDONA_PC, 
          /* PJ_ABANDONA */
            (SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="PJ_ABANDONA" AS PJ_ABANDONA, 
          /* PJ_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="PJ_ABANDONA_PC" AS PJ_ABANDONA_PC, 
          /* N_ID_ABANDONA */
            (SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) LABEL="N_ID_ABANDONA" AS N_ID_ABANDONA, 
          /* N_ID_ABANDONA_PC */
            (100*(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)
            /
            ((SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 1 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.GERENCIADO = 0 and t1.CD_TIP_PSS = 1 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI > 0 and t1.CD_TIP_PSS = 2 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))+(SUM(Case
            When t1.CD_CLI = 0 AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END))))) LABEL="N_ID_ABANDONA_PC" AS N_ID_ABANDONA_PC, 
          /* AB_Clientes_Remotos */
            (SUM(Case
            When t1.CD_TIP_CTRA=10 OR  t1.CD_TIP_CTRA=56 OR  t1.CD_TIP_CTRA=40  AND t1.CD_EST_ATDT = 30 then 1
            Else 0
            END)) AS AB_Clientes_Remotos
      FROM WORK.BASE_ATENDIMENTO t1
      GROUP BY t1.SUPER;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: RELATORIO_SENHAS_QTD_SUPER   */
%LET _CLIENTTASKLABEL='RELATORIO_SENHAS_QTD_SUPER';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.RELATORIO_SENHAS_QTD_SUPER);

PROC SQL;
   CREATE TABLE WORK.RELATORIO_SENHAS_QTD_SUPER AS 
   SELECT t1.SUPER AS PREFIXO, 
          t1.TOTAL_SENHAS, 
          t1.PF_ENC_TOTAL, 
          t1.PF_ENC_TOTAL_PC, 
          t1.PF_NENC_TOTAL, 
          t1.PF_NENC_TOTAL_PC, 
          t1.PJ_TOTAL, 
          t1.PJ_TOTAL_PC, 
          t1.N_ID_TOTAL, 
          t1.N_ID_TOTAL_PC, 
          t4.TOTAL_ENCERRA, 
          t4.PF_ENC_ENCERRA, 
          t4.PF_ENC_ENCERRA_PC, 
          t4.PF_NENC_ENCERRA, 
          t4.PF_NENC_ENCERRA_PC, 
          t4.PJ_ENCERRA, 
          t4.PJ_ENCERRA_PC, 
          t4.N_ID_ENCERRA, 
          t4.N_ID_ENCERRA_PC, 
          t2.TOTAL_ABANDONA, 
          t2.PF_ENC_ABANDONA, 
          t2.PF_ENC_ABANDONA_PC, 
          t2.PF_NENC_ABANDONA, 
          t2.PF_NENC_ABANDONA_PC, 
          t2.PJ_ABANDONA, 
          t2.PJ_ABANDONA_PC, 
          t2.N_ID_ABANDONA, 
          t2.N_ID_ABANDONA_PC, 
          t3.TOTAL_DEMAIS, 
          t3.PF_ENC_DEMAIS, 
          t3.PF_ENC_DEMAIS_PC, 
          t3.PF_NENC_DEMAIS, 
          t3.PF_NENC_DEMAIS_PC, 
          t3.PJ_DEMAIS, 
          t3.PJ_DEMAIS_PC, 
          t3.N_ID_DEMAIS, 
          t3.N_ID_DEMAIS_PC, 
          t5.PF_ENC_NS, 
          t5.PF_NENC_NS, 
          t5.PJ_NS, 
          t5.N_ID_NS, 
          t6.PF_ENC_TAB, 
          t6.PF_NENC_TAB, 
          t6.PJ_TAB, 
          t6.N_ID_TAB, 
          /* CARTEIRA */
            (Case
            when t1.SUPER <> 0 then 0
            Else 1
            END
            ) LABEL="CARTEIRA" AS CARTEIRA, 
          /* TOTAL_NS */
            (100*(t4.TOTAL_ENCERRA/t1.TOTAL_SENHAS)) LABEL="TOTAL_NS" AS TOTAL_NS, 
          /* TOTAL_TAB */
            (100*(t2.TOTAL_ABANDONA/t1.TOTAL_SENHAS)
            ) LABEL="TOTAL_TAB" AS TOTAL_TAB, 
          /* ENCERRADAS */
            (t4.TOTAL_ENCERRA) LABEL="ENCERRADAS" AS ENCERRADAS, 
          /* ENCERRADAS_PC */
            ((100*(t4.TOTAL_ENCERRA/t1.TOTAL_SENHAS))
            ) LABEL="ENCERRADAS_PC" AS ENCERRADAS_PC, 
          /* ABANDONADAS */
            (t2.TOTAL_ABANDONA) LABEL="ABANDONADAS" AS ABANDONADAS, 
          /* ABANDONADAS_PC */
            ((100*(t2.TOTAL_ABANDONA/t1.TOTAL_SENHAS))
            ) LABEL="ABANDONADAS_PC" AS ABANDONADAS_PC, 
          /* DEMAIS */
            (t3.TOTAL_DEMAIS) LABEL="DEMAIS" AS DEMAIS, 
          /* DEMAIS_PC */
            (100*(t3.TOTAL_DEMAIS/t1.TOTAL_SENHAS)
            ) LABEL="DEMAIS_PC" AS DEMAIS_PC, 
          /* SENHAS_TOTAL */
            (t1.TOTAL_SENHAS) LABEL="SENHAS_TOTAL" AS SENHAS_TOTAL, 
          t2.AB_Clientes_Remotos
      FROM WORK.TOTAL_SENHAS_SUPER t1, WORK.SENHAS_ABANDONA_SUPER t2, WORK.SENHAS_DEMAIS_SUPER t3, 
          WORK.SENHAS_ENCERRADAS_SUPER t4, WORK.SENHAS_NS_SUPER t5, WORK.SENHAS_TAB_SUPER t6
      WHERE (t1.SUPER = t2.SUPER AND t1.SUPER = t3.SUPER AND t1.SUPER = t4.SUPER AND t1.SUPER = t5.SUPER AND t1.SUPER = 
           t6.SUPER) AND t1.SUPER > 0;
QUIT;

GOPTIONS NOACCESSIBLE;







%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Append Table   */
%LET _CLIENTTASKLABEL='Append Table';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA1);
PROC SQL;
CREATE TABLE WORK.TABELA1 AS 
SELECT * FROM WORK.RELATORIO_SENHAS_QTD_AGENCIAS
 OUTER UNION CORR 
SELECT * FROM WORK.RELATORIO_SENHAS_QTD_GEREV
 OUTER UNION CORR 
SELECT * FROM WORK.RELATORIO_SENHAS_QTD_SUPER
;
Quit;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: TABELA_FINAL-ag   */
%LET _CLIENTTASKLABEL='TABELA_FINAL-ag';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.TABELA_FINAL);

PROC SQL;
   CREATE TABLE WORK.TABELA_FINAL(label="WORK.TABELA_FINAL") AS 
   SELECT DISTINCT /* POSICAO */
                     (CASE 
                     WHEN WEEKDAY (TODAY()-1) = 1 THEN TODAY()-3
                     ELSE TODAY()-1
                     END) FORMAT=IS8601DA10. LABEL="POSICAO" AS POSICAO, 
          t1.PREFIXO, 
          t1.CARTEIRA, 
          t1.TOTAL_SENHAS, 
          t1.ENCERRADAS, 
          t1.ENCERRADAS_PC, 
          t1.ABANDONADAS, 
          t1.ABANDONADAS_PC, 
          t1.DEMAIS, 
          t1.DEMAIS_PC, 
          t1.SENHAS_TOTAL, 
          t1.PF_ENC_TOTAL, 
          t1.PF_ENC_TOTAL_PC, 
          t1.PF_NENC_TOTAL, 
          t1.PF_NENC_TOTAL_PC, 
          t1.PJ_TOTAL, 
          t1.PJ_TOTAL_PC, 
          t1.N_ID_TOTAL, 
          t1.N_ID_TOTAL_PC, 
          t1.TOTAL_ENCERRA, 
          t1.PF_ENC_ENCERRA, 
          t1.PF_ENC_ENCERRA_PC, 
          t1.PF_NENC_ENCERRA, 
          t1.PF_NENC_ENCERRA_PC, 
          t1.PJ_ENCERRA, 
          t1.PJ_ENCERRA_PC, 
          t1.N_ID_ENCERRA, 
          t1.N_ID_ENCERRA_PC, 
          t1.TOTAL_ABANDONA, 
          t1.PF_ENC_ABANDONA, 
          t1.PF_ENC_ABANDONA_PC, 
          t1.PF_NENC_ABANDONA, 
          t1.PF_NENC_ABANDONA_PC, 
          t1.PJ_ABANDONA, 
          t1.PJ_ABANDONA_PC, 
          t1.N_ID_ABANDONA, 
          t1.N_ID_ABANDONA_PC, 
          t1.TOTAL_DEMAIS, 
          t1.PF_ENC_DEMAIS, 
          t1.PF_ENC_DEMAIS_PC, 
          t1.PF_NENC_DEMAIS, 
          t1.PF_NENC_DEMAIS_PC, 
          t1.PJ_DEMAIS, 
          t1.PJ_DEMAIS_PC, 
          t1.N_ID_DEMAIS, 
          t1.N_ID_DEMAIS_PC, 
          t1.TOTAL_NS, 
          t1.PF_ENC_NS, 
          t1.PF_NENC_NS, 
          t1.PJ_NS, 
          t1.N_ID_NS, 
          t1.TOTAL_TAB, 
          t1.PF_ENC_TAB, 
          t1.PF_NENC_TAB, 
          t1.PJ_TAB, 
          t1.N_ID_TAB, 
          t1.AB_Clientes_Remotos
      FROM WORK.TABELA1 t1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: gera-relatorio   */
%LET _CLIENTTASKLABEL='gera-relatorio';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='G:\Interna\1.Gestão da Rede\1.BI - Relatórios\9.P2_ATENDIMENTO\P2_Atende_QTDv3.egp';
%LET _CLIENTPROJECTPATHHOST='ESBSA239500HJ41';
%LET _CLIENTPROJECTNAME='P2_Atende_QTDv3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
/*HEADER PROCESSOS*/
/*PACOTE DE FUNÇÕES BASE*/
%include '/dados/externo/UNV/canais/intranet/FuncoesBase.sas';

%LET Usuario=F9570458;
%LET Keypass=AO1aHANZoS1X0lD77fQRyahxWMXbXa8952PsuIOkfgiUDyqQ7o;
/*%PUT &Keypass;*/


/*#################################################################################################################*/

/*PROCESSAMENTOS*/
/*#################################################################################################################*/

data relatorio;
set WORK.TABELA_FINAL;
run;

data detalhe;
set WORK.TBL_DETALHE;
run;

/*#################################################################################################################*/
/*#################################################################################################################*/


/*#################################################################################################################*/
/*#################################################################################################################*/
/*EXPORTAR REL*/
/*#################################################################################################################*/

/*167*/


/*TABELA AUXILIAR DE TABELAS DE CARGA E ROTINAS DO SISTEMA REL*/
PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL;
	CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
		/*TABELAS PARA EXPORTAÇÃO > VALUES('TABELA_SAS', 'ROTINA') > INICIAR PELA PRINCIPAL*/
	INSERT INTO TABELAS_EXPORTAR_REL VALUES('relatorio', 'atendimento-horizontal');
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
