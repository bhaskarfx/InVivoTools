function par = wcprocessparams( record )
%WCPROCESSPARAMS sets parameters for webcam recording
%
% 2015, Alexander Heimel

% set player
if isunix
    par.wc_player = 'vlc' ;
    [status,out] = system(['which ' par.wc_player]);
    if status==0
        par.wc_playercommand = out ;
    else
        par.wc_player = 'totem';
        [status,out] = system(['which ' par.wc_player]);
        if status==0
            par.wc_playercommand = out;
        else
            par.wc_playercommand = '';
        end
    end
else
    par.wc_player = 'vlc'; 
    par.wc_playercommand = 'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe' ;
    if ~exist(par.wc_playercommand,'file')
        par.wc_playercommand = '';
    else
        par.wc_playercommand=['"' par.wc_playercommand '"'];
    end
end

% set mp4 wrapper
par.wc_mp4wrappercommand = '';
if isunix 
    par.wc_mp4wrappercommand = 'MP4Box -fps 30 -add ' ;
else
    if exist('C:\Program Files\GPAC\mp4box.exe','file')
        par.wc_mp4wrappercommand =  '"C:\Program Files\GPAC\mp4box.exe" -fps 30 -add ';
    end
end

par.wc_playbackpretime = 1; % s to show before stim onset


