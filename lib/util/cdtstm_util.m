function stc = cdtstm_util
    stc.info = @info;
    stc.mc_switch = @mc_switch;
end

%utility function information
function info
    disp(['Conditional Judgment Related Utility Functions(cdtstm_util)', newline, ...
        '----------------------------------------------', newline, ...
        '1.mc_switch Multi-condition switch and its configuration', newline, ...
        '----------------------------------------------', newline, ]);
end

%Multi-condition switch
function stc = mc_switch
    stc.config = @mc_switch_config;
    stc.mulcon_switch = @mulcon_switch;
end

%------------------------related functions---------------------------
function stc = mc_switch_config
    %Multi-condition switch configuration
    stc.con_num = 2;
    stc.fun = cell(2, 1);
    stc.fun_con = {cell(2,1), cell(2,1)};
end

function vcell = mulcon_switch(cdt, config)
    %Multi-condition switch execution
    vcell = cell(config.con_num, 1);
    assert(length(config.fun) == config.con_num && length(config.fun_con) == config.con_num);
    for i = 1:config.con_num
        if any(ismember(cdt, cell2mat(config.fun_con{i})))
            vcell{i} = config.fun{i}();
        end
    end
end