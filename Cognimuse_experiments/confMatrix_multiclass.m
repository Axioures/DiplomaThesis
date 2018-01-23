function confusion_matrix = confMatrix_multiclass(classes, annotation, num_classes)

	if isstruct(classes)

		fields = fieldnames(classes);

		for f=1:length(fields)

			confusion_matrix.(fields{f}) = confMatrix_multiclass([classes.(fields{f})], annotation, num_classes);

		end

    else

        tmp=unique(annotation);

        for i=1:length(tmp)

            annotation(annotation==tmp(i))=i;

            classes(classes==tmp(i))=i;

        end

		confusion_matrix = confMatrix( annotation,classes, num_classes);

	end

end
