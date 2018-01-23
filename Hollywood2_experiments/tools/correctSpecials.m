function [videos2bash] = correctSpecials(videos)
	% videos: cell array of strings
	videos2bash = regexprep(videos,'(','\\('); 
	videos2bash = regexprep(videos2bash,')','\\)');
	videos2bash = regexprep(videos2bash,'&','\\&');
    videos2bash = regexprep(videos2bash,'#','\\#');
	videos2bash = regexprep(videos2bash,';','\\;');
    videos2bash = strcat('./', videos2bash);
end