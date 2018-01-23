function construct_video_array()

	fid = fopen('train_list.txt','r');

	count = 0;
	line = fgets(fid);
    	while ischar(line)
		space = strfind(line,' ');
		line = line(1:(space-1));
                str = strsplit(line,'/');
		video = str{end};	
		disp(video);

		count = count+1;
		movsum_videos{count} = video;

                line=fgets(fid);
        end
	fclose(fid);
	
	save('movsum_videos','movsum_videos');
end

