function seq = construct_seq( dca, dcb, opts )
% Construct the transition sequence from two stacks of conditional
% dilations between image A and image B.
%
% Required Inputs
% ===============
%     dca     Stack of conditional dilations from image A to B
%     dcb     Stack of conditional dilations from image B to A
%     opts    Structure with optional argument values generated from the 
%             wrapper function albuRun
%
% Output
% ======
%     seq     Transition sequence
%
% See also albuRun, albuInterpolate, dilatcond
%

if nargin < 3; dispimg = 0; end
if nargin < 2; error(['Must specify both input conditional dilations, ' ...
        'dca and dcb']); end

% Check that the two inputs have matching sizes in all three dimensions
if ~isequaln(size(dca), size(dcb))
    error(['The conditional dilations, dca and dcb, must have matching' ...
        'dimensions']);
end

% Define seq as the logical OR of the dca and dcb stacks
seq = uint8(dca | dcb);

if opts.dispimg
    % Determine the starting images, A and B, based on the conditional
    % dilation iteration stacks
    imga = dca(:,:,1);
    imgb = dcb(:,:,end);
    C = 1;
    while sum(sum(imgb)) == 0
        imgb = dcb(:,:,end-C);
        C = C + 1;
    end
    
    nslices = size(dca, 3);
    boxDim = ceil(sqrt(nslices));
    figure;
    for ii = 1:nslices
        h = subplot(boxDim, boxDim, ii);
        imshow(seq(:,:,ii) + 2*(uint8(imga | imgb)), []);
        if opts.dispgrid
            pixelgrid(h);
        end
    end
end