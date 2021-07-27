% Apply transaction cost to a series of Technical Analysis signals
% Script developed by Arman Hassannia Kalager for completing 1st chapter,
% Created on 14 Jul 2017 13:37 BST,
% Last modified 16 Oct 2017 17:13 BST.
% ****************************************
% Input arguments:
% Inputser: The trading signals
% dataret: The return series of underlying asset
% trncost: The transaction cost (default= 3bp= 3e-4)
% ****************************************
% Outputs:
% Transaction cost adjusted series;

function [ret,trades]=TransCost(inputser,dataret,trncost)
ret=zeros(size(inputser));
grmat=size(ret);
if size(inputser,1)~=size(dataret,1)
    error(' The number of instances does not match');
end
if isempty(trncost)
    trncost=3e-4;
end
sigcng=vertcat(zeros(1,grmat(2)),abs(min(max(diff(inputser),-1),1)));
% Adjust return for zero values and transaction costs
trades=0;
for iter32=1:grmat(2) % all models
    ret(1,iter32)=dataret(1)*inputser(1,iter32);
    for iter33=2:grmat(1) % all observations 
        ret(iter33,iter32)=dataret(iter33)*inputser(iter33,iter32)-...
            abs(inputser(iter33,iter32))*trncost*sigcng(iter33,iter32);
        trades=trades+abs(inputser(iter33,iter32))*sigcng(iter33,iter32);
    end
end