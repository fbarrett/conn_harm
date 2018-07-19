% decompose BOLD data using connectome harmonics
% 
% fbarrett@jhmi.edu 2018.05.17

dataroot = '/g4/rgriffi6/1305_working/';
dataroot = '/Volumes/OrangeDisk/1305/resting_preproc/';
fsroot = '/g5/fbarret2/fs-subjects/fsaverage5/surf';
fsroot = '/Volumes/OrangeDisk/1305/conn_harm_mtcs';

neig = 20484;

% get subject folderst
% subids = dir(dataroot);
% subids(1:2) = [];
% subids = subids([subids.isdir]);
% subids(strcmp('ignore',{subids.name})) = [];
% subids = {subids.name};
subids = {'agg751','amm755','cah753','cec761','

% get all subjects and sessions
subsess = {};
for s=1:length(subids)
  subpath = fullfile(dataroot,subids{s});

  % session directories are nested in subject directories
  sessdir = dir(subpath);           % get session directories
  sessdir(1:2) = [];                % remove '.' and '..'
  sessdir(~[sessdir.isdir]) = [];   % remove non-directory entries
  sess = {sessdir.name}';
  
  for ss=1:length(sess)
    subsess{end+1} = {subids{s},sess{ss}};
  end % for ss
end % for s

bold_harmonics = cell(length(subsess),1);
bold_error = cell(length(subsess),1);

parfor s=1:length(subsess)
% parfor s=5
  bpath = fullfile(dataroot,subsess{s}{1},subsess{s}{2},'func_stc');
  bdir = dir(fullfile(bpath,'ra*rest*nii'));
  if isempty(bdir), continue, end
  bold_path = fullfile(bpath,bdir(1).name);

  fssub = [regexprep(subsess{s}{1},'sub-','') '-' subsess{s}{2}];
  adj_path = fullfile(fsroot,sprintf('%s.seedwhite.endptwhite.A.txt',fssub));

  try
    bold_harmonics(s) = {conn_harm_bold_decomp(bold_path,adj_path)};
  catch
    bold_error(s) = {lasterror};
  end 
end % for s
