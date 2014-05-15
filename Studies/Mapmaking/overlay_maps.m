%function overlay_maps
%OVERLAY_MAPS loads intrinsic signal winner-take-all maps and overlays them
%
% 2014, Enny van Beest, Alexander Heimel
%

%persistent db mousedb

experiment(''); % to select for which specific experiment to load the data

if ~exist('mousedb','var') || isempty(mousedb)
    mousedb = load_mousedb;
end

if ~exist('db','var') || isempty(db)
    db = load_testdb;
end

mousedb = mousedb(find_record(mousedb,'strain!*BXD*,strain!*DBA*'));

close_figs; % to close non-persistent figures
figure;

for m = 1:length(mousedb) % loop over mice
    ind = find_record(db,['mouse=' mousedb(m).mouse ',stim_type=retinotopy,reliable!0']);
    for i = ind % loop over tests
        record = db(i);
        if isempty(record.ref_image) || isempty(record.imagefile)
            continue
        end
        if ~all(record.stim_parameters==[2 2]) % only do 2x2 maps
            continue
        end
        if ~strcmpi(record.hemisphere,'left')
            continue
        end
        
        filename = fullfile(oidatapath(record),'analysis',record.imagefile);
        if ~exist(filename,'file') || exist(filename,'dir')
            logmsg(['Image ' filename ' does not exist.']);
            continue
        end
        img = imread(filename);
        if ~isa(img,'uint8')
            logmsg(['Image of ' recordfilter(record) ' is not a uint8.']);
            continue
        end
        impatch = zeros(size(img,1),size(img,2),4,'uint8');
        impatch(:,:,1) = (img(:,:,1)-img(:,:,2)); % red
        impatch(:,:,2) = (img(:,:,2)-img(:,:,1)); % green
        impatch(:,:,3) = img(:,:,3); % blue
        impatch(:,:,4) = img(:,:,1) - impatch(:,:,1);
        impatch = double(impatch);

        
        
        % lambda is in unbinned pixel coordinates
        % reference image is unbinned
        [lambda_x,lambda_y,refname] = get_bregma(record);
        if isempty(lambda_x)
            continue
        end
        imgref=imread(refname,'bmp');

        
        % convert comma separated lists into cell list of tests
        % e.g. 'mouse_E2,mouse_E3' -> {'mouse_E2','mouse_E3'}
        tests=convert_cst2cell(record.test);

        % get image info
        fileinfo=imagefile_info( fullfile(oidatapath(record),...
            [ tests{1} 'B0.BLK']));
        if ~isfield(fileinfo,'xoffset')
            continue
        end
        
        xoffset = fileinfo.xoffset; % in (binned?) pixels
        yoffset = fileinfo.yoffset; % in (binned?) pixels
        xsize = fileinfo.xsize;
        ysize = fileinfo.ysize;
        
        % show data
        
        subplot(3,2,1);
        image(img)
        axis image off

        subplot(3,2,2);
        imagesc(imgref);
        axis image off
        hold on
        h = plot(lambda_x,lambda_y,'+r');
        set(h,'MarkerSize',10);

        h = line([xoffset xoffset+xsize xoffset+xsize xoffset xoffset]*fileinfo.xbin,...
            [yoffset yoffset yoffset+ysize yoffset+ysize yoffset]*fileinfo.ybin);
        
        hold off

        
        
        colmap = colormap('gray');
        for c=1:4
            subplot(3,2,2+c);
            image(impatch(:,:,c)/255*size(colmap,1));
            axis image off
        end
        
        
            
        keyboard
        
        
    end % test i
end % mouse m