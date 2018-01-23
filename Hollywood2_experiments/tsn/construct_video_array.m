function construct_video_array()

	fid = fopen('hollywood2_train_list.txt','r');

	count = 0;
	line = fgets(fid);
    	while ischar(line)
                str = strsplit(line,',');
		video = str{1}(3:end-1);	
		disp(video);

		count = count+1;
		hollywood2_train_videos{count} = video;

                line=fgets(fid);
        end
	fclose(fid);
	
	save('hollywood2_train_videos','hollywood2_train_videos');
end

