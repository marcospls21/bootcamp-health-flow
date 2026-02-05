resource "aws_iam_role" "nodes" {
  count = var.node_role_arn == "" ? 1 : 0
  name  = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes_worker" {
  count      = var.node_role_arn == "" ? 1 : 0
  role       = aws_iam_role.nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "nodes_cni" {
  count      = var.node_role_arn == "" ? 1 : 0
  role       = aws_iam_role.nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "nodes_ecr" {
  count      = var.node_role_arn == "" ? 1 : 0
  role       = aws_iam_role.nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "healthflow-prod-nodes"
  node_role_arn  = var.node_role_arn != "" ? var.node_role_arn : aws_iam_role.nodes[0].arn
  subnet_ids     = var.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  instance_types = ["t3.medium"]
}

