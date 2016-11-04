function batchInfo = spmPrep_run(sessionsDirectory,batchOptions)
%% spmPrep_options  Lucas Rosen 10/28/16
% Sorts fMRI image directories, moves files into correct places for
% preproccessing, and creates structure with parameters needed to fill the 
% batch to preproccess
% 
% Inputs:
%   sessionsDirectory -- directory containing fMRI sessions folders
%   batchOptions -- structure containing info about:
%       1. template batch files to use for preproccessing
%       2. files that contain frames with no scans
%       3. whether or not to search all files
%       4. tissue reference file to use for preproccessing
%
% Outputs:
%   batchInfo - structure containing info neccessary for preproccessing


batchInfo=struct(); %this is output of function
sessions={'/Users/lrosen/Documents/Sessions/E/Screening','/Users/lrosen/Documents/Sessions/CEC761/Baseline'};
%also hardcoded, but will be generated in part 1
%%batchInfo.sessionsDirectory=sessionsDirectory;

%% Part 1 - Identify Directories that need to be sorted/preprocced, or simply preprocced
% It is always possible that those using this program run into issues in the future with images from new MRI
% sources that have to be identified in different ways, but hopefully the
% code is clear enough that it will be enough for anyone to add in new
% parameters that define how to identify which source their MRI comes from
% as well as their own sorting methods

%this is the hardest part so I will do it last 
%will output a list directories that need to be preprocced
    %logic behind this 
        %1. if it was sorted it needs to be preprocced
        %2. if it had already been sorted but contained no files starting
        %with swr in the epi directory then it must be sorted
        %3. could also have case where there are some but not all swr files
        %but i don't truly see how this could happen but perhaps i will
        %code it in anyway
batchInfo.sessions=sessions;

%% Part 2 - put batch into working dir 
spmPrepPath=strcat(fileparts(which('spmPrep_run'))); %retrieve spm path
if ~isfield(batchOptions,'template') %if there is no template use defualt
    batchPath=fullfile(spmPrepPath,'batch.mat'); 
    batchInfo.usedDefaulBatch=0;
else
    if class(batchOptions.template~='char'
        disp('Template batch file inputted incorrectly, using default');
        batchPath=fullfile(spmPrepPath,'batch.mat'); 
        batchInfo.usedDefaulBatch=0;

    else
        batchPath=batchOptions.template;
        batchInfo.usedDefaultBatch=1;
    end
end

for i=1:length(sessions);
        copyfile(batchPath,char(sessions(i))); %move the batch file into the session directories
end
disp('Batch files copied');
batchInfo.pathToTemplateBatch=batchPath;
%% Part 3 - In each session directory, go through and select frames needed for problematic files

%create default structure for fMRI psilocybin studies, if this program is
%used in the future these lines will likely be modified

%check in on user's input of searchAll
if isfield(batchOptions,'searchAll')
    if class(batchOptions.searchAll)=='double'
        if ~(batchOptions.searchAll==0 || batchOptions.searchAll==1)
            disp('Search all frames inputted incorrectly. Will only search "music"');
            batchOptions.searchAll=0;
        end
    elseif class(batchOptions.searchAll=='char')
        if str2double(batchOptions.searchAll)==0 || str2double(batchOptions.searchAll)==1
            batchOptions.searchAll=str2double(batchOptions.searchAll);
        else
            disp('Search all frames inputted incorrectly. Will only search "music"');
            batchOptions.searchAll=0;
        end
    else
        disp('Search all frames inputted incorrectly. Will only search "music"');
        batchOptions.searchAll=0;
    end
end

badFrames=struct();
badFrames.fileNums={};

if ~isfield(batchOptions,'badFrames');
    badFrames.keywords={'music'};
else
    if class(batchOptions.badFrames)=='cell'
        badFrames.keywords=batchOptions.badFrames';
    elseif class(batchOptions.badFrames)=='char'
        badFrames.keywords{1}=batchOptions.badFrames;
    else
        disp('Keywords inputted incorrectly, using default "music"');
        badFrames.keywords={'music'};
    end
end

if ~isfield(batchOptions,'searchAll') || (isfield(batchOptions,'searchAll') && batchOptions.searchAll==0)
    batchOptions.searchedAll=0;
    numBadFiles=0; %defines number of files that have erroneous frames, will be used in making matrix of files and frame numbers
    keyWords=badFrames.keyWords;
    warning('off','all') %scrolling through frames brings up annoying warnings
    if badFrames.searchAll==0 && ~isempty(keyWords) %if we shouldn't search for everything and there are defined key words
        for i=1:length(sessions) %go through all sessions
            epiPath=fullfile(char(sessions(i)),'epi');
                for j=1:length(keyWords); %go through all key words
                    wildCard=strcat(epiPath,'/*',char(keyWords(j)),'*.nii'); %% could be any 4d image format, but I only know of .nii
                    badFiles=dir(wildCard);
                    for k=1:length(badFiles) %% go through all files with erroneous frames
                        numBadFiles=numBadFiles+1;
                        fullPathtoBadFile=fullfile(epiPath,badFiles(k).name);
                        spm_check_registration(fullPathtoBadFile); %display 4d image so that user can scroll through frames, 
                        % issue with this is that the frame number isn't
                        % visible so I need to figure out a way to modify the
                        % graph
                    
                        %set up parameters for input box
                        inpnames='Input';
                        numlines=1;
                        defaultanswer={''};
                        options.WindowStyle='normal';
                    
                        %ask user how many relevant frames are in image and add
                        %to matrix only if they inputed a single number
                        relFrames = inputdlg(strcat('How many relevant frames are in this image ?'),inpnames,numlines,defaultanswer,options);
                        relFrames = str2num(relFrames{1});
                        while isempty(relFrames) || ~isequal(size(relFrames),[1,1])
                            relFrames = inputdlg(strcat('Please input a single number. How many relevant frames are in this image ?'),inpnames,numlines,defaultanswer,options);
                            relFrames = str2num(relFrames{1});   
                        end
                        %create matrix containing directory, file name, and
                        %relevant frames for each file that must be checked
                        badFrames.filenums{1,numBadFiles}=sessions(i);
                        badFrames.filenums{2,numBadFiles}=badFiles(k).name;
                        badFrames.filenums{3,numBadFiles}=relFrames;
                    end
                end
        end
    end
elseif (isfield(batchOptions,'searchAll') && batchOptions.searchAll==1)
    batchOptions.searchedAll=1;
    %% add commands to search thru all files
close(gcf);
batchInfo.badFrames=badFrames;
warning('on'); %turn warnings back on
%% Part 4 - Tissue baseline file selection (default or user-input)

%if naragin<4 or something like this
batchInfo.usedDefaultTissue=1;
spmPath=strcat(fileparts(which('spmPrep')));
tissuePath=fullfile(spmPath,'tpm','TPM.nii');
batchInfo.tissuePath=tissuePath;

%% Part 5 - Fill Batch file
for i=1:length(sessions)
    load(char(fullfile(sessions(i),'batch.mat')));
    matlabbatch{1, 1}.spm.spatial.realign.estimate.data=[];
    %fill in data for realign, will do no dict case then add that later
    runsTemp=dir(char(fullfile(sessions(i),'epi','*nii')));
    numRuns=length(runsTemp);
    estimateData=cell(1,numRuns);
    for j=1:numRuns
        thisName=fullfile(sessions(i),'epi',runsTemp(j).name);
        thisVol=spm_vol(thisName);
        thisFrames=length(thisVol{1,1});
        thisCell=cell(thisFrames,1);
        for k=1:thisFrames
            thisCell{k,1}=char(strcat(thisName,',',num2str(k)));
        end
        estimateData{1,j}=thisCell;
    end
    matlabbatch{1, 1}.spm.spatial.realign.estimate.data=estimateData;
    
    %fill in hires data
    hiResMult=dir(char(fullfile(sessions(i),'hires','*mprage*.nii')));
    if length(hiResMult)==1;
        hires=hiResMult.name;
    else %in all cases I know of the file with the shortest name is the one we want to we will search for that
        shortestNum=length(hiResMult(1).name);
        shortestName=hiResMult(1).name;
        for j=1:length(hiResMult);
            cur=length(hiResMult(j).name);
            if cur<shortestNum
                shortestNum=length(hiResMul(j).name);
                shortestName=hiResMult(j).name;
            end
        end
    hires=shortestName;
    end
    matlabbatch{1, 2}.spm.spatial.coreg.estwrite.ref{1, 1}=char(fullfile(sessions(i),'hires',strcat(hires,',1')));
    matlabbatch{1, 3}.spm.spatial.preproc.channel.vols{1, 1}=char(fullfile(sessions(i),'hires',strcat(hires,',1')));
    
    %fill in 'other images'
    templatePath=fullfile(spmPrepPath,'template.mat');
    load(templatePath);
    for j=1:numRuns
        matlabbatch{1, 2}.spm.spatial.coreg.estwrite.other(1, i)=template;
        matlabbatch{1, 2}.spm.spatial.coreg.estwrite.other(1, i).src_output(2).subs{1, 1}=i;
        tempText=char(strcat('Realign: Estimate: Realigned Images (Sess ',{' '},num2str(i),')'));
        matlabbatch{1, 2}.spm.spatial.coreg.estwrite.other(1, i).sname=tempText;
    end
    matlabbatch{1, 2}.spm.spatial.coreg.estwrite.other=matlabbatch{1, 2}.spm.spatial.coreg.estwrite.other(1:numRuns);
    
    %fill in tissue probability map index
    %will use struct so will do it later
    
    %save matlabbatch
    newFilePath=fullfile(char(sessions(i)),'batch');
    save(newFilePath,'matlabbatch');
end
    

%% Part 6 - Run Spm Preproccessing