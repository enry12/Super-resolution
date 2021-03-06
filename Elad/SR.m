close all; clear all; clc

dir = '../text-test';
format = '.bmp';

LR = 20;
scale = 3;

for i = 1:LR
    im(:, :, i) = im2double(imread([dir,'/', int2str(i), format]));
end
figure; imshow(im(:,:,1)); title('first image of the sequence');
figure; imshow(imresize(im(:,:,1), scale, 'bicubic'));
title('single frame interpolation');

tic
[optimizer, metric] = imregconfig('monomodal');
T(1,1) = affine2d();
fixed = im(:,:,1);
for i = 2:LR
    T(1,i) = imregtform(im(:,:,i), fixed, 'affine', optimizer, metric);
end
computationTime = toc;
disp(['elapsed time to register parameters: ', num2str(computationTime)]);

tic
[h, w] = size(im(:,:,1));
R = sparse(h*w*(scale^2), h*w*(scale^2));
P = sparse(h*w*(scale^2), 1);
D = DownSampling(h, w, scale);
for i = 1:LR
    disp(['iter ', int2str(i), ' of ', int2str(LR)]);
    shift = T(i).invert.T;
    shift = round([shift(3,1), shift(3,2)]);
    S  = ComputeShiftMatrix(h*scale, w*scale, shift);
    LRimg = im(:, :, i);
    
    R = R + (S')*((D')*D)*S;
    P = P + (S')*(D')*LRimg(:);
end
computationTime = toc;
disp(['elapsed time to compute R and P: ', num2str(computationTime)]);

tic
Z = zeros(h*w*(scale^2), 1);
for i = 1:h*w*(scale^2)
    Z(i) = P(i)/R(i, i);
end
Z = reshape(Z, h*scale, w*scale);
Z = inpaint_nans(Z, 0);

computationTime = toc;
disp(['elapsed time to reconstruct the blurred HR image: ', num2str(computationTime)]);

figure; imshow(Z); title('blurred HR image');

blurDim = round(max(size(im(:,:,1)))*0.05*scale); blurDim = max(blurDim, 2);
X = deconvblind(Z, fspecial('gaussian', blurDim, 1));
figure; imshow(X); title('HR image');