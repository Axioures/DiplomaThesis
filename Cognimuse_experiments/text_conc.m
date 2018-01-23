function text_conc(varargin)

	disp(varargin{1});

	fid_train = fopen(['/home/vaggelis/mov_frames_jpg/classification/train_list.txt'],'wt');
	
	for i=2:length(varargin)

		fid = fopen(['/home/vaggelis/mov_frames_jpg/classification/' varargin{i} '_list.txt']);

		line = fgets(fid);
		while ischar(line)
			disp(line);
			fprintf(fid_train,line);
			line=fgets(fid);
		end
		fclose(fid);
	end
end
