// Helpers shared by the framework parts.
local versions = std.parseYaml(importstr '../defaults.yaml');
local ns = import 'namespace.libsonnet';
local vendor = import 'vendor.libsonnet';

local s3EnvEntry(name, key, secret) = {
  name: name,
  valueFrom: { secretKeyRef: { name: secret, key: key } },
};

local imageTag(s, name) =
  if std.objectHas(s.images, name) && std.objectHas(s.images[name], 'tag') then s.images[name].tag
  else if std.objectHas(versions.controllers, name) then versions.controllers[name].version
  else std.get(versions.images[name], 'tag');

local parseDockerImage(image) =
  assert std.type(image) == 'string' && std.length(image) > 0 : 'image must be a non-empty string';
  local referenceParts = std.split(image, '@');
  assert std.length(referenceParts) <= 2 : 'image must contain at most one digest separator: ' + image;
  local name = referenceParts[0];
  local digest = if std.length(referenceParts) == 2 then referenceParts[1] else null;
  assert digest != '' : 'image digest must not be empty: ' + image;
  local path = std.split(name, '/');
  assert std.length([ part for part in path if part == '' ]) == 0 : 'image path must not contain empty components: ' + image;
  local last = path[std.length(path) - 1];
  local lastParts = std.split(last, ':');
  assert std.length(lastParts) <= 2 : 'image tag must contain at most one separator: ' + image;
  local tag = if std.length(lastParts) == 2 then lastParts[1] else null;
  assert tag != '' : 'image tag must not be empty: ' + image;
  local nameParts = path[0:std.length(path) - 1] + [ lastParts[0] ];
  local first = nameParts[0];
  local hasRegistry =
    std.length(nameParts) > 1
    && (std.length(std.findSubstr('.', first)) > 0
        || std.length(std.findSubstr(':', first)) > 0
        || first == 'localhost');
  local registry = if hasRegistry then first else 'docker.io';
  local repositoryParts =
    if hasRegistry then nameParts[1:]
    else if std.length(nameParts) == 1 then [ 'library' ] + nameParts
    else nameParts;
  assert std.length(repositoryParts) > 0 : 'image repository must not be empty: ' + image;
  {
    registry: registry,
    repository: std.join('/', repositoryParts),
    [if tag != null then 'tag']: tag,
    [if digest != null then 'digest']: digest,

    format()::
      local base = std.join('/', [ self.registry, self.repository ]);
      local withTag = if std.get(self, 'tag') != null then std.join(':', [ base, self.tag ]) else base;
      if std.get(self, 'digest') != null then std.join('@', [ withTag, self.digest ]) else withTag,
  };

{
  imageTag:: imageTag,
  parseDockerImage:: parseDockerImage,

  imageFor(s, name)::
    local fallback =
      if std.objectHas(versions.images, name) then versions.images[name]
      else { registry: 'ghcr.io', repository: 'helmetica-framework/' + name };
    local i = fallback + std.get(s.images, name, {});
    local tag = imageTag(s, name);
    if tag != null then
      '%(registry)s/%(repository)s:%(tag)s' % (i { tag: tag })
    else
      '%(registry)s/%(repository)s' % i,

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
