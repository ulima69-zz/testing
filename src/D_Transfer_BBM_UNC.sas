%include '/dados/infor/suporte/FuncoesInfor.sas';


DATA _NULL_;
	CALL SYMPUTX('BBMData',CATS(put(TODAY(),year2.),put(Month(TODAY()),z2.),put(Day(TODAY()),z2.)));
RUN;

%put &BBMData;

/*%LET Arquivo=BBM.ATB048C.O8892.D9938.D&BBMData..SATSMS;*/
/*%LET MOVER_SATSMS="cp /dados/externo/UNC/Indicadores/&Arquivo. /dados/infor/transfer/enviar/; cd /dados/infor/transfer/enviar/; chmod 777 &Arquivo.;";*/
/*%commandShell(&MOVER_SATSMS.);*/

%LET Arquivo=BBM.ATB048C.O8892.D9938.D&BBMData..TRM001;
%LET MOVER_TRM001="cp /dados/externo/UNC/Indicadores/&Arquivo. /dados/infor/transfer/enviar/; cd /dados/infor/transfer/enviar/; chmod 777 &Arquivo.;";
%commandShell(&MOVER_TRM001.);

%LET Arquivo=BBM.ATB048C.O8892.D9938.D&BBMData..EXPCRS;
%LET MOVER_EXPCRS="cp /dados/externo/UNC/Indicadores/&Arquivo. /dados/infor/transfer/enviar/; cd /dados/infor/transfer/enviar/; chmod 777 &Arquivo.;";
%commandShell(&MOVER_EXPCRS.);

%LET Arquivo=BBM.ATB048C.O8892.D9924.D&BBMData..APF;
%LET MOVER_EXPCRS="cp /dados/externo/UNC/Indicadores/&Arquivo. /dados/infor/transfer/enviar/; cd /dados/infor/transfer/enviar/; chmod 777 &Arquivo.;";
%commandShell(&MOVER_EXPCRS.);


/*#################################################################################################################*/
/*#################################################################################################################*/
/*CkeckOut do processamento*/
/*#################################################################################################################*/

%processCheckOut(
    uor_resp = 341556
    ,funci_resp = &sysuserid
    ,tipo = Indicador
    ,sistema = Indicador
    ,rotina = Transferencia BBMs da UNC
    ,mailto= &EmailsCheckOut.
);
/*#################################################################################################################*/
/*#################################################################################################################*/
