% prior to running, user needs to:%   turn off screen saver%   put computer into 256 colors%   set screen res%   mount any other necessary computersif 0,    	applescript('helloIgor.applescript');end;NewStimInit;NewStimGlobals;ReceptiveFieldGlobals;%load warmup; %warmup_stim = periodicstim3D('default');warmup_stim = periodicstim('default');%warmup_stim = stochasticgridstim3D('default');%warmup_stim = lammestim('default');warmup = StimScript(0); warmup=append(warmup,warmup_stim);warmup=loadStimScript(warmup);MTI=DisplayTiming(warmup);DisplayStimScript(warmup,MTI,0);cd(NewStimRemoteCommDir);delete runit.mwhile 1,  % needs control-C to ex	pause(1);	if KbCheck 		% then quit	    CloseStimScreen;		break	end	cd(NewStimRemoteCommDir); % refresh file directory	disp('Checking for runit. Hold any key to exit.');	txt = checkscript('runit.m');	if ~isempty(txt)		disp(txt)		eval(txt); 		cd(NewStimRemoteCommDir); 		disp('Ran file, deleting...');			delete runit.m; 		lastrun_script = txt;	end;end;