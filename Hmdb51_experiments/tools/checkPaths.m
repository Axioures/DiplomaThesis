function [] = checkPaths(path, mode, varargin)
if (nargin>2) && strcmp(varargin{1}, 'mute')
    mute = true;
else
    mute = false;
end

if isa(path, 'struct')
    fields = fieldnames(path);
    for i=1:numel(fields)
        new_path = path.(fields{i});
        checkPaths(new_path, mode);
    end
elseif isa(path, 'string')||isa(path, 'char')
    if ~exist(path, 'dir')
        if strcmp(mode, 'check')
            error('Path does not exist: %s\n', path);
        elseif strcmp(mode, 'create')
            try
                mkdir(path);
                if ~mute
                    fprintf(sprintf('Created path: %s\n', path));
                end
            catch
                warning('Cannot create path: %s\n', path);
            end
        else
            error('Unknown mode\n');
        end
    end
end
