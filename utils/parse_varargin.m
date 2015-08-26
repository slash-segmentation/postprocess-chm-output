function opts = parse_varargin(defaults, optargs)
% Parses varargin, sets defaults, and replaces defaults with user-supplied 
% values when appropriate. Returns the optional arguments as a structure.
%
% Required Inputs
% ===============
%     defaults    A structure corresponding to the default arguments. For
%                 example: defaults = struct('name1', val1, 'name2', val2).
%                 The number of fields corresponds to the number of
%                 optional arguments allowed.
%
%     optargs     The optional arguments input. This corresponds to
%                 varargin from the calling function.
%
% Output
% ======
%     opts    Structure containing the final values of all optional
%             arguments
%
% Reference
% =========
% stackoverflow.com/questions/2775263/how-to-deal-with-name-value-pairs-of-
%        function-arguments-in-matlab
%

opts = defaults;
optionNames = fieldnames(opts);

nargs = length(optargs);
if round(nargs/2) ~= nargs/2
    error('Variable arguments need propertyName/propertyValue pairs');
end

for pair = reshape(optargs, 2, [])
    inpName = lower(pair{1});
    if any(strcmp(inpName, optionNames))
        opts.(inpName) = pair{2};
    else
        error('%s is not a recognized parameter name', inpName);
    end
end

end