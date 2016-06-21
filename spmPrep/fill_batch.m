function fill = fill_batch(myDir)

%% introductory stuff
cd(myDir);
load batch.mat;
musicnum=textread('music.txt','%d');
need=myDir;
path=cd('../');
currentDirectory = pwd;
[upperPath, working, ~] = fileparts(currentDirectory); 
working=lower(working);
cd(path);

%% filling data for realign
cd('epi');
rest=cell(210,1);
med1=cell(123,1);
med2=cell(123,1);
med3=cell(123,1);
music=cell(musicnum,1);
for i= 1:musicnum;
    music{i,1}=strcat(need,'/epi/',working,'_wip_music1_sense_fsl_11_1.nii,',num2str(i));
end
for i = 1:210;
    if i>123;
        rest{i,1}=strcat(need,'/epi/',working,'_wip_resting_state_sense_fsl_5_1.nii,',num2str(i));
    else
        rest{i,1}=strcat(need,'/epi/',working,'_wip_resting_state_sense_fsl_5_1.nii,',num2str(i));
        med1{i,1}=strcat(need,'/epi/',working,'_wip_med1_sense_fsl_6_1.nii,',num2str(i));
        med2{i,1}=strcat(need,'/epi/',working,'_wip_med2_sense_fsl_7_1.nii,',num2str(i));
        med3{i,1}=strcat(need,'/epi/',working,'_wip_med3_sense_fsl_8_1.nii,',num2str(i));
    end
end
matlabbatch{1, 1}.spm.spatial.realign.estimate.data{1,1}=rest;
matlabbatch{1, 1}.spm.spatial.realign.estimate.data{1,2}=med1;
matlabbatch{1, 1}.spm.spatial.realign.estimate.data{1,3}=med2;
matlabbatch{1, 1}.spm.spatial.realign.estimate.data{1,4}=med3;
matlabbatch{1, 1}.spm.spatial.realign.estimate.data{1,5}=music;
cd('..');

%% fill in hires
cd('hires');
var=strcat(working,'_wip_mprage*');
highres=dir(var);
hires=highres.name;
matlabbatch{1, 2}.spm.spatial.coreg.estwrite.ref{1, 1}=strcat(need,'/hires/',hires,',1');
matlabbatch{1, 3}.spm.spatial.preproc.channel.vols{1, 1}=strcat(need,'/hires/',hires,',1');
cd('..');

%% fill in tissue probability map input
if exist('tissue.txt','file')==2;
    tissuedir=textread('tissue.txt','%s');
    tissue=strcat(tissuedir,'/TPM.nii,');
    matlabbatch{1, 3}.spm.spatial.preproc.tissue(1).tpm=strcat(tissue,'1') ;
    for i=1:6
        matlabbatch{1, 3}.spm.spatial.preproc.tissue(i).tpm=strcat(tissue,num2str(i));
    end
    delete('tissue.txt');
%% save matlabbatch
end
batch=matlabbatch;
save('batch');