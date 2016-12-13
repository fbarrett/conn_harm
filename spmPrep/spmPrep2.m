function varargout = spmPrep2(varargin)
% Advanced Options of SPM Prep - Lucas Rosen 12/13/16
% Must first run spmPrep.m and select directories and then click 'advanced
% options'
% SPMPREP2 MATLAB code for spmPrep2.fig
%      SPMPREP2, by itself, creates a new SPMPREP2 or raises the existing
%      singleton*.
%
%      H = SPMPREP2 returns the handle to a new SPMPREP2 or the handle to
%      the existing singleton*.
%
%      SPMPREP2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPMPREP2.M with the given input arguments.
%
%      SPMPREP2('Property','Value',...) creates a new SPMPREP2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before spmPrep2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to spmPrep2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help spmPrep2

% Last Modified by GUIDE v2.5 29-Nov-2016 15:47:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @spmPrep2_OpeningFcn, ...
                   'gui_OutputFcn',  @spmPrep2_OutputFcn, ...
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


% --- Executes just before spmPrep2 is made visible.
function spmPrep2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spmPrep2 (see VARARGIN)

% Choose default command line output for spmPrep2
handles.output = hObject;
if nargin>1 && iscell(varargin{2})
    handles.sessionsDir=varargin{2};
else
    error('Bad input')
end
guidata(hObject, handles);

% UIWAIT makes spmPrep2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = spmPrep2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
% alternate batch
function pushbutton1_Callback(hObject, eventdata, handles)
[baseName,folder]=uigetfile('*.mat');
template=fullfile(folder,baseName);
handles.template=template;
guidata(hObject,handles);
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox1.
% search all?
function checkbox1_Callback(hObject, eventdata, handles)
if get(hObject,'Value')==0;
    searchAll=0;
elseif get(hObject,'Value')==1;
    searchAll=1;
end
handles.searchAll=searchAll;
guidata(hObject,handles);
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in pushbutton3.
%key words
function pushbutton3_Callback(hObject, eventdata, handles)
keysString=char(inputdlg(sprintf('Input list of keywords in files with erroneous frames.\nThis list should be separated by commas.\nExample: music, cats, dogs')));
keysString(keysString==' ') = '';
badFrames=strsplit(keysString,',');
handles.badFrames=badFrames;
guidata(hObject,handles);
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton4.
% tissue
function pushbutton4_Callback(hObject, eventdata, handles)
[tissueBN,tissueF]=uigetfile('*.nii');
tissue=fullfile(tissueF,tissueBN);
handles.tissue=tissue;
guidata(hObject,handles);
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
%run
function pushbutton5_Callback(hObject, eventdata, handles)
if ~isfield(handles,'template')
    template='default';
else
    template=handles.template;
end
if ~isfield(handles,'searchAll')
    searchAll='default';
else
    searchAll=handles.searchAll;
end
if ~isfield(handles,'tissue')
    tissue='default';
else
    tissue=handles.tissue;
end
if ~isfield(handles,'badFrames')
    badFrames='default';
else
    badFrames=handles.badFrames;
end
sessions=handles.sessionsDir;
batchOpt=spmPrep_intro('template',template,'searchAll',searchAll,'badFrames',badFrames,'tissue',tissue);
batchInfo=spmPrep_run(sessions,batchOpt);

% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
