# Calibration

Calibrates weights to a set of control totals.

```SAS
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
```

# Usage  

