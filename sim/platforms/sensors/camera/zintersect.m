function pt = inv_cam_prj(tp,Rp,uv)

% bring the chosen point to world coords
ss = Rp'*R'*s;
ss = ss+repmat(t,1,4);

% compute intersection point of the camera field
% of view with z=0
gp1 = zintersect(ss(:,1),t);
gp2 = zintersect(ss(:,2),t);
gp3 = zintersect(ss(:,3),t);
gp4 = zintersect(ss(:,4),t);

z=0;
x=(p(1)-t(1))*((z-t(3))/(p(3)-t(3)))+t(1);
y=(p(2)-t(2))*((z-t(3))/(p(3)-t(3)))+t(2);


pp=[x;y;z];