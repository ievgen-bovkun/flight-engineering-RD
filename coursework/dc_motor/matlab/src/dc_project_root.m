function root=dc_project_root()
%DC_PROJECT_ROOT Resolve project paths independently of current directory.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
