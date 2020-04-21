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
%   prefe
% 
%   NOTE: needs janatalab script cell2str
%
% fbarrett@jhmi.edu 2018.11.24
% 
% 2019.08.28: added code to rotate bvecs

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
fstrg = {'fsaverage5'};
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

% initialize mrDiffu;sion parameter structure
% bspline interpolation %%%ARBITRARY?
dwParamsMaster = dtiInitParams('bvecsFile',bvecspath,'bvalsFile',bvalspath,...
    'bsplineInterpFlag',true,'eddyCorrect',1,'phaseEncodeDir',2,...
    'excludeVols',34,'rotateBvecsWithRx',1);

% initialize SPM
spm12_init;
spm('defaults','fmri');
defs.realign.estimate = spm_get_defaults('realign.estimate');
defs.realign.estimate.prefix = 'r';
defs.realign.estimate.rtm=1;
defs.realign.estimate.interp=7;

  % add variables to describe slice timing correction? add to
  % preprocessing?

%% iterate over subjects, preprocess data
% iterate over subjects
parfor s=1:length(subids)
% for s=1:length(subids)
% for s=6
  subpath = fullfile(dataroot,subids{s});
  subid = regexprep(subids{s},'sub-','');

  % session directories are nested in subject directories
  sessdir = dir(subpath);           % get session directories
  sessdir(1:2) = [];                % remove '.' and '..'
  sessdir(~[sessdir.isdir]) = [];   % remove non-directory entries
  sess = {sessdir.name}';
  
  % iterate over sessions
%   if length(sess)>2 && ~strcmp('ses-Session2s',sess{3})
%     continue
%   end % if length(sst
  for ss=1:length(sess) %3:5 % for ss=3:5 % for ss=1:2 % 1:length(sess
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

    % use FS to reconstruct cortical surface from the T1 - THIS WILL TAKE A WHILE
    if ~exist(fullfile(sfspath,'surf',sprintf('lh.sphere')),'file')
      reconstr = sprintf(reconcmd,fssub,t1path);
      fprintf(1,'reconstructing cortical surfaces for %s (%s)\n',fssub,reconstr);
      [status,result] = unix(reconstr);
      if status
          warning(result);
          continue
      end % if status
    end % if ~exist(fullfile(fspath,fssub,'surf
    
    % register subject cortical surface to template surface
    % extract native vertex coordinates
    for tt=fstrg
      tgtpath = fullfile(fspath,tt{1});
      
      % register subject to template with FS mris_register
      [status,result] = conn_harm_fs_register(sfspath,tgtpath);
      if status, warning(result), continue, end
      
      % resample surf to template, create gifti, extract vertex coordinates
      [status,result] = conn_harm_resample(sfspath,tgtpath);
      if status, warning(result), continue, end
    end % for tt=fstrg
    
    % % %     coregister DWI, EPI to MPRAGE
    EPIfiles = spm_select('ExtFPList',fullfile(sesspath,'func_stc'),['^' lower(subid) '.*rest.*nii']);
    DWIfiles = spm_select('ExtFPList',fullfile(sesspath,'dwi'),'^201.*DTI.*nii');
    try
      % % %     realign DWI files
      realign_output = conn_harm_realign(cellstr(DWIfiles),cellstr(EPIfiles),t1path);
      
      % % %     normalize DTI to EPI
      normed_output = conn_harm_oldnorm(realign_output{1}.sess(1).rfiles,...
          realign_output{2}.rfiles(1)); % from realign_output

      % % %     realign/normalize bvecs
      % get raw DTI realignment matrix
      rotfiles = dir(fullfile(sesspath,'dwi','201*DTI*.mat'))
      for rf=1:length(rotfiles)
        if ~isempty(regexp(rotfiles(rf).name,'.*_sn.mat$')), continue, end
        [~,fn] = fileparts(rotfiles(rf).name);
        rfname = fullfile(rotfiles(rf).folder,[fn '.bvecs']);
        rotmat = load(fullfile(rotfiles(rf).folder,rotfiles(rf).name));
        % get bvecs
        bvecs = load(bvecspath);
        % rotate based on realignment
        bvecs = rotate_bvecs(bvecs,rotmat.mat);
        % get normalized DTI headers
        normed_params = load(normed_output{1}.params{1});
        % rotate based on normalized DTI headers
        bvecs = rotate_bvecs(bvecs,normed_params.Affine);
        % write out new rotated/realigned bvecs
        dlmwrite(rfname,bvecs,'delimiter','\t');
        % set new bvecs file in dwi analysis parameters
      end %   
    catch
      warning('PROBLEMS REALIGNING/NORMING %s, SKIPPING\n',fssub);
      continue
    end
        
    % REGISTER T1 TO DWI
    DWIdir = dir(fullfile(sesspath,'dwi','wr201*DTI*nii*'));
    if isempty(DWIdir)
      fprintf(1,'DTI not found at %s, SKIPPING\n',fullfile(sesspath,'dwi'));
      continue
    end % if isempty(DWIdir
    
        for d=1:length(DWIdir)
          % if .gz, unzip it
          [~,fn,fx] = fileparts(DWIdir(d).name);
          if strcmp(fx,'.gz')
            gunzipstr = sprintf('gunzip %s',DWIdir(d).name);
            [status,result] = unix(gunzipstr);
            if status
              warning(result);
              continue % if unsuccessful, move to next subject
            end % if status after gunzip
            dtifname = fullfile(DWIdir(d).folder,fn);
          else
            dtifname = fullfile(DWIdir(d).folder,DWIdir(d).name);
          end % if strcmp(fx,'gz

          % preprocess DWI
          dwParams = dwParamsMaster;
          dwParams.bvecsFile = fullfile(DWIdir(d).folder,[fn(3:end) '.bvecs']);
          dwParams.outDir = DWIdir(d).folder;

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
            dt6fname = {fullfile(dtidir(1).folder,dtidir(1).name)};
          end
          dt6 = load(dt6fname{1});      
        end % for d=1:length(DWIdir
  end % for ss=sess
end % for s=subids

fprintf(1,'DONE\n\n');
