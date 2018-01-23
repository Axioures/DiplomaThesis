
training.video_list = '/home/vaggelis/hollywood2_frames_c3d/train_list.txt';
testing.video_list = '/home/vaggelis/hollywood2_frames_c3d/test_list.txt';

actions = {'AnswerPhone','DriveCar','Eat','FightPerson','GetOutCar','HandShake','HugPerson',...
                        'Kiss','Run','SitDown','SitUp','StandUp'};

fid_train = fopen('./trainlist01.txt','wt'); 
fid_test = fopen ('./testlist01.txt','wt');

%% TRAINING VIDEOS
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
                        fprintf(fid_train,[actions{j} '/' training.videos{i} '.avi 1\n']);
                end
                fclose(fid);
        end
end


%% TESTING VIDEOS
%% read testing video info
fid = fopen(testing.video_list, 'r');
o = textscan(fid, '%s %d %d');
fclose(fid);
[~, testing.clips] = cellfun(@(x) fileparts(x), o{1}, 'UniformOutput', false);
[testing.videos, idx] = unique(testing.clips);
testing.clip_video_id = cellfun(@(x) find(strcmp(x, testing.videos)), testing.clips);
testing.start_frame = o{2};
%training.clip_gt = o{3};
%training.video_gt = training.clip_gt(idx);

for i=1:length(testing.videos)
        for j=1:length(actions)
                fid = fopen(['/ssd_data/hollywood2/Hollywood2/ClipSets/' actions{j} '_test.txt'],'r');
                line = textscan(fid, '%[^\n]', 1 , 'HeaderLines', i-1);
                str = strsplit(cell2mat(line{1}));
                if strcmp(str{2},'1')
                        fprintf(fid_test,[actions{j} '/' testing.videos{i} '.avi 1\n']);
                end
                fclose(fid);
        end
end

