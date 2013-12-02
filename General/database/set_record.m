function record=set_record(record,settings)
%SET_RECORD sets some fields of record
%
%  RECORD=SET_RECORD(RECORD,SETTINGS)
%
%  2005, Alexander Heimel
%
  
  if ~iscell(settings)
    settings=split(settings,',');
  end

  for i=1:length(settings)
    setting=settings{i};
    indis=find(setting=='=');
    if length(indis)~=1
      display(['SET_RECORD: cannot handle setting ' setting ]);
      return
    end
    fieldname=trim(setting(1:indis-1));
    field=getfield(record,fieldname);
    content=trim(setting(indis+1:end));
    if isnumeric(field)
      record=setfield(record,fieldname,str2num(content));
    else
      record=setfield(record,fieldname,content);
    end
    
  end
