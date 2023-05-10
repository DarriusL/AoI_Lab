%变时隙仿真配置函数
% ["Manual", "Random", "weight-based Random", "Greedy", "weight-based Greedy", "Proportion", ...
%     "ProportionPro", "ProportionNB", "ProportionNBPro", "Ladder", "FastLadder", "LadderPro", "FastLadderPro", ...
%     "weight-based LP", "weight-based FLP", "Hybrid", "FastHybrid", "TG", "proportion-based Random", "MWAoI"];
function stc = config_benchmark_tsc
    stc = lab_init_stc(false);
    stc.strategy = ["weight-based Random", "weight-based Greedy", "ProportionNB"];
    stc.terminal_num = 100;
    stc.ts = (([1, 5, 10, 50, 1e+2, 1e+3])*1e+4)';
    stc.pn = (linspace(0, 0, stc.terminal_num))';
    stc.lambda = (linspace(0.5, 0.5, stc.terminal_num))'; 
    stc.alpha = (linspace(1,  1, stc.terminal_num))';
end