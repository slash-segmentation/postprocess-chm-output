function Im_cpd = im2cpd( Im )
% im2cpd
%    Converts an image to the 3xM indexed representation needed by the CPD
%    algorithm.
%         
%    Input
%    --------------------
%    Im            Input binary image.
%
%    Output
%    --------------------
%    Im_cpd        Mx3 representation of binary image.
%
%    Example
%    --------------------
%    A_cpd = im2cpd(A);
    
Idx = find( Im > 0 );
Im_cpd = zeros(3,numel(Idx));
[X Y] = ind2sub(size(Im),Idx);
Im_cpd(1,:) = X';
Im_cpd(2,:) = Y';
Im_cpd(3,:) = Im(Idx)';

end