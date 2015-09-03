function img_out = reduce_perim(img_in, percent)

if ~percent
    interval = 1;
else
    interval = floor(100 / (100 - percent));
end

bound = bwboundaries(img_in, 8);
bound = bound{1};

idx = sub2ind(size(img_in), bound(:,1), bound(:,2));

% Reduce the pixels in the image
idx = idx(1:interval:end);

% Create image
img_out = zeros(size(img_in), 'uint8');
img_out(idx) = 1;

end