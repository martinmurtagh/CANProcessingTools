function [candb, dbmessages, dbc] = importDBCFiles()
%% Decoding an ascii CAN trace
%% Import Database file
% Import one or more dbc file for decoding the ascii log file
% db = [];
% hexStr = dec2hex(2566909940);
% tic
[file,path] = uigetfile('*.dbc','Select One or More DBC Files','MultiSelect', 'on');
if path == 0
    disp('Simulation Cancelled')
   return
end
file=string(file);
[~,~] = fileparts(file);
%% Set up the Import Options and import the dbc variables
opts = delimitedTextImportOptions("NumVariables", 15);

% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = [" ", ",", ":", "@", "|"];

% Specify column names and types
opts.VariableNames = ["VarName1", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["VarName1", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["VarName1", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15"], "EmptyFieldRule", "auto");
dbc=struct();
%% Read in the dbc data
% for each dbc file read in its name, its path and the file contents to the
% structure dbc 
for i = 1:numel(file)
    dbc(i).file = readmatrix(fullfile(path,file{i}), opts);
    dbc(i).name = file{1,i};
    dbc(i).path = path;
end
% CANSystemWB = readmatrix("C:\Users\martin.murtagh\OneDrive - Wrights Group Ltd\Testing\Setups\dbc files\AT330_DoubleDeckEV\CAN_System_WB.dbc", opts);

% Clear temporary variables
clear i opts dbcfile file path name
%% Create CAN database structure
% dbcFiles = 'C:\Users\martin.murtagh\OneDrive - Wrights Group Ltd\Testing\Setups\dbc files\AT330_DoubleDeckEV\CAN_System_WB.dbc';
% messageDetails = ['ID','name','DLC','transmitter'];
% signalDetails = ['name','startBit','length','byteOrder','valueType','scale','offset','min','max','unit','receiver'];
% processing messages

candb=struct();
% Create a list of all the database messages in one location from all dbc
% files
% dbmessages = strings(0,4);
% for i = 1:numel(dbc)
% %     a = dbc(1).file(dbc(1).file(:,1) == "BO_",[2,3,5,6]);
%     dbmessages=[dbmessages;dbc(1).file(dbc(1).file(:,1) == "BO_",[2,3,5,6])];
% end
% dbmessages = CANSystemWB(CANSystemWB(:,1) == "BO_",[2,3,5,6]);
% dbmessages = dbc.file(dbc.file(:,1) == "BO_",[2,3,5,6]);
for j=1:length(dbc)

    dbmessages = dbc(j).file(find(dbc(j).file(:,1) == "BO_"),[2,3,5,6]);
    % messages(:,5) = dec2hex(str2double(messages(:,1))-2147483648);
    % dbmessages(:,5) = strcat([dec2hex(str2double(dbmessages(:,1))-2147483648),repmat('x',size(dbmessages(:,1)))],'');
    for i=1:length(dbmessages(:,1))
        if str2double(dbmessages(i,1))<hex2dec('7FF') % if message is 11 bit 
            dbmessages(i,5) = dec2hex(str2double(dbmessages(i,1))); % directly convert to hex from decimal
        else % if 29 extended bit CAN frame
            % subtract 8000 0000 (hex) from the message id to get the correct
            % hexadecimal message id and append the letter x
            dbmessages(i,5) = strcat(dec2hex(str2double(dbmessages(i,1))-2147483648),'x');
        end
    end
    % [messageRow,~]=find(CANSystemWB(:,1) == "BO_"); % find the message row numbers
    % [endRow,~]=find(CANSystemWB(:,2) ~= "SG_"); % find the non signal row numbers
    [messageRow,~]=find(dbc(j).file(:,1) == "BO_"); % find the message row numbers
    [endRow,~]=find(dbc(j).file(:,2) ~= "SG_"); % find the non signal row numbers
    endRow=endRow(endRow>messageRow(end,1)); % find the rows after the last signal
    messageRow(end+1,1)=endRow(1,1)+1; % add the end row of the test data to the
    for i = 1:numel(dbmessages(:,1))
    %     a = CANSystemWB(messageRow(i)+1:messageRow(i+1)-2,3);
    %     a = CANSystemWB(messageRow(i)+1:messageRow(i+1)-2,[3,6:15]);
        a = dbc(j).file(messageRow(i)+1:messageRow(i+1)-2,[3,6:15]);
    %     a = strtok(a,['(',')','[',']']);
    %     a = extract(a(:,5:8),digitsPattern);
        a = erase(a(:,:),["(",")","[","]"]);
    %     candb=setfield(candb,'messages',messages(i,2),'signals',a(:,:));
        candb=setfield(candb,'messages',dbmessages(i,2),'ID',dec2hex(str2double(dbmessages(i,1))-2147483648));
        candb=setfield(candb,'messages',dbmessages(i,2),'DLC',str2double(dbmessages(i,3)));
        candb=setfield(candb,'messages',dbmessages(i,2),'transmitter',dbmessages(i,4));
        % Create a signal structure containing the signal details
        for k = 1:numel(a(:,1))
            % might need to remove string to double at end of signal field and
            % leave as a string. See how it is used to process data
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'startBit',str2double(a(k,2)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'length',str2double(a(k,3)));

            signPat = characterListPattern("+-");
            bytePat = digitsPattern;
            if extract(a(k,4),signPat)=="+"
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'valueType','Signed');
            else
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'valueType','Unsigned');
            end
            if extract(a(k,4),bytePat) == "1"
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'byteOrder','Intel');
            else
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'valueType','Motorola');
            end
    %         candb=setfield(candb,'messages',messages(i,2),'signals',a(k,1),'type',a(k,4));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'scale',str2double(a(k,5)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'offset',str2double(a(k,6)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'min',str2double(a(k,7)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'max',str2double(a(k,8)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'unit',a(k,9));
    %         candb=setfield(candb,'messages',messages(i,2),'signals',a(k,1),'unknownVectorxx',str2double(a(k,10)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(k,1),'receiver',a(k,11));
        end
    end
end
clear a i j k endRow messageRow signPat bytePat
%% Notes on message breakdown
% A standard CAN frame with a 3 digit identifier (hex) is a standard CAN
% frame with an 11-bit identifier. The maximum size is 111 1111 1111 bin,
% 7FF hex or 2047 dec
% 
% 
% An extended CAN frame with more than 3 digits is more complecated. In the
% dbc file the identifier is recorded in decimal. However when this is
% converted to hex we need to subtract 8000 0000 (hex) or 2,147,483,648
% (dec) from it. This appears to be due to the 29-bit identifier being
% represented by a 32-bit binary. The first 3 bits (32,31,30) are always
% 100(bin) and should be ignored. 
% The next 3 bits (bits 29,28,27) are the message priorty:
% 
% Priority 0 = 00 hex = 0 00 bin (or not shown)
% Priority 1 = 04 hex = 0 01 bin
% Priority 2 = 08 hex = 0 10 bin
% Priority 3 = 0C hex = 0 11 bin 
% Priority 4 = 1C hex = 1 00 bin
% Priority 5 = 14 hex = 1 01 bin 
% Priority 6 = 18 hex = 1 10 bin
% Priority 7 = 1C hex = 1 11 bin
% Priority 0 being the highest priority and 7 the lowest
%
% Note: The 32 bits here don't appear to line up with the 32 bits shown on
% CAN frames images online
% 
% The next 18-bits (bits 26-9) are the PGN i.e. FD22
% The last 8-bits (bits 8-1) are the Source address i.e FE
% 


