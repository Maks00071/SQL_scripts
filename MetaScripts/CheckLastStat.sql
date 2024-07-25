-- Запрос для просмотра информации о последней собранной статистике

select
  pn.nspname,
  pc.relname,
  pslo.staactionname,
  pslo.stasubtype,
  pslo.statime as action_date,
  pp.partitionrangestart
from
  pg_stat_last_operation pslo
  right outer join pg_class pc on pc.oid = pslo.objid
  and pslo.staactionname in ('ANALYZE')
  join pg_namespace pn on pn.oid = pc.relnamespace
  left join pg_catalog.pg_partitions pp on (
    pp.partitiontablename = pc.relname
    and pp.schemaname = pn.nspname
  )
where
  pc.relkind IN ('r', 's')
  and pc.relstorage IN ('h', 'a', 'c')
  and relname like 'table_name'
  and pn.nspname = 'schema_name'
order by
  partitionrangestart desc;
