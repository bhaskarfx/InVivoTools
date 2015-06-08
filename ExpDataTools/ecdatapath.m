function datapath=ecdatapath( record )
%ECDATAPATH constructs the datapath for ec-experiments
%
% DEPRECATED: Use EXPERIMENTPATH instead
%
% 2007-2015 Alexander Heimel
%

if nargin<1
	record.date = datestr(now,29);
    record.setup = host;
end

% first check locally
params.ecdatapath_localroot = fullfile(localpathbase,'Electrophys',capitalize(record.setup));

% check for local overrides
params = processparams_local(params);

if ~exist(params.ecdatapath_localroot,'dir')
    logmsg(['Folder ' params.ecdatapath_localroot ' does not exist.']);
    if exist(networkpathbase,'dir')
        params.ecdatapath_localroot = fullfile(networkpathbase,'Electrophys',capitalize(record.setup));
    end
end

datapath=fullfile(params.ecdatapath_localroot,record.date(1:4),record.date(6:7),record.date(9:10));
switch record.setup
    case 'antigua'
        datapath = fullfile(datapath,'Mouse');
end

if ~exist(datapath,'dir')
    if ispc
        switch record.setup
            case 'antigua'
                root = 'Z:\InVivo\';
            case 'nin380'
                root = 'V:\InVivo\';
        end
    else
        root = networkpathbase;
    end
    datapath=fullfile(root,'Electrophys',capitalize(record.setup),...
        record.date(1:4),record.date(6:7),record.date(9:10),'Mouse');
end