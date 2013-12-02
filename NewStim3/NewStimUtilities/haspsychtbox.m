function b = haspsychtbox

% Part of the NewStim package
%
% B = HASPSYCHTBOX
%
%  Returns 1 if the Psychophysics toolbox is installed, and 0 otherwise.
%
%                             Questions to vanhoosr@brandeis.edu


NewStimGlobals;

b = NS_PTBv;

return;

 % should superceed what is below

b = 0;
cpustr = computer;
if strcmp(cpustr,'MAC2')&exist('screen')&exist('serial'), b = 1; end;
