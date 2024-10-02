%% Decoding an ascii CAN trace
%% Import Database file
disp ("Start!")

[file,path] = uigetfile('*.dbc','Select One or More DBC Files','MultiSelect', 'on');

if path == 0
    disp('Simulation Cancelled')
    return
end

file=string(file);

[~,name] = fileparts(file);

FullpathCAN = strcat(path,file);

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

%% Read in the dbc data
% for each dbc file read in its name, its path and the file contents to the structure dbc

dbc = struct();

for i = 1:numel(file)

    dbc(i).file = readmatrix(fullfile(path,file{i}), opts);
    dbc(i).name = file{1,i};
    dbc(i).path = path;

end

% CANSystemWB = readmatrix(FullpathCAN, opts);

candb = struct();

dbmessages = strings(0,4);

for i = 1:numel(dbc)
    a = dbc(1).file(dbc(1).file(:,1) == "BO_",[2,3,5,6]);
    dbmessages=[dbmessages;dbc(i).file(dbc(i).file(:,1) == "BO_",[2,3,5,6])];
end

%%
% dbmessages = CANSystemWB(CANSystemWB(:,1) == "BO_",[2,3,5,6]);
% dbmessages = dbc.file(dbc.file(:,1) == "BO_",[2,3,5,6]);

for j=1:length(dbc)

    for i=1:length(dbmessages(:,1))
        if str2double(dbmessages(i,1))<hex2dec('7FF') % if message is 11 bit 
            dbmessages(i,5) = dec2hex(str2double(dbmessages(i,1))); % directly convert to hex from decimal
        else % if 29 extended bit CAN frame
            dbmessages(i,5) = strcat(dec2hex(str2double(dbmessages(i,1))-2147483648),'x');
        end
    end
%

[messageRow,~]=find(dbc(j).file(:,1) == "BO_");
[endRow,~]=find(dbc(j).file(:,2) ~= "SG_");
endRow=endRow(endRow>messageRow(end,1));
messageRow(end+1,1)=endRow(1,1)+1;

%%
for i = 1:numel(dbmessages(:,1))
    
        a = dbc(j).file(messageRow(i)+1:messageRow(i+1)-2,[3,6:15]);
        a = erase(a(:,:),["(",")","[","]"]);

        
        candb=setfield(candb,'messages',dbmessages(i,2),'ID',dec2hex(str2double(dbmessages(i,1))-2147483648));
        candb=setfield(candb,'messages',dbmessages(i,2),'DLC',str2double(dbmessages(i,3)));
        candb=setfield(candb,'messages',dbmessages(i,2),'transmitter',dbmessages(i,4));
        

        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'startBit',str2double(a(j,2)));
        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'length',str2double(a(j,3)));
        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'factor',str2double(a(j,5)));
        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'offset',str2double(a(j,6)));
        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'minimum',str2double(a(j,7)));
        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'maximum',str2double(a(j,8)));
        candb=setfield(candb,'messages',dbmessages(i,2),'signals',a(j,1),'unit',(a(j,9)));




end
end





disp ("Done!")