#!/bin/bash

NAMESPACE="elk-new"

# Function to create namespace if it doesn't exist
create_namespace() {
  if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "🔧 Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
  else
    echo "✅ Namespace $NAMESPACE already exists"
  fi
}

# Function to install Helm chart
install_chart() {
  local name=$1
  local chart=$2
  local values=$3

  if helm status "$name" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "⚠️  Helm release $name already exists in namespace $NAMESPACE. Skipping."
  else
    echo "🚀 Installing $name..."
    helm install "$name" "$chart" -n "$NAMESPACE" -f "$values"
  fi
}

# Start script
echo "🔁 Starting ELK stack installation in namespace: $NAMESPACE"

create_namespace

install_chart "elasticsearch" "elastic/elasticsearch" "elasticsearch-values.yaml"
install_chart "logstash" "elastic/logstash" "logstash-values.yaml"
install_chart "kibana" "elastic/kibana" "kibana-values.yaml"
install_chart "filebeat" "elastic/filebeat" "filebeat-values.yaml"

echo "✅ ELK stack deployed in $NAMESPACE!"











helm install elasticsearch elastic/elasticsearch -n elk-new -f elasticsearch-values.yaml

helm install filebeat elastic/filebeat -n elk-new -f filebeat-values.yaml

helm install logstash elastic/logstash -n elk-new -f logstash-values.yaml

helm install kibana elastic/kibana -n elk-new -f kibana-values.yaml
