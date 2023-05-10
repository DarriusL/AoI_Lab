%变终端数仿真配置函数
% ["Manual", "Random", "weight-based Random", "Greedy", "weight-based Greedy", "Proportion", ...
%     "ProportionPro", "ProportionNB", "ProportionNBPro", "Ladder", "FastLadder", "LadderPro", "FastLadderPro", ...
%     "weight-based LP", "weight-based FLP", "Hybrid", "FastHybrid", "TG", "proportion-based Random", "MWAoI"];
function stc = config_benchmark_ter
    stc = lab_init_stc(false);
    stc.type = "TER";
    stc.strategy = ["MWAoI", "LadderPro"];
    stc.terminal_num = ([5 10 40 60 80 100])';
    stc.ts = 1e+3;
    
    stc.lambda = cell(length(stc.terminal_num), 1);
    stc.pn = cell(size(stc.lambda));
    stc.alpha = cell(size(stc.lambda));
    for i = 1:length(stc.terminal_num)
        stc.lambda{i} = (linspace(0.5, 0.5, stc.terminal_num(i)))';
        stc.pn{i} = 0*ones(stc.terminal_num(i), 1);
        stc.alpha{i} = (linspace(1, 1, stc.terminal_num(i)))';
    end
end