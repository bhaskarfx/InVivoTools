function plot_spike_features( cells, record )
%PLOTS_SPIKE_FEATURES plot features obtained with get_spike_features
%
% 2013, Alexander Heimel
%

if nargin<2
    record.test = '';
    record.date = '';
end

params = ecprocessparams(record);

flds = fields(cells);
ind = strmatch('spike_',flds);
if isempty(ind)
    disp('PLOT_SPIKES_FEATURES: No features available');
    return
end

features = {flds{ind}};
n_features = length(ind);
n_cells = length(cells);
% plot clusters
figure('Name',['Spike clusters: ' record.test ',' record.date] ,'Numbertitle','off');
colors = params.cell_colors;
n_colors = length(colors);
for i=1:n_features
    lims(i,1) = prctile( vertcat(cells(:).(features{i})),3);
    lims(i,2) = prctile( vertcat(cells(:).(features{i})),97);
    ran = lims(i,2)-lims(i,1);
    lims(i,1) = lims(i,1) -0.2*ran;
    lims(i,2) = lims(i,2) +0.2*ran;
    
end

max_spikes = 200;

for i=1:n_features
    for j=i+1:n_features
        subplot(n_features-1,n_features-1,(n_features-i-1)*(n_features-1)+(n_features-j+1));
        hold on
        for cl=1:n_cells
            clr = colors( mod(cl-1,n_colors)+1);
            n_spikes = length(cells(cl).(features{j}));
            if n_spikes>max_spikes
                ind = round(linspace(1,n_spikes,max_spikes));
            else
                ind = 1:n_spikes;
            end
                
            plot(cells(cl).(features{j})(ind),...
                cells(cl).(features{i})(ind),[clr '.']);
            if ~isnan(lims(i,1)) % Mehran
                xlim( lims(j,:));
                ylim( lims(i,:));
            else
                xlim([-0.1 0.3]);
                ylim([-0.5 10]);
            end
            if i==1
                xlabel(capitalize(features{j}));
            else
                set(gca,'xtick',[]);
            end
            if j==n_features
                ylabel(capitalize(features{i}));
            else
                set(gca,'ytick',[]);
            end
            
        end % cl
    end % feature j
end % feature i

% show cell numbers
subplot(n_features-1,n_features-1,2);
axis off;
x=0;
for cl=1:n_cells
    clr = colors( mod(cl-1,n_colors)+1);
    [y,x,h]=printtext([' .' num2str(cl)] ,[],x);
    set(h,'color',clr);
end

subplot(n_features-1,n_features-1,n_features-1);
show_cluster_overlap( record)







function show_cluster_overlap( record)

params = ecprocessparams(record);

% cluster figure
axis off
report_overlap = params.cluster_overlap_threshold ;

measures = record.measures;

if ~isfield(measures,'clust')
    return
end

n_cells = length(measures);

suggest_resort = false;

y = printtext('Overlapping clusters:');
multiunits = [];
for c1=1:n_cells
    if ~measures(c1).contains_data
        continue
    end
    for c2=(c1+1):n_cells
        if ~measures(c2).contains_data
            continue
        end
        
        if measures(c1).clust(c2)>report_overlap
            multiunits = [multiunits c1 c2];
            
            suggest_resort = true;
            y=printtext([ num2str(c1) ' and ' num2str(c2) ],y);
        end
    end
end
multiunits = uniq(sort(multiunits));
singleunits = setdiff(find([measures.contains_data]),multiunits);

if ~isempty(singleunits)
    disp(['PLOT_SPIKE_FEATURES: Isolated single units: ' mat2str(singleunits)]);
else
    disp(['PLOT_SPIKE_FEATURES: No well isolated single units']);
end

if 0 && isfield(measures,'clust')
    fh = figure('Name',[record.test ': Cluster overlap'],...
        'numbertitle','off',...
        'Position',[100 100 500 500]);
    cnames = {};
    clust = zeros(n_cells,n_cells);
    for i=1:n_cells
        cnm = ['Cell ',num2str(i)];
        cnames = [cnames,cnm];
        clust(i,:) = measures(i).clust;
    end;
    th = uitable('Data',clust,'ColumnName',cnames,'RowName',cnames,...
        'Parent',fh,'Position',[50 50 400 400]);
end
    
if isfield(measures,'p_multiunit')
    for c=1:n_cells
        disp(['PLOT_SPIKE_FEATURES: ' num2str(measures(c).index,'%3d') ' P(multiunit) = ' num2str(measures(c).p_multiunit,2)]);
        disp(['PLOT_SPIKE_FEATURES: ' num2str(measures(c).index,'%3d') ' P(subunit)   = ' num2str(measures(c).p_subunit,2)]);
    end
end


if suggest_resort
    disp(['PLOT_SPIKE_FEATURES: Occasional cluster overlap larger than ' num2str(report_overlap) '. Consider resorting.']);
end