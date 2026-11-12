// Upstream objects at their pinned tags, from the generated index.
local index = import '../vendor/index.libsonnet';
local versions = std.parseYaml(importstr '../controllers.yaml');

local asList(x) =
  if std.isArray(x) then x else [ x ];

// Empty documents come back as null.
local parse(s) =
  [ o for o in asList(std.parseYaml(s)) if o != null ];

{
  // Namespace each upstream dir renders into. Cluster-scoped dirs have none.
  namespaces: {
    chrysopoeia: { default: 'chrysopoeia-system', proxy: 'chrysopoeia-proxy-system', flux: 'chrysopoeia-flux-system' },
    custos: { default: 'custos-system' },
    ampulla: { default: 'ampulla-system' },
    adept: { default: 'adept-system' },
    sigillum: { default: 'sigillum-system' },
    libra: { default: 'libra-system' },
  },

  objects: {
    [controller]: {
      [name]: parse(index[controller][name])
      for name in std.objectFields(index[controller])
    }
    for controller in std.objectFields(index)
  },

  // The namespace a generic controller's upstream dir renders into.
  namespaceOf(controller)::
    local v = versions.controllers[controller];
    local found = [
      o.metadata.name
      for o in parse(index[controller].default)
      if o.kind == 'Namespace'
    ];
    if std.objectHas(v, 'namespace') then v.namespace
    else if std.length(found) == 1 then found[0]
    else controller + '-system',

  asList:: asList,
  parse:: parse,
}
