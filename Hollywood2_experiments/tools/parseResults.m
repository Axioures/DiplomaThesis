function [] = parseResults(dir)
% parseResults.m - quick & dirty
try
	file = fullfile(dir, sprintf('results.mat'));
	temp = load(file);
catch
	file = fullfile(dir, sprintf('results_long.mat'));
	temp = load(file);
end
%temp = load(file);
a = temp.accuracy;
f = fieldnames(a);
copy_able = zeros(length(f),1);
for i_f=1:length(f)
    copy_able(i_f) = a.(f{i_f});
end

copy_able
% copy_able = [a{:}]'

return;
    
