function compute_dist(type, path, channels)
	c = channels;
	for i=1:length(c)
		msg_size = fprintf('Computing distances: channel %d/%d (%s)\n', i, length(c), c(i).name);
		if exist(fullfile(path, sprintf('dist_%s.mat', c(i).name)), 'file')
			continue;
		end
		encoded_features = parload(fullfile(path, sprintf('encoded_features_%s.mat', c(i).name)));
		switch type
			case 'ChiSquared'
				dist = distChiSq(encoded_features, encoded_features);
			otherwise
				error('Unsupported kernel type: %s', type);
		end
		parsave(fullfile(path, sprintf('dist_%s', c(i).name)), dist);
% 		erase_msg(msg_size, i==length(c));
	end
end
