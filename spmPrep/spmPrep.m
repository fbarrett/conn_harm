function varargout = spmPrep(varargin)
% SPMPREP MATLAB code for spmPrep.fig
%      SPMPREP, by itself, creates a new SPMPREP or raises the existing
%      singleton*.
%
%      H = SPMPREP returns the handle to a new SPMPREP or the handle to
%      the existing singleton*.
%
%      SPMPREP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPMPREP.M with the given input arguments.
%
%      SPMPREP('Property','Value',...) creates a new SPMPREP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before spmPrep_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to spmPrep_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help spmPrep

% Last Modified by GUIDE v2.5 13-Dec-2016 12:44:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @spmPrep_OpeningFcn, ...
                   'gui_OutputFcn',  @spmPrep_OutputFcn, ...
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



% --- Executes just before spmPrep is made visible.
function spmPrep_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spmPrep (see VARARGIN)

% Choose default command line output for spmPrep
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes spmPrep wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = spmPrep_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in pushbutton1.
function sessionsDir=pushbutton1_Callback(hObject, eventdata, handles)
sessionsDir=uipickfiles();
handles.sessionsDir=sessionsDir;
guidata(hObject,handles);

% --- Executes on button press in pushbutton2.
function sorting_method=pushbutton2_Callback(hObject, eventdata, handles)
%not used
spmPrepPath=strcat(fileparts(which('spmPrep_run'))); %retrieve spm path
sortsPath=fullfile(spmPrepPath,'sort');
sorting_method=uigetfile(fullfile(sortsPath,'*.m'));
sessionsDir=handles.sessionsDir;
%do sorting here


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
if ~isfield(handles,'sessionsDir')
    error('Did not select session directory')
else
    close gcf;
    sessionsDir=handles.sessionsDir;
    spmPrep2([],sessionsDir);
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
batchOpt=spmPrep_intro();
if ~isfield(handles,'sessionsDir')
    error('Did not select session directory')
else
    sessionsDir=handles.sessionsDir;
    close(gcf);
    spmPrep_run(sessionsDir,batchOpt);
end
