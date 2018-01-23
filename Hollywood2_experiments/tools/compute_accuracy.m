function accuracy = compute_accuracy(prediction, annotation)
	if isstruct(prediction)
		fields = fieldnames(prediction(1));
		accuracy = init_struct_array(fields, 1);
		for f = 1:length(fields)
			accuracy.(fields{f}) = compute_accuracy([prediction.(fields{f})]', annotation);
		end
	else
		if max(size(prediction))~=max(size(annotation))
			error('Prediction and annotation should have the same size');
		end
		accuracy = sum(squeeze(prediction)==annotation) / length(annotation);
	end
end
