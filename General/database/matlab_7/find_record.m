function ind=find_record(db,crit)
% FIND_RECORD finds records matching criteria in database
%
%   IND=FIND_RECORD(DB,CRIT)
%          DB is struct array containing database
%          CRIT is a string containg criteria
%
%     special characters in criterium:
%        |    logical or
%        ,    logical and
%        =    equal to
%        !    unequal to
%        >    larger than
%        <    smaller than
%
%
%  criterium examples:
%          lsl=TLT 817, typing_lsl>0, cre=Kazu*
%          cre=Kazu | cre=Kazu-X
%          typing_lsl!0
%
%   implemented comparisons for strings:
%           = (equal) and ! (unequal), <, >
%   implemented comparisons for numbers:
%           =, !, <, >
%
%   when using logical ands in criteria put the most restrictive condition
%   first for maximum speed
%
%   to find case-insensitive use '~' or wild cards *
%
%   FIND_RECORD returns a one-row columnar vector like FIND
%
%   2005, Alexander Heimel
%

if isempty(db)
    ind=[];
    return
end

if isempty(crit)
    ind=(1:length(db));
    return
end


% if criterium is a cell list, than apply 'and' to all individual
% conditions
if iscell(crit)
    if length(crit)>1
        ind=(1:length(db));
        for i=1:length(crit)
            ind=ind( find_record( db(ind), crit{i} ) );
        end
        return
    else
        crit=crit{1};
    end
end


% at this point crit is certainly a non-empty string
crit=trim(crit);

ind=[];
if crit(1)=='('
    br_open=1;
    p=1;
    while br_open>0 && p<length(crit)
        p=p+1;
        switch crit(p)
            case ')', % bracket closed
                br_open=br_open-1;
            case '(', % bracket opened
                br_open=br_open+1;
        end
    end
    if br_open>0
        disp(['Unclosed bracket in criterium: ' crit]);
        return
    end
    
    if p==length(crit)
        ind=find_record(db,{crit(2:p-1)});
    else
        head=crit(2:p-1);
        tail=crit(p+1:end);
        tail=trim(tail);
        switch tail(1)
            case ',' % AND
                ind=find_record(db,{head,tail(2:end)});
            case '|' % OR
                ind=uniq(sort([find_record(db,head)...
                    find_record(db,tail(2:end))]));
            otherwise
                disp(['Unexpected character after ) in criterium: ' crit]);
        end
    end
    return
end

p=find(crit==','|crit=='|');
if ~isempty(p)
    head=crit(1:p(1)-1);
    tail=crit(p(1)+1:end);
    switch crit(p(1))
        case ',' % AND
            ind=find_record(db,{head,tail});
        case '|' % OR
            ind=uniq(sort( [find_record(db,head) ...
                find_record(db,tail)] ));
    end
    return
end


% apply criteria
ind=[];
pos=sort([findstr(crit,'=') findstr(crit,'!') ...
    findstr(crit,'>') findstr(crit,'<') findstr(crit,'~')]);
if length(pos)>1
    disp(['FIND_RECORD: Only uses first comparison in ' crit ]);
    pos=pos(1);
end
if isempty(pos)
    % no comparison found, defaulting to using [firstfield '~' crit '*']
    fnames=fieldnames(db);
    crit=[fnames{1} '~' crit '*'];
    pos=length(fnames{1})+1;
end
if ~isempty(pos)
    comp=crit( pos ); % get which comparison
    field=trim( crit(1:pos-1) );
    
   
    
    expr=trim( crit(pos+1:end) );
    
    pbracket = find(field=='(',1);
    if ~isempty(pbracket) && pbracket>1
        fieldindex = str2double(field(pbracket+1:end-1));
        field = field(1:pbracket-1);
    else
        fieldindex = [];
    end
    
    if strcmp(field,'recordnumber') && ~isfield(db,'recordnumber')
        content = 1;
        entries = num2cell( 1:length(db) );
    else
        try
            content=db(1).(field);
        catch %exception
            
            if ~isfield(db,field)
                disp(['FIND_RECORD: ' field ' is not a valid field']);
                ind=[];
                return
                %else
                %  throw(exception)
            end
        end
        if ~isempty(fieldindex)
            entries = cellfun(@(x) x(fieldindex),{db(:).(field)});
            if isnumeric(entries)
                entries = num2cell(entries);
            end
        else
            entries={db(:).(field)};
        end
    end
    if isnumeric(content) % && ~isempty(content)
        expn=str2double(expr);
        switch comp
            case '=',
                for i=1:length(db)
                    if entries{i}==expn;
                        ind(end+1)=i;
                    end
                end
            case '!',
                for i=1:length(db)
                    if entries{i}~=expn
                        ind(end+1)=i;
                    elseif isempty(entries{i})
                        ind(end+1)=i;
                    end
                end
            case '>',
                for i=1:length(db)
                    if entries{i}>expn
                        ind(end+1)=i;
                    end
                end
            case '<',
                for i=1:length(db)
                    if entries{i}<expn
                        ind(end+1)=i;
                    end
                end
            otherwise
                disp(['comparison type ' comp ...
                    ' is not implemented for numbers.'])
        end
    else
        % check if there are wildcards in comparison and replace = by ~
        if comp=='='
            if ~isempty(find(expr=='*',1))
                comp='~';
            end
        end
        switch comp
            case '~', % with wildcard
                for i=1:length(db)
                    if numel(entries{i})~=length(entries{i})
                        ent = '';
                        for j=1:size(entries{i},1)
                            ent = [ ent ' ' trim(entries{i}(j,:))];
                        end
                        entries{i} = ent;
                    end
                    
                    if streq( entries{i}, expr,'*')==1
                        ind(end+1)=i;
                    end
                end
            case '=',
                ind=strmatch(expr,entries,'exact');
                %      for i=1:length(db)
                %       if strcmp( entries{i}, expr)==1
                %        ind(end+1)=i;
                %    end
                %   end
            case '!',
                for i=1:length(db)
                    content = entries{i};
                    if iscell(content) 
                        content = flatten(content);
                    end
                    if ischar(content) && size(content,1)>1
                        content = flatten(content')';
                    end
                    if streq(content, expr)==0
                        ind(end+1)=i;
                    elseif isempty(content)
                        ind(end+1)=i;
                    end
                end
            case {'>','<'},
                for i=1:length(db)
                    content=entries{i};
                    if ~isempty(content)
                        nlen=max(length(content),length(expr))+1;
                        pcontent=padarray( double(content)', ...
                            nlen-length(content),'post');
                        pexpr=padarray( double(expr)', ...
                            nlen-length(expr),'post');
                        diff=pcontent-pexpr;
                        first_nz=find(diff~=0);
                        if ~isempty(first_nz)
                            first_nz=first_nz(1);
                            switch comp
                                case '>',
                                    if diff(first_nz)>0
                                        ind(end+1)=i;
                                    end
                                case '<',
                                    if diff(first_nz)<0
                                        ind(end+1)=i;
                                    end
                            end
                        end
                    end
                end
            otherwise
                disp(['comparison type ' comp ...
                    ' is not implemented for strings.'])
        end
    end
end

if size(ind,1)>1
    ind=transpose(ind);
end
