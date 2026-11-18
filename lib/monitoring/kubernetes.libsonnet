local kind = import './kubelet/kind/kubelet.libsonnet';
local openshift = import './kubelet/openshift/kubelet.libsonnet';

function(s)
  local prom = (import 'common.libsonnet')(s);

  if prom.platform == prom.PlatformOpenShift4 then
    openshift(s)
  else if prom.platform == prom.PlatformKind then
    kind(s)
  else
    []
