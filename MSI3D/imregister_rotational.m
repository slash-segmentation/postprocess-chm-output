% imregister_rotational
%    Determines the angle of rotation in the XY plane that puts 2D binary
%    images in register. Angle of rotation is determined by using the CPD 
%    algorithm with rigid transformations [1]. Rotation angles are defined as 
%    positive in the counter-clockwise direction.
%         
%    Input
%    --------------------
%    Im1           Binary image to match.
%    Im2           Binary image to determine the rotation for, with respect
%                  to Im1.
%    compile       = 1, will compile CPD code. = 0, will not compile,
%                  assuming code has been previously compiled.
%
%    Output
%    --------------------
%    thetaZ_deg    Rotation angle from Im2 -> Im2, in degrees about the XY
%                  plane.
%
%    Example
%    --------------------
%    theta = imregister_rotational(Imatch,Irotate,1);
%
%    Dependencies
%    --------------------
%    Requires the Coherent Point Drift toolbox, available for download here:
%    https://sites.google.com/site/myronenko/research/cpd
%
%    References
%    --------------------
%    [1] Myronenko and Song (2012). Point Set Registration: Coherent Point
%    Drift. IEEE Transactions on Pattern Analysis and Machine Intelligence,
%    32(12):2262-75.
%

function thetaZ_deg = imregister_rotation( Im1,Im2,compile )

if nargin == 2; compile = 1; end

if compile == 1;
    addpath /home/aperez/CPD2/core
    addpath /home/aperez/CPD2/core/utils
    addpath /home/aperez/CPD2/core/Rigid
    addpath /home/aperez/CPD2/core/Nonrigid
    addpath /home/aperez/CPD2/core/mex
    addpath /home/aperez/CPD2/core/FGT
    cpd_make;
end

S_A = skeletonization_dt( Im1 );
S_B = skeletonization_dt( Im2 );
S_A_icp = im2cpd(S_A);
S_B_icp = im2cpd(S_B);

opt.method = 'rigid';
opt.viz = 0;
Transform_AB = cpd_register(S_B_icp',S_A_icp',opt);

thetaZ = atan2(Transform_AB.R(2,1),Transform_AB.R(1,1));
thetaZ_deg = thetaZ*180/pi;

end