function params = oiprocessparams(record)
%OIPROCESSPARAMS contains experiment dependent process parameters
%
% 2013, Alexander Heimel
%

if nargin<1
    record = [];
end
if isempty(record)
        record.mouse = '';
end

if length(record.mouse)>5
    experiment = record.mouse(1:5);
else 
    experiment = '';
end


params.wta_equalize_area = false; % default
switch experiment
    case '12.54'
        params.wta_equalize_area = true;
    otherwise
        switch record.stim_type
            case 'orientation'
                params.wta_equalize_area = true;
        end
end
        

params.spatial_filter_width = 3; % pixels
switch experiment
    case '13.61'
        params.spatial_filter_width = 5; % pixels use nan to turn off filter
end
