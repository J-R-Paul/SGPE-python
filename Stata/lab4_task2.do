// load and prepare the data
use "http://fmwww.bc.edu/ec-p/data/wooldridge/kielmc.dta", clear
keep if year==1981
global nobs = _N

***************************************************************
// We will use polynomials constructed from the following variables:
//   baths rooms age lland larea lintst
// baths will be treated as categorical; the others, continuous.

// Standardise the continuous variables to have mean=0 and SD=1.
// This uses the Stata add-in zval from the Stata website.

zval rooms age lland larea

// Prepare global macros with first/second/third/fourth-order polynomial terms.
// Macros will be called p1/p2/p3/p4. Begin by clearing these macros.

macro drop p*

// create a global macro with all first-order terms
foreach v1 in i.baths c.z_rooms c.z_lland c.z_larea {
	global p1 $p1 `v1'
}
// 7 first-order terms (but the base category for baths will be dropped later).
sum $p1

// create a global macro with all second-order terms
foreach v1 in i.baths c.z_rooms c.z_lland c.z_larea {
	foreach v2 in i.baths c.z_rooms c.z_lland c.z_larea {
		global p2 $p2 `v1'#`v2'
	}
}
// use fvexpand to get rid of duplicates
fvexpand $p2
global p2 `r(varlist)'
// 22 second-order terms
sum $p2

// create a global macro with all third-order terms
foreach v1 in i.baths c.z_rooms c.z_lland c.z_larea {
	foreach v2 in i.baths c.z_rooms c.z_lland c.z_larea {
		foreach v3 in i.baths c.z_rooms c.z_lland c.z_larea {
			global p3 $p3 `v1'#`v2'#`v3'
		}
	}
}
// use fvexpand to get rid of duplicates
fvexpand $p3
global p3 `r(varlist)'
// 50 third-order terms
sum $p3

// create a global macro with all fourth-order terms
foreach v1 in i.baths c.z_rooms c.z_lland c.z_larea {
	foreach v2 in i.baths c.z_rooms c.z_lland c.z_larea {
		foreach v3 in i.baths c.z_rooms c.z_lland c.z_larea {
			foreach v4 in i.baths c.z_rooms c.z_lland c.z_larea {
				global p4 $p4 `v1'#`v2'#`v3'#`v4'
			}
		}
	}
}
// use fvexpand to get rid of duplicates
fvexpand $p4
global p4 `r(varlist)'
// 95 fourth-order terms
sum $p4


***************************************************************
// Estimate 4 models. These correspond to 1st/2nd/3rd/4th-order Taylor approximations.
// How do the models compare in terms of in-sample prediction (fit)?

// Model 1: levels.
// k=6, R-sq = 73%
global model_1 $p1
regress lrprice $model_1

// Model 2: levels, squares and interactions. 2 collinearities.
// k=19, R-sq = 79%
global model_2 $p1 $p2
regress lrprice $model_2

// Model 3: levels, squares, cubics and interactions. 8 collinearities.
// k=41, R-sq = 84%
global model_3 $p1 $p2 $p3
regress lrprice $model_3

// Model 4: levels, squares, cubic, quartics and interactions. 21 collinearities.
// k=73, R-sq = 89%
global model_4 $p1 $p2 $p3 $p4
regress lrprice $model_4


***************************************************************
// How do they compare in terms of OOS prediction?
// Use the LOO approach.

// Model 1:
cap drop yhat_1_oos
gen yhat_1_oos = .
forvalues i=1/$nobs {
	qui regress lrprice $model_1 if _n~=`i'
    cap drop yhat_i
    qui predict yhat_i if _n==`i', xb
    qui replace yhat_1_oos = yhat_i if _n==`i'
}

// Model 2:
cap drop yhat_2_oos
gen yhat_2_oos = .
forvalues i=1/$nobs {
	qui regress lrprice $model_2 if _n~=`i'
    cap drop yhat_i
    qui predict yhat_i if _n==`i', xb
    qui replace yhat_2_oos = yhat_i if _n==`i'
}

// Model 3:
cap drop yhat_3_oos
gen yhat_3_oos = .
forvalues i=1/$nobs {
	qui regress lrprice $model_3 if _n~=`i'
    cap drop yhat_i
    qui predict yhat_i if _n==`i', xb
    qui replace yhat_3_oos = yhat_i if _n==`i'
}

// Model 4:
cap drop yhat_4_oos
gen yhat_4_oos = .
forvalues i=1/$nobs {
	qui regress lrprice $model_4 if _n~=`i'
    cap drop yhat_i
    qui predict yhat_i if _n==`i', xb
    qui replace yhat_4_oos = yhat_i if _n==`i'
}


// Calcluate the OOS prediction errors.
gen ehat_1_oos = lprice - yhat_1_oos
gen ehat_2_oos = lprice - yhat_2_oos
gen ehat_3_oos = lprice - yhat_3_oos
gen ehat_4_oos = lprice - yhat_4_oos

// Examine the SDs of the OOS prediction errors.
// Which is your preferred specification?
// Also save the MSPEs. Round for later display.
sum ehat_1_oos, detail
global mspe_1 = round(r(Var),0.0001)
sum ehat_2_oos, detail
global mspe_2 = round(r(Var),0.0001)
sum ehat_3_oos, detail
global mspe_3 = round(r(Var),0.0001)
sum ehat_4_oos, detail
global mspe_4 = round(r(Var),0.0001)

// Examine the 4 sets of OOS predictions graphically in a single graph.
scatter yhat_1_oos lprice, name(m1, replace) title("Model 1, MSPE=$mspe_1") nodraw
scatter yhat_2_oos lprice, name(m2, replace) title("Model 2, MSPE=$mspe_2") nodraw
scatter yhat_3_oos lprice, name(m3, replace) title("Model 3, MSPE=$mspe_3") nodraw
scatter yhat_4_oos lprice, name(m4, replace) title("Model 4, MSPE=$mspe_4") nodraw
graph combine m1 m2 m3 m4
