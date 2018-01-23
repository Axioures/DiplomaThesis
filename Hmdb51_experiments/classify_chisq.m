clear all; close all; clc;

addpath('./tools');
addpath('./core_fcns');

%% parameters
paths.features_root = '/home/vaggelis/hmdb51_frames_c3d/c3d/';
paths.libsvm = '/home/vaggelis/ExternalPackages/libsvm-3.17_with_conversion_tool/matlab/';
training.video_list = '/home/vaggelis/hmdb51_frames_c3d/classification/train_list.txt';
testing.video_list = '/home/vaggelis/hmdb51_frames_c3d/classification/test_list.txt';
features_dim = 4096;
layer = 'fc6';
svm_cost = 100;
addpath(paths.libsvm);

%actions = {'climb_stairs', 'cry', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'pick', ...
%'point__at_something', 'ride_horse', 'running', 'sitting_down', 'sitting_up', 'smile', 'standing_up', 'throw', 'turn', 'walk', 'wave_hands'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

%% TRAINING
%% read training video info
fid = fopen(training.video_list, 'r');
o = textscan(fid, '%s %d %d');
fclose(fid);
[~, training.clips] = cellfun(@(x) fileparts(x), o{1}, 'UniformOutput', false);
[training.videos, idx] = unique(training.clips);
training.clip_video_id = cellfun(@(x) find(strcmp(x, training.videos)), training.clips);
training.start_frame = o{2};
training.clip_gt = o{3};
training.video_gt = training.clip_gt(idx);

%    load('models.mat')
%catch
    %% load features
    video_features = zeros(length(training.videos), features_dim);
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
	%data = max(clip_feature_vector,[],1);
	data = clip_feature_vector(1,:);
	for k=2:num_clips_in_video
		data = data.*clip_feature_vector(k,:);
	end	
	data = data / norm(data);
	video_features(i,:) = data;
    end

%     keyboard
    %video_features = sqrt(video_features);
    %video_features = video_features ./ repmat(sqrt(sum(video_features.^2, 2)), 1, size(video_features,2));
%     keyboard
 
    %% compute dist and kernels
    dist_tr = distChiSq(video_features, video_features);

    n_mean = mean(dist_tr(:)) + eps;
    kernel = exp( - dist_tr / n_mean ); % n = mean(k(:));

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
%         parameters = sprintf('-t 0 -b 1 -q -c %d', svm_cost);
        models{c} = svmtrain(double(oneVSall), K, parameters);
%    end
%    save('models.mat', 'models', '-v7.3')
end

training_video_features = video_features;

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
testing.clip_gt = o{3};
testing.video_gt = testing.clip_gt(idx);

num_classes = length(unique(testing.video_gt));

%% load features
video_features = zeros(length(testing.videos), features_dim);
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
        %data = max(clip_feature_vector,[],1);
        data = clip_feature_vector(1,:);
        for k=2:num_clips_in_video
                data = data.*clip_feature_vector(k,:);
        end
	data = data / norm(data);
        video_features(i,:) = data;
end

%video_features = sqrt(video_features);
%video_features = video_features ./ repmat(sqrt(sum(video_features.^2, 2)), 1, size(video_features,2));

    dist2 = distChiSq(video_features, training_video_features);

    kernel2 = exp( - dist2 / n_mean );


%% test
probs = zeros(length(testing.videos), num_classes);
K2 = [(1:size(kernel2,1))', kernel2];
for m=1:length(models)
    fprintf('Testing with SVM %d\n', m);
    [~,~,p] = svmpredict(zeros(size(video_features,1),1), K2, models{m} ,'-b 1 -q');
    probs(:,m) = p(:,models{m}.Label==1);
end
[~,class] = max(probs, [], 2);
class = class - 1; % classes in the GT are indexed from 0

%conf_matrix = confusionmat(testing.video_gt,class);
conf_matrix = confMatrix_multiclass(testing.video_gt,class,num_classes);
accuracy = sum(class==testing.video_gt)/length(class);
disp(accuracy)
disp(conf_matrix)

