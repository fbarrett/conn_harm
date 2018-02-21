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
%   volume, so the file has # directions + 2 volumes, need to remove final volume
% 
%   !! Assumes data in roughly BIDS directory organization
% 
%   !! %%%ARBITRARY? marks places where potentially arbitrary decisions are made
%       these are decisions that needed to be made, but were ill-specified (or not
%       at all specified) and needed to be inferred (or guessed) given what is
%       described in Atasoy et al., 2015, 2017. So, I made my best guess, but these
%       are decisions that are absolutely up for debate, and potentially up for
%       systematic examination
% 
% fbarrett@jhmi.edu

%% initialize variables
subids = {'jed716'}; % these subjects will be processed

% root path for DTI and functional data
dataroot = '/Users/fbarrett/Documents/data/1305/conn_harm';

% FreeSurfer (FS) variables
fstrg = 'fsaverage5';
fspath = '/Applications/freesurfer/subjects';
h={'l','r'};
surfs={'white','pial'};

% FS commands
reconcmd = 'recon-all -s %s -i %s -all'; % <subid> <MPRAGE>
regcmd = 'mris_register %s %s %s'; % <surfname> <tgt> <outname>
s2scmd = ['mri_surf2surf --s %s --hemi %sh --sval-xyz %s '...
    '--trgsubject %s --tval %sh.%s.%s --tval-xyz %s/mri/orig.mgz'];
m2acmd = 'mris_convert %s/%sh.%s.%s %s/%sh.%s.%s.asc';

% FSL commands
%   - use very low fractional intensity threshold (0.1?) %%%ARBITRARY?
betcmd = 'bet %s %s_BET%s -f 0.1';

% mrDiffusion variables
bvecspath = '/Users/fbarrett/Documents/data/1305/dti/bvecs';
bvalspath = '/Users/fbarrett/Documents/data/1305/dti/bvals';
bva lsize = length(load(bvalspath));

% initialize mrDiffusion parameter structure
% bspline interpolation %%%ARBITRARY?
dwParams = dtiInitParams('bvecsFile',bvecspath,'bvalsFile',bvalspath,...
    'bsplineInterpFlag',true,'eddyCorrect',-1,'phaseEncodeDir',2);

% initialize SPM
spm12_init;
spm('defaults','fmri');
spm_jobman('initcfg');

%% iterate over subjects, preprocess data
% iterate over subjects
for s=subids
  subpath = fullfile(dataroot,['sub-' s{1}]);

  % session directories are nested in subject directories
  sessdir = dir(subpath);           % get session directories
  sessdir(1:2) = [];                % remove '.' and '..'
  sessdir(~[sessdir.isdir]) = [];   % remove non-directory entries
  sess = {sessdir.name}';
  
  % iterate over sessions
  for ss=sess
    cwd=pwd;
    
    sesspath = fullfile(subpath,ss{1});
    
    % get skull-stripped T1
    t1dirs = dir(fullfile(sesspath,'anat',[s{1} '*mprage*BET.nii']));
    if isempty(t1dirs)
      % if there isn't a skull-stripped image, make one
      t1dirs = dir(fullfile(sesspath,'anat',[s{1} '*mprage*nii']));
      t1path = fullfile(sesspath,'anat',t1dirs(end).name);
      [fp,fn,fx] = fileparts(t1path);
  
      % FSL BET
      cd(fp);
      betstr = sprintf(betcmd,t1path,fn,fx);
      [status,result] = unix(betstr);
      if status
        warning(result);
        continue % if unsuccessful, move to next subject
      end % if status after BET

      % gunzip the BET output
      gunzipstr = sprintf('gunzip %s_BET%s.gz',fn,fx);
      [status,result] = unix(gunzipstr);
      if status
        warning(result);
        continue % if unsuccessful, move to next subject
      end % if status after gunzip
      cd(cwd);
    
      t1dirs = dir(fullfile(sesspath,'anat',[s{1} '*mprage*BET.nii']));
    end % if isempty(t1dirs
    
    t1path = fullfile(sesspath,'anat',t1dirs(end).name);
    if ~exist(t1path,'file')
      warning('%s not found, SKIPPING\n',t1path)
      continue
    end
    
    % SET ORIGIN ON T1 IMAGE
    nii_setOrigin(t1path,1);

    % use FS to reconstruct cortical surface - THIS WILL TAKE A WHILE
    reconstr = sprintf(reconcmd,s{1},t1path);
    fprintf(1,'reconstructing cortical surfaces for %s (%s)\n',s{1},reconstr);
    [status,result] = unix(reconstr);
    if status
        warning(result);
        continue
    end % if status

    for hh=h % for each hemisphere ...

      % register subject to template with FS mris_register
      surfname = fullfile(fspath,s{1},'surf',sprintf('%sh.sphere',hh{1}));
      regtrg = fullfile(fspath,fstrg,sprintf('%sh.reg.template.tif',hh{1}));
      outname = fullfile(fspath,s{1},'surf',sprintf('%sh.%s.sphere.reg',hh{1},fstrg));
      regstr = sprintf(regcmd,surfname,regtrg,outname);
    
      [status,result] = unix(regstr);
      if status
        warning(result);
        continue % if unsuccessful, move to next subject
      end % if status
      
      % resample surface to the template, extract coordinates for each
      % vertex in native space
      for sss=surfs % for each surface ...
        % resample
        s2sstr = sprintf(s2scmd,s{1},hh{1},sss{1},fstrg,hh{1},sss{1},...
            s{1},fullfile(fspath,s{1}));
        [status,result] = unix(s2sstr);
        if status
          warning(result);
          continue % if unsuccessful, move to next subject
        end % if status
    
        % convert surface to ascii
        m2astr = sprintf(m2acmd,fullfile(fspath,fstrg,'surf'),hh{1},sss{1},...
            s{1},fullfile(fspath,fstrg,'surf'),hh{1},sss{1},s{1});
        [status,result] = unix(m2astr);
        if status
          warning(result);
          continue % if unsuccessful, move to next subject
        end % if status
      end % for sss=surfs
    end % for hh=h
  
    % % %     coregister EPI to MPRAGE
    EPIfiles = spm_select('ExtFPList',fullfile(sesspath,'func'),[s{1} '.*rest.*nii']);
    DWIfiles = spm_select('ExtFPList',fullfile(sesspath,'dwi'),'.*DTI.*nii');
    realign_output = conn_harm_realign(cellstr(DWIfiles),cellstr(EPIfiles),t1path);
    
    % % %     normalize DTI to EPI
    normed_output = conn_harm_oldnorm(realign_output{1}.sess(1).rfiles,...
        realign_output{2}.rfiles(1)); % from realign_output
  
    % % % use mrDiffusion to preprocess DTI data
    dtifname = fullfile(spm_file(normed_output{1}.files{1},'fpath'),...
        [spm_file(normed_output{1}.files{1},'basename') '.' ...
        spm_file(normed_output{1}.files{1},'ext')]);
    dwParams.outDir = spm_file(normed_output{1}.files{1},'fpath');
  
    % get file parts
    [fp,fn,fx] = fileparts(dtifname);

    % PHILIPS appends an average DW image to the end ... we need to remove
    % this image
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
  
        % recombine 1:n-1 images
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

    % set up mrDiffusion analysis variables
    [dt6fname,outBaseDir] = dtiInit(dtifname,t1path,dwParams);
    dt6 = load(dt6fname{1});

  end % for ss=sess
end % for s=subids
