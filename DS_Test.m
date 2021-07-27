%  Conduct Data-snooping test of Romano et al. (2008),
%  Script developed by Arman Hassanniakalager,
%  Part of codes created on 20 Nov 2015,
%  Current version created on 28 Feb 2017 11:53 GMT,
%  Last modified 27 Jul 2021.
% ****************************************
%% Input arguments:
% sym: The desired ticker name available in directory e.g. 'EURUSD'

%% Application modified elements
% bench: Test benchmark (muhat in the original test) can be a selection of following:
% 1. 'b&h' simple buy and hold strategy (takes return series of the ticker
% under study.
% 2. 'rand' a series of random values with mean and std equal to market
% return for the ticker under study.
% 3. 'riskless' A series with fixed returns adjusted for the daily returns.
% * Note: In this case the user can specify the rate beforehand by setting
% a global variable in workspace called "risklessrate" and set a value in %
% or alternatively the script will ask for amount of risk free rate
% expressed in percentage (number) on an annualized scale.


%% Basic parameters of the test
% k: control of k-Familywise Error Rate (k>=1)

% alpha: Alpha as in k-FWE (e.g. 0.1)

% Nmax:           as in operative method of k-StepM (e.g. 20)

% maxsimul: Number of Monte-Carlo results generated to compare agains each
% trading strategy.
% ****************************************
%% Outputs
% A file with all information required named as DSTres-sym e.g.
% DSTres-EURUSD'1440.mat

function toplist=DS_Test(sym,bench,risklessrate)
tic
rng(0);
% Load the filtered input data
fllbl=['FILTres-',sym];
load(fllbl);

%% Basic parameters of DST
kp=0.1;
alpha=0.1;
Nmax=200;
maxsimul=1;
Bsize=1000;
Bwindow=10; %Block size in Bootstrap

% posind=1:size(ret,2);
% Return series size
retsiz=numel(dataret);

% Filtered rules indices are recorded in "posind"
poscount=numel(posind);
kf=round(kp*poscount); % k in k-FWER
dataset=ret(:,posind);
switch bench
    case 'b&h'
        benchser=dataret;
    case 'rand'
        benchser=mean(dataret)+std(dataret)*0.05*randn(retsiz,1);
    case 'riskless'
        if ~exist('risklessrate','var')
            risklessrate=input('Please enter the annualized riskless rate in %: ');
        end
        disp(['Riskless rate for data-snooping test is set to ',num2str(risklessrate),'%.'])
        risklessval=exp(risklessrate/100/259)-1;
        benchser=ones(retsiz,1)*risklessval;
    otherwise
        warning('Benchmark series is not selected. Random walk benchmark is selected.');
        benchser=mean(dataret)+std(dataret)*0.05*randn(retsiz,1);
end
%% Bootstrap generation 
%% Bootstrap indices
indices=stationary_bootstrap((1:size(dataset,1))',Bsize,Bwindow);
%% Test statistics 
modelscount=size(dataset,2);
tststatB=nan(Bsize,modelscount);
tststat=mean(dataset-benchser)./std(dataset);
tic;
for i=1:modelscount
    candmodel=dataset(:,i);
    for b=1:Bsize
        tststatB(b,i)=(mean(candmodel(indices(:,b)))-mean(candmodel)-mean(benchser(indices(:,b))))/max(std(candmodel),1e-10);
    end
end
for j=1:maxsimul
    %% Conducting the data-snooping test
    [toplist, ~] = kfwe(tststat,tststatB,kf,alpha,Nmax);
    genind{j}=posind(toplist); % Index of genuine strategies
    genfinalret{j}=finalret(genind{j});
    disp(['Average return in data snooping test with ',...
        num2str(numel(toplist)),' rule is ',...
        num2str(roundn(mean(genfinalret{j}),-4)*100),'%']);
end    
topsiz=round(numel(toplist));
gold=toplist(1:topsiz);
goldind=posind(gold);
goldser=cumretadj(:,goldind);
goldret=finalret(goldind);
goldretadj=ret(:,goldind);
organized=cell(numel(gold),6);
for m=1:numel(gold)
    organized(m,:)={m,paramstrct.type{goldind(m)},...
        paramstrct.case(goldind(m)),paramstrct.params{goldind(m)},...
        goldind(m),goldret(m)};
end
organized=cell2table(organized,'VariableNames',{'Top_Rule','Category','Case','Parameters','Index','In_Sample_Return'});
disp(['Average return for ',num2str(numel(gold)),' top gainful strategies is ',...
    num2str(roundn(mean(goldret),-4)*100),'%']);
lbl=['DSTres','-',sym];
save(lbl);
toc
end