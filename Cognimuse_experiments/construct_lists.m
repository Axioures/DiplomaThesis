function construct_lists(movie)

fid_test = fopen([movie '_list.txt'],'wt');

%actions = {'climb_stairs', 'cry', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'pick', ...
%'point__at_something', 'ride_horse', 'running', 'sitting_down', 'sitting_up', 'smile', 'standing_up', 'throw', 'turn', 'walk', 'wave_hands'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

%actions = {'climb_stairs', 'dance', 'fall_on_the_floor', 'grab_hand', 'hugging', 'laugh', 'open_door', 'sitting_down', 'sitting_up', 'throw'};

%actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};

actions = {'cry', 'pick', 'point__at_something', 'ride_horse', 'running', 'smile', 'standing_up', 'wave_hands'};

actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};


DT_folder = dir('/Data/mov_cvsp_DT');
DT_names = extractfield(DT_folder,'name');
DT_names = DT_names(3:end);

fid = fopen(['/home/vaggelis/mov_frames_jpg/' movie '_input_list.txt'],'r');

line = fgets(fid);
while ischar(line)
	str = strsplit(line);
	str2 = strsplit(str{1},'/');
	str3 = strsplit(str2{end},'_');
 	
	if ismember(str3{end},actions_segm)
                if strcmp(str3{end},'something')
                        if strcmp(str3{end-1},'at')
                                label = 'point__at_something';
                        else
				label = strcat(str3{end-1},'_',str3{end});
			end
                else
			if strcmp(str3{end},'floor')
				label = 'fall_on_the_floor';
			else
                        	label = strcat(str3{end-1},'_',str3{end});
                	end
		end
	else
		label = str3{end};
	end

	if ~ismember([str2{end} '.mat'],DT_names)
		line=fgets(fid);
		continue;
	end

	if ismember(label,actions)
		fprintf(fid_test,line);
	end
	line=fgets(fid);
end
	
fclose(fid_test);

