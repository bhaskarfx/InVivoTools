function record = analyse_wctestrecord( record, verbose )
%ANALYSE_WCTESTRECORD analyses webcam testrecord
%
%  RECORD = ANALYSE_WCTESTRECORD( RECORD, VERBOSE=true )
%
% 2015, Alexander Heimel
% 

if nargin<2
    verbose = [];
end
if isempty(verbose)
    verbose = true;
end

wcinfo = wc_getmovieinfo( record);

