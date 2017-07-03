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

  kubernetes::apply { "prometheus-rule-${title}":
    type => 'concat',
  }

  kubernetes::apply_fragment { "prometheus-rule-${title}-content":
    content => template('prometheus/prometheus-rule.yaml.erb'),
    order   => '00',
    target  => "/etc/kubernetes/apply/prometheus-rule-${title}.yaml",
  }
}
