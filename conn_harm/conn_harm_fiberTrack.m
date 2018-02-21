% dtiFiberTrack applied to conn_harm development data
% 
%   SO FAR ALL OF THIS IS BEING DONE WITH BINARY, UNDIRECTED GRAPHS
%   NEXT STEP IS TO TRY IT WITH WEIGHTED GRAPHS
% 
% fbarrett@jhmi.edu 2018.02.02

%% set paths, input variables
tic
chroot = '/Users/fbarrett/Documents/data/1305/conn_harm';
subs = {'jed716'};
sess = {'ses-Session4'};
dt6fname = fullfile(chroot,['sub-' subs{1}],sess{1},'dwi','dti32','dt6.mat');
dt6mat = load(dt6fname);
xformfname = fullfile(chroot,['sub-' subs{1}],sess{1},'dwi',...
    'wr20150317_094441WIPDTIHR22SENSEs1301a013_origin_reduced_aligned_noMEC_acpcXform.mat');
xform = load(xformfname);
dt6 = niftiRead(fullfile(chroot,['sub-' subs{1}],sess{1},'dwi',dt6mat.files.tensors));
dt6data = reshape(dt6.data,size(dt6.data,1),size(dt6.data,2),size(dt6.data,3),size(dt6.data,5));

fsroot = '/Applications/freesurfer/subjects';
fstrg = 'fsaverage5';

h = {'l','r'};
radius = 1;

%% what surface are we using for fiber-tracking seeds?
tracksurftype = 'white';

%% set options for dtiFiberTrack
% settings from Atasoy 2015 Nature Communications
% defaults from dtiFiberTracker.m when not specified in Atasoy
opts.stepSizeMm = 1; % example in dtiFiberTracker
opts.angleThresh = 30; % per Atasoy
opts.faThresh = 0.3; % per Atasoy
opts.lengthThreshMm = 20; % per Atasoy
opts.wPuncture = 0.2; % example in dtiFiberTracker.m
opts.whichAlgorithm = 1; % 1=STT RK4, "... Basser et. al., (2000)" (per Atasoy)
opts.whichInterp = 1; % trilinear
opts.seedVoxelOffsets = [0.25 0.75]; % places 8 seeds in each voxel? per Atasoy, dtiFiberTrack.m
opts.offsetJitter = 0; % no jitter in seedVoxelOffsets

fgName = 'connHarmFG';

%% get seeds
trackseeds = [];
for hh = h
  spath = fullfile(fsroot,fstrg,'surf',...
      sprintf('%sh.%s.%s.asc',hh{1},tracksurftype,subs{1}));
  nlines = loadtxt(spath,'skipline',1,'nlines',1); % second line, first entry indicates # of vertices
  tmp = loadtxt(spath,'skipline',2,'nlines',nlines{1}); % lines 3:nlines+2 are coordinates in different systems
  trackseeds = [trackseeds; [[tmp{1:nlines{1},1}]' [tmp{1:nlines{1},2}]' [tmp{1:nlines{1},3}]']];
end % for h={'l

%% calcualte fiber tracks
toc
[fg,opts] = dtiFiberTrack(dt6data,trackseeds',[2 2 2],xform.acpcXform,fgName,opts);
toc

%% generate connectivity matrix
% what surface are we using for connectivity end-points?
endsurftype = 'pial';

% get seeds for pial surface -- ATASOY 
endseeds = [];
for hh = h
  spath = fullfile(fsroot,fstrg,'surf',...
      sprintf('%sh.%s.%s.asc',hh{1},endsurftype,subs{1}));
  nlines = loadtxt(spath,'skipline',1,'nlines',1); % second line, first entry indicates # of vertices
  tmp = loadtxt(spath,'skipline',2,'nlines',nlines{1}); % lines 3:nlines+2 are coordinates in different systems
  endseeds = [endseeds; [[tmp{1:nlines{1},1}]' [tmp{1:nlines{1},2}]' [tmp{1:nlines{1},3}]']];
end % for h={'l

% get cortico-cortico and thalamo-cortico connectivity matrix
fiber_cmat = conn_mat_from_fibers(fg.fibers,endseeds);

% get connectivity matrix generated from local neighborhood
% this has been calculated elsewhere (conn_mat_from_fibers.m)
A = fiber_cmat;
for hh=1:length(h)
  local_file = sprintf('%sh.%s.r%d.cmat.mat',h{hh},surftype,radius);
  local_cmat = load(fullfile(fsroot,fstrg,'surf',local_file));
  local_cmat = local_cmat.cmat;
  lidxs = (1:size(A,1)/2);
  hidxs = lidxs+(size(A,1)/2*(hh-1));
  A(hidxs,hidxs) = A(hidxs,hidxs)+local_cmat(lidxs,lidxs);
end % for hh=h

%% generate graphs
% calculate Laplacian
D = diag(sum(A)); % degree matrix
L = D - A;
Dp = D^(-0.5);
tic
G = Dp*L*Dp; % symmetric graph laplacian
toc

tic
[V,E] = eig(G);   % get eigenmodes (V) and eigenvalues (E) of G
[Es,j] = sort(diag(E));  % sort E, get sorting vector j
Vj = V(:,j);
toc

% save adjacency and graph laplacian matrices to file (sparsely)
[row col v] = find(A);
dlmwrite(fullfile(fsroot,fstrg,'surf',...
      sprintf('%s.%s.adj.txt',subs{1},surftype)),...
      [row col v], 'delimiter', '\t')
[row col v] = find(G);
dlmwrite(fullfile(fsroot,fstrg,'surf',...
      sprintf('%s.%s.L.txt',subs{1},surftype)),...
      [row col v], 'delimiter', '\t')
[row col v] = find(V);
dlmwrite(fullfile(fsroot,fstrg,'surf',...
    sprintf('%s.%s.V.txt',subs{1},surftype)),...
    [row col v], 'delimiter', '\t');
[row col v] = find(E);
dlmwrite(fullfile(fsroot,fstrg,'surf',...
    sprintf('%s.%s.E.txt',subs{1},surftype)),...
    [row col v], 'delimiter', '\t');
