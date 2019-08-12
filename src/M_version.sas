

%include '/dados/infor/suporte/FuncoesInfor.sas';

LIBNAME VER '/dados/infor/producao/versionamento_1';


DATA _NULL_;


D1 = '30apr2019'd;
/*D1 = diaUtilAnterior(TODAY());*/
CALL SYMPUT('D1',COMPRESS(D1,' '));

ANO_ATUAL = 2019;
CALL SYMPUT('ANO_ATUAL',COMPRESS(ANO_ATUAL,' '));

MES_POSICAO = 04;
/*MES_POSICAO = Put(MONTH (diaUtilAnterior(TODAY())), Z2.);*/
CALL SYMPUT('MES_POSICAO', COMPRESS(MES_POSICAO,' '));

ANOMES = 201904;
/*ANOMES = Put(D1, yymmn6.);*/
CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));

MESANO = 042019;
/*MESANO = Put(D1, mmyyn6.);*/
CALL SYMPUT('MESANO',COMPRESS(MESANO,' '));

RUN;


%Put &MES_POSICAO &ANO_ATUAL &D1 &ANOMES &MESANO;



x #!/bin/bash;

x SUFFIX=`date +%d/%m/%Y-%H:%M:%S`;



/*opcao1*/
x function versionamento {

rsync -uahv --include '*.sas' --exclude '*' /dados/infor/producao/versionamento_1/ /dados/infor/producao/versionamento_1/backup

};
x versionamento > /dados/infor/producao/versionamento_1/log.txt;




/*opcao2*/
x function versionamento {

rsync -brhv --suffix=SUFFIX --include '*.sas' --exclude '*' /dados/infor/producao/versionamento_1/ /dados/infor/producao/versionamento_1/backup

};
x versionamento > /dados/infor/producao/versionamento_1/log.txt;



/*opcao3*/
x function versionamento {

rsync -brhv --suffix=SUFFIX --include '*.sas' --exclude '*' /dados/infor/producao/versionamento_1/ /$(pwd)/versao

};
x versionamento > /dados/infor/producao/versionamento_1/log.txt;



x cd /dados/infor/producao/versionamento_1;
x chmod 2777 *;
