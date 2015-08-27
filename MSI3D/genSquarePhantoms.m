function [ I1, I2 ] = genSquarePhantoms(S1,S2,t1,t2,ang1,ang2)
% genSquarePhantoms
%    Generates a pair of binary images that are square phantoms of 
%    specified size, XY rotation, and translation from the image center.
%     
%    Input
%    --------------------
%    S1,S2         Length of the squares in pixels.
%    t1,t2         1x2 vectors specifying the X and Y translations for
%                  the squares. I.E.: t1 = [tx ty].
%    ang1,ang2     Angle, in degrees, to rotate the squares about the XY
%                  axis.
%
%    Output
%    --------------------
%    I1,I2         Output images 
%
%    Example
%    --------------------
%    [I1, I2] = genSquarePhantoms(80,40,[20 10],[0 0],0,30)
%
%    Dependencies
%    --------------------
%    Requires Jan Motl's rotateAround.m from the Mathworks File Exchange:
%    http://www.mathworks.com/matlabcentral/fileexchange/40469-rotate-an-image-about-a-point

if nargin < 6; ang2 = 0; end
if nargin < 5; ang1 = 0; end
if nargin < 4; t2 = [0 0]; end
if nargin < 3; t1 = [0 0]; end
if nargin < 2; error('Must specify at least two square sizes.'); end

% Calculate amount to pad each image based on input parameters
Max_tx = max(abs([t1 t2]));
Max_r  = max([S1 S2]);
Pad = round((Max_tx + Max_r));

% Initialize squares
I1 = ones(S1,S1);
I2 = ones(S2,S2);

% Make each image the same size by padding with zeros
Max = abs(max([S1 S2]));

I1 = padarray(I1,[ceil((Max - S1)/2)+Pad ceil((Max - S1)/2)+Pad],0,'both');
I2 = padarray(I2,[ceil((Max - S2)/2)+Pad ceil((Max - S2)/2)+Pad],0,'both');
if mod((Max - S1),2) ~= 0; I2 = padarray(I2,[1 1],0,'post'); end
if mod((Max - S2),2) ~= 0; I1 = padarray(I1,[1 1],0,'post'); end

% Translate squares
I1 = sqTranslate(I1,t1(1),t1(2));
I2 = sqTranslate(I2,t2(1),t2(2));

% Rotate squares. Rotation is performed about the centroid of each square
% using rotateAround.m.
RP_I1 = regionprops(I1,'Centroid');
RP_I2 = regionprops(I2,'Centroid');
I1 = rotateAround(I1,RP_I1.Centroid(2),RP_I1.Centroid(1),ang1);
I2 = rotateAround(I2,RP_I2.Centroid(2),RP_I2.Centroid(1),ang2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Im_out = sqTranslate( Im_in, dC, dR )
    tx = maketform('affine',[1 0; 0 1; dC dR]);
    [SX SY] = size(Im_in);
    bounds = findbounds(tx,[1 1; size(Im_in)]);
    bounds(1,:) = [1 1];
    Im_out = imtransform(Im_in,tx,'XData',bounds(:,2)','YData',bounds(:,1)');
    Min = min([dC dR]);
    if Min < 0
        Im_out = padarray(Im_out,[abs(Min) abs(Min)],0,'post');
    end
    Im_out = Im_out(1:SX,1:SY);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
