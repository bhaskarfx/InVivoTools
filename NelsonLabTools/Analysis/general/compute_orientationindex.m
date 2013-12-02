function [oi,di] = compute_orientationindex( angles, rates )
% COMPUTE_ORIENTATIONINDEX
%     [OI,DI] = COMPUTE_ORIENTATIONINDEX( ANGLES, RATES )
%
%     Takes ANGLES in degrees
%
%     oi = (max + max_180 - max_90 - max_270)/(max+max_180)
%     di = (max - max_180)/(max)
%
%     No interpolation done
%
% 2002-2013, Alexander Heimel

oi = [];
di = [];

if length(uniq(sort(angles))) ~= length(angles)
    disp('COMPUTE_ORIENTATIONINDEX: Only works for uniq angles.');
    return
end


if length(angles)<8
    return
end

[m,ind]=max(rates);
ang=angles(ind);

j1 = findclosest(mod(angles,360),mod(ang,360));
j2 = findclosest(mod(angles,360),mod(ang+180,360));
j3 = findclosest(mod(angles,360),mod(ang+90,360));
j4 = findclosest(mod(angles,360),mod(ang+270,360));
m1 = rates(j1);
m2 = rates(j2);
m3 = rates(j3);
m4 = rates(j4);
di = (m1-m2)/(m1+0.0001); % direction index
oi = (m1+m2-m3-m4)/(0.0001+(m1+m2)); % orientation

di = round(100*di)/100;
oi = round(100*oi)/100;