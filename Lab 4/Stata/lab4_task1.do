// Load data and keep only observations with non-missing wages
webuse mroz, clear
keep if lwage<.

// Define a global with the number of observations (will be 428).
global nobs = _N

// For reference: wage equation estimated using OLS and the full dataset.
reg lwage educ exper expersq

*********************************************************************

// Loop through, each time estimating while excluding one observation
// and then getting the OOS prediction for that observation.
// This is called a LOO (leave-one-out) or jackknife approach.

// Prepare to collect OOS (out-of-sample) predictions.
cap drop yhat_oos
gen yhat_oos = .

forvalues i=1/$nobs {
    qui reg lwage educ exper expersq if _n~=`i'
    cap drop yhat_i
    qui predict yhat_i if _n==`i', xb
    qui replace yhat_oos = yhat_i if _n==`i'
}

// Calcluate the OOS errors
cap drop ehat_oos
gen ehat_oos = lwage - yhat_oos

// What is the MSPE?  The root MSPE? How does this differ from the RMSE
// reported for the OLS estimation at the top of the do file?
sum ehat_oos, detail

// Examine the OOS predictions graphically.
scatter yhat_oos lwage

*********************************************************************

// As above but after splitting the dataset randomly into 4 pieces.
// Use 3 pieces for estimation and 1 piece for OOS predictions.

// For replicability, set the random number seed.
set seed 42
// foldvar will be the fold ID = 1, 2, 3, 4
cap drop foldvar
gen foldvar = runiform()
recode foldvar (0/0.25 = 1) (0.25/0.5 = 2) (0.5/0.75 = 3) (0.75/1 = 4)
tab foldvar

// Prepare to collect OOS (out-of-sample) predictions.
cap drop yhat_4f_oos
gen yhat_4f_oos = .

forvalues k=1/4 {
    qui reg lwage educ exper expersq if foldvar~=`k'
    cap drop yhat_i
    qui predict yhat_i if foldvar==`k', xb
    qui replace yhat_4f_oos = yhat_i if foldvar==`k'
}

// Calcluate the OOS errors
cap drop ehat_4f_oos
gen ehat_4f_oos = lwage - yhat_4f_oos

// What is the MSPE?  The root MSPE? How does this differ from the RMSE
// reported for the OLS estimation at the top of the do file?
sum ehat_4f_oos, detail

// Examine the OOS predictions graphically.
scatter yhat_4f_oos lwage

