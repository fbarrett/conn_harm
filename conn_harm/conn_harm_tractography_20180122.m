% perform tractography on DTI using seeds from surface
% 
% fbarrett@jhmi.edu 2018.01.22

dwiroot = '/Users/fbarrett/Documents/data/1305/dti/';
fsroot = '/Applications/freesurfer/subjects';

opts.stepSizeMm = 1;
opts.angleThresh = 30;
opts.faThresh = 0.3;
opts.lengthThreshMm = 20;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1; % from dtiFiberTracker.m, 1 resembles Basser 2000
opts.whichInterp = 1; %% 0 = NN, 1 = linear, which to use????
opts.seedVoxelOffsets = [0.25 0.75]; % 8 equi-spaced seeds, somehow
opts.offsetJitter = 0; % no jitter in seed placement
mmPerVox = [2 2 2]; % voxel size

for s=subids
  % get images for this participant
  dt6 = load(fullfile(dwiroot,s{1},'dt6.mat'));
  [fp,fn] = fileparts(dt6.files.alignedDwRaw);
  xform = load(fullfle(fp,[fn '_acpcXform.mat']));
  xform = xform.acpcXform;
  
  fgName = sprintf('connHarm_%s',s{1});

  % get coordinates for each vertex in native space for subject 's'
  seeds = fullfile(fsroot,s{1},'surf','s.fs5.coords');
  
  % tractography!
  fg = dtiFiberTrack(dt6,seeds,mmPerVox,xform,fgName,opts);
end % for s=subs
