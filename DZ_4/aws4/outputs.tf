output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "replica_endpoints" {
  value = aws_db_instance.replica[*].endpoint
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
