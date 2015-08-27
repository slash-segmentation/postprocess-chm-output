% skeletonization_dt
%    Generates the skeleton for an input binary image based on the distance
%    transformation. This method allows for easy object reconstruction from
%    the skeleton.
%         
%    Input
%    --------------------
%    Im            Input binary image.
%    Output
%    --------------------
%    skel          Output skeleton of Im.
%
%    Example
%    --------------------
%    S = skeletonization_dt(I);
%
%    Reference
%    --------------------
%    http://reference.wolfram.com/mathematica/ref/SkeletonTransform.html
%    http://stackoverflow.com/questions/7648186/is-there-any-function-opposite-to-bwmorphimage-skel-in-matlab-or-c-c-code
%

function skel = skeletonization_dt( Im )

sk = bwmorph(Im,'skel',Inf);
dt = double(bwdist(~Im));
skel = zeros(size(dt));
skel(sk) = dt(sk);

end