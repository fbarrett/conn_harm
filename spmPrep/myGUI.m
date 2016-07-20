function varargout = myGUI(varargin)
% myGUI MATLAB code for myGUI.fig
%      myGUI, by itself, creates a new myGUI or raises the existing
%      singleton*.
%
%      H = myGUI returns the handle to a new myGUI or the handle to
%      the existing singleton*.
%
%      myGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in myGUI.M with the given input arguments.
%
%      myGUI('Property','Value',...) creates a new myGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before myGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to myGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help myGUI

% Last Modified by GUIDE v2.5 12-Jul-2016 13:17:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @myGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @myGUI_OutputFcn, ...
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


% --- Executes just before myGUI is made visible.
function myGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to myGUI (see VARARGIN)

% Choose default command line output for myGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes myGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = myGUI_OutputFcn(hObject, eventdata, handles) 
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




% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
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
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
dname8904=evalin('base','dname8904');
fid=fopen(strcat(dname8904,'/dict.txt'),'w');
frames = inputdlg('Enter Session Keywords Separated by Commas');
fprintf(fid,'%s',frames{1});
fclose(fid);
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
[baseName, folder] = uigetfile('*.nii');
fullFileName = fullfile(folder, baseName);
dname8904=evalin('base','dname8904');
fid=fopen(strcat(dname8904,'/tissue.txt'),'w');
fprintf(fid,'%s',fullFileName);
fclose(fid);
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
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
    disp('Calculating Mean...')
    V = spm_vol(name);
    Y = spm_read_vols(V);
    Ysnr = mean(Y,4)./std(Y,[],4);
    a=Ysnr(:);
    noNAN=a(~isnan(a));
    noINF=noNAN(~isinf(noNAN));
    snr=mean(noINF);
    disp('Done')
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
    mTextBox = uicontrol('style','text');
    set(mTextBox,'String',strcat('SNR Mean=',num2str(snr)))
    mTextBox.ForegroundColor=[1 0 0];
    mTextBox.Position=[20 20 500 13];
    saveas(fig,fig.Name)
end
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function pushbutton1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function pushbutton1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function pushbutton1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
dname = uigetdir('C:\');

% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
[baseName, folder] = uigetfile();
dname8904=evalin('base','dname8904');
cd(dname8904);
path=strcat(folder,baseName);
system(path);
messagebox('Files Formatted')

