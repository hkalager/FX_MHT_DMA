% Create 7864 technical trading rules for input symbol,
% Script developed by Arman Hassanniakalager,
% Created on 28 Oct 2015 11:15 GMT,
% Last modified 27 Jul 2021.
% ****************************************
% Input arguments:
% sym1: The desired ticker name available in directory e.g. 'EURUSD'
% transbasis: Transaction cost in basis points (Optional, default=3)
% typ: Type of data: 
% 1 for insample, 2 for out-of-sample & 3 for DMA model
% start: Start date of dataset (YYYY)
% finish: Last date of dataset (YYYY)
% ****************************************
% Outputs:
% A file with all information required named as tickername-in/outsample

function rulegenerator(sym1,transbasis,typ,start,finish)
warning off;
tic;
rng(1);
sym=[sym1,'.csv'];
if  exist(sym,'file')==0
    error('No file with such name available for daily period, retry!');
end
master=importdata(sym,',');
TF1 = contains(master.textdata(:,1),mat2str(start));
TF1=find(TF1==1,1,'first');
startdt=master.textdata(TF1,1);
TF2 = contains(master.textdata(:,1),mat2str(finish));
TF2=find(TF2==1,1,'last');
finishdt=master.textdata(TF2,1);
switch typ
    case 1
        sym3='insample';
        initstart=startdt;
    case 2
        sym3='outsample';
        fllbl=[sym1,'-insample'];
        load(fllbl,'initstart');
        gap1=find(strcmp(master.textdata,startdt))-find(strcmp(master.textdata,initstart));
    case 3
        sym3='DMA';
        fllbl=[sym1,'-insample'];
        load(fllbl,'initstart');
        gap1=find(strcmp(master.textdata,startdt))-find(strcmp(master.textdata,initstart));
end

data=master.data(find(strcmp(master.textdata,initstart)):find(strcmp(master.textdata,finishdt)),4);
highvals=master.data(find(strcmp(master.textdata,initstart)):find(strcmp(master.textdata,finishdt)),2);
lowvals=master.data(find(strcmp(master.textdata,initstart)):find(strcmp(master.textdata,finishdt)),3);
volumes=master.data(find(strcmp(master.textdata,initstart)):find(strcmp(master.textdata,finishdt)),5);
data1=master.data(find(strcmp(master.textdata,initstart)):find(strcmp(master.textdata,finishdt))+1,4);
datsiz=max(size(data));
dataret=price2ret(data1,[],'continuous');
datadir=sign(dataret);
paramstrct=struct('type',[],'case',[],'params',[]); % parameters of each trading rule
if isempty(transbasis)
    transbasis=3;
end
trncost=transbasis*1e-4;
% Alternative in case of CFD calculation:
%transcost=transbasis*1e-4*10^floor(log10(mean(data)));
% Filter rule generation (filt)
xserfilt=[0.005,0.01,0.015,0.020,0.025,0.030,0.035,0.040,0.045,0.050,0.060,0.070,...
    0.080,0.090,0.10,0.12,0.14,0.16,0.18,0.20,0.25,0.30,0.40,0.50]; % alternative in %
yserfilt=[0.0050,0.010,0.015,0.020,0.025,0.030,0.040,0.050,0.075,0.10,0.15,0.2]; % alternative in %
eserfilt=[1:5,10,15,20];
cserfilt=[5,10,25,50];
aa=numel(xserfilt);
%% Filter case 1 (x)
pos=0;
%inputser=nan(dim,7846);
inputser(1,1:aa)=pos;
ope=nan;high=nan;low=nan;
aaa=1;
for iter1=1:aa % for all x
    for iter2=2:datsiz
        if pos==0
            if abs(dataret(iter2-1))>=xserfilt(iter1)
                ope=data(iter2);hld=iter2;
                high=data(iter2);
                low=data(iter2);
                pos=sign(dataret(iter2-1));
            end
        elseif pos==1
            if data(iter2)>high
                high=data(iter2);
            elseif data(iter2)/high-1<-xserfilt(iter1)
                close=data(iter2);
                pos=-1;
                
                hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                aaa=aaa+1;
                ope=close;
                high=close;
                low=close;
            end
            
        else
            if data(iter2)<low
                low=data(iter2);
            elseif data(iter2)/low-1>xserfilt(iter1)
                close=data(iter2);
                pos=1;
                hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                aaa=aaa+1;
                ope=close;
                high=close;
                low=close;
            end
            
        end
        inputser(iter2,iter1)=pos;
    end
    paramstrct.type{iter1}='Filter';
    paramstrct.case(iter1)=1;
    paramstrct.params{iter1}=['x=',num2str(xserfilt(iter1))];
    pos=0;
    aaa=1;
end
%Filter case 2 (x,e)
iter1=iter1+1;
pos=0;
aab=numel(eserfilt);
zzy=find(inputser(1,:)==0, 1, 'last' );
inputser(1,zzy+1:zzy+aa*aab)=pos;
ope=nan;high=nan;low=nan;
aaa=1;
for iter3=1:aab % for all e
    for iter4=1:aa % for all x
        filter=xserfilt(iter4);
        for iter2=2:datsiz
            if pos==0 && iter2>eserfilt(iter3)
                if abs(dataret(iter2-1))>=filter
                    ope=data(iter2);hld=iter2;
                    high=data(iter2);
                    low=data(iter2);
                    pos=sign(dataret(iter2-1));
                end
            elseif pos==1 && iter2>eserfilt(iter3)
                
                if (data(iter2)/max(data(iter2-eserfilt(iter3):iter2-1))-1)<-filter
                    close=data(iter2);
                    pos=-1;
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    ope=close;
                    high=close;
                    low=close;
                end
                
            elseif pos==-1 && iter2>eserfilt(iter3)
                
                if (data(iter2)/min(data(iter2-eserfilt(iter3):iter2-1))-1)>filter
                    close=data(iter2);
                    pos=1;
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    ope=close;
                    high=close;
                    low=close;
                end
                
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='Filter';
        paramstrct.case(iter1)=2;
        paramstrct.params{iter1}=['x=',num2str(xserfilt(iter4)),',e=',num2str(eserfilt(iter3))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
%Filter case 3 (x,c)
pos=0;
aac=max(size(cserfilt));
zzy=find(inputser(1,:)==0, 1, 'last' );
inputser(1,zzy+1:zzy+aac*aa)=pos;
ope=nan;high=nan;low=nan;close=nan;
aaa=1;
for iter3=1:aac % for all c
    for iter4=1:aa % for all x
        filter=xserfilt(iter4);
        for iter2=2:datsiz
            if pos==0
                hold=0;
                if abs(dataret(iter2-1))>=filter
                    ope=data(iter2);hld=iter2;
                    high=data(iter2);
                    low=data(iter2);
                    pos=sign(dataret(iter2-1));
                end
            elseif pos==1
                hold=hold+1;
                if hold==cserfilt(iter3)
                    close=data(iter2);
                    pos=0;
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    ope=close;
                    high=close;
                    low=close;
                    
                end
                
            elseif pos==-1
                hold=hold+1;
                if hold==cserfilt(iter3)
                    close=data(iter2);
                    pos=0;
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    ope=close;
                    high=close;
                    low=close;
                end
                
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='Filter';
        paramstrct.case(iter1)=3;
        paramstrct.params{iter1}=['x=',num2str(xserfilt(iter4)),',c=',num2str(cserfilt(iter3))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
%Filter case 4 (x,y)
pos=0;
aad=max(size(yserfilt));
zzz=1;
%  X-Y combinations generating
for iter5=1:aa
    iter3=1;
    while xserfilt(iter5)>yserfilt(iter3)
        xycomb(zzz,:)=[zzz,yserfilt(iter3),xserfilt(iter5)];
        iter3=iter3+1;
        zzz=zzz+1;
        if iter3>numel(yserfilt)
            break
        end
    end
end
zzz=zzz-1;
zzy=find(inputser(1,:)==0, 1, 'last' );
inputser(1,zzy+1:zzy+zzz)=pos;
ope=nan;high=nan;low=nan;close=nan;
aaa=1;
for iter6=1:max(size(xycomb)) % for all combinations of x,y
    for iter2=2:datsiz
        if pos==0
            if abs(dataret(iter2-1))>=xycomb(iter6,3)
                ope=data(iter2);hld=iter2;
                high=data(iter2);
                low=data(iter2);
                pos=sign(dataret(iter2-1));
            end
        elseif pos==1
            if data(iter2)>high
                high=data(iter2);
            elseif data(iter2)/high-1<-xycomb(iter6,2)
                close=data(iter2);
                pos=0;
                hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                aaa=aaa+1;
                ope=close;
                high=close;
                low=close;
            end
            
        else
            if data(iter2)<low
                low=data(iter2);
            elseif data(iter2)/low-1>xycomb(iter6,2)
                close=data(iter2);
                pos=0;
                hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                aaa=aaa+1;
                ope=close;
                high=close;
                low=close;
            end
            
        end
        inputser(iter2,iter1)=pos;
    end
    paramstrct.type{iter1}='Filter';
    paramstrct.case(iter1)=4;
    paramstrct.params{iter1}=['x=',num2str(xycomb(iter6,3)),',y=',num2str(xycomb(iter6,2))];
    iter1=iter1+1;
    aaa=1;
    pos=0;
end


%% Moving average crossover rules generation (cross)
nsercross=[2,5,10,15,20,25,30,40,50,75,100,125,150,200,250];
bsercross=[.001,.005,.01,.015,.02,.03,.04,.05];
dsercross=2:5;
csercross=[5,10,25,50];
bbb=numel(nsercross);
nmcomb(1:bbb,:)=[(1:bbb)',ones(bbb,1),nsercross'];
iter13=bbb;
% n-m combinations generation
for iter11=2:bbb % for all n
    for iter12=1:iter11-1 % for all m<n
        nmcomb(iter13+1,:)=[iter13+1,nsercross(iter12),nsercross(iter11)];
        iter13=iter13+1;
    end
end
% MA crosover case 1 (n+m)
pos=0;
bba=max(size(nmcomb));
zzy=find(inputser(1,:)==0, 1, 'last' );
inputser(1,zzy+1:zzy+bba)=pos;
aaa=1;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(data,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(data,'s',nmcomb(iter11,3),1);
    for iter2=2:datsiz
        if iter2>nmcomb(iter11,3)
            if pos==0
                if fastmaser(iter2)~=slowmaser(iter2)
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                end
                
            elseif pos==1
                if fastmaser(iter2)<slowmaser(iter2)
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                end
                
            else
                if fastmaser(iter2)>slowmaser(iter2)
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                end
            end
        end
        inputser(iter2,iter1)=pos;
    end
    paramstrct.type{iter1}='MA Cross';
    paramstrct.case(iter1)=1;
    paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3))];
    iter1=iter1+1;
    aaa=1;
    pos=0;
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% MA crosover case 2 (b*n+m)
bbc=numel(bsercross);
inputser(1,zzy+1:zzy+bba*bbc)=pos;
aaa=1;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(data,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(data,'s',nmcomb(iter11,3),1);
    for iter14=1:bbc % for all b
        band=bsercross(iter14);
        for iter2=2:datsiz
            if iter2>nmcomb(iter11,3)
                if pos==0
                    if abs(fastmaser(iter2)/slowmaser(iter2)-1)>band
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                elseif pos==1
                    if abs(fastmaser(iter2)/slowmaser(iter2)-1)<-band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                else
                    if abs(fastmaser(iter2)/slowmaser(iter2)-1)>band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='MA Cross';
        paramstrct.case(iter1)=2;
        paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3)),',b=',num2str(bsercross(iter14))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );
% MA crosover case 3 (d*n+m)
bbd=numel(dsercross);
inputser(1,zzy+1:zzy+bba*bbd)=pos;
aaa=1;band=0;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(data,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(data,'s',nmcomb(iter11,3),1);
    for iter15=1:bbd % for all d
        delay=dsercross(iter15);
        for iter2=2:datsiz
            if iter2>nmcomb(iter11,3)
                if pos==0
                    if abs(abs(fastmaser(iter2)/slowmaser(iter2)-1))>band
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                elseif pos==1 && hold>=delay
                    if fastmaser(iter2)/slowmaser(iter2)-1<-band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                    
                elseif pos==-1 && hold>=delay
                    if fastmaser(iter2)/slowmaser(iter2)-1>band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        hold=0;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                else
                    hold=hold+1;
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='MA Cross';
        paramstrct.case(iter1)=3;
        paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3)),',d=',num2str(dsercross(iter15))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% MA crosover case 4 (c*n+m)
bbe=numel(csercross);
inputser(1,zzy+1:zzy+bba*bbe)=pos;
aaa=1;band=0;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(data,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(data,'s',nmcomb(iter11,3),1);
    for iter15=1:bbd % for all c
        holdtime=csercross(iter15);
        for iter2=2:datsiz
            if iter2>nmcomb(iter11,3)
                if pos==0
                    if abs(abs(fastmaser(iter2)/slowmaser(iter2)-1))>band
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                elseif pos==1 && hold==holdtime
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=0;
                    ope=data(iter2);hld=iter2;
                    hold=0;
                    
                elseif pos==-1 && hold==holdtime
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=0;
                    ope=data(iter2);hld=iter2;
                else
                    hold=hold+1;
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='MA Cross';
        paramstrct.case(iter1)=4;
        paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3)),',c=',num2str(csercross(iter15))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% MA crosover case 5 (b=.01,c=10, select n&m)
inputser(1,zzy+1:zzy+9)=pos;
aaa=1;band=.01;
holdtime=10;
nmcombsel=nan(3,3);
nsercrosssel=[50,150,200];
msercrosssel=[1,2,5];
iter13=0;
for iter11=1:3
    for iter12=1:3
        nmcombsel(iter13+1,:)=[iter13+1,msercrosssel(iter12),nsercrosssel(iter11)];
        iter13=iter13+1;
    end
end
bbf=max(size(nmcombsel));

for iter11=1:bbf % for all n
    fastmaser=tsmovavg(data,'s',nmcombsel(iter11,2),1);
    slowmaser=tsmovavg(data,'s',nmcombsel(iter11,3),1);
    for iter2=2:datsiz
        if iter2>nmcombsel(iter11,3)
            if pos==0
                if abs(fastmaser(iter2)/slowmaser(iter2)-1)>band
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                    hold=0;
                end
            elseif pos==1 && hold==holdtime
                hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                aaa=aaa+1;
                pos=0;
                ope=data(iter2);hld=iter2;
                hold=0;
                
            elseif pos==-1 && hold==holdtime
                hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                aaa=aaa+1;
                pos=0;
                ope=data(iter2);hld=iter2;
            else
                hold=hold+1;
            end
        end
        inputser(iter2,iter1)=pos;
    end
    paramstrct.type{iter1}='MA Cross';
    paramstrct.case(iter1)=5;
    paramstrct.params{iter1}=['n=',num2str(nmcombsel(iter11,2)),',m=',num2str(nmcombsel(iter11,3)),',b=',num2str(0.01),',c=',num2str(10)];
    iter1=iter1+1;
    aaa=1;
    pos=0;
    
end
zzy=find(inputser(1,:)==0, 1, 'last' );

%% Support and resilience trading rules generation (S_R)
nsers_r=[5,10,15,20,25,50,100,150,200,250];
esers_r=[2,3,4,5,10,20,25,50,100,200];
bsers_r=[.001,.005,.01,.015,.02,.03,.04,.05];
dsers_r=2:5;
csers_r=[0,5,10,25,50];
% creating n-e comb and condition
necombcount=numel(nsers_r)+numel(esers_r);
necomb=nan(necombcount,3);
necombint=[nsers_r,esers_r];
for iter21=1:necombcount
    if iter21<=numel(nsers_r) % for n series daily extreme is considered (1)
        necomb(iter21,2)=1;
    else                      % for e series extreme daily close in considered (2)
        necomb(iter21,2)=2;
    end
    necomb(iter21,1)=iter21;
    necomb(iter21,3)=necombint(iter21);
end

% S&R case 1, n-e combintions+c
inputser(1,zzy+1:zzy+numel(csers_r)*necombcount)=pos;
aaa=1;
for iter22=1:necombcount % for all n-e comb
    for iter23=1:numel(csers_r) % for all c
        for iter2=2:datsiz
            if csers_r(iter23)==0 && iter2>necomb(iter22,3)
                if pos==0 && necomb(iter22,2)==1
                    if data(iter2)>max(highvals(iter2-necomb(iter22,3):iter2-1)) ...
                            || data(iter2)<min(lowvals(iter2-necomb(iter22,3):iter2-1))
                        pos=sign(dataret(iter2-1));
                        ope=data(iter2);hld=iter2;
                    end
                elseif pos==1 && necomb(iter22,2)==1
                    if data(iter2)<min(lowvals(iter2-necomb(iter22,3):iter2-1))
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=-1;
                        ope=data(iter2);hld=iter2;
                    end
                    
                elseif pos==-1 && necomb(iter22,2)==1
                    if data(iter2)>max(highvals(iter2-necomb(iter22,3):iter2-1))
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=1;
                        ope=data(iter2);hld=iter2;
                    end
                    
                elseif pos==0 && necomb(iter22,2)==2
                    if data(iter2)>max(data(iter2-necomb(iter22,3):iter2-1)) ...
                            || data(iter2)<min(data(iter2-necomb(iter22,3):iter2-1))
                        pos=sign(dataret(iter2-1));
                        ope=data(iter2);hld=iter2;
                    end
                elseif pos==1 && necomb(iter22,2)==2
                    if data(iter2)<min(data(iter2-necomb(iter22,3):iter2-1))
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=-1;
                        ope=data(iter2);hld=iter2;
                    end
                    
                elseif pos==-1 && necomb(iter22,2)==2
                    if data(iter2)>max(data(iter2-necomb(iter22,3):iter2-1))
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=1;
                        ope=data(iter2);hld=iter2;
                    end
                end
                
            elseif csers_r(iter23)~=0 && iter2>necomb(iter22,3) % just for readibility
                holdtime=csers_r(iter23);
                if pos==0 && necomb(iter22,2)==1
                    if data(iter2)>max(highvals(iter2-necomb(iter22,3):iter2-1)) ...
                            || data(iter2)<min(lowvals(iter2-necomb(iter22,3):iter2-1))
                        pos=sign(dataret(iter2-1));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                elseif pos==1 && necomb(iter22,2)==1
                    if hold==holdtime
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=0;
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    else
                        hold=hold+1;
                    end
                    
                elseif pos==-1 && necomb(iter22,2)==1
                    if hold==holdtime
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=0;
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    else
                        hold=hold+1;
                    end
                    
                elseif pos==0 && necomb(iter22,2)==2
                    if data(iter2)>max(data(iter2-necomb(iter22,3):iter2-1)) ...
                            || data(iter2)<min(data(iter2-necomb(iter22,3):iter2-1))
                        pos=sign(dataret(iter2-1));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                elseif pos==1 && necomb(iter22,2)==2
                    if hold==holdtime
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=0;
                        hold=0;
                        ope=data(iter2);hld=iter2;
                    else
                        hold=hold+1;
                    end
                    
                elseif pos==-1 && necomb(iter22,2)==2
                    if hold==holdtime
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=0;
                        hold=0;
                        ope=data(iter2);hld=iter2;
                    end
                else
                    hold=hold+1;
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='S&R';
        paramstrct.case(iter1)=1;
        if necomb(iter22,2)==1
            paramstrct.params{iter1}=['c=',num2str(csers_r(iter23)),',n=',num2str(necomb(iter22,3))];
        else
            paramstrct.params{iter1}=['c=',num2str(csers_r(iter23)),',e=',num2str(necomb(iter22,3))];
        end
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% S&R case 2, n-e combintions+c+b
inputser(1,zzy+1:zzy+numel(csers_r)*necombcount*numel(bsers_r))=pos;
aaa=1;
for iter22=1:necombcount % for all n-e comb
    for iter23=1:numel(csers_r) % for all c
        for iter24=1:numel(bsers_r) % for all b
            band=bsers_r(iter24);
            for iter2=2:datsiz
                if csers_r(iter23)==0 && iter2>necomb(iter22,3)
                    if pos==0 && necomb(iter22,2)==1
                        if (data(iter2)/max(highvals(iter2-necomb(iter22,3):iter2-1))-1)>band ...
                                || (data(iter2)/min(lowvals(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            pos=sign(dataret(iter2-1));
                            ope=data(iter2);hld=iter2;
                        end
                    elseif pos==1 && necomb(iter22,2)==1
                        if (data(iter2)/min(lowvals(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=-1;
                            ope=data(iter2);hld=iter2;
                        end
                        
                    elseif pos==-1 && necomb(iter22,2)==1
                        if (data(iter2)/max(highvals(iter2-necomb(iter22,3):iter2-1))-1)>band
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=1;
                            ope=data(iter2);hld=iter2;
                        end
                        
                    elseif pos==0 && necomb(iter22,2)==2
                        if (data(iter2)/max(data(iter2-necomb(iter22,3):iter2-1))-1)>band ...
                                || (data(iter2)/min(data(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            pos=sign(dataret(iter2-1));
                            ope=data(iter2);hld=iter2;
                        end
                    elseif pos==1 && necomb(iter22,2)==2
                        if (data(iter2)/min(data(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=-1;
                            ope=data(iter2);hld=iter2;
                        end
                        
                    elseif pos==-1 && necomb(iter22,2)==2
                        if (data(iter2)/max(data(iter2-necomb(iter22,3):iter2-1))-1)>band
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=1;
                            ope=data(iter2);hld=iter2;
                        end
                    end
                elseif csers_r(iter23)~=0 && iter2>necomb(iter22,3) % just for readibility
                    holdtime=csers_r(iter23);
                    if pos==0 && necomb(iter22,2)==1
                        if (data(iter2)/max(highvals(iter2-necomb(iter22,3):iter2-1))-1)>band ...
                                || (data(iter2)/min(lowvals(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            pos=sign(dataret(iter2-1));
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        end
                    elseif pos==1 && necomb(iter22,2)==1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==-1 && necomb(iter22,2)==1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==0 && necomb(iter22,2)==2
                        if (data(iter2)/max(data(iter2-necomb(iter22,3):iter2-1))-1)>band ...
                                || (data(iter2)/min(data(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            pos=sign(dataret(iter2-1));
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        end
                    elseif pos==1 && necomb(iter22,2)==2
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==-1 && necomb(iter22,2)==2
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                        end
                    else
                        hold=hold+1;
                    end
                end
                inputser(iter2,iter1)=pos;
            end
            paramstrct.type{iter1}='S&R';
            paramstrct.case(iter1)=2;
            if necomb(iter22,2)==1
                paramstrct.params{iter1}=['c=',num2str(csers_r(iter23)),',b=',num2str(bsers_r(iter24)),',n=',num2str(necomb(iter22,3))];
            else
                paramstrct.params{iter1}=['c=',num2str(csers_r(iter23)),',b=',num2str(bsers_r(iter24)),',e=',num2str(necomb(iter22,3))];
            end
            iter1=iter1+1;
            aaa=1;
            pos=0;
        end
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% S&R case 3, n-e combintions+c+d
inputser(1,zzy+1:zzy+(numel(csers_r)-1)*necombcount*numel(dsers_r))=pos;
aaa=1;band=0;
for iter22=1:necombcount % for all n-e comb
    for iter23=2:numel(csers_r) % for all c excluding zero case
        for iter24=1:numel(dsers_r) % for all d
            delaylev=dsers_r(iter24);
            holdtime=csers_r(iter23);
            delay=0;
            for iter2=2:datsiz
                if iter2>necomb(iter22,3)
                    if pos==0 && delay<delaylev
                        delay=delay+1;
                    elseif pos==0 && necomb(iter22,2)==1 && delay>=delaylev
                        if (data(iter2)/max(highvals(iter2-necomb(iter22,3):iter2-1))-1)>band ...
                                || (data(iter2)/min(lowvals(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            pos=sign(dataret(iter2-1));
                            ope=data(iter2);hld=iter2;
                            hold=0;
                            delay=0;
                        end
                    elseif pos==1 && necomb(iter22,2)==1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==-1 && necomb(iter22,2)==1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==0 && necomb(iter22,2)==2 && delay>=delaylev
                        if (data(iter2)/max(data(iter2-necomb(iter22,3):iter2-1))-1)>band ...
                                || (data(iter2)/min(data(iter2-necomb(iter22,3):iter2-1))-1)<-band
                            pos=sign(dataret(iter2-1));
                            ope=data(iter2);hld=iter2;
                            hold=0;
                            delay=0;
                        end
                    elseif pos==1 && necomb(iter22,2)==2
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==-1 && necomb(iter22,2)==2
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                        else
                            hold=hold+1;
                        end
                    end
                end
                inputser(iter2,iter1)=pos;
            end
            paramstrct.type{iter1}='S&R';
            paramstrct.case(iter1)=2;
            if necomb(iter22,2)==1
                paramstrct.params{iter1}=['c=',num2str(csers_r(iter23)),',d=',num2str(dsers_r(iter24)),',n=',num2str(necomb(iter22,3))];
            else
                paramstrct.params{iter1}=['c=',num2str(csers_r(iter23)),',d=',num2str(dsers_r(iter24)),',e=',num2str(necomb(iter22,3))];
            end
            iter1=iter1+1;
            aaa=1;
            pos=0;
        end
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

%% Channel breakout trading rules generation (CHB)
nserchb=[5,10,15,20,25,50,100,150,200,250];
xserchb=[.005,.01,.02,.03,.05,.075,.1,.15];
bserchb=[.001,.005,.01,.015,.02,.03,.04,.05];
cserchb=[5,10,25,50];
% creating x-b comb and condition
iter33=1;
for iter31=1:numel(xserchb)
    iter32=1;
    while xserchb(iter31)>bserchb(iter32)
        xbcomb(iter33,:)=[iter33,bserchb(iter32),xserchb(iter31)];
        iter33=iter33+1;
        iter32=iter32+1;
        if iter32>numel(bserchb)
            break
        end
    end
end
iter33=iter33-1;
% CHB case 1, n+x+c
inputser(1,zzy+1:zzy+numel(nserchb)*numel(xserchb)*numel(cserchb))=pos;
aaa=1;band=0;
for iter34=1:numel(nserchb) % for all n
    for iter35=1:numel(xserchb) % for all x
        channel=xserchb(iter35);
        for iter36=1:numel(cserchb) % for all c
            holdtime=cserchb(iter36);
            for iter2=2:datsiz
                if iter2>nserchb(iter34)
                    if pos==0
                        if (data(iter2)/min(lowvals(iter2-nserchb(iter34):iter2-1))-1-channel)>band
                            pos=1;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        elseif (data(iter2)/max(highvals(iter2-nserchb(iter34):iter2-1))-1-channel)<-band
                            pos=-1;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        end
                        
                    elseif pos==1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==-1
                        if hold==holdtime
                            
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                            
                        else
                            hold=hold+1;
                        end
                        
                    end
                end
                inputser(iter2,iter1)=pos;
            end
            paramstrct.type{iter1}='CHB';
            paramstrct.case(iter1)=1;
            paramstrct.params{iter1}=['n=',num2str(nserchb(iter34)),',x=',num2str(xserchb(iter35)),',c=',num2str(cserchb(iter36))];
            iter1=iter1+1;
            aaa=1;
            pos=0;
        end
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );
% CHB case 2, n+c+x-b combinations
xbcombcount=max(size((xbcomb)));
inputser(1,zzy+1:zzy+numel(nserchb)*xbcombcount*numel(cserchb))=pos;
aaa=1;
for iter34=1:numel(nserchb) % for all n
    for iter35=1:xbcombcount % for all x-b combinations
        band=xbcomb(iter35,2);
        channel=xbcomb(iter35,3);
        for iter36=1:numel(cserchb) % for all c
            holdtime=cserchb(iter36);
            for iter2=2:datsiz
                if iter2>nserchb(iter34)
                    if pos==0
                        if (data(iter2)/min(lowvals(iter2-nserchb(iter34):iter2-1))-1-channel)>band
                            pos=1;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        elseif (data(iter2)/max(highvals(iter2-nserchb(iter34):iter2-1))...
                                -1-channel)<-band
                            pos=-1;
                            ope=data(iter2);hld=iter2;
                            hold=0;
                        end
                        
                    elseif pos==1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                        else
                            hold=hold+1;
                        end
                        
                    elseif pos==-1
                        if hold==holdtime
                            hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                            aaa=aaa+1;
                            pos=0;
                            hold=0;
                            ope=data(iter2);hld=iter2;
                            
                        else
                            hold=hold+1;
                        end
                        
                    end
                end
                inputser(iter2,iter1)=pos;
            end
            paramstrct.type{iter1}='CHB';
            paramstrct.case(iter1)=2;
            paramstrct.params{iter1}=['n=',num2str(nserchb(iter34)),',x=',num2str(xbcomb(iter35,3)),',b=',num2str(xbcomb(iter35,2)),',c=',num2str(cserchb(iter36))];
            iter1=iter1+1;
            aaa=1;
            pos=0;
        end
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

%% On-Balance Volume Average rules generation (OBV)
obvser=onbalvol(data,volumes);
iter11=0;iter12=0;iter14=0;iter15=0;
nserobv=[2,5,10,15,20,25,30,40,50,75,100,125,150,200,250];
bserobv=[.001,.005,.01,.015,.02,.03,.04,.05];
dserobv=2:5;
cserobv=[5,10,25,50];
bbb=numel(nserobv);
nmcomb(1:bbb,:)=[(1:bbb)',ones(bbb,1),nserobv'];
iter13=bbb;
for iter11=2:bbb
    for iter12=1:iter11-1
        nmcomb(iter13+1,:)=[iter13+1,nserobv(iter12),nserobv(iter11)];
        iter13=iter13+1;
    end
end
% OBV case 1
bba=max(size(nmcomb));
inputser(1,zzy+1:zzy+bba)=pos;
aaa=1;
for iter11=1:bba % for all n+m
    fastmaser=tsmovavg(obvser,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(obvser,'s',nmcomb(iter11,3),1);
    for iter2=2:datsiz
        if iter2>nmcomb(iter11,3)
            if pos==0
                if fastmaser(iter2)~=slowmaser(iter2)
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                end
                
            elseif pos==1
                if fastmaser(iter2)<slowmaser(iter2)
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                end
                
            else
                if fastmaser(iter2)>slowmaser(iter2)
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=sign(fastmaser(iter2)-slowmaser(iter2));
                    ope=data(iter2);hld=iter2;
                end
            end
        end
        inputser(iter2,iter1)=pos;
    end
    paramstrct.type{iter1}='OBV';
    paramstrct.case(iter1)=1;
    paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3))];
    iter1=iter1+1;
    aaa=1;
    pos=0;
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% OBV case 2 (b*n+m)
bbc=numel(bserobv);
inputser(1,zzy+1:zzy+bba*bbc)=pos;
aaa=1;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(obvser,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(obvser,'s',nmcomb(iter11,3),1);
    for iter14=1:bbc % for all b
        band=bserobv(iter14);
        for iter2=2:datsiz
            if iter2>nmcomb(iter11,3)
                if pos==0
                    if abs(fastmaser(iter2)/slowmaser(iter2)-1)>band
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                elseif pos==1
                    if fastmaser(iter2)/slowmaser(iter2)-1<-band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                    
                else
                    if fastmaser(iter2)/slowmaser(iter2)-1>band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='OBV';
        paramstrct.case(iter1)=2;
        paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3)),',b=',num2str(bsercross(iter14))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );
% OBV case 3 (d*n+m)
bbd=numel(dserobv);
inputser(1,zzy+1:zzy+bba*bbd)=pos;
aaa=1;band=0;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(obvser,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(obvser,'s',nmcomb(iter11,3),1);
    for iter15=1:bbd % for all d
        delay=dserobv(iter15);
        for iter2=2:datsiz
            if iter2>nmcomb(iter11,3)
                if pos==0
                    if abs(fastmaser(iter2)/slowmaser(iter2)-1)>band
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                elseif pos==1 && hold>=delay
                    if fastmaser(iter2)/slowmaser(iter2)-1<-band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                    
                elseif pos==-1 && hold>=delay
                    if fastmaser(iter2)/slowmaser(iter2)-1>band
                        hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                        aaa=aaa+1;
                        hold=0;
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                    end
                else
                    hold=hold+1;
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='OBV';
        paramstrct.case(iter1)=3;
        paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3)),',d=',num2str(dsercross(iter15))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );

% OBV case 4 (c*n+m)
bbe=numel(cserobv);
inputser(1,zzy+1:zzy+bba*bbe)=pos;
aaa=1;band=0;
for iter11=1:bba % for all n
    fastmaser=tsmovavg(obvser,'s',nmcomb(iter11,2),1);
    slowmaser=tsmovavg(obvser,'s',nmcomb(iter11,3),1);
    for iter15=1:bbd % for all c
        holdtime=cserobv(iter15);
        for iter2=2:datsiz
            if iter2>nmcomb(iter11,3)
                if pos==0
                    if abs(fastmaser(iter2)/slowmaser(iter2)-1)>band
                        pos=sign(fastmaser(iter2)-slowmaser(iter2));
                        ope=data(iter2);hld=iter2;
                        hold=0;
                    end
                elseif pos==1 && hold==holdtime
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=0;
                    ope=data(iter2);hld=iter2;
                    hold=0;
                    
                elseif pos==-1 && hold==holdtime
                    hldp(aaa,iter1)=iter2-hld;hldt(aaa,iter1)=iter2;hld=iter2;
                    aaa=aaa+1;
                    pos=0;
                    ope=data(iter2);hld=iter2;
                else
                    hold=hold+1;
                end
            end
            inputser(iter2,iter1)=pos;
        end
        paramstrct.type{iter1}='OBV';
        paramstrct.case(iter1)=4;
        paramstrct.params{iter1}=['n=',num2str(nmcomb(iter11,2)),',m=',num2str(nmcomb(iter11,3)),',c=',num2str(csercross(iter15))];
        iter1=iter1+1;
        aaa=1;
        pos=0;
    end
end
zzy=find(inputser(1,:)==0, 1, 'last' );


%% Output arguments & finalizing
% Applying transaction cost
ret=TransCost(inputser,dataret,trncost);
tts=zzy*numel(dataret); % Total trading signal
cumretadj=cumsum(ret); % Cumulative return with transaction cost for adjusted returns
finalret=cumretadj(end,:);
disp(' Data generation completed ...');
fllbl=[sym1,'-',sym3];
switch typ
    case 1
        save(fllbl);
    case 2 % For out-of-sample one step before formal start is considered to avoid losing any observation
        inputser(1:gap1-1,:)=[];
        data(1:gap1-1)=[];
        datadir(1:gap1-1)=[];
        save(fllbl,'inputser','data','datadir','start','finish','initstart','gap1');
    case 3
        save(fllbl,'inputser','data','datadir','start','finish','initstart','gap1');
end
toc