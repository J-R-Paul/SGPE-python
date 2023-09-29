// load and prepare the data
use "http://fmwww.bc.edu/ec-p/data/wooldridge/kielmc.dta", clear
keep if year==1981

// Use Stata factor variables to create a full 2nd order polynomial.
sum i.baths##c.rooms##c.lland##c.larea		///
		i.baths#(							///
		c.rooms#c.rooms						///
		c.lland#c.lland						///
		c.larea#c.larea						///
		)

// Show the path = what happens as the penalty decreases.
// Variables enter (and sometimes leave) the lasso solution.
// Note standardisation is the default behaviour.
// The lglmnet option means use the parameterisation used by the R package glmnet.
lasso2 lrprice								///
	i.baths##c.rooms##c.lland##c.larea		///
		i.baths#(							///
		c.rooms#c.rooms						///
		c.lland#c.lland						///
		c.larea#c.larea						///
		), lglmnet

// Show the lasso solution for two different lambdas.
// The first column is the lasso solution.
// The second column is OLS using lasso-selected variables.
lasso2 lrprice								///
	i.baths##c.rooms##c.lland##c.larea		///
		i.baths#(							///
		c.rooms#c.rooms						///
		c.lland#c.lland						///
		c.larea#c.larea						///
		), lglmnet lambda(0.2)
lasso2 lrprice								///
	i.baths##c.rooms##c.lland##c.larea		///
		i.baths#(							///
		c.rooms#c.rooms						///
		c.lland#c.lland						///
		c.larea#c.larea						///
		), lglmnet lambda(0.001)

// Use 5-fold cross-validation to select an optimal lambda.
// Note standardisation is the default behaviour.
// Note that observations are allocated randomly to folds,
// so you need to set the random number seed if you want
// the results to be replicable.
// Option lopt = estimate using the full sample and the lambda
// that minimised the MSPE.
cvlasso lrprice								///
	i.baths##c.rooms##c.lland##c.larea		///
		i.baths#(							///
		c.rooms#c.rooms						///
		c.lland#c.lland						///
		c.larea#c.larea						///
		), lglmnet nfolds(5) lopt seed(42)
