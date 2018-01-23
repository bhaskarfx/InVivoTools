function [azimuth,elevation,r] = compute_overheadstim_angles( nose_pxl,arse_pxl,stim_pxl)
%COMPUTE_OVERHEADSTIM_ANGLES computes elevation and azimuth of a stimulus relative to mouse
%
%  [AZIMUTH, ELEVATION, R] = COMPUTE_OVERHEADSTIM_ANGLES( NOSE_PXL,ARSE_PXL,  STIM_PXL)
%
%     AZIMUTH is horizontal angles in radii, in front of animal is 0, left
%     of animal is -pi/2
%
%     ELEVATION is altitude angle in radii. Above mouse is pi/2
%
%     R is distance in cm
%
% 2018, Alexander Heimel

monitorheight_cm = 35;
floor_pxl_per_cm = 640/47;
monitor_pxl_per_cm = 490/47;

% nose_pxl = [n x 2], n rows of x,y coordinates of nose in camera pixels
% arse_pxl = [n x 2], n rows of x,y coordinates of arse in camera pixels
% stim_pxl = [n x 2], n rows of x,y coordinates of stim center in camera pixels

% switch to (uncorrected) centimeters (full widths of floor and monitor)
    nose_cm = nose_pxl / floor_pxl_per_cm;
    arse_cm = arse_pxl / floor_pxl_per_cm;
    stim_cm = stim_pxl / monitor_pxl_per_cm;

% transform pxls to cm by reverse fisheye transform
if 0
    nose_cm = reverse_fisheye(nose_cm,fishparams_floor); %#ok<UNRCH>
    arse_cm = reverse_fisheye(arse_cm,fishparams_floor);
    stim_cm = reverse_fisheye(stim_cm,fishparams_ceiling);
else
    warning('COMPUTER_OVERHEADSTIM_ANGLES:NOFISHEYE','No fish eye undistortion performed');
    warning('off','COMPUTER_OVERHEADSTIM_ANGLES:NOFISHEYE');
end

% make the nose center
arse_cm_nose_centered = arse_cm - nose_cm;
stim_cm_nose_centered = stim_cm - nose_cm;

phi = cart2pol(arse_cm_nose_centered(:,1),arse_cm_nose_centered(:,2));
phi = pi - phi;
stim_cm_nose_centered_rotated = NaN(length(phi),2);
for i=1:length(phi)
    stim_cm_nose_centered_rotated(i,:) = [cos(-phi(i)) sin(-phi(i)); -sin(-phi(i)) cos(-phi(i))] * stim_cm_nose_centered(i,:)';
end

stim_cm_nose_centered_rotated(:,3) = monitorheight_cm;

[azimuth,elevation,r] = cart2sph(...
    stim_cm_nose_centered_rotated(:,1),...
    stim_cm_nose_centered_rotated(:,2),...
    stim_cm_nose_centered_rotated(:,3));





