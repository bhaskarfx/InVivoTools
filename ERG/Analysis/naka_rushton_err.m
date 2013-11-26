function err=naka_rushton_err(p,c,data)
%  NAKA_RUSHTON_ERR Naka-Rushton function helper function for fitting
%
%       ERR=NAKA_RUSHTON_ERR(P,C,DATA)
%       P = [rm b]
%          returns mean squared error of  p(1)*c./(p(2)+c) with data
%       P = [rm b n]
%          returns mean squared error of p(1)*cn./(p(2)^p(3)+cn) with data
%          where cn=c.^p(3)
%       P = [rm b n m]
%          returns mean squared error of p(1)*c^p(3)./(p(2)^p(4)+c^p(4)) with data
%
%
err=0;

switch length(p)
  case 2,   % p = [ rm b]
    fitr=p(1)*c./(p(2)+c);
    d = (data-repmat(fitr,size(data,1),1));
    err=err+sum(sum(d.*d));
  case 3,   % p = [ rm b n]
    c=c.^p(3);
    fitr=p(1)*c./(p(2)^p(3)+c);
    d = (data-repmat(fitr,size(data,1),1));
    err=err+sum(sum(d.*d));
    err=err+0.01*(p(3)-2)^2;% exponent  should be around 2
  case 4 % p=[rm b n m]
    fitr=p(1)*c.^p(3)./(p(2)^p(4)+c.^p(4));
    d = (data-repmat(fitr,size(data,1),1));
    err=err+sum(sum(d.*d));
    
    % n should be close unless good reason
    err=err* (1+0.1*(p(3)-p(4))^2);
  otherwise
    disp('Not enough parameters in NAKA_RUSHTON_ERR');
end
