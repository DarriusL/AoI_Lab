function check_lab
    zipfile = dir("*.zip");
    if ~isempty(zipfile)
        for i = 1:length(zipfile)  
            delete(zipfile(i).name);
        end
    end
    path = ["./aoi_lab", "./config", "./data","./lib", ...
        "./model"];
    filename = ["run_lab.m", "SetCurrentFile.m", "check_lab.m", "lab_init_stc.m", ...
        "lab_strategy.m", "lab_type.m", "run_sim.m", "save_lab.m", "zip_lab.m", ...
        "config_lbd.m", "config_pn.m", "config_ter.m", "config_tsc.m", ...
        "cdtstm_util.m", "path_util.m", "util.m", "Strategy.m", "System.m", ...
        "Terminal.m", "Top.m"];
    %关键路径和文件检查
    if ~path_util().chk_pf(path, filename)
        error("关键路径/文件不存在，AoI Lab无法运行")
    end

end