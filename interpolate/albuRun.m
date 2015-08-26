function interp = albuRun( A, B, skip, varargin )
% Wrapper function for running morphological, interslice interpolation with
% the algorithm of Albu and colleagues. The algorithm uses an object-based,
% iterative approach that involves computing a transition sequence based on
% conditional dilations between the two input slices. The two input slices
% must have the same dimensions.
%
% Required Inputs
% ===============
%     A        Starting image to begin the interpolation from
%
%     B        Ending image to interpolate to
%
%     skip     Number of slices skipped between the input images, A and B
%
% Optional Arguments
% ==================
%     'se'        Structuring element to use during dilation.
%                 DEFAULT = ones(3, 3)
%
%     'dispimg'   Toggles the display of intermediate images for trouble-
%                 shooting purposes. 1 = on, 0 = off.
%                 DEFAULT = 0
%
%     'dispgrid'  Toggles the display of pixel grid liens for images
%                 displayed when 'dispimg' is turned on. 1 = on, 0 = off.
%                 DEFAULT = 0
%
% Output
% ======
%     interp   The output stack of interpolations. The size of the stack
%              will be [size(A, 1) size(A, 2) skip].
%
% Example Usage
% =============
% (1) Interpolate two slices between A and B using a 3x3, cross-shaped
% structuring element:
%
% interp = albuRun(A, B, 2, 'se', [0 1 0; 1 1 1; 0 1 0]);
%
% (2) Interpolate four slices between A and B with the default structuring
% element. Display intermediate figures with pixel grid lines:
%
% interp = albuRun(A, B, 4, 'dispimg', 1, 'dispgrid', 1);
%
% Reference
% =========
% Albu, A.B., Beugeling, T., and Laurendeau, D. (2008). A morphology-based
% approach for interslice interpolation of anatomical slices from
% volumetric images. IEEE Transactions in Biomedical Engineering, 55(8), 
% 2022-2038.
%
% See also albuInterpolate, dilatcond, construct_seq
%

% Parse the optional arguments
defaults = struct('se', ones(3,3), 'dispimg', 0, 'dispgrid', 0);
opts = parse_varargin(defaults, varargin);

% The dimensions of A and B must be the same
dimsA = size(A);
dimsB = size(B);
if ~isequaln(dimsA, dimsB)
    error('The input images must have the same pixel dimensions.')
end

% Generate the interpolation stack. Set the first and last slices to be the
% input images, A and B, respectively.
interp = zeros([dimsA(1) dimsA(2) skip+2], 'uint8');
interp(:,:,1) = A;
clear A
interp(:,:,end) = B;
clear B

% Generate check_interp, a vector that will be one-valued at all slices 
% that have data, and zero-valued at all empty slices. This will be used to
% determine which slices need to be interpolated. The idx_keep vector has 
% size [1 skip] and specifies which slices in interp correspond to the 
% actual interpolations.
check_interp = reshape(sum(any(interp(:,:,:))) > 0, 1, size(interp, 3));
idx_keep = find(~check_interp);

% Main loop. Add interpolations as long as needed (i.e., there are still
% blank slices in interp. 
while sum(check_interp) ~= size(interp, 3)
    % Find the locations of the first empty slice and the closest non-empty
    % slice after it.
    idx_first_zero = find(~check_interp, 1);
    next_nonzero = find(check_interp(idx_first_zero+1:end), 1);
    idx_next_nonzero = next_nonzero + idx_first_zero;
    
    % Calculate the gap size, or the number of slices between the first
    % empty slice and the closest non-empty slice.
    gap_size = idx_next_nonzero - idx_first_zero;
    
    % Compute the interpolation between the two slices
    albu_out = albuInterpolate(interp(:,:,idx_first_zero-1), ...
        interp(:,:,idx_next_nonzero), opts);
    
    % Next, we need to determine where in the interp stack to append this
    % new interpolation to. There are three cases:
    %   1. If the gap size is one, the interpolation will be put in the 
    %      location of the first empty slice. 
    %   2. If the gap size is greater than one and odd, it will be put in
    %      the middle slice between the first empty slice and the closest
    %      non-empty slice. 
    %   3. If the gap size is even, we need to add a slice halfway between
    %      the first empty slice and the closest non-empty slice. The new
    %      interpolation will be placed here.
    if ~mod(gap_size, 2)
        interp = cat(3, interp(:,:,1:idx_first_zero + gap_size/2 - 1), ...
            albu_out, interp(:,:,idx_first_zero + gap_size/2:end));
        
        idx_add = find(idx_keep >= idx_first_zero + gap_size/2);
        idx_keep(idx_add) = idx_keep(idx_add) + 1;
    elseif mod(gap_size, 2) && gap_size == 1
        interp(:,:,idx_first_zero) = albu_out;
    else
        interp(:,:,idx_first_zero + floor(gap_size / 2)) = albu_out;
    end
    
    % Regenerate the empty slice vector
    check_interp = reshape(sum(any(interp(:,:,:))) > 0, 1, size(interp, 3));
end

% Return only the interpolations necessary
interp = interp(:,:,idx_keep);

end