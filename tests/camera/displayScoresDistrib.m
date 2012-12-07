clear all;
close all;

state = State();
state.rStreams = RandStream.create('mrg32k3a','seed',1,'NumStreams',1,'CellOutput',1);
params.simState = state; 
params.prngId = 1;
params.f = 0;
params.c = 0;
params.psize = 0; 
model = IndepObsModel(params);


N = 10000;
hmax = 60;
xstar = cell(N,1);
for i=1:N
   xstar{i}=[0,0,hmax*rand(1,1),2];
end

hc = cell2mat(cellfun(@(x) x(1,3:4),xstar,'UniformOutput',false));
sp = model.sample(ones(N,1),xstar);
sn = model.sample(zeros(N,1),xstar);


% gp = randn(N,1);
% gn = randn(N,1);
% 
% obj.Ch = 11;
% obj.ChM = 50;
% obj.Cpm1 = 0.55;
% obj.Cpm2 = 0.11;
% obj.Cpm3 = 0.66;
% obj.Cpm4 = -0.005;
% obj.Cpm5 = -0.1;
% obj.Cpsd1 = 7.4e-05;
% obj.Cpsd2 = -0.0061;
% obj.Cpsd3 = 0.16;
% 
% obj.Cnm1 = 0.34;
% obj.Cnm2 = 0.076;
% obj.Cnm3 = 0.416;
% obj.Cnsd1 = 2.4e-05;
% obj.Cnsd2 = -0.0016;
% obj.Cnsd3 =  0.125;
% obj.Cnsd4 =  0.003;
% 
%h = hc(:,1); 
%h(h<0) = 0;
%h(h>obj.ChM) = obj.ChM;
%             
% mp = (h<=obj.Ch).*(obj.Cpm1+obj.Cpm2*cos(pi*(1+h./obj.Ch)))+...
%      (h>obj.Ch).*(obj.Cpm3+obj.Cpm4*(h-obj.Ch))+...
%      obj.Cpm5.*(hc(:,2)==2);
% sdp = (obj.Cpsd1.*h + obj.Cpsd2).*h + obj.Cpsd3;  
% 
% mn = (h<=obj.Ch).*(obj.Cnm1+(obj.Cnm2/obj.Ch)*h)+...
%      (h>obj.Ch).*obj.Cnm3;
% sdn = (obj.Cnsd1.*h + obj.Cnsd2).*h + obj.Cnsd3 +...
%       obj.Cnsd3.*(hc(:,2)==1);
% 
% sp = mp+sdp.*gp;
% sn = mn+sdn.*gn;

figure(1)
plot(hc(:,1),sp,'.r');
hold on;
plot(hc(:,1),sn,'.b');


% height bucket of size dh
dh = 2;
hmeans = zeros(1,ceil(hmax/dh));
hvar = zeros(1,ceil(hmax/dh));
hcnt = zeros(1,ceil(hmax/dh));
hcenters = dh/2:dh:hmax;
for i=1:size(sp,1)
    if(hc(i,1)>0)
        binidx = ceil(hc(i,1)/dh);
        oldmean = hmeans(binidx);
        oldcnt = hcnt(binidx);
        hcnt(binidx) = hcnt(binidx)+1;
        hmeans(binidx) = (oldmean*oldcnt + sp(i))/hcnt(binidx);
        if(oldcnt>0)
            hvar(binidx) = (1-1/oldcnt)*hvar(binidx)+hcnt(binidx)*(hmeans(binidx)-oldmean).^2;
        end
    end
end
figure(8);
errorbar(hcenters,hmeans,sqrt(hvar),'r');

hmeans = zeros(1,ceil(hmax/dh));
hvar = zeros(1,ceil(hmax/dh));
hcnt = zeros(1,ceil(hmax/dh));
hcenters = dh/2:dh:hmax;
for i=1:size(sn,1)
    if(hc(i,1)>0)
        binidx = ceil(hc(i,1)/dh);
        oldmean = hmeans(binidx);
        oldcnt = hcnt(binidx);
        hcnt(binidx) = hcnt(binidx)+1;
        hmeans(binidx) = (oldmean*oldcnt + sn(i))/hcnt(binidx);
        if(oldcnt>0)
            hvar(binidx) = (1-1/oldcnt)*hvar(binidx)+hcnt(binidx)*(hmeans(binidx)-oldmean).^2;
        end
    end
end
figure(8);
hold on;
errorbar(hcenters,hmeans,sqrt(hvar));
xlabel('height [m]');
ylabel('score');
legend('positive','negative');


% pick a bunch of samples from both the positive and the negative models
% and plot them on the bar plot with a color given by the likelihood ratio,
% star if correct, dot if wrong

idxp = randperm(length(sp)); idxp=idxp(1:100)';
idxn = randperm(length(sn)); idxn=idxn(1:100)';
ss = [sp(idxp);sn(idxn)];
hss = [hc(idxp,1);hc(idxn,1)];
css = [hc(idxp,2);hc(idxn,2)];

% mssp = (hss<=obj.Ch).*(obj.Cpm1+obj.Cpm2*cos(pi*(1+hss./obj.Ch)))+...
%        (hss>obj.Ch).*(obj.Cpm3+obj.Cpm4*(hss-obj.Ch))+...
%        obj.Cpm5.*(css==2);
% sdssp = (0.000074.*hss -0.0061).*hss + 0.16;
% lkssp = (1./(sqrt(2*pi).*sdssp)).*exp(-0.5*((ss-mssp)./sdssp).^2);
% 
% mssn = (hss<=obj.Ch).*(obj.Cnm1+(obj.Cnm2/obj.Ch)*hss)+...
%      (hss>obj.Ch).*obj.Cnm3;
% sdssn = (obj.Cnsd1.*hss + obj.Cnsd2).*hss + obj.Cnsd3 +...
%       obj.Cnsd3.*(css==1);
% lkssn = (1./(sqrt(2*pi).*sdssn)).*exp(-0.5*((ss-mssn)./sdssn).^2);
% lkr = lkssp./lkssn;
lkr = model.computeLogLikelihoodDifference([zeros(200,2),hss,css], [zeros(200,2),hss,css], [], ss);

for i=1:length(idxp),
    if(lkr(i)>1)
        plot(hss(i),ss(i),'r*');
    else
        plot(hss(i),ss(i),'b.');
    end
end

for i=length(idxp)+(1:length(idxn)),
    if(lkr(i)<1)
        plot(hss(i),ss(i),'b*');
    else
        plot(hss(i),ss(i),'r.');
    end
end