function [enc, empty] = aggregate_encodings(input_path, output_path, clips)
	f0 = parload(fullfile(input_path, sprintf('%s.mat', clips{1})));
	d = fieldnames(f0);
	empty = [];
	enc = init_struct_array(d,length(clips));
	for i=1:length(clips)
    		e = parload(fullfile(input_path, sprintf('%s.mat', clips{i})));
  	  	if isempty(e)
        		empty = [empty i];
    		else
        		enc(i) = e;
    		end
	end
	enc(empty) = [];
	for id = 1:length(d)
    		encoded_features = cell2mat({enc.(d{id})}');
    		parsave(fullfile(output_path, sprintf('encoded_features_%s.mat', d{id})), encoded_features);
end

