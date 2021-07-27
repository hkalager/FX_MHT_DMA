
if ~exist('Xser','var')
    error('Input series not specified. Please call DMA function with correct inputs!')
end
if ~exist('Tser','var')
    error('Target series not specified. Please call DMA function with correct target!')
end
xdata=Xser;
tcode=ones(size(xdata,2),1);
sample_begin=ones(size(xdata,2),1);
correct=0;

% Transform Inflation
% 1. Make the transformation that will be used to obtain lags pi[t],pi[t-1],...,pi[t-plag+1]
target_4lags = Tser;
% 2. Make the transformation that will be used to create the dependent
% variable pi[t+h]
% Tser_4dependent = yfcst(Tser,1,h_fore);
Tser_4dependent = Tser;
Xindex=1:size(xdata,2);

% Y is target series. 

Y = Tser_4dependent(:,1);
X = xdata;

% ------------Now create lags, set of un-/restrited variables and finalize the model specification
% Initial time-series observations (we will lose some later when we take lags)
T = size(Y,1);
lbls=1:T;
% Number of exogenous predictors
h = size(X,2);
 
% Number of lags:
LAGS = max(plag,hlag);


if plag>0
    ylag = target_4lags;
    if plag>1   
        ylag = [ylag mlag2(target_4lags,plag-1)];
    end
    ylag = ylag(LAGS+1:end,:);
else
    ylag = [];
end
% Generate lagged X matrix.
xlag = mlag2(X,hlag);
xlag = xlag(LAGS+1:end,:);

% m is the number of R.H.S. variables (intercept, lags and exogenous variables)
m = 1*intercept + plag +  h*(hlag+1);
% Create matrix of RHS variables. Note that z_t has the variables to be
% restricted, and Z_t the variables which are unrestricted
if apply_dma == 1   % restrict only the exogenous variables
    z_t = [X(LAGS+1:T,:) xlag];
    if intercept == 1 
        Z_t = [ones(T-LAGS,1) ylag];
    elseif intercept == 0
        Z_t = ylag;
    end
elseif apply_dma == 2  % restrict the exogenous variables, plus the lags of the dependent
    z_t = [ylag X(LAGS+1:T,:) xlag];
    if intercept == 1 
        Z_t = ones(T-LAGS,1);
    elseif intercept == 0
        Z_t = [];
    end
elseif apply_dma == 3 % restrict all R.H.S. variables (exogenous-lags-intercept)
    z_t = [ones(T-LAGS,1) ylag X(LAGS+1:T,:) xlag];
    Z_t = [];
end

% Redefine variables y, yearlab and T (correct observations since we are taking lags)
y_t = Y(LAGS+1:end,:);
lbls = lbls(LAGS+1:end,:);
T=size(y_t,1);

% Correct for h_fore forecast horizon
T = T-h_fore;
lbls = lbls(1:end-h_fore);
