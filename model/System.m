classdef System < handle
    properties(Access = public)
        system_ts       %该次仿真下的ts
        system_M        %该次仿真下的终端数
        terminal_obj    %cell simulation_num*1 终端类
        simulation_num  %仿真次数
        simulation_mode %仿真模式
        simulation_t_block
        pAoI_avg_r      %平均峰值信息年龄记录 simulation_num*1
        AoI_avg_r       %平均信息年龄记录 simulation_num*1
        pAoI_max_r      %最大峰值信息年龄记录 simulation_num*1
    end

    methods(Access = public)
        %构造函数
        function obj = System(simulation_num_in, terminal_num_in, ts_t, lambda_in, pn_in, strategy_name_in, alpha_in, random_mode, simu_mode)%所有指标统一 strategy_name_in(元胞)
            assert(simulation_num_in>0, 'simulation_num_in输入错误');
            obj.system_ts = ts_t;
            obj.system_M = terminal_num_in;
            obj.simulation_num = simulation_num_in;
            obj.terminal_obj = cell(simulation_num_in, 1);
            for i = 1:simulation_num_in
                obj.terminal_obj{i} = Terminal(terminal_num_in, max(ts_t), lambda_in, pn_in, strategy_name_in(i), alpha_in, random_mode, simu_mode);
            end
            obj.pAoI_avg_r = zeros(simulation_num_in, 1);
            obj.AoI_avg_r = zeros(simulation_num_in, 1);
            obj.pAoI_max_r = zeros(simulation_num_in, 1);
            obj.simulation_mode = simu_mode;
            obj.simulation_t_block = ts_t;
        end
        
        %开始模拟
        function [TLB, STI, MAI, TLBP] = Simulate(obj, show_info, show_info_struct)
            TLB = [];
            STI = [];
            MAI = [];
            TLBP = [];
            simu_rounds = randperm(3696, 1);
            if(show_info && (obj.simulation_mode == 0))
                disp(" ");
                disp(" ");
                disp(['[',char(datetime), '] Simulation Rounds: ',num2str(show_info_struct.rounds),'/', num2str(show_info_struct.total) ]);
            end

            for i = 1: obj.simulation_num
                [theoretical_lower_bound, sti, mai, theoretical_lower_bound_phmax] = obj.terminal_obj{i}.simulation_start(simu_rounds, obj.simulation_t_block);
                if ~isempty(theoretical_lower_bound)
                    assert(length(theoretical_lower_bound) == length(obj.simulation_t_block));
                    TLB = theoretical_lower_bound;
                end
                if ~isempty(sti)
                    assert(length(sti) == 1);
                    STI = sti;
                end
                if ~isempty(mai)
                    assert(length(mai) == 1);
                    MAI = mai;
                end
                if ~isempty(theoretical_lower_bound_phmax)
                    assert(length(theoretical_lower_bound_phmax) == 1);
                    TLBP = theoretical_lower_bound_phmax;
                end
            end
            obj.Calculate();
            if(show_info && (obj.simulation_mode == 0))
                for i = 1: obj.simulation_num
                        disp([char(obj.terminal_obj{i}.strategy.strategy_name),':', repmat(' ', 1, (22 - length(char(obj.terminal_obj{i}.strategy.strategy_name)))), ...
                            'max arrival interval:', num2str(obj.terminal_obj{i}.max_arrival_interval(end - 1)), newline, ...
                            repmat(' ', 1, 23), 'wpAoI_avg:', num2str(obj.pAoI_avg_r(i)), newline, ...
                            repmat(' ', 1, 23), 'pAoI_max :', num2str(obj.pAoI_max_r(i)), newline ...
                            '----------------------------------------------']);
                end
            end
            if(obj.simulation_mode == 1 && show_info)
                for rounds = 1:length(obj.system_ts)
                    ts_tem_top = obj.system_ts(rounds);
                    disp(['[',char(datetime), '] Simulation Rounds( ',num2str(rounds),' / ', num2str(length(obj.system_ts)) ,') ']);
                    for i = 1: obj.simulation_num
                        disp([char(obj.terminal_obj{i}.strategy.strategy_name), ' '*(25 - length(obj.terminal_obj{i}.strategy.strategy_name)), ...
                            ': max arrival interval:', num2str(obj.terminal_obj{i}.max_arrival_interval(ts_tem_top)), newline, ...
                            ' '*25, 'wpAoI_avg:', num2str(obj.pAoI_avg_r(i)), newline, ...
                            ' '*25, 'pAoI_max :', num2str(obj.pAoI_max_r(i)), newline]);
                    end
                end
            end

        end


        %绘图，所有系统每个终端的pAoI比较（固定的）
        function [pic_obj, ax_obj, figure_obj] = Show_System_pAoI(obj, simulation_order)
            [pic_obj, ax_obj, figure_obj] = obj.terminal_obj{simulation_order}.pic_pAoIavg();
        end

        %计算每次模拟平均峰值信息年龄
        function Calculate(obj)
            if(obj.simulation_mode == 0)
                for i = 1:obj.simulation_num
                     value_struct = obj.terminal_obj{i}.calculate(obj.system_ts);
                     obj.pAoI_avg_r(i) = value_struct.phavg;
                     obj.AoI_avg_r(i) = value_struct.AoI_avg_system;
                     obj.pAoI_max_r(i) = value_struct.pAoI_max_system;
                end
            elseif(obj.simulation_mode == 1)
                %重构大小
                obj.pAoI_avg_r = zeros(obj.simulation_num, length(obj.system_ts));
                obj.AoI_avg_r = zeros(obj.simulation_num, length(obj.system_ts));
                obj.pAoI_max_r = zeros(obj.simulation_num, length(obj.system_ts));
                for i = 1:obj.simulation_num
                     value_struct = obj.terminal_obj{i}.calculate(obj.system_ts);
                     obj.pAoI_avg_r(i, :) = value_struct.phavg;
                     obj.AoI_avg_r(i, :) = value_struct.AoI_avg_system;
                     obj.pAoI_max_r(i, :) = value_struct.pAoI_max_system;
                end
            end
        end
    end
end