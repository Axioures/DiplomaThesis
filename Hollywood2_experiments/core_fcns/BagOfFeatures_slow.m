%Compute Bag-of-Features histogram of features
function [BOF,H] = BagOfFeatures_slow(centers,feat)

[~, min_dist_centers] = pdist2(centers, feat, 'euclidean','Smallest', 1);
H = histc(min_dist_centers, 1:size(centers,1));
BOF = H/(sqrt(H*H')+eps);
%     BOF = H/(sum(H)+eps);

end

