function results_ectestrecord( record )
%RESULTS_ECTESTRECORD
%
%  RESULTS_ECTESTRECORD( record )
%
%  2007-2013, Alexander Heimel
%

global measures analysed_script

if isfield(record,'electrode') % i.e. ecdata
    data_type = 'ec';
elseif isfield(record,'laser') % i.e. tpdata
    data_type = 'tp';
else
    errordlg('Unknown test record type.','Results_ectestrecord');
    disp('RESULTS_ECTESTRECORD: Unknown test record type.');
    return
end

switch data_type
    case 'ec'
        params = ecprocessparams;
        tit=[record.test ', ' record.mouse ', ' record.date ', ' ...
            ' depth=' num2str(record.depth-record.surface) ' um, ' ...
            record.eye ', ' ...
            record.comment];
        rate_label = 'Rate (Hz)';
    case 'tp'
        params = tpprocessparams;
        tit=[record.epoch ', ' record.mouse ', ' record.date ', ' ...
            record.comment];
        rate_label = '\DeltaF/F';
end

tit(tit=='_')='-';

measures = record.measures;
measures_on_disk = [];
 
% add measures from measures file
switch record.datatype
    case 'tp'
        measuresfile = fullfile(tpdatapath(record),'tp_measures');
        if exist([measuresfile '.mat'],'file')
            load(measuresfile);
            measures_on_disk = measures;
        end
end
if ~isempty(measures_on_disk) && length(measures)==length(record.measures)
    f = fields(measures);
    f_on_disk = fields(measures_on_disk);
    sf = intersect(setdiff(f,f_on_disk),f_on_disk);
    for i = 1:length(measures)
        for f = 1:length(sf)
            measures(i).(sf{f}) = measures_on_disk(i).(sf{f});
        end
    end
end

% select on cells on channels of interest
channels = get_channels2analyze( record );
if ~isempty(channels) && isfield(measures,'channel')
    i = 1;
    while i<=length(measures)
        if ~ismember(measures(i).channel,channels)
            measures(i) = [];
        else
            i = i+1;
        end
    end
end

n_cells=length(measures);

subheight=150; % pixel
subwidth=200; % pixel
titleheight=40; %pixel

screensize = get(0,'ScreenSize');
screenheight = screensize(4)-screensize(2);

max_rows = floor((screenheight-titleheight)/subheight) ;
n_cols = 5;

width = n_cols*subwidth;
figleft = fix((screensize(3)-width)/2);
relsubwidth = 1 / n_cols;




row = 1;
for c=1:n_cells
    row = (mod(row-1,max_rows)+1);
    if row==1 % new figure
        if isfield(measures,'contains_data')
            n_cells_with_data = sum([measures(c:n_cells).contains_data]);
        else
            n_cells_with_data = n_cells-c+1;
        end
        if n_cells_with_data==0
            continue
        end
        max_rows = min(n_cells_with_data,max_rows);
        height = max_rows*subheight;
        
        figpos = [ fix( [figleft  (screensize(4)-height-titleheight)/2]) ...
            width height+titleheight];
        figure('Name',tit,'NumberTitle','off','units','pixels',...
            'Position',figpos,'MenuBar','none');
        
        reltitlepos = (max_rows*subheight)/(max_rows*subheight+titleheight);
        relsubheight = reltitlepos/max_rows;
        
        % title
        subplot('position',[0 reltitlepos 1 1-reltitlepos]);
        axis off
        text(0.5,0.5,tit,'HorizontalAlignment','center');
    end
    
    measure = measures(c);
    
    if isfield(measure,'contains_data') && ~measure.contains_data
        continue
    end
    
    subplot('position',...
        [ 0 reltitlepos-row*relsubheight relsubwidth relsubheight]);
    axis off
    if isfield(measure,'index')
        y = printtext(subst_ctlchars(['Index: ' num2str(measure.index)]),1);
    else
        y =  printtext(subst_ctlchars(['Number: ' num2str(c)]),1);
    end
    y = printfield(measure,'type',1,0.5);
    printfield(measure,'usable',y);
    y = printfield(measure,'SNR',y,0.5);
    y = printfield(measure,'responsive',y);
    if isfield(measure,'labels')
        y = printfield(measure,'labels',y);
    end
    
    switch record.stim_type
        case {'sg','sg_adaptation'}
            n_graphs=1+length(measure.rf)+1;
            printtext(subst_ctlchars(['rf_n_on: ' num2str(measure.rf_n_on) ]),y);
            y=printtext(subst_ctlchars(['halfmax: ' num2str(measure.halfmax_deg,2) '^o']),y,0.5);
            y=printtext(subst_ctlchars(['onsize : ' num2str(fix(measure.rf_onsize_sqdeg)) ' deg^2']),y);
            printtext(subst_ctlchars(['rate   : ' num2str(measure.rate_peak,2) ' Hz']),y);
            y=printtext(subst_ctlchars(['spont  : ' num2str(measure.rate_spont,2) ' Hz']),y,0.5);
            printtext(subst_ctlchars(['early  : ' num2str(measure.rate_early,2) ' Hz']),y);
            y=printtext(subst_ctlchars(['late   : ' num2str(measure.rate_late,2) ' Hz']),y,0.5);
            printtext(subst_ctlchars(['RI     : ' num2str(measure.ri,2) ]),y);
            y=printtext(subst_ctlchars(['PDI    : ' num2str(measure.pdi,2) ]),y,0.5);
            printtext(subst_ctlchars(['onset  : ' num2str(fix(measure.time_onset*1000)) ' ms']),y);
            y=printtext(subst_ctlchars(['peak   : ' num2str(fix(measure.time_peak*1000)) ' ms']),y,0.5);
            printtext(subst_ctlchars(['half life: ' num2str(measure.response_halflife*1000,'%2.f') ' ms' ]),y);
            y=printtext(subst_ctlchars(['roc auc: ' num2str(measure.roc_auc,2) ]),y,0.5);
            
            % rf graphs
            for i=1:length(measure.rf)-1
                subplot('position',...
                    [ (1+i)/(n_graphs)+0.01 reltitlepos-row*relsubheight 1/(n_graphs)*0.96 relsubheight]);
                plot_rf( measure,i );
            end
            i=i+1;
            subplot('position',...
                [ (1+i)/(n_graphs)+0.01 reltitlepos-row*relsubheight 1/(n_graphs)*0.96 relsubheight]);
            plot_waveform( measure,record,params.cell_colors(c) )
            
            % PSTH graph
            subplot('position',...
                [ (1.1)/(n_graphs) reltitlepos-(row-0.3)*relsubheight 1/(n_graphs)*0.8 relsubheight*0.7]);
            plot_psth(measure);
        case {'hupe','lammemotion','lammetexture'}
            color = 'bgrcmybgrcmy';
                
            y = printfield(measure,'lamme_modulation',y,0.5);
            y = printfield(measure,'hupe_modulation',y);
            y = printfield(measure,'start_stim_difference',y);
            y = printfield(measure,'duration',y);
            
            curves = measure.curve;
            psths = measure.psth;
            if ~iscell(curves)
                curves = {curves};
                psths = {psths};
            elseif length(curves)>1
                disp('RESULTS_ECTESTRECORD: Darker lines are without trigger.');
            end
            
            for i = 1:length(curves)
                curve = curves{i};
                psth = psths{i};
                
                n_types = size(curve,2);
                
                % tuning curve
                hs = subplot('position',...
                    [ 1/3+0.01 reltitlepos-(c-0.2)*relsubheight 1/3*0.96 relsubheight*0.8]);
                hold on
                for j=1:size(curve,2)
                    h = errorbar(curve(1,j)  -0.5 + i/(2*length(curves))   ,curve(2,j),curve(4,j),['.' color(j)]);
                    rgb = get(h,'color');
                    rgb = rgb / length(curves) * i;
                    set(h,'color',rgb);
                    h = bar(curve(1,j)  -0.5 + i/(2*length(curves))   ,curve(2,j) , 1/length(curves)*0.8);
                    set(h,'FaceColor',rgb);
                end
                
                % plot spontaneous rate
                h = plot( [0.5 n_types+0.5],[measure.rate_spont(i) measure.rate_spont(i)],'r--');
                rgb = get(h,'color');
                rgb = rgb / length(curves) * i;
                set(h,'color',rgb);
                set(gca,'XTick',1:n_types);
                ylabel('Rate (Hz)');
                xlim([0.25 n_types]);
                
                fgm_add_fig_captions(size(curve,2));
                
                % show psths
                if isfield(measure,'psth')
                    hs = subplot('position',...
                        [ 2/3+0.05 reltitlepos-(c-0.2)*relsubheight 1/3*0.96-0.05 relsubheight*0.8]);
                    hold on
                    for j=1:min(6,length(psth))
                        h = plot(figgnd_psth_smooth(psth(j).tbins),figgnd_psth_smooth(psth(j).data),color(j));
                        rgb = get(h,'color');
                        rgb = rgb / length(curves) * i;
                        set(h,'color',rgb);
                        set(h,'LineWidth',2);
                    end
                    ax = axis;
                    h=plot([0 0],[ax(3) ax(4)],'k--');
                    set(h,'Color',0.7*[1 1 1]);
                    ax(1) = max(-0.5,ax(1));
                    axis(ax);
                    ylabel('Rate (Hz)');
                    xlabel('Time (s)');
                end
            end %i
        otherwise
            if ~isfield(measure,'variable')
                errordlg('Analysis should be run first');
                disp('RESULTS_ECTESTRECORD: Unknown field ''variable''');
                return
            end
            
            y = printfield(measure,'preferred_stimulus',y);
            y = printfield(measure,'friedman_p',y);
            printfield(measure,'rate_max',y);
            y = printfield(measure,'rate_spont',y,0.5);
            y = printfield(measure,'time_peak',y);
            y = printfield(measure,'selectivity',y);
            y = printfield(measure,'selectivity_index',y);
            if isfield(measure,'rate_change')
                y = printtext(subst_ctlchars(['Drate  : ' num2str(measure.rate_change*100,'%2.0f') '%' ]),y);
            end
            y = printfield(measure,'response_max',y);
            
            
            switch measure.variable
                case {'angle', 'figdirection','gnddirection'}
                    y = printfield(measure,'orientation_index',y);
                    y = printfield(measure,'tuningwidth',y);
                    y = printfield(measure,'direction_index',y);
                case 'size' 
                    y = printfield(measure,'suppression_index',y);
                case 'contrast'
                    printfield(measure,'c50',y);
                    y = printfield(measure,'nk_rm',y,0.5);
                    printfield(measure,'nk_b',y);
                    y = printfield(measure,'nk_n',y,0.5);
                case 'position'
                    y = printfield(measure,'rf_center',y);
            end
            
            % tuning curve
            col = 2;
            subplot('position',...
                [relsubwidth*(col-1) reltitlepos-(row-0.2)*relsubheight relsubwidth*0.8 relsubheight*0.8]);
            plot_tuning_curve(measure,'-',rate_label);
            hold on
            
            if c==n_cells  && numel(measure.range{1})>1
                xlabel(capitalize(measure.variable));
            end

            switch measure.variable
                case {'angle', 'figdirection','gnddirection'}
                    col = 3;
                    subplot('position',...
                        [relsubwidth*(col-1) reltitlepos-(row-0.2)*relsubheight relsubwidth*0.8 relsubheight*0.8]);
                    plot_polar_curve(measure,'-');
                    hold on
                case 'position'
                    % overlap = str2double(answer{3})/100;
                    col = 3;
                    subplot('position',...
                        [relsubwidth*(col-1) reltitlepos-(row-0.2)*relsubheight relsubwidth*0.8 relsubheight*0.8]);
                    hold on;

                    plot_rf( measure , 1)
                    
%                     resp_by_pos = reshape(measure.curve(2,:),measure.n_x,measure.n_y)';
%                     resp_by_pos = resp_by_pos-min(resp_by_pos(:));
%                     %figure('Name',['Cell ' num2str(resps(i).index) ' RF'],'NumberTitle','off');
%                     imagesc(resp_by_pos);colormap gray;axis off
            end
            
            % psth
            col = 4;
            subplot('position',...
                [relsubwidth*(col-1) reltitlepos-(row-0.2)*relsubheight relsubwidth*0.8 relsubheight*0.8]);
            plot_psth( measure,record )
            
            % waveform
            col = 5;
            subplot('position',...
                [relsubwidth*(col-1) reltitlepos-(row-0.2)*relsubheight relsubwidth*0.8 relsubheight*0.8]);
            plot_waveform( measure,record,params.cell_colors(c) )
            set(gca,'YAxisLocation','right');
    end
    row = row+1;
end % cells c

if isfield(measures,'contains_data')
    n_cells_with_data = sum([measures.contains_data]);
else
    n_cells_with_data = n_cells;
end


% ODI
if isfield(record,'eye') && strcmp(record.eye,'ipsi') && isfield(measures,'odi')
    tit=[record.mouse ' ' record.date ' ' concat_testnames( record.measures(1).odi_tests ) ' ODI - depth=' num2str(record.depth-record.surface) ' um,' record.comment];
    tit(tit=='_')='-';
    
    max_rows = floor((screenheight-titleheight)/subheight) ;
    reltitlepos = (max_rows*subheight)/(max_rows*subheight+titleheight);
    relsubheight = reltitlepos/max_rows;
    row=1;
    
    %     figure('name',[ concat_testnames( record.measures(1).odi_tests ) ' ODI'],'numbertitle','off')
    for c=1:n_cells
        row = (mod(row-1,max_rows)+1);
        measure = measures(c);
        if isfield(measure,'contains_data') && ~measure.contains_data
            continue
        end
        if row==1 % new figure

            if isfield(measures,'contains_data')
                n_cells_with_data = sum([measures(c:n_cells).contains_data]);
            else
                n_cells_with_data = n_cells-c+1;
            end
            if n_cells_with_data==0
                continue
            end
            max_rows = min(n_cells_with_data,max_rows);
            height = max_rows*subheight;

            
                      
            figpos = [ fix( [figleft  (screensize(4)-height-titleheight)/2]) ...
                width height+titleheight];
            figure('Name',tit,'NumberTitle','off','units','pixels','Position',figpos);
            
            reltitlepos = (max_rows*subheight)/(max_rows*subheight+titleheight);
            relsubheight = reltitlepos/max_rows;
            
            % title
            subplot('position',[0 reltitlepos 1 1-reltitlepos]);
            axis off
            text(0.5,0.5,tit,'HorizontalAlignment','center');
        end
        
        
        subplot('position',...
            [ 0 reltitlepos-row*relsubheight 1/4 relsubheight]);
        axis off
        if isfield(measure,'index')
            y=printtext(subst_ctlchars(['Index: ' num2str(measure.index)]),1);
        else
            y=printtext(subst_ctlchars(['Number: ' num2str(c)]),1);
        end
        if isfield(measure,'odi_rate_spont') % deprecated on 2013-02-28
            y=printtext(subst_ctlchars(['Spont  : ' num2str([measure.odi_rate_spont{:}],2) ' Hz']),y);
            y=printtext(subst_ctlchars(['Rate_max  : ' num2str([measure.odi_rate_max{:}],2) ' Hz']),y,0);
            y=printtext(subst_ctlchars(['Response_max  : ' num2str([measure.odi_response_max{:}],2) ' Hz']),y,0);
        else
            y=printtext(subst_ctlchars(['Spont  : ' num2str([measure.rate_spont_binoc_mean{:}],2) ' Hz']));
            y=printtext(subst_ctlchars(['Rate_max  : ' num2str([measure.rate_max_binoc{:}],2) ' Hz']),y,0);
            y=printtext(subst_ctlchars(['Response_max  : ' num2str([measure.response_max_binoc{:}],2) ' Hz']),y,0);
            
        end
        
        % odi tuning curve
        subplot('position',...
            [ 0.32 reltitlepos-(row-0.2)*relsubheight 0.28 relsubheight*0.8]);
        plot_odi_tuning_curve(measure,'-');
        hold on
        row = row+1;
    end % c
end

% if 0
switch data_type
    case 'ec'
        spikesfile = fullfile(ecdatapath(record),record.test,'_spikes.mat');
        if exist(spikesfile,'file')
            cells = [];
            load(spikesfile);
            plot_spike_features(cells, record);
            if exist('isi','var')
                plot_spike_isi(isi,record);
            end
        end
end
% end



evalin('base','global measures');
evalin('base','global analysed_script');
analysed_stimulus = getstimsfile(record);
if ~isempty(analysed_stimulus) && isfield(analysed_stimulus,'saveScript')
    analysed_script = analysed_stimulus.saveScript; 
else
    disp('RESULTS_ECTESTRECORD: No savedscript');
end
disp('RESULTS_ECTESTRECORD: Measures available in workspace as ''measures'', stimulus as ''analysed_script''.');

return

function txt = concat_testnames( tests)
txt = [];
if isempty(tests)
    return
end
txt = tests{1};
for t=2:length(tests)
    txt = [txt ',' num2str(str2double(tests{t}(2:end)))];
end


%
function bordersquare( r,color )
if nargin<1
    color=[1 0 0];
end
hline=line( [r(1)-0.5 r(1)+0.5],[r(2)-0.5 r(2)-0.5]);
set(hline,'Color',color);
hline=line( [r(1)-0.5 r(1)+0.5],[r(2)+0.5 r(2)+0.5]);
set(hline,'Color',color);
hline=line( [r(1)-0.5 r(1)-0.5],[r(2)-0.5 r(2)+0.5]);
set(hline,'Color',color);
hline=line( [r(1)+0.5 r(1)+0.5],[r(2)-0.5 r(2)+0.5]);
set(hline,'Color',color);
return


%
function plot_psth(measure,record)
clr = 'kbry';
hold on;


last_timepoint = 2;
first_timepoint = -0.1;
if isfield(measure,'psth_tbins') && ~isempty(measure.psth_tbins) && ~isempty(measure.psth_tbins{1})
    for t=1:length(measure.psth_tbins) % over triggers
        if isfield(measure,'psth_count')
            bar(measure.psth_tbins{t},measure.psth_count{t},clr(t));
        else
            n_stimuli = length(measure.range{t});
            tbins = reshape(measure.psth_tbins{t},...
                numel(measure.psth_tbins{t})/length(measure.range{t}),n_stimuli);
            response = reshape(measure.psth_response{t},...
                numel(measure.psth_response{t})/length(measure.range{t}),n_stimuli);
            plot(tbins,response);
            first_timepoint = min(tbins(:));
        end
        if measure.psth_tbins{t}(end)>last_timepoint
            last_timepoint = measure.psth_tbins{t}(end);
        end
    end
elseif isfield(measure,'psth')
    bar(measure.psth.tbins,measure.psth.data);
    last_timepoint = measure.psth.tbins(end);
else
    axis off
    return
end

ax=axis;
ax([1 2])=[first_timepoint last_timepoint];
axis(ax);

% spont rate
if isfield(measure,'psth')
    h=line([ax(1) ax(2)],[measure.psth.spont measure.psth.spont]);
    set(h,'Color',[1 0 0]);
end

% onset threshold
if isfield(measure,'psth')
    h=line([ax(1) ax(2)],[measure.psth.onset_threshold measure.psth.onset_threshold]);
    set(h,'Color',[1 0 0]);
    set(h,'LineStyle',':')
end

% response onset time
if isfield(measure,'time_oneset') && ~isempty(measure.time_onset)
    h=line([measure.time_onset measure.time_onset],[ax(3) ax(4)]);
    set(h,'Color',[0 0 1]);
end

% response max time
if isfield(measure,'time_peak')
    if ~iscell(measure.time_peak)
        measure.time_peak = {measure.time_peak};
    end
    for t=1:length(measure.time_peak)
        plot([measure.time_peak{t} measure.time_peak{t}],[ax(3) ax(4)],[clr(t) ':']);
    end
end

% stimulus onset time
h=line([0 0],[ax(3) ax(4)]);
set(h,'Color',[1 1 0]);
return


function plot_rf( measure , i)
rf=measure.rf{i};
imagesc(rf); axis image
hold on
set(gca,'XTick',[]);
set(gca,'YTick',[]);
%colormap gray
%set(gca,'CLim',[256/35 max(20,max(measure.rf{1}(:)) )])
if max(measure.rf{1})>2 % i.e. luminance and not df/f
    colormap hot
    set(gca,'CLim',[256/35 40 ])
else % df/d 
    set(gca,'ydir','reverse');
    colormap gray
end
if iscell(measure.rf_center)
    rf_center = measure.rf_center{i};
else
    rf_center = measure.rf_center;
end
if isfield(measure,'rect')
    rf_center(1) = (rf_center(1) - measure.rect(1))/(measure.rect(3)-measure.rect(1)) * size(rf,2)+0.5;
    rf_center(2) = (rf_center(2) - measure.rect(2))/(measure.rect(4)-measure.rect(2)) * size(rf,1)+0.5;
end
if max(measure.rf{1})>2 % i.e. luminance and not df/f
bordersquare(rf_center,[0 1 0]);
else
    plot(rf_center(1),rf_center(2),'r*');
end
if isfield(measure,'rate_intervals')
    title([ num2str( fix(measure.rate_intervals{i}(1)*1000)) ' - '...
        num2str( fix(measure.rate_intervals{i}(2)*1000)) ' ms']);
end
return

function plot_odi_tuning_curve(measure,linestyle)
if nargin<2
    linestyle = '.';
end
if ~isfield(measure,'odi') || isempty(measure.odi)
    return
end

curves=measure.curve;
if ~iscell(curves)
    curves = {curves};
end
clr = 'kbry';

for i=1:length(curves) % over triggers
    if ~iscell(measure.range)
        range = measure.range; % deprecated
    else
        range = measure.range{i};
    end
    odi = measure.odi{i};
%     if strcmp(measure.variable,'angle') && length(range)>1
%         odi(end+1) = odi(1);
%         range(end+1) = range(1)+360; % complete circle
%     end
    
    [x,ind] = sort(range);
    y = odi(ind);
    
    plot(x,y,[ linestyle clr(i)]);
    hold on
    
    ax=axis;
    ylabel('ODI');
    ylim([-1.1 1.1]);
end
return


function plot_tuning_curve(measure,linestyle,rate_label)
if nargin<3
    rate_label = 'Rate';
end
if nargin<2
    linestyle = '.';
end
curves=measure.curve;
if ~iscell(curves)
    curves = {curves};
end
if ~iscell(measure.range)
    measure.range = {measure.range};
end
clr = 'kbry';
for i=1:length(curves) % over triggers
    curve = curves{i};
    
    if strcmp(measure.variable,'angle') && length(measure.range{1})>1
        curve(:,end+1) = curve(:,1); %#ok<AGROW>
        curve(1,end) =curve(1,end)+360; % complete circle

        if 0  % show orientation rather than direction
            new_curve(1,:) = curve(1,1:end/2);
            new_curve(2,:) = (curve(2,1:end/2) + curve(2,end/2+1:end))/2 ;
            new_curve(3,:) = (curve(3,1:end/2) + curve(3,end/2+1:end))/sqrt(2) ;
            new_curve(4,:) = (curve(4,1:end/2) + curve(4,end/2+1:end))/sqrt(2);
            curve = new_curve;
        end
    end
    
    
    switch measure.variable
        case {'typenumber','position'}
            x = 1:size(curve,2);
            bar(x,curve(2,:));
%            bar(x,curve(2,:),'barcolor',clr(i));
            box off
            set(gca,'XTick',1:size(curve,2));
            set(gca,'XTickLabel',curve(1,:));
        otherwise
            if size(curve,2)==1 
                x = curve(1,1)+(i-1)/length(curves);
                bar(x,curve(2,1),1/length(curves),clr(i));
                set(gca,'Xtick',[]);
                box off
            else
                x = curve(1,:);
                plot(curve(1,:),curve(2,:),[ linestyle clr(i)]);
            end
    end
        hold on
    errorbar(x,curve(2,:),curve(4,:),[clr(i) '.']);
    
    ylabel(rate_label);
    
    
    
    
end

for i=1:length(curves) % over triggers, separate to have axis right

    ax=axis;
    if isfield(measure,'rate_spont')
        plot([ax(1) ax(2)],[measure.rate_spont{i} measure.rate_spont{i}],[clr(i) '--']);
    end
end
yl = ylim;
if yl(2)>0
    ylim([0 yl(2)]);
end
switch measure.variable

    case 'contrast'
        xlim([-0.02 1]);
        set(gca,'XTick',[0 0.2 0.4 0.6 0.8 1]);
        set(gca,'XTickLabel',{'0','20','40','60','80','100'})
        hold on
        if isfield(measure,'nk_rm') % naka-rushton fit
            cn=(0:0.01:1);
            for t=1:length(curves) % over triggers
                r=measure.nk_rm{t}* (cn.^measure.nk_n{t})./ ...
                    (measure.nk_b{t}^measure.nk_n{t}+cn.^measure.nk_n{t}) + ...
                    measure.rate_spont{t};
                plot(cn,r,'k-');
            end
        end
    case 'angle' % polar plot
        if length(measure.range{1})>1
            xlim([0 365]);
            set(gca,'XTick',0:45:360);
        end
end

return


function plot_polar_curve(measure,linestyle)
if nargin<2
    linestyle = '.';
end
curves=measure.curve;
if ~iscell(curves)
    curves = {curves};
end

% run first to get maximum limit
clr = 'kbry';
m = 0;
for i=1:length(curves)
    curve = curves{i};
    m = max([m curve(2,:)]);
end

for i=1:length(curves)
    polar(0,m,'w');
    hold on
    curve = curves{i};
    polar([curve(1,:) curve(1,1)]/180*pi,thresholdlinear([curve(2,:) curve(2,1)]),[ linestyle clr(i)]);
    %phi =linspace(0,2*pi,100);
    %polar(phi,measure.rate_spont(i)*ones(size(phi)),[clr(i) '--']);
end
return


function plot_waveform( measure,record,clr)
if ~isfield(measure,'wave')
    axis off
    return
end

if nargin<3
    clr = 'k';
end
x=(0:length(measure.wave)-1);
xlab='Sample';
if isfield(measure,'sample_interval')
    x=measure.sample_interval*x*1000; % to make it ms
    xlab='Time (ms)';
end
if ~isempty(record.amplification)
    amplification=record.amplification;
    ylab='Potential (mV)';
else
    amplification=1;
    ylab='Potential (arbitrary)';
end
plot(x,measure.wave/amplification,['-' clr]);
hold on
plot(x,(measure.wave+measure.std)/amplification,['--' clr]);
plot(x,(measure.wave-measure.std)/amplification,['--' clr]);
xlabel(xlab);
ylabel(ylab);




function y = printfield(measure,field,y,x)
if nargin<4
    x = [];
end
if nargin<3
    y = [];
end
if isfield(measure,field)
    val = measure.(field);
    if iscell(val)
        val = [val{:}];
    end
    if islogical(val)
        val = double(val);
    end
    if  isnumeric(val)
        if any(val>10) && all(val<10000)
            val = mat2str(val,4);
        else
            val = mat2str(val,2);
        end
    end
    y = printtext(subst_ctlchars([capitalize(field) ' : ' val ]),y,x);
else
    y = printtext('',y,x);
end