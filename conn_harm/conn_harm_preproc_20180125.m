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
% 
% fbarrett@jhmi.edu

%% initialize variables

% FS variables
datapath = '/Users/fbarrett/Documents/data/1305/anat';
fsspath = '/Applications/freesurfer/subjects';
fs5path = fullfile(fsspath,'fsaverage5');
subids = {'agg751','jfg716'};
h={'l','r'};

reconcmd = 'recon-all -s %s -i %s -all'; % <subid> <MPRAGE>
regcmd = 'mris_register %s %s %s'; % <surfname> <tgt> <outname>
% mris_register agg751/surf/lh.sphere fsaverage5/lh.reg.template.tif
% agg/surf/lh.fsaverage5.sphere.reg
% qccmd = 'recon-all -s %s -qcache -target %s'; % <subid> <tgt>
s2scmd = ['mri_surf2surf --s %s --hemi %sh --sval-xyz white '...
    '--trgsubject %s --tval %sh.white.%s --tval-xyz %s/mri/orig.mgz'];
m2acmd = 'mris_convert %s/%sh.white.fsaverage5 %s/%sh.white.fsaverage5.asc';

trg = 'fsaverage5';

% mrDiffusion variables
cwd = pwd;

dtiroot = '/Users/fbarrett/Documents/data/1305/dti/';
dwParams = dtiInitParams('bvecsFile',fullfile(dtiroot,'bvecs'),...
    'bvalsFile',fullfile(dtiroot,'bvals'),...
    'bsplineInterpFlag',true,...
    'eddyCorrect',-1,...
    'phaseEncodeDir',2,'outDir',dtiroot);

bvaldata = load(dwParams.bvalsFile);
bvalsize = length(bvaldata);

% make sure SPM is on the path
spm12_init;

%% process the work
for s=subids
  cwd=pwd;
  
  % % % use FS to process structural image, generate and register surfaces
  % get T1
  t1dirs = dir(fullfile(datapath,[s{1} '.*mprage.*BET.nii']));
  if isempty(t1dirs)
    t1dirs = dir(fullfile(datapath,[s{1} '.*mprage.*nii']));
    if isempty(t1dirs), error, end
    t1path = fullfile(datapath,t1dirs(end).name);
    if ~exist(t1path,'file'), error, end
    [fp,fn,fx] = fileparts(t1path);
  
    % BET
    cd(fp);
    betstr = sprintf('bet %s %s_BET%s -f 0.1',t1path,fn,fx);
    [status,result] = unix(betstr);
    if status
      warning(result);
      continue
    end % if status
    cd(cwd);
    
    t1dirs = dir(fullfile(datapath,[s{1} '.*mprage.*BET.nii']));
  end % if isempty(t1dirs
  t1path = fullfile(datapath,t1dirs(end).name);
  if ~exist(t1path,'file'), error, end

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
    surfname = sprintf('%s/surf/%h.sphere',s{1},hh{1});
    regtrg = sprintf('%s/%sh.reg.template.tif',trg,hh{1});
    outname = sprintf('%s/surf/%sh.%s.sphere.reg',s{1},hh{1},trg);
    regstr = sprintf(regcmd,surfname,regtrg,outname);
    
    [status,result] = unix(regstr);
    if status
      warning(result);
      continue
    end % if status
  end % for hh=h
  
  % resample white matter surface to the template, extract coordinates for
  % each vertex in native space
  surfpath = fullfile(fsspath,s{1},'surf');
  for hh=h
    % resample
    s2sstr = sprintf(s2scmd,s{1},hh{1},trg,hh{1},s{1},s{1});
    [status,result] = unix(s2sstr);
    if status
      warning(result);
      continue
    end % if status
    
    % convert
    m2astr = sprintf(m2acmd,surfpath,hh{1},surfpath,hh{1});
    [status,result] = unix(m2astr);
    if status
      warning(result);
      continue
    end % if status
  end % for hh=h
  
  % % %     coregister EPI to MPRAGE
  
  % % %     normalize DTI to EPI
  
  % % % use mrDiffusion to preprocess DTI data
  sdir = sprintf('sub-%s',upper(s{1}));
  dtifname = fullfile(dtiroot,sdir,'ses-Session4','dwi',...
      '20150317_094441WIPDTIHR22SENSEs1301a013.nii');
  t1fname = fullfile(dtiroot,sdir,'ses-Session4','dwi',...
      'jed716_wip_mprage_1mm_sense_fsl_12_1_BET.nii');
  
  dwParams.outDir = fileparts(dtifname);

  % get file parts
  [fp,fn,fx] = fileparts(dtifname);

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

  fprintf(1,'DTI filename: %s\nT1 filename: %s\n',dtifname,t1fname);

  % change directory to the parent of dtifname, so that output from
  % mrDiffusion goes into this directory
  cd(fileparts(dtifname));

  [dt6fname,outBaseDir] = dtiInit(dtifname,t1fname,dwParams);

end % for s=subids
