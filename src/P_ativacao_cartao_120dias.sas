%include '/dados/infor/suporte/FuncoesInfor.sas';	
%diasUteis(%sysfunc(today()), 1);
%GLOBAL DiaUtil_D1;

/*libnames*/
Options
	Compress = no
	Reuse    = Yes
	PageNo   =   1
	PageSize =  55
	LineSize = 110;
	
%conectardb2 (VIP, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (CDE, AUTHDOMAIN=DB2SGCEN);
libname ativ "/dados/infor/producao/ativacao_cartao_120dias";


%let data = intnx('month',Today(), -3,'b');

PROC SQL;
CREATE TABLE WORK.R1 AS 
	 SELECT L4.CD_CLI    												,
			L4.NR_CT_CRT 												,          
			L4.CD_MDLD_CRT												,
			L4.USO_120													,
			case 
				when L4.CD_MDLD_CRT in (27, 30, 127, 149, 163, 167, 180) then 5
				when L4.CD_MDLD_CRT in (26, 35, 59, 60, 129) then 4
				when L4.CD_MDLD_CRT in (1, 2, 131, 192) then 3
				when L4.CD_MDLD_CRT in (53, 54, 72, 73, 74, 75, 119, 133, 139, 141, 193,
 194) then 2
				when L4.CD_MDLD_CRT in (80, 81, 135, 136, 195) then 1 else 9 end AS
 BEST_USO,
			T4.BEST                			  					        ,
            T14.DT_DEB  AS DT_ULT_MVTC_DBT  	    FORMAT=DDMMYYS10.   ,
            T15.DT_CRED AS DT_ULT_MVTC_CRD  	    FORMAT=DDMMYYS10.   ,
            T16.DT_AUTZ												    ,
         	T16.TX_DCR_CMP											    ,
            T6.DT_INCL_OCR_TRB 						FORMAT=DDMMYYS10.   ,
            /* Posse de Cartão ELO */
            T12.ELO
	 FROM (			SELECT 	L2.CD_CLI, 
							L2.NR_CT_CRT,
							L2.CD_MDLD_CRT,
							L2.MVT_CT_CRT, 
							L2.USO_120
					FROM (
							SELECT  L1.CD_CLI, 
									L1.NR_CT_CRT, 
									L1.CD_MDLD_CRT, 
									L1.MVT_CT_CRT, 
									L1.USO_120,
									L1.BANDEIRA
					   		FROM 	(

							
							SELECT  L3.CD_CLI, 
									L3.NR_CT_CRT,
									L3.MVT_CT_CRT, 
									L3.CD_MDLD_CRT,
									L3.USO_120,
									L3.BANDEIRA
							FROM (
									SELECT  r1.CD_CLI, 
											r1.NR_CT_CRT, 
											r1.CD_MDLD_CRT, 
											r1.DT_ABTR_CT, 
											r1.MVT_CT_CRT, 
											r1.USO_120,
									  (CASE r2.VL_TIP_NUM WHEN 4 THEN 0 ELSE r2.VL_TIP_NUM END) as BANDEIRA
									FROM (
											SELECT A1.CD_CLI						, 
													A1.NR_CT_CRT					, 
													A1.CD_MDLD_CRT					, 
													A1.DT_ABTR_CT					, 
												(MAX(A1.MVT_CT_CRT))   AS MVT_CT_CRT, 
													1 AS USO_120     				, 
												(SUM(A1.VL_MVT_CT_CRT)) AS VL_MVT_CT_CRT

											FROM(	 SELECT t1.CD_CLI, 
															t1.NR_CT_CRT, 
															t1.CD_MDLD_CRT, 
															t1.DT_ABTR_CT, 
													   (MAX(t3.DT_INCL_SIS))   AS MVT_CT_CRT, 
													   (SUM(t3.VL_MVT_CT_CRT)) AS VL_MVT_CT_CRT
													FROM DB2VIP.FAT_CT_CRT t2, DB2VIP.MVT_CT_CRT t3, DB2VIP.CT_CRT t1,
 DB2VIP.TIP_TRAN t4


													WHERE  (t2.NR_SEQL_FAT_CT_CRT = t3.NR_SEQL_FAT_CT_CRT	AND 
															t1.NR_CT_CRT          = t2.NR_CTR_OPR_CT_CRT	AND 
															t3.CD_TIP_TRAN        = t4.CD_TRAN) 			AND 
														  ((t4.CD_ITEM_ETTC BETWEEN 27 AND 33 OR (t4.CD_ITEM_ETTC IN (65,
 296, 298) AND t3.CD_RMAT IN (6762, 6763, 6022, 6260, 6257, 6765))) AND 
															t3.QT_PCL_MVT_CPR IN (0, 1) AND t3.DT_MVT_CT_CRT GE &DATA)
													GROUP BY t1.CD_CLI, t1.NR_CT_CRT, t1.CD_MDLD_CRT, t1.DT_ABTR_CT

													UNION

													SELECT  t1.CD_CLI, 
															t1.NR_CT_CRT, 
															t1.CD_MDLD_CRT, 
															t1.DT_ABTR_CT, 
													    MAX(t2.DT_CPTR)   AS MVT_CT_CRT, 
													    SUM(t2.VL_CPR_REAL) AS VL_MVT_CT_CRT
													FROM DB2VIP.CPR_PCLD t2, DB2VIP.CT_CRT t1

													WHERE  t1.NR_CT_CRT = t2.NR_CT_CRT AND
														   t2.TIP_TRAN in ('01', '02', '51', '52', '53') AND
														   t2.DT_CPTR GE &DATA
													GROUP BY t1.CD_CLI, t1.NR_CT_CRT, t1.CD_MDLD_CRT, t1.DT_ABTR_CT) A1

											GROUP BY A1.CD_CLI, A1.NR_CT_CRT, A1.CD_MDLD_CRT, A1.DT_ABTR_CT)	r1,

												   DB2VIP.PRM_MDLD_CRT_CRD										r2
									 WHERE  r1.CD_MDLD_CRT  = r2.CD_MDLD_CRT_CRD AND
											r2.NM_PRM		= 'BANDEIRA'	
									GROUP BY r1.CD_CLI
									HAVING (MAX(r1.VL_MVT_CT_CRT)) = r1.VL_MVT_CT_CRT
												 
									UNION

									SELECT DISTINCT  C2.CD_CLI  	  ,        /* Caso o cliente não tenha
 transacionado nos últimos meses será selecionada a melhor conta cartão       */
                  
													 C2.NR_CT_CRT     ,        /* O primeiro critério é a Modalidade da
 Conta, seguido pela Bandeira e por último a Data de contratação */
													 C2.CD_MDLD_CRT   , 
													 C2.DT_ABTR_CT    , 
													 "01JAN1"D AS MVT_CT_CRT  , 
													 0 AS USO_120     , 
											   (CASE C5.VL_TIP_NUM WHEN 4 THEN 0 ELSE C5.VL_TIP_NUM END) as
 BANDEIRA

												FROM  DB2VIP.CT_CRT 		  C2,
													  DB2VIP.PRM_MDLD_CRT_CRD C5 
																			                            											
												WHERE 	C2.CD_MDLD_CRT  = C5.CD_MDLD_CRT_CRD	AND
														C5.NM_PRM		= 'BANDEIRA'			AND
														C2.CD_CLI NOT IN (SELECT t1.CD_CLI
										      								FROM DB2VIP.FAT_CT_CRT t2, DB2VIP.MVT_CT_CRT t3,
 																				DB2VIP.CT_CRT t1, DB2VIP.TIP_TRAN t4
																	       WHERE (t2.NR_SEQL_FAT_CT_CRT = t3.NR_SEQL_FAT_CT_CRT	AND 
																			      t1.NR_CT_CRT          = t2.NR_CTR_OPR_CT_CRT	AND 
																			      t3.CD_TIP_TRAN        = t4.CD_TRAN)			AND 
																				  ((t4.CD_ITEM_ETTC BETWEEN 27 AND 33 OR (t4.CD_ITEM_ETTC IN
 											(65, 296, 298) AND t3.CD_RMAT IN (6762, 6763, 6022, 6260, 6257, 6765))) AND 
																					t3.QT_PCL_MVT_CPR IN (0, 1) AND t3.DT_MVT_CT_CRT GE &DATA)
																					UNION
																						SELECT  t1.CD_CLI
																						FROM DB2VIP.CPR_PCLD t2, DB2VIP.CT_CRT t1
																						WHERE  t1.NR_CT_CRT = t2.NR_CT_CRT AND
																							   t2.TIP_TRAN in ('01', '02', '51', '52', '53') AND
																							   t2.DT_CPTR GE &DATA)

																																			)	L3

								GROUP BY L3.CD_CLI
								HAVING (MAX(L3.MVT_CT_CRT)) = L3.MVT_CT_CRT							)L1


							GROUP BY L1.CD_CLI
							HAVING (MIN((case 
									when L1.CD_MDLD_CRT in (27, 30, 127, 149, 163, 167, 180) then 5
									when L1.CD_MDLD_CRT in (26, 35, 59, 60, 129) then 4
									when L1.CD_MDLD_CRT in (1, 2, 131, 192) then 3
									when L1.CD_MDLD_CRT in (53, 54, 72, 73, 74, 75, 119, 133, 139, 141,
 193, 194) then 2
									when L1.CD_MDLD_CRT in (80, 81, 135, 136, 195) then 1 else 9 end))) =
 ((case 
									when L1.CD_MDLD_CRT in (27, 30, 127, 149, 163, 167, 180) then 5
									when L1.CD_MDLD_CRT in (26, 35, 59, 60, 129) then 4
									when L1.CD_MDLD_CRT in (1, 2, 131, 192) then 3
									when L1.CD_MDLD_CRT in (53, 54, 72, 73, 74, 75, 119, 133, 139, 141,
 193, 194) then 2
									when L1.CD_MDLD_CRT in (80, 81, 135, 136, 195) then 1 else 9 end))
												) L2
				GROUP BY L2.CD_CLI
				
				HAVING (MIN(L2.BANDEIRA)) = L2.BANDEIRA	)L4

	    LEFT JOIN ( SELECT DISTINCT A2.CD_CLI,  /* Calculo de variável auxilar a
 ser utilizada na identificação do cartão a ser Sugerido */
        					  (MIN(case when A2.CD_MDLD_CRT in (27, 30, 127, 149, 163, 167,
 180)                      then 5
                 						when A2.CD_MDLD_CRT in (26, 35, 59, 60, 129)             
                     then 4
                             	   	    when A2.CD_MDLD_CRT in (1, 2, 131, 192)   
                                    then 3
                             		    when A2.CD_MDLD_CRT in (53, 54, 72, 73, 74,
 75, 119, 133, 139, 141, 193, 194) then 2
                             		    when A2.CD_MDLD_CRT in (80, 81, 135, 136,
 195)                                then 1
                                                                                
                                       else 9 end)) AS BEST
                 		      FROM DB2VIP.CT_CRT  A2
                 		      GROUP BY A2.CD_CLI                                    
 )     T4
               	ON (L4.CD_CLI  = T4.CD_CLI)
         
         LEFT JOIN ( SELECT A7.CD_CLI,         /* Identifica a data de abertura
 da última Ocorrência de Trabalho pendente */
                                      (MAX(A5.DT_INCL_OCR_TRB))  AS
 DT_INCL_OCR_TRB
                 		         FROM DB2VIP.OCR_TRB        A5,
                                      DB2VIP.ACAO_OCR_TRB   A6,
                                      DB2VIP.CT_CRT         A7
                 		         WHERE (A5.NR_PTC_OCR_TRB = A6.NR_PTC_OCR_TRB     AND
                                        A5.NR_OCR_TRB     = A6.NR_OCR_TRB       
  AND
                                        A5.CD_EST_OCR_TRB =
 A6.CD_EST_OCR_TRB_ANT AND
                                        A5.NR_CT_CRT      = A7.NR_CT_CRT)       
  AND
                                        A6.CD_ACAO_SLC_OCR = 'ABERT'
                 		      GROUP BY  A7.CD_CLI                                    
  )     T6
                         ON (L4.CD_CLI  = T6.CD_CLI)
         
         
         LEFT JOIN ( SELECT DISTINCT t1.CD_CLI,    /* Posse de Cartão ELO */
                                     ('S') AS ELO
                 			    FROM DB2VIP.CT_CRT t1
                 		  INNER JOIN DB2VIP.PRM_MDLD_CRT_CRD t2
                 			      ON (t1.CD_MDLD_CRT = t2.CD_MDLD_CRT_CRD)
                 			   WHERE t2.NM_PRM     = 'BANDEIRA' AND
                 					 t2.VL_TIP_NUM = 4									)     T12
                 		ON (L4.CD_CLI  = T12.CD_CLI)
         
         
         LEFT JOIN ( SELECT A7.CD_CLI,								/* Identifica a data de última
 utilização no Débito */
         			    MAX(A7.DT_DEB) FORMAT=DDMMYYS10. AS DT_DEB
                	   FROM (
                			  SELECT t2.CD_CLI,
                				(MAX(t5.DT_APSC_TRAN)) FORMAT=DATE9. AS DT_DEB
                			    FROM DB2CDE.TRAN_CRT_DEB t5, DB2VIP.PLST_PORT t6,
 DB2VIP.CT_CRT t2
                			   WHERE (t5.NR_CRT = t6.NR_PLST AND t2.NR_CT_CRT =
 t6.NR_CT_CRT) AND
                				     (t5.CD_TIP_TRAN IN (5, 7, 9, 12, 13, 15) AND
 t5.CD_EST_TRAN = 103)
                			 GROUP BY t2.CD_CLI
        
                		UNION
        
     	    				  SELECT t2.CD_CLI,
     	  	         	         (MAX(t1.DT_APSC_TRAN)) FORMAT=DATE9. AS DT_DEB
     	 	          	        FROM DB2CDE.TRAN_CRT_DEB t1 INNER JOIN
 DB2CDE.CLI_CRT_DEB t2 ON (t1.NR_CRT = t2.NR_CRT_DEB)
     		           	       WHERE t1.CD_TIP_TRAN IN (5, 7, 9, 12, 13, 15) AND
 t1.CD_EST_TRAN = 103
         	        	    GROUP BY t2.CD_CLI) A7
                	GROUP BY A7.CD_CLI 											) T14
                        ON (L4.CD_CLI  = T14.CD_CLI)
        
         LEFT JOIN ( SELECT A2.CD_CLI,
						MAX(A2.DT_CRED) AS DT_CRED
					FROM(	SELECT   t2.CD_CLI, 							/* Identifica a data de última utilização
 no crédito */
	                	   		(MAX(t1.DT_INCL_SIS)) FORMAT=DDMMYYS10. AS DT_CRED
	                	   FROM DB2VIP.MVT_CT_CRT t1, DB2VIP.FAT_CT_CRT t3,
 DB2VIP.CT_CRT t2, DB2VIP.TIP_TRAN t4
	                	   WHERE (t1.NR_SEQL_FAT_CT_CRT = t3.NR_SEQL_FAT_CT_CRT AND
 t3.NR_CTR_OPR_CT_CRT = t2.NR_CT_CRT AND t1.CD_TIP_TRAN =
	                	         t4.CD_TRAN) AND t1.QT_PCL_MVT_CPR IN (0, 1) AND
 (t4.CD_ITEM_ETTC BETWEEN 27 AND 33 OR
	                			(t1.CD_RMAT IN (6762, 6763, 6022, 6260, 6257, 6765) AND
 t4.CD_ITEM_ETTC IN (65, 296, 298)))
							GROUP BY t2.CD_CLI
						UNION
							SELECT  t1.CD_CLI, 
								MAX(t2.DT_CPTR)   AS DT_CRED 
							FROM DB2VIP.CPR_PCLD t2, DB2VIP.CT_CRT t1
							WHERE   t1.NR_CT_CRT = t2.NR_CT_CRT AND
									t2.TIP_TRAN in ('01', '02', '51', '52', '53') AND
									t2.DT_CPTR GE &DATA
							GROUP BY t1.CD_CLI) A2
					GROUP BY A2.CD_CLI											) T15
                		ON (L4.CD_CLI = T15.CD_CLI)
        
         LEFT JOIN ( SELECT DISTINCT 								/* Identifica a última transação
 negada no crédito */
        					  t2.CD_CLI    ,
        			          t1.DT_AUTZ   ,
        			          t4.TX_DCR_CMP
        			  FROM DB2VIP.AUTZ_RVSA_TRAN t1, DB2VIP.PLST_PORT t3, DB2VIP.CT_CRT
 t2, DB2VIP.LDR_DCR_CD t4
        			 WHERE (t1.NR_PLST = t3.NR_PLST AND t3.NR_CT_CRT = t2.NR_CT_CRT AND
 t1.CD_RPST = t4.CD_ITEM) AND (t1.CD_RPST NOT =
        			       '00' AND t1.CD_MTV_ACAO_FIM NOT = 0 AND t4.NM_TAB = 
'AUTZ_RVSA_TRAN' AND t4.NM_CMP = 'CD_RPST')
        		  GROUP BY t2.CD_CLI
        		    HAVING  (MAX(t1.DT_AUTZ)) 			= t1.DT_AUTZ AND
        					(MAX(t1.HH_AUTZ)) 			= t1.HH_AUTZ AND					
							(MAX(t1.NR_AUTZ))			= t1.NR_AUTZ AND
        					(MAX(t1.NR_REF_TRAN_AUTD))  = t1.NR_REF_TRAN_AUTD	) T16
        				ON (L4.CD_CLI = T16.CD_CLI)

	GROUP BY L4.CD_CLI
	HAVING (MAX(L4.NR_CT_CRT)) = L4.NR_CT_CRT	;

   CREATE TABLE WORK.R2 AS 
   SELECT t1.CD_CLI_PF, 
          t1.VL_LIM_CLI_PF 							AS VL_LIM_UNICO, 
          t1.VL_LIM_RTV_CLI_PF 						AS VL_LIM_ROTATIVO, 
         (t1.VL_LIM_CLI_PF - t1.VL_LIM_RTV_CLI_PF)	AS VL_LIM_PCLD
      FROM DB2VIP.LIM_CLI_PF t1;

   CREATE TABLE ATIV.RELATORIO_CRT_1 AS 
   SELECT t1.CD_CLI, 
          t1.NR_CT_CRT, 
		  t1.CD_MDLD_CRT,
		  t1.USO_120,
		  t1.BEST_USO,
          t1.BEST, 
          t1.DT_ULT_MVTC_DBT, 
          t1.DT_ULT_MVTC_CRD, 
          t1.DT_AUTZ, 
          t1.TX_DCR_CMP, 
          t2.VL_LIM_UNICO, 
          t2.VL_LIM_ROTATIVO, 
          t2.VL_LIM_PCLD, 
          t1.DT_INCL_OCR_TRB, 
          t1.ELO
      FROM WORK.R1 t1 LEFT JOIN WORK.R2 t2 ON (t1.CD_CLI = t2.CD_CLI_PF);
QUIT;

PROC SQL;
   CREATE TABLE ativ.ENCARTEIRAMENTO_201801 AS 
   SELECT DISTINCT t2.prefdep, 
          ifN(t2.tp_cart in (10,16,25,40,41,42,43,44,45,46,47,48,49,50,54,55,56,57,190,200,210,303,315,400,405,406,407,430,500,550,321,322,323,324,328), t2.cart,7002) as cart,
          t2.cart, 
          t1.*
      FROM ATIV.RELATORIO_CRT_1 t1
           INNER JOIN comum.ENCARTEIRADOS t2 ON (t1.CD_CLI = t2.CD_CLI);
QUIT;

PROC SQL;
   CREATE TABLE WORK.restricao AS 
   SELECT distinct t1.mci, 
          t1.max_peso_anot_cadl
      FROM BCN.BCN_PF t1
      WHERE t1.max_peso_anot_cadl IN (3, 4);
QUIT;

PROC SQL;
   CREATE TABLE ativ.ANALITICO_201801 AS 
   SELECT distinct t1.prefdep, 
          t1.cart, 
          t1.CD_CLI, 
          t1.CD_MDLD_CRT, 
          t1.BEST_USO as cartao_uso,
          t1.BEST as cartao_disp,
          t1.DT_ULT_MVTC_CRD format yymmdd10., 
		  ifn ((t1.DT_ULT_MVTC_CRD+120)-today()<0,0,(t1.DT_ULT_MVTC_CRD+120)-today()) as falta_inat,          
          t1.VL_LIM_UNICO, 
          t1.VL_LIM_ROTATIVO, 
          t1.ELO, 
		  t1.DT_AUTZ format yymmdd10., 
		  t1.TX_DCR_CMP,
          ifn (t1.DT_INCL_OCR_TRB=., 0, 1) as ocor_penden,
		  t1.DT_INCL_OCR_TRB format yymmdd10.,
		  ifn (t2.mci=.,0,1) as restricao,
		  ifn (vl_lim_unico not in (., 0),1,0) as possui_limite
      FROM ATIV.ENCARTEIRAMENTO_201801 t1
		left join restricao t2 on (t1.cd_cli=t2.mci)
		;
QUIT;


PROC SQL;
   CREATE TABLE ativ.fim_cart AS 
   SELECT t1.prefdep, 
          t1.cart, 
          count (distinct t1.CD_CLI) as qtd_cli, 
          sum (ifn (falta_inat>0,1,0)) as qtd_cartao, 
          sum (t1.VL_LIM_UNICO) as VL_LIM_UNICO, 
          sum (t1.VL_LIM_ROTATIVO) as VL_LIM_ROTATIVO
      FROM ATIV.analitico t1
group by 1, 2;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_ag AS 
   SELECT t1.prefdep, 
          0 as cart, 
          sum  (t1.qtd_CLI) as qtd_cli, 
          sum  (t1.qtd_cartao) as qtd_cartao, 
          sum (t1.VL_LIM_UNICO) as VL_LIM_UNICO, 
          sum (t1.VL_LIM_ROTATIVO) as VL_LIM_ROTATIVO
      FROM ativ.fim_cart t1
group by 1;
QUIT;


PROC SQL;
CREATE TABLE APOIO AS 
SELECT DISTINCT PREFDEP
FROM FIM_AG;
QUIT;

DATA IGRREDE;
	SET dep.IGRREDE APOIO;

	IF PrefDep='8477' THEN
		NomeDep='DISAP';

	IF PrefDep='8592' THEN
		NomeDep='DIRED';
RUN;


PROC SQL;
	CREATE TABLE QATOT_MOB AS 
		SELECT I.PrefDep, 
			TRIM(IFC(TipoDep='39','SUPER '||N.NomeDep,I.NomeDep)) AS NomeDep, 
			IFC(I.TipoDep='99' AND I.PrefDep NE '8166','8',I.NivelDep) AS NivelDep, 
			IFC(I.TipoDep='99','39',I.TipoDep) AS TipoDep, 
			I.PrefSupReg, I.PrefSupEst, I.PrefUEN, '8166' AS VP, 
			IFC(I.TipoDep='99','8166',
			IFC(I.TipoDep='39',PrefUEN,IFC(I.TipoDep='29' OR PrefSupReg='0000',PrefSupEst,PrefSupReg))) AS Pref_Pai,
			CodSitDep
FROM IGRREDE I 
			LEFT JOIN dep.IGRNivel N ON(I.PrefDep=N.PrefDep)
				WHERE TipoDep In('01' '09' '29' '39' '99') AND I.PrefDep Not In('TTBB' '9978');
	DROP TABLE IGRREDE;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_grv AS 
   SELECT prefsupreg as prefdep, 
          0 as cart, 
          sum  (t1.qtd_CLI) as qtd_cli, 
          sum  (t1.qtd_cartao) as qtd_cartao, 
          sum (t1.VL_LIM_UNICO) as VL_LIM_UNICO, 
          sum (t1.VL_LIM_ROTATIVO) as VL_LIM_ROTATIVO
      FROM fim_ag t1 inner join qatot_mob t2 on (t1.prefdep=t2.prefdep)
	  where prefsupreg ne '0000'
group by 1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.fim_sup AS 
   SELECT prefsupest as prefdep, 
          0 as cart, 
          sum  (t1.qtd_CLI) as qtd_cli, 
          sum  (t1.qtd_cartao) as qtd_cartao, 
          sum (t1.VL_LIM_UNICO) as VL_LIM_UNICO, 
          sum (t1.VL_LIM_ROTATIVO) as VL_LIM_ROTATIVO
      FROM fim_ag t1 inner join qatot_mob t2 on (t1.prefdep=t2.prefdep)
	  where prefsupreg ne '0000'
group by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_dir AS 
   SELECT prefuen as prefdep, 
          0 as cart, 
          sum  (t1.qtd_CLI) as qtd_cli, 
          sum  (t1.qtd_cartao) as qtd_cartao, 
          sum (t1.VL_LIM_UNICO) as VL_LIM_UNICO, 
          sum (t1.VL_LIM_ROTATIVO) as VL_LIM_ROTATIVO
      FROM fim_ag t1 inner join qatot_mob t2 on (t1.prefdep=t2.prefdep)
	  where prefsupreg ne '0000'
group by 1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fim_vp AS 
   SELECT vp as prefdep, 
          0 as cart, 
          sum  (t1.qtd_CLI) as qtd_cli, 
          sum  (t1.qtd_cartao) as qtd_cartao, 
          sum (t1.VL_LIM_UNICO) as VL_LIM_UNICO, 
          sum (t1.VL_LIM_ROTATIVO) as VL_LIM_ROTATIVO
      FROM fim_ag t1 inner join qatot_mob t2 on (t1.prefdep=t2.prefdep)
	  where prefsupreg ne '0000'
group by 1;
QUIT;


data base;
set ativ.fim_cart fim_ag fim_grv fim_sup fim_dir fim_vp;
by prefdep;
run;

data base_1 (drop=CodSitDep);
merge qatot_mob base;
by prefdep;
if qtd_cli ne .;
run;

DATA ativ.BASE_RPT_FIM;
	SET BASE_1;

	IF CART NE 0 THEN
		DO;	
			Pref_Pai=Prefdep;
			TipoDep='89';
			NivelDep='0';
		END;
RUN;





PROC EXPORT 
	DATA=ativ.BASE_RPT_FIM
	OUTFILE="/dados/infor/producao/ativacao_cartao_120dias/base_rpt_fim.txt" DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate ativacao_cartao_120dias" ;
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/ativacao_cartao_120dias/base_rpt_fim.txt' INTO TABLE ativacao_cartao_120dias FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="update posicoes set posicao = if(Weekday(date(now())) = 0 ,date(date(now())-3),date(date(now())-1)) where xml = 'ativacao_cartao_120dias'";




PROC EXPORT 
	DATA=ativ.analitico
	OUTFILE="/dados/infor/producao/ativacao_cartao_120dias/analitico.txt" DBMS=DLM REPLACE;
	PUTNAMES=NO;
	DELIMITER=';';
RUN;


x cd /dados/infor/utilitarios; /*local onde está o "conector" MySql*/
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="truncate ativacao_cartao_120dias_det" ;
x ./mysql -h svispo02157.sp.intrabb.bb.com.br -u proc_paulo relatorios -p33262308 --execute="load data low_priority local infile '/dados/infor/producao/ativacao_cartao_120dias/analitico.txt' INTO TABLE ativacao_cartao_120dias_det FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'";
