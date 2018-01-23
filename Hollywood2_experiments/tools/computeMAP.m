function [mAP, AP] = computeMAP(probs, annotation)

classes = unique([annotation{:}]');
nclasses = length(classes);
AP = zeros(nclasses,1);
for c = 1:nclasses
    class_probs = probs(:,c);
    gt = cellfun(@(x, i) any(x==i), annotation, num2cell(ones(size(annotation))*classes(c)));
    AP(c) = computeAP(class_probs, single(gt), 1, 0);
end
mAP = mean(AP);
end
