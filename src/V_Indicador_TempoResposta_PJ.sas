/*#############################################################################################################################
#####      PROGRAMA DE CÓDIGO SAS DE PROCESSAMENTO DE INDICADOR DE INDUÇÃO DA REDE DE NEGÓCIOS DO BANCO DO BRASIL       #######
###############################################################################################################################

VIVAR - Vice-Presidência de Distribuição de Varejo
DIVAR - Diretoria Comercial Varejo
GEREX METAS - Gerencia Executiva da Central de Metas de Varejo 
Gerência de Avaliação e Soluções

Os metadados e dados desde programa são confidenciais (#CONFIDENCIAL) com informações de infraestrutura estratégica, 
dados cadastrais e financeiros de clientes, oriundos de informações dos legados e bases do Banco do Brasil.

!!! ESTE PROGRAMA NÃO PODE SER ALTERADO, DIVULGADO OU DISTRIBUÍDO SEM A EXPRESSA AUTORIZAÇÃO DA GEREX METAS.

!!! É EXPRESSAMENTE PROIBIDA A DIVULGAÇÃO EXTERNA AO BANCO, DO PROGRAMA OU DOS DADOS POR ELE GERADOS.

/*############################################################################################################################*/

/*############################################################################################################################*/
/* PACOTE DE FUNÇÕES BASE ----------------------------------------------------------------------------------------------------*/
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

/* ---------------------------------------------------------------------------------------------------------------------------*/
/*############################################################################################################################*/
/*# BIBLIOTECAS - ############################################################################################################*/
%CONECTARDB2(MIV);
%CONECTARDB2(REL);
%CONECTARDB2(SGCEN);
%CONECTARDB2(MCI);
%CONECTARDB2(ATB);
%CONECTARDB2(DTM);
%CONECTARDB2(MST);

LIBNAME unc_ata "/dados/externo/UNC/ATA";
LIBNAME unc_gat "/dados/externo/UNC/GAT/TELEFONE";
LIBNAME AUX_TP "/dados/infor/producao/Tempo_Resposta_PF_PJ";
LIBNAME TRPJ "/dados/infor/producao/tempo_resposta";

/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/
DATA _NULL_;
	D1 = diaUtilAnterior(today());
	CALL SYMPUT('D1',COMPRESS(D1,' '));
	ANOMES = Put(D1, yymmn6.);
	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));
	MMAAAA=PUT(D1,mmyyn6.);
	CALL SYMPUT('MMAAAA', COMPRESS(MMAAAA,' '));
	INI_MES= Put(INTNX('month',DiaUtilAnterior(D1),0), yymmdd10.);
	CALL SYMPUT('INI_MES',COMPRESS(INI_MES,' '));
	D_ANT=MDY((MONTH(D1) - 1),1,YEAR(D1));
	CALL SYMPUT('D_ANT',COMPRESS(D_ANT,' '));
	ANOMES_ANT = Put(D_ANT, yymmn6.);
	CALL SYMPUT('ANOMES_ANT',COMPRESS(ANOMES_ANT,' '));
RUN;
%PUT &D1. &INI_MES.;

/* DADOS ---------------------------------------------------------------------------------------------------------------------*/
%LET NM_INDICADOR= Tempo de Resposta PJ;
%LET NR_INDICADOR=;
%LET TXT_FONTE=6062;
%LET MT_DEMANDANTE=F6065881;
%LET NM_DEMANDANTE=Karina Neves;
%LET MT_AUTOR=F9457977;
%LET NM_AUTOR=VANESSA;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=14:00;
%LET Excluir_data='06mar2019'd;

/* ---------------------------------------------------------------------------------------------------------------------------*/

/* CONCEITO ------------------------------------------------------------------------------------------------------------------

/*Reduzir o tempo médio de resposta e realizar contatos ativos com os clientes da carteira*/

/*Indicador possui 3 componentes: 
								- 1 FaleCom (Tempo de retorno)	Peso 20%;
								- 2 ATA (Tempo de Retorno) 		Peso 20%;
                                - 3 Rotação de Carteira			Peso 40%.

/* Apuração: MENSAL.



/*############################################################################################################################*/

/*############################################################################################################################*/




PROC SQL;
	CREATE TABLE TRPJ.AGENCIAS_ATA_&ANOMES. AS
		SELECT DISTINCT INPUT(t2.PrefDep, 4.) AS PREFIXO,
			t1.CD_UOR_BB AS UOR,
			t2.NomeDep,
			1 as ATA
		FROM DB2MST.UOR_BB t1
			INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON (t1.CD_UOR_BB = INPUT(t2.UOR, 9.))
				WHERE t1.CD_CRCT_ATDT_BB = 2
					ORDER BY 1;
QUIT;


/****** PÚBLICO CARTEIRA REMOTA MPE **************/

PROC SQL;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	CREATE TABLE WORK.CLIENTES_PJ AS 
		SELECT COD AS CD_CLI
			FROM connection to db2(			
				SELECT DISTINCT 
					T1.COD 
				FROM DB2MCI.CLIENTE t1
					WHERE t1.COD_TIPO = 2 AND t1.COD_MERC <> 3);
	disconnect from db2;;
QUIT;

%EncarteirarCNX(tabela_cli=CLIENTES_PJ, tabela_saida=encarteiramento, aaaamm=&AnoMes, so_ag_paa=1)


PROC SQL;
   CREATE TABLE WORK.ENCARTEIRADOS AS 
   SELECT DISTINCT 
          t1.PREFDEP_ATB AS CD_PRF_DEPE, 
          t1.CTRA_ATB AS NR_SEQL_CTRA_ATB, 
          t1.CD_CLI, 
          t1.COD_MERC
      FROM WORK.ENCARTEIRAMENTO t1
      WHERE t1.TP_CTRA_ATB = 328;
QUIT;

/******************************FALE COM**********************/

DATA _NULL_;
	CALL SYMPUT('DTDB2',"'"||Put(&d1., yymmdd10.)||"'");
RUN;

%PUT &DTDB2;
%Put &ANOMES;

DATA _NULL_;
	CALL SYMPUT('Filtro',"'"||"&INI_MES"||"'");
RUN;

%Put &Filtro;
OPTIONS MLOGIC MPRINT SYMBOLGEN;

PROC SQL;
	connect to db2 (authdomain=db2sgcen database=bdb2p04);
	CREATE TABLE TX_MIV AS 
		SELECT *
			FROM connection to db2(			
				SELECT DISTINCT 
					*
				FROM DB2MIV.TX_MSG_EXPS t1
					INNER JOIN DB2MIV.DBT_ELET_MSG_EXPS t2 ON (t2.CD_CLI_MSG_EXPS = t1.CD_CLI_MSG_EXPS and t2.NR_SEQL_DBT = t1.NR_SEQL_DBT)
						WHERE t2.CD_TIP_DBT = 3 AND DATE(T1.TS_CRIC_MSG) BETWEEN &FILTRO. and &DTDB2. );
	disconnect from db2;
	;
QUIT;

data tx;
	set tx_MIV;
	where cd_snlc_msg in (200 201 0 1 604) and CD_ITCE_CNL_ATDT is not missing;
run;

PROC SQL;
	CREATE TABLE TX_ENCARTEIRADOS_&anomes AS 
		SELECT *
			FROM WORK.TX t1
				INNER JOIN ENCARTEIRADOS T2 ON (T1.CD_CLI_PJ=T2.CD_CLI AND t1.cd_prf_depe and t2.cd_prf_depe and t1.nr_seql_ctra=t2.NR_SEQL_CTRA_ATB)
					WHERE (datepart(t1.TS_CRIC_MSG)) ne &Excluir_data.;
	;
QUIT;

PROC SQL;
	CREATE TABLE PROTOCOLO AS 
		SELECT DISTINCT 
			t1.CD_CLI,
			(datepart(t1.TS_CRIC_MSG)) FORMAT=ddmmyy10. LABEL="data" AS data, 
			(timepart(t1.TS_CRIC_MSG)) FORMAT=time8. LABEL="hora" AS hora,  
			t1.TS_CRIC_MSG AS TIMESTAMP, 
			t1.CD_USU_RSP_EST_MSG AS RESPONSAVEL, 
			t1.DT_LET_MSG format=ddmmyy10. as data_leitr, 
			t1.HR_LET_MSG as hora_leitr, 
			t1.CD_SNLC_MSG, 
			trim(compress(TX_MSG,,'kadst'))  as TX_MSG
		FROM TX_ENCARTEIRADOS_&anomes t1
				WHERE t1.CD_SNLC_MSG in (200 201)
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.PROTOCOLO01 AS 
		SELECT 

			t1.CD_CLI, 
			t1.data, 
			t1.hora, 
			t1.TIMESTAMP, 
			t1.RESPONSAVEL, 
			t1.data_leitr, 
			t1.hora_leitr, 
			t1.CD_SNLC_MSG, 
			COMPBL(TX_MSG) as TX_MSG
		FROM WORK.PROTOCOLO t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.PROTOCOLO02 AS 
		SELECT 	
			t1.CD_CLI, 
			t1.data, 
			t1.hora, 
			t1.TIMESTAMP, 
			t1.RESPONSAVEL, 
			t1.data_leitr, 
			t1.hora_leitr, 
			t1.CD_SNLC_MSG, 
			t1.TX_MSG,
			index(TX_MSG,"PROTOCOLO_INICIO") as a,
			substr(TX_MSG,calculated a+25,12) as PROTOCOLO_INICIO,
			index(TX_MSG,"PROTOCOLO_FIM") as B,
			substr(TX_MSG,calculated B+27,12) as PROTOCOLO_FIM
		FROM WORK.PROTOCOLO01 t1;
QUIT;

PROC SQL;
	CREATE TABLE PROTOCOLO_FINALIZADO AS 
		SELECT DISTINCT t1.CD_CLI, 
			t1.PROTOCOLO_FIM,
			T1.TX_MSG,
			T1.data AS DATA_ENC,
			T1.hora AS HR_ENC
		FROM WORK.PROTOCOLO02 t1
			WHERE t1.CD_SNLC_MSG = 201 and TX_MSG CONTAINS 'por';
QUIT;

PROC SQL;
	CREATE TABLE WORK.PROTOCOLO AS 
		SELECT DISTINCT
			t1.CD_CLI, 
			t1.data, 
			t1.hora FORMAT=TIME8., 
			t1.TIMESTAMP, 
			t1.RESPONSAVEL, 
			t1.data_leitr, 
			t1.hora_leitr, 
			t1.CD_SNLC_MSG, 
			t1.TX_MSG,
			input(t1.PROTOCOLO_INICIO, 12.) as protocolo,
			t2.TX_MSG as MSG_FIM,
			t2.DATA_ENC,
			t2.HR_ENC,
			t1.CD_SNLC_MSG
		FROM WORK.PROTOCOLO02 t1
			LEFT JOIN PROTOCOLO_FINALIZADO T2 ON (T1.CD_CLI=T2.CD_CLI AND T1.PROTOCOLO_INICIO=T2.PROTOCOLO_FIM)
				WHERE T1.CD_SNLC_MSG = 200 AND t1.TX_MSG NOT CONTAINS 'por';
QUIT;

PROC SQL;
	CREATE TABLE PROTOCOLO_PRIMEIRA_INTERACAO AS 
		SELECT DISTINCT t1.CD_CLI, 
			t1.data, 
			/* MIN_of_hora */
(t1.hora) FORMAT=TIME8. AS hora FROM WORK.PROTOCOLO t1 GROUP BY t1.CD_CLI, t1.data;
QUIT;

PROC SQL;
	CREATE TABLE WORK.PRIMEIRA_INTERACAO_CLIENTE AS 
		SELECT t1.CD_CLI, 
			t1.data, 
			t1.hora, 
			t1.TIMESTAMP, 
			t1.RESPONSAVEL, 
			t1.data_leitr, 
			t1.hora_leitr, 
			t1.CD_SNLC_MSG, 
			t1.TX_MSG, 
			t1.protocolo, 
			t1.MSG_FIM, 
			t1.DATA_ENC, 
			t1.HR_ENC
		FROM WORK.PROTOCOLO t1
			INNER JOIN PROTOCOLO_PRIMEIRA_INTERACAO T2 ON (T1.CD_CLI=T2.CD_CLI AND T1.DATA=T2.DATA AND T1.HORA=T2.HORA);
QUIT;

/*###########################*/
/*FALE COM - TEMPO DE RETORNO*/
/*###########################*/


PROC SQL;
	CREATE TABLE WORK.TX_MSG_EXPS AS 
		SELECT DISTINCT 
			t1.CD_PRF_DEPE as PREFDEP, 
			t1.NR_SEQL_CTRA_ATB AS CARTEIRA, 
			t1.CD_CLI,
			(datepart(t1.TS_CRIC_MSG)) FORMAT=ddmmyy10. LABEL="data" AS data, 
			(timepart(t1.TS_CRIC_MSG)) FORMAT=time8. LABEL="hora" AS hora,  
			t1.TS_CRIC_MSG AS TIMESTAMP, 
			t1.CD_USU_RSP_EST_MSG AS RESPONSAVEL, 
			t1.DT_LET_MSG format=ddmmyy10. as data_leitr, 
			t1.HR_LET_MSG as hora_leitr, 
			t1.CD_SNLC_MSG, 
			trim(compress(T1.TX_MSG,,'kadst'))  as TX_MSG
		FROM TX_ENCARTEIRADOS_&anomes t1

	;
QUIT;


PROC SQL;
	CREATE TABLE INTERACAO_CLIENTE AS 
		SELECT t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI, 
			ifn((t1.hora>'17:0:0't),diaUtilPosterior(t1.data),t1.data) format ddmmyy10. as  data, 
		(case 
			when t1.hora <'09:0:0't then '09:0:0't
			when t1.hora>'17:0:0't then '09:0:0't 
			else t1.hora 
		end)
		format time8. as hora_cliente,
		t1.RESPONSAVEL
	FROM WORK.TX_MSG_EXPS t1
where RESPONSAVEL is null;
QUIT;


PROC SQL;
	CREATE TABLE WORK.INTERACAO_CLIENTE AS 
		SELECT t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI,
			t1.data, 
			min(t1.hora_cliente) FORMAT=TIME8. AS hora_cliente, 
			t1.RESPONSAVEL
/*			t1.protocolo*/
		FROM WORK.INTERACAO_CLIENTE t1	  
					group by 1,2,3,4,6
	;
QUIT;

PROC SQL;
	CREATE TABLE INTERACAO_FUNCI_COM_PROTOCOLO AS 
		SELECT DISTINCT 
			t1.CD_CLI, 
			DATA_ENC, 
			MIN(HR_ENC) format time8. AS HR_ENC, 
			t1.MSG_FIM, 
			t1.protocolo
		FROM WORK.PRIMEIRA_INTERACAO_CLIENTE t1
			WHERE MSG_FIM CONTAINS 'por'
				group by 1,2,4,5;
QUIT;

PROC SQL;
	CREATE TABLE WORK.INTERACAO_BB00 AS 
		SELECT DISTINCT
			t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI, 
			ifn((t1.hora>'17:0:0't),diaUtilPosterior(t1.data),t1.data) format ddmmyy10. as  data, 
		(case 
			when t1.hora <'09:0:0't then '09:0:0't
			when t1.hora>'17:0:0't then '09:0:0't 
			else t1.hora 
		end)
		FORMAT=TIME8. AS hora, 
		t1.RESPONSAVEL
/*		t2.protocolo*/
	FROM WORK.TX_MSG_EXPS t1
/*		INNER JOIN INTERACAO_FUNCI_COM_PROTOCOLO T2 ON (T1.CD_CLI=T2.CD_CLI AND T1.DATA=T2.DATA_ENC)*/
			WHERE t1.responsavel NOT IS NULL and t1.CD_SNLC_MSG=0
				group by 1,2,3,6;
QUIT;

PROC SQL;
	CREATE TABLE INTERACAO_BB AS 
		SELECT t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI, 
			t1.data, 
			min(hora) format time8. as hora
/*			t1.protocolo*/
		FROM WORK.INTERACAO_BB00 t1
			group by 1,2,3,4;
QUIT;

/*PAREI AQUI*/
PROC SQL;
	CREATE TABLE WORK.fale_com AS 
		SELECT t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI, 
			t1.data, 
			t1.hora_cliente, 
			t2.hora  as hora_bb,
			t1.RESPONSAVEL,
			(IFN(t2.hora IS MISSING, '2:00:00't, 
			IFN(t2.hora LT t1.hora_cliente, ('17:0:0't - t1.hora_cliente), (t2.hora - t1.hora_cliente)))) FORMAT=TIME8. LABEL="tempo_start_2" AS tempo_start, 
			(WEEKDAY(t1.data)) AS dia_semana
		FROM WORK.INTERACAO_CLIENTE t1
			LEFT JOIN INTERACAO_BB t2 on (t1.prefdep=t2.prefdep and t1.carteira=t2.carteira and t1.cd_cli=t2.cd_cli and t1.data=t2.data)
				WHERE WEEKDAY(t1.data) IN(2, 3, 4, 5, 6);;
QUIT;

PROC SQL;
	CREATE TABLE WORK.TEMPO_FALE_COM AS 
		SELECT t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI, 
			t1.data, 
			t1.HORA_CLIENTE,
			t1.responsavel,
			(MIN(t1.tempo_start)) FORMAT=TIME8. AS tempo_start, 
			t1.dia_semana
		FROM WORK.FALE_COM t1
			GROUP BY 1,2,3,4,5,6,8;
QUIT;

PROC SQL;
	CREATE TABLE WORK.tempo_retorno_cliente AS 
		SELECT DISTINCT t1.prefdep, t1.CARTEIRA, t1.cd_cli, 
			t1.data, 
			t1.hora_cliente, 
			t1.responsavel, 
			t1.tempo_start
		FROM WORK.TEMPO_FALE_COM t1, WORK.FALE_COM t2
			WHERE (t1.cd_cli = t2.cd_cli AND t1.data = t2.data AND t1.tempo_start = t2.tempo_start AND t1.hora_cliente = 
				t2.hora_cliente) 
			ORDER BY t1.hora_cliente;
QUIT;

PROC SQL;
	CREATE TABLE FALECOM_CARTEIRA AS 
		SELECT DISTINCT t1.PREFDEP,
			t1.CARTEIRA AS CTRA,
			AVG(t1.tempo_start) FORMAT=TIME8. AS TEMPO_RETORNO_FALECOM
		FROM WORK.TEMPO_RETORNO_CLIENTE t1
			GROUP BY 1,2
				ORDER BY 1,2;
QUIT;

/*##############################################################*/
/*ATA*/
/*##############################################################*/
PROC SQL;
	CREATE TABLE TRPJ.AGENCIAS_ATA_&ANOMES. AS
		SELECT DISTINCT INPUT(t2.PrefDep, 4.) AS PREFIXO,
			t1.CD_UOR_BB AS UOR,
			t2.NomeDep,
			1 as ATA
		FROM DB2MST.UOR_BB t1
			INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON (t1.CD_UOR_BB = INPUT(t2.UOR, 9.))
				WHERE t1.CD_CRCT_ATDT_BB = 2
					ORDER BY 1;
QUIT;

PROC SQL;
	CREATE TABLE ATA_IMPLANTADO AS 
		SELECT DISTINCT PREFIXO
			FROM TRPJ.AGENCIAS_ATA_&ANOMES_ANT.
				WHERE ATA=1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.UNC_TB_GAT AS 
		SELECT t2.CD_PRF_DEPE,
			t2.NR_SEQL_CTRA_ATB AS NR_SEQL_CTRA, 
			t1.subordinada, 
			t1.protocoloAtend, 
			t1.clienteEncarteirado, 
			t1.mci, 
			t1.chaveAdmAtend, 
			t1.tipoCarteira, 
			t1.chaveAtendente, 
			t1.prefixoAtendente, 
			t1.statusAtend, 
			t1.tipoPessoaNaoCli, 
			t1.dataSolicitacaoAtend, 
			t1.horaSolicitacaoAtend, 
			t1.dataInicioAtend, 
			t1.horaInicioAtend, 
			t1.dataFimAtend, 
			t1.horaFimAtend,
			diasUteisEntreDatas(t1.dataSolicitacaoAtend, t1.dataFimAtend) AS qtd_dias_uteis,
			t1.dataUltimaAnotacao, 
			t1.horaUltimaAnotacao, 
			t1.horaAberturaAgencia, 
			t1.horaFechamentoAgencia
		FROM UNC_GAT.tel&ANOMES. t1
			INNER JOIN WORK.ENCARTEIRADOS t2 ON (t1.MCI = t2.CD_CLI)
			INNER JOIN ATA_IMPLANTADO T3 ON (T2.CD_PRF_DEPE=T3.PREFIXO)
				WHERE prefixoAtendente=CD_PRF_DEPE AND t1.statusAtend = 40	AND t1.horaSolicitacaoAtend BETWEEN "9:0:0"t AND "17:0:0"t AND t1.dataFimAtend<=&d1. AND horaFimAtend>=horaSolicitacaoAtend
					and dataSolicitacaoAtend ne &Excluir_data.
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.MCI_GAT AS 
		SELECT t1.CD_PRF_DEPE,
			t1.NR_SEQL_CTRA,
			t1.MCI,
			t1.dataSolicitacaoAtend, 
			t1.horaSolicitacaoAtend, 
			t1.dataInicioAtend, 
			t1.horaInicioAtend, 
			t1.dataFimAtend, 
			t1.horaFimAtend,
			/*   		  IFN(t1.qtd_dias_uteis = 1 AND (t1.horaInicioAtend - t1.horaSolicitacaoAtend) <= "0:20:0"t, 1, 0, 0) AS ATD_IMEDIATO,*/
	( IFN(t1.qtd_dias_uteis > 2, (t1.qtd_dias_uteis - 2)* "10:0:0"t, 0, 0) + IFN(t1.qtd_dias_uteis >= 2, ("17:0:0"t - t1.horaSolicitacaoAtend) + (t1.horaInicioAtend - "9:0:0"t), 0, 0) + IFN(t1.qtd_dias_uteis = 1, t1.horaInicioAtend - t1.horaSolicitacaoAtend, 0, 0) ) FORMAT=TIME8. AS TEMPO_RETORNO_GAT, t1.qtd_dias_uteis FROM WORK.UNC_TB_GAT t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.GAT_CARTEIRA AS 
		SELECT t1.CD_PRF_DEPE AS PREFDEP,
			t1.NR_SEQL_CTRA_ATB AS CTRA,
			AVG(t2.TEMPO_RETORNO_GAT) FORMAT=TIME8. AS TEMPO_RETORNO_GAT
		FROM WORK.ENCARTEIRADOS t1
			INNER JOIN WORK.MCI_GAT t2 ON (t1.CD_PRF_DEPE = t2.CD_PRF_DEPE AND t1.NR_SEQL_CTRA_ATB = t2.NR_SEQL_CTRA AND T1.CD_CLI=T2.MCI)
				WHERE t2.TEMPO_RETORNO_GAT IS NOT MISSING
					GROUP BY 1,2
						ORDER BY 1,2;
QUIT;

/*##############################################################*/
/*ROTACAO*/
/*##############################################################*/

PROC SQL;
	CREATE TABLE WORK.CONTATOS_FALECOM AS 
		SELECT DISTINCT 
			t1.prefdep,
			t1.carteira,
			t1.CD_CLI,
			max(data) format ddmmyy10. as dt_contato,
			'FaleCom' as Tipo_Contato
		FROM WORK.TX_MSG_EXPS t1
			WHERE DATA BETWEEN TODAY()-91 AND TODAY()-1 AND t1.responsavel NOT IS NULL and t1.CD_SNLC_MSG=0
			group by 1,2,3,5
;QUIT;

%ConectarDB2(BIC);
%Put &ANOMES;

DATA _NULL_;
	CALL SYMPUT('Filtro',"'"||"&INI_MES"||"'");
RUN;

%Put &Filtro;




PROC SQL;
	connect to db2 (authdomain=db2sgcen database=BDB2P04);
	CREATE TABLE TRPJ.BIC_&ANOMES AS 
		SELECT      
			CD_DEPE_RSP_ATDT,
			CD_CLI,
			TS_INRO_CLI
		from connection to db2(
			SELECT
				T2.CD_DEPE_RSP_ATDT,
				T1.CD_CLI,
				t1.TS_INRO_CLI
			FROM DB2BIC.INRO_HMNO_CLI t1
				INNER JOIN DB2BIC.AUX_INRO_CLI_ATU T2 ON (T1.CD_CLI=T2.CD_CLI AND T1.TS_INRO_CLI=T2.TS_INRO_CLI)
					WHERE t1.CD_FMA_CTT = 2 AND T2.CD_TIP_CNL=55 ;
						);
	disconnect from db2;
QUIT;


DATA trpj.BIC_ANTERIOR;
	SET TRPJ.BIC_ANTERIOR TRPJ.BIC_&ANOMES;
RUN;


PROC SQL;
	connect to db2 (authdomain=db2sgcen database=BDB2P04);
	CREATE TABLE TRPJ.BIC360_&ANOMES AS 
		SELECT      
			CD_DEPE_RSP_ATDT,
			CD_CLI,
			TS_INRO_CLI
		from connection to db2(
			SELECT
				T1.CD_DEPE_RSP_ATDT,
				T1.CD_CLI,
				t1.TS_INRO_CLI
			FROM DB2BIC.AUX_INRO_CLI_ATU t1
					WHERE (CD_TRAN_INRO_SIS IN ('GST00001', 'RPJ00001') AND CD_RSTD_INRO = 1 AND CD_ASNT_INRO = 6 AND CD_SUB_ASNT_INRO = 49) ;
						);
	disconnect from db2;
QUIT;



DATA TRPJ.JUNTA_BIC360;
	SET TRPJ.JUNTA_BIC360 TRPJ.BIC360_&ANOMES;
RUN;



PROC SQL;
	CREATE TABLE WORK.BIC AS 
		SELECT DISTINCT 
			t2.cd_prf_depe AS PREFDEP,
			t2.NR_SEQL_CTRA_ATB AS CARTEIRA,
			t1.CD_CLI,
			max(datepart(TS_INRO_CLI)) format ddmmyy10.  as dt_contato,
			'BIC/telefone' as Tipo_Contato
		FROM TRPJ.BIC_ANTERIOR t1
			INNER JOIN ENCARTEIRADOS T2 ON (T1.CD_CLI=T2.CD_CLI AND t1.CD_DEPE_RSP_ATDT=t2.cd_prf_depe)
            WHERE DATE(TS_INRO_CLI) BETWEEN DATE(TODAY()-91) AND DATE(TODAY()-1)
			group by 1,2,3,5
;
QUIT;


PROC SQL;
	CREATE TABLE WORK.BIC_360 AS 
		SELECT DISTINCT 
			t2.cd_prf_depe AS PREFDEP,
			t2.NR_SEQL_CTRA_ATB AS CARTEIRA,
			t1.CD_CLI,
			max(datepart(TS_INRO_CLI)) format ddmmyy10.  as dt_contato,
			'BIC/Clientes 360' as Tipo_Contato
		FROM TRPJ.JUNTA_BIC360 t1
			INNER JOIN ENCARTEIRADOS T2 ON (T1.CD_CLI=T2.CD_CLI AND t1.CD_DEPE_RSP_ATDT=t2.cd_prf_depe)
            WHERE DATE(TS_INRO_CLI) BETWEEN DATE(TODAY()-91) AND DATE(TODAY()-1)
			group by 1,2,3,5
;
QUIT;

DATA JUNTA_ROTACAO;
	SET CONTATOS_FALECOM BIC BIC_360;
RUN;

PROC SQL;
	CREATE TABLE WORK.ROTACAO AS 
		SELECT DISTINCT 
			t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI,
			max(dt_contato) format ddmmYY10. as dt_contato
		FROM WORK.JUNTA_ROTACAO t1
        group by 1,2,3;
QUIT;


PROC SQL;
	CREATE TABLE WORK.ROTACAO AS 
		SELECT DISTINCT 
			t1.PREFDEP, 
			t1.CARTEIRA, 
			t1.CD_CLI,
			t1.DT_CONTATO,
			T1.TIPO_CONTATO
		FROM WORK.JUNTA_ROTACAO t1
INNER JOIN ROTACAO T2 ON (T1.PREFDEP=T2.PREFDEP AND T1.CARTEIRA=T2.CARTEIRA AND T1.CD_CLI=T2.CD_CLI AND T1.DT_CONTATO=T2.DT_CONTATO);
QUIT;

PROC SQL;
	CREATE TABLE QUANTITIVO_ROTACAO AS 
		SELECT DISTINCT 
			t1.cd_prf_depe, 
			t1.NR_SEQL_CTRA_ATB AS CTRA, 
			t1.CD_CLI,
			ifn(T2.CD_CLI is missing,0,1)  AS CONTATO,
			t2.dt_contato,
			t2.tipo_contato
		FROM WORK.ENCARTEIRADOS t1
			LEFT JOIN ROTACAO T2 ON (T1.cd_prf_depe=T2.PREFDEP AND T1.NR_SEQL_CTRA_ATB=T2.CARTEIRA and t1.cd_cli=t2.cd_cli);
QUIT;

PROC SQL;
	CREATE TABLE CARTEIRA_ROTACAO AS 
		SELECT 
			t1.CD_PRF_DEPE AS PREFDEP, 
			t1.CTRA, 
			count(CD_CLI) as orcado_rotacao, 
			sum(CONTATO) as realizado_rotacao,
			sum(CONTATO)/count(CD_CLI)*100 FORMAT 19.2 as pct_rotacao
		FROM WORK.QUANTITIVO_ROTACAO t1
			group by 1,2;
QUIT;

DATA JUNTA_COMPONENTES;
	SET FALECOM_CARTEIRA GAT_CARTEIRA CARTEIRA_ROTACAO;
RUN;

PROC SQL;
	CREATE TABLE RESULTADO_PREFIXO AS 
		SELECT 
			t1.PREFDEP, 
			t1.CTRA, 
			SUM(TEMPO_RETORNO_FALECOM) FORMAT TIME8. AS TEMPO_RETORNO_FALECOM, 
			SUM(TEMPO_RETORNO_GAT) FORMAT TIME8. AS TEMPO_RETORNO_GAT,
			SUM(orcado_rotacao) AS ORCADO_ROTACAO,
			SUM(realizado_rotacao) AS REALIZADO_ROTACAO
		FROM WORK.JUNTA_COMPONENTES t1
			GROUP BY 1,2;
QUIT;

PROC SQL;
	CREATE TABLE WORK.COM_RESPOSTA AS 
		SELECT 
			t1.PREFDEP, 
			t1.CTRA, 
			IFN(TEMPO_RETORNO_FALECOM IS MISSING,0,1) AS  TEMPO_RETORNO_FALECOM,
			IFN(TEMPO_RETORNO_GAT IS MISSING,0,1) AS  TEMPO_RETORNO_GAT,
			IFN(ORCADO_ROTACAO IS MISSING,0,1) AS ORCADO_ROTACAO
		FROM WORK.RESULTADO_PREFIXO t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.PREFIXOS_COM_RESPOSTA AS 
		SELECT t1.PREFDEP, 
			t1.CTRA, 
			(TEMPO_RETORNO_FALECOM+TEMPO_RETORNO_GAT+ORCADO_ROTACAO) AS PREFIXOS
		FROM WORK.COM_RESPOSTA t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.PARA_SUMARIZAR AS 
		SELECT t1.PREFDEP, 
			t1.CTRA, 
			t1.TEMPO_RETORNO_FALECOM, 
			IFN(TEMPO_RETORNO_FALECOM IS MISSING,0,1) AS POSSUI_FALECOM,
			t1.TEMPO_RETORNO_GAT, 
			IFN(TEMPO_RETORNO_GAT IS MISSING,0,1) AS POSSUI_GAT,
			t1.ORCADO_ROTACAO, 
			t1.REALIZADO_ROTACAO, 
			IFN(ORCADO_ROTACAO IS MISSING,0,1) AS POSSUI_ROTACAO
		FROM WORK.RESULTADO_PREFIXO t1
			INNER JOIN PREFIXOS_COM_RESPOSTA T2 ON (T1.PREFDEP=T2.PREFDEP AND T1.CTRA=T2.CTRA)
				WHERE PREFIXOS NE 0
	;
QUIT;

PROC SQL;
	DROP TABLE COLS_SUM;
	CREATE TABLE COLS_SUM (Coluna CHAR(50), Tipo CHAR(10), Alias CHAR(50) );

	/*COLUNAS PARA SUMARIZACAO*/
	INSERT INTO COLS_SUM VALUES ('TEMPO_RETORNO_FALECOM', 'SUM', 'TEMPO_RETORNO_FALECOM');
	INSERT INTO COLS_SUM VALUES ('POSSUI_FALECOM', 'SUM', 'POSSUI_FALECOM');
	INSERT INTO COLS_SUM VALUES ('TEMPO_RETORNO_GAT', 'SUM', 'TEMPO_RETORNO_GAT');
	INSERT INTO COLS_SUM VALUES ('POSSUI_GAT', 'SUM', 'POSSUI_GAT');
	INSERT INTO COLS_SUM VALUES ('ORCADO_ROTACAO', 'SUM', 'ORCADO_ROTACAO');
	INSERT INTO COLS_SUM VALUES ('REALIZADO_ROTACAO', 'SUM', 'REALIZADO_ROTACAO');
	INSERT INTO COLS_SUM VALUES ('POSSUI_ROTACAO', 'SUM', 'POSSUI_ROTACAO');
QUIT;

%SumarizadorCNX(TblSASValores=PARA_SUMARIZAR, TblSASColunas=COLS_SUM, NivelCTRA=1, PAA_PARA_AGENCIA=0, TblSaida=RESULTADO, AAAAMM=&ANOMES);

PROC SQL;
	CREATE TABLE WORK.RESULTADO AS 
		SELECT t1.UOR, 
			t1.PREFDEP,
			t1.CTRA, 
			T1.POSSUI_FALECOM,
			T1.POSSUI_GAT,
			T1.POSSUI_ROTACAO,
			IFN(CTRA=0,TEMPO_RETORNO_FALECOM/POSSUI_FALECOM,TEMPO_RETORNO_FALECOM) FORMAT TIME8. AS TEMPO_RETORNO_FALECOM,
			IFN(CTRA=0,TEMPO_RETORNO_GAT/POSSUI_GAT,TEMPO_RETORNO_GAT) FORMAT TIME8. AS TEMPO_RETORNO_GAT,
			t1.ORCADO_ROTACAO, 
			t1.REALIZADO_ROTACAO,
			(REALIZADO_ROTACAO/ORCADO_ROTACAO)*100 FORMAT 19.2 AS PCT_ROTACAO
		FROM WORK.RESULTADO t1
			GROUP BY 1,2,3;
QUIT;

PROC SQL;
	CREATE TABLE PONTUACAO_GERAL AS 
		SELECT t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.TEMPO_RETORNO_FALECOM, 
		(CASE 
			WHEN TEMPO_RETORNO_FALECOM>="0:0:0"t AND TEMPO_RETORNO_FALECOM < "1:0:0"t THEN 25
			WHEN (TEMPO_RETORNO_FALECOM >="1:0:0"t AND TEMPO_RETORNO_FALECOM <"1:15:0"t) THEN 20
			WHEN (TEMPO_RETORNO_FALECOM >="1:15:0"t AND TEMPO_RETORNO_FALECOM<"1:30:0"t) THEN 15
			WHEN (TEMPO_RETORNO_FALECOM >="1:30:0"t AND TEMPO_RETORNO_FALECOM<"1:45:0"t) THEN 10
			WHEN (TEMPO_RETORNO_FALECOM >="1:45:0"t AND TEMPO_RETORNO_FALECOM<"2:0:0"t)  THEN 5
			WHEN TEMPO_RETORNO_FALECOM >="2:0:0"t THEN 0 
			ELSE . 
		END)
	AS PESO_FALECOM,
		t1.TEMPO_RETORNO_GAT,
	(CASE 
		WHEN TEMPO_RETORNO_GAT>="0:0:0"t AND TEMPO_RETORNO_GAT < "1:0:0"t THEN 25
		WHEN (TEMPO_RETORNO_GAT >="1:0:0"t AND TEMPO_RETORNO_GAT <"1:15:0"t) THEN 20
		WHEN (TEMPO_RETORNO_GAT >="1:15:0"t AND TEMPO_RETORNO_GAT<"1:30:0"t) THEN 15
		WHEN (TEMPO_RETORNO_GAT >="1:30:0"t AND TEMPO_RETORNO_GAT<"1:45:0"t) THEN 10
		WHEN (TEMPO_RETORNO_GAT >="1:45:0"t AND TEMPO_RETORNO_GAT<"2:0:0"t)  THEN 5
		WHEN TEMPO_RETORNO_GAT >="2:0:0"t THEN 0
		ELSE . 
	END)
AS PESO_GAT,
	t1.ORCADO_ROTACAO, 
	t1.REALIZADO_ROTACAO, 
	t1.PCT_ROTACAO,
(CASE 
	WHEN PCT_ROTACAO >=0 AND PCT_ROTACAO <=65 THEN 0
	WHEN (PCT_ROTACAO >65 AND PCT_ROTACAO<=75) THEN 10
	WHEN (PCT_ROTACAO >75 AND PCT_ROTACAO<=80) THEN 20
	WHEN (PCT_ROTACAO >80 AND PCT_ROTACAO<=85) THEN 30
	WHEN (PCT_ROTACAO >85 AND PCT_ROTACAO<90)  THEN 40
	WHEN PCT_ROTACAO >=90 THEN 50
	ELSE . 
END)
AS PESO_ROTACAO,
T1.POSSUI_FALECOM,
T1.POSSUI_GAT,
T1.POSSUI_ROTACAO
FROM WORK.RESULTADO t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.REDISTRIBUICAO_PESO AS 
		SELECT t1.UOR, 
			t1.PREFDEP, 
			t1.CTRA, 
			t1.TEMPO_RETORNO_FALECOM, 
			t1.PESO_FALECOM, 
			t1.TEMPO_RETORNO_GAT, 
			t1.PESO_GAT, 
			t1.ORCADO_ROTACAO, 
			t1.REALIZADO_ROTACAO, 
			t1.PCT_ROTACAO, 
			t1.PESO_ROTACAO AS PONTUACAO,
		(CASE 
			WHEN POSSUI_FALECOM=0 AND POSSUI_GAT=0 THEN PESO_ROTACAO*2
			WHEN POSSUI_FALECOM>0 AND POSSUI_GAT=0 THEN PESO_ROTACAO*1.75
			WHEN POSSUI_FALECOM=0 AND POSSUI_GAT>0 THEN PESO_ROTACAO*1.75 
			ELSE PESO_ROTACAO 
		END)
	AS PESO_ROTACAO
		FROM WORK.PONTUACAO_GERAL t1;
QUIT;



DATA CONSOLIDADO;
SET REDISTRIBUICAO_PESO;
ORCADO = 80;
RUN;

PROC SQL;
   CREATE TABLE WORK.PONTUACAO AS 
   SELECT DISTINCT t1.UOR, 
          t1.PREFDEP, 
          t1.CTRA, 
          IFN(PESO_FALECOM IS MISSING,0,PESO_FALECOM) as PESO_FALECOM, 
          IFN(PESO_GAT IS MISSING,0,PESO_GAT) as PESO_GAT, 
          IFN(PESO_ROTACAO IS MISSING,0, PESO_ROTACAO) as PESO_ROTACAO
      FROM WORK.CONSOLIDADO t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.PONTUACAO_II AS 
   SELECT t1.UOR, 
          t1.PREFDEP, 
          t1.CTRA, 
          (PESO_FALECOM+PESO_GAT+PESO_ROTACAO) as REALIZADO
      FROM WORK.PONTUACAO t1
GROUP BY 1,2,3
ORDER BY 1,2,3;
QUIT;

PROC SQL;
   CREATE TABLE CONSOLIDADO_REL AS 
   SELECT 
          &D1. FORMAT YYMMDD10. AS POSICAO,
          t1.UOR, 
          t1.PREFDEP, 
          t1.CTRA, 
          t1.TEMPO_RETORNO_FALECOM, 
          t1.PESO_FALECOM as pontos_falecom, 
          t1.TEMPO_RETORNO_GAT, 
          t1.PESO_GAT as pontos_gat, 
          t1.ORCADO_ROTACAO as qtd_clientes_rotacao, 
          t1.REALIZADO_ROTACAO as rlz_contatos_rotacao, 
          t1.PCT_ROTACAO as pc_rotacionado, 
          t1.PESO_ROTACAO as pontos_rotacao,
		  T2.REALIZADO FORMAT 17.2 as pontuacao_total
      FROM WORK.CONSOLIDADO t1
INNER JOIN PONTUACAO_II T2 ON (T1.UOR=T2.UOR AND T1.PREFDEP=T2.PREFDEP AND T1.CTRA=T2.CTRA)
;
;
QUIT;

/*CONEXÃO*/
/*AVALIACAO-RELACIONAMENTO*/


PROC SQL;
   CREATE TABLE CONEXAO AS 
   SELECT DISTINCT t1.POSICAO, 
          t1.UOR, 
          t1.PREFDEP, 
          t1.CTRA,
          INPUT(t2.TD_SINERGIA, d4.) AS TipDepCnx,
          t1.pontuacao_total as realizado
      FROM WORK.CONSOLIDADO_REL t1
INNER JOIN IGR.IGRREDE_&ANOMES. t2 ON T1.PREFDEP = INPUT(t2.PREFDEP, d4.);
;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CONEXAO_&ANOMES AS 
   SELECT t1.POSICAO, 
          t1.UOR, 
          t1.PREFDEP, 
          ifn(TIPDEPCNX=2 and CTRA=0,7002,ctra) as CTRA,
          IFN(TIPDEPCNX=2,1,TipDepCnx) AS TipDepCnx, 
          t1.REALIZADO
      FROM WORK.CONEXAO t1	  
      ;
QUIT;



PROC SQL;
    CREATE TABLE CONEXAO AS
        SELECT
            '2000153'
            ||"&Txt_Fonte"
            ||REPEAT(' ',45)
            ||COMPRESS(PUT(t1.PrefDep,Z4.))
            ||COMPRESS(PUT(t1.CTRA,Z5.))
            ||"&ANOMES"
            ||put(t1.TipDepCnx,z4.)
            ||'+'
            ||PUT(ABS(t1.REALIZADO)*100,z13.)
            ||'F9457977'
            ||COMPRESS(PUT(Today(), ddmmyy10.))
            ||'N' AS L
        FROM WORK.CONEXAO_&ANOMES t1       
;QUIT;


%GerarBBM(TabelaSAS=CONEXAO, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=M6062);



/*############################################################################################################################*/
/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS #################################*/

data trpj.CONSOLIDADO_REL_&anomes;
set CONSOLIDADO_REL;
run;

data trpj.QUANTITIVO_ROTACAO_&anomes;
set QUANTITIVO_ROTACAO;
run;


data trpj.MCI_GAT_&anomes;
set MCI_GAT;
run;

DATA TRPJ.TEMPO_RETORNO_CLIENTE_&ANOMES;
SET TEMPO_RETORNO_CLIENTE;
RUN;



LIBNAME EXT_ANLT '/dados/externo/DIVAR/METAS/conexao/19S2/';

DATA EXT_ANLT.PRINCIPAL_TRPJ_6062_&anomes.;
    SET trpj.CONSOLIDADO_REL_&anomes.;
RUN;


DATA EXT_ANLT.DETALHE_TRPJ_GAT6062_&anomes. ;
    SET trpj.MCI_GAT_&anomes;
RUN;


DATA EXT_ANLT.DETALHE_TRPJ_FALECOM6062_&anomes.;
    SET TRPJ.TEMPO_RETORNO_CLIENTE_&ANOMES;
RUN;


DATA EXT_ANLT.DETALHE_TRPJ_ROTACAO6062_&anomes.;
    SET trpj.QUANTITIVO_ROTACAO_&anomes.;
RUN;
