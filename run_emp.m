%  Making recurrent empirical analysis,
%  Script developed by Arman Hassanniakalager,
%  Created on 04 Apr 2016 17:45 GMT,
%  Last modified 27 Jul 2021.
function run_emp(symbol,date1,date2)
if ~nargin
    symbol='EURUSD';
end
load([symbol,'RVMres.mat'],'PARAMETER');
postbayes=numel(PARAMETER.Relevant);
fid=fopen([symbol,'_emp.txt'],'w');
txt='Symbol\tStart\tFinish\tBlack\tNB\tDMA\tDMS\tDST_survivors\tRWalk\tB&H\tTest_Count\tPost-Bayes_Count\n';
fprintf(fid,txt);
rulegenerator(symbol,0,2,date1,date2); % All models
rulegenerator(symbol,0,3,date1,date2); % DMA / DMS
gen_pred_models(symbol);
sym2=[symbol,'_perf_range'];
load(sym2,'arithRVMret','arithNBret','arithDMAret','arithDMSret','arithbenchmarkb_h',...
    'arithavgDSTbenchret','arithbenchmarkRW','DSTsurvivors');
% RVMMDD=roundn(maxdrawdown(1+arithRVMret),-4);
arithRVMres=roundn((arithRVMret(end)),-4);
arithDSTsurvres=roundn((arithavgDSTbenchret(end)),-4);
arithRWres=roundn((arithbenchmarkRW(end)),-4);
arithb_hres=roundn((arithbenchmarkb_h(end)),-4);
arithNBres=roundn((arithNBret(end)),-4);
arithDMAres=roundn((arithDMAret(end)),-4);
arithDMSres=roundn((arithDMSret(end)),-4);
txt=[symbol,'\t',num2str(date1),'\t',num2str(date2),'\t',...
    num2str(arithRVMres),'\t',...
    num2str(arithNBres),'\t',num2str(arithDMAres),'\t',num2str(arithDMSres),'\t',...
    num2str(arithDSTsurvres),'\t',num2str(arithRWres),'\t',...
    num2str(arithb_hres),'\t',num2str(DSTsurvivors),'\t',...
    num2str(postbayes),'\n'];
fprintf(fid,txt);
fclose(fid);


