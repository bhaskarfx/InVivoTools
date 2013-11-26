function [outstim] = loadstim(CSSstim)% stimulus is presented by changing the color lookup table%CSSstim = unloadstim(CSSstim);outstim = CSSstim;if haspsychtbox   StimWindowGlobals;   CSSparams = CSSstim.CSSparams;    dfs = struct(getdisplayprefs(CSSstim));   tRes = (1/StimWindowRefresh);   fps = StimWindowRefresh;   biggestrad = max([CSSparams.radius CSSparams.surrradius]); % to center in square of double the size   hasSurround = (CSSparams.surrradius>=0);   bigRad = biggestrad; if bigRad==0,bigRad=1; end;   offscreen = screen(StimWindow,'OpenOffscreenWindow',255,2*bigRad*[0 0 1 1]);   if hasSurround  % make surround oval with color index 2     screen(offscreen,'FillOval',2,biggestrad+CSSparams.surrradius*[-1 -1 1 1]);   end;   if CSSparams.radius>0 % place on to a center oval with color index 1      screen(offscreen,'FillOval',1,biggestrad+CSSparams.radius*[-1 -1 1 1]);   end;   middle=mean([CSSparams.FGc;CSSparams.FGs])/255;   fgc=round(255*(middle+CSSparams.contrast*(CSSparams.FGc/255-middle))); % center color   fgs=round(255*(middle+CSSparams.contrast*(CSSparams.FGs/255-middle))); % surround color   % making color tables   % 1, background only: all color indices to background color   ctab{1} = repmat(CSSparams.BG,256,1);     % 2, center only: color 1 = center color, rest is background   ctab{2} = [CSSparams.BG; fgc; repmat(CSSparams.BG,254,1)];    % 3, surround only: color 2 = surround color, rest is background   ctab{3} = [CSSparams.BG; CSSparams.BG; fgs;  repmat(CSSparams.BG,253,1)];    % 4, both center and surround: color 1 = center color, color 2 =   %        surround color, rest i background   ctab{4} = [CSSparams.BG; fgc; fgs; repmat(CSSparams.BG,253,1)]; % bg, center color, surround color, rest to bg      frames=ones(1,ceil(CSSparams.stimduration/tRes)); % default to background frame number 1   start = max([1 1+round(CSSparams.lagon/tRes)]);  % center on time   if CSSparams.lagoff>0       stop=min([length(frames) 1+round(CSSparams.lagoff/tRes)]); % center off time    else       stop = length(frames);    end;   sstart = max([1 1+round(CSSparams.surrlagon/tRes)]); % surround on time   if CSSparams.surrlagoff>0      sstop=min([length(frames) 1+round(CSSparmas.surrlagoff/tRes)]); % surround off time   else       sstop = length(frames);    end;   frames(start:stop)=2; % center only frames   frames(sstart:sstop)=3; % surround only frames   frames(intersect(start:stop,sstart:sstop))=4; % center and surround frames   % rect = [ CSSparams.center-biggestrad CSSparams.center+biggestrad ];   dP = cat(2,{'fps',fps,'rect',dfs.rect,'frames',frames},CSSparams.dispprefs);   dS = { 'displayType', 'CLUTanim', 'displayProc', 'standard', ...         'offscreen', offscreen, 'frames', size(ctab,2), ...		 'clut_usage', repmat(1,256), 'depth', 8, ...		 'clut_bg', ctab{1}, 'clut', ctab, 'clipRect', [], ...		 'makeClip', 0,'userfield',[] }; 		   outstim.stimulus = setdisplaystruct(outstim.stimulus,displaystruct(dS));  outstim.stimulus = setdisplayprefs(outstim.stimulus,displayprefs(dP));end;outstim.stimulus = loadstim(outstim.stimulus);