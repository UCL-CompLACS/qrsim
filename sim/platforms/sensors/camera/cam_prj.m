function uv = cam_prj(tp, rp ,point, c , f, r)
% cam_prj projects points from world coordinate to the camera frame.

% tp and rp are generally the translation vector and rotation
% matrix of the platform

% world frame to camera frame
p3 = r*rp*(point - tp);

% return an empty point if the
% camera does not point to the 3d point
if(p3(3)<0)
    uv=[];
    return;
end

% pinhole projection
p2 = p3(1:2)./p3(3);

% intrinsic
uv = p2.*f + c;

% return an empty point if the
% camera reprojected point is
% outside the sensor area
% for simplicity we assume the principal point
% to be at the center of the sensor, i.e. a valid
% pixel point p has coordinates  0<uv_p<2*f
if( uv(1)<0 || uv(1)> 2*c(1) || uv(2)<0 || uv(2)> 2*c(2) )
    uv=[];
    return;
end
