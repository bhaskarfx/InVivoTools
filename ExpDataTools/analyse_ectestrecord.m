function record=analyse_ectestrecord(record,verbose)
%ANALYSE_ECTESTRECORD
%
%   RECORD=ANALYSE_ECTESTRECORD( RECORD, VERBOSE )
%
% 2007-2014, Alexander Heimel, Mehran Ahmadlou

if nargin<2
    verbose = [];
end

if isempty(verbose)
    verbose = true;
end

if strcmp(record.datatype,'ec')~=1
    warning('InVivoTools:datatypeNotImplemented',['datatype ' record.datatype ' is not implemented.']);
    return
end

if isempty(record.monitorpos)
    msg =['Monitor position is missing in record. mouse=' record.mouse ',date=' record.date ',test=' record.test];
    disp(['ANALYSE_ECTESTRECORD: ' msg]);
    errordlg(msg,'Analyse ectestrecord');
end

datapath=ecdatapath(record);
if ~exist(datapath,'dir')
    errordlg(['Folder ' datapath ' does not exist.']);
    disp(['ANALYSE_ECTESTRECORD: Folder ' datapath ' does not exist.'])
    return
end

% per date one cksdirstruct to conform to Nelsonlab practice
cksds=cksdirstruct(datapath);

processparams = ecprocessparams(record);

[recorded_channels,area] = get_recorded_channels( record );

channels2analyze = get_channels2analyze( record );

if isempty(channels2analyze)
    channels2analyze = recorded_channels;
end

WaveTime_Spikes = struct([]);
switch lower(record.setup)
    case 'antigua'
        EVENT.Mytank = datapath;
        EVENT.Myblock = record.test;
        EVENT = importtdt(EVENT);
        if ~isfield(EVENT,'strons')
            logmsg(['No triggers present in ' recordfilter(record)]);
            record.measures = [];
            return
        end
        if length(EVENT.strons.tril)>1
            errormsg(['More than one trigger in ' recordfilter(record) '. Taking last']);
            EVENT.strons.tril(1)=EVENT.strons.tril(end);
        end
        EVENT.Myevent = 'Snip';
        EVENT.type = 'snips';
        EVENT.Start = 0;
        
        if any(channels2analyze>EVENT.snips.Snip.channels)
            errormsg(['Did not record more than ' num2str(EVENT.snips.Snip.channels) ' channels.']);
            return
        end
        
        if isempty(channels2analyze)
            channels2analyze = 1:EVENT.snips.Snip.channels;
        end
        logmsg(['Analyzing channels: ' num2str(channels2analyze)]);
        total_length=EVENT.timerange(2)-EVENT.strons.tril(1);
        clear('WaveTime_Fpikes');
        if ~isunix
            for i=1:length(channels2analyze)
                WaveTime_fpikes.time=[];
                WaveTime_fpikes.data=[];
                for kk=1:ceil(total_length/60)
                    EVENT.Triallngth = min(60,total_length-60*(kk-1));
                    WaveTime_chspikes = ExsnipTDT(EVENT,EVENT.strons.tril(1)+60*(kk-1));
                    WaveTime_fpikes.time = [WaveTime_fpikes.time;WaveTime_chspikes(channels2analyze(i),1).time];
                    WaveTime_fpikes.data = [WaveTime_fpikes.data;WaveTime_chspikes(channels2analyze(i),1).data];
                end
                WaveTime_Fpikes(i,1) =  WaveTime_fpikes;
            end
        else % linux
            EVENT.CHAN = channels2analyze;
            WaveTime_Fpikes = ExsnipTDT(EVENT);
        end
        
%         if isempty(WaveTime_Fpikes)
%             return
%         end
        
        % spike sorting
        for ii=1:length(channels2analyze)
            logmsg(['Sorting channel ' num2str(channels2analyze(ii))]);
            clear kll
            if isempty(WaveTime_Fpikes(ii,1).time)
                continue
            end
            kll.sample_interval = 1/EVENT.snips.Snip.sampf;
            kll.data = WaveTime_Fpikes(ii,1).time;
            spikes = WaveTime_Fpikes(ii,1).data;
            kll = get_spike_features(spikes, kll );
            
            [wtime_sp,nclusters] = spike_sort_wpca(spikes,kll);
            for cluster = 1:nclusters
                wtime_sp(cluster).channel = channels2analyze(ii);
            end
            WaveTime_Spikes = [WaveTime_Spikes;wtime_sp]; %#ok<AGROW>
        end
        n_cells = length(WaveTime_Spikes);
        
        % load stimulus starttime
        stimsfile = getstimsfile( record );
        EVENT.strons.tril = EVENT.strons.tril * processparams.secondsmultiplier;
        
        
        intervals=[stimsfile.start ...
            stimsfile.MTI2{end}.frameTimes(end)+10];
        % shift time to fit with TTL and stimulustimes
        % disp('IMPORTSPIKE2: Taking first TTL for time synchronization');
        timeshift = stimsfile.start-EVENT.strons.tril(1);
        timeshift = timeshift+ processparams.trial_ttl_delay; % added on 24-1-2007 to account for delay in ttl
       
        
        
        cells = struct([]);
        cll.name = '';
        cll.intervals = intervals;
        cll.sample_interval = 1/EVENT.snips.Snip.sampf;
        cll.detector_params = [];
        cll.trial = record.test;
        cll.desc_long = fullfile(datapath,record.test);
        cll.desc_brief = record.test;
        channels_new_index = (0:1000)*10+1; % works for up to 1000 channels, and max 10 cells per channel
        for c = 1:n_cells
            if isempty(WaveTime_Spikes(c,1))
                continue
            end
            cll.channel = WaveTime_Spikes(c,1).channel;
            cll.index = channels_new_index(cll.channel); % used to identify cell
            channels_new_index(cll.channel) = channels_new_index(cll.channel) + 1;
            cll.name = sprintf('cell_%s_%.3d',...
                subst_specialchars(record.test),cll.index);
            cll.data = WaveTime_Spikes(c,1).time * processparams.secondsmultiplier + timeshift;
            spikes = WaveTime_Spikes(c,1).data;
            cll.wave = mean(spikes,1);
            cll.std = std(spikes,1);
            cll.snr = (max(cll.wave)-min(cll.wave))/mean(cll.std);
            cll = get_spike_features(spikes, cll );
            cells = [cells,cll]; %#ok<AGROW>
        end
        

    otherwise
        % import spike2 data into experiment file
        channels2analyze = 1;
        cells = importspike2([record.test filesep 'data.smr'],record.test,datapath,'Spikes','TTL',[],[],record.amplification);
end

n_spikes = 0;
for i=1:length(cells);
    n_spikes = n_spikes+ length(cells(i).data);
end


if isempty(cells)
    logmsg('Imported no cells.');
    return
else
    logmsg(['Imported ' num2str(length(cells)) ' cells with ' num2str(n_spikes ) ' spikes.']);
end


switch processparams.spike_sorting_routine
    case 'klustakwik'
        cells = sort_with_klustakwik(cells,record);
        logmsg('WORKING HERE');
    case 'sort_wpca'
        cells = sort_with_wpca(cells,record);
    otherwise
        % no sorting
end

if processparams.compare_with_klustakwik
    kkcells = sort_with_klustakwik(cells,record);
    if ~isempty(kkcells)
        cells = compare_spike_sortings( cells, kkcells);
    end
end

logmsg(['After sorting ' num2str(length(cells)) ' cells.']);

transfer2cksdirstruct(cells,datapath);

spikesfile = fullfile(ecdatapath(record),record.test, '_spikes.mat');

isi = [];
if exist(spikesfile,'file')
    old = load( spikesfile);
    if isfield(old,'isi')
        isi = old.isi;
    end
end

switch lower(record.setup)
    case 'antigua'   
        isi = get_spike_interval( cells, isi ); %#ok<NASGU>
    otherwise
        isi = get_spike_interval( cells, isi ); %#ok<NASGU>
end
save(spikesfile,'cells','isi');

ssts = getstimscripttimestruct(cksds,record.test);

if isfield(record,'stimscript') && isempty(record.stimscript)
    % fill in stimscript class
    stims = getstimsfile(record);
    if isempty(stims)
        return
    end
    record.stimscript = class(stims.saveScript(1));
end

measures=[];

%nr = getallnamerefs(cksds);
%for r=1:length(nr) % for all refs
%    g = getcells(cksds,nr(r));
    g = getcells(cksds);
    if isempty(g)
        return
    end
    loadstr = ['''' g{1} ''''];
    for i=2:length(g)
        loadstr = [loadstr ',''' g{i} '''']; %#ok<AGROW>
    end
    eval(['d = load(getexperimentfile(cksds),' loadstr ',''-mat'');']);
    
    if length(g)>10 % dont show more than 10 cells in the analysis
        logmsg('More than 10 cells, going into silence mode');
        verbose = 0;
    end
    
    for i=1:length(g) % for all cells
        switch record.stim_type
            case {'sg','sg_adaptation'}
                inp.stimtime = stimtimestruct(ssts,1); % only works for one repetition
        end
        
        inp.st=ssts;
        inp.spikes={};
        inp.cellnames = {};
        inp.spikes=d.(g{i});
        n_spikes=0;
        for k=1:length(ssts.mti)
            try
                n_spikes=n_spikes+length(get_data(inp.spikes,...
                    [ssts.mti{k}.startStopTimes(1),...
                    ssts.mti{k}.startStopTimes(end)]));
            catch
                n_spikes=n_spikes+length(get_data(inp.spikes,...
                    [ssts.mti{k}.startStopTimes(1),...
                    ssts.mti{k}.startStopTimes(end-1)]));
            end
        end
        inp.cellnames{1} = [g{i}];
        inp.title=[g{i}]; % only used in period_curve
        disp(['ANALYSE_ECTESTRECORD: Cell ' num2str(i) ' of ' num2str( length(g) ) ...
            ', ' g{i} ', ' num2str(n_spikes) ' spikes']);
        
        stim_type = record.stim_type;
        try
            stim = get(inp.st.stimscript);
            if ~isempty(stim)
                switch class(stim{1})
                    case 'stochasticgridstim'
                        stim_type = 'sg';
                end
            end
        end
        
        switch stim_type
            case {'sg','sg_adaptation'}
                cellmeasures = analyse_sg(inp,n_spikes,record);
            case {'hupe','border','lammemotion','lammetexture'}
                cellmeasures = analyse_ectest_by_typenumber(inp,record);
            otherwise
                cellmeasures = analyse_ps(inp,record,verbose);
        end
        
        cellmeasures.usable = 1;
        
        if ~isempty(find_record(record,['comment=*' num2str(i) ':axon*']))
            cellmeasures.usable=0;
        end
        
        if ~isempty(find_record(record,['comment=*' num2str(i) ':bad*']))
            cellmeasures.usable=0;
        end
        
        if isempty(measures) % may not be correct! check importspike2
            cellmeasures.type='mu';
        else
            cellmeasures.type='su';
        end
        
        try % compute Reponse Index
            cellmeasures.ri= (cellmeasures.rate_peak-cellmeasures.rate_spont) /...
                cellmeasures.rate_peak;
        end
        
        try % compute selectivity index
            for t = 1:length(cellmeasures.rate)
                cellmeasures.selectivity_index{t} = ...
                    (max(cellmeasures.rate{t})-min(cellmeasures.rate{t})) / ...
                    max(cellmeasures.rate{t});
            end % t
        end
        
        try
            % compute signal to noise ratio (don't confuse with cell quality snr)
            cellmeasures.response_snr= (cellmeasures.rate_peak-cellmeasures.rate_spont) /...
                cellmeasures.rate_spont;
        end
        
        try
            % compute Prolonged Discharge Index
            cellmeasures.pdi=thresholdlinear( ...
                (cellmeasures.rate_late-cellmeasures.rate_spont) /...
                (cellmeasures.rate_early-cellmeasures.rate_spont));
        end
        
        cellmeasures.index = cells(i).index;
        if isfield(cells,'wave')
            cellmeasures.wave = cells(i).wave;
            cellmeasures.std = cells(i).std;
            cellmeasures.snr = cells(i).snr;
        else
            cellmeasures.wave = [];
            cellmeasures.std = [];
            cellmeasures.snr = NaN;
        end
        cellmeasures.sample_interval = cells(i).sample_interval;
        if isfield(cells,'p_multiunit')
            cellmeasures.p_multiunit = cells(i).p_multiunit;
        end
        if isfield(cells,'p_subunit')
            cellmeasures.p_subunit = cells(i).p_subunit;
        end
        
        flds = fields(cells);
        spike_flds = {flds{strmatch('spike_',flds)}};
        for field = spike_flds
            cellmeasures.(field{1}) = median( cells(i).(field{1}));
        end
        
        if ~all(isnan(cellmeasures.wave)) || isempty(cellmeasures.wave)
            cellmeasures.contains_data = true;
        else
            cellmeasures.contains_data = false;
        end
        if ~cellmeasures.contains_data
            cellmeasures.usable = 0;
        end
        
        cellmeasures.depth = record.depth-record.surface;
        
        if isfield(cells,'channel') % then check area
            cellmeasures.channel = cells(i).channel;
            if ~isempty(area)
                for a=1:length(area)
                    if ismember(cellmeasures.channel,area(a).channels)
                        cellmeasures.area = area(a).name;
                    end
                end
            end
        end
        
        measures = [measures cellmeasures];
    end % cell i
    
    if exist('fcm','file')
        cluster_spikes = true;
    else
        cluster_spikes = false;
        disp('ANALYSE_ECTESTRECORD: No fuzzy toolbox present for spike clustering');
    end
        
    if cluster_spikes            % compute cluster overlap
        for c = channels2analyze % do this per channel
            ind = find([measures.channel]==c);
            n_cells = length(measures(ind));
            clust=zeros(n_cells);
            spike_features = cell(n_cells,1);
            for i=1:n_cells
                for field = spike_flds
                    spike_features{i} = [ spike_features{i};cells(ind(i)).(field{1})'];
                end
            end
            max_spikes = 200;
            cluster_features = [ 1 2 3 ]; % 5 ruins it
            for i=2:n_cells
                if isempty(spike_features{i})
                    continue
                end
                n_spikesi = min(max_spikes,size(spike_features{i},2));
                for j=1:i-1
                    if isempty(spike_features{j})
                        continue
                    end
                    n_spikesj = min(max_spikes,size(spike_features{j},2));
                    features = [spike_features{i}(cluster_features,1:n_spikesi),spike_features{j}(cluster_features,1:n_spikesj)]';
                    orglabel = [ones(1,n_spikesi),zeros(1,n_spikesj)];
                    [dummy,Ulabel] =fcm(features,2,[2 50 1e-4 0]); %#ok<ASGLU>
                    newlabel = double(Ulabel(1,:)>0.5);
                    clust(i,j) = 2 * (sum(orglabel~=newlabel)/(n_spikesi+n_spikesj));
                    if clust(i,j)>1
                        clust(i,j)=2-clust(i,j);
                    end
                end
            end
            clust = clust + clust' + eye(length(clust));
            for i=1:n_cells
                measures(ind(i)).clust = clust(i,:); %#ok<AGROW>
            end
        end % channel c
    end % if cluster_spikes
%end % reference r


measuresfile = fullfile(ecdatapath(record),record.test,['_measures',num2str(channels2analyze),'.mat']);
save(measuresfile,'measures','WaveTime_Spikes');

% insert measures into record.measures
if (length(channels2analyze)==length(recorded_channels) && all( sort(channels2analyze)==sort(recorded_channels)))...
        || ~isfield(measures,'channel')|| ~isfield(record.measures,'channel')
    record.measures = measures;
else
    try
        record.measures(ismember([record.measures.channel],channels2analyze)) = []; % remove old
        record.measures = [record.measures measures];
        [dummy,ind] = sort([record.measures.index]); %#ok<ASGLU>
        record.measures = record.measures(ind);
    catch me % in case measures struct definition has changed
        logmsg(me.message);
        record.measures = measures;
    end
    
end

record = add_distance2preferred_stimulus( record );

record.analysed = datestr(now);

return


function [recorded_channels,area] = get_recorded_channels( record )
recorded_channels = [];
area = [];
if isfield(record,'channel_info') && ~isempty(record.channel_info)
    channel_info = split(record.channel_info);
    if length(channel_info)==1
        recorded_channels = sort(str2num(channel_info{1})); %#ok<ST2NM>
    else
        for i=1:2:length(channel_info)
            area( (i+1)/2 ).channels = sort(str2num(channel_info{i})); %#ok<ST2NM,AGROW>
            area( (i+1)/2 ).name = lower(channel_info{i+1}); %#ok<AGROW>
            if ~isempty(intersect(recorded_channels,area( (i+1)/2 ).channels))
                errormsg('There is a channel assigned to two areas');
                return
            end
            recorded_channels = [recorded_channels area( (i+1)/2 ).channels]; %#ok<AGROW>
        end
        recorded_channels = sort( recorded_channels );
    end
end
