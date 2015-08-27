function merge = findMerges( N, cc, objects, opts )
%
%
%
%

% Get the Z values for every pixel index in the given object
[~, ~, z] = ind2sub(opts.stackdims, cc.PixelIdxList{N});

% Get the indices that correspond to the pixels on the maximum slice
vals = (z == cc.zmax(N));
idx = cc.PixelIdxList{N}(vals);
area = numel(idx);

% Loop over all values of skip, from one to the max

toggle = 0;
for ii = 1:opts.skip
                  
    % Determine which pixel indices on the above slice to test for
    idxskip = bsxfun(@plus, idx, opts.idxPerSlice * (ii+1));
    idxskip = reshape(idxskip, numel(idxskip), 1); %May no longer be necessary
    idxskip = idxskip(idxskip < opts.idxMax); %Remove any invalid indices
        
    % Determine how many pixels in idxskip overlap with the actual
    % segmentation
    overlap = sum(opts.stack(idxskip));
    overlap_percent = 100 * (overlap / area);
    fprintf('Skip: %d, Area: %d, Overlap Area: %d, Percent Overlap: %0.2f\n', ...
        ii, area, overlap, overlap_percent);
        
    % If there is some overlap AND this overlap is greater than the
    % threshold percentage specified, merge the objects together. 
    if overlap && overlap_percent > opts.percent
        toggle = 1;
            
        % Find the pixel indices that correspond to the overlap between
        % idxskip and the segmentation
        idxmerge = opts.stack(idxskip) == 1;
        idxmerge = idxskip(idxmerge);
            
        % Next, we need to determine the object number that will be
        % merged into object ii. To do this, we will look in all
        % objects that have values on the given slice. These are stored
        % in the structure slices.
        searchStr = ['z' sprintf('%04d', cc.zmax(N) + ii + 1)];
        searchObjects = objects.(searchStr);
            
        % Loop over each object in searchObjects. Determine if its
        % pixel indices overlap with those corresponding to the
        % overlapping region (idxmerge).
        for kk = 1:numel(searchObjects)
            obj_kk = searchObjects(kk);
            overlap_kk = sum(ismember(cc.PixelIdxList{obj_kk}, idxmerge));
            if overlap_kk
                fprintf('Merge found: %d\n', obj_kk);
                
                % Merge the PixelIdxList entries for the two objects
                cc.PixelIdxList{ii} = [cc.PixelIdxList{ii}; 
                    cc.PixelIdxList{obj_kk}];
                cc.PixelIdxList{obj_kk} = [];
                break
            end
        end
    end
        
    % If a merge is found, stop looking across additional slices
    if toggle; break; end

end

if toggle
    merge = obj_kk;
else
    merge = 0;
end
            
end