{
  rewrite(objs, from, to)::

    local walk(v) =
      if std.isString(v) then std.strReplace(v, from, to)
      else if std.isArray(v) then [ walk(x) for x in v ]
      else if std.isObject(v) then { [k]: walk(v[k],) for k in std.objectFields(v) }
      else v;

    local isUpstreamNamespace(o) =
      local kindOf(o) = std.get(o, 'kind', '');
      local nameOf(o) = std.get(std.get(o, 'metadata', {}), 'name', '');

      kindOf(o) == 'Namespace' && nameOf(o) == from;


    [ walk(o) for o in objs if !isUpstreamNamespace(o) ],
}
