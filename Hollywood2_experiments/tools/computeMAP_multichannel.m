function [mAP] = computeMAP_multichannel(probs, gt)
d = fieldnames(probs(1));
for id = 1:length(d)
    probs_d = {probs.(d{id})}';
    probs_d = cell2mat(cellfun(@(x) x, probs_d, 'UniformOutput', false));
    mAP.d{id} = computeMAP(probs_d, gt);
end
end
