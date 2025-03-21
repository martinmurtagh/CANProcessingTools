function CANTracePlottingTool(trace)
%%
fn1 = fieldnames(trace); 
fn2=strings(size(fn1)); % preallocate string for fieldnames
for ii = 1:numel(fn1)
    fn2(ii,1)=fn1{ii,1}; % convert cell of message names to strings
end
numFields = numel(fn2); % number of messages in the trace

for idx = 1:numFields
    signames1 = fieldnames(trace.(fn2(idx)).signals);
    signames2 = strings(size(signames1));
    for jj = 1:numel(signames1)
        signames2(jj,1) = signames1{jj,1};
    end
    numSignals = numel(signames2);
    % newTable =table(trace.(fn2(idx)).timeStamp);
    figure
    for idx2 = 1:numSignals
        subplot(numSignals,1,idx2)
        x=trace.(fn2(idx)).timeStamp;
        y=trace.(fn2(idx)).signals.(signames2(idx2)).data;
        plot(x,y)
    end
end
    
% *** Need to put data into a table if you want to use the stacked plot
% feature. Consider doing this back in the importCANTrace script ***
%% Plotting tool
% have a list of messages and signal that is easy to search/click a signal
% or multiple signals to plot. Plot discrete data for each signal.

% subplot(2,1,1)
% x=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.time;
% y=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.data;
% plot(x,y)
% 
% subplot(2,1,2)
% x=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.time;
% y=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.data;
% plot(x,y)
%% To do list
% Remove dataArray from the mix and remove from workspace
% Full list of signals seperately form candb
% Add ability to load multiple dbc files
% Add ability to load multiple data files at once
% How to handle duplicates
% How to handle duplicate messages but on seperate channels
% Find out the difference between a standard and extended CAN message and
% work out if it affects the processing of the message
% Export signals to matlab workspace
% Save data to a .mat file, excel or a txt document
end