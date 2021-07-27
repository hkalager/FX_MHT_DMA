addpath(genpath(pwd))
part1=pwd;
%% Specification of experiments
% In-sample period
insampleper=[2010,2012;
    2011,2013;
    2012,2014;
    2013,2015];
%% Series
symser={'EURUSD''1440','GBPUSD''1440','USDJPY''1440'};%,'AUDUSD''1440','NZDUSD''1440','USDCHF''1440'};
%% Filteration
% Filtering process methods
mde1={'ret'};
% Filtering level (percentile)
toplevel1=5;
%% Data-snooping
% Data snooping test benchmark types 
benchtyp={'riskless'};%,'rand'};
% If the riskless asset is used the fixed return level determined below
% Data snooping survivors rules selection methods
mde2={'accuracy'};
% Data snooping selection level (number/percentile)
toplevel2=5;
% Selection between number or percentile 'count' for number and 'prc' for
% percentile
numprc='count';
%% Table preparation
tbl=table();

%% Running the experiments 
v=0;
for t=1:size(insampleper,1) % all sample periods
    for s1=1:numel(toplevel1) % All filtering levels 
        for x1=1:numel(mde1) % filtering options
            for s2=1:numel(toplevel2) % All data snooping selection level
                for x2=1:numel(mde2)
                    for z=1:numel(benchtyp)
                        serlbl=['Backtest_(',num2str(insampleper(t,1)),'-',num2str(insampleper(t,2)),...
                            ')-',mde1{x1},'-',num2str(toplevel1(s1)),'-',mde2{x2},'-',num2str(toplevel2(s2)),'-',numprc,'-',benchtyp{z}];
                        pathdir=[part1,'/',serlbl];
                        cd(pathdir);
                        for iter=1:numel(symser)
                            v=v+1;
                            sym1=symser{iter};
                            load(['DSTres-',sym1],'goldind');
                            IS_data=[sym1,'-insample'];
                            IS_struct=load(IS_data,'inputser','data','dataret');                          
                            ret=price2ret(IS_struct.data,[],'Continuous');
                            DSTsurvivors=numel(goldind);
                            IS_inputser=IS_struct.inputser;
                            IS_ret=IS_inputser(1:end-1,goldind).*ret;
                            
                            [includedR,pvalsR]=mcs(-IS_ret,.1, 1000, 10)
                            
                            
                            
                            %% Writing to table
                            tbl{v,'Symbol'}=symser(iter);
                            tbl{v,'IS_Start'}={insampleper(t,1)};
                            tbl{v,'IS_Finish'}={insampleper(t,2)};
                            tbl{v,'Mode_Filter'}=mde1(x1);
                            tbl{v,'Mode_Test'}=mde2(x2);
                            tbl{v,'Benchmark'}=benchtyp(z);
                            tbl{v,'DST_survivors'}={DSTsurvivors};
                            tbl{v,'pval_dst'}=pval_dst;
                            tbl{v,'pval_rvm'}=pval_rvm;
                            tbl{v,'pval_nb'}=pval_nb;
                            tbl{v,'pval_top'}=pval_top;
                            tbl{v,'top_count'}=size(topser_ret,2);
                            
                        end
                        clc;
                        cd('../')
                    end
                end
            end
        end
    end
end
%% Recording the results in a table
writetable(tbl,['GW_Test_Table_',num2str(insampleper(1,1)),'_',num2str(insampleper(end,2)),'.xlsx']);