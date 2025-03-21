function importCANTrace()
%% Loading the measured test data for processing
%% Import Database file
% Import one or more dbc file for decoding the ascii log file
% db = [];
% hexStr = dec2hex(2566909940);
% tic
[file,path] = uigetfile('*.txt','Select a CAN trace','MultiSelect', 'off');
if path == 0
    disp('Simulation Cancelled')
   return
end
file=string(file);
[~,~] = fileparts(file);
%%
% fileName = 'C:\Users\martin.murtagh\Documents\Testing\AT399_ARMD_FCEV_SD\20211116_allDayDriving\ARMD_2021-11-16_08-13-55.asc';
% startRow = 8; % for .asc
startRow = 15; % for .trc
endRow = 2000000; %3571998;
% formatSpec = '%17s%2s%14s%4s%5s%3s%s%[^\n\r]'; % for .asc
formatSpec = '%7s%12s%4s%13s%3s%25s%s%[^\n\r]';
% Open the text file.
% fileID = fopen(fileName,'r');
fileID = fopen(fullfile(path,file),'r');
% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error occurs for a different file, try regenerating the code from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines', startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
% Remove white space around all cell columns.
for idx = 1:numel(dataArray)
        dataArray{idx} = strtrim(dataArray{idx});
end
% dataArray{1} = strtrim(dataArray{1});
% dataArray{2} = strtrim(dataArray{2});
% dataArray{3} = strtrim(dataArray{3});
% dataArray{4} = strtrim(dataArray{4});
% dataArray{5} = strtrim(dataArray{5});
% dataArray{6} = strtrim(dataArray{6});
% dataArray{7} = strtrim(dataArray{7});
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
end