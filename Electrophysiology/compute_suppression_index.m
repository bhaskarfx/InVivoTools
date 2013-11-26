function si = compute_suppression_index( x, response )
%COMPUTE_SUPPRESSION_INDEX returns suppression index
%
%  RECORD = COMPUTE_SUPPRESSION_INDEX( X, RESPONSES )
%
%
%      Computes the suppression index as by Carandini: To quantify the
%      strength of this surround suppression, we defined a suppression
%      index as (Rp – RL)/RL, where RL and RP are the responses
%      to the largest size and to the preferred size. For robustness,
%      we defined the latter as the smallest size that elicited >95% of
%      the maximal response (Figure 1B).
%
% 2013 Alexander Heimel
%

[x,ind] = sort(x); %#ok<ASGLU>
response = response(ind);

m = max(response);
rp = find(response>0.95*m,1);
rl = response(end);

si = (rp-rl)/rl;

