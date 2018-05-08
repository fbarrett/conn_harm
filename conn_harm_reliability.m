% calculate DICE between/within subjects adjacency matrices
% 
% fbarrett@jhmi.edu

aroot = '/Users/fbarrett/Google Drive/collabs/pekar/harmonics/fs5';
subids = {'CEC761','DCE745','EWM768','JAT763','JLD740','JRD722',...
    'KDB754','LDC713','MEG743','MGM762','MP733','RDW746','RJL752',...
    'RZ_758','SHH709'};
sess = {'ses-Baseline','ses-Session1'};

nsub = length(subids);
nsess = length(sess);
nvertex = 20484;

win_corrs = [];
btwn_corrs = [];

win_dices = [];
btwn_dices = [];

% get neighborhood matrices to subtract from adjacency matrices
nmat.l = load(fullfile(aroot,'rh.white.r1.cmat.mat'));
nmat.r = load(fullfile(aroot,'lh.white.r1.cmat.mat'));
nmat.l = nmat.l.cmat;
nmat.r = nmat.r.cmat;
nfld = fieldnames(nmat);
An = zeros(size(nmat.l,1)*2);

for hh=1:length(nfld)
  tmpmat = nmat.(nfld{hh});
  lidxs = 1:size(tmpmat,1);
  hidxs = lidxs+size(tmpmat,1)*(hh-1);
  An(hidxs,hidxs) = An(hidxs,hidxs)+tmpmat(lidxs,lidxs);
end % for hh=h

tic
for s=1:length(subids)
% for s=1
  fprintf(1,'%s\n',subids{s});
  
  Abl = [];
  for ss=1:length(sess)
    fprintf(1,'%s\t',sess{ss});
    
    % adjacency matrix
    apath = fullfile(aroot,sprintf('%s-%s.seedwhite.endptwhite.A.txt',...
        subids{s},sess{ss}));
    if ~exist(apath,'file'), continue, end
    
    Asparse = load(apath);
    A = zeros(nvertex);
    for k=1:size(Asparse,1)
      A(Asparse(k,1),Asparse(k,2)) = Asparse(k,3);
      A(Asparse(k,2),Asparse(k,1)) = Asparse(k,3);
    end % for k=1:size(Asparse,1
    A(find(eye(size(A,1)))) = 0;
    A(find(An)) = 0;
    if ss == 1
        Abl = A;
    else
        ld = dice(Abl,A);
        win_dices(end+1) = ld(1);
    end % if ss==1
  end % for sess
  
  for ss=s+1:length(subids)
    fprintf('%02d',ss);
    
    % adjacency matrix
    apath = fullfile(aroot,sprintf('%s-%s.seedwhite.endptwhite.A.txt',...
        subids{ss},sess{1}));
    if ~exist(apath,'file'), continue, end
    
    Asparse = load(apath);
    A = zeros(nvertex);
    for k=1:size(Asparse,1)
      A(Asparse(k,1),Asparse(k,2)) = Asparse(k,3);
      A(Asparse(k,2),Asparse(k,1)) = Asparse(k,3);
    end % for k=1:size(Asparse,1
    A(find(eye(size(A,1)))) = 0;
    A(find(An)) = 0;
    ld = dice(Abl,A);
    btwn_dices(end+1) = ld(1);
    
    fprintf(1,'\b\b');
  end % for ss=s+1:length(subids
  
  fprintf(1,'\n');
end % for subids

fprintf(1,'DONE in %0.0f minutes\n\n',toc/60);
