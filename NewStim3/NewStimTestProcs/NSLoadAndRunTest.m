function [MTI,MTI2]=NSLoadAndRunTest(stimclass,output)
if nargin<2
    output = usejava('jvm');
end


NewStimGlobals;
StimWindowGlobals;

if NS_PTBv==3
    currLut = Screen('ReadNormalizedGammaTable', StimWindowMonitor);
    mypriority = MaxPriority(StimWindowMonitor,'WaitBlanking','SetClut','GetSecs'); % PD
else
    mypriority = 1;
end;


if isa(stimclass,'stimscript')
    myscript = stimclass;
else
    if isa(stimclass,'stimulus')
       mystim = stimclass;
    else
        mystim = NSGetTestStim(stimclass);
    end
    if iscell(mystim)||isa(mystim,'stimulus')
        myscript = stimscript(0);
        if iscell(mystim)
            for i=1:length(mystim), myscript = append(myscript,mystim{i}); end;
        else
            myscript = append(myscript,mystim);
        end;
    else
        myscript = mystim;
    end;
end;

ShowStimScreen;
disp('Got past ShowStimScreen');
myscript = loadStimScript(myscript);
disp('Got past loading');
MTI = DisplayTiming(myscript);
disp('Got past DisplayTiming');
MTI2 = DisplayStimScript(myscript,MTI,mypriority,1);
myscript = unloadStimScript(myscript);
CloseStimScreen;
success = 1;

if NS_PTBv==3
    Screen('LoadNormalizedGammaTable', StimWindowMonitor, currLut); 
end

if success && output
    StimWindowGlobals;
    figure;
    plot(diff(MTI2{1}.frameTimes));
    hold on;
    plot(1:length(MTI2{1}.frameTimes)-1,ones(1,length(MTI2{1}.frameTimes)-1)*mean(diff(MTI2{1}.frameTimes))+1/StimWindowRefresh,'g--');
    plot(1:length(MTI2{1}.frameTimes)-1,ones(1,length(MTI2{1}.frameTimes)-1)*mean(diff(MTI2{1}.frameTimes))-1/StimWindowRefresh,'g--');
end
