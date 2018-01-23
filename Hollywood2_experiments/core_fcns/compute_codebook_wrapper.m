function codebook = compute_codebook_wrapper(params, clips, varargin)

%% Check codebook existence
d = params.features.descriptors;
d_codebook = false(length(d),1);
if params.reuse.codebooks
    for i=1:length(d)
        if exist(fullfile(params.paths.training, sprintf('codebook_%s.mat', d{i})), 'file')
            d_codebook(i) = true;
        end
    end
    if all(d_codebook)
        return;
    end
end

%% Random Sampling
features_all = random_sample(params, clips, params.encoding.data_usage, params.global_seed);

%% Clustering
for i=1:length(d)
    fprintf('Processing descriptor: %s\n', d{i});
    if d_codebook(i)
        continue;
    end
    switch params.encoding.type
        case 'BoVW'
            codebook = vq_cluster(features_all.(d{i}), params.encoding.K, params.global_seed);
        case 'vlad'
            codebook = vq_cluster(features_all.(d{i}), params.encoding.K, params.global_seed);
        case 'fisher'
            codebook = gmm_cluster(features_all.(d{i}), params.encoding.K, params.encoding.pca_factor);
        otherwise
            error('Unrecognized encoding type: %s.\n', params.encoding.type);
    end
    parsave(fullfile(params.paths.training, sprintf('codebook_%s.mat', d{i})), codebook);
end
end

function features_all = random_sample(params, clips, data_usage, varargin)
if (nargin>2)&&isnumeric(varargin{1})
    rng(varargin{1});
else
    rng('default');
end
d = params.features.descriptors;
features_all = cell2struct(cell(size(d)), d, 2);
num_clips = 0;
while size(features_all.(d{1}),1) < data_usage
    msg_size = fprintf('Randomly sampling features. Current number: %d. Target: %d. Number of clips: %d.\n',...
        size(features_all.(d{1}), 1), data_usage, num_clips);    
    random_clip = randperm(numel(clips));
    f = feature_extraction_wrapper(clips(random_clip(1)), params); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for i = 1:length(d)
        features_all.(d{i}) = vertcat(features_all.(d{i}), f.(d{i}));
    end
    num_clips = num_clips + 1;
    clips(random_clip(1)) = [];
end
fprintf('\n');
end

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