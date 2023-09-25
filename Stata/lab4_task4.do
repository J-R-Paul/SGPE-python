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
from sfi import Data,Matrix, Scalar, SFIToolkit
import numpy as np
import sklearn
from sklearn.linear_model import Lasso, LassoCV, Ridge, RidgeCV
from sklearn.preprocessing import PolynomialFeatures, StandardScaler

# Xlevels is the array (matrix, sort of) with the basic features (Xs) in levels.
Xlevels = np.array(Data.get("rooms age lland larea lintst"))
# Dimensions of this array:
np.shape(Xlevels)

# Outcome (dependent variable)
y = np.array(Data.get("lrprice"))
np.shape(y)

# The axes of an array are like a coordinate system.
# axis 0 is rows; axis 1 is columns.
# The mean of Xlevels on axis=0 is the mean across all elements in a ROWS.
# The mean of Xlevels on axis=1 is the mean across all elements in a COLUMN.
# The default mean is the mean of EVERYTHING.
np.mean(Xlevels,axis=0)
np.mean(Xlevels,axis=1)
np.mean(Xlevels)


######### MODEL ##########
# The code creates a Python object called "model".
# This is defined to use sklearn's cross-validated lasso.
# We define the numpy array "X" to be our (possibly transformed) regressors,
# and then "model.fit(X,y)" estimates the model using X and y.

# Lasso
# https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html
# The default max_iter of 1,000 isn't enough for it to converge sometimes,
# so set it to 10,000.
model = LassoCV(fit_intercept=True,cv=5,max_iter=10000)

######### PREDICTORS ("FEATURES") ########
# If using just the basic variables in levels, X is just the Xs in levels.
# For a polynomial, use PolynomialFeatures.
# The argument to PolynomialFeatures is the max degree of the polynomial.
# It's usually a good idea to standardise the Xs (mean=0, SD=1).
# To standardise, using StandardScaler.
# Note: this introduces some "data leakage"; strictly speaking, we should
# re-standardise each time we estimate omitting a fold (i.e. 5 times here).
# More on this in the lectures.

poly = PolynomialFeatures(degree=4)
scaler = StandardScaler()
X = poly.fit_transform(scaler.fit_transform(Xlevels))

######### ESTIMATE #########
model.fit(X,y)

######### RESULTS ##########

# Optimal penalty (called alpha in sklearn, called lambda in the lectures).
model.alpha_

# Estimated coefficients and intercept (returned separately):
model.coef_
model.intercept_

# Dimension of X?
np.shape(X)
# How many selected?
np.count_nonzero(model.coef_)

# R-squared (called score). Important: this is a measure of IN-SAMPLE fit.
model.score(X,y)

########## PREDICTED VALUES ########

# Predicted values:
yhatvalues = model.predict(X)

# Residuals:
ehatvalues = y - yhatvalues

# In-sample MSE = SD of residuals (no DOF adustment)
np.std(ehatvalues)

# Copy predicted values and residuals back into Stata
# Assumes variables yhat and ehat already exist in Stata.
Data.store(var="yhat",val=yhatvalues,obs=None)
Data.store(var="ehat",val=ehatvalues,obs=None)

end

// Back in Stata, look at the in-sample predicted values and MSE
// MSE = SD of residuals (with a DOF adjustment):
sum yhat ehat


////////// *********************************************** //////////

// Further exploration of results left behind by LassoCV.
// You can run this section via a do file, or you can enter Python
// and execute the lines interactively. If you do it interactively,
// just copy-and-paste a line after starting Python from within Stata.

python:

# List all available attributes of the Python object "model".
# We can access these by saying "model.<attribute>".
dir(model)

# List the grid of 100 Lasso penalties ("alphas"). Confirm there are 100.
# (NB: In the lectures, we will call this penalty "lambda".)
model.alphas_
np.shape(model.alphas_)

# List the cross-validated MSEs.
# These are out-of-sample so we can treat them as estimates of the MSPE.
# For each alpha there are 5 cross-validated MSEs, one for each CV fold.
# Confirm there are 100 x 5 MSEs.
model.mse_path_
np.shape(model.mse_path_)

# The CV algorithm calculates the mean of the MSEs for each alpha,
# and chooses the minimum. These are OOS MSEs.
# Hence we can treat the mean across folds as estimates of the MSPE
# for a given lasso penalty parameter alpha.
# The CV algorithm chooses the alpha that yields the smallest estimated MSPE.
# The argmin function tells you the index ("row") that is the minimum.
np.mean(model.mse_path_,axis=1)
np.argmin(np.mean(model.mse_path_,axis=1))

# Display that estimated minimum MSPE. This is a key result of the CV procedure.
np.mean(model.mse_path_,axis=1)[np.argmin(np.mean(model.mse_path_,axis=1))]

# Display the alpha that obtains that minimum estimated MSPE.
model.alphas_[np.argmin(np.mean(model.mse_path_,axis=1))]

# The above is what LassoCV saves in model.alpha_ (no "s"!).
model.alpha_

end
