clear all; close all; clc;

addpath('./tools');
addpath('./core_fcns');
addpath('./DT_fcns');
addpath('/home/vaggelis/ExternalPackages/yael_v438/matlab');
%% parameters
paths.features_root = '/home/vaggelis/mov_frames_jpg/c3d/all_features/';
paths.libsvm = '/home/vaggelis/ExternalPackages/libsvm-3.17_with_conversion_tool/matlab/';
training.video_list = '/home/vaggelis/mov_frames_jpg/classification/train_equal_list.txt';
testing.video_list = '/home/vaggelis/mov_frames_jpg/classification/test_equal_list.txt';
features_dim = 4096;
layer = 'fc6';
svm_cost = 100;
addpath(paths.libsvm);

actions = {'sitting_down','standing_up','ride_horse',...
		'open_door','point__at_something'};

actions_segm = {'down','up','hands','something','door','horse'};

%% TRAINING
%% read training video info
fid = fopen(training.video_list, 'r');
o = textscan(fid, '%s %d %d');
fclose(fid);
[~, training.clips] = cellfun(@(x) fileparts(x), o{1}, 'UniformOutput', false);
[training.videos, idx] = unique(training.clips);
training.clip_video_id = cellfun(@(x) find(strcmp(x, training.videos)), training.clips);
training.start_frame = o{2};
%training.clip_gt = o{3};
%training.video_gt = training.clip_gt(idx);

for i=1:length(training.videos)
        
	name = training.videos(i);
        str = strsplit(name{1},'_');
        if ismember(str{end},actions_segm)
                if strcmp(str{end},'something')
                        label = 'point__at_something';
                else
			if strcmp(str{end},'floor')
                                label = 'fall_on_the_floor';
                        else
                                label = strcat(str{end-1},'_',str{end});
                        end
		end
        else
		label = str{end};
	end
	cat_train(i,1) = find(strcmp(label,actions)==1);
end

training.video_gt = cat_train;
num_classes = length(unique(training.video_gt));

%try
%    load('./DT_models/models_Traj.mat')
%catch
    %% load features
    video_c3d_features = zeros(length(training.videos), features_dim);
    for i=1:length(training.videos)
        num_clips_in_video = sum(training.clip_video_id==i);
        sz = zeros(num_clips_in_video, 5);
        clip_feature_vector = zeros(num_clips_in_video, features_dim);
	disp(training.videos(i));
	for j=1:num_clips_in_video
	    clip_features_filename = fullfile(paths.features_root, training.videos{i}, sprintf('%06d.%s-1', training.start_frame(j), layer));
            [sz(j,:), clip_feature_vector(j,:)] = read_binary_blob(clip_features_filename);
        end
        %video_features(i,:) = mean(clip_feature_vector,1);
        data = mean(clip_feature_vector,1);
	data = data / norm(data);
	video_c3d_features(i,:) = data;
    end

    %% codebook generation
    encoding_type = 'BoVW';
    descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'MBH'};
    combine_descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy'};
    d_codebook = false(length(descriptors),1);
    for i=1:length(descriptors)
        if exist(fullfile('./codebooks/', sprintf('codebook_%s.mat', descriptors{i})), 'file')
            d_codebook(i) = true;
        end
    end
    if ~all(d_codebook)
    
    	data_usage = 100000;
    	global_seed = 25;
	K = 4000;
	pca_factor = 1;

    	features_all = random_sample(training.videos,descriptors,data_usage,global_seed);

	for i=1:length(descriptors)
    		fprintf('Processing descriptor: %s\n', d{i});
    		if d_codebook(i)
        		continue;
    		end
    		switch encoding_type
        		case 'BoVW'
            			codebook = vq_cluster(features_all.(descriptors{i}), K, global_seed);
        		case 'vlad'
            			codebook = vq_cluster(features_all.(descriptors{i}), K, global_seed);
        		case 'fisher'
            			codebook = gmm_cluster(features_all.(descriptors{i}), K, pca_factor);
        		otherwise
            			error('Unrecognized encoding type: %s.\n', params.encoding.type);
    		end
    		parsave(fullfile('./codebooks', sprintf('codebook_%s.mat', descriptors{i})), codebook);
    	end
    end

    %% feature encoding
    channels = repmat(struct('name', '', 'descriptor', ''), length(descriptors), 1);
    for d = 1:length(descriptors)
        channels(d).descriptor = descriptors{d};
        channels(d).name = descriptors{d};
    end	
   
    for i=1:length(training.videos)
	fprintf('Encoding features: video %d/%d (%s)\n', i, length(training.videos), training.videos{i});
    	if exist(fullfile('./encodings/', sprintf('%s.mat', training.videos{i})), 'file')
		continue;
	end	
	load(['/Data/mov_cvsp_DT/' training.videos{i} '.mat']);
	switch encoding_type
            case 'BoVW'
                encoded_features = encode_multichannel_bof(f, channels, 0);
            case 'fisher'
                encoded_features = encode_multichannel_fisher(f, channels, 0);
            case 'vlad'
                encoded_features = encode_multichannel_vlad(f, channels, 0);
        end
        parsave(fullfile('./encodings', training.videos{i}), encoded_features);
    end


    %% SVM training
    [~, empty] = aggregate_encodings('./encodings', './DT_training', training.videos);
    annotation(empty) = [];

    combine_by_concatenation(combine_descriptors, './DT_training');
    descriptors{end+1} = 'combined';

    for id=1:length(descriptors)
	fprintf('Training SVMs: descriptor %d/%d (%s)\n', id, length(descriptors), descriptors{id});
	encoded_features = parload(fullfile('./DT_training', sprintf('encoded_features_%s.mat', descriptors{id})));    

	video_features = encoded_features;

    	% train SVMs
    	classes = unique(training.video_gt);
    	models = cell(length(classes), 1);
    	for c = 1:length(classes)
        	fprintf('Training SVM %d\n', c);
        	oneVSall = training.video_gt==classes(c);
        	w_pos = length(training.video_gt)/(2*sum(oneVSall));
        	w_neg = length(training.video_gt)/(2*sum(~oneVSall));
        	parameters = sprintf('-t 0 -b 1 -q -c %d -w1 %f -w0 %f', svm_cost, w_pos, w_neg);
%         	parameters = sprintf('-t 0 -b 1 -q -c %d', svm_cost);
        	models{c} = svmtrain(double(oneVSall), double(video_features), parameters);
    	end
    	save(sprintf('./DT_models/models_%s.mat',descriptors{id}), 'models', '-v7.3')
    end
%end

% keyboard

%% TESTING
%% read testing video info
fid = fopen(testing.video_list, 'r');
o = textscan(fid, '%s %d %d');
fclose(fid);
[~, testing.clips] = cellfun(@(x) fileparts(x), o{1}, 'UniformOutput', false);
[testing.videos, idx] = unique(testing.clips);
testing.clip_video_id = cellfun(@(x) find(strcmp(x, testing.videos)), testing.clips);
testing.start_frame = o{2};
%testing.clip_gt = o{3};
%testing.video_gt = testing.clip_gt(idx);

for i=1:length(testing.videos)

        name = testing.videos(i);
        str = strsplit(name{1},'_');
        if ismember(str{end},actions_segm)
                if strcmp(str{end},'something')
                        label = 'point__at_something';
                else
			if strcmp(str{end},'floor')
                                label = 'fall_on_the_floor';
                        else
                                label = strcat(str{end-1},'_',str{end});
                        end                
		end
        else
                label = str{end};
        end
        cat_test(i,1) = find(strcmp(label,actions)==1);
end

testing.video_gt = cat_test;
num_classes = length(unique(testing.video_gt));

%% load features
video_c3d_features = zeros(length(testing.videos), features_dim);
for i=1:length(testing.videos)
    num_clips_in_video = sum(testing.clip_video_id==i);
    sz = zeros(num_clips_in_video, 5);
    clip_feature_vector = zeros(num_clips_in_video, features_dim);
    disp(testing.videos(i));
    for j=1:num_clips_in_video
        clip_features_filename = fullfile(paths.features_root, testing.videos{i}, sprintf('%06d.%s-1', testing.start_frame(j), layer));
        [sz(j,:), clip_feature_vector(j,:)] = read_binary_blob(clip_features_filename);
    end
	%video_features(i,:) = mean(clip_feature_vector,1);
        data = mean(clip_feature_vector,1);
        data = data / norm(data);
        video_c3d_features(i,:) = data;
end

%video_features = sqrt(video_features);
%video_features = video_features ./ repmat(sqrt(sum(video_features.^2, 2)), 1, size(video_features,2));
encoding_type = 'BoVW';
descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'MBH'};
combine_descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy'};

channels = repmat(struct('name', '', 'descriptor', ''), length(descriptors), 1);
for d = 1:length(descriptors)
	channels(d).descriptor = descriptors{d};
	channels(d).name = descriptors{d};
end


for i=1:length(testing.videos)
	fprintf('Encoding features: video %d/%d (%s)\n', i, length(testing.videos), testing.videos{i});
        if exist(fullfile('./encodings/', sprintf('%s.mat', testing.videos{i})), 'file')
                continue;
        end
        load(['/Data/mov_cvsp_DT/' testing.videos{i} '.mat']);
        switch encoding_type
            case 'BoVW'
                encoded_features = encode_multichannel_bof(f, channels, 0);
            case 'fisher'
                encoded_features = encode_multichannel_fisher(f, channels, 0);
            case 'vlad'
                encoded_features = encode_multichannel_vlad(f, channels, 0);
        end
        parsave(fullfile('./encodings', testing.videos{i}), encoded_features);
end

%% SVM testing
[~, empty] = aggregate_encodings('./encodings', './DT_testing', testing.videos);
annotation(empty) = [];

combine_by_concatenation(combine_descriptors, './DT_testing');
descriptors{end+1} = 'combined';

for id=1:length(descriptors)
        fprintf('Testing SVMs: descriptor %d/%d (%s)\n', id, length(descriptors), descriptors{id});
        encoded_features = parload(fullfile('./DT_testing', sprintf('encoded_features_%s.mat', descriptors{id})));

        video_features = encoded_features;

	%% test
	load(sprintf('./DT_models/models_%s.mat',descriptors{id}));
	prb = zeros(length(testing.videos), num_classes);
	for m=1:length(models)
    		fprintf('Testing with SVM %d\n', m);
    		[~,~,p] = svmpredict(zeros(size(video_features,1),1), double(video_features), models{m} ,'-b 1 -q');
    		prb(:,m) = p(:,models{m}.Label==1);
	end
	[~,cls] = max(prb, [], 2);
	%class = class - 1; % classes in the GT are indexed from 0
	for i=1:length(testing.videos)
		class(i).(descriptors{id}) = cls(i);
		probs(i).(descriptors{id}) = prb(i,:);
	end
end
conf_matrix = confMatrix_multiclass(class,testing.video_gt,length(actions));
accuracy = compute_accuracy(class, testing.video_gt);
disp(accuracy)
parsave(fullfile('./DT_testing', 'results.mat'), accuracy, conf_matrix, class, probs);
