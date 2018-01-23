function centers = vq_cluster(features, K, varargin)
	%% Vector quantization
	if (nargin>2)&&isnumeric(varargin{1})
    		seed = varargin{1};
	else
    		seed = rand;
	end

	msgSize = fprintf('K-means clustering (%d training data, %d centers)\n', size(features,1), K);
	centers = yael_kmeans(single(features)', K, 'seed', seed);
end
