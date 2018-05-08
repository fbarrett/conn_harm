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
%   NOTE: needs janatalab script cell2str
%
% fbarrett@jhmi.edu

%% initialize variables
% subids = {'AGG751'}; % these subjects will be processed
% subids = {'AMM755','CAH753','CEC761'}; % these subjects will be processed
% subids = {'CFL767','DCE745','DJH730','EWM768','GJM708','JAT763',...
%     'JRD722','MEG743','MP733','RDW746','RJL752','RZ_758','SEW732',...
%     'SHH709'};%,'TPM710'};'JLD740',
% subids = {'DCE745','EWM768','JAT763','JLD740','JRD722','MEG743',...
%     'MP733','RDW746','RJL752','RZ_758','SHH709'};

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
regcmd = 'mris_register %s %s %s'; % <surfname> <tgt> <outname>
s2scmd = ['mri_surf2surf --s %s --hemi %sh --sval-xyz %s '...
    '--trgsubject %s --tval %sh.%s.%s --tval-xyz %s/mri/orig.mgz'];
m2acmd = 'mris_convert %s/%sh.%s.%s %s/%sh.%s.%s.asc';
giicmd = 'mris_convert %s %s.gii';
a2lcmd = 'mri_annotation2label --subject %s --hemi %sh --outdir %s';
sccmd  = ['mri_surfcluster --in %s --clabel %s --sum %s --centroid '...
    '--thmin 0 --hemi %s --subject %s'];

% FSL commands
%   - use very low fractional intensity threshold (0.1?) %%%ARBITRARY?
betcmd = 'bet %s %s_BET%s -f 0.1';

% mrDiffusion variables
bvecspath = '/g4/rgriffi6/1305_working/bvecs';
bvalspath = '/g4/rgriffi6/1305_working/bvals';
bvalsize = length(load(bvalspath));

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
for s=1:length(subids)
% parfor s=1:length(subids)
  subpath = fullfile(dataroot,subids{s});
  subid = regexprep(subids{s},'sub-','');

  % session directories are nested in subject directories
  sessdir = dir(subpath);           % get session directories
  sessdir(1:2) = [];                % remove '.' and '..'
  sessdir(~[sessdir.isdir]) = [];   % remove non-directory entries
  sess = {sessdir.name}';
  
  % iterate over sessions
%   for ss=sess
  for ss=1:2 % 1:length(sess
%   for ss=1
    cwd=pwd;
    
    sesspath = fullfile(subpath,sess{ss});
    fssub = [subid '-' sess{ss}];
    
    % get skull-stripped T1
    t1dirs = dir(fullfile(sesspath,'anat',[lower(subid) '*mprage*BET.nii']));
    if isempty(t1dirs)
      fprintf(1,'no skull-stripped T1 for %s, making one\n',fssub);
      
      % if there isn't a skull-stripped image, make one
      t1dirs = dir(fullfile(sesspath,'anat',[lower(subid) '*mprage*nii']));
      if isempty(t1dirs)
        warning('No t1 for %s %s, SKIPPING\n',subid,sess{ss});
        continue
      end
      t1path = fullfile(sesspath,'anat',t1dirs(end).name);
      [fp,fn,fx] = fileparts(t1path);
  
      % FSL BET
      if ~exist(fp,'dir')
        fprintf(1,'%s not found, SKIPPING\n',fp);
        continue
      end % if ~exist(fp,'dir
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
    
      t1dirs = dir(fullfile(sesspath,'anat',[lower(subid) '*mprage*BET.nii']));
    end % if isempty(t1dirs
    
    t1path = fullfile(sesspath,'anat',t1dirs(end).name);
    if ~exist(t1path,'file')
      warning('%s not found, SKIPPING\n',t1path)
      continue
    end
    
    % SET ORIGIN ON T1 IMAGE
    nii_setOrigin(t1path,1);

    % use FS to reconstruct cortical surface - THIS WILL TAKE A WHILE
    if ~exist(fullfile(fspath,fssub,'surf',sprintf('lh.sphere')),'file')
      reconstr = sprintf(reconcmd,fssub,t1path);
      fprintf(1,'reconstructing cortical surfaces for %s (%s)\n',fssub,reconstr);
      [status,result] = unix(reconstr);
      if status
          warning(result);
          continue
      end % if status
    end % if ~exist(fullfile(fspath,fssub,'surf
    
    for hh=h % for each hemisphere ...

      for tt=fstrg
          
        % register subject to template with FS mris_register
        surfname = fullfile(fspath,fssub,'surf',sprintf('%sh.sphere',hh{1}));
        regtrg = fullfile(fspath,tt{1},sprintf('%sh.reg.template.tif',hh{1}));
        outname = fullfile(fspath,fssub,'surf',sprintf('%sh.%s.sphere.reg',hh{1},tt{1}));
        regstr = sprintf(regcmd,surfname,regtrg,outname);

        if ~exist(outname,'file')
          fprintf(1,'registering %s to template for %sh\n',fssub,hh{1});
        
          [status,result] = unix(regstr);
          if status
            warning(result);
            continue % if unsuccessful, move to next subject
          end % if status
        end % if ~exist(outname,'file
      
        % resample surface to the template, extract coordinates for each
        % vertex in native space, create gifti
        for sss=1:length(surfs) % for each surface ...
          % resample?
          if ~exist(fullfile(fspath,tt{1},'surf',sprintf('%sh.%s.%s',...
                  hh{1},surfs{sss},fssub)),'file')
            fprintf(1,'resampling %sh %s to template for %s\n',hh{1},surfs{sss},fssub);

            % resample
            s2sstr = sprintf(s2scmd,fssub,hh{1},surfs{sss},tt{1},hh{1},surfs{sss},...
                fssub,fullfile(fspath,fssub));
            [status,result] = unix(s2sstr);
            if status
              warning(result);
              continue % if unsuccessful, move to next subject
            end % if status
            
            % create gifti
            giipath = fullfile(fspath,tt{1},'surf',...
                sprintf('%sh.%s.%s',hh{1},surfs{sss},fssub));
            giistr = sprintf(giicmd,giipath,giipath);
            [status,result] = unix(giistr);
            if status
              warning(result);
              continue
            end % if status
          end % if ~exist(fullfile(fspath,tt{1},sprintf('...

          % convert surface to ascii?
          if ~exist(fullfile(fspath,tt{1},sprintf('%sh.%s.%s.asc',...
                  hh{1},surfs{sss},fssub)),'file')
            fprintf(1,'convert %sh %s to ascii for %s\n',hh{1},surfs{sss},fssub);

            m2astr = sprintf(m2acmd,fullfile(fspath,tt{1},'surf'),hh{1},surfs{sss},...
                fssub,fullfile(fspath,tt{1},'surf'),hh{1},surfs{sss},fssub);
            [status,result] = unix(m2astr);
            if status
              warning(result);
              continue % if unsuccessful, move to next subject
            end % if status
          end % if ~exist(fullfile(fspath,fstrg,sprint-f('%sh.%s.%s.asc...

        end % for sss=surfs
      end % for tt=fstrg
    end % for hh=h
      
    % extract Deskian coordinates
%           a2lcmd = 'mri_annotation2label --subject %s --hemi %sh --outdir %s';
    aparcpath = fullfile(fspath,fssub,'aparc');
    if ~exist(aparcpath,'dir')
      fprintf(1,'Deskian coordinates for %s\n',fssub);
      
      for hh=h
        a2lstr = sprintf(a2lcmd,fssub,hh{1},aparcpath);
        [status,result] = unix(a2lstr);
        if status
          warning(result);
          continue
        end
      end % for hh=h

      aparcdir = dir(aparcpath);
      for ap=1:length(aparcdir)
        if aparcdir(ap).isdir, continue, end
        parc = regexp(aparcdir(ap).name,'(\w*)\.(\w*)\.(\w*)','tokens');
        tmppath = fullfile(fspath,fssub,'surf',[parc{1}{1} '.thickness']);
        sumpath = fullfile(fspath,fssub,'sums',['sum.' aparcdir(ap).name]);
        if ~exist(fileparts(sumpath),'dir')
          mkdir(fileparts(sumpath));
        end % if ~exist(fileparts(sumpath),'dir

        labpath = fullfile(aparcpath,aparcdir(ap).name);
        scstr = sprintf(sccmd,tmppath,labpath,sumpath,parc{1}{1},fssub);
        [status,result] = unix(scstr);
        if status
          warning(result);
          continue
        end
      end % for ap=1:length(aparcdir
%       sccmd  = ['mri_surfcluster --in %s --clabel %s --sum sum.%s --centroid '...
%           '--thmin --hemi %sh --subject %s'];
      
    end % if ~exist(Fullfile(fspath,fssub,'apart          

    continue
    
    % % %     coregister EPI to MPRAGE
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
  
    % get file parts
    [fp,fn,fx] = fileparts(dtifname);

    % PHILIPS appends an average DW image to the end ... we need to remove
    % this image
    V = niftiRead(dtifname);
    if V.dim(4) > bvalsize
      % check to see if a reduced file exists
      if ~exist(fullfile(fp,[fn '_reduced' fx]),'file')
        % create a reduced file
    
        % change directory into the volunteer's directory
        if ~exist(fp,'dir')
          fprintf(1,'%s not found, SKIPPING\n',fp);
          continue
        end % if ~exist(fp,'dir
        cd(fp);

        % split the file into one file per volume
        splitstr = ['fslsplit ' fn fx];
        fprintf(1,'splitting file (%s)\n',splitstr);
        [status,result] = unix(splitstr);
        if status, error(result); end
        
        pause(5);
  
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
      [fp,fn,fx] = fileparts(dtifname);
    end % if length(V) > bvalsize

    fprintf(1,'DTI filename: %s\nT1 filename: %s\n',dtifname,t1path);

    % change directory to the parent of dtifname, so that output from
    % mrDiffusion goes into this directory
    if ~exist(fileparts(dtifname),'dir')
      fprintf(1,'%s not found, SKIPPING\n',fileparts(dtifname));
      continue
    end % if ~exist(fp,'dir
    cd(fileparts(dtifname));

    % set up mrDiffusion analysis variables
    dtidir = dir(fullfile(fp,'**','dt6.mat'));
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
