function pt = inv_cam_prjZ0(tp,Rp,uv,focal_length,principal_point, R)

% bring the chosen point uv to world coords
p = Rp'*R'*((uv-principal_point)./focal_length) + tp;

% compute intersection of ray t-p and
% the ground plane z=0
z=0;
x=(p(1)-tp(1))*((z-tp(3))/(p(3)-tp(3)))+t(1);
y=(p(2)-tp(2))*((z-tp(3))/(p(3)-tp(3)))+t(2);

pt=[x;y;z];