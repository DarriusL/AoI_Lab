classdef Terminal < handle
    %
    properties (Access = public)
         num % number of terminals
         ts_total % simulates the total duration of time slots
         lambda % Bernoulli process lambda of packet arrival
         pn % packet transmission interruption probability
         alpha % importance of each device
        
         max_arrival_interval % maximum arrival interval
         max_transport_interval % maximum transmission interval

         data_state % the state of the current time slot
        
         AoIdata % The information age of the terminal's data packet
         AoIaddup % terminal information age accumulation

         pAoI_num % The number of peak information ages obtained in this simulation
         PAoIaddup % terminal peak information age accumulation
         wPAoImax % weighted maximum peak information age

         ph_avg_terminal % average peak information age of each terminal num*1
         ph_avg_system % The average peak information age of the entire system 1*1

         Scheduling_id %Record the terminal number of the current time slot scheduling
         Scheduling_Times% records the number of times each terminal is scheduled

         strategy % scheduling strategy
         proportion % The optimal scheduling ratio under the optimal strategy of queuing delay based on scheduling ratio constraints
         proportion_pro

         random_mode
         simulation_mode % simulation mode

         TsBlock % This is a row vector
    end
    
    methods (Access = public)
        %Constructor
        function obj = Terminal(num_in, ts_t, lambda_in, pn_in, strategy_name_in, alpha_in, random_mode_in, simu_mode_in) %lambda_in, pn_in可为空
            obj.num = num_in;
            obj.ts_total = ts_t;
            
            if isempty(lambda_in)
                obj.lambda = rand(obj.num, 1);
            else
                assert(size(lambda_in,1)==num_in, 'lambda_in wrong input dimension')
                obj.lambda = lambda_in;
            end
            
            if isempty(pn_in)
                obj.pn = rand(obj.num, 1);
            else
                assert(size(pn_in,1)==num_in, 'pn_in wrong input dimension')
                obj.pn = pn_in;
            end
            
            assert(size(alpha_in,1)==num_in, 'alpha_in wrong input dimension')
            obj.alpha = alpha_in/sum(alpha_in);
            %obj.alpha = alpha_in;

            obj.data_state = [ones(obj.num, 3), zeros(obj.num, 4)]; %By default, there are packages at the initial moment
            obj.AoIdata = zeros(obj.num, 2, 2);                     %Only record the last time slot and the current time slot
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
            obj.max_arrival_interval = zeros(ts_t + 1, 1);          %The terminal number corresponding to the last element record
            obj.max_transport_interval = zeros(2, 1);               %One to record the previous time slot (1), one to record the current time slot (2)
            obj.random_mode = random_mode_in;
            obj.simulation_mode = simu_mode_in;
            obj.TsBlock = [];
        end
        
        %get package (get at the same time)
        function get_data(obj, ts, ArrLogiMat)%ts - current time slot
            persistent ts_prov_array

            if(ts == 1)                                    
                ts_prov_array = obj.data_state(:, 2);
            end

            tem = ArrLogiMat(:, ts);
            obj.data_state(tem, 1) = ones(sum(tem), 1);    %package arrives
            obj.data_state(tem, 2) = ts*ones(sum(tem), 1); %The time the new package arrives

            idArray = 1:obj.num;
            %Start recording packet arrival intervals
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
            
            ts_prov_array(tem) = ts*ones(sum(tem), 1);     %Record the time when new packages arrive
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
        
        
        %The terminal sends data to the central
        function ts_tem = transport(obj, id, ts, TransRandMat)%id-The index determined by the decision-making process
            % (assuming that the transmission starts immediately after receiving the decision, and the transmission delay is 1 slot)
            %Transfer decision information, start transmission
            r = TransRandMat(ts);
            ts_tem = 0;
            persistent ts_prov_array
            if id == 0
                return;
            end
            trans_flag = r > obj.pn(id);
            if id > 0 && id <= obj.num
                if obj.data_state(id, 1)
                    if trans_flag       %The transmission is not interrupted, and the current time slot starts to transmit
                        obj.data_state(id, 6) = 1;
                        obj.data_state(id, 5) = ts;
                        ts_tem = obj.data_state(id, 2);
                        obj.Scheduling_id(ts) = id;
                        obj.Scheduling_Times(id) = obj.Scheduling_Times(id) + 1;    %The transmission is not interrupted before it is scheduled once
                    else
                        obj.data_state(id, 6) = 0;
                    end
                end
                obj.data_state(id, 1) = 0;%In any case, after the packet is sent, there is no packet in the terminal
                obj.data_state(id, 2) = 0;%The latest packet arrival time slot is 0, that is, no packet arrives,
                
            end
            
            if(obj.strategy.strategy_name ~= "LadderPro" || ~trans_flag)
                return
            end

            if(ts == 1)|| isempty(ts_prov_array) || length(ts_prov_array) ~= obj.num
                ts_prov_array = zeros(obj.num, 1);     
            end

            %Start recording packet transmission interval
            max_tem = (ts - ts_prov_array(id)) * obj.alpha(id);
            %Update last time slot
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

        %
        function recive(obj, ts, ts_tem)%ts - the current time slot, 
            % ts_tem - the generation time of the transmitted packet (0 means there is no packet to receive or the transmission failed)
            assert(ts > ts_tem, "input error -> ts_tem");
            if(ts_tem == 0)
                return
            end
             %Determine whether other transmissions have arrived
            row_logi = obj.data_state(:, 6) == 1;
            if ~all(row_logi == 0)
                if ts >= obj.data_state(row_logi, 5) + 1
                    obj.data_state(row_logi, 6) = 0;%The packet arrives successfully, and the transmission is set to 0
                    obj.data_state(row_logi, 3) = 1;
                    obj.data_state(row_logi, 4) = ts_tem;
                end
            end
        end

       
        %
        function calculate_WT(obj, ts)
            obj.data_state(:, 7) = (ts - obj.data_state(:, 2)).*obj.data_state(:, 1);
        end

        %Calculate the information age between the current slot terminal and the central base station
        function calculate_AoI(obj, ts)
            obj.AoIdata(:, 1, :) = obj.AoIdata(:, 2, :);                             %Update last time slot
            obj.AoIdata(:, 2, 1) = (ts - obj.data_state(:, 4)).*obj.data_state(:, 3);%Calculate the AoI of the latest packet received by the central base station
            obj.AoIdata(:, 2, 2) = (ts - obj.data_state(:, 2)).*obj.data_state(:, 1);%Calculate the AoI of the latest packet received by the terminal
            col_logi = obj.TsBlock >= ts;
            obj.AoIaddup(:, col_logi) = obj.AoIaddup(:, col_logi) + repmat(obj.AoIdata(:, 2, 1), 1, sum(col_logi));
            if ts >= 2
                row_logi = obj.AoIdata(:, 2, 1) <= obj.AoIdata(:, 1, 1);
                
                pAoI = obj.AoIdata(row_logi, 1, 1);
                wPAoI = pAoI .* obj.alpha(row_logi);
                obj.PAoIaddup(row_logi, col_logi) = obj.PAoIaddup(row_logi, col_logi) + repmat(pAoI, 1, sum(col_logi));
                obj.pAoI_num(row_logi, col_logi) = obj.pAoI_num(row_logi,col_logi) + 1; %Record the number of times the peak message age is reached
                
                idarray = (1:obj.num)';
                idarray = idarray(row_logi);
                row_logi = obj.wPAoImax(row_logi, end) < wPAoI;
                idarray = idarray(row_logi);
                obj.wPAoImax(idarray, col_logi) = repmat(wPAoI(row_logi), 1, sum(col_logi));
            end
            
            if ts == obj.ts_total %last slot
                row_logi = obj.AoIdata(:, 2, 1) ~= 0;
                obj.PAoIaddup(row_logi, end) = obj.PAoIaddup(row_logi, end) + obj.AoIdata(row_logi, 2, 1);
                obj.pAoI_num(row_logi,end) = obj.pAoI_num(row_logi,end) + 1; %Record the number of times the peak message age is reached
            end
        end

        %Calculate the optimal scheduling ratio under the optimal strategy of queuing delay based on scheduling ratio constraints
        function calculate_proportion(obj)
            %fun = @(x)mean(sum((obj.alpha)'.*(1./x)));
            %obj.proportion = fmincon(fun, 1/obj.num*ones(1, obj.num), ones(1, obj.num), 1, ones(1, obj.num), 1, zeros(1, obj.num), ones(1, obj.num));
            %obj.proportion = sqrt(obj.alpha ./ (1 - obj.pn))./sum(sqrt(obj.alpha ./ (1 - obj.pn)));
            obj.proportion_pro = obj.alpha ./ (1 - obj.pn)./ (sum(obj.alpha ./ (1 - obj.pn)));
            %obj.proportion = fmincon(fun, sqrt(obj.alpha)./sum(sqrt(obj.alpha)), ones(1, obj.num), 1, ...
            %ones(1, obj.num), 1, zeros(1, obj.num), obj.lambda');
            f = @(v) abs( sum( min(obj.lambda, sqrt( obj.alpha ./ (( 1 - obj.pn) .* v) ))) - 1);
            options = optimoptions('fmincon', 'Display', 'off');
            v = fmincon(f, 50, -1, 0, [], [], [], [], [], options);
            obj.proportion = min(obj.lambda, sqrt( obj.alpha ./ (( 1 - obj.pn) .* v) ));
        end
        
        %
        function [theoretical_lower_bound, STI, MAI, theoretical_lower_bound_phmax] = simulation_start(obj, simu_rounds, ts_block)
            assert(ts_block(end) == obj.ts_total);
            obj.TsBlock = ts_block';
            obj.AoIaddup = zeros(obj.num, length(ts_block));
            obj.PAoIaddup = obj.AoIaddup;                           %the same initialization value
            obj.wPAoImax = obj.AoIaddup;                            %the same initialization value
            obj.pAoI_num = obj.AoIaddup;                            %the same initialization value

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
    
         % Calculate terminal average weighted peak information age pAoI_avg
         % Calculate terminal average weighted information age AoI_avg
        function value_struct = calculate(obj, ts_block) %(average peak information age 1*1, average AoI, maxpAoI) of packets returned to central base station
            assert(ts_block(end) == obj.ts_total);
            value_struct.phavg = zeros(1, length(ts_block));
            value_struct.AoI_avg_system = zeros(1, length(ts_block));
            value_struct.pAoI_max_system = zeros(1, length(ts_block));

            for rounds = 1:length(ts_block)
                ts_tem_top = ts_block(rounds);
                % AoI_avg_terminal = zeros(obj.num, 1);
                % pAoI_max_terminal = zeros(obj.num, 1);
                %Calculate the average peak AoI of each terminal
                obj.ph_avg_terminal = obj.PAoIaddup(:, rounds) ./ obj.pAoI_num(:, rounds);
                %Calculate the average AoI of each terminal
                AoI_avg_terminal = obj.AoIaddup(:, rounds) / ts_tem_top;
                %Get the maximum pAoI per terminal -> obj.wPAoImax(:, rounds)
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

        %Plot the average peak information age series plot of the system
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
            %Enable setting random seed conditions: same random mode, same simulation round
            if( obj.random_mode && simulation_rounds ~= simu_rounds)
                simulation_rounds = simu_rounds;
                rand_send = randperm(3696, 1);
                %disp(['The random seed setting for the current simulation is complete:', num2str(rand_send)]);
            end

            if(obj.random_mode == 0) %completely random pattern
                rng('shuffle');
            else                         %Same random pattern (only arrivals are the same, interrupts may be the same)
                rng(rand_send);
            end
            rand_ArrMat = rand(obj.num, obj.ts_total);
            TransRandMat = rand(1, obj.ts_total);
            ArrLogiMat = rand_ArrMat < obj.lambda;
            rng('shuffle');
        end
    end
end
