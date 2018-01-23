function text_conc_2(split)

        fid_train = fopen('./trainlist01.txt','wt');

	fid = fopen([split '_list.txt'],'r');


	actions = {'cry', 'pick', 'point__at_something', 'ride_horse', 'running', 'smile', 'standing_up', 'wave_hands'};

	actions_segm = {'stairs','floor','hand','door','down','up','something','horse','hands'};
     	
	
	line = fgets(fid);
    	while ischar(line)
		space = strfind(line,' ');
		line = line(1:(space-1));
                disp(line);
                str = strsplit(line,'/');
		str2 = strsplit(str{end},'_');
		if ismember(str2{end},actions_segm)
                	switch str2{end}
                        	case 'something'
                                	label = 'point__at_something';
                        	case 'floor'
                                	label = 'fall_on_the_floor';
                        	otherwise
                                	label = strcat(str2{end-1},'_',str2{end});
                	end
        	else
                	label = str2{end};
        	end

		fprintf(fid_train,[label '/' str{end} '.avi 1\n']);
                line=fgets(fid);
        end
        fclose(fid); fclose(fid_train);

end

