% skel2obj
%    Reconstructs an object from its distance transform-derived skeleton. 
%         
%    Input
%    --------------------
%    skel          Skeleton image
%    mode          = 1, uses the midpoint circle algorithm to append
%                  circles to the image
%                  = 2, uses a function involving polymask to append
%                  circles to the image
%
%    Output
%    --------------------
%    obj           Image of reconstructed object
%
%    Example
%    --------------------
%    A_obj = skel2obj(A_skel);
%
%    Dependencies
%    --------------------
%    [1] Requires Peter Bone's implementation of the midpoint circle
%    algorithm:
%    http://www.mathworks.com/matlabcentral/fileexchange/14331-draw-a-circle-in-a-matrix-image
%
%    References
%    --------------------
%    http://reference.wolfram.com/mathematica/ref/InverseDistanceTransform.html
%
%    Mode 1:
%    http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
%
%    Mode 2:
%    http://stackoverflow.com/questions/7648186/is-there-any-function-opposite-to-bwmorphimage-skel-in-matlab-or-c-c-code
%

function obj = skel2obj( skel, mode )

if nargin < 2; mode = 1; end

if mode == 1
    Idx = find(skel > 0);
    [r c] = ind2sub(size(skel),Idx);
    obj = zeros(size(skel));
    for i = 1:numel(Idx)
        obj = midpoint(obj,skel(Idx(i)),r(i),c(i),1);
    end
    obj = imfill(obj,'holes');
else
    t = linspace(0,2*pi,50);
    ct = cos(t);
    st = sin(t);
    [r c] = size(skel);
    obj = false(r,c);
    for j=1:c
        for k=1:r
            if skel(k,j)==0, continue; end
            mask = poly2mask(skel(k,j).*st + j, skel(k,j).*ct + k, r, c);
            obj(mask) = true;
        end
    end     
end

end