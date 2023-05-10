classdef Top < handle
    properties(Access = public)
        type %改变的变量 char
        total_num %总的次数
        pAoI_avg_r %平均峰值信息年龄记录
        AoI_avg_r  %平均信息年龄记录
        pAoI_max_r  %最大信息年龄记录

        system_obj %系统对象
        
        theoretical_lower_bound
        suc_trans_interval
        max_arr_interval
        theoretical_lower_bound_phmax
        strategy_name
        x_var

        random_mode
        simu_mode
    end

    methods(Access = public)
        %构造函数
        function obj = Top(type_in, total_num_in, simulation_num_in, terminal_num_in, ts_t, lambda_in, pn_in, strategy_name_in, alpha_in, random_mode_in, simu_mode_in)
            %f = @(alpha) 1/(sum(alpha))*sum(sqrt(alpha)*sum(sqrt(alpha)))+1;
            %simulation_mode 0 - 完全随机模式  1 - 相同随机模式
            obj.type = type_in;
            obj.total_num = total_num_in;
            obj.pAoI_avg_r = zeros(simulation_num_in, total_num_in);
            obj.AoI_avg_r = zeros(simulation_num_in, total_num_in);
            obj.pAoI_max_r = zeros(simulation_num_in, total_num_in);
            obj.suc_trans_interval = zeros(total_num_in, 1);
            obj.max_arr_interval = zeros(total_num_in, 1);
            obj.theoretical_lower_bound = zeros(total_num_in, 1);
            obj.system_obj = cell(total_num_in, 1);
            obj.theoretical_lower_bound_phmax = zeros(total_num_in, 1);
            obj.strategy_name = strategy_name_in;
            obj.simu_mode = simu_mode_in;
            switch type_in
                case "TermianlNumber"
                    %此时输入的terminal_num应为total_num_in*1
                    assert(length(terminal_num_in) == total_num_in, 'terminal_num_in输入维度错误');
                    obj.simu_mode = 0;              %变终端数的情况下只能为独立运行
                    obj.x_var = terminal_num_in;
                    for i = 1:total_num_in
                        obj.system_obj{i} = System(simulation_num_in, terminal_num_in(i), ts_t, lambda_in{i}, pn_in{i}, strategy_name_in, alpha_in{i}, random_mode_in, obj.simu_mode);
                        %obj.theoretical_lower_bound(i) = f(alpha_in{i});
                    end
                case "TimeSlot" 
                    %此时输入的ts应为total_num_in*1
                    assert(length(ts_t) == total_num_in, 'ts_t输入维度错误');
                    if(length(ts_t) == 1)
                        obj.simu_mode = 0;          %没有必要接力运行
                    end
                    obj.x_var = ts_t;
                    %obj.theoretical_lower_bound = repmat(f(alpha_in), 1, total_num_in);
                    if(obj.simu_mode == 0)  %独立运行模式
                        for i = 1:total_num_in
                            obj.system_obj{i} = System(simulation_num_in, terminal_num_in, ts_t(i), lambda_in, pn_in, strategy_name_in, alpha_in, random_mode_in, obj.simu_mode);
                        end
                    else                    %接力运行模式
                        obj.system_obj = System(simulation_num_in, terminal_num_in, ts_t, lambda_in, pn_in, strategy_name_in, alpha_in, random_mode_in, obj.simu_mode);
                    end
                case "Lambda"
                    %此时输入的lambda应为total_num_in*1
                    assert(length(lambda_in) == total_num_in, 'lambda_in输入维度错误');
                    obj.simu_mode = 0;              %变到达概率的情况下只能为独立运行
                    obj.x_var = lambda_in;
                    for i = 1:total_num_in
                        obj.system_obj{i} = System(simulation_num_in, terminal_num_in, ts_t, lambda_in(i)*ones(terminal_num_in, 1), pn_in, strategy_name_in, alpha_in, random_mode_in, obj.simu_mode);
                    end
                case "Pn"
                    %此时输入的pn应为total_num_in*1
                    assert(length(pn_in) == total_num_in, 'pn_in输入维度错误');
                    obj.simu_mode = 0;              %变传输失败概率的情况下只能为独立运行
                    obj.x_var = pn_in;
                    for i = 1:total_num_in
                        obj.system_obj{i} = System(simulation_num_in, terminal_num_in, ts_t, lambda_in, pn_in(i)*ones(terminal_num_in, 1), strategy_name_in, alpha_in, random_mode_in, obj.simu_mode);
                    end
            end
            obj.random_mode = random_mode_in;
        end
        %模拟
        function simulate(obj, show_info)
            random_show = {'completely random', 'same random'};
            simu_show = {'operate independently', 'relay running'};
            if(show_info)
                disp(['[',char(datetime), '] #simulation starts...#']);
                disp(['Type: ', char(obj.type)]);
                disp(['Random mode:', random_show{(obj.random_mode + 1)}]);
                disp(['Simulation mode:', simu_show{(obj.simu_mode + 1)}]);
            end
            
            if(obj.simu_mode == 0)
                for i = 1:obj.total_num
                    show_info_struct.rounds = i;
                    show_info_struct.total = obj.total_num;
                    [TLB, sti, mai, TLBP] = obj.system_obj{i}.Simulate(show_info, show_info_struct);
                    if ~isempty(TLB)
                        obj.theoretical_lower_bound(i) = TLB;
                    end
                    if ~isempty(sti)
                        obj.suc_trans_interval(i) = sti;
                    end
                    if ~isempty(mai)
                        obj.max_arr_interval(i) = mai;
                    end
                    if ~isempty(TLBP)
                        obj.theoretical_lower_bound_phmax(i) = TLBP;
                    end
                end
    
            elseif(obj.simu_mode == 1)
                TLB = obj.system_obj.Simulate(show_info, 0);
                if ~isempty(TLB)
                    assert(length(TLB) == obj.total_num)
                    obj.theoretical_lower_bound = TLB;
                end
            end
            obj.calculate();
        end

        %计算平均峰值信息年龄
        function calculate(obj)
            if(obj.simu_mode == 0)
                for i = 1:obj.total_num
                    %每列对应同一x下，不同策略的值
                    %最终结果每行对应同一策略
                    obj.pAoI_avg_r(:, i) = obj.system_obj{i}.pAoI_avg_r;
                    obj.AoI_avg_r(:, i) = obj.system_obj{i}.AoI_avg_r;
                    obj.pAoI_max_r(:, i) = obj.system_obj{i}.pAoI_max_r;
                end
            elseif(obj.simu_mode == 1)
                    %每列对应同一x下，不同策略的值
                    %最终结果每行对应同一策略
                    obj.pAoI_avg_r = obj.system_obj.pAoI_avg_r;
                    assert(all(size(obj.pAoI_avg_r) == [length(obj.strategy_name), length(obj.x_var)]));
                    obj.AoI_avg_r = obj.system_obj.AoI_avg_r;
                    obj.pAoI_max_r = obj.system_obj.pAoI_max_r;
            end
        end
        
        %效果对比pAoI_avg
        function [figure_obj, ax_obj] = show_pAoI_avg(obj, sl_flag)
            f = @(para) string(para) == "ProportionNB";
            if(any(f(obj.strategy_name)))
                [figure_obj, ax_obj] = obj.show(obj.x_var, obj.pAoI_avg_r, obj.theoretical_lower_bound, '\bf{Weighted average of pAoI}', ...
                    obj.strategy_name, 'theoretical lower bound', sl_flag);
            else
                [figure_obj, ax_obj] = obj.show(obj.x_var, obj.pAoI_avg_r, [], '\bf{Weighted average of pAoI}', ...
                    obj.strategy_name, 'theoretical lower bound', sl_flag);
            end
        end
        %效果对比 AoI_avg
        function [figure_obj, ax_obj] = show_AoI_avg(obj, sl_flag)
            [figure_obj, ax_obj] = obj.show(obj.x_var, obj.AoI_avg_r, [], '\bf{Weighted average of AoI}', obj.strategy_name, [], sl_flag);
        end
        %效果对比 pAoI_max
        function [figure_obj, ax_obj] = show_pAoI_max(obj, sl_flag)
            f = @(para) string(para) == "LadderPro";
            if(any(f(obj.strategy_name)))    
                [figure_obj, ~] = obj.show(obj.x_var, obj.pAoI_max_r, obj.theoretical_lower_bound_phmax, '\bf{Maximum of pAoI}', obj.strategy_name, ...
                    'theoretical lower bound', sl_flag);
%                 [figure_obj, ~] = obj.add_line(figure_obj, obj.x_var, obj.max_arr_interval, "\bf{Maximum inter-arrival interval}", sl_flag);
%                 [figure_obj, ax_obj] = obj.add_line(figure_obj, obj.x_var, obj.suc_trans_interval, "\bf{Maximum successful transmission interval}",sl_flag);
            else
                [figure_obj, ax_obj] = obj.show(obj.x_var, obj.pAoI_max_r, [], '\bf{Maximum of pAoI}', obj.strategy_name, [], sl_flag);
            end
        end
        
    end

    methods(Access = private)
        function [figure_obj, ax_obj] = add_line(~, figure_obj, x_data, y_data, legend_name, slogx_flag)
            assert(~isempty(figure_obj))
            assert(class(figure_obj) == "matlab.ui.Figure");
            persistent add_num
            mark_bar = ["+", "*", ">", "<", "^", "h", "p", "v", "d", "s", "o"];
            if isempty(add_num)
                add_num = 1;
            end
            if add_num > length(mark_bar)
                add_num = 1;
            end
            figure(figure_obj);hold on
            ax_obj = gca;ax_obj.LineWidth = 2;
            plot(x_data, y_data, "LineWidth", 1.5, "Marker", mark_bar(add_num), "MarkerSize", 5, "DisplayName", legend_name);
            if(slogx_flag)
                ax_obj.XScale = 'log';
            end
            add_num = add_num + 1;
        end
        function [figure_obj, ax_obj] = show(obj, x_data, y_data, y_add, pic_title, legend_name, lengend_add, slogx_flag)
            if(nargin == 6)
                slogx_flag = 0;
            end
            mark_bar = ["+", "*", ">", "<", "^", "h", "p", "v", "d", "s", "o"];
            figure_obj = figure('Name', char(datetime), 'NumberTitle', 'off');hold on
            [row, ~] = size(y_data);
            assert(length(legend_name) == row);
            ax_obj = gca;ax_obj.LineWidth = 2;
            for i = 1:row
                plot(x_data, y_data(i, :), 'LineWidth', 1.5, 'Marker', mark_bar(i), 'MarkerSize', 5, 'DisplayName', legend_name{i});
            end

            if ~isempty(y_add)
                plot(x_data, y_add, 'k:', 'LineWidth', 2, 'MarkerSize', 5, 'DisplayName', lengend_add);
            end

            if(slogx_flag)
                ax_obj.XScale = 'log';
            end
            %grid on
            ylabel(pic_title, 'FontSize', 20);
            legend('Location', 'best');
            legend('FontSize', 10);
            switch obj.type
                case "TermianlNumber"
                    xlabel('\bf{number of clients in the network, M}','FontSize', 20);
                case "TimeSlot"
                    xlabel('\bf{Time-Horizon, K}','FontSize', 20);
                case "Lambda"
                    xlabel('\bf{Probability of arrival of data, \lambda}', 'FontSize', 20);
                case "Pn"
                    xlabel('\bf{Probability of transmission failure, p_n}', 'FontSize', 20);
            end
        end
    end
end