# Calibration

Calibrates weights to a set of control totals.

```SAS
%macro Calibration(inVar,ConsCoef=,Targets=,DataOut=);
/*
inVar: File
    unitId	: numeric of string
    weight	: numeric decision variable
	lb	: numeric x >= lb
	ub	: numeric x <= up

ConsCoef : File
    unitId      : numeric or string
    (Var1..VarN): coefficients of the linear combinations that must be statisfied. One variable per linear combination.

Targets : File
    consId      : name of the variable (Var1..VarN) from file ConsCoef that contains the coefficients of this linear combination
    Target      : numeric

DataOut : File
    untiId      : label identifying the unit from input faile inVar
    weight	: numeric lb <=	w <= ub

*/
```

# Usage  

