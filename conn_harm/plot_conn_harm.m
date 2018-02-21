% load, plot sparsely saved Laplacian matrices (connectome harmonics)
% 
% fbarret2@jhmi.edu 2018.02.20

%% get G (symmetric graph Laplacian)
rootpath = '/Applications/freesurfer/subjects/fsaverage5/surf';
Gsparse = load(fullfile(rootpath,'jed716.white.L.txt'));
nvertex = 20484;
G = zeros(nvertex);

for k=1:size(Gsparse,1)
  G(Gsparse(k,1),Gsparse(k,2)) = Gsparse(k,3);
  G(Gsparse(k,2),Gsparse(k,1)) = Gsparse(k,3);
end % for k=1:size(Gsparse,1

%% get eigendata
tic
[V,E] = eig(G);   % get eigenmodes (V) and eigenvalues (E) of G
[Es,j] = sort(diag(E));  % sort E, get sorting vector j
Vj = V(:,j);
toc

%% plot!
lhemi = fullfile(rootpath,'lh.white.jed716.gii');
rhemi = fullfile(rootpath,'rh.white.jed716.gii');

figoutroot = '/Users/fbarrett/Google Drive/collabs/pekar/harmonics/20180220/';

for k=1:20 % first 20 eigenvectors
  h = make_surface_figure('leftsurfacefile',lhemi,'rightsurfacefile',rhemi);
  plot_surface_map({Vj(1:nvertex/2,k),Vj(nvertex/2+1:nvertex,k)},...
      'colmap','jet','figure',h,'title',sprintf('Connectome Harmonic %d',k));
  print(fullfile(figoutroot,sprintf('harmonic_%03d.png',k)),'-dpng','-r300'); %
end % for k=1:10

