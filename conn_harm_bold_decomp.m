function bold_harmonics = conn_harm_bold_decomp(bold_path,adj_path)

% decompose BOLD data in terms of connectome harmonics
% 
%   bold_harmonics = conn_harm_bold_decomp(bold_path,adj_path)
% 
% INPUT
%   bold_path - paths to 4D NIfTI bold scan
%   adj_path  - path to adjacency matrix to calcualte sym.graph Laplacian
% 
% OUTPUT
%   bold_harmonics - path to time X harmonic matrix of BOLD harmonics
% 
% fbarrett@jhmi.edu - 2018.05.16

if isempty(strfind(getenv('PATH'),'freesurfer'))
  setenv('PATH',[getenv('PATH') ...
      ':/usr/local/freesurfer/bin:/usr/local/freesurfer']);
end % if isempty(getenv('PATH

if isempty(getenv('FREESURFER_HOME'))
  setenv('FREESURFER_HOME','/usr/local/freesurfer');
  unix('source $FREESURFER_HOME/SetUpFreeSurfer.sh');
end 

bold_harmonics = '';
bbregcmd = 'bbregister --s %s --mov %s --reg %s --bold';
v2scmd = ['mri_vol2surf --src %s --out %s --srcreg %s --hemi %sh ' ...
    '--trgsubject fsaverage5 --interp nearest'];
h = {'l','r'};
nvertex = 20484;

if ~exist(bold_path,'file') || ~exist(adj_path,'file')
  warning('%s or %s not found\n',bold_path,adj_path);
  return
end % if ~exist...

% get subid
[ap,an] = fileparts(adj_path);
subid = regexp(an,'(\w{6}\-ses\-\w*)','tokens');
subid = subid{1};

% register bold data with the volunteer's fs template
[bp,bn] = fileparts(bold_path);
regpath = fullfile(bp,sprintf('%s_register.dat',bn));
if ~exist(regpath,'file')
  fprintf(1,'creating %s\n',regpath);
  bbregstr = sprintf(bbregcmd,subid{1},bold_path,regpath);
  [status,result] = unix(bbregstr);
  if status
    bold_harmonics = result;
    return
  end % if status
else
  fprintf(1,'%s found\n',regpath);
end % if ~exist(regpath,'file

% calculate connectome harmonics
rpath = fullfile(ap,sprintf('%s.%deig.R.mat',subid{1},nvertex));
epath = fullfile(ap,sprintf('%s.%deig.mat',subid{1},nvertex));
if ~exist(rpath,'file')
  if ~exist(epath,'file')
    fprintf(1,'generating %s\n',epath);
    
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
    
    save(epath,'V','-v7.3');
  else
    fprintf(1,'loading %s\n',epath);
    load(epath);
  end % if ~exist(epath,'file

  % Y = Xb+e, b = inv(X*X') * X'Y
  R = inv(V*V')*V';
  clear V;
  save(rpath,'R','-v7.3');
else
  load(rpath);
end % if ~exist(rpath,'file
    
size(R)

% project bold data onto fsaverage5 vertex space
B = []; % bold data, time X vertex
for hh=h
  mghpath = fullfile(bp,sprintf('%s.%sh.mgh',bn,hh{1}));
  if ~exist(mghpath,'file')
    fprintf(1,'creating %s\n',mghpath);
    v2sstr = sprintf(v2scmd,bold_path,mghpath,regpath,hh{1});
    [status,result] = unix(v2sstr);
    if status
      bold_harmonics = result;
      return
    end % if status
  else
    fprintf(1,'loading %s\n',mghpath);
  end % if ~exist(mghpath,'file
  mghdata = MRIread(mghpath);
  B = [B squeeze(mghdata.vol)'];
end % for hh
size(B)

% decompose B given R
harmonics = [];
for k=1:size(B,1)
  harmonics(k,:) = R*B(k,:)';
end % for k=1:size(B

size(harmonics)

bold_harmonics = fullfile(bp,[bn '_harmonics.mat']);
paths = struct('bold_path',bold_path,'adj_path',adj_path,...
    'regpath',regpath,'epath',epath,'mghpath',mghpath);
save(bold_harmonics,'harmonics','paths');

% bold_harmonics = B*V; % time X harmonic
