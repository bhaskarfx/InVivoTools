function newMTI = stripMTI(MTI)

for i=1:length(MTI),
	MTI{i}.ds = [];
	MTI{i}.df = [];
end;

newMTI = MTI;
