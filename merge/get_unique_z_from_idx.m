function [zunique, idx_missing] = get_unique_z_from_idx( dims, idx, ...
    runmissing )

[~, ~, z] = ind2sub(dims, idx);
zunique = unique(z);
idx_missing = [];

if runmissing
    delta = diff(zunique);
    idx_missing = find(delta > 1);    
end

end