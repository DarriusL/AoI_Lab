classdef Terminal < handle
    %固定指标下（包括调度策略）的
    properties (Access = public)
        num                     %终端数
        ts_total                %模拟总持续的时隙数
        lambda                  %数据包到达的伯努利过程lambda
        pn                      %数据包传输中断概率
        alpha                   %每个设备的重要程度
        
        max_arrival_interval    %最大到达间隔
        max_transport_interval  %最大传输间隔

        data_state              %当前时隙的状态
        
        AoIdata                 %终端的数据包的信息年龄
        AoIaddup                %终端的信息年龄累加

        pAoI_num                %本次模拟取到的峰值信息年龄的次数
        PAoIaddup               %终端的峰值信息年龄累加
        wPAoImax                %加权最大峰值信息年龄

        ph_avg_terminal         %每个终端的平均峰值信息年龄 num*1
        ph_avg_system           %整个系统的平均峰值信息年龄 1*1

        Scheduling_id           %记录当前时隙调度的终端号
        Scheduling_Times        %记录每个终端的调度的次数

        strategy                %调度策略
        proportion              %基于调度比例约束的排队时延最优策略下的最优调度比例
        proportion_pro

        random_mode             
        simulation_mode         %仿真模式

        TsBlock                %这是一个行向量
    end
    
    methods (Access = public)
        %构造函数
        function obj = Terminal(num_in, ts_t, lambda_in, pn_in, strategy_name_in, alpha_in, random_mode_in, simu_mode_in) %lambda_in, pn_in可为空
            obj.num = num_in;
            obj.ts_total = ts_t;
            
            if isempty(lambda_in)
                obj.lambda = rand(obj.num, 1);
            else
                assert(size(lambda_in,1)==num_in, 'lambda_in输入维度错误')
                obj.lambda = lambda_in;
            end
            
            if isempty(pn_in)
                obj.pn = rand(obj.num, 1);
            else
                assert(size(pn_in,1)==num_in, 'pn_in输入维度错误')
                obj.pn = pn_in;
            end
            
            assert(size(alpha_in,1)==num_in, 'alpha_in输入维度错误')
            obj.alpha = alpha_in/sum(alpha_in);
            %obj.alpha = alpha_in;
            %初始化
            obj.data_state = [ones(obj.num, 3), zeros(obj.num, 4)]; %默认初始时刻有包
            obj.AoIdata = zeros(obj.num, 2, 2);                     %只记录上一时隙和当前时隙
            obj.AoIaddup = [];                       
            obj.pAoI_num = [];
            obj.PAoIaddup = [];
            obj.wPAoImax = [];
            obj.ph_avg_terminal = zeros(num_in, 1);
            obj.ph_avg_system = 0;
            obj.Scheduling_id = zeros(ts_t, 1);
            obj.Scheduling_Times = zeros(num_in, 1);
            obj.proportion = zeros(num_in, 1);
            obj.proportion_pro = zeros(num_in, 1);
            obj.strategy = Strategy(strategy_name_in);
            obj.max_arrival_interval = zeros(ts_t + 1, 1);          %最后一个元素记录对应的终端号
            obj.max_transport_interval = zeros(2, 1);               %一个记录上一个时隙(1)，一个记录当前时隙(2)
            obj.random_mode = random_mode_in;
            obj.simulation_mode = simu_mode_in;
            obj.TsBlock = [];
        end
        
        %获取包(同时获取)
        function get_data(obj, ts, ArrLogiMat)%ts - 当前时隙
            persistent ts_prov_array

            if(ts == 1)                                    
                ts_prov_array = obj.data_state(:, 2);
            end

            tem = ArrLogiMat(:, ts);
            obj.data_state(tem, 1) = ones(sum(tem), 1);    %有包到达
            obj.data_state(tem, 2) = ts*ones(sum(tem), 1); %新包到达的时间 

            idArray = 1:obj.num;
            %开始记录包的到达间隔
            if(ts ~= obj.ts_total)
                max_tem = ts - min(ts_prov_array(tem));
                idat = idArray(tem);
                id = idat(ts_prov_array(tem) == min(ts_prov_array(tem)));
            else
                max_tem = ts - min(ts_prov_array);
                id = idArray(ts_prov_array == min(ts_prov_array));
            end

            if(isempty(max_tem))
                return
            end
            if(length(id) > 1)
                id = id(randperm(length(id), 1));
            end
            
            ts_prov_array(tem) = ts*ones(sum(tem), 1);     %记录新包到的时间
            assert(length(max_tem) == 1, mat2str(size(max_tem)));
            if(ts == 1)
                obj.max_arrival_interval(ts) = max_tem;
                obj.max_arrival_interval(end) = id;
                return
            end
            if(max_tem > obj.max_arrival_interval(ts - 1))
                obj.max_arrival_interval(ts) = max_tem;
                obj.max_arrival_interval(end) = id;
            else
                obj.max_arrival_interval(ts) = obj.max_arrival_interval(ts - 1);
            end
        end
        
        
        %终端向中央发送数据
        function ts_tem = transport(obj, id, ts, TransRandMat)%id-由决策过程决定的索引(假设收到决策后立即开始传,传输时延为1时隙)
            %传递决策信息，开始传输
            r = TransRandMat(ts);
            ts_tem = 0;
            persistent ts_prov_array
            if id == 0
                return;
            end
            trans_flag = r > obj.pn(id);
            if id > 0 && id <= obj.num
                if obj.data_state(id, 1)
                    if trans_flag       %传输不中断，当前时隙开始传
                        obj.data_state(id, 6) = 1;
                        obj.data_state(id, 5) = ts;
                        ts_tem = obj.data_state(id, 2);
                        obj.Scheduling_id(ts) = id;
                        obj.Scheduling_Times(id) = obj.Scheduling_Times(id) + 1;    %传输未中断才算调度一次
                    else
                        obj.data_state(id, 6) = 0;
                    end
                end
                obj.data_state(id, 1) = 0;%无论如何，包发送后，终端无包
                obj.data_state(id, 2) = 0;%最新包到达时隙为0，即无包到达，
                
            end
            
            if(obj.strategy.strategy_name ~= "LadderPro" || ~trans_flag)
                return
            end

            if(ts == 1)|| isempty(ts_prov_array) || length(ts_prov_array) ~= obj.num
                ts_prov_array = zeros(obj.num, 1);     
            end

            %开始记录包的传输间隔
            max_tem = (ts - ts_prov_array(id)) * obj.alpha(id);
            %更新上个时隙
            obj.max_transport_interval(1) = obj.max_transport_interval(2);  
            assert(length(max_tem) == 1, mat2str(size(max_tem)));
            if(ts == 1) 
                obj.max_transport_interval(2) = max_tem;
                ts_prov_array(id) = ts;
                return
            end
            if(max_tem > obj.max_transport_interval(1))
                obj.max_transport_interval(2) = max_tem;
            end
            ts_prov_array(id) = ts;
        end

        %收包
        function recive(obj, ts, ts_tem)%ts-当前时隙， ts_tem - 传输的包的生成时间（为0表示没有要收的包 或者 传输失败）
            assert(ts > ts_tem, "input error -> ts_tem");
            if(ts_tem == 0)
                return
            end
             %判断其它传输是否到达   
            row_logi = obj.data_state(:, 6) == 1;
            if ~all(row_logi == 0)
                if ts >= obj.data_state(row_logi, 5) + 1
                    obj.data_state(row_logi, 6) = 0;%包成功到达,传输置0
                    obj.data_state(row_logi, 3) = 1;
                    obj.data_state(row_logi, 4) = ts_tem;
                end
            end
        end

       
        %计算终端包的排队等待时间
        function calculate_WT(obj, ts)
            obj.data_state(:, 7) = (ts - obj.data_state(:, 2)).*obj.data_state(:, 1);
        end

        %计算当前时隙终端与中央基站间的信息年龄
        function calculate_AoI(obj, ts)
            obj.AoIdata(:, 1, :) = obj.AoIdata(:, 2, :);                             %更新上个时隙
            obj.AoIdata(:, 2, 1) = (ts - obj.data_state(:, 4)).*obj.data_state(:, 3);%计算中央基站最新收到的包的AoI
            obj.AoIdata(:, 2, 2) = (ts - obj.data_state(:, 2)).*obj.data_state(:, 1);%计算终端最新收到的包的AoI
            col_logi = obj.TsBlock >= ts;
            obj.AoIaddup(:, col_logi) = obj.AoIaddup(:, col_logi) + repmat(obj.AoIdata(:, 2, 1), 1, sum(col_logi));
            if ts >= 2
                row_logi = obj.AoIdata(:, 2, 1) <= obj.AoIdata(:, 1, 1);
                %col_logi不用再次计算，这里相同
                pAoI = obj.AoIdata(row_logi, 1, 1);
                wPAoI = pAoI .* obj.alpha(row_logi);
                obj.PAoIaddup(row_logi, col_logi) = obj.PAoIaddup(row_logi, col_logi) + repmat(pAoI, 1, sum(col_logi));
                obj.pAoI_num(row_logi, col_logi) = obj.pAoI_num(row_logi,col_logi) + 1; %记录达到峰值信息年龄的次数
                
                idarray = (1:obj.num)';
                idarray = idarray(row_logi);
                row_logi = obj.wPAoImax(row_logi, end) < wPAoI;
                idarray = idarray(row_logi);
                obj.wPAoImax(idarray, col_logi) = repmat(wPAoI(row_logi), 1, sum(col_logi));
            end
            
            if ts == obj.ts_total %最后时隙
                row_logi = obj.AoIdata(:, 2, 1) ~= 0;
                obj.PAoIaddup(row_logi, end) = obj.PAoIaddup(row_logi, end) + obj.AoIdata(row_logi, 2, 1);
                obj.pAoI_num(row_logi,end) = obj.pAoI_num(row_logi,end) + 1; %记录达到峰值信息年龄的次数
            end
        end

        %计算基于调度比例约束的排队时延最优策略下的最优调度比例
        function calculate_proportion(obj)
            %fun = @(x)mean(sum((obj.alpha)'.*(1./x)));
            %obj.proportion = fmincon(fun, 1/obj.num*ones(1, obj.num), ones(1, obj.num), 1, ones(1, obj.num), 1, zeros(1, obj.num), ones(1, obj.num));
            %效果应该不是很好，可以考虑用粒子群
            %obj.proportion = sqrt(obj.alpha ./ (1 - obj.pn))./sum(sqrt(obj.alpha ./ (1 - obj.pn)));
            obj.proportion_pro = obj.alpha ./ (1 - obj.pn)./ (sum(obj.alpha ./ (1 - obj.pn)));
            %obj.proportion = fmincon(fun, sqrt(obj.alpha)./sum(sqrt(obj.alpha)), ones(1, obj.num), 1, ...
            %ones(1, obj.num), 1, zeros(1, obj.num), obj.lambda');
            f = @(v) abs( sum( min(obj.lambda, sqrt( obj.alpha ./ (( 1 - obj.pn) .* v) ))) - 1);
            options = optimoptions('fmincon', 'Display', 'off');
            v = fmincon(f, 50, -1, 0, [], [], [], [], [], options);
            obj.proportion = min(obj.lambda, sqrt( obj.alpha ./ (( 1 - obj.pn) .* v) ));
        end
        
        %仿真
        function [theoretical_lower_bound, STI, MAI, theoretical_lower_bound_phmax] = simulation_start(obj, simu_rounds, ts_block)
            assert(ts_block(end) == obj.ts_total);
            obj.TsBlock = ts_block';
            obj.AoIaddup = zeros(obj.num, length(ts_block));
            obj.PAoIaddup = obj.AoIaddup;                           %相同的初始化值
            obj.wPAoImax = obj.AoIaddup;                            %相同的初始化值
            obj.pAoI_num = obj.AoIaddup;                            %相同的初始化值

            [ArrLogiMat, TransRandMat] = obj.Generate_RandMat(simu_rounds);
            obj.calculate_proportion();
            ts_tem = 0;
            for ts = 1:obj.ts_total
                obj.get_data(ts, ArrLogiMat);
                obj.calculate_WT(ts);
                obj.recive(ts, ts_tem);
                obj.calculate_AoI(ts);
                id = obj.strategy.Scheduling(obj, ts);
                ts_tem = obj.transport(id, ts, TransRandMat);
            end
            
            theoretical_lower_bound = [];
            STI = [];
            MAI = [];
            theoretical_lower_bound_phmax = [];
            switch obj.strategy.strategy_name
                case "ProportionNB"
                    alphak = obj.alpha;
                    p = obj.pn;
                    Rk = obj.proportion;
                    theoretical_lower_bound = zeros(length(ts_block), 1);
                    for rounds = 1:length(ts_block)
%                         ts_tem_top = ts_block(rounds);
%                         ScheId = obj.Scheduling_id(1:ts_tem_top);
%                         tem_id = ScheId(ScheId ~= 0);
%                         id_end = tem_id(end);
%                         assert(id_end ~= 0, ['error' newline char(obj.strategy.strategy_name)]);
%                         mk = ts_tem_top * obj.proportion;
%                         mk(id_end) = mk(id_end) - 1;
%                         mk = mk +1;
%                         theoretical_lower_bound(rounds) = sum( alphak ./ (1 - obj.pn) .*((ts_tem_top)./mk) );
                        theoretical_lower_bound(rounds) = sum(alphak ./ ((1 - p) .* Rk));
                    end

                case "LadderPro" 
                    STI = obj.max_transport_interval(2);
                    MAI = obj.max_arrival_interval(end - 1);
                    theoretical_lower_bound_phmax = max([sum(obj.alpha ./(1 - obj.pn)), MAI]);
            end

            clear Generate_RandMat
        end

        %计算终端平均加权峰值信息年龄pAoI_avg
        %计算终端平均加权信息年龄 AoI_avg
        function value_struct = calculate(obj, ts_block) %返回中央基站的包的(平均峰值信息年龄 1*1， 平均AoI， maxpAoI)
            assert(ts_block(end) == obj.ts_total);
            value_struct.phavg = zeros(1, length(ts_block));
            value_struct.AoI_avg_system = zeros(1, length(ts_block));
            value_struct.pAoI_max_system = zeros(1, length(ts_block));

            for rounds = 1:length(ts_block)
                ts_tem_top = ts_block(rounds);
                % AoI_avg_terminal = zeros(obj.num, 1);
                % pAoI_max_terminal = zeros(obj.num, 1);
                %计算每个终端平均峰值AoI
                obj.ph_avg_terminal = obj.PAoIaddup(:, rounds) ./ obj.pAoI_num(:, rounds);
                %计算每个终端平均AoI
                AoI_avg_terminal = obj.AoIaddup(:, rounds) / ts_tem_top;
                %得到每个终端的最大pAoI -> obj.wPAoImax(:, rounds)
                PAoImax = obj.wPAoImax(:, rounds) ./ obj.alpha;
                pAoI_max_terminal = max(PAoImax);

                tem = obj.ph_avg_terminal ~= 0;
                value_struct.phavg(rounds) = sum(obj.alpha(tem).*obj.ph_avg_terminal(tem))/sum(obj.alpha(tem));
                obj.ph_avg_system = value_struct.phavg(rounds);
    
                value_struct.AoI_avg_system(rounds) = sum(obj.alpha .* AoI_avg_terminal) / sum(obj.alpha);
                assert(length(value_struct.AoI_avg_system(rounds)) == 1 && value_struct.AoI_avg_system(rounds) ~= 0);
    
                value_struct.pAoI_max_system(rounds) = max(pAoI_max_terminal);
            end
        end

        %绘制系统的平均峰值信息年龄序列图
        function [figure_obj, pic_obj, ax_obj] = pic_pAoIavg(obj) 
            figure_obj = figure('Name', char(datetime), 'NumberTitle', 'off');
            pic_obj = stem(obj.ph_avg_terminal, 'k', 'LineWidth', 1.5, 'MarkerSize', 2);
            axis([0, length(obj.ph_avg_terminal)+1, 0, max(obj.ph_avg_terminal)+5])
            ax_obj = gca;
            ax_obj.LineWidth = 1.5;
            xlabel('terminal id');
            title(obj.strategy.strategy_name, ['terminal average of pAoI ---> system average of pAoI : ', num2str(obj.ph_avg_system)]);
        end
    
        
    end

    methods(Access = private)
        function [ArrLogiMat, TransRandMat] = Generate_RandMat(obj, simu_rounds)
            persistent rand_send
            persistent simulation_rounds

            if(isempty(simulation_rounds))
                simulation_rounds = 0;
            end
            %开启设置随机种子条件：相同随机模式、同仿真轮次
            if( obj.random_mode && simulation_rounds ~= simu_rounds)
                simulation_rounds = simu_rounds;
                rand_send = randperm(3696, 1);
                %disp(['The random seed setting for the current simulation is complete:', num2str(rand_send)]);
            end

            if(obj.random_mode == 0) %完全随机模式
                rng('shuffle');
            else                         %相同随机模式（只有到达相同，中断可能相同）
                rng(rand_send);
            end
            rand_ArrMat = rand(obj.num, obj.ts_total);
            TransRandMat = rand(1, obj.ts_total);
            ArrLogiMat = rand_ArrMat < obj.lambda;
            rng('shuffle');
        end
    end
end
