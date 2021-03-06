function fig=graph_db( create )
%GRAPH_DB starts graph database
%
%  FIG=GRAPH_DB( CREATE )
%     If CREATE is true, creates new database if it doesn't exist.
%
% 2007-2013, Alexander Heimel
%

if nargin<1 || isempty(create)
    create = false;
end

clear functions

[db,filename]=load_graphdb( create);
if isempty(db)
   logmsg('Empty graph database.');
   return
end

h_fig=control_db(filename,[0 1 1]); % which will load the file again
if isempty(h_fig)
    return
end

if nargout==1
  fig=h_fig;
end

left=10;
buttonwidth=70;
colsep=3;
buttonheight=30;
top=10;

% extra buttons:
ud=get(h_fig,'UserData');
h=ud.h;

h.compute = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth buttonheight], ...
  'String','Compute','Tag','graphdb_compute' );
left=left+buttonwidth+colsep;

h.show = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth buttonheight], ...
  'String','Show' , 'Tag','graphdb_show');
left=left+buttonwidth+colsep;

h.groupdb = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth buttonheight], ...
  'String','Groups','Tag','graphdb_groupdb' );
left=left+buttonwidth+colsep;

h.measuredb = ...
  uicontrol('Parent',h_fig, ...
  'Units','pixels', ...
  'BackgroundColor',0.8*[1 1 1],...
  'Callback','genercallback', ...
  'ListboxTop',0, ...
  'Position',[left top buttonwidth buttonheight], ...
  'String','Measures','Tag','graphdb_measuredb' );
left=left+buttonwidth+colsep;

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

h.assignin_figs = ...
    uicontrol('Parent',h.fig, ...
    'Units','pixels', ...
    'BackgroundColor',0.8*[1 1 1],...
    'Callback', @assignud2base, ...
    'ListboxTop',0, ...
    'Position',[left top buttonwidth buttonheight], ...
    'String','Assignin', ...
    'Tag','Assign2base',...
    'Tooltipstring','Assignin ud');
left=left+buttonwidth+colsep;

ud.h=h;
ud.type = 'graph';
set(h_fig,'UserData',ud);
set_control_name(h_fig);

pos_control = get(h_fig,'Position');
pos_record = get(ud.record_form,'Position');
pos_record(3) = pos_control(3);
set(ud.record_form,'Position',pos_record);

function assignud2base(hObject, cbdata)
   % h = hObject.parent;
    hP = get(hObject, 'Parent');
    ud = get(hP, 'Userdata');
    assignin('base', 'ud', ud)

