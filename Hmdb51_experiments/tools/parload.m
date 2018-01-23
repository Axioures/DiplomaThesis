function [result] = parload(file)
	tmp = load(file);
	f = fieldnames(tmp);
	if length(f)==1
		result = tmp.(f{1});
	else
		result = tmp;
	end
end