function [] = print_n_log(message, logfile)

fprintf(1, message);
if exist('logfile', 'var')
    fid = fopen(logfile, 'a');
    fprintf(message)
    fclose(fid);
end
