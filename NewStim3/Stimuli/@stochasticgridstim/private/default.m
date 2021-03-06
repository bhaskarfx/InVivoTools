function parameters = default
% 2012, Alexander Heimel

if ~exist('rng_twister','file') % for backwards compatibility with R2009
    rs = rand('state');
else
    rs = rng_twister;
end

parameters = struct ( ...
    'BG', [128 128 128], ...
    'dist', [1;30], ...
    'values', [255 255 255; 0 0 0], ...
    'rect',[0 0 400 400], ...
    'angle', 0,  ...
    'pixSize', [50 50] , ...
    'N',150,...
    'fps',5, ...
    'randState', rs); 
parameters.dispprefs = {};