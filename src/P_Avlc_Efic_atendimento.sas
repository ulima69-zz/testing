
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

/* DADOS ---------------------------------------------------------------------------------------------------------------------*/
%LET NM_INDICADOR=Eficiência do Atendimento;
%LET NR_INDICADOR=txtfon6066;
%LET MT_DEMANDANTE=F6320998;
%LET NM_DEMANDANTE=LUCAS ACCORINTE;	
%LET MT_AUTOR=F8176496;
%LET NM_AUTOR=PAULO;
%LET VIGENCIA=2019/2;
%LET HR_EXECUCAO=06:00;
/* ---------------------------------------------------------------------------------------------------------------------------*/

/* CONCEITO ------------------------------------------------------------------------------------------------------------------

Percentual de atendimentos negociais realizados dentro da Diretiva Nacional  UNV (20 minutos em dias normais e 30 minutos em dias de pico), 
ponderados  pelo nível de serviço de atendimento.  É composto por 2 indicadores:  TAP - Taxa de Atendimentos no Prazo  NS - Nível de Serviço 

Informações Adicionais:
Composto por 2 indicadores:  TAP - Taxa de Atendimentos no Prazo: 
(Quantidade de senhas atendidas no  prazo / Quantidade de senhas atendidas)  NS - Nível de Serviço: (Quantidade de senhas atendidas / Quantidade de  senhas emitidas).  

/* ---------------------------------------------------------------------------------------------------------------------------*/
/*############################################################################################################################*/

/*############################################################################################################################*/
/*# CKECKIN ##################################################################################################################*/
%indCheckIn();
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# BIBLIOTECAS - ############################################################################################################*/

libname ind_52 "/dados/infor/conexao/2018/&ind";
libname lib "/dados/infor/producao/tempo_atendimento";
libname gcn "/dados/externo/GECEN";
libname gat "/dados/infor/bases/gat";

%conectardb2 (gat, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (arg, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (uor, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (arh, AUTHDOMAIN=DB2SGCEN);
%conectardb2 (dwh, AUTHDOMAIN=DB2SGCEN);
libname aux ORACLE USER=sas_gecen PASSWORD=Gecen77 PATH="sas_dirco" SCHEMA="atb_sinergia";

/*# BIBLIOTECAS - ############################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# VARIÁVEIS - ##############################################################################################################*/


%diasUteis(%sysfunc(today()), 5);
%GLOBAL DiaUtil_D1;
/*  %LET DIAUTIL_D1 = '30apr2019'D;  */

data _null_; call symput('Dataatu',"'"||put (&DiaUtil_D1, FINDFDD10.)||"'");run;
%put &Dataatu;

data arq;
    format dia yymmdd6.
           AnoMes yymmn6.
		   AnoMes_1 yymmn6.
			Mesano mmyyn6.
			ano2 YEAR2.;
    dia = &diaUtil_d1;
    AnoMes = &diaUtil_d1;
	AnoMes_1 = &diaUtil_d2;
	dia_semana=weekday(today());
	Mesano = &diaUtil_d1;
	MES=MONTH(&diaUtil_d1);
	ano2 = &diautil_d1;
	semtr = ifn (mes in (1, 2, 3, 4, 5, 6),1,2);
run;

proc sql;

    select distinct dia into: dia separated by ', '
    from work.arq;
    select distinct AnoMes into: AnoMes separated by ', '
    from work.arq;
	select distinct AnoMes_1 into: AnoMes_1 separated by ', '
    from work.arq;
	select distinct dia_semana into: dia_semana separated by ', '
    from work.arq;
	select distinct Mesano into: Mesano separated by ', '
    from work.arq;
	select distinct Mes into: Mes separated by ', '
    from work.arq;
	select distinct ano2 into: ano2 separated by ', '
    from work.arq;
	select distinct semtr into: semtr separated by ', '
    from work.arq;
quit;
%put &Mes;


DATA _NULL_; call symput('INICIO',"'"||put ((intnx('month',&diautil_d1, 0, 'begin')), FINDFDD10.)||"'");run;
%PUT &INICIO;
DATA _NULL_; call symput('FIM',"'"||put ((intnx('month',&diautil_d1, 0, 'end')), FINDFDD10.)||"'");run;
%PUT &FIM;




proc sql;
    SELECT (MAX(t1.DataMovimento)) AS DataMovimento into: ultimodia separated by ', '
    FROM ROT.TBL_DATAS_PROCESSAMENTO t1
	where DataMovimento between (intnx('month',&diautil_d1, 0, 'begin')) and (intnx('month',&diautil_d1, 0, 'end'))
and Dia_Util = 'S';
quit;
%put &ultimodia;


/*# VARIÁVEIS - ##############################################################################################################*/
/*############################################################################################################################*/



/*############################################################################################################################*/
/*# CLIENTES DO ESCOPO - #####################################################################################################*/

/*%BuscarPrefixosIndicador(IND=&NR_INDICADOR., MMAAAA=&MMAAAA., NIVEL_CTRA=1, SO_AG_PAA=0);*/


/*# CLIENTES DO ESCOPO - #####################################################################################################*/



/*############################################################################################################################*/
/*# TABELAS PROCESSAMENTO - ##################################################################################################*/

PROC SQL;
	CREATE TABLE orc_&anomes AS 
		SELECT distinct t1.TX_FON ,
		    ifc (t1.CD_PRF=.,'8166',(put (t1.CD_PRF, z4.))) as prefdep, 
			ifc (cd_uor=0,'000018525',(put(cd_uor, z9.))) as uor,
			t1.CRTA as cart, 
			t1.VL as valor, 
			t1.ANOMES,
			INPUT(DT_APRC, DDMMYY10.) AS DT_APRC
		FROM AUX.VW_FON_153 t1
			where t1.ANOMES=&anomes
				and t1.TX_FON = "6065"
				GROUP BY 1, 2, 3, 4, 6
				HAVING MAX(DT_APRC) = DT_APRC
	;
QUIT;

PROC SQL;
   CREATE TABLE orc_&anomes AS 
   SELECT distinct t1.TX_FON, 
          t1.uor, 
          t1.cart, 
          t1.valor as orc, 
          t1.ANOMES, 
          input(t2.PrefDep, 4.) as prefixo
      FROM ORC_&anomes t1
           INNER JOIN igr.igrrede_&anomes t2 ON (t1.uor = t2.UOR);
QUIT;



PROC SQL;
   CREATE TABLE WORK.HR_FCN_UOR AS 
   SELECT input(t2.prefdep, 4.) as prefdep,
		  t1.CD_UOR, 
          t1.HR_INC_FCN_EXNO
      FROM DB2UOR.HR_FCN_UOR t1
	  inner join igr.igrrede t2 on (t1.cd_uor = input(uor, 9.))
      WHERE t1.HR_INC_FCN_EXNO NOT = '0:0:0't
      ORDER BY t1.CD_UOR;
QUIT;

PROC SQL;
   CREATE TABLE WORK.mci_funci AS 
   SELECT 'F'||put (t1.MATRICULA_215, z7.) as matricula,
          t1.LOCALIZACAO_215, 
          t1.CODIGO_MCI_215
      FROM DB2ARH.ARH215_CADASTRO_BASICO t1
where t1.LOCALIZACAO_215 <> 0
and t1.CODIGO_MCI_215 <> 0
order by 2, 3;
QUIT;


PROC SQL;
   CREATE TABLE WORK.ATDT AS 
   SELECT CD_SNH_ATDT as TX_UTZD_SNH_ATDT,
   CHV_ATD_ATDT as CD_CHV_ATD,
   cd_cli,
   CD_EST_PTL_ATDT as CD_EST_ATDT,
   CD_TIP_ESP_ATDT as CD_TIP_LCL_ATDT,
   PREF_ATDT as CD_PRF_DEPE,
   PREF_SLCT as cd_depe,
   CD_TIP_CTRA,
   DT_SLCT_ATDT as DT_ATDT,
   case 
			when CD_TIP_OGM_SLCT = 4 then t1.HR_CHGD_DEPE
			else T1.HR_INC_EPR  
		end FORMAT=E8601TM8.
	as HR_CHGD_AG,   
   HR_INC_ATDT,
   case 
		when CD_TIP_OGM_SLCT = 4 and CD_EST_PTL_ATDT = 11 then 1
		else 0 
	end as sem_checkin,
	HR_FIM_ATDT,
	case 
		when CD_EST_PTL_ATDT = 40 and substr(CHV_ATD_ATDT, 1, 1) <> 'F' then 1
		when CD_EST_PTL_ATDT = 40 and CD_CHV_ATD in ('F0000000', 'F9999999') then 1 
		else 0 
	end 
as encerrada_sist,
case 
		when CD_TIP_CTRA in (31, 32, 33, 34, 35, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 54, 79, 900) then 1 
		else 0 
	end 
as prvt,
UOR_ATDT as uor,
ifn (UOR_RLZC_ATDT=. and CD_EST_PTL_ATDT in (15, 20) or CD_TIP_OGM_SLCT = 4 and CD_EST_PTL_ATDT = 30,1,0) as exclui
      FROM GAT.ATDT_GAT_&anomes t1
		WHERE CD_TIP_ESP_ATDT = 1 AND CD_TIP_OGM_SLCT not in (5);
QUIT;

data ATDT(drop=exclui);
set ATDT;
if exclui = 0;
run;

/* INDICADOR NÃO UTILIZA ENCARTEIRAMENTO DE CLIENTES

 %EncarteirarCNX(tabela_cli=TESTE, tabela_saida=ENCARTEIRADOS, aaaamm=&aaaamm.);

*/

PROC SQL;
	CREATE TABLE ATDT1 AS 
		SELECT TX_UTZD_SNH_ATDT,
   		  CD_CHV_ATD,CD_CLI, 
			CD_EST_ATDT, 
			CD_TIP_LCL_ATDT, 
			CD_PRF_DEPE, 
			CD_TIP_CTRA, 
			DT_ATDT,
			HR_CHGD_AG,
			HR_INC_ATDT,
			sem_checkin,
			encerrada_sist,
			matricula,
			prvt,
			ifn (c.LOCALIZACAO_215 <> . and c.CODIGO_MCI_215 <> .,1,0) as funci_do_prefixo,
		case 
			when HR_CHGD_AG>HR_INC_FCN_EXNO then HR_CHGD_AG
			else HR_INC_FCN_EXNO 
		end 
		FORMAT=E8601TM8. as HR_CHGD_AG_NOVO,
		HR_FIM_ATDT,
		HR_INC_ATDT-CALCULATED HR_CHGD_AG_NOVO FORMAT=E8601TM8. AS TEMPO_ESPERA,
		ifn (CD_EST_ATDT=40 and HR_FIM_ATDT-HR_INC_ATDT<='00:00:60't,1,0) as menos_1min,
		HR_FIM_ATDT-HR_INC_ATDT FORMAT=E8601TM8. as tma
	FROM ATDT A
		LEFT JOIN HR_FCN_UOR B ON (A.CD_PRF_DEPE=B.PREFDEP)
		left join mci_funci c on (A.CD_PRF_DEPE=c.LOCALIZACAO_215 and a.cd_cli=c.CODIGO_MCI_215)
where HR_CHGD_AG <> .;
QUIT;


PROC SQL;
	CONNECT TO DB2 (AUTHDOMAIN=DB2SGCEN DATABASE=BDB2P04);
	CREATE TABLE WORK.dias_pico AS select 
		input(b.prefdep, 4.) as prefdep,
		a.*
	FROM CONNECTION TO DB2(
		SELECT t1.CD_DEPE, 
			t1.CD_TIP_CFG, 
			t1.DT_REF,
			t1.IN_CFG_TRML
		FROM DB2DWH.PRM_CFG_AG t1
			WHERE t1.CD_TIP_CFG = 112 and t1.DT_REF BETWEEN &inicio AND &FIM and IN_CFG_TRML in ('O', 'P')
				order by t1.cd_depe, t1.DT_REF) a
					inner join igr.igrrede_&anomes b on (a.cd_depe = input(b.uor, 9.));
QUIT;

proc sql;
    select distinct MAX(DT_ATDT) into: MAX_DATA separated by ', '
    from work.ATDT;
    select distinct MIN(DT_ATDT) into: MIN_DATA separated by ', '
    from work.ATDT;
QUIT;

proc sql;
    select distinct DataMovimento format 10. into: DataMovimento separated by ', '
    from ROT.TBL_DATAS_PROCESSAMENTO where Dia_Util = 'S' and DataMovimento between &MIN_DATA and &MAX_DATA;
QUIT;
%put &DataMovimento;


PROC SQL;
   CREATE TABLE WORK.FRDO_MUN AS 
   SELECT t1.CD_MUN, 
          t1.DT_FRDO,
		  input (t2.prefdep, 4.) as prefdep,
		  WEEKDAY(t1.DT_FRDO) AS DIA_SEMANA,
		  case when calculated DIA_SEMANA in (2, 3, 4, 5) then t1.DT_FRDO+1
		  when calculated DIA_SEMANA in (6) then t1.DT_FRDO+3
		  when calculated DIA_SEMANA in (7) then t1.DT_FRDO+2
		  when calculated DIA_SEMANA in (1) then t1.DT_FRDO+1
		  end format date9. as pico_pos,
		  case when calculated DIA_SEMANA in (3, 4, 5, 6) then t1.DT_FRDO-1
		  when calculated DIA_SEMANA in (2) then t1.DT_FRDO-3
		  when calculated DIA_SEMANA in (1) then t1.DT_FRDO-2
		  when calculated DIA_SEMANA in (7) then t1.DT_FRDO-1
		  end format date9. as pico_pre
      FROM DB2ARG.FRDO_MUN t1
	  inner join igr.dependencias t2 on (put (t1.CD_MUN,z5.) = t2.CidBB)
	where t1.DT_FRDO BETWEEN &MIN_DATA AND &MAX_DATA
	and sb='00' and calculated DIA_SEMANA in (2, 3, 4, 5, 6)
order by 3;
QUIT;

PROC SQL;
	CREATE TABLE WORK.DIAS_PICO_FIM AS 
		SELECT t1.prefdep, 
			t1.DT_REF format date9.
		FROM WORK.DIAS_PICO t1
			UNION
		SELECT t1.prefdep, 
			t1.pico_pre format date9. AS DT_REF
		FROM WORK.FRDO_MUN t1
			UNION
		SELECT t1.prefdep, 
			t1.pico_pos format date9. AS DT_REF
		FROM WORK.FRDO_MUN t1;
QUIT;




PROC SQL;
   CREATE TABLE WORK.ATDT_TRATADA AS 
   SELECT distinct max(t1.DT_ATDT) format yymmdd10. as posicao, t1.CD_PRF_DEPE, 
   		  trim(compress(t1.TX_UTZD_SNH_ATDT,,'kadst')) AS TX_UTZD_SNH_ATDT,
   		  trim(compress(t1.CD_CHV_ATD,,'kadst')) AS CD_CHV_ATD,
		  t1.CD_CLI, 
          t1.CD_EST_ATDT, 
          t1.CD_TIP_LCL_ATDT,           
          t1.CD_TIP_CTRA, 
          t1.DT_ATDT format yymmdd10., 
          t1.HR_CHGD_AG, 
          t1.HR_INC_ATDT, 
          t1.TEMPO_ESPERA,
		  menos_1min,
		  sem_checkin,
		  encerrada_sist,
		  funci_do_prefixo,
		  prvt,
		  ifn (t1.CD_EST_ATDT=40,1,0) as status_40,
		  ifn (t2.prefdep = . and t2.DT_REF = ., 0, 1) AS PICO,
		  case when calculated pico = 1 and t1.TEMPO_ESPERA<'00:30:00't and t1.CD_EST_ATDT=40 and menos_1min=0 then 1
		  when calculated pico = 0 and t1.TEMPO_ESPERA<'00:20:00't and t1.CD_EST_ATDT=40 and menos_1min=0 then 1
		  else 0 end as atendido,
		  ifn (t1.CD_EST_ATDT=30,1,0) as abdn,
		  1 as tt_cli,
		  tma
      FROM WORK.ATDT1 t1
           LEFT JOIN WORK.DIAS_PICO_FIM t2 ON (t1.CD_PRF_DEPE = t2.prefdep and t1.DT_ATDT = t2.DT_REF)
order by 2, 9;
QUIT;

PROC SQL;
   CREATE TABLE LIB.ATDT_TRATADA_&ANOMES AS 
   SELECT t1.posicao, 
          t1.CD_PRF_DEPE, 
          t1.TX_UTZD_SNH_ATDT, 
          t1.CD_CHV_ATD, 
          t1.CD_CLI, 
          t1.CD_EST_ATDT, 
          t1.CD_TIP_LCL_ATDT, 
          t1.CD_TIP_CTRA, 
          t1.DT_ATDT, 
          t1.HR_CHGD_AG, 
          t1.HR_INC_ATDT, 
          t1.TEMPO_ESPERA, 
          t1.menos_1min, 
          t1.SEM_CHECKIN, 
          t1.ENCERRADA_SIST, 
          t1.funci_do_prefixo, 
          t1.prvt, 
          t1.status_40, 
          max(t1.PICO) as PICO, 
          t1.atendido, 
          t1.abdn, 
          t1.tt_cli,
		  tma
      FROM WORK.ATDT_TRATADA t1
group by t1.CD_PRF_DEPE, t1.DT_ATDT
having max(t1.PICO) = t1.PICO;
QUIT;

/*# TABELAS PROCESSAMENTO - FIM ##############################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS #################################*/

LIBNAME EXT_ANLT "/dados/externo/DIVAR/METAS/conexao/&ANO2.S&semtr./rlzd_analitico";

DATA EXT_ANLT.anlt_&NR_INDICADOR._&ANOMES.;
	SET LIB.ATDT_TRATADA_&ANOMES;
RUN;

%commandShell("chmod 777 /dados/externo/DIVAR/METAS/conexao/&ANO2.S&semtr./rlzd_analitico/anlt_&NR_INDICADOR._&ANOMES.*");

/*# GRAVA CÓPIA DO ANALÍTICO DE PRODUTO PARA VALIDAÇÃO E GERAÇÃO DE RELATÓRIOS POR TERCEIROS - FIM ###########################*/
/*############################################################################################################################*/

/*# SUMARIZAR ################################################################################################################*/
/*############################################################################################################################*/


PROC SQL;
	CREATE TABLE WORK.fim_ag AS 
		select t1.*, t2.*, t3.*, t4.*
			from (SELECT t1.CD_PRF_DEPE as prefdep, 
				sum (t1.tt_cli) as tt_cli,
				sum (sem_checkin) as sem_checkin,
				sum (prvt) as prvt,
				sum (funci_do_prefixo) as funci_do_prefixo,
				sum (t1.status_40) as status_40,
				sum (t1.atendido) as atendido, 
				sum (menos_1min) as menos_1min,
				sum (encerrada_sist) as encerrada_sist,
				sum (t1.abdn) as abdn
			FROM LIB.ATDT_TRATADA_&ANOMES t1 group by 1) t1
				left join 
					(select 
						CD_PRF_DEPE as prefdep,
						avg(tma) FORMAT=E8601TM8. as tma FROM WORK.ATDT_TRATADA t1 where tma>0 group by 1) t2 on (t1.prefdep = t2.prefdep)
					left join 
						(select 
							CD_PRF_DEPE as prefdep,
							avg(TEMPO_ESPERA) FORMAT=E8601TM8. as TEMPO_ESPERA FROM WORK.ATDT_TRATADA t1 where status_40=1 group by 1) t3 on (t1.prefdep = t3.prefdep)
						left join(SELECT input(t1.DEP_LOTACAO, 4.) as prefdep,
							COUNT(DISTINCT(t1.chave)) AS qtd_funci FROM COMUM.ADM_FUNCIS_NOVO_REL t1
							where cod_funcao in (610, 2623, 2800, 2802, 2805, 2809, 2812, 2816, 2822, 2829, 2830, 2831, 2832, 2835, 2845, 4653, 4654, 4655, 4656, 4679, 4680, 4681, 4682, 4685, 4686, 4687, 4688, 4689, 4690, 4691, 4693, 4694, 4695, 4696, 4704, 4705, 4723, 4724, 4940, 4942, 4965, 5641, 5659, 5700, 7010, 7011, 7012)
							GROUP BY 1) t4 on (t1.prefdep = t4.prefdep);
QUIT;



/*TABELA COLUNAS PARA FUNCAO SUMARIZACAO*/
PROC SQL;
    DROP TABLE ColunasSumarizador;
    CREATE TABLE ColunasSumarizador (Coluna CHAR(50), Tipo CHAR(10));
        /*COLUNAS PARA SUMARIZACAO*/
        INSERT INTO ColunasSumarizador VALUES ('tt_cli', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('sem_checkin', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('prvt', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('funci_do_prefixo', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('status_40', 'SUM');
        INSERT INTO ColunasSumarizador VALUES ('atendido', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('menos_1min', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('encerrada_sist', 'SUM');
        INSERT INTO ColunasSumarizador VALUES ('abdn', 'SUM');
		INSERT INTO ColunasSumarizador VALUES ('tma', 'avg');
		INSERT INTO ColunasSumarizador VALUES ('TEMPO_ESPERA', 'avg');
		INSERT INTO ColunasSumarizador VALUES ('qtd_funci', 'sum');
		
QUIT;

%SumarizadorCNX(TblSASValores=fim_ag, TblSASColunas=ColunasSumarizador,  NivelCTRA=0, PAA_PARA_AGENCIA=1, TblSaida=base_rpt);

%zerarmissingtabela(work.base_rpt);

PROC SQL;
   CREATE TABLE WORK.base_rel AS 
   SELECT &DiaUtil_D1 format yymmdd10. as posicao,		  
          t1.PREFDEP, 
		  t1.UOR, 
          t1.tt_cli format 19.0, 		  
          t1.atendido format 19.0,
		  t1.status_40 format 19.0,
          t1.abdn  format 19.0,
		  sem_checkin format 19.0,
		  prvt format 19.0,
		  funci_do_prefixo format 19.0,
		  menos_1min format 19.0,
		  encerrada_sist format 19.0,
		  tma FORMAT=E8601TM8.,
		  TEMPO_ESPERA FORMAT=E8601TM8.,
		  qtd_funci format 19.0
      FROM WORK.BASE_RPT t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.base_rpt_fim AS 
   SELECT &DiaUtil_D1 format yymmdd10. as posicao,
		  t2.prefdep, 
          t2.uor, 
          /*80 as vlr_orc, */
          t2.tt_cli format 19.0, 
          t2.atendido format 19.0, 
		  t2.status_40 format 19.0,
          t2.abdn format 19.0,
		  t2.sem_checkin format 19.0,
		  t2.prvt format 19.0,
		  t2.funci_do_prefixo format 19.0,
		  t2.menos_1min format 19.0,
		  t2.encerrada_sist format 19.0,
		  (t2.atendido-t2.encerrada_sist)/(t2.status_40-t2.menos_1min-t2.encerrada_sist)*100 format 19.2 as pct_atd_prazo,
		  (t2.status_40-t2.menos_1min-t2.encerrada_sist)/(t2.tt_cli-t2.sem_checkin-t2.prvt-t2.funci_do_prefixo)*100 format 19.2 as nivel_servico,
		  calculated pct_atd_prazo*calculated nivel_servico/100 as rlzd,
		  case when t1.prefixo <>. and calculated rlzd/t1.orc*100 < 10 then 0
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 10 and t1.prefixo <>. and calculated rlzd/t1.orc*100<20 then 100
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 20 and t1.prefixo <>. and calculated rlzd/t1.orc*100<30 then 200
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 30 and t1.prefixo <>. and calculated rlzd/t1.orc*100<40 then 300
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 40 and t1.prefixo <>. and calculated rlzd/t1.orc*100<50 then 400
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 50 and t1.prefixo <>. and calculated rlzd/t1.orc*100<60 then 500
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 60 and t1.prefixo <>. and calculated rlzd/t1.orc*100<70 then 600
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 70 and t1.prefixo <>. and calculated rlzd/t1.orc*100<80 then 700
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 80 and t1.prefixo <>. and calculated rlzd/t1.orc*100<90 then 800
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 90 and t1.prefixo <>. and calculated rlzd/t1.orc*100<100 then 900
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 100 and t1.prefixo <>. and calculated rlzd/t1.orc*100<105 then 1000
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 105 and t1.prefixo <>. and calculated rlzd/t1.orc*100<110 then 1100
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 110 and t1.prefixo <>. and calculated rlzd/t1.orc*100<115 then 1200
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 115 and t1.prefixo <>. and calculated rlzd/t1.orc*100<120 then 1300
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 120 and t1.prefixo <>. and calculated rlzd/t1.orc*100<130 then 1400
		  when t1.prefixo <>. and calculated rlzd/t1.orc*100 >= 130 then 1500
		  when t1.prefixo =. and calculated rlzd/70*100 < 10 then 0
		  when t1.prefixo =. and calculated rlzd/70*100 >= 10 and t1.prefixo =. and calculated rlzd/70*100<20 then 100
		  when t1.prefixo =. and calculated rlzd/70*100 >= 20 and t1.prefixo =. and calculated rlzd/70*100<30 then 200
		  when t1.prefixo =. and calculated rlzd/70*100 >= 30 and t1.prefixo =. and calculated rlzd/70*100<40 then 300
		  when t1.prefixo =. and calculated rlzd/70*100 >= 40 and t1.prefixo =. and calculated rlzd/70*100<50 then 400
		  when t1.prefixo =. and calculated rlzd/70*100 >= 50 and t1.prefixo =. and calculated rlzd/70*100<60 then 500
		  when t1.prefixo =. and calculated rlzd/70*100 >= 60 and t1.prefixo =. and calculated rlzd/70*100<70 then 600
		  when t1.prefixo =. and calculated rlzd/70*100 >= 70 and t1.prefixo =. and calculated rlzd/70*100<80 then 700
		  when t1.prefixo =. and calculated rlzd/70*100 >= 80 and t1.prefixo =. and calculated rlzd/70*100<90 then 800
		  when t1.prefixo =. and calculated rlzd/70*100 >= 90 and t1.prefixo =. and calculated rlzd/70*100<100 then 900
		  when t1.prefixo =. and calculated rlzd/70*100 >= 100 and t1.prefixo =. and calculated rlzd/70*100<105 then 1000
		  when t1.prefixo =. and calculated rlzd/70*100 >= 105 and t1.prefixo =. and calculated rlzd/70*100<110 then 1100
		  when t1.prefixo =. and calculated rlzd/70*100 >= 110 and t1.prefixo =. and calculated rlzd/70*100<115 then 1200
		  when t1.prefixo =. and calculated rlzd/70*100 >= 115 and t1.prefixo =. and calculated rlzd/70*100<120 then 1300
		  when t1.prefixo =. and calculated rlzd/70*100 >= 120 and t1.prefixo =. and calculated rlzd/70*100<130 then 1400
		  when t1.prefixo =. and calculated rlzd/70*100 >= 130 then 1500
		  end as regua,
		  ifn (t1.prefixo=.,70,t1.orc) as orc,
		  tma FORMAT=E8601TM8.,
		  TEMPO_ESPERA FORMAT=E8601TM8.,
		  qtd_funci format 19.0,
		  TP_CNX_AVL
      FROM  WORK.BASE_RPT t2
	  left join orc_&anomes t1 on (t2.prefdep = t1.prefixo)
order by 2;
QUIT;

%zerarmissingtabela(WORK.base_rpt_fim);

/*# SUMARIZAR - FIM ##########################################################################################################*/
/*############################################################################################################################*/


/*############################################################################################################################*/
/*# CONEXÃO ##################################################################################################################*/

proc sql;
	create table BASEATB as 
		select 
			'20001536066                                              '
			||put(t2.PrefDep, z4.)
			||"00000"
			||Put(Year(t2.posicao), Z4.)
			||Put(Month(t2.posicao), Z2.)
			||ifc (t2.prefdep=8166,'0011',put(TP_CNX_AVL, z4.))
			||"+"||Put(abs(t2.rlzd)*100, Z13.)
			||"F8176496"
			||Put(t2.posicao, ddmmyy10.)
			||"N" as atb
		from 
			base_rpt_fim t2
		inner join igr.igrrede_&anomes t1 on (input(t1.prefdep, 4.)=t2.prefdep)
			;
quit;

%GerarBBM(TabelaSAS=BASEATB, Caminho=/dados/infor/transfer/enviar/, ExtencaoBBM=MA6066);

/*# CONEXÃO - FIM ############################################################################################################*/
/*############################################################################################################################*/

data base_rpt_fim(drop=tp_cnx_avl);
set base_rpt_fim;
run;

data gcn.eficiencia_atdt;
set base_rpt_fim;
run; 

data base_analitico(drop=tma);
set LIB.ATDT_TRATADA_&ANOMES;
run;

%LET Usuario=f8176496;
%LET Keypass=JQZoFZPLpLC3ve2qE2o3pt9qY7pFPAXeKqzsAGiqL4HSZi7tQ1;

PROC SQL;
DROP TABLE TABELAS_EXPORTAR_REL;
CREATE TABLE TABELAS_EXPORTAR_REL (TABELA_SAS CHAR(100), ROTINA CHAR(100));
INSERT INTO TABELAS_EXPORTAR_REL VALUES('base_rpt_fim', 'indicador-atendimento-unv');
INSERT INTO TABELAS_EXPORTAR_REL VALUES('base_analitico', 'detalhamento');
QUIT;

%ExportarREL(TABELAS_EXPORTAR_REL, Usuario=&Usuario., Keypass=&Keypass.);

x cd /;
x cd /dados/infor/producao/tempo_atendimento;
x chmod 777 *; /*ALTERAR PERMISÕES*/




















/*############################################################################################################################*/
/*# CKECKOUT #################################################################################################################*/
%indCheckOut();
/*############################################################################################################################*/




