
%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME DIMPE 	"/dados/externo/GECEN/DIMPE/encarteiramento-mpe/solicitacoes";
LIBNAME DIMPE2 	"/dados/externo/GECEN/DIMPE/encarteiramento-mpe/carga";
LIBNAME DIMPE3 	"/dados/externo/GECEN/DIMPE/encarteiramento-mpe/retorno";
LIBNAME GEGEM POSTGRES server="172.16.15.103" port=5432 user="gecen_processamento" password='procgecen17' database="portal" schema="encarteiramento_mpe";



DATA _NULL_;
	
	D1 = diaUtilAnterior(TODAY());
	CALL SYMPUT('D1',COMPRESS(D1,' '));
	 
RUN;


/*Primeira Leitura*/


PROC SQL;
 
CREATE TABLE work.tb_recomendacao_carteira_semanal AS SELECT

t1.cod_cli as mci,     
t1.codigo_tipo_carteira_recomendada as perfil

FROM  DIMPE2.tb_recomendacao_carteira_semanal (PW= gecem8892) t1;

QUIT;


data work.tb_recomendacao_carteira_semanal;
format posicao yymmdd10.;
set work.tb_recomendacao_carteira_semanal;
posicao = &D1;
run;


/*Segunda Tabela*/


PROC SQL;
 
CREATE TABLE work.upd_perfil_encart_por_cli_201809 AS SELECT

t1.mci,     
t1.perfil

FROM  DIMPE2.upd_perfil_encart_por_cli_201809 (PW= gecem8892) t1;

QUIT;


data work.upd_perfil_encart_por_cli_201809;
format posicao yymmdd10.;
set work.upd_perfil_encart_por_cli_201809;
posicao = &D1;
run;


/*Terceira Tabela*/


PROC SQL;
 
CREATE TABLE work.upd_solicitacoes_execucao AS SELECT

t1.id_solicitacao,
t1.mci,
t1.executada,
t1.posicao,
t1.Motivo_Recusa

FROM DIMPE3.upd_solicitacoes_execucao (PW= gecem8892) t1;

QUIT;


data work.upd_solicitacoes_execucao;
format posicao yymmdd10.;
set work.upd_solicitacoes_execucao;
posicao = &D1;
run;



/*carga*/


PROC SQL;

	CREATE TABLE DIMPE.solicitacoes AS SELECT
	    
    t1.id,
    t1.mci,
    t1.nome,
    t1.cnpj,
    t1.carac_especial,
    t1.faturamento,
    t1.peso,
    t1.cliente_novo,
    t1.filial,
    t1.particip_grp_emp,
    t1.interesse_negocial,
    t1.perfil_enc,
    t1.data_enc,
    t1.prefixo_ag_origem,
    t1.cd_carteira_origem,
    t1.cd_tipo_cart_origem,
    t1.chave_adm_cart_origem,
    t1.chave_co_resp_cart_origem,
    t1.chave_assist_cart_origem,
    t1.justificativa_origem,
    t1.cart_neg_origem,
    t1.data_origem,
    t1.chave_origem,
    t1.prefixo_ag_destino,
    t1.cd_carteira_destino,
    t1.cd_tipo_cart_destino,
    t1.chave_adm_cart_destino,
    t1.chave_co_resp_cart_destino,
    t1.chave_assist_cart_destino,
    t1.justificativa_destino,
    t1.cart_neg_destino,
    t1.ag_esp_destino,
    t1.data_destino,
    t1.chave_destino,
    t1.precisa_validar,
    t1.prazo_validacao,
    t1.observacoes,
    t1.status

	FROM GEGEM.VIEW_SOLICITACOES t1;

QUIT;


%LET Usuario=f7176219;
%LET Keypass=yvzVsv7aInEDNdgZ5BQuDZZutHD395Xlh1HUJJj3xFARE7EVuD;
%LET Rotina=encarteiramento-mpe-perfil-encarteiramento-por-cliente;
%ProcessoIniciar();

data teste;
set work.tb_recomendacao_carteira_semanal;
run;


PROC SQL;
	DROP TABLE TABELAS_EXPORTAR_REL_1;
	CREATE TABLE TABELAS_EXPORTAR_REL_1 (TABELA_SAS CHAR(100), ROTINA CHAR(100));
	INSERT INTO TABELAS_EXPORTAR_REL_1 VALUES('teste', 'encarteiramento-mpe-perfil-encarteiramento-por-cliente');
   ;
QUIT;


%ProcessoCarregarEncerrar(TABELAS_EXPORTAR_REL_1);

x cd /dados/externo/GECEN/DIMPE/encarteiramento-mpe/solicitacoes;
x cd /dados/externo/GECEN/DIMPE/encarteiramento-mpe/carga;

x chmod 2777 *;



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
