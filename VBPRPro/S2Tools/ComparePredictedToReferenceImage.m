function varargout = ComparePredictedToReferenceImage(varargin)
% COMPAREPREDICTEDTOREFERENCEIMAGE MATLAB code for ComparePredictedToReferenceImage.fig
%      COMPAREPREDICTEDTOREFERENCEIMAGE, by itself, creates a new COMPAREPREDICTEDTOREFERENCEIMAGE or raises the existing
%      singleton*.
%
%      H = COMPAREPREDICTEDTOREFERENCEIMAGE returns the handle to a new COMPAREPREDICTEDTOREFERENCEIMAGE or the handle to
%      the existing singleton*.
%
%      COMPAREPREDICTEDTOREFERENCEIMAGE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMPAREPREDICTEDTOREFERENCEIMAGE.M with the given input arguments.
%
%      COMPAREPREDICTEDTOREFERENCEIMAGE('Property','Value',...) creates a new COMPAREPREDICTEDTOREFERENCEIMAGE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ComparePredictedToReferenceImage_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ComparePredictedToReferenceImage_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ComparePredictedToReferenceImage

% Last Modified by GUIDE v2.5 09-Feb-2021 19:47:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ComparePredictedToReferenceImage_OpeningFcn, ...
                   'gui_OutputFcn',  @ComparePredictedToReferenceImage_OutputFcn, ...
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


% --- Executes just before ComparePredictedToReferenceImage is made visible.
function ComparePredictedToReferenceImage_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ComparePredictedToReferenceImage (see VARARGIN)

% Choose default command line output for ComparePredictedToReferenceImage
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ComparePredictedToReferenceImage wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ComparePredictedToReferenceImage_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pbClose.
function pbClose_Callback(hObject, eventdata, handles)
% hObject    handle to pbClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close;

% --- Executes on button press in pbOK.
function pbOK_Callback(hObject, eventdata, handles)
% hObject    handle to pbOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Prevent user from double clicking the button causing "race" bug 
% set(hObject,'Enable','off');

%% Start program
tic;

%% get reference image file path and names
reference_file = get(handles.txtReferenceImageFile,'String');
if isempty(reference_file)
    msgbox('Specify a reference image file for your assessment!');
    return;
end
ref_band = get(handles.popRefBand,'Value');
ref_scale = str2double(get(handles.txtRefScale,'String'));

comp_band = get(handles.popCompBand,'Value');
comp_scale = str2double(get(handles.txtPredScale,'String'));

%% get the output folder and assign a result log file name
result_file = get(handles.txtOutputFolder,'String');

%% delete the old result file
if exist(result_file,'file')
    delete(result_file);
end

%% get all image files to be tested
file_list = get(handles.lstPredictImageFiles,'String');
if iscell(file_list)
    nf = length(file_list);
else
    nf = 1;
end
if nf<1
    msgbox('Add at least one image file to the list for your assessment!');
    return;
end

%% read in the reference image data
[ref, x, y, info] = geoimread(reference_file);

ref = double(ref)/ref_scale;

%% get the selected band for comparison
ref = ref(:,:, ref_band);
[row, col, bands] = size(ref);

%% Preallocation 
% Indices per band
b_bias  = zeros(bands,nf);
b_mae   = zeros(bands,nf);
b_mre   = zeros(bands,nf);
b_pcc   = zeros(bands,nf);
b_div   = zeros(bands,nf);
b_ergas = zeros(bands,nf);
b_rmse  = zeros(bands,nf);
b_rase  = zeros(bands,nf);
b_uiqi  = zeros(bands,nf);
b_ssim  = zeros(bands,nf);
b_exc   = zeros(bands,nf);
% Average indices
av_bias = zeros(1,nf);
av_mae  = zeros(1,nf);
av_mre  = zeros(1,nf);
av_pcc  = zeros(1,nf);
av_div  = zeros(1,nf);
av_ergas  = zeros(1,nf);
av_rmse = zeros(1,nf);
av_rase = zeros(1,nf);
av_uiqi = zeros(1,nf);
av_ssim = zeros(1,nf);
ergas_spectral = zeros(1,nf);
ergas_spatial = zeros(1,nf);

flnames = cell(1,nf);

%% compute indices for each image to be tested
for i = 1:nf
    % retreive file name for output
    if ischar(file_list)
        test_file = file_list;
    else
        test_file = char(file_list{i});
    end
    [path, name, ext] = fileparts(test_file);
    flnames{i} = name;    
    
    % readin the test image data
    test = geoimread(test_file);
    test = double(test)/comp_scale;
    
    % get the selected band for comparison
    test = test(:,:,comp_band);
    
    % compute Bias
    if get(handles.chkBIAS,'Value')==1
        [b_bias(:,i),av_bias(1,i)] = ComputeBIAS(test, ref);      
    end
    % compute MAE
    if get(handles.chkMAE,'Value')==1
        [b_mae(:,i),av_mae(1,i)] = ComputeMAE(test, ref);      
    end
    % compute MRE
    if get(handles.chkMRE,'Value')==1
        [b_mre(:,i),av_mre(1,i),b_exc(:,i)] = ComputeMRE(test, ref);
    end 
    % compute PCC
    if get(handles.chkCC,'Value')==1
        [b_pcc(:,i), av_pcc(1,i)] = ComputePCC(test, ref);
    end 
    % compte DIV
    if get(handles.chkDIV,'Value')==1 
        [b_div(:,i), av_div(1,i)] = ComputeDIV(test, ref);
    end
    % compte RMSE
    if get(handles.chkRMSE,'Value')==1
        [b_rmse(:,i), av_rmse(1,i)] = ComputeRMSE(test, ref);
    end
    % compte RASE
    if get(handles.chkRASE,'Value')==1
        [b_rase(:,i), av_rase(1,i)] = ComputeRASE(test, ref);
    end
    % compte UIQI
    if get(handles.chkUIQI,'Value')==1
        [b_uiqi(:,i), av_uiqi(1,i)] = ComputeUIQI(test, ref);
    end
    % compute SSIM
    if get(handles.chkSSIM,'Value')==1
        [b_ssim(:,i), av_ssim(1,i)] = ComputeSSIM(test, ref);
    end
    % compute ERGAS
    resratio = eval(get(handles.txtResolutionRatio,'string')); % use eval to accept fraction
    if get(handles.chkERGAS,'Value')==1
        [b_ergas(:,i), av_ergas(1,i), ergas_spectral(1,i), ergas_spatial(1,i)] = ComputeERGAS(test, ref, resratio);
    end
end

ttime = toc;

disp(['>>> Elapsed time: ', num2str(ttime),' seconds. <<<'])
disp(' ')

%% Output the results
fid = fopen(result_file,'wt');
fprintf(fid,'%-63s','         Method');
fprintf(fid,'%-12s','  InvPixels');
if get(handles.chkBIAS,'Value')==1
    fprintf(fid,'%-12s','      AD');
end
if get(handles.chkMAE,'Value')==1
    fprintf(fid,'%-12s','     AAD');
end
if get(handles.chkMRE,'Value')==1
    fprintf(fid,'%-12s','     ARD');
end
if get(handles.chkDIV,'Value')==1
    fprintf(fid,'%-12s','     DIV');
end
if get(handles.chkRMSE,'Value')==1
    fprintf(fid,'%-12s','    RMSE');
end
if get(handles.chkRASE,'Value')==1
    fprintf(fid,'%-12s','    RASE');
end
if get(handles.chkERGAS,'Value')==1
    fprintf(fid,'%-12s','   ERGAS');
%     fprintf(fid,'%-12s','  Spectral');
%     fprintf(fid,'%-12s\n','   Spatial');
end
if get(handles.chkCC,'Value')==1
    fprintf(fid,'%-12s','     CC');
end
if get(handles.chkUIQI,'Value')==1
    fprintf(fid,'%-12s','     QI');
end
if get(handles.chkSSIM,'Value')==1
    fprintf(fid,'%-12s','    SSIM');
end
fprintf(fid,'\n');


for i=1:bands
    % fprintf(fid,'%-60s\n',['Band ' num2str(i)]);
    fprintf(fid,'%-60s\n',['Reference band ' num2str(ref_band) ' vs. comparision band ' num2str(comp_band)]);
    for j=1:nf
        fprintf(fid,'%-60s',flnames{j});
        fprintf(fid,'%12d',b_exc(i,j));
        if get(handles.chkBIAS,'Value')==1
            fprintf(fid,'%12.4f',b_bias(i,j));
        end
        if get(handles.chkMAE,'Value')==1
            fprintf(fid,'%12.4f',b_mae(i,j));
        end
        if get(handles.chkMRE,'Value')==1
            fprintf(fid,'%12.4f',b_mre(i,j));
        end
        if get(handles.chkDIV,'Value')==1
            fprintf(fid,'%12.4f',b_div(i,j));
        end
        if get(handles.chkRMSE,'Value')==1
            fprintf(fid,'%12.4f',b_rmse(i,j));
        end
        if get(handles.chkRASE,'Value')==1
            fprintf(fid,'%12.4f',b_rase(i,j));
        end
        if get(handles.chkERGAS,'Value')==1
            fprintf(fid,'%12.4f',b_ergas(i,j));
        end
        if get(handles.chkCC,'Value')==1
            fprintf(fid,'%12.4f',b_pcc(i,j));
        end
        if get(handles.chkUIQI,'Value')==1
            fprintf(fid,'%12.4f',b_uiqi(i,j));
        end
        if get(handles.chkSSIM,'Value')==1
            fprintf(fid,'%12.4f',b_ssim(i,j));
        end
        fprintf(fid,'\n');
    end
end
% write the average values of all bands
if bands > 1
    fprintf(fid,'%-60s\n','Average');
    for j=1:nf
        fprintf(fid,'%-60s',flnames{j});
        fprintf(fid,'%12d',sum(b_exc(:,j)));
        if get(handles.chkBIAS,'Value')==1
            fprintf(fid,'%12.4f',av_bias(1,j));
        end
        if get(handles.chkMAE,'Value')==1
            fprintf(fid,'%12.4f',av_mae(1,j));
        end
        if get(handles.chkMRE,'Value')==1
            fprintf(fid,'%12.4f',av_mre(1,j));
        end
        if get(handles.chkDIV,'Value')==1
            fprintf(fid,'%12.4f',av_div(1,j));
        end
        if get(handles.chkRMSE,'Value')==1
            fprintf(fid,'%12.4f',av_rmse(1,j));
        end
        if get(handles.chkRASE,'Value')==1
            fprintf(fid,'%12.4f',av_rase(1,j));
        end
        if get(handles.chkERGAS,'Value')==1
            fprintf(fid,'%12.4f',av_ergas(1,j));
%             fprintf(fid,'%12.4f',ergas_spectral(1,j));
%             fprintf(fid,'%12.4f\n',ergas_spatial(1,j));  
        end
        if get(handles.chkCC,'Value')==1
            fprintf(fid,'%12.4f',av_pcc(1,j));
        end
        if get(handles.chkUIQI,'Value')==1
            fprintf(fid,'%12.4f',av_uiqi(1,j));
        end
        if get(handles.chkSSIM,'Value')==1
            fprintf(fid,'%12.4f',av_ssim(1,j));  
        end
        fprintf(fid,'\n');
    end
end
fclose(fid);

return;

% Write excel file with all index analysis results

disp('-Preparing Excel Output...')
% Disable AddSheet Warning
warning off MATLAB:xlswrite:AddSheet
% Band count
cbnd    = num2cell(1:bands)';
cbnda   = [ {'BAND #'}; cbnd ; cell(1,1) ; {'AVERAGE'} ];
cbndt   = [ {'BAND #'}; cbnd ; cell(1,1) ; {'TOTAL'} ];
e_line =  cell(1,nf);

% Prepare cell per index
% MAE
cmae = [ flnames ; num2cell(b_mae); e_line; num2cell(av_mae)];
cmae = [ cbnda, cmae ];
% MRE
cmre = [ flnames ; num2cell(b_mre); e_line; num2cell(av_mre)];
cmre = [ cbnda, cmre ];
% PCC
cpcc = [ flnames ; num2cell(b_pcc); e_line; num2cell(av_pcc)];
cpcc = [ cbnda, cpcc ];
% MSE
cmse = [ flnames ; num2cell(b_mse); e_line; num2cell(av_mse)];
cmse = [ cbnda, cmse ];
% RMSE
crmse = [ flnames ; num2cell(b_rmse); e_line; num2cell(av_rmse)];
crmse = [ cbnda, crmse ];
% SSIM
cssim = [ flnames ; num2cell(b_ssim); e_line; num2cell(av_ssim)];
cssim = [ cbnda, cssim ];

%% Determine if the system has Microsoft Excel installed..
csvmode = false;
try
   Excel = actxserver('excel.application');
catch exc   
   csvmode = true;
   disp('-Cannot establish connection with Excel.')
   disp('-The indices values will be written in *.CSV format.')
   disp(' ')
end

%% Output Results
if csvmode == false
    % Excel file name
    if ~exist( 'excel_name' )
        excel_name = fullfile(output_folder,'CompareResults.xls');
    end
    % Write every index in the homonymous excel spreadsheet
    % Write MAE
    if get(handles.chkMAE,'Value')==1
        xlswrite( excel_name, cmae,       'MAE')     
    end
    % Write MRE
    if get(handles.chkMRE,'Value')==1
        xlswrite( excel_name, cmre,       'MRE')     
    end 
    % Write PCC
    if get(handles.chkCC,'Value')==1
        xlswrite( excel_name, cpcc,       'PCC')     
    end 
    % Write MSE and RMSE
    if get(handles.chkMSE,'Value')==1
        xlswrite( excel_name, cmse,       'MSE')     
    end
    % Write RMSE
    if get(handles.chkRMSE,'Value')==1
        xlswrite( excel_name, crmse,       'RMSE')     
    end
    % Write SSIM
    if get(handles.chkSSIM,'Value')==1
        xlswrite( excel_name, cssim,       'SSIM')     
    end
    disp('-All indices have been written successfully in Excel file.')
    disp(' ')
else
    csv_name = fullfile(output_folder,'CompareResults.csv');
    e_line2 =  cell(1,nf);
    % Make one massive csv file
    if iov(1) == 1
        header = {'MAE'};
        header = repmat(header,[1 nin+2]);
        csvindices = [ header; cmae; e_line2; e_line2 ];
    end
    if iov(2) == 1
        header = {'DIV'};
        header = repmat(header,[1 nin+2]);
        if ciov(2) > 1
            csvindices = [ csvindices; header; cdivs; e_line2; e_line2 ];
        else
            csvindices = [ header; cdivs; e_line2; e_line2 ];
        end
    end
    if iov(3) == 1
        header = {'CC'};
        header = repmat(header,[1 nin+2]);
        if ciov(3) > 1
            csvindices = [ csvindices; header; cccs; e_line2; e_line2 ];
        else
            csvindices = [ header; cccs; e_line2; e_line2 ];
        end
    end
    if iov(4) == 1
        header = {'Entropy Diff'};
        header = repmat(header,[1 nin+2]);
        if ciov(4) > 1
            csvindices = [ csvindices; header; centropys; e_line2; e_line2 ];
        else
            csvindices = [ header; centropys; e_line2; e_line2 ];
        end
    end
    if iov(5) == 1
        header = {'ERGAS'};
        header = repmat(header,[1 nin+2]);
        if ciov(5) > 1
            csvindices = [ csvindices; header; cergass; e_line2; e_line2 ];
        else
            csvindices = [ header; cergass; e_line2; e_line2 ];
        end
    end
    if iov(6) == 1
        header = {'Q'};
        header = repmat(header,[1 nin+2]);
        if ciov(6) > 1
            csvindices = [ csvindices; header; cqss; e_line2; e_line2 ];
        else
            csvindices = [ header; cqss; e_line2; e_line2 ];
        end
    end
    if iov(7) == 1
        header = {'RASE'};
        header = repmat(header,[1 nin+2]);
        csvindices = [ csvindices; header; crases; e_line2; e_line2 ];
    end
    if iov(8) == 1
        header = {'RMSE'};
        header = repmat(header,[1 nin+2]);
        if ciov(7) > 1
            csvindices = [ csvindices; header; crmses; e_line2; e_line2 ];
        else
            csvindices = [ header; crmses; e_line2; e_line2 ];
        end
    end
    % Write the massive .csv
    dlmcell( csv_name,          csvindices, ';')

    disp('-All indices have been written successfully in .CSV file.')
    disp(' ')
end

disp('=== Job:Done! ===')
disp(' ')
% Callback has been executed, user can reclick if he/she wants
set(hObject,'Enable','on')



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbUncheckAll.
function pbUncheckAll_Callback(hObject, eventdata, handles)
% hObject    handle to pbUncheckAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Check all
set(handles.chkBIAS,'value',0);
set(handles.chkMAE,'value',0);
set(handles.chkMRE,'value',0);
set(handles.chkCC,'value',0);
set(handles.chkDIV,'value',0);
set(handles.chkUIQI,'value',0);
set(handles.chkMSE,'value',0);
set(handles.chkRMSE,'value',0);
set(handles.chkRASE,'value',0);
set(handles.chkSSIM,'value',0);
set(handles.chkERGAS,'value',0);

% --- Executes on button press in pbCheckAll.
function pbCheckAll_Callback(hObject, eventdata, handles)
% hObject    handle to pbCheckAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Check all 
set(handles.chkBIAS,'value',1);
set(handles.chkMAE,'value',1);
set(handles.chkMRE,'value',1);
set(handles.chkCC,'value',1);
set(handles.chkDIV,'value',1);
set(handles.chkUIQI,'value',1);
set(handles.chkRMSE,'value',1);
set(handles.chkRASE,'value',1);
set(handles.chkSSIM,'value',1);
set(handles.chkERGAS,'value',1);

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on button press in chkSSIM.
function chkSSIM_Callback(hObject, eventdata, handles)
% hObject    handle to chkSSIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkSSIM


% --- Executes on button press in checkbox6.
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6


% --- Executes on button press in chkMRE.
function chkMRE_Callback(hObject, eventdata, handles)
% hObject    handle to chkMRE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkMRE


% --- Executes on button press in chkRMSE.
function chkRMSE_Callback(hObject, eventdata, handles)
% hObject    handle to chkRMSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkRMSE


% --- Executes on button press in chkMSE.
function chkMSE_Callback(hObject, eventdata, handles)
% hObject    handle to chkMSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkMSE


% --- Executes on button press in chkCC.
function chkCC_Callback(hObject, eventdata, handles)
% hObject    handle to chkCC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkCC


% --- Executes on button press in chkMAE.
function chkMAE_Callback(hObject, eventdata, handles)
% hObject    handle to chkMAE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkMAE


% --- Executes on button press in pbSelectOutputFile.
function pbSelectOutputFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbSelectOutputFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cur_dir = cd;
folder_name = uigetdir(cd, 'Specify a output folder for the evaluation results');
if  folder_name > 0  
set(handles.txtOutputFolder, 'String', [folder_name '\ImageAssessResults.txt']);
end 
 cd(cur_dir);


function txtOutputFolder_Callback(hObject, eventdata, handles)
% hObject    handle to txtOutputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtOutputFolder as text
%        str2double(get(hObject,'String')) returns contents of txtOutputFolder as a double


% --- Executes during object creation, after setting all properties.
function txtOutputFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtOutputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtReferenceImageFile_Callback(hObject, eventdata, handles)
% hObject    handle to txtReferenceImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtReferenceImageFile as text
%        str2double(get(hObject,'String')) returns contents of txtReferenceImageFile as a double


% --- Executes during object creation, after setting all properties.
function txtReferenceImageFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtReferenceImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbBrowseReferenceImageFile.
function pbBrowseReferenceImageFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbBrowseReferenceImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cur_dir = cd;
[filename, pathname] = uigetfile( ...
    {  '*.*','Specify a reference image file (*.*)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Specify a reference image file');
 if  filename > 0  
    set(handles.txtReferenceImageFile, 'String', [pathname filename]);
 end 
 cd(cur_dir);
 

% --- Executes on button press in pbAddPredictImageFile.
function pbAddPredictImageFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbAddPredictImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cur_dir = cd;

%% get the files already in the list
listed_files = get(handles.lstPredictImageFiles,'String');

%% get the new files
[filenames, folder] = uigetfile( ...
    {  '*.*','Downscaled image files (*.*)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Multiselect','on',...
    'Select downscaled image files for quality assessment');
%% add the new files to the list
if ~isempty(filenames)
     filenames = fullfile(folder, filenames);
     if  isempty(listed_files) 
         listed_files = cellstr(filenames);
     else
         if iscell(listed_files)
            listed_files = [listed_files; filenames];
         else
            listed_files = [cellstr(listed_files); filenames];
         end
         %listed_files = sort(listed_files);
     end
     set(handles.lstPredictImageFiles,'String',listed_files,'Value',1); 
     % set the default output file name
     set(handles.txtOutputFolder, 'String', [folder 'ImageAssessResults.txt']);
end 
cd(cur_dir);

% --- Executes on button press in pbShowReferenceImage.
function pbShowReferenceImage_Callback(hObject, eventdata, handles)
% hObject    handle to pbShowReferenceImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

reference_file = get(handles.txtReferenceImageFile,'String');
if isempty(reference_file)
    msgbox('Specify a reference image file for your comparison!');
    return;
end

data_format = get(handles.popDataFormat,'Value');

switch data_format
    case 1  % ENVI image format        
        [rgb, hdr] = envireaddata(reference_file);
    otherwise
        % do nothing for now
end

% % get file parameters
% n_row = str2double(get(handles.txtRows,'String'));
% n_col = str2double(get(handles.txtColums,'String'));
% n_band = str2double(get(handles.txtBands,'String'));

ShowImageInProperColorScale(rgb, 256);

% --- Executes on selection change in lstPredictImageFiles.
function lstPredictImageFiles_Callback(hObject, eventdata, handles)
% hObject    handle to lstPredictImageFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstPredictImageFiles contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstPredictImageFiles


% --- Executes during object creation, after setting all properties.
function lstPredictImageFiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstPredictImageFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbRemovePredictImageFile.
function pbRemovePredictImageFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbRemovePredictImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.lstPredictImageFiles,'Value');
file_list = get(handles.lstPredictImageFiles,'String');
if iscell(file_list)
    file_list(index_selected)=[];
else
    file_list = [];
end
set(handles.lstPredictImageFiles,'String',file_list,'Value',1);

% --- Executes on button press in pbShowPredictImageFile.
function pbShowPredictImageFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbShowPredictImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.lstPredictImageFiles,'Value');
file_list = get(handles.lstPredictImageFiles,'String');

if iscell(file_list)
    selected_file = file_list{index_selected};
else
    selected_file = file_list;
end

[rgb, hdr] = envireaddata(selected_file);

ShowImageInMaxColorScale(rgb);


function txtScaleFactor_Callback(hObject, eventdata, handles)
% hObject    handle to txtScaleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtScaleFactor as text
%        str2double(get(hObject,'String')) returns contents of txtScaleFactor as a double


% --- Executes during object creation, after setting all properties.
function txtScaleFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtScaleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtBands_Callback(hObject, eventdata, handles)
% hObject    handle to txtBands (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtBands as text
%        str2double(get(hObject,'String')) returns contents of txtBands as a double


% --- Executes during object creation, after setting all properties.
function txtBands_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtBands (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtColums_Callback(hObject, eventdata, handles)
% hObject    handle to txtColums (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtColums as text
%        str2double(get(hObject,'String')) returns contents of txtColums as a double


% --- Executes during object creation, after setting all properties.
function txtColums_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtColums (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtRows_Callback(hObject, eventdata, handles)
% hObject    handle to txtRows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRows as text
%        str2double(get(hObject,'String')) returns contents of txtRows as a double


% --- Executes during object creation, after setting all properties.
function txtRows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtRows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popDataFormat.
function popDataFormat_Callback(hObject, eventdata, handles)
% hObject    handle to popDataFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popDataFormat contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popDataFormat


% --- Executes during object creation, after setting all properties.
function popDataFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popDataFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkRASE.
function chkRASE_Callback(hObject, eventdata, ~)
% hObject    handle to chkRASE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkRASE


% --- Executes on button press in chkUIQI.
function chkUIQI_Callback(hObject, eventdata, handles)
% hObject    handle to chkUIQI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkUIQI


% --- Executes on button press in chkDIV.
function chkDIV_Callback(hObject, eventdata, handles)
% hObject    handle to chkDIV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkDIV


% --- Executes on button press in chkERGAS.
function chkERGAS_Callback(hObject, eventdata, handles)
% hObject    handle to chkERGAS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkERGAS



function txtResolutionRatio_Callback(hObject, eventdata, handles)
% hObject    handle to txtResolutionRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtResolutionRatio as text
%        str2double(get(hObject,'String')) returns contents of txtResolutionRatio as a double


% --- Executes during object creation, after setting all properties.
function txtResolutionRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtResolutionRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkBIAS.
function chkBIAS_Callback(hObject, eventdata, handles)
% hObject    handle to chkBIAS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkBIAS


% --- Executes on button press in pbScatterPlot.
function pbScatterPlot_Callback(hObject, eventdata, handles)
% hObject    handle to pbScatterPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(0,'DefaultTextInterpreter','none');
set(gcf, 'InvertHardCopy', 'off');

reference_file = get(handles.txtReferenceImageFile,'String');
if isempty(reference_file)
    msgbox('Specify a reference image file for your assessment!');
    return;
end

ref_band = get(handles.popRefBand,'Value');
ref_scale = str2double(get(handles.txtRefScale,'String'));

comp_band = get(handles.popCompBand,'Value');
comp_scale = str2double(get(handles.txtPredScale,'String'));

file_list = get(handles.lstPredictImageFiles,'String');
index_selected = get(handles.lstPredictImageFiles,'Value');
selected_file = file_list{index_selected};

%% determine the downscale method
switch get(handles.popMethod,'Value')
    case 1
        method = 'Cubic Spline';
    case 2
        method = 'ATPRK-SM';
    case 3
        method = 'ATPRK-PAN';
    case 4
        method = 'SupReME';
    case 5
        method = 'DSen2';
end

%% read in image data
imgo = geoimread(reference_file);
imgp = geoimread(selected_file);

imgo = double(imgo)/ref_scale;
imgp = double(imgp)/comp_scale;

%% retreive the matched band for comparison
imgo = imgo(:,:, ref_band);
imgp = imgp(:,:, comp_band);

%% compute Quality Indices
resratio = eval(get(handles.txtResolutionRatio,'string')); % use eval to accept fraction
r = ComputePCC(imgp, imgo);
rmse = ComputeRMSE(imgp, imgo);
qi = ComputeUIQI(imgp, imgo);
ergas = ComputeERGAS(imgp, imgo, resratio);

[m, n, b] = size(imgo);
excp = zeros(b,1);

for i=1:b
    x = imgo(:,:,i);
    y = imgp(:,:,i);
    x = x(:);
    y = y(:);
%     idx = find(x<=0|x>=1.0);
%     idy = find(y<=0|y>=1.0);
%     idxy = union(idx,idy);
%     y(idxy) = [];
%     x(idxy) = [];
%     if isempty(idxy)
%         excp(i) = 0;
%     else
%         excp(i) = length(idxy);
%     end
    
    %[r2 rmse] = rsquare(x,y);    

    % figure;
    h1 = figure;
    set(h1,'Position',[100 100 850 800]);

    ax_min = min(min(x),min(y));
    ax_max = max(max(x), max(y));
%     ax_min = min(round(min(x)),round(min(y)));
%     ax_max = max(ceil(max(x)), ceil(max(y)));
    
    %scatter(x,y,sz,'filled');
    dscatter(x,y);
    hold on;
    x1 = [ax_min ax_max];
    y1 = [ax_min ax_max];
    line(x1,y1,'Color','r','LineWidth',1);
    x2 = [ax_min ax_max];
    y2 = [ax_max ax_max];
    line(x2,y2,'Color','k');%,'LineWidth',1);
    x3 = [ax_max ax_max];
    y3 = [ax_min ax_max];
    line(x3,y3,'Color','k');%,'LineWidth',1);

    xlim([ax_min ax_max]);
    ylim([ax_min ax_max]); 
    
    xlabel('Reference');
    ylabel('Downscaled');
    title(method);
    
    TXT_1=['RMSE  = ';'R     = ';'Q     = ';'ERGAS = '];
    TXT_2=strjust(num2str([rmse;r;qi;ergas],'%.3f'),'right');   
    text(0.05*(ax_max-ax_min),0.925*(ax_max-ax_min),[TXT_1,TXT_2],'FontName', 'Courier','FontSize',12,'FontWeight','bold','EdgeColor',[1 1 1],'BackgroundColor',[1 1 1],'Color',[0 0 0]);
   
end


% --- Executes on selection change in popRefBand.
function popRefBand_Callback(hObject, eventdata, handles)
% hObject    handle to popRefBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popRefBand contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popRefBand


% --- Executes during object creation, after setting all properties.
function popRefBand_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popRefBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popCompBand.
function popCompBand_Callback(hObject, eventdata, handles)
% hObject    handle to popCompBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popCompBand contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popCompBand


% --- Executes during object creation, after setting all properties.
function popCompBand_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popCompBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtRefScale_Callback(hObject, eventdata, handles)
% hObject    handle to txtRefScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRefScale as text
%        str2double(get(hObject,'String')) returns contents of txtRefScale as a double


% --- Executes during object creation, after setting all properties.
function txtRefScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtRefScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtPredScale_Callback(hObject, eventdata, handles)
% hObject    handle to txtPredScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtPredScale as text
%        str2double(get(hObject,'String')) returns contents of txtPredScale as a double


% --- Executes during object creation, after setting all properties.
function txtPredScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtPredScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popMethod.
function popMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popMethod


% --- Executes during object creation, after setting all properties.
function popMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
