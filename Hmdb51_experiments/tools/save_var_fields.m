function [] = save_var_fields(var, prefix, path)
    fields = fieldnames(var);
    for f=1:length(fields)
		v = cell2mat({var.(fields{f})}');
        eval([prefix ' = v;']);
        parsave(fullfile(path, sprintf('%s_%s.mat', prefix, fields{f})), encoded_features);
    end
end