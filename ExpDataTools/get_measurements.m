function [results,dresults,measurelabel] = get_measurements( groups, measure, varargin )
%GET_MEASUREMENTS gets results for groups of mice for one or more measures
%
% [RESULTS,DRESULTS,MEASURELABELS] = GET_MEASUREMENTS( GROUPS, MEASURE,
% VARARGIN )
%
%    RESULTS has structure like RESULTS{ group }(measure)
%    RESULTS has structure like DRESULTS{ group }(measure) and contains
%       SEM in the individual measurements
%    MEASURELABEL is cell list of string
%
% 2007-2013, Alexander Heimel
%

persistent expdb_cache

results={};
dresults={};

pos_args={...
    'value_per','measurement',... % 'group','mouse','test','measurement', 'stack','neurite'
    'reliable',1,...  % 1 to only use reliable records (record.reliable!0), 0 to use all
    'testdb',[],...
    'mousedb',[],...
    'groupdb',[],...
    'measuredb',[],...
    'extra_options','',...
    };

if nargin<3
    disp('GET_MEASUREMENTS: Using default arguments:');
    disp(pos_args)
end

assign(pos_args{:});

%parse varargins
nvarargin=length(varargin);
if nvarargin>0
    if rem(nvarargin,2)==1
        disp('GET_MEASUREMENTS: Odd number of varguments');
        return
    end
    for i=1:2:nvarargin
        found_arg=0;
        for j=1:2:length(pos_args)
            if strcmp(varargin{i},pos_args{j})==1
                found_arg=1;
                if ~isempty(varargin{i+1}) % only assign if not-empty
                    assign(pos_args{j}, varargin{i+1});
                end
            end
        end
        if ~found_arg
            warning(['could not parse argument ' varargin{i}]);
            return
        end
    end
end

if isempty(mousedb)
    mousedb=load_mousedb;
end
if isempty(groupdb)
    groupdb=load_groupdb;
end
if isempty(measuredb)
    measuredb=load_measuredb;
end
if ischar(extra_options)
    extra_options=split(extra_options,',');
end
for i=1:2:length(extra_options)
    assign(extra_options{i},extra_options{i+1});
end

if ischar(measure)
    measuress=get_measures(measure,measuredb);
else
    measuress=measure;
end
if isempty(measuress)
    errordlg(['Could not find measure ' measure ],'GET_MEASUREMENTS');
    disp(['GET_MEASUREMENTS: Could not find measure ' measure ]);
    return
end

if ischar(groups)
    groupss=get_groups(groups,groupdb);
else
    groupss=groups;
end
n_groups=length(groups);

% complete filters
for g=1:n_groups
    groupss(g).filter=group2filter(groupss(g),groupdb);
end % g

linehead = 'GET_MEASUREMENTS: ';
switch measuress.datatype
    case {'oi','ec','lfp','tp','ls','fret','fp'}
        reload = false;
        if isempty(expdb_cache) || ...
                ~isfield(expdb_cache,measuress.datatype) || ...
                ~strcmp(expdatabases(measuress.datatype), expdb_cache.(measuress.datatype).type)
            reload = true;
        else
            d = dir(expdb_cache.(measuress.datatype).filename);
            if isempty(d) % probably concatenated database
                reload = false;
            elseif ~strcmp(d.date, expdb_cache.(measuress.datatype).date) % i.e. changed
                reload = true;
            end
        end
        if reload
            expdb_cache.(measuress.datatype).type = expdatabases(measuress.datatype) ;
            [expdb_cache.(measuress.datatype).db,expdb_cache.(measuress.datatype).filename] = ...
                load_testdb(expdb_cache.(measuress.datatype).type);
            d = dir(expdb_cache.(measuress.datatype).filename);
            expdb_cache.(measuress.datatype).date = d.date;
        else
            disp(['GET_MEASUREMENTS: Using cache of ' expdb_cache.(measuress.datatype).filename '. Type ''clear functions'' to clear cache.']);
        end
        
        testdb = expdb_cache.(measuress.datatype).db;
    otherwise
        testdb=[];
end

% exclude groups for which we have too few points
if exist('min_n','var')
    min_n=str2double(min_n);
else
    min_n=1;
end

for g=1:n_groups
    newlinehead=[linehead groupss(g).name ';'];
    [results{g},dresults{g}]=get_measurements_for_group( groupss(g),measuress,value_per,mousedb,testdb,reliable,extra_options,newlinehead);
    measurelabel=measuress.label;
    n=sum(~isnan(results{g})) ;
    if n<min_n
        results{g}=nan;
        disp(['GET_MEASUREMENTS: Fewer than ' num2str(min_n) ' datapoints.']);
    end
    switch value_per
        case 'group'
            results{g}=nanmean(results{g},ndims(results{g}));
            dresults{g}=norm(dresults{g}(~isnan(dresults{g})));
            if numel(results{g})==length(results{g})
                disp([newlinehead num2str(results{g},3)]);
            else
                disp([newlinehead ' array']);
            end
            
        otherwise
            disp([ 'GET_MEASUREMENTS: measure = ' measuress.measure ', group=' groupss(g).name ...
                ' : mean = ' num2str(nanmean(double(results{g}(:)))) ...
                ' , std = ' num2str(nanstd(double(results{g}(:)))) ...
                ' , sem = ' num2str(sem(double(results{g}(:)))) ...
                ' , N = ' num2str(min(n(:)))]);
    end
end % g (groups)

return


function [results, dresults]=get_measurements_for_group( group, measure, value_per, mousedb,testdb,reliable,extra_options,linehead)
results=[];
dresults=[];

if strcmp(trim(group.name),'empty')
    return
end
indmice=find_record(mousedb,group.filter);

disp(['GET_MEASUREMENTS: Group ' group.name ' contains ' num2str(length(indmice)) ' mice.']);

if isempty(indmice)
    return
end

for i_mouse=indmice
    mouse=mousedb(i_mouse);
    newlinehead=[linehead mouse.mouse ';'];
    [res,dres]=get_measurements_for_mouse( mouse, measure, value_per,mousedb,testdb,reliable,extra_options,newlinehead);
    
    switch value_per
        case 'mouse' %{'mouse','group'}
            res=nanmean(res,ndims(res));
            dres=norm(dres(~isnan(dres)));
            
            if numel(res)==length(res)
                disp([newlinehead measure.name '=' num2str(res,3)]);
            else
                disp([newlinehead measure.name '= array']);
            end
        case 'group'
            disp('GET_MEASUREMENTS: Changed behavior from group on 2013-04-27');
    end
    
    
    if ~isempty(res) && numel(res)==length(res)
        results=[results(:)' res(:)'];
        dresults=[dresults(:)' dres(:)'];
    elseif isempty(res)
        % do nothing
    elseif isempty(results)
        results = res;
        dresults = dres;
    else
        % ugly and not very general!
        xl = min(size(results,1),size(res,1));
        yl = min(size(results,2),size(res,2));
        zl = size(res,3);
        %         if ndims(results)==3 && ndims(res)==3 && any(sr(1:end-1)~=size(res))
        %             disp('GET_MEASUREMENTS: Result arrays are not all the same size');
        %         end
        results(1:xl,1:yl,end+1:(end+zl)) = res(1:xl,1:yl,1:zl);
        dresults(1:xl,1:yl,end+1:(end+zl)) = dres(1:xl,1:yl,1:zl);
    end
    
    %results=[results res];
    %dresults=[dresults dres];
end % i_mouse (mice)
return

%
function [results, dresults]=get_measurements_for_mouse( mouse, measure, value_per, mousedb,testdb,reliable,extra_options,linehead)
results=[];
dresults=[];

isolation='';
for i=1:2:length(extra_options)
    assign(extra_options{i},extra_options{i+1});
end

if strcmpi(measure.datatype,'genenetwork')
    results=get_genenetwork_probe(mouse.strain,measure.stim_type,measure.measure);
end

if isempty(measure.stim_type) || strcmp(measure.stim_type,'*')
    switch measure.measure
        case 'sex', % only once per mouse
            results=strcmp(mouse.sex,'male');
            return
        case 'weight'
            results = get_mouse_weight( mouse );
            return
        case 'bregma2lambda'
            if ~isempty(mouse.bregma2lambda)
                results = mouse.bregma2lambda(1);
            else
                results = [];
            end
            return
        case 'skullwidth'
            if ~isempty(mouse.bregma2lambda)
                results = mouse.bregma2lambda(2);
            else
                results = [];
            end
            return
    end
end


cond=[ 'mouse=' mouse.mouse  ];
cond=[cond ', datatype=' measure.datatype  ];
if ~isempty(measure.stim_type)
    cond=[cond ', stim_type=' measure.stim_type  ];
end
% 2013-05-28 moved reliable checking to within record, because it can be
% done for separate cells
% if isfield(testdb,'reliable') && reliable==1
%     cond=[cond ', reliable!0'];
% end
if isfield(testdb,'experimenter') && exist('experimenter','var')
    cond=[cond ', (experimenter=' experimenter ')' ];
end
if isfield(testdb,'comment') &&  exist('comment','var')
    comment=trim(comment);
    if comment(1)=='{'
        comment = split( comment(2:end-1));
    else
        comment = {comment};
    end
    for i=1:length(comment)
        cond=[cond ', comment=*' comment{i} '*'];
    end
end
if isfield(testdb,'comment') &&  exist('nocomment','var')
    nocomment=trim(nocomment);
    if nocomment(1)=='{'
        nocomment = split( nocomment(2:end-1));
    else
        nocomment = {nocomment};
    end
    for i=1:length(nocomment)
        cond=[cond ', comment!*' nocomment{i} '*'];
    end
end
if exist('test','var')
    cond=[cond ', test=*' test '*'];
end
if ~isempty(isolation)
    switch isolation
        case 'ok'
            cond=[cond ', (comment=*perfect*|comment=*good*|comment=*nice*|comment=*ok*)'];
        case 'good'
            cond=[cond ', (comment=*perfect*|comment=*good*)'];
        case 'nice'
            cond=[cond ', (comment=*perfect*|comment=*nice*|comment=*good*)'];
        case 'perfect'
            cond=[cond ', (comment=*perfect*)'];
    end
end
if exist('eyes','var') % eye is already used for matlab function
    cond=[cond ', eye=*' eyes '*'];
end

indtests=find_record(testdb,cond);
%    disp(['found ' num2str(length(indtests)) ' records']);
for i_test=indtests
    testrecord=testdb(i_test);
    if isfield(testrecord,'setup')
        setup = testrecord.setup;
    else
        setup = '';
    end
    newlinehead = linehead;
    if isfield(testrecord,'date')
        newlinehead = [newlinehead testrecord.date ';'];
    end
    newlinehead=[newlinehead setup ';'];
    if isfield(testrecord,'test')
        newlinehead = [newlinehead testrecord.test ';']; %#ok<AGROW>
    elseif isfield(testrecord,'epoch')
        newlinehead = [newlinehead testrecord.epoch ';' testrecord.stack ';' testrecord.slice ';']; %#ok<AGROW>
    end
    [res dres]=get_measurements_for_test( testrecord,mouse, measure,value_per,reliable,extra_options,newlinehead);

    
    
    switch value_per
        case {'test','stack'}
            if ~isempty(res)
                res=nanmean(res);
                dres=norm(dres(~isnan(dres)));
                disp([newlinehead measure.name '='  num2str(res,3)]);
            end
    end
    
    if ~isempty(res) && numel(res)==length(res) % i.e. 1D results
        results=[results(:)' res(:)'];
        dresults=[dresults(:)' dres(:)'];
    elseif isempty(res)
        % do nothing
    elseif isempty(results)
        results = res;
        dresults = dres;
    else
        % ugly and not very general!
        sr = size(results);
        try
            if any(sr(1:end-1)~=size(res))
                disp('GET_MEASUREMENTS: Result arrays are not all the same size');
            end
        catch
                disp('GET_MEASUREMENTS: Result arrays are not all the same size');
        end            
        xl = min(size(results,1),size(res,1));
        yl = min(size(results,2),size(res,2));
        
        results(1:xl,1:yl,end+1) = res(1:xl,1:yl);
        dresults(1:xl,1:yl,end+1) = dres(1:xl,1:yl);
    end
    if any(size(results)~=size(dresults))
        disp('GET_MEASUREMENTS: sizes of RESULTS and DRESULTS are not equal');
        %keyboard
    end
    
    
    % was:, changed on 2011-04-01
    %results=[results res];
    %dresults=[dresults dres];
end % test records



%
function [results, dresults]=get_measurements_for_test(testrecord, mouse, measure, value_per,reliable,extra_options,linehead)
results = [];
dresults = [];
celltype = '';


if reliable==1 && length(testrecord.reliable)==1 && testrecord.reliable==0
    return % no need to check individual cells
end

for i=1:2:length(extra_options)
    assign(extra_options{i},extra_options{i+1});
end

if exist('min_blocks','var')
    if ischar(min_blocks) %#ok<NODEF>
        min_blocks=eval(min_blocks);
    end
    if size(testrecord.response_all,1)<min_blocks
        disp(['Fewer than ' num2str(min_blocks) ' blocks.']);
        results=nan;
        return
    end
end

switch measure.datatype
    case 'ec'
        if ~isfield(testrecord,'datatype') || ~strcmp(measure.datatype,'ec')
            results = NaN;
            return
        end
    case 'lfp'
        if ~isfield(testrecord,'datatype') || ~strcmp(measure.datatype,'lfp')
            results = NaN;
            return
        end
        
end

switch measure.measure
    case 'weight'
        results = get_mouse_weight( mouse);
    case 'age'
        results = age(mouse.birthdate,testrecord.date);
        dresults = NaN;
    case 'expdate'  % day number since 1-1-0000
        results=datenum(testrecord.date,'yyyy-mm-dd') ;
        
    otherwise
        if strcmp(measure.measure(1:min(end,4)),'file')
            switch measure.datatype
                case 'tp'
                    saved_data_file = fullfile(tpdatapath(testrecord),'saved_data.mat');
                case {'ec','lfp'}
                    saved_data_file = fullfile(ecdatapath(testrecord),testrecord.test,'saved_data.mat');
            end
            if exist(saved_data_file,'file')
                saved_data = load(saved_data_file); %#ok<NASGU>
                try
                    eval(['results = saved_data.' measure.measure(6:end) ';']);
                    dresults = nan(size(results));
                    disp(['GET_MEASUREMENTS: Retrieved ' ...
                        measure.measure(6:end) ' from ' saved_data_file ...
                        '. Results is of size ' num2str(size(results)) ]);
                catch
                    %                    disp(['GET_MEASUREMENTS: Could not retrieve ' measure.measure(6:end) ' from ' saved_data_file ]);
                    
                end
                %             else
                %                 disp(['GET_MEASUREMENTS: ' saved_data_file ' does not exist.']);
            end
        else
            [results dresults]=get_measure_from_record(testrecord,measure.measure,celltype,reliable,extra_options);            
            results = double(results);
            dresults = double(dresults);
            if strcmpi(value_per,'neurite')
                linked2neurite = get_measure_from_record(testrecord,'linked2neurite',celltype,reliable,extra_options);
                if length(linked2neurite)~=length(results)
                    errormsg('Not an equal number of values and neurite numbers.');
                    return
                end
                uniqneurites =  uniq(sort(linked2neurite(~isnan(linked2neurite))));
                res = [];
                dres = [];
                for neurite = uniqneurites(:)'
                    res = [res nanmean(results(linked2neurite==neurite))];
                    dres = [dres nanstd(results(linked2neurite==neurite))];

                end
                results = res;
                dresults = dres;
            end
            if isempty(results) && ~strcmp(measure.measure,'depth')
                [results dresults]=get_valrecord(testrecord,measure.measure,mouse);
            end
        end
        if ~isempty(results)
            switch value_per
                case 'measurement'
                    if ndims(results)<3 && numel(results)<200
                        textres=mat2str(results',3);
                        if ~isempty(textres) && textres(1)=='['
                            textres=textres(2:end-1);
                        end
                    else
                        textres = [num2str(ndims(results)) 'd array'];
                    end
                    disp([linehead measure.name '=' textres]);
            end
        end
end
return


