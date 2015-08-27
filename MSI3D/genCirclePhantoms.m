function [ I1, I2 ] = genCirclePhantoms(R1,R2,t1,t2)
% genCirclePhantoms
%  Generates a pair of binary images that are circularphantoms of specified 
%  radius and translation from the image center.
%     
%    Input
%    --------------------
%    R1,R2         Radii of  the circles in pixels
%    t1,t2         1x2 vectors specifying the X and Y translations for
%                  the circles. I.E.: t1 = [tx ty].
%
%    Output
%    --------------------
%    I1,I2         Output images 
%
%    Example
%    --------------------
%    [I1, I2] = genCirclePhantoms(80,40,[20 10],[0 0])
if nargin < 4; t2 = [0 0]; end
if nargin < 3; t1 = [0 0]; end
if nargin < 2; error('Must specify at least two circle radii.'); end

% Calculate amount to pad each image based on input parameters
Max_tx = max(abs([t1 t2]));
Max_r  = max([R1 R2]);
Pad = round((Max_tx + Max_r)/2);

% Initialize circles
I1 = fspecial('disk',R1); I1 = (I1 > 0);
I2 = fspecial('disk',R2); I2 = (I2 > 0);

% Make each image the same size by padding with zeros
I1 = padarray(I1,[R2+Pad R2+Pad],0,'both');
I2 = padarray(I2,[R1+Pad R1+Pad],0,'both');

% Translate circles
I1 = circTranslate(I1,t1(1),t1(2));
I2 = circTranslate(I2,t2(1),t2(2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Im_out = circTranslate( Im_in, dC, dR )
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