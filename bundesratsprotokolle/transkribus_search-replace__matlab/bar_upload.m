% BAR_UPLOAD Uploads XML files to Transkribus via the REST API.
%
% -------------
% DOCUMENTATION
% -------------
% See for a showcase of the whole process: TRANSKRIBUS_IO.
%
% Transkribus REST Interface
%   https://transkribus.eu/TrpServer/Swadl/wadl.html
% Matlab documentation
%   https://ch.mathworks.com/help/matlab/ref/webwrite.html
% Interfacing with Transkribus using Python
%   https://dhlab.hypotheses.org/2114
%
% -------------
% PERFORMANCE
% -------------
% Expected processing duration (MacBook Pro 2019, 8 cores, 16 GB RAM):
% 4.000 files / 1h > 150.000 files / 40 h
%
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/
% 2021.10.05


% initialisation
api = 'https://transkribus.eu/TrpServer/rest/';
% specify the collection ID (see transkribus_io for how to find it out)
colId = 74823;

% login
url = [api,'auth/login'];
login = webwrite(url,...
    'user','userid',...
    'pw','password');

% NOTE: At each transaction we need to identify ourselved by sending the 
% object JSESSIONID with the prarameter login.sessionId obtained at login.

% http error codes
% 401 Unauthorized
% 403 Forbidden
% 405 Method Not Allowed
% 500 Internal Server Error

% RESTful web service parameters
opt = weboptions;
opt.HeaderFields = {'Content-Type','application/xml'};
opt.ContentType = 'text';
opt.MediaType = 'auto';
%opt.MediaType = 'application/xml';
%opt.MediaType = 'application/x-www-form-urlencoded';
opt.KeyName = 'cookie';
opt.KeyValue = ['JSESSIONID=',login.sessionId];
opt.CharacterEncoding = 'UTF-8';
opt.RequestMethod = 'post';
opt.ArrayFormat = 'csv';
opt.Username = '';
opt.Password = '';


% make file list
% MAC
% root = 'nlp/bar/data/';
% flist = dir([root,'**/*.xml']);
% root = '/Volumes/NB74/bar/test/';
root = '/Volumes/NB74/bar/export_job_2126377/';
% PC
% root = 'E:\bar\test\';

flist = dir([root,'**',filesep,'*.xml']);
nlist = length(flist);


% delete any preexisting error log files
logRoot = '/Volumes/NB74/bar/unuploadable/'; % MAC
% logRoot = 'E:\bar\unuploadable\'; % PC

status = isfolder(logRoot);
if status == true
    status = rmdir(logRoot);
else
    status = mkdir(logRoot);
end

logUnreadable = [logRoot,'log unreadable files.txt'];
status = isfile(logUnreadable);
if status == true
    delete(logUnreadable)
end

logErroneousFiles = [logRoot,'log erroneous files.txt'];
status = isfile(logErroneousFiles);
if status == true
    delete(logErroneousFiles)
end


% upload files
% measure processing duration
t0 = tic;
disp(root)
disp(datetime(now,'ConvertFrom','datenum'))

% loop files
% If you wish to restart the loop after an interruption, update the next
% three variables with the values at the interruption time.
startList = 1;
fileUnreadableNr = 0;
fileUnuploadableNr = 0;

progressIter = 0;
progressStep = floor((nlist-startList)/10);
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
    
    % upload file
    pathElements = split(fname,'_');
    docId = pathElements{1};
    pageNr = pathElements{2};
    % this is an URL, so the filesep is forwardslash '/'
    url = [api,'collections/',num2str(colId),'/',...
        num2str(docId),'/',num2str(pageNr),'/text'];
    try
        response = webwrite(url, txt, opt);
    catch
        fileUnuploadableNr = fileUnuploadableNr + 1;
        
        % log erroneous file name
        fid = fopen(logErroneousFiles,'a','n','UTF-8');
        fwrite(fid, [fpath,newline]);
        fclose(fid);
        
        % copy unuploadable file to a holding folder
        copyfile(fpath,logRoot)

        continue
    end

    % display progress
    if mod(klist,progressStep) == 1
        fprintf(num2str(progressIter))
        progressIter = progressIter + 1;
    end
    
end
fprintf('0\n')

% logout
% url = [api,'auth/logout'];
% response = webwrite(url,'JSESSIONID',login.sessionId);

% display results
disp(['Total files to upload: ',num2str(nlist)])
disp(['Files unreadable: ',num2str(fileUnreadableNr)])
disp(['Files unuploadable: ',num2str(fileUnuploadableNr)])

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


