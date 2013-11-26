function fig=mouse_db
%MOUSE_DB starts imaging mouse database
%
%  FIG=MOUSE_DB
%
% 2005, Alexander Heimel
%

%[mousedb,filename] = load_mousedb;

%[dbpath,dbfilename]=fileparts(filename);
%dbfile=fullfile(dbpath,dbfilename);

filename = fullfile(expdatabasepath, 'mousedb.mat');

if ~exist(filename,'file')
    disp(['MOUSE_DB: ' filename ' does not exist.']);
    return
end

h_fig=control_db(filename,[1 1 0]); 
if isempty(h_fig)
    return
end

set(h_fig,'Name',['Mouse database']);



if nargout==1
  fig=h_fig;
end

left=10;
buttonwidth=65;
colsep=3;
buttonheight=30;
top=10;

maxleft = 0;

% extra buttons:
ud=get(h_fig,'UserData');
h=ud.h;

h.cageform = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth+30 buttonheight], ...
  'String','Welfare form', ...
  'Tag','generate_cageform');
left=left+buttonwidth+30+colsep;
maxleft=max(maxleft,left);

h.schedule = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth+5 buttonheight], ...
  'String','Schedule', ...
  'Tag','make_schedule');
left=left+buttonwidth+5+colsep;
maxleft=max(maxleft,left);

h.next_mousenumber = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top 1.5*buttonwidth buttonheight], ...
  'String','Next number', ...
  'Tag','next_mousenumber');
left=left+1.5*buttonwidth+colsep;
maxleft=max(maxleft,left);

h.list = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top 0.7*buttonwidth buttonheight], ...
  'String','List', ...
  'Tag','make_list');
left=left+0.7*buttonwidth+colsep;
maxleft=max(maxleft,left);


h.orderform = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth+20 buttonheight], ...
  'String','Order form', ...
  'Tag','generate_orderform');
left=left+buttonwidth+20+colsep;
maxleft=max(maxleft,left);

%h.summary = ...
%  uicontrol('Parent',h_fig, ...
%  'Units','pixels', ...
%  'BackgroundColor',0.8*[1 1 1],...
%  'Callback','genercallback', ...
%  'ListboxTop',0, ...
%  'Position',[left top buttonwidth buttonheight], ...
%  'String','Summary', ...
%  'Tag','make_summary');
%left=left+buttonwidth+colsep;


h.mdb = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth buttonheight], ...
  'String','Info', ...
  'Tag','show_mouseinfo');
%left=left+buttonwidth+colsep; %#ok<NASGU>
%maxleft=max(maxleft,left);

top = top + buttonheight + colsep; 
h.close_figs = ...
    uicontrol('Parent',h.fig, ...
    'Units','pixels', ...
    'BackgroundColor',0.8*[1 1 1],...
    'Callback','genercallback', ...
    'ListboxTop',0, ...
    'Position',[left top buttonwidth buttonheight], ...
    'String','Close figs', ...
    'Tag','close figs',...
    'Tooltipstring','Close all non-persistent figures');
left=left+buttonwidth+colsep; %#ok<NASGU>
maxleft=max(maxleft,left);



% make figure wide enough
pos=get(h_fig,'Position');
pos(3)=max(maxleft,pos(3));
set(h_fig,'Position',pos);

ud.h=h;
ud.type = 'mouse';
set(h_fig,'UserData',ud);
set_control_name(h_fig);

control_db_callback( h.current_record );


