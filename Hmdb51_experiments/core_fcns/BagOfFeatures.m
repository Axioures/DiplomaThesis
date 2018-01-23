%Compute Bag-of-Features histogram of features
function [BOF,H] = BagOfFeatures(centers,feat)

try
    dist=eucliddist(centers, feat);
    [~, lbl]=min(dist);
catch
    feature('jit',0)
    feature('accel',0)    
    [~, lbl] = pdist2(centers, feat, 'euclidean', 'Smallest', 1);
    feature('jit',1)
    feature('accel',1)    
end


H = histc(lbl, 1:size(centers,1));
BOF = H/(sqrt(H*H')+eps);
%     BOF = H/(sum(H)+eps);

end

