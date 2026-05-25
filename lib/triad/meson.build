project(
  'astal-triad',
  'vala',
  'c',
  version: run_command('cat', join_paths(meson.project_source_root(), 'version')).stdout().strip(),
  meson_version: '>= 0.62.0',
  default_options: [
    'warning_level=2',
    'werror=false',
    'c_std=gnu11',
  ],
)

assert(
  get_option('lib'),
  'The lib option must be set to true.',
)

version = meson.project_version()
name = meson.project_name()
version_split = version.split('.')
api_version = '0.1'
gir_name = 'AstalTriad-0.1.gir'
typelib_name = 'AstalTriad-0.1.typelib'

config = configure_file(
  input: 'src/config.vala.in',
  output: 'config.vala',
  configuration: {
    'API_VERSION': api_version,
    'VERSION': version,
    'MAJOR_VERSION': version_split[0],
    'MINOR_VERSION': version_split[1],
    'MICRO_VERSION': version_split[2],
  },
)

deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('gio-unix-2.0'),
  dependency('json-glib-1.0'),
]

sources = [config] + files(
  'src/command.vala',
  'src/layout.vala',
  'src/output.vala',
  'src/triad.vala',
  'src/window.vala',
  'src/workspace.vala',
)

lib = library(
  name,
  sources,
  dependencies: deps,
  vala_args: ['--vapi-comments'],
  vala_header: name + '.h',
  vala_vapi: name + '-' + api_version + '.vapi',
  version: version,
  install: true,
  install_dir: [true, true, true],
)

gir = custom_target(
  gir_name,
  command: [
    find_program('python3'),
    files('gir.py'),
    '--name', name,
    '--gir', gir_name,
    '--pkgs', ':'.join(
      'gio-unix-2.0',
      'json-glib-1.0',
    ),
    '--property', ':'.join(
      'Triad.commands',
      'Triad.layouts',
      'Triad.layout_cycle_entries',
      'Triad.outputs',
      'Triad.special_requests',
      'Triad.workspaces',
      'Triad.windows',
    ),
    sources,
  ],
  input: sources,
  depends: lib,
  output: gir_name,
  install: true,
  install_dir: get_option('datadir') / 'gir-1.0',
)

custom_target(
  typelib_name,
  command: [
    find_program('g-ir-compiler'),
    '--output', '@OUTPUT@',
    '--shared-library', get_option('prefix') / get_option('libdir') / '@PLAINNAME@',
    meson.current_build_dir() / gir_name,
  ],
  input: lib,
  output: typelib_name,
  depends: [lib, gir],
  install: true,
  install_dir: get_option('libdir') / 'girepository-1.0',
)

import('pkgconfig').generate(
  lib,
  name: name,
  filebase: name + '-' + api_version,
  version: version,
  subdirs: name,
  requires: deps,
  install_dir: get_option('libdir') / 'pkgconfig',
)

if get_option('tests')
  test_env = environment()
  test_env.set('ASTAL_TRIAD_TEST_FIXTURES', meson.current_source_dir() / 'tests' / 'fixtures')

  test_bin = executable(
    'astal-triad-tests',
    sources + files('tests/triad-ipc.vala'),
    dependencies: deps,
    vala_args: ['--define=ASTAL_TRIAD_TESTS'],
  )

  test('triad-ipc', test_bin, env: test_env)
endif

if get_option('socket_tests')
  socket_test_env = environment()
  socket_test_env.set('ASTAL_TRIAD_TEST_FIXTURES', meson.current_source_dir() / 'tests' / 'fixtures')

  socket_test_bin = executable(
    'astal-triad-socket-tests',
    sources + files('tests/triad-socket.vala'),
    dependencies: deps,
    vala_args: ['--define=ASTAL_TRIAD_TESTS'],
  )

  test('triad-socket', socket_test_bin, env: socket_test_env)
endif

if get_option('live_tests')
  live_test_bin = executable(
    'astal-triad-live-tests',
    sources + files('tests/triad-live.vala'),
    dependencies: deps,
    vala_args: ['--define=ASTAL_TRIAD_TESTS'],
  )

  test('triad-live', live_test_bin, timeout: 10)
endif
