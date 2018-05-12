function bold_harmonics = conn_harm_bold_decomp(bold_path,adj_path)

% decompose BOLD data in terms of connectome harmonics
% 
%   bold_harmonics = conn_harm_bold_decomp(bold_path,adj_path)
% 
% INPUT
%   bold_path - paths to 4D NIfTI bold scan
%   adj_path  - path to adjacency matrix to calcualte sym.graph Laplacian
% 
% fbarrett@jhmi.edu - 2018.05.11

bbregcmd = 'bbregister --s %s --mov %s --reg %s --bold';
v2scmd = ['mri_vol2surf --src %s --out %s --srcreg %s --hemi %sh ' ...
    '--trgsubject fsaverage5 --interp nearest'];
h = {'l','r'};
nvertex = 20484;

if ~exist(bold_path,'file') || ~exist(adj_path,'file')
  error('%s or %s not found\n',bold_path,adj_path);
end % if ~exist...

% get subid
[~,an] = fileparts(adj_path);
subid = regexp(an,'(\w{3}\d{3}\-ses\-\w*)\.seed.*','tokens');
subid = subid{1};

% register bold data with the volunteer's fs template
[bp,bn] = fileparts(bold_path);
regpath = fullfile(bp,sprintf('%s_register.dat',bn));
if ~exist(regpath,'file')
  bbregstr = sprintf(bbregcmd,subid{1},bold_path,regpath);
  [status,result] = unix(bbregstr);
  if status
    bold_harmonics = result;
    return
  end % if status
end % if ~exist(regpath,'file

% calculate connectome harmonics
Asparse = load(adj_path);  % load sparse adjacency matrix
A = zeros(nvertex);
for k=1:size(Asparse,1) % populate a full matrix
  A(Asparse(k,1),Asparse(k,2)) = Asparse(k,3);
  A(Asparse(k,2),Asparse(k,1)) = Asparse(k,3);
end % for k=1:size(Asparse,1
A(find(eye(size(A,1)))) = 0; % remove the diagonal
clear Asparse;

% calculate symmetric graph Laplacian
D = diag(sum(A));
L = D - A;
clear A;
Dp = mpower(D,-0.5);
clear D;
G = Dp*L*Dp;
clear L Dp;
[V,~] = eig(G);
clear G;

% Y = Xb+e, b = inv(X*X') * X'Y
R = inv(V*V')*V';
clear V;

% project bold data onto fsaverage5 vertex space
B = []; % bold data, time X vertex
for hh=h
  mghpath = fullfile(bp,sprintf('%s.%sh.mgh',bn,hh{1}));
  if ~exist(mghpath,'file')
    v2sstr = sprintf(v2scmd,bold_path,mghpath,regpath,hh{1});
    [status,result] = unix(v2sstr);
    if status
      bold_harmonics = result;
      return
    end % if status
  end % if ~exist(mghpath,'file
  mghdata = MRIread(mghpath);
  B = [B squeeze(mghdata.vol)'];
end % for hh

% decompose B given R
for k=1:size(B,1)
  bold_harmonics(k,:) = R*B(k,:);
end % for k=1:size(B

% bold_harmonics = B*V; % time X harmonic
