%变传输失败概率仿真配置函数
% ["Manual", "Random", "weight-based Random", "Greedy", "weight-based Greedy", "Proportion", ...
%     "ProportionPro", "ProportionNB", "ProportionNBPro", "Ladder", "FastLadder", "LadderPro", "FastLadderPro", ...
%     "weight-based LP", "weight-based FLP", "Hybrid", "FastHybrid", "TG", "proportion-based Random", "MWAoI"， "WIP"];
function stc = config_pn
    stc = lab_init_stc(false);
    stc.type = "PnC";
    stc.strategy = ["WIP", "LadderPro"];
    stc.terminal_num = 100;
    stc.ts = 1e+6;
    stc.pn = (0:0.05:0.4)'; 
    stc.alpha = (linspace(1,1, stc.terminal_num))';
    stc.lambda = (linspace(0.5, 0.5, stc.terminal_num))';
end