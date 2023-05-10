function run_lab(cfg, mode)
    tic
    clearvars -except cfg mode
    close all
    clc
    SetCurrentFile;
    dbstop if error

    paths = ["./model", "./lib", "./aoi_lab", "./config"];
    addpath(genpath(paths(2)));
    path_util().add_paths(paths);

    disp('=============== AoI Lab ===============');
    check_lab
    switch nargin
        case 0
            save_ = false;
            i = randperm(4, 1);
            switch i
                case 1
                    disp('Execute by default: config_benchmark_tsc');
                    run_sim(@config_benchmark_tsc, save_);
                case 2
                    disp('Execute by default: config_benchmark_ter');
                    run_sim(@config_benchmark_ter, save_);
                case 3
                    disp('Execute by default: config_benchmark_pn');
                    run_sim(@config_benchmark_pn, save_);
                case 4
                    disp('Execute by default: config_benchmark_lbd')
                    run_sim(@config_benchmark_lbd, save_);
            end
            
        case 1
            if string(cfg) == "zip_lab"
                zip_lab
                return
            elseif string(cfg) == "zip_data"
                zip_data
                return
            end
            save_ = true;
            run_sim(eval(['@', cfg]), save_);
        case 2
            mode = string(mode);
            if mode == "test"
                save_ = false;
            else
                save_ = true;
            end
            run_sim(eval(['@', cfg]), save_);
    end

    path_util().rm_paths(paths);
    toc
end