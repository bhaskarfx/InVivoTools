function [pso] = periodicstim3D(PSparams,OLDSTIM)% NewStim package: PERIODICSTIM%%  THEPERIODICSTIM = PERIODICSTIM(PARAMETERS)%%  Creates a periodic stimulus, such as a sine-wave grating, saw-tooth%  grating,%  etc.  This class is a wrapper to the stimuli in the StimGen package.  Note%  that this package is gray-scale only, so color values are given between 0-1.%%  The PARAMETERS argument can either be a structure containing the parameters%  or the string 'graphical'(in which case the user is prompted for the values%  of the parameters), or the string 'default' (in which case default parameter%  values are assigned). In the graphical case, the following call is%  available:%%  THEPERIODICSTIM = PERIODICSTIM('graphical',OLDSTIM)%%  in which case the default parameters presented are based on OLDSTIM.  If the%  values are being passed, then PARAMETERS should be a structure with the%  following fields (fields are 1x1 unless indicated):%%  imageType       -   0 => field (single luminance across field)%                      1 => square (field split into light and dark halves)%                      2 => sine (smoothly varying shades)%                      3 => triangle (linear light->dark->light transition)%                      4 => lightsaw (linear light->dark transition)%                      5 => darksaw (linear dark->light transition)%                      6 => <sFrequency> bars of <barwidth> width (see below)%                      7 => edge (like lightsaw but with bars determining width%                           of saw)%                      8 => bump (bars with internal smooth dark->light->dark%                           transitions%  animType        -   0 => no animation%                      1 => square wave%                      2 => sine wave%                      3 => ramp%                      4 => drifting grating%                      5 => fixed on-duration flicker for field stimulus%  flickerType     -   0 => light > background -> light%                      1 => dark -> background -> dark%                      2 => counterphase%  angle           -   orientation, in degrees, 0 is up%  DEPRECATED, SHOULD USE NEWSTIMVIEWINGDISTANCE, distance        -   distance of the monitor from the viewer%  sFrequency      -   spatial frequency in cycles per degree%  tFrequency      -   temporal frequency (Hz)%  sPhaseShift     -   Phase shift (only works for counterphase stims but must%                      be passed for all), in radians  where 2*pi is 1 cycle%  barWidth        -   Width of bar (% of display rgn), only valid for bar stims%                      but must have value passed for all stims.%  [1x4] rect      -   The rectangle on the screen where the stimulus will be%                      displayed:  [ top_x top_y bottom_x bottom_y ]%  nCycles         -   The number of times the stimulus should be repeated%  contrast        -   0-1: 0 means no diff from background, 1 is max difference%  background      -   absolute luminance of the background (0-1)%  backdrop        -   absolute luminance of area outside of display rgn (0-1)%  barColor        -   For bar stimuli, the color of the bars (0-1)%  nSmoothPixels   -   Blurs the image with a boxcar of this width%  fixedDur        -   fixed on-duration of squarewave flicker%  windowShape     -   0 rectangle,1 oval,2 oriented rectangle,3 oriented oval%%  See also:  STIMULUS, STOCHASTICGRIDSTIM, PERIODICSCRIPTfinish = 1;default_p = struct( ...    'imageType',         2,              ...    'animType',          4,              ...    'flickerType',       0,              ...    'angle',             45,             ...    'chromhigh',	   [200 200 200],	 ...    'chromlow',		   [70 70 70],	     ...    'sFrequency',        0.05,           ...      'sPhaseShift',       0,              ... %'distance',57,...    'tFrequency',        0.6,            ...    'barWidth',          0.5,            ...    'rect',         [340 26 1340 1026],     ... %(Image is always converted to a square)    'rectimage',    [0 0 500 500],       ... %(Right and left separate images)    'posR',         [400 0],             ... %(upper left corner)     'posL',         [100 0],             ...    'nCycles',           2,             ...    'contrast',           1,             ...    'background',       0.5,             ...    'backdrop',    		0.5,             ...    'barColor',          1,              ...    'nSmoothPixels',     2,              ...    'fixedDur',          0,              ...    'windowShape',       0,              ...    'eyes',              2               ...  %0=left, 1=right, 2=both    );default_p.dispprefs = {};if nargin==1, oldstim=[]; else, oldstim = OLDSTIM; end;if ischar(PSparams),    if strcmp(PSparams,'graphical'),        % load parameters graphically        p = get_graphical_input(oldstim);        if isempty(p), finish = 0; else, PSparams = p; end;    elseif strcmp(PSparams,'default'),        PSparams = default_p;    else        error('Unknown string input into periodicstim.');    end;else   % they are just parameters    [good, err] = verifyperiodicstim(PSparams);    if ~good, error(['Could not create periodicstim: ' err]); end;end;if finish,    StimWindowGlobals    if ~isempty(StimWindowRefresh) % if stimulus computer        %compute displayprefs info        fps = StimWindowRefresh;        % tRes = screen frames / cycle        tRes = round( (1/PSparams.tFrequency) * fps);    else  % we're just initializing        tRes = 5;        fps = -1;    end;    frames = repmat(1:tRes,1,PSparams.nCycles);    % Special case: animType == 1    if (PSparams.animType == 1) % if a square wave, only 2 frames:  ON and OFF        fps = tRes;        %f = PSparams.tFrequency;        %t = 0.00001 + (0:1/StimWindowRefresh:PSparams.nCycles/f);        %x = zeros(size(t)); x(find(sin(f*2*pi*t)<0)) = 1; x(find(sin(f*2*pi*t)>=0)) = 2;        frames = 2;  % x    end;    oldRect = PSparams.rect;    width = oldRect(3) - oldRect(1); height = oldRect(4)-oldRect(2);    dims = max(width,height);    newrect = [oldRect(1) oldRect(2) oldRect(1)+dims oldRect(2)+dims];    if PSparams.windowShape==2|PSparams.windowShape==3, %#ok<OR2>        angle = mod(PSparams.angle,360)/180*pi;        trans = [cos(angle) -sin(angle); sin(angle) cos(angle)];        ctr = [mean(oldRect([1 3])) mean(oldRect([2 4]))];        cRect=(trans*([oldRect([1 2]);oldRect([3 2]);...            oldRect([3 4]);oldRect([1 4])]-...            repmat(ctr,4,1))')'+repmat(ctr,4,1);        dimnew = [max(cRect(:,1))-min(cRect(:,1)) ...            max(cRect(:,2))-min(cRect(:,2))];        ID = max(dimnew);        newrect = ([-ID -ID ID ID]/2+repmat(ctr,1,2));    end;    dp={'fps',fps, ...        'rect',newrect, ...        'frames',frames,PSparams.dispprefs{:} };    s = stimulus(5);    data = struct('PSparams', PSparams);    pso = class(data,'periodicstim3D',s);    pso.stimulus = setdisplayprefs(pso.stimulus,displayprefs(dp));else    pso = [];end;%%% GET_GRAPHICAL_INPUT funciton %%%function params = get_graphical_input(oldstim)if isempty(oldstim),    rect_str = '[100 100 191 191]';    image_val = 3; anim_val = 5; flicker_val = 1;    angle_str = '90'; sFrequency_str = '0.5';    tFrequency_str = '4';    nCycles_str = '10';    %	durtn_str = '2';    % distance_str = '57';    contrast_str = '1'; background_str = '0.5';backdrop_str = '0.5';    smooth_str = '2'; shape_val = 2; barColor_str = '1';    barWidth_str = '0.5'; sPhase_str = '0'; fixed_str = '0';    dp_str = '{}';    chromhigh_str = '[255 255 255]';    chromlow_str = '[0 0 0]';else    oldS = struct(oldstim); PSparams = oldS.PSparams;    rect_str = mat2str(PSparams.rect);    image_val = (PSparams.imageType+1);    anim_val = (PSparams.animType+1);    flicker_val = (PSparams.flickerType+1);    angle_str = num2str(PSparams.angle);    chromhigh_str = mat2str(PSparams.chromhigh);    chromlow_str = mat2str(PSparams.chromlow);    sFrequency_str = num2str(PSparams.sFrequency);    tFrequency_str = num2str(PSparams.tFrequency);    nCycles_str = num2str(PSparams.nCycles);    %	durtn_str = num2str(round(PSparams.nCycles/PSparams.tFrequency));   %  distance_str = num2str(PSparams.distance);    contrast_str = num2str(PSparams.contrast);    background_str = num2str(PSparams.background);    backdrop_str = num2str(PSparams.backdrop);    smooth_str = num2str(PSparams.nSmoothPixels);    shape_val = (PSparams.windowShape+1);    barColor_str = num2str(PSparams.barColor);    barWidth_str = num2str(PSparams.barWidth);    sPhase_str = num2str(PSparams.sPhaseShift);    fixed_str = num2str(PSparams.fixedDur);    dp_str = cell2str(PSparams.dispprefs);end;% make figure layouth0 = figure('Color',[0.8 0.8 0.8],'Position',[100 100 500 800]);settoolbar(h0,'none'); set(h0,'menubar','none');             guicreate('Text','String','New periodicstim3D object','fontsize',26,'height',50,'top','top','left','left','width','auto');             guicreate('Text','String','Position and size of image display','fontsize',10,'tooltipstring','[top_x top_y bottom_x bottom_y]','width',250,'move','right');rect_ctl =   guicreate('edit','String','[0 0 1680 1050]','fontsize',9,'width',150,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Size of separate right and left images','fontsize',10,'tooltipstring','[top_x top_y bottom_x bottom_y] relative to image display','width',250,'move','right');rectsep_ctl =guicreate('edit','String','[0 0 500 500]','fontsize',9,'width',150,'BackgroundColor',[1 1 1]);                          guicreate('Text','String','Position of right-eye image','fontsize',10,'tooltipstring','[left top] relative to image display','width',250,'move','right');posR_ctl =   guicreate('edit','String','[0 0]','fontsize',9,'width',150,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Position of left-eye image','fontsize',10,'tooltipstring','[left top] relative to image display','width',250,'move','right');posL_ctl =   guicreate('edit','String','[0 0]','fontsize',9,'width',150,'BackgroundColor',[1 1 1]);             guicreate('text','String','Eye(s) you would you like to stimulate:','fontsize',10,'width','auto','move','right');lefteye_ckb =guicreate('checkbox','value',1,'String','Left' ,'width',70,'fontsize',8,'move','right');righteye_ckb=guicreate('checkbox','value',1,'String','Right','fontsize',8);             guicreate('Text','String','Stimulus type:','fontsize',11,'fontweight', 'bold', 'width',250);             guicreate('Text','String','Image Type','fontsize',10,'tooltipstring','Select type in menu','width',150,'move','right');image_ctl =  guicreate('popupmenu','String',{'field','square','sine','triangle','lightsaw','darksaw','bars','edge', 'bump'},'fontsize',9,'width',210,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Flicker Type','fontsize',10,'tooltipstring','Select type in menu','width',150,'move','right');flicker_ctl =guicreate('popupmenu','String',{'light->background->light','dark->background->dark','counterphase'},'fontsize',9,'width',210,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Animation Type','fontsize',10,'tooltipstring','Select type in menu','width',150,'move','right');anim_ctl =   guicreate('popupmenu','String',{'static','square','sine','ramp','drifting','fixed on-duration (field only)'},'fontsize',9,'width',210,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Stimulus Shape','fontsize',10,'tooltipstring','Select shape in menu','width',150,'move','right');shape_ctl =  guicreate('popupmenu','String',{'rectangle','oval','angled rect','angled oval'},'fontsize',9,'width',210,'BackgroundColor',[1 1 1]);                        guicreate('Text','String','Orientation angle','fontsize',10,'tooltipstring','0 is up, single number required','width',150,'move','right');angle_ctl =  guicreate('Edit','String','90','fontsize',9,'width',30,'BackgroundColor',[1 1 1],'move','right');             guicreate('Text','String','Spatial frequency','fontsize',10,'tooltipstring','in cycles per degree','width',150,'move','right');sFrequency_ctl=guicreate('Edit','String',['0.05'],'fontsize',9,'width',30,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Number of cycles','fontsize',10,'tooltipstring','The number of times the stimulus should be repeated','width',150,'move','right');nCycles_ctl =guicreate('Edit','String','4','fontsize',9,'width',30,'BackgroundColor',[1 1 1],'move','right');             guicreate('Text','String','Temporal frequency','fontsize',10,'tooltipstring','Hz','width',150,'move','right');tFrequency_ctl=guicreate('Edit','String','2','fontsize',9,'width',30,'BackgroundColor',[1 1 1]);                    guicreate('Text','String','Colour settings:','fontsize',11,'fontweight', 'bold', 'width',250);             guicreate('Text','String','Contrast','fontsize',10,'tooltipstring','value between 0 and 1','width',150,'move','right');contrast_ctl =guicreate('Edit','String','1','fontsize',9,'width',30,'BackgroundColor',[1 1 1],'move','right');             guicreate('Text','String','','fontsize',10,'width',75,'move','right');                          guicreate('Text','String','Background colour','fontsize',10,'tooltipstring','absolute luminance of the background, value between 0 and 1','width',150,'move','right');background_ctl=guicreate('Edit','String','0.5','fontsize',9,'width',30,'BackgroundColor',[1 1 1]);             guicreate('Text','String','Backdrop colour','fontsize',10,'tooltipstring','absolute luminance of area outside of display region, value between 0 and 1','width',150,'move','right');backdrop_ctl=guicreate('Edit','String','0.5','fontsize',9,'width',30,'BackgroundColor',[1 1 1],'move','right');             guicreate('Text','String','','fontsize',10,'width',75,'move','right');             guicreate('Text','String','Smooth N pixels','fontsize',10,'tooltipstring','Blurs the image with a boxcar of this width','width',150,'move','right');smooth_ctl=  guicreate('Edit','String','2','fontsize',9,'width',30,'BackgroundColor',[1 1 1]);             guicreate('Text','String','High/Low colour','fontsize',10,'tooltipstring','left is high, right is low, [rgb]','width',150,'move','right');chromhighinp=guicreate('Edit','String','[200 200 200]','fontsize',9,'width',100,'BackgroundColor',[1 1 1],'move','right');             guicreate('Text','String','','fontsize',11,'fontweight', 'bold', 'width',15, 'move','right');chromlowinp= guicreate('Edit','String','[100 100 100]','fontsize',9,'width',100,'BackgroundColor',[1 1 1]);             guicreate('text','String',''); %space               guicreate('Text','String','Bars only (ignore otherwise):','fontsize',9,'fontweight', 'bold', 'width',275, 'move','right');             guicreate('Text','String','Bar colour','fontsize',10,'tooltipstring','Colour of the bars value between 0 and 1','width',145,'move','right');barColor_ctl=guicreate('Edit', 'String','1','fontsize',9,'width',30,'BackgroundColor',[0.7 0.7 0.7]);             guicreate('Text','String','','fontsize',10,'width',275,'move','right');             guicreate('Text','String','Bar width','fontsize',10,'tooltipstring','Proportion of the display region that is width of bar','width',145,'move','right');barWidth_ctl=guicreate('Edit', 'String','0.5','fontsize',9,'width',30,'BackgroundColor',[0.7 0.7 0.7]);             guicreate('Text','String','Counterphase flicker only (ignore otherwise):','fontsize',9,'fontweight', 'bold', 'width',275,'move','right');             guicreate('Text','String','Spatial phase shift','fontsize',10,'tooltipstring','[1x1]in radians  where 2*pi is 1 cycle [0..2*pi]','width',145,'move','right');sPhase_ctl=  guicreate('Edit', 'String','0','fontsize',9,'width',30,'BackgroundColor',[0.7 0.7 0.7]);             guicreate('Text','String','Fixed on-duration anim. only (ignore otherwise):','fontsize',9,'fontweight', 'bold', 'width',275,'move','right');             guicreate('Text','String','Fixed on duration','fontsize',10,'tooltipstring','[1x1], fixed on-duration of squarewave flicker','width',145,'move','right');fixed_ctl=   guicreate('Edit', 'String','0','fontsize',9,'width',30,'BackgroundColor',[0.7 0.7 0.7]);                     guicreate('text','String',''); %space             guicreate('Text','String','Set any displayprefs options here:','fontsize',10,'tooltipstring','example: {''BGpretime'',1}, ...','width',250);dp_ctl =     guicreate('edit','String','{''BGpretime'',1}','width',400,'fontsize',9,'BackgroundColor',[1 1 1], 'height', 60);             set(dp_ctl,'max',10);                       guicreate('text','String',''); %space             guicreate('text','String','','width',80,'move','right');ok_ctl =     guicreate('Pushbutton','String','OK','Callback','set(gcbo,''userdata'',[1]);uiresume(gcf);','userdata',0,'width',80,'move','right');cancel_ctl = guicreate('Pushbutton','String','Cancel','Callback','set(gcbo,''userdata'',[1]);uiresume(gcf);','userdata',0,'width',80, 'move','right');help_ctl =   guicreate('Pushbutton','String','Help','Callback','textbox(''periodicstim help'',help(''periodicstim''));','width',80);              error_free = 0;psp = [];while ~error_free,    drawnow;    uiwait(h0);    if get(cancel_ctl,'userdata')==1,        error_free = 1;    else % it was OK        dp_str         = get(dp_ctl,'String');        rect_str       = get(rect_ctl,'String');        rectsep_str    = get(rectsep_ctl,'String');        posR_str       = get(posR_ctl,'String');        posL_str       = get(posL_ctl,'String');        lefteye_val    = get(lefteye_ckb,'value');        righteye_val   = get(righteye_ckb,'value');        image_val      = get(image_ctl,'value');        flicker_val    = get(flicker_ctl,'value');        anim_val       = get(anim_ctl,'value');        shape_val      = get(shape_ctl,'value');        angle_str      = get(angle_ctl,'String');        sFrequency_str = get(sFrequency_ctl,'String');        tFrequency_str = get(tFrequency_ctl,'String');        nCycles_str    = get(nCycles_ctl,'String');        chromhigh_str  = get(chromhighinp,'String');        chromlow_str   = get(chromlowinp,'String');        contrast_str   = get(contrast_ctl,'String');        background_str = get(background_ctl,'String');        backdrop_str   = get(backdrop_ctl,'String');        smooth_str     = get(smooth_ctl, 'String');        barColor_str   = get(barColor_ctl,'String');        barWidth_str   = get(barWidth_ctl,'String');        sPhase_str     = get(sPhase_ctl,'String');        fixed_str      = get(fixed_ctl,'String');        so = 1; % syntax_okay;        try,			dp=eval(dp_str);        catch,			errordlg('Syntax error in displayprefs'); so=0;		end;        try,			rect = eval(rect_str);        catch,			errordlg('Syntax error in Rect'); so=0; 		end;        try,			rectimage = eval(rectsep_str);        catch,			errordlg('Syntax error in Rect of separate images'); so=0; 		end;        try,			posR = eval(posR_str);        catch, 			errordlg('Syntax error in right eye position'); so=0; 		end;        try, 			posL = eval(posL_str);        catch,			errordlg('Syntax error in left eye position'); so=0; 		end;        if so == 1;             if lefteye_val==0 & righteye_val==0               errordlg('No eye(s) selected'); so=0;            elseif lefteye_val==1 & righteye_val==0               eyes = 0; so=1;            elseif lefteye_val==0 & righteye_val==1               eyes = 1; so=1;            elseif lefteye_val==1 & righteye_val==1               eyes = 2; so=1;            end;        end;        imageType = image_val - 1;              flickerType = flicker_val - 1;          animType = anim_val - 1;                shape = shape_val - 1;                  try, 			angle = eval(angle_str);        catch,			errordlg('Syntax error in angle'); so=0;		end;        try,			sFrequency = eval(sFrequency_str);        catch,			errordlg('Syntax error in spatial frequency'); so=0;		end;        try,			tFrequency = eval(tFrequency_str);        catch, 			errordlg('Syntax error in temporal frequency'); so=0;		end;        try, 			nCycles = eval(nCycles_str);        catch, 			errordlg('Syntax error in number of cycles'); so=0; 		end;        try, 			chromhigh= eval(chromhigh_str);        catch, 			errordlg('Syntax error in chromhigh'); so=0; 		end;        try, 			chromlow= eval(chromlow_str);        catch,			errordlg('Syntax error in chromlow'); so=0; 		end;        try, 			contrast = eval(contrast_str);        catch,			errordlg('Syntax error in contrast'); so=0; 		end;        try, 			background = eval(background_str);        catch, 			errordlg('Syntax error in background'); so=0; 		end;        try, 			backdrop = eval(backdrop_str);        catch, 			errordlg('Syntax error in backdrop'); so=0; 		end;        try, 			smooth = eval(smooth_str);        catch, 			errordlg('Syntax error in smooth'); so=0; 		end;        try,			barColor = eval(barColor_str);        catch,			errordlg('Syntax error in barColor'); so=0; 		end;        try, 			barWidth = eval(barWidth_str);        catch, 			errordlg('Syntax error in barWidth'); so=0;		end;        try,			sPhase = eval(sPhase_str);        catch,			errordlg('Syntax error in spatial phase'); so=0; 		end;        try,			fixed = eval(fixed_str);        catch, 			errordlg('Syntax error in fixed on duration'); so=0; 		end;        if so            psp = struct(...                'imageType',imageType,'animType',animType,'flickerType',flickerType, ...                'angle',angle,'chromhigh',chromhigh,'chromlow',chromlow,'sFrequency',sFrequency, ...                'sPhaseShift',sPhase,'tFrequency',tFrequency,'posR',posR,'posL',posL,...                 'barWidth',barWidth,'rect',rect,'rectimage',rectimage,'nCycles',nCycles, ...                'contrast',contrast,'background',background,'backdrop',backdrop, ...                'barColor',barColor,'nSmoothPixels',smooth,'fixedDur',fixed, ...                'windowShape',shape, 'eyes',eyes);            psp.dispprefs = dp;            [good, err] = verifyperiodicstim(psp);            if ~good,                errordlg(['Parameter value invalid: ' err]);                set(ok_ctl,'userdata',0);            else                error_free = 1;            end;        else            set(ok_ctl,'userdata',0);        end; % if so    end;end; %while% if everything is ak, return the entered parametersif get(ok_ctl,'userdata')==1,    params = psp;    % otherwise return an empty vectorelse    params = [];end;delete(h0);