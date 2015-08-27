function [img1, img2] = get_interp_keyframes( dims, idx, Z1, Z2 )

[r, c, z] = ind2sub(dims, idx);

idx1 = find(z == Z1);
idx2 = find(z == Z2);

% Get initial positions
r1 = r(idx1);
c1 = c(idx1);
r2 = r(idx2);
c2 = c(idx2);
clear r c z

% Get boundings boxes
bb1 = [min(r1) max(r1) min(c1) max(c1)];
bb2 = [min(r2) max(r2) min(c2) max(c2)];

% Get the bounding box required to contain both images
bbt = [min(bb1(1), bb2(1)), max(bb1(2), bb2(2)), min(bb1(3), bb2(3)), ...
    max(bb1(4), bb2(4))];

dimr = bbt(2) - bbt(1) + 1;
dimc = bbt(4) - bbt(3) + 1;

% Update positions
r1 = r1 - bbt(1) + 1;
r2 = r2 - bbt(1) + 1;
c1 = c1 - bbt(3) + 1;
c2 = c2 - bbt(3) + 1; 

% Initialize empty images
img1 = zeros(dimr, dimc, 'uint8');
img2 = img1;

% Convert subscript locations to indices
idx1 = sub2ind([dimr dimc], r1, c1);
idx2 = sub2ind([dimr dimc], r2, c2);

img1(idx1) = 1;
img2(idx2) = 1;


end