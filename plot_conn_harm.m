% load, plot sparsely saved Laplacian matrices (connectome harmonics)
% 
% fbarret2@jhmi.edu 2018.02.20

nvertex = 20484;
num_eig = 200;

if ~exist('make_surface_figure','file')
  path(path,genpath('/usr/local/share/canlabcore/CanlabCore'));
end % ~exist('make_surface_figure

%% get G (symmetric graph Laplacian)
fspath = '/data2/fs-subjects';
fsdir = dir(fspath);
fsdir(1:2) = [];
fsdir(~[fsdir.isdir]) = [];
nfsdir = length(fsdir);

rootpath = '/data2/fs-subjects/fsaverage5/surf';
giipath = rootpath;

for k=1:nfsdir
% for k=127:nfsdir
    if isempty(regexp(fsdir(k).name,'.*-ses-.*','once')), continue, end

    fprintf(1,'sub/sess %s (%d/%d)\n',fsdir(k).name,k,nfsdir);
    
    vpath = fullfile(rootpath,[fsdir(k).name '.20484eig.mat']);
    if exist(vpath,'file')
      % load eigenvectors
      V = load(vpath);
    end % if exist(epath
    
    if ~exist(vpath,'file') || isempty(V) || ...
            (isstruct(V) && length(fieldnames(V)) == 0)
      % eigenvectors haven't been calculated - calculate them!
      fprintf(1,'calculating V');% for %s, %s\n',subids{s},sess{ss});

      % get adjacency matrix
      apath = fullfile(rootpath,[fsdir(k).name '.seedwhite.endptwhite.A.txt']);
      if ~exist(apath,'file')
        warning('cannot find file %s,SKIPPING\n',apath);
        continue
      end % if ~exist(apath,'file
      Asparse = load(apath);
      A = zeros(nvertex);
      for l=1:size(Asparse,1)
        A(Asparse(l,1),Asparse(l,2)) = Asparse(l,3);
        A(Asparse(l,2),Asparse(l,1)) = Asparse(l,3);
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
        save(vpath,'V');
      catch
        warning('error, SKIPPING\n');
        continue
      end
    else
      V = V.V;
      V = V(:,1:num_eig);
    end % if ~exist(epath,'file

    %% plot!
    lhemi = fullfile(giipath,['lh.white.' fsdir(k).name '.gii']);
    rhemi = fullfile(giipath,['rh.white.' fsdir(k).name '.gii']);

    figoutroot = fullfile('/data2/fs-subjects',fsdir(k).name,'harmonics');
    check_dir(figoutroot,0,1);

    for l=1:20 % first 20 eigenvectors
      h = make_surface_figure('surfacefiles',{lhemi,rhemi});
      plot_surface_map({V(1:nvertex/2,l),V(nvertex/2+1:nvertex,l)},...
          'colmap','jet','figure',h,'title',sprintf('Connectome Harmonic %d',l));
      print(fullfile(figoutroot,sprintf([fsdir(k).name '-harmonic_%03d.png'],l)),'-dpng','-r300');
    end % for k=1:10
end % for k=1:length(fsdir

fprintf(1,'-- done\n');
