function(s)
  local PlatformOpenShift4 = 'openshift4';
  local PlatformTalos = 'talos';
  local PlatformKind = 'kind';

  local platform =
    local allowedPlatforms = [ PlatformTalos, PlatformOpenShift4, PlatformKind ];
    assert std.contains(allowedPlatforms, s.monitoring_stack.platform) : "Invalid platform '%s' specified for monitoring_stack. Allowed values: %s" % [ s.monitoring_stack.platform, std.join(', ', allowedPlatforms) ];
    s.monitoring_stack.platform;

  {
    PlatformOpenShift4: PlatformOpenShift4,
    PlatformTalos: PlatformTalos,
    PlatformKind: PlatformKind,

    // The platform the monitoring stack is running on.
    platform: platform,
  }
