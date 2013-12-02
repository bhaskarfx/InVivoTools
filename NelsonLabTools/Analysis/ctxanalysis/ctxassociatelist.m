function assoclist=ctxassociatelist(testname),

%  ctxassociatelist - list of associates for ctx data analysis
%
%  asclist = ctxassociatelist(testname), cell list

  switch(testname),
   case 'CentSize',
    assoclist = {'Center size','Center latency test',...
		 'Center transience test','Sustained/Transient response',...
		 'Center Initial Response','Center Maintained Response',...
		 'Cent Size spontaneous','Cent Size Params','Has surround'};
   case 'ConeTest',
    assoclist = {'Cone test spont rates','Cone test stim rates',...
		 'Cone test significant firing','Center Initial Response imp',...
		 'Center Maintained Response imp','Phasic-Tonic index',...
		 'Peak Latency','Peak firing rate',...
		 'Spike density'};
   case 'Phase Test',
    assoclist = {'Phase Early rate',...
		 'Phase Late rate',...
		 'Phase Transience',...
		 'Phase Sustained?',...
		 'Phase Adapt',...
		 'Phase Latency',...
		 'Phase Peak Latency',...
		 'Phase Linearity',...
		 'Phase Response curve',...
		 'Phase Spontaneous rate',...
		 'Phase Histogram'};
   case 'TF Test',
    assoclist = {'TF Response Curve F0',...
		 'TF Response Curve F1',...
		 'TF Max drifting grating firing',...
		 'TF F1/F0',...
		 'TF Pref',...
		 'TF Low',...
		 'TF High',...
		 'TF Fitparameters'};
   case {'bw SF Test','equilum SF Test',...
	 'blue SF Test','green SF Test'}
    stimulusname=testname(1:end-5);
    assoclist = {...%[stimulusname ' Test'],...
	         [stimulusname ' Response Curve F0'],...
		 [stimulusname ' Response Curve F1'],...
		 [stimulusname ' F1 Phase'],...
		 [stimulusname ' Max drifting grating firing'],...
		 [stimulusname ' Pref'],...
		 [stimulusname ' Low'],...
		 [stimulusname ' High'],...
		 [stimulusname ' DOG'],...
		 [stimulusname ' F1/F0']};
    if strcmp(testname,'bw SF Test')
      assoclist{end+1}=[stimulusname ' Color sensitivity'];
    elseif strcmp(testname,'blue SF Test')
      assoclist{end+1}=[stimulusname ' Color opponency'];
    end
   case 'Contrast Test',
    assoclist = {'Contrast Response Curve F0',...
		 'Contrast Response Curve F1',...
		 'C50',...
		 'Contrast Max rate',...
		 'Cgain 0-16',...
		 'Cgain 16-100',...
		 'Cgain 0-32',...
		 'CGain32Ratio',...
		 'Naka-Rushton gain',...
		 'Naka-Rushton max',...
		 'Naka-Rushton 50',...
		 'Naka-Rushton exponent',...
		 'Contrast Spontaneous rate'};
   case 'FDT Test',
    assoclist = {'FDT Response Curve F0',...
		 'FDT Response Curve F1',...
		 'FDT Max firing rate',...
		 'FDT Pref',...
		 'FDT Circular variance',...
		 'FDT Tuning width',...
		 'FDT Direction index',...
		 'FDT Orientation index',...
		 'FDT F1/F0',...
		 'FDT Spontaneous rate'};
   case 'OT Test',
    assoclist = {'OT Response Curve F0',...
		 'OT Response Curve F1',...
		 'OT F1/F0',...
		 'OT Max drifting grating firing',...
		 'OT Pref',...
		 'OT Circular variance',...
		 'OT Tuning width',...
		 'OT Orientation index',...
		 'OT Direction index',...
		 'OT Spontaneous rate'};
   case 'Pos Test',
    assoclist = {'Pos Response Curve F0',...
		 'Pos Response Curve F1',...
		 'Pos Max drifting grating firing',...
		 'Pos F1/F0',...
		 'Pos Pixels Pref',...
		 'Pos Degrees Pref'};
   case 'Length Test',
    assoclist = {'Length Response Curve F0',...
		 'Length Response Curve F1',...
		 'Length Max drifting grating firing',...
		 'Length F1/F0',...
		 'Length Pixels Pref',...
		 'Length Pixels Low',...
		 'Length Pixels High',...
		 'Length Degrees Pref',...
		 'Length Degrees Low',...
		 'Length Degrees High'};
   case 'Width Test',
    assoclist = {'Width Response Curve F0',...
		 'Width Response Curve F1',...
		 'Width Max drifting grating firing',...
		 'Width F1/F0',...
		 'Width Pixels Pref',...
		 'Width Pixels Low',...
		 'Width Pixels High',...
		 'Width Degrees Pref',...
		 'Width Degrees Low',...
		 'Width Degrees High'};
   case 'Color Test',
    assoclist = {'Color Response Curve F0',...
		 'Color Response Curve F1',...
		 'Color Max rate',...
		 'Color Min rate',...
		 'Color F1/F0',...
		 'Color Spontaneous rate',...
		 'Color Fitparameters',...
		 'Color Fitfunction',...
		 'Color Balance'};
   case 'VEP Test',
    assoclist={'VEP Latency'};
   case 'all',
    assoclist = {};
    testlist = {'CentSize','ConeTest','TF Test','Contrast Test',...
		'OT Test','Phase Test',...
		'bw SF Test','equilum SF Test',...
		'blue SF Test','green SF Test','FDT Test',...
		'Pos Test','Length Test','Width Test','Color Test',...
		'VEP Test'};
    for i=1:length(testlist),
      assoclist = cat(2,assoclist,ctxassociatelist(testlist{i}));
    end;
end;
