function [opts, cc] = run_postprocessing( path_seg, varargin )

addpath(

% Parse the optional arguments
defaults = struct('runmerge', 1, 'runinterp', 1, 'skip', 0, 'percent', ...
    0, 'filtsize2D', 1, 'se', ones(3,3));
opts = parse_varargin(defaults, varargin);

% Check if the input path exists
if ~isequal(exist(path_seg), 7)
    error('The input path %s does not exist', path_seg);
end

% Find TIF or PNG files in the input path, path_seg
files_seg = dir(fullfile(path_seg, '*.png'));
if isempty(files_seg); files_seg = dir(fullfile(path_seg, '*.tif')); end
nimgs = numel(files_seg);

% Check that the input path contains image files
if ~nimgs
    error('The input path %s does not contain any image files', path_seg);
end

% Read the first file to get its size. Store some pertinent values to the
% opts structure
seg_tmp = imread(fullfile(path_seg, files_seg(1).name));
opts.stackdims = [size(seg_tmp) nimgs];
opts.idxMax = prod(opts.stackdims);
opts.idxPerSlice = prod(opts.stackdims(1:2));
clear seg_tmp

% Initialize an empty array to load images into
fprintf('Initializing an empty stack of size %d x %d x %d.\n', ...
    opts.stackdims(1), opts.stackdims(2), opts.stackdims(3));
opts.stack = zeros(opts.stackdims, 'uint8');
memUsageStack = ByteSize(opts.stack);
fprintf('Stack memory usage: %s\n', memUsageStack);

% Load the segmentations into the initialized array. 
for ii = 1:nimgs
    fname = fullfile(path_seg, files_seg(ii).name);
    fprintf('Reading image %s\n', fname);
    opts.stack(:,:,ii) = imread(fname);
    if opts.filtsize2D == 1    
        opts.stack(:,:,ii) = bwmorph(opts.stack(:,:,ii), 'clean');
    elseif opts.filtsize2D > 1
        opts.stack(:,:,ii) = bwareaopen(opts.stack(:,:,ii, ...
            opts.filtsize2D));
    end
end

% Compute the 3D connected components in the stack
tic;
fprintf('Computing 3D connected components. ')
cc = bwconncomp(opts.stack);
fprintf('DONE! Elapsed time: %0.2f seconds\n', toc);
fprintf('Connected components found: %d.\n', cc.NumObjects)
memUsageCC = ByteSize(cc);
fprintf('Connected components memory usage: %s\n', memUsageCC);

% Run steps
if opts.runmerge
    cc = merge_cc_across_gaps(cc, opts); 
end

if opts.runinterp
  for ii = 1: cc.NumObjects
      [zunique, idx_missing] = get_unique_z_from_idx(opts.stackdims, ...
          cc.PixelIdxList{ii}, 1);
      while idx_missing
          zframe1 = zunique(idx_missing(1));
          zframe2 = zunique(idx_missing(1)+1);
          [img1, img2] = get_interp_keyframes(opts.stackdims, ...
              cc.PixelIdxList{ii}, zframe1, zframe2);
          interp = albuRun(img1, img2, zframe2 - zframe1 - 1);
          idx_missing(1) = [];
      end
  end
      
end



end
