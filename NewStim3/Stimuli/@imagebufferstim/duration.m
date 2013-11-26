function t = duration(PSstim)

PSparams = struct(PSstim.PSparams);

if isfield(PSparams,'loops'),
        loops = PSparams.loops;
else, loops = 0;
end;

StimWindowGlobals;
if ~haspsychtbox|isempty(StimWindowRefresh)|~isloaded(PSstim),
	t = (PSparams.imgnumber*(loops+1)*PSparams.pause/1000)+(PSparams.imgnumber*(loops+1)*PSparams.blankpause/1000);
else, % calculate exactly
    df = struct(getdisplayprefs(PSstim));
	pauseRefresh = zeros(1,length(df.frames));
    if df.roundFrames,
          pauseRefresh(:) = round(StimWindowRefresh / df.fps);
    else,
          pauseRefresh = diff(fix((1:(length(df.frames)+1)) * StimWindowRefresh / df.fps));
    end;
	t = sum(pauseRefresh)/StimWindowRefresh + duration(PSstim.stimulus);
end;
