function mf_results = bd_model_free(file)
    subdat = readtable(file);
    
        
    if strcmp(class(subdat.response_time),"cell")
       subdat.response_time = str2double(subdat.response_time);
    end
    main_row_idx = find(strcmp(subdat.trial_type, 'MAIN'));
    subdat = subdat(main_row_idx+1:end, :);


%     observations.obs = cell(1,108);
%     observations.obs = cell(1,108);
% 
%     actions = cell(1,108);
%     rts = cell(1,108);
    trials = 107;
    for i = 0:trials
        %Extract the relevant rows from df for the current trial
        trial_data = subdat(subdat.trial == i, {'response','trial_type', 'result', 'response_time'});

        %Let's build an array of states 

        %0 initial state, 1 not having a date 2 having a date
        num_waits = sum(strcmp(trial_data.response, 'right'));
        num_accepts = sum(strcmp(trial_data.response, 'left'));
        n = 1 + num_waits + num_accepts;
        state_array = nan(n, 1);

        % Assign values
        state_array(1) = 0; % 0 for initial state
        state_array(2:num_waits+1) = 1;  % Fill with 1s for not having a date
        state_array(2+num_waits:end) = 2;  % Fill with 2s for accepting date

        trial_type = trial_data.trial_type{1};
        split_str = strsplit(trial_type, '_');
        high_offer_time = str2double(split_str{2})+1; % time high offer is given
        rejection_time = str2double(split_str{3}); % time rejection happens
        observation_array = nan(n, 1);
        observation_array(1) = str2num(trial_data.response{1});

         if high_offer_time == n % if got high offer
            observation_array(length(observation_array)) = 90;
         elseif any(state_array(end) == 2) % if accepted initial offer
            observation_array(length(observation_array)) = observation_array(1);
         elseif rejection_time == n % if got rejected
            observation_array(length(observation_array)) = 0;
         else  %if rejected the initial offer
            observation_array(length(observation_array)) = 0;
         end

        % reaction time
        reaction_times = nan(n,1);
        reaction_times(2:end) = trial_data.response_time(~isnan(trial_data.response_time));


        observations.obs{1,i+1} = observation_array;
        observations.trial_length{1,i+1} = str2double(split_str{1});

        actions.choice{1,i+1} = state_array;
        actions.rts{1,i+1} = reaction_times;

    end
    
    num_dates_4_games = 0;
    num_dates_8_games = 0;
    num_initial_offers_accepted_4_games = 0;
    num_initial_offers_accepted_8_games = 0;
    num_high_offers_accepted_4_games = 0; % number of high offers accepted
    num_high_offers_accepted_8_games = 0; % number of high offers accepted
    initial_offers_total_4_games = 0;% total value of initial offers accepted (to later get avg value)
    initial_offers_total_8_games = 0;% total value of initial offers accepted (to later get avg value)
    time_step_when_accepted_initial_offer_4_games = [];
    time_step_when_accepted_initial_offer_8_games = [];
    for i=1:length(actions.choice)
        game_choices = actions.choice{i};
        trial_length = observations.trial_length{i};
        obs = observations.obs{i}; 
        
        if any(game_choices == 2) % if accepted initial offer or high offer
            if trial_length ==4
                num_dates_4_games = num_dates_4_games+1;
            else
                num_dates_8_games = num_dates_8_games+1;
            end
        end
        offer_ended_up_with = obs(end); % get offer person accepted
        % if person accepted initial offer
        if (offer_ended_up_with ~= 0 && offer_ended_up_with ~= 90)
            if trial_length ==4
                num_initial_offers_accepted_4_games = num_initial_offers_accepted_4_games+1;
                initial_offers_total_4_games = initial_offers_total_4_games+offer_ended_up_with;
                time_step_when_accepted_initial_offer_4_games = [time_step_when_accepted_initial_offer_4_games length(game_choices)-1];
            else
                num_initial_offers_accepted_8_games = num_initial_offers_accepted_8_games+1;
                initial_offers_total_8_games = initial_offers_total_8_games+offer_ended_up_with;
                time_step_when_accepted_initial_offer_8_games = [time_step_when_accepted_initial_offer_8_games length(game_choices)-1];
            end          
        else
            if offer_ended_up_with==90
                if trial_length ==4
                    num_high_offers_accepted_4_games = num_high_offers_accepted_4_games+1;
                else
                    num_high_offers_accepted_8_games = num_high_offers_accepted_8_games+1;
                end
            end
        end
        
    end
    avg_initial_offer_accepted = (initial_offers_total_4_games+initial_offers_total_8_games)/...
                                 (num_initial_offers_accepted_8_games+num_initial_offers_accepted_4_games);
    avg_timestep_accepted_initial_offer = (sum(time_step_when_accepted_initial_offer_4_games)+sum(time_step_when_accepted_initial_offer_8_games))/...
                                  (length(time_step_when_accepted_initial_offer_4_games)+length(time_step_when_accepted_initial_offer_8_games));

    avg_initial_offer_accepted_4_games = initial_offers_total_4_games/num_initial_offers_accepted_4_games;
    avg_initial_offer_accepted_8_games = initial_offers_total_8_games/num_initial_offers_accepted_8_games;

    avg_timestep_accepted_initial_offer_4_games = sum(time_step_when_accepted_initial_offer_4_games)/length(time_step_when_accepted_initial_offer_4_games);
    avg_timestep_accepted_initial_offer_8_games = sum(time_step_when_accepted_initial_offer_8_games)/length(time_step_when_accepted_initial_offer_8_games);


    

    mf_results.num_dates = num_dates_4_games + num_dates_8_games;
    mf_results.num_dates_4_games = num_dates_4_games;
    mf_results.num_dates_8_games = num_dates_8_games;

    mf_results.num_initial_offers_accepted = num_initial_offers_accepted_4_games+ num_initial_offers_accepted_8_games;
    mf_results.num_initial_offers_accepted_4_games = num_initial_offers_accepted_4_games;
    mf_results.num_initial_offers_accepted_8_games = num_initial_offers_accepted_8_games;
    
    mf_results.num_high_offers_accepted = num_high_offers_accepted_4_games + num_high_offers_accepted_8_games;
    mf_results.num_high_offers_accepted_4_games = num_high_offers_accepted_4_games;
    mf_results.num_high_offers_accepted_8_games = num_high_offers_accepted_8_games;

    mf_results.avg_initial_offer_accepted = avg_initial_offer_accepted;
    mf_results.avg_initial_offer_accepted_4_games = avg_initial_offer_accepted_4_games;
    mf_results.avg_initial_offer_accepted_8_games = avg_initial_offer_accepted_8_games;
    
    mf_results.avg_timestep_accepted_initial_offer = avg_timestep_accepted_initial_offer;
    mf_results.avg_timestep_accepted_initial_offer_4_games = avg_timestep_accepted_initial_offer_4_games;
    mf_results.avg_timestep_accepted_initial_offer_8_games = avg_timestep_accepted_initial_offer_8_games;

end