% preprocess images for connectome harmonic analysis
% 
%   BET to skull-strip the structural
%   - use very low fractional intensity threshold (0.1?)
%   use FS to generate and register cortical surfaces to 1000 connectome
%   - reconstruct subject
%   - register subject to fsaverage5
%   - mri_surf2surf -src fsaverage.white -trg subject.white
%   - dtrecon --b bvecs bvals --i <file> --s <subj> --o <outpath>
%   - register subject's DTI to subject.white
%   use mrDiffusion to preprocess DTI data
%   
%   !! Assumes 4D FSL NIfTI DWI file from Phillips platform - Phillips adds
%   B0 as the first volume and an average diffusion volume as the final
%   volume, so the file has # directions + 2 volumes
% 
%   !! Assumes data in roughly BIDS directory organization
% 
% fbarrett@jhmi.edu

%% initialize variables
subids = {'jed716'};

% path variables
dataroot = '/Users/fbarrett/Documents/data/1305/conn_harm';

% FS variables
fstrg = 'fsaverage5';
fspath = '/Applications/freesurfer/subjects';
h={'l','r'};

% FS commands
reconcmd = 'recon-all -s %s -i %s -all'; % <subid> <MPRAGE>
regcmd = 'mris_register %s %s %s'; % <surfname> <tgt> <outname>
% mris_register agg751/surf/lh.sphere fsaverage5/lh.reg.template.tif
% agg/surf/lh.fsaverage5.sphere.reg
% qccmd = 'recon-all -s %s -qcache -target %s'; % <subid> <tgt>
s2scmd = ['mri_surf2surf --s %s --hemi %sh --sval-xyz white '...
    '--trgsubject %s --tval %sh.white.%s --tval-xyz %s/mri/orig.mgz'];
m2acmd = 'mris_convert %s/%sh.white.%s %s/%sh.white.%s.asc';

% mrDiffusion variables
bvecspath = '/Users/fbarrett/Documents/data/1305/dti/bvecs';
bvalspath = '/Users/fbarrett/Documents/data/1305/dti/bvals';

dwParams = dtiInitParams('bvecsFile',bvecspath,'bvalsFile',bvalspath,...
    'bsplineInterpFlag',true,'eddyCorrect',-1,'phaseEncodeDir',2);

% initialize SPM
spm12_init;
spm('defaults','fmri');
spm_jobman('initcfg');

%% process the work
for s=subids
  subpath = fullfile(dataroot,['sub-' s{1}]);
  
  sessdir = dir(subpath);
  sessdir(1:2) = [];
  sessdir(~[sessdir.isdir]) = [];
  sess = {sessdir.name}';
  
  for ss=sess
    cwd=pwd;
    
    sesspath = fullfile(subpath,ss{1});
    
    % % % use FS to process structural image, generate and register surfaces
    % get skull-stripped T1
    t1dirs = dir(fullfile(sesspath,'anat',[s{1} '*mprage*BET.nii']));
    if isempty(t1dirs)
      % if there isn't a skull-stripped image, make one
      t1dirs = dir(fullfile(sesspath,'anat',[s{1} '*mprage*nii']));
      if isempty(t1dirs), error, end
      
      t1path = fullfile(sesspath,'anat',t1dirs(end).name);
      if ~exist(t1path,'file'), error, end
      [fp,fn,fx] = fileparts(t1path);
  
      % BET
      cd(fp);
      betstr = sprintf('bet %s %s_BET%s -f 0.1',t1path,fn,fx);
      [status,result] = unix(betstr);
      if status
        warning(result);
        continue
      end % if status after BET
      
      gunzipstr = sprintf('gunzip %s_BET%s.gz',fn,fx);
      [status,result] = unix(gunzipstr);
      if status
        warning(result);
        continue
      end % if status after gunzip
      cd(cwd);
    
      t1dirs = dir(fullfile(sesspath,'anat',[s{1} '*mprage*BET.nii']));
    end % if isempty(t1dirs
    t1path = fullfile(sesspath,'anat',t1dirs(end).name);
    if ~exist(t1path,'file'), warning('%s not found, SKIPPING\n',t1path), end
    
    %%%% SET ORIGIN ON T1 IMAGE
    nii_setOrigin(t1path,1);

    % reconstruct cortical surface
    reconstr = sprintf(reconcmd,s{1},t1path);
    fprintf(1,'reconstructing cortical surfaces for %s (%s)\n',s{1},reconstr);
    [status,result] = unix(reconstr);
    if status
      warning(result);
      continue
    end % if status
  
    % register subject to template with mris_register
    for hh=h
%       surfname = sprintf('%s/surf/%sh.sphere',s{1},hh{1});
      surfname = fullfile(fspath,s{1},'surf',sprintf('%sh.sphere',hh{1}));
%       regtrg = sprintf('%s/%sh.reg.template.tif',fstrg,hh{1});
      regtrg = fullfile(fspath,fstrg,sprintf('%sh.reg.template.tif',hh{1}));
%       outname = sprintf('%s/surf/%sh.%s.sphere.reg',s{1},hh{1},fstrg);
      outname = fullfile(fspath,s{1},'surf',sprintf('%sh.%s.sphere.reg',hh{1},fstrg));
      regstr = sprintf(regcmd,surfname,regtrg,outname);
    
      [status,result] = unix(regstr);
      if status
        warning(result);
        continue
      end % if status
    end % for hh=h
  
    % resample white matter surface to the template, extract coordinates for
    % each vertex in native space
    for hh=h
      % resample
      s2sstr = sprintf(s2scmd,s{1},hh{1},fstrg,hh{1},s{1},fullfile(fspath,s{1}));
      [status,result] = unix(s2sstr);
      if status
        warning(result);
        continue
      end % if status
    
      % convert
      m2astr = sprintf(m2acmd,fullfile(fspath,fstrg,'surf'),hh{1},s{1},...
          fullfile(fspath,fstrg,'surf'),hh{1},s{1});
      [status,result] = unix(m2astr);
      if status
        warning(result);
        continue
      end % if status
    end % for hh=h
  
    % % %     coregister EPI to MPRAGE
    EPIfiles = spm_select('ExtFPList',fullfile(sesspath,'func'),[s{1} '.*rest.*nii']);
    DWIfiles = spm_select('ExtFPList',fullfile(sesspath,'dwi'),'.*DTI.*nii');
    realign_output = conn_harm_realign(cellstr(DWIfiles),cellstr(EPIfiles),t1path);

    nii_setOrigin(realign_output{1}.sess(1).rfiles{1},2);
    nii_setOrigin(realign_output{1}.sess(2).rfiles{1},4);
    
    % % %     normalize DTI to EPI
    normed_output = conn_harm_oldnorm(realign_output{1}.sess(1).rfiles,...
        realign_output{2}.rfiles(1)); % from realign_output
  
    % % % use mrDiffusion to preprocess DTI data
    dtifname = fullfile(spm_file(normed_output,'fpath'),...
        [spm_file(normed_output,'basename') spm_file(normed_output,'ext')]);
  
    % get file parts
    [fp,fn,fx] = fileparts(dtifname);
    dwParams.outDir = fp;

    % ? if the # of volumes in dtifname is greater than the size of bvals/bvecs
    % (assuming by 1), then create a new file that contains 2:n volumes
    V = niftiRead(dtifname);
    if V.dim(4) > bvalsize
      % check to see if a reduced file exists
      if ~exist(fullfile(fp,[fn '_reduced' fx],'file'))
        % create a reduced file
    
        % change directory into the volunteer's directory
        cd(fp);

        % split the file into one file per volume
        splitstr = ['fslsplit ' fn fx];
        fprintf(1,'splitting file (%s)\n',splitstr);
        [status,result] = unix(splitstr);
        if status, error(result); end
  
        % recombine 2:n images
        vols = dir(fullfile(fp,'vol0*nii.gz'));
        catstr = ['fslmerge -t ' fn '_reduced' fx ' ' ...
            cell2str({vols(1:end-1).name},' ')];
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

    fprintf(1,'DTI filename: %s\nT1 filename: %s\n',dtifname,t1path);

    % change directory to the parent of dtifname, so that output from
    % mrDiffusion goes into this directory
    cd(fileparts(dtifname));

    [dt6fname,outBaseDir] = dtiInit(dtifname,t1path,dwParams);
  end % for ss=sess
end % for s=subids
