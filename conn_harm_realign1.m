function realign_output = conn_harm_realign1(files)

% realign files using SPM
% 
%   realign_output = realign(EPIfiles,DWIfiles,T1files)
% 
% INPUT
%   EPIfiles, DWIfiles, T1file - paths to raw files on disk
% 
% OUTPUT
%   realign_output - spm_jobman output from realign/coregister
% 
% fbarrett@jhmi.edu 2018.01.31

%% spm setup
spm('defaults','fmri');
spm_jobman('initcfg');

%% add raw DWI and EPI files
matlabbatch{1}.spm.spatial.realign.estwrite.data = {DWIfiles EPIfiles};

%% add T1 file
matlabbatch{2}.spm.spatial.coreg.estwrite.ref = {T1file};
matlabbatch{2}.spm.spatial.coreg.estwrite.source(1) = ...
    cfg_dep('Realign: Estimate & Reslice: Resliced Images (Sess 2)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{2}, '.','rfiles'));
matlabbatch{2}.spm.spatial.coreg.estwrite.other(1) = ...
    cfg_dep('Realign: Estimate & Reslice: Resliced Images (Sess 2)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{2}, '.','rfiles'));

%% realign settings
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 7;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 7;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 0; %% !!
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

%% coreg settings
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.interp = 7;
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';


%% run the job!
realign_output = spm_jobman('run',matlabbatch);
