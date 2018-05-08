function t1path = conn_harm_t1(input_path,fprefix)

% get skull-stripped T1 image
% 
%   t1path = conn_harm_t1(input_path,subid)
% 
% INPUT
%   input_path - /path/to/data/subid/session/anat/
%   fprefix - filename prefix for t1-weighted image
% 
% OUTPUT
%   t1path - /path/to/skull/stripped/t1image
% 
% fbarrett@jhmi.edu 2018.05.07

% initialize
t1path = '';

% t1dirs = dir(fullfile(sesspath,'anat',[lower(subid) '*mprage*BET.nii']));
t1dirs = dir(fullfile(input_path,[fprefix '*BET.nii']));
if isempty(t1dirs)
  fprintf(1,'no skull-stripped T1 at %s, making one\n',input_path);

  % if there isn't a skull-stripped image, make one
  t1dirs = dir(fullfile(input_path,[fprefix '*nii']));
  if isempty(t1dirs)
    warning('No t1 for %s, SKIPPING\n',input_path);
    return
  end
  t1tmp = fullfile(input_path,t1dirs(end).name);
  [fp,fn,fx] = fileparts(t1tmp);

  % FSL BET
  if ~exist(fp,'dir')
    fprintf(1,'%s not found, SKIPPING\n',fp);
    return
  end % if ~exist(fp,'dir
  cd(fp);
  betstr = sprintf(betcmd,t1tmp,fn,fx);
  [status,result] = unix(betstr);
  if status
    warning(result);
    return
  end % if status after BET

  % gunzip the BET output
  gunzipstr = sprintf('gunzip %s_BET%s.gz',fn,fx);
  [status,result] = unix(gunzipstr);
  if status
    warning(result);
    return
  end % if status after gunzip
  cd(cwd);

  t1dirs = dir(fullfile(input_path,[fprefix '*BET.nii']));
end % if isempty(t1dirs

t1path = fullfile(input_path,t1dirs(end).name);
