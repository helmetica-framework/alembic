// Rows for hack/vendor.sh, one per line:
//   <controller> <name> <kind> <path> <version>
local versions = std.parseYaml(importstr '../controllers.yaml');
local controllers = versions.controllers;

local paths(controller, field) =
  if std.objectHas(controllers[controller], field) then controllers[controller][field] else {};

local rows(controller, kind, field) = [
  '%s %s %s %s %s' % [ controller, name, kind, paths(controller, field)[name], controllers[controller].version ]
  for name in std.objectFields(paths(controller, field))
];

std.join('\n', std.flattenArrays([
  rows(c, 'kustomize', 'dirs') + rows(c, 'raw', 'files')
  for c in std.objectFields(controllers)
])) + '\n'
