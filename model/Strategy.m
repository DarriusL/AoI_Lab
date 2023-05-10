classdef Strategy < handle

    properties (Access = public)
        strategy_name %char
        strategy_func %调度函数
        flag
    end

    methods (Access = public)
        %构造函数
        function obj = Strategy(strategy_name_in)
            obj.strategy_name = strategy_name_in;
            obj.flag = 0;
            switch obj.strategy_name
                case "Manual"                           %手动
                    obj.strategy_func = @obj.strategy_manual;
                case "Random"                           %完全随机调度
                    obj.strategy_func = @obj.strategy_rand;
                case "weight-based Random"              %基于权重的随机调度
                    obj.strategy_func = @obj.strategy_rand_wb;
                case "proportion-based Random"
                    obj.strategy_func = @obj.strategy_rand_wp;
                case "TG"                               %传统贪心策略
                    obj.strategy_func = @obj.strategy_TG;
                case "Greedy"                           %贪婪策略
                    obj.strategy_func = @obj.strategy_greedy;
                case "weight-based Greedy"              %基于权重的贪婪策略
                    obj.strategy_func = @obj.strategy_greedy_wb;
                case "Proportion"                       %基于调度比例约束的排队时延最优策略1
                    obj.strategy_func = @obj.strategy_proportion;
                case "ProportionPro"                    %Proportion改进
                    obj.strategy_func = @obj.strategy_proportion_pro;
                case "ProportionNB"                     %基于调度比例约束的排队时延最优策略2
                    obj.strategy_func = @obj.strategy_proportion_nb;
                case "ProportionNBPro"
                    obj.strategy_func = @obj.strategy_proportion_nb_pro;
                case "Ladder"                           %阶梯
                    obj.strategy_func = @obj.strategy_ladder;
                case "FastLadder"                       %快速阶梯
                    obj.strategy_func = @obj.strategy_ladder;
                    obj.flag = 1;
                case "LadderPro"                        %阶梯改进
                    obj.strategy_func = @obj.strategy_ladderpro;
                case "FastLadderPro"                    %快速阶梯改进
                    obj.strategy_func = @obj.strategy_ladderpro;
                    obj.flag = 1;
                case "weight-based LP"                  %基于权重的阶梯改进
                    obj.strategy_func = @obj.strategy_ladderpro_wb;
                case "weight-based FLP"                 %基于权重的快速阶梯改进
                    obj.strategy_func = @obj.strategy_ladderpro_wb;
                    obj.flag = 1;
                case "Hybrid"                           %杂交策略
                    obj.strategy_func = @obj.strategy_hybrid;
                case "FastHybrid"                       %快速杂交策略
                    obj.strategy_func = @obj.strategy_hybrid;
                    obj.flag = 1;
                case "MWAoI"                            %最大权重AoI
                    obj.strategy_func = @obj.strategy_mwAoI;
                case "WIP"                              %惠特尔索引策略
                    obj.strategy_func = @obj.strategy_WIP;
                otherwise                               %无法识别的策略名
                    error(['Strategy error, unrecognized strategy name', obj.strategy_name]);
            end
        end
        
        %调度
        function id = Scheduling(obj, terminal_obj, ts)
            id = obj.strategy_func(terminal_obj, ts, obj.flag);
        end

    end

    methods (Access = private)
        %手动
        function id = strategy_manual(obj, terminal_obj, ts, ~)
            persistent fast_flag
            if(ts == 1 || isempty(fast_flag))
                fast_flag = input("是否使用快速算法(0/1)？\n");
            end
            %fast_flag 是否使用快速算法(0-不使用 1使用)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.strategy_greedy(terminal_obj, ts);
                return;
            end
            persistent figure_obj_cell
            if(isempty(figure_obj_cell) || ts == 1)
                figure_obj_cell = cell(1,3);
            end
            AoICur = terminal_obj.AoIdata(:, 2, 1);                                     %当前时隙每个终端的信息年龄(num*1)
            lambdaCur = terminal_obj.lambda;
            pnCur = terminal_obj.pn;
            numCur = terminal_obj.num;

            idArray = 1:numCur;
            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));
            EPAoI_sort = AoICur(SortToIdArray) + (idArray)' - 1;                        %计算EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                                       %EPAoI每个位置与每个终端号对应
            WTCur = terminal_obj.AoIdata(:, 2, 2);                                     %当前时刻每个终端的排队时延

            id_book = obj.find_terminal_with_data(terminal_obj);
            if(isempty(id_book))
                id = 0;
                return
            end
            WT_tem = WTCur;
            WT_tem(terminal_obj.data_state(:, 1)~=1) = -1;
            figure_obj_cell{1} = obj.stem_pic(1:numCur, AoICur, "AoI", figure_obj_cell{1});
            figure_obj_cell{2} = obj.stem_pic(1:numCur, EPAoICur, "EPAoI", figure_obj_cell{2});
            figure_obj_cell{3} = obj.stem_pic(1:numCur, WT_tem, "WT", figure_obj_cell{3});

            id = input("Which terminal to schedule?(Ctrl + C to stop)\nid = ");
            if(any(id_book == id))
                disp(['Choice:', num2str(id)]);
                return
            end
            disp(['Choice:', num2str(id), ' out of range, set 0']);
            id = 0;
        end

        %完全随机调度（'Random'）
        function id = strategy_rand(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            if(isempty(id_book))
                id = 0;
                return;
            end
            id = id_book(randperm(length(id_book), 1));
        end
        
        %基于权重的随机调度（'weight-based Random'）
        function id = strategy_rand_wb(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            alphai = terminal_obj.alpha(id_book);
            alphai = alphai/sum(alphai);
            if ~isempty(id_book)
                id = id_book(obj.Generate_roulette(length(alphai), alphai));
            else
                id = 0;%表示不调度
            end
        end

        function id = strategy_rand_wp(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            if(isempty(id_book))
                id = 0;
                return;
            end
            if(length(id_book) == 1)
                id = id_book(1);
                return;
            end
            prob = terminal_obj.proportion_pro;
            id_book = obj.find_terminal_within_proportion(terminal_obj, id_book, 1, 1, prob);
            if(isempty(id_book))
                id_book = obj.find_terminal_with_data(terminal_obj);
                id = id_book(obj.Generate_roulette(length(id_book), prob(id_book)));
                return;
            end
            id = id_book(obj.Generate_roulette(length(id_book), prob(id_book)));
        end
        
        
        %传统贪心
        function id = strategy_TG(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            if(isempty(id_book))
                id = 0;
                return;
            end

            AoI = terminal_obj.AoIdata(id_book, 2, 1);
            id_book = id_book(AoI == max(AoI));
            if(length(id_book) == 1)
                id= id_book(1);
                return;
            end
            id = id_book(obj.Generate_roulette(length(id_book), ones(length(id_book))));
        end

        %贪婪策略（'Greedy'）
        function id = strategy_greedy(obj, terminal_obj, ts, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            id = obj.greedy_func(terminal_obj, ts, id_book);
        end

        %基于权重的贪婪策略（'weight-based Greedy'）
        function id = strategy_greedy_wb(obj, terminal_obj, ts, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            id= obj.greedy_wb_func(terminal_obj, ts, id_book);
        end
        
        %基于调度比例约束的排队时延最优策略('Proportion')
        function id = strategy_proportion(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            if isempty(id_book)
                id = 0;
            else
                WT = terminal_obj.data_state(id_book, 7);
        
                row = find(WT == min(WT));
                %id = id_book(row(ceil(length(row)*rand(1,1))));%随机选择
                lambdai = terminal_obj.lambda(row);
                id = id_book(row(obj.Generate_roulette(length(row), 1./lambdai)));%轮盘选择

                times_proportion = terminal_obj.proportion;
                
                if sum([terminal_obj.Scheduling_Times]) == 0
                    tem = 0;
                else
                    tem = (terminal_obj.Scheduling_Times(id))/sum([terminal_obj.Scheduling_Times])... 
                    > times_proportion(id); %
                end
        
                while tem
                    id_book(id_book == id) = []; %id达到调度比例
                    if isempty(id_book)
                        id_book_tem = obj.find_terminal_with_data(terminal_obj);
                        id = id_book_tem(ceil(length(id_book_tem)*rand(1, 1)));
                        break;
                    end
        
                    WT = terminal_obj.data_state(id_book, 7);
        
                    row = find(WT == min(WT));
                    %id = id_book(row(ceil(length(row)*rand(1,1))));%随机选择
                    lambdai = terminal_obj.lambda(row);
                    id = id_book(row(obj.Generate_roulette(length(row), 1./lambdai)));

                    if sum([terminal_obj.Scheduling_Times]) == 0
                        tem = 0;
                    else
                        tem = (terminal_obj.Scheduling_Times(id))/sum([terminal_obj.Scheduling_Times]) ...
                        > times_proportion(id); %
                    end
                end
            end

        end
        
        %基于proportion的改进策略(在调度比例不超标的终端里，调AoI最大，当AoI相同时,调排队时延最小，当排队时延相同，随机调度)
        function id = strategy_proportion_pro(obj, terminal_obj, ts, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            if isempty(id_book)%终端无包
                id = 0;
                return
            end

            id_book = obj.find_terminal_within_proportion(terminal_obj, id_book, 1, 1, terminal_obj.proportion);
            %在id_book中选出在调度比列内的终端编号（forward=1允许返回空）
            if isempty(id_book)%在已有的终端中没有在调度比例内的终端
                %此时随机调度（依据到达概率）
                id_book = obj.find_terminal_with_data(terminal_obj);
                id = id_book(obj.Generate_roulette(length(id_book), 1./terminal_obj.lambda(id_book)));
                %disp("ProportionPro use strategy: rand based on lambda");
            else%在已有的终端中有在调度比例内的终端
                if(ts ~= 1)
                    AoI_tem = terminal_obj.AoIdata(id_book, 2, 1);%选出没有在传输包（包括传输中断）的AoI
                    id_book = id_book(AoI_tem == max(AoI_tem));
                    if(length(id_book) == 1)
                        id = id_book;
                        return
                    end
                end
                %找排队时延最小
                WT_tem = terminal_obj.data_state(id_book, 7);
                id_book = id_book(WT_tem == min(WT_tem));
                if(length(id_book) == 1)
                    id = id_book;
                    return
                end
                %在其中随机调度（依据终端到达概率）
                id = id_book(obj.Generate_roulette(length(id_book), 1./terminal_obj.lambda(id_book)));

            end
        end

        %基于调度比例约束的排队时延无缓存最优策略
        function id = strategy_proportion_nb(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            id = obj.proportion_nb_func(terminal_obj, id_book, terminal_obj.proportion);
        end

        %基于调度比例约束的排队时延无缓存最优策略改进版
        function id = strategy_proportion_nb_pro(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %应该考虑在当前时隙有包的终端
            AoI = terminal_obj.AoIdata(id_book, 2, 1);
            id_book = id_book(AoI == max(AoI));
            if(length(id_book) == 1)
                id = id_book(1);
                return
            end
%             proportion = terminal_obj.alpha ./ (sum(sqrt(terminal_obj.alpha ./ (1 - terminal_obj.pn))) ).^2;
            proportion = terminal_obj.proportion_pro;
            id = obj.proportion_nb_func(terminal_obj, id_book, proportion);
        end
        
        %阶梯调度策略
        function id = strategy_ladder(obj, terminal_obj, ts, fast_flag)
            %fast_flag 是否使用快速算法(0-不使用 1使用)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.strategy_greedy(terminal_obj, ts);
                return;
            end

            %XXXCur 每个位置索引对应的都是终端号(id)
            %EPAoI_sort 按照AoI大小排序后的EPAoI, 通过排序顺序查询EPAoI
            %SortToIdArray 通过排序顺序查询终端号
            %IdToSortArray 通过终端号查询排序顺序
            AoICur = terminal_obj.AoIdata(:, 2, 1);%当前时隙每个终端的信息年龄(num*1)
            lambdaCur = terminal_obj.lambda;        %每个终端的包到达概率（num*1）
            pnCur = terminal_obj.pn;                %每个终端的包传输失败概率
            numCur = terminal_obj.num;              %终端数量
            WTCur = terminal_obj.AoIdata(:, 2, 2); %当前时刻每个终端的排队时延

            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));
            %对AoI进行排序（降序），AoI相同时依据lambda*(1-pn)，越小序号越靠前
            %乘0.5是将后者限制在小于1的范围内
            %返回值SortToIdArray 为排序后每个位置对应的终端号（id）                                                                                                                                                    

            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;                       %计算EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                                       %EPAoI每个位置与每个终端号对应
            
%             if(ts == terminal_obj.ts_total)
%                 WT_tem = WTCur;
%                 WT_tem(terminal_obj.data_state(:, 1)~=1) = -1;
%                 obj.stem_pic(1:numCur, AoICur, "AoI");
%                 obj.stem_pic(1:numCur, EPAoICur, "EPAoI");
%                 obj.stem_pic(1:numCur, WT_tem, "WT");
%             end
            EPAoIStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);    %激励生成结构体（未作选择时）

            id_book = obj.find_terminal_with_data(terminal_obj);                        %找到有包的终端号
            if(isempty(id_book))                                                        %没有终端有包
                id = 0;                                                                 %不做调度
                return;
            end
            if(length(id_book) == 1)                                                    %只有一个终端有包
                id = id_book(1);                                                        %不做比较，直接调度
                return
            end
            sort_book = sort(IdToSortArray(id_book));

            iter_num = 1;
            id_k0 = SortToIdArray(sort_book(iter_num));%依次选取有包的终端中AoI（降序）的终端号
            a_k0 = WTCur(id_k0);                     %排队时延
            EPAoIChangeSruct = obj.Generate_EPAoIChangeStruct(0, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);        %0-生成结构体
            while 1
                for iter_part_num = iter_num + 1: length(id_book)
                    id_k = SortToIdArray(sort_book(iter_part_num));
                    EPAoIChangePartSruct = obj.Generate_EPAoIChangePartStruct(0, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray);
                    %0-生成结构体
                    if(obj.Compare_Struct(EPAoIChangeSruct, EPAoIChangePartSruct, lambdaCur, pnCur, 1111, EPAoIStruct, 1111, 1111) == 1)  
                        %前者更好（1111表示没有使用到的变量）
                        id = id_k0;
                        %disp(['情况1:', num2str(IdToSortArray(id)), ' ', num2str(id)]);
                        return;
                    end
                    %后者粗略更好
                    a_k = WTCur(id_k);
                    EPAoIChangeSruct2 = obj.Generate_EPAoIChangeStruct(0, numCur, id_k, a_k, AoICur, lambdaCur, pnCur); %0-生成结构体
                    if(obj.Compare_Struct(EPAoIChangeSruct, EPAoIChangeSruct2, lambdaCur, pnCur, 1111, EPAoIStruct, 1111, 1111) == 1)     %前者更好
                        if(iter_part_num == length(id_book))                                                            %已经比较完成
                            id = id_k0;
                            %disp(['情况2:', num2str(IdToSortArray(id)), ' ',num2str(id)]);
                            return;
                        end
                        continue;
                    end
                    %后者更好
                    iter_num = iter_part_num;
                    if(iter_num == length(id_book))%只剩最后一个了
                        id = id_k;
                        %disp(['情况3:', num2str(IdToSortArray(id)), ' ',num2str(id)]);
                        return
                    end
                    break;
                end

                id_k0 = SortToIdArray(sort_book(iter_num));%依次选取有包的终端中AoI（降序）的终端号
                a_k0 = WTCur(id_k0);                       %排队时延
                EPAoIChangeSruct = obj.Generate_EPAoIChangeStruct(0, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);    %0-生成结构体
            end
        end
        
        %改进阶梯调度策略
        function id = strategy_ladderpro(obj, terminal_obj, ts, fast_flag)
            persistent EPAoImax
            if isempty(EPAoImax) || (ts == 1)
                EPAoImax = 0;
            end
            id_book = obj.find_terminal_with_data(terminal_obj);
            [id, EPAoImax] = obj.ladderpro_func(terminal_obj, ts, fast_flag, id_book, EPAoImax);
        end

        %改进阶梯调度策略
        function id = strategy_ladderpro_wb(obj, terminal_obj, ts, fast_flag)
            persistent wEPAoImax
            if isempty(wEPAoImax) || (ts == 1)
                wEPAoImax = 0;
            end
            id_book = obj.find_terminal_with_data(terminal_obj);
            [id, wEPAoImax] = obj.ladderpro_wb_func(terminal_obj, ts, fast_flag, id_book, wEPAoImax);
        end
        
        %杂交策略
        %在调度比例不超标的终端里，使用，当AoI相同时,调排队时延最小，当排队时延相同，随机调度
        function id = strategy_hybrid(obj, terminal_obj, ts, fast_flag)
            persistent wEPAoImax
            if isempty(wEPAoImax) || (ts == 1)
                wEPAoImax = 0;
            end

            id_book = obj.find_terminal_with_data(terminal_obj);
            if isempty(id_book)
                id = 0;
                return;
            end
            if(length(id_book) == 1)
                id = id_book(1);
                return;
            end

            id_book = obj.find_terminal_within_proportion(terminal_obj, id_book, 1, 1, terminal_obj.proportion_pro);
            if(isempty(id_book))
                id = obj.strategy_ladderpro_wb(terminal_obj, ts, fast_flag);
                return;
            end
            
            %在调度比例中的终端使用
            [id, wEPAoImax] = obj.ladderpro_wb_func(terminal_obj, ts, fast_flag, id_book, wEPAoImax);

        end
    end

    %一些公用的调度方法（只能在调度策略里使用，不能单独使用）
    methods(Access = private)
        %主体的贪心策略
        function id = greedy_func(obj, terminal_obj, ~, id_book)
            if(isempty(id_book))
                id = 0;
                return
            end


            AoI_tem = terminal_obj.AoIdata(id_book, 2, 1); %选出AoI
            id_book = id_book(AoI_tem == max(AoI_tem));

            if(length(id_book) == 1)
                id = id_book(1);
                return
            end
            WTCur = terminal_obj.AoIdata(:, 2, 2);             %当前时刻每个终端的排队时延
            id_book = id_book(WTCur(id_book) == min(WTCur(id_book)));
            if(length(id_book) == 1)
                id = id_book(1);
                return
            end
            id = id_book(obj.Generate_roulette(length(id_book), 1./(terminal_obj.lambda(id_book) ) ));
        end
        
        %基于权重的主体贪心策略
        function id = greedy_wb_func(obj, terminal_obj, ~, id_book)
            if(isempty(id_book))
                id = 0;
                return;
            end
            %选出加权AoI
            wAoI_tem = terminal_obj.AoIdata(id_book, 2, 1) .* terminal_obj.alpha(id_book);
            id_book = id_book(wAoI_tem == max(wAoI_tem));
            if(length(id_book) == 1)
                id = id_book(1);
                return
            end
            WTCur = terminal_obj.AoIdata(:, 2, 2);
            id_book = id_book(WTCur(id_book) == min(WTCur(id_book)));
            
            if(length(id_book) == 1)
                id = id_book(1);
                return;
            end
            id = id_book(obj.Generate_roulette(length(id_book), 1./terminal_obj.lambda(id_book)));
        end

        %基于权重的梯子策略的主体
        function [id, EPAoImax] = ladderpro_func(obj, terminal_obj, ts, fast_flag, id_book, EPAoImax) 
            %fast_flag 是否使用快速算法(0-不使用 1使用)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.greedy_func(terminal_obj, ts, id_book);
                return;
            end
            AoICur = terminal_obj.AoIdata(:, 2, 1);                        %当前时隙每个终端的信息年龄(num*1)
            lambdaCur = terminal_obj.lambda;                                %每个终端的包到达概率（num*1）
            pnCur = terminal_obj.pn;                                        %每个终端的包传输失败概率
            numCur = terminal_obj.num;                                      %终端数量
            WTCur = terminal_obj.AoIdata(:, 2, 2);                         %当前时刻每个终端的排队时延
            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));                                                                                                                                                    

            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;                       %计算EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                                       %EPAoI每个位置与每个终端号对应

            if(EPAoImax < max(EPAoICur))
                EPAoImax = max(EPAoICur);
            end
            
%             if(ts ~= terminal_obj.ts_total)
%                 WT_tem = WTCur;
%                 WT_tem(terminal_obj.data_state(:, 1)~=1) = -1;
%                 f1 = figure(1);
%                 obj.stem_pic(1:numCur, AoICur, "AoI", f1);
%                 f2 = figure(2);
%                 obj.stem_pic(1:numCur, EPAoICur, "EPAoI",f2);
%                 f3 = figure(3);
%                 obj.stem_pic(1:numCur, WT_tem, "WT", f3);
%             end
            EPAoIStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);    %激励生成结构体（未作选择时）

            if(isempty(id_book))                                                        %没有终端有包
                id = 0;                                                                 %不做调度
                return;
            end
            if(length(id_book) == 1)                                                    %只有一个终端有包
                id = id_book(1);                                                        %不做比较，直接调度
                return
            end
            sort_book = sort(IdToSortArray(id_book));

            iter_num = 1;
            id_k0 = SortToIdArray(sort_book(iter_num)); %依次选取有包的终端中AoI（降序）的终端号
            a_k0 = WTCur(id_k0);                        %排队时延
            EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);          %1-返回EPAoICur
            while 1
                for iter_part_num = iter_num + 1: length(id_book)
                    id_k = SortToIdArray(sort_book(iter_part_num));
                    EPAoIChangePartCur = obj.Generate_EPAoIChangePartStruct(1, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray);
                    %1-生成EPAoICur
                    if(obj.Compare_StructPro(EPAoIChangeCur, EPAoIChangePartCur, lambdaCur, pnCur, ...
                            EPAoImax, EPAoIStruct, IdToSortArray, 1111) == 1)                                           %前者更好                                        
                        id = id_k0;
                        %disp(['情况1:', num2str(IdToSortArray(id)), ' ', num2str(id)]);
                        return;
                    end
                    %后者粗略更好
                    a_k = WTCur(id_k);
                    EPAoIChangeCur2 = obj.Generate_EPAoIChangeStruct(1, numCur, id_k, a_k, AoICur, lambdaCur, pnCur); %1-返回EPAoICur
                    if(obj.Compare_StructPro(EPAoIChangeCur, EPAoIChangeCur2, lambdaCur, pnCur, ...
                            EPAoImax, EPAoIStruct, IdToSortArray, 1111) == 1)                                           %前者更好
                        if(iter_part_num == length(id_book))                                                            %已经比较完成
                            id = id_k0;
                            %disp(['情况2:', num2str(IdToSortArray(id)), ' ',num2str(id)]);
                            return;
                        end
                        continue;
                    end
                    %后者更好
                    iter_num = iter_part_num;
                    if(iter_num == length(id_book))%只剩最后一个了
                        id = id_k;
                        %disp(['情况3:', num2str(IdToSortArray(id)), ' ',num2str(id)]);
                        return
                    end
                    break;
                end

                id_k0 = SortToIdArray(sort_book(iter_num));%依次选取有包的终端中AoI（降序）的终端号
                a_k0 = WTCur(id_k0);                       %排队时延
                EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);    %1-返回EPAoICur
            end
        end

        %基于权重的梯子策略的主体
        function [id, wEPAoImax] = ladderpro_wb_func(obj, terminal_obj, ts, fast_flag, id_book, wEPAoImax)
            %fast_flag 是否使用快速算法(0-不使用 1使用)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.greedy_wb_func(terminal_obj, ts, id_book);
                return;
            end
            AoICur = terminal_obj.AoIdata(:, 2, 1);                        %当前时隙每个终端的信息年龄(num*1)
            alphaCur = terminal_obj.alpha;                                  %每个终端的权重
            lambdaCur = terminal_obj.lambda;                                %每个终端的包到达概率（num*1）
            pnCur = terminal_obj.pn;                                        %每个终端的包传输失败概率
            numCur = terminal_obj.num;                                      %终端数量
            WTCur = terminal_obj.AoIdata(:, 2, 2);                         %当前时刻每个终端的排队时延
            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));                                                                                                                                                    

            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;           %计算EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                           %EPAoI每个位置与每个终端号对应
            wPAoICur = EPAoICur .* alphaCur;                                %加权EPAoI

            if(wEPAoImax < max(wPAoICur))
                wEPAoImax = max(wPAoICur);
            end
            
%             if(ts ~= terminal_obj.ts_total)
%                 WT_tem = WTCur;
%                 WT_tem(terminal_obj.data_state(:, 1)~=1) = -1;
%                 f1 = figure(1);
%                 obj.stem_pic(1:numCur, AoICur, "AoI", f1);
%                 f2 = figure(2);
%                 obj.stem_pic(1:numCur, EPAoICur, "EPAoI",f2);
%                 f3 = figure(3);
%                 obj.stem_pic(1:numCur, WT_tem, "WT", f3);
%             end
            EPAoIStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);    %激励生成结构体（未作选择时）

            if(isempty(id_book))                                                        %没有终端有包
                id = 0;                                                                 %不做调度
                return;
            end
            if(length(id_book) == 1)                                                    %只有一个终端有包
                id = id_book(1);                                                        %不做比较，直接调度
                return
            end
            sort_book = sort(IdToSortArray(id_book));

            iter_num = 1;
            id_k0 = SortToIdArray(sort_book(iter_num)); %依次选取有包的终端中AoI（降序）的终端号
            a_k0 = WTCur(id_k0);                        %排队时延
            EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);          %1-返回EPAoICur
            while 1
                for iter_part_num = iter_num + 1: length(id_book)
                    id_k = SortToIdArray(sort_book(iter_part_num));
                    EPAoIChangePartCur = obj.Generate_EPAoIChangePartStruct(1, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray);
                    %1-生成EPAoICur
                    if(obj.Compare_StructPro_wb(EPAoIChangeCur, EPAoIChangePartCur, lambdaCur, pnCur, ...
                            wEPAoImax, EPAoIStruct, IdToSortArray, alphaCur) == 1)                                                 %前者更好
                        id = id_k0;
                        %disp(['情况1:', num2str(IdToSortArray(id)), ' ', num2str(id)]);
                        return;
                    end
                    %后者粗略更好
                    a_k = WTCur(id_k);
                    EPAoIChangeCur2 = obj.Generate_EPAoIChangeStruct(1, numCur, id_k, a_k, AoICur, lambdaCur, pnCur); %1-返回EPAoICur
                    if(obj.Compare_StructPro_wb(EPAoIChangeCur, EPAoIChangeCur2, lambdaCur, pnCur, ...
                            wEPAoImax, EPAoIStruct, IdToSortArray, alphaCur) == 1)                                     %前者更好
                        if(iter_part_num == length(id_book))                                                           %已经比较完成
                            id = id_k0;
                            %disp(['情况2:', num2str(IdToSortArray(id)), ' ',num2str(id)]);
                            return;
                        end
                        continue;
                    end
                    %后者更好
                    iter_num = iter_part_num;
                    if(iter_num == length(id_book))%只剩最后一个了
                        id = id_k;
                        %disp(['情况3:', num2str(IdToSortArray(id)), ' ',num2str(id)]);
                        return
                    end
                    break;
                end

                id_k0 = SortToIdArray(sort_book(iter_num));%依次选取有包的终端中AoI（降序）的终端号
                a_k0 = WTCur(id_k0);                       %排队时延
                EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);    %1-返回EPAoICur
            end
        end
        
        %proportion_nb的主体函数
        function id = proportion_nb_func(obj, terminal_obj,id_book, proportion)
            if isempty(id_book)
                id = 0;
                return;
            end

            ST = terminal_obj.Scheduling_Times;
            assert(all(size(ST) == size(terminal_obj.proportion)), ['error' newline mat2str(size(ST)) newline ...
                mat2str(size(terminal_obj.proportion))])
            WT = terminal_obj.data_state(id_book, 7);
            id_book = id_book(WT == min(WT));
            if(length(id_book) == 1)
                id = id_book(1);
                return;
            end

            if all(ST == 0)
                rk = ones(terminal_obj.num, 1);
            else
                rk = ST ./ sum(ST);
            end
            
            p = (rk(id_book) ./ (1 - terminal_obj.pn(id_book))) ./ proportion(id_book);
            id_book = id_book(p == min(p));
            if(length(id_book) == 1)
                id = id_book(1);
                return;
            end
            id_book = id_book(terminal_obj.lambda(id_book) == min(terminal_obj.lambda(id_book)));
            if(length(id_book) == 1)
                id = id_book(1);
                return;
            end
            id = id_book(obj.Generate_roulette(length(id_book), terminal_obj.lambda(id_book)));
        end

        %最大权重策略
        function id = strategy_mwAoI(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            if isempty(id_book)
                id = 0;
                return;
            end
            if length(id_book) == 1
                id = id_book(1);
                return;
            end
            alpha = terminal_obj.alpha(id_book);
            p = 1 - terminal_obj.pn(id_book);
            h = terminal_obj.AoIdata(id_book, 2, 1);
            w = 0.5 * alpha .* p .* h .* (h + 2);
            id = id_book(w == max(w));
            if length(id) == 1
                id = id(1);
                return;
            end
            id = id(randperm(length(id), 1));
        end

        %惠特尔索引策略
        function id = strategy_WIP(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            if isempty(id_book)
                id = 0;
                return;
            end
            if length(id_book) == 1
                id = id_book(1);
                return
            end
            h = terminal_obj.AoIdata(id_book, 2, 1);
            a = terminal_obj.AoIdata(id_book, 2, 2);
            d = h - a;
            lambda = terminal_obj.lambda(id_book);
            pn = terminal_obj.pn(id_book);
            %模型下排队时延有0的情况，因而使用该策略最好lambda不要设置为1
            x = ( d + 0.5 * a .* (a - 1) .* lambda ) ./ ( 1 - lambda + a.* lambda + eps);
            alpha = terminal_obj.alpha(id_book);
            WI = alpha .* d ./ lambda;
            logindex = d > a.*(0.5 * lambda .* a + 1 - 0.5 * lambda);
            WI(logindex) = alpha(logindex) .* ( x(logindex) .* (0.5 * x(logindex) + 1./lambda(logindex) - 0.5) );
            WI = WI .* (1 - pn);
            id = id_book(WI == max(WI));
            if length(id) == 1
                id = id(1);
                return;
            end
            id = id(randperm(length(id), 1));
        end

    end

    %一些功能函数
    methods(Access = private)

        %找到有包的终端
        function id = find_terminal_with_data(~, terminal_obj)
            assert(class(terminal_obj) == "Terminal", "error input class -> terminal_obj")
            id = find(terminal_obj.data_state(:,1) == 1);
%             if(isempty(id))
%                 disp("find_terminal_with_data: return []");
%             end
        end

        function id = find_terminal_within_proportion(~, terminal_obj, id_book, mode, forward, proportion)
            %mode为0时,返回terminal_obj中在调度比例中的终端id向量（列）
            %mode为1时,返回id_book中在调度比例中的终端id向量（列）

            %forward为1，省略一些报错， 默认为0
            switch nargin
                case 4
                    forward = 0;
                    disp("set forward: 0")
                case 5
                    if((forward ~= 0) && (forward ~= 1))
                        error("error input value -> forward");
                    end
            end
            f_flag = forward == 1;
            assert(class(terminal_obj) == "Terminal", "error input class -> termianl_obj");
            mat_tem = (1:terminal_obj.num)';
            switch mode
                case 0
                    %找到在调度比例里的包
                    index_tem = terminal_obj.Scheduling_Times./sum(terminal_obj.Scheduling_Times) <= proportion;
                    id = mat_tem(index_tem);
                    return

                case 1
                    %检查id_book
                    assert(~isempty(id_book) || f_flag, "invalid input(empty) -> id_book" );%flag为1则允许id_book为空
                    if(isempty(id_book))
                        if(~f_flag)
                            warning(["find_terminal_within_proportion:return []" newline "->input id_book is empty"]);
                        end
                        id = [];
                        return
                    end
                    
                    assert((max(id_book) <= terminal_obj.num) && min(id_book) > 0, ["error input value -> id_book" newline mat2str(id_book)]);
                    if(sum(terminal_obj.Scheduling_Times(id_book)) == 0)
                        index_tem = id_book ~= 0;%这里只是做一个逻辑转换生成一个和id_book size相同的全1逻辑向量
                    else 
                        index_tem = terminal_obj.Scheduling_Times(id_book)./sum(terminal_obj.Scheduling_Times(id_book)) ...
                        <= proportion(id_book);
                    end

                    if(~any(index_tem))%没有一个满足条件
                        if(~f_flag)
                            warning(['find_terminal_within_proportion:return []' newline '-> None of the terminals meet the conditions']);
                        end
                        id = [];
                        return
                    end
                    id = id_book(index_tem);
                    return
                otherwise
                    error("error input value -> mode");
            end

        end
        
        %产生轮盘并返回结果
        function id = Generate_roulette(~, n, pro_set)
            %返回值为抽中的序号
            id_array = 1:n;
            pro_set = pro_set/sum(pro_set);
            pro_array = cumsum(pro_set);
            rand_index = rand(1, 1);
            index_logi = pro_array >= rand_index;
            id = min(id_array(index_logi));
        end

        function [figure_obj, pic_obj] = stem_pic(~, xdata, ydata, title_in, figure_obj)
            if(nargin == 4 || isempty(figure_obj))
                figure_obj = figure('Name', char(datetime), 'NumberTitle', 'off');
            else
                figure(figure_obj);
            end
            assert(length(xdata) == length(ydata), 'error input');
            pic_obj = stem(xdata, ydata, 'k', 'LineWidth', 1.5, 'MarkerSize', 2);
            axis([0, length(xdata)+1, -2, max(ydata) + 1])
            ax_obj = gca;
            ax_obj.LineWidth = 1.5;
            xlabel('terminal id');
            title(title_in);
        end

    end

    %阶梯策略使用到的函数
    methods(Access = private)
        %激励生成EPAoI相关数据结构体
        function value_struct = Generate_EPAoIStruct(~, EPAoICur, IdToSortArray, numCur)
            %返回值:读取EPAoI中终端的id号  
            % value_struct.ter_mat(1:value_struct.count(EPAoI),value_struct.mat_index(EPAoI))
            % 为空则表示无对应EPAoI
            assert((size(EPAoICur, 1) > 1) && (size(EPAoICur, 2) == 1), 'error input -> EPAoICur');%需要为列向量
            value_tem = tabulate(EPAoICur);
            value_tem = value_tem((value_tem(:, 2) ~= 0) & (value_tem(:, 1) ~= 0), 1:2);           %除去EPAoI为0和统计数量为0的行
            EPAoI_stat = value_tem(:, 1);           %包含有哪些
            count_stat = value_tem(:, 2);           %包含的数量
            num_EPAoI = numCur + 2000;              %表的默认长度为num_EPAoI
            value = (1:num_EPAoI)';                 %行数对应EPAoI 便于查询
            mat_index = zeros(num_EPAoI, 1);
            count = zeros(num_EPAoI, 1);
            ter_mat = zeros(numCur, numCur);
            sort_mat = zeros(numCur, numCur);
            
            mat_tem = repmat((1:numCur)', 1, numCur);%用于制作逻辑表
            %相应数据写入表中
            %EPAoI可能有为0的情况
            assert(~any(EPAoI_stat == 0), "value error -> EPAoI = 0");
            mat_index(EPAoI_stat) = 1:length(EPAoI_stat);
            index = find(EPAoICur == EPAoI_stat');
            %关于该用法的说明
            %EPAoICur = [7 8 6 7 7]';
            %EPAoI_stat = [6 7 8]';
            %find(EPAoICur = EPAoI_stat')
            %效果repmat(EPAoICur, 1, length(EPAoI_stat'))
            %在第i列中找EPAoI_stat'(i) 返回列向索引
            assert((size(index, 1) > 1) && (size(index, 2) == 1), "error");%应为列向量
            len_E = length(EPAoICur);
            while 1
                if(any(index > len_E))
                    index(index > len_E) = index(index > len_E) - len_E;
                else
                    break;
                end
            end
        
            mat_index_tem = mat_tem <= [count_stat', zeros(1, numCur - length(count_stat))];%制作矩阵逻辑索引（矩阵使用此索引返回为列向量）
            %这一步出来的结果还有点问题
            ter_mat(mat_index_tem) = index;
            sort_mat(mat_index_tem) = IdToSortArray(index);
            
            count(EPAoI_stat) = count_stat;
        
            value_struct.value = value;
            value_struct.mat_index = mat_index;
            value_struct.count = count;
            value_struct.ter_mat = ter_mat;
            value_struct.sort_mat = sort_mat;
            value_struct.EPAoIMat = value_tem;
        end

        %生成EPAoIChangeSruct
        function value = Generate_EPAoIChangeStruct(obj, flag, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur)
            %flag 0 - 返回EPAoIChangeStruct 1 - 返回EPAoICur
            AoICur = AoICur + 1;
            AoICur(id_k0) = a_k0 + 1;

            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));
            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;                       %计算EPAoI
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);
            if(flag)
                value = EPAoICur;
                return
            end
            EPAoIChangeStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);
            value = EPAoIChangeStruct;
        end

        %生成EPAoIChangePartSruct
        function value = Generate_EPAoIChangePartStruct(obj, flag, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray)%使用原来的IdToSortArray
            %flag 0 - 返回EPAoIChangeStruct 1 - 返回EPAoICur
            index_id = 1:numCur;
            index_sort = IdToSortArray(index_id);
            index_sort = index_sort(index_sort < IdToSortArray(id_k));
            
            index_tem = SortToIdArray(index_sort);

            EPAoICur(index_tem) = EPAoICur(index_tem) + 1;
            EPAoICur(id_k) = 0;
            if(flag)
                value = EPAoICur;
                return
            end
            EPAoIChangePartStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);
            value = EPAoIChangePartStruct;
        end

        %返回比较结果
        function value = Compare_Struct(~, Struct_front, Struct_after, lambdaCur, pnCur, ~, EPAoIStruct, ~, ~)
            %关于返回值 1-前者更好  0-后者更好
            recCur = lambdaCur.*(1 - pnCur);
            s1 = Struct_front;
            s2 = Struct_after;

            eps = EPAoIStruct;

            %获取相关数据
            s1_maxEP = max(s1.EPAoIMat(:, 1));
            s2_maxEP = max(s2.EPAoIMat(:, 1));

            if(s1_maxEP > s2_maxEP)
                value = 0;
                return
            elseif(s1_maxEP < s2_maxEP)
                value = 1;
                return
            end
            
            %最大EPAoI相等的情况
            index = s1_maxEP;
            while 1
                if(s1.count(index) + s2.count(index) == 0)%均无
                    index = index - 1;
                    if(index == 0)
                        value = 1;
                        return
                    end
                    continue
                end

                if(s1.count(index) > s2.count(index)) 
                    value = 0;
                    return
                elseif(s1.count(index) < s2.count(index))
                    value = 1;
                    return
                end

                c_flag = s1.count(index) >= eps.count(index);
                %相等的情况，比较接收概率
                arr1 = prod(recCur(s1.ter_mat(1:s1.count(index), s1.mat_index(index)) ) );
                arr2 = prod(recCur(s2.ter_mat(1:s2.count(index), s2.mat_index(index)) ) );
                if(c_flag) %越大越好
                    if(arr1 < arr2)
                        value = 0;
                        return;
                    elseif(arr1 > arr2)
                        value = 1;
                        return
                    end
                else    %越小越好
                    if(arr1 > arr2)
                        value = 0;
                        return;
                    elseif(arr1 < arr2)
                        value = 1;
                        return
                    end
                end

                if(index == 1)
                    value = 1;
                    return
                end
                %相等比较下一个
                index = index - 1;
            end

        end

        function value = Compare_StructPro(obj, EPH_front, EPH_after, lambdaCur, pnCur, EPAoImx, EPAoIStruct, IdToSortArray, ~)
            %关于返回值 1-前者更好  0-后者更好
            e1 = EPH_front;
            e2 = EPH_after;
            
            assert(all(size(e1) == size(e2)));

            Prk = ones(length(e1), 1);
            data = ones(length(e1), 1);
            idAray = 1:length(e1);
            index_logi = e1 < EPAoImx + 1;
            idAray = idAray(index_logi);
            for rounds = 1:sum(index_logi)
                id = idAray(rounds);
                i = 0:(EPAoImx - e1(id));
                data(id) = sum( (1 - lambdaCur(id) ).^i .* (1 - lambdaCur(id) + lambdaCur(id)*pnCur(id)).^(EPAoImx - e1(id) - i) + ...
                    (1 - lambdaCur(id)).^(EPAoImx + 1 - e1(id)) );
                Prk(id) = lambdaCur(id) * pnCur(id) * data(id);
            end

            value1 = prod( 1 - Prk );

            Prk = ones(length(e2), 1);
            data = ones(length(e2), 1);
            idAray = 1:length(e2);
            index_logi = (e2 ~= 0) & (e2 < EPAoImx + 1);
            idAray = idAray(index_logi);
            for rounds = 1:sum(index_logi)
                id = idAray(rounds);
                i = 0:(EPAoImx - e2(id));
                data(id) = sum( (1 - lambdaCur(id) ).^i .* (1 - lambdaCur(id) + lambdaCur(id)*pnCur(id)).^(EPAoImx - e2(id) - i) + ...
                    (1 - lambdaCur(id)).^(EPAoImx + 1 - e2(id)) );
                Prk(id) = lambdaCur(id) * pnCur(id) * data(id);
            end

            value2 = prod( 1 - Prk );

            if(value1 + value2 == 0)                                    %得到不突破现有EPAoI最大值的概率都为零
                s1 = obj.Generate_EPAoIStruct(e1, IdToSortArray, length(e1));
                s2 = obj.Generate_EPAoIStruct(e2, IdToSortArray, length(e2));
                value = obj.Compare_Struct(s1, s2, lambdaCur, pnCur, 1111, EPAoIStruct, 1111, 1111);
                return;
            end

            if(value1 >= value2)
                value = 1;
            else
                value = 0;
            end

        end
    
        function value = Compare_StructPro_wb(obj, EPH_front, EPH_after, lambdaCur, pnCur, wEPAoImx, EPAoIStruct, IdToSortArray, alphaCur) 
            %关于返回值 1-前者更好  0-后者更好
            recCur = lambdaCur.*(1 - pnCur);
            e1 = EPH_front;
            e2 = EPH_after;
            w_e1 = alphaCur .* e1;
            w_e2 = alphaCur .* e2;

            assert(all(size(w_e1) == size(w_e2)));
            f = @(array) mod(array, 1) == 0;            %找出整数的逻辑索引
            mk1 = (wEPAoImx - w_e1) .* (1 ./ alphaCur);
            index_logi = f(mk1);
            mk1(~index_logi) = ceil(mk1(~index_logi));    %非整数向上取整
            mk1(index_logi) = mk1(index_logi) + 1;    %整数加1

            mk2 = (wEPAoImx - w_e2) .* (1 ./ alphaCur);
            index_logi = f(mk2);
            mk2(~index_logi) = ceil(mk2(~index_logi));    %非整数向上取整
            mk2(index_logi) = mk2(index_logi) + 1;    %整数加1

            value1 = prod( 1 - (1 - recCur) .^ mk1 );
            value2 = prod( 1 - (1 - recCur) .^ mk2 );

            if(value1 + value2 == 0)                    %得到不突破现有EPAoI最大值的概率都为零
                s1 = obj.Generate_EPAoIStruct(e1, IdToSortArray, length(e1));
                s2 = obj.Generate_EPAoIStruct(e2, IdToSortArray, length(e2));
                value = obj.Compare_Struct(s1, s2, lambdaCur, pnCur, 1111, EPAoIStruct, 1111, 1111);
                return;
            end

            if(value1 >= value2)
                value = 1;
            else
                value = 0;
            end
        end

    end
    
end