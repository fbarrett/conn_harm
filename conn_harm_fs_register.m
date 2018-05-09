function [status,result] = conn_harm_fs_register(fpath,tgtpath)

% register subject to template with FS mris_register
% 
%   [status,result] = conn_harm_fs_register(
% 
% fbarrett@jhmi.edu - 2018.05.09

regcmd = 'mris_register %s %s %s'; % <surfname> <tgt> <outname>
h = {'l','r'};
status = 0;
result = '';

[~,tgtstub] = fileparts(tgtpath);

for hh=h
  surfname = fullfile(fpath,'surf',sprintf('%sh.sphere',hh{1}));
  regtrg = fullfile(tgtpath,sprintf('%sh.reg.template.tif',hh{1}));
  outname = fullfile(fpath,'surf',sprintf('%sh.%s.sphere.reg',hh{1},tgtstub));
  regstr = sprintf(regcmd,surfname,regtrg,outname);

  if ~exist(outname,'file')
    fprintf(1,'registering %s to template for %sh\n',fssub,hh{1});

    [status,result] = unix(regstr);
    if status
      result = track_errors(fpath,tgtpath,hh{1},result);
      return % if unsuccessful, stop
    end % if status
  end % if ~exist(outname,'file
end % for hh

function result = track_errors(f,t,h,result)
% tack on tracking information to 'result'
result = sprintf('conn_harm_fs_register: %s, %s, %s\n%s',f,t,h,result);
