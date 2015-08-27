function Im_out = cpd2im( cpd_mat,Im )
% cpd2im
%    Converts from the 3xM indexed representation needed by the CPD
%    algorithm to an image.
%         
%    Input
%    --------------------
%    cpd_mat       Input 3xM indexed representation
%    Im            Image to match the size of the output image to.
%
%    Output
%    --------------------
%    Im_out        Output image
%
%    Example
%    --------------------
%    Im_trx = cpd2im(cpd_trx,Im);
    
[SX SY] = size(Im);
Im_out = zeros(SX,SY);
for i = 1:size(cpd_mat,2)
    if cpd_mat(1,i) <= 0; cpd_mat(1,i) = 1; end
    if cpd_mat(2,i) <= 0; cpd_mat(2,i) = 1; end
    if cpd_mat(3,i) >= 0
        Im_out(ceil(cpd_mat(1,i)),ceil(cpd_mat(2,i))) = cpd_mat(3,i);
    else
        Im_out(ceil(cpd_mat(1,i)),ceil(cpd_mat(2,i))) = 0;
    end
end
Im_out = Im_out(1:SX,1:SY);

end     