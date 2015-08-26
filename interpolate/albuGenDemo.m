function [A, B] = albuGenDemo( N )
% Generates demo images to interpolate between for testing purposes 
%
% Required Input
% ==============
%     N     Integer corresponding to the demo case to generate.
%
%           N = 1: Generates the examples fir 'Image i' and 'Image i+1'
%           from the Albu et al. paper. The examples created are the same
%           as the images in Figure 2A.
%
% Outputs
% =======
%     A     The first image from the desired demo
%     B     The second image from the desired demo
%

demo_stack = zeros([16 16], 'uint8');

switch N
    case 1
        A = demo_stack;
        A(4,:)  = [0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0];
        A(5,:)  = [0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0];
        A(6,:)  = [0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0];
        A(7,:)  = [1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0];
        A(8,:)  = [1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0];
        A(9,:)  = [1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0];
        A(10,:) = [1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0];
        A(11,:) = [0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0];
        A(12,:) = [0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0];
        A(13,:) = [0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0];
        A(14,:) = [0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0];

        B = demo_stack;
        B(3,:)  =  [0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0];
        B(4,:)  =  [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0];
        B(5,:)  =  [0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 0];
        B(6,:)  =  [0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1];
        B(7,:)  =  [0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1];
        B(8,:)  =  [0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1];
        B(9,:)  =  [0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1];
        B(10,:) =  [0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0];
        B(11,:) =  [0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0];
end

end