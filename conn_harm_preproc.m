% preprocess images for connectome harmonic analysis
% 
%   BET to skull-strip the structural
%   - use very low fractional intensity threshold (0.1?) 
%   use FS to generate and register cortical surfaces to 1000 connectome
%   - reconstruct subject
%   - register subject to fsaverage5 (or fsaverage4,3,?)
%   - mri_surf2surf -src fsaverage.white -trg subject.white
%   - dtrecon --b bvecs bvals --i <file> --s <subj> --o <outpath>
%   - register subject's DTI to subject.white
%   use mrDiffusion to preprocess DTI data
%   
%   !! Assumes 4D FSL NIfTI DWI file from Philips platform - Philips adds
%   B0 as the first volume and an average diffusion volume as the final
%   volume, so the file has # directions + 2 volumes, need to remove final volume
% 
%   !! Assumes data in roughly BIDS directory organization
% 
%   NOTE: needs janatalab script cell2str
%
% fbarrett@jhmi.edu

%% initialize variables
% root path for DTI and functional data
dataroot = '/Users/fbarrett/Documents/data/1305/conn_harm';
dataroot = '/g4/rgriffi6/1305_working/';

% get subject folderst
subids = dir(dataroot);
subids(1:2) = [];
subids = subids([subids.isdir]);
subids(strcmp('ignore',{subids.name})) = [];
subids = {subids.name};

% FreeSurfer (FS) variables
% fstrg = 'fsaverage5';
fstrg = {'fsaverage5','fsaverage4','fsaverage3'};
fspath = '/Applications/freesurfer/subjects';
fspath = '/g5/fbarret2/fs-subjects';
h={'l','r'};
surfs={'white','pial'};

% FS commands
reconcmd = 'recon-all -s %s -i %s -all'; % <subid> <MPRAGE>

% mrDiffusion variables
bvecspath = '/g4/rgriffi6/1305_working/bvecs';
bvalspath = '/g4/rgriffi6/1305_working/bvals';
bvals = load(bvalspath);
bvalsize = length(bvals);

% initialize mrDiffusion parameter structure
% bspline interpolation %%%ARBITRARY?
dwParamsMaster = dtiInitParams('bvecsFile',bvecspath,'bvalsFile',bvalspath,...
    'bsplineInterpFlag',true,'eddyCorrect',-1,'phaseEncodeDir',2);

% initialize SPM
spm12_init;
spm('defaults','fmri');
% spm_jobman('initcfg');

%% iterate over subjects, preprocess data
% iterate over subjects
parfor s=1:length(subids)
% for s=1:length(subids)
  subpath = fullfile(dataroot,subids{s});
  subid = regexprep(subids{s},'sub-','');

  % session directories are nested in subject directories
  sessdir = dir(subpath);           % get session directories
  sessdir(1:2) = [];                % remove '.' and '..'
  sessdir(~[sessdir.isdir]) = [];   % remove non-directory entries
  sess = {sessdir.name}';
  
  % iterate over sessions
  for ss=3:5 % for ss=1:2 % 1:length(sess
    cwd=pwd;
    
    if ss > length(sess), continue, end
    
    sesspath = fullfile(subpath,sess{ss});
    fssub = [subid '-' sess{ss}];
    sfspath = fullfile(fspath,fssub);
    
    % get skull-stripped T1
    t1path = conn_harm_t1(fullfile(sesspath,'anat'),[lower(subid) '*mprage']);
    if ~exist(t1path,'file')
      warning('%s not found, SKIPPING\n',t1path)
      continue
    end
    
    % SET ORIGIN ON T1 IMAGE
    nii_setOrigin(t1path,1);

    % use FS to reconstruct cortical surface - THIS WILL TAKE A WHILE
    if ~exist(fullfile(sfspath,'surf',sprintf('lh.sphere')),'file')
      reconstr = sprintf(reconcmd,fssub,t1path);
      fprintf(1,'reconstructing cortical surfaces for %s (%s)\n',fssub,reconstr);
      [status,result] = unix(reconstr);
      if status
          warning(result);
          continue
      end % if status
    end % if ~exist(fullfile(fspath,fssub,'surf

    % register subject to template, extract native vertex coordinates
    for tt=fstrg
      tgtpath = fullfile(fspath,tt{1});
      
      % register subject to template with FS mris_register
      [status,result] = conn_harm_fs_register(sfspath,tgtpath);
      if ~status, warning(result), continue, end
      
      % resample surf to template, create gifti, extract vertex coordinates
      [status,result] = conn_harm_resample(sfspath,tgtpath);
      if ~status, warning(result), continue, end

    end % for tt=fstrg
    
    % % %     coregister DWI, EPI to MPRAGE
    EPIfiles = spm_select('ExtFPList',fullfile(sesspath,'func_stc'),['^ra' lower(subid) '.*rest.*nii']);
    if isempty(EPIfiles)
      EPIfiles = spm_select('ExtFPList',fullfile(sesspath,'func_stc'),['^' lower(subid) '.*rest.*nii']);
    end % if isempty(EPIfilespreprocd
    
    DWIfiles = spm_select('ExtFPList',fullfile(sesspath,'dwi'),'^wr.*DTI.*nii');
    if isempty(DWIfiles) % check to see if gzipped
      DWIfiles = spm_select('ExtFPList',fullfile(sesspath,'dwi'),'^201.*DTI.*nii');
      if isempty(DWIfiles)
        DWIfiles = dir(fullfile(sesspath,'dwi','*DTI*nii.gz'));
        if ~exist(fullfile(sesspath,'dwi'),'dir')
          fprintf(1,'%s not found, SKIPPING\n',fullfile(sesspath,'dwi'));
          continue
        end % if ~exist(fp,'dir
        cd(fullfile(sesspath,'dwi'));
        for dwif=1:length(DWIfiles)
          gunzipstr = sprintf('gunzip %s',DWIfiles(dwif).name);
          [status,result] = unix(gunzipstr);
          if status
            warning(result);
            continue % if unsuccessful, move to next subject
          end % if status after gunzip
        end % for dwif=1:length(DWIfiles
        cd(cwd);
        DWIfiles = spm_select('ExtFPList',fullfile(sesspath,'dwi'),'.*DTI.*nii');
      end % if isempty(DWIfiles <nested>

      try 
        realign_output = conn_harm_realign(cellstr(DWIfiles),cellstr(EPIfiles),t1path);
    
        % % %     normalize DTI to EPI
        normed_output = conn_harm_oldnorm(realign_output{1}.sess(1).rfiles,...
            realign_output{2}.rfiles(1)); % from realign_output
      catch
        warning('PROBLEMS REALIGNING/NORMING %s, SKIPPING\n',fssub);
        continue
      end
      dwi_file = normed_output{1}.files{1};
    else
      dwi_file = DWIfiles(1,:);
    end % if isempty(DWIfiles
    
    % % % use mrDiffusion to preprocess DTI data
    dtifname = fullfile(spm_file(dwi_file,'fpath'),...
        [spm_file(dwi_file,'basename') '.' ...
        spm_file(dwi_file,'ext')]);
    dwParams = dwParamsMaster;
    dwParams.outDir = spm_file(dwi_file,'fpath');
  
    % check that Philips DTI output is reduced
    dtifname = check_philips_dti_file(dtifname,bvals);

    fprintf(1,'DTI filename: %s\nT1 filename: %s\n',dtifname,t1path);

    % change directory to the parent of dtifname, so that output from
    % mrDiffusion goes into this directory
    if ~exist(fileparts(dtifname),'dir')
      fprintf(1,'%s not found, SKIPPING\n',fileparts(dtifname));
      continue
    end % if ~exist(fp,'dir
    cd(fileparts(dtifname));

    % set up mrDiffusion analysis variables
    dtidir = dir(fullfile(fileparts(dtifname),'**','dt6.mat'));
    if isempty(dtidir)
      fprintf(1,'processing DTI for %s, %s\n',subids{s},sess{ss});
      [dt6fname,outBaseDir] = dtiInit(dtifname,t1path,dwParams);
    else
      fprintf(1,'DTI already processed for %s, %s\n',subids{s},sess{ss});
%       dt6fname = {fullfile(dtidir(1).folder,dtidir(1).name)};
    end
%     dt6 = load(dt6fname{1});

  end % for ss=sess
end % for s=subids
