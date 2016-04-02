function measures = compute_position_measures( measures, stimfile )
%COMPUTE_POSITION_MEASURES compute some specific tiling measures
%
%  MEASURES = COMPUTE_SIZE_MEASURES( MEASURES )
%
%
% 2016 Alexander Heimel
%

if ~strcmp(measures.variable,'position') 
    return
end

stimparams = cellfun(@getparameters,get(stimfile.saveScript));
rects = cat(1,stimparams(:).rect);
left = uniq(sort(rects(:,1)));
right = uniq(sort(rects(:,3)));
top = uniq(sort(rects(:,2)));
bottom = uniq(sort(rects(:,4)));
center_x = (left+right)/2;
center_y = (top+bottom)/2;
n_x = length(center_x);
n_y = length(center_y);
stimrect = [min(left) min(top) max(right) max(bottom)];

for t=1:length(measures.triggers)
   response = measures.response{t};
   measures.rect = stimrect;
   resp_by_pos = reshape(response,n_x,n_y)';
   resp_by_pos = thresholdlinear(resp_by_pos);
   measures.rf{1} = resp_by_pos;
   center_of_mass_x = center_x(:)'*  sum(resp_by_pos,1)'/sum(resp_by_pos(:));
   center_of_mass_y = center_y(:)'*sum(resp_by_pos,2)/sum(resp_by_pos(:));
   measures.rf_center{1} = round([center_of_mass_x center_of_mass_y]);
end
