function order_cellarray(orgcells)
%ORDER_CELLARRAY lets one graphically order a cell array
%
  ud.orgcells=orgcells;
  
  n_cells=length(orgcells);
  ud.order=(1:n_cells);
  
  screensize=get(0,'ScreenSize');
  
  labelleft=5;
  labelwidth=100;
  labelheight=17;
  
  linesep=3;
  colsep=3;
  lineheight=labelheight+linesep;
  colwidth=labelleft+labelwidth+2*colsep;
  height=n_cells*lineheight;

  bc=0.8*[1 1 1];
  h_fig=figure('Name','Order cell',...
	       'Color',bc,...
	       'Position',[screensize(3)/2-colwidth/2 screensize(4)/2-height/2 colwidth height], ... 
	       'Tag','order_cellarray_callback', ...
	       'Units','pixels',...
	       'Menu','none',...
	       'ToolBar','none');
  
  
  top=height-lineheight;  
    
  left=labelleft;
  for i=1:n_cells
    h_cell(i) =...
	uicontrol('Parent',h_fig, ...
		  'Units','pixels', ...
		  'BackgroundColor',bc,...
		  'Callback','genercallback',...
		  'ListboxTop',0, ...
		  'Position',[left top+2 labelwidth labelheight], ...
		  'String',orgcells{i}, ...
		  'HorizontalAlignment','center',...
		  'Units','pixels',...
		  'Tag',num2str(i));
    
    top=top-lineheight;

  end
  ud.h_cell=h_cell;
  
  set(h_fig,'UserData',ud);