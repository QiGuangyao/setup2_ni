function build_ni(do_build)

%   BUILD_NI -- Build script for `ni_mex` interface.
%
%     This function is used to build the mex function `ni_mex` from source.
% 
%     This function, when built on Windows, depends on the National 
%     Instruments SDK, which can be downloaded from their website. This SDK 
%     is expected to be located in 
%     C:\Program Files (x86)\National Instruments on PC.
%
%     build_ni() attempts to build the interface from source.
%     build_ni( false ) prints the mex command that would normally be
%     evaluated to build the interface.
%
%     For platforms other than Windows, a dummy interface will be built.
%
%     See also NIInterface

dummy_ni = ~ispc();

if ( nargin < 1 )
  do_build = true;
end

repo_p = fileparts( fileparts(which('build_ni')) );

src_dir = dir( fullfile(repo_p, 'src') );
src_dir = fullfile( {src_dir.folder}, {src_dir.name} );
src_ps = src_dir(endsWith(src_dir, '.cpp'));
mex_p = fullfile( repo_p, 'mex', 'ni_mex.cpp' );

out_dir = fullfile( repo_p, 'mex' );

ni_dir = 'C:\Program Files (x86)\National Instruments\Shared\ExternalCompilerSupport\C';

include_dirs = {...
  fullfile(ni_dir, 'include') ...
  fullfile(repo_p, 'src') ...
};

lib_dirs = {...
  fullfile(ni_dir, 'lib64/msvc') ...
};

lib_names = {...
  'NIDAQmx' ...
};

addtl_defines = {};
if ( dummy_ni )
  keep_srcs = { 'task_interface_dummy', 'ni_mex' };
  has_src = cellfun( @(x) contains(src_ps, x), keep_srcs, 'un', 0 );
  has_src = or_many( has_src{:} );
  
  include_dirs(1) = [];
  lib_dirs(1) = [];
  lib_names(1) = [];
  addtl_defines{end+1} = 'DUMMY_NI';
  src_ps = src_ps(has_src);
else
  rm_src = contains( src_ps, 'task_interface_dummy.cpp' );
  src_ps(rm_src) = [];
end

src_ps = [ mex_p, src_ps ];

optim_level = 3;
optim_flags = '-DNDEBUG';

if ( ispc() )
  addtl_cxx_flags = '';
  comp_flags = 'COMPFLAGS="$COMPFLAGS /std:c++17"';
else
  addtl_cxx_flags = 'CXXFLAGS="-std=c++17"';
  comp_flags = '';
end

build_cmd = sprintf( ...
    '-v %s %s %s COPTIMFLAGS="-O%d %s" CXXOPTIMFLAGS="-O%d %s" %s %s %s %s -outdir "%s"' ...
  , comp_flags ...
  , addtl_cxx_flags ...
  , strjoin(cellfun(@(x) sprintf('-D%s', x), addtl_defines, 'un', 0), ' ') ...
  , optim_level, optim_flags, optim_level, optim_flags ...
  , strjoin(cellfun(@(x) sprintf('"%s"', x), src_ps, 'un', 0), ' ') ...
  , strjoin(cellfun(@(x) sprintf('-I"%s"', x), include_dirs, 'un', 0), ' ') ...
  , strjoin(cellfun(@(x) sprintf('-L"%s"', x), lib_dirs, 'un', 0), ' ') ...
  , strjoin(cellfun(@(x) sprintf('-l%s', x), lib_names, 'un', 0), ' ') ...
  , out_dir ...
);

if ( do_build )
  eval( sprintf('mex %s', build_cmd) );
else
  fprintf( '\n\n\n%s\n\n\n', build_cmd );
end

end