%%kki sort 2.0

% sort data for the KKI project
% LR 2016.10.03
inpath=pwd;
sortdefs=struct();
sortdefs.dcm2nii = 1;
sortdefs.directories.epi = {'*med*.nii','*music*.nii','*rest*.nii'};
sortdefs.directories.hires = {'mprage'};

sort_nidata(inpath,sortdefs)

