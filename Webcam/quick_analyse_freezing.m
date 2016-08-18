clear all
experiment(14.13)
host('tinyhat')

if ~exist('db_org','var') || isempty(db_org)
    db_org = load_testdb('wc');
end

% examples to select records
% ind = find_record(db,'mouse=14.13.1.02');
% ind = find_record(db,'mouse=14.13.1.02,date=2016-05-02');
% ind = find_record(db,'mouse=14.13.1.02,date>2016-05-01');
% ind = find_record(db,'(mouse=14.13.1.02|mouse=14.13.1.03),date>2016-05-01');
% db = db(ind)
%
% mousedb = load_mousedb
% mice = mousedb(find_record(mousedb,'mouse=14.13.*'))

% for m = 1:length(mice) % loop of mouse
%     mouse = mice(m);
%     ind = find_record(db,'mouse=' mouse.mouse);
%     db = db(ind);
% end

mice = {...
    '14.13.1.08',...
    '14.13.1.09',...
    '14.13.1.10',...
    '14.13.1.11',...
    'unspecified-2',...
    'unspecified-3',...
    '14.14.1.39',...
    '14.14.2.04,date>2015-09-17',...
    '14.14.2.03,date>2015-09-14',...
%         '14.13.1.06,date>2015-09-21',...
%         '14.13.1.07,date>2015-09-21',...
%         '14.14.1.38',...
%         '14.14.1.37',...
        };

% mice = [mice(1:4) mice(8:9)];
% mice(12:13)];

n_mice = length(mice);

fracfreezing = NaN(n_mice,5,1);
fracfreezing_manual = NaN(n_mice,5,1);

for m=1:n_mice
    db = db_org(find_record(db_org,['mouse='  mice{m} ',(stim_type=*hawk*|stim_type=*full*|stim_type=*adv*)']));
    
    dates = unique({db.date});
    n_dates = length(dates);
    %     disp(['Found ' num2str(length(db)) ' records of ' num2str(n_dates) ' days']);
    
    fs = [];
    ft = [];
    froze = NaN(length(db),1);
    freezing_comment = NaN(length(db),1);
    freezing = NaN(length(db),1);
    freezing_computed = NaN(length(db),1);
    day = NaN(length(db),1);
    stimtype = NaN(length(db),1);
    freezing_time = NaN(length(db),1);
    freeze_duration = NaN(length(db),1);
    duration = [];
    pos_theta = NaN(length(db),1);
    head_theta = NaN(length(db),1);
    r = 1;
    recs = {};
    if ~isempty(strfind(db(1).stim_type,'hawk'))
        hawkstim = 1;
        discstim = 2;
    else
        hawkstim = 2;
        discstim = 1;
    end
    
    for s = 1:2
        switch s
            case  hawkstim
                dbs = db(find_record(db,'stim_type=*hawk*'));
            case discstim
                dbs = db(find_record(db, 'stim_type!*hawk*'));
        end
        
        for d = 1:n_dates
            dbday = dbs(find_record(dbs,['date=' dates{d}]));
            
            for i=1:length(dbday)
                measures = dbday(i).measures;
                
                if isempty(measures) || ~isfield(measures,'freezetimes') || ~isfield(measures,'stimstart')
                    continue
                end
                
                if isempty(measures.freezetimes)
                    froze(r) = false;
                else
                    cfs =  measures.freezetimes(:,1) - measures.stimstart;
                    cft = measures.freezetimes(:,2) - measures.freezetimes(:,1);
                    froze(r) = any(cfs>=-0.5 & cfs<4 & (measures.freeze_duration)'>=0.6);
                    freeze_index = find(cfs>=-0.5 & cfs<4 & (measures.freeze_duration)'>=0.6);
                end
                
                if froze(r) == 1
                    if length(freeze_index)>1
                        for k = 1:length(freeze_index)
                            if isempty(measures.pos_theta) || any(isnan(measures.pos_theta))
                                continue
                            elseif sum(~isnan(measures.pos_theta))>1
                                pos_theta(r)= measures.pos_theta(min(find(~isnan(measures.pos_theta))));
                                head_theta(r) = measures.head_theta(min(find(~isnan(measures.pos_theta))));
                                freeze_duration(r) = freeze_duration(min(find(~isnan(measures.pos_theta))));
                            else
                                freeze_duration(r) = measures.freeze_duration(freeze_index(k));
                                pos_theta(r) = measures.pos_theta(freeze_index(k));
                                head_theta(r) = measures.head_theta(freeze_index(k));
                            end
                        end
                    else
                        freeze_duration(r) = measures.freeze_duration(freeze_index);
                        head_theta(r) = measures.head_theta(freeze_index);
                        pos_theta(r) = measures.pos_theta(freeze_index);
                        
                    end
                else
                    freeze_duration(r) = NaN;
                    head_theta(r) = NaN;
                    pos_theta(r) = NaN;
                end
                comment = dbday(i).comment;
                if isempty(comment)
                    continue
                end
                p = strfind(comment,'frz');
                freezing_comment(r) = ~isempty(p);
                
                %                 if freezing_comment(r)~=froze(r)
                %                     disp(['Disagree on freezing for ' recordfilter(dbday(i)) ' Comment: ' dbday(i).comment]);
                %                 end
                
                if ~isempty(freezing_comment(r)) && freezing_comment(r)~= 0
                    
                    frz = comment(p-3:p+2);
                    if strcmp(frz,'detfrz')
                        freezing_time(r) = 1;
                    else
                        freezing_time(r) = str2num(frz(1:3));
                    end
                    %                     disp([frz ': ' num2str(freezing_time(r))]);
                end
                
                
                freezing(r) = measures.freezing;
                freezing_computed(r) = measures.freezing_computed;
                day(r) = d;
                stimtype(r) = s;
                recs{r} = recordfilter(dbday(i));
                
                fs = [fs; cfs];
                ft = [ft; cft];
                
                r = r+1;
            end
            
        end
    end
    
    %     ind = ~isnan(day);
    %     day = day(ind);
    %     froze = froze(ind);
    %     freezing = freezing(ind);
    %     freezing = freezing(ind);
    %     stimtype = stimtype(ind);
    %     disp(['Froze: ' num2str(sum(froze)/length(froze))]);
    %     disp(['Freezing: ' num2str(sum(freezing)/length(freezing))]);
    %     disp(['Freezing_computed : ' num2str(sum(freezing_computed)/length(freezing_computed))]);
    
    for d=1:5
        for s=1:2
            fracfreezing(m,d,s) = nanmean(froze(day==d & stimtype ==s));
            fracfreezing_manual(m,d,s) = nanmean(freezing_comment(day==d & stimtype ==s));
        end
    end
    
    % recs(froze==1 & day ==2 & freezing_comment==0 & stimtype==1)'
    % recs(froze==1 & day ==2 & freezing_comment==0 & stimtype==2)'
    % recs(froze==1 & day ==1 & freezing_comment==0 & stimtype==1)'
    % recs(froze==0 & day ==2 & freezing_comment==1 & stimtype==1)'
    % recs(froze==0 & day ==2 & freezing_comment==1 & stimtype==2)'
    % recs(froze==0 & day ==1 & freezing_comment==1 & stimtype==1)'
    
end

% for m = 1:n_mice
%     if any(~isnan(flatten(fracfreezing(m,:,:)))) || any(~isnan(flatten(fracfreezing_manual(m,:,:))))
%         disp(['mouse = ' mice{m}])
%     end
%     for d = 1:5
%         for s = 1:2
%             if ~isnan(fracfreezing(m,d,s)) || ~isnan(fracfreezing_manual(m,d,s))
%                 disp(['day = ' num2str(d) ', stimtype = ' num2str(s) ...
%                     ', fracfreezing = ' num2str(fracfreezing(m,d,s)) ...
%                     ', fracfreezing_manual = ' num2str(fracfreezing_manual(m,d,s))]);
%             end
%         end
%     end
% end

frzsd1_indiv = fracfreezing(:,(1:2),1);
frzsd2_indiv = fracfreezing(:,2,2);
allfrzs_indiv = [frzsd1_indiv frzsd2_indiv];
allfrzs_av = mean(allfrzs_indiv)
allfrzs_std = std(allfrzs_indiv);
allfrzs_sem = allfrzs_std/sqrt(n_mice);

frzsmand1_indiv = fracfreezing_manual(:,(1:2),1);
frzsmand2_indiv = fracfreezing_manual(:,2,2);
allfrzsman_indiv = [frzsmand1_indiv frzsmand2_indiv];
allfrzsman_av = mean(allfrzsman_indiv)
allfrzsman_std = std(allfrzsman_indiv);
allfrzsman_sem = allfrzsman_std/sqrt(n_mice);

freeze_duration_av = [nanmean(freeze_duration(day==1 & stimtype==1)),...
    nanmean(freeze_duration(day==2 & stimtype==1)), nanmean(freeze_duration(day==2 & stimtype==1))]
% freeze_duration_std = std([(freeze_duration(day==1 & stimtype==1)),...
%     (freeze_duration(day==2 & stimtype==1)), (freeze_duration(day==2 & stimtype==1))])
% freeze_duration_sem = freeze_duration_std/sqrt(n_mice)

freezing_time_av = [nanmean(freezing_time(day==1 & stimtype==1)),...
    nanmean(freezing_time(day==2 & stimtype==1)), nanmean(freezing_time(day==2 & stimtype==1))]
% freezing_time_std = std([(freezing_time(day==1 & stimtype==1)),...
%     (freezing_time(day==2 & stimtype==1)), (freezing_time(day==2 & stimtype==1))])
% freezing_time_sem = freezing_time_std/sqrt(n_mice)

% figHandles = findall(0,'Type','figure');
% if isempty(figHandles)
%     fig_n = 0;
% else
%     fig_n = max(figHandles);
% end


% return

figure;
ax1 = subplot(1,2,1); bar(ax1, allfrzs_indiv);
title(ax1,'computer, individual mice');
set(ax1, 'xlim', [0 (n_mice)+1], 'ylim', [0 1]);
ax2 = subplot(1,2,2); bar(ax2, allfrzs_av);hold on;
errorbar(ax2, allfrzs_av, allfrzs_sem, '.', 'linewidth', 2, 'color', [0.3 0.3 0.3])
title(ax2,'computer, average');
set(ax2, 'XTickLabel', {'d1 s1' 'd2 s1' 'd2 s2'});
set(ax2, 'ylim', [0 1]);

figure;
ax3 = subplot(1,2,1); bar(ax3, allfrzsman_indiv);
title(ax3,'manual, individual mice');
set(ax3, 'xlim', [0 (n_mice)+1], 'ylim', [0 1]);
ax4 = subplot(1,2,2); bar(ax4, allfrzsman_av); hold on;
errorbar(ax4, allfrzsman_av, allfrzsman_sem, '.', 'linewidth', 2, 'color', [0.3 0.3 0.3])
title(ax4,'manual, average');
set(ax4, 'XTickLabel', {'d1 s1' 'd2 s1' 'd2 s2'});
set(ax4, 'ylim', [0 1]);
return
figure;
ax7 = subplot(1,2,1);
bar(freeze_duration_av);
% errorbar(freeze_duration_av, freeze_duration_sem, '.', 'linewidth', 2, 'color', [0.3 0.3 0.3])
title('mean computer freezing durations');
set(ax7, 'XTickLabel', {'d1 s1' 'd2 s1' 'd2 s2'});
set(ax7, 'ylim', [0 2]);
ylabel(ax7, 'sec');
ax8 = subplot(1,2,2);
bar(freezing_time_av);
% errorbar(freezing_time_av, freezing_time_sem, '.', 'linewidth', 2, 'color', [0.3 0.3 0.3])
title('mean manual freezing durations');
set(ax8, 'XTickLabel', {'d1 s1' 'd2 s1' 'd2 s2'});
set(ax8, 'ylim', [0 2]);
ylabel(ax8, 'sec');

figure;
bar([(freeze_duration(day==1 & stimtype==1)),freezing_time(day==1 & stimtype==1)]);
legend('computer', 'manual'); title('all freezing durations d1 s1');
figure;
bar([(freeze_duration(day==2 & stimtype==1)), (freezing_time(day==2 & stimtype==1))]);
legend('computer', 'manual'); title('all freezing durations d2 s1');
figure;
bar([(freeze_duration(day==2 & stimtype==2)), (freezing_time(day==2 & stimtype==2))]);
legend('computer', 'manual'); title('all freezing durations d2 s2');

figure; title('freezing duration');
ax5 = subplot(1,2,1);
hist(ax5, freeze_duration, 10);
title(ax5, 'freezing duration, computer');
ax6 = subplot(1,2,2);
hist(ax6, freezing_time, 10);
title(ax6, 'freezing duration, manual');

bins = 15:30:335;

figure;
subplot(1,2,1);
hand1 = rose(head_theta, bins); title('head angle');
set(hand1, 'linewidth', 2);
ax9 = subplot(1,2,2);
hist(head_theta, 6);
set(ax9, 'xlim', [0 180])

figure;
subplot(1,2,1);
hand2 = rose(pos_theta, bins); title('position angle');
set(hand2, 'linewidth', 2);
ax10 = subplot(1,2,2);
hist(pos_theta, 6);
set(ax10, 'xlim', [-180 180])


if 0
    figure;plot(froze,'or');hold on;plot(freezing+0.1,'ob');plot(freezing_computed+0.2,'og');
    
    figure
    hist(fs,-12:0.1:10);
    
    figure;
    plot(fs,ft,'.');
    hold on;
    plot([0 0],[0 10],'y-')
    
    figure
    hist3([fs ft],[40 20])
    set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
    view([0 90])
    
end