% dtiFiberTrack applied to conn_harm development data
% 
%   SO FAR ALL OF THIS IS BEING DONE WITH BINARY, UNDIRECTED GRAPHS
%   NEXT STEP IS TO TRY IT WITH WEIGHTED GRAPHS
% 
% fbarrett@jhmi.edu 2018.02.02

%% set paths, input variables
tic
chroot = '/Users/fbarrett/Documents/data/1305/conn_harm';
chroot = '/g4/rgriffi6/1305_working';

% subs = {'AGG751'};
% subs = {'AMM755','CAH753','CEC761'}; % these subjects will be processed
% subs = {'CFL767','DCE745','DJH730','EWM768','GJM708','JAT763','JLD740',...
%     'JRD722','MEG743','MP733','RDW746','RJL752','RZ_758','SEW732',...
%     'SHH709'};%,'TPM710'};
% subids = {'DCE745','EWM768','JAT763','JLD740','JRD722','MEG743',...
%     'MP733','RDW746','RJL752','RZ_758','SHH709'};

subs = dir(chroot);
subs(1:2) = [];
subs = subs([subs.isdir]);
subs(strcmp('ignore',{subs.name})) = [];
subs = {subs.name};

sess = {'ses-Baseline','ses-Session1'};

fsroot = '/g5/fbarret2/fs-subjects';
fstrg = 'fsaverage5';
fstrg = {'fsaverage4','fsaverage3'};
fstrg = {'fsaverage5','fsaverage4','fsaverage3'};

h = {'l','r'};
radius = 1;

%% what surface are we using for fiber-tracking seeds?
tracksurftype = 'white';

%% set options for dtiFiberTrack
% settings from Atasoy 2015 Nature Communications
% defaults from dtiFiberTracker.m when not specified in Atasoy
dopts.stepSizeMm = 1; % example in dtiFiberTracker
dopts.angleThresh = 30; % per Atasoy
dopts.faThresh = 0.3; % per Atasoy
dopts.lengthThreshMm = 20; % per Atasoy
dopts.wPuncture = 0.2; % example in dtiFiberTracker.m
dopts.whichAlgorithm = 1; % 1=STT RK4, "... Basser et. al., (2000)" (per Atasoy)
dopts.whichInterp = 1; % trilinear
dopts.seedVoxelOffsets = [0.25 0.75]; % places 8 seeds in each voxel? per Atasoy, dtiFiberTrack.m
dopts.offsetJitter = 0; % no jitter in seedVoxelOffsets

fgName = 'connHarmFG';

% what surface are we using for connectivity end-points?
endsurftype = 'white';

%% iterate over subjects
% parfor k=1:length(subs)
for tt=1:length(fstrg)
  for k=1:length(subs)
    for s=1:length(sess)
      fssub = [regexprep(subs{k},'sub-','') '-' sess{s}];
      adjmtxpath = fullfile(fsroot,fstrg{tt},'surf',...
          sprintf('%s.seed%s.endpt%s.A.txt',fssub,tracksurftype,endsurftype));
      if exist(adjmtxpath,'file')
        fprintf(1,'adjacency matrix %s exists, moving on\n',adjmtxpath)
        continue
      end % if exist(adjmtxpath,'file
      fprintf(1,'generating adjacency matrix for %s %s\n',subs{k},sess{s});

      fprintf(1,'getting fibers, calculating matrices for %s\n',subs{k});
      dwiroot = fullfile(chroot,[subs{k}],sess{s},'dwi');
      if ~exist(dwiroot,'dir'), fprintf(1,'%s not found, SKIPPING\n',dwiroot), continue, end
      dt6fname = fullfile(dwiroot,'dti32','dt6.mat');
      if ~exist(dt6fname,'file'), fprintf(1,'%s not found, SKIPPING\n',dt6fname), continue, end
      dt6mat = load(dt6fname);
      xformdir = dir(fullfile(dwiroot,'*acpcXform.mat'));
      if isempty(xformdir), fprintf(1,'no acpcXform.mat %s %s, SKIPPING\n',subs{k},sess{s}), continue, end
      xform = load(fullfile(dwiroot,xformdir(end).name));
      dt6 = niftiRead(fullfile(dwiroot,dt6mat.files.tensors));
      dt6data = reshape(dt6.data,size(dt6.data,1),size(dt6.data,2),size(dt6.data,3),size(dt6.data,5));

      %% get seeds
      trackseeds = [];
      for hh = h
        spath = fullfile(fsroot,fstrg{tt},'surf',...
            sprintf('%sh.%s.%s.asc',hh{1},tracksurftype,fssub));
        if ~exist(spath,'file'), fprintf(1,'%s not found, SKIPPING\n',spath), continue, end
        nlines = loadtxt(spath,'skipline',1,'nlines',1); % second line, first entry indicates # of vertices
        tmp = loadtxt(spath,'skipline',2,'nlines',nlines{1}); % lines 3:nlines+2 are coordinates in different systems
        trackseeds = [trackseeds; [[tmp{1:nlines{1},1}]' [tmp{1:nlines{1},2}]' [tmp{1:nlines{1},3}]']];
        clear tmp
      end % for h={'l

      %% calcualte fiber tracks
      try
        tic
        [fg,opts] = dtiFiberTrack(dt6data,trackseeds',[2 2 2],xform.acpcXform,fgName,dopts);
        fibers = fg.fibers;
        clear fg;
        toc
      catch
        fprintf(1,'dtiFiberTrack error for %s %s, SKIPPINGn',subs{k},sess{s})
        continue
      end

%     save(fullfile(dwiroot,'fibergroup.mat'),'fg','opts','dt6data');

      %% generate connectivity matrix

      % get seeds for pial surface -- ATASOY 
      endseeds = [];
      for hh = h
        spath = fullfile(fsroot,fstrg{tt},'surf',...
            sprintf('%sh.%s.%s.asc',hh{1},endsurftype,fssub));
        if ~exist(spath,'file'), fprintf(1,'%s not found, SKIPPING\n',spath), continue, end
        nlines = loadtxt(spath,'skipline',1,'nlines',1); % second line, first entry indicates # of vertices
        tmp = loadtxt(spath,'skipline',2,'nlines',nlines{1}); % lines 3:nlines+2 are coordinates in different systems
        endseeds = [endseeds; [[tmp{1:nlines{1},1}]' [tmp{1:nlines{1},2}]' [tmp{1:nlines{1},3}]']];
        clear tmp
      end % for h={'l

      % get cortico-cortico and thalamo-cortico connectivity matrix
      clear A
      A = conn_mat_from_fibers(fibers,endseeds);
      clear fibers;

      % get connectivity matrix generated from local neighborhood
      % this has been calculated elsewheref0
      for hh=1:length(h)
        local_file = sprintf('%sh.%s.r%d.cmat.mat',h{hh},endsurftype,radius);
        local_cmat = load(fullfile(fsroot,fstrg{tt},'surf',local_file));
        local_cmat = local_cmat.cmat;
        lidxs = (1:size(A,1)/2);
        hidxs = lidxs+(size(A,1)/2*(hh-1));
        A(hidxs,hidxs) = A(hidxs,hidxs)+local_cmat(lidxs,lidxs);
      end % for hh=h
      clear local_cmat

      fprintf(1,'saving (sparse) adjacency matrix\n');
      [row,col,v] = find(A);
      dlmwrite(adjmtxpath,[row col v], 'delimiter', '\t')

      continue
    
%     %% generate graphs
%     % calculate Laplacian
%     fprintf(1,'calculating Laplacian\n');
%     D = diag(sum(A)); % degree matrix
%     L = D - A;
%     Dp = D^(-0.5);
%     tic
%     G = Dp*L*Dp; % symmetric graph laplacian
%     toc
% 
%     tic
%     [V,E] = eig(G);   % get eigenvalues (V) and eigenvalues (E) of G
%     [Es,j] = sort(diag(E));  % sort E, get sorting vector j
%     Vj = V(:,flipud(j));
%     toc
% 
%     % save adjacency and graph laplacian matrices to file (sparsely)
%     fprintf(1,'saving (sparse) symmetric graph Laplacian matrix\n');
%     [row col v] = find(G);
%     dlmwrite(fullfile(fsroot,fstrg,'surf',...
%           sprintf('%s.seed%s.endpt%s.L.txt',fssub,tracksurftype,endsurftype)),...
%           [row col v], 'delimiter', '\t')
%     fprintf(1,'saving (sparse) eigenvectors matrix\n');
%     [row col v] = find(V);
%     dlmwrite(fullfile(fsroot,fstrg,'surf',...
%         sprintf('%s.seed%s.endpt%s.V.txt',fssub,tracksurftype,endsurftype)),...
%         [row col v], 'delimiter', '\t');
%     fprintf(1,'saving (sparse) eigenvalues matrix\n');
%     dlmwrite(fullfile(fsroot,fstrg,'surf',...
%         sprintf('%s.seed%s.endpt%s.Es.txt',fssub,tracksurftype,endsurftype)),...
%         [Es]);
    end % for s=1:length(Sess
  end % parfor k=1:length(subs
end % for tt=1:length(Fstrg

fprintf(1,'DONE\n');

