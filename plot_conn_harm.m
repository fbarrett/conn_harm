% load, plot sparsely saved Laplacian matrices (connectome harmonics)
% 
% fbarret2@jhmi.edu 2018.02.20

nvertex = 20484;
num_eig = 200;

if ~exist('make_surface_figure','file')
  path(path,genpath('/Users/fbarrett/git/CanlabCore/CanlabCore'));
end % ~exist('make_surface_figure

%% get G (symmetric graph Laplacian)
rootpath = '/Volumes/OrangeDisk/1305/conn_harm_mtcs';
rootpath = '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/Amtc_test';
giipath = '/Volumes/OrangeDisk/for_Welsh/fsaverage5/surf';
giipath = '/Users/fbarrett/Documents/_data/1305/fmri/conn_harm/fs-subjects/gii';

% epath = fullfile(aroot,sprintf('%s-%s.%deig.mat',subids{s},sess{ss},nvertex));
epath = fullfile(rootpath,'TSM712-ses-Baseline.20484eig.mat');
if ~exist(epath,'file')
  % eigenvectors haven't been calculated - calculate them!
%   continue % not this time
  fprintf(1,'calculating V');% for %s, %s\n',subids{s},sess{ss});

  % get adjacency matrix
%   apath = fullfile(aroot,sprintf('%s-%s.seedwhite.endptwhite.A.txt',...
%       subids{s},sess{ss}));
  apath = fullfile(rootpath,'TSM712-ses-Baseline.seedwhite.endptwhite.A.txt');
%   if ~exist(apath,'file'), continue, end
  Asparse = load(apath);
  A = zeros(nvertex);
  for k=1:size(Asparse,1)
    A(Asparse(k,1),Asparse(k,2)) = Asparse(k,3);
    A(Asparse(k,2),Asparse(k,1)) = Asparse(k,3);
  end % for k=1:size(Asparse,1
  A(find(eye(size(A,1)))) = 0;

  % calculate symmetric graph Laplacian
  try
    D = diag(sum(A));
    L = D - A;
    Dp = mpower(D,-0.5);
    G = Dp*L*Dp;
    [V,E] = eig(G);
    V = V(:,1:num_eig);
    save(epath,'V');
  catch
%     warning('error for %s/%s, SKIPPING\n',subids{s},sess{ss});
    warning('error, SKIPPING\n');
%     continue
  end
else
  % load eigenvectors
  V = load(epath);
  V = V.V;
  V = V(:,1:num_eig);
end % if ~exist(epath,'file

%% plot!
lhemi = fullfile(giipath,'lh.white.TSM712-ses-Baseline.gii');
rhemi = fullfile(giipath,'rh.white.TSM712-ses-Baseline.gii');

figoutroot = '/Users/fbarrett/Google Drive/collabs/pekar/harmonics/20200222/';

for k=1:20 % first 20 eigenvectors
  h = make_surface_figure('surfacefiles',{lhemi,rhemi});
  plot_surface_map({V(1:nvertex/2,k),V(nvertex/2+1:nvertex,k)},...
      'colmap','jet','figure',h,'title',sprintf('Connectome Harmonic %d',k));
  print(fullfile(figoutroot,sprintf('TSM712-ses-Baseline-harmonic_%03d.png',k)),'-dpng','-r300'); %
end % for k=1:10

