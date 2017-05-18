function experimental_pc = is_experimental_pc( hostname )
%RETURNS WHETHER HOST IS EXPERIMENTAL_PC
%
% 2015, Alexander Heimel

if nargin<1 || isempty(hostname)
    hostname = host;
end


switch hostname
    case  {'nin380','nori001','daneel','antigua','wall-e','nin343','andrew','jander','helero2p','G2P'}
        experimental_pc = true;
    otherwise
        experimental_pc = false;
end
