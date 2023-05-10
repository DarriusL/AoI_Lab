classdef Strategy < handle

    properties (Access = public)
        strategy_name %char
        strategy_func %Scheduling function
        flag
    end

    methods (Access = public)
        %Constructor
        function obj = Strategy(strategy_name_in)
            obj.strategy_name = strategy_name_in;
            obj.flag = 0;
            switch obj.strategy_name
                case "Manual"
                    obj.strategy_func = @obj.strategy_manual;
                case "Random"                           %Complete random scheduling
                    obj.strategy_func = @obj.strategy_rand;
                case "weight-based Random"              %Random scheduling based on weight
                    obj.strategy_func = @obj.strategy_rand_wb;
                case "proportion-based Random"
                    obj.strategy_func = @obj.strategy_rand_wp;
                case "TG"                               %Traditional greed strategy
                    obj.strategy_func = @obj.strategy_TG;
                case "Greedy"                           %greed strategy
                    obj.strategy_func = @obj.strategy_greedy;
                case "weight-based Greedy"              %Greedy strategy based on weight
                    obj.strategy_func = @obj.strategy_greedy_wb;
                case "Proportion"                       %Based on the scheduling ratio constraint, queuing delay strategy 1
                    obj.strategy_func = @obj.strategy_proportion;
                case "ProportionPro"                    %Proportion improvement
                    obj.strategy_func = @obj.strategy_proportion_pro;
                case "ProportionNB"                     %Based on the scheduling ratio constraint, queuing delay strategy 2
                    obj.strategy_func = @obj.strategy_proportion_nb;
                case "ProportionNBPro"
                    obj.strategy_func = @obj.strategy_proportion_nb_pro;
                case "Ladder" 
                    obj.strategy_func = @obj.strategy_ladder;
                case "FastLadder"
                    obj.strategy_func = @obj.strategy_ladder;
                    obj.flag = 1;
                case "LadderPro" 
                    obj.strategy_func = @obj.strategy_ladderpro;
                case "FastLadderPro" 
                    obj.strategy_func = @obj.strategy_ladderpro;
                    obj.flag = 1;
                case "weight-based LP"                  %Weight-Based Ladder Improvement
                    obj.strategy_func = @obj.strategy_ladderpro_wb;
                case "weight-based FLP"                 %Weight-based Fast Ladder Improvement
                    obj.strategy_func = @obj.strategy_ladderpro_wb;
                    obj.flag = 1;
                case "Hybrid"                           %
                    obj.strategy_func = @obj.strategy_hybrid;
                case "FastHybrid"                       %
                    obj.strategy_func = @obj.strategy_hybrid;
                    obj.flag = 1;
                case "MWAoI"                            %Maximum Weight AoI
                    obj.strategy_func = @obj.strategy_mwAoI;
                case "WIP"                              %Whittle Indexing Strategy
                    obj.strategy_func = @obj.strategy_WIP;
                otherwise 
                    error(['Strategy error, unrecognized strategy name', obj.strategy_name]);
            end
        end
        
        %scheduling
        function id = Scheduling(obj, terminal_obj, ts)
            id = obj.strategy_func(terminal_obj, ts, obj.flag);
        end

    end

    methods (Access = private)
        %manual
        function id = strategy_manual(obj, terminal_obj, ts, ~)
            persistent fast_flag
            if(ts == 1 || isempty(fast_flag))
                fast_flag = input("Whether to use fast algorithm(0/1)？\n");
            end
            %fast_flagWhether to use the fast algorithm (0-not use 1 use)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.strategy_greedy(terminal_obj, ts);
                return;
            end
            persistent figure_obj_cell
            if(isempty(figure_obj_cell) || ts == 1)
                figure_obj_cell = cell(1,3);
            end
            AoICur = terminal_obj.AoIdata(:, 2, 1);                                     %The AoI of each terminal in the current slot(num*1)
            lambdaCur = terminal_obj.lambda;
            pnCur = terminal_obj.pn;
            numCur = terminal_obj.num;

            idArray = 1:numCur;
            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));
            EPAoI_sort = AoICur(SortToIdArray) + (idArray)' - 1;                        %calculate EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                                       %EPAoI Each position corresponds to each terminal number
            WTCur = terminal_obj.AoIdata(:, 2, 2);                                     %The queuing delay of each terminal at the current moment

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

        %completely random scheduling（'Random'）
        function id = strategy_rand(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            if(isempty(id_book))
                id = 0;
                return;
            end
            id = id_book(randperm(length(id_book), 1));
        end
        
        %Weight-Based Random Scheduling（'weight-based Random'）
        function id = strategy_rand_wb(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            alphai = terminal_obj.alpha(id_book);
            alphai = alphai/sum(alphai);
            if ~isempty(id_book)
                id = id_book(obj.Generate_roulette(length(alphai), alphai));
            else
                id = 0;%Indicates no scheduling
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
        
        
        function id = strategy_TG(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); %Terminals that have packets in the current slot should be considered
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

        %（'Greedy'）
        function id = strategy_greedy(obj, terminal_obj, ts, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); 
            id = obj.greedy_func(terminal_obj, ts, id_book);
        end

        %（'weight-based Greedy'）
        function id = strategy_greedy_wb(obj, terminal_obj, ts, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            id= obj.greedy_wb_func(terminal_obj, ts, id_book);
        end
        
        %('Proportion')
        function id = strategy_proportion(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
            if isempty(id_book)
                id = 0;
            else
                WT = terminal_obj.data_state(id_book, 7);
        
                row = find(WT == min(WT));
                %id = id_book(row(ceil(length(row)*rand(1,1))));%random selection
                lambdai = terminal_obj.lambda(row);
                id = id_book(row(obj.Generate_roulette(length(row), 1./lambdai)));%roulette selection

                times_proportion = terminal_obj.proportion;
                
                if sum([terminal_obj.Scheduling_Times]) == 0
                    tem = 0;
                else
                    tem = (terminal_obj.Scheduling_Times(id))/sum([terminal_obj.Scheduling_Times])... 
                    > times_proportion(id); %
                end
        
                while tem
                    id_book(id_book == id) = []; %id reach the scheduling ratio
                    if isempty(id_book)
                        id_book_tem = obj.find_terminal_with_data(terminal_obj);
                        id = id_book_tem(ceil(length(id_book_tem)*rand(1, 1)));
                        break;
                    end
        
                    WT = terminal_obj.data_state(id_book, 7);
        
                    row = find(WT == min(WT));
                    %id = id_book(row(ceil(length(row)*rand(1,1))));%random selection
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
        
        %(In the terminals whose scheduling ratio does not exceed the standard, adjust the AoI to be the largest. 
        % When the AoI is the same, adjust the queuing delay to be the smallest. When the queuing delay is the same, schedule randomly)
        function id = strategy_proportion_pro(obj, terminal_obj, ts, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); 
            if isempty(id_book)%terminal no packet
                id = 0;
                return
            end

            id_book = obj.find_terminal_within_proportion(terminal_obj, id_book, 1, 1, terminal_obj.proportion);
            %Select the terminal number in the scheduling ratio column in id_book (forward=1 allows returning empty)
            if isempty(id_book)%There are no terminals within the scheduling ratio among the existing terminals
                %Random scheduling at this time (according to arrival probability)
                id_book = obj.find_terminal_with_data(terminal_obj);
                id = id_book(obj.Generate_roulette(length(id_book), 1./terminal_obj.lambda(id_book)));
                %disp("ProportionPro use strategy: rand based on lambda");
            else%Among the existing terminals, there are terminals within the scheduling ratio
                if(ts ~= 1)
                    AoI_tem = terminal_obj.AoIdata(id_book, 2, 1);%Select AoIs that are not transmitting packets (including transmission interruptions)
                    id_book = id_book(AoI_tem == max(AoI_tem));
                    if(length(id_book) == 1)
                        id = id_book;
                        return
                    end
                end
                %Find the minimum queuing delay
                WT_tem = terminal_obj.data_state(id_book, 7);
                id_book = id_book(WT_tem == min(WT_tem));
                if(length(id_book) == 1)
                    id = id_book;
                    return
                end
                %Random scheduling among them (according to terminal arrival probability)
                id = id_book(obj.Generate_roulette(length(id_book), 1./terminal_obj.lambda(id_book)));

            end
        end

        %Optimal strategy for queuing delay without caching based on scheduling ratio constraint
        function id = strategy_proportion_nb(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj); 
            id = obj.proportion_nb_func(terminal_obj, id_book, terminal_obj.proportion);
        end

        %Improved version of optimal strategy for queuing delay without caching based on scheduling ratio constraint
        function id = strategy_proportion_nb_pro(obj, terminal_obj, ~, ~)
            id_book = obj.find_terminal_with_data(terminal_obj);
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
        
        %Ladder Scheduling Strategy
        function id = strategy_ladder(obj, terminal_obj, ts, fast_flag)
            %fast_flagWhether to use the fast algorithm (0-not use 1 use)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.strategy_greedy(terminal_obj, ts);
                return;
            end

            %XXXCur Each position index corresponds to the terminal number (id)
            %EPAoI_sort EPAoI sorted by AoI size, query EPAoI by sorting order
            %SortToIdArray Query terminal number by sort order
            %IdToSortArray Query sort order by terminal number
            AoICur = terminal_obj.AoIdata(:, 2, 1);%Information age of each terminal in the current slot (num*1)
            lambdaCur = terminal_obj.lambda;        %Packet arrival probability of each terminal (num*1)
            pnCur = terminal_obj.pn;                %Probability of packet transmission failure for each terminal
            numCur = terminal_obj.num;              %Number of terminals
            WTCur = terminal_obj.AoIdata(:, 2, 2); %The queuing delay of each terminal at the current moment

            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));
            %Sort the AoIs (descending order). When the AoIs are the same, it is based on lambda*(1-pn), 
            % the smaller the sequence number, the higher the front
            %Multiplying by 0.5 is to limit the latter to less than 1
            %The return value SortToIdArray is the terminal number (id) corresponding to each position after sorting                                                                                                                                               

            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;                       %Calculate EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                                       %Each position of EPAoI corresponds to each terminal number
            
%             if(ts == terminal_obj.ts_total)
%                 WT_tem = WTCur;
%                 WT_tem(terminal_obj.data_state(:, 1)~=1) = -1;
%                 obj.stem_pic(1:numCur, AoICur, "AoI");
%                 obj.stem_pic(1:numCur, EPAoICur, "EPAoI");
%                 obj.stem_pic(1:numCur, WT_tem, "WT");
%             end
            EPAoIStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);    %Stimulus generation structure (when not selected)

            id_book = obj.find_terminal_with_data(terminal_obj);                        %Find the terminal number with the package
            if(isempty(id_book))                                                        %no terminal has package
                id = 0;                                                                 %no scheduling
                return;
            end
            if(length(id_book) == 1)                                                    %Only one terminal has the package
                id = id_book(1);                                                        %No comparison, direct scheduling
                return
            end
            sort_book = sort(IdToSortArray(id_book));

            iter_num = 1;
            id_k0 = SortToIdArray(sort_book(iter_num));%Select the terminal number of AoI (descending order) among the terminals with packets in turn
            a_k0 = WTCur(id_k0);                     %queuing delay
            EPAoIChangeSruct = obj.Generate_EPAoIChangeStruct(0, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);        %0 - generate structure
            while 1
                for iter_part_num = iter_num + 1: length(id_book)
                    id_k = SortToIdArray(sort_book(iter_part_num));
                    EPAoIChangePartSruct = obj.Generate_EPAoIChangePartStruct(0, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray);
                    %0 - generate structure
                    if(obj.Compare_Struct(EPAoIChangeSruct, EPAoIChangePartSruct, lambdaCur, pnCur, 1111, EPAoIStruct, 1111, 1111) == 1)  
                        %The former is better (1111 means unused variables)
                        id = id_k0;
                        return;
                    end
                    %the latter is roughly better
                    a_k = WTCur(id_k);
                    EPAoIChangeSruct2 = obj.Generate_EPAoIChangeStruct(0, numCur, id_k, a_k, AoICur, lambdaCur, pnCur); %
                    if(obj.Compare_Struct(EPAoIChangeSruct, EPAoIChangeSruct2, lambdaCur, pnCur, 1111, EPAoIStruct, 1111, 1111) == 1)
                        if(iter_part_num == length(id_book))                                                            %Already compared
                            id = id_k0;
                            return;
                        end
                        continue;
                    end
                    %the latter is better
                    iter_num = iter_part_num;
                    if(iter_num == length(id_book))%only one left
                        id = id_k;
                        return
                    end
                    break;
                end

                id_k0 = SortToIdArray(sort_book(iter_num));%Select the terminal number of AoI (descending order) among the terminals with packets in turn
                a_k0 = WTCur(id_k0);                       %queuing delay
                EPAoIChangeSruct = obj.Generate_EPAoIChangeStruct(0, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur); 
            end
        end
        
        %Improved Ladder Scheduling Strategy
        function id = strategy_ladderpro(obj, terminal_obj, ts, fast_flag)
            persistent EPAoImax
            if isempty(EPAoImax) || (ts == 1)
                EPAoImax = 0;
            end
            id_book = obj.find_terminal_with_data(terminal_obj);
            [id, EPAoImax] = obj.ladderpro_func(terminal_obj, ts, fast_flag, id_book, EPAoImax);
        end

        %Improved Ladder Scheduling Strategy based on weight
        function id = strategy_ladderpro_wb(obj, terminal_obj, ts, fast_flag)
            persistent wEPAoImax
            if isempty(wEPAoImax) || (ts == 1)
                wEPAoImax = 0;
            end
            id_book = obj.find_terminal_with_data(terminal_obj);
            [id, wEPAoImax] = obj.ladderpro_wb_func(terminal_obj, ts, fast_flag, id_book, wEPAoImax);
        end
        
        %hybrid strategy
        %In the terminal where the scheduling ratio does not exceed the standard, use, 
        % when the AoI is the same, adjust the queuing delay to be the smallest, and when the queuing delay is the same, randomly schedule
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
            
            %Terminal use in dispatch ratios
            [id, wEPAoImax] = obj.ladderpro_wb_func(terminal_obj, ts, fast_flag, id_book, wEPAoImax);

        end
    end

    %Some public scheduling methods (can only be used in the scheduling strategy, not alone)
    methods(Access = private)
        %Agent's Greedy Strategy
        function id = greedy_func(obj, terminal_obj, ~, id_book)
            if(isempty(id_book))
                id = 0;
                return
            end


            AoI_tem = terminal_obj.AoIdata(id_book, 2, 1); %Select AoI
            id_book = id_book(AoI_tem == max(AoI_tem));

            if(length(id_book) == 1)
                id = id_book(1);
                return
            end
            WTCur = terminal_obj.AoIdata(:, 2, 2);             %The queuing delay of each terminal at the current moment
            id_book = id_book(WTCur(id_book) == min(WTCur(id_book)));
            if(length(id_book) == 1)
                id = id_book(1);
                return
            end
            id = id_book(obj.Generate_roulette(length(id_book), 1./(terminal_obj.lambda(id_book) ) ));
        end
        
        %Weight-based Agent Greedy Strategy
        function id = greedy_wb_func(obj, terminal_obj, ~, id_book)
            if(isempty(id_book))
                id = 0;
                return;
            end
            %Select Weighted AoI
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

        %The main body of the weight-based ladder strategy
        function [id, EPAoImax] = ladderpro_func(obj, terminal_obj, ts, fast_flag, id_book, EPAoImax) 
            %fast_flag Whether to use the fast algorithm (0-not use 1 use)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.greedy_func(terminal_obj, ts, id_book);
                return;
            end
            AoICur = terminal_obj.AoIdata(:, 2, 1);                        %The AoI of each terminal in the current slot(num*1)
            lambdaCur = terminal_obj.lambda;                                %Packet Arrival Probability for Each Endpoint（num*1）
            pnCur = terminal_obj.pn;                                        %Probability of packet transmission failure for each terminal
            numCur = terminal_obj.num;                                      %Number of terminals
            WTCur = terminal_obj.AoIdata(:, 2, 2);                         %The queuing delay of each terminal at the current moment
            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));                                                                                                                                                    

            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;                       %Calculate EPAoI
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                                       %Each position of EPAoI corresponds to each terminal number

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
            EPAoIStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);    %Stimulus generation structure (when not selected)

            if(isempty(id_book))                                                        %no terminal has package
                id = 0;                                                                 %no scheduling
                return;
            end
            if(length(id_book) == 1)                                                    %Only one terminal has the package
                id = id_book(1);                                                        %No comparison, direct scheduling
                return
            end
            sort_book = sort(IdToSortArray(id_book));

            iter_num = 1;
            id_k0 = SortToIdArray(sort_book(iter_num)); %Select the terminal number of AoI (descending order) among the terminals with packets in turn
            a_k0 = WTCur(id_k0);                        %queuing delay
            EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);          %1 - return EPAoICur
            while 1
                for iter_part_num = iter_num + 1: length(id_book)
                    id_k = SortToIdArray(sort_book(iter_part_num));
                    EPAoIChangePartCur = obj.Generate_EPAoIChangePartStruct(1, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray);
                    %1- Generate EPAoICur
                    if(obj.Compare_StructPro(EPAoIChangeCur, EPAoIChangePartCur, lambdaCur, pnCur, ...
                            EPAoImax, EPAoIStruct, IdToSortArray, 1111) == 1)                                           %the former is better                                      
                        id = id_k0;
                        return;
                    end
                    %the latter is roughly better
                    a_k = WTCur(id_k);
                    EPAoIChangeCur2 = obj.Generate_EPAoIChangeStruct(1, numCur, id_k, a_k, AoICur, lambdaCur, pnCur); %1 - return EPAoICur
                    if(obj.Compare_StructPro(EPAoIChangeCur, EPAoIChangeCur2, lambdaCur, pnCur, ...
                            EPAoImax, EPAoIStruct, IdToSortArray, 1111) == 1)                                           %the former is better
                        if(iter_part_num == length(id_book))                                                            %Already compared
                            id = id_k0;
                            return;
                        end
                        continue;
                    end
                    %the latter is better
                    iter_num = iter_part_num;
                    if(iter_num == length(id_book))%only one left
                        id = id_k;
                        return
                    end
                    break;
                end

                id_k0 = SortToIdArray(sort_book(iter_num));%Select the terminal number of AoI (descending order) among the terminals with packets in turn
                a_k0 = WTCur(id_k0);                       %queuing delay
                EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);    %1 - return EPAoICur
            end
        end

        %The main body of the weight-based ladder strategy
        function [id, wEPAoImax] = ladderpro_wb_func(obj, terminal_obj, ts, fast_flag, id_book, wEPAoImax)
            %fast_flag Whether to use the fast algorithm (0-不使用 1使用)
            if(ts <= terminal_obj.num && fast_flag)
                id = obj.greedy_wb_func(terminal_obj, ts, id_book);
                return;
            end
            AoICur = terminal_obj.AoIdata(:, 2, 1);                        %The AoI of each terminal in the current slot(num*1)
            alphaCur = terminal_obj.alpha;                                  %weight for each terminal
            lambdaCur = terminal_obj.lambda;                                %Packet Arrival Probability for Each Endpoint（num*1）
            pnCur = terminal_obj.pn;                                        %Probability of packet transmission failure for each terminal
            numCur = terminal_obj.num;                                      %Number of terminals
            WTCur = terminal_obj.AoIdata(:, 2, 2);                         %The queuing delay of each terminal at the current moment
            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));                                                                                                                                                    

            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;           %
            assert(size(EPAoI_sort, 2) == 1)
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);                           %Each position of EPAoI corresponds to each terminal number
            wPAoICur = EPAoICur .* alphaCur;                                %Weighted EPAoI

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
            EPAoIStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);    %Stimulus generation structure (when not selected)

            if(isempty(id_book))                                                        %no terminal has package
                id = 0;                                                                 %no scheduling
                return;
            end
            if(length(id_book) == 1)                                                    %Only one terminal has the package
                id = id_book(1);                                                        %No comparison, direct scheduling
                return
            end
            sort_book = sort(IdToSortArray(id_book));

            iter_num = 1;
            id_k0 = SortToIdArray(sort_book(iter_num)); %Select the terminal number of AoI (descending order) among the terminals with packets in turn
            a_k0 = WTCur(id_k0);                        %queuing delay
            EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);          %1 - return EPAoICur
            while 1
                for iter_part_num = iter_num + 1: length(id_book)
                    id_k = SortToIdArray(sort_book(iter_part_num));
                    EPAoIChangePartCur = obj.Generate_EPAoIChangePartStruct(1, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray);
                    %1- Generate EPAoICur
                    if(obj.Compare_StructPro_wb(EPAoIChangeCur, EPAoIChangePartCur, lambdaCur, pnCur, ...
                            wEPAoImax, EPAoIStruct, IdToSortArray, alphaCur) == 1)                                                 %the former is better
                        id = id_k0;
                        return;
                    end
                    %the latter is roughly better
                    a_k = WTCur(id_k);
                    EPAoIChangeCur2 = obj.Generate_EPAoIChangeStruct(1, numCur, id_k, a_k, AoICur, lambdaCur, pnCur); %1-return EPAoICur
                    if(obj.Compare_StructPro_wb(EPAoIChangeCur, EPAoIChangeCur2, lambdaCur, pnCur, ...
                            wEPAoImax, EPAoIStruct, IdToSortArray, alphaCur) == 1)                                     %the former is better
                        if(iter_part_num == length(id_book))                                                           %Already compared
                            id = id_k0;
                            return;
                        end
                        continue;
                    end
                    %the latter is better
                    iter_num = iter_part_num;
                    if(iter_num == length(id_book))%only one left
                        id = id_k;
                        return
                    end
                    break;
                end

                id_k0 = SortToIdArray(sort_book(iter_num));%Select the terminal number of AoI (descending order) among the terminals with packets in turn
                a_k0 = WTCur(id_k0);                       %queuing delay
                EPAoIChangeCur = obj.Generate_EPAoIChangeStruct(1, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur);    %1-return EPAoICur
            end
        end
        
        %The main function of proportion_nb
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

        %Maximum Weight Policy
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

        %Whittle Indexing Strategy
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
            %The queuing delay under the model is 0, so it is best not to set lambda to 1 when using this strategy
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

    %some functions
    methods(Access = private)

        %Find the terminal with the package
        function id = find_terminal_with_data(~, terminal_obj)
            assert(class(terminal_obj) == "Terminal", "error input class -> terminal_obj")
            id = find(terminal_obj.data_state(:,1) == 1);
%             if(isempty(id))
%                 disp("find_terminal_with_data: return []");
%             end
        end

        function id = find_terminal_within_proportion(~, terminal_obj, id_book, mode, forward, proportion)
            %When mode is 0, return the terminal id vector (column) in the scheduling ratio in terminal_obj
            %When mode is 1, return the terminal id vector (column) in the scheduling ratio in id_book

            %forward is 1, some error reports are omitted, the default is 0
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
                    %find the package in the dispatch scale
                    index_tem = terminal_obj.Scheduling_Times./sum(terminal_obj.Scheduling_Times) <= proportion;
                    id = mat_tem(index_tem);
                    return

                case 1
                    %check id_book
                    assert(~isempty(id_book) || f_flag, "invalid input(empty) -> id_book" );%flag is 1 to allow id_book to be empty
                    if(isempty(id_book))
                        if(~f_flag)
                            warning(["find_terminal_within_proportion:return []" newline "->input id_book is empty"]);
                        end
                        id = [];
                        return
                    end
                    
                    assert((max(id_book) <= terminal_obj.num) && min(id_book) > 0, ["error input value -> id_book" newline mat2str(id_book)]);
                    if(sum(terminal_obj.Scheduling_Times(id_book)) == 0)
                        index_tem = id_book ~= 0;%Here just do a logical conversion to generate a logical vector of all 1s with the same size as id_book
                    else 
                        index_tem = terminal_obj.Scheduling_Times(id_book)./sum(terminal_obj.Scheduling_Times(id_book)) ...
                        <= proportion(id_book);
                    end

                    if(~any(index_tem))%None of the conditions are met
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
        
        %Generate a roulette wheel and return the result
        function id = Generate_roulette(~, n, pro_set)
            %The return value is the serial number drawn
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

    %Functions used by the ladder strategy
    methods(Access = private)
        %Incentives to generate EPAoI-related data structures
        function value_struct = Generate_EPAoIStruct(~, EPAoICur, IdToSortArray, numCur)
            %Return value: read the id number of the terminal in EPAoI 
            % value_struct.ter_mat(1:value_struct.count(EPAoI),value_struct.mat_index(EPAoI))
            % If it is empty, it means that there is no corresponding EPAoI
            assert((size(EPAoICur, 1) > 1) && (size(EPAoICur, 2) == 1), 'error input -> EPAoICur');%Needs to be a column vector
            value_tem = tabulate(EPAoICur);
            value_tem = value_tem((value_tem(:, 2) ~= 0) & (value_tem(:, 1) ~= 0), 1:2);           %Remove rows with EPAoI of 0 and statistics of 0
            EPAoI_stat = value_tem(:, 1);           %what are included
            count_stat = value_tem(:, 2);           %Quantity included
            num_EPAoI = numCur + 2000;              %The default length of the table is num_EPAoI
            value = (1:num_EPAoI)';                 %The number of rows corresponds to EPAoI for easy query
            mat_index = zeros(num_EPAoI, 1);
            count = zeros(num_EPAoI, 1);
            ter_mat = zeros(numCur, numCur);
            sort_mat = zeros(numCur, numCur);
            
            mat_tem = repmat((1:numCur)', 1, numCur);%for making logical tables
            %The corresponding data is written into the table
            %EPAoI may be 0
            assert(~any(EPAoI_stat == 0), "value error -> EPAoI = 0");
            mat_index(EPAoI_stat) = 1:length(EPAoI_stat);
            index = find(EPAoICur == EPAoI_stat');
            %Notes on the usage
            %EPAoICur = [7 8 6 7 7]';
            %EPAoI_stat = [6 7 8]';
            %find(EPAoICur = EPAoI_stat')
            %Effect repmat(EPAoICur, 1, length(EPAoI_stat'))
            %Find EPAoI_stat'(i) in the i-th column and return the column-oriented index
            assert((size(index, 1) > 1) && (size(index, 2) == 1), "error");%Should be a column vector
            len_E = length(EPAoICur);
            while 1
                if(any(index > len_E))
                    index(index > len_E) = index(index > len_E) - len_E;
                else
                    break;
                end
            end
        
            mat_index_tem = mat_tem <= [count_stat', zeros(1, numCur - length(count_stat))];%Make matrix logical indexing (matrix is returned as a column vector using this indexing)
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

        %Generate EPAoIChangeSruct
        function value = Generate_EPAoIChangeStruct(obj, flag, numCur, id_k0, a_k0, AoICur, lambdaCur, pnCur)
            %flag 0 - returns EPAoIChangeStruct 1 - returns EPAoICur
            AoICur = AoICur + 1;
            AoICur(id_k0) = a_k0 + 1;

            [~, SortToIdArray] = sort(-(AoICur - 0.5 * lambdaCur .* (1 - pnCur)));
            EPAoI_sort = AoICur(SortToIdArray) + (1:numCur)' - 1;                       %Calculate EPAoI
            [~, IdToSortArray] = sort(SortToIdArray);
            EPAoICur = EPAoI_sort(IdToSortArray);
            if(flag)
                value = EPAoICur;
                return
            end
            EPAoIChangeStruct = obj.Generate_EPAoIStruct(EPAoICur, IdToSortArray, numCur);
            value = EPAoIChangeStruct;
        end

        %
        function value = Generate_EPAoIChangePartStruct(obj, flag, numCur, EPAoICur, id_k, IdToSortArray, SortToIdArray)%Use the original IdToSortArray
            %flag 0 - returns EPAoIChangeStruct 1 - returns EPAoICur
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

        %return comparison result
        function value = Compare_Struct(~, Struct_front, Struct_after, lambdaCur, pnCur, ~, EPAoIStruct, ~, ~)
            %Regarding the return value 1 - the former is better 0 - the latter is better
            recCur = lambdaCur.*(1 - pnCur);
            s1 = Struct_front;
            s2 = Struct_after;

            eps = EPAoIStruct;

            %Get related data
            s1_maxEP = max(s1.EPAoIMat(:, 1));
            s2_maxEP = max(s2.EPAoIMat(:, 1));

            if(s1_maxEP > s2_maxEP)
                value = 0;
                return
            elseif(s1_maxEP < s2_maxEP)
                value = 1;
                return
            end
            
            %The case where the maximum EPAoI is equal
            index = s1_maxEP;
            while 1
                if(s1.count(index) + s2.count(index) == 0)%None
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
                %In the case of equality, compare the acceptance probability
                arr1 = prod(recCur(s1.ter_mat(1:s1.count(index), s1.mat_index(index)) ) );
                arr2 = prod(recCur(s2.ter_mat(1:s2.count(index), s2.mat_index(index)) ) );
                if(c_flag) %The bigger the better
                    if(arr1 < arr2)
                        value = 0;
                        return;
                    elseif(arr1 > arr2)
                        value = 1;
                        return
                    end
                else    %The smaller the better
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
                %equal compare next
                index = index - 1;
            end

        end

        function value = Compare_StructPro(obj, EPH_front, EPH_after, lambdaCur, pnCur, EPAoImx, EPAoIStruct, IdToSortArray, ~)
            %Regarding the return value 1 - the former is better 0 - the latter is better
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

            if(value1 + value2 == 0)                                    %The probability of not breaking through the existing EPAoI maximum is zero
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
            %Regarding the return value 1 - the former is better 0 - the latter is better
            recCur = lambdaCur.*(1 - pnCur);
            e1 = EPH_front;
            e2 = EPH_after;
            w_e1 = alphaCur .* e1;
            w_e2 = alphaCur .* e2;

            assert(all(size(w_e1) == size(w_e2)));
            f = @(array) mod(array, 1) == 0;            %Find the logical index of an integer
            mk1 = (wEPAoImx - w_e1) .* (1 ./ alphaCur);
            index_logi = f(mk1);
            mk1(~index_logi) = ceil(mk1(~index_logi));    %Non-integer round up
            mk1(index_logi) = mk1(index_logi) + 1;    %

            mk2 = (wEPAoImx - w_e2) .* (1 ./ alphaCur);
            index_logi = f(mk2);
            mk2(~index_logi) = ceil(mk2(~index_logi));    %Non-integer round up
            mk2(index_logi) = mk2(index_logi) + 1;    %Integer plus 1

            value1 = prod( 1 - (1 - recCur) .^ mk1 );
            value2 = prod( 1 - (1 - recCur) .^ mk2 );

            if(value1 + value2 == 0)                    %The probability of not breaking through the existing EPAoI maximum is zero
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