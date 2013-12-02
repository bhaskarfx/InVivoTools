function base=networkpathbase
%NETWORKPATHBASE return base of network data path
%
% BASE = NETWORKPATHBASE
%
%  LEVELTLAB dependent, returns path to levelt storage share 
%
% 2009, Alexander
%

if isunix
    switch computer
        case 'MACI64'
            base = '/Volumes/MVP/Common/InVivo';
        otherwise
            base = '/mnt/InVivo';
    end
else % assume windows
  base = 'Z:\InVivo';
  if ~exist(base,'dir')
      base = '\\vs01.herseninstituut.knaw.nl\MVP\Shared\InVivo';
  end
end

  