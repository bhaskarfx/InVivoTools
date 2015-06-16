function cells = sort_with_klustakwik(orgcells,record)
%SORT_WITH_KLUSTAKWIK
%
%   SORT_WITH_KLUSTAKWIK 
%
% 2013, Alexander Heimel
%

params = ecprocessparams(record);

cells = [];

if isunix
    kkexecutable = 'KlustaKwik';
else
    kkexecutable = which('KlustaKwik.exe');
end

[status,res] = system(kkexecutable);

if status~=1
    if isunix
        kkexecutable = 'MaskedKlustaKwik';
    else
        kkexecutable = which('MaskedKlustaKwik.exe');
    end
    [status,res] = system(kkexecutable);
end

if status~=1
    logmsg('KlustaKwik not present');
    return
end

if ~params.sort_always_resort
    cells = import_klustakwik(record,orgcells);
end

if isempty(cells) %|| 1
    channels = unique([orgcells.channel]);

    if params.sort_always_resort
        for ch = channels
            filenamef = fullfile(experimentpath(record,true),[ 'klustakwik.*.' num2str(ch)]);
            delete(filenamef);
        end
    end
    
    write_spike_features_for_klustakwik( orgcells, record,channels );
    savepwd = pwd;
    cd(experimentpath(record));
    arguments = [ ...
         ' -ElecNo 1' ...
         ' -nStarts 1' ...
        ' -MinClusters 1' ...   % 20
        ' -MaxClusters ' num2str(params.max_spike_clusters) ...   % 30
         ' -MaxPossibleClusters ' num2str(params.max_spike_clusters) ...  % 100
         ' -UseDistributional 0' ... 
         ' -PriorPoint 1'...
         ' -FullStepEvery 20'... %
         ' -UseFeatures  1010100' ... %10101  %10111 11111
         ' -SplitEvery 40' ...
         ' -RandomSeed 1' ...
         ' -MaxIter 500' ...  % 500  
        ' -DistThresh 6.9' ...   % 6.9
        ' -ChangedThresh 0.05' ... % 0.05
        ' -PenaltyK 0'... % 0 
        ' -PenaltyKLogN 1' ]; % 1

%             ' -UseMaskedInitialConditions 1'...  % 1
%         ' -AssignToFirstClosestMask 1'... 

    for ch=channels
        cmd = [kkexecutable ' klustakwik ' num2str(ch) ' ' arguments];
        logmsg(cmd);
        [status,result] = system(cmd);
        if status == 1
            errormsg(result(max(1,end-100):end),true);
        else
            logmsg(result(max(1,end-100):end));
        end
    end
    cd(savepwd);
    cells = import_klustakwik(record,orgcells);
end

