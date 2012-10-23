function uv = cam_prj(tp, Rp ,point, c , f, R)
% project points from world coordinate to the camera frame.

% tp and Rp are generally the translation vector and rotation
% matrix of the platform

% world frame to camera frame
p3 = R*Rp*(point - tp);

% return an empty point if the
% camera does not point to the 3D point
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
end