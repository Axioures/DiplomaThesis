function compute_dist_testing(type, train_path , test_path, channels)
	c = channels;
	for i=1:length(c)
		if exist(fullfile(test_path, sprintf('dist_%s.mat', c(i).name)), 'file')
			continue;
		end
		msg_size = fprintf('Computing distances: channel %d/%d (%s)\n', i, length(c), c(i).name);
		encoded_features = parload(fullfile(test_path, sprintf('encoded_features_%s.mat', c(i).name)));
		encoded_features_training = parload(fullfile(train_path, sprintf('encoded_features_%s.mat', c(i).name)));
		switch type
			case 'ChiSquared'
				dist = distChiSq(encoded_features, encoded_features_training);
			otherwise
				error('Unsupported kernel type: %s', type);
		end
		parsave(fullfile(test_path, sprintf('dist_%s', c(i).name)), dist);
% 		erase_msg(msg_size, i==length(c));
	end
end
