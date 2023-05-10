%变时隙仿真配置函数
% ["Manual", "Random", "weight-based Random", "Greedy", "weight-based Greedy", "Proportion", ...
%     "ProportionPro", "ProportionNB", "ProportionNBPro", "Ladder", "FastLadder", "LadderPro", "FastLadderPro", ...
%     "weight-based LP", "weight-based FLP", "Hybrid", "FastHybrid", "TG", "proportion-based Random", "MWAoI"， "WIP"];
function stc = config_tsc
    stc = lab_init_stc(false);
    stc.strategy = ["WIP", "MWAoI", "ProportionNB"];
    stc.terminal_num = 100;
    stc.ts = [1e+4, ceil(10^4.5), 1e+5, ceil(10^5.5), 1e+6, ceil(10^6.5), 1e+7]';
    stc.pn = (linspace(0, 0., stc.terminal_num))';
    stc.lambda = (linspace(0.5, 0.9, stc.terminal_num))'; 
    stc.alpha = (linspace(100,  1, stc.terminal_num))';
end