function S = periodicscript(PSparams,OLDSCRIPT)

% NewStim package: PERIODICSCRIPT
%
%  SCRIPT = PERIODICSCRIPT(PARAMETERS)
%
%  Creates a PERIODICSCRIPT object, which is a descendant of the STIMSCRIPT
%  object.  It allows one to easily create a script of PERIODICSTIM stimuli
%  which vary along commonly varied dimensions.  The PARAMETERS structure has
%  the same format as PERIODICSTIM except that certain elements can accept
%  vector arguments, which creates an array of stimuli each of which has
%  one of the values of the vector argument.  For example, if the contrast
%  field is set to [0.1 0.5 1] and all other fields are single-valued, then
%  three stimuli will be created, each with one of the contrasts specified.
%
%  PARAMETERS should be a struct with fields described below.  Those fields
%  which are marked with a * are the fields which can accept vector arguments.
%
%  One may also use the construction SCRIPT=PERIODICSCRIPT('graphical'), which
%  will prompt the user for all fields.  One may use the construction
%  SCRIPT=PERIODICSCRIPT('graphical',OLDPERIODICSCRIPT), which will prompt the
%  user for all fields but provide the parameters of OLDPERIODICSCRIPT as
%  defaults.  Finally, one may use SCRIPT=PERIODICSCRIPT('default') to assign
%  default parameter values.
%
%
%  imageType       -   0 => field (single luminance across field)
%                      1 => square (field split into light and dark halves)
%                      2 => sine (smoothly varying shades)
%                      3 => triangle (linear light->dark->light transition)
%                      4 => lightsaw (linear light->dark transition)
%                      5 => darksaw (linear dark->light transition)
%                      6 => <sFrequency> bars of <barwidth> width (see below)
%                      7 => edge (like lightsaw but with bars determining width
%                           of saw)
%                      8 => bump (bars with internal smooth dark->light->dark
%                           transitions
%  animType        -   0 => no animation
%                      1 => square wave
%                      2 => sine wave
%                      3 => ramp
%                      4 => drifting grating
%                      5 => fixed on-duration flicker for field stimulus
%  flickerType     -   0 => light > background -> light
%                      1 => dark -> background -> dark
%                      2 => counterphase
%  *angle          -   orientation, in degrees, 0 is up
%  distance        -   distance of the monitor from the viewer
%  *sFrequency     -   spatial wavelength, in degrees
%  *tFrequency     -   temporal frequency (Hz)
%  *sPhaseShift    -   Phase shift (only works for counterphase stims but must
%                      be passed for all), in radians where 2*pi is 1 cycle
%  *barWidth       -   Width of bar (% of display rgn), only valid for bar stims
%                      but must have value passed for all stims.
%  [1x4] rect      -   The rectangle on the screen where the stimulus will be
%                      displayed:  [ top_x top_y bottom_x bottom_y ]
%  *nCycles        -   The number of times the stimulus should be repeated
%  *contrast       -   0-1: 0 means no diff from background, 1 is max difference
%  *background     -   luminance of the background, 0-1 from chromhigh (1) to chromlow (0)
%  *backdrop       -   describes area outside of display region
%                      If [Nx1], then indicates luminance of background, 0-1 from chromhigh to low
%                      If [Nx3], then indicates actual RGB values to be used
%  *barColor       -   For bar stimuli, the color of the bars (0-1 from chrom high to low)
%  *nSmoothPixels  -   Blurs the image with a boxcar of this width
%  *fixedDur        -   fixed on-duration of squarewave flicker
%  windowShape     -   0 rectangle,1 oval,2 angled rect,3 angled oval
%                  -     8 - gaussian windowed (sigma_x=0.33*width/sqrt(8*log(2)) )
%                                              (sigma_y=0.33*height/sqrt(8*log(2)) )
%  loops           -   Number of forward&back loops, 0 is forward,
%                        1 is forward and back, 2 is forward, back,
%                        and forward again, etc.
%  size            -   Diameter in degrees. If empty, it is ignored and
%                        full rect is used.
%
% See also: STIMSCRIPT PERIODICSTIM

NewStimScriptListAdd('periodicscript');
if nargin==0,
    S = periodicscript('default');
    return;
end;

default_p = default; % private function

finish = 1;

if nargin==1,
    oldscript = [];
else,
    if ~isa(OLDSCRIPT,'periodicscript'),
        error('OLDSCRIPT must be a periodicscript.');
    end;
    oldscript = OLDSCRIPT;
end;

if ischar(PSparams),
    if strcmp(PSparams,'graphical'),
        % load parameters graphically
        p = get_graphical_input(oldscript);
        if isempty(p), finish = 0; else, PSparams = p; end;
    elseif strcmp(PSparams,'default'),
        PSparams = default_p;
    else,
        error('Unknown string input to periodicscript');
    end;
else,
    [good,err] = verifyperiodicscript(PSparams);
    if ~good, error(['Could not create periodicscript: ' err]); end;
end;

if finish,
    
    s = stimscript(0);
    data = struct('PSparams',PSparams);
    
    S = class(data,'periodicscript',s);
    theParams = PSparams;
    theParams.angle = 0; theParams.sFrequency=1; theParams.tFrequency=1;
    theParams.nCycles=1; theParams.contrast=1; theParams.background=0;
    theParams.backdrop=1; theParams.nSmoothPixels=2; theParams.barColor=1;
    theParams.barWidth=0.5; theParams.sPhaseShift=0; theParams.fixedDur=0;
    theParams.size = 1;
    for n1=1:length(PSparams.angle),
        for n2=1:length(PSparams.sFrequency),
            for n3=1:length(PSparams.tFrequency),
                for n4=1:length(PSparams.nCycles),
                    for n5=1:length(PSparams.contrast),
                        for n6=1:length(PSparams.background),
                            for n7=1:size(PSparams.backdrop,1),
                                for n8=1:length(PSparams.nSmoothPixels),
                                    for n9=1:length(PSparams.barColor),
                                        for n10=1:length(PSparams.barWidth),
                                            for n11=1:length(PSparams.sPhaseShift),
                                                for n12=1:length(PSparams.fixedDur),
                                                    for n13=1:length(PSparams.size),
                                                        theParams.angle=PSparams.angle(n1);
                                                        theParams.sFrequency=PSparams.sFrequency(n2);
                                                        theParams.tFrequency=PSparams.tFrequency(n3);
                                                        if PSparams.fixedDur ~= 0
                                                            theParams.nCycles = PSparams.fixedDur(n12)*theParams.tFrequency;
                                                        else
                                                            theParams.nCycles = PSparams.nCycles(n4);
                                                        end
                                                        theParams.contrast = PSparams.contrast(n5);
                                                        theParams.background = PSparams.background(n6);
                                                        theParams.backdrop = PSparams.backdrop(n7,:);
                                                        theParams.nSmoothPixels=PSparams.nSmoothPixels(n8);
                                                        theParams.barColor = PSparams.barColor(n9);
                                                        theParams.barWidth = PSparams.barWidth(n10);
                                                        theParams.sPhaseShift = PSparams.sPhaseShift(n11);
                                                        theParams.fixedDur = PSparams.fixedDur(n12);
                                                        theParams.size = PSparams.size(n13);
                                                        if ~isempty(PSparams.ps_add)
                                                            masking_stims=get(evalin('base',PSparams.ps_add));
                                                            for n14=1:length(masking_stims)
                                                                theParams.ps_add = masking_stims{n14};
                                                                stim = periodicstim(theParams); % should never fail
                                                                S = append(S,stim);
                                                            end;
                                                        else
                                                            stim = periodicstim(theParams); % should never fail
                                                            S = append(S,stim);
                                                        end
                                                end; 
                                                end; end; end; end; end; end; end; end; end; end; end; end;
    % generate all these stims
else,
    S = [];
end;


%%% GET_GRAPHICAL_INPUT function %%%

function params = get_graphical_input(oldscript);

if isempty(oldscript),
    default_p = default; % private function
    
    rect_str = mat2str(default_p.rect);
    image_val = default_p.imageType+1;
    anim_val = default_p.animType+1;
    flicker_val = default_p.flickerType+1;
    chromhigh_str = mat2str(default_p.chromhigh);
    chromlow_str = mat2str(default_p.chromlow);
    angle_str = mat2str(default_p.angle);
    sFrequency_str = mat2str(default_p.sFrequency);
    tFrequency_str = mat2str(default_p.tFrequency);
    nCycles_str = mat2str(default_p.nCycles);
    distance_str = mat2str(default_p.distance); % irrelevant for PTB3
    contrast_str = mat2str(default_p.contrast);
    background_str = mat2str(default_p.background);
    backdrop_str = mat2str(default_p.backdrop);
    smooth_str = mat2str(default_p.nSmoothPixels);
    shape_val = default_p.windowShape+1;
    barColor_str = mat2str(default_p.barColor);
    barWidth_str = mat2str(default_p.barWidth);
    sPhase_str = mat2str(default_p.sPhaseShift);
    fixed_str = mat2str(default_p.fixedDur);
    dp_str = wimpcell2str(default_p.dispprefs);
    loops_str = mat2str(default_p.loops);
    size_str = mat2str(default_p.size);
    ps_mask = default_p.ps_add;
else,
    oldS = struct(oldscript); PSparams = oldS.PSparams;
    rect_str = mat2str(PSparams.rect);
    image_val = (PSparams.imageType+1);
    anim_val = (PSparams.animType+1);
    flicker_val = (PSparams.flickerType+1);
    chromhigh_str = mat2str(PSparams.chromhigh);
    chromlow_str = mat2str(PSparams.chromlow);
    angle_str = mat2str(PSparams.angle);
    sFrequency_str = mat2str(PSparams.sFrequency);
    tFrequency_str = mat2str(PSparams.tFrequency);
    nCycles_str = mat2str(PSparams.nCycles);
    if isfield(PSparams,'distance') % irrelevant for PTB3
        distance_str = num2str(PSparams.distance);
    else
        NewStimGlobals;
        distance_str = num2str(NewStimViewingDistance);
    end
    contrast_str = mat2str(PSparams.contrast);
    background_str = mat2str(PSparams.background);
    backdrop_str = mat2str(PSparams.backdrop);
    smooth_str = mat2str(PSparams.nSmoothPixels);
    shape_val = PSparams.windowShape + 1;
    barColor_str = mat2str(PSparams.barColor);
    barWidth_str = mat2str(PSparams.barWidth);
    sPhase_str = mat2str(PSparams.sPhaseShift);
    fixed_str = mat2str(PSparams.fixedDur);
    dp_str = wimpcell2str(PSparams.dispprefs);
    if isfield(PSparams,'loops'),
        loops_str = mat2str(PSparams.loops);
    else, loops_str = '0';
    end
    if isfield(PSparams,'size'),
        size_str = mat2str(PSparams.size);
    else
        size_str = mat2str(NaN);
    end;
    %%
    if isfield(PSparams,'ps_add'),
        ps_mask = PSparams.ps_add;
    else
        ps_mask = [];
    end;
end;


% make figure layout
h0 = figure('Color',[0.8 0.8 0.8], ...
    'PaperPosition',[18 180 576 432], ...
    'PaperUnits','points', ...
    'Position',[30 100 415 650], ...
    'MenuBar','none');
settoolbar(h0,'none');

% window heading
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'FontSize',18, ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[50 595 285 25], ...
    'String','New periodicscript object...', ...
    'Style','text', ...
    'Tag','StaticText1');

% define top frame
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Position',[17 419 383 175], ...
    'Style','frame', ...
    'Tag','Frame1');

% frame heading
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7 ], ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[25 570 130 19], ...
    'String','Static parameters:', ...
    'Style','text', ...
    'Tag','StaticText3');

% rectangle entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 548 225 19], ...
    'String','[1x4] Rect [top_x top_y bottom_x bottom_y]', ...
    'Style','text', ...
    'Tag','StaticText2');
rect_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[255 552 135 19], ...
    'String',rect_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% image type entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 521 55 19], ...
    'String','image type', ...
    'Style','text', ...
    'Tag','StaticText2');
image_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Max',9, ...
    'Min',1, ...
    'Position',[85 525 80 16], ...
    'String',{'field','square','sine','triangle','lightsaw','darksaw','bars','edge','bump'}, ...
    'Style','popupmenu', ...
    'Tag','PopupMenu1', ...
    'Value',image_val);

% flicker entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[185 521 35 19], ...
    'String','flicker', ...
    'Style','text', ...
    'Tag','StaticText2');
flicker_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Max',3, ...
    'Min',1, ...
    'Position',[225 525 165 16], ...
    'String',{'light->background->light', 'dark->background->dark','counterphase'}, ...
    'Style','popupmenu', ...
    'Tag','PopupMenu1', ...
    'Value',flicker_val);

% animation type entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 496 54 19], ...
    'String','animation', ...
    'Style','text', ...
    'Tag','StaticText2');
anim_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Max',6, ...
    'Min',1, ...
    'Position',[80 500 120 16], ...
    'String',{'static','square','sine','ramp','drifting','fixed on-duration (field only)'}, ...
    'Style','popupmenu', ...
    'Tag','PopupMenu1', ...
    'Value',anim_val);

% stimulus shape entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position', [210 496 91 19], ...
    'String','stimulus shape', ...
    'Style','text', ...
    'Tag','StaticText2');
shape_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Max',2, ...
    'Min',1, ...
    'Position',[290 500 100 16], ...
    'String',{'rectangle', 'oval','angled rect','angled oval','n/a','n/a','n/a','n/a','gaussian'}, ...
    'Style','popupmenu', ...
    'Tag','PopupMenu1', ...
    'Value',shape_val);

% distance entry
% h1 = uicontrol('Parent',h0, ...
%     'Units','pixels', ...
%     'BackgroundColor',[0.7 0.7 0.7], ...
%     'HorizontalAlignment','left', ...
%     'ListboxTop',0, ...
%     'Position', [25 472 150 19], ...
%     'String','[1x1] distance to screen (cm)', ...
%     'Style','text', ...
%     'Tag','StaticText2');
% distance_ctl = uicontrol('Parent',h0, ...
%     'Units','pixels', ...
%     'BackgroundColor',[1 1 1], ...
%     'FontSize',9, ...
%     'HorizontalAlignment','left', ...
%     'ListboxTop',0, ...
%     'Position',[175 476 40 19], ...
%     'String',distance_str, ...
%     'Style','edit', ...
%     'Tag','EditText1');

% chromaticity entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position', [225 472 81 19], ...
    'String','color high/low', ...
    'Style','text', ...
    'Tag','StaticText2');
chromhighval = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'ListboxTop',0, ...
    'Position',[280 476 110 16], ...
    'String',chromhigh_str, ...
    'Style','Edit', ...
    'Tag','');
chromlowval = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'ListboxTop',0, ...
    'Position',[280 446 110 16], ...
    'String',chromlow_str, ...
    'Style','Edit', ...
    'Tag','');

% display prefs entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 450 250 19.2], ...
    'String','Set displayprefs opts,example:{''BGpretime'',1}',...
    'Style','text', ...
    'Tag','StaticText2');
dp_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize', 9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 430 343 19], ...
    'String',dp_str, ...
    'Style','edit', ...
    'Tag','EditText1');
sh=10;
% angle entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 384+sh 105 19], ...
    'String','[1xn] angles, 0 is up', ...
    'Style','text', ...
    'Tag','StaticText2');
angle_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 388+sh 245 19], ...
    'String',angle_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% spatial frequency entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 364+sh 130 19], ...
    'String','[1xm] spatial frequencies', ...
    'Style','text', ...
    'Tag','StaticText2');
sFrequency_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 368+sh 245 19], ...
    'String',sFrequency_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% temporal frequency entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 344+sh 140 19], ...
    'String','[1xk] temporal frequencies', ...
    'Style','text', ...
    'Tag','StaticText2');
tFrequency_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 348+sh 245 19], ...
    'String',tFrequency_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% number of cycles entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 324+sh 120 19], ...
    'String','[1xq] number of cycles', ...
    'Style','text', ...
    'Tag','StaticText2');
nCycles_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 328+sh 245 19], ...
    'String',nCycles_str, ...
    'Style','edit', ...
    'Tag','EditText1');

%      % duration of display entry
%      h1 = uicontrol('Parent',h0, ...
%              'Units','pixels', ...
%              'BackgroundColor',[0.8 0.8 0.8], ...
%              'HorizontalAlignment','left', ...
%              'ListboxTop',0, ...
%              'Position',[17 324+sh 120 19], ...
%              'String','[1xq] stimulus duration', ...
%              'Style','text', ...
%              'Tag','StaticText2');
%      durtn_ctl = uicontrol('Parent',h0, ...
%              'Units','pixels', ...
%              'BackgroundColor',[1 1 1], ...
%               'FontSize',9, ...
%              'HorizontalAlignment','left', ...
%              'ListboxTop',0, ...
%              'Position',[155 328+sh 245 19], ...
%              'String',durtn_str, ...
%              'Style','edit', ...
%              'Tag','EditText1');

% contrast entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 304+sh 120 19], ...
    'String','[1xj] contrasts [0..1]', ...
    'Style','text', ...
    'Tag','StaticText2');
contrast_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 308+sh 245 19], ...
    'String',contrast_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% background entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 284+sh 125 19], ...
    'String','[1xs] backgrounds [0..1]', ...
    'Style','text', ...
    'Tag','StaticText2');
background_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 288+sh 245 19], ...
    'String',background_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% backdrop entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 264+sh 120 19], ...
    'String','[tx1or3] backdrops ', ...
    'Style','text', ...
    'Tag','StaticText2');
backdrop_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 268+sh 245 19], ...
    'String',backdrop_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% N smoothing pixels entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 244+sh 120 19], ...
    'String','[1xw] smooth N pixels', ...
    'Style','text', ...
    'Tag','StaticText2');
smooth_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 248+sh 245 19], ...
    'String',smooth_str, ...
    'Style','edit', ...
    'Tag','EditText1');

h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[17 244+sh-20 120 19], ...
    'String','[1x1] # of loops', ...
    'Style','text', ...
    'Tag','StaticText2');
loops_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[155 248+sh-20 245 19], ...
    'String',loops_str, ...
    'Style','edit', ...
    'Tag','EditText1');


% second frame
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Position',[17 178 383 60], ...
    'Style','frame', ...
    'Tag','Frame1');

% frame heading
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'FontWeight','bold', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[32 216 288 19], ...
    'String','For bars only (ignore this area for other stims):', ...
    'Style','text', ...
    'Tag','StaticText2');

% bar color entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 200 120 19], ...
    'String','[1xh] barColors [0..1]', ...
    'Style','text', ...
    'Tag','StaticText2');
barColor_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[145 204 245 19], ...
    'String',barColor_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% bar width entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 180 100 19], ...
    'String','[1xp] barWidth:', ...
    'Style','text', ...
    'Tag','StaticText2');
barWidth_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[145 184 245 19], ...
    'String',barWidth_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% third frame
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7 ], ...
    'ListboxTop',0, ...
    'Position',[17 135 383 39], ...
    'Style','frame', ...
    'Tag','Frame1');

% frame heading
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'FontWeight','bold', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[32 152 288 19], ...
    'String','Phase (0:C=B/W; pi/2: C=B, -pi/2: C=W):', ...
    'Style','text', ...
    'Tag','StaticText2');

% phase shift entry
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 136 185 19], ...
    'String','[1xy] spatial phase shift [0..2*pi]', ...
    'Style','text', ...
    'Tag','StaticText2');
sPhase_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[200 140 190 19], ...
    'String',sPhase_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% fourth frame
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'ListboxTop',0, ...
    'Position',[17 90 383 40], ...
    'Style','frame', ...
    'Tag','Frame1');

% frame heading
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'FontWeight','bold', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[32 109 350 19], ...
    'String','For fixed dur animation w/ fields only (ignore for others):', ...
    'Style','text', ...
    'Tag','StaticText2');

% duration heading
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 92 115 19], ...
    'String','[1xz] fixed on duration', ...
    'Style','text', ...
    'Tag','StaticText2');
fixed_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[145 96 245 19], ...
    'String',fixed_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% size
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 72 115 19], ...
    'String','Size', ...
    'Style','text', ...
    'Tag','StaticText2');
size_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[145 76 245 19], ...
    'String',size_str, ...
    'Style','edit', ...
    'Tag','EditText1');

% mask
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[25 52 115 19], ...
    'String','Mask', ...
    'Style','text', ...
    'Tag','StaticText2');
mask_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'FontSize',9, ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[95 56 85 19], ...
    'String',ps_mask, ...
    'Style','edit', ...
    'Tag','EditText1');

% OK button
ok_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'Callback','set(gcbo,''userdata'',[1]);uiresume(gcf);', ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[29.6 39.2-30 71.2 27.2], ...
    'String','OK', ...
    'Tag','Pushbutton1', ...
    'UserData',0);

% Cancel button
cancel_ctl = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'Callback','set(gcbo,''userdata'',[1]);uiresume(gcf);', ...
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[166.4 37.6-30 71.2 27.2], ...
    'String','Cancel', ...
    'Tag','Pushbutton1', ...
    'UserData',0);

% Help button
h1 = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'Callback','textbox(''Periodicscript Help'',help(''periodicscript''));', ...      
    'FontWeight','bold', ...
    'ListboxTop',0, ...
    'Position',[297.6 38.4-30 71.2 27.2], ...
    'String','Help', ...
    'Tag','Pushbutton1');

error_free = 0;

while ~error_free,
    drawnow;
    uiwait(h0);
    
    if get(cancel_ctl,'userdata')==1,
        error_free = 1;
        
    else, % it was OK
        rect_str = get(rect_ctl,'String');
        image_val = get(image_ctl,'value');
        flicker_val = get(flicker_ctl,'value');
        anim_val = get(anim_ctl,'value');
        shape_val = get(shape_ctl,'value');
        chromhigh_str = get(chromhighval,'String');
        chromlow_str = get(chromlowval,'String');
        angle_str = get(angle_ctl,'String');
        sFrequency_str = get(sFrequency_ctl,'String');
        tFrequency_str = get(tFrequency_ctl,'String');
        nCycles_str = get(nCycles_ctl,'String');
        %         durtn_str = get(durtn_ctl,'String');
        distance_str = '15';%get(distance_ctl,'String');
        contrast_str = get(contrast_ctl,'String');
        background_str = get(background_ctl,'String');
        backdrop_str = get(backdrop_ctl,'String');
        smooth_str = get(smooth_ctl, 'String');
        barColor_str = get(barColor_ctl,'String');
        barWidth_str = get(barWidth_ctl,'String');
        sPhase_str = get(sPhase_ctl,'String');
        fixed_str = get(fixed_ctl,'String');
        dp_str = get(dp_ctl,'String');
        loops_str = get(loops_ctl,'String');
        size_str = get(size_ctl,'String');
        ps_mask = get(mask_ctl,'String');
        
        so = 1; % syntax_okay;
        try, rect = eval(rect_str);
        catch, errordlg('Syntax error in Rect'); so=0; end;
        imageType = image_val - 1;
        flickerType = flicker_val - 1;
        animType = anim_val - 1;
        shape = shape_val - 1;
        try, angle = eval(angle_str);
        catch, errordlg('Syntax error in angle'); so=0; end;
        try, sFrequency = eval(sFrequency_str);
        catch, errordlg('Syntax error in spatial frequency'); so=0; end;
        try, tFrequency = eval(tFrequency_str);
        catch, errordlg('Syntax error in temporal frequency'); so=0; end;
        try, nCycles = eval(nCycles_str);
        catch, errordlg('Syntax error in number of cycles'); so=0; end;
        %              try, durtn = eval(durtn_str);
        %              catch, errordlg('Syntax error in duration'); so=0; end;
        try, distance = eval(distance_str);
        catch, errordlg('Syntax error in distance'); so=0; end;
        try, chromhigh= eval(chromhigh_str);
        catch, errordlg('Syntax error in chromhigh'); so=0; end;
        try, chromlow= eval(chromlow_str);
        catch, errordlg('Syntax error in chromlow'); so=0; end;
        try, contrast = eval(contrast_str);
        catch, errordlg('Syntax error in contrast'); so=0; end;
        try, background = eval(background_str);
        catch, errordlg('Syntax error in background'); so=0; end;
        try, backdrop = eval(backdrop_str);
        catch, errordlg('Syntax error in backdrop'); so=0; end;
        try, smooth = eval(smooth_str);
        catch, errordlg('Syntax error in smooth'); so=0; end;
        try, barColor = eval(barColor_str);
        catch, errordlg('Syntax error in barColor'); so=0; end;
        try, barWidth = eval(barWidth_str);
        catch, errordlg('Syntax error in barWidth'); so=0; end;
        try, sPhase = eval(sPhase_str);
        catch, errordlg('Syntax error in spatial phase'); so=0; end;
        try, fixed = eval(fixed_str);
        catch, errordlg('Syntax error in fixed on duration'); so=0; end;
        try, dp = eval(dp_str);
        catch, errordlg('Syntax error in displayprefs'); so=0; end;
        try, loops = eval(loops_str);
        catch, errordlg('Syntax error in loops.'); so=0;end;
        try, size = eval(size_str);
        catch, errordlg('Syntax error in size.'); so=0;end;
        try, ps_add = ps_mask;
        catch, errordlg('Syntax error in mask.','Periodicscript'); so=0;end;
        
        if so
            
            %                              % determine number of cycles from duration and temporal frequency
            %                              nCycles = round(durtn .* tFrequency);
            
            psp = struct('imageType',imageType,'animType',animType,'flickerType',flickerType, ...
                'angle',angle,'chromhigh',chromhigh,'chromlow',chromlow,'sFrequency',sFrequency, ...
                'sPhaseShift',sPhase,'distance',distance,'tFrequency',tFrequency, ...
                'barWidth',barWidth,'rect',rect,'nCycles',nCycles, ...
                'contrast',contrast,'background',background,'backdrop',backdrop, ...
                'barColor',barColor,'nSmoothPixels',smooth,'fixedDur',fixed, ...
                'windowShape',shape,'loops',loops,'size',size,'ps_add',ps_add);
            
            psp.dispprefs = dp;
            
            [good, err] = verifyperiodicscript(psp);
            
            if ~good
                errordlg(['Parameter value invalid: ' err]);
            else
                error_free = 1;
            end;
            
        else
            set(ok_ctl,'userdata',0);
        end;
        
    end;
    
end; % while

% if everything is ok, return the entered parameters
if get(ok_ctl,'userdata')==1
    params = psp;
    
    % otherwise return an empty vector
else
    params = [];
end;
delete(h0);


%%% end of GET_GRAPHICAL_INPUT function %%%


%%% WIMPCELL2STR function %%%

function str = wimpcell2str(theCell)
%1-dim cells only, only chars and matricies
str = '{  ';
for i=1:length(theCell),
    if ischar(theCell{i})
        str = [str '''' theCell{i} ''', '];
    elseif isnumeric(theCell{i}),
        str = [str mat2str(theCell{i}) ', '];
    end;
end;
str = [str(1:end-2) '}'];
