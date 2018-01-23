function [ nHist ] = normalizeHistogram( hist, type )
%NORMALIZEHISTOGRAM Summary of this function goes here
%   Detailed explanation goes here

switch type
    case 'L1'
        normHist = sum(hist);
        nHist = hist ./ normHist;
    case 'L2'
        %eps = 0.005;
        nHist = hist/(sqrt(hist*hist')+eps);
    otherwise
        error('Invalid normalization type for histogram');
end


end

