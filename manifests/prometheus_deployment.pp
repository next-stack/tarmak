class prometheus::prometheus_deployment (
  $addon_dir = $::prometheus::addon_dir,
  $helper_dir = $::prometheus::helper_dir,
  $prometheus_namespace = $::prometheus::prometheus_namespace,
  $prometheus_image = $::prometheus::prometheus_image,
  $prometheus_version = $::prometheus::prometheus_version,
  $prometheus_storage_local_retention = $::prometheus::prometheus_storage_local_retention,
  $prometheus_storage_local_memchunks = $::prometheus::prometheus_storage_local_memchunks,
  $prometheus_port = $::prometheus::prometheus_port,
  $prometheus_use_module_config = $::prometheus::prometheus_use_module_config,
  $etcd_cluster = $::prometheus::etcd_cluster,
  $etcd_k8s_port = $::prometheus::etcd_k8s_port,
  $etcd_events_port = $::prometheus::etcd_events_port,
  $etcd_overlay_port = $::prometheus::etcd_overlay_port,
  $prometheus_use_module_rules = $::prometheus::prometheus_use_module_rules,
  $prometheus_install_state_metrics = $::prometheus::prometheus_install_state_metrics,
  $prometheus_install_node_exporter = $::prometheus::prometheus_install_node_exporter,
  $node_exporter_image = $::prometheus::node_exporter_image,
  $node_exporter_port = $::prometheus::node_exporter_port,
  $node_exporter_version = $::prometheus::node_exporter_version,
)
{
  require ::kubernetes

  kubernetes::apply{'prometheus-server':
    manifests => [
      template('prometheus/prometheus-ns.yaml.erb'),
      template('prometheus/prometheus-deployment.yaml.erb'),
      template('prometheus/prometheus-svc.yaml.erb'),
    ],
  }

  kubernetes::apply{'prometheus-config':
      type => 'concat',
  }

  kubernetes::apply_fragment { 'prometheus-config-header':
      content => template('prometheus/prometheus-config-header.yaml.erb'),
      order   => '00',
      target  => '/etc/kubernetes/apply/prometheus-config.yaml',
  }

  kubernetes::apply_fragment { 'prometheus-config-prometheus-file':
      content => "  prometheus.yml: |-",
      order   => '01',
      target  => '/etc/kubernetes/apply/prometheus-config.yaml',
  }

  kubernetes::apply_fragment { 'prometheus-config-prometheus-rules':
      content => template('prometheus/prometheus-config-rules.yaml.erb'),
      order   => '02',
      target  => '/etc/kubernetes/apply/prometheus-config.yaml',
  }

  kubernetes::apply_fragment { 'prometheus-config-global':
      content => template('prometheus/prometheus-config-global.yaml.erb'),
      order   => '03',
      target  => '/etc/kubernetes/apply/prometheus-config.yaml',
  }

  kubernetes::apply_fragment { 'prometheus-config-global':
      content => '    scrape_configs:',
      order   => '04',
      target  => '/etc/kubernetes/apply/prometheus-config.yaml',
  }

  kubernetes::apply{'prometheus-rules':
      type => 'concat',
  }

  kubernetes::apply_fragment { 'prometheus-rules-header':
      content => template('prometheus/prometheus-rules-header.yaml.erb'),
      order   => '00',
      target  => '/etc/kubernetes/apply/prometheus-rules.yaml',
  }

  prometheus::prometheus_rule { 'cpu-usage':
    alert_if          => '(100 - (avg by (instance) (irate(node_cpu{name="node-exporter",mode="idle"}[5m])) * 100)) > 75',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: High CPU usage detected',
    alert_description => '{{$labels.instance}}: CPU usage is above 75% (current value is: {{ $value }})',
    order             => '01',
  }

  prometheus::prometheus_rule { 'etcd-server':
    alert_if          => '(probe_success !=1 AND probe_success{instance=~".*etcd.*"})',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: etcd server probe failed',
    alert_description => '{{$labels.instance}}: etcd server probe failed for {{$labels.job}}',
    order             => '02',
  }

  prometheus::prometheus_rule { 'etcd-server-quorum':
    alert_if          => '(etcd_server_has_leader != 1)',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: etcd server has no leader',
    alert_description => '{{$labels.instance}}: etcd cluster server has no leader',
    order             => '03',
  }
  prometheus::prometheus_rule { 'kubernetes-pods':
    alert_if          => '(kube_deployment_status_replicas_unavailable != 0)',
    alert_for         => '2m',
    alert_summary     => '{{$labels.deployment}}: deployment has replicas unavailable',
    alert_description => '{{$labels.deployment}}: deployment has {{$value}} replicas unavailable',
    order             => '04',
  }

  prometheus::prometheus_rule { 'kubernetes-nodes':
    alert_if          => '((kube_node_status_ready{condition="false"})>0 OR (kube_node_status_ready{condition="unknown"})>0)',
    alert_for         => '2m',
    alert_summary     => '{{$labels.node}}: is not ready or in unknown state',
    alert_description => '{{$labels.node}}: condition {{$labels.condition}}',
    order             => '05',
  }

  prometheus::prometheus_rule { 'load-average':
    alert_if          => '((node_load5 / count without (cpu, mode) (node_cpu{mode="system"})) > 3)',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: High LA detected',
    alert_description => '{{$labels.instance}}: 5 minute load average is {{$value}}',
    order             => '06',
  }

  prometheus::prometheus_rule { 'low-disk-space-root':
    alert_if          => '((node_filesystem_size{mountpoint="/root-disk"} - node_filesystem_free{mountpoint="/root-disk"} ) / node_filesystem_size{mountpoint="/root-disk"} * 100) > 75',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: Low root disk space',
    alert_description => '{{$labels.instance}}: Root disk usage is above 75% (current value is: {{ $value }})',
    order             => '07',
  }
  prometheus::prometheus_rule { 'low-disk-space-data':
    alert_if          => '((node_filesystem_size{mountpoint="/data-disk"} - node_filesystem_free{mountpoint="/data-disk"} ) / node_filesystem_size{mountpoint="/data-disk"} * 100) > 75',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: Low data disk space',
    alert_description => '{{$labels.instance}}: Data disk usage is above 75% (current value is: {{ $value }})',
    order             => '08',
  }

  prometheus::prometheus_rule { 'swap-usage':
    alert_if          => '(((node_memory_SwapTotal-node_memory_SwapFree)/node_memory_SwapTotal)*100) > 75',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: Swap usage detected',
    alert_description => '{{$labels.instance}}: Swap usage usage is above 75% (current value is: {{ $value }})',
    order             => '09',
  }

  prometheus::prometheus_rule { 'mem-usage':
    alert_if          => '(((node_memory_MemTotal-node_memory_MemFree-node_memory_Cached)/(node_memory_MemTotal)*100)) > 75',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: High memory usage detected',
    alert_description => '{{$labels.instance}}: Memory usage usage is above 75% (current value is: {{ $value }})',
    order             => '10',
  }

  prometheus::prometheus_rule { 'scrape':
    alert_if          => '(up == 0 AND up {job != "kubernetes-apiservers"})',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: Scrape target is down',
    alert_description => '{{$labels.instance}}: Target down for job {{$labels.job}}',
    order             => '11',
  }

  prometheus::prometheus_rule { 'scrape-container':
    alert_if          => '(container_scrape_error) != 0',
    alert_for         => '2m',
    alert_summary     => '{{$labels.instance}}: Container scrape error',
    alert_description => '{{$labels.instance}}: Failed to scrape container, metrics will not be updated',
    order             => '12',
  }

  kubernetes::apply{'kube-state-metrics':
    manifests => [
      template('prometheus/prometheus-ns.yaml.erb'),
      template('prometheus/kube-state-metrics-deployment.yaml.erb'),
      template('prometheus/kube-state-metrics-service.yaml.erb'),
    ],
  }

  kubernetes::apply{'node-exporter':
    manifests => [
      template('prometheus/prometheus-ns.yaml.erb'),
      template('prometheus/prometheus-node-exporter-ds.yaml.erb'),
    ],
  }
}
