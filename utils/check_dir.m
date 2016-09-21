function status = check_dir(outdir, verbose, parents, group, perm)
% Checks for existence of outdir, and creates it if necessary
%
% status = check_dir(outdir, verbose, parents, group, perm);
%
% status returns 0 on success and 1 on failure
%
% INPUT
% outdir:   a string that specifies the directory to check.
% verbose:  0 or 1. 1 means that some basic status messages will
%           output to the command line
% parents:  0 or 1. 1 means that check_dir will execute mkdir with the '-p'
%           argument, if outdir does not exist. This will create parent
%           directories as needed. execute 'man mkdir' from the unix command
%           line for more information
% groupname: if set, mkdir will change the group of the new directory to
%           this value
% perm:     if set, mkdir will change the permissions of the new directory
%           to this value
%
% Copyright (c) 2005-2012 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% 10/18/05 Petr Janata
% 08/17/09 Fred Barrett - added recursive option
% 04/04/11 Fred Barrett - added group and permission setting. Permission
% setting can be used to set the gid stick bit, if needed (perm: 'g+s')

if ~exist('verbose','var')
  verbose = 0;
end
if exist('parents','var') && parents
  mkdiropts = '-p ';
else
  mkdiropts = '';  
end
status = -1;

if exist(outdir) ~= 7
  if verbose
    fprintf('Making directory: %s\n', outdir);
  end
  %escape spaces and other strange characters for mkdir
  outdir = regexprep(outdir,'[()'',& ]','\\$0');
    
  unix_str = sprintf('mkdir %s%s',mkdiropts,outdir);
  status = unix(unix_str);

else
  status = 0;
end

if ~status
  if exist('group','var') && ~isempty(group)
    unix_str = sprintf('chgrp %s %s',group,outdir);
    status = unix(unix_str);
  end
  if ~status && exist('perm','var') && ~isempty(perm)
    unix_str = sprintf('chmod %s %s',perm,outdir);
    status = unix(unix_str);
  end
end % if ~status
