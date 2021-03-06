function df=diskusage( disk )
%DISKUSAGE gives diskusage (only works in unix)
%
% DF=DISKUSAGE( DISK )
%
% 2007, Alexander Heimel
%

df.available=inf;

if nargin < 1
  disk='';
end

if isempty(disk)
  disk='.'
end

switch computer
    case {'GLNX86','GLNXA64'}
        %
    otherwise
        disp('DISKUSAGE only works under unix/linux')
        return
end

[s,w]=system(['df -P ' disk ]);

if s~=0 
    if ~exist(disk,'dir')
        logmsg(['Folder ' disk ' does not exist']);
    else
        logmsg(['Error in performing diskusage of disk ' disk ]);
    end
  return
end

w=split(w,10); % split at returns
header=w{1};
content=w{2};

p=[];
p(end+1)=strfind(header,'Filesystem');
p(end+1)=20;
p(end+1)=strfind(header,'1024-blocks')+length('1024-blocks');
p(end+1)=strfind(header,'Used')+length('Used');
p(end+1)=strfind(header,'Available')+length('Available');
p(end+1)=strfind(header,' Mounted on');
p(end+1)=256;

fields={'filesystem','blocks','used','available','capacity','mounted_on'};

for i=1:length(p)-1
  switch fields{i}
   case 'capacity'
    field=strtrim(content(p(i):min(end,p(i+1)-2))) ;
   otherwise
    field=strtrim(content(p(i):min(end,p(i+1)-1))) ;
  end
  
  if ~isempty(str2num(field))
    field=str2num(field);
  end
  
    df=setfield(df,fields{i},field);

end



