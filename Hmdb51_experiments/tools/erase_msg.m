function [] = erase_msg(msg_size, varargin)
	if (nargin > 2) && (islogical(varargin{1}) || isnumeric(varargin{1})) && varargin{1}
		fprintf('\n');
	else
		fprintf(repmat('\b', 1, msg_size));
		fprintf(repmat(' ', 1, msg_size));
		fprintf(repmat('\b', 1, msg_size));
	end
end
