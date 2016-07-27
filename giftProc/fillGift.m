%%function fillIt=fillGift() %% will have it input path but for now won't do that
load gift_Template.mat;
cd('/Users/lrosen/Documents/SEW732/Session2'); %%temporary
cd('analyses')
%% easier to not do for loop so this is for gift_20
cd('gift_20');
gift_Template.userInput.pwd=pwd;
gift_Template.userInput.prefix=strcat('gift_20');
gift_Template.userInput.param_file=strcat(pwd,'/gift_20_ica_parameter_info.mat');
cd('../../epi');
restings=dir('swr*rest*.nii'); %%possibly add workaround for kki files
resting=restings.name;
v=spm_vol(resting);
frames=length(v);
cellFrames=cell(frames,1);
for j=1:frames;
    cellFrames{j,1}=strcat(pwd,'/',resting,',',num2str(j));
end;
charFrames=char(cellFrames);
gift_Template.userInput.files.name=charFrames;
gift_Template.userInput.diffTimePoints=frames;
gift_Template.userInput.numComp=20;
gift_Template.userInput.numOfPC1=20;
gift_Template.userInput.HInfo.V.fname=strcat(pwd,'/',resting);
%have to do the calculated ones next but will do later
sesInfo=gift_Template;
clearvarlist = ['clearvarlist';setdiff(who,{'sesInfo'})];
clear(clearvarlist{:}); 
cd('../analyses/gift_20')
save('gift_20_ica_parameter_info.mat');
clear sesInfo
%% gift_70
folderToo=mfilename('fullpath')
folder=fileparts(folderToo)
cd('folder')
load gift_Template.mat;
cd('/Users/lrosen/Documents/SEW732/Session2'); %%temporary
cd('analyses')
cd('gift_70');
gift_Template.userInput.pwd=pwd;
gift_Template.userInput.prefix=strcat('gift_70');
gift_Template.userInput.param_file=strcat(pwd,'/gift_70_ica_parameter_info.mat');
cd('../../epi');
restings=dir('swr*rest*.nii'); %%possibly add workaround for kki files
resting=restings.name;
v=spm_vol(resting);
frames=length(v);
cellFrames=cell(frames,1);
for j=1:frames;
    cellFrames{j,1}=strcat(pwd,'/',resting,',',num2str(j));
end;
charFrames=char(cellFrames);
gift_Template.userInput.files.name=charFrames;
gift_Template.userInput.diffTimePoints=frames;
gift_Template.userInput.numComp=70;
gift_Template.userInput.numOfPC1=70;
gift_Template.userInput.HInfo.V.fname=strcat(pwd,'/',resting);
%have to do the calculated ones next but will do later
sesInfo=gift_Template;
clearvarlist = ['clearvarlist';setdiff(who,{'sesInfo'})];
clear(clearvarlist{:}); 
cd('../analyses/gift_70')
save('gift_70_ica_parameter_info.mat');
clear sesInfo
