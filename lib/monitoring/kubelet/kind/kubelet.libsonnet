local kubelet = import '../kubelet.libsonnet';

function(s)
  [
    // The scrape class is defined on the Prometheus, see prometheus.jsonnet.
    kubelet(s).serviceMonitor('kubelet-serviceaccount-auth'),
  ]
