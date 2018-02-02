% dtiFiberTrack applied to conn_harm development data
% 
% fbarrett@jhmi.edu 2018.02.02

%% set paths
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

seeds = [];
for h = {'l','r'};
  spath = fullfile(fsroot,fstrg,'surf',...
      sprintf('%sh.white.%s.asc',h{1},subs{1}));
  tmp = loadtxt(spath,'skipline',2);
  seeds = [seeds; [[tmp{:,1}]' [tmp{:,2}]' [tmp{:,3}]']];
end % for h={'l

[fg,opts] = dtiFiberTrack(dt6data,seeds',[2 2 2],xform.acpcXform,fgName,opts);
