function [Z,Time,Mnem] = readData(datafile)
%readData Read data from Microsoft Excel workbook file

[DATA,TEXT] = xlsread(datafile,'data');
Mnem = TEXT(1,:);
if ispc
    Time = datenum(TEXT(2:end,1),'mm/dd/yyyy');
    Z    = DATA;
else
    Time = DATA(:,1) + datenum(1899,12,31) - 1;
    Z    = DATA(:,2:end);
end

end
