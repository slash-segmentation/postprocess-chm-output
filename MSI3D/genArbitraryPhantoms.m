function [I1,I2] = genArbitraryPhantoms( Im_string,scale1,scale2,t1,t2,ang1,ang2 );
% genArbitraryPhantoms
%    Takes a binary image as input, then creates two phantoms of this image
%    that are scaled, translated, and rotated by the specified parameters.
%     
%    Input
%    --------------------
%    Im_string       String specifying the path of the binary image to be
%                    loaded and made into phantoms.
%    scale1,scale2   Factor by which to scale the two phantoms with respect
%                    to the input image.
%    t1,t2           1x2 vectors specifying the X and Y translations for
%                    the phantoms. I.E.: t1 = [tx ty].
%    ang1,ang2       Angle, in degrees, to rotate the phantoms about the XY
%                    axis.
%
%    Output
%    --------------------
%    I1,I2         Output images 
%
%    Example
%    --------------------
%    [I1, I2] = genArbitraryPhantoms('nucleus.0100.tif',1,0.5,[200 100],[0 0],0,30)
%
%    Dependencies
%    --------------------
%    Requires Jan Motl's rotateAround.m from the Mathworks File Exchange:
%    http://www.mathworks.com/matlabcentral/fileexchange/40469-rotate-an-image-about-a-point

if nargin < 7; ang2 = 0; end
if nargin < 6; ang1 = 0; end
if nargin < 5; t2 = [0 0]; end
if nargin < 4; t1 = [0 0]; end
if nargin < 3; scale2 = 1; end
if nargin < 2; scale1 = 1; end

Im = imread(Im_string);

% Crop input image to be tight around the binary blob
RP = regionprops(Im,'BoundingBox');
BB = RP.BoundingBox;
BB(1:2) = floor(BB(1:2));
BB(3:4) = ceil(BB(3:4));
Im = Im(BB(2):BB(2)+BB(4),BB(1):BB(1)+BB(3));

% Scale image
I1 = imresize(Im,scale1);
I2 = imresize(Im,scale2);

[Y1 X1] = size(I1);
[Y2 X2] = size(I2);
[MaxY IdxMaxY] = max([Y1 Y2]);
[MaxX] = max([X1 X2]);

% Pad the smaller image to be the same size as the larger image,
% post-scaling.
if scale1 ~= scale2 & IdxMaxY == 1
    I2 = padarray(I2,[ceil((MaxY-Y2)/2) ceil((MaxX-X2)/2)],0,'both');
    if mod((MaxY-Y2),2) == 1; I1 = padarray(I1,[1 0],0,'post'); end
    if mod((MaxX-X2),2) == 1; I1 = padarray(I1,[0 1],0,'post'); end
elseif scale1 ~= scale2 & IdxMaxY == 2
    I1 = padarray(I1,[ceil((MaxY-Y1)/2) ceil((MaxX-X1)/2)],0,'both');
    if mod((MaxY-Y1),2) == 1; I2 = padarray(I2,[1 0],0,'post'); end
    if mod((MaxX-X1),2) == 1; I2 = padarray(I2,[0 1],0,'post'); end
end

% Pad again to account for translations
Max = max([t1 t2]);
I1 = padarray(I1,[Max+round(MaxY/2) Max+round(MaxX/2)],0,'both');
I2 = padarray(I2,[Max+round(MaxY/2) Max+round(MaxX/2)],0,'both');

% Translate
I1 = arbTranslate(I1,t1(1),t1(2));
I2 = arbTranslate(I2,t2(1),t2(2));

% Rotate
RP_I1 = regionprops(I1,'Centroid');
RP_I2 = regionprops(I2,'Centroid');
I1 = rotateAround(I1,RP_I1.Centroid(2),RP_I1.Centroid(1),ang1);
I2 = rotateAround(I2,RP_I2.Centroid(2),RP_I2.Centroid(1),ang2);

figure; imshow(I1,[])
figure; imshow(I2,[])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Im_out = arbTranslate( Im_in, dC, dR )
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

