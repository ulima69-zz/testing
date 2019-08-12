%include '/dados/infor/suporte/FuncoesInfor.sas';
%LET NomeRelatorio=;
%LET NomePasta=imob_digital;
%LET Keypass=;
%LET Rotina=;

%commandshell ("ssh-keygen -f $HOME/.ssh/id_rsa -P ''");
*/%IniciarProcessoMysql(Processo=&NomeRelatorio., Responsavel=Vanessa, XML=&NomeXML.);/*


/*#################################################################################################################*/
/*##### B I B L I O T E C A S #####*/


LIBNAME DB2SGCEN 	db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2SGCEN database=BDB2P04;
LIBNAME DB2CIM 		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2CIM 	database=BDB2P04;
LIBNAME DB2DEB		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2DEB database=BDB2P04;
LIBNAME DB2ARG		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2ARG database=BDB2P04;
LIBNAME DB2COP		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2COP database=BDB2P04;
LIBNAME DB2MCI		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2MCI database=BDB2P04;
LIBNAME DB2BIC		db2 AUTHDOMAIN=DB2SGCEN 	schema=DB2BIC database=BDB2P04;

LIBNAME IGR "/dados/infor/producao/dependencias";

libname imob "/dados/infor/producao/imob_digital";




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



%PUT &DT_FIXA_SQL.;


x cd /;
x cd /dados/infor/producao/dependencias;
x cd /dados/infor/producao/imob_digital;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/



PROC SQL;
connect to db2 (authdomain=db2sgcen database=bdb2p04);
execute (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
   CREATE TABLE DADOS_CLIENTES AS 
   SELECT DISTINCT *
from connection to db2( 
   SELECT DISTINCT 
   t1.NR_CPF_PRPN_SMLC AS CPF
      FROM DB2CIM.SMLC_FNTO_IMRO t1
	  WHERE NR_TEL_CTT > 0 );
	  disconnect from db2
;QUIT;


proc sql;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	execute (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
	create table clientes as 
		select 
			*
		from connection to db2(
			select distinct
				cod as mci, 
				cod_cpf_cgc as cpf
			from db2mci.cliente 
				where cod_tipo = 1);
	disconnect from db2;
quit;


proc sql;
	create table dados_clientes3 as
		select distinct
			t1.mci,			
			ifn(t2.cpf = ., t1.cpf, t2.cpf) as cpf 
		from clientes t1 
			inner join dados_clientes t2 on t1.cpf=t2.cpf
				order by 1 
	;
quit;



DATA REG_BIC_CMPR;
SET IMOB.CONTATOS_201803;
RUN;
PROC SORT DATA=REG_BIC_CMPR NODUPKEY; BY _ALL_; RUN;



PROC SQL;
   CREATE TABLE WORK.CONTATOS_201708 AS 
   SELECT DISTINCT t1.MCI, 
          MAX(t1.DT_CONTATO) FORMAT=YYMMDD10. AS DT_CONTATO
      FROM WORK.REG_BIC_CMPR t1
GROUP BY 1;
QUIT;


PROC SQL;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	execute (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
	CREATE TABLE reg_bic_ant AS 
		SELECT DISTINCT 
			cd_cli as mci, 
			datepart(dt_contato) format yymmdd10. as dt_contato 
		from connection to db2(
			SELECT DISTINCT
				cd_cli, 
				MAX(ts_inro_cli) AS dt_contato
			FROM db2bic.aux_inro_cli_ant 
				where /*cd_rstd_inro = 10 and cd_sub_rstd_inro = 105 and */cd_prd=436 and cd_tran_inro_sis IN ('REL02','SMI02')
				group by cd_cli
					order by 1);
	disconnect from db2;
QUIT;

PROC SQL;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	execute (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
	CREATE TABLE reg_bic AS 
		SELECT DISTINCT 
			cd_cli as mci, 
			datepart(dt_contato) format yymmdd10. as dt_contato 
		from connection to db2(
			SELECT DISTINCT
				cd_cli, 
				MAX(ts_inro_cli) AS dt_contato
			FROM db2bic.aux_inro_cli_atu 
				where /*cd_rstd_inro = 10 and cd_sub_rstd_inro = 105 and */cd_prd=436 and cd_tran_inro_sis IN ('REL02','SMI02')
				group by cd_cli
					order by 1);
	disconnect from db2;
QUIT;


PROC SQL;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	execute (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
	CREATE TABLE reg_bic_dia AS 
		SELECT DISTINCT 
			cd_cli as mci, 
			datepart(dt_contato) format yymmdd10. as dt_contato 
		from connection to db2(
			SELECT DISTINCT
				cd_cli, 
			MAX(ts_inro_cli) AS dt_contato
			FROM db2bic.inro_cli 
				where /*cd_rstd_inro = 10 and cd_sub_rstd_inro = 105 and */cd_prd=436 and cd_tran_inro_sis IN ('REL02','SMI02')
				group by cd_cli
					order by 1);
	disconnect from db2;
QUIT;


data imob.contatos_&anomes;
	merge dados_clientes3 CONTATOS_201708 reg_bic_ant reg_bic reg_bic_dia;
	by mci;
run;


/**/
/**/
/*PROC SQL;*/
/*		CREATE TABLE REC_01 AS*/
/*		SELECT DISTINCT*/
/*			t1.CPF,*/
/*			t2.DEB307_COD_BDC 	AS MCI*/
/*	FROM DADOS_CLIENTES t1 */
/*LEFT JOIN DB2DEB.TDEB307 t2 	ON t1.CPF=t2.DEB307_CGC_CPF */
/*;*/
/*QUIT;*/



DATA ENCARTEIRAMENTO_CONEXAO;
SET COMUM.ENCARTEIRAMENTO_CONEXAO;
RUN;
PROC SORT DATA=ENCARTEIRAMENTO_CONEXAO NODUPKEY; BY _ALL_; RUN;


PROC SQL;
CREATE TABLE WORK.CART_IMOB AS 
	SELECT DISTINCT 
		t2.MCI,
		t2.CPF FORMAT 11., 
		t1.CD_PRF_DEPE,
	   /*NR_SEQL_CTRA*/
			(Case when t1.CD_TIP_CTRA IN (59,20,17,15,18,19,70,69)
				then 7002
			when  t1.CD_TIP_CTRA in (10,16,50,56,60) then t1.NR_SEQL_CTRA end)	AS NR_SEQL_CTRA, 
/*  CD_TIP_CTRA  */
			(Case when t1.CD_TIP_CTRA IN (59,20,17,15,18,19,70,69)
				then 700
			when  t1.CD_TIP_CTRA in (10,16,50,56,60) then t1.CD_TIP_CTRA end) 	AS CD_TIP_CTRA
		FROM WORK.ENCARTEIRAMENTO_CONEXAO t1
		RIGHT JOIN DADOS_CLIENTES3 t2 on (t2.mci=t1.cd_cli)
/*		WHERE (CALCULATED NR_SEQL_CTRA) NOT = .*/
		;
QUIT;





PROC SQL;
	connect to db2 (authdomain=DB2SGCEN database=bdb2p04);
	execute (SET CURRENT QUERY ACCELERATION NONE) BY DB2;
   CREATE TABLE WORK.DADOS_IMOB AS 
   SELECT * 
   	from connection to db2(  
   SELECT 
		  t1.NR_CPF_PRPN_SMLC AS CPF, 
          t1.NR_SMLC_FNTO_IMRO, 
          t1.DT_NSC_PRPN_SMLC, 
          t1.CD_RSCO_CRD_ATBD, 
          t1.DT_SMLC_FNTO_IMRO, 
          t1.CD_TIP_CNL_SMLC, 
          t1.CD_LNCD, 
          t1.CD_SIS_RPC_CRD, 
          t1.CD_FNLD_BEM_IMV, 
          t1.CD_MUN, 
          t1.CD_EST_IMV, 
          t1.CD_SGM_CLI, 
          t1.QT_PCL_FNTO, 
          t1.QT_MM_CARE, 
          t1.QT_PCL_AA, 
          t1.IN_CT_FGTS_ATV, 
          t1.IN_TMP_MIN_CT_FGTS, 
          t1.IN_EPRD_FNCD_BB, 
          t1.IN_FUN_BB, 
          t1.IN_PRGC_PCL, 
          t1.IN_PROP_CID_FNTO, 
          t1.IN_RSDC_CID_FNTO, 
          t1.IN_SMLC_TAXA_REF, 
          t1.VL_IMV_SMLC_FNTO, 
          t1.VL_UTZD_RCS_PRPP, 
          t1.VL_SBS, 
          t1.VL_DSP_FNCD, 
          t1.VL_FNTO, 
          t1.VL_TAXA_JUR_FNTO, 
          t1.VL_REN_BRTO_FMLR, 
          t1.CD_PRD_SGRO, 
          t1.CD_MDLD_SGRO, 
          t1.CD_ITEM_MDLD_SGRO, 
          t1.CD_CVN, 
          t1.NR_DDD_TEL_CTT, 
          t1.NR_TEL_CTT, 
          t1.TX_EMAI_CTT, 
          t1.NR_ANL, 
          t1.NR_VRS_ANL, 
          t1.NR_PRPT, 
          t1.NR_VRS_PRPT, 
          t1.CD_USU_RSP_ALT, 
          t1.TS_ALT, 
          t1.IN_BNFD_SBS_FGTS, 
          t1.IN_FTR_SCL, 
          t2.VL_PSTC_INC,
          t2.VL_CET, 
          t2.VL_CST_SGRO_RSDC, 
          t2.VL_IOF, 
          t2.VL_SGRO_MRT_INVZ, 
          t2.VL_SGRO_DAN_IMV, 
          t2.VL_DSP_CON
      FROM DB2CIM.SMLC_FNTO_IMRO t1
       INNER JOIN DB2CIM.RSTD_SMLC_FNTO t2 on (t1.NR_CPF_PRPN_SMLC = t2.NR_CPF_PRPN_SMLC AND t1.NR_SMLC_FNTO_IMRO = t2.NR_SMLC_FNTO_IMRO)                      
	  WHERE t1.DT_SMLC_FNTO_IMRO >= &DT_FIXA_SQL. 
/*	  AND t1.TX_EMAI_CTT       IS NOT NULL*/
/*	  AND t1.NR_ANL            IS NOT NULL	*/
);
	disconnect from db2;
QUIT;	 



proc sql;
	select max(dt_smlc_fnto_imro) format date9. as dt_smlc_fnto_imro
	into :dt_smlc_fnto_imro
from IMOB.DADOS_IMOB_&ANOMES;
quit;
%put &dt_smlc_fnto_imro;

DATA DADOS_IMOB_temp;
SET IMOB.DADOS_IMOB_&ANOMES(where=(dt_smlc_fnto_imro < "&dt_smlc_fnto_imro"d)); 
RUN;

data IMOB.DADOS_IMOB_&ANOMES;
set DADOS_IMOB_temp 
	DADOS_IMOB;
run;

proc sort data=IMOB.DADOS_IMOB_&ANOMES nodupkey; by _all_; run;
%put &ANOMES;


proc format;
	VALUE NM 475='SFH' 477='CH' 580="PRO-COTISTA" 524 = "PMCMV" 570="PMCMV RURAL" 582="FGTS" 586="FGTS"
	;
	VALUE SR 1='SAC' 2='PRICE' 5='PRICE-POS';
	VALUE FB 1='Residencial' 2='Comercial';
	VALUE PS 441='Seguro Habitacional';
	VALUE MS 1='Banco do Brasil' 3='Bradesco';
	VALUE IS 6102='BB Residencial' 7731='BB Comercial' 6800='Bradesco Residencial';
run;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_MUN AS 
   SELECT t1.CD_MUN, 
          t1.NM_MUN,
		  t1.SG_UF
      FROM DB2ARG.MUN t1;
QUIT;

PROC SQL;
   CREATE TABLE Ultima_simulacao AS 
   SELECT distinct t1.CPF, 
          /* MAX_of_NR_SMLC_FNTO_IMRO */
            (MAX(t1.NR_SMLC_FNTO_IMRO)) FORMAT=11. AS NR_SMLC_FNTO_IMRO
      FROM imob.DADOS_IMOB_&ANOMES t1
      GROUP BY t1.CPF;
QUIT;
%put &ANOMES;

PROC SQL;
   CREATE TABLE Ultimo_Contato AS 
   SELECT distinct t1.MCI, 
          /* MAX_of_dt_contato */
            (MAX(t1.dt_contato)) FORMAT=YYMMDD10. AS Ult_dt_contato
      FROM IMOB.CONTATOS_&ANOMES t1
      WHERE t1.dt_contato >= '29Aug2017'd
      GROUP BY t1.MCI;
QUIT;


PROC SQL;
   CREATE TABLE CART_IMOB AS 
   SELECT t1.MCI, 
          t1.cpf, 
          t1.CD_PRF_DEPE, 
          t1.NR_SEQL_CTRA, 
          t1.CD_TIP_CTRA, 
          t2.Ult_dt_contato
      FROM WORK.CART_IMOB t1
           LEFT JOIN WORK.ULTIMO_CONTATO t2 ON (t1.MCI = t2.MCI);
QUIT;



PROC SQL;
   CREATE TABLE WORK.DADOS_IMOB_01 AS 
   SELECT 
&DATA_HOJE. FORMAT=DateMysql. as POSICAO,
   		  IFN(t2.CD_PRF_DEPE=.,4777,t2.CD_PRF_DEPE)   as PREFDEP,
		  IFN(t2.NR_SEQL_CTRA=.,7002,t2.NR_SEQL_CTRA) AS CARTEIRA, 
		  t2.MCI format 9. ,
          t4.NR_SMLC_FNTO_IMRO AS NUMERO_DA_SIMULACAO, 
          t1.DT_NSC_PRPN_SMLC FORMAT DDMMYY10. AS DATA_DE_NASCIMENTO, 
          t1.CD_RSCO_CRD_ATBD AS CODIGO_DO_RISCO, 
          t1.DT_SMLC_FNTO_IMRO FORMAT DDMMYY10. AS DATA_DA_SIMULACAO, 
          t1.CD_SGM_CLI AS SEGMENTO_DO_CLIENTE, 
          t1.QT_PCL_FNTO AS QTD_PARCELAS, 
          t1.QT_MM_CARE AS CARENCIA, 
          t1.VL_IMV_SMLC_FNTO AS VALOR_DO_IMOVEL, 
          t1.VL_UTZD_RCS_PRPP AS RECURSOS_PROPRIOS, 
          t1.VL_SBS AS VALOR_DO_SUBSIDIO, 
          t1.VL_DSP_FNCD AS VALOR_DAS_DESPESAS, 
          t1.VL_FNTO AS VALOR_DO_FINANCIAMENTO, 
          t1.VL_TAXA_JUR_FNTO AS TAXA_DE_JUROS, 
          t1.VL_REN_BRTO_FMLR AS RENDA_BRUTA_INFORMADA, 
          t1.NR_DDD_TEL_CTT AS DDD_TELEFONE, 
          t1.NR_TEL_CTT AS NR_TELEFONE, 
          t1.TX_EMAI_CTT AS EMAIL,
          t1.VL_PSTC_INC as VALOR_DA_PRESTACAO, 
          t1.VL_CET AS VALOR_DO_CET, 
          t1.VL_CST_SGRO_RSDC AS VALOR_DO_CESH, 
          t1.VL_IOF AS VALOR_DO_IOF, 
          t1.VL_SGRO_MRT_INVZ AS VALOR_DO_MIP, 
          t1.VL_SGRO_DAN_IMV AS VALOR_DO_DFI,
		   t1.CPF format 11.,
		    t1.CD_LNCD format nm. as LINHA_DE_CREDITO,
			t3.NM_MUN AS  MUNICIPIO,
			t1.CD_SIS_RPC_CRD Format sr. AS SISTEMA_DE_REPOSICAO, 
          t1.CD_FNLD_BEM_IMV Format fb. AS FINALIDADE_DO_BEM,
		  t1.CD_PRD_SGRO Format ps. AS PRODUTO_DO_SEGURO, 
          t1.CD_MDLD_SGRO Format ms. AS MODALIDADE_DO_SEGURO, 
          t1.CD_ITEM_MDLD_SGRO Format is. AS ITEM_DO_SEGURO,
		t3.SG_UF AS ESTADO_DO_IMOVEL,
         t2.Ult_dt_contato, 
		 t1.NR_ANL AS NR_DA_PRE_SAC,
		 IFC((t1.IN_CT_FGTS_ATV='S'),'1','0') AS CT_FGTS_ATIVA, 
          IFC((t1.IN_TMP_MIN_CT_FGTS='S'),'1','0') AS tres_anos_ct_fgts,
          IFC((t1.IN_FUN_BB='S'),'1','0') AS FUNCI_BB, 
          IFC((t1.IN_PRGC_PCL='S'),'1','0') AS PARCELA_PULA, 
          IFC((t1.IN_PROP_CID_FNTO='S'),'1','0') AS POSSUI_IMOVEL_NA_CIDADE,
          IFC((t1.IN_RSDC_CID_FNTO='S'),'1','0') AS RESIDE_NA_CIDADE, 
          IFC((t1.IN_SMLC_TAXA_REF='S'),'1','0') AS SIMULACAO_COM_TR, 
		  IFC((t1.IN_EPRD_FNCD_BB='S'),'1','0') AS EMPREEND_FINANCIADO
      FROM IMOB.DADOS_IMOB_&ANOMES t1 left join Ultima_simulacao t4 on (t1.CPF=t4.CPF and t1.NR_SMLC_FNTO_IMRO=t4.NR_SMLC_FNTO_IMRO)
LEFT JOIN CART_IMOB t2 ON (t1.CPF=t2.CPF)
left JOIN DB2ARG.MUN t3 ON (t1.CD_MUN=t3.CD_MUN) 
	  WHERE NR_TELEFONE > 0 
 ORDER BY DATA_DA_SIMULACAO DESC;
;QUIT;


PROC SQL;
   CREATE TABLE DADOS_IMOB_CLIENTES AS 
   SELECT DISTINCT  t1.POSICAO, 
          t1.PREFDEP, 
          t1.CARTEIRA, 
          t1.MCI, 
          ifn(t1.NUMERO_DA_SIMULACAO=.,0,NUMERO_DA_SIMULACAO) as NUMERO_DA_SIMULACAO, 
          t1.DATA_DE_NASCIMENTO, 
          t1.CODIGO_DO_RISCO, 
          t1.DATA_DA_SIMULACAO, 
          t1.SEGMENTO_DO_CLIENTE, 
          t1.QTD_PARCELAS, 
          t1.CARENCIA, 
          
          t1.VALOR_DO_IMOVEL, 
          t1.RECURSOS_PROPRIOS, 
          t1.VALOR_DO_SUBSIDIO, 
          t1.VALOR_DAS_DESPESAS, 
          t1.VALOR_DO_FINANCIAMENTO, 
          t1.TAXA_DE_JUROS, 
          t1.RENDA_BRUTA_INFORMADA, 
          t1.DDD_TELEFONE, 
          t1.NR_TELEFONE, 
          t1.EMAIL, 
          t1.VALOR_DA_PRESTACAO, 
          t1.VALOR_DO_CET, 
          t1.VALOR_DO_CESH, 
          t1.VALOR_DO_IOF, 
          t1.VALOR_DO_MIP, 
          t1.VALOR_DO_DFI, 
          t1.CPF, 
          t1.LINHA_DE_CREDITO, 
          t1.MUNICIPIO, 
          t1.SISTEMA_DE_REPOSICAO, 
          t1.FINALIDADE_DO_BEM, 
          t1.PRODUTO_DO_SEGURO, 
          t1.MODALIDADE_DO_SEGURO, 
          t1.ITEM_DO_SEGURO, 
          t1.ESTADO_DO_IMOVEL, 
          t1.Ult_dt_contato, 
          t1.NR_DA_PRE_SAC,
		  t1.CT_FGTS_ATIVA, 
          t1.tres_anos_ct_fgts,
          t1.FUNCI_BB, 
          t1.PARCELA_PULA, 
          t1.POSSUI_IMOVEL_NA_CIDADE, 
          t1.RESIDE_NA_CIDADE, 
          t1.SIMULACAO_COM_TR,
			t1.EMPREEND_FINANCIADO 
      FROM WORK.DADOS_IMOB_01 t1
WHERE MCI NE 917164210;
QUIT;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_DADOS_IMOB_01 AS 
   SELECT DISTINCT t1.POSICAO, 
          t1.PREFDEP, 
          t1.CARTEIRA, 
          t1.MCI, 
          t1.DATA_DA_SIMULACAO, 
          ifC((t1.CT_FGTS_ATIVA='S'),'1','0') as CT_FGTS_ATIVA,
          t1.tres_anos_ct_fgts, 
          t1.EMPREEND_FINANCIADO, 
          t1.FUNCI_BB, 
          t1.PARCELA_PULA, 
          t1.POSSUI_IMOVEL_NA_CIDADE, 
          t1.RESIDE_NA_CIDADE, 
          t1.SIMULACAO_COM_TR
      FROM WORK.DADOS_IMOB_01 t1;
QUIT;

PROC SQL;
   CREATE TABLE QNT AS 
   SELECT /* COUNT_of_MCI */
   		  IFN(t2.CD_PRF_DEPE=.,4777,t2.CD_PRF_DEPE) as PREFDEP,
		  ifn(t2.NR_SEQL_CTRA=.,7002,t2.NR_SEQL_CTRA) AS CARTEIRA, 
            (COUNT(t1.MCI)) AS CONTACTADOS
      FROM Ultimo_contato t1
	  INNER JOIN CART_IMOB T2 ON (T1.MCI=T2.MCI)
GROUP BY 1,2
;
QUIT;



PROC SQL;
   CREATE TABLE WORK.DADOS_IMOB_02 AS 
   SELECT DISTINCT
   		  t1.PREFDEP,
		  t1.Carteira,
          /* COUNT_of_CPF */
          count(DISTINCT t1.MCI) AS QNT_SIMULACAO
      FROM DADOS_IMOB_01 t1
      GROUP BY t1.PREFDEP,
               t1.CARTEIRA;
QUIT;

DATA QNT_SIM;
MERGE  DADOS_IMOB_02 QNT;
BY PREFDEP CARTEIRA;
RUN;
PROC SORT DATA=QNT_SIM NODUPKEY; BY _ALL_; RUN;


PROC SQL;
   CREATE TABLE QNT_SIM AS 
   SELECT t1.PREFDEP, 
          t1.CARTEIRA, 
          /* SUM_of_QNT_SIMULACAO */
            (SUM(t1.QNT_SIMULACAO)) AS QNT_SIMULACAO, 
          /* SUM_of_CONTACTADOS */
            (SUM(t1.CONTACTADOS)) AS CONTACTADOS
      FROM WORK.QNT_SIM t1
      GROUP BY t1.PREFDEP,
               t1.CARTEIRA;
QUIT;

PROC SQL;
   CREATE TABLE QNT_TOTAL AS 
   SELECT distinct  
		t1.prefdep, 
          t1.carteira, 
          t1.Contactados, 
          T1.QNT_SIMULACAO
      FROM WORK.QNT_SIM t1
	  WHERE T1.PREFDEP NOT IN(4777)
	  group by 1,2
	 ;
QUIT;

PROC SQL;
   CREATE TABLE QNT_TOTAL1 AS 
   SELECT distinct  
		t1.prefdep, 
          0 as carteira, 
          sum(t1.Contactados) as Contactados, 
          sum(T1.QNT_SIMULACAO) as QNT_SIMULACAO
      FROM QNT_TOTAL t1
	  WHERE T1.PREFDEP NOT IN(4777)
	  group by 1,2
	 ;
QUIT;


PROC SQL;
CREATE TABLE QNT_TOTAL2 AS 
SELECT
INPUT(PREFSUPREG,4.) AS PREFDEP,
0 AS CARTEIRA,
SUM(Contactados) AS Contactados, 
SUM(QNT_SIMULACAO) AS QNT_SIMULACAO
FROM QNT_TOTAL A
INNER JOIN IGR.IGRREDE B ON (A.PREFDEP=INPUT(B.PREFDEP,4.))
WHERE PREFSUPREG NE "0000"
GROUP BY 1,2
;QUIT;


PROC SQL;
CREATE TABLE QNT_TOTAL3 AS 
SELECT
INPUT(PREFSUPEST, 4.) AS PREFDEP,
0 AS CARTEIRA,
SUM(Contactados) AS Contactados, 
SUM(QNT_SIMULACAO) AS QNT_SIMULACAO
FROM QNT_TOTAL A
INNER JOIN IGR.IGRREDE B ON (A.PREFDEP=INPUT(B.PREFDEP,4.))
WHERE PREFSUPEST NE "0000"
GROUP BY 1,2
;QUIT;


PROC SQL;
CREATE TABLE QNT_TOTAL4 AS 
SELECT
INPUT(PREFUEN, 4.) AS PREFDEP,
0 AS CARTEIRA,
SUM(Contactados) AS Contactados, 
SUM(QNT_SIMULACAO) AS QNT_SIMULACAO
FROM QNT_TOTAL A
INNER JOIN IGR.IGRREDE B ON (A.PREFDEP=INPUT(B.PREFDEP,4.))
WHERE PREFUEN NE "0000"
GROUP BY 1,2
;QUIT;


PROC SQL;
CREATE TABLE QNT_TOTAL5 AS 
SELECT
INPUT(PREFUEN,4.) AS PREFDEP,
0 AS CARTEIRA,
SUM(Contactados) AS Contactados, 
SUM(QNT_SIMULACAO) AS QNT_SIMULACAO
FROM QNT_TOTAL A
INNER JOIN IGR.IGRREDE B ON (A.PREFDEP=INPUT(B.PREFDEP,4.))
WHERE PREFUEN NE "0000"
GROUP BY 1,2
;QUIT;


PROC SQL;
CREATE TABLE QNT_TOTAL6 AS 
SELECT
8166 AS PREFDEP,
0 AS CARTEIRA,
SUM(Contactados) AS Contactados, 
SUM(QNT_SIMULACAO) AS QNT_SIMULACAO
FROM QNT_TOTAL5 A
GROUP BY 1,2
;QUIT;



DATA JUNTA_TUDO;
MERGE QNT_TOTAL QNT_TOTAL1 QNT_TOTAL2 QNT_TOTAL3 QNT_TOTAL4 QNT_TOTAL5 QNT_TOTAL6;
BY PREFDEP CARTEIRA;
RUN;
PROC SORT DATA=JUNTA_TUDO NODUPKEY; BY _ALL_; RUN;
%ZerarMissingTabela(JUNTA_TUDO);


PROC SQL;
   CREATE TABLE JUNTA_TUDO AS 
   SELECT t1.PREFDEP, 
          t1.CARTEIRA, 
          /* SUM_of_CONTACTADOS */
            (SUM(t1.CONTACTADOS)) AS CONTACTADOS, 
          /* SUM_of_QNT_SIMULACAO */
            (SUM(t1.QNT_SIMULACAO)) AS QNT_SIMULACAO
      FROM WORK.JUNTA_TUDO t1
      GROUP BY t1.PREFDEP,
               t1.CARTEIRA;
QUIT;


/**/
/**/
/*/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/*/
/*PROC SQL;*/
/*DROP TABLE COLS_SUM;*/
/*	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );*/
/*/*COLUNAS PARA SUMARIZACAO*/*/
/*		INSERT INTO COLS_SUM VALUES ('QNT_SIMULACAO', 'SUM', 'QNT_SIMULACAO');*/
/*		INSERT INTO COLS_SUM VALUES ('Contactados', 'SUM', 'Contactados');*/
/*QUIT;*/
/*%SumarizadorSimples(TblSASValores=QNT_TOTAL, TblSASColunas=COLS_SUM, NivelCarteira=1, TblSaida=SIMULACAO_01);*/
/*%ZerarMissingTabela(QNT_TOTAL);


PROC SQL;
   CREATE TABLE WORK.SIMULACAO_01 AS 
   SELECT 
   &DATA_HOJE. FORMAT=DateMysql. as POSICAO,
          t1.PrefDep, 
          t1.Carteira, 
          t1.QNT_SIMULACAO format 20.,
		  t1.Contactados format 20.,
		  (t1.Contactados/QNT_SIMULACAO)*100 format 20.2 as perc_contactados 
      FROM WORK.JUNTA_TUDO t1
	  WHERE T1.PREFDEP NOT IN(4777)
group by 1,2,3;
QUIT;
%ZerarMissingTabela(SIMULACAO_01)



x cd /;
x cd imob /dados/infor/producao/&nome_pasta;
x chmod -R 2777 *; /*ALTERAR PERMISÕES*/
x chown f9457977 -R ./; /*FIXA O FUNCI*/
x chgrp -R GSASBPA ./; /*FIXA O GRUPO*/



%LET Usuario=f9457977;
%LET Keypass=09PYMR3M7EJ5TJ11I25WPI2CS0IGOR;
PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('SIMULACAO_01', 'imob-digital');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('DADOS_IMOB_CLIENTES', 'clientes');
QUIT;
%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);

DATA IMOB.IMOB_REL_&ANOMES;
set DADOS_IMOB_01;
RUN;

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
