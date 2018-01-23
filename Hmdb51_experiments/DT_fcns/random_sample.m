function features_all = random_sample(clips, d, data_usage, varargin)

	if (nargin>2)&&isnumeric(varargin{1})
    		rng(varargin{1});
	else
    		rng('default');
	end
	
	features_all = cell2struct(cell(size(d)), d, 2);
	num_clips = 0;
	
	while size(features_all.(d{1}),1) < data_usage
    		msg_size = fprintf('Randomly sampling features. Current number: %d. Target: %d. Number of clips: %d.\n',...
        				size(features_all.(d{1}), 1), data_usage, num_clips);    
    		random_clip = randperm(numel(clips));
    		load(['/Data/mov_cvsp_DT/' clips{random_clip(1)} '.mat']);
    		for i = 1:length(d)
        		features_all.(d{i}) = vertcat(features_all.(d{i}), f.(d{i}));
    		end
    		num_clips = num_clips + 1;
    		clips(random_clip(1)) = [];
	end
	fprintf('\n');
end
