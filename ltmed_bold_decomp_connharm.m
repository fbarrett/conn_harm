% decompose BOLD data using connectome harmonics
% 
% fbarrett@jhmi.edu 2018.05.17

% if ~exist('MRIread','file')
%   addpath('/Users/fbarrett/git/vistalab/external/freesurfer');
% end % if ~exist('MRIread','file

dataroot = '/Volumes/OrangeDisk/1305/resting_preproc/';
dataroot = '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/rest';
dataroot = '/g4/rgriffi6/1305_working/';
fsroot = '/Volumes/OrangeDisk/1305/conn_harm_mtcs';
fsroot = '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/fs-subjects/Amtcs';
fsroot = '/g5/fbarret2/fs-subjects/fsaverage5/surf';

% setenv('SUBJECTS_DIR','/Volumes/OrangeDisk/fs-subjects');
% setenv('SUBJECTS_DIR',...
%     '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/fs-subjects');

neig = 20484;
teig = 200;
teig = 50;

% get subject folderst
subids = dir(dataroot);
subids(1:2) = [];
subids = subids([subids.isdir]);
subids(strcmp('ignore',{subids.name})) = [];
subids = {subids.name};
% subids = {'agg751','amm755','cec761','cfl767','css727',...
%     'cwr765','dce745','dhw772','djh730','do769','ewm768','faj770',...
%     'gap742','gjm708','jat763','jed716','jfg764','jld740','jnp739',...
%     'jrd722','kdb754','ld738','ldc713','meg743','mgm762','mmm744',...
%     'mp733','rdw746','rjl752','rz_758','sew732','shh709','sm735',...
%     'smp771','tpm710','tsm712','vjd775'}; % 'cah753',

% sess = dir(fullfile(dataroot,'ses-*'));
% sess = {sess.name};

snames = {'ses-Baseline','ses-Session1','ses-Session2',...
  'ses-Session4','ses-Session5'};

bold_harmonics = cell(length(subids),length(snames));
bold_error = bold_harmonics;
eigenvalues = bold_harmonics;

for s=1:length(subids)
  sess = dir(fullfile(dataroot,subids{s},'ses-*'));
  sess = {sess.name};
  for ss=1:length(sess)
    snum = strmatch(sess{ss},snames);
    
    fprintf(1,'%s, %s\n',subids{s},sess{ss});
    
    % get bold decomposition
    bdir = dir(fullfile(dataroot,subids{s},sess{ss},'func_stc','swr*rest*nii'));
    if isempty(bdir), continue, end
    bold_path = fullfile(bdir(1).folder,bdir(1).name);

    adj_path = fullfile(fsroot,...
        sprintf('%s-%s.seedwhite.endptwhite.A.txt',subids{s}(5:end),sess{ss}));
    if ~exist(adj_path,'file'), continue, end

    try
      [fp,fn] = fileparts(bold_path);
      fpath = fullfile(fp,[fn '_harmonics.mat']);
      if ~exist(fpath,'file')
        fprintf(1,'decomping\n');
        fpath = conn_harm_bold_decomp(bold_path,adj_path);
      end % if ~exist(fpath,'file
      
      fprintf(1,'loading %s\n',fpath);
      bold_harm = load(fpath);
      bold_harmonics{s,snum} = bold_harm.harmonics;
    catch
      bold_error(s,snum) = {lasterror};
    end
    
    % get eigenvalues for connectome harmonics
    epath = fullfile(fsroot,...
        sprintf('%s-%s.%deig.E.mat',upper(subids{s}(5:end)),sess{ss},neig));
    if exist(epath,'file')
        fprintf(1,'loading eigenvalues (%s)\n',epath);
        E = load(epath);
        E = E.E;
    else
      warning('%s not found, SKIPPING\n',epath);
      continue
      
%         fprintf(1,'generating eigenvalues\n');
%         Asparse = load(adj_path);  % load sparse adjacency matrix
%         A = zeros(neig);
%         for k=1:size(Asparse,1) % populate a full matrix
%           A(Asparse(k,1),Asparse(k,2)) = Asparse(k,3);
%           A(Asparse(k,2),Asparse(k,1)) = Asparse(k,3);
%         end % for k=1:size(Asparse,1
%         A(find(eye(size(A,1)))) = 0; % remove the diagonal
%         clear Asparse;
% 
%         % calculate symmetric graph Laplacian
%         D = diag(sum(A));
%         L = D - A;
%         clear A;
%         Dp = mpower(D,-0.5);
%         clear D;
%         G = Dp*L*Dp;
%         clear L Dp;
%         E = eig(G);
%         clear G;
%         
%         fprintf(1,'saving eigenvalues to %s\n',epath);
%         save(epath,'E');
    end % if isempty(edir
    eigenvalues{s,snum} = E;
  end % for ss
end % for s

%% calculate metrics for each scan
chpower = cell(size(bold_harmonics));
xfr = cell(size(bold_harmonics));
energy = cell(size(bold_harmonics));
energy_corr = cell(size(bold_harmonics));
energy_total = cell(size(bold_harmonics));
for k=1:numel(bold_harmonics)
  if isempty(bold_harmonics{k}), continue, end
  
  % cross-frequency correlations for target eigenvectors (teig)
  xfr{k} = corr(bold_harmonics{k}(:,1:teig));
  
  % power : |a<k>(t)|
  chpower{k} = abs(bold_harmonics{k});
  
  % energy : power<k>(t)^2 * lambda<k>^2, where lambda = eigenvalue of the
  % given eigenvector "k"
  energy{k} = bold_harmonics{k}.*repmat(eigenvalues{k}',size(bold_harmonics{k},1),1);
%   energy_corr{k} = corr(energy{k}(:,1:teig));
  energy_total{k} = bold_harmonics{k}*eigenvalues{k};
end % for k=1:numel(bold_harmonics

fprintf(1,'done calculating metrics\n')

%% get map of who has what
not_empty = ~cellfun(@isempty,bold_harmonics);
pcbo_group = find(not_empty(:,1) & not_empty(:,2) & not_empty(:,3));
pslo_group = find(not_empty(:,1) & not_empty(:,2) & ~not_empty(:,3));
study2 = find(not_empty(:,4) & not_empty(:,5));

%% compare ...

% ... eigenmatrix within subjects across time
v_compare_pcbo_pcbo = struct('r',[],'mi',[],'ss',[],'dice',[]);
v_compare_pcbo_pslo = struct('r',[],'mi',[],'ss',[],'dice',[]);
v_compare_pslo = struct('r',[],'mi',[],'ss',[],'dice',[]);
v_compare_study2 = struct('r',[],'mi',[],'ss',[],'dice',[]);

% ... cross-frequency correlations
xfr_pcbo_pcbo = struct('r',[],'mi',[],'ss',[],'dice',[]);
xfr_pcbo_pslo = struct('r',[],'mi',[],'ss',[],'dice',[]);
xfr_pslo = struct('r',[],'mi',[],'ss',[],'dice',[]);
xfr_study2 = struct('r',[],'mi',[],'ss',[],'dice',[]);

% baseline to placebo (reliability)
for k=pcbo_group'
  % eigenmatrices within subjects across time
  Vbl = load(fullfile(fsroot,...
    sprintf('%s-%s.%deig.R.mat',upper(subids{k}(5:end)),sess{1},neig)));

  V = load(fulllfile(fsroot,...
    sprintf('%s-%s.%deig.R.mat',upper(subids{k}(5:end)),sess{2},neig)));
  v_compare_pcbo_pcbo.r(end+1) = corr(Vbl.R,V.R);
  v_compare_pcbo_pcbo.mi(end+1) = mi(Vbl.R,V.R);
  v_compare_pcbo_pcbo.ss(end+1) = space_sim(Vbl.R,V.R);
  v_compare_pcbo_pcbo.dice(end+1) = dice(Vbl.R,V.R);
  
  V = load(fulllfile(fsroot,...
    sprintf('%s-%s.%deig.R.mat',upper(subids{k}(5:end)),sess{3},neig)));
  v_compare_pcbo_pslo.r(end+1) = corr(Vbl.R,V.R);
  v_compare_pcbo_pslo.mi(end+1) = mi(Vbl.R,V.R);
  v_compare_pcbo_pslo.ss(end+1) = space_sim(Vbl.R,V.R);
  v_compare_pcbo_pslo.dice(end+1) = dice(Vbl.R,V.R);  
  g bvon
  % cross-frequency correlations
  blr = xfr{k,1};
  pcbo_r = xfr{k,2};
  pslo_r = xfr{k,3};
  
  % remove diagonals
  blr(find(eye(teig))) = 0;
  pcbo_r(find(eye(teig))) = 0;
  pslo_r(find(eye(teig))) = 0;
  
  xfr_pcbo_pcbo.r(end+1) = corr(atanh(blr(:)),atanh(pcbo_r(:)));
  xfr_pcbo_pslo.r(end+1) = corr(atanh(blr(:)),atanh(pslo_r(:)));
  xfr_pcbo_pcbo.mi(end+1) = mi(atanh(blr(:)),atanh(pcbo_r(:)));
  xfr_pcbo_pslo.mi(end+1) = mi(atanh(blr(:)),atanh(pslo_r(:)));
  xfr_pcbo_pcbo.ss(end+1) = space_sim(atanh(blr(:)),atanh(pcbo_r(:)));
  xfr_pcbo_pslo.ss(end+1) = space_sim(atanh(blr(:)),atanh(pslo_r(:)));
  xfr_pcbo_pcbo.dice(end+1) = dice(atanh(blr(:)),atanh(pcbo_r(:)));
  xfr_pcbo_pslo.dice(end+1) = dice(atanh(blr(:)),atanh(pslo_r(:)));
end % for k=pcbo_group'

for k=pslo_group'
  blr = xfr{k,1};
  pslo_r = xfr{k,2};
  
  % remove diagonals
  blr(find(eye(teig))) = 0;
  pslo_r(find(eye(teig))) = 0;  
  
  xfr_pslo.r(end+1) = corr(atanh(blr(:)),atanh(pslo_r(:)));
  xfr_pslo.mi(end+1) = mi(atanh(blr(:)),atanh(pslo_r(:)));
  xfr_pslo.ss(end+1) = space_sim(atanh(blr(:)),atanh(pslo_r(:)));
  xfr_pslo.dice(end+1) = dice(atanh(blr(:)),atanh(pslo_r(:)));
end % for k=pslo_group'


