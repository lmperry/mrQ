function pMatrix = polyCreateMatrix(nSamples,order,dimension)
% Build 2D polynomial matrix.  Will generalize to other cases later
%
%
% Example:
%   nSamples = 20; order = 2; dimension = 2;
%   pMatrix = polyCreateMatrix(20,2,2);
%   imagesc(pMatrix)
%
% BW Copyright vistasoft 2013

switch order
    case 2  % 2nd order polynomial
        if dimension == 1
            X = 1:nSamples; 
            X = X(:);
            X2 = X(:).^2;
            pMatrix = [X, X2];
        elseif dimension == 2
            [X, Y] = meshgrid(1:nSamples,1:nSamples);
            X = X(:);
            Y = Y(:);
            X2 = X(:).^2;
            Y2 = Y(:).^2;
            XY = X(:).*Y(:);
            % X, X^2, Y, Y^2, XY
            pMatrix = [X, X2, Y, Y2, XY];
        else
            error('Not yet implemented')
        end
        
    otherwise
        error('Order %d not built',order);
end



return