function ratio_construction(split,ratio)

system('rm models.mat');

%actions = {'climb_stairs', 'cry', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'pick', ...
%'point__at_something', 'ride_horse', 'running', 'sitting_down', 'sitting_up', 'smile', 'standing_up', 'throw', 'turn', 'walk', 'wave_hands'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

%num = [43, 59, 45, 36, 45, 40, 38, 51, 62, 75, 80, 99, 54, 29, 146, 76, 30, 198, 446, 126];

%num = 29;

%actions = {'climb_stairs', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'sitting_down', 'sitting_up', 'throw'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

%num = [44, 45, 36, 45, 40, 38, 51, 54, 29, 30];

actions = {'cry', 'pick', 'point__at_something', 'ride_horse', 'running', 'smile', 'standing_up', 'wave_hands'};

actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

num = [59, 62, 75, 80, 99, 146, 76, 126];

fid = fopen([split '_list.txt'],'r');
o = textscan(fid, '%s %d %d');
fclose(fid);

fid_new = fopen([split '_equal_list.txt'],'wt');
fid_test = fopen('test_equal_list.txt','wt');

DT_folder = dir('/Data/mov_cvsp_DT');
DT_names = extractfield(DT_folder,'name');
DT_names = DT_names(3:end);

[~, training.clips] = cellfun(@(x) fileparts(x), o{1}, 'UniformOutput', false);
[training.videos, idx] = unique(training.clips);
training.clip_video_id = cellfun(@(x) find(strcmp(x, training.videos)), training.clips);

count = zeros(1,length(actions));
video_names = training.videos;

check = (count==ceil(ratio.*num));

while ~all(check)
	id = ceil(rand*length(video_names));
	str = strsplit(video_names{id},'_');
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

 	cls = find(strcmp(label,actions)==1);
	if isempty(cls)
		continue;
	else
		if check(cls)
			continue;
		end
	end

	% check DT consistency
	if ~ismember([video_names{id} '.mat'],DT_names)
		continue;
	end

	lines = find(strcmp(training.clips,video_names(id)));
	for i=1:length(lines)
		fprintf(fid_new,[o{1}{lines(i)} ' ' num2str(o{2}(lines(i))) ' ' num2str(cls) '\n']);
	end	

	video_names{id} = ' ';

	count(cls) = count(cls)+1;
	check = (count==ceil(ratio.*num));

end

for id=1:length(video_names)
	if strcmp(video_names(id),' ') == 0 
		lines = find(strcmp(training.clips,video_names(id)));
	        for i=1:length(lines)
        	        fprintf(fid_test,[o{1}{lines(i)} ' ' num2str(o{2}(lines(i))) ' 0\n']);
        	end
	end
end

end
