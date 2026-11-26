local parse = (import '../lib/common.libsonnet').parseDockerImage;

assert parse('alpine') == {
  registry: 'docker.io',
  repository: 'library/alpine',
  tag: null,
  digest: null,
};
assert parse('team/app:1.2') == {
  registry: 'docker.io',
  repository: 'team/app',
  tag: '1.2',
  digest: null,
};
assert parse('localhost:5000/team/app:1.2') == {
  registry: 'localhost:5000',
  repository: 'team/app',
  tag: '1.2',
  digest: null,
};
assert parse('registry.example/team/app@sha256:abcdef') == {
  registry: 'registry.example',
  repository: 'team/app',
  tag: null,
  digest: 'sha256:abcdef',
};
assert parse('registry.example/team/app:stable@sha256:abcdef') == {
  registry: 'registry.example',
  repository: 'team/app',
  tag: 'stable',
  digest: 'sha256:abcdef',
};

assert parse('alpine').format() == 'docker.io/library/alpine';
assert parse('team/app:1.2').format() == 'docker.io/team/app:1.2';
assert parse('registry.example/team/app@sha256:abcdef').format() == 'registry.example/team/app@sha256:abcdef';
assert parse('registry.example/team/app:stable@sha256:abcdef').format() == 'registry.example/team/app:stable@sha256:abcdef';

assert (
  parse('registry.example/team/app:stable@sha256:abcdef')
  +
  std.prune(parse('overlay.example/team/app'))
).format() == 'overlay.example/team/app:stable@sha256:abcdef';

true
