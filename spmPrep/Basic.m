function varargout = Basic(varargin)
% BASIC MATLAB code for Basic.fig
%      BASIC, by itself, creates a new BASIC or raises the existing
%      singleton*.
%
%      H = BASIC returns the handle to a new BASIC or the handle to
%      the existing singleton*.
%
%      BASIC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BASIC.M with the given input arguments.
%
%      BASIC('Property','Value',...) creates a new BASIC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Basic_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Basic_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Basic

% Last Modified by GUIDE v2.5 25-Jul-2016 14:29:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Basic_OpeningFcn, ...
                   'gui_OutputFcn',  @Basic_OutputFcn, ...
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


% --- Executes just before Basic is made visible.
function Basic_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Basic (see VARARGIN)

% Choose default command line output for Basic
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Basic wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Basic_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
clear;
p = mfilename('fullpath');
fileDirectory = fileparts(p);
cd(fileDirectory);
dname = uigetdir(pwd);
pathname=strcat(pwd,'/');
filename='default_batch.mat';
copyfile(strcat(pathname,filename),dname)
curDir = pwd;
cd(dname);
if strcmp(filename,'batch.mat')==0
    movefile(filename,'batch.mat');
end
q=dir('Screening');
qq=size(q);
qqq=qq(1);
if qqq==0;
    p=dir('epi');
    pp=size(p);
    ppp=pp(1);
    if ppp==0;
        run('kki_sort.m');
        cd(dname);
    end
else;
    cd('Screening');
    p=dir('epi');
    pp=size(p);
    ppp=pp(1);
    cd('..');
    if ppp==0;
        run('ctmi_sort.m');
        cd(dname);
        cd('Screening');
        loc=strcat(dname,'/batch.mat');
        movefile(loc);
        dname=pwd;
    else
        cd(dname);
        cd('Screening');
        loc=strcat(dname,'/batch.mat');
        movefile(loc);
        dname=pwd;
    end
end
fid=fopen('dict.txt','w');
fprintf(fid,'music');
fclose(fid);
tooMuch=which('spm_jobman.m');
justRight=tooMuch(1:end-12);
tissuePath=strcat(justRight,'tpm/TPM.nii');
fid=fopen('tissue.txt','w');
fprintf(fid,'%s',tissuePath);
fclose(fid);
cd('epi');
r=dir('swr*');
rr=size(r);
rrr=rr(1);
if rrr==0
    cd('..')
    fill_batch(dname);
    clear;
    load('batch.mat');
    spm_jobman('initcfg');
    spm_jobman('run',matlabbatch);
    cd('epi');
else
    clear;
end
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

% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
