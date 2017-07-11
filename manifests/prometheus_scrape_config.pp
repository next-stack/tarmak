define prometheus::prometheus_scrape_config (
  $order,
  $config = {},
  $job_name = $title,
) {
  if ! defined(Class['kubernetes::apiserver']) {
    fail('This defined type can only be used on the kubernetes master')
  }

  $prepared_config = fragmenthash2yaml($config)

  kubernetes::apply_fragment { "prometheus-scrape-config-${job_name}":
    content => template('prometheus/prometheus-config-frag.yaml.erb'),
    order   => $order,
    target  => '/etc/kubernetes/apply/prometheus-config.yaml',
  }
}
