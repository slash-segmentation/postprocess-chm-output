function compileCPD
% compileCPD
%    Adds the appropriate paths and compiles the CPD package.

addpath 'CPD/core' 'CPD/core/utils' 'CPD/core/Rigid' 'CPD/core/Nonrigid' 'CPD/core/mex' 'CPD/core/FGT'
cpd_make;

end
