function interp = albuInterpolate( A, B, opts )
% Generate a binary interpolation between the two input images using the
% algorithm of Albu and colleagues.
%
% Required Inputs
% ===============
%     A        Starting image to begin the interpolation from
%     B        Ending image to interpolate to
%     se       Structuring element to use during conditional dilation
%     opts     Structure with optional argument values generated from the 
%              wrapper function albuRun
%
% Output
% ======
%     interp   A 2D interpolation corresponding to the member of the
%              transition sequence that minimizes distance
%
% Reference
% =========
% Albu, A.B., Beugeling, T., and Laurendeau, D. (2008). A morphology-based
% approach for interslice interpolation of anatomical slices from
% volumetric images. IEEE Transactions in Biomedical Engineering, 55(8), 
% 2022-2038.
%
% See also albuRun, dilatcond, construct_seq, pixelgrid
%

% Get the example images
dimsa = size(A);
dimsb = size(B);

% Compute the intersection between A and B
intersection = A & B;

% Compute the sequence of conditional dilations taking A to B. Flip the
% stack along the Z dimension.
[dca, la] = dilatcond(intersection, A, opts);
dca = flipdim(dca, 3);

% Compute the sequence of conditional dilations taking B to A
[dcb, lb] = dilatcond(intersection, B, opts);

% If la and lb are not equal, pad the output of the conditional dilation
% step that has fewer iterations with zeros.
for ii = 1:abs(lb - la)
    if la > lb
        dcb(:,:,lb+ii) = zeros(dimsb, 'uint8');
    else
        dca(:,:,la+ii) = zeros(dimsa, 'uint8');
    end
end

% Construct the sequence function
seq = construct_seq(dca, dcb, opts);
nseq = size(seq, 3);

% Compute the distance function
dist = zeros(1, nseq);
for ii = 1:nseq
    da = sum(sum((seq(:,:,ii) | A) - (seq(:,:,ii) & A)));
    db = sum(sum((seq(:,:,ii) | B) - (seq(:,:,ii) & B)));
    dist(ii) = abs(da - db);
end

[~, idx] = min(dist);

% Sometimes there will be only two images in seq, and the distances will be
% identical. This happens if the two input images are very similar. In
% these cases, take the second image of seq as the interpolation.
% Otherwise, take the entry of seq that minimizes the distance, as per the
% paper.
if size(seq, 3) == 2 && dist(2) == min(dist)
    interp = seq(:,:,2);
else
    interp = seq(:,:,idx);
end

end