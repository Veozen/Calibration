/**/

%macro Nobs(dataIn);
/*Returns the number of observations in a dataset*/
	%local dataid nobs rc;
	%let nobs=0;
	%if (&dataIn ne ) %then %do;
		%let dataid=%sysfunc(open(&dataIn));
		%let nobs=%sysfunc(attrn(&dataid,nobs));
		%let rc=%sysfunc(close(&dataid));
	%end;
	&nobs 
%mend Nobs;

%macro saveOptions();
	/*save some common options*/
	%local notes mprint symbolgen source options;
	%let notes = %sysfunc(getoption(Notes));
	%let mprint = %sysfunc(getoption(mprint));
	%let symbolgen = %sysfunc(getoption(Symbolgen));
	%let source = %sysfunc(getoption(source));

	%let options = &notes &mprint &symbolgen &source;
	&options;
%mend saveOptions;

%macro Time(from);
/*returns the current time  or if input provided: 
returns the elaspsed time from the input time */
	%local dataTime now time;
	%let datetime = %sysfunc( datetime() );
	%let now=%sysfunc( timepart(&datetime) );

	%if (&from ne ) %then %do;
		%let timefrom = %sysfunc(inputn(&from,time9.));
		%if %sysevalf(&now<&timefrom) %then %do;
			%let time =  %sysevalf(86400-&timefrom,ceil);
			%let time = %sysevalf(&time + %sysevalf(&now,ceil));
		%end;
		%else %do;
			%let time = %sysevalf(&now-&timefrom,ceil);
		%end;
		%let time = %sysfunc(putn(&time,time9.));
	%end;
	%else %do;
		%let time = &now;
		%let time = %sysfunc(putn(&time,time9.));
	%end;
	&time
%mend Time;

%macro VarLen(data,Var);
/* yields the length of a dataset s variable*/
	%local dataid varnum varLen rc var;
	%let dataid=%sysfunc(open(&data));
	%let varnum=%sysfunc(varnum(&dataId,&var));
	%let varLen=%sysfunc(varLen(&dataId,&varNum));
	%let rc = %sysfunc(close(&dataId));
	
	&VarLen
%mend VarLen;

%macro VarExist(data,Var);
	/*Check if a variable exists in a data set */
	%local dataid varnum VarExist rc var;
	%let dataid=%sysfunc(open(&data));
	%let varnum=%sysfunc(varnum(&dataId,&var));
	%let VarExist = 0;
	%if &varnum gt 0 %then %do;
		%let VarExist = 1;
	%end;
	%let rc = %sysfunc(close(&dataId));
	
	&VarExist
%mend VarExist;

%macro varExist_(Data,var);
	/*Check if a set of variables exists in a data set */
	%local count DSID varexist N varnum;
	%let DSID = %sysfunc(open(&Data));
	%let n=  %sysfunc(countw(&var,%str( )));

	%let count = 1;
	%let varexist=1;
	%do %while(&count <= &N);
		%let varnum = %sysfunc(varnum(&DSID, %scan(&var,&count)));
		%if &varnum eq 0 %then %do;
			%let varexist=0;
		%end;
		%let count = %eval(&count + 1);
	%end;
	
	%let DSID = %sysfunc(close(&DSID));
	&varexist 
%mend varExist_;

%macro varType(data,var);
	/*return a list of types for the variables of a Data set*/
	%local id nvar types rc N i varnum n;
	%let id= %sysfunc(open(&data));

	%if (&var eq) %then %do;
		%let nvar=%sysfunc(attrn(&id,nvar));
		%let types=;
		%do i = 1 %to &nvar;
			%let types= &types %sysfunc(varType(&id,&i));
		%end;
	%end;
	%else %do;
		%let n=  %sysfunc(countw(&var,%str( )));
		%let types=;
		%do i = 1 %to &n;
			%let varnum = %sysfunc(varnum(&id,%scan(&var,&i)));
			%let types= &types %sysfunc(varType(&id,&varnum));
		%end;
	%end;

	%let rc= %sysfunc(close(&id));
	&types
%mend varType;

%macro varNames(data,var,start=1);
	/*return a list of names for the variables of a Data set*/
	%local id nvar names rc N i varnum n;
	%let id= %sysfunc(open(&data));

	%if (&var eq) %then %do;
		%let nvar=%sysfunc(attrn(&id,nvar));
		%let names=;
		%do i = &start %to &nvar;
			%let names= &names %sysfunc(varName(&id,&i));
		%end;
	%end;

	%let rc= %sysfunc(close(&id));
	&names
%mend varNames;


%macro Calibration(inVar,ConsCoef=,Targets=,DataOut=);
/*
inVar: File
    unitId      : numeric of string
    weight      : numeric decision variable
	lb			: numeric x >= lb
	ub			: numeric x <= up

ConsCoef : File
    unitId      : numeric or string
    (Var1..VarN):

Targets : File
    consId      : liste des variables contenant les coefficients (Var1..VarN)
    Target       : numeric

DataOut : File
    untiId      :
    weight		: numeric lb <=	w <= ub

*/
/*
    %put;
    %put -----------;
    %put Calibration;
    %put -----------;
    %put;*/

    %local i unitIdType consId TargetValues types Varnames Nunits Nvar options start;

    %let Start = %time();
    %let options = %saveOptions();
    option nonotes nosource;


    %let unitIdType = %varType(data=&ConsCoef,var=unitId);
    %if &unitIdType= N %then %do;
        %let unitIdType= num;
    %end;
    %else %do;
        %let unitIdType= str;
    %end;

	/*Collect the values from dataset &targets*/
	proc sql noprint;
		select consId into : consId separated by " "
		from &targets;
	quit;
	proc sql noprint;
		select Target into : TargetValues separated by " "
		from &targets;
	quit;

    %let Nunits= %Nobs(&ConsCoef);
    %let VarNames = %VarNames(data=&ConsCoef,start=2);
    %let Nvar = %sysfunc(countw(&varNames));

    %put Nombre d équations : &Nvar;
    %put Nombre d unitées   : &Nunits;
	

    ods html close;
    ods output printTable=constraints;
    proc optmodel PRINTLEVEL=0 ;
        /*Déclarer les variables*/
        set <&unitIdType> UnitID ;
        %do i=1 %to &Nvar;
            num Coef&i {UnitID};
        %end;
        %if (&inVar ne) %then %do;
            num initw{unitId};
			num lb{unitId};
			num ub{unitId};
        %end;
        var w{UnitID} ;

        /*Lire les données*/
        %if (&inVar ne) %then %do;
            read data &inVar into unitId=[unitId] initw=weight lb=lb ub=ub;
        %end;
        read data &ConsCoef into unitId=[unitId] %do i = 1 %to &Nvar;  Coef&i=%scan(&varNames,&i) %end; ;

        /*valeurs par défaut*/
        for {i in unitID} w[i]=initw[i];

        /*Contraintes*/
        %do i=1 %to &NVar;
            con cons&i: sum{i in UnitID}  coef&i[i]*w[i]  = %scan(&TargetValues,&i,%str( )) %str(;)
        %end;
		con LBound{i in UnitID} : w[i] >= lb[i];
		con UBound{i in UnitID} : w[i] <= ub[i];

        /*Minimisation*/
        %if (&inVar ne) %then %do;
            min Distance= sum{i in UnitID} ((w[i]-initw[i])**2)/initw[i]    ;
        %end;
        %else %do;
            impvar meanw = sum{i in UnitID} w[i]/&Nunits;
            min Distance= sum{i in UnitID} (w[i]-meanw)**2    ;
        %end;

        solve with NLP / tech= activeset;
        print _con_.name _con_.body  _con_.lb _con_.ub ;

        /*Output*/
        create data &dataOut  from [UnitID]   weight=w;
    quit;
    ods output close;

    data &dataOut;
        set &dataOut;
        weight= round(weight,0.001);
    run;


	%put ;
	%put &_OrOptModel_;

    option &options;

    %put;
    %Put Débuté à  &Start;
    %put Terminé à %time();
    %put Durée     %time(&Start);
%mend Calibration;
