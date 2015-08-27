% msi3d_dce_cpd
%    Generates evenly distributed, interpolated binary images between two
%    input binary images. This approach is inspired by the morphological
%    skeleton interpolation (MSI) algorithm of Chatzis and Pitas [1].
%    Depending on the mode specified, the input images are simplified by
%    reducing them to their skeleton or perimeter. Distance transform-based
%    skeletonization is performed using the discrete curve evolution (DCE)
%    algorithm of Bai, et al [2], and perimeterization is performed using
%    bwperim. The reduced objects are registered to each other using the 
%    non-rigid registration mode of the coherent point drift (CPD) 
%    algorithm of Myronenko and Song [3]. CPD determines the non-rigid 
%    mapping of pixels between the input and output reduced objects, and 
%    this correspondence is used to generate evenly spaced, interpolated 
%    objects between the two in the interpolation transformation step. 
%    Finally, the whole objects are reconstructed from the reduced 
%    simplifications. In the case of reduction by skeletonization, 
%    reconstruction is performed by creating the union of all circles 
%    centered at each pixel of the skeleton, with each pixel value 
%    specifying the radius of the given circle. In the case of reduction by
%    perimeterization, reconstruction is performed by first running a
%    gap-filling algorithm to connect all pixels of the interpolated
%    perimeter, then filling the object using imfill(...,'holes').
%
%    Input
%    --------------------
%    I_A,I_B       Input binary images to interpolate between.
%    L0            Number of interpolated slices to produce between the two
%                  input images.
%    mode          = 1, aligns the skeletons of the images. Skeletons are
%                    generated using the DCE algorithm of Bai, et al.
%                  = 2, aligns the perimeters of the images.
%    image         = 1, will write intermediate plots and figures to disk.
%                  = 0, will not save any intermediate images.
%    verbose       = 1, will print text pertaining to intermediate steps.
%                  = 0, will not print any text.
%    compile       = 1, will compile CPD code. = 0, will not compile,
%                  assuming code has been previously compiled.
%
%    Output
%    --------------------
%    Out           Stack of interpolated images between I_A and I_B.
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
%    [2] Requires the Matlab code for the DCE algorithms for skeleton
%    generation, available for download here:
%    https://sites.google.com/site/xiangbai/softwareforskeletonizationandskeletonpru
%    NOTE: For compatibility with MATLAB R2013a, add the following between
%    lines 41 and 42 in the file SkeletonGrow1.m:
%         lab = single(lab);
%
%    References
%    --------------------
%    [1] Chatzis and Pitas (2000). Interpolation of 3-D binary images based
%    on morphological skeletonization. IEEE Transactions on Medical
%    Imaging, 19(7):699-710.
%
%    [2] Bai, Latecki, and Liu (2007). Skeleton pruning by contour
%    partitioning with discrete curve evolution. IEEE Transactions on
%    Pattern Analysis and Machine Intelligence. 29(3):1-14.
%
%    [3] Myronenko and Song (2012). Point Set Registration: Coherent Point
%    Drift. IEEE Transactions on Pattern Analysis and Machine Intelligence,
%    32(12):2262-75.
%
%

function [Out,time,ratio] = msi3d_dce_cpd( I_A, I_B, L, mode, image, verbose, compile )

if nargin < 7; compile = 1; end
if nargin < 6; verbose = 0; end
if nargin < 5; image = 0; end
if nargin < 4; mode = 1; end %Default is to align the skeletons

% Add needed paths for CPD and compile
if compile == 1; compileCPD; end

% Initialize output matrix
Out = zeros([size(I_A),L+2]);
Out(:,:,1) = I_A;
Out(:,:,L+2) = I_B; 

% Set options for CPD
opt.method = 'nonrigid';
opt.tol = 1e-4;
opt.beta = 1;
opt.corresp = 1;
opt.viz = 0;

C = 2;

%%%%%%%%%%
%%% (1) Object Reduction
%%%%%%%%%%

% Find number of connected components in input images
CC_A = bwconncomp(I_A);
CC_B = bwconncomp(I_B);

tic; % Start timer for object reduction

if mode == 1  
    % Create skeleton images of both input images by using DCE
    S_A = div_skeleton_new(4,1,~I_A,15);
    fprintf('Skeletonization of Image A done.\n');

    S_B = div_skeleton_new(4,1,~I_B,15);
    fprintf('Skeletonization of Image B done.\n');
else
    S_A = bwperim(I_A);
    fprintf('Perimeterization of Image A done.\n');
    S_B = bwperim(I_B);
    fprintf('Perimeterization of Image B done.\n');
end
    
runtime_reduce = toc; % End timer for DCE skeletonization

A_A = numel(find(I_A > 0));
A_SA = numel(find(S_A > 0));
ratio(1) = A_SA/A_A;
fprintf('Image A contains %d points.\n',A_A);
fprintf('Reduction A contains %d points.\n',A_SA);
fprintf('Reduction : Image Ratio A = %f\n',ratio(1));

A_B = numel(find(I_B > 0));
A_SB = numel(find(S_B > 0));
ratio(2) = A_SB/A_B;
fprintf('Image B contains %d points.\n',A_B);
fprintf('Reduction B contains %d points.\n',A_SB);
fprintf('Reduction : Image Ratio B = %f\n',ratio(2));

%%%%%%%%%%
%%% (2) Skeleton Matching
%%%%%%%%%%

tic; % Start timer for CPD

% Convert from image format to a 3xM array of points, as required for CPD
S_A_cpd = im2cpd(S_A);
S_B_cpd = im2cpd(S_B);

% Run Coherent Point Drift Algorithm using rigid point set registration.
% CPD is run to generate transforms in both directions: (1) From I_A to
% I_B, and (2) from I_B to I_A.

fprintf('Running non-rigid CPD registration of A to B.\n');
[Transform_AB,X_AB] = cpd_register(S_B_cpd',S_A_cpd',opt);

runtime_cpd = toc; % End timer for CPD
fprintf('CPD registration done.\n')

%%%%%%%%
% (3) Interpolation Transformation Calculation
%%%%%%%%

% Calculate the transforms in distance, in X and Y, and pixel intensity 
% in Z to apply to the original skeleton to match the destination
% skeleton

tic; % Start timer for interpolation transformation 

clear D_AB
for i = 1:numel(X_AB); D_AB(:,i) = S_B_cpd(:,X_AB(i)) - S_A_cpd(:,i); end

for l = 1:L

    % Calculate coefficients for matching interpolations to the properly spaced
    % slice. l = [1...L].
    C_AB = l / (L+1);
    fprintf('Transforming interpolation for l = %d, C_AB = %f.\n',l,C_AB);

    % Scale transforms by the coefficients
    D_AB_scale = C_AB .* D_AB;
    
    % Create new objects
    delta_AB = S_A_cpd + D_AB_scale;
    delta_AB(1:2,:) = round(delta_AB(1:2,:));
    S_AB_delta = cpd2im(delta_AB,S_A);
    
    %%%%%%%%
    % (4) Object Reconstruction
    %%%%%%%%

    % Reconstruct objects
    if mode == 1
        O_interp_AB = skel2obj(S_AB_delta,2);
        O_interp_AB = bwmorph(O_interp_AB,'spur');
        O_interp_AB = bwmorph(O_interp_AB,'hbreak');     
    else
        O_interp_AB = perimFill(S_AB_delta);
        O_interp_AB = imfill(O_interp_AB,'holes');
    end

    % Check for consistency in connected components. Remove artifacts
    % if necessary.
    CC_AB = bwconncomp(O_interp_AB,4);

    if CC_A.NumObjects == CC_B.NumObjects
        if CC_AB.NumObjects ~= CC_A.NumObjects
            RP_AB = regionprops(O_interp_AB,'Area','PixelIdxList');
            [Sort,Idx] = sort([RP_AB.Area],'descend');
            Remove = Idx(CC_A.NumObjects+1:end);
            for q = 1:numel(Remove)
                O_interp_AB(RP_AB(Remove(q)).PixelIdxList) = 0;
            end
        end
    end                     

    %%%%%%%%
    % Store output and set inputs for next iteration
    %%%%%%%%

    Out(:,:,C) = O_interp_AB;
    C = C+1;

    %%%%%%%%
    % (OPTIONAL)
    %%%%%%%%

    if image == 1
        figure;
        subplot(3,2,1); imshow(S_A,[]); title('P_A')
        subplot(3,2,2); imshow(S_B,[]); title('P_B')
        subplot(3,2,3); imshow(S_interp_AB,[]); title('P_{AB}')
        subplot(3,2,4); imshow(S_interp_BA,[]); title('P_{BA}')
        subplot(3,2,5); imshow(O_interp_AB,[]); title('O_{AB}')
        subplot(3,2,6); imshow(O_interp_BA,[]); title('O_{BA}');
        figure;
        subplot(2,3,1); imshow(I_A,[]);
        subplot(2,3,2); imshow(O_interp_AB,[]);
        subplot(2,3,3); imshow(I_B,[]);
        subplot(2,3,4); imshow(I_A,[]);
        subplot(2,3,5); imshow(O_interp_BA,[]);
        subplot(2,3,6); imshow(I_B,[]);
    end
end

runtime_interpTrx = toc; % End timer for interpolation transformation

Out = uint8(Out);

fprintf('Run time:\n');
fprintf('Image Reduction %f\n',runtime_reduce);
fprintf('CPD Registration %f\n',runtime_cpd);
fprintf('Interpolation Transformation %f\n',runtime_interpTrx);

time = [runtime_reduce runtime_cpd runtime_interpTrx];

end
