%  Train RVM model.
%  Script developed by Arman Hassanniakalager
%  Created on 29 Nov 2015 17:45 GMT,
%  Last modified 19 Mar 2017 11:58 GMT.
% ****************************************
%% Input arguments:
% sym: The desired ticker name available in directory e.g. 'EURUSD'

% ****************************************
%% Outputs:
% A file with all information required named as symRVMres e.g.
% EURUSDRVMres.mat
%% Function
function run_rvm(sym)
%rvmplus(sym,measure,numprc,topx)
symser={sym};      

% if ~exist('topx','var')
%     warning('No top number/percentile level determined. 5 is used!');
%     topx=10;
% end

for iter=1:size(symser,2)
    sym1=symser{iter};
    symDST=['DSTres-',sym1];
    symres=[sym1,'-insample'];
    load(symDST,'goldind');
    load(symres,'inputser','data','finalret');
    retinit=price2ret(data);
    datadir=sign(retinit);
%     switch measure
%         case 'ret'
%             measureser=finalret(goldind);
%         case 'sharperatio'
%             measureser= sharpe(ret(:,goldind),0);
%         case 'accuracy'
%             measureser=sum(inputser(1:end-1,goldind)==datadir)/numel(datadir);
%         otherwise
%             warning('No correct measure series selected! Measurement basis is set to return.');
%             measureser=finalret(goldind);
%     end
%     
%     switch numprc
%         case 'count'
%             [sortmeasureser,sortind]=sort(measureser,'descend');
%             goldindplus=goldind(sortind(1:topx));
%         case 'prc'
%             newind=find(measureser>=prctile(measureser,100-topx));
%             goldindplus=goldind(newind);
%         otherwise
%             warning('Count/percentile selection is not properly determined. Count is chosen!');
%             [sortmeasureser,sortind]=sort(measureser,'descend');
%             goldindplus=goldind(sortind(1:topx));
%     end

    if numel(goldind)>0
        X=inputser(1:end,goldind);
        u=nan(1,numel(goldind));
        for i=1:numel(goldind)
            u(i)=find(cumsum(X(:,i))~=0,1,'first');
        end
        dim=max(u);
        Xser=inputser(dim+1:end-1,goldind);
        Tser=datadir(dim+1:end);
        profit=retinit(dim+1:end);
        kernel='Gaussian';
        options=SB2_UserOptions('monitor',10);
        settings = SB2_ParameterSettings;
        [PARAMETER,HYPERPARAMETER,DIAGNOSTIC]=SparseBayes(kernel,Xser,Tser,options,settings);
        predictvalSB=(PARAMETER.Value')*Xser(:,(PARAMETER.Relevant'))';
        predictdirSB=sign(predictvalSB)';
        correctpredind=find(predictdirSB-Tser==0);
        errlevSB=sum(sign(abs(predictdirSB-Tser)))/numel(Tser);
        mdlinput=Xser(:,(PARAMETER.Relevant'));
        mdloutput=predictdirSB;
        disp(['Loss for Sparse Bayes in series of ',sym1,' is ',num2str(roundn(errlevSB,-3)*100),'%']);
        SBret=predictdirSB.*profit;
        SBretfinal=sum(SBret);
        disp(['Return for ',sym1,' with SB results is ',num2str(roundn(sum(SBret)*100,-2)),'%']);
        save([sym1,'RVMres']);
    end
end
end