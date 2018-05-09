function [status,result] = conn_harm_resample(fpath,tgtpath)

% resample surf to template, create gifti, extract vertex coordinates
% 
%   [status,result] = conn_harm_resample(fpath,tgtpath)
% 
% fbarrett@jhmi.edu 2018.05.09

s2scmd = ['mri_surf2surf --s %s --hemi %sh --sval-xyz %s '...
    '--trgsubject %s --tval %sh.%s.%s --tval-xyz %s/mri/orig.mgz'];
giicmd = 'mris_convert %s %s.gii';
m2acmd = 'mris_convert %s/%sh.%s.%s %s/%sh.%s.%s.asc';

h={'l','r'};
surfs={'white','pial'};

[~,tgtstub] = fileparts(tgtpath);
[~,fssub] = fileparts(fpath);

for hh=h
  for sss=1:length(surfs)
      % resample?
      if ~exist(fullfile(tgtpath,sprintf('%sh.%s.%s',...
              hh{1},surfs{sss},fssub)),'file')
        fprintf(1,'resampling %sh %s to template for %s\n',hh{1},surfs{sss},fssub);

        % resample
        s2sstr = sprintf(s2scmd,fssub,hh{1},surfs{sss},tgtstub,hh{1},surfs{sss},...
            fssub,fpath);
        [status,result] = unix(s2sstr);
        if status
          result = track_errors(fpath,tgtpath,hh{1},surfs{sss},result);
          return % if unsuccessful, move to next subject
        end % if status
            
        % create gifti
        giipath = fullfile(fspath,tgtstub,'surf',...
            sprintf('%sh.%s.%s',hh{1},surfs{sss},fssub));
        giistr = sprintf(giicmd,giipath,giipath);
        [status,result] = unix(giistr);
        if status
          result = track_errors(fpath,tgtpath,hh{1},surfs{sss},result);
          return
        end % if status
      end % if ~exist(fullfile(fspath,tt{1},sprintf('...

      % convert surface to ascii?
      if ~exist(fullfile(fspath,tgtstub,sprintf('%sh.%s.%s.asc',...
              hh{1},surfs{sss},fssub)),'file')
        fprintf(1,'convert %sh %s to ascii for %s\n',hh{1},surfs{sss},fssub);

        m2astr = sprintf(m2acmd,fullfile(tgtpath,'surf'),hh{1},surfs{sss},...
            fssub,fullfile(tgtpath,'surf'),hh{1},surfs{sss},fssub);
        [status,result] = unix(m2astr);
        if status
          result = track_errors(fpath,tgtpath,hh{1},surfs{sss},result);
          return % if unsuccessful, move to next subject
        end % if status
      end % if ~exist(fullfile(fspath,fstrg,sprintf('%sh.%s.%s.asc...
  end % for sss
end % for hh

function result = track_errors(f,t,h,s,result)
% tack on tracking information to 'result'
result = sprintf('conn_harm_resample: %s, %s, %s, %s\n%s',f,t,h,s,result);

