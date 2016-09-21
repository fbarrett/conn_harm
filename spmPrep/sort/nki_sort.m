% sort data for the NKI project
% FB 2016.09.19

sortdefs=struct();
sortdefs.dcm2nii.siemens_directory_naming = 1;
sortdefs.directories.epi = {'rest_1400'}; % ,'rest_645'
sortdefs.directories.hires = {'defaced'};

inpath = '/Users/fbarrett/Documents/data/NKI/working';
dirs  = dir(inpath);
ndir  = length(dirs);

for k=1:ndir
  if ~dirs(k).isdir, continue, end
  if ~isempty(strmatch(dirs(k).name,{'.','..'})), continue, end
  sdir = dir(fullfile(inpath,dirs(k).name));

  for l=1:length(sdir)
    if ~sdir(l).isdir, continue, end
    if ~isempty(strmatch(sdir(l).name,{'.','..'})), continue, end
    sort_nidata(fullfile(inpath,dirs(k).name,sdir(l).name),sortdefs);
  end % for l=1:length(sdir
end % for k=1:ndir
