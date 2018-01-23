function gmm = gmm_cluster(features, K, pca_factor, varargin)
	%% Gaussian mixture model
	if (nargin>3)&&isnumeric(varargin{1})
    		seed = varargin{1};
	else
    		seed = rand;
	end
	msgSize = fprintf('GMM estimation (%d training data, %d gaussians)\n', size(features,1), K);
	gmm = struct('w', [], 'mu', [], 'sigma', []);
	features_normalized = zscore(features);
	[coeff, score] = pca(features_normalized);
	princomp = coeff(:, 1:round(size(coeff,2)*pca_factor));
	features_reduced = princomp' * features_normalized';
	[gmm.w, gmm.mu, gmm.sigma] = yael_gmm(single(features_reduced), K, 'seed', seed);
	gmm.princomp = princomp;
end
