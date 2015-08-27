function compileCPD
% compileCPD
%    Adds the appropriate paths and compiles the CPD package.

addpath C:\Users\Alex\Documents\NCMIR\Experiments\MSI3D\nucleolus_test\keep\CPD2\core
addpath C:\Users\Alex\Documents\NCMIR\Experiments\MSI3D\nucleolus_test\keep\CPD2\core\utils
addpath C:\Users\Alex\Documents\NCMIR\Experiments\MSI3D\nucleolus_test\keep\CPD2\core\Rigid
addpath C:\Users\Alex\Documents\NCMIR\Experiments\MSI3D\nucleolus_test\keep\CPD2\core\Nonrigid
addpath C:\Users\Alex\Documents\NCMIR\Experiments\MSI3D\nucleolus_test\keep\CPD2\core\mex
addpath C:\Users\Alex\Documents\NCMIR\Experiments\MSI3D\nucleolus_test\keep\CPD2\core\FGT
cpd_make;

end