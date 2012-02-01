function [ e ] = testAssertions()
%TESTASSERTIONS test assertion for missing initialization parameters
% returns 0 if all tests passed

addpath('assert');

e = 0;

e = e & loadBadlySpecifiedTask('TaskNoDT','qrsim:nodt','missing DT task parameter');
e = e & loadBadlySpecifiedTask('TaskNoSeed','qrsim:noseed','missing seed task parameter');
e = e & loadBadlySpecifiedTask('TaskNoDisplay3D','qrsim:nodisplay3d','missing display3d task parameter');
e = e & loadBadlySpecifiedTask('TaskNoDisplay3DHeight','qrsim:nodisplay3dwidthorheight','missing display3d.height task parameter');
e = e & loadBadlySpecifiedTask('TaskNoDisplay3DWidth','qrsim:nodisplay3dwidthorheight','missing display3d.width task parameter');

e = e & loadWorkingTaskWith3DDisplayOff('TaskDisplay3DOff','3D display off');

e = e & loadBadlySpecifiedTask('TaskNoAreaType','qrsim:noareatype','missing area.type task parameter');
e = e & loadBadlySpecifiedTask('TaskNoAreaLimits','boxarea:nolimits','missing area.limits task parameter');
e = e & loadBadlySpecifiedTask('TaskNoAreaOriginUTMCoords','boxarea:nooriginutmcoords','missing area.originutmcoords task parameter');
e = e & loadBadlySpecifiedTask('TaskNoAreaGraphicsType','boxarea:nographicstype','missing area.graphics.type task parameter');

e = e & loadWorkingTaskWithObjectOff('TaskGPSSpaceSegmentOff','state.environment.gpsspacesegment','GPSSpaceSegment','gpsspacesegment off');

e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentType','qrsim:nogpsspacesegmenttype','missing gpsspacesegment.type task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentDt','steppable:nodt','missing gpsspacesegment.dt task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpacesegmentOrbitFileA','gpsspacesegmentgm2:noorbitfile','missing gpsspacesegment.orbitfile task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpacesegmentOrbitFileB','gpsspacesegmentgm:noorbitfile','missing gpsspacesegment.orbitfile task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpacesegmenttStartA','gpsspacesegmentgm2:notstart','missing gpsspacesegment.tStart task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpacesegmenttStartB','gpsspacesegmentgm:notstart','missing gpsspacesegment.tStart task parameter'); 
e = e & loadBadlySpecifiedTask('TaskNoGPSSpacesegmenttSVSA','gpsspacesegmentgm2:nosvs','missing gpsspacesegment.svs task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpacesegmenttSVSB','gpsspacesegmentgm:nosvs','missing gpsspacesegment.svs task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentBeta2','gpsspacesegmentgm2:nobeta2','missing gpsspacesegment.PR_BETA2 task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentBeta1','gpsspacesegmentgm2:nobeta1','missing gpsspacesegment.PR_BETA1 task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentBeta','gpsspacesegmentgm:nobeta','missing gpsspacesegment.PR_BETA task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentSigmaA','gpsspacesegmentgm2:nosigma','missing gpsspacesegment.PR_SIGMA task parameter');
e = e & loadBadlySpecifiedTask('TaskNoGPSSpaceSegmentSigmaB','gpsspacesegmentgm:nosigma','missing gpsspacesegment.PR_SIGMA task parameter');
e = e & loadBadlySpecifiedTask('TaskNoWind','qrsim:nowind','missing wind.on task parameter');

e = e & loadWorkingTaskWithObjectOff('TaskWindOff','state.environment.wind','Wind','wind off');
 
e = e & loadBadlySpecifiedTask('TaskNoWindType','qrsim:nowindtype','missing wind.type task parameter');
e = e & loadBadlySpecifiedTask('TaskNoWindDirection','windconstmean:nodirection','missing wind.direction task parameter');
e = e & loadBadlySpecifiedTask('TaskNoWindW6','windconstmean:now6','missing wind.W6 task parameter');
e = e & loadBadlySpecifiedTask('TaskNoPlatformsConfigFile','qrsim:noplatforms','missing platforms task parameter');
e = e & loadBadlySpecifiedTask('TaskNoPlatformsX','qrsim:noplatformsx','missing platforms initial state task parameter');
e = e & loadBadlySpecifiedTask('TaskNoPlatformType','qrsim:noplatformtype','missing platform type parameter');
e = e & loadBadlySpecifiedTask('TaskNoPlatformStateLimits','pelican:nostatelimits','missing platform state limits');
e = e & loadBadlySpecifiedTask('TaskNoPlatformCollisionDistance','pelican:nocollisiondistance','missing platform collision distance');
e = e & loadBadlySpecifiedTask('TaskNoPlatformDynNoise','pelican:nodynnoise','missing platform dynamic noise');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGPSReceiver','pelican:nogpsreceiver','missing platform gps receiver');

e = e & loadWorkingTaskWithObjectOff('TaskPlatformGPSReceiverOff','state.platforms(1).gpsreceiver','GPSReceiver','gpsreceiver off');

e = e & loadBadlySpecifiedTask('TaskNoPlatformGPSReceiverType','pelican:nogpsreceivertype','missing platform gps receiver type');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGPSReceiverSigma','gpsreceiverg:nosigma','missing gps receiver sigma');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGPSReceiverNumSVS','gpsreceiverg:nonumsvs','missing gps receiver num svs');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGPSReceiverDelay','gpsreceiverg:nodelay','missing gps receiverdelay');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAHARS','pelican:noahars','missing ahars');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAHARSType','pelican:noaharstype','missing ahars type');

e = e & loadBadlySpecifiedTask('TaskNoPlatformAerodynamicTurbulence','qrsim:noaerodynamicturbulence','missing aerodynamic turbulence');

e = e & loadWorkingTaskWithObjectOff('TaskPlatformAerodynamicTurbulenceOff','state.platforms(1).aerodynamicTurbulence','AerodynamicTurbulence','aerodynamic turbulence off');

e = e & loadBadlySpecifiedTask('TaskNoPlatformAerodynamicTurbulenceType','pelican:noaerodynamicturbulencetype','missing aerodynamic turbulence type');

e = e & loadBadlySpecifiedTask('TaskNoPlatformAerodynamicTurbulenceW6','aerodynamicturbulencemilf8785:now6','missing aerodynamic turbulence W6 parameter');

e = e & loadWorkingTaskWithObjectOff('TaskPlatformAccelerometerOff','state.platforms(1).ahars.accelerometer','Accelerometer','accelerometer off');

e = e & loadBadlySpecifiedTask('TaskNoPlatformAccelerometer','ahahrspelican:noaccelerometer','missing accelerometer');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAccelerometerType','ahahrspelican:noaccelerometertype','missing accelerometer type');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAccelerometerSigma','accelerometerg:sigma','missing accelerometer sigma');

e = e & loadWorkingTaskWithObjectOff('TaskPlatformGyroscopeOff','state.platforms(1).ahars.gyroscope','Gyroscope','gyroscope off');

e = e & loadBadlySpecifiedTask('TaskNoPlatformGyroscope','ahahrspelican:nogyroscope','missing gyroscope');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGyroscopeType','ahahrspelican:nogyroscopetype','missing gyroscope type');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGyroscopeSigma','gyroscopeg:nosigma','missing gyroscope sigma');

e = e & loadWorkingTaskWithObjectOff('TaskPlatformAltimeterOff','state.platforms(1).ahars.altimeter','Altimeter','altimeter off');

e = e & loadBadlySpecifiedTask('TaskNoPlatformAltimeter','ahahrspelican:noaltimeter','missing altimeter');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAltimeterType','ahahrspelican:noaltimetertype','missing altimeter type');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAltimeterTau','altimetergm:notau','missing altimeter tau');
e = e & loadBadlySpecifiedTask('TaskNoPlatformAltimeterSigma','altimetergm:nosigma','missing altimeter sigma');

e = e & loadWorkingTaskWithObjectOff('TaskPlatformOrientationEstimatorOff','state.platforms(1).ahars.orientationEstimator','OrientationEstimator','orientation estimator off');

e = e & loadBadlySpecifiedTask('TaskNoPlatformOrientationEstimator','ahahrspelican:noorientationestimator','missing orientation estimator');
e = e & loadBadlySpecifiedTask('TaskNoPlatformOrientationEstimatorType','ahahrspelican:noorientationestimatortype','missing orientation estimator type');
e = e & loadBadlySpecifiedTask('TaskNoPlatformOrientationEstimatorBeta','orientationestimatorgm:nobeta','missing orientation estimator beta');
e = e & loadBadlySpecifiedTask('TaskNoPlatformOrientationEstimatorSigma','orientationestimatorgm:nosigma','missing orientation estimator sigma');

e = e & loadBadlySpecifiedTask('TaskNoPlatformGraphicsType','pelican:nographicstype','missing graphics type');
e = e & loadBadlySpecifiedTask('TaskNoPlatformGraphicsParams','pelicangraphics:nopar','missing graphics parameter');

rmpath('assert');

end


function e = loadWorkingTaskWith3DDisplayOff(task,msg)

global state; %#ok<NUSED>

qrsim = QRSim();
e = 0;

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

try
    qrsim.init(task);
    
    e = e || (state.environment.area.params.graphics.on ~= 0);
    e = e || (~ischar('state.environment.area.graphics'));
    e = e || (strcmp(class(state.platforms(1).graphics),'QuadrotorGraphics')~=1);

    % do a few steps to make sure things actually work
    for i=1:50
        qrsim.step(U);
    end
catch exception
     e = 1;  
     fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

clear('global state');
clear('qrsim');
close('all');

end


function e = loadWorkingTaskWithObjectOff(task,obj,shouldBeClass,msg)

global state; %#ok<NUSED>

qrsim = QRSim();
e = 0;

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

try
    qrsim.init(task);
    
    if(~isa(eval(obj),shouldBeClass))
        e = 1;
        fprintf('\nUNEXPECTED TYPE:%s instead of %s\n',class(obj),shouldBeClass);
    end
    
    % do a few steps to make sure things actually work
    for i=1:50
        qrsim.step(U);
    end
catch exception
    e = 1;  
    fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

clear('global state');
clear('qrsim');
close('all');

end

function e = loadBadlySpecifiedTask(task,id,msg)

global state; %#ok<NUSED>

qrsim = QRSim();
e = 0;

try
    qrsim.init(task);
    e = 1;
catch exception
    if(~strcmp(exception.identifier,id))
        e = 1;
        fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
    end
end
clear('global state');
clear('qrsim');
close('all');

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end

