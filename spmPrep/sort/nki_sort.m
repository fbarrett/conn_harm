% sort data for the NKI project
% FB 2016.09.19
inpath=pwd;
sortdefs=struct();
sortdefs.dcm2nii.siemens_directory_naming = 1;
sortdefs.directories.epi = {'rest_1400'}; % ,'rest_645'
sortdefs.directories.hires = {'defaced'};

dirs  = dir(inpath);
ndir  = length(dirs);

for k=1:ndir
  if ~dirs(k).isdir, continue, end
  if ~isempty(strmatch(dirs(k).name,{'.','..'})), continue, end
  sort_nidata(fullfile(inpath,dirs(k).name),sortdefs);
end