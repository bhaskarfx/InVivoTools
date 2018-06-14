function NewStimInit

pwd = which('NewStimInit');

pi = find(pwd==filesep); 
pwd = [pwd(1:pi(end)-1) filesep];

addpath(pwd,...
fullfile(pwd,'Scripts'),...
fullfile(pwd, 'NewStimProcs'),...
fullfile(pwd, 'NewStimDisplayProcs'),...
fullfile(pwd, 'NewStimServices'),...
fullfile(pwd, 'NewStimUtilities'),...
fullfile(pwd, 'NewStimUtilities' , 'NewStimConfigureInterviewHelpers'),...
fullfile(pwd, 'NewStimServices' , 'StimScreen'),...
fullfile(pwd, 'NewStimServices' , 'MonitorScreen'),...
fullfile(pwd, 'NewStimServices' , 'GammaCorrectionTable'),...
fullfile(pwd, 'NewStimServices' , 'StimTrigger'),...
fullfile(pwd, 'NewStimServices' , 'FitzTrig'),...
fullfile(pwd, 'NewStimServices' , 'VHTrig'),...
fullfile(pwd, 'NewStimServices' , 'GaiaTrig'),...
fullfile(pwd, 'NewStimServices' , 'StimSerial'),...
fullfile(pwd, 'NewStimServices' , 'StimPCIDIO96'),...
fullfile(pwd, 'NewStimServices' , 'StimScreenBlender'),...
fullfile(pwd, 'NewStimEditor'),...
fullfile(pwd, 'RemoteCommunication'),...
fullfile(pwd, 'Stimuli'),...
fullfile(pwd, 'Stimuli' , 'Display objs'),...
fullfile(pwd, 'Stimuli' , 'CustomProcs'),...
fullfile(pwd, 'NewStimTestProcs'),...
fullfile(pwd, 'ReceptiveFieldMapper')); 


%eval(['NewStimGlobals;'])
NewStimGlobals;
NewStimStimList = {};
NewStimStimScriptList = {};

if exist('NewStimConfiguration','file')
    NewStimConfiguration;
	%eval(['NewStimConfiguration;']);
end

if isempty(which('NewStimConfiguration')) || ~VerifyNewStimConfiguration 
	vhlabtoolspath = fileparts(fileparts(pwd)); % 2 levels up
	copyfile([pwd 'NewStimUtilities' filesep 'NewStimConfiguration_analysiscomputer.m'],...
		[vhlabtoolspath filesep 'Configuration' filesep 'NewStimConfiguration.m']);
	warning(['No NewStimConfiguration.m file was detected;' ...
			' the program is now copying the default settings for a basic analysis computer. ' ...
			'If you need to use this computer to control stimulus computers, or if this itself ' ...
			'should be a stimulus computer, you will need to edit the file NewStimConfiguration.m ' ...
			'according to the instructions on the website.  If you want to use this computer for ' ...
			'analysis only, then no action is needed, you should be all set.']);
	zz = which('NewStimConfiguration'); % force it to look again
	eval('NewStimConfiguration;');
end

if exist('PsychtoolboxVersion','file')
    b = PsychtoolboxVersion;
    if isnumeric(b)
        NS_PTBv = b;
    else
        NS_PTBv = eval(b(1));
    end
else
    NS_PTBv = 0;
end

eval('NewStimObjectInit');

