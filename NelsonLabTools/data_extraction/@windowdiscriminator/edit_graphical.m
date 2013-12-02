function [nwd] = edit_graphical(thewd,arg2,arg3,fig)

%  NWD = EDIT_GRAPHICAL(WD)
%
%  Allows for graphical editing of parameters for WINDOWDISCRIMINATOR WD.
%
%  EDIT_GRAPHICAL(WD,'NAME')
%
%  Allows editing of the WINDOWDISCRIMINATOR object WD with name 'NAME' in the main
%  workspace.
%
%  EDIT_GRAPHICAL(WD,CKSDIRSTRUCT)
%  Allows editing of WD.  When the user selects "Select Data", then the user is
%  prompted to select data from the CKSDIRSTRUCT.
%
%  EDIT_GRAPHICAL(WD,STRUCT.NAME,STRUCT.CKSDIRSTRUCT)
%  Combines the above two methods of calling.
%
%  See also:  WINDOWDISCRIMINATOR

name = '';cksds=[];
if nargin<=2,
    isname = 0;
    wd = thewd;
    if nargin==2,
      try,
	isname = 1;
        if ischar(arg2),
          name=arg2;
  	  wd=evalin('base',name);
	  if ~strcmp(class(wd),'windowdiscriminator'),
		error([name ' is not a windowdiscriminator.']); end;
        elseif isstruct(arg2),
          isname = 1; name = arg2.name; cksds = arg2.cksdirstruct;
          wd = evalin('base',name);
	  if ~strcmp(class(wd),'windowdiscriminator'),
		error([name ' is not a windowdiscriminator.']); end;
        elseif isa(arg2,'cksdirstruct'),
          isname = 0; cksds = arg2;
        end;
      catch, error(lasterr); end;
    end;
    z = geteditor('extracttool');
    params=buildwindow(wd,isname,~isempty(z),name,cksds);
    if ~isname
	if isempty(params), nwd = thewd;
	else, nwd = windowdiscriminator(params); end;
    end;
else, % manage the command (arg3)
	if nargin==4, theFig = fig; else, theFig = gcbf; end;
	estruct = get(theFig,'userdata');
	switch(arg3),
		case 'OK',
			p = checkinput(theFig);
			if ~isempty(p),
				wdnew = windowdiscriminator(p);
				assignin('base',estruct.wdname,wdnew);
				if ~isempty(estruct.browsewind)&ishandle(estruct.browsewind),
					delete(estruct.browsewind);
				end;
				delete(theFig);
			end;
		case 'Apply',
			p = checkinput(theFig);
			if ~isempty(p),
				wdnew = windowdiscriminator(p);
				assignin('base',estruct.wdname,wdnew);
			end;
		case 'Cancel',
			if ~isempty(estruct.browsewind)&ishandle(estruct.browsewind),
				delete(estruct.browsewind);
			end;
			delete(theFig);
		case 'BrowseData',
			if isempty(estruct.browsewind)|~ishandle(estruct.browsewind),
				estruct.browsewind = makebrowsedata(theFig,...
					get(estruct.threshmethodpopup,'value'),...
					get(estruct.thresh1,'String'),...
					get(estruct.thresh2,'String'),thewd);
				set(theFig,'userdata',estruct);
			else,   figure(estruct.browsewind); end;
		case 'BDok',
			if ishandle(estruct.browsewind),
			   ud = get(estruct.browsewind,'userdata');
			   set(estruct.thresh1,'String',get(ud.thresh1,'String'));
			   set(estruct.thresh2,'String',get(ud.thresh2,'String'));
			   set(estruct.threshmethodpopup,'value',get(ud.threshmethodpopup,'value'));
			   delete(estruct.browsewind); drawnow;
			   estruct.browsewind = [];
			   set(theFig,'userdata',estruct);
			end;
		case 'BDcan',
			if ishandle(estruct.browsewind),
			   delete(estruct.browsewind); drawnow;
			   estruct.browsewind = [];
			   set(theFig,'userdata',estruct);
			end;
		case 'BDdata',
			if ishandle(estruct.browsewind),
			   cont = 1; fname = 0;
			   ud=get(estruct.browsewind,'userdata');
                           if isa(ud.cksds,'cksdirstruct'),
                              str = getalltests(ud.cksds);
                              [s,v]=listdlg('PromptString','Select a test directory',...
                                       'SelectionMode','single','ListString',str);
                              if ~isempty(s),
                                 acq = loadStructArray([getpathname(ud.cksds) str{s} filesep 'acqParams_out' ]);
                                 [f,fi,ii] = intersect({acq.type},input_types(ud.wd));
                                 rstr = {acq.name}; rstr = {rstr{fi}};
                                 if ~isempty(rstr),
                                      [sr,vr]=listdlg('PromptString','Select a record',...
					'SelectionMode','single','ListString',rstr);
				      if ~isempty(sr)
                                         [sn,vn]=listdlg('PromptString','Select a file','SelectionMode','single',...
                                                     'ListString',cellstr(int2str((1:acq(sr).reps)')));
                                         if ~isempty(sn),
                                           fname = [ getpathname(ud.cksds) str{s} filesep 'r' sprintf('%.3d',sn) ...
                                                    '_'acq(fi(sr)).fname];
                                           pathname = '';
                                         end;
                                      end;
                                 else, errordlg('Test contains no records compatible with windowdiscriminators.');
                                 end;
                              end;
                           else,
			      [fname,pathname]=uigetfile('*','Select data file...');
                           end;
			   if fname~=0,
				try,
				  d = loadIgor([pathname fname]);
				  d = winddiscfilter(thewd,d);
				catch, cont = 0;
				  errordlg('File could not be read.'); cont = 0;
				end;
				if cont,
				   sd=std(d);
				   set(ud.stddevstr,'String',['Std dev: ' num2str(sd)]);
				   j=findobj(ud.dataax,'Tag','data');
				   if ishandle(j), delete(j); end;
				   j=findobj(ud.dataax,'Tag','points');
				   if ishandle(j), delete(j); end;
				   j=findobj(ud.dataax,'Tag','peaks');
				   if ishandle(j), delete(j); end;
				   axes(ud.dataax); hold off;
				   j = plot(d,'b'); set(j,'Tag','data'); hold on;
				   if get(ud.showpointschk,'value')==1,v='on';else,v='off';end;
			 	   j=plot(d,'bx');set(j,'Tag','points','Visible',v);
				   a=axis;axis([1 length(d) a(3) a(4)]);
				   zoom on;
				   edit_graphical(windowdiscriminator('default'),...
					[],'BDupdate',theFig);
				end;
			   end;
			end;
		case 'BDupdate',
			if ishandle(estruct.browsewind),
				ud = get(estruct.browsewind,'userdata');
				j=findobj(ud.dataax,'Tag','data');
				if ishandle(j),
				  % check params
				  d = get(j,'YData'); sd = std(d);
				  try, j=findobj(ud.dataax,'Tag','peaks');
				       axes(ud.dataax);
				       if ishandle(j),delete(j);end;
				       j=findobj(ud.dataax,'Tag','thresh1');
				       if ishandle(j),delete(j);end;
				       j=findobj(ud.dataax,'Tag','thresh2');
				       if ishandle(j),delete(j);end;
				       thresh1=eval(get(ud.thresh1,'String'));
				       thresh2=eval(get(ud.thresh2,'String'));
				       threshmeth=get(ud.threshmethodpopup,'value')-1; m = mean(d);
				       if threshmeth==0,
					  thresh1=thresh1*sd+mean(d);thresh2=thresh2*sd+m;
				       end;
				       j=plot([0 length(d)],[thresh1 thresh1],'k');
				       if get(ud.showthreshchk,'value')==1,v='on';else,v='off';end;
				       set(j,'Tag','thresh1','Visible',v);
				       j=plot([0 length(d)],[thresh2 thresh2],'y');
				       if get(ud.showthreshchk,'value')==1,v='on';else,v='off';end;
				       set(j,'Tag','thresh2','Visible',v);
                                       [locs,vals]=winddisc(ud.wd,d,thresh1,thresh2);
				       if get(ud.showpeakschk,'value')==1,v='on';else,v='off';end;
				       j=plot(locs,vals,'ro');set(j,'Tag','peaks','Visible',v);
				       hvals=d(1:10:end); l=length(hvals);mult = length(d)/l;
				       axes(ud.histax);cla;hold off;
				       [n,x]=hist(hvals,fix(max([2 20*log(l)])));
				       bar(x,mult*n); a=axis;hold on;
				       if get(ud.showthreshchk,'value')==1,v='on';else,v='off';end;
				       j=plot([thresh1 thresh1],[0 a(4)],'k');
					set(j,'Tag','thresh1','visible',v);
				       j=plot([thresh2 thresh2],[0 a(4)],'y');
					set(j,'Tag','thresh2','visible',v);
				       n=histc(vals,x); bar(x,n,'r'); dx = x(2)-x(1);
				       %plot(x,mult*l*dx*exp(-((x-m).*(x-m))/(2*sd*sd))/sqrt(2*pi*sd*sd),'g');
				       inds=locs(find(locs>40&locs<length(d)-41))'; axes(ud.waveax); cla;
				       if ~isempty(inds),inds = repmat(inds,1,51)+repmat(-25:25,length(inds),1);
				       plot(-25:25,d(inds'));a=axis;axis([-25 25 a(3) a(4)]);end;
				  catch, errordlg('Could not update: check parameters.'); end;
				end;
			end;
		case 'BDshowpeaks',
			if ishandle(estruct.browsewind),
				ud = get(estruct.browsewind,'userdata');
				j = findobj(ud.dataax,'Tag','peaks');
				if ishandle(j),
					v=set(j,'visible');
					set(j,'visible',v{2-get(ud.showpeakschk,'value')});
				end;
			end;
		case 'BDshowpoints',
			if ishandle(estruct.browsewind),
				ud = get(estruct.browsewind,'userdata');
				j = findobj(ud.dataax,'Tag','points');
				if ishandle(j),
					v=set(j,'visible');
					set(j,'visible',v{2-get(ud.showpointschk,'value')});
				end;
			end;
		case 'BDshowthresh',
			if ishandle(estruct.browsewind),
				ud = get(estruct.browsewind,'userdata');
				j = findobj(ud.dataax,'Tag','thresh1');
				if ishandle(j),
					v=set(j,'visible');
					set(j,'visible',v{2-get(ud.showthreshchk,'value')});
				end;
				j = findobj(ud.dataax,'Tag','thresh2');
				if ishandle(j),
					v=set(j,'visible');
					set(j,'visible',v{2-get(ud.showthreshchk,'value')});
				end;
				j = findobj(ud.histax,'Tag','thresh1');
				if ishandle(j),
					v=set(j,'visible');
					set(j,'visible',v{2-get(ud.showthreshchk,'value')});
				end;
				j = findobj(ud.histax,'Tag','thresh2');
				if ishandle(j),
					v=set(j,'visible');
					set(j,'visible',v{2-get(ud.showthreshchk,'value')});
				end;
			end;
		case 'BDthresh1set',
			if ishandle(estruct.browsewind),
				ud = get(estruct.browsewind,'userdata');
				j=findobj(ud.dataax,'Tag','data');
				if ishandle(j),
				  threshmeth=get(ud.threshmethodpopup,'value')-1;
				  if threshmeth==0,
				     d = get(j,'YData'); sd = std(d); m=mean(d);
				  end;
				  % check params
				  x=ginput(1);x=x(2);if threshmeth==0,x=(x-m)/sd;end;
				  set(ud.thresh1,'String',sprintf('%f',x));
				  edit_graphical(windowdiscriminator('default'),...
				  [],'BDupdate',theFig);
                                end;
			end;
		case 'BDthresh2set',
			if ishandle(estruct.browsewind),
				ud = get(estruct.browsewind,'userdata');
				j=findobj(ud.dataax,'Tag','data');
				if ishandle(j),
				  threshmeth=get(ud.threshmethodpopup,'value')-1;
				  if threshmeth==0,
				     d = get(j,'YData'); sd = std(d); m = mean(d);
				  end;
				  % check params
				  x=ginput(1);x=x(2);if threshmeth==0,x=(x-m)/sd;end;
				  set(ud.thresh2,'String',sprintf('%f',x));
				  edit_graphical(windowdiscriminator('default'),...
				  [],'BDupdate',theFig);
                                end;
			end;
		case 'BDthreshmeth',
			if ishandle(estruct.browsewind),
				4,
				ud = get(estruct.browsewind,'userdata');
				j=findobj(ud.dataax,'Tag','data');
				if ishandle(j),
				   ov = get(ud.threshmethodpopup,'userdata');
				   nv = get(ud.threshmethodpopup,'value');
				   if ov~=nv, % must convert & update
					set(ud.threshmethodpopup,'userdata',nv); % set it right
					d=get(j,'YData'); sd = std(d); m = mean(d);
				        thresh1=eval(get(ud.thresh1,'String'));
				        thresh2=eval(get(ud.thresh2,'String'));
					if ov==1, % N std dev convert to Absolute
					   thresh1=thresh1*sd+mean(d);thresh2=thresh2*sd+mean(d);
					else, % Absolute convert to N std dev
					   thresh1=(thresh1-m)/sd;thresh2=(thresh2-m)/sd;
                                        end;
					set(ud.thresh1,'String',sprintf('%f',thresh1));
					set(ud.thresh2,'String',sprintf('%f',thresh2));
				        edit_graphical(windowdiscriminator('default'),...
				           [],'BDupdate',theFig);
				   end;
				end;
			end;
	end;
end;


function p = buildwindow(wd,isname,hasdata,thename,cksds)

params = getparameters(wd);

filtmethval = params.filtermethod + 1;
filtargstr = mat2str(params.filterarg);
threshmethval = params.threshmethod  + 1;
thresh1str = num2str(params.thresh1);
thresh2str = num2str(params.thresh2);
cntbordersval = params.allowborders + 1;
scratchfilestr = params.scratchfile;
event_type_stringstr = params.event_type_string;
output_obj_val = params.output_object + 1;

h0 = figure('Color',[0.8 0.8 0.8], ...
        'PaperPosition',[18 180 576 432], ...
        'PaperUnits','points', ...
        'Position',[184   279   419 319], ...
        'Tag','Fig1', ...
        'Menu','none');
		settoolbar(h0,'none');
title = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[12 228 176.8 17.6], ...
        'String','Windowdiscriminator editor:', ...
        'Style','text', ...
        'Tag','StaticText1');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 156.8 64.8 13.6], ...
        'String','Thresh1:', ...
        'Style','text', ...
        'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 133.6 64.8 13.6], ...
        'String','Thresh2:', ...
        'Style','text', ...
        'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 176 99.2 16], ...
        'String','Threshold method:', ...
        'Style','text', ...
        'Tag','StaticText3');
threshmethodpopup = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[116.8 176.8 88.8 18.4], ...
        'String',{'N std devs','Absolute'}, ...
        'Style','popupmenu', ...
        'Tag','PopupMenu1', ...
        'Value',threshmethval);
thresh1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[84 152 115.2 20], ...
        'Style','edit', 'String',thresh1str,...
        'Tag','EditText1');
thresh2 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[84 129.6 115.2 20], ...
        'Style','edit', 'String',thresh2str, ...
        'Tag','EditText1');
countborders = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[117.6 110.4 88.8 18.4], ...
        'String',{'no','yes'}, ...
        'Style','popupmenu', ...
        'Tag','PopupMenu1', ...
        'Value',cntbordersval);
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 110.4 99.2 16], ...
        'String','Count borders?', ...
        'Style','text', ...
        'Tag','StaticText3');
enstr = 'on';% else, enstr = 'off'; end;
browsebt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[211.2 143.2 68 19.2], ...
        'String','Browse data', ...
        'Tag','Pushbutton1','enable',enstr,'Callback',...
	'edit_graphical(windowdiscriminator(''default''),[],''BrowseData'');');
if ~isname, okcb = 'set(gcbo,''userdata'',[1]);uiresume(gcf);';
else, okcb = 'edit_graphical(windowdiscriminator(''default''),[],''OK'');'; end;
okbt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[12.8 14.4 64 20.8], ...
        'String','OK', ...
        'Tag','Pushbutton2','UserData',0,'Callback',okcb);
if ~isname, cancb = 'set(gcbo,''userdata'',[1]);uiresume(gcf);';
else, cancb = 'edit_graphical(windowdiscriminator(''default''),[],''Cancel'');'; end;
canbt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[146.4 14.4 64 20.8], ...
        'String','Cancel', ...
        'Tag','Pushbutton2','UserData',0,'Callback',cancb);
if isname,enstr = 'on'; else, enstr = 'off'; end;
applybt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[80 14.4 64 20.8], ...
        'String','Apply', ...
        'Tag','Pushbutton2','enable',enstr,...
	'Callback','edit_graphical(windowdiscriminator(''default''),[],''Apply'');');
helpbt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[215.2 14.4 64 20.8], ...
        'String','Help', ...
        'Tag','Pushbutton2');
scratchfile = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[84 82.4 115.2 20], ...
        'Style','edit', 'String',scratchfilestr,...
        'Tag','EditText1');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 86.4 64.8 13.6], ...
        'String','scratchfile:', ...
        'Style','text', ...
        'Tag','StaticText2');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 62.4 64.8 13.6], ...
        'String','event type:', ...
        'Style','text', ...
        'Tag','StaticText2');
event_type = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[84 58.4 115.2 20], ...
        'Style','edit', 'String',event_type_stringstr,...
        'Tag','EditText1');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 40.8 75.2 16], ...
        'String','output type:', ...
        'Style','text', ...
        'Tag','StaticText3');
output_type = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[92.8 40 88.8 18.4], ...
        'String',{'cksmultiunit', 'ckssingleunit'}, ...
        'Style','popupmenu', ...
        'Tag','PopupMenu1', ...
        'Value',output_obj_val);
filtmethod = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[88.8 200 85.2 18.4], ...
        'String',{'none', 'convolution', 'Chebyshev I'}, ...
        'Style','popupmenu', ...
        'Tag','PopupMenu1', ...
        'Value',filtmethval);
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[10.4 200.8 73.6 16], ...
        'String','Filter method:', ...
        'Style','text', ...
        'Tag','StaticText3');
filtargstring = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[178.4 200.8 68 16], ...
        'String','Arg:', ...
        'Style','text','HorizontalAlignment','left', ...
        'Tag','StaticText3');
filtarg = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[232.8 200 81.6 18.4], ...
        'Style','edit', 'String',filtargstr,...
        'Tag','EditText2');
set(h0,'userdata',struct('title',title,'threshmethodpopup',threshmethodpopup,...
	'thresh1',thresh1,'thresh2',thresh2,'countborders',countborders,...
	'browsebt',browsebt,'okbt',okbt,'canbt',canbt,'applybt',applybt,...
	'helpbt',helpbt,'scratchfile',scratchfile,'event_type',event_type,...
	'output_type',output_type,'filtmethod',filtmethod,...
	'filtargstring',filtargstring,'filtarg',filtarg,'wd',wd,'cksds',cksds,'wdname',thename,...
	'browsewind',[]));

p = [];
if ~isname,
    error_free = 0;
    while(~error_free),
	drawnow;
	uiwait(h0);

	if get(canbt,'userdata')==1,
		p = [];
		error_free = 1;
	else, % it was OK
		p = checkinput(h0);
		if isempty(p), set(okbt,'UserData',0); else, error_free = 1; end;
	end;
    end;	
    estruct=get(h0,'userdata');
    if ~isempty(estruct.browsewind)&ishandle(estruct.browsewind),
	delete(estruct.browsewind);
    end;
    delete(h0);
end;

function pstruct = checkinput(h0);
ud = get(h0,'UserData');
so = 1; % syntax ok
try,t1=eval(get(ud.thresh1,'String'));catch,errordlg('Syntax error in thresh1.');so=0;end;
try,t2=eval(get(ud.thresh2,'String'));catch,errordlg('Syntax error in thresh2.');so=0;end;
try,fa=eval(get(ud.filtarg,'String'));catch,errordlg('Syntax error in filter arg.');so=0;end;
try,eval(['a_' get(ud.scratchfile,'String') '_1 = 5;']);
    catch,errordlg('Syntax error in scratchfile.');so=0;end;
try,eval(['a_' get(ud.event_type,'String') '_1 = 5;']);
    catch,errordlg('Syntax error in event type.');so=0;end;
if so,
	pstruct=struct('filtermethod',get(ud.filtmethod,'value')-1,...
			'filterarg',fa,'threshmethod',get(ud.threshmethodpopup,'value')-1,...
			'thresh1',t1,'thresh2',t2,...
			'allowborders',get(ud.countborders,'value')-1,...
			'scratchfile',get(ud.scratchfile,'String'),...
			'event_type_string',get(ud.event_type,'String'),...
			'output_object',get(ud.output_type,'value')-1);
	[good,err]=verifywindowdiscriminator(pstruct);
	if ~good, errordlg(['Error in parameters: ' err]); pstruct = []; end;
else, pstruct = [];
end;

function h0 = makebrowsedata(parentFig,threshmethod,thresh1,thresh2,wd)

co=[0 0 1;0 0.5 0;1 0 0;0 0.75 0.75;0.75 0 0.75;0.75 0.75 0;0.25 0.25 0.25];
h0 = figure('Color',[0.8 0.8 0.8], ...
        'PaperPosition',[18 180 576 432], ...
        'PaperUnits','points', ...
        'Position',[184   110   769   488], ...
        'Tag','BrowseData');
		settoolbar(h0,'none');
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDok'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
okbt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontSize',12, ...
        'ListboxTop',0, ...
        'Position',[420 23.2 68.8 22.4], ...
        'String','OK', ...
        'Tag','Pushbutton1','Callback',cb);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDcan'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
canbt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontSize',12, ...
        'ListboxTop',0, ...
        'Position',[497.6 24.8 68.8 22.4], ...
        'String','Cancel', ...
        'Tag','Pushbutton1','Callback',cb);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDthreshmeth'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
threshmethodpopup = uicontrol('Parent',h0, ...
        'Units','points', ...
        'ListboxTop',0, ...
        'Min',1, ...
        'Position',[495.6 332 100 20], ...
        'String',{'N std devs', 'Absolute'}, ...
        'Style','popupmenu', ...
        'Tag','PopupMenu1', ...
        'BackgroundColor',[0.8 0.8 0.8],...
        'Value',threshmethod,'Callback',cb,'userdata',threshmethod);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDupdate'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
thresh1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[495.6 292 100 17.6], ...
        'Style','edit', ...
        'Tag','EditText1','String',thresh1,'Callback',cb);
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[495.6 356.8 100 13.6], ...
        'String','Thresh method:', ...
        'Style','text', ...
        'Tag','StaticText1');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[495.6 314.4 100 13.6], ...
        'String','Thresh1:', ...
        'Style','text', ...
        'Tag','StaticText1');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[495.6 257.6 100 13.6], ...
        'String','Thresh2:', ...
        'Style','text', ...
        'Tag','StaticText1');
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDupdate'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
thresh2 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[1 1 1], ...
        'ListboxTop',0, ...
        'Position',[495.6 234.4 100 18.4], ...
        'Style','edit', ...
        'Tag','EditText1','String',thresh2,'Callback',cb);
dataax = axes('Parent',h0, ...
        'Units','pixels', ...
        'CameraUpVector',[0 1 0], ...
        'Color',[1 1 1], ...
        'ColorOrder',co, ...
        'Position',[35 247 459 166], ...
        'Tag','Axes1', ...
        'XColor',[0 0 0], ...
        'YColor',[0 0 0], ...
        'ZColor',[0 0 0]);
stddevstr = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'HorizontalAlignment','left', ...
        'ListboxTop',0, ...
        'Position',[495.6 193.6 100 16.8], ...
        'String','Std dev:', ...
        'Style','text', ...
        'Tag','StaticText2');
histax = axes('Parent',h0, ...
        'Units','pixels', ...
        'CameraUpVector',[0 1 0], ...
        'Color',[1 1 1], ...
        'ColorOrder',co, ...
        'Position',[37 40 164 153], ...
        'Tag','Axes2', ...
        'XColor',[0 0 0], ...
        'YColor',[0 0 0], ...
        'ZColor',[0 0 0]);
waveax = axes('Parent',h0, ...
        'Units','pixels', ...
        'CameraUpVector',[0 1 0], ...
        'Color',[1 1 1], ...
        'ColorOrder',co, ...
        'Position',[256 40 164 153], ...
        'Tag','Axes2', ...
        'XColor',[0 0 0], ...
        'YColor',[0 0 0], ...
        'ZColor',[0 0 0]);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDthresh1set'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
thresh1set = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[495.6 273.6 100 16.8], ...
        'String','Select on graph', ...
        'Tag','Pushbutton2','Callback',cb);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDthresh2set'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
thresh2set = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[495.6 216.8 100 16.8], ...
        'String','Select on graph', ...
        'Tag','Pushbutton2','Callback',cb);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDdata'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
selectdatabt = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[430 61.6 100 23.2], ...
        'String','Select Data', ...
        'Tag','Pushbutton3','Callback',cb);
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[72 197.6 82.4 14.4], ...
        'String','Histogram', ...
        'Style','text', ...
        'Tag','StaticText3');
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[265.6 196.8 82.4 14.4], ...
        'String','Waveforms:', ...
        'Style','text', ...
        'Tag','StaticText3');
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDshowpeaks'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
showpeakschk = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'HorizontalAlignment','left', ...
        'Position',[495.6 166.4 100 21.6], ...
        'String','Show Peaks', ...
        'Style','checkbox', ...
        'Tag','Checkbox1','Callback',cb,'Value',1);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDshowpoints'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
showpointschk = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[495.6 141.6 100 21.6], ...
        'HorizontalAlignment','left', ...
        'String','Show Points', ...
        'Style','checkbox', ...
        'Tag','Checkbox1','Callback',cb);
cb = ['edit_graphical(windowdiscriminator(''default''),[],''BDshowthresh'',' ...
      'getfield(get(gcbf,''userdata''),''parentFig''));'];
showthreshchk = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'ListboxTop',0, ...
        'Position',[495.6 116.8 100 21.6], ...
        'HorizontalAlignment','left', ...
        'String','Show Threshes', ...
        'Style','checkbox', ...
        'Tag','Checkbox1','Value',1,'Callback',cb);
h1 = uicontrol('Parent',h0, ...
        'Units','points', ...
        'BackgroundColor',[0.8 0.8 0.8], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'ListboxTop',0, ...
        'Position',[16.8 400.4 220 20], ...
        'String','Windowdiscriminator data browser', ...
        'Style','text', ...
        'Tag','StaticText4');
ud2 = get(parentFig,'userdata');
set(h0,'userdata',struct('okbt',okbt,'canbt',canbt,'threshmethodpopup',...
threshmethodpopup,'thresh1',thresh1,'thresh2',thresh2,'dataax',dataax,...
'stddevstr',stddevstr,'histax',histax,'waveax',waveax,'thresh1set',...
thresh1set,'thresh2set',thresh2set,'selectdatabt',selectdatabt,'showpeakschk',...
showpeakschk,'showpointschk',showpointschk,'showthreshchk',showthreshchk,'parentFig',parentFig,...
'data',[],'wd',wd,'cksds',ud2.cksds));

