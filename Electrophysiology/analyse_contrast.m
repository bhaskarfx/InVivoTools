function measures=analyse_contrast( inp , record)
%ANALYSE_CONTRAST analyses periodic stimulus ecdata
%
%  MEASURES=ANALYSE_CONTRAST( INP , RECORD)
%
%
% 2007 Alexander Heimel
%

disp('ANALYSE_CONTRAST: Deprecated. Routines should be transferred to ANALYSE_PS');

measures.usable=1;

%	inp.st=s;

switch record.stim_type
  case {'contrast_drifting','contrast_reversing'}
    paramname='contrast';
  otherwise
    paramname=record.stim_type;
end

inp.paramnames=paramname; % for periodic_curve
inp.paramname=paramname; % for tuning_curve

%where.figure=figure;where.rect=[0 0 1 1]; where.units='normalized';
%orient(where.figure,'landscape');
par=struct('res',0.01,'showrast',0,'interp',3,'drawspont',1,...
  'int_meth',0,'interval',[0 0]);
tc=tuning_curve(inp,par,[]);
out=getoutput(tc);
% out.curve contains per responses
% (1,:) parameter value
% (2,:) average firing rate
% (3,:) std firing rate
% (4,:) sem in firing rate (std/sqrt(trials))
cout=out.curve;
rast=getoutput(out.rast);
parset=unique(cout(1,:));
curve=nan*ones(4,length(parset));
for i=1:length(parset)
  ind=find(cout(1,:)==parset(i));
  curve(1,i)=parset(i);
  if 0 % take mean
    curve(2,i)=mean(cout(2,ind));
    curve(3,i)=mean(cout(3,ind));
    curve(4,i)=mean(cout(4,ind))/sqrt(length(ind));
  else % take best
    [curve(2,i),j]=max(cout(2,ind));
    curve(3,i)=cout(3,ind(j));
    curve(4,i)=cout(4,ind(j));   
  end


  % only use counts in first cycle
  tempst=getparameters(inp.st.stimscript);
  binsize=(rast.bins{1}(end)-rast.bins{1}(1))/(length(rast.bins{1})-1);
  
%  rastcount_max=zeros(1,length(rast.counts{1})-1);%length decreased because it can fluctuate with one
  rastcount_max=zeros(1,ceil(1/tempst.tFrequency/binsize));%length decreased because it can fluctuate with one
  for j=ind
	  rastcount_max=rastcount_max+rast.counts{j}(1:length(rastcount_max)); 
  end
  filterwidth=0.05/binsize; % 50 ms width = too broad for onset times!
  rastcount_max=spatialfilter(rastcount_max,filterwidth);
  [m,ind_max]=max(rastcount_max);
  measures.time_peak(i)=ind_max*binsize;

end



%	inp.paramnames={par};

%	pc=periodic_curve(inp,'default',where);

measures.curve = curve;
measures.rate_spont = out.spont(1);

[measures.rate_max ind_pref]=max(curve(2,:));
measures.preferred_stimulus=curve(1,ind_pref);

% STIMULUS SELECTIVITY
% at preferred contrast, calculate stimulus selectivity as
% best-worst/best+worst  (subtracted rate_spont)
ind=find(cout(1,:)==measures.preferred_stimulus);
best=max(cout(2,ind))-measures.rate_spont;
worst=min(cout(2,ind))-measures.rate_spont;
measures.selectivity= (best-worst)/(best+worst);

resp=curve(2,:)-measures.rate_spont;
[measures.nk_rm,measures.nk_b,measures.nk_n]=naka_rushton(curve(1,:),resp);

cn=(0:0.01:1);
r=measures.nk_rm* (cn.^measures.nk_n)./ ...
  (measures.nk_b^measures.nk_n+cn.^measures.nk_n) ; % without spont
ind=findclosest(r,0.5*max(r));
measures.c50=cn(ind);

if measures.c50<0.1
  measures.usable=0;
  disp('c50 below 10%');
end

if measures.nk_n<0.9
  measures.usable=0;
  disp('nk_n below 0.9');
end

% calculate adaptation
n_spikes_per_stim=zeros(1,length(inp.st.mti));
for i=1:length(inp.st.mti)
  n_spikes_per_stim(i)= ...
    length(get_data(inp.spikes,[inp.st.mti{i}.startStopTimes(2),inp.st.mti{i}.startStopTimes(3)]));
end
norm_n_spikes_per_stim=n_spikes_per_stim/mean(n_spikes_per_stim);
%figure;
%plot(n_spikes_per_stim);
pfit=polyfit((1:length(n_spikes_per_stim)),norm_n_spikes_per_stim,1);
% p(1) is fractional change in rate per presented stimulus;
measures.rate_change=pfit(1);

