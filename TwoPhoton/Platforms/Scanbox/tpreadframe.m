function [im,fname] = tpreadframe(record,channel,frame,opt,verbose, fname,multiple_frames_mode)
%TPREADFRAME read frame from scanbox sbx file
%
%  [IM, FNAME] = TPREADFRAME( RECORD, CHANNEL, FRAME, OPT, VERBOSE, FNAME, multiple_frames_mode )
%
%    if multiple_frames_mode == 0, output individual frames, if
%    multiple_frames_mode ==1, output avg
%    multiple_frames_mode ==2, output max
%
% 2017, Alexander Heimel
%

persistent readfname images

if nargin<7 || isempty( multiple_frames_mode )
    multiple_frames_mode = 0;
end
if nargin<5 || isempty(verbose)
    verbose = true;
end
if length(channel)>1
    warning('TPREADFRAME:MULTIPLE_CHANNELS','TPREADFRAME:TPREADFRAME WILL IN FUTURE ONLY ACCEPT SINGLE CHANNEL');
end
if nargin<4
    opt = [];
end
if nargin<6 || isempty(fname)
    fname = tpfilename( record, frame, channel, opt);
end

if length(fname)>4 && strcmp(fname(end-3:end),'.sbx')
    fname = fname(1:end-4);
end

% check if matlabstored file is present
if strcmp(readfname,fname)==0 % not read in yet
    org_fname = tpfilename( record, frame, channel); % no options
    iminf = tpreadconfig(record);
    
    if iminf.BitsPerSample~=16
        warning('TPREADFRAME:not_16bits','TPREADFRAME: Bits per samples is unequal to 16');
    end
    try
        images = zeros(iminf.Height,iminf.Width,iminf.NumberOfFrames,iminf.NumberOfChannels,'uint16');
    catch me
        if strcmp(me.identifier,'MATLAB:nomem')
            required = iminf.Height*iminf.Width*iminf.NumberOfFrames*iminf.NumberOfChannels*2/1024/1024; % in Mb
            m = memory;
            available = m.MaxPossibleArrayBytes/1024/1024; % in Mb
            warning('TPREADFRAME:MEM',['TPREADFRAME: Array size to large. ' ...
                num2str(fix(required)) ' Mb required, ' num2str(fix(available)) ' Mb available.']);
            warning('OFF','TPREADFRAME:MEM');
            if ~isfield(iminf,'slice') || isempty(iminf.slice)
                im = sbxread(fname,frame-1,1);
            else
                im = sbxread(fname,(frame-1)*iminf.slices + iminf.slice,1);
            end
            return
        else
            rethrow me
        end
    end
    logmsg(['Loading ' fname]);
    if exist(fname,'file') && ~strcmp(org_fname,fname)
        % i.e. (processed) image file already exists
        already_processed = true;
    else
        already_processed = false;
    end
    
    if verbose
        hwaitbar = waitbar(0,'Loading frames...');
    end
    waitbarstep = max(1,round(iminf.NumberOfFrames/100)); % only maximum 100 updates

    
    if ~isfield(iminf,'slice') || isempty(iminf.slice)
        if iminf.NumberOfChannels>1
            for fr = 1:iminf.NumberOfFrames
                images(:,:,fr,:) = permute(sbxread(fname,fr-1,1),[2 3 4 1]);
                if verbose && mod(fr,waitbarstep)==0
                    hwaitbar = waitbar(fr/iminf.NumberOfFrames);
                end
            end
        else
            for fr = 1:iminf.NumberOfFrames
                images(:,:,fr,1) = sbxread(fname,fr-1,1);
                if verbose && mod(fr,waitbarstep)==0
                    hwaitbar = waitbar(fr/iminf.NumberOfFrames);
                end
            end
        end
    else
        if iminf.NumberOfChannels>1
            for fr = 1:iminf.NumberOfFrames
                images(:,:,fr,:) =permute( sbxread(fname,(fr-1)*iminf.slices + iminf.slice-1,1),[2 3 4 1]);
                if verbose && mod(fr,waitbarstep)==0
                    hwaitbar = waitbar(fr/iminf.NumberOfFrames);
                end
            end
        else
            for fr = 1:iminf.NumberOfFrames
                images(:,:,fr,1) = sbxread(fname,(fr-1)*iminf.slices + iminf.slice-1,1);
                if verbose && mod(fr,waitbarstep)==0
                    hwaitbar = waitbar(fr/iminf.NumberOfFrames);
                end
            end
        end
    end
    if verbose
        close(hwaitbar);
    end
    if ~already_processed
        % shift bidirectional scanned image
        if isfield(iminf,'bidirectional') && iminf.bidirectional
            % determine optimal shift
            
            mean_image = mean(mean(images,3),4);
            shift_range = [ 2 3 4 5 6 7 8 9 10 11 ];
            max_correl = -inf;
            shift = 0;
            im = zeros(size(mean_image));
            for i =1:length(shift_range)
                % shift odd and even lines
                oddshift = floor( shift_range(i)/2);
                evenshift = ceil(shift_range(i)/2);
                
                im(1:2:end,1+oddshift:end) = mean_image(1:2:end, 1:end-oddshift);
                im(2:2:end,1:end-evenshift) = mean_image(2:2:end, 1+evenshift:end);
                correl = corrcoef( flatten(im(1:2:end,:)), flatten(im(2:2:end,:)));
                if correl(1,2)>max_correl
                    shift = shift_range(i);
                    max_correl = correl(1,2);
                end
            end % i shiftrange
            
            % shift odd and even lines
            oddshift = floor( shift/2);
            evenshift = ceil(shift/2);
            for ch = 1:iminf.NumberOfChannels
                for fr = 1:iminf.NumberOfFrames
                    images(1:2:end,1+oddshift:end,fr,ch) = images(1:2:end, 1:end-oddshift,fr,ch);
                    images(2:2:end,1:end-evenshift,fr,ch) = images(2:2:end, 1+evenshift:end,fr,ch);
                end
            end
            logmsg(['Optimal line shift for bidirectional ' num2str(shift)]);
        end
        
        % now do image processing
        images = tp_image_processing( images, opt,verbose );
        if ~strcmp(fname,org_fname)
            % save processed file for later use
            %             logmsg(['Writing processed image stack as ' fname]);
            %             writepath = fileparts(fname);
            %             if ~exist(writepath,'dir')
            %                 mkdir(writepath);
            %             end
            logmsg('Not implemented writing processed image');
            %            fluoviewtiffwrite(images,fname,iminf)
        end
    end
    logmsg('Finished reading')
    readfname = fname; % when completely loaded set readfname
end

switch multiple_frames_mode
    case 0 % return individual images
        im = images(:,:,frame,channel);
    case 1 % avg
        if ndims(images)==3 && length(frame)==size(images,3)
            % assume only 1 channel, and want all frames
            im = sum(images,3); % much faster
        else
            im = sum(double(images(:,:,frame,channel)),3);
        end
        im = im/length(frame);
    case 2 % max
        im = max(double(images(:,:,frame,channel)),[],3);
end
