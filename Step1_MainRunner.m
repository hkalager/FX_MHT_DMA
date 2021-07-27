% This is the main script for replicating results in a paper entitled
% "Trading the foreign exchange market with technical analysis and
% Bayesian Statistics" You can access the article at
% https://doi.org/10.1016/j.jempfin.2021.07.006
% Script developed by Arman Hassanniakalager
% Created on 07 Jun 2016 16:45 GMT,
% Last revised 27 Jul 2021.
% Common disclaimers apply.
addpath(genpath(pwd));
part1=pwd;
%% Specification of experiments
% In-sample period
insample_range=(2010:2013)';
insample_range(:,2)=insample_range(:)+2;
% Out-of-sample period (the following year)
outsample_range=insample_range(:,2)+1;
%% Series
ticker_list={'EURUSD','GBPUSD','USDJPY'};
%% Filteration
% Filtering process methods
filter_measure='ret';
% Filtering level (percentile)
toplevel1=5;
%% Data-snooping
% Data snooping test benchmark types
% benchtyp={'riskless','b&h'};
benchmark_choice={'riskless'};
% If the riskless asset is used the fixed return level determined below
risklessrate=0;
% Data snooping survivors rules selection methods
%mde2={'accuracy','ret','sharperatio'};
mde2='accuracy';
% Data snooping selection level (number/percentile)
toplevel2=[5,10,15];
% Selection between number or percentile 'count' for number and 'prc' for
% percentile
numprc='count';
%% Table preparation
labels={'Symbol','Start','Finish','Black','NB','DMA','DMS','DST_survivors',...
    'RWalk','B&H','Test_Count','Post-Bayes_Count','Top_Level','Mode_Filter','Mode_Test','Benchmark'};
tbl=labels;
%% Setting the forgetting factor in DMA/DMS & transaction cost for the OOS
global alpha lambda trncost;
alpha=0.90;
lambda=0.99;
trncost=3e-4;
%trncost=0;

%% Running the experiments
v=0;
for t=1:size(insample_range,1) % all sample periods
    for s1=1:numel(toplevel1) % All filtering levels
        for s2=1:numel(toplevel2)
            for z=1:numel(benchmark_choice)
                v=v+1;
                fld_name=['Backtest_(',num2str(insample_range(t,1)),'-',num2str(insample_range(t,2)),...
                    ')-',filter_measure,'-',num2str(toplevel1(s1)),'-',mde2,'-',...
                    num2str(toplevel2(s2)),'-',numprc,'-',benchmark_choice{z}];
                mkdir(fld_name);
                pathdir=[part1,'\',fld_name];
                cd(pathdir);
                for iter=1:numel(ticker_list)
                    sym1=ticker_list{iter};
                    rulegenerator(sym1,3,1,insample_range(t,1),insample_range(t,2));
                    filter_inputs(sym1,filter_measure,toplevel1(s1));
                    top_list=DS_Test(sym1,benchmark_choice{z},risklessrate);
                    if numel(top_list)>0
                        run_rvm(sym1);
                        run_nb(sym1,mde2,numprc,min(toplevel2(s2),numel(top_list)));
                        run_emp(sym1,outsample_range(t,1),outsample_range(t,1));
                        fileID=fopen([sym1,'_emp.txt']);
                        C = textscan(fileID,'%s');
                        fclose(fileID);
                        C=C{1};
                        C=reshape(C,[12,2]);
                        C=C';
                        Cp=C(2,:);
                        Cp{1,13}=toplevel2(s2);
                        Cp{1,14}=filter_measure;
                        Cp{1,15}=mde2;
                        Cp{1,16}=benchmark_choice{z};
                        tbl=[tbl;Cp];
                    end
                end
                fprintf('calculation finished for %s ...\n',sym1)
                cd('../')
            end
        end
    end
end
%% Recording the results in a table
fl_name=['EMP-BAYES_',num2str(insample_range(1,1)),...
    '_',num2str(insample_range(end,2)),'_Alpha-',num2str(alpha),'_Lambda-',num2str(lambda),'.xlsx'];
tbl_columns=tbl(1,:);
writetable(cell2table(tbl(2:end,:),'VariableNames',tbl_columns),fl_name);
