define prometheus::prometheus_rule (
  $alert_if,
  $alert_for,
  $alert_summary,
  $alert_description,
  $order,
  $alert_labels = undef,
  $alert_name = $title,
) {
  if ! defined(Class['kubernetes::apiserver']) {
    fail('This defined type can only be used on the kubernetes master')
  }

  kubernetes::apply_fragment { "prometheus-rules-${title}":
    content => template('prometheus/prometheus-rule.yaml.erb'),
    order   => $order,
    target  => '/etc/kubernetes/apply/prometheus-rules.yaml',
  }
}
