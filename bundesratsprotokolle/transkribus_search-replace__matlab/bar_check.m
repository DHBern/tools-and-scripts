% BAR_CHECK Identify files containing specific text patterns.
%
% -------------
% PURPOSE
% -------------
% We use this program to detect errors:
% - Tags without opening bracket, with only closing bracket: 
%   E.g.: <xmltag>Content from here to here.xmltag>
%
% -------------
% CAVEAT
% -------------
% You need to define the regex patterns really smart, otherwise
% the process becomes impractically slow. E.g., compare:
% 1st pattern: 20 sec / 1 file > 34 days / 150.000 files
% 2st pattern: 25 min / 15.000 files > 2h45 / 150.000 files
%
% -------------
% DOCUMENTATION
% -------------
% Matlab REGEX documentation
%   https://ch.mathworks.com/help/matlab/ref/regexp.html
% Developing, debugging, & visualizing regexs online
%   https://regex101.com/
% Regex Tutorial & software
%   https://www.regular-expressions.info/
%
% -------------
% EXAMPLE
% -------------
% data = ['<TextRegion orientation="0.0" id="rfJp3_2" custom="readingOrder {index:0;} structure {type:heading;}">',...
%         '<Coords points="826,189 3133,189 3133,630 826,630"/>',...
%         '<Unicode>Eins</Unicode>',...
%         '<Unicode>Zwei</Unicode>',...
%         '<Unicode>weniger als 4 Kilometer von der französ. Gränz(...)/Unicode>',...
%         '</TextRegion>'];
% pat = '<(\w.*)[^<]*?\1>';
% match = regexp(data,pat,'match');
% disp(match)
%
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/
% 2021.10.05


% make file list
% MAC
% root = 'nlp/bar/data/';
% root = '/Volumes/NB74/bar/test/';
% root = '/Volumes/NB74/bar/erroneous/';
root = '/Volumes/NB74/bar/export_job_2126377/';
% PC
% root = 'E:\bar\test\';

flist = dir([root,'**',filesep,'*.xml']);
nlist = length(flist);

% delete any preexisting error log files
logUnreadable = [root,'log unreadable files.txt'];
status = isfile(logUnreadable);
if status == true
    delete(logUnreadable)
end

logErroneousFiles = [root,'log erroneous files.txt'];
status = isfile(logErroneousFiles);
if status == true
    delete(logErroneousFiles)
end

logErroneousContent = [root,'log erroneous content.txt'];
status = isfile(logErroneousContent);
if status == true
    delete(logErroneousContent)
end


% -----------------
% define regex search patterns
% -----------------
% Search for tags without opening bracket, only closing bracket.
% E.g.: <xmltag>Content from here to here.xmltag>
pat1 = '>[^<]*?>';


% measure processing duration
t0 = tic;
disp(root)
disp(datetime(now,'ConvertFrom','datenum'))

% loop files
% If you wish to restart the loop after an interruption, update the next
% three variables with the values at the interruption time.
startList = 1;
fileUnreadableNr = 0;
fileErroneousNr = 0;

progressIter = 0;
progressStep = floor((nlist-startList)/10);
if progressStep < 1
    progressStep = 1;
end

for klist = startList:nlist
    
    % skip non-transcription files
    if strcmp(flist(klist).name,'metadata.xml') || ...
            strcmp(flist(klist).name,'mets.xml')
        continue
    end
    
    % read file
    fname = flist(klist).name;
    fpath = [flist(klist).folder,filesep,fname];
    try
        txt = fileread(fpath);
    catch
        fileUnreadableNr = fileUnreadableNr + 1;
        
        % log unreadable file name
        fid = fopen(logUnreadable,'a','n','UTF-8');
        fwrite(fid, [fpath,newline]);
        fclose(fid);
        
        continue
    end
 
    % -----------------
    % search for patterns
    % -----------------
    match = regexp(txt,pat1,'match');

    % log results
    if ~isempty(match)
        % log erroneous file name
        fid = fopen(logErroneousFiles,'a','n','UTF-8');
        fwrite(fid, [fpath,newline]);
        fclose(fid);

        nMatch = length(match);
        for kMatch = 1:nMatch
            
            % log erroneous content
            fid = fopen(logErroneousContent,'a','n','UTF-8');
            data = [match{kMatch},newline];
            encodedText = unicode2native(data, 'UTF-8');
            fwrite(fid, encodedText);
            fclose(fid);
            
        end

        fileErroneousNr = fileErroneousNr + 1;
    end
    
    % display progress
    if mod(klist,progressStep) == 1
        fprintf(num2str(progressIter))
        progressIter = progressIter + 1;
    end
    
end
fprintf('0\n')

% display results
disp(['Total files checked: ',num2str(nlist)])
disp(['Files unreadable: ',num2str(fileUnreadableNr)])
disp(['Files w/ errors: ',num2str(fileErroneousNr)])

% display processing duration
disp(datetime(now,'ConvertFrom','datenum'))
dt = toc(t0);
dt = datestr(seconds(dt),'HH:MM:SS');
dt = datevec(dt);
dt = [...
    num2str(dt(4)),'h ',...
    num2str(dt(5)),'m ',...
    num2str(dt(6)),'s'];
del = '';
if dt(6) == 0
    dt = ['less than ',dt];
end
msg = ['Processing duration was ',dt,'.'];
disp(msg)



