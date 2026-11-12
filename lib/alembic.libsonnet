// Entry point for the framework and monitoring renderers.
local chrysopoeia = import 'chrysopoeia.libsonnet';
local common = import 'common.libsonnet';
local controllers = import 'controllers.libsonnet';
local defaults = import 'defaults.libsonnet';

{
  defaults:: defaults,

  framework(settings)::
    local s = std.mergePatch(defaults, settings);

    assert s.chrysopoeia.admission == 'builtin' || s.chrysopoeia.admission == 'espejote'
           : 'chrysopoeia.admission must be builtin or espejote';

    local namespace =
      if s.createNamespace then [ {
        apiVersion: 'v1',
        kind: 'Namespace',
        metadata: { name: s.namespace } + s.namespaceMetadata,
      } ] else [];

    common.part('00_namespace', namespace)
    + chrysopoeia.parts(s)
    + controllers.parts(s),

  monitoring(settings)::
    {},
}
