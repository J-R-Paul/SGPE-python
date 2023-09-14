// load and prepare the data
use "http://fmwww.bc.edu/ec-p/data/wooldridge/kielmc.dta", clear
keep if year==1981

// Predicted values will go into the variable yhat.
// Residuals will go into variable ehat.
cap drop yhat
gen yhat = .
cap drop ehat
gen ehat = .

python:

# Stata Python API documentation:
# https://www.stata.com/python/api17/index.html
from sfi import Data,Matrix,Scalar,SFIToolkit
import numpy as np
from sklearn.linear_model import Lasso,LassoCV,ElasticNet,ElasticNetCV,Ridge,RidgeCV
from sklearn.preprocessing import PolynomialFeatures

# Xlevels is the array (matrix) with the basic features (predictors) in levels.
Xlevels = np.array(Data.get("rooms age lland larea lintst"))
# Dimensions of this array:
np.shape(Xlevels)

# Outcome (dependent variable)
y = np.array(Data.get("lrprice"))
np.shape(y)

# Means
np.mean(Xlevels,axis=0)
np.mean(y,axis=0)
# SDs
np.std(Xlevels,axis=0)
np.std(y,axis=0)

# What would happen if we asked for the mean of X without specifying the axis?
np.mean(Xlevels)
# What would happen if we asked for the mean of X for axis=1?
np.mean(Xlevels,axis=1)


######### MODEL ##########
# Various models and specifications below. Uncomment to choose one.

# Lasso
# https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html
# "normalize=True" provides the normalize argument without reference to the position.
# normalize is like standardize but without dividing by the sample size.
# nb: normalize will be removed from sklearn starting with release 1.2.
model = LassoCV(normalize=True,fit_intercept=True,cv=5)

# Ridge
# https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.RidgeCV.html
# model = RidgeCV(normalize=True,fit_intercept=True,cv=5)

######### PREDICTORS ########
# If using just the basic variables in levels, X is just X levels.
# For a polynomial, use PolynomialFeatures.

# Basic model - just the raw variables in levels.
# X = Xlevels

# Polynomial including interactions.
# The argument to PolynomialFeatures is the max degree of the polynomial.
poly = PolynomialFeatures(degree=4)
X = poly.fit_transform(Xlevels)

######### ESTIMATE #########
model.fit(X,y)

######### RESULTS ##########

# Penalty hyperparameter (called alpha in sklearn, called lambda in the lectures).
model.alpha_

# R-squared (called score).
# For LassoCV:
# model.score(Xall,y)
# For RidgeCV:
# model.best_score_

# Estimated coefficients and intercept (returned separately):
b = model.coef_
b
model.intercept_

# Dimension of X?
np.shape(X)
# How many selected?
np.count_nonzero(b)

########## PREDICTED VALUES ########

# Predicted values:
yhatvalues = model.predict(X)

# Residuals:
ehatvalues = y - yhatvalues

# In-sample MSE = SD of residuals (no DOF adustment)
np.std(ehatvalues)

# Assumes variables yhat and ehat already exist in Stata.
Data.store(var="yhat",val=yhatvalues,obs=None)
Data.store(var="ehat",val=ehatvalues,obs=None)

end

// Back in Stata, look at the in-sample MSE
// = SD of residuals (with a DOF adjustment):
sum ehat, detail
