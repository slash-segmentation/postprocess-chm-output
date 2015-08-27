% msi3d_cpd_perim
%    Generates evenly distributed, interpolated binary images between two
%    input binary images. This is an implementation of the morphological
%    skeleton interpolation (MSI) algorithm of Chatzis and Pitas [1].
%    Skeleton images are registered using the coherent point drift (CPD)
%    algorithm of Myronenko and Song [2]. The output transforms from CPD
%    are modified to enable rotation in only the xy-plane and translations
%    in all three directions, (x,y,r).
%         
%    Input
%    --------------------
%    I_A,I_B       Input binary images to interpolate between.
%    L0            Number of interpolated slices to produce between the two
%                  input images.
%    mode          = 1, continuous
%                  = 2, semi-continuous
%                  = 3, iterative
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
%
%    Example
%    --------------------
%    interp = msi3d_cpd_perim( I1,I2,3,3,0,0,1);    
%
%    Dependencies
%    --------------------
%    Requires the Coherent Point Drift toolbox, available for download here:
%    https://sites.google.com/site/myronenko/research/cpd
%
%    References
%    --------------------
%    [1] Chatzis and Pitas (2000). Interpolation of 3-D binary images based
%    on morphological skeletonization. IEEE Transactions on Medical
%    Imaging, 19(7):699-710.
%    [2] Myronenko and Song (2012). Point Set Registration: Coherent Point
%    Drift. IEEE Transactions on Pattern Analysis and Machine Intelligence,
%    32(12):2262-75.
%

function [O_interp_AB,O_interp_BA,Out] = msi3d_cpd( I_A, I_B, L0, mode, image, verbose, compile )

if nargin < 7; compile = 1; end
if nargin < 6; verbose = 0; end
if nargin < 5; image = 0; end
if nargin < 4; mode = 1; end % Default mode = continuous

% Add needed paths for CPD and compile
if compile == 1; compileCPD; end

% Initialize output matrix
Out = zeros([size(I_A),L0+2]);
Out(:,:,1) = I_A;
Out(:,:,L0+2) = I_B; 

% Set variables for the run depending on the mode selected
if mode < 3
    N_iter = 1;
    L = L0 * ones(1,L0)
    l_AB = [1:L0]
    l_BA = l_AB
    K = L0;
else
    N_iter = round(L0/2);
    L = [L0:-2:1]
    l_AB = ones(1,N_iter)
    l_BA = L
    D = L0+1;
    K = 1;
end

C = 2;

for iter = 1:N_iter

    %%%%%%%%%%
    %%% (1) Object Perimeterization
    %%%%%%%%%%

    % Create perimeter images of both input images
    P_A = bwperim( I_A );
    P_B = bwperim( I_B );

    %%%%%%%%%%
    %%% (2) Perimeter Matching
    %%%%%%%%%%

    % Convert from image format to a 3xM array of points, as required for CPD
    P_A_cpd = im2cpd(P_A);
    P_B_cpd = im2cpd(P_B);

    % Run Coherent Point Drift Algorithm using rigid point set registration.
    % CPD is run to generate transforms in both directions: (1) From I_A to
    % I_B, and (2) from I_B to I_A.
    opt.method = 'rigid';
    opt.viz = 0;
    Transform_AB = cpd_register(P_B_cpd',P_A_cpd',opt)
    Transform_BA = cpd_register(P_A_cpd',P_B_cpd',opt);
    
    % Determine thetaZ from the output rotation matrices for each transform.
    % Then construct a rotation matrix, R, for each transform with only
    % this angle, thereby restricting rotation to the xy-plane.
    thetaZ_AB = atan2(Transform_AB.R(2,1),Transform_AB.R(1,1));
    thetaZ_BA = atan2(Transform_BA.R(2,1),Transform_BA.R(1,1));
    R_xy_AB = [cos(thetaZ_AB) -sin(thetaZ_AB) 0; sin(thetaZ_AB) cos(thetaZ_AB) 0; 0 0 1];
    R_xy_BA = [cos(thetaZ_BA) -sin(thetaZ_BA) 0; sin(thetaZ_BA) cos(thetaZ_BA) 0; 0 0 1];

    %%%%%%%%%%
    %%% (3) Interpolation Transformation Calculation
    %%%%%%%%%%

    for k = 1:K
        
        if mode < 3; m = k; end
        if mode == 3; m = iter; end

        % Calculate coefficients for matching interpolations to the properly spaced
        % slice. l = [1...L].
        Li = L(m);
        C_AB = (l_AB(m)/(Li+1));
        C_BA = ((Li+1-l_BA(m))/(Li+1));

        % Compute the skeletons obtained by applying the transformations in the
        % A-to-B and B-to-A directions. 
        rigid_AB = R_xy_AB*(Transform_AB.s.*P_A_cpd) + repmat(Transform_AB.t,1,length(P_A_cpd));
        rigid_BA = R_xy_BA*(Transform_BA.s.*P_B_cpd) + repmat(Transform_BA.t,1,length(P_B_cpd));
        P_rigid_AB = cpd2im(rigid_AB,P_A);
        P_rigid_BA = cpd2im(rigid_BA,P_B);

        %%%%%%%%%%
        %%% (4) Perimeter Modification
        %%%%%%%%%%

        % Calculate the translations between the interpolated skeleton and the
        % original skeleton in the x, y, and r directions.
        d_rigid_AB = C_AB.*(rigid_AB - P_A_cpd);
        d_rigid_BA = C_BA.*(rigid_BA - P_B_cpd);
        interp_AB = P_A_cpd + d_rigid_AB;
        interp_BA = P_B_cpd + d_rigid_BA;

        
        %%%%%%%%%%
        %%% (5) Perimeter Filling
        %%%%%%%%%%
        % Convert to binary images
        P_interp_AB = cpd2im(interp_AB,P_A);
        P_interp_BA = cpd2im(interp_BA,P_B);
        
        % Fill gaps in perimeter images
        O_interp_AB = perimFill(P_interp_AB);
        O_interp_BA = perimFill(P_interp_BA);
        O_interp_AB = imfill(O_interp_AB,'holes');
        O_interp_BA = imfill(O_interp_BA,'holes');

        figure;
        subplot(1,2,1); imshow(O_interp_AB,[]);
        subplot(1,2,2); imshow(O_interp_BA,[]);

        %%%%%%%%%%
        %%% Store output and set inputs for next iteration
        %%%%%%%%%%

        if mode == 1
            Out(:,:,C) = O_interp_AB;
        elseif mode == 2
            if l_AB(m) <= round(L0/2)
                Out(:,:,C) = O_interp_AB;
            else
                Out(:,:,C) = O_interp_BA;
            end
        elseif mode == 3
            if L(iter) >= 2
                Out(:,:,C) = O_interp_AB;
                Out(:,:,D) = O_interp_BA;
            else
                Out(:,:,C) = O_interp_AB;
            end
            D = D-1;
            I_A = O_interp_AB;
            I_B = O_interp_BA;
        end
        
        C = C+1;

        %%%%%%%%%%
        %%% (OPTIONAL) Print and/or write outputs
        %%%%%%%%%%

        if image == 1
            figure;
            subplot(3,2,1); imshow(P_A,[]); title('P_A')
            subplot(3,2,2); imshow(P_B,[]); title('P_B')
            subplot(3,2,3); imshow(P_interp_AB,[]); title('P_{AB}')
            subplot(3,2,4); imshow(P_interp_BA,[]); title('P_{BA}')
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
end

Out = uint8(Out);

end
