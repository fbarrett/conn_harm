function bvecs = rotate_bvecs(bvecs,rotmat)

% rotate bvectors based on realignment matrices
% 
%   bvecs = rotate_bvecs(bvecs,rotmat)
% 
% assuming we skip the first matrix in rotmat and bvecs
% 
% fbarrett@jhmi.edu <2020.01.01>

for k=2:size(bvecs)
  bvecs(:,k) = bvecs(:,k)'*squeeze(rotmat(1:3,1:3,k));
end % for k=1:size(bvecs