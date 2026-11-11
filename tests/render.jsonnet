local alembic = import '../lib/alembic.libsonnet';

function(settings)
  local fw = alembic.framework(settings);
  local mon = alembic.monitoring(settings);
  {
    ['framework/%s.yaml' % k]: std.manifestYamlStream(fw[k], quote_keys=false)
    for k in std.objectFields(fw)
  } + {
    ['monitoring/%s.yaml' % k]: std.manifestYamlStream(mon[k], quote_keys=false)
    for k in std.objectFields(mon)
  }
