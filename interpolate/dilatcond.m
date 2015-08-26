function [dc, L] = dilatcond( img1, img2, opts )
% Generates an image stack, dc, for which each slice corresponds to 
% subsequent iterations of conditional dilations from img1 to img2.
% Iterations continue until the dilation has reached img2, i.e. the area of
% img2 is the same as the area of the dilation iteration.
%
% Required Inputs
% ===============
%     img1    Starting image to being conditional dilations from
%     img2    Final image to conditionally dilate to
%     opts    Structure with optional argument values generated from the 
%             wrapper function albuRun
%
% Outputs
% =======
%     dc    3D stack of conditional dilations from img1 to img2. The stack
%           will have the size [size(img1,1) size(img1,1) L].
%     L     The number of conditional dilations required
%
% See also albuRun, albuInterpolate, construct_seq
%

% Check that the two input images have the same dimensions in X and Y
if ~isequaln(size(img1), size(img2))
    error('img1 and img2 must have the same dimensions');
end

% Set the zero-th iteration of conditional dilation to the input image
dc = uint8(img1);

% Compute the target area (i.e., the area of the second input image being
% dilated to)
area = sum(sum(img2(:)));
L = 1;

% Perform iterative conditional dilations until the area of the dilated
% intermediate is equal to the target area.
while sum(sum(dc)) ~= area
    dc(:,:,L+1) = imdilate(dc(:,:,L), opts.se);
    dc(:,:,L+1) = dc(:,:,L+1) & img2;
    L = L + 1;  
end

% If desired, graphically display the results of each iteration overlaid on
% the target image
if opts.dispimg
    boxDim = ceil(sqrt(L));
    figure;
    for ii = 1:L
        h = subplot(boxDim, boxDim, ii);
        imshow(dc(:,:,ii) + 2*img2, []);
        h = findobj(h, 'type', 'image');
        if opts.dispgrid
            pixelgrid(h);
        end
    end
end

end
