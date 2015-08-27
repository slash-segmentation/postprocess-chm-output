% perimFill
%    Takes a thinned perimeter binary image, finds the pixels belonging to
%    gaps in the perimeter, then fills them such that the perimeter can be
%    properly filled using imfill(...,'holes').
%         
%    Input
%    --------------------
%    Im            Binary perimeter image.
%
%    Output
%    --------------------
%    Out           Filled image.
%
%    Example
%    --------------------
%    P_filled = perimFill(P);
%
%    Dependencies
%    --------------------
%    [1] Peter Kovesi's findendsjunctions.m for detecting the pixels
%    surrounding gaps in the output perimeter map:
%    http://www.csse.uwa.edu.au/~pk/Research/MatlabFns/#edgelink
%    [2] Jing Tian's func_drawLine.m for connecting end pixels:
%    http://www.mathworks.com/matlabcentral/fileexchange/4211-connect-two-pixels
%

function Out = perimFill( Im )

% Bridge gaps that are separated by only one pixel
Im = bwmorph(Im,'bridge');

% Find points where ends occur
[rj,cj,re,ce] = findendsjunctions(Im,0);
re = [re; rj];
ce = [ce; cj];

% Determine the pairs of points in re and ce that constitute both edges of
% a gap. This is done by determining which points are closest to one
% another by minimizing the distance. The gap is then closed by calling 
% func_DrawLine.
while re
    R1 = re(1);
    C1 = ce(1);
    d = [];
    for i = 1:numel(re)
        d(i) = sqrt((R1-re(i))^2 + (C1-ce(i))^2);
    end
    d(1) = Inf;
    [Min Idx] = min(d);
    Im = func_DrawLine(Im,R1,C1,re(Idx),ce(Idx),1);
    re(Idx) = []; re(1) = []; %Remove points from future consideration
    ce(Idx) = []; ce(1) = []; 
end   

Out = Im;

end