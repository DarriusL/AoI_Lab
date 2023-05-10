function stc = lab_init_stc(show_info)
    if nargin == 0
        show_info = true;
    end
    strategy = lab_strategy(); 
    if show_info
        disp(['AoI Lab parameter', newline, ...
        '----------------------------------------', newline, ...
        'type:TSC, TER, PnC, LBN', newline, ...
        'strategy:', s2c(strategy), newline ...
        'random_mode: 0/1 (0 for completely random; 1 for same random', newline, ...
        'simulation_mode: 0/1 (0 for operate independently; 1 for relay running', newline, ...
        'show_info: 0/1       （1 for show simulation details', newline, ...
        ]);
    end
    stc.type = "TSC";
    stc.strategy = ["Random", "weight-based Random"];
    stc.random_mode = 1;
    stc.simulation_mode = 0;
    stc.show_info = 1;
    stc.terminal_num = [];
    stc.pn = [];
    stc.alpha = [];
    stc.lambda = [];
    stc.ts = [];
end

function value = s2c(Str)
    value = "";
    for i = 1:length(Str)
        value = value + ", "  + Str(i); 
    end
    value = char(value);
    value(1:2) = [];
end