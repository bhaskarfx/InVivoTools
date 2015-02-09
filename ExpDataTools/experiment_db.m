function fig=experiment_db( type, hostname )
%EXPERIMENT_DB starts physiology database
%
%   FIG=EXPERIMENT_DB
%   FIG=EXPERIMENT_DB( TYPE )
%   FIG=EXPERIMENT_DB( TYPE, HOSTNAME )
%
%     TYPE can be 'oi','ec','tp','wc'
%     FIG returns handle to the database control figure
%
% 2005-2014, Alexander Heimel
%

if nargout==1
    fig=[];
end

color = 0.7*[1 1 1];

if nargin < 1
    type=[];
end
if isempty(type)
    type='oi';
end

if nargin<2
    hostname = host;
    if ~isempty(hostname)
        logmsg(['Working on host ' hostname ]);
    end
end

%defaults
select_all_of_name_enabled=0;
blind_data_enabled = 0;
reverse_data_enabled = 0;
open_data_enable = 0;
channels_enabled = 0;
average_tests_enabled=0;
export_tests_enabled=0;

switch type
    case 'ec'
        channels_enabled = 1;
    case 'tp' 
        color = [0.4 0.5 1];
        open_data_enable = 1;
        blind_data_enabled = 1;
        reverse_data_enabled = 1; % for reversing database
    case 'ls' % linescans
        color = [0.8 0.6 0];
end

% get which database
[testdb, experimental_pc] = expdatabases( type, hostname );

% load database
[db,filename]=load_testdb(testdb);

if isempty(db)
    return
end

% temporarily adding anesthetic field % 2013-03-18
switch type
    case {'tp','oi','ec'}
        if ~isfield(db,'anesthetic')
            for i=1:length(db)
                db(i).anesthetic = '';
            end
            stat = checklock(filename);
            if stat~=1
                filename = save_db(db,filename,'');
                rmlock(filename);
            end
        end
end
% temporarily adding analysis field % 2014?
switch type
    case {'ec'}
        if ~isfield(db,'analysis')
            for i=1:length(db)
                db(i).analysis = '';
            end
            stat = checklock(filename);
            if stat~=1
                filename = save_db(db,filename,'');
                rmlock(filename);
            end
        end
end
% temporarily adding channel info 2014-03-25
switch type
    case {'ec'}
        if ~isfield(db,'channel_info')
            for i=1:length(db)
                db(i).channel_info = '';
            end
            stat = checklock(filename);
            if stat~=1
                filename = save_db(db,filename,'');
                rmlock(filename);
            end
        end
end
% temporarily adding eye field % 2014?
switch type
    case {'tp'}
        if ~isfield(db,'eye') 
            for i=1:length(db)
                db(i).eye = '';
            end
            stat = checklock(filename);
            if stat~=1
                filename = save_db(db,filename,'');
                rmlock(filename);
            end
        end
end

if isfield(db,'comment')
    % Temp removal for multiline comments
    multiline = false;
    for i=1:length(db)
        if size(db(i).comment,1)>1 && ischar(db(i).comment)% i.e. multiline
            db(i).comment = flatten(db(i).comment')';
            multiline = true;
        end
    end
    if multiline
        logmsg('Flattened multiline comments');
        stat = checklock(filename);
        if stat~=1
            filename = save_db(db,filename,'');
            rmlock(filename);
        end
    end
end

% start control database
switch testdb
    case {'testdb','ectestdb'}
        h_fig=control_db(db,color);
    otherwise
       h_fig=control_db(filename,color); 
end
if isempty(h_fig)
    return
end
ud = get(h_fig,'Userdata');
ud.type = type;

set(h_fig,'Userdata',ud);
set_control_name(h_fig);

if nargout==1
    fig=h_fig;
end

maxleft=0;
left=10;
buttonwidth=65;
colsep=3;
buttonheight=30;
top=10;

ud=get(h_fig,'UserData');
h=ud.h;

% set customize sort to sort button
set(h.sort,'Tag','sort_testrecords');
set(h.sort,'Enable','on'); % enable sort button

if haspsychtbox || experimental_pc
    runexperiment_enabled = 1;
else
    runexperiment_enabled = 0;
end

if experimental_pc
    % check diskusage
    df=diskusage(eval([type 'datapath']));
    if df.available < 11000000
        errormsg('Less than 11 Gb available on /home/data. Clean up disk!');
    end
end

if strcmp(host,'wall-e')
    h.laser = ...
        uicontrol('Parent',h.fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','control_lasergui', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'String','Laser', ...
        'Tag','Laser',...
        'Tooltipstring','Close all non-persistent figures');
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

if runexperiment_enabled
    h.runexperiment = ...
        uicontrol('Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'Tag','run_callback',...
        'String','Stimulus');
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

if open_data_enable
    h.open = ...
        uicontrol('Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'String','Open','Tag','open_tptestrecord_callback');
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

h.analyse = ...
    uicontrol('Parent',h_fig, ...
    'Units','pixels', ...
    'BackgroundColor',0.8*[1 1 1],...
    'Callback','genercallback', ...
    'ListboxTop',0, ...
    'Position',[left top buttonwidth buttonheight], ...
    'String','Analyse' );
left=left+buttonwidth+colsep;
maxleft=max(maxleft,left);

h.results = ...
    uicontrol('Parent',h_fig, ...
    'Units','pixels', ...
    'BackgroundColor',0.8*[1 1 1],...
    'Callback','genercallback', ...
    'ListboxTop',0, ...
    'Position',[left top buttonwidth buttonheight], ...
    'String','Results');
left=left+buttonwidth+colsep;
maxleft=max(maxleft,left);

h.which_test = ...
    uicontrol('Parent',h_fig, ...
    'Style','popupmenu',...
    'Units','pixels', ...
    'BackgroundColor',0.8*[1 1 1],...
    'Callback','genercallback', ...
    'ListboxTop',0, ...
    'Position',[left top-0.1*buttonheight buttonwidth buttonheight], ...
    'Value',1,...
    'Tag','');
left=left+buttonwidth+colsep;
maxleft=max(maxleft,left);

if average_tests_enabled
    h.average_tests = ...
        uicontrol('Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'Tag','average_tests',...
        'String','Average');
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

if export_tests_enabled
    h.export_tests = ...
        uicontrol('Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'Tag','export_tests',...
        'String','Export');
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

if select_all_of_name_enabled
    h.selectname = ...
        uicontrol('Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'TooltipString','Selects all records of the current mouse',...
        'Tag','tptestdb_selectname',...
        'String','Select'); %#ok<UNRCH>
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

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
left=left+buttonwidth+colsep;
maxleft=max(maxleft,left);


if blind_data_enabled
    h.blind = ...
        uicontrol('Style','toggle','Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'TooltipString','Blinds and shuffles database',...
        'Tag','blinding_tpdata',...
        'String','Blind');
    if ~strcmp(host,'wall-e') % i.e. no laser button
        left=left+buttonwidth+colsep;
    else
        top = top + buttonheight + colsep;

    end
    maxleft=max(maxleft,left);
end

if reverse_data_enabled
    h.reverse = ...
        uicontrol('Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',0.8*[1 1 1],...
        'Callback','genercallback', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'TooltipString','Reverses database',...
        'Tag','reverse',...
        'String','Reverse');
    left=left+buttonwidth+colsep;
    maxleft=max(maxleft,left);
end

if channels_enabled
    h.channels = ...
        uicontrol('Style','edit','Parent',h_fig, ...
        'Units','pixels', ...
        'BackgroundColor',1*[1 1 1],...
        'Callback','', ...
        'ListboxTop',0, ...
        'Position',[left top buttonwidth buttonheight], ...
        'TooltipString','Which channels to analyse',...
        'Tag','channels_edit',...
        'String','        ');
    maxleft=max(maxleft,left);
end

ud.h=h;
set(h_fig,'UserData',ud);

set(h.analyse,'Tag','analyse_testrecord_callback');

set(h.results,'Enable','on');
set(h.results,'Tag',['results_' type 'testrecord_callback']);
set(h.new,'Callback',...
    ['ud=get(gcf,''userdata'');ud=new_' type 'testrecord(ud);' ...
    'set(gcf,''userdata'',ud);control_db_callback(ud.h.current_record);']);

avname = ['available_' type 'tests'];
if exist(avname,'file')
    set(h.which_test,'String',eval(['available_' type 'tests']));
else
    set(h.which_test,'String','');
    set(h.which_test,'visible','off');
end

% make figure wide enough
pos=get(h_fig,'Position');
pos(3)=max(maxleft,pos(3));
set(h_fig,'Position',pos);

% set current record
control_db_callback( h.current_record );
control_db_callback( h.current_record );

