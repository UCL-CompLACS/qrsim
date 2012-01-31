function [ e ] = testAssertions()
%TESTASSERTIONS test assertion for missing initialization parameters
% returns 0 if all tests passed

addpath('assert');

e = 0;

e = e & loadTask('TaskNoDT','qrsim:nodt','missing DT task parameter');

e = e & loadTask('TaskNoSeed','qrsim:noseed','missing seed task parameter');

e = e & loadTask('TaskNoDisplay3D','qrsim:nodisplay3d','missing display3d task parameter');

e = e & loadTask('TaskNoDisplay3DHeight','qrsim:nodisplay3dwidthorheight','missing display3d.height task parameter');

e = e & loadTask('TaskNoDisplay3DWidth','qrsim:nodisplay3dwidthorheight','missing display3d.width task parameter');

%test TaskDisplay3DOff making sure that all loads fine withdisplay3d.on=0

e = e & loadTask('TaskNoAreaType','qrsim:noareatype','missing area.type task parameter');

e = e & loadTask('TaskNoAreaLimits','boxarea:nolimits','missing area.limits task parameter');

e = e & loadTask('TaskNoAreaOriginUTMCoords','boxarea:nooriginutmcoords','missing area.originutmcoords task parameter');

e = e & loadTask('TaskNoAreaGraphics','boxarea:nographics','missing area.graphics.on task parameter');

e = e & loadTask('TaskNoAreaGraphicsType','boxarea:nographicstype','missing area.graphics.type task parameter');

% test TaskGPSSPaceSegmentOff making sure that a GPSSpaceSegment is loaded

e = e & loadTask('TaskNoGPSSpaceSegmentType','qrsim:nogpsspacesegmenttype','missing gpsspacesegment.type task parameter');

e = e & loadTask('TaskNoGPSSpaceSegmentDt','steppable:nodt','missing gpsspacesegment.dt task parameter');

e = e & loadTask('TaskNoGPSSpacesegmentOrbitFileA','gpsspacesegmentgm2:noorbitfile','missing gpsspacesegment.orbitfile task parameter');
 
e = e & loadTask('TaskNoGPSSpacesegmentOrbitFileB','gpsspacesegmentgm:noorbitfile','missing gpsspacesegment.orbitfile task parameter');

e = e & loadTask('TaskNoGPSSpacesegmenttStartA','gpsspacesegmentgm2:notstart','missing gpsspacesegment.tStart task parameter');

e = e & loadTask('TaskNoGPSSpacesegmenttStartB','gpsspacesegmentgm:notstart','missing gpsspacesegment.tStart task parameter'); 

e = e & loadTask('TaskNoGPSSpacesegmenttSVSA','gpsspacesegmentgm2:nosvs','missing gpsspacesegment.svs task parameter');

e = e & loadTask('TaskNoGPSSpacesegmenttSVSB','gpsspacesegmentgm:nosvs','missing gpsspacesegment.svs task parameter');

e = e & loadTask('TaskNoGPSSpaceSegmentBeta2','gpsspacesegmentgm2:nobeta2','missing gpsspacesegment.PR_BETA2 task parameter');

e = e & loadTask('TaskNoGPSSpaceSegmentBeta1','gpsspacesegmentgm2:nobeta1','missing gpsspacesegment.PR_BETA1 task parameter');

e = e & loadTask('TaskNoGPSSpaceSegmentBeta','gpsspacesegmentgm:nobeta','missing gpsspacesegment.PR_BETA task parameter');

e = e & loadTask('TaskNoGPSSpaceSegmentSigmaA','gpsspacesegmentgm2:nosigma','missing gpsspacesegment.PR_SIGMA task parameter');

e = e & loadTask('TaskNoGPSSpaceSegmentSigmaB','gpsspacesegmentgm:nosigma','missing gpsspacesegment.PR_SIGMA task parameter');
 
e = e & loadTask('TaskNoWind','qrsim:nowind','missing wind.on task parameter');

% % test TaskWindOff making sure that a Wind is loaded
 
e = e & loadTask('TaskNoWindType','qrsim:nowindtype','missing wind.type task parameter');

e = e & loadTask('TaskNoWindDirection','windconstmean:direction','missing wind.direction task parameter');
 
e = e & loadTask('TaskNowindW6','windconstmean:w6','missing wind.W6 task parameter');
 
e = e & loadTask('TaskNoPlatformsConfigFile','qrsim:noplatforms','missing platforms task parameter');
 
e = e & loadTask('TaskNoPlatformsX','qrsim:noplatformsx','missing platforms initial state task parameter');

rmpath('assert');

end


function e = loadTask(task,id,msg)

global state; %#ok<NUSED>

qrsim = QRSim();
e = 0;

try
    qrsim.init(task);
    e = 1;
catch exception
    if(~strcmp(exception.identifier,id))
        e = 1;  
        fprintf('(Got exception %s with message %s)',exception.identifier,exception.message);
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

