function save_lab(obj, stc, fig_cell)
    mdir = path_util().make_dir;
    if nargin == 2
        fig_cell = empty;
    end
    new_folder = "./data/" + string(date);
    mdir(new_folder);
    day = char(datetime);
    time = day(12:end);
    time(time == ':') = '_';
    time = string(time);
    types = lab_type();
    switch stc.type
        %变时隙
        case types(1)
            filename = "TSC_ 1e+" + string(floor((log10(max(stc.ts))))) + "_" + string(stc.terminal_num) +"_"+ string(min(stc.lambda)) + "--" + string(max(stc.lambda)) + "_" + ...
            string(min(stc.pn)) + "--" + string(max(stc.pn));
        %变终端
        case types(2)
            filename = "TER_ 1e+" + string(floor((log10(max(stc.ts))))) + "_" + string(min(stc.terminal_num)) + "--" + string(max(stc.terminal_num)) ...
            +"_"+ string(min(stc.lambda{end})) + "--" + string(max(stc.lambda{end})) + "_" + string(min(stc.pn{end})) + "--" + string(max(stc.pn{end}));
        %变传输失败概率
        case types(3)
            filename = "PnC_ 1e+" + string(floor((log10(max(stc.ts))))) + "_" + string(stc.terminal_num) +"_"+ string(min(stc.lambda)) + "--" + string(max(stc.lambda)) + "_" + ...
            string(min(stc.pn)) + "--" + string(max(stc.pn));
        %变到达概率
        case types(4)
            filename = "LBD_ 1e+" + string(floor((log10(max(stc.ts))))) + "_" + string(stc.terminal_num) +"_"+ string(min(stc.lambda)) + "--" + string(max(stc.lambda)) + "_" + ...
            string(min(stc.pn)) + "--" + string(max(stc.pn));
    end
    folder = new_folder + "/[" + time + "]" + filename;
    mdir(folder);
    filename_obj = folder + "/" + filename + ".mat";
    save(filename_obj, 'obj');
    if ~isempty(fig_cell)
        filename_fig =  folder + "/wpAoI_avg.fig";
        savefig(fig_cell{1}, filename_fig);
 
        filename_fig =  folder + "/wAoI_avg.fig";
        savefig(fig_cell{2}, filename_fig);
 
        filename_fig =  folder + "/pAoI_max.fig";
        savefig(fig_cell{3}, filename_fig);
    end
    disp(['数据已存储在：', char(folder)]);
    msgbox(['数据已存储在：', char(folder)], "reminder");
end