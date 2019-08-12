

%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME DB2BIC DB2 DATABASE=BDB2P04 SCHEMA=DB2BIC AUTHDOMAIN=DB2SGCEN;

LIBNAME STL '/dados/infor/producao/stelo';
LIBNAME CIE '/dados/infor/producao/cielo';


DATA _NULL_;

/*D1 = '01JAN2019'd*/	
D1 = diaUtilAnterior(TODAY());
CALL SYMPUT('D1',COMPRESS(D1,' '));

/*ANOMES = 201901*/
ANOMES = Put(D1, yymmn6.);
CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));

/*MESANO = 012019*/
MESANO=PUT(D1,mmyyn6.);
CALL SYMPUT('MESANO', COMPRESS(MESANO,' '));

/*ANO_ATUAL = 2019*/
ANO_ATUAL = 2019;
CALL SYMPUT('ANO_ATUAL',COMPRESS(ANO_ATUAL,' '));

/*MES_POSICAO = 01*/
MES_POSICAO = Put(MONTH (diaUtilAnterior(TODAY())), Z2.);
CALL SYMPUT('MES_POSICAO', COMPRESS(MES_POSICAO,' '));

RUN;

%Put &D1 &ANOMES &MESANO &ANO_ATUAL &MES_POSICAO;

/*  Tabela Original =  /dados/infor/producao/stelo/dados_entrada/2019/BASE_BB_201907.csv   */


/*  Formata, faz a correção abaixo e cria uma tabela no mesmo endereço chamada BASE_CADASTRO*/

                /*DIA_COMPRA=DATEPART(DC);
				MES=&AnoMes;*/

/*IF AGENCIA=2 AND LOWCASE(REP_BANCO)='acao-bb' AND LOWCASE(COD_FUNCIONAL='f0000002') THEN DO;
				AGENCIA=0;
				COD_FUNCIONAL='f0000000';
				END;*/

/* cria a tabela BASE_CADASTRO_bkp no STL */

/* /dados/infor/producao/stelo/dados_entrada/2019/BASE_CADASTRO */














































