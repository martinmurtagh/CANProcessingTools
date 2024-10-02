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
    dbmessages(j) = dbc(j).file(dbc.file(:,1) == "BO_",[2,3,5,6]);
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
        for j = 1:numel(a(:,1))
            % might need to remove string to double at end of signal field and
            % leave as a string. See how it is used to process data
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'startBit',str2double(a(j,2)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'length',str2double(a(j,3)));

            signPat = characterListPattern("+-");
            bytePat = digitsPattern;
            if extract(a(j,4),signPat)=="+"
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'valueType','Signed');
            else
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'valueType','Unsigned');
            end
            if extract(a(j,4),bytePat) == "1"
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'byteOrder','Intel');
            else
                candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'valueType','Motorola');
            end
    %         candb=setfield(candb,'messages',messages(i,2),'signals',a(j,1),'type',a(j,4));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'scale',str2double(a(j,5)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'offset',str2double(a(j,6)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'min',str2double(a(j,7)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'max',str2double(a(j,8)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'unit',a(j,9));
    %         candb=setfield(candb,'messages',messages(i,2),'signals',a(j,1),'unknownVectorxx',str2double(a(j,10)));
            candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'receiver',a(j,11));
        end
    end
end
clear a i j endRow messageRow signPat bytePat
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
%% Import ASCII data from CANalyser tests
% load(fileName,'-ascii');
% or 
% S=load(filename,'-ascii');
% or
% filename = 'myfile01.txt';
% delimiterIn = ' ';
% headerlinesIn = 1;
% A = importdata(filename,delimiterIn,headerlinesIn);

%% decode messages
% find all the unique messages
% create the message and signals using names from db
% extract and decode data for each signal

%% Loading the measured test data for processing
fileName = 'C:\Users\martin.murtagh\Documents\Testing\AT399_ARMD_FCEV_SD\20211116_allDayDriving\ARMD_2021-11-16_08-13-55.asc';
startRow = 8;
endRow = 2000000; %3571998;
formatSpec = '%17s%2s%14s%4s%5s%3s%s%[^\n\r]';
% Open the text file.
fileID = fopen(fileName,'r');
% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error occurs for a different file, try regenerating the code from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines', startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
% Remove white space around all cell columns.
dataArray{1} = strtrim(dataArray{1});
dataArray{2} = strtrim(dataArray{2});
dataArray{3} = strtrim(dataArray{3});
dataArray{4} = strtrim(dataArray{4});
dataArray{5} = strtrim(dataArray{5});
dataArray{6} = strtrim(dataArray{6});
dataArray{7} = strtrim(dataArray{7});
% Close the text file.
fclose(fileID);
% Create output variable
data = [dataArray{1:end-1}];
% Remove Error Frames
data = data((data(:,3)~="ErrorFrame"),:); 
% Clear temporary variables
clearvars startRow endRow formatSpec fileID ans dataArray;
%% convert hex data to binary
% dlc = 8;
% x='FF 7D 00 00 FF FF FF 7D';
% y = x(~isspace(x));
% z=dec2bin(hex2dec(y));
% z1=dec2bin(hex2dec([y(1,1:2);y(1,3:4);y(1,5:6);y(1,7:8);y(1,9:10);y(1,11:12);y(1,13:14);y(1,15:16)]));
% z3=reshape(z1,1,[]);
% data1=split(data(:,7),' ',2);
% data2=split(data(:,7),' ',1);
% y2 = dec2bin(hex2dec(data1(1,:)));
% y2 = string(dec2bin(hex2dec(data1)));
% y222 = reshape(y2,[numel(y2)/8,8]);
% y222 = join(y222,'');
% data(:,8:15) = y222;
for i = 1:numel(data(:,1))
    x1=split(data(i,7),' ',2);
    x2=string(dec2bin(hex2dec(x1)));
    x3 = pad(x2,8,'left','0');
%     x4 = join(x3,'');
%     data(i,8:7+str2num(data(i,6))) =  reshape(x3,1,[]);
    data(i,8) = join(x3,''); % data joined into one 64 bit string
end
clear i x1 x2 x3 x4
% this won't work. need to take into consideration Error frames and DLC
% shorter than 8 bytes. nee to use a for loop to remove error frames and
% account for DLC. Not sure if I should join the 64 bit binary string or
% leave seperate. Need to work out how reverse reading of hex (intel type)
% is implemented in the binary layer.


% startBit = 0;
% length = 8;
% scale = 0.125;
% offset = 0;
% 
% sig = bin2dec(y3(startBit+1:startBit+length))*scale+offset;
%%
% find all unique messages in the data stream
% uniqueMessages = unique(data.MessageID);
uniqueMessages = unique(data(:,3));
% for i=1:numel(uniqueMessages)
% %     a=dataArray{1,1}(uniqueMessages(i)==dataArray{:,3});
% %     a = data((categorical(data(:,3))==uniqueMessages(i)),1);
%     if isempty(messages{(categorical(messages(:,5))==uniqueMessages(i)),2})
% %     if isempty(messages{(messages(:,5)==uniqueMessages(i)),2})
%     else
%     candb=setfield(candb,'messages',messages{(messages(:,5)==uniqueMessages(i)),2},'timeStamp',dataArray{1,1}(uniqueMessages(i)==dataArray{:,3}));
%     end
% end
for i=1:numel(uniqueMessages)
%     a=dataArray{1,1}(uniqueMessages(i)==dataArray{:,3});
%     a = data((data(:,3)==uniqueMessages(i)),1);
%     if isempty(messages{(categorical(messages(:,5))==uniqueMessages(i)),2})
    if isempty(dbmessages(dbmessages(:,5)==uniqueMessages(i)))
    else
        candb=setfield(candb(1),'messages',dbmessages{(dbmessages(:,5)==uniqueMessages(i)),2},'timeStamp',data(uniqueMessages(i)==data(:,3),1));   
%         candb=setfield(candb,'messages',dbmessages{(dbmessages(:,5)==uniqueMessages(i)),2},'timeStamp',dataArray{1,1}(uniqueMessages(i)==dataArray{:,3}));
    end
end
% clear i 
%% reading data
% for all the data messages for each incrementing unique message, and for
% all the signals in that message, get the startbit, length,  scale and
% offset, calculate the signal value
% for i = 1:numel(fieldnames(candb.messages))
%     a=fieldnames(candb.messages); % get the list of message names
%     b = a{i}; % get the individual message name
for i = 1:numel(uniqueMessages)
    b = uniqueMessages{i};
%     if isempty(data(messageIDhex==data(:,3),8))
    if ismember(uniqueMessages{i},dbmessages(:,5))
        % if the message is withing the know message database, get the
        % message ID name and the hex ID name
        messageID = dbmessages(dbmessages(:,5)==uniqueMessages{i},2);
        messageIDhex = dbmessages(dbmessages(:,5)==uniqueMessages{i},5); % get the message's hex ID
        % get all the binary data for all the times the message is broadcast
%         messagedata = data(data(:,3)==messageIDhex,8);
        messagedata = data(data(:,3)==uniqueMessages{i},8);
        % get the timestamp data
        timedata = str2double(data(data(:,3)==messageIDhex,1)); 
        % for each signal in the CAN database, get the signal details and
        % the binary information from the data file and apply the correct
        % scale and offsets
        for j = 1:numel(fieldnames(candb.messages.(messageID).signals))
            c=fieldnames(candb.messages.(messageID).signals); % get the list of signal names
            d = c{j}; % get the individual signal name
            startBit = candb.messages.(messageID).signals.(d).startBit;
            length = candb.messages.(messageID).signals.(d).length;
            scale = candb.messages.(messageID).signals.(d).scale;
            offset = candb.messages.(messageID).signals.(d).offset;
    %         data( ,8)
            sig = bin2dec(extractBetween(messagedata,startBit+1,startBit+length))*scale+offset;
            % save the processed signal data to the CAN database structure
            candb=setfield(candb,'messages',(messageID),'signals',(d),'data',sig);
            candb=setfield(candb,'messages',(messageID),'signals',(d),'time',timedata);
        end
    else    
    end
end
clear a b c d i j length messagedata messageIDhex offset scale sig startBit timedata
% toc
% sig = bin2dec(y3(startBit+1:startBit+length))*scale+offset;
% candb=setfield(candb,'messages',messages(i,2),'signals',a(j,1),'data','put processed signal data here');
%% Plotting tool
% have a list of messages and signal that is easy to search/click a signal
% or multiple signals to plot. Plot discrete data for each signal.

subplot(2,1,1)
x=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.time;
y=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.data;
plot(x,y)

subplot(2,1,2)
x=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.time;
y=candb.messages.(messageID).signals.Signal_BSC_Actual_State_02.data;
plot(x,y)
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