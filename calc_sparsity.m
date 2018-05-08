% calculate sparsity for adjacency matrices
% 
% fbarrett@jhmi.edu 2018.04.09

%% initialize variables
fstrgs = {'fsaverage5','fsaverage4','fsaverage3'};
nvertex = [10242*2,2562*2,642*2];
nneighbor = [x,y,z]; % determine # of neighbors @ each fsaverage level
aroot = '/Users/fbarrett/Google Drive/collabs/pekar/harmonics/fs5';
subids = {'DCE745','EWM768','JAT763','JLD740','JRD722','MEG743',...
    'MP733','RDW746'};
sess = {'ses-Baseline','ses-Session1'};

%% get adjacency matrices
A = {};
for f=1:length(fstrgs)
%   A{f} = zeros(nvertex(f)); % was used to store entire A mtcs
  A{f} = []; % store # elements in each 

  idx = 0;
  for s=subids
    for ss=sess
        % construct path for subid/sess
        apath = fullfile(aroot,...
            sprintf('%s-%s.seedwhite.endptwhite.A.txt',s{1},ss{1}));

        % look for sparse adjacency matrix file
        if ~exist(apath,'file')
          warning('%s not found, SKIPPING!\n',apath)
          continue
        end % if ~exist(apath,'file
        idx = idx + 1;

        fprintf('processing %s, %s\n',s{1},ss{1});

        % load sparse matrix representation
        Asparse = load(apath);
        A{f}(end+1) = size(Asparse,1)-nneighbor(f); % get only dti cnxns
        
%         %% used to store the entire matrix, but that's not necessary
%         %% to calculate sparseness, just need the # of elements
%         % add to A{f
%         for k=1:size(Asparse,1)
%           A{f}(Asparse(k,1),Asparse(k,2),idx) = Asparse(k,3);
%           A{f}(Asparse(k,2),Asparse(k,1),idx) = Asparse(k,3);
%         end % for k=1:size(Gsparse,1
%         
%         % make sure the diagonal is zero
%         A{f}(find(eye(size(A,1)))+nvertex(f)*idx) = 0;
    end % for ss
  end % for s
end % for f

%% calculate, plot sparsity for all adjacency matrices
figure();
hold on;
for f=1:length(fstrgs)
  nelements = (nvertex(f)*nvertex(f)-nvertex(f))/2;
  hist(A{f}/nelements);
end % f=1:length(fstrgs

