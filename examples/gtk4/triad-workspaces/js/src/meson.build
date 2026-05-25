pkgdatadir = get_option('prefix') / get_option('datadir') / meson.project_name()
bindir = get_option('prefix') / get_option('bindir')
sass = find_program('sass', required: true)
esbuild = find_program('esbuild', required: true)
gjs = find_program('gjs', required: true)
layer_shell = dependency('gtk4-layer-shell-0')

js = custom_target(
  'typescript',
  input: files('App.ts'),
  command: [
    esbuild,
    '--bundle', '@INPUT@',
    '--format=esm',
    '--outfile=@OUTPUT@',
    '--sourcemap=inline',
    '--external:gi://*',
    '--external:gettext',
    '--external:system',
  ],
  output: 'index.js',
)

css = custom_target(
  'scss',
  input: files('style.scss'),
  command: [sass, '@INPUT@', '@OUTPUT@'],
  output: 'style.css',
)

import('gnome').compile_resources(
  'data',
  files('gresource.xml'),
  dependencies: [css, js],
  gresource_bundle: true,
  install: true,
  install_dir: pkgdatadir,
)

configure_file(
  input: files('main.in.js'),
  output: 'main.js',
  configuration: {
    'GJS': gjs.full_path(),
    'PKGDATADIR': pkgdatadir,
  },
  install: true,
  install_dir: pkgdatadir,
)

configure_file(
  input: 'main.in.sh',
  output: meson.project_name(),
  configuration: {
    'LAYER_SHELL_PREFIX': layer_shell.get_variable('prefix'),
    'INDEX': pkgdatadir / 'main.js',
  },
  install: true,
  install_dir: bindir,
)
