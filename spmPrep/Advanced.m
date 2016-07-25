function varargout = Advanced(varargin)
% Advanced MATLAB code for Advanced.fig
%      Advanced, by itself, creates a new Advanced or raises the existing
%      singleton*.
%
%      H = Advanced returns the handle to a new Advanced or the handle to
%      the existing singleton*.
%
%      Advanced('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in Advanced.M with the given input arguments.
%
%      Advanced('Property','Value',...) creates a new Advanced or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Advanced_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Advanced_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Advanced

% Last Modified by GUIDE v2.5 25-Jul-2016 13:29:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Advanced_OpeningFcn, ...
                   'gui_OutputFcn',  @Advanced_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Advanced is made visible.
function Advanced_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Advanced (see VARARGIN)

% Choose default command line output for Advanced
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Advanced wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Advanced_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
evalin('base', 'clear *8904');
[filename8904, pathname8904, filterindex] = uigetfile('*.mat');
assignin('base','filename8904',filename8904);
assignin('base','pathname8904',pathname8904);
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
p = mfilename('fullpath');
fileDirectory = fileparts(p);
cd(fileDirectory);
dname8904 = uigetdir(pwd);
assignin('base','dname8904',dname8904);
try
    if exist(evalin('base','pathname8904'))==7
        pathname8904=evalin('base','pathname8904');
        filename8904=evalin('base','filename8904');
    end
    catch
        pathname8904=strcat(pwd,'/');
        filename8904='default_batch.mat';
end
copyfile(strcat(pathname8904,filename8904),dname8904);
curDir = pwd;
cd(dname8904);
if strcmp(filename8904,'batch.mat')==0
    movefile(filename8904,'batch.mat');
end
cd(curDir);
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
[baseName, folder] = uigetfile('*.m');
cur=pwd;
dname8904=evalin('base','dname8904');
cd(dname8904);
path=strcat(folder,baseName);
copyfile(path,dname8904);
run(baseName);
cd(cur);
msgbox('Files Formatted');
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
dname8904=evalin('base','dname8904');
fid=fopen(strcat(dname8904,'/dict.txt'),'w');
frames = inputdlg('Enter Session Keywords Separated by Commas');
fprintf(fid,'%s',frames{1});
fclose(fid);
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
[baseName, folder] = uigetfile('*.nii');
fullFileName = fullfile(folder, baseName);
dname8904=evalin('base','dname8904');
fid=fopen(strcat(dname8904,'/tissue.txt'),'w');
fprintf(fid,'%s',fullFileName);
fclose(fid);
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
dname8904=evalin('base','dname8904');
cd(dname8904);
a=dir();
num=size(a);
names=num(1);
for i=1:names;
    name=a(i).name;
    if strcmp(name,'Screening')==1;  
        cd('Screening');
        loc=strcat(dname8904,'/batch.mat');
        movefile(loc);
        dname8904=pwd;
        break;
    end
end
fill_batch(dname8904);
evalin('base', 'clear *8904');
load('batch.mat');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
cd('epi');
prepfiles=dir('swr*.nii');
nums=size(prepfiles);
num=nums(1);
for i=1:num
    name=prepfiles(i).name;
    v=spm_vol(name);
    frames=length(v);
    mid=round(frames/2);
%%    disp('Calculating Mean...')
%%    V = spm_vol(name);
%%    Y = spm_read_vols(V);
%%    Ysnr = mean(Y,4)./std(Y,[],4);
%%    a=Ysnr(:);
%%    noNAN=a(~isnan(a));
%%    noINF=noNAN(~isinf(noNAN));
%%    snr=mean(noINF);
%%    disp('Done')
    cd('..')
    create_cfg(name);
    art repair.cfg;
    hAllAxes = findobj(gcf,'type','axes');
    f=figure;
    for i=1:3
        fig=hAllAxes(i);
        copyobj(fig,f);
    end
   close art;
    fig=gcf;
    fig.Name=strcat(name(1:end-4),'.fig');
    hAllAxes = findobj(gcf,'type','axes');
    meanA=hAllAxes(3);
    meanA.Position=[0.1111 .87 0.8 0.1];
    globalMean=hAllAxes(1);
    globalMean.Position=[0.1111 0.70 0.8 0.1];
    move=hAllAxes(2);
    move.Position=[.1111 0.57 0.8 0.08];
    cd('epi');
    mapping(strcat(pwd,'/',name,',',num2str(mid)));
%%    mTextBox = uicontrol('style','text');
%%    set(mTextBox,'String',strcat('SNR Mean=',num2str(snr)))
%%    mTextBox.ForegroundColor=[1 0 0];
%%    mTextBox.Position=[20 20 500 13];
    saveas(fig,fig.Name)
end
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
