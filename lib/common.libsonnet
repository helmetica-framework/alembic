// Helpers shared by the framework parts.
local versions = std.parseYaml(importstr '../controllers.yaml');
local ns = import 'namespace.libsonnet';
local vendor = import 'vendor.libsonnet';

local s3EnvEntry(name, key, secret) = {
  name: name,
  valueFrom: { secretKeyRef: { name: secret, key: key } },
};

local imageTag(s, name) =
  if std.objectHas(s.images, name) && std.objectHas(s.images[name], 'tag') then s.images[name].tag
  else if std.objectHas(versions.controllers, name) then versions.controllers[name].version
  else versions.images[name].tag;

{
  imageTag:: imageTag,

  imageFor(s, name)::
    local v = std.get(versions.controllers, name, {});
    local fallback =
      if std.objectHas(v, 'repository') then { registry: 'ghcr.io', repository: v.repository }
      else if std.objectHas(versions.images, name) then versions.images[name]
      else { registry: 'ghcr.io', repository: 'helmetica-framework/' + name };
    local i = fallback + std.get(s.images, name, {});
    '%(registry)s/%(repository)s:%(tag)s' % (i { tag: imageTag(s, name) }),

  addArgs(c, args)::
    c { args: std.get(c, 'args', []) + args },

  replaceArg(args, prefix, value)::
    local hits = [
      i
      for i in std.range(0, std.length(args) - 1)
      if std.startsWith(args[i], prefix)
    ];
    assert std.length(hits) == 1 : 'expected exactly one arg starting with ' + prefix;
    [
      if i == hits[0] then value else args[i]
      for i in std.range(0, std.length(args) - 1)
    ],

  patchContainer(name, d, f)::
    local cs = d.spec.template.spec.containers;
    local hits = [
      i
      for i in std.range(0, std.length(cs) - 1)
      if cs[i].name == name
    ];
    assert std.length(hits) == 1 : 'expected exactly one container named ' + name + ' in ' + d.metadata.name;
    d {
      spec+: {
        template+: {
          spec+: {
            containers: [
              if i == hits[0] then f(cs[i]) else cs[i]
              for i in std.range(0, std.length(cs) - 1)
            ],
          },
        },
      },
    },

  patchDeployments(objs, f)::
    [
      if o.kind == 'Deployment' then f(o) else o
      for o in objs
    ],

  part(key, objs)::
    if std.length(objs) == 0 then {} else { [key]: objs },

  s3Env(c, s)::
    std.mergePatch(c, { envFrom: null })
    {
      env: std.get(c, 'env', []) + [
        s3EnvEntry('S3_ENDPOINT', 'COSI_S3_ENDPOINT', s.libra.bucketSecretName),
        s3EnvEntry('S3_BUCKET', 'COSI_S3_BUCKET_ID', s.libra.bucketSecretName),
        s3EnvEntry('AWS_ACCESS_KEY_ID', 'COSI_S3_ACCESS_KEY_ID', s.libra.bucketSecretName),
        s3EnvEntry('AWS_SECRET_ACCESS_KEY', 'COSI_S3_ACCESS_SECRET_KEY', s.libra.bucketSecretName),
      ],
    },

  admissionObjs(s, proxyObjs)::
    if s.chrysopoeia.admission == 'builtin' then proxyObjs
    else if s.chrysopoeia.admission == 'espejote' then
      local kept = [
        o
        for o in proxyObjs
        if !(std.objectHas(o, 'kind')
             && (o.kind == 'MutatingAdmissionPolicy' || o.kind == 'MutatingAdmissionPolicyBinding')
             && o.metadata.name == 'chrysopoeia-instances-namespaced-requires-labels')
      ];
      kept + ns.rewrite(vendor.objects.chrysopoeia.espejote, vendor.namespaces.chrysopoeia.proxy, s.namespace)
    else error 'chrysopoeia.admission must be builtin or espejote, got ' + s.chrysopoeia.admission,
}
