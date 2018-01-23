function features = extractFeatures(clip, params, varargin)
switch params.type
    case 'DT'
        features = extractDT(clip, params);
    case 'harris3d'
        features = extractSTIP(clip, params);
    case 'dense'
        features = extractSTIP(clip, params);        
    otherwise
        error('Unrecognized feature: %s\n', params.type);
end
end

function features = extractDT(clip, params)

%% Set environmental variable
if exist(params.libs, 'file')
    ffmpeglibsPath = params.libs;
else
    ffmpeglibsPath = '/usr/local/lib/';
end

ldPath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH',ffmpeglibsPath);

%% Extract features
if (clip.startFrame<0)||(clip.endFrame<1)
    % redirect sdterr (2>/dev/null) to mute fucking ffmpeg errors
    command = sprintf('%s %s -L %d -W %d -N %d -s %d -t %d 2>/dev/null',...
        params.executable, clip.file, params.L, params.W, params.N, params.s, params.t);
else
    % note: segments are annotated starting from frame 1, DenseTrack
    % counts frames starting from 0
    command = sprintf('%s %s -S %d -E %d -L %d -W %d -N %d -s %d -t %d 2>/dev/null',...
        params.executable, clip.file, clip.startFrame-1, clip.endFrame -1,...
        params.L, params.W, params.N, params.s, params.t);
end
% file_size = extractfield(dir(clip.file), 'bytes')/(1024*1024); % file size in MB
if isfield(params, 'use_disk') && params.use_disk
    % some videos (Hollywood) are very big, features result >1GB, and "system" crashes matlab
    [~, file_name] = fileparts(clip.file);
    temp_file = fullfile(params.path, sprintf('temp_%s', file_name));
    command = sprintf('%s > %s', command, temp_file);
    status = system(command);
    cmdout = fopen(temp_file);
else
    [status, cmdout] = system(command);    
end
if status
    error('Error extracting features');
end

%% Parse features
format = repmat('%f\t', 1, 10+2*params.L+3*96+108); format = format(1:end-2);
f = textscan(cmdout, format);
if ~isempty(f)
    f = horzcat(f{:});
    features.info = f(:,1:10);
    for ii=1:length(params.descriptors)
        switch params.descriptors{ii}
            case 'Traj'
                features.Traj = f(:,11:10+2*params.L);
            case 'HOG'
                features.HOG = f(:,10+2*params.L+1:10+2*params.L+96);
            case 'HOF'
                features.HOF = f(:,10+2*params.L+96+1:10+2*params.L+96+108);
            case 'MBHx'
                features.MBHx = f(:,10+2*params.L+96+108+1:10+2*params.L+2*96+108);
            case 'MBHy'
                features.MBHy = f(:,10+2*params.L+2*96+108+1:10+2*params.L+3*96+108);
            case 'MBH'
                features.MBH = f(:,10+2*params.L+96+108+1:10+2*params.L+3*96+108);
            otherwise
                error('Unrecognized descriptor: %s\n', params.descriptors{ii})
        end
    end
end

if isfield(params, 'use_disk') && params.use_disk
    fclose(cmdout);
    delete(temp_file);
end

end

function features = extractSTIP(clip, params)
%% Set environmental variable
if exist(params.libs, 'file')
    ffmpeglibsPath = params.libs;
else
    ffmpeglibsPath = '/usr/local/lib/';
end

ldPath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH',ffmpeglibsPath);

%% Extract features
[path, video_name, ext] = fileparts(clip.file);
% list_file_name = fullfile(path, sprintf('%s_list.txt', video_name));
if isfield(clip, 'file_orig')
    [path, video_name_orig, ext] = fileparts(clip.file_orig);
    list_file_name_orig = sprintf('%s_list.txt', video_name_orig);
    list_file_fid = fopen(list_file_name_orig, 'w');
    fprintf(list_file_fid, video_name_orig);
    list_file_name = sprintf('./%s_list.txt', video_name);
else
    list_file_name = sprintf('%s_list.txt', video_name);
    list_file_fid = fopen(list_file_name, 'w');
    fprintf(list_file_fid, video_name);
end
if (clip.startFrame>0)||(clip.endFrame>0)
    fprintf(list_file_fid, sprintf(' %d %d', clip.startFrame-1, clip.endFrame-1));
    % note: segments are annotated starting from frame 1, stipdet counts frames starting from 0
end
fprintf(list_file_fid, sprintf('\n'));
fclose(list_file_fid);
if isfield(clip, 'file_orig')
    command = sprintf('%s -i %s -vpath %s -ext %s -det %s -descr hoghof-szf -%d -tzf %d -nplev %d -plev0 %d -vis no -stdout yes 2>/dev/null', ...
    params.executable, list_file_name, fullfile(path,'/'), ext, params.type, params.szf, params.tzf, params.nplev, params.plev0);
else
    % redirect sdterr (2>/dev/null) to mute fucking ffmpeg errors
    command = sprintf('%s -i %s -vpath %s -ext %s -det %s -descr hoghof-szf -%d -tzf %d -nplev %d -plev0 %d -vis no -stdout yes 2>/dev/null', ...
        params.executable, list_file_name, fullfile(path,'/'), ext, params.type, params.szf, params.tzf, params.nplev, params.plev0);
end

[status, cmdout] = system(command);
if status
    error('Error extracting features');
end
if isfield(clip, 'file_orig')
    delete(list_file_name_orig);
else
    delete(list_file_name);
end
cmdout_lines = strsplit(cmdout, '\n');
nomempty_lines = cellfun(@(x) ~isempty(x), cmdout_lines);
cmdout_lines = cmdout_lines(nomempty_lines);
uncommented_lines = cell2mat(cellfun(@(x) x(1)~='#', cmdout_lines, 'UniformOutput', false));
cmdout_lines = cmdout_lines(uncommented_lines);
cmdout = strjoin(cmdout_lines, '\n');
if isempty(cmdout)
    warning('NO features detected\n')
    disp(clip);
    for ii=1:length(params.descriptors)
        features.(params.descriptors{ii}) = [];
    end
    features.info = [];
    return;
end
format = repmat('%f ', 1, 9+162); format = format(1:end-1);
f = textscan(cmdout, format); % read the features
f = horzcat(f{:});

features.info = f(:,1:9);
for ii=1:length(params.descriptors)
    switch params.descriptors{ii}
        case 'HOG'
            features.HOG = f(:,10:10+72-1);
        case 'HOF'
            features.HOF = f(:,10+72:10+72+90-1);
        case 'HOGHOF'
            features.HOGHOF = f(:,10:10+72+90-1);
        otherwise
            error('Unrecognized descriptor: %s\n', params.descriptors{ii})
    end
end
% rearrange and augment features' info so x-norm y-norm t-norm positions are consistent
% with DenseTrack's ones for spatiotemporal pyramids
% point-type sigma2 tau2 x y t x-norm y-norm t-norm 
features.info = f(:,[1 1 9 8 5 6 7 3 2 4]);
    

end

% if any(strcmp(params.descriptors, 'HOGHOF'))
%     format = repmat('%f ', 1, 9+162); format = format(1:end-1);
% elseif any(strcmp(params.descriptors, 'HOG')) && ~any(strcmp(params.descriptors, 'HOF'))
%     format = repmat('%f ', 1, 9+72); format = format(1:end-1);
% else
%     format = repmat('%f ', 1, 9+90); format = format(1:end-1);
% end
