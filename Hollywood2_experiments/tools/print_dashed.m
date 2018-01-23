function [] = print_dashed(msg, varargin)
	if nargin>1 && isnumeric(varargin{1}) && varargin{1}>0
		fid = varargin{1};
	else
		fid = 1;
	end
	msg_size = length(msg);
	fprintf(fid, repmat('-', 1, msg_size+4));
	fprintf(fid, '\n');
	fprintf(fid, '| ');
	fprintf(fid, msg);
	fprintf(fid, ' |');
	fprintf(fid, '\n');
	fprintf(fid, repmat('-', 1, msg_size+4));
	fprintf(fid, '\n');
end