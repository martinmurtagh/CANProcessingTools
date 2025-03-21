function [candb,data] = CANProcessingTool()
% This is the master script for decoding CAN traces
%% Import known CAN dbc files
% importASCIIData()
[candb, dbmessages,~] = importDBCFiles();
%% Import the PCAN or .asc CAN trace
[data, trace] = importCANTrace(candb, dbmessages);
% data = importCANTraceASC();
%% Create list of discovered messages and a new dbc file

%% Add a plotting tool for discovered messages
CANTracePlottingTool(trace)
end
%% *** NOTES ***
% Consider splitting out import function from processing functions. 

% Need to make sure the importDBCFiles function can work with single and
% multipe dbc files.

% Complete process of process the trace data from data table. This will
% allow stacked plotting later.

% Consider importing message data as individual bytes. This will help if
% data needs reversed or if motorala/intel format specifice. 

% Need to make sure the import CANTrace function works with both .asc
% traces from CANalyzer and .trc files from Peak PCAN traces.
