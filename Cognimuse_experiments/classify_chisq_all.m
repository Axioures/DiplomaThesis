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

tsn_dim = 1024;
load('./tsn/movsum_videos');
load('./tsn/max/movsum_rgb_features.mat');
load('./tsn/max/movsum_flow_features.mat');

load('./tsn/max/movsum_rgb_features_split2.mat');
load('./tsn/max/movsum_flow_features_split2.mat');

load('./tsn/max/movsum_rgb_features_split3.mat');
load('./tsn/max/movsum_flow_features_split3.mat');

%load('./tsn/max/movsum_rgb_features_ucf.mat');
%load('./tsn/max/movsum_flow_features_ucf.mat');


rgb_features = [rgb_features, rgb_features_split2, rgb_features_split3];
flow_features = [flow_features, flow_features_split2, flow_features_split3];

%actions = {'climb_stairs', 'cry', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'pick', ...
%'point__at_something', 'ride_horse', 'running', 'sitting_down', 'sitting_up', 'smile', 'standing_up', 'throw', 'turn', 'walk', 'wave_hands'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

%actions = {'climb_stairs', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'sitting_down', 'sitting_up', 'throw'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

actions = {'cry', 'pick', 'point__at_something', 'ride_horse', 'running', 'smile', 'standing_up', 'wave_hands'};

actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

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
                switch str{end}
			case 'something'
                        	label = 'point__at_something';
            		case 'floor'
                                label = 'fall_on_the_floor';
                        otherwise
                                label = strcat(str{end-1},'_',str{end});
		end
        else
		label = str{end};
	end
	cat_train(i,1) = find(strcmp(label,actions)==1);
end

training.video_gt = cat_train;
num_classes = length(unique(training.video_gt));
%try
%    load('models.mat')
%catch
    %% load C3D features
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
	%data = mean(clip_feature_vector,1);
        data = max(clip_feature_vector,[],1);
        %data = clip_feature_vector(1,:);
        %for k=2:num_clips_in_video
        %        data = data.*clip_feature_vector(k,:);
        %end
	data = data / norm(data);
	video_c3d_features(i,:) = data;
    end

    parsave(fullfile('./DT_training', sprintf('encoded_features_c3d.mat')), video_c3d_features);

    %% load tsn rgb features
    video_tsn_rgb_features = zeros(length(training.videos), 3*tsn_dim);
    for i=1:length(training.videos)
	ind = find(strcmp(movsum_videos,training.videos(i)));
	tsn_data = rgb_features(ind,:);
	tsn_data = tsn_data / norm(tsn_data);

	video_tsn_rgb_features(i,:) = tsn_data;
    end

    parsave(fullfile('./DT_training', sprintf('encoded_features_tsn_rgb.mat')), video_tsn_rgb_features);

    %% load tsn flow features
    video_tsn_flow_features = zeros(length(training.videos), 3*tsn_dim);
    for i=1:length(training.videos)
        ind = find(strcmp(movsum_videos,training.videos(i)));
        tsn_data = flow_features(ind,:);
        tsn_data = tsn_data / norm(tsn_data);

        video_tsn_flow_features(i,:) = tsn_data;
    end

    parsave(fullfile('./DT_training', sprintf('encoded_features_tsn_flow.mat')), video_tsn_flow_features);


    %% codebook generation
    encoding_type = 'BoVW';
    descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'MBH'};
    
    combine_descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'c3d', 'tsn_rgb', 'tsn_flow'};
    %combine_descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'tsn_rgb', 'tsn_flow'};
    %combine_descriptors = {'tsn_rgb', 'tsn_flow'};
    
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
                fprintf('Processing descriptor: %s\n', descriptors{i});
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

    [~, empty] = aggregate_encodings('./encodings', './DT_training', training.videos);
    annotation(empty) = [];

    channels(length(descriptors)+1).descriptor = 'c3d';
    channels(length(descriptors)+1).name = 'c3d';
 
    channels(length(descriptors)+2).descriptor = 'tsn_rgb';
    channels(length(descriptors)+2).name = 'tsn_rgb';

    channels(length(descriptors)+3).descriptor = 'tsn_flow';
    channels(length(descriptors)+3).name = 'tsn_flow';


    descriptors{end+1} = 'c3d';
    descriptors{end+1} = 'tsn_rgb';
    descriptors{end+1} = 'tsn_flow';
    descriptors{end+1} = 'combined';

    %% compute dist and kernels
    compute_dist('ChiSquared','./DT_training',channels);
    compute_kernels(descriptors,channels,combine_descriptors,'./DT_training');
   
    for id=1:length(descriptors)
	fprintf('Training SVMs: descriptor %d/%d (%s)\n', id, length(descriptors), descriptors{id});
        kernel = parload(fullfile('./DT_training', sprintf('kernel_%s.mat', descriptors{id})));

    	%% train SVMs
    	classes = unique(training.video_gt);
    	models = cell(length(classes), 1);
    	K = [(1:size(kernel,1))', kernel];
    	for c = 1:length(classes)
        	fprintf('Training SVM %d\n', c);
        	oneVSall = training.video_gt==classes(c);
        	w_pos = length(training.video_gt)/(2*sum(oneVSall));
        	w_neg = length(training.video_gt)/(2*sum(~oneVSall));
        	parameters = sprintf('-t 4 -b 1 -q -c %d -w1 %f -w0 %f', svm_cost, w_pos, w_neg);
%         	parameters = sprintf('-t 0 -b 1 -q -c %d', svm_cost);
        	models{c} = svmtrain(double(oneVSall), K, parameters);
%    		end
%    		save('models.mat', 'models', '-v7.3')
	end
	parsave(fullfile('./DT_training', sprintf('models_%s.mat', descriptors{id})), models);
    end

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
                switch str{end}
                        case 'something'
                                label = 'point__at_something';
                        case 'floor'
                                label = 'fall_on_the_floor';
                        otherwise
                                label = strcat(str{end-1},'_',str{end});
                end
        else
                label = str{end};
        end
	%if ~isempty(find(strcmp(label,actions)))
    		cat_test(i,1) = find(strcmp(label,actions)==1);
        %else
        %	cat_test(i,1) = 2;
        %end

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
        %data = mean(clip_feature_vector,1);
        data = max(clip_feature_vector,[],1);
        %data = clip_feature_vector(1,:);
        %for k=2:num_clips_in_video
        %        data = data.*clip_feature_vector(k,:);
        %end
	data = data / norm(data);
        video_c3d_features(i,:) = data;
end

parsave(fullfile('./DT_testing', sprintf('encoded_features_c3d.mat')), video_c3d_features);

%% load tsn rgb features
video_tsn_rgb_features = zeros(length(testing.videos), 3*tsn_dim);
for i=1:length(testing.videos)
	ind = find(strcmp(movsum_videos,testing.videos(i)));
        tsn_data = rgb_features(ind,:);
        tsn_data = tsn_data / norm(tsn_data);

        video_tsn_rgb_features(i,:) = tsn_data;
end

parsave(fullfile('./DT_testing', sprintf('encoded_features_tsn_rgb.mat')), video_tsn_rgb_features);

%% load tsn flow features
video_tsn_flow_features = zeros(length(testing.videos), 3*tsn_dim);
for i=1:length(testing.videos)
        ind = find(strcmp(movsum_videos,testing.videos(i)));
        tsn_data = flow_features(ind,:);
        tsn_data = tsn_data / norm(tsn_data);

        video_tsn_flow_features(i,:) = tsn_data;
end

parsave(fullfile('./DT_testing', sprintf('encoded_features_tsn_flow.mat')), video_tsn_flow_features);


clear descriptors;

encoding_type = 'BoVW';
descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'MBH'};
combine_descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'c3d', 'tsn_rgb', 'tsn_flow'};
%combine_descriptors = {'Traj', 'HOG', 'HOF', 'MBHx', 'MBHy', 'tsn_rgb', 'tsn_flow'};
%combine_descriptors = {'tsn_rgb','tsn_flow'};

clear channels;
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

[~, empty] = aggregate_encodings('./encodings', './DT_testing', testing.videos);
annotation(empty) = [];

channels(length(descriptors)+1).descriptor = 'c3d';
channels(length(descriptors)+1).name = 'c3d';

channels(length(descriptors)+2).descriptor = 'tsn_rgb';
channels(length(descriptors)+2).name = 'tsn_rgb';

channels(length(descriptors)+3).descriptor = 'tsn_flow';
channels(length(descriptors)+3).name = 'tsn_flow';

descriptors{end+1} = 'c3d';
descriptors{end+1} = 'tsn_rgb';
descriptors{end+1} = 'tsn_flow';
descriptors{end+1} = 'combined';

%% compute dist and kernels
compute_dist_testing('ChiSquared','./DT_training','./DT_testing',channels);
compute_kernels_testing(descriptors,channels,combine_descriptors,'./DT_training','./DT_testing');

%% test
for id=1:length(descriptors)
        fprintf('Testing SVMs: descriptor %d/%d (%s)\n', id, length(descriptors), descriptors{id});
        kernel2 = parload(fullfile('./DT_testing', sprintf('kernel_%s.mat', descriptors{id})));

	prb = zeros(length(testing.videos), num_classes);
	K2 = [(1:size(kernel2,1))', kernel2];

	models = parload(fullfile('./DT_training', sprintf('models_%s.mat', descriptors{id})));
	for m=1:length(models)
    		fprintf('Testing with SVM %d\n', m);
    		[~,~,p] = svmpredict(zeros(size(kernel2,1),1), K2, models{m} ,'-b 1 -q');
    		prb(:,m) = p(:,models{m}.Label==1);
	end
	[~,cls] = max(prb, [], 2);

	for i=1:length(testing.videos)
        	class(i).(descriptors{id}) = cls(i);
                probs(i).(descriptors{id}) = prb(i,:);
        end

end
%conf_matrix = confusionmat(testing.video_gt,class);
conf_matrix = confMatrix_multiclass(class,testing.video_gt,length(actions));
accuracy = compute_accuracy(class, testing.video_gt);
disp(accuracy)
parsave(fullfile('./DT_testing', 'results.mat'), accuracy, conf_matrix, class, probs);
