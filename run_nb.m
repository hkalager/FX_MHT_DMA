%  Train RVM model.
%  Script developed by Arman Hassanniakalager for completing 1st paper,
%  Created on 29 Nov 2015 17:45 GMT,
%  Last modified 17 Mar 2017 22:33 GMT.
% ****************************************
%% Input arguments:
% sym: The desired ticker name available in directory e.g. 'EURUSD''1440'
% measure: selection of top data-snooping test survivors based on:
% 1. 'ret' selection of survivors based on in-sample return.
% 2. 'sharperatio' selection of survivors based on Sharpe ratio.
% 3. 'accuracy' selection of survivors based on maximum accuracy over
% in-sample

% numprc: performing the selections based on simple 'count' of rules or
% percentile 'prc'

% topx: the level used for selection of top X number/percentile of DST
% survivors

% ****************************************
%% Outputs:
% A file with all information required named as symRVMres e.g.
% EURUSD'1440RVMres.mat
%% Function
function run_nb(sym,measure,numprc,topx)
%sym=input('Please enter the symbol name (e.g. EURUSD1440): ','s');
if ~exist('sym','var')
    symser={'EURUSD','GBPUSD','USDJPY','AUDUSD','NZDUSD','USDCHF'};
else
    symser={sym};
end      

if ~exist('topx','var')
    warning('No top number/percentile level determined. 5 is used!');
    topx=10;
end

for iter=1:size(symser,2)
    sym1=symser{iter};
    symDST=['DSTres-',sym1];
    symres=[sym1,'-insample'];
    load(symDST,'goldind');
    load(symres,'inputser','data','finalret','ret');
    retinit=price2ret(data,[],'Continuous');
    datadir=sign(retinit);
    switch measure
        case 'ret'
            measureser=finalret(goldind);
        case 'sharperatio'
            measureser= sharpe(ret(:,goldind),0);
        case 'accuracy'
            measureser=sum(inputser(1:end-1,goldind)==datadir)/numel(datadir);
        otherwise
            warning('No correct measure series selected! Measurement basis is set to return.');
            measureser=finalret(goldind);
    end
    
    switch numprc
        case 'count'
            [sortmeasureser,sortind]=sort(measureser,'descend');
            goldindplus=goldind(sortind(1:topx));
        case 'prc'
            newind=find(measureser>=prctile(measureser,100-topx));
            goldindplus=goldind(newind);
        otherwise
            warning('Count/percentile selection is not properly determined. Count is chosen!');
            [sortmeasureser,sortind]=sort(measureser,'descend');
            goldindplus=goldind(sortind(1:topx));
    end

    if numel(goldindplus)>0
        X=inputser(1:end,goldindplus);
        u=nan(1,numel(goldindplus));
        for i=1:numel(goldindplus)
            u(i)=find(cumsum(X(:,i))~=0,1,'first');
        end
        dim=max(u);
        Xser=inputser(dim+1:end-1,goldindplus);
        Tser=datadir(dim+1:end);
        profit=retinit(dim+1:end);
        NBMdl = fitcnb(Xser,Tser,'Distribution','kernel');
        predictNB=predict(NBMdl,Xser);
        errlevNB=sum(sign(abs(predictNB-Tser)))/numel(Tser);
        disp(['Loss for Naive Bayes in series of ',sym1,' is ',num2str(roundn(errlevNB,-3)*100),'%']);
        NBret=sign(predictNB).*profit;
        NBretfinal=sum(NBret);
        disp(['Return for ',sym1,' with NB results is ',num2str(roundn(sum(NBret)*100,-2)),'%']);
        save([sym1,'NBres']);
    end
end
end