clear all;
close all;

set = 2;

e = 340;
% radio with mo

dt = 0.4;
    
if(set==1)

    files = {'uav4-serial--21_5-13_56_gps.csv','uav4-serial--21_5-13_25_gps.csv==','uav4-serial--21_5-15_22_gps.csv',...
        'uav4-serial--21_5-13_27_gps.csv--','uav4-serial--21_5-15_28_gps.csv','uav4-serial--21_5-13_29_gps.csv',...
        'uav4-serial--21_5-15_36_gps.csv','uav4-serial--21_5-13_30_gps.csv','uav4-serial--21_5-15_9_gps.csv',...
        'uav4-serial--21_5-13_33_gps.csv'};

    d  = csvread(['/home/rdenardi/complacs/qrsim/tests/gt/gps/fromradio/',files{5}]);
    d = d(1:e,:);

    t = d(:,1)'-d(1,1);
    lat = d(:,2)'./1e7;
    lon = d(:,3)'./1e7;
    h = d(:,4)'./1000;

    dt = 0.4;

else
    files = {'arTest2Video-8_3_111-13_36_30_gps.csv','arTest2Video-8_3_111-13_38_2.csv',...
        'arTest2Video-8_3_111-14_12_42_gps.csv','arTest2Video-8_3_111-14_27_53_gps.csv',...
        'arTest2Video-8_3_111-14_39_13_gps.csv'};

    d  = csvread(['/home/rdenardi/complacs/qrsim/tests/gt/gps/fromar2/',files{4}]);
    d = d(1:e,:);
    
    t = d(:,1)'-d(1,1);
    lat = d(:,4)'./1e7;
    lon = d(:,5)'./1e7;
    h = d(:,6)'./1000;

end

[E,N,zone,h] = lla2utm([lat;lon;h]);
E = E-E(1);
N = N-N(1);
figure;
plot(lat,lon);

figure;
plot(E,N);

figure;
plot(t,h);


data.rate = 1/dt;
data.freq = E;

[retval, s, errorb] = allan(data,[2^0 2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11]*dt,'x acc');

