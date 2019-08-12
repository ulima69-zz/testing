

%INCLUDE '/dados/infor/suporte/FuncoesInfor.sas';

Libname tempo_1 "/dados/infor/producao/Tempo_Resposta_PF_PJ/backup";

LIBNAME tempo_2 "/dados/externo/restrito";


DATA tempo_2.gat_pres_201904 (pw=arnesto);
SET tempo_1.gat_pres_201904;
RUN;
