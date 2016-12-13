function sort_nidata(inpath,sort_defs)

% sorts and organizes raw MRI data
% 
%       sort_nidata(indir)
% 
%   indir - path to directory containing raw MRI data for one volunteer and
%       one imaging session
%   sort_defs - struct containing instructions for sorting data
%       .directories - each fieldname below ".directories" will be created
%           as a directory under inpath. the value of
%           .directories.(Dirname) should be a cell array of strings with
%           regular expressions that identify files from "orig" to be put
%           into the given directory.
%       .dcm2nii - instructions for how to convert from dcm to nii, as well
%           as how to rename files that get generated as nii (if necessary)
%           .siemens_directory_naming - see below for pattern assumptions
% 
% this assumes that, if you have directories nested within your original
% data directory (and subsequently your orig directory), there will only be
% one level of nesting below that. 
% 
% FB 2016.09.19

% hard coded ... shouldn't be
if ~exist('spmPrep','file')
  addpath('/Users/fbarrett/git/napp_ni/spmPrep');
end % if ~exist('spmPrep','file

dcmpath = fullfile(fileparts(which('spmPrep')),'mricron','dcm2nii64');
dcmstub = sprintf('%s -4 y -n y -v y -g n %%s',dcmpath);

%allow use of dcm2nii on new machines
unix(char(strcat('chmod u+x',{' '},dcmpath)));

if ~exist(inpath)
  inpath = uigetdir(pwd,'Choose an MRI input directory');
  if isempty(inpath)
    error('directory not specified\n',inpath);
  elseif ~exist(inpath)
    error('%s not found\n',inpath);
  end % if ~exist(indir
end

origpath = fullfile(inpath,'orig');
if ~exist(origpath)
  warning('%s not found, CREATING, moving contents of %s to %s\n',...
      origpath,inpath,origpath);
  
  % get contents of inpath
  indir = dir(inpath);
  indir(1:2) = [];
  
  % make origpath
  check_dir(origpath,0,1);
  
  % move inpath files to origpath
  for k=1:length(indir)
    movefile(fullfile(inpath,indir(k).name),fullfile(origpath,indir(k).name));
  end % for k=1:length(indir
  
  % physio data?
  physdir = dir(fullfile(origpath,'*log'));
  if ~isempty(physdir)
    % make physio directory, copy files from origpath
    physpath = fullfile(inpath,'physio');
    fprintf(1,'making physio dir (%s), copying .log files',physpath);
    mkdir(physpath)
    
    for k=1:length(physdir)
      copyfile(fullfile(origpath,physdir(k).name),...
          fullfile(physpath,physdir(k).name));
    end % for k=1:length(physdir
  end % if ~isempty(physdir
  
  % dcm2nii?
  if isfield(sort_defs,'dcm2nii')
    ustr = sprintf(dcmstub,origpath);
    fprintf(1,'%s\n',ustr);
    [status,result] = unix(ustr);
    
    if isfield(sort_defs.dcm2nii,'siemens_directory_naming')
      for k=1:length(indir)
        if ~indir(k).isdir || ~isempty(strmatch(indir(k).name,{'.','..'}))
          continue
        end % if ~indir(k).isdir
        
        dcmtoken = regexp(indir(k).name,'(.*)\_(\d{4})$','tokens');
        if isempty(dcmtoken)
          warning('didnt resolve scan sequence for %s',indir(k).name);
          continue
        end % if isempty(dcmtoken
        niistr = sprintf('*%03da*001.nii',str2num(dcmtoken{1}{2}));
        seqdir = dir(fullfile(origpath,niistr));
        if isempty(seqdir)
          warning('didnt resolve nii file for %s',indir(k).name);
          continue
        end % if isempty(seqdir

        % move file
        niipath = fullfile(origpath,seqdir(1).name);
        newpath = fullfile(origpath,sprintf('%s.nii',lower(dcmtoken{1}{1})));
        movefile(niipath,newpath);
      end % for k=1:length(indir
    end % if isfield(sort_defs.dcm2nii,'siemens_directory_naming
  end % if isfield(sort_defs,'dcm2nii
end % if ~exist(origdir

for d=fieldnames(sort_defs.directories)';
  dest = fullfile(inpath,d{1});
  check_dir(dest,0,1);
  if ~isempty(sort_defs.directories.(d{1})) && ~iscell(sort_defs.directories.(d{1}))
    sort_defs.directories.(d{1}) = {sort_defs.directories.(d{1})};
  end % if ~isempty(sort_defs.(d{1
  
  for t=1:length(sort_defs.directories.(d{1}))
    nested_dir(dest,origpath,sort_defs.directories.(d{1}){t});
  end % for t=1:length(sort_defs.(d{1
end % for d=fieldnames(sort_defs

% 

function nested_dir(dest,tpath,t)

  dirs = dir(fullfile(tpath,['*' t '*']));
  
  for k=1:length(dirs)
    if dirs(k).isdir
      if ~isempty(strmatch(dirs(k).name,{'.','..'}))
        continue
      else
        nested_dir(dest,fullfile(tpath,dirs(k).name),t);
      end % if ~isempty(strmatch(dirs(k
    else
      lpath = fullfile(tpath,dirs(k).name);
      if ~isempty(regexp(lpath,'.*.gz$','once'))
        unix(['gunzip ' lpath]);
        lpath = lpath(1:end-3);
      end % if ~isempty(regexp(lpath,'.*.gz$
      
      fprintf(1,'copying %s to %s\n',lpath,dest);
      copyfile(lpath,dest);
    end % if dirs(k)isdir
  end % for k=1:length(dirs
