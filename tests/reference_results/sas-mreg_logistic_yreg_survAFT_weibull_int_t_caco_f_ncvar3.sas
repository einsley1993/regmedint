
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
    mvar = bili_bin,
    cvar = age male stage,
    a0 = 1,
    a1 = 2,
    m = 1,
    yreg = survAFT_weibull,
    mreg = logistic,
    interaction = true,
    casecontrol = false,
    output = full,
    c = 50 1 2,
    boot = ,
    cens = cens);
run;
