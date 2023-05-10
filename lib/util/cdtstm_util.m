function stc = cdtstm_util
    stc.info = @info;
    stc.mc_switch = @mc_switch;
end

%实用函数信息
function info
    disp(['条件判断相关实用函数(cdtstm_util)', newline, ...
        '----------------------------------------------', newline, ...
        '1.mc_switch 多条件switch及其配置', newline, ...
        '----------------------------------------------', newline, ...
        '最后一次更新：2022-08-29']);
end

%多条件switch
function stc = mc_switch
    stc.config = @mc_switch_config;
    stc.mulcon_switch = @mulcon_switch;
end

%------------------------相关函数---------------------------
function stc = mc_switch_config
    %多条件switch配置
    stc.con_num = 2;
    stc.fun = cell(2, 1);
    stc.fun_con = {cell(2,1), cell(2,1)};
end

function vcell = mulcon_switch(cdt, config)
    %多条件switch执行
    vcell = cell(config.con_num, 1);
    assert(length(config.fun) == config.con_num && length(config.fun_con) == config.con_num);
    for i = 1:config.con_num
        if any(ismember(cdt, cell2mat(config.fun_con{i})))
            vcell{i} = config.fun{i}();
        end
    end
end