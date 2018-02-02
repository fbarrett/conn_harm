% use FS to generate and register cortical surfaces to 1000 connectome
% 
%   - reconstruct subject
%   - register subject to fsaverage5
%   - mri_surf2surf -src fsaverage.white -trg subject.white
%   - dtrecon --b bvecs bvals --i <file> --s <subj> --o <outpath>
%   - register subject's DTI to subject.white
% 
% fbarrett@jhmi.edu

% initialize variables
datapath = '/Users/fbarrett/Documents/data/1305/anat';
fsspath = '/Applications/freesurfer/subjects';
fs5path = fullfile(spath,'fsaverage5');
subids = {'agg751','jfg716'
h={'l','r'};

reconcmd = 'recon-all -s %s -i %s -all'; % <subid> <MPRAGE>
regcmd = 'mris_register %s %s %s'; % <surfname> <tgt> <outname>
% mris_register agg751/surf/lh.sphere fsaverage5/lh.reg.template.tif
% agg/surf/lh.fsaverage5.sphere.reg
qccmd = 'recon-all -s %s -qcache -target %s'; % <subid> <tgt>
s2scmd = ['mri_surf2surf --s %s --hemi %sh --sval-xyz white '...
    '--trgsubject %s --tval %sh.white.%s --tval-xyz %s/mri/orig.mgz'];

trg = 'fsaverage5';

for s=subids
  % realign DTI
  D = spm_select('ExtList',dwipath,'.*DTI.*.nii',1:34);
  cd(dwipath);
  D = spm_realign(D,struct('interp',4));
  D = spm_reslice(D);

  % realign RSFC
  R = spm_select('ExtList',funcpath,sprintf('%s.*rest.*nii',1:1000));
  cd(funcpath);
  R = spm_realign(R,struct('interp',4));
  R = spm_reslice(R);
  
  % get T1
  t1dirs = dir(fullfile(datapath,[s{1} '.*mprage.*nii']));
  if isempty(t1dirs), continue, end
  
  t1path = fullfile(datapath,t1dirs(end).name);
  if ~exist(t1path,'file'), continue, end

  % coregister RSFC, DTI, MPRAGE
  Vt1 = spm_vol(t1path);
  Vsrc = spm_vol([D;R]);
  
  x = spm_coreg(Vt1,Vsrc);
  
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

  % resample the reconstructions onto the template
  qcstr = sprintf(qccmd,s{1},trg);
  [status,result] = unix(qcstr);
  if status
    warning(result);
    continue
  end % if status
  
  % resample white matter surface to the template
  for hh=h
    s2sstr = sprintf(s2scmd,s{1},hh{1},trg,hh{1},s{1},s{1});
    [status,result] = unix(s2sstr);
    if status
      warning(result);
      continue
    end % if status
  end % for hh=h
  
  % extract coordinates for each vertex in native space
  
    
end % for s=subids
