define prometheus::prometheus_rule (
  $alert_name = $title,
  $alert_if = '',
  $alert_for = '',
  $alert_summary = '',
  $alert_description = '',
) {
  if ! defined(Class['kubernetes::apiserver']) {
    fail('This defined type can only be used on the kubernetes master')
  }

  kubernetes::apply_fragment { "prometheus-rules-${title}":
    content => template('prometheus/prometheus-rule.yaml.erb'),
    order   => '01',
    target  => '/etc/kubernetes/apply/prometheus-rules.yaml',
  }
}
