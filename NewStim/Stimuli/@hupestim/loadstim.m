function [outstim] = loadstim(stim)%hupestim/loadstim%% 2009, Alexander Heimel%StimWindowGlobals;NewStimGlobals;stim = unloadstim(stim);  % unload old version before loadingparams = stim.params;width  = params.rect(3) - params.rect(1);height = params.rect(4) - params.rect(2);% set initial random staterand('state',params.randState); %#ok<RAND>% set BG, figure and ground colorsclut_bg = repmat(params.BG,256,1);clut_usage = [ 1 ones(1,2) zeros(1,255-2) ]';max_intensity_color = [255 255 255];fig_color_rgb = params.BG + params.figcontrast * params.BG;if fig_color_rgb(1) > max_intensity_color(1)	error('HUPESTIM/LOADSTIM: figcontrast too high. decrease background luminance');endgnd_color_rgb = params.BG + params.gndcontrast * params.BG;if gnd_color_rgb(1) > max_intensity_color(1)	error('HUPESTIM/LOADSTIM: gndcontrast too high. decrease background luminance');endclut = repmat(params.BG,256,1);bg_color = 0;fig_color = 1;gnd_color = 2;clut(bg_color+1,:) = params.BG;clut(fig_color+1,:) = fig_color_rgb;clut(gnd_color+1,:) = gnd_color_rgb;dp = getdisplayprefs(stim.stimulus);dps = struct(dp);% set framerate if there is open stimscreenif ~isempty(StimWindowRefresh)	dps.fps = StimWindowRefresh;endn_frames = ceil(params.duration * dps.fps);n_still_frames = round(params.movement_onset * dps.fps);n_movement_frames = n_frames - n_still_frames;% initiate offscreen handle vectoroffscreen = zeros(1,n_frames);% compute rotation matrixangle = params.direction * pi /180;rotation = [ cos(angle) sin(angle); -sin(angle) cos(angle)];% compute motion vectorunit_motion_per_frame = NewStimViewingDistance * 2 *tan(1/2 * pi/180) * NewStimPixelsPerCm  / dps.fps ;unit_motion_per_frame = -(rotation * [unit_motion_per_frame; 0])'; % in pixels, minus is to match periodicstim% compute figurefigwidth_pixels = NewStimViewingDistance * 2*tan( params.width/2 *pi/180) * NewStimPixelsPerCm;figlength_pixels = NewStimViewingDistance * 2*tan( params.figlength/2 *pi/180) * NewStimPixelsPerCm;figbasepoints = [ -figwidth_pixels -figlength_pixels; ...	-figwidth_pixels +figlength_pixels; ...	+figwidth_pixels +figlength_pixels; ...	+figwidth_pixels -figlength_pixels ];figbasepoints = (rotation * figbasepoints')';figbasepoints = figbasepoints + repmat(round(params.center),4,1);figpoints = figbasepoints;figmotion_per_frame = unit_motion_per_frame * params.figspeed;% ground stimuligndwidth_pixels = figwidth_pixels ;% extend after rotation:gndextend = abs(rotation * [gndwidth_pixels figlength_pixels*max(params.gndlengthrange)]' )';gndmotion_per_frame = unit_motion_per_frame * params.gndspeed;gndtotalmovingdistance = gndmotion_per_frame * n_frames;gndrectleft = min( 0, -gndtotalmovingdistance(1) ) - gndextend(1);gndrectright = max( width, width - gndtotalmovingdistance(1) ) + gndextend(1);gndrecttop = min( 0, -gndtotalmovingdistance(2) )- gndextend(2);gndrectbottom = max( height, height -gndtotalmovingdistance(2) )+ gndextend(2);gndrectwidth = gndrectright - gndrectleft;gndrectheight = gndrectbottom - gndrecttop;average_size_ground_stimulus = mean(params.gndlengthrange)*2*figlength_pixels*2*figwidth_pixels;number_of_ground_to_fill_rect = gndrectheight * gndrectwidth / average_size_ground_stimulus;n_gnd_stimuli = ceil(params.gnddensity * number_of_ground_to_fill_rect);gndpoints = cell(n_gnd_stimuli,1);rf_clearance_radius_pixels = NewStimViewingDistance * 2* tan( params.rf_clearance_radius/2 *pi/180) * NewStimPixelsPerCm;for i = 1:n_gnd_stimuli	gndlength_pixels = figlength_pixels * ...		(params.gndlengthrange(1) + ...		(params.gndlengthrange(2)-params.gndlengthrange(1))*rand(1));	gndbasepoints = [ -gndwidth_pixels -gndlength_pixels; ...		-gndwidth_pixels +gndlength_pixels; ...		+gndwidth_pixels +gndlength_pixels; ...		+gndwidth_pixels -gndlength_pixels ];	gndbasepoints = (rotation * gndbasepoints')';		gndcenter = params.center;	center_clear = 0;	disp('nieuw');	while ~center_clear		gndcenter = [gndrectleft + gndrectwidth*rand(1) gndrecttop+gndrectheight*rand(1)];		gndpoints{i} = gndbasepoints + repmat(round(gndcenter),4,1)		center_clear = 1;		for j=1:4			if norm(gndpoints{i}(j,:)-params.center) < rf_clearance_radius_pixels				center_clear = 0;				break;			end		end	end	endShowStimScreen;for f=1:n_movement_frames+1 % first a still frame	% new offscreen	offscreen(f) = Screen(StimWindow,'OpenOffscreenWindow',255,[0 0 width height]);	% set background	Screen(offscreen(f),'FillRect',0)	% set ground stimuli	for i=1:n_gnd_stimuli		% plot ground stimulus		Screen(offscreen(f),'FillPoly',gnd_color,gndpoints{i})	end	% set figure	Screen(offscreen(f),'FillPoly',fig_color,figpoints)	% movement	figpoints = figpoints   + repmat(figmotion_per_frame,4,1);	for i=1:n_gnd_stimuli		gndpoints{i} = gndpoints{i}   + repmat(gndmotion_per_frame,4,1);	endend;dps.frames = [ones(1,n_still_frames) 2:n_movement_frames+1];if isfield(dps,'defaults')	dps = rmfield(dps,'defaults');endstim = setdisplayprefs(stim,displayprefs(struct2vararg(dps)));displayType = 'Movie';displayProc = 'standard';dS = {'displayType', displayType, 'displayProc', displayProc, ...	'offscreen', offscreen, 'frames', n_frames, 'depth', 8, ...	'clut_usage', clut_usage, 'clut_bg', clut_bg, 'clut', clut};outstim = stim;outstim.stimulus = setdisplaystruct(outstim.stimulus,displaystruct(dS));outstim.stimulus = loadstim(outstim.stimulus);