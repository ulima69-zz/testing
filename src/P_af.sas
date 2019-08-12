%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME AF		"/dados/infor/producao/AF";

%diasUteis(%sysfunc(today()), 10);
%GLOBAL DiaUtil_D1;


%conectardb2 (csh, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (cop, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (rel, AUTHDOMAIN=DB2SGCEN);


LIBNAME TBLS		"/dados/infor/producao/tbls_comuns";
LIBNAME PREP		"/dados/gecen/interno/bases/bcn";
LIBNAME IGR "/dados/infor/producao/dependencias/";
LIBNAME AF		"/dados/infor/producao/AF";
LIBNAME rel		"/dados/gecen/interno/bases/rel";
libname gcn "/dados/externo/GECEN/AF";


/*libnames*/
Options
	Compress = no
	Reuse    = Yes
	PageNo   =   1
	PageSize =  55
	LineSize = 110;



LIBNAME RUT "/dados/infor/producao/RotinasUteis";

PROC SQL;
	CREATE VIEW APOIO AS
		SELECT Min(DataMovimento) Format ddmmyy10. AS D
			FROM RUT.TBL_DATAS_PROCESSAMENTO 
				WHERE DataMovimento>Today()-Weekday(Today())
					AND Dia_Util='S';
QUIT;

DATA _NULL_;
	SET APOIO;
	CALL SYMPUT('Posicao',Put(D, Date9.));
RUN;

%PUT &Posicao;

PROC SQL;
   CREATE TABLE af.Antecipadas AS 
   SELECT t2.cd_cli_pct label="ancora" as mci_ancora,t1.DT_EST_ORD_CPR, 
   t1.NR_ORD_CPR,
          t1.VL_ORD_CPR, 
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF
      FROM DB2CSH.ORD_CPR t1, db2csh.pct_neg t2 
      WHERE t1.CD_EST_ORD_CPR = 6 AND t1.DT_EST_ORD_CPR >= '1JAN2018'd
and t1.nr_ctr_pct_cprd = t2.nr_ctr_pct_neg ;
QUIT;




PROC SQL;
   CREATE TABLE Antecipadas_MCI AS 
   SELECT t1.mci_ancora, t1.DT_EST_ORD_CPR, 
   t1.NR_ORD_CPR,
          t2.mci, 
          t1.VL_ORD_CPR, 
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF
      FROM af.Antecipadas t1
           LEFT JOIN PREP.bcn_pj t2 ON (t1.NR_IDFR_FRNC_SRF = t2.cnpj)
;
QUIT;

DATA GCN.AF_Antecipadas;
SET Antecipadas_MCI;
RUN;


PROC SQL;
   CREATE TABLE Antecipadas_cart AS 
   SELECT put (t2.CD_PRF_DEPE, z4.) format $4. as PrefDep, 
          t2.NR_SEQL_CTRA as CART,
          T2.cd_tIp_ctra as TP_CART, t1.mci_ancora, 
          t1.DT_EST_ORD_CPR, 
		  t1.NR_ORD_CPR,
          t1.mci, 
          t1.VL_ORD_CPR, 
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF
      FROM WORK.Antecipadas_MCI t1
           left JOIN tbls.pai_rel_201612 t2 ON (t1.mci = t2.CD_CLI)
where t1.DT_EST_ORD_CPR >='01aug2015'd and t2.cd_tIp_ctra not in (321, 322, 323, 328)
order by 5;
QUIT;

PROC SQL;
   CREATE TABLE ANTECIPADAS_CART1 AS 
   SELECT DISTINCT IFC (t1.prefdep IN ('   .' '0000' '4777'),PUT (T2.pref_agen_cdto, Z4.),t1.prefdep) AS PREFDEP,
   		IFN (T1.TP_CART=.,700,T1.TP_CART) AS TP_CART,
          IFN (t1.cart=.,7002,t1.cart) AS CART, t1.mci_ancora, 
          t1.DT_EST_ORD_CPR, 
          t1.NR_ORD_CPR, 
          t1.mci, 
          t1.VL_ORD_CPR, 
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF, 
          
          t2.nr_carteira
      FROM WORK.ANTECIPADAS_CART t1
           INNER JOIN TBLS.BCN_PJ t2 ON (t1.mci = t2.mci)
		   WHERE t1.PREFDEP NE '9940'
order by 1, 2, 5;
QUIT;


PROC SQL;
   CREATE TABLE CART_1 AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.cart, t1.mci_ancora, 
          t1.DT_EST_ORD_CPR, 
          t1.mci, 
		  t1.NR_ORD_CPR,
          t1.VL_ORD_CPR, 
		  ifn (week (&diautil_d0)=week (DT_EST_ORD_CPR),T1.VL_ORD_CPR,0) as semana,
		  IFN (t1.DT_EST_ORD_CPR BETWEEN (intnx('month',&diautil_d0, 0, 'begin')) AND (intnx('month',&diautil_d0, 0, 'end')), T1.VL_ORD_CPR,0) AS VLR_MES_ATU,
		  IFN (t1.DT_EST_ORD_CPR BETWEEN INTNX('MONTH',TODAY(),-1) AND (INTNX('MONTH',TODAY(),0)-1), T1.VL_ORD_CPR,0) AS VLR_MES_ANT,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D1,T1.VL_ORD_CPR,0) AS VLR_D_1,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D2,T1.VL_ORD_CPR,0) AS VLR_D_2,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D3,T1.VL_ORD_CPR,0) AS VLR_D_3,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D4,T1.VL_ORD_CPR,0) AS VLR_D_4,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D5,T1.VL_ORD_CPR,0) AS VLR_D_5,
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF
      FROM ANTECIPADAS_CART1 t1
           WHERE PREFDEP Not in ('9940' '3868' '7058' '7006');
QUIT;

DATA GCN.ANTECIPADAS;
SET CART_1;
WHERE YEAR(DT_EST_ORD_CPR)=YEAR(&DiaUtil_D1);
RUN;

PROC SQL;
   CREATE TABLE CART AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.cart, 
          SUM (t1.VL_ORD_CPR) AS VLR_TOTAL, 
		  sum (t1.semana) as semana,
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5
      FROM WORK.CART_1 t1
GROUP BY 1, 2;
QUIT;

/*
PROC SQL;
   CREATE TABLE WORK.ORDENS_FINAIS_ENC_HST AS 
   SELECT DISTINCT  put (t2.CD_PRF_DEPE, z4.) format $4. as PrefDep, 
          t2.NR_SEQL_CTRA as CART,
          t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR, 
          t1.SITUACAO, 
          t1.NR_ORD_CPR, 
          t1.VL_ORD_CPR, 
          t1.DT_VNCT_ORD_CPR, 
          t1.NR_SEQL_TAXA, 
          t1.NR_BCO_PGTO, 
          t1.CD_PRF_AG_PGTO, 
          t1.DV_AG_PGTO, 
          t1.NR_CT_PGTO, 
          t1.DV_CT_PGTO, 
          t1.mvto
      FROM AF.ORDENS_FINAIS_ENC_HST t1
           LEFT JOIN rel.rel t2 ON (t1.MCI_FORNECEDOR = t2.CD_CLI);
QUIT;

*/

DATA GCN.ORDENS;
SET AF.ORDENS_FINAIS_ENC_HST;
WHERE YEAR(mvto)=YEAR(&DiaUtil_D1);
RUN;

PROC SQL;
   CREATE TABLE WORK.ORDENS_FINAIS_ENC_HST AS 
   SELECT DISTINCT  put (t2.CD_PRF_DEPE, z4.) format $4. as PrefDep, 
          t2.NR_SEQL_CTRA as CART,
          t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR, 
          t1.SITUACAO, 
          t1.NR_ORD_CPR, 
          t1.VL_ORD_CPR, 
          t1.DT_VNCT_ORD_CPR, 
          t1.NR_SEQL_TAXA, 
          t1.NR_BCO_PGTO, 
          t1.CD_PRF_AG_PGTO, 
          t1.DV_AG_PGTO, 
          t1.NR_CT_PGTO, 
          t1.DV_CT_PGTO, 
		  T1.MVTO as mvto1,
           t1.mvto FORMAT DDMMYY10. AS MVTO
      FROM AF.ORDENS_FINAIS_ENC_HST t1
           LEFT JOIN rel.rel t2 ON (t1.MCI_FORNECEDOR = t2.CD_CLI)
where t2.cd_tIp_ctra not in (321, 322, 323, 328);
QUIT;

DATA GCN.AF_ORDENS_HIST;
SET AF.ORDENS_FINAIS_ENC_HST;
RUN;

/*
PROC SQL;
   CREATE TABLE WORK.ORDENS_FINAIS_ENC_HST_1 AS 
   SELECT DISTINCT  ifc (t1.PrefDep in ('' '4777' '0000'),put (t2.pref_agen_cdto, z4.),t1.prefdep) as prefdep,
          t1.cart, 
          t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR, 
          t1.SITUACAO, 
          t1.NR_ORD_CPR, 
          t1.VL_ORD_CPR, 
          t1.DT_VNCT_ORD_CPR, 
          t1.NR_SEQL_TAXA, 
          t1.NR_BCO_PGTO, 
          t1.CD_PRF_AG_PGTO, 
          t1.DV_AG_PGTO, 
          t1.NR_CT_PGTO, 
          t1.DV_CT_PGTO, 
          t1.mvto
      FROM ORDENS_FINAIS_ENC_HST t1
           INNER JOIN BCN.BCN_PJ t2 ON (t1.MCI_FORNECEDOR = t2.mci);
QUIT;
*/

/*PROC SQL;
   CREATE TABLE AJUSTA_DISP AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
          IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D1,t1.DT_EST_ORD_CPR-1, t1.DT_EST_ORD_CPR) format ddmmyy10. AS DT_EST_ORD_CPR,
          t1.NR_ORD_CPR, 
          t1.mci, 
          t1.VL_ORD_CPR, 
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF, 
          t1.nr_carteira
      FROM WORK.ANTECIPADAS_CART1 t1;
QUIT;*/

PROC SQL;
CREATE TABLE ORDENS_FINAIS_ENC_HST AS 
SELECT IFC (t1.prefdep IN ('   .' '0000' '4777'),PUT (T2.pref_agen_cdto, Z4.),t1.prefdep) AS PREFDEP,
          IFN (t1.cart=.,7002,t1.cart) AS CART,
		  t1.MCI_ANCORA, 
          t1.NOME_ANCORA, 
          t1.MCI_FORNECEDOR, 
          t1.NOME_FONECEDOR, 
          t1.SITUACAO, 
          t1.NR_ORD_CPR, 
          t1.VL_ORD_CPR, 
          t1.DT_VNCT_ORD_CPR, 
          t1.NR_SEQL_TAXA, 
          t1.NR_BCO_PGTO, 
          t1.CD_PRF_AG_PGTO, 
          t1.DV_AG_PGTO, 
          t1.NR_CT_PGTO, 
          t1.DV_CT_PGTO, 
		  T1.MVTO as mvto1,
           t1.mvto FORMAT DDMMYY10. AS MVTO
FROM ORDENS_FINAIS_ENC_HST t1 INNER JOIN tbls.BCN_PJ t2 ON (t1.MCI_FORNECEDOR=t2.MCI)
where mci_ancora NOT IN (100122685, 603378064, 205343430);
QUIT;


proc sql;
create table ANTECIPADAS_CART1_temp as
 select a.prefdep, a.cart, a.NR_ORD_CPR, a.mci as MCI_FORNECEDOR, 0 as MCI_ANCORA, a.VL_ORD_CPR, a.DT_EST_ORD_CPR format E8601DA10. as  mvto
from ANTECIPADAS_CART1 A left join ORDENS_FINAIS_ENC_HST B on (A.NR_ORD_CPR = b.NR_ORD_CPR) where b.NR_ORD_CPR = . order by 1,2;
quit; 



proc sql;
create table ordens_finais as 
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, MCI_ANCORA, VL_ORD_CPR, mvto
from ANTECIPADAS_CART1_temp 
union
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, MCI_ANCORA, VL_ORD_CPR, mvto
from ORDENS_FINAIS_ENC_HST;
quit;

DATA _NULL_; call symput('INICIO_ANT',(intnx('month',&diautil_d1, -1, 'begin')));run;
%PUT &INICIO_ANT;
DATA _NULL_; call symput('FIM_ANT',(intnx('month',&diautil_d1, -1, 'end')));run;
%PUT &FIM_ANT;

DATA _NULL_; call symput('INICIO',(intnx('month',&diautil_d1, 0, 'begin')));run;
%PUT &INICIO;
DATA _NULL_; call symput('FIM',(intnx('month',&diautil_d1, 0, 'end')));run;
%PUT &FIM;

proc sql;
	create table INICIO_MES AS 
		SELECT DISTINCT 
			CASE 
				WHEN MONTH (&diautil_d0)=1 THEN  '02JAN2017'D
				WHEN MONTH (&diautil_d0)=2 THEN  '01FEB2017'D
				WHEN MONTH (&diautil_d0)=3 THEN  '01MAR2017'D
				WHEN MONTH (&diautil_d0)=4 THEN  '03APR2017'D
				WHEN MONTH (&diautil_d0)=5 THEN  '02MAY2017'D
				WHEN MONTH (&diautil_d0)=6 THEN  '01JUN2017'D
				WHEN MONTH (&diautil_d0)=7 THEN  '03JUL2017'D
				WHEN MONTH (&diautil_d0)=8 THEN  '01AUG2017'D
				WHEN MONTH (&diautil_d0)=9 THEN  '01SEP2017'D
				WHEN MONTH (&diautil_d0)=10 THEN  '02OCT2017'D
				WHEN MONTH (&diautil_d0)=11 THEN  '01NOV2017'D
				WHEN MONTH (&diautil_d0)=12 THEN  '01DEC2017'D
			END 
			FOrMaT DDMMYY10. AS MES_ATU,
		CASE 
			WHEN CALCULATED MES_ATU='02jan2017'D THEN '01MAR2017'D
			WHEN CALCULATED MES_ATU='01FEB2017'D THEN '02JAN2017'D
			WHEN CALCULATED MES_ATU='01MAR2017'D THEN '01FEB2017'D
			WHEN CALCULATED MES_ATU='03APR2017'D THEN '01MAR2017'D
			WHEN CALCULATED MES_ATU='02MAY2017'D THEN '03APR2017'D
			WHEN CALCULATED MES_ATU='01JUN2017'D THEN '02MAY2017'D
			WHEN CALCULATED MES_ATU='03JUL2017'D THEN '01JUN2017'D
			WHEN CALCULATED MES_ATU='01AUG2017'D THEN '03JUL2017'D
			WHEN CALCULATED MES_ATU='01SEP2017'D THEN '01AUG2017'D
			WHEN CALCULATED MES_ATU='02OCT2017'D THEN '01SEP2017'D
			WHEN CALCULATED MES_ATU='01NOV2017'D THEN '02OCT2017'D
			WHEN CALCULATED MES_ATU='01DEC2017'D THEN '01NOV2017'D
		END 
		FOrMaT DDMMYY10. AS MES_ANT
	FROM rut.TBL_DATAS_PROCESSAMENTO;
QUIT;





PROC SQL;
   CREATE TABLE ORDENS_FINAIS_1 AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.mvto,
          t1.cart,
          t1.MCI_FORNECEDOR, 
		  T1.MCI_ANCORA,
		  t1.NR_ORD_CPR,
		  IFN (T1.MVTO=&INICIO_ANT,t1.VL_ORD_CPR,0) AS MES_ANT,
		  IFN (T1.MVTO=&INICIO,t1.VL_ORD_CPR,0) AS MES_ATU,
		  ifn (t1.mvto=&DiaUtil_D0,t1.VL_ORD_CPR,0) as disp_0,
          ifn (t1.mvto=&DiaUtil_D1,t1.VL_ORD_CPR,0) as disp_1,
		  ifn (t1.mvto=&DiaUtil_D2,t1.VL_ORD_CPR,0) as disp_2,
		  ifn (t1.mvto=&DiaUtil_D3,t1.VL_ORD_CPR,0) as disp_3,
		  ifn (t1.mvto=&DiaUtil_D4,t1.VL_ORD_CPR,0) as disp_4,
		  ifn (t1.mvto=&DiaUtil_D5,t1.VL_ORD_CPR,0) as disp_5
      FROM ordens_finais t1, INICIO_MES T2 
order by 1,2;
QUIT;

/*PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_ORDENS_FINAIS_1 AS 
   SELECT t1.PrefDep, 
          t1.cart, 
          t1.MCI_FORNECEDOR, 
          t1.disp_0, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5
      FROM WORK.ORDENS_FINAIS_1 t1,rut.TBL_DATAS_PROCESSAMENTO t2;
QUIT;*/


PROC SQL;
   CREATE TABLE ORDENS_FINAIS_MCI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
		  t1.MCI_FORNECEDOR,
		  t1.MCI_ANCORA,
		  disp_0
      FROM ORDENS_FINAIS_1 t1 
	  where t1.prefdep not in ('' '   .' '4777' '0000' '9940' '3868' '7058' '7006') 
	  and disp_0 ne 0
group by 1, 2, 3;
QUIT;



PROC SQL;
   CREATE TABLE ORDENS_FINAIS_1_1 AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.mvto,
          t1.cart,
          t1.MCI_FORNECEDOR, 
		  t1.NR_ORD_CPR,
		  IFN (T1.MVTO=&INICIO_ANT,t1.VL_ORD_CPR,0) AS MES_ANT,
		  IFN (T1.MVTO=&INICIO,t1.VL_ORD_CPR,0) AS MES_ATU,
		  ifn (t1.mvto=&DiaUtil_D0,t1.VL_ORD_CPR,0) as disp_0,
          ifn (t1.mvto=&DiaUtil_D1,t1.VL_ORD_CPR,0) as disp_1,
		  ifn (t1.mvto=&DiaUtil_D2,t1.VL_ORD_CPR,0) as disp_2,
		  ifn (t1.mvto=&DiaUtil_D3,t1.VL_ORD_CPR,0) as disp_3,
		  ifn (t1.mvto=&DiaUtil_D4,t1.VL_ORD_CPR,0) as disp_4,
		  ifn (t1.mvto=&DiaUtil_D5,t1.VL_ORD_CPR,0) as disp_5
      FROM ordens_finais t1, INICIO_MES T2 
order by 1,2;
QUIT;



PROC SQL;
   CREATE TABLE ORDENS_FINAIS_cart AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
		  sum (MES_ANT) as MES_ANT,
		  sum (MES_ATU) as MES_ATU,
		  sum (disp_0) as disp_0,
          sum (disp_1) as disp_1,
		  sum (disp_2) as disp_2,
		  sum (disp_3) as disp_3,
		  sum (disp_4) as disp_4,
		  sum (disp_5) as disp_5
      FROM ORDENS_FINAIS_1_1 t1 
	  where t1.prefdep not in ('' '   .' '4777' '0000' '9940' '3868' '7058' '7006') 
group by 1, 2;
QUIT;
%zerarmissingtabela (work.ORDENS_FINAIS_cart);

PROC SQL;
   CREATE TABLE ORDENS_FINAIS_CART_1 AS 
   SELECT DISTINCT t1.prefdep, 
          t1.cart, 
          t1.MES_ANT, 
          t1.MES_ATU, 
          t1.disp_0, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5,
		  CASE WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=2 THEN (disp_0)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=3 THEN (disp_1)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=4 THEN (disp_2)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=5 THEN (disp_3)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=6 THEN (disp_4)
		  END AS SEMANA
      FROM WORK.ORDENS_FINAIS_CART t1, rut.TBL_DATAS_PROCESSAMENTO E
WHERE E.DataMovimento>='01AUG2015'D having semana ne .;
QUIT;

PROC SQL;
   CREATE TABLE ORDENS_FINAIS_CART_2 AS 
   SELECT DISTINCT t1.prefdep, 
          t1.cart, 
          t1.MES_ANT, 
          t1.MES_ATU, 
          t1.disp_0, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5, 
          t1.SEMANA
      FROM WORK.ORDENS_FINAIS_CART_1 t1
      WHERE t1.SEMANA NOT = .;
QUIT;


PROC SQL;
   CREATE TABLE WORK.ORDENS_UNICAS_ENC_HST AS 
   SELECT DISTINCT put (t2.CD_PRF_DEPE, z4.) format $4. as PrefDep, 
          t2.NR_SEQL_CTRA as CART, mci_ancora,
          t1.NR_ORD_CPR, 
          t1.MCI_FORNECEDOR, 

          t1.VL_ORD_CPR,
		  t1.mvto,
		  CASE WHEN MONTH (&diautil_d0)=1 THEN  '04JAN2016'D
		  WHEN MONTH (&diautil_d0)=2 THEN  '01FEB2016'D
		  WHEN MONTH (&diautil_d0)=3 THEN  '01MAR2016'D
		  WHEN MONTH (&diautil_d0)=4 THEN  '01APR2016'D
		  WHEN MONTH (&diautil_d0)=5 THEN  '02MAY2016'D
		  WHEN MONTH (&diautil_d0)=6 THEN  '01JUN2016'D
		  WHEN MONTH (&diautil_d0)=7 THEN  '01JUL2016'D
		  WHEN MONTH (&diautil_d0)=8 THEN  '01AUG2016'D
		  WHEN MONTH (&diautil_d0)=9 THEN  '01SEP2016'D
		  WHEN MONTH (&diautil_d0)=10 THEN  '03OCT2016'D
		  WHEN MONTH (&diautil_d0)=11 THEN  '01NOV2016'D
		  WHEN MONTH (&diautil_d0)=12 THEN  '01DEC2016'D
END FOrMaT DDMMYY10. AS XX
      FROM AF.ORDENS_UNICAS_ENC_HST t1
	             LEFT JOIN rel.rel t2 ON (t1.MCI_FORNECEDOR = t2.CD_CLI)
where mci_ancora NOT IN (100122685, 603378064, 205343430/*, 903587815*/)
and calculated xx ne mvto
and t2.cd_tIp_ctra not in (321, 322, 323, 328);
QUIT;

/*
PROC SQL;
   CREATE TABLE WORK.ORDENS_UNICAS_ENC_HST_1 AS 
   SELECT DISTINCT ifc (t1.PrefDep in ('' '4777' '0000'),put (t2.pref_agen_cdto, z4.),t1.prefdep) as prefdep,
          t1.cart, 
          t1.NR_ORD_CPR, 
          t1.MCI_FORNECEDOR, 

          t1.VL_ORD_CPR,
		  t1.mvto
      FROM ORDENS_UNICAS_ENC_HST t1
	             INNER JOIN BCN.BCN_PJ t2 ON (t1.MCI_FORNECEDOR = t2.mci)
;
QUIT;
*/


PROC SQL;
CREATE TABLE ORDENS_UNICAS_ENC_HST AS 
SELECT IFC (t1.prefdep IN ('   .' '0000' '4777'),PUT (T2.pref_agen_cdto, Z4.),t1.prefdep) AS PREFDEP,
          IFN (t1.cart=.,7002,t1.cart) AS CART,
		  t1.MCI_ANCORA, 
          t1.NR_ORD_CPR, 
          t1.MCI_FORNECEDOR, 
          t1.VL_ORD_CPR, 
          t1.mvto, 
          t1.XX
FROM ORDENS_UNICAS_ENC_HST t1 
INNER JOIN tbls.BCN_PJ t2 ON (t1.MCI_FORNECEDOR=t2.MCI);
QUIT;

libname bcn clear;

PROC SQL;
CREATE TABLE APOIO_UNICAS AS 
SELECT PREFDEP, CART, NR_ORD_CPR, mci as MCI_FORNECEDOR
FROM Antecipadas_cart1
UNION 
SELECT PREFDEP, CART, NR_ORD_CPR, MCI_FORNECEDOR
FROM ORDENS_UNICAS_ENC_HST;
QUIT;




proc sql;
create table ordens_unicas as 
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, VL_ORD_CPR, mvto
from Antecipadas_cart1_temp
union
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, VL_ORD_CPR, mvto
from ORDENS_UNICAS_ENC_HST;
quit;

PROC SQL;
CREATE TABLE ordens_unicas_ AS 
SELECT  DISTINCT PREFDEP,
CART,
NR_ORD_CPR,
MCI_FORNECEDOR, 
VL_ORD_CPR, 
MIN (mvto) format E8601DA10. AS MVTO
FROM ordens_unicas
GROUP BY 1,2,3,4, 5;
QUIT;


PROC SQL;
   CREATE TABLE ORDENS_unicas_1 AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
		  t1.mvto,
		  t1.MCI_FORNECEDOR,
		  T1.NR_ORD_CPR,
		  t1.VL_ORD_CPR,
		  IFN (T1.MVTO= "&Posicao"D, T1.VL_ORD_CPR, 0) AS SEGUNDA,
          IFN (t1.mvto BETWEEN (intnx('month',&diautil_d0, 0, 'begin')) AND (intnx('month',&diautil_d0, 0, 'end')), T1.VL_ORD_CPR,0) AS VLR_MES_ATU,
		  IFN (t1.mvto BETWEEN INTNX('MONTH',TODAY(),-1) AND (INTNX('MONTH',TODAY(),0)-1), T1.VL_ORD_CPR,0) AS VLR_MES_ANT,
		  ifn (week (&diautil_d0)=week (mvto),T1.VL_ORD_CPR,0) as semana,
		  ifn (t1.mvto=&diautil_d1,T1.VL_ORD_CPR,0) as dia
      FROM ordens_unicas_ t1
	  where t1.prefdep not in ('' '   .' '4777' '0000' '9940' '3868' '7058' '7006' '7414' '7057')
group by 1, 2;
QUIT;
%zerarmissingtabela (work.ORDENS_unicas_1);


PROC SQL;
   CREATE TABLE ORDENS_UNICAS_cart AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.cart, 
            (SUM(t1.VLR_MES_ATU)) AS VLR_MES_ATU, 
			sum (t1.VLR_MES_ANT) as VLR_MES_ANT,
            (SUM(t1.semana)) AS semana,
			sum (t1.dia) as dia
      FROM WORK.ORDENS_UNICAS_1 t1

      GROUP BY t1.PrefDep,
               t1.cart;
QUIT;

%zerarmissingtabela (work.ORDENS_unicas_cart);



PROC SQL;
   CREATE TABLE ORDENS_UNICAS_CART_1 AS 
   SELECT DISTINCT t1.prefdep, 
          t1.cart, 
          t1.VLR_MES_ATU, 
          t1.VLR_MES_ANT, 
          T1.SEMANA,
          t1.dia
      FROM WORK.ORDENS_UNICAS_CART t1, rut.TBL_DATAS_PROCESSAMENTO E
WHERE E.DataMovimento>='01AUG2015'D;
QUIT;


proc sql;
create table apoio_cart as 
select distinct prefdep, cart
from ORDENS_FINAIS_CART_2
union 
select distinct prefdep, cart
from CART
union 
select distinct prefdep, cart
from ORDENS_UNICAS_CART_1;
quit;


proc sql;
	create table AF.FIM_CART_1 AS 
		SELECT DISTINCT A.PREFDEP,
			A.CART,
			B.VLR_TOTAL,
			B.VLR_MES_ATU,
			B.VLR_MES_ANT,
			B.VLR_D_1,
			B.VLR_D_2,
			B.VLR_D_3,
			B.VLR_D_4,
			B.VLR_D_5,
			C.disp_1,
			C.disp_2,
			C.disp_3,
			C.disp_4,
			C.disp_5,
			b.semana as vlr_semana,
  			ifn ("&Posicao"d=&diautil_d0,c.SEMANA, (IFN (C.SEMANA=.,0,C.SEMANA)+IFN (D.SEMANA=.,0,D.SEMANA))) AS SEMANA,
			IFN (d.VLR_MES_ATU=.,0,d.VLR_MES_ATU)+IFN (C.MES_Atu=.,0,C.MES_Atu) as mes,
			IFN (d.VLR_MES_ANT=.,0,d.VLR_MES_ANT)+IFN (C.MES_ANT=.,0,C.MES_ANT) as mes_ant,
			C.disp_0 AS DIA
		FROM APOIO_CART A
			LEFT JOIN CART B ON (A.PREFDEP=B.PREFDEP AND A.CART=B.CART)
			LEFT JOIN ORDENS_FINAIS_CART_2 C ON (A.PREFDEP=C.PREFDEP AND A.CART=C.CART)
			LEFT JOIN ORDENS_UNICAS_CART_1 d ON (A.PREFDEP=d.PREFDEP AND A.CART=d.CART)/*, rut.TBL_DATAS_PROCESSAMENTO E
WHERE E.DataMovimento>='01AUG2015'D*/;
QUIT;
%zerarmissingtabela (AF.fim_cart_1);

PROC SQL;
   CREATE TABLE FIM_AG AS 
   SELECT DISTINCT t1.PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM AF.FIM_CART_1 t1
GROUP BY 1;
QUIT;

PROC FORMAT;
	VALUE NM 1='jan' 2='fev' 3='mar' 4='abr' 5='mai' 6='jun' 7='jul' 8='ago' 9='set' 10='out' 11='nov' 12='dez';
RUN;

DATA _NULL_;
	CALL SYMPUT('MCR',Month(Today()) NE Month(&DiaUtil_D1));
	CALL SYMPUT('RFM',Put(Month(&DiaUtil_D1), NM.));
	CALL SYMPUT('RFA',Put(Month(IntNx('month',&DiaUtil_D1,-1)), NM.));
RUN;



%macro fim_mes;
	%if &MCR=1 %then
		%do;

			data af.fim_ag_&RFA;
				set af.fim_ag_ant;
			run;

			data af.fim_ag_ant;
			set fim_ag;
			run;

		%end;
%mend;

%fim_mes;


proc sql;
	create table apoio_ag as 
		select prefdep
			from fim_ag
				union
			select prefdep
				from af.fim_ag_ant;
quit;


proc sql;
create table fim_ag_1 as 
select a.prefdep,
0 as cart,
b.VLR_TOTAL,
b.VLR_MES_ATU,
c.VLR_MES_ANT,
b.VLR_D_1,
b.VLR_D_2,
b.VLR_D_3,
b.VLR_D_4,
b.VLR_D_5,
ifn (B.disp_1<b.VLR_D_1,b.VLR_D_1,B.disp_1) as disp_1,
ifn (B.disp_2<b.VLR_D_2,b.VLR_D_2,B.disp_2) as disp_2,
ifn (B.disp_3<b.VLR_D_3,b.VLR_D_3,B.disp_3) as disp_3,
ifn (B.disp_4<b.VLR_D_4,b.VLR_D_4,B.disp_4) as disp_4,
ifn (B.disp_5<b.VLR_D_5,b.VLR_D_5,B.disp_5) as disp_5,
b.vlr_semana,
b.semana,
ifn (b.mes<b.VLR_MES_ATU,b.VLR_MES_ATU,b.mes) as mes,
c.mes_ant,
b.dia
from apoio_ag a left join fim_ag b on (a.prefdep=b.prefdep)
left join af.fim_ag_ant c on (a.prefdep=c.prefdep)
where a.prefdep not in ('' '   .' '4777' '0000' '9940' '3868' '7058' '7006' '7414' '7057');
quit;



PROC SQL;
	CREATE TABLE AUX_DEPENDENCIAS AS 
		SELECT I.PrefDep, 
			TRIM(IFC(TipoDep='39','SUPER '||N.NomeDep,I.NomeDep)) Format $33. AS NomeDep, 
			IFC(I.TipoDep='99' AND I.PrefDep NE '8166','8',I.NivelDep) AS NivelDep, 
			IFC(I.TipoDep='99','39',I.TipoDep) AS Tipo, 
			I.PrefSupReg, I.PrefSupEst, I.PrefUEN, '8166' AS VP, 
			IFC(I.TipoDep='99','8166',
			IFC(I.TipoDep='39',PrefUEN,IFC(I.TipoDep='29' OR PrefSupReg='0000',PrefSupEst,PrefSupReg))) AS PrefPai, 
			'V' AS Mercado
		FROM IGR.IGRREDE I 
			LEFT JOIN IGR.IGRNivel N ON(I.PrefDep=N.PrefDep)
				WHERE TipoDep In('01' '09' '29' '39' '99') AND I.PrefDep Not In('TTBB' '9978');
QUIT;

DATA AUX_DEPE(DROP=SB)/VIEW=AUX_DEPE;
	SET IGR.DEPENDENCIAS(WHERE=(SB='00'));
RUN;

PROC SQL;
	CREATE TABLE AUX_DEPENDENCIAS_A AS 
		SELECT I.PrefDep, NomeDep, 
			IFC(I.TipoDep='023','C',IFC(I.TipoDep='002','B','A'||I.Nivel)) AS NivelDep, 
			IFC(I.TipoDep In('023','002'),'004',I.TipoDep) AS TipoDep, 
			I.PrefSureg AS PrefSupReg, I.PrefSuper AS PrefSupEst, I.PrefDir AS PrefUEN, PrefVice AS VP, 
			IFC(I.TipoDep='002',PrefVice,
			IFC(I.TipoDep='004',PrefDir,IFC(I.TipoDep='003' OR PrefSureg='0000',PrefSuper,PrefSureg))) AS PrefPai,
			'A' AS Mercado
		FROM AUX_DEPE I
			ORDER BY 1;
	DELETE FROM AUX_DEPENDENCIAS_A
		WHERE PrefDep In(SELECT PrefDep FROM IGR.IGRREDE);
	DROP VIEW AUX_DEPE;
	
QUIT;

DATA AUX_DEPENDENCIAS_A(DROP=TipoDep);
	SET AUX_DEPENDENCIAS_A(WHERE=(TipoDep In('003' '004' '013' '015' '034')));

	IF TipoDep='013' THEN
		Tipo='09';
	ELSE IF TipoDep='015' THEN
		Tipo='01';
	ELSE IF TipoDep='003' THEN
		Tipo='29';
	ELSE IF TipoDep='034' THEN
		Tipo='34';
	ELSE Tipo='39';
RUN;

DATA AUX_DEPENDENCIAS;
	SET AUX_DEPENDENCIAS AUX_DEPENDENCIAS_A;
	BY PrefDep;
RUN;


PROC SQL;
   CREATE TABLE FIM_GRV AS 
   SELECT DISTINCT PREFSUPREG AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1 t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;



PROC SQL;
   CREATE TABLE FIM_SUP AS 
   SELECT DISTINCT PREFSUPEST AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1 t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;



PROC SQL;
   CREATE TABLE FIM_UEN AS 
   SELECT DISTINCT PREFUEN AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1 t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;


PROC SQL;
   CREATE TABLE FIM_VP AS 
   SELECT DISTINCT VP AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1 t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;

PROC SQL;
   CREATE TABLE FIM_brasil AS 
   SELECT DISTINCT '9999' AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_vp t1
	  
GROUP BY 1;
QUIT;


DATA BASE;
SET FIM_AG_1 FIM_GRV FIM_SUP FIM_UEN FIM_VP FIM_BRASIL;
BY PREFDEP;
efetiv_mes_ant=VLR_MES_ANT/mes_ant*100;
efetiv_mes_atu=VLR_MES_ATU/mes*100;
efetiv_semana=vlr_semana/semana*100;
mvto=Put(&DiaUtil_D1, yymmdd10.);
WHERE PREFDEP NE '0000';
RUN;


DATA BASE_1 ;
MERGE AUX_DEPENDENCIAS BASE;
BY PREFDEP;
RUN;
%zerarmissingtabela (WORK.BASE_1);


DATA BASE_FIM;
	SET BASE_1;

	IF CART NE 0 THEN
		DO;	
			PrefPai=Prefdep;
			Tipo='89';
			NivelDep='0';
		END;
		WHERE VLR_TOTAL+mes+MES_ANT NE 0;
RUN;

PROC SQL;
   CREATE TABLE BASE_FIM_1 AS 
   SELECT DISTINCT t1.PrefDep, 
          IFC (t1.NomeDep='','BRASIL', t1.NomeDep) AS NomeDep,
          IFC (t1.NivelDep='', 'D', t1.NivelDep) AS NivelDep,
          IFC (t1.Tipo='', '39',T1.TIPO) AS TIPO,
          t1.PrefSupReg, 
          t1.PrefSupEst, 
          t1.PrefUEN, 
          t1.VP, 
          t1.PrefPai,           
          t1.cart, 
		  'TODOS OS ÂNCORAS' as ancora,
          t1.VLR_TOTAL, 
          t1.VLR_MES_ATU, 
          t1.VLR_MES_ANT, 
          t1.VLR_D_1, 
          t1.VLR_D_2, 
          t1.VLR_D_3, 
          t1.VLR_D_4, 
          t1.VLR_D_5, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5, 
          t1.vlr_semana, 
          t1.semana, 
          t1.mes, 
		  t1.mes_ant,
		  t1.dia,
		  t1.efetiv_mes_ant,
		  t1.efetiv_mes_atu,
		  t1.efetiv_semana,
		  ifn (t1.Mercado IN ('A' ''),1,0) AS SEQ, 
          t1.mvto
      FROM WORK.BASE_FIM t1
WHERE PREFDEP NOT IN ('1966' '   .' '4904');
QUIT;

DATA BASE_FIM_2 (DROP=ANCORA);
SET BASE_FIM_1;
RUN;


PROC 	EXPORT DATA=BASE_FIM_2 OUTFILE="/dados/infor/producao/AF/Dados_saida/base_rpt_fim.txt" DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;

PROC SORT DATA=BASE_FIM_1(WHERE=(PrefDep IN('8166' '8477' '8592' '9867' '8590' '8069' '9999'))) OUT=AF.BASE_PLANILHA(KEEP=NomeDep VLR_MES_ATU VLR_MES_ANT VLR_D_1 DISP_1 VLR_SEMANA SEMANA MES MES_ANT DIA EFETIV_MES_ANT EFETIV_MES_ATU EFETIV_SEMANA);
	BY NomeDep;
RUN;

PROC SQL;
   CREATE TABLE QTD_ANCORA_FORNECEDOR_UEN AS 
   SELECT DISTINCT t2.PrefUEN AS PrefDep, 
		  COUNT (DISTINCT t1.MCI_FORNECEDOR) AS QTD_FORNECEDOR,
		  COUNT (DISTINCT t1.MCI_ANCORA) AS QTD_ANCORA
      FROM ORDENS_FINAIS_MCI t1 
	  INNER JOIN WORK.AUX_DEPENDENCIAS t2 ON (t1.PrefDep = t2.PrefDep)
      GROUP BY 1
               ;
QUIT;

PROC SQL;
   CREATE TABLE QTD_ANCORA_FORNECEDOR_VP AS 
   SELECT DISTINCT t2.VP AS PrefDep,
		  COUNT (DISTINCT t1.MCI_FORNECEDOR) AS QTD_FORNECEDOR,
		  COUNT (DISTINCT t1.MCI_ANCORA) AS QTD_ANCORA
      FROM ORDENS_FINAIS_MCI t1 
	  INNER JOIN WORK.AUX_DEPENDENCIAS t2 ON (t1.PrefDep = t2.PrefDep)
      GROUP BY 1
               ;
QUIT;

PROC SQL;
   CREATE TABLE QTD_ANCORA_FORNECEDOR_BRASIL AS 
   SELECT DISTINCT '9999' AS PrefDep, 
		  COUNT (DISTINCT t1.MCI_FORNECEDOR) AS QTD_FORNECEDOR,
		  COUNT (DISTINCT t1.MCI_ANCORA) AS QTD_ANCORA
      FROM ORDENS_FINAIS_MCI t1 
	  INNER JOIN WORK.AUX_DEPENDENCIAS t2 ON (t1.PrefDep = t2.PrefDep)
      GROUP BY 1
               ;
QUIT;




DATA QTD_ANCORA_FORNECEDOR_1;
SET QTD_ANCORA_FORNECEDOR_UEN QTD_ANCORA_FORNECEDOR_VP QTD_ANCORA_FORNECEDOR_BRASIL;
RUN;

PROC SQL;
   CREATE TABLE AF.QTD_ANCORA_FORNECEDOR AS 
   SELECT DISTINCT IFC (t2.NomeDep='','BRASIL',T2.NOMEDEP) AS NOMEDEP, 
          t1.QTD_FORNECEDOR, 
          t1.QTD_ANCORA
      FROM WORK.QTD_ANCORA_FORNECEDOR_1 t1
           LEFT JOIN WORK.AUX_DEPENDENCIAS t2 ON (t1.PrefDep = t2.PrefDep);
QUIT;

/*
PROC SQL;
   CREATE TABLE SALDO_AF AS 
   SELECT &AnoMes as mes,
            t1.SALDO FORMAT=19.2 AS SALDO
      FROM AF.SALDO_AF t1;
QUIT;
*/

x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate af_2" ;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/AF/Dados_saida/base_rpt_fim.txt' INTO TABLE af_2 FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' ;";
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="update posicoes set posicao = if(Weekday(date(now())) = 0 ,date(date(now())-3),date(date(now())-1)) where xml = 'af_relatorio';";




data af.ANTECIPADAS_CART1;
set  ANTECIPADAS_CART1;
run;


PROC SQL;
   CREATE TABLE ANTECIPADAS_CART1_CASSI AS 
   SELECT DISTINCT IFC (t1.prefdep IN ('   .' '0000' '4777'),PUT (T2.pref_agen_cdto, Z4.),t1.prefdep) AS PREFDEP,
   		IFN (T1.TP_CART=.,700,T1.TP_CART) AS TP_CART,
          IFN (t1.cart=.,7002,t1.cart) AS CART, t1.mci_ancora, 
          t1.DT_EST_ORD_CPR, 
          t1.NR_ORD_CPR, 
          t1.mci, 
          t1.VL_ORD_CPR, 
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF, 
          
          t2.nr_carteira
      FROM WORK.ANTECIPADAS_CART t1
           INNER JOIN TBLS.BCN_PJ t2 ON (t1.mci = t2.mci)
		   WHERE t1.PREFDEP NE '9940' and mci_ancora ne 903587815
order by 1, 2, 5;
QUIT;



PROC SQL;
   CREATE TABLE CART_1_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.cart, t1.mci_ancora, 
          t1.DT_EST_ORD_CPR, 
          t1.mci, 
		  t1.NR_ORD_CPR,
          t1.VL_ORD_CPR, 
		  ifn (week (&diautil_d0)=week (DT_EST_ORD_CPR),T1.VL_ORD_CPR,0) as semana,
		  IFN (t1.DT_EST_ORD_CPR BETWEEN (intnx('month',&diautil_d0, 0, 'begin')) AND (intnx('month',&diautil_d0, 0, 'end')), T1.VL_ORD_CPR,0) AS VLR_MES_ATU,
		  IFN (t1.DT_EST_ORD_CPR BETWEEN INTNX('MONTH',TODAY(),-1) AND (INTNX('MONTH',TODAY(),0)-1), T1.VL_ORD_CPR,0) AS VLR_MES_ANT,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D1,T1.VL_ORD_CPR,0) AS VLR_D_1,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D2,T1.VL_ORD_CPR,0) AS VLR_D_2,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D3,T1.VL_ORD_CPR,0) AS VLR_D_3,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D4,T1.VL_ORD_CPR,0) AS VLR_D_4,
		  IFN (t1.DT_EST_ORD_CPR=&DiaUtil_D5,T1.VL_ORD_CPR,0) AS VLR_D_5,
          t1.VL_ORD_CPR_AGDT, 
          t1.NR_IDFR_FRNC_SRF
      FROM ANTECIPADAS_CART1_CASSI t1
           WHERE PREFDEP Not in ('9940' '3868' '7058' '7006') ;
QUIT;

PROC SQL;
   CREATE TABLE CART_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.cart, 
          SUM (t1.VL_ORD_CPR) AS VLR_TOTAL, 
		  sum (t1.semana) as semana,
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5
      FROM WORK.CART_1_CASSI t1
GROUP BY 1, 2;
QUIT;


PROC SQL;
CREATE TABLE ORDENS_FINAIS_ENC_HST_CASSI AS 
SELECT a.* 
FROM ORDENS_FINAIS_ENC_HST A INNER JOIN tbls.BCN_PJ B ON (A.MCI_FORNECEDOR=B.MCI)
where mci_ancora NOT IN (100122685, 603378064, 205343430, 903587815);
QUIT;


proc sql;
create table ANTECIPADAS_CART1_temp_CASSI as
 select a.prefdep, a.cart, a.NR_ORD_CPR, a.mci as MCI_FORNECEDOR, 0 as MCI_ANCORA, a.VL_ORD_CPR, a.DT_EST_ORD_CPR format E8601DA10. as  mvto
from ANTECIPADAS_CART1_CASSI A left join ORDENS_FINAIS_ENC_HST_CASSI B on (A.NR_ORD_CPR = b.NR_ORD_CPR) where b.NR_ORD_CPR = . order by 1,2;
quit; 



proc sql;
create table ordens_finais_CASSI as 
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, MCI_ANCORA, VL_ORD_CPR, mvto
from ANTECIPADAS_CART1_temp_CASSI 
union
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, MCI_ANCORA, VL_ORD_CPR, mvto
from ORDENS_FINAIS_ENC_HST_CASSI;
quit;

PROC SQL;
   CREATE TABLE ORDENS_FINAIS_1_1_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.mvto,
          t1.cart,
          t1.MCI_FORNECEDOR, 
		  t1.NR_ORD_CPR,
		  IFN (T1.MVTO=&INICIO_ANT,t1.VL_ORD_CPR,0) AS MES_ANT,
		  IFN (T1.MVTO=&INICIO,t1.VL_ORD_CPR,0) AS MES_ATU,
		  ifn (t1.mvto=&DiaUtil_D0,t1.VL_ORD_CPR,0) as disp_0,
          ifn (t1.mvto=&DiaUtil_D1,t1.VL_ORD_CPR,0) as disp_1,
		  ifn (t1.mvto=&DiaUtil_D2,t1.VL_ORD_CPR,0) as disp_2,
		  ifn (t1.mvto=&DiaUtil_D3,t1.VL_ORD_CPR,0) as disp_3,
		  ifn (t1.mvto=&DiaUtil_D4,t1.VL_ORD_CPR,0) as disp_4,
		  ifn (t1.mvto=&DiaUtil_D5,t1.VL_ORD_CPR,0) as disp_5
      FROM ordens_finais_CASSI t1, INICIO_MES T2 
order by 1,2;
QUIT;



PROC SQL;
   CREATE TABLE ORDENS_FINAIS_cart_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
		  sum (MES_ANT) as MES_ANT,
		  sum (MES_ATU) as MES_ATU,
		  sum (disp_0) as disp_0,
          sum (disp_1) as disp_1,
		  sum (disp_2) as disp_2,
		  sum (disp_3) as disp_3,
		  sum (disp_4) as disp_4,
		  sum (disp_5) as disp_5
      FROM ORDENS_FINAIS_1_1_CASSI t1 
	  where t1.prefdep not in ('' '   .' '4777' '0000' '9940' '3868' '7058' '7006') 
group by 1, 2;
QUIT;
%zerarmissingtabela (work.ORDENS_FINAIS_cart_CASSI);

PROC SQL;
   CREATE TABLE ORDENS_FINAIS_CART_1_CASSI AS 
   SELECT DISTINCT t1.prefdep, 
          t1.cart, 
          t1.MES_ANT, 
          t1.MES_ATU, 
          t1.disp_0, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5,
		  CASE WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=2 THEN (disp_0)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=3 THEN (disp_1)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=4 THEN (disp_2)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=5 THEN (disp_3)
		  WHEN &DiaUtil_D0=E.DataMovimento AND E.dia_da_semana_cod=6 THEN (disp_4)
		  END AS SEMANA
      FROM WORK.ORDENS_FINAIS_CART_CASSI t1, rut.TBL_DATAS_PROCESSAMENTO E
WHERE E.DataMovimento>='01AUG2015'D having semana ne .;
QUIT;

PROC SQL;
   CREATE TABLE ORDENS_FINAIS_CART_2_CASSI AS 
   SELECT DISTINCT t1.prefdep, 
          t1.cart, 
          t1.MES_ANT, 
          t1.MES_ATU, 
          t1.disp_0, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5, 
          t1.SEMANA
      FROM WORK.ORDENS_FINAIS_CART_1_CASSI t1
      WHERE t1.SEMANA NOT = .;
QUIT;


PROC SQL;
CREATE TABLE ORDENS_UNICAS_ENC_HST_CASSI AS 
SELECT a.* 
FROM ORDENS_UNICAS_ENC_HST A 
INNER JOIN tbls.BCN_PJ B ON (A.MCI_FORNECEDOR=B.MCI)
where mci_ancora NOT IN (100122685, 603378064, 205343430, 903587815);
QUIT;

libname bcn clear;

PROC SQL;
CREATE TABLE APOIO_UNICAS_CASSI AS 
SELECT PREFDEP, CART, NR_ORD_CPR, mci as MCI_FORNECEDOR
FROM Antecipadas_cart1_CASSI
UNION 
SELECT PREFDEP, CART, NR_ORD_CPR, MCI_FORNECEDOR
FROM ORDENS_UNICAS_ENC_HST_CASSI;
QUIT;




proc sql;
create table ordens_unicas_CASSI as 
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, VL_ORD_CPR, mvto
from Antecipadas_cart1_TEMP_CASSI
union
select prefdep, cart, NR_ORD_CPR, MCI_FORNECEDOR, VL_ORD_CPR, mvto
from ORDENS_UNICAS_ENC_HST_CASSI;
quit;

PROC SQL;
CREATE TABLE ordens_unicas__CASSI AS 
SELECT  DISTINCT PREFDEP,
CART,
NR_ORD_CPR,
MCI_FORNECEDOR, 
VL_ORD_CPR, 
MIN (mvto) format E8601DA10. AS MVTO
FROM ordens_unicas_CASSI
GROUP BY 1,2,3,4, 5;
QUIT;


PROC SQL;
   CREATE TABLE ORDENS_unicas_1_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.CART, 
		  t1.mvto,
		  t1.MCI_FORNECEDOR,
		  T1.NR_ORD_CPR,
		  t1.VL_ORD_CPR,
		  IFN (T1.MVTO= "&Posicao"D, T1.VL_ORD_CPR, 0) AS SEGUNDA,
          IFN (t1.mvto BETWEEN (intnx('month',&diautil_d0, 0, 'begin')) AND (intnx('month',&diautil_d0, 0, 'end')), T1.VL_ORD_CPR,0) AS VLR_MES_ATU,
		  IFN (t1.mvto BETWEEN INTNX('MONTH',TODAY(),-1) AND (INTNX('MONTH',TODAY(),0)-1), T1.VL_ORD_CPR,0) AS VLR_MES_ANT,
		  ifn (week (&diautil_d0)=week (mvto),T1.VL_ORD_CPR,0) as semana,
		  ifn (t1.mvto=&diautil_d1,T1.VL_ORD_CPR,0) as dia
      FROM ordens_unicas__CASSI t1
	  where t1.prefdep not in ('' '   .' '4777' '0000' '9940' '3868' '7058' '7006')
group by 1, 2;
QUIT;
%zerarmissingtabela (work.ORDENS_unicas_1_CASSI);


PROC SQL;
   CREATE TABLE ORDENS_UNICAS_cart_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          t1.cart, 
            (SUM(t1.VLR_MES_ATU)) AS VLR_MES_ATU, 
			sum (t1.VLR_MES_ANT) as VLR_MES_ANT,
            (SUM(t1.semana)) AS semana,
			sum (t1.dia) as dia
      FROM WORK.ORDENS_UNICAS_1_CASSI t1

      GROUP BY t1.PrefDep,
               t1.cart;
QUIT;

%zerarmissingtabela (work.ORDENS_unicas_cart_CASSI);



PROC SQL;
   CREATE TABLE ORDENS_UNICAS_CART_1_CASSI AS 
   SELECT DISTINCT t1.prefdep, 
          t1.cart, 
          t1.VLR_MES_ATU, 
          t1.VLR_MES_ANT, 
          T1.SEMANA,
          t1.dia
      FROM WORK.ORDENS_UNICAS_CART_CASSI t1, rut.TBL_DATAS_PROCESSAMENTO E
WHERE E.DataMovimento>='01AUG2015'D;
QUIT;


proc sql;
create table apoio_cart_CASSI as 
select distinct prefdep, cart
from ORDENS_FINAIS_CART_2_CASSI
union 
select distinct prefdep, cart
from CART_CASSI
union 
select distinct prefdep, cart
from ORDENS_UNICAS_CART_1_CASSI;
quit;


proc sql;
	create table AF.FIM_CART_1_CASSI AS 
		SELECT DISTINCT A.PREFDEP,
			A.CART,
			B.VLR_TOTAL,
			B.VLR_MES_ATU,
			B.VLR_MES_ANT,
			B.VLR_D_1,
			B.VLR_D_2,
			B.VLR_D_3,
			B.VLR_D_4,
			B.VLR_D_5,
			C.disp_1,
			C.disp_2,
			C.disp_3,
			C.disp_4,
			C.disp_5,
			b.semana as vlr_semana,
  			ifn ("&Posicao"d=&diautil_d0,c.SEMANA, (IFN (C.SEMANA=.,0,C.SEMANA)+IFN (D.SEMANA=.,0,D.SEMANA))) AS SEMANA,
			IFN (d.VLR_MES_ATU=.,0,d.VLR_MES_ATU)+IFN (C.MES_Atu=.,0,C.MES_Atu) as mes,
			IFN (d.VLR_MES_ANT=.,0,d.VLR_MES_ANT)+IFN (C.MES_ANT=.,0,C.MES_ANT) as mes_ant,
			C.disp_0 AS DIA
		FROM APOIO_CART_CASSI A
			LEFT JOIN CART_CASSI B ON (A.PREFDEP=B.PREFDEP AND A.CART=B.CART)
			LEFT JOIN ORDENS_FINAIS_CART_2_CASSI C ON (A.PREFDEP=C.PREFDEP AND A.CART=C.CART)
			LEFT JOIN ORDENS_UNICAS_CART_1_CASSI d ON (A.PREFDEP=d.PREFDEP AND A.CART=d.CART)/*, rutTBL_DATAS_PROCESSAMENTO E
WHERE E.DataMovimento>='01AUG2015'D*/;
QUIT;
%zerarmissingtabela (AF.fim_cart_1_CASSI);

PROC SQL;
   CREATE TABLE FIM_AG_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM AF.FIM_CART_1_CASSI t1
GROUP BY 1;
QUIT;

PROC FORMAT;
	VALUE NM 1='jan' 2='fev' 3='mar' 4='abr' 5='mai' 6='jun' 7='jul' 8='ago' 9='set' 10='out' 11='nov' 12='dez';
RUN;

DATA _NULL_;
	CALL SYMPUT('MCR',Month(Today()) NE Month(&DiaUtil_D1));
	CALL SYMPUT('RFM',Put(Month(&DiaUtil_D1), NM.));
	CALL SYMPUT('RFA',Put(Month(IntNx('month',&DiaUtil_D1,-1)), NM.));
RUN;



%macro fim_mes;
	%if &MCR=1 %then
		%do;

			data af.fim_ag_&RFA_CASSI;
				set af.fim_ag_ant_CASSI;
			run;

			data af.fim_ag_ant_CASSI;
			set fim_ag_CASSI;
			run;

		%end;
%mend;

%fim_mes;


proc sql;
	create table apoio_ag_CASSI as 
		select prefdep
			from fim_ag_CASSI
				union
			select prefdep
				from af.fim_ag_ant_CASSI;
quit;


proc sql;
create table fim_ag_1_CASSI as 
select a.prefdep,
0 as cart,
b.VLR_TOTAL,
b.VLR_MES_ATU,
c.VLR_MES_ANT,
b.VLR_D_1,
b.VLR_D_2,
b.VLR_D_3,
b.VLR_D_4,
b.VLR_D_5,
ifn (B.disp_1<b.VLR_D_1,b.VLR_D_1,B.disp_1) as disp_1,
ifn (B.disp_2<b.VLR_D_2,b.VLR_D_2,B.disp_2) as disp_2,
ifn (B.disp_3<b.VLR_D_3,b.VLR_D_3,B.disp_3) as disp_3,
ifn (B.disp_4<b.VLR_D_4,b.VLR_D_4,B.disp_4) as disp_4,
ifn (B.disp_5<b.VLR_D_5,b.VLR_D_5,B.disp_5) as disp_5,
b.vlr_semana,
b.semana,
ifn (b.mes<b.VLR_MES_ATU,b.VLR_MES_ATU,b.mes) as mes,
c.mes_ant,
b.dia
from apoio_ag_CASSI a left join fim_ag_cassi b on (a.prefdep=b.prefdep)
left join af.fim_ag_ant_CASSI c on (a.prefdep=c.prefdep);
quit;



PROC SQL;
	CREATE TABLE AUX_DEPENDENCIAS AS 
		SELECT I.PrefDep, 
			TRIM(IFC(TipoDep='39','SUPER '||N.NomeDep,I.NomeDep)) Format $33. AS NomeDep, 
			IFC(I.TipoDep='99' AND I.PrefDep NE '8166','8',I.NivelDep) AS NivelDep, 
			IFC(I.TipoDep='99','39',I.TipoDep) AS Tipo, 
			I.PrefSupReg, I.PrefSupEst, I.PrefUEN, '8166' AS VP, 
			IFC(I.TipoDep='99','8166',
			IFC(I.TipoDep='39',PrefUEN,IFC(I.TipoDep='29' OR PrefSupReg='0000',PrefSupEst,PrefSupReg))) AS PrefPai, 
			'V' AS Mercado
		FROM IGR.IGRREDE I 
			LEFT JOIN IGR.IGRNivel N ON(I.PrefDep=N.PrefDep)
				WHERE TipoDep In('01' '09' '29' '39' '99') AND I.PrefDep Not In('TTBB' '9978');
QUIT;

DATA AUX_DEPE(DROP=SB)/VIEW=AUX_DEPE;
	SET IGR.DEPENDENCIAS(WHERE=(SB='00'));
RUN;

PROC SQL;
	CREATE TABLE AUX_DEPENDENCIAS_A AS 
		SELECT I.PrefDep, NomeDep, 
			IFC(I.TipoDep='023','C',IFC(I.TipoDep='002','B','A'||I.Nivel)) AS NivelDep, 
			IFC(I.TipoDep In('023','002'),'004',I.TipoDep) AS TipoDep, 
			I.PrefSureg AS PrefSupReg, I.PrefSuper AS PrefSupEst, I.PrefDir AS PrefUEN, PrefVice AS VP, 
			IFC(I.TipoDep='002',PrefVice,
			IFC(I.TipoDep='004',PrefDir,IFC(I.TipoDep='003' OR PrefSureg='0000',PrefSuper,PrefSureg))) AS PrefPai,
			'A' AS Mercado
		FROM AUX_DEPE I
			ORDER BY 1;
	DELETE FROM AUX_DEPENDENCIAS_A
		WHERE PrefDep In(SELECT PrefDep FROM IGR.IGRREDE);
	DROP VIEW AUX_DEPE;
	
QUIT;

DATA AUX_DEPENDENCIAS_A(DROP=TipoDep);
	SET AUX_DEPENDENCIAS_A(WHERE=(TipoDep In('003' '004' '013' '015' '034')));

	IF TipoDep='013' THEN
		Tipo='09';
	ELSE IF TipoDep='015' THEN
		Tipo='01';
	ELSE IF TipoDep='003' THEN
		Tipo='29';
	ELSE IF TipoDep='034' THEN
		Tipo='34';
	ELSE Tipo='39';
RUN;

DATA AUX_DEPENDENCIAS;
	SET AUX_DEPENDENCIAS AUX_DEPENDENCIAS_A;
	BY PrefDep;
RUN;


PROC SQL;
   CREATE TABLE FIM_GRV_CASSI AS 
   SELECT DISTINCT PREFSUPREG AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1_CASSI t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;



PROC SQL;
   CREATE TABLE FIM_SUP_CASSI AS 
   SELECT DISTINCT PREFSUPEST AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1_CASSI t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;



PROC SQL;
   CREATE TABLE FIM_UEN_CASSI AS 
   SELECT DISTINCT PREFUEN AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1_CASSI t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;


PROC SQL;
   CREATE TABLE FIM_VP_CASSI AS 
   SELECT DISTINCT VP AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_AG_1_CASSI t1 inner join AUX_DEPENDENCIAS t2 on (T1.prefdep=T2.prefdep)
	  where t1.prefdep not in ('7058' '7006' '3868')
GROUP BY 1;
QUIT;

PROC SQL;
   CREATE TABLE FIM_brasil_CASSI AS 
   SELECT DISTINCT '9999' AS PrefDep, 
          0 AS cart, 
          SUM (t1.VLR_TOTAL) AS VLR_TOTAL, 
          SUM (t1.VLR_MES_ATU) AS VLR_MES_ATU,
		  SUM (T1.VLR_MES_ANT) AS VLR_MES_ANT,
		  SUM (VLR_D_1) AS VLR_D_1,
		  SUM (VLR_D_2) AS VLR_D_2,
		  SUM (VLR_D_3) AS VLR_D_3,
		  SUM (VLR_D_4) AS VLR_D_4,
		  SUM (VLR_D_5) AS VLR_D_5,
		  SUM (disp_1) AS disp_1,
		  SUM (disp_2) AS disp_2,
		  SUM (disp_3) AS disp_3,
		  SUM (disp_4) AS disp_4,
		  SUM (disp_5) AS disp_5,
		  sum (vlr_semana) as vlr_semana,
		  sum (semana) as semana,
		  sum (mes) as mes,
		  sum (mes_ant) as mes_ant,
		  sum (dia) as dia
      FROM WORK.FIM_vp_CASSI t1
	  
GROUP BY 1;
QUIT;


DATA BASE_cassi;
SET FIM_AG_1_CASSI FIM_GRV_CASSI FIM_SUP_CASSI FIM_UEN_CASSI FIM_VP_CASSI FIM_BRASIL_CASSI;
BY PREFDEP;
efetiv_mes_ant=VLR_MES_ANT/mes_ant*100;
efetiv_mes_atu=VLR_MES_ATU/mes*100;
efetiv_semana=vlr_semana/semana*100;
mvto=Put(&DiaUtil_D1, yymmdd10.);
WHERE PREFDEP NE '0000';
RUN;


DATA BASE_1_CASSI ;
MERGE AUX_DEPENDENCIAS BASE_CASSI;
BY PREFDEP;
RUN;
%ZERARMISSINGtabela (WORK.BASE_1_CASSI);


DATA BASE_FIM_CASSI;
	SET BASE_1_CASSI;

	IF CART NE 0 THEN
		DO;	
			PrefPai=Prefdep;
			Tipo='89';
			NivelDep='0';
		END;
		WHERE VLR_TOTAL+mes+MES_ANT NE 0;
RUN;

PROC SQL;
   CREATE TABLE BASE_FIM_1_CASSI AS 
   SELECT DISTINCT t1.PrefDep, 
          IFC (t1.NomeDep='','BRASIL', t1.NomeDep) AS NomeDep,
          IFC (t1.NivelDep='', 'D', t1.NivelDep) AS NivelDep,
          IFC (t1.Tipo='', '39',T1.TIPO) AS TIPO,
          t1.PrefSupReg, 
          t1.PrefSupEst, 
          t1.PrefUEN, 
          t1.VP, 
          t1.PrefPai,           
          t1.cart, 
		  'SEM CASSI' as ancora,
          t1.VLR_TOTAL, 
          t1.VLR_MES_ATU, 
          t1.VLR_MES_ANT, 
          t1.VLR_D_1, 
          t1.VLR_D_2, 
          t1.VLR_D_3, 
          t1.VLR_D_4, 
          t1.VLR_D_5, 
          t1.disp_1, 
          t1.disp_2, 
          t1.disp_3, 
          t1.disp_4, 
          t1.disp_5, 
          t1.vlr_semana, 
          t1.semana, 
          t1.mes, 
		  t1.mes_ant,
		  t1.dia,
		  t1.efetiv_mes_ant,
		  t1.efetiv_mes_atu,
		  t1.efetiv_semana,
		  ifn (t1.Mercado IN ('A' ''),1,0) AS SEQ, 
          t1.mvto
      FROM WORK.BASE_FIM_CASSI t1
WHERE PREFDEP NOT IN ('1966' '   .' '4904');
QUIT;

data base_rpt;
set base_fim_1 base_fim_1_cassi;
by prefdep;
run; 



PROC 	EXPORT DATA=base_rpt OUTFILE="/dados/infor/producao/AF/Dados_saida/base_rpt_fim_cassi.txt" DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;




x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate af_3" ;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/AF/Dados_saida/base_rpt_fim_cassi.txt' INTO TABLE af_3 FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' ;";





x /dados/infor/producao/AF;
x chmod 777 *;

x /dados/infor/producao/AF/dados_saida;
x chmod 777 *;






x /dados/infor/producao/AF;
x chmod 777 *;

x /dados/infor/producao/AF/dados_saida;
x chmod 777 *;


%macro analitico;
	%if &MCR=1 %then
		%do;

PROC SQL;
   CREATE TABLE WORK.DISPONIVEL AS 
   SELECT DISTINCT t1.prefdep, 
		  t1.mvto,
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.MES_ANT as VLR_MES_ANT
      FROM WORK.ORDENS_FINAIS_1 t1
      WHERE t1.MES_ANT NOT = 0;
QUIT;


PROC SQL;
   CREATE TABLE WORK.DISPONIVEL_UNICA(label="QUERY_FOR_ORDENS_UNICAS_1") AS 
   SELECT t1.prefdep, 
          t1.MVTO, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT
      FROM WORK.ORDENS_UNICAS_1 t1
      WHERE t1.VLR_MES_ANT NOT = 0;
QUIT;


PROC SQL;
   CREATE TABLE WORK.antecipado AS 
   SELECT DISTINCT t1.prefdep, 
          t1.DT_EST_ORD_CPR, 
          t1.mci, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT
      FROM WORK.CART_1 t1
      WHERE t1.VLR_MES_ANT NOT = 0;
QUIT;


proc sql;
create table disponiveis as 
select prefdep, 
          MVTO, 
          MCI_FORNECEDOR, 
          NR_ORD_CPR, 
          VLR_MES_ANT
		  from DISPONIVEL
		  union 
select prefdep, 
          MVTO, 
          MCI_FORNECEDOR, 
          NR_ORD_CPR, 
          VLR_MES_ANT
		  from DISPONIVEL_UNICA;
		  quit;



		  PROC SQL;
   CREATE TABLE disponivel_anteciapdo AS 
   SELECT DISTINCT t1.prefdep, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT, 
          put(t2.DT_EST_ORD_CPR, E8601DA10.) as data_antecipacao,
		  t2.VLR_MES_ANT as antecipado
      FROM WORK.DISPONIVEIS t1
           LEFT JOIN WORK.ANTECIPADO t2 ON (t1.prefdep = t2.prefdep) AND (t1.MCI_FORNECEDOR = 
          t2.mci) AND (t1.NR_ORD_CPR = t2.NR_ORD_CPR)
where t1.prefdep not in ('4777' '0000' '9940' '   .');
QUIT;


		  PROC SQL;
   CREATE TABLE disponivel_anteciapdo_grv AS 
   SELECT DISTINCT prefsupreg as prefdep, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT, 
          t1.data_antecipacao,
		  t1.antecipado
      FROM WORK.disponivel_anteciapdo t1 inner join AUX_DEPENDENCIAS t2 on (t1.prefdep=t2.prefdep)
;
QUIT;


		  PROC SQL;
   CREATE TABLE disponivel_anteciapdo_sup AS 
   SELECT DISTINCT prefsupest as prefdep, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT, 
          t1.data_antecipacao,
		  t1.antecipado
      FROM WORK.disponivel_anteciapdo t1 inner join AUX_DEPENDENCIAS t2 on (t1.prefdep=t2.prefdep)
;
QUIT;



		  PROC SQL;
   CREATE TABLE disponivel_anteciapdo_uen AS 
   SELECT DISTINCT prefuen as prefdep, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT, 
          t1.data_antecipacao,
		  t1.antecipado
      FROM WORK.disponivel_anteciapdo t1 inner join AUX_DEPENDENCIAS t2 on (t1.prefdep=t2.prefdep)
;
QUIT;



		  PROC SQL;
   CREATE TABLE disponivel_anteciapdo_vp AS 
   SELECT DISTINCT vp as prefdep, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT, 
          t1.data_antecipacao,
		  t1.antecipado
      FROM WORK.disponivel_anteciapdo t1 inner join AUX_DEPENDENCIAS t2 on (t1.prefdep=t2.prefdep)
;
QUIT;



		  PROC SQL;
   CREATE TABLE disponivel_anteciapdo_brasil AS 
   SELECT DISTINCT '9999' as prefdep, 
          t1.MCI_FORNECEDOR, 
          t1.NR_ORD_CPR, 
          t1.VLR_MES_ANT, 
          t1.data_antecipacao,
		  t1.antecipado
      FROM WORK.disponivel_anteciapdo t1 inner join AUX_DEPENDENCIAS t2 on (t1.prefdep=t2.prefdep)
;
QUIT;


data base_det;
set disponivel_anteciapdo disponivel_anteciapdo_grv disponivel_anteciapdo_sup disponivel_anteciapdo_uen disponivel_anteciapdo_vp disponivel_anteciapdo_brasil;
by prefdep;
run;



PROC 	EXPORT DATA=base_det OUTFILE="/dados/infor/producao/AF/Dados_saida/analitico.txt" DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate af_det" ;
x mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="LOAD DATA LOW_PRIORITY LOCAL INFILE '/dados/infor/producao/AF/Dados_saida/analitico.txt' INTO TABLE af_det FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' ;";

		%end;
%mend;
%analitico;

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
