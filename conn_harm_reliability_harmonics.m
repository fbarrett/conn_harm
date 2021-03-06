% Reliability (btwn/within subject Pearson corrleation of adjacency)
% 
% fbarrett@jhmi.edu

% initialize variables
aroot = '/path/to/example_fs5_200eig';
dataroot = '/g4/rgriffi6/1305_working/';

% get subject folderst
subids = dir(dataroot);
subids(1:2) = [];
subids = subids([subids.isdir]);
subids(strcmp('ignore',{subids.name})) = [];
subids = {subids.name};
% subids = {'AGG751','AMM755','CEC761','CWR765','JAT763',...
%     'JED16','JLD740','JNP739','JRD722','KDB754','LDC713','MEG743',...
%     'MGM762','MMM744','MP733','RDW746','RJL752','RZ_758','SHH709',...
%     'SM735'}; % 'DCE745','EWM768','CAH753',
sess = {'ses-Baseline','ses-Session1'};

save_path = fullfile(aroot,'harmonics_reliability_corr_20180716.mat');

nsub = length(subids);
nsess = length(sess);
nvertex = 20484;

num_eig = 200;

win_corrs = [];
btwn_corrs = [];

win_idx = 0;
btwn_idx = 0;

levels = 5:5:num_eig;

%% calculate inter- and intra-subject reliability
for s=1:length(subids)
  fprintf(1,'%s\n',subids{s});
  
  Vbl = [];
  for ss=1:length(sess)
    fprintf(1,'%s\t',sess{ss});
    
    % get first <num_eig> eigenvectors?
    epath = fullfile(dataroot,subids{s},sess{ss},sprintf('%s-%s.%deig.mat',subids{s},sess{ss},num_eig));
    if ~exist(epath,'file')
      % eigenvectors haven't been calculated - calculate them!
      fprintf(1,'not found for %s, %s, SKIPPING!\n',subids{s},sess{ss});
      continue % not this time
      
      % get adjacency matrix
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
        warning('error for %s/%s, SKIPPING\n',subids{s},sess{ss});
        continue
      end
    else
      % load eigenvectors
      V = load(epath);
      V = V.V;
    end % if ~exist(epath,'file

    if ss == 1
      % baseline eigenstuff - save for next iteration
      Vbl = V;
    else
      % calculate intra-subject reliability
      if isempty(Vbl), continue, end
      
      tmp_r = corr([Vbl V(:,1:num_eig)]);
      tmp_r = tmp_r(num_eig+1:num_eig*2,1:num_eig);

      % calculate intra-subject reliability for a range of sub-samples of
      % eigenvectors
      win_idx = win_idx + 1;
      for ll=1:length(levels)
        % mean of Fisher-transformed correlations
        win_corrs(ll,win_idx) = tanh(mean(atanh(max(tmp_r(1:levels(ll),1:levels(ll))))));
      end % for ll=1:length(levels

      save(save_path,'win_sim','btwn_sim');
    end % if ss==1
  end % for sess

  if isempty(Vbl), continue, end
  
  % calculate inter-subject reliability
  for ss=s+1:length(subids)
    fprintf('%02d',ss);
    
    % get first <num_eig> eigenvectors?
    epath = fullfile(dataroot,subids{ss},sess{1},sprintf('%s-%s.%deig.mat',subids{ss},sess{1},num_eig));
    if ~exist(epath,'file')
      % eigenvectors for comparison subject don't exist - calculate them!
      fprintf(1,'not found for %s, %s, SKIPPING!\n',subids{ss},sess{1});
      continue % not this time
      
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
        warning('error for %s, %s, SKIPPING\n',subids{ss},sess{1});
        continue
      end
    else
      % load eigenvectors from disk for comparison subject
      V = load(epath);
      V = V.V;
    end % if ~exist(epath,'file

    % inter-subject reliability for a range of subsamples of eigenvectors
    tmp_r = corr([Vbl V(:,1:num_eig)]);
    tmp_r = tmp_r(num_eig+1:num_eig*2,1:num_eig);
    
    btwn_idx = btwn_idx+1;
    for ll=1:length(levels)
      % mean of Fisher-transformed correlations
      btwn_corrs(ll,btwn_idx) = tanh(mean(atanh(max(tmp_r(1:levels(ll),1:levels(ll))))));
    end % for ll=1:length(levels

    save(save_path,'win_sim','btwn_sim');

    fprintf(1,'\b\b');
  end % for ss=s+1:length(subids
  
  fprintf(1,'\n');
end % for subids

fprintf(1,'DONE in %0.0f minutes\n\n',toc/60);

% clean up matrices - remove anomalous columns
win_corrs(:,mean(win_corrs) == 1) = [];
btwn_corrs(:,mean(btwn_corrs) == 1) = [];

% paired t-test, calculate effect size for intra- vs inter-subject
% reliability for each sub-sample of eigenvectors
h = []; p = []; ci = {}; stats = {}; d= [];
for k=1:length(levels)
  [h(k),p(k),ci{k},stats{k}] = ...
      ttest2(atanh(win_corrs(k,:)),atanh(btwn_corrs(k,:)));
end % for k

% visualize
figure();
wcm = tanh(mean(atanh(win_corrs),2));
wce = tanh(std(atanh(win_corrs),[],2))/sqrt(size(win_corrs,1));
bcm = tanh(mean(atanh(btwn_corrs),2));
bce = tanh(std(atanh(btwn_corrs),[],2))/sqrt(size(btwn_corrs,1));
x = 1:40;
fill([x';flipud(x')],[wcm-wce;flipud(wcm+wce)],[.4 .4 .9],'linestyle','none');
hold on
fill([x';flipud(x')],[bcm-bce;flipud(bcm+bce)],[.9 .4 .4],'linestyle','none');
alpha(0.4)
plot(mean(win_corrs,2),'color','b')
plot(mean(btwn_corrs,2),'color','r')
set(gca,'xtick',0:2:40,'xticklabels',[0 levels(2:2:end)])
title('Reliability of Connectome Harmonics');
xlabel('first N eigenvectors');
ylabel('average Pearson correlation');
legend('intra-subject reliability','inter-subject reliability');

lidx = find(h>0,1,'first');
line([lidx lidx],get(gca,'ylim'));

figure();
subplot(2,1,1);
hist(win_corrs');
title('Within-subject reliabilities');
xlabel('Pearson correlations');

subplot(2,1,2);
hist(btwn_corrs');
title('Between-subject reliabilities');
xlabel('Pearson correlations');

lcell = strsplit(num2str(levels));
legend(lcell,'Location','NorthEastOutside')

