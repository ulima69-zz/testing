
%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

libname chip "/dados/infor/producao/Dimep/chipamento_inss";

LIBNAME EPO DB2 DATABASE=BDB2P04 SCHEMA=DB2EPO AUTHDOMAIN=DB2SGCEN;

DATA _NULL_;
	
	D1 = diaUtilAnterior(TODAY());
	ANOMES = Put(D1, yymmn6.);
	
	CALL SYMPUT('D1',COMPRESS(D1,' '));
	CALL SYMPUT('ANOMES',COMPRESS(ANOMES,' '));
	
RUN;

%PUT &D1. &ANOMES.;
