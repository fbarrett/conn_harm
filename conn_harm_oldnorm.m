function normed_output = conn_harm_oldnorm(rDWIfiles,rrEPIfiles)

% normalize realigned DWI files to an EPI file coreg'd to T1 anatomical
% 
%   normedpath = norm_dwi_to_epi(rDWIfiles,rrEPIfile)
% 
% INPUT
%   rDWIfiles - cell str containing full paths to realigned DWI files
%   rrEPIfiles - cell str containing full path to EPI files that has been
%       realigned and coregistered to the T1 anatomical
% 
% OUTPUT
%   normedpath - paths DWI files tha thave been normalized to the EPI
% 
% fbarrett@jhmi.edu 2018.01.31

%% spm setup
spm('defaults','fmri');
spm_jobman('initcfg');

%% first realigned DWI file
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.source = rDWIfiles(1);
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';

%% all realigned DWI files
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.resample = rDWIfiles;

%% add coregistered EPI
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.template = rrEPIfiles;

%% additional settings
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 4;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smoref = 4;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.bb = [-78 -112 -70
                                                         78 90 85];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.vox = [2 2 2];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w';

%% run the job!
normed_output = spm_jobman('run',matlabbatch);
