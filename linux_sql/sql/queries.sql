-- 1. Group hosts by hardware info

select 
    cpu_number,
    id as host_id,
    total_mem
from host_info
order by
    cpu_number asc,
    total_mem desc;


-- 2. Average memory usage

CREATE FUNCTION round5(ts timestamp) RETURNS timestamp AS
$$
BEGIN
    RETURN date_trunc('hour', ts) + date_part('minute', ts):: int / 5 * interval '5 min';
END;
$$
    LANGUAGE PLPGSQL;


select
    hu.host_id, 
    hi.hostname,
    round5(hu.timestamp) as rounded_timestamp,
    ROUND(AVG((hi.total_mem - hu.memory_free)::numeric / hi.total_mem * 100), 2) AS avg_used_mem_pct
from host_usage hu
join host_info hi
    on hu.host_id = hi.id
group by
    hu.host_id,
    hi.hostname,
    rounded_timestamp
order by
    hu.host_id,
    hi.hostname,
    avg_used_mem_pct desc; 


-- 3. Detect host failure

select
	hu.host_id, 
	round5(hu.timestamp) as rounded_timestamp,
	COUNT(*) as num_data_points
from host_usage hu
join host_info hi
	on hu.host_id = hi.id
group by
	hu.host_id,
	rounded_timestamp
having 
	COUNT(*) <= 3
order by
	hu.host_id;

