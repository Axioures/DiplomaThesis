clear all; close all; clc;

addpath('./tools');
addpath('./core_fcns');
addpath('./DT_fcns');
addpath('/home/vaggelis/ExternalPackages/yael_v438/matlab');

%% parameters
paths.features_root = '/home/vaggelis/hollywood2_frames_c3d/overlapped/c3d/';
paths.libsvm = '/home/vaggelis/ExternalPackages/libsvm-3.17_with_conversion_tool/matlab/';
training.video_list = '/home/vaggelis/hollywood2_frames_c3d/overlapped/train_list.txt';
testing.video_list = '/home/vaggelis/hollywood2_frames_c3d/overlapped/test_list.txt';

features_dim = 4096;
layer = 'fc6';
svm_cost = 100;
addpath(paths.libsvm);

tsn_dim = 1024;
load('./tsn/hollywood2_train_videos');
load('./tsn/hollywood2_test_videos');

%% load features from hmdb51 split1 cnns
load('./tsn/hollywood2_train_rgb_features.mat');
load('./tsn/hollywood2_train_flow_features.mat');

load('./tsn/hollywood2_val_rgb_features.mat');
load('./tsn/hollywood2_val_flow_features.mat');

%% load features from hmdb51 split2 cnns
load('./tsn/hollywood2_train_rgb_features_split2.mat');
load('./tsn/hollywood2_train_flow_features_split2.mat');

load('./tsn/hollywood2_val_rgb_features_split2.mat');
load('./tsn/hollywood2_val_flow_features_split2.mat');

%% load features from hmdb51 split3 cnns
load('./tsn/hollywood2_train_rgb_features_split3.mat');
load('./tsn/hollywood2_train_flow_features_split3.mat');

load('./tsn/hollywood2_val_rgb_features_split3.mat');
load('./tsn/hollywood2_val_flow_features_split3.mat');


%% load features from ucf101 split1 cnns
load('./tsn/hollywood2_train_rgb_features_ucf.mat');
load('./tsn/hollywood2_train_flow_features_ucf.mat');

load('./tsn/hollywood2_val_rgb_features_ucf.mat');
load('./tsn/hollywood2_val_flow_features_ucf.mat');

%% load features from ucf101 split2 cnns
load('./tsn/hollywood2_train_rgb_features_ucf_split2.mat');
load('./tsn/hollywood2_train_flow_features_ucf_split2.mat');

load('./tsn/hollywood2_val_rgb_features_ucf_split2.mat');
load('./tsn/hollywood2_val_flow_features_ucf_split2.mat');

%% load features from ucf101 split3 cnns
load('./tsn/hollywood2_train_rgb_features_ucf_split3.mat');
load('./tsn/hollywood2_train_flow_features_ucf_split3.mat');

load('./tsn/hollywood2_val_rgb_features_ucf_split3.mat');
load('./tsn/hollywood2_val_flow_features_ucf_split3.mat');

%actions = {'cry', 'pick', 'point__at_something', 'ride_horse', 'running', 'smile', 'standing_up', 'wave_hands'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};
train_rgb_features = [train_rgb_features, train_rgb_features_split2, train_rgb_features_ucf, train_rgb_features_ucf_split2];
train_flow_features = [train_flow_features, train_flow_features_split2, train_flow_features_ucf, train_flow_features_ucf_split2];

test_rgb_features = [test_rgb_features, test_rgb_features_split2, test_rgb_features_ucf, test_rgb_features_ucf_split2];
test_flow_features = [test_flow_features, test_flow_features_split2, test_flow_features_ucf, test_flow_features_ucf_split2];



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

actions = {'AnswerPhone','DriveCar','Eat','FightPerson','GetOutCar','HandShake','HugPerson',...
                        'Kiss','Run','SitDown','SitUp','StandUp'};


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

    parsave(fullfile('./training', sprintf('encoded_features_c3d.mat')), video_c3d_features);

    %% load tsn rgb features
    video_tsn_rgb_features = zeros(length(training.videos), 4*tsn_dim);
    for i=1:length(training.videos)
	ind = find(strcmp(hollywood2_train_videos,training.videos(i)));
	tsn_data = train_rgb_features(ind(1),:);
	tsn_data = tsn_data / norm(tsn_data);

	video_tsn_rgb_features(i,:) = tsn_data;
    end

    parsave(fullfile('./training', sprintf('encoded_features_tsn_rgb.mat')), video_tsn_rgb_features);

    %% load tsn flow features
    video_tsn_flow_features = zeros(length(training.videos), 4*tsn_dim);
    for i=1:length(training.videos)
        ind = find(strcmp(hollywood2_train_videos,training.videos(i)));
        tsn_data = train_flow_features(ind(1),:);
        tsn_data = tsn_data / norm(tsn_data);

        video_tsn_flow_features(i,:) = tsn_data;
    end

    parsave(fullfile('./training', sprintf('encoded_features_tsn_flow.mat')), video_tsn_flow_features);


    channels(1).descriptor = 'c3d';
    channels(1).name = 'c3d';
 
    channels(2).descriptor = 'tsn_rgb';
    channels(2).name = 'tsn_rgb';

    channels(3).descriptor = 'tsn_flow';
    channels(3).name = 'tsn_flow';

    descriptors{1} = 'c3d';
    descriptors{end+1} = 'tsn_rgb';
    descriptors{end+1} = 'tsn_flow';
    descriptors{end+1} = 'combined';

    combine_descriptors = {'c3d','tsn_rgb','tsn_flow'};


    %% compute dist and kernels
    compute_dist('ChiSquared','./training',channels);
    compute_kernels(descriptors,channels,combine_descriptors,'./training');
   
    for id=1:length(descriptors)
	fprintf('Training SVMs: descriptor %d/%d (%s)\n', id, length(descriptors), descriptors{id});
        kernel = parload(fullfile('./training', sprintf('kernel_%s.mat', descriptors{id})));

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
	parsave(fullfile('./training', sprintf('models_%s.mat', descriptors{id})), models);
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

parsave(fullfile('./testing', sprintf('encoded_features_c3d.mat')), video_c3d_features);

%% load tsn rgb features
video_tsn_rgb_features = zeros(length(testing.videos), 4*tsn_dim);
for i=1:length(testing.videos)
	ind = find(strcmp(hollywood2_test_videos,testing.videos(i)));
        tsn_data = test_rgb_features(ind(1),:);
        tsn_data = tsn_data / norm(tsn_data);

        video_tsn_rgb_features(i,:) = tsn_data;
end

parsave(fullfile('./testing', sprintf('encoded_features_tsn_rgb.mat')), video_tsn_rgb_features);

%% load tsn flow features
video_tsn_flow_features = zeros(length(testing.videos), 4*tsn_dim);
for i=1:length(testing.videos)
        ind = find(strcmp(hollywood2_test_videos,testing.videos(i)));
        tsn_data = test_flow_features(ind(1),:);
        tsn_data = tsn_data / norm(tsn_data);

        video_tsn_flow_features(i,:) = tsn_data;
end

parsave(fullfile('./testing', sprintf('encoded_features_tsn_flow.mat')), video_tsn_flow_features);


%% compute dist and kernels
compute_dist_testing('ChiSquared','./training','./testing',channels);
compute_kernels_testing(descriptors,channels,combine_descriptors,'./training','./testing');

%% test
for id=1:length(descriptors)
        fprintf('Testing SVMs: descriptor %d/%d (%s)\n', id, length(descriptors), descriptors{id});
        kernel2 = parload(fullfile('./testing', sprintf('kernel_%s.mat', descriptors{id})));

	prb = zeros(length(testing.videos), num_classes);
	K2 = [(1:size(kernel2,1))', kernel2];

	models = parload(fullfile('./training', sprintf('models_%s.mat', descriptors{id})));
	for m=1:length(models)
    		fprintf('Testing with SVM %d\n', m);
    		[~,~,p] = svmpredict(zeros(size(kernel2,1),1), K2, models{m} ,'-b 1 -q');
    		prb(:,m) = p(:,models{m}.Label==1);
	end
	[~,cls] = max(prb, [], 2);
	%cls = cls - 1;
	for i=1:length(testing.videos)
        	class(i).(descriptors{id}) = cls(i);
                probs(i).(descriptors{id}) = prb(i,:);
        end

end
%conf_matrix = confusionmat(testing.video_gt,class);
conf_matrix = confMatrix_multiclass(class,testing.video_gt,num_classes);
accuracy = compute_accuracy(class, testing.video_gt);
disp(accuracy)
parsave(fullfile('./testing', 'results.mat'), accuracy, conf_matrix, class, probs);
