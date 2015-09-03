function [interp, time] = interp_perim( img1, img2, L, varargin )
% interp_perim
%    Generates evenly distributed, interpolated binary images between two
%    input binary images. This approach is inspired by the morphological
%    skeleton interpolation (MSI) algorithm of Chatzis and Pitas [1]. The
%    input images are simplified by reducing them to their perimeter using
%    the bwperim function. The reduced objects are then registered to each
%    other using the non-rigid registration mode of the coherent point
%    drift (CPD) algorithm of Myronenko and Song [2]. CPD determines the 
%    non-rigid mapping of pixels between the input and output reduced
%    objects, and this correspondence is used to generate evenly spaced,
%    interpolated objects between the two in the interpolation 
%    transformation step.
%
%    Finally, the whole objects are reconstructed from the reduced 
%    simplifications. Reconstruction is performed by first running a
%    gap-filling algorithm to connect all pixels of the interpolated
%    perimeter, then filling the object using imfill(...,'holes').
%
%    Required Inputs
%    ===============
%    img1       Input binary image to interpolate to
%    img2       Input binary images to interpolate from
%    L          Number of interpolated slices to produce between the two
%               input images
%
%    Optional Arguments
%    ==================
%    'reduce'       Percentage to reduce the number of perimeter points by.
%                   This will result in a faster run time.
%                   DEFAULT = 0
%    'compile'      Compiles the CPD code. 1 = run compiling, 0 = do not
%                   run. 
%                   DEFAULT = 1
%    'writeimgs'    Indicates whether or not to write intermediate plots
%                   and figures of the interpolation outputs to disk. This
%                   can be useful for troubleshooting, but probably not
%                   desirable for use with big datasets as it will slow
%                   down run time. 1 = write images, 0 = do not write.
%                   DEFAULT = 0
%    'verbose'      Indicates whether or not to print text pertaining to
%                   the intermediate steps. May slow down run time. 1 =
%                   print all output, 0 = suppress all text output.
%                   DEFAULT = 0
%
%    Output
%    ======
%    interp        Stack of interpolated images between I_A and I_B.
%    time          1x3 vector specifying the runtimes, in seconds, for (1)
%                  object reduction, (2) CPD registration, and (3)
%                  interpolation transformation.
%
%    Example
%    --------------------
%    interp = msi3d_cpd_perim( I1,I2,3,3,0,0,1);    
%
%    Dependencies
%    --------------------
%    [1] Requires the Coherent Point Drift toolbox, available for download 
%    here: https://sites.google.com/site/myronenko/research/cpd
%
%    References
%    --------------------
%    [1] Chatzis and Pitas (2000). Interpolation of 3-D binary images based
%    on morphological skeletonization. IEEE Transactions on Medical
%    Imaging, 19(7):699-710.
%
%    [2] Myronenko and Song (2012). Point Set Registration: Coherent Point
%    Drift. IEEE Transactions on Pattern Analysis and Machine Intelligence,
%    32(12):2262-75.
%

% Parse the optional arguments
defaults = struct('reduce', 0, 'compile', 1, 'writeimgs', 0, 'verbose', 0);
opts = parse_varargin(defaults, varargin);

% Compile CPD, if necessary
if opts.compile; compileCPD; end

% Initialize output matrix
interp = zeros([size(img1) L+2]);
interp(:,:,1) = img1;
interp(:,:,L+2) = img2; 

% Set options for CPD
optscpd.method = 'nonrigid';
optscpd.tol = 1e-4;
optscpd.beta = 1;
optscpd.corresp = 1;
optscpd.viz = 0;

C = 2;

%%%%%%%%%%
%%% (1) Object Reduction
%%%%%%%%%%

% Find number of connected components in input images
CC1 = bwconncomp(img1);
CC2 = bwconncomp(img2);

% Reduce the images to their perimeters
tic;

S1 = bwperim(img1);
S2 = bwperim(img2);

if opts.reduce
    S1 = reduce_perim(S1, opts.reduce);
    S2 = reduce_perim(S2, opts.reduce);
end

runtime_reduce = toc;

%%%%%%%%%%
%%% (2) Perimeter Matching
%%%%%%%%%%

tic; % Start timer for CPD

% Convert from image format to a 3xM array of points, as required for CPD
S1_cpd = im2cpd(S1);
S2_cpd = im2cpd(S2);

% Run Coherent Point Drift Algorithm using rigid point set registration.
% CPD is run to generate the transform from img1 to img2.

fprintf('Running non-rigid CPD registration of A to B.\n');
[Transform_AB, X_AB] = cpd_register(S2_cpd', S1_cpd', optscpd);

runtime_cpd = toc; % End timer for CPD
fprintf('CPD registration done.\n')

%%%%%%%%
% (3) Interpolation Transformation Calculation
%%%%%%%%

% Calculate the transforms in distance, in X and Y, and pixel intensity 
% in Z

tic; % Start timer for interpolation transformation 

for i = 1:numel(X_AB); 
    D_AB(:,i) = S2_cpd(:, X_AB(i)) - S1_cpd(:, i);
end

for l = 1:L
    % Calculate coefficients for matching interpolations to the properly
    % spaced slice. l = [1...L].
    C_AB = l / (L+1);
    fprintf('Transforming interpolation for l = %d, C_AB = %f.\n', ...
        l, C_AB);

    % Scale transforms by the coefficients
    D_AB_scale = C_AB .* D_AB;
    
    % Create new objects
    delta_AB = S1_cpd + D_AB_scale;
    delta_AB(1:2,:) = round(delta_AB(1:2,:));
    S_AB_delta = cpd2im(delta_AB,S1);
    
    %%%%%%%%
    % (4) Object Reconstruction
    %%%%%%%%

    % Reconstruct objects
    O_interp_AB = perimFill(S_AB_delta);
    O_interp_AB = imfill(O_interp_AB,'holes');

    % Check for consistency in connected components. Remove artifacts
    % if necessary.
    CC_AB = bwconncomp(O_interp_AB,4);

    if CC1.NumObjects == CC2.NumObjects
        if CC_AB.NumObjects ~= CC1.NumObjects
            RP_AB = regionprops(O_interp_AB,'Area','PixelIdxList');
            [Sort, Idx] = sort([RP_AB.Area],'descend');
            Remove = Idx(CC1.NumObjects+1:end);
            for q = 1:numel(Remove)
                O_interp_AB(RP_AB(Remove(q)).PixelIdxList) = 0;
            end
        end
    end                     

    %%%%%%%%
    % Store output and set inputs for next iteration
    %%%%%%%%

    interp(:,:,C) = O_interp_AB;
    C = C+1;

    %%%%%%%%
    % (OPTIONAL)
    %%%%%%%%

    if opts.writeimgs
        figure;
        subplot(3,2,1); imshow(S1,[]); title('P_A')
        subplot(3,2,2); imshow(S2,[]); title('P_B')
        subplot(3,2,3); imshow(S_interp_AB,[]); title('P_{AB}')
        subplot(3,2,4); imshow(S_interp_BA,[]); title('P_{BA}')
        subplot(3,2,5); imshow(O_interp_AB,[]); title('O_{AB}')
        subplot(3,2,6); imshow(O_interp_BA,[]); title('O_{BA}');
        figure;
        subplot(2,3,1); imshow(img1,[]);
        subplot(2,3,2); imshow(O_interp_AB,[]);
        subplot(2,3,3); imshow(img2,[]);
        subplot(2,3,4); imshow(img1,[]);
        subplot(2,3,5); imshow(O_interp_BA,[]);
        subplot(2,3,6); imshow(img2,[]);
    end
end

runtime_interpTrx = toc; % End timer for interpolation transformation

interp = uint8(interp);

fprintf('Run time:\n');
fprintf('Image Reduction %f\n',runtime_reduce);
fprintf('CPD Registration %f\n',runtime_cpd);
fprintf('Interpolation Transformation %f\n',runtime_interpTrx);

time = [runtime_reduce runtime_cpd runtime_interpTrx];

end
