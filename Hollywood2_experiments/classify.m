clear all; close all; clc;

%% parameters
paths.features_root = '/home/vaggelis/hollywood2_frames_c3d/c3d';
paths.libsvm = '/home/vaggelis/ExternalPackages/libsvm-3.17_with_conversion_tool/matlab/';
training.video_list = '/home/vaggelis/hollywood2_frames_c3d/train_list.txt';
testing.video_list = '/home/vaggelis/hollywood2_frames_c3d/test_list.txt';
features_dim = 4096;
layer = 'fc6';
svm_cost = 100;
addpath(paths.libsvm);

actions = {'AnswerPhone','DriveCar','Eat','FightPerson','GetOutCar','HandShake','HugPerson',...
                        'Kiss','Run','SitDown','SitUp','StandUp'};

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
        for j=1:length(actions)
                fid = fopen(['/ssd_data/hollywood2/Hollywood2/ClipSets/' actions{j} '_train.txt'],'r');
                line = textscan(fid, '%[^\n]', 1 , 'HeaderLines', i-1);
                str = strsplit(cell2mat(line{1}));
                if strcmp(str{2},'1')
                        cat(i,1) = j;
                end
                fclose(fid);
        end
end

training.video_gt = cat;
num_classes = length(unique(training.video_gt));
try
    load('models.mat')
catch
    %% load features
    video_features = zeros(length(training.videos), features_dim);
    for i=1:length(training.videos)
        num_clips_in_video = sum(training.clip_video_id==i);
        sz = zeros(num_clips_in_video, 5);
        clip_feature_vector = zeros(num_clips_in_video, features_dim);
        for j=1:num_clips_in_video
            clip_features_filename = fullfile(paths.features_root, training.videos{i}, sprintf('%06d.%s-1', training.start_frame(j), layer));
            [sz(j,:), clip_feature_vector(j,:)] = read_binary_blob(clip_features_filename);
        end
        %video_features(i,:) = mean(clip_feature_vector,1);
        data = mean(clip_feature_vector,1);
	data = data / norm(data);
	video_features(i,:) = data;
    end

%     keyboard
    %video_features = sqrt(video_features);
    %video_features = video_features ./ repmat(sqrt(sum(video_features.^2, 2)), 1, size(video_features,2));
%     keyboard
    
    %% train SVMs
    classes = unique(training.video_gt);
    models = cell(length(classes), 1);
    for c = 1:length(classes)
        fprintf('Training SVM %d\n', c);
        oneVSall = training.video_gt==classes(c);
        w_pos = length(training.video_gt)/(2*sum(oneVSall));
        w_neg = length(training.video_gt)/(2*sum(~oneVSall));
        parameters = sprintf('-t 0 -b 1 -q -c %d -w1 %f -w0 %f', svm_cost, w_pos, w_neg);
%         parameters = sprintf('-t 0 -b 1 -q -c %d', svm_cost);
        models{c} = svmtrain(double(oneVSall), double(video_features), parameters);
    end
    save('models.mat', 'models', '-v7.3')
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
        for j=1:length(actions)
                fid = fopen(['/ssd_data/hollywood2/Hollywood2/ClipSets/' actions{j} '_test.txt'],'r');
                line = textscan(fid, '%[^\n]', 1 , 'HeaderLines', i-1);
                str = strsplit(cell2mat(line{1}));
                if strcmp(str{2},'1')
                        cat_test(i,1) = j;
                end
                fclose(fid);
        end
end

testing.video_gt = cat_test;
num_classes = length(unique(testing.video_gt));

%% load features
video_features = zeros(length(testing.videos), features_dim);
for i=1:length(testing.videos)
    num_clips_in_video = sum(testing.clip_video_id==i);
    sz = zeros(num_clips_in_video, 5);
    clip_feature_vector = zeros(num_clips_in_video, features_dim);
    for j=1:num_clips_in_video
        clip_features_filename = fullfile(paths.features_root, testing.videos{i}, sprintf('%06d.%s-1', testing.start_frame(j), layer));
        [sz(j,:), clip_feature_vector(j,:)] = read_binary_blob(clip_features_filename);
    end
	%video_features(i,:) = mean(clip_feature_vector,1);
        data = mean(clip_feature_vector,1);
        data = data / norm(data);
        video_features(i,:) = data;
end

%video_features = sqrt(video_features);
%video_features = video_features ./ repmat(sqrt(sum(video_features.^2, 2)), 1, size(video_features,2));


%% test
probs = zeros(length(testing.videos), num_classes);
for m=1:length(models)
    fprintf('Testing with SVM %d\n', m);
    [~,~,p] = svmpredict(zeros(size(video_features,1),1), double(video_features), models{m} ,'-b 1 -q');
    probs(:,m) = p(:,models{m}.Label==1);
end
[~,class] = max(probs, [], 2);
%class = class - 1; % classes in the GT are indexed from 0

conf_matrix = confusionmat(testing.video_gt,class);
accuracy = sum(class==testing.video_gt)/length(class);
disp(accuracy)
disp(conf_matrix)
