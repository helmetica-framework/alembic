// Rows for hack/vendor.sh, one per line:
//   <controller> <name> <kind> <path> <version> <repo>
// `dirs` are kustomize, `files` are raw, `rawdirs` are all YAML files in a dir.
local versions = std.parseYaml(importstr '../defaults.yaml');
local controllers = versions.controllers;

local paths(controller, field) =
  if std.objectHas(controllers[controller], field) then controllers[controller][field] else {};

// Controllers without a version use their image tag. One pin for the image and
// its CRDs.
local version(controller) =
  if std.objectHas(controllers[controller], 'version')
  then controllers[controller].version
  else versions.images[controller].tag;

local repo(controller) =
  std.get(controllers[controller], 'repo', 'helmetica-framework/' + controller);

local rows(controller, kind, field) = [
  '%s %s %s %s %s %s' % [
    controller,
    name,
    kind,
    paths(controller, field)[name],
    version(controller),
    repo(controller),
  ]
  for name in std.objectFields(paths(controller, field))
];

std.join('\n', std.flattenArrays([
  rows(c, 'kustomize', 'dirs') + rows(c, 'raw', 'files') + rows(c, 'github-dir', 'rawdirs')
  for c in std.objectFields(controllers)
])) + '\n'
