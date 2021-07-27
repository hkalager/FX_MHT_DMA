%  Calculate final return calculation for expert system,
%  Script developed by Arman Hassanniakalager for completing 1st paper,
%  Created on 14 Mar 2016 17:45 GMT,
%  Last modified 14 Jul 2017 14:00 BST.
function gen_pred_models(tickername)
global sym trncost
if nargin==0 && isempty(sym)
    sym=input('Please enter the desired symbol: ','s');
elseif nargin==1
    sym=tickername;
end
%% Data import
symres=[sym,'-outsample'];
load(symres);
syminsample=[sym,'-insample'];
load(syminsample,'dataret','paramstrct','finalret');
load(['DSTres-',sym],'goldind');
sym1=[sym,'RVMres'];
load(sym1,'PARAMETER','goldind');
sym1=[sym,'NBres'];
load(sym1,'NBMdl','goldindplus','measure','sortmeasureser');

%% Calculations
ret=price2ret(data,[],'Continuous');

%% Benchmark calculation
% Random Walk
rng('shuffle');
randvar=min(var(dataret),1e-4);
RWnoise=sqrt(randvar)*randn(numel(ret),1)+mean(dataret);
RWser=nan(size(ret));
RWser(1)=RWnoise(1);
RWser(2:end)=ret(1:end-1)+RWnoise(2:end);

%% Data-snooping survivors
DSTsurvivors=numel(goldindplus);
DSTbench=inputser(1:end-1,goldindplus);

%% Table of top rules properties
organized=cell(numel(goldindplus),9);

for m=1:numel(goldindplus)
    backtestret=sum(inputser(1:end-1,goldindplus(m)).*ret);
    organized(m,:)={m,paramstrct.type{goldindplus(m)},...
        paramstrct.case(goldindplus(m)),paramstrct.params{goldindplus(m)},...
        goldindplus(m),finalret(goldindplus(m))-1,backtestret,measure,...
        sortmeasureser(m)};  
end
organized=cell2table(organized,'VariableNames',{'Top_Rule','Category','Case','Parameters','Index','In_Sample_Return','Out_of_Sample_Return','Measure','Value'});

%% RVM Prediction
predictvalSB=(PARAMETER.Value')*inputser(1:end-1,goldind(PARAMETER.Relevant'))';
predictdirSB=sign(predictvalSB)';
rvmret=TransCost(predictdirSB,ret,trncost);

%% DST Survivors return
DSTsurvret=TransCost(DSTbench,ret,trncost);
avgDSTbenchret=mean(DSTsurvret,2);

%% Naive Bayes return calculation
predictNB=predict(NBMdl,DSTbench);
NBret=TransCost(predictNB,ret,trncost);

%% DMA & DMS return calculation
DMAfl=[sym,'-DMA'];
load(DMAfl);
if numel(goldindplus)>10
    warning('The computation time may get exponentially when you exceed 10 input models!!!');
end
X=inputser(:,goldindplus);
u=nan(1,numel(goldindplus));
for i=1:numel(goldindplus)
    u(i)=find(cumsum(X(:,i))~=0,1,'first');
end
dim=max(u);
Xser=inputser(dim:end,goldindplus);
Tser=datadir(dim-1:end-1);
t0=gap1-dim;
if ~exist([sym,'DMAres.mat'],'file')
    [y_t_DMA,y_t_BEST]=DMA(Xser,Tser,t0);
else
    load([sym,'DMAres'],'y_t_DMA','y_t_BEST')
end
DMAser=sign(y_t_DMA(t0+1:end));
DMAret=DMAser.*ret;
DMSser=sign(y_t_BEST(t0+1:end));
DMSret=TransCost(DMSser,ret,trncost);
%% Simple return calculation
arithRVMret=cumsum(rvmret);
arithbenchmarkb_h=cumsum(ret);
arithbenchmarkRW=cumsum(RWser);
arithavgDSTbenchret=cumsum(avgDSTbenchret);
arithNBret=cumsum(NBret);
arithDMAret=cumsum(DMAret);
arithDMSret=cumsum(DMSret);

save([sym,'_perf_range']);
end