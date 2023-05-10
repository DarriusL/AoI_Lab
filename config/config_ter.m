%变终端数仿真配置函数
% ["Manual", "Random", "weight-based Random", "Greedy", "weight-based Greedy", "Proportion", ...
%     "ProportionPro", "ProportionNB", "ProportionNBPro", "Ladder", "FastLadder", "LadderPro", "FastLadderPro", ...
%     "weight-based LP", "weight-based FLP", "Hybrid", "FastHybrid", "TG", "proportion-based Random", "MWAoI"， "WIP"];
function stc = config_ter
    stc = lab_init_stc(false);
    stc.type = "TER";
    stc.strategy = ["WIP", "LadderPro"];
    stc.terminal_num = ([10, 50, 100, 500, 1000])';
    stc.ts = 1e+6;
    
    stc.lambda = cell(length(stc.terminal_num), 1);
    stc.pn = cell(size(stc.lambda));
    stc.alpha = cell(size(stc.lambda));
    for i = 1:length(stc.terminal_num)
        stc.lambda{i} = (linspace(0.5, 0.5, stc.terminal_num(i)))';
        stc.pn{i} = 0*ones(stc.terminal_num(i), 1);
        stc.alpha{i} = (linspace(1, 1, stc.terminal_num(i)))';
    end
end