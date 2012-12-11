function pt = inv_cam_prjZ0(tp,Rp,uv,principal_point,focal_length, R)
% INV_CAM_PRJ_Z0 inverse camera projection bring the chosen point uv to world coords

p = Rp'*R'*[((uv-principal_point)./focal_length);1] + tp;

% compute intersection of ray t-p and
% the ground plane z=0
z=0;
x=(p(1)-tp(1))*((z-tp(3))/(p(3)-tp(3)))+tp(1);
y=(p(2)-tp(2))*((z-tp(3))/(p(3)-tp(3)))+tp(2);

pt=[x;y;z];

end