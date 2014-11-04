function ScriptObjEditor(scriptName, soefig)

%  NewStim package
%
%  SCRIPTOBJEDITOR(SCRIPTNAME)
%
%  ScriptObjEditor brings up an editor for NewStim stimscript objects. It allows
%  one to graphically browse the stimulus objects inside the script and
%  edit
%  all aspects of the script. 
%  These operations are the following:
%
%  Update             - Update the editor's list of stimuli.  This is useful if
%                       a non-graphical script modifies the data in some way.
%  Help               - Display this file.
%  New                - Adds a new stimulus to the script.
%  Add                 -Adds a stimulus in memory to the script.
%  Load               - Tell the stimulus to load its images into memory.
%  Edit displayprefs  - Edit the displayprefs objects of the selected stimuli.
%  New Based on       - Add a stimulus based on a previous stimulus
%                       (only available when a single stimulus is selected).
%     (the following three options only available with Psychophysics toolbox)
%  Load               - Loads the selected stimuli into memory
%  Unload             - Unloads the selected stimuli from memory 
%  Strip              - Disassociates a stimulus from its memory structures
%                       without deleting the structures (useful if you have
%                       multiple copies of a stimulus).
%  Delete             - Remove the currently selected stimuli from the script.
%  
%  See 'DisplayMethod' help for help setting the order of presentation of the
%  stimuli.
% 

if ~ischar(scriptName),error('Argument to ScriptObjEditor must be a name.');end;
 %check to see if is command or scriptName
commands = {'Update', 'New', 'NewOK', 'Close','SetMethod', 'Method', 'Trigger',...
	    'Up', 'Down', 'Load', 'Unload', 'Strip', 'Add', 'Delete', ...
	    'Replace', 'EditDisplayPrefs','EnableDisable','Tile'};
iscmd = 0;
for i=1:length(commands),
	if strcmp(char(commands(i)),scriptName), iscmd=1;end;
end;

if iscmd==0,
	if ~isscriptname(scriptName),
		error([scriptName ' is not name of a stimscript.']);
	end;
	drawScriptObjEditor(scriptName);
	drawnow;
	theFig = gcf;
	ScriptObjEditor('Update',theFig);
else, % it is a callback command
	command = scriptName;
	theFig = gcbf;
	if isempty(theFig)&nargin~=2, theFig = gcf;
	elseif nargin==2, theFig = soefig; end;
	scriptstruct = get(theFig,'UserData');
	script=[];
	lb = scriptstruct.lb;
	if ~isscriptname(scriptstruct.scriptname),
		close(theFig);
		error([scriptstruct.scriptname ' no longer refers to '...
			'a stimscript.']);
	else, script=evalin('base',scriptstruct.scriptname); end;
	switch command,
		case 'Update',
			n = numStims(script);
			stims = get(script);
			g = {};
			for i=1:length(stims),
				g(i) = {class(stims{i})};
			end;
			set(lb,'String',g,'value',[]);
			g = getDisplayOrder(script);
			set(scriptstruct.dispord,'String',mat2str(g));
            dur = duration(script);
			
			set(scriptstruct.duration,'String',['Duration: ' ...
                num2str(fix(dur/60)) ':' ...  % minutes
                num2str(rem(fix(dur),60),'%02d') '.' ... % seconds
                num2str(fix( 10*(dur-fix(dur)))) ' m:s = ' num2str(dur,'%.1f') ' s' ]); % 10th
			ScriptObjEditor('Method',theFig);
			ScriptObjEditor('EnableDisable',theFig);
        case 'Tile'
            script = tile(script);
            assignin('base',scriptstruct.scriptname,...
					script);
            ScriptObjEditor SetMethod;
            ScriptObjEditor Update;
		case 'Help',
			g = help('ScriptObjEditor');
			textbox('ScriptObjEditor help',g);
  % display order stuff
		case 'Method',
			switch(get(scriptstruct.dispmeth,'value')),
			case 1, % sequential
				set(scriptstruct.dispord,'Style','text',...
				'BackgroundColor',[0.7 0.7 0.7]);
				set(scriptstruct.replabel,'enable','on');
				set(scriptstruct.repeat,'enable','on');
			case 2, % random
				set(scriptstruct.dispord,'Style','text', ...
				'BackgroundColor',[0.7 0.7 0.7]);
				set(scriptstruct.replabel,'enable','on');
				set(scriptstruct.repeat,'enable','on');
			case 3, % specified
				set(scriptstruct.dispord,'Style','edit', ...
				'BackgroundColor',[1 1 1]);
				set(scriptstruct.replabel,'enable','off');
				set(scriptstruct.repeat,'enable','off');
			end;
		case 'SetMethod',
			val = get(scriptstruct.dispmeth,'value');
            trigger_value = get(scriptstruct.trigger,'value');
            switch trigger_value
                case 1
                    trigger = 'none';
                case 2
                    trigger = 'interleaved';
                case 3
                    trigger = 'all';
            end
            
			if val<3,
				repstr=get(scriptstruct.repeat,'String');
				reps=0;
				go=1;
				try,eval(['reps=' repstr ';']);
				catch,errordlg('Syntax error in repeats');go=0;
				end;
				if go,
				 try,
				     script=setDisplayMethod(script,val-1,reps,trigger);
				     assignin('base',scriptstruct.scriptname,...
					script);
				     ScriptObjEditor Update;
				 catch,
				     errordlg(lasterr);
				 end;
				end;
			else % specified
				dispstr = get(scriptstruct.dispord,'String');
				go=1;
				try,eval(['do=' dispstr ';']);
				catch,errordlg('Syntax error in repeats');go=0;
				end;
				if go,
				  try,
				    script=setDisplayMethod(script,val-1,do,trigger);
				    assignin('base',scriptstruct.scriptname,...
			             script);
				    ScriptObjEditor Update;
				  catch,errordlg(lasterr); end;
			        end;
			end;
        case 'Trigger'    
            % val = get(scriptstruct.trigger,'value')
            % setting is handled by 'SetMethod' command

     % now the stimuli buttons
		case 'New',
		    z = gcbf;
		    stimlist = NewStimList;
		    [s,v]=listdlg('PromptString','Select a stimulus type',...
			'SelectionMode','single','ListString',stimlist);
		        if v,
				ty=char(stimlist(s));
				eval(['newstim = ' ty '(''graphical'');']);
				if ~isempty(newstim),
					script=append(script,newstim);
					assignin('base', ...
					  scriptstruct.scriptname,script);
					figure(z);
					ScriptObjEditor Update;
				end;
			end;
		case 'Add',
			z = gcbf;
			stimlist = listofvars('stimulus');
		       [s,v]=listdlg('PromptString','Select a stimulus',...
                        'SelectionMode','single','ListString',stimlist);
                        if v,
				ty=char(stimlist(s));
				newstim=evalin('base',[ty]);
				if ~isempty(newstim),
					script=append(script,newstim);
					assignin('base', ...
					scriptstruct.scriptname,script);
					figure(z);
					ScriptObjEditor Update;
                                end;
                        end;
		case 'Replace', % should really be New based on
			% should only happen when one stimulus is selected
			z = gcbf;
			val=int2str(get(lb,'value')); s=scriptstruct.scriptname;
			thestim=evalin('base',['get(' s ',' val ')']);
			ty = class(thestim);
			eval(['newstim = ' ty '(''graphical'',thestim);']);
			if ~isempty(newstim),
				script=append(script,newstim);
				assignin('base',scriptstruct.scriptname,script);
				figure(z);
				ScriptObjEditor Update;
			end;
		case 'Load', % should only happen if selected stims
			vals = get(lb,'value');
		  	for i=1:length(vals),
				v=int2str(vals(i));
				s=scriptstruct.scriptname;
				evalin('base',['set(' s ',loadstim(get(' s ',' v ')),' v ');']);
			end;
		case 'unload', % should only happen if selected stims
			vals = get(lb,'value');
		  	for i=1:length(vals),
				v=int2str(vals(i));
				s=scriptstruct.scriptname;
				evalin('base',['set(' s ',unloadstim(get(' s ',' v ')),' v ');']);
			end;
		case 'Strip', % should only happen if selected stims
			vals = get(lb,'value');
		  	for i=1:length(vals),
				v=int2str(vals(i));
				s=scriptstruct.scriptname;
				evalin('base',['set(' s ',strip(get(' s ',' v ')),' v ');']);
			end;
		case 'EditDisplayPrefs',
			dpl = repmat(displaystruct({}),0,0);
			vals = get(lb,'value');
		  	for i=1:length(vals),
				dpl(i)=getdisplayprefs(get(script,vals(i)));
			end;
			dpln=editdisplayprefs(dpl);
			if ~isempty(dpln),
				for i=1:length(vals),
					stim = get(script,vals(i));
					stim = setdisplayprefs(stim,dpln(i));
					script=set(script,stim,vals(i));
				end;
			end;
			assignin('base',scriptstruct.scriptname,script);
			ScriptObjEditor Update;
		case 'Delete',
			vals = get(lb,'value');
		  	for i=1:length(vals),
				v=int2str(vals(i));
				s=scriptstruct.scriptname;
				evalin('base',[s '=remove(' s ',' v ');']);
				vals = vals-1;
			end;
			ScriptObjEditor Update;
		case 'Close',
			close(gcbf);
		case 'EnableDisable'
			strs = get(lb,'String');
			if length(strs)>0,
			else,
			end;
			strs = lb_getselected(lb);
			set(scriptstruct.new,'enable','on');
			set(scriptstruct.add,'enable','on');
			set(scriptstruct.moveup,'enable','off');
			set(scriptstruct.movedown,'enable','off');
			if length(strs)>0,
				set(scriptstruct.editdp,'enable','on');
				set(scriptstruct.delete,'enable','on');
				if length(strs)==1,
					set(scriptstruct.replace,'enable','on');
				else,  set(scriptstruct.replace,'enable','off');
				end;
				if haspsychtbox,
				   set(scriptstruct.load,'enable','on');
				   set(scriptstruct.unload,'enable','on');
				   set(scriptstruct.strip,'enable','on');
				else,
				   set(scriptstruct.load,'enable','off');
				   set(scriptstruct.unload,'enable','off');
				   set(scriptstruct.strip,'enable','off');
				end;
			else,
				set(scriptstruct.editdp,'enable','off');
				set(scriptstruct.delete,'enable','off');
				set(scriptstruct.editdp,'enable','off');
				set(scriptstruct.replace,'enable','off');
				set(scriptstruct.load,'enable','off');
				set(scriptstruct.unload,'enable','off');
				set(scriptstruct.strip,'enable','off');
			end;
			if ~haspsychtbox,
				set(scriptstruct.load,'enable','off');
				set(scriptstruct.unload,'enable','off');
				set(scriptstruct.strip,'enable','off');
			end;
	end;
end;

function b = isscriptname(sn)
b=1; try, g = evalin('base',sn); catch, b=0; end;

function makeNewFig(figNum)

h0 = figure('Color',[0.8 0.8 0.8], ...
        'PaperPosition',[18 180 576 432], ...
        'PaperUnits','points', ...
        'Position',[302 204 550 239], ...
        'Tag','Fig2', ...
        'MenuBar','none');
		settoolbar(h0,'none');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[71.2 9.6 63.2 24.8], ...
        'String','OK', ...
        'Tag','Pushbutton1','Callback','ScriptObjEditor NewOK');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontSize',14, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[14.4 40 50.4 19.2], ...
        'String','Name:', ...
        'Style','text', ...
        'Tag','StaticText1');
namectl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[68.8 37.6 197.6 24.8], ...
        'Style','edit', ...,
	'HorizontalAlignment','left',...
        'Tag','EditText1');
lb = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'Position',[19.2 80 244 77.6], ...
        'String',NewStimList, ...
        'Style','listbox', ...
        'Tag','Listbox1', ...
        'Value',1);
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontSize',14, ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[10.4 163.2 100.8 17.6], ...
        'String','Stimulus Type:', ...
        'Style','text', ...
        'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[152.8 9.6 63.2 24.8], ...
        'String','Cancel', ...
        'Tag','Pushbutton1','Callback','close(gcbf);');
set(h0,'UserData',struct('lb',lb,'name',namectl,'parentFig',figNum));


function drawScriptObjEditor(scriptName)

h0 = figure('Color',[0.8 0.8 0.8], ...
        'PaperUnits','points', ...
        'Position',[408   134   580   530], ...
        'Tag','Fig1', ...
        'MenuBar','none','Name','Display Order','NumberTitle','off');
		settoolbar(h0,'none');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8 ], ...
        'FontSize',16, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[15.369 345 80 40], ...
        'String','Editing Script:', ...
        'Style','text', ...
        'Tag','StaticText1');
sname_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8 ], ...
        'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'ListboxTop',0, ...
        'Position',[15.369 325 65 19], ...
        'String',scriptName,...
        'Style','text', ...
        'Tag','StaticText1');
dmx=-175;dmy=210;
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'ListboxTop',0, ...
        'Position',[269.91972+dmx 1.9211368+dmy 334.277805 175.784],...
        'Style','frame', ...
        'Tag','Frame1');
h1 = uicontrol('Parent',h0, ...
	'Units','points',...
	'BackgroundColor',[0.7 0.7 0.7], ...
	'ListboxTop',0,...
	'HorizontalAlignment','left',...
	'Position',[280+dmx 145+dmy 125 22],...
	'String','Set Display Order:', ...
	'fontsize',12,'fontweight','bold', ...
	'Tag','StaticText10','Style','text');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'ListboxTop',0, ...
        'Position',[475.4892+dmx  149+dmy  125.2572   22.0931], ...
        'String','DisplayMethod Help', ...
        'Tag','Pushbutton1','Callback',...
	'textbox(''DisplayMethod help'',help(''setDisplayMethod''));');
dispord_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7], ...
        'ListboxTop',0, ...
	'Fontsize',9,'Max',2,...
        'Position',[278.56+dmx 12.659+dmy 321.79 49.94], ...
        'Style','text', ...
        'Tag','EditText1');
dispparam_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[280.4859+dmx 64.53+dmy 144.08 18.250], ...
        'String','Display Order:', ...
        'Style','text', ...
        'Tag','StaticText4');
dispmeth_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[335.65+dmx 112.465+dmy 80.67 23.05], ...
        'String',{'sequential','random','specified'}, ...
        'Style','popupmenu', ...
        'Tag','PopupMenu1', ...
        'Value',1,'Callback','ScriptObjEditor Method');

    
trigger_txt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[280.4859+dmx 89.53+dmy 144.08 18.250], ...
        'String','Optogenetics:', ...
        'Style','text', ...
        'Tag','StaticText4');

    
trigger_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[375.65+dmx 87.465+dmy 80.67 23.05], ...
        'String',{'none','interleaved','all'}, ...
        'Style','popupmenu', ...
        'Tag','popup_trigger', ...
        'Value',1,'Callback','ScriptObjEditor Trigger');

    
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[280.4859+dmx 112.3865+dmy 52.99 18.25], ...
        'String','Method:', ...
        'Style','text', ...
        'Tag','StaticText4');
replabel_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[424.4859+dmx 112.3865+dmy 54.99 18.25], ...
        'String','Repeats:', ...
        'Style','text', ...
        'Tag','StaticText4');
rep_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'ListboxTop',0, ...
        'Position',[484.4859+dmx 114.3865+dmy 44.99 18.25], ...
        'String','1', ...
        'Style','edit', ...
        'Tag','StaticText4');
setit_ctl = uicontrol('Parent',h0,...
	'Units','points',...
	'BackgroundColor',[0.7 0.7 0.7],...
	'FontSize',12,'FontWeight','bold',...
	'HorizontalAlignment','center',...
	'ListboxTop',0,'Position',[555.4859+dmx 114.3865+dmy 44.99 18.25], ...
	'String','Set it', 'Style','pushbutton','Tag','PushButton5',...
	'Callback','ScriptObjEditor SetMethod');
totdur_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[300+dmx    9.6057+dmy  400.7556   16.3297], ...
        'String','Total duration:', ...
        'Style','text', ...
        'Tag','StaticText3');
stx=-15;sty=-245;
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'ListboxTop',0, ...
        'Position',[5  5  425 205], ...
        'Style','frame', ...
        'Tag','Frame2');
lb = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'Position',[120 10 250  193.0742], ...
        'String',' ', ...
        'Style','listbox', ...
        'Tag','Listbox1', ...
        'Max',2,'Value',[],'Callback','ScriptObjEditor EnableDisable');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[10  175  110   19], ...
	'HorizontalAlignment','center',...
        'String','Stimuli', ...
        'Style','text', ...
        'Tag','StaticText2');
new_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 396+sty 98.938 19], ...
        'String','New', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor New');
add_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 376+sty 98.938 19], ...
        'String','Add', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor Add');
editdp_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 336+sty 98.938 19], ...
        'String','Edit displayprefs', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor EditDisplayPrefs');
replace_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 356+sty 98.9385 19], ...
        'String','New based on...', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor Replace');
load_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 316+sty 98.9385 19], ...
        'String','Load', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor Load');
unload_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 296.01+sty 98.9385 19], ...
        'String','Unload', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor Unload');
strip_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 276+sty 98.9385 19], ...
        'String','Strip', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor Strip');
delete_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7 ], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[30.738+stx 256+sty 98.9385 19], ...
        'String','Delete', ...
        'Tag','Pushbutton2','Callback','ScriptObjEditor Delete');
moveup_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[375 120 48.9385 19], ...
        'String','up', ...
        'Tag','Pushbutton2');
movedown_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.7 0.7 0.7], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[375  80   48.9385   19], ...
        'String','down', ...
        'Tag','Pushbutton2');
tile_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[10 280 79.727 19], ...
        'String','Tile', ...
        'Tag','Pushbutton3','Callback','ScriptObjEditor Tile');
update_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[10 260 79.727 19], ...
        'String','Update', ...
        'Tag','Pushbutton3','Callback','ScriptObjEditor Update');
help_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[10 240 79.727 19], ...
        'String','Help', ...
        'Tag','Pushbutton3','Callback',...
	'textbox(''ScriptObjEditor Help'',help(''ScriptObjEditor''));');
save_ctl = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[10 220 79.727 19], ...
        'String','Close', ...
        'Tag','Pushbutton3','Callback','ScriptObjEditor Close');
%close_ctl = uicontrol('Parent',h0, ...
%        'Units','points', ...
%        'BackgroundColor',[0.8 0.8 0.8], ...
%        'FontWeight','bold', ...
%        'ListboxTop',0, ...
%        'Position',[139.2824 43.2255 79.727 26.8959], ...
%        'String','', ...
%        'Tag','Pushbutton3');
set(h0,'UserData',struct('update',update_ctl,'help',help_ctl,'save',save_ctl,...
		'add',add_ctl,'moveup',moveup_ctl,'scriptname',scriptName,...
		'movedown',movedown_ctl,'delete',delete_ctl,...
		'setit',setit_ctl,'scriptnamectl',sname_ctl,...
		'strip',strip_ctl,'unload',unload_ctl,...
		'load',load_ctl,'replace',replace_ctl,'new',new_ctl,...
		'lb',lb,'dispmeth',dispmeth_ctl,'dispparm',dispparam_ctl,...
		'dispord',dispord_ctl,'duration',totdur_ctl,...
		'editdp',editdp_ctl,'replabel',replabel_ctl,'repeat',rep_ctl,...
        'trigger',trigger_ctl,...
		'tag','ScriptObjEditor'));
