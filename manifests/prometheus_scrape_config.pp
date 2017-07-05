define prometheus::prometheus_scrape_config (
  $metrics_path,
  $order,
  $scheme,
  $scrape_interval,
  $scrape_timeout,
  $basic_auth = {},
  $bearer_token = '',
  $bearer_token_file = '',
  $kubernetes_sd_configs = {},
  $metric_relabel_configs = {},
  $params = {},
  $proxy_url = '',
  $relabel_configs = {},
  $static_configs = {},
  $tls_config = '',
  $job_name = $title,
) {
  if ! defined(Class['kubernetes::apiserver']) {
    fail('This defined type can only be used on the kubernetes master')
  }

  kubernetes::apply_fragment { "prometheus-scrape-config-${job_name}":
    content => template('prometheus/prometheus-rule.yaml.erb'),
    order   => $order,
    target  => '/etc/kubernetes/apply/prometheus-rules.yaml',
  }
}
