%变到达概率仿真配置函数
% ["Manual", "Random", "weight-based Random", "Greedy", "weight-based Greedy", "Proportion", ...
%     "ProportionPro", "ProportionNB", "ProportionNBPro", "Ladder", "FastLadder", "LadderPro", "FastLadderPro", ...
%     "weight-based LP", "weight-based FLP", "Hybrid", "FastHybrid", "TG", "proportion-based Random", "MWAoI"， "WIP"];
function stc = config_benchmark_lbd
    stc = lab_init_stc(false);
    stc.type = "LBN";
    stc.strategy = ["MWAoI", "LadderPro"];
    stc.terminal_num = 100;
    stc.ts = 1e+3;
    stc.pn = (linspace(0.1, 0.1, stc.terminal_num))';
    stc.alpha = (linspace(1, 1, stc.terminal_num))';
    stc.lambda = (0.05:0.05:0.95)'; 
end