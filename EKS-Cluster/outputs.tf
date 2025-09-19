output "cluster_id" {
    description = "EKS Cluster ID"
    value = module.eks.cluster_id
}
 
output "cluster_endpoint" {
    description = "Endpoint for EKS Control Plane"
    value = module.eks.cluster_endpoint
}
 
output "cluster_security_group_id" {
    description = "Security Group IDs attached to the Cluster Control Plan"
    value = module.eks.cluster_security_group_id
}
 
output "region" {
    description = "AWS Region"
    value = var.aws_region
}
 
output "oidc_provider_arn" {
    description = "OIDC ARN"
    value = module.eks.oidc_provider_arn
}