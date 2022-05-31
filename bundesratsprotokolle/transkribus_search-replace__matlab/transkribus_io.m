% TRANSKRIBUS_IO Showcase Transkribus RESTful IO.
%
% -------------
% PURPOSE
% -------------
% This file showcases how to read from and write to Transkribus via 
% the REST interface using Matlab.
%
% -------------
% DOCUMENTATION
% -------------
% Transkribus REST Interface
%   https://transkribus.eu/TrpServer/Swadl/wadl.html
% Matlab documentation
%   https://ch.mathworks.com/help/matlab/ref/webwrite.html
% Interfacing with Transkribus using Python
%   https://dhlab.hypotheses.org/2114
%
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/
% 2021.10.05


% This is the URL of the Transkribus API.
api = 'https://transkribus.eu/TrpServer/rest/';


% ---
% Login
% ---
% You must have access to a user account to connect to Trankribus.
url = [api,'auth/login'];
login = webwrite(url,...
    'user','userid',...
    'pw','password');

disp(login)
%             type: 'trpUserLogin'
%           userId: 98131
%         userName: 'atanasiu@alum.mit.edu'
%            email: 'atanasiu@alum.mit.edu'
%      affiliation: 'None'
%        firstname: 'Vlad'
%         lastname: 'Atanasiu'
%           gender: 'unknown'
%     userRoleList: {'User'}
%         isActive: 1
%          isAdmin: 0
%          created: '2021-09-07T10:37:06.794+02:00'
%        loginTime: '2021-10-05T19:03:31.683+02:00'
%        sessionId: '800CEDEA713697B11443553D7BA3CC34'
%        userAgent: 'MATLAB 9.9.0.1570001 (R2020b) Update 4'
%               ip: '134.21.43.166'

% NOTE: At each transaction we need to identify ourselved by sending the 
% object JSESSIONID with the prarameter login.sessionId obtained at login.

% Common HTTP error codes:
% 401 Unauthorized
% 403 Forbidden
% 405 Method Not Allowed
% 500 Internal Server Error (This error is usually returned by the server 
%   when no other error code is suitable. For Transkribus this error may 
%   be issued for malformed XML content, such as missing tags.)


% ---
% Check session details
% ---
url = [api,'auth/details'];
response = webread(url,'JSESSIONID',login.sessionId);
disp(response)
%             type: 'trpUserLogin'
%           userId: 98131
%         userName: 'atanasiu@alum.mit.edu'
%            email: 'atanasiu@alum.mit.edu'
%      affiliation: 'None'
%        firstname: 'Vlad'
%         lastname: 'Atanasiu'
%           gender: 'unknown'
%     userRoleList: {'User'}
%         isActive: 1
%          isAdmin: 0
%          created: '2021-09-07T10:37:06.794+02:00'
%        loginTime: '2021-10-05T19:03:31.683+02:00'
%        sessionId: '800CEDEA713697B11443553D7BA3CC34'
%        userAgent: 'MATLAB 9.9.0.1570001 (R2020b) Update 4'
%               ip: '134.21.43.166'
              

% ---
% Logout
% ---
url = [api,'auth/logout'];
response = webwrite(url,'JSESSIONID',login.sessionId);
disp(response)


% ---
% Read the list of available collections
% ---
url = [api,'collections/list'];
response = webread(url,'JSESSIONID',login.sessionId);
colId = response{1,1}.colId;
disp(response{1,1});
%                 type: 'trpCollection'
%                colId: 74823
%              colName: 'BAR_Bundesratsprotokolle'
%          description: 'Publication collection.'
%        crowdsourcing: 0
%            elearning: 0
%        nrOfDocuments: 214
%                 role: 'Owner'
%     accountingStatus: 1


% ---
% Get the metadata of a specific document
% ---
docId = '514186';
url = [api,'collections/',num2str(colId),'/',docId,'/fulldoc'];
doc = webread(url,'JSESSIONID',login.sessionId);
disp(doc)
%             md: [1×1 struct]
%       pageList: [1×1 struct]
%     collection: [1×1 struct]
%     edDeclList: []
disp(doc.collection)
%                colId: 74823
%              colName: 'BAR_Bundesratsprotokolle'
%          description: 'Publication collection.'
%        crowdsourcing: 0
%            elearning: 0
%        nrOfDocuments: 0
%     accountingStatus: 1
disp(doc.pageList.pages)
%   734×1 struct array with fields:
%     pageId
%     docId
%     pageNr
%     key
%     imageId
%     url
%     thumbUrl
%     imgFileName
%     tsList
%     width
%     height
%     created
%     indexed
%     imageVersions
%     tagsStored
disp(doc.pageList.pages(1).pageId)
%   21777117
disp(doc.pageList.pages(1).docId)
%       514186
disp(doc.pageList.pages(1).pageNr)
%      1
disp(doc.pageList.pages(1).key)
% KBCKANNOZKGIPFYOZWGFZSZX
disp(doc.pageList.pages(1).imageId)
%     16891068
disp(doc.pageList.pages(1).url)
% https://files.transkribus.eu/Get?id=KBCKANNOZKGIPFYOZWGFZSZX&fileType=view
disp(doc.pageList.pages(1).thumbUrl)
% https://files.transkribus.eu/Get?id=KBCKANNOZKGIPFYOZWGFZSZX&fileType=thumb
disp(doc.pageList.pages(1).imgFileName)
% 70006139_70006139-0.jpg


% ---
% Download one document page
% ---
docId = doc.pageList.pages(1).docId;
pageNr = doc.pageList.pages(1).tsList.transcripts{1}.pageNr;
url = doc.pageList.pages(1).tsList.transcripts{1}.url;
filename = ['transkribus',...
    '_col',num2str(colId),...
    '_doc',num2str(docId),...
    '_page',num2str(pageNr),'.xml'];
% Save the file in the Matlab root folder.
outfilename = websave(filename,url);
% View the file content.
web(outfilename)


% ---
% Upload one document page
% ---
data = fileread(filename);
url = [api,'collections/',num2str(colId),'/',...
    num2str(docId),'/',num2str(pageNr),'/text'];

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

response = webwrite(url, data, opt);

% % Variant: specify status, parent, overwrite.
% % - can be send with name-value syntax, but then we can't send data;
% % - can't be send with "data, opt" syntax, but then data can be send;
% %   but it seems ok to do so.
% params = struct(...
%     'JSESSIONID',login.sessionId,...
%     'status',pageStatus,...
%     'parent',tsId,...
%     'overwrite','false'...
%     );
% write_status = webwrite(url,text_page_content,params);


