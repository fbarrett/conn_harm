function dtifname = check_philips_dti_file(dtifname,bvals)

% remove average DW image from end of Philips DTI output
% 
%   dtifname = check_philips_dti_file(dtifname,bvals)
% 
% fbarrett@jhmi.edu 2018.05.09

bvallen = length(bvals);
[fp,fn,fx] = fileparts(dtifname);
V = niftiRead(dtifname);

if V.dim(4) > bvallen
  % check to see if a reduced file exists
  if ~exist(fullfile(fp,[fn '_reduced' fx]),'file')
    % create a reduced file

    % change directory into the volunteer's directory
    cwd=pwd;
    
    if ~exist(fp,'dir')
      fprintf(1,'%s not found, SKIPPING\n',fp);
      dtifname = '';
      return
    end % if ~exist(fp,'dir
    cd(fp);

    % split the file into one file per volume
    splitstr = ['fslsplit ' fn fx];
    fprintf(1,'splitting file (%s)\n',splitstr);
    [status,result] = unix(splitstr);
    if status
      warning('check_philips_dti_file %s: %s',dtifname,result);
      dtifname = '';
      return
    end

    pause(5);

    % recombine 1:n-1 images
    vols = dir(fullfile(fp,'vol0*nii.gz'));
    catstr = ['fslmerge -t ' fn '_reduced' fx ' ' ...
        cell2str({vols(1:bvallen).name},' ')];
    fprintf(1,'merging files (%s)\n',catstr);
    [status,result] = unix(catstr);
    if status, error(result); end
    [status,result] = unix(['gunzip ' fn '_reduced' fx '.gz']);
    if status, error(result); end

    % clean up split files
    rmstr = ['rm ' cell2str({vols.name},' ')];
    fprintf(1,'cleaning up (%s)\n',rmstr);
    [status,result] = unix(rmstr);
    if status, warning(result); end

    % go back from whence we came
    cd(cwd);
  end % if exist([fp fn '_reduced ...

  dtifname = fullfile(fp,[fn '_reduced' fx]);
end % if length(V) > bvalsize
