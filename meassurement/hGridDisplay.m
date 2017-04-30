function hGridDisplay(grid,varargin)

%%
% Initialize aggregation level
AggregationLevel = 1;


% Initialize antenna port to visualize
if nargin==2
    AntennaPort = varargin{1};
else
    AntennaPort = 1;
end

% figure out maximum of antennas
MaxAntenna = size(grid,3); 
    

%% Define all the widgets

fPosition = [104 5 154 42];
f = figure('Visible','off', ...
    'Units','characters',...
    'Position',fPosition,...
    'Resize','on',...
    'ResizeFcn', {@resizeCallback},...
    'MenuBar','none',...
    'Name','LTE Subframe Grid Before Transmission');

% Left margin for bottom of the display
LeftMargin = 6;

%Make the GUI visible.
set(f,'Visible','on')

% Display area
haxes = axes(...
    'Parent',f,...
    'Units','characters',...
    'Position',AxesPosition(fPosition),...
    'Tag','axes1',...
    'Tag','figure1',...
    'CreateFcn', {@CreateAxes, grid, AggregationLevel,AntennaPort} , ...
    'Visible','on' ...
    );
% Enable zoom in the window but only in the vertical direction
h = zoom(haxes);
set(h,'Motion','vertical','Enable','on');

% Text for aggregation level
hTextAggregation = uicontrol(...
    'Units','characters',...
    'Parent', f, ...
    'FontSize',12,...
    'Position',[LeftMargin 1 26 2],...
    'String','Granularity in REs',...
    'HorizontalAlignment','left', ...
    'Style','text',...
    'Visible', 'on', ...
    'Tag','TextAggregation'...
    );

% Popup menu for aggregation level
hAggregationLevel = uicontrol(...
    'Units','characters',...
    'Parent', f, ...
    'Callback',{@AggregationLevel_Callback},...
    'BackgroundColor',[1 1 1],...
    'FontSize',12,...
    'Position',PopupPosition(fPosition,LeftMargin),...
    'String',{  'Pop-up Menu' },...
    'Style','popupmenu',...
    'Value',1,...
    'Visible', 'on', ...
    'Tag','AggregationLevel');

% Text for antenna number
hTextAntennaPort = uicontrol(...
    'Units','characters',...
    'Parent', f, ...
    'FontSize',12,...
    'Position',[LeftMargin 3 26 2],...
    'String','Antenna Number',...
    'HorizontalAlignment','left', ...
    'Style','text',...
    'Visible', 'on', ...
    'Tag','TextAggregation'...
    );

% Popup menu for antenna number
hAntennaPort = uicontrol(...
    'Units','characters',...
    'Parent', f, ...
    'Callback',{@AntennaPort_Callback},...
    'BackgroundColor',[1 1 1],...
    'FontSize',12,...
    'Position',PopupPosition(fPosition,LeftMargin)+[0 1 0 1],...
    'String',{  'Pop-up Menu' },...
    'Style','popupmenu',...
    'Value',1,...
    'Visible', 'on', ...
    'Tag','AggregationLevel');

% Make widgets available in handles structure
handles.Widgets.figure = f;
handles.Widgets.axes = haxes;
handles.Widgets.AggregationLevel = hAggregationLevel;
handles.Widgets.TextAggregation = hTextAggregation;
handles.Widgets.AntennaPort = hAntennaPort;
handles.Widgets.TextAntennaPort = hTextAntennaPort;

% Define aggregation levels

AggregationChoices = {'1','6', '12'};
set(handles.Widgets.AggregationLevel,'String',AggregationChoices);

% Define antenna ports
AntennaPortChoices = cell(1,MaxAntenna);
for ii=1:MaxAntenna
    AntennaPortChoices{ii} = ii;
end;
set(handles.Widgets.AntennaPort,'String',AntennaPortChoices);

% Create legend
xOffset = 20;  % Offset between two columns in the legend
% Get list of colors
ColorArray = ListColors();
ChannelCell = {'Unused','RefSig','PBCH','PSS/SSS','PDSCH','PDCCH','PCFICH','PHICH','DMRS'};
for ii=1:numel(ChannelCell)/2
    ind = 2*ii;
    % Start with color nr 2 because first one is all black
    legendEntry(ChannelCell{ind-1},3,(ii-1)*xOffset,ColorArray(ind,:),LeftMargin);
    legendEntry(ChannelCell{ind},1,(ii-1)*xOffset,ColorArray(ind+1,:),LeftMargin);
end
% Add last one
ii = floor(numel(ChannelCell)/2+1);
ind = 2*ii;
legendEntry(ChannelCell{ind-1},3,(ii-1)*xOffset,ColorArray(ind,:),LeftMargin);

% Input grid
handles.Data.grid = grid;
handles.Data.AntennaPortValue = 1;
handles.Data.AggregationLevel = 1;

guidata(f,handles)


function resizeCallback(source, eventdata)
handles = guidata(gcbo);
% Get position of resized figure
dim = get(source,'Position');
% Scale display accordingly
try
    set(handles.Widgets.axes,'Position',AxesPosition(dim) );
end
guidata(gcbo, handles);

function AggregationLevel_Callback(source, eventdata)
handles = guidata(gcbo);

contents = cellstr(get(source,'String'));
Value = contents{get(source,'Value')};
% index = get(source,'Value');
AggregationLevel = str2double(Value);
handles.Data.AggregationLevel = AggregationLevel;
% helperPlotResourceGrid(handles.Data.grid,AggregationLevel);
CreateAxes(source, eventdata, handles.Data.grid, ...
              handles.Data.AggregationLevel,handles.Data.AntennaPortValue);
guidata(gcbo,handles)

function AntennaPort_Callback(source, eventdata)
handles = guidata(gcbo);

contents = cellstr(get(source,'String'));
Value = contents{get(source,'Value')};
% index = get(source,'Value');
AntennaPortValue = str2double(Value);
handles.Data.AntennaPortValue = AntennaPortValue;
% helperPlotResourceGrid(handles.Data.grid(:,:,AntennaPortValue),AggregationLevel);
CreateAxes(source, eventdata, handles.Data.grid, ...
              handles.Data.AggregationLevel,handles.Data.AntennaPortValue);
guidata(gcbo,handles)

% Initial creation of the function
function CreateAxes(source, eventdata, grid, AggregationLevel,AntennaPort)
helperPlotResourceGrid(grid(:,:,AntennaPort),AggregationLevel);

function y = AxesPosition(x)
% Input is position of figure
% Output is position of axes inside that figure
leftMargin = 15;
rightMargin = 15;
bottomMargin = 9;
topMargin = 5;
width = max(1,x(3)- leftMargin - rightMargin);
height = max(1,x(4)- bottomMargin - topMargin);
y = [leftMargin bottomMargin width height];

function y = PopupPosition(x, LeftMargin)
% Input is position of figure
% Output is position of pop up position
leftOffset = 30 + LeftMargin;
rightMargin = 2;
bottomMargin = 1;
topMargin = 5;
targetWidth = 10;
targetHeight = 2;
width = max(1,min(targetWidth,x(3)- leftOffset - rightMargin));
height = max(1,min(targetHeight,x(4)- bottomMargin - topMargin));
y = [leftOffset bottomMargin width height];

%% Create one legend entry as color + text
function legendEntry(Text, posY, posX, color, LeftMargin)
uicontrol(...
    'Units','characters',...
    'Position',[45+LeftMargin+posX posY 5 2],...
    'BackgroundColor',color,...
    'Style','text',...
    'Tag',sprintf('col%s',Text) ...
    );

uicontrol(...
    'Units','characters',...
    'FontSize',10,...
    'Position',[52+LeftMargin+posX posY 12 2],...
    'String',{  Text },...
    'HorizontalAlignment','left', ...
    'Style','text',...
    'Tag',sprintf('legend%s',Text) ...
   );