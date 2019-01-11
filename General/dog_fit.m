function par = dog_fit(x,y,options)
%DOG_FIT fits difference of gaussians
%
%    PAR=DOG_FIT(X,Y,[OPTIONS])
%
%    PAR = [ R0 RE SE RI SI ]
%    OPTIONS can be 'zerobaseline', in which case for x->inf, y->0
%
%    R0 is baseline response
%    RE is maximum response of positive gaussian
%    SE is standard deviation of positive gaussian
%    RI is maximum response of negative gaussian
%    SI is standard deviation of negative gaussian
%
% 200X-2019, Alexander Heimel

if nargin<3 || isempty(options)
    options = '';
end

search_options=optimset('fminsearch');
	search_options.TolFun=1e-4;
	search_options.TolX=1e-4;
	search_options.MaxFunEvals=6*300;%'300*numberOfVariables';
	search_options.Display='off';

% starting values
[~,ind] = max(x);
r0 = y(ind); %min(y);
re = max(y)-r0;
se = max(x)/2;
ri = re+r0;
si = min(x)/2;
xo = [r0 re se ri si];

switch lower(options)
    case 'zerobaseline'
        xo(1)= 0;
        par = fminsearch(@(par) dog_error([0 par(2:5)],x,y),xo,search_options);
        par(1) = 0;
    otherwise
        par = fminsearch(@(par) dog_error(par,x,y),xo,search_options);
end






