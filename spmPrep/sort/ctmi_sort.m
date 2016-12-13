%%ctmi_sort 2.0

% sort data for the CTMI project
% LR 2016.10.03
inpath=pwd;
sortdefs=struct();
sortdefs.dcm2nii.siemens_directory_naming = 1;
sortdefs.directories.epi = {'RS_BOLD'}; % ,'rest_645'
sortdefs.directories.hires = {'T1_MPRAGE'};

dirs  = dir(inpath);
ndir  = length(dirs);

for k=1:ndir
  if ~dirs(k).isdir, continue, end
  if ~isempty(strmatch(dirs(k).name,{'.','..'})), continue, end
  sort_nidata(fullfile(inpath,dirs(k).name),sortdefs);
end