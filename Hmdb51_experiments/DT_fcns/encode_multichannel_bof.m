function encoded_features = encode_multichannel_bof(features, channels, pyramids)
	c = channels;
    	encoded_features = cell2struct(cell(size(c)), {c.name}, 1);
    	for i=1:length(c)
        	codebook = parload(fullfile('./codebooks', sprintf('codebook_%s.mat', c(i).descriptor)))';
        	if pyramids
			encoded_features.(c(i).name) = BagOfFeaturesPyramid(features.(c(i).descriptor), codebook, c(i).grid, features.info);
        	else
			encoded_features.(c(i).name) = BagOfFeatures(codebook, features.(c(i).descriptor));
 	       	end
    	end
end


function bof = BagOfFeaturesPyramid(features, codebook, grid, info)
	K = size(codebook, 1);
	bof = zeros(1, K*grid.num_cells);
	partialSum = zeros(size(features, 1),1);
	for c = 1:grid.num_cells
		ind = ...
			(info(:,8)>grid.cells(c).xStart) & (info(:,8)<=grid.cells(c).xEnd)...
			& (info(:,9)>grid.cells(c).yStart) & (info(:,9)<=grid.cells(c).yEnd) ...
			& (info(:,10)>grid.cells(c).tStart) & (info(:,10)<=grid.cells(c).tEnd);
		partialSum=xor(partialSum, ind);
		[~, bof((c-1)*K+1:c*K)] = BagOfFeatures(codebook, features(ind,:));
	end
	bof = bof/(sqrt(bof*bof')+eps);
	if ~all(partialSum) % just a test ...
		error('s.t. pyramids error!\n')
	end
end
