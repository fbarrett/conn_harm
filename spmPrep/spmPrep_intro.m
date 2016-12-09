function batchOptions = spmPrep_intro(varargin)
%% spmPrep_intro  Lucas Rosen 10/28/16
% creates structure batchOptions to be used in spmPrep run
% Inputs:
%   varargin - can contain inputs about
%       1. 'template' - template batch file - give path to template 
%       2. 'searchAll' - whether to search all files for bad frames - give
%           0 for no or 1 for yes
%       3. 'keywords' - keywords for files with bad frames. Note that if 
%           searchAll is 1, this program will ignore keywords - give cell
%           array of keywords or single string keyword
%       4. 'tissue' - tissue reference file - give path to tissue reference
%           file
% 
% Each option has a default input which will be used if no input is given or input is 'default' 
% Defaults:
%   'template' - batch.mat inside spmPrep folder
%   'searchAll' - 0 (do not search all)
%   'keywords' - 'music'
%   'tissue' - TPM.nii image inside TPM folder of spm directory
%
% To prompt user input, type 'UserInput' as the option after the input
%
% Usage example
% batchOptions = spmPrep_intro('searchAll',0,'badFrames',{'music','numbers'},'tissue','UserInput')
%   This creates batchOptions using the default batch file, instructions to
%   search files with keywords - music or numbers - for badFrames, but not
%   all files, and will prompt the user to select the tissue reference file
%
% Outputs:
%   batchOptions - structure with options to use in spmPrep run based on
%   inputs
%
%%
%set all as default to begin and can change later if neccessary
batchOptions=struct();
userInput={};
manualInput={};
searchAll=[];
if nargin %if there is input
    %Go through varargin and see what is there, what isn't, and what needs to be user inputted
    for i=1:2:nargin
        if isa(varargin{i+1},'char') && strcmp(varargin{i+1},'UserInput')
            userInput(end+1)={varargin{i}};
        else
            manualInput(end+1,:)={varargin{i},varargin{i+1}};
        end
    end
            
end

%first creates batchOptions stuct from manual input
if ~isempty(manualInput)
    batchOptions=cell2struct(cell(length(manualInput),1),manualInput(:,1),1);
    names=fieldnames(batchOptions);
    numFields=numel(names)
    for i=1:numFields
        manInp=manualInput(i,2)
        batchOptions.(names{i})=manInp{1};
    end 
end

%prompt user to input those that should be user inputted
if ~isempty(userInput)
    for i=1:length(userInput)
        if strcmp(userInput{i},'template') %select template file
            [templateBaseName, templateFolder] = uigetfile('*.mat');
            template = fullfile(templateFolder, templateBaseName);
            batchOptions.template=template;
        elseif strcmp(userInput{i},'searchAll') %find out if user wants all files searched
            searchAllText=inputdlg('Should all files be search for erroneous frames? (Select Yes or No)');
            while(isempty(searchAll))
                if strcmp(searchAllText,'Yes') || strcmp(searchAllText,'yes') || strcmp(searchAllText,'Y') || strcmp(searchAllText,'y') || strcmp(searchAllText,'1')
                    searchAll='1';
                    batchOptions.searchAll=searchAll;
                elseif strcmp(searchAllText,'No') || strcmp(searchAllText,'no') || strcmp(searchAllText,'N') || strcmp(searchAllText,'n') || strcmp(searchAllText,'0')
                    searchAll='0';
                    batchOptions.searchAll=searchAll;
                else
                    searchAllText=inputdlg('Did not understand input, please select yes or no.');
                end
            end
        elseif strcmp(userInput{i},'keywords') %get list of keywords to select files in
            if searchAll==1
                disp('All files will be searched.');
            else
                keysString=char(inputdlg(sprintf('Input list of keywords in files with erroneous frames.\nThis list should be separated by commas.\nExample: music, cats, dogs')));
                keysString(keysString==' ') = '';
                badFrames=strsplit(keysString,',');
                batchOptions.badFrames=badFrames';
            end
        elseif strcmp(userInput{i},'tissue') %get path to tissue file
            [tissueBaseName, tissueFolder] = uigetfile('*.nii');
            tissue = fullfile(tissueFolder, tissueBaseName);
            batchOptions.tissue=tissue;
        else
            disp(strcat('Option:', userInput{i} ,' not found'));
        end
    end        
end