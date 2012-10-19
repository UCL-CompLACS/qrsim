function uv = cam_prj(R, t ,xyz, focal_length,principal_point)
   
% world frame to camera frame
p3 = R*(xyz - t);
   
% return an empty point if the 
% camera does not point to the 3D point
if(p3(3)<0)
    uv=[];
    return;
end

% pinhole projection
p2 = p3(1:2)./p3(3);

% intrinsic
uv = p2.*focal_length + principal_point;

% return an empty point if the 
% camera reproxected point is 
% outside the sensor area
% for simplicity we assume the principal point
% to be at the center of the sensor, i.e. a valid
% pixel point p has coordinates  0<uv_p<2*principal_point 

if( uv(1)<0 || uv(1)> 2*principal_point(1) || uv(2)<0 || uv(2)> 2*principal_point(2) )
    uv=[];
    return;
end
        