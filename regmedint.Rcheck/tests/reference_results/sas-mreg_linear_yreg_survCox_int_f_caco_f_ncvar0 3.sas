
/** Set libname */
libname w './';

/* Load SAS macro */
%include './mediation.sas';

/* Load data */
proc import datafile = './data-pbc_cc.csv'
    out = pbc_cc
    dbms = csv
    replace;
run;

%mediation(
    data = pbc_cc,
    yvar = time,
    avar = trt,
    mvar = bili,
    cvar = ,
    a0 = 1.1,
    a1 = 2.3,
    m = 1.4,
    yreg = survCox,
    mreg = linear,
    interaction = false,
    casecontrol = false,
    output = full,
    c = ,
    boot = ,
    cens = cens);
run;
