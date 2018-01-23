function [] = check_nan(configFile, code_path)

if exist('code_path', 'var')
	addpath(genpath(code_path));
else
	addpath(genpath('../'));
end
params = config_parser(configFile);
switch params.dbName
    case 'KTH'
        db_params = configKTH(params.paths);
    case 'UCFSports'
        db_params = configUCFSports(params.paths);
    case 'Hollywood2'
        db_params = configHollywood2(params.paths);
    case 'HMDB51'
        db_params = configHMDB51(params.paths);
    case 'UCF101'
        db_params = configUCF101(params.paths);
    case 'MOBOT6a'
        db_params = configMOBOT6a(params.paths);
    otherwise
        error('Unrecognized database: %s', params.dbName)
end

logfile('./nan_log.txt');
diary on;
nans = [];
parfor i=1:length(db_params.clips)
    features_file = fullfile(params.paths.features, [db_params.clips(i).name '.mat']);
    if exist(features_file, 'file')
        fprintf('Checking file %s...\n', features_file)
        f = parload(features_file);
        d = fieldnames(f);
	for id = i:length(d)
	    if find(isnan(f.(d{id})))
		%nans = [nans i];
		fprintf('file %d (%s) has NaNs', i, features_file);
		break;
	    end
	end
        
    end
end

diary off;
end


