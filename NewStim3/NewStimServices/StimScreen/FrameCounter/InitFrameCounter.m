function InitFrameCounter(frameCounter)%  function InitFrameCounter(frameCounter)%%  Draws the background of the framecounter on StimWindow (if open)%  and initializes the frame count to 1.FrameCounterGlobals;frameCounter.currentFrame = 1;StimWindowGlobalsif (~isempty(StimWindow)), 	 Screen(StimWindow,'FillRect', frameCounter.bg, FrameCounterRect(2,:));	 if (~isempty(frameCounter.clut_index)),		 Screen(StimWindow,'FillRect',frameCounter.clut_index,FrameCounterRect(1,:));	 end;end;