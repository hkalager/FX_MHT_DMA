%  Filter the trading pool for Data-snooping test,
%  Script developed by Arman Hassanniakalager for the Bayesian models paper,
%  Current version created on 18 Mar 2017 17:04 GMT,
%  Last modified 08 Jul 2017 14:19 BST.
%% Input arguments
% sym: The desired ticker name available in directory as the trading pool
% e.g. 'EURUSD''1440' where information is saved in
% "EURUSD'1440-insample.mat"

% measure: The filteration method:
% 1. 'ret' selection of rules based on in-sample return.
% 2. 'sharperatio' selection of rules based on Sharpe ratio.
% 3. 'threshold' selection of rules based on minimum return expected per
% annum

% prc1: determines the percentile level used for filteration of the rules
% or the threshold level in case of third filteration method.

% Example 1: selection of measure='sharperatio' and prc1=5 stands for
% selection of top 5 percentile of the trading strategies sorted by Sharpe
% ratio. 
% Example 2: selection of measure='threshold' and prc1=3 means selection of
% all rules that can meet the requirement of making at least 3% profit over the
% in-sample period.
function filter_inputs(sym,measure,prc1)

fllbl=[sym,'-insample'];
load(fllbl,'ret','cumretadj','finalret','paramstrct','dataret');
if nargin<3
    error('Call the function with all input arguments!!!');
end

% Return series size
retsiz=numel(dataret);
switch measure
    case 'ret'
        retlev=prctile(finalret,100-prc1);
        disp([' Min profit in top ',num2str(prc1),'% of rules is ',num2str((retlev)*100),'%']);
        posind=find(finalret>retlev);
    case 'sharperatio'
        SRser=sharpe(ret,0);
        posind=find(SRser>prctile(SRser,100-prc1));
    case 'threshold'
        threshold=1+(prc1/100)*(retsiz/259);
        posind=find(finalret>threshold);
end
posindret=finalret(posind);
posindaveret=(mean(posindret)-1)/retsiz*259;
lbl=['FILTres-',sym];
save(lbl);

end