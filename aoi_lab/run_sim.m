function obj = run_sim(fun_stc, save_)
    stc = fun_stc();
    if nargin == 1
        save_ = 0;
    end
    types = lab_type();
    assert(ismember(stc.type, types));
    assert(all(ismember(stc.strategy, lab_strategy())));

    pause(1)
    disp(['[type]:', char(stc.type)]);
    pause(0.4)
    disp('[strategy]:');
    disp(stc.strategy);
    pause(0.4)
    disp('[terminal_num]:');
    disp(stc.terminal_num')
    pause(0.4)
    disp('[pn]:');
    disp(stc.pn');
    pause(0.4)
    disp('[alpha]:');
    disp(stc.alpha');
    pause(0.4)
    disp('[lambda]:');
    disp(stc.lambda');
    pause(0.4)
    disp('[ts]:')
    disp(stc.ts');
    pause(1)

    sn = length(stc.strategy);
    tern = stc.terminal_num;
    tsc = stc.ts;
    lambda = stc.lambda;
    pn = stc.pn;
    s = stc.strategy;
    alpha = stc.alpha;
    rm = stc.random_mode;
    sm = stc.simulation_mode;
    switch stc.type
        %变时隙
        case types(1)
            tn = length(stc.ts);
            obj = Top("TimeSlot", tn, sn, tern, tsc, lambda, pn, s, alpha, rm, sm);
            log_axis = 1;
        %变终端
        case types(2)
            tn = length(tern);
            obj = Top("TermianlNumber", tn, sn, tern, tsc, lambda, pn, s, alpha, rm, sm);
            log_axis = 0;
        %变传输失败概率
        case types(3)
            tn = length(pn);
            obj = Top("Pn", tn, sn, tern, tsc, lambda, pn, s, alpha, rm, sm);
            log_axis = 0;
        %变到达概率
        case types(4)
            tn = length(lambda);
            obj = Top("Lambda", tn, sn, tern, tsc, lambda, pn, s, alpha, rm, sm);
            log_axis = 0;
    end
    
    fig_cell = cell(3, 1);
    obj.simulate(stc.show_info); 
    fig_cell{1} = obj.show_pAoI_avg(log_axis);
    fig_cell{2} = obj.show_AoI_avg(log_axis);
    fig_cell{3} = obj.show_pAoI_max(log_axis);

    if save_
        save_lab(obj, stc, fig_cell);
    end
end