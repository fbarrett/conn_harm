% decompose BOLD data using connectome harmonics
% 
% fbarrett@jhmi.edu 2018.05.17

if ~exist('MRIread','file')
  addpath('/Users/fbarrett/git/vistalab/external/freesurfer');
end % if ~exist('MRIread','file

dataroot = '/g4/rgriffi6/1305_working/';
dataroot = '/Volumes/OrangeDisk/1305/resting_preproc/';
dataroot = '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/rest';
fsroot = '/g5/fbarret2/fs-subjects/fsaverage5/surf';
fsroot = '/Volumes/OrangeDisk/1305/conn_harm_mtcs';
fsroot = '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/fs-subjects/Amtcs';

setenv('SUBJECTS_DIR','/Volumes/OrangeDisk/fs-subjects');
setenv('SUBJECTS_DIR',...
    '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/fs-subjects');

neig = 20484;
teig = 200;

% get subject folderst
% subids = dir(dataroot);
% subids(1:2) = [];
% subids = subids([subids.isdir]);
% subids(strcmp('ignore',{subids.name})) = [];
% subids = {subids.name};
subids = {'agg751','amm755','cec761','cfl767','css727',...
    'cwr765','dce745','dhw772','djh730','do769','ewm768','faj770',...
    'gap742','gjm708','jat763','jed716','jfg764','jld740','jnp739',...
    'jrd722','kdb754','ld738','ldc713','meg743','mgm762','mmm744',...
    'mp733','rdw746','rjl752','rz_758','sew732','shh709','sm735',...
    'smp771','tpm710','tsm712','vjd775'}; % 'cah753',

sess = dir(fullfile(dataroot,'ses-*'));
sess = {sess.name};

bold_harmonics = cell(length(subids),length(sess));
bold_error = bold_harmonics;
eigenvalues = bold_harmonics;

% parfor s=1:length(subids)
for s=1:length(subids)
  for ss=1:length(sess)
    fprintf(1,'%s, %s\n',subids{s},sess{ss});
    
    % get bold decomposition
    bdir = dir(fullfile(dataroot,sess{ss},sprintf('*%s*nii',subids{s})));
    if isempty(bdir), continue, end
    bold_path = fullfile(bdir(1).folder,bdir(1).name);

    adj_path = fullfile(fsroot,...
        sprintf('%s-%s.seedwhite.endptwhite.A.txt',upper(subids{s}),sess{ss}));
    if ~exist(adj_path,'file'), continue, end

    try
      fpath = fullfile(fsroot,...
          sprintf('%s-%s.bold_harmonics.mat',upper(subids{s}),sess{ss}));
      if exist(fpath,'file')
        fprintf(1,'loading %s\n',fpath);
        bold_harm = load(fpath);
        bold_harmonics(s,ss) = bold_harm.bold_harm;
      else
        fprintf(1,'decomping\n');
        bold_harmonics(s,ss) = {conn_harm_bold_decomp(bold_path,adj_path)};
      
        bold_harm = bold_harmonics(s,ss);
        save(fpath,'bold_harm');
      end % if exist(fpath
    catch
      bold_error(s,ss) = {lasterror};
    end
    
    % get eigenvalues for connectome harmonics
    epath = fullfile(fsroot,...
        sprintf('%s-%s.%deig.E.mat',upper(subids{s}),sess{ss},neig));
    if exist(epath,'file')
        fprintf(1,'loading eigenvalues (%s)\n',epath);
        E = load(epath);
        E = E.E;
    else
        fprintf(1,'generating eigenvalues\n');
        Asparse = load(adj_path);  % load sparse adjacency matrix
        A = zeros(neig);
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
        E = eig(G);
        clear G;
        
        fprintf(1,'saving eigenvalues to %s\n',epath);
        save(epath,'E');
    end % if isempty(edir
    eigenvalues{s,ss} = E;
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

%% compare cross-frequency correlations
xfr_pcbo = [];
xfr_pslo = [];

% baseline to placebo (reliability)
for k=pcbo_group'
  blr = xfr{k,1};
  pcbo_r = xfr{k,2};
  pslo_r = xfr{k,3};
  
  % remove diagonals
  blr(find(eye(200))) = 0;
  pcbo_r(find(eye(200))) = 0;
  pslo_r(find(eye(200))) = 0;
  
  xfr_pcbo(end+1) = corr(atanh(blr(:)),atanh(pcbo_r(:)));
  xfr_pslo(end+1) = corr(atanh(blr(:)),atanh(pslo_r(:)));
end % for k=pcbo_group'

for k=pslo_group'
  blr = xfr{k,1};
  pslo_r = xfr{k,2};
  
  xfr_pslo(end+1) = corr(atanh(blr(:)),atanh(pslo_r(:)));
end % for k=pslo_group'


