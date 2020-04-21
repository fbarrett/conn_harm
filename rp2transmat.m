function T = rp2transmat(g,b,a,x,y,z)

% create transformation matrix for a given translation and rotation
% 
% fbarrett@jhmi.edu 2019.08.28

r11 = cos(a)*cos(b);
r12 = cos(a)*sin(b)*sin(g)-sin(a)*cos(g);
r13 = cos(a)*sin(b)*cos(g)+sin(a)*sin(g);
r21 = sin(a)*cos(b);
r22 = sin(a)*sin(b)*sin(g)+cos(a)*cos(g);
r23 = sin(a)*sin(b)*cos(g)-cos(a)*sin(g);
r31 = -sin(b);
r32 = cos(b)*sin(g);
r33 = cos(b)*cos(g);

T = [r11 r12 r13 x; r21 r22 r23 y; r31 r32 r33 z; 0 0 0 1];
