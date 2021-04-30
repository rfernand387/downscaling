function [ergas_pb, av_ergas, ergas_spectral, ergas_spatial, excp] = ComputeERGAS(x,y,resratio)
%
% ComputeERGAS computes the image ERGAS between two image pixels grids
% 
% Input:
%   x and y - two signal data series of the same dimension. 
%             They can be in a vector or matrix fotmat. 
%             Usually, y is a reference signal.
%   resratio - the resolution ratio, for example, if we use 30m resolution 
%             Landsat imsage as the reference and the 480m MODIS imsge as
%             the test image, the ratio is typically 1/16.
%
% Output:
%   ergas_pb - the ERGAS per band
%   av_ergas - the average ERGAS of all bands
%   ergas_spectral - the total spectral ERGAS
%   ergas_spatial - the total spatial ERGAS
%   excp - number of invalid pixels per band
%

%% find the number of bands
sizi = size(x);
if max(size(size(x))) == 2
    bands = 1;
else
    bands = sizi(1,3);
end

%% variable preallocation
meansx  = zeros(bands,1);            
RMSE = zeros(bands,1);
excp = zeros(bands,1);

for i = 1:bands                     
    xt = double(x(:,:,i));          
    yt = double(y(:,:,i));
    xt = xt(:);
    yt = yt(:);
    % exclude the invalid pixels
    % idx = find(yt<=0|yt>1.0);
    idx = union(find(xt<=0|xt>1.0),find(yt<=0|yt>1.0));
    yt(idx) = [];
    xt(idx) = [];   
    d = xt - yt;
    
    excp(i) = length(idx);
    meansx(i,1) = mean(xt);
    RMSE(i) = sqrt(sum(d.^2)/length(d)); 
end

%% global RMSE and mean
xt = double(x(:));          
yt = double(y(:));
% exclude the invalid pixels
% idx = find(yt<=0|yt>1.0);
idx = union(find(xt<=0|xt>1.0),find(yt<=0|yt>1.0));
yt(idx) = [];
xt(idx) = [];   
d = xt - yt;
globalMEAN = mean(xt);
globalRMSE = sqrt(sum(d.^2)/length(d));

%% compute ERGAS 
presratio = 100*resratio;
% ERGAS per band
ergasroot = sqrt((RMSE.^2)./(meansx.^2));
ergas_pb  = presratio*ergasroot;
% average ERGAS of all bands
av_ergas  = mean(ergas_pb);
% the total spectral ERGAS
ergasroot = sqrt((sum((RMSE.^2)./(meansx.^2))) / bands);
ergas_spectral  = presratio*ergasroot;
% the total spatial ERGAS
ergas_spatial   = presratio*globalRMSE/globalMEAN;

end