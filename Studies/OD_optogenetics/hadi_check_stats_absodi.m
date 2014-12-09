function [data,x,g]=hadi_check_stats_absodi
% 
% tests for statistics, 2014-12-02
% Alexander Heimel

data = getdata;
groups={'pv ctl','pv gfp','pv 1 md','pv sh','pv 7 md'};

x = [];
g = [];
fun = @id; %@sqrt; %id;%@sqrt; %id;% @sqrt; %@log;

data = cellfun(fun,data,'UniformOutput',false);


data = {data{1},data{3},data{4},data{5}}
groups = {groups{1},groups{3},groups{4},groups{5}}
for i=1:length(data)
    x = [x;data{i}];
    g = [g;i*ones(size(data{i}))];
end
[p,anovatab,stats] = anova1(x,g);
disp(['ANOVA ' num2str(p)]);

[p,h,comp] = myanova(x,g)
disp(['ANOVA ' num2str(p)]);
[p,h,comp] = kruskalwallis(x,g)
disp(['Kruskal-Wallis' num2str(p)]);

for i=1:length(data)

   [h,p]=swtest(data{i});
   pbs=[];
   for j=1:100
       [hbs,pbs(j)]=swtest(bootstrp(100,@mean,data{i}));
   end
   disp(['Group ' groups{i} ': swtest p = ' num2str(p,2)...
       ', bootstrap mean swtest p=' ...
       num2str(mean(pbs),2)]);
end
for i=1:length(data)

   disp(['Group ' groups{i} ':  ' num2str(mean(data{i}),2) ' +/- ' num2str(std(data{i}),2) ' mean +/- std']);
end

p =vartestn(x,g);
disp(['Groups have equal variances: ' num2str(p,2)]);


welchanova([x g])

function x = id(x)


function x = getdata

x{1}=[0.16101
    0.010028
    0.195164
    0.026055
    0.306809
    0.209799
    0.001783
    0.147362
    0.044961
    0.079624
    0.001237
    0.065114
    0.020477
    0.182644
    0.021766
    0.541431
    0.3327
    0.210306
    0.252423
    0.36366
    0.012883
    0.060149
    0.017829
    0.334287
    0.169085
    0.435489
    0.05364
    0.223031
    0.226245
    0.263823
    0.089466
    0.004082
    0.143023
    0.175336
    0.013801
    0.130667
    0.015787
    0.026099
    0.071177
    0.064357
    0.093027
    0.547938];

x{2}=[0.0043
    0.0142771
    0.00516675
    0.0927177
    0.193978
    0.081857
    0.44625
    0.308282
    0.079677
    0.182002];

x{3}=[0.08125
    0.059381
    0.100402
    0.027908
    0.117182
    0.057265
    0.077738
    0.146279
    0.122884
    0.150503
    0.068021
    0.025044
    0.253664
    0.264665];

x{4}=[0.017772
    0.065522
    0.033519
    0.047754
    0.189194
    0.283105
    0.095358
    0.240788
    0.009918
    0.038851
    0.077756
    0.036922
    0.080831
    0.05301
    0.055085
    0.259507
    0.091409
    0.106979
    0.101652
    0.034509
    0.247628
    0.159876
    0.099961
    0.052165
    0.194173
    0.08807
    0.001825
    0.172219
    0.096405
    0.296354
    0.251627
    0.22517
    0.035511
    0.336011
    0.141192
    0.037865
    0.200037
    0.075994
    0.352135
    ];

x{5}=[0.296719
    0.009718
    0.084174
    0.303286
    0.086807
    0.07365
    0.019785
    0.256074
    0.367543
    0.009704
    0.272209
    0.019524
    0.325237
    0.045314
    0.20705
    0.619682
    0.031312
    0.035549
    0.833038
    0.08016
    0.290984
    0.240328
    0.545284
    0.413751
    0.154679
    0.223343
    0.098713
    0.140541
    0.170472
    0.684358
    0.608453
    0.799129
    0.19467
    0.152011
    0.08879
    0.171911
    0.279737
    0.298162
    0.026945
    0.096446
    0.354255
    0.0546
    ];
